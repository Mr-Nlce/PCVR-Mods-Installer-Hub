@echo off
setlocal
title SOMA VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0SomaVR-core.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
