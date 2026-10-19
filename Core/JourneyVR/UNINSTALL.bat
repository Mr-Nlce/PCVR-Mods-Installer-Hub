@echo off
setlocal
title Remove Journey VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_JourneyVR.ps1" %*
exit /b %ERRORLEVEL%
