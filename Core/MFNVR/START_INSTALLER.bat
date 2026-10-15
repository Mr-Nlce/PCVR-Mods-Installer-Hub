@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%MFNVR-core.ps1"
title My Friendly Neighborhood VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "PCVR_EXIT=%ERRORLEVEL%"
endlocal & exit /b %PCVR_EXIT%