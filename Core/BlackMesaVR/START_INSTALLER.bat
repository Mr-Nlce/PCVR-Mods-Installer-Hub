@echo off
setlocal
title Black Mesa VR Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BlackMesaVR-core.ps1"
endlocal

