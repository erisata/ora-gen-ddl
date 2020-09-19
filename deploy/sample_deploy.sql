-- this is sample install script file used as template and stored in GIT
-- make a copy, then rename file to "deploy.sql" and modify 
--
set serveroutput on size 1000000
set heading off
set verify off
set feedback on

spool deploy.log APPEND

WHENEVER SQLERROR CONTINUE

prompt
prompt ==============================
prompt Start install script 
prompt ==============================


select to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS')  script_exec_time from dual;

prompt
prompt *** Runing SCHEMA objects DDL scripts one-by-one ***
prompt -----------------------------------------

-- below should be the list of individual script files  in the form :
-- @@run C:\Users\username\CODE\project-db\schema\packages\UTL_LOG.pkb 
-- 
-- if execution should abort on error add "WHENEVER SQLERROR EXIT" command
-- 



spool off
exit
