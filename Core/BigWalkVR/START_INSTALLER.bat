@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%BigWalkVR-core.ps1"
title Big Walk VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
