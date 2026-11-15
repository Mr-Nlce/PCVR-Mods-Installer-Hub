@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-TTWVR.ps1"
set "result=%ERRORLEVEL%"
if not "%result%"=="0" pause
exit /b %result%
