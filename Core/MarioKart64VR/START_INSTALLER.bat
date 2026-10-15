@echo off
title Mario Kart 64 VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MarioKart64VR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%