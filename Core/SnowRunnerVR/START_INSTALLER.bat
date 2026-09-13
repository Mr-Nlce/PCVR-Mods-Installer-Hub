@echo off
setlocal
title SnowRunner VR Installer
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SnowRunnerVR-core.ps1"
endlocal
