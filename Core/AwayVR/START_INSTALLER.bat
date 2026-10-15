@echo off
title AWAY VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0AwayVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%