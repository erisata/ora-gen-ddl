
  CREATE OR REPLACE TYPE "UTL_GEN_SOURCE_OT" force
AS OBJECT
(
   object_name VARCHAR2 (500),
   object_type VARCHAR2 (30),
   orig_schema VARCHAR2 (30),
   ret_schema  VARCHAR2 (30),
   ret_ddl     CLOB,

   constructor FUNCTION utl_gen_source_ot RETURN self AS result
 )
/

