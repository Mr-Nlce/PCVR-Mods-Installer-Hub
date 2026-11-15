@echo off
setlocal
title Tiny Tina's Wonderlands VR Installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0WonderlandsVR-core.ps1"
exit /b %ERRORLEVEL%
