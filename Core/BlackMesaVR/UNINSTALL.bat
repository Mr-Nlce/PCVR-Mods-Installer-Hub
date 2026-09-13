@echo off
setlocal
title Black Mesa VR Uninstaller
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_BlackMesaVR.ps1" %*
endlocal

