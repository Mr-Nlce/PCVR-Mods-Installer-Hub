@echo off
setlocal
title Remove Oblivion (2006) VR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Oblivion2006VR.ps1" %*
exit /b %errorlevel%
