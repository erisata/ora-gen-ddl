#!/bin/bash

base_dir=`pwd`
db_url=$1
dir_db=$2

echo base dir: $base_dir
echo db_url: $db_url
echo db dir: $dir_db


echo -----------------------------------------
echo Clearing DB ddl folder
echo -----------------------------------------
rm -rf $dir_db/*


echo -----------------------------------------
echo Creating subdirectories by object type
echo -----------------------------------------
mkdir -p $dir_db/dblinks
mkdir -p $dir_db/functions
mkdir -p $dir_db/grants
mkdir -p $dir_db/jobs
mkdir -p $dir_db/mviews
mkdir -p $dir_db/packages
mkdir -p $dir_db/procedures
mkdir -p $dir_db/sequences
mkdir -p $dir_db/synonyms
mkdir -p $dir_db/tables
mkdir -p $dir_db/triggers
mkdir -p $dir_db/types
mkdir -p $dir_db/views

echo -----------------------------------------
echo Start main SQLPlus script
echo -----------------------------------------

sqlplus64 $db_url @$base_dir/scripts/gen_ddl.sql $base_dir $dir_db

echo -----------------------------------------
echo OPERATION COMPLETED
echo -----------------------------------------