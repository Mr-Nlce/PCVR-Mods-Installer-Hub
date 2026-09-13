@echo off
title Forza Horizon 5 VR - Uninstall
color 0C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_ForzaHorizon5VR.ps1" %*
exit /b %errorlevel%
