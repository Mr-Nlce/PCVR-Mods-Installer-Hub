@echo off
setlocal
title Super Mario 3D World VR Uninstaller
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_SuperMario3DWorldVR.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
