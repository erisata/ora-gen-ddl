
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

## Generate only DDL

Linux terminal (run from ora-gen-ddl directory): 
```
./run_gen_ddl.sh owner/psw@db_name /home/some-user/code/someproject-db/SCHEMA_NAME
```


