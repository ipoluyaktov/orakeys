unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,  IniFiles,
  Oracle, OracleData, SimpleGraph, Vcl.ComCtrls, Vcl.Menus, Vcl.TitleBarCtrls,
  Vcl.WinXPanels, Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TfmMain = class(TForm)
    TableGraph: TSimpleGraph;
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    oraTargetQ: TOracleQuery;
    oraTarget: TOracleSession;
    oraDS: TOracleDataSet;
    Status: TStatusBar;
    TableMenu: TPopupMenu;
    RenameNode: TMenuItem;
    TablesMenu: TPopupMenu;
    InsertNode: TMenuItem;
    CopyNode: TMenuItem;
    PageControl: TPageControl;
    tsTables: TTabSheet;
    tsJobs: TTabSheet;
    JobGraph: TSimpleGraph;
    tsDataRefresh: TTabSheet;
    RefreshGraph: TSimpleGraph;
    oraSource: TOracleSession;
    oraSourceQ: TOracleQuery;
    RefreshMenu: TPopupMenu;
    miRefresh: TMenuItem;
    dateClosed: TDateTimePicker;
    Label1: TLabel;
    dateLastRefreshed: TDateTimePicker;
    Label2: TLabel;
    chbAutoRefresh: TCheckBox;
    tmrRefresh: TTimer;
    tsLog: TTabSheet;
    rchLog: TRichEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TableGraphInfoTip(Graph: TSimpleGraph; GraphObject: TGraphObject;
      var InfoTip: string);
    procedure FormShow(Sender: TObject);
    procedure TableGraphGraphChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TableGraphObjectContextPopup(Graph: TSimpleGraph;
      GraphObject: TGraphObject; const MousePos: TPoint; var Handled: Boolean);
    procedure RenameNodeClick(Sender: TObject);
    procedure CopyNodeClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure miRefreshClick(Sender: TObject);
    procedure RefreshGraphObjectContextPopup(Graph: TSimpleGraph;
      GraphObject: TGraphObject; const MousePos: TPoint; var Handled: Boolean);
    procedure chbAutoRefreshClick(Sender: TObject);
    procedure tmrRefreshTimer(Sender: TObject);
  private
    { Private declarations }
    FLatestConnectionError: string;
    FGraphChanged: boolean;
    FIni: TIniFile;
    FRowsInserted: integer;
    FRefreshId: integer; //Значение RECORD_ID из таблицы NRLOGS.LG_DATA_FLOW для auto-refresh
    function AppendSchema(p_TableName: string; p_IsSource: boolean): string;
    function CheckConnections: boolean;
    procedure CompareStructure(p_Source, p_Target: TGraphNode);
    procedure CompareStructures;
    function GetAppVersion: string;
    function GetRecordCount( p_TableName: string ): integer;
    function GetDateField(p_TableName: string): string;
    function FindNode( p_graph: TSimpleGraph; p_name: string ): TGraphNode;
    procedure FetchClosedDateFromSource;
    procedure InitRefreshTab;
    procedure Log(p_Message: string);
    procedure RemoveLinks;
    procedure ShowLinks;
    procedure RefreshByClick;
    procedure RefreshAll;
    procedure DeleteFromTarget( p_TableName, p_DateField: string );
    procedure InsertIntoTarget( p_TableName, p_DateField: string );
    procedure RefreshTable( p_TableName, p_SourceTable: string );
    function FetchLatestRefreshId(p_DoRefresh: boolean): integer;
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

{ TfmMain }
uses AppVersion;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  FIni := TIniFile.Create( ChangeFileExt(Application.ExeName, '.ini') );
  oraSource.LogonDatabase := FIni.ReadString('Source', 'DB', '');
  oraSource.LogonUsername := FIni.ReadString('Source', 'Username', '');
  oraSource.LogonPassword := FIni.ReadString('Source', 'Password', '');

  oraTarget.LogonDatabase := FIni.ReadString('Target', 'DB', '');
  oraTarget.LogonUsername := FIni.ReadString('Target', 'Username', '');
  oraTarget.LogonPassword := FIni.ReadString('Target', 'Password', '');
