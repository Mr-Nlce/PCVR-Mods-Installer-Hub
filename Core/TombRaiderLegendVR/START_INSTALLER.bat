@echo off
setlocal
title Tomb Raider: Legend VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0TombRaiderLegendVR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
