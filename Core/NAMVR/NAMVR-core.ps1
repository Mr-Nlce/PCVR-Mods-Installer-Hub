$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'NAM VR Installer'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\RazeXRShared\RazeXRShared.ps1')
try { Install-RazeXRGame -Family 'nam' }
catch { Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
