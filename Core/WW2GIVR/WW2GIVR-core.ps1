$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'World War II GI VR Installer'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\RazeXRShared\RazeXRShared.ps1')
try { Install-RazeXRGame -Family 'ww2gi' }
catch { Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
