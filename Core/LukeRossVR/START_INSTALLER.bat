@echo off
title Luke Ross R.E.A.L. VR Installer
color 0B
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0LukeRossVR-core.ps1" -GameTitle "%~1"
