@echo off

rem set encoding if needed
set NLS_LANG=LITHUANIAN_LITHUANIA.BLT8MSWIN1257

set /p INST_HOST=  enter database host name:
set /p INST_USR=  enter schema owner:
set /p INST_PSW=  enter psw for (%INST_HOST%.%INST_USR%):
cls


echo. 
echo Run changes deploy script for (%INST_HOST%.%INST_USR%)
echo -----------------------------------------
echo.
rem pause

sqlplus %INST_USR%/%INST_PSW%@%INST_HOST% @deploy.sql


echo.
echo COMPLETED.
echo.
pause
