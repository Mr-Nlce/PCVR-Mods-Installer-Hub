@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%AnotherCrabsTreasureVR-core.ps1"
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
