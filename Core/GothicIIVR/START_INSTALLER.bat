@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0GothicIIVR-core.ps1"
if errorlevel 1 pause
