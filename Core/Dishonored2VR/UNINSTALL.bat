@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Dishonored2VR.ps1" %*
exit /b %ERRORLEVEL%
