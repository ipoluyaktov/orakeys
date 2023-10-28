select fk.STATUS as fk_status,
       fk.TABLE_NAME as fk_table_name,
       fk.CONSTRAINT_NAME as fk_name,
       pk.CONSTRAINT_NAME as pk_name,
       pk.TABLE_NAME as pk_table_name
  from all_constraints fk
  left
  join all_constraints pk
    on pk.OWNER = fk.R_OWNER
   and pk.CONSTRAINT_NAME = fk.R_CONSTRAINT_NAME
 where fk.owner = 'DDS'
   and fk.constraint_type = 'R';
   
select *
  from all_cons_columns fk
 where fk.owner = 'DDS'
   and fk.CONSTRAINT_NAME in ('FK_MD_CURRE_REFER430_MD_SECUR', 'PK_MD_SECURITY_S');

select * from dba_users
 where username = 'DMA';
 
create user alpha_test identified by alpha_test;
alter user alpha_test quota unlimited on users;
GRANT CREATE SESSION TO alpha_test;
GRANT CREATE table TO alpha_test;

select *
  from dma.dm_f101_round_f
 where to_date = date '2018-12-31'
   and from_date = add_months(to_date, -6) + 1
   and (turn_deb_total <> 0 or turn_cre_total <> 0);
   
select min(bank_date), max(bank_date)
  from dma.dm_account_turnover_f;
  
select min(on_date),
       max(on_date)
  from dma.dm_balance_f
 --where on_date between date '2019-01-01' and date '2019-01-31'
 --group by on_date
 ;

SELECT count(1) from dm_account_d;
select count(1) from dma.dm_account_turnover_f;
select count(1) from dma.dm_balance_f;

select * from dba_users order by username;
select * from dba_profiles;

ALTER user DMA identified by DMA;

select max(bank_date) from dm_account_turnover_f
 where bank_date between date '2022-09-05' and date '2022-10-04';

select * from dm_balance_f;

select * from nrsettings.st_settings
 where sysdate between start_date and end_date
   and param_name = 'PAYPAL.CLOSED_DATE';
   
select * from nrlogs.vw_lg_data_flow
 where flow_to = 'DMA'
 order by record_id desc;
 
select * from dba_tab_privs
 where table_name = 'ST_SETTINGS';
 
grant select on nrsettings.st_settings to dma;

select record_id, begin_date, end_date, oper_date, oper_date_to from nrlogs.vw_lg_data_flow
 where flow_to = 'DMA' and end_date is not null
 order by record_id desc;

