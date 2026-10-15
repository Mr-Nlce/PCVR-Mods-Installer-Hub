@echo off
title Assassin's Creed Mirage VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ACMirageVR-core.ps1"
set "pcvr_exit=%errorlevel%"
pause
exit /b %pcvr_exit%
