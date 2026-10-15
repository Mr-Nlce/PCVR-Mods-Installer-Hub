@echo off
title GTA IV VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GTA4VR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%