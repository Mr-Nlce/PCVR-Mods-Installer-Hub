@echo off
title Outer Wilds NomaiVR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OuterWildsVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
pause
exit /b %PCVR_EXIT%