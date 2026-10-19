@echo off
setlocal
if not exist "%~dp0current\Start KF2-VR.cmd" exit /b 1
if not exist "%~dp0current\app\release.json" exit /b 1
call "%~dp0current\Start KF2-VR.cmd"
exit /b %ERRORLEVEL%
