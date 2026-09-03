@echo off
title BioShock Remastered VR - Uninstall
color 0C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_BioshockVR.ps1" %*
exit /b %errorlevel%
