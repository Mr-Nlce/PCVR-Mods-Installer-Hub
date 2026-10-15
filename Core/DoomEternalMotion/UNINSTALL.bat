@echo off
setlocal
title Remove DOOM Eternal Motion VR
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL_DoomEternalMotion.ps1" %*
exit /b %errorlevel%
