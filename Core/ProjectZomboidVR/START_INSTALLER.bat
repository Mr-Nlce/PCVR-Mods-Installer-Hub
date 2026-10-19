@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ProjectZomboidVR-core.ps1"
exit /b %ERRORLEVEL%
