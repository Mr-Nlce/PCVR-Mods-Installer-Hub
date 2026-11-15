@echo off
setlocal
title The Darkness II VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0DarknessIIVR-core.ps1"
exit /b %ERRORLEVEL%
