@echo off
setlocal
title A Tale of Two Realities Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0TTWVR-core.ps1"
exit /b %ERRORLEVEL%
