@echo off
setlocal
title Remove Dishonored VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_DishonoredVR.ps1" %*
exit /b %ERRORLEVEL%
