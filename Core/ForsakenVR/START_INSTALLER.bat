@echo off
setlocal
title Forsaken VR Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ForsakenVR-core.ps1"
set "result=%ERRORLEVEL%"
exit /b %result%
