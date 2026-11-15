@echo off
setlocal
title Resident Evil 5 VR Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RE5VR-core.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
