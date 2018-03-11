PROMPT starting gen_ddl.sql ...
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
SET VERIFY OFF
SET FEEDBACK OFF
SET HEADING OFF
SET LONG 1000000 pages 50000 lines 30000
SET LONGCHUNKSIZE 200000
SET LINESIZE 30000

rem SET TERMOUT OFF
SET TRIMSPOOL ON

set embedded on
rem column text format a24999 word_wrapped
rem SHOW linesize

DEFINE base_dir=&1
DEFINE ddl_out_dir=&2
DEFINE gen_sql_dir=&base_dir/scripts/gen_scripts
DEFINE log_file=&base_dir/gen_ddl.log


-- init loging
SPOOL &log_file 
PROMPT ========================================================================
PROMPT Script gen_ddl.sql started
PROMPT ========================================================================
PROMPT 
PROMPT "base directory  = &base_dir"
PROMPT "gen scripts dir = &gen_sql_dir"
PROMPT "objects ddl dir = &ddl_out_dir"
PROMPT "log file name   = &log_file"
PROMPT

-- verify if mandatory ddl objects exists before calling them..
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PROMPT  (1.1) "verify if required objects exists"
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

COLUMN check_exists NEW_VALUE l_exists_text
COLUMN deploy_sql   NEW_VALUE l_deploy_script

spool off
set termout off
select
    case when gen_obj_count <> 5 
        then 'Required schema objects not found and will be installed.'
        else 'Required objects already exists.'
    end as check_exists, 
    case when gen_obj_count <> 5 
        then 'scripts/deploy_gen_ddl.sql'
        else 'scripts/gen_scripts/dummy.ddl'
    end as deploy_sql
from
    (select count(*) as gen_obj_count from all_objects o
     where owner = sys_context ('userenv', 'current_schema')
     and o.object_name in ('UTL_GEN_IGNORE', 'UTL_GEN_SOURCE_OT', 'UTL_GEN_SOURCE_TT', 'UTL_GEN_DDL_FT')) gc;

set termout on
SPOOL &log_file APPEND

PROMPT
PROMPT &l_exists_text
PROMPT

-- if not exists create objects for generation otherwise run dummy.sql
@@&l_deploy_script scripts/utl_gen_obj

-- verify gen ddl version
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PROMPT  (1.2) "verify installed gen_ddl version"
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DEFINE gen_ddl_ver = "1.0.0"
COLUMN check_ver  NEW_VALUE l_version_text
COLUMN update_sql NEW_VALUE l_update_script

spool off
set termout off
select
    case when gen_ddl_version <> '&gen_ddl_ver' 
        then 'Installed ('||gen_ddl_version||') and script (&gen_ddl_ver) versions not match. Schema objects will be updated.'
        else 'Installed and script versions are same: &gen_ddl_ver'
    end as check_ver, 
    case when gen_ddl_version <> '&gen_ddl_ver' 
        then 'scripts/update_gen_ddl.sql'
        else 'scripts/gen_scripts/dummy.ddl'
    end as update_sql
from
    (select 
        regexp_substr(min(comments), 'gen_ddl.version=(\d+\.\d+\.\d+)', 1, 1, null, 1) gen_ddl_version
    from user_tab_comments
    where table_name = 'UTL_GEN_IGNORE');

set termout on
SPOOL &log_file APPEND
     
PROMPT
PROMPT &l_version_text
PROMPT

-- if versions not match run update script otherwise run dummy.sql
@@&l_update_script

PROMPT
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PROMPT  (2) Generate DDL extraction scripts for each object type
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PROMPT


@@&base_dir/scripts/create_gen_scripts.sql &ddl_out_dir &gen_sql_dir

SPOOL off
set termout on
SPOOL &log_file APPEND
PROMPT
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PROMPT  (3) Extract each object DDL into db folder (&ddl_out_dir)
PROMPT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PROMPT
set termout off

-- spool on/off used to print proggress to console

--packages
SET TERMOUT ON
PROMPT extract PACKAGES ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/packages.sql
SPOOL off

--procedures
SET TERMOUT ON
PROMPT extract PROCEDURES ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/procedures.sql
SPOOL off

--functions
SET TERMOUT ON
PROMPT extract FUNCTIONS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/functions.sql
SPOOL off

--views
SET TERMOUT ON
PROMPT extract VIEWS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/views.sql
SPOOL off

--synonyms
SET TERMOUT ON
PROMPT extract SYNONYMS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/synonyms.sql
SPOOL off

--types
SET TERMOUT ON
PROMPT extract TYPES ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/types.sql
SPOOL off

--sequences
SET TERMOUT ON
PROMPT extract SEQUENCES ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/sequences.sql
SPOOL off

--tables
SET TERMOUT ON
PROMPT extract TABLES ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/tables.sql
SPOOL off

--triggers
SET TERMOUT ON
PROMPT extract TRIGGERS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/triggers.sql
SPOOL off

--jobs
SET TERMOUT ON
PROMPT extract JOBS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/jobs.sql
SPOOL off

--dblinks
SET TERMOUT ON
PROMPT extract DBLINKS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/dblinks.sql
SPOOL off

--mviews
SET TERMOUT ON
PROMPT extract MVIEWS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/mviews.sql
SPOOL off

--grants
SET TERMOUT ON
PROMPT extract GRANTS ddl
SET TERMOUT OFF
SPOOL &log_file APPEND
@@&gen_sql_dir/grants.sql
SPOOL off

SPOOL &log_file APPEND
PROMPT
PROMPT ========================================================================
PROMPT Script gen_ddl.sql completed
PROMPT ========================================================================
PROMPT


SPOOL OFF

EXIT
