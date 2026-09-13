param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-MGS([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-MGSRoot([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'mgsvtpp.exe') -PathType Leaf)) }

if (-not (Test-MGSRoot $GameRoot)) {
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-MGSRoot $recorded) { $GameRoot = $recorded }
    } catch {}
}
if (-not (Test-MGSRoot $GameRoot)) {
    $GameRoot = Find-SteamGameFolder -AppId '287700' -SteamFolderNames @('MGS_TPP') -ProbeExe 'mgsvtpp.exe'
}
if (-not (Test-MGSRoot $GameRoot)) { Write-Host '[X] Metal Gear Solid V was not found. Nothing changed.' -ForegroundColor Red; Finish-MGS 1 }
if (Get-Process -Name 'mgsvtpp' -ErrorAction SilentlyContinue) { Write-Host '[X] Close MGSV before removing MGS5VR.' -ForegroundColor Red; Finish-MGS 1 }
$manifest = Join-Path $GameRoot '.pcvrhub_mgs5vr_ownership.csv'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { Write-Host '[X] No Hub ownership record was found. Nothing was guessed or deleted.' -ForegroundColor Red; Finish-MGS 1 }
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove MGS5VR from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-MGS 0 }
}
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'mgs5vr'
Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] mgs5vr.ini contains your settings and remains in the game folder.' -ForegroundColor Gray
Write-Host '[KEEP] Game files, saves, logs and unrelated mods were not touched.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Force -ErrorAction SilentlyContinue
}
Finish-MGS 0
