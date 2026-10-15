@echo off
title Elden Ring VR - Gamepad Installer
color 0E
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0EldenRingRealVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%