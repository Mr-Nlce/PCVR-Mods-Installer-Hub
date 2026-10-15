@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_XIIIVR.ps1" -NoPause %*
if errorlevel 1 pause
