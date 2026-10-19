@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_ProjectZomboidVR.ps1" %*
exit /b %ERRORLEVEL%