end;

procedure TfmMain.FormShow(Sender: TObject);
begin
  if CheckConnections then begin
    TableGraph.LoadFromFile('Tables.sgp');
    JobGraph.LoadFromFile('Jobs.sgp');
    RefreshGraph.LoadFromFile('Refresh.sgp');
    PageControl.ActivePageIndex := FIni.ReadInteger('UI', 'ActivePageIndex', 0);
    RemoveLinks;
    ShowLinks;
  end;
  FGraphChanged := False;
  PageControlChange(self);
  rchLog.Clear;
  Log( GetAppVersion + ' started' );
  tmrRefresh.Enabled := chbAutoRefresh.Checked;
  FRefreshId := 0;
end;

function TfmMain.GetAppVersion: string;
var
  v_exe: string;
  v_major, v_minor, v_build: cardinal;
begin
  v_exe := Application.ExeName;
  result := ExtractFileName(v_exe);
  if GetProductVersion(v_exe, v_major, v_minor, v_build) then
    result := Format('%s %d.%d.%d', [result, v_major, v_minor, v_build]);
end;

procedure TfmMain.Log(p_Message: string);
begin
  rchLog.Lines.Add( DateTimeToStr(Now()) + '   ' + p_Message );
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FIni.WriteInteger('UI', 'ActivePageIndex', PageControl.ActivePageIndex);
  FIni.Free;
end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FGraphChanged then
    case MessageDlg('Table graph has been changed. Do you want to save it?',
                    TMsgDlgType.mtConfirmation,
                    [mbYes, mbNo, mbCancel],
                    0) of
      mrYes: begin
        TableGraph.SaveToFile('Tables.sgp');
        CanClose := True;
      end;
      mrNo: CanClose := True;
      mrCancel: CanClose := False;
    end;

end;

function TfmMain.FindNode(p_Graph: TSimpleGraph; p_name: string): TGraphNode;
var
  i: integer;
begin
  result := nil;
  for i := 0 to p_Graph.Objects.Count - 1 do
    if p_Graph.Objects[i] is TGraphNode then
      if (p_Graph.Objects[i] as TRectangularNode).Text = p_name then
        result := TGraphNode( p_Graph.Objects[i] );
end;

function TfmMain.GetRecordCount(p_TableName: string): integer;
begin
  Screen.Cursor := crSQLWait;
  try
    oraTargetQ.Close;
    oraTargetQ.SQL.Text := 'select count(1) from ' + p_TableName;
    oraTargetQ.Execute;
    result := oraTargetQ.Field(0);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfmMain.miRefreshClick(Sender: TObject);
begin
  RefreshByClick;
end;

procedure TfmMain.TableGraphGraphChange(Sender: TObject);
begin
  FGraphChanged := True;
end;

procedure TfmMain.TableGraphInfoTip(Graph: TSimpleGraph; GraphObject: TGraphObject;
  var InfoTip: string);
begin
  if GraphObject.IsNode then
    try
      InfoTip := 'Number of records: ' + IntToStr(GetRecordCount(GraphObject.Text));
    except
      on E: Exception do
        InfoTip := E.Message;
    end;
end;

procedure TfmMain.TableGraphObjectContextPopup(Graph: TSimpleGraph;
  GraphObject: TGraphObject; const MousePos: TPoint; var Handled: Boolean);
begin
  if GraphObject.IsNode then begin
    TableMenu.Popup( fmMain.Left + MousePos.X,
                     fmMain.Top + MousePos.Y);
    Handled := True;
  end;
end;

procedure TfmMain.CopyNodeClick(Sender: TObject);
var
  v_src, v_tgt: TRectangularNode;
begin
  v_src := TRectangularNode(TableGraph.SelectedObjects[0]);
  v_tgt := TRectangularNode.Create(TableGraph);
  v_tgt.Assign(v_src);
  v_tgt.Left := v_tgt.Left + 60;
  v_tgt.Top := v_tgt.Top + 30;
