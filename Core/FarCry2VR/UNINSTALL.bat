@echo off
setlocal
title Remove Far Cry 2 VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_FarCry2VR.ps1" %*
exit /b %errorlevel%
