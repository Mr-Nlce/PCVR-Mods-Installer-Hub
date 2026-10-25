@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_GridLegendsVR.ps1" %*
exit /b %ERRORLEVEL%