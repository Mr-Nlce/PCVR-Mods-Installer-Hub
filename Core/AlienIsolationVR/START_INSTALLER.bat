@echo off
title Alien: Isolation VR Mod Installer
color 0B
:: Request admin elevation
net session >nul 2>&1
if %errorLevel% == 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0AlienIsolationVR-core.ps1"
) else (
    powershell.exe -Command "try { Start-Process cmd -ArgumentList '/c cd /d ""%~dp0"" && color 0B && powershell.exe -NoProfile -ExecutionPolicy Bypass -File AlienIsolationVR-core.ps1 && pause' -Verb RunAs -ErrorAction Stop } catch { Write-Host ''; Write-Host '============================================================' -ForegroundColor Yellow; Write-Host '  Administrator permission is required for this installer.' -ForegroundColor Yellow; Write-Host '  The Alien: Isolation VR mod needs to write files into a' -ForegroundColor White; Write-Host '  protected Steam directory, which Windows only allows with' -ForegroundColor White; Write-Host '  elevated rights.' -ForegroundColor White; Write-Host ''; Write-Host '  Close this window with Enter and launch the installer' -ForegroundColor White; Write-Host '  again from the Hub when you are ready to grant permission.' -ForegroundColor White; Write-Host '============================================================' -ForegroundColor Yellow; Write-Host ''; Read-Host '  Press Enter to close' }"
)
pause
