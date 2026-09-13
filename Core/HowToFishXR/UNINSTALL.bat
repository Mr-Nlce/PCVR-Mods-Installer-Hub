@echo off
title Uninstall How to Fish XR
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UNINSTALL.ps1" %*
