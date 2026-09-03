@echo off
setlocal
title Nuclear Option VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0NuclearOptionVR-core.ps1"
endlocal
