@echo off
setlocal
title Final Fantasy VII Remake Intergrade VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0FF7RemakeVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
