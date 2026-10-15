@echo off
title Remove W40KRT_VR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_RogueMaqueta.ps1" %*
exit /b %ERRORLEVEL%
