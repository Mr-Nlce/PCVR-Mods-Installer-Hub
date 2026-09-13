@echo off
setlocal
title Halo MCC VR Uninstaller
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_Halo3MCCVR.ps1" %*
endlocal
