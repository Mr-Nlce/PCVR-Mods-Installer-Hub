@echo off
title Virtua Cop 2 VR Installer
color 0E
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0VirtuaCop2VR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%