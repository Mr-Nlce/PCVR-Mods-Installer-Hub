@echo off
setlocal
title Remove Mirror's Edge VR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_MirrorsEdgeVR.ps1" %*
exit /b %errorlevel%
