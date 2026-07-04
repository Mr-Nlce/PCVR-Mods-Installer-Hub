@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%AnomalyGammaVR-core.ps1"
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
