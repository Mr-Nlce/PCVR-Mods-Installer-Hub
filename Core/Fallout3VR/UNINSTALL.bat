@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Fallout3VR.ps1" %*
exit /b %ERRORLEVEL%
