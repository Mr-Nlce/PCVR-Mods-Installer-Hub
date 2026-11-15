@echo off
setlocal
title Resident Evil Code: Veronica X VR Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CodeVeronicaVR-core.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
