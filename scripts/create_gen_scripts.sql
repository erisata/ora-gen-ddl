SET TERMOUT OFF
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED
SET echo OFF
SET FEEDBACK OFF
SET NEWPAGE NONE
SET TRIMSPOOL ON

DEFINE folder= &1
DEFINE gen_scripts_dir= &2

-------------------------------------------------------------------------------
--=== TABLES
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate TABLES script
SET TERMOUT OFF
SPOOL &gen_scripts_dir/tables.sql
DECLARE
   l_obj_type VARCHAR2(10) :='TABLE';
   l_obj_str VARCHAR2(4) :='tbl ';
   l_folder VARCHAR2(20) := 'tables';  
   --
   l_col_text_fmt VARCHAR2(40) := 'column text for a24900'||CHR(10); -- word_wrapped
   l_cr_sl VARCHAR2(50) := '||CHR(10)||''/'' '; 
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
prompt
prompt Performing '||l_folder||' backup
prompt =================================
prompt

EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''PRETTY'', TRUE );
EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''CONSTRAINTS_AS_ALTER'', TRUE );
EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''CONSTRAINTS'', TRUE );
EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''STORAGE'', false );
EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''SQLTERMINATOR'', TRUE );
EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''SEGMENT_ATTRIBUTES'', false);
EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''TABLESPACE'', false );

