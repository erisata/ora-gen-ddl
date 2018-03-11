PROMPT ====================================================
PROMPT Creating objects for DDL extraction
PROMPT ====================================================

-- get path parameter if provided, else use default
column 1 new_value 1 noprint
select '' "1" from dual where rownum = 0;
define sql_path = &1 "utl_gen_obj"

PROMPT "sql_path=&sql_path"
PROMPT

PROMPT "Creating table UTL_GEN_IGNORE"
@@&sql_path/UTL_GEN_IGNORE.tbl 

PROMPT "Creating type UTL_GEN_SOURCE_OT"
@@&sql_path/UTL_GEN_SOURCE_OT.tps
@@&sql_path/UTL_GEN_SOURCE_OT.tpb

PROMPT "Creating table type UTL_GEN_SOURCE_TT"
@@&sql_path/UTL_GEN_SOURCE_TT.tps

PROMPT "Creating function UTL_GEN_DDL_FT"
@@&sql_path/UTL_GEN_DDL_FT.fnc

SHOW ERRORS;