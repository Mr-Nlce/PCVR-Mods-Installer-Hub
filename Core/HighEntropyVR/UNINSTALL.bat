@echo off
setlocal
title Remove High Entropy VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_HighEntropyVR.ps1" %*
exit /b %ERRORLEVEL%