end;

procedure TfmMain.RenameNodeClick(Sender: TObject);
var
  s:string;
begin
  s := TableGraph.SelectedObjects[0].Text;
  if InputQuery('Edit', 'Node name', s) then
    TableGraph.SelectedObjects[0].Text := s;
end;

procedure TfmMain.RefreshGraphObjectContextPopup(Graph: TSimpleGraph;
  GraphObject: TGraphObject; const MousePos: TPoint; var Handled: Boolean);
begin
  if GraphObject.IsNode then begin
    RefreshMenu.Popup( fmMain.Left + MousePos.X,
                     fmMain.Top + MousePos.Y);
    Handled := True;
  end;

end;

procedure TfmMain.RemoveLinks;
var
  i: integer;
begin
  i := 0;
  while i <= TableGraph.Objects.Count - 1 do
    if TableGraph.Objects[i].IsLink then
      TableGraph.Objects[i].Delete
    else
      i := i + 1;
end;

procedure TfmMain.ShowLinks;
var
  v_src, v_tgt: TGraphNode;
  v_link: TGraphLink;
begin
  oraDS.Open;
  while not oraDS.Eof do begin
    v_src := FindNode( TableGraph, oraDS.FieldByName('FK_TABLE_NAME').AsString );
    v_tgt := FindNode( TableGraph, oraDS.FieldByName('PK_TABLE_NAME').AsString );
    if (v_src <> nil) and (v_tgt <> nil) then begin
      v_link := TGraphLink.Create(TableGraph);
      v_link.Link(v_src, v_tgt);
      v_link.LinkOptions := [gloFixedStartPoint, gloFixedEndPoint];
      v_link.Pen.Width := 1;
      if oraDS.FieldByName('FK_STATUS').AsString = 'DISABLED' then
        v_link.Pen.Style := psDot;
    end;
    oraDS.Next;
  end;
end;


procedure TfmMain.PageControlChange(Sender: TObject);
begin
  if PageControl.ActivePage = tsDataRefresh then begin
    InitRefreshTab;
  end;
end;

function TfmMain.CheckConnections: boolean;
var
  v_check: TCheckConnectionResult;
  v_env: string;
begin
  result := True;
  try
    oraSource.Connected := True;
    v_env := oraSource.LogonUsername + '@' + oraSource.LogonDatabase;
    Status.Panels[0].Text := 'Checking source: ' + v_env + '...';
    v_check := oraSource.CheckConnection(False);
    if v_check = ccError then begin
      Status.Panels[0].Text := v_env + ' is unavailable';
      result := False;
      oraSource.Connected := False;
    end
    else begin
      oraTarget.Connected := True;
      v_env := oraTarget.LogonUsername + '@' + oraTarget.LogonDatabase;
      Status.Panels[0].Text := 'Checking target: ' + v_env + '...';
      if oraTarget.CheckConnection(False) = ccError then begin
        Status.Panels[0].Text := v_env + ' is unavailable';
        result := False;
        oraTarget.Connected := False;
      end
      else
        Status.Panels[0].Text := 'Connected to target: ' + v_env;
    end;
  except
    on E: Exception do begin
      result := False;
      if E.Message <> FLatestConnectionError then
        Log(E.Message);
      FLatestConnectionError := E.Message;
    end;
  end;
end;

// ------------------------------ Refresh tab --------------------------------//
procedure TfmMain.InitRefreshTab;
var
  v_src, v_tgt: TGraphNode;
begin
  CheckConnections;
  v_src := FindNode(RefreshGraph, 'Source');
  v_tgt := FindNode(RefreshGraph, 'Target');
  if v_src <> nil then begin
    v_src.Text := oraSource.LogonUsername + '@' + oraSource.LogonDatabase;
    v_src.Brush.Color := clActiveCaption;
  end;
  if v_tgt <> nil then begin
    v_tgt.Text := oraTarget.LogonUsername + '@' + oraTarget.LogonDatabase;
    v_tgt.Brush.Color := clActiveCaption;
  end;
  //FetchClosedDateFromSource;
  dateLastRefreshed.Date := FIni.ReadDate('Target', 'LastRefreshedDate', EncodeDate(1900, 1, 1));
  //CompareStructures;
