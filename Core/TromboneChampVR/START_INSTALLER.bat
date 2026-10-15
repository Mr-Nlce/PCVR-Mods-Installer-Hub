@echo off
title Trombone Champ VR Installer
color 0E
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TromboneChampVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%