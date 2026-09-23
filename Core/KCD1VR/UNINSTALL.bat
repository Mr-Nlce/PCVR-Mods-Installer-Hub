@echo off
setlocal
title Remove Kingdom Come Deliverance VR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_KCD1VR.ps1" %*
exit /b %errorlevel%
