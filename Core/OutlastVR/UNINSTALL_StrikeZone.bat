@echo off
title Remove StrikeZoneVR Outlast VR
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_StrikeZone.ps1" %*
exit /b %errorlevel%
