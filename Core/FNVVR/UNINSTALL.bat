@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_FNVVR.ps1" %*
exit /b %ERRORLEVEL%
