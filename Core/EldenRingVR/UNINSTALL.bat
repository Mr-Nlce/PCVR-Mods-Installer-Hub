@echo off
title Elden Ring VR - Uninstall Motion Controls
color 0C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_EldenRingVR.ps1" %*
exit /b %errorlevel%
