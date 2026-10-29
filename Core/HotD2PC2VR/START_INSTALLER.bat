@echo off
setlocal
title The House of the Dead 2 - PC2VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0HotD2PC2VR-core.ps1"
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
