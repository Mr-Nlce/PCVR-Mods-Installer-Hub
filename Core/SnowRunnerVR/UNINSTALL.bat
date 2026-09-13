@echo off
setlocal
title SnowRunner VR Uninstaller
color 0A
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL.ps1" %*
endlocal
