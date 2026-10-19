@echo off
setlocal
title Beyond Two Souls VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BeyondTwoSoulsVR-core.ps1"
exit /b %ERRORLEVEL%
