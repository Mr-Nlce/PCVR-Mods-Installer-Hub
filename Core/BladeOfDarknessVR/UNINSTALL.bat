@echo off
setlocal
title Remove BladeVR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_BladeOfDarknessVR.ps1" %*
exit /b %ERRORLEVEL%
