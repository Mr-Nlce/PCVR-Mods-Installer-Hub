@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0XIIIVR-core.ps1"
set "installerExit=%errorlevel%"
if not "%installerExit%"=="0" pause
exit /b %installerExit%
