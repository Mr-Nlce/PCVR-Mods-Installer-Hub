@echo off
setlocal
title Remove Thief (2014) VR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Thief2014VR.ps1" %*
exit /b %errorlevel%
