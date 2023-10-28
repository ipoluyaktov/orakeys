object fmMain: TfmMain
  Left = 0
  Top = 0
  Caption = 'Orakeys'
  ClientHeight = 665
  ClientWidth = 823
  Color = clInactiveCaption
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  DesignSize = (
    823
    665)
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 0
    Top = 548
    Width = 823
    Height = 96
    Align = alBottom
    DataSource = DataSource1
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object Status: TStatusBar
    Left = 0
    Top = 644
    Width = 823
    Height = 21
    Panels = <
      item
        Width = 300
      end
      item
        Width = 250
      end
      item
        Width = 50
      end>
  end
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 823
    Height = 605
    ActivePage = tsDataRefresh
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
    OnChange = PageControlChange
    object tsTables: TTabSheet
      Caption = 'Tables'
      object TableGraph: TSimpleGraph
        Left = 0
        Top = 0
        Width = 815
        Height = 577
        Align = alClient
        Color = clBtnFace
        ParentColor = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnObjectContextPopup = TableGraphObjectContextPopup
        OnGraphChange = TableGraphGraphChange
        OnInfoTip = TableGraphInfoTip
      end
    end
    object tsJobs: TTabSheet
      Caption = 'Jobs'
      ImageIndex = 1
      object JobGraph: TSimpleGraph
        Left = 0
        Top = 0
        Width = 815
        Height = 577
        Align = alClient
        Color = clSkyBlue
        ParentColor = False
        TabOrder = 0
      end
    end
    object tsDataRefresh: TTabSheet
      Caption = 'Data Refresh'
      ImageIndex = 2
      DesignSize = (
        815
        577)
      object Label1: TLabel
        Left = 208
        Top = 10
        Width = 87
        Height = 18
        Caption = 'Closed date'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9109504
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 476
        Top = 10
        Width = 146
        Height = 18
        Caption = 'Last refreshed date'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9109504
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object RefreshGraph: TSimpleGraph
        Left = 0
        Top = 40
        Width = 817
        Height = 534
        Anchors = [akLeft, akTop, akRight, akBottom]
        Color = clInactiveCaption
        ParentColor = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnObjectContextPopup = RefreshGraphObjectContextPopup
      end
      object chbAutoRefresh: TCheckBox
        Left = 24
        Top = 8
        Width = 137
        Height = 25
        Caption = 'Auto-refresh'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = chbAutoRefreshClick
      end
      object dateClosed: TDateTimePicker
        Left = 301
        Top = 10
        Width = 100
        Height = 24
        Date = 44829.000000000000000000
        Time = 0.818246469905716400
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
      end
      object dateLastRefreshed: TDateTimePicker
        Left = 628
        Top = 10
        Width = 100
        Height = 24
        Date = 44829.000000000000000000
        Time = 0.818246469905716400
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
      end
    end
    object tsLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 3
      DesignSize = (
        815
        577)
      object rchLog: TRichEdit
        Left = 3
        Top = 0
        Width = 809
        Height = 574
        Anchors = [akLeft, akTop, akRight, akBottom]
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Fira Code'
        Font.Style = []
        Lines.Strings = (
          'rchLog')
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
  end
  object DataSource1: TDataSource
    AutoEdit = False
    DataSet = oraDS
    Left = 384
    Top = 520
  end
  object oraTargetQ: TOracleQuery
    SQL.Strings = (
      'select * from all_constraints'
      'where OWNER = '#39'DDS'#39
      'and CONSTRAINT_TYPE = '#39'R'#39)
    Session = oraTarget
    Optimize = False
    Left = 400
    Top = 392
  end
  object oraTarget: TOracleSession
    LogonUsername = 'system'
    LogonPassword = 'Moscow2021'
    LogonDatabase = 'NRD'
    Preferences.ConvertUTF = cuUTF8ToUTF16
    Left = 296
    Top = 392
  end
  object oraDS: TOracleDataSet
    SQL.Strings = (
      'select fk.STATUS as fk_status,'
      '       fk.OWNER || '#39'.'#39' || fk.TABLE_NAME as fk_table_name,'
      '       fk.CONSTRAINT_NAME as fk_name,'
      '       pk.CONSTRAINT_NAME as pk_name,'
      '       pk.OWNER || '#39'.'#39' || pk.TABLE_NAME as pk_table_name'
      '  from all_constraints fk'
      '  left'
      '  join all_constraints pk'
      '    on pk.OWNER = fk.R_OWNER'
      '   and pk.CONSTRAINT_NAME = fk.R_CONSTRAINT_NAME'
      ' where fk.owner = '#39'DDS'#39
      '   and fk.constraint_type = '#39'R'#39)
    Optimize = False
    QBEDefinition.QBEFieldDefs = {
      0500000003000000140000005400410042004C0045005F004E0041004D004500
      0100000000002200000052005F0043004F004E00530054005200410049004E00
      54005F004E0041004D0045000100000000000C00000053005400410054005500
      5300010000000000}
    Session = oraTarget
    Left = 480
    Top = 392
  end
  object TableMenu: TPopupMenu
    Left = 200
    Top = 392
    object RenameNode: TMenuItem
      Caption = 'Rename'
      OnClick = RenameNodeClick
    end
    object CopyNode: TMenuItem
      Caption = 'Copy'
      OnClick = CopyNodeClick
    end
  end
  object TablesMenu: TPopupMenu
    Left = 120
    Top = 392
    object InsertNode: TMenuItem
      Caption = 'Insert Node'
    end
  end
  object oraSource: TOracleSession
    Preferences.ConvertUTF = cuUTF8ToUTF16
    Left = 292
    Top = 321
  end
  object oraSourceQ: TOracleQuery
    Session = oraSource
    ReadBuffer = 100
    Optimize = False
    Left = 396
    Top = 321
  end
  object RefreshMenu: TPopupMenu
    Left = 200
    Top = 480
    object miRefresh: TMenuItem
      Caption = 'Refresh'
      OnClick = miRefreshClick
    end
  end
  object tmrRefresh: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = tmrRefreshTimer
    Left = 148
    Top = 32
  end
end
