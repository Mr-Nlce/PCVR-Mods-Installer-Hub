@echo off
title Portal 2 VR Mod Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Portal2VR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%