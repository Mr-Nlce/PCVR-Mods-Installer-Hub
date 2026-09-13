@echo off
title PCVR Mods Installer Hub
rem -------------------------------------------------------------
rem  The splash owns the Hub launch: it first removes the stale ready
rem  signal, then starts the Hub and remains visible until the activated
rem  WPF window writes a fresh signal. This avoids both a startup race
rem  and a blank desktop gap between splash and Hub.
rem -------------------------------------------------------------
powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0Core\Show-StartupSplash.ps1" ^
    -HubScript "%~dp0Core\VRModHub.ps1"
if errorlevel 1 exit /b %errorlevel%

rem -------------------------------------------------------------
rem  Only after the Hub is visibly ready, run the detached online jobs.
rem  They cannot compete with the cold start for disk, CPU or Defender.
rem  MUST NOT use "start /b": attached children keep this console open.
rem -------------------------------------------------------------
start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden ^
    -File "%~dp0Core\Update-Hub.ps1" -Silent

start "" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden ^
    -File "%~dp0Core\Prefetch-Versions.ps1"
