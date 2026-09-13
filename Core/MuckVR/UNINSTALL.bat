@echo off
title Uninstall Muck VR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL.ps1" %*
