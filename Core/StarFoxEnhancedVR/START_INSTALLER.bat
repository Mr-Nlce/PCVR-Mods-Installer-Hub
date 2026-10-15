@echo off
setlocal
title Star Fox Enhanced PCVR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0StarFoxEnhancedVR-core.ps1" %*
set "PCVR_EXIT=%ERRORLEVEL%"
if not "%PCVR_EXIT%"=="0" pause
exit /b %PCVR_EXIT%
