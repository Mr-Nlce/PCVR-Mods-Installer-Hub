@echo off
setlocal
title Outbound VR Uninstaller
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_OutboundVR.ps1" %*
endlocal
