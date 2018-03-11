
  CREATE OR REPLACE FUNCTION "UTL_GEN_DDL_FT" (
            p_object_type   varchar2,
            p_object_name   varchar2,
            p_orig_schema   varchar2 default null,
            p_ret_schema    varchar2 default null)
    return utl_gen_source_tt pipelined
is
    pragma autonomous_transaction;

    l_orig_schema   varchar2(30);

    -- setup output record of type :
    out_rec utl_gen_source_ot := utl_gen_source_ot ();

    -- setup handles to be used for setup and fetching metadata information handles are used
    -- to keep track of the different objects (DDL) we will be referencing in the PL/SQL code
    hOpenOrig     NUMBER;
    hModifyOrig   NUMBER; -- pls_integer ?
    fetch_ddl     CLOB;
BEGIN

    -- special formated DDL extraction for JOBS
    if p_object_type in ( 'PROCOBJ', 'JOB' ) then

        for c_obj in (
            select j.*,
                'to_timestamp('''||to_char(start_date, 'YYYY-MM-DD')||''', ''YYYY-MM-DD'')' job_start_date
            from user_scheduler_jobs j
            where job_name = p_object_name )
        loop
            fetch_ddl := 'BEGIN'||chr(10)||
                '  dbms_scheduler.create_job('||chr(10)||
                '    job_name => '''||c_obj.job_name||''','||chr(10)||
                '    job_type => '''||c_obj.job_type||''','||chr(10)||
                '    job_action => '''||c_obj.job_action||''','||chr(10)||
                '    start_date => '||c_obj.job_start_date||','||chr(10)||
                '    repeat_interval => '''||c_obj.repeat_interval||''','||chr(10)||
                '    enabled => '||c_obj.enabled||','||chr(10)||
                '    auto_drop => '||c_obj.auto_drop||','||chr(10)||
                '    comments => '''||c_obj.comments||''');'||chr(10)||
                'END;'||chr(10)||'/';

        end loop;

    -- default case DDL extraction using DBMS_METADATA
    else

        --== 1) prepare for DDL extraction, setup required params
        -- use current schema name if null
        l_orig_schema := nvl(p_orig_schema, sys_context ('userenv', 'current_schema'));


        hopenorig := dbms_metadata.open (p_object_type);
        dbms_metadata.set_filter (hopenorig, 'SCHEMA', l_orig_schema);
        dbms_metadata.set_filter (hopenorig, 'NAME', p_object_name);

        --  Modify the transformation of "orig_schema" to take on ownership of "ret_schema"
        --  If we didn't do this, when we compared the original to the comp objects there
        --  would always be a difference because the schema_owner is in the DDL generated
        if p_object_type not in ( 'PROCOBJ' )  then
            hmodifyorig := dbms_metadata.add_transform (hopenorig, 'MODIFY');
            dbms_metadata.set_remap_param (hmodifyorig, 'REMAP_SCHEMA', l_orig_schema, p_ret_schema);
        end if;

        -- This states to create DDL instead of XML
        hModifyOrig := DBMS_METADATA.add_transform (hOpenOrig, 'DDL');

        --== 2) Set extracted DDL transforming, formating and other parameters
        dbms_metadata.set_transform_param (hmodifyorig, 'PRETTY', true);
        dbms_metadata.set_transform_param (hmodifyorig, 'SQLTERMINATOR', true);

        -- Strip off Attributes not concerned with in DDL. If you are concerned with
        -- TABLESPACE, STORAGE, OR SEGMENT information just COMMENT OUT these lines.
        if p_object_type in ( 'TABLE', 'INDEX' )  then
            if p_object_type in ('TABLE') then
                dbms_metadata.set_transform_param (hmodifyorig, 'CONSTRAINTS_AS_ALTER', true);
                dbms_metadata.set_transform_param (hmodifyorig, 'CONSTRAINTS', true);
            end if;
            dbms_metadata.set_transform_param (hmodifyorig, 'TABLESPACE', false);
            dbms_metadata.set_transform_param (hmodifyorig, 'STORAGE', false);
            dbms_metadata.set_transform_param (hmodifyorig, 'SEGMENT_ATTRIBUTES', false);
            if  (dbms_db_version.version > 10) then
                dbms_metadata.set_transform_param (hmodifyorig, 'PARTITIONING', false);
            end if;
        end if;

        --== 3) Extracting object DDL as clob
        fetch_ddl := DBMS_METADATA.fetch_clob (hOpenOrig);

        --== 4) Additional custom post procesing for some object types

        -- 4.1) For TABLE add USING INDEX clause if it not exists
        if p_object_type = 'TABLE' then
            -- for Primary key constraint
            fetch_ddl := regexp_replace(
                            fetch_ddl,
                            'PRIMARY KEY \((("\w+",?\s?)+)\) ENABLE',
                            'PRIMARY KEY (\1)'||chr(10)||'  USING INDEX  ENABLE');
            -- for Unique key constraint
            fetch_ddl := regexp_replace(
                            fetch_ddl,
                            'UNIQUE \("(.*)"\) ENABLE',
                            'UNIQUE ("\1")'||chr(10)||'  USING INDEX  ENABLE');

        -- 4.2) for VIEW wrap colum names
        elsif p_object_type = 'VIEW' then
            declare
                l_start_pos number;
                l_end_pos number;
                l_size integer;
                l_cols varchar2(10000);
            begin
                l_size := dbms_lob.getlength (fetch_ddl);
                l_start_pos := dbms_lob.instr(fetch_ddl, 'CREATE OR REPLACE', 1);
                l_end_pos := dbms_lob.instr(fetch_ddl, chr(10), l_start_pos);

                l_cols := dbms_lob.substr (fetch_ddl, l_end_pos-l_start_pos,  l_start_pos);
                l_cols := regexp_replace(
                            l_cols,
                            '("\w+")',
                            chr(10)||'    \1');

                fetch_ddl := to_clob(
                    dbms_lob.substr (fetch_ddl, l_start_pos-1,  1)||
                    l_cols ||
                    dbms_lob.substr (fetch_ddl, l_size-l_end_pos,  l_end_pos) );
            end;

        end if;

        -- Cleanup and release the handles
        DBMS_METADATA.close (hOpenOrig);

    end if;  -- spec object types;

    -- Now simply output row
    out_rec.object_name := p_object_name;
    out_rec.object_type := p_object_type;
    out_rec.orig_schema := l_orig_schema;
    out_rec.ret_schema  := p_ret_schema;
    out_rec.ret_ddl     := fetch_ddl;

    PIPE ROW (out_rec);

   return;
END utl_gen_ddl_ft;
/