'|| l_col_text_fmt
);

  FOR i IN (
    SELECT object_name 
      FROM user_objects o
     WHERE UPPER(object_type)=UPPER(l_obj_type)
       --ignore some system tables (comment if needed)
        AND SUBSTR(UPPER(object_name),1,3) NOT IN ('Q##','BIN','SYS','AQ$')
        AND UPPER(object_name) NOT LIKE 'QT%'
        AND not exists (
                select 1 from utl_gen_ignore i
                where o.object_type = i.oig_type
                and o.object_name like i.oig_name  ) 
    ORDER BY 1
  ) LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL'||l_cr_sl||' text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL off');


    --== indexes
    FOR j IN (
        SELECT index_name AS object_name
        FROM user_indexes i
        WHERE 1 = 1
            AND NOT EXISTS (
                SELECT 1 FROM user_constraints c
                WHERE i.index_name = c.constraint_name
                AND c.table_name = i.object_name )
          AND i.table_name = i.object_name
          AND i.index_type <> 'LOB'
        order by 1
        ) 
    LOOP
  
    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||' APPEND'||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft(''INDEX'','''||j.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL OFF');
  
    END LOOP;


--comments
  dbms_output.put_line('
SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name || '.' ||  l_obj_str || ' APPEND
SELECT ''COMMENT ON TABLE '' || table_name || '' IS '' || '''''''' || comments || '''''';''||CHR(10) ||''/'' text
  FROM user_tab_comments
 WHERE 1 = 1
   AND comments IS NOT NULL
   AND table_type = ''TABLE''
   AND UPPER(table_name)=UPPER(''' || i.object_name ||''')
UNION ALL
SELECT ''COMMENT ON COLUMN '' || table_name || ''.'' || column_name || '' IS '' || '''''''' ||
       comments || '''''';''||CHR(10) ||''/'' text
  FROM user_col_comments
 WHERE 1 = 1
   AND comments IS NOT NULL
   AND UPPER(table_name)=UPPER(''' || i.object_name ||''')
 ORDER BY 1
;

SPOOL OFF');

  END LOOP;       
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== VIEWS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate VIEWS script
SET TERMOUT OFF
SPOOL &gen_scripts_dir/views.sql
DECLARE
   l_obj_type VARCHAR2(10) :='VIEW';
   l_obj_str VARCHAR2(3) :='vw';
   l_folder VARCHAR2(20) := 'VIEWS';
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT

rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''PRETTY'', TRUE );
rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''CONSTRAINTS_AS_ALTER'', TRUE );
rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''CONSTRAINTS'', TRUE );
rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''STORAGE'', false );
rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''SQLTERMINATOR'', TRUE );
rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''SEGMENT_ATTRIBUTES'', false);
rem EXECUTE dbms_metadata.set_transform_param( DBMS_METADATA.SESSION_TRANSFORM, ''TABLESPACE'', false );

');



  FOR i IN (
    SELECT object_name, object_type FROM user_objects o
        WHERE UPPER(object_type) LIKE UPPER('%'||l_obj_type||'%')
        --ignore 
        AND SUBSTR(UPPER(object_name),1,3) NOT IN ('AQ$')
        AND not exists (
                select 1 from utl_gen_ignore i
                where o.object_type = i.oig_type
                and o.object_name like i.oig_name  ) 
                
    ) 
  LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        l_add_line_sl||
        'SPOOL off');


    --== view comments
    dbms_output.put_line(
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name || '.' ||  l_obj_str || ' APPEND '||chr(10)||
'SELECT ''COMMENT ON TABLE '' || table_name || '' IS '' || '''''''' || comments || '''''';''||CHR(10) ||''/'' text
  FROM user_tab_comments
 WHERE 1 = 1
   AND comments IS NOT NULL
   AND table_type = ''VIEW''
   AND UPPER(table_name)=UPPER(''' || i.object_name ||''')
UNION ALL
SELECT ''COMMENT ON COLUMN '' || table_name || ''.'' || column_name || '' IS '' || '''''''' ||
       comments || '''''';''||CHR(10) ||''/'' text
  FROM user_col_comments
 WHERE 1 = 1
   AND comments IS NOT NULL
   AND UPPER(table_name)=UPPER(''' || i.object_name ||''')
;
SPOOL OFF'||chr(10) );


  END LOOP;       
END;
/
SPOOL OFF



-------------------------------------------------------------------------------
--=== SEQUENCES
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate SEQUENCES script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/sequences.sql
DECLARE
   l_obj_type VARCHAR2(10) :='SEQUENCE';
   l_obj_str VARCHAR2(3) :='seq';
   l_folder VARCHAR2(20) := 'sequences';
   l_start_with VARCHAR2(10) := '1'; --'last_number'; -- use last_number if actual values are required  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10);   
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT');

  FOR i IN (
    SELECT object_name FROM user_objects o
     WHERE UPPER(object_type)=UPPER(l_obj_type)
      AND not exists (
        select 1 from utl_gen_ignore i
        where o.object_type = i.oig_type
        and o.object_name like i.oig_name  ) 
  ) LOOP

dbms_output.put_line('
SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str|| CHR(10)||
'
SELECT ''CREATE SEQUENCE '' || A.sequence_name || '' START WITH '' ||'|| l_start_with ||'|| CHR(10)||''/'' 
  FROM user_sequences A WHERE UPPER(sequence_name) = UPPER('''||i.object_name||''');

SPOOL OFF' ||CHR(10) );
  END LOOP;       
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== SYNONYMS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate SYNONYMS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/synonyms.sql
DECLARE
   l_obj_type VARCHAR2(10) :='SYNONYM';
   l_obj_str VARCHAR2(3) :='syn';
   l_folder VARCHAR2(20) := 'synonyms';  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
       dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT

');

  FOR i IN (
        SELECT object_name 
        FROM user_objects o
        WHERE UPPER(object_type)=UPPER(l_obj_type)
        AND not exists (
                select 1 from utl_gen_ignore i
                where o.object_type = i.oig_type
                and o.object_name like i.oig_name  )               
  ) LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,USER));'||CHR(10)||
        --l_add_line_sl||
        'SPOOL off');  
  
  END LOOP;        
END;
/
SPOOL OFF



-------------------------------------------------------------------------------
--=== PROCEDURES
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate PROCEDURES script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/procedures.sql
DECLARE
   l_obj_type VARCHAR2(10) :='PROCEDURE';
   l_obj_str VARCHAR2(5) :='prc';
   l_folder VARCHAR2(20) := 'procedures';  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT
');

  FOR i IN (
        SELECT object_name 
        FROM user_objects o
        WHERE UPPER(object_type)=UPPER(l_obj_type)
        and 1=2
        AND not exists (
                select 1 from utl_gen_ignore i
                where o.object_type = i.oig_type
                and o.object_name like i.oig_name  )               
  ) LOOP  

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL off');  
  
  END LOOP;       
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== FUNCTIONS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate FUNCTIONS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/functions.sql
DECLARE
   l_obj_type VARCHAR2(10) :='FUNCTION';
   l_obj_str VARCHAR2(5) :='fnc ';
   l_folder VARCHAR2(20) := 'FUNCTIONS';  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT
');

  FOR i IN (
        SELECT object_name 
        FROM user_objects o
        WHERE UPPER(object_type)=UPPER(l_obj_type)
        AND not exists (
                select 1 from utl_gen_ignore i
                where o.object_type = i.oig_type
                and o.object_name like i.oig_name  )               
  ) LOOP  

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL off');    
  

  END LOOP;       
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== TRIGGERS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate TRIGGERS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/triggers.sql
DECLARE
   l_obj_type VARCHAR2(10) :='TRIGGER';
   l_obj_str VARCHAR2(3) :='trg';
   l_folder VARCHAR2(20) := 'TRIGGERS';  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT');

  FOR i IN (SELECT NAME AS object_name
              FROM user_source us 
                   LEFT JOIN RECYCLEBIN bin 
                   ON (us.NAME = bin.object_name AND 
                       us.TYPE = bin.TYPE) 
              WHERE us.TYPE = UPPER(l_obj_type)
              AND bin.OBJECT_NAME IS NULL -- musn`t be in the RecycleBin
              GROUP BY NAME
  ) LOOP

    dbms_output.put_line(
'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str|| CHR(10)||
'SELECT ''CREATE OR REPLACE'' text FROM dual
UNION ALL
SELECT text FROM (SELECT text
FROM user_source us
WHERE UPPER(NAME) = UPPER('''||i.object_name||''')
AND UPPER(TYPE) = UPPER('''||l_obj_type||''')
ORDER BY line ASC)
UNION ALL
SELECT ''/'' text FROM dual;
SPOOL OFF'||CHR(10) );
  END LOOP;       
END;
/
SPOOL OFF



-------------------------------------------------------------------------------
--=== PACKAGES
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate PACKAGES script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/packages.sql
DECLARE
   l_obj_type VARCHAR2(12) :='PACKAGE_SPEC';
   l_obj_type_body VARCHAR2(20) :='PACKAGE BODY';
   l_obj_str VARCHAR2(3) :='pks';
   l_obj_str_body VARCHAR2(3) :='pkb';
   l_folder VARCHAR2(20) := 'packages';  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT

');
--packages
FOR i IN (
SELECT object_name
  FROM user_objects o
  WHERE UPPER(object_type) = 'PACKAGE'
    --ismetam nereikalingus
    AND SUBSTR(UPPER(object_name),1,3) NOT IN ('Q##','RLM','EXF')
    AND not exists (
            select 1 from utl_gen_ignore i
            where o.object_type = i.oig_type
            and o.object_name like i.oig_name  )                      
  ORDER BY object_name
) LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL OFF');  

END LOOP;

  
--packages body
FOR i IN (
    SELECT o.object_name
     FROM user_objects o
     WHERE UPPER(object_type) = UPPER(l_obj_type_body)
       --ismetam nereikalingus
       AND SUBSTR(UPPER(object_name),1,3) NOT IN ('Q##','RLM','EXF')
       AND not exists (
                select 1 from utl_gen_ignore i
                where o.object_type = i.oig_type
                and o.object_name like i.oig_name  )  
    ORDER BY object_name
) LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str_body||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||replace(l_obj_type_body,' ','_')||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL OFF');  

  END LOOP;   
  
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== TYPES
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate TYPES script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/types.sql
DECLARE
   l_obj_type VARCHAR2(10) :='TYPE_SPEC';
   l_obj_type_body VARCHAR2(10) :='TYPE BODY';
   l_obj_str VARCHAR2(3) :='tps';
   l_obj_str_body VARCHAR2(3) :='tpb';
   l_folder VARCHAR2(20) := 'TYPES';  
   l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT
');
--type
  FOR i IN (
    SELECT o.object_name
      FROM user_objects o 
           LEFT JOIN RECYCLEBIN bin 
           ON (o.object_name = bin.object_name AND 
               o.object_type = bin.TYPE) 
      WHERE o.object_type = 'TYPE'
      --ignore
      AND bin.object_name IS NULL -- must not be in the RecycleBin
      AND SUBSTR(UPPER(o.object_name),1,3) NOT IN ('Q##')
      AND UPPER(o.object_name) NOT LIKE 'SYSTP%' -- hard-parsed oracle collection types?
      AND not exists (
            select 1 from utl_gen_ignore i
            where o.object_type = i.oig_type
            and o.object_name like i.oig_name  ) 
      GROUP BY o.object_name
  ) LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL off');  

  END LOOP;

 --type body
 FOR i IN (SELECT NAME AS object_name
              FROM USER_SOURCE us 
                   LEFT JOIN RECYCLEBIN bin 
                   ON (us.NAME = bin.OBJECT_NAME AND 
                       us.TYPE = bin.TYPE) 
              WHERE us.TYPE = UPPER(l_obj_type_body)
              --ignore
              AND bin.OBJECT_NAME IS NULL -- must not be in the RecycleBin
              AND SUBSTR(UPPER(NAME),1,3) NOT IN ('Q##')
			  AND UPPER(NAME) NOT LIKE 'SYSTP%' -- hard-parsed oracle collection types?
              GROUP BY NAME
  ) LOOP

    dbms_output.put_line( 
        'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str_body||CHR(10)||
        'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||replace(l_obj_type_body,' ','_')||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
        --l_add_line_sl||
        'SPOOL off');    

  END LOOP;   
  
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== JOBS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate JOBS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/jobs.sql
DECLARE
    l_obj_type VARCHAR2(10) :='PROCOBJ';
    l_obj_str VARCHAR2(3) :='job';
    l_folder VARCHAR2(20) := 'JOBS';  
    l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT
');
    FOR i IN (
        select object_name, object_type 
        from user_objects o
        where object_type = 'JOB'
        -- filter out ignored objects
        and not exists (
                    select 1 from utl_gen_ignore i
                    where o.object_type = i.oig_type
                    and o.object_name like i.oig_name  )   
        ) 
    LOOP
        -- for every object make ddl generation statement
        dbms_output.put_line( 
            'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
            'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
            --l_add_line_sl||
            'SPOOL off');  
            
    END LOOP;       
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== DBLINKS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate DBLINKS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/dblinks.sql
DECLARE
    l_obj_type VARCHAR2(10) :='DB_LINK';
    l_obj_str VARCHAR2(3) :='dbl';
    l_folder VARCHAR2(20) := 'DBLINKS';  
    l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10); 
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT
');
    FOR i IN (
        select object_name, object_type 
        from user_objects o
        where object_type like  'DATABASE LINK'        
        -- filter out ignored objects
        and not exists (
                    select 1 from utl_gen_ignore i
                    where o.object_type = i.oig_type
                    and o.object_name like i.oig_name  )   
    ) LOOP
        -- for every object add ddl generation command
        dbms_output.put_line( 
            'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
            'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
            l_add_line_sl||
            'SPOOL off');          

    END LOOP;       
END;
/
SPOOL OFF


-------------------------------------------------------------------------------
--=== MATERIALIZED VIEWS
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate MATERIALIZED VIEWS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/mviews.sql
DECLARE
    l_obj_type VARCHAR2(30) :='MATERIALIZED_VIEW';
    l_file_ext VARCHAR2(3) :='mv';
    l_folder VARCHAR2(20) := 'mviews';
    l_add_line_sl VARCHAR2(50) := 'select ''/'' text from dual;'||CHR(10);    
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT
');
    FOR i IN (
        select object_name, object_type 
        from user_objects o
        where object_type = 'MATERIALIZED VIEW'
        -- filter out ignored objects
        and not exists (
                    select 1 from utl_gen_ignore i
                    where o.object_type = i.oig_type
                    and o.object_name like i.oig_name  )   
    ) LOOP
        -- for every object add ddl generation command
        dbms_output.put_line( 
            'SPOOL &folder'||chr(92)||l_folder||chr(92)||i.object_name||'.'||l_obj_str||CHR(10)||
            'SELECT ''DROP MATERIALIZED VIEW  '||i.object_name||';'' text FROM DUAL; '|| CHR(10) );
        dbms_output.put_line(
            'SELECT RET_DDL text FROM TABLE(utl_gen_ddl_ft('''||l_obj_type||''','''||i.object_name||''',NULL,NULL) );'||CHR(10)||
            l_add_line_sl||
            'SPOOL off');          
        
    END LOOP;       
END;
/
SPOOL OFF



-------------------------------------------------------------------------------
-- grants for schema
-------------------------------------------------------------------------------
SET TERMOUT ON
PROMPT generate GRANTS script
SET TERMOUT OFF

SPOOL &gen_scripts_dir/grants.sql
DECLARE
   l_obj_type VARCHAR2(12) :='OBJECT_GRANT';
   l_obj_str VARCHAR2(3) :='sql';
   l_folder VARCHAR2(6) := 'GRANTS';  
BEGIN
    dbms_output.put_line('
PROMPT
PROMPT Performing '||l_folder||' backup
PROMPT =================================
PROMPT');

dbms_output.put_line(
'SPOOL &folder'||chr(92)||l_folder||'\grants_for_schema.'||l_obj_str|| CHR(10)|| 
'SELECT DBMS_METADATA.GET_GRANTED_DDL('''||l_obj_type||''') text FROM dual;
SPOOL OFF' ||CHR(10) 
);   

END;
/

SPOOL OFF


--SET serveroutput OFF
