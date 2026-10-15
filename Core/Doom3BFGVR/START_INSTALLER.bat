@echo off
title Doom 3 BFG VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Doom3BFGVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%