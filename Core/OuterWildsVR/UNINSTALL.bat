@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_NOMAIVR.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%
