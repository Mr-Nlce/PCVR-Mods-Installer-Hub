@echo off
setlocal
title Black Mesa VR Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlackMesaVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
endlocal & exit /b %PCVR_EXIT%

