@echo off
setlocal
title Gothic 3 VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Gothic3VR-core.ps1"
exit /b %ERRORLEVEL%
