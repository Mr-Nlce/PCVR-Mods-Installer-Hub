@echo off
title Hollow Knight Silksong VR - Uninstall
color 0C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_HollowKnightSilksongVR.ps1" %*
exit /b %errorlevel%
