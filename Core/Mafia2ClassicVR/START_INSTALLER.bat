@echo off
setlocal
title Mafia II Classic VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Mafia2ClassicVR-core.ps1"
exit /b %ERRORLEVEL%
