@echo off
setlocal
title World War II GI VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WW2GIVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" (
  echo.
  pause
)
endlocal & exit /b %PCVR_EXIT%
