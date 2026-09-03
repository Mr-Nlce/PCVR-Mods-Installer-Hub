@echo off
setlocal
title Nuclear Option VR Uninstaller
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_NuclearOptionVR.ps1" %*
endlocal
