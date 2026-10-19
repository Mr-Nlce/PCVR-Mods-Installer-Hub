@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_KillingFloor2VR.ps1" %*
exit /b %ERRORLEVEL%