end;

procedure TfmMain.RefreshTable(p_TableName, p_SourceTable: string);
var
  v_DateField, v_Message: string;
begin
  v_DateField := GetDateField( p_SourceTable );
  DeleteFromTarget( p_TableName, v_DateField );
  InsertIntoTarget( p_TableName, v_DateField );
  v_Message := IntToStr(FRowsInserted) + ' records inserted into table ' + p_TableName;
  Log(v_Message);
  if not chbAutoRefresh.Checked then
    ShowMessage( v_Message );
  Status.Panels[1].Text := '';
  FIni.WriteDate('Target', 'LastRefreshedDate', dateClosed.Date);
end;

procedure TfmMain.RefreshByClick;
var
  v_Node, v_SourceNode: TGraphNode;
begin
  Screen.Cursor := crSQLWait;
  Application.ProcessMessages;
  try
    v_Node := RefreshGraph.SelectedObjects[0] as TGraphNode;
    if v_Node.LinkInputCount = 0 then
      ShowMessage('No input link')
    else begin
      v_SourceNode := v_Node.LinkInputs[0].Source as TGraphNode;
      RefreshTable( v_Node.Text, v_SourceNode.Text );
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfmMain.RefreshAll;
var
  i: integer;
  v_Object: TGraphObject;
  v_Node, v_SourceNode: TGraphNode;
begin
  for i := 0 to RefreshGraph.Objects.Count - 1 do begin
    v_Object := RefreshGraph.Objects[i];
    if v_Object.IsNode then begin
      v_Node := (v_Object as TGraphNode);
      if v_Node.LinkInputCount > 0 then begin
        v_SourceNode := v_Node.LinkInputs[0].Source as TGraphNode;
        RefreshTable(v_Node.Text, v_SourceNode.Text);
      end;
    end;
  end;
end;

function TfmMain.FetchLatestRefreshId(p_DoRefresh: boolean): integer;
var
  v_record_id: integer;
begin
  result := FRefreshId;
  try
    oraSourceQ.Close;
    oraSourceQ.DeleteVariables;
    oraSourceQ.SQL.Text := 'select nvl(max(record_id), 0) as record_id, ';
    oraSourceQ.SQL.Add(    '       min(oper_date) as oper_date, ');
    oraSourceQ.SQL.Add(    '       max(oper_date_to) as oper_date_to');
    oraSourceQ.SQL.Add(    '  from nrlogs.vw_lg_data_flow' );
    oraSourceQ.SQL.Add(    ' where flow_to = ''DMA'' and end_date is not null' );
    oraSourceQ.SQL.Add(    '   and record_id > ' + IntToStr(FRefreshId) );
    oraSourceQ.SQL.Add(    ' order by record_id desc' );
    oraSourceQ.Execute;
    v_record_id := oraSourceQ.FieldAsInteger('record_id');
    if v_record_id = 0 then begin
      Status.Panels[2].Text := 'No new RECORD_ID found in NRLOGS.VW_LG_DATA_FLOW';
    end
    else begin
      if p_DoRefresh then begin
        Log( 'A new data mart regeneration found in the source. RECORD_ID = ' + IntToStr(v_record_id) );
        dateLastRefreshed.Date := oraSourceQ.FieldAsDate('oper_date');
        dateClosed.Date := oraSourceQ.FieldAsDate('oper_date_to');
        Log( 'The refresh interval is ' + DateToStr(dateLastRefreshed.Date) + ' - ' +
                                          DateToStr(dateClosed.Date) );
        RefreshAll;
      end;
      result := v_record_id;
    end;
  except
    on E: Exception do
      Log(E.Message);
  end;
end;

