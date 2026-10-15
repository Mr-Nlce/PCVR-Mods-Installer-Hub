@echo off
setlocal
title Remove DS2VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_DS2VR.ps1" %*
exit /b %ERRORLEVEL%
