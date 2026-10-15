@echo off
setlocal
title BannerlordVR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BannerlordVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
