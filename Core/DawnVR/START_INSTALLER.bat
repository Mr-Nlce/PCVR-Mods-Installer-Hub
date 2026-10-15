@echo off
title Life is Strange: BtS - DawnVR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DawnVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%