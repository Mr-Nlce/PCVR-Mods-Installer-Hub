@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL.ps1" %*
endlocal
