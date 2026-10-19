@echo off
setlocal
title Fallout New Vegas VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0FNVVR-core.ps1"
exit /b %ERRORLEVEL%