procedure TfmMain.tmrRefreshTimer(Sender: TObject);
begin

  Status.Panels[1].Text := 'Auto-refresh check: ' + DateTimeToStr(Now);
  tmrRefresh.Enabled := False;
  try
    FRefreshId := FetchLatestRefreshId(True);
  finally
    tmrRefresh.Enabled := True;
  end;
end;

function TfmMain.GetDateField(p_TableName: string): string;
var
  i: integer;
  fn: string;
begin
  oraSourceQ.Close;
  oraSourceQ.DeleteVariables;
  oraSourceQ.SQL.Text := 'select * from ' + p_TableName;
  oraSourceQ.Execute;

  if oraSourceQ.FieldIndex('TO_DATE') <> -1 then
    result := 'TO_DATE'
  else if oraSourceQ.FieldIndex('ON_DATE') <> - 1 then
    result := 'ON_DATE'
  else if oraSourceQ.FieldIndex('BANK_DATE') <> -1 then
    result := 'BANK_DATE'
  else if oraSourceQ.FieldIndex('OPER_DATE') <> -1 then
    result := 'OPER_DATE';
end;

procedure TfmMain.DeleteFromTarget(p_TableName, p_DateField: string);
begin
  Status.Panels[1].Text := 'Deleting from ' + p_TableName + '...';
  Application.ProcessMessages;
  oraTargetQ.DeleteVariables;
  oraTargetQ.SQL.Text := 'delete from ' + p_TableName;
  if p_DateField <> '' then begin
    oraTargetQ.SQL.Add('where ' + p_DateField + ' between :last_refreshed_date and :closed_date');
    oraTargetQ.DeclareVariable('last_refreshed_date', otDate);
    oraTargetQ.SetVariable('last_refreshed_date', dateLastRefreshed.Date);
    oraTargetQ.DeclareVariable('closed_date', otDate);
    oraTargetQ.SetVariable('closed_date', dateClosed.Date);
  end;
  oraTargetQ.Execute;
  oraTargetQ.DeleteVariables;
end;

procedure TfmMain.InsertIntoTarget(p_TableName, p_DateField: string);
var
  i: integer;
  fn, vn: string;
  q_DDL: TOracleQuery;
  ts: TDateTime;
  f_list, p_list: TStringList;
begin
  Status.Panels[1].Text := 'Inserting into ' + p_TableName + '...';
  Application.ProcessMessages;

  oraTargetQ.SQL.Text := 'select * from ' + p_TableName + ' where 1=0';
  oraTargetQ.DeleteVariables;
  oraTargetQ.Execute;
  if oraTargetQ.FieldCount < oraSourceQ.FieldCount then
    q_DDL := oraTargetQ
  else
    q_DDL := oraSourceQ;

  f_list := TStringList.Create;
  p_list := TStringList.Create;
  try
    for i  := 0 to q_DDL.FieldCount - 1 do begin
      vn := q_DDL.FieldName(i);
      if UpperCase(vn) <> 'COMMENT' then begin
        fn := vn;
        if q_DDL.FieldType(i) <> otTimestamp then begin
          f_list.Add(fn);
          p_list.Add(':' + vn);
          oraTargetQ.DeclareVariable( vn, oraSourceQ.FieldType(i) );
        end;
      end;
    end;

    oraTargetQ.SQL.Text := 'insert into ' + p_TableName + '(' + f_list.CommaText + ') ' +
                           'values (' + p_list.CommaText + ')';
  finally
    f_list.Free;
    p_list.Free;
  end;

  if p_DateField <> '' then begin
    oraSourceQ.Close;
    oraSourceQ.SQL.Add('where ' + p_DateField + ' between :last_refreshed_date and :closed_date');
    oraSourceQ.DeclareVariable('last_refreshed_date', otDate);
    oraSourceQ.SetVariable('last_refreshed_date', dateLastRefreshed.Date);
    oraSourceQ.DeclareVariable('closed_date', otDate);
    oraSourceQ.SetVariable('closed_date', dateClosed.Date);
    oraSourceQ.Execute;
  end;
  // Передача данных из oraSourceQ в oraTargetQ
  FRowsInserted := 0;
  while not oraSourceQ.Eof do begin
    for i := 0 to oraTargetQ.VariableCount - 1 do begin
      fn := Copy( oraTargetQ.VariableName(i), 2, 255 );
      {if oraSourceQ.FieldType(fn) = otTimestamp then begin
        ts := oraSourceQ.Field(fn);
        //oraTargetQ.SetComplexVariable(fn, ts); не работает с типом Timestamp
        oraTargetQ.SetVariable(i, ts);
      end
      else}
      oraTargetQ.SetVariable(i, oraSourceQ.Field(fn));
    end;
    oraTargetQ.Execute;
    Inc(FRowsInserted);
    oraSourceQ.Next;
    if (oraSourceQ.RowCount mod 1000 = 0)
       or
       (oraSourceQ.Eof)
    then begin
      Status.Panels[2].Text := IntTostr(oraSourceQ.RowCount) + ' records have been inserted';
      Application.ProcessMessages;
    end;
  end;
  oraTarget.Commit;
