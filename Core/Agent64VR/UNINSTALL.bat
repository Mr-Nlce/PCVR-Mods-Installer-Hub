@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Agent64VR.ps1" %*
exit /b %ERRORLEVEL%
