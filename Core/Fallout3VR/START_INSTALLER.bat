@echo off
setlocal
title Fallout 3 VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fallout3VR-core.ps1"
exit /b %ERRORLEVEL%
