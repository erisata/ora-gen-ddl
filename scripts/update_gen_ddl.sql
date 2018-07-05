PROMPT ====================================================
PROMPT "Update/upgrade DDL extraction objects"
PROMPT ====================================================

-- get path parameter if provided, else use default
column 1 new_value 1 noprint
select '' "1" from dual where rownum = 0;
define sql_path = &1 "utl_gen_obj"

PROMPT "sql_path=&sql_path"
PROMPT

PROMPT "Backup UTL_GEN_IGNORE table data"
begin
    execute immediate 'create table UTL_GEN_IGN_'||to_char(sysdate, 'YYYYMMDD')||' as select * from UTL_GEN_IGNORE';
    execute immediate 'drop table UTL_GEN_IGNORE';
end;
/


PROMPT "Creating table UTL_GEN_IGNORE"
@@&sql_path/UTL_GEN_IGNORE.tbl 

PROMPT "Restore UTL_GEN_IGNORE table data"
begin
    execute immediate 'insert into UTL_GEN_IGNORE select * from UTL_GEN_IGN_'||to_char(sysdate, 'YYYYMMDD');
    commit;
    
    --execute immediate 'drop table UTL_GEN_IGN_'||to_char(sysdate, 'YYYYMMDD');
end;
/

PROMPT "Creating type UTL_GEN_SOURCE_OT"
@@&sql_path/UTL_GEN_SOURCE_OT.tps
@@&sql_path/UTL_GEN_SOURCE_OT.tpb

PROMPT "Creating table type UTL_GEN_SOURCE_TT"
@@&sql_path/UTL_GEN_SOURCE_TT.tps

PROMPT "Creating function UTL_GEN_DDL_FT"
@@&sql_path/UTL_GEN_DDL_FT.fnc

PROMPT "Create table comment with version"
COMMENT ON TABLE UTL_GEN_IGNORE IS 'Objects to be excluded from DDL generation. This table comment also holds version checked on script execution [utl_gen_ddl.version=1.0.1]';

SHOW ERRORS;