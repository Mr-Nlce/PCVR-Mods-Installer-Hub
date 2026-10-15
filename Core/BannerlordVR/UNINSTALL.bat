@echo off
setlocal
title Remove BannerlordVR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_BannerlordVR.ps1" %*
exit /b %errorlevel%
