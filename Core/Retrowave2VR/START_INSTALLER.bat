@echo off
title Retrowave 2 VR Installer
color 0D
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Retrowave2VR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%