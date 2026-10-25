@echo off
setlocal
title Far Cry 2 VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0FarCry2VR-core.ps1" %*
exit /b %errorlevel%
