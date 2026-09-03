@echo off
title Quake VR - Uninstall
color 0C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_QuakeVR.ps1" %*
exit /b %errorlevel%
