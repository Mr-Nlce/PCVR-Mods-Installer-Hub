@echo off
setlocal
title Remove Flower VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_FlowerVR.ps1" %*
exit /b %ERRORLEVEL%
