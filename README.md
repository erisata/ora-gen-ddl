
# Oracle DDL generator 

Exports oracle schema to set of ddl scripts and compares to
files stored in your version control system (i.e. GIT).

## Prerequisites

 * SQL*Plus is needed to run installation scripts from shell
 * WinMerge - for file comaprison (http://winmerge.org/) 

## Usage

Windows CLI:

~~~~
run_gen_ddl.cmd C:\code\git\someproject-db\SCHEMA_NAME owner/psw@db_name
~~~~

