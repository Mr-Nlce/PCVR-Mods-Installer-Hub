@echo off
setlocal
title Twilight Princess VR Installer
color 0B
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0TwilightPrincessVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
