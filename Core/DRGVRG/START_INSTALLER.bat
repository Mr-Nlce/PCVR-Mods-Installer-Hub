@echo off
title Deep Rock Galactic VRG Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DRGVRG-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%