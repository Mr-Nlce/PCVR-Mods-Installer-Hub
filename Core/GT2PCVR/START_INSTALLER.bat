@echo off
setlocal
title Gran Turismo 2 PCVR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0GT2PCVR-core.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
