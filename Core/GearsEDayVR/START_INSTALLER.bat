@echo off
setlocal
title Gears of War: E-Day VR Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GearsEDayVR-core.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
