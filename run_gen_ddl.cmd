@echo off
rem define parameters
:parameters

rem base scripts directory
set base_dir=%CD%

rem folder to store extracted ddl files
set dir_db=%base_dir%\db

rem source code folder (to compare against)
set dir_git=%1

rem db database connection url
set db_url=%2

echo.
echo base dir: %base_dir%
echo db dir: %dir_db%
echo git dir: %dir_git%
echo db_url: %db_url%
echo
echo.


:delete        
echo.
echo -----------------------------------------
echo Clearing DB ddl folder 
echo -----------------------------------------
echo. 
rem clearing backup folder
rd /s /q %dir_db%

rem creating subdirectories by object type
md "%dir_db%\sequences" 
md "%dir_db%\tables"
md "%dir_db%\packages"
md "%dir_db%\procedures"
md "%dir_db%\functions"
md "%dir_db%\types" 
md "%dir_db%\views" 
md "%dir_db%\triggers" 
md "%dir_db%\grants" 
md "%dir_db%\synonyms" 
md "%dir_db%\jobs" 
md "%dir_db%\dblinks" 
md "%dir_db%\mviews" 

rem create folder for generated ddl extraction scripts (if not exist)
if not exist "%base_dir%\scripts\gen_scripts" md "%base_dir%\scripts\gen_scripts"
rem clearing generated scripts; files other than .sql type are left intact
del /f /q %base_dir%\scripts\gen_scripts\*.sql

:backup
echo.
echo -----------------------------------------
echo Start main SQLPlus script
echo -----------------------------------------
echo. 


rem Run sqlplus script
sqlplus %db_url% @%base_dir%\scripts\gen_ddl.sql  %base_dir% %dir_db% 

rem pause
 
if not defined db_url goto exit 
rem cls
echo.
echo -----------------------------------------  
echo  Starting file compare.....
echo -----------------------------------------
echo. 

:compare
rem /r compares all files in all subfolders
rem /e enables you to close WinMerge with a single Esc  key press
rem /x closes WinMerge (after displaying an information dialog) when you start a comparison of identical files.
rem /s limits WinMerge windows to a single instance
rem /dl specifies a description in the left side title bar
rem /dr specifies a description in the right side title bar
rem outputpath  Specifies an optional output folder where you want merged result files to be saved. 
start WinMergeU /r /e /f "*.tbl *.vw *.pks *.pkb *.tps *.tpb *.syn *.trg *.fnc *.prc *.seq *.job *.dbl *.mv" /x /s /dl "DB" /dr "Git" %dir_db% %dir_git%

echo.
echo -----------------------------------------  
echo  File comparing done
echo -----------------------------------------
echo. 
echo. 
echo OPERATION COMPLETED
echo.
rem pause
:exit
rem exit /b

