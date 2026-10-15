@echo off
title Red Faction VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RedFactionVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%