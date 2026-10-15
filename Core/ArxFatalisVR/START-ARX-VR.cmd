@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0START-ARX-VR.ps1"
if errorlevel 1 pause
