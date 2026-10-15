@echo off
title DREDGE VR Mod Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DredgeVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%