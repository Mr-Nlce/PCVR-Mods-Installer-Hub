@echo off
setlocal
title NAM VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0NAMVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" (
  echo.
  pause
)
endlocal & exit /b %PCVR_EXIT%
