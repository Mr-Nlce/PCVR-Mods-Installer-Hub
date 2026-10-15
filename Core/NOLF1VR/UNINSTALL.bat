@echo off
setlocal
title Remove No One Lives Forever VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_NOLF1VR.ps1" %*
exit /b %ERRORLEVEL%
