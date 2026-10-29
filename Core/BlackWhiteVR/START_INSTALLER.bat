@echo off
setlocal
title Black and White VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlackWhiteVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