end;

procedure TfmMain.FetchClosedDateFromSource;
begin
  try
    oraSourceQ.Close;
    oraSourceQ.DeleteVariables;
    oraSourceQ.SQL.Text := 'select * from nrsettings.st_settings';
    oraSourceQ.SQL.Add( 'where sysdate between start_date and end_date and param_name = ''PAYPAL.CLOSED_DATE''');
    oraSourceQ.Execute;

    dateClosed.Date := oraSourceQ.Field('DATE_VALUE');
  except
    on E: Exception do
      Log(E.Message + ' on ' + oraSourceQ.SQL.Text);
  end;
end;

const
  ncTarget = $A0E0F0;
  ncSource = $C0A090;

function TfmMain.AppendSchema(p_TableName: string; p_IsSource: boolean): string;
begin

end;

procedure TfmMain.chbAutoRefreshClick(Sender: TObject);
begin
  tmrRefresh.Enabled := chbAutoRefresh.Checked;
  if chbAutoRefresh.Checked then begin
    Log('Auto-refresh is enabled and will be checking source mart logs every ' + IntToStr(tmrRefresh.Interval div 1000) + ' seconds' );
    FRefreshId := FetchLatestRefreshId(false);
    Log('The latest RECORD_ID in source is ' + IntToStr(FRefreshId));
  end
  else
    Log('Auto-refresh is disabled');
end;

procedure TfmMain.CompareStructure(p_Source, p_Target: TGraphNode);
var
  i: integer;
  v_SourceTable, v_TargetTable: string;
begin
   p_Source.Brush.Color := ncSource;
   v_SourceTable := p_Source.Text;
   oraSourceQ.SQL.Text := 'select * from ' + v_SourceTable + ' where 1=0';
   oraSourceQ.DeleteVariables;
   oraSourceQ.Execute;

   v_TargetTable := p_Target.Text;
   oraTargetQ.SQL.Text := 'select * from ' + v_TargetTable + ' where 1=0';
   oraTargetQ.DeleteVariables;
   oraTargetQ.Execute;
   p_Target.Hint := '';
   if oraSourceQ.FieldCount = oraTargetQ.FieldCount then
     p_Target.Brush.Color := ncSource
   else begin
     p_Target.Brush.Color := ncTarget;
     p_Target.Hint := Format('Fields in source: %d'+ #13#10 + 'Fields in target: %d',
                              [oraSourceQ.FieldCount, oraTargetQ.FieldCount]);
   end;
end;

procedure TfmMain.CompareStructures;
var
  i: integer;
  v_Node, v_SourceNode: TGraphNode;
begin
  for i := 0 to RefreshGraph.ObjectsCount() - 1 do
    if RefreshGraph.Objects[i] is TGraphNode then begin
      v_Node := TGraphNode( RefreshGraph.Objects[i] );
      if v_Node.LinkInputCount > 0 then begin
        v_SourceNode := TGraphNode( v_Node.LinkInputs[0].Source );
        CompareStructure(v_SourceNode, v_Node);
      end;
    end;

end;



end.
