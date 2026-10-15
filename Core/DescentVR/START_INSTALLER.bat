@echo off
setlocal
title Descent VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DescentVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" (
  echo.
  pause
)
endlocal & exit /b %PCVR_EXIT%
