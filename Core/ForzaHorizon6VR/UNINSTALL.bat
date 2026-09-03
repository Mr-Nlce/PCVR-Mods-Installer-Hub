@echo off
title Forza Horizon 6 VR - Uninstall
color 0C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_ForzaHorizon6VR.ps1" %*
exit /b %errorlevel%
