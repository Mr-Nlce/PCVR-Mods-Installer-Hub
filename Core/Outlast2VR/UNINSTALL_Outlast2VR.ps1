param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\HubState.ps1')
function Finish-Outlast2([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-Outlast2Owned([string]$Path) { return [bool]($Path -and
    (Test-Path -LiteralPath (Join-Path $Path 'Binaries\Win64\Outlast2.exe') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_outlast2vr_ownership.csv') -PathType Leaf)) }
if (-not (Test-Outlast2Owned $GameRoot)) { try { $candidate=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"'); if (Test-Outlast2Owned $candidate) { $GameRoot=$candidate } } catch {} }
if (-not (Test-Outlast2Owned $GameRoot)) {
    try {
        $candidate=Get-PCVRRememberedGameFolder -GameId 'outlast-2-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('Binaries\Win64\Outlast2.exe')
        if (Test-Outlast2Owned $candidate) { $GameRoot=$candidate }
    } catch {}
}
if (-not (Test-Outlast2Owned $GameRoot)) {
    try {
        $candidate=Find-SteamGameFolder -AppId '414700' -SteamFolderNames @('Outlast 2') -ProbeExe 'Binaries\Win64\Outlast2.exe' -HubGameId 'outlast-2-vr'
        if (Test-Outlast2Owned $candidate) { $GameRoot=$candidate }
    } catch {}
}
if (-not (Test-Outlast2Owned $GameRoot)) {
    $candidate='C:\Program Files (x86)\Steam\steamapps\common\Outlast 2'
    if (Test-Outlast2Owned $candidate) { $GameRoot=$candidate }
}
if (-not (Test-Outlast2Owned $GameRoot)) {
    Write-Host '  Hub-owned VR files were not found in the saved or Steam location.' -ForegroundColor Yellow
    Write-Host '  Enter your Outlast 2 game folder, or Q to cancel.' -ForegroundColor White
    while (-not (Test-Outlast2Owned $GameRoot)) {
        $answer=('' + (Read-Host 'Outlast 2 game folder or Q')).Trim().Trim('"')
        if ($answer -ieq 'Q') { Finish-Outlast2 0 }
        if (Test-Outlast2Owned $answer) { $GameRoot=$answer }
        else { Write-Host '  No matching base game and Hub ownership record there.' -ForegroundColor Yellow }
    }
}
if (Get-Process -Name 'Outlast2','Outlast2VR' -ErrorAction SilentlyContinue) { Write-Host '  Close Outlast 2 and its VR launcher before removing the mod.' -ForegroundColor Red; Finish-Outlast2 1 }
if (-not $HubConfirmed) { $answer=([string](Read-Host "Remove Hub-owned Outlast 2 VR files from '$GameRoot'? Type REMOVE")).Trim(); if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-Outlast2 0 } }
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'outlast2vr'
if (-not $result.Found) { throw 'The Outlast 2 VR ownership manifest disappeared before removal.' }
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot 'Binaries\Win64\Outlast2VR.exe') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_version') -Force -ErrorAction SilentlyContinue
    $gameState=[pscustomobject]@{ Id='outlast-2-vr'; Title='Outlast 2 VR'; GithubRepo='StrikeZoneVR-hub/Outlast2VR' }
    Clear-HubInstallManifestVersion -Game $gameState -GameDir $GameRoot
    Reset-PersistentGameStateValue -Game $gameState -Name 'installed_version'
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed files." -ForegroundColor Green
Write-Host '  Purchased game files, user settings, saves and unrelated files remain.' -ForegroundColor Gray
Finish-Outlast2 0
