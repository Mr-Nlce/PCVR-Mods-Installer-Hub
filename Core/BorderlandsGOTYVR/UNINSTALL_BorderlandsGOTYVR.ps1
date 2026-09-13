param(
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$APP_ID = '729040'
$GAME_EXE = 'Binaries\Win64\BorderlandsGOTY.exe'
$BIN_REL = 'Binaries\Win64'
$IDENTITY = 'borderlandsgotyenhancedvr'
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Finish([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-Root([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf)) }

if (-not (Test-Root $GameRoot)) {
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $StateRoot '.installed_path') -Raw).Trim()
        if (Test-Root $recorded) { $GameRoot = $recorded }
    } catch {}
}
if (-not (Test-Root $GameRoot)) {
    $GameRoot = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('BorderlandsGOTYEnhanced') -ProbeExe $GAME_EXE
}
if (-not (Test-Root $GameRoot)) {
    Write-Host '[X] Borderlands GOTY Enhanced was not found. No files were changed.' -ForegroundColor Red
    Finish 1
}

$binPath = Join-Path $GameRoot $BIN_REL
$manifest = Join-Path $binPath ".pcvrhub_${IDENTITY}_ownership.csv"
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    Write-Host '[X] No Hub ownership record was found. Nothing was guessed or deleted.' -ForegroundColor Red
    Write-Host '    Use the uninstall guide for a manual review.' -ForegroundColor Gray
    Finish 1
}
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove BL1GOTYVR from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish 0 }
}

$result = Uninstall-OwnedModPayload -GameRoot $binPath -Identity $IDENTITY -ParkedAlternates @{ 'dxgi.dll'='dxgi.dll.pcvrhub_off' }
if (-not $result.Found) { Write-Host '[X] The ownership record disappeared before removal. No files were guessed.' -ForegroundColor Red; Finish 1 }

# BL1GOTYVR creates this uniquely named diagnostic log at runtime, so it is
# not part of the downloaded ownership manifest. It is safe to remove only
# after that manifest has positively identified this as a Hub-managed setup.
$runtimeLog = Join-Path $binPath 'BL1GOTYVR.log'
$removedLog = $false
if (Test-Path -LiteralPath $runtimeLog -PathType Leaf) {
    Remove-Item -LiteralPath $runtimeLog -Force
    $removedLog = $true
}

Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
if ($removedLog) { Write-Host '[OK] Removed BL1GOTYVR.log.' -ForegroundColor Green }
Write-Host '[KEEP] BL1GOTYVR.ini contains your settings and was retained.' -ForegroundColor Gray
Write-Host '[KEEP] The game, saves and unrelated mods were not touched.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $StateRoot '.installed_version') -Force -ErrorAction SilentlyContinue
}
Finish 0
