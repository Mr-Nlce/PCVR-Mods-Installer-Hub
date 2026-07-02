@echo off
title PCVR Mods Installer Hub
rem -------------------------------------------------------------
rem  Update check: detached + silent. It only writes a marker file
rem  the Hub reads on its NEXT launch, so it never blocks startup.
rem -------------------------------------------------------------
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0Core\Update-Hub.ps1" -Silent

rem -------------------------------------------------------------
rem  Pre-warm the version caches in the background (detached, no
rem  window). Fills the same 6h caches the scan reads, so the first
rem  scan is fast. It never displays anything - a mod is shown as an
rem  update only after the user runs a scan.
rem -------------------------------------------------------------
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0Core\Prefetch-Versions.ps1"

rem -------------------------------------------------------------
rem  Load the Hub CONCURRENTLY in its own minimized console. Running
rem  it in parallel lets the splash (below) track the Hub's real
rem  progress, and lets THIS launcher console simply close when the
rem  splash is done - so no console is left gammeling in the front.
rem -------------------------------------------------------------
start "PCVR Mods Installer Hub" /min powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0Core\VRModHub.ps1"

rem -------------------------------------------------------------
rem  Splash in THIS console: magenta banner + a progress bar paced
rem  to the last recorded load time, snapping to 100 percent the
rem  moment the Hub signals its window is up. When it returns, the
rem  batch ends and this console closes on its own.
rem -------------------------------------------------------------
powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0Core\Show-StartupSplash.ps1"
