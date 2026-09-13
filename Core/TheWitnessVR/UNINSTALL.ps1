param(
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$IDENTITY = 'witnessvr'
$GAME_EXE = 'witness64_d3d11.exe'
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
    $GameRoot = Find-SteamGameFolder -AppId '210970' -SteamFolderNames @('The Witness') -ProbeExe $GAME_EXE -EpicNames @('TheWitness','The Witness')
}
if (-not (Test-Root $GameRoot)) {
    Write-Host '[X] The Witness was not found. No files were changed.' -ForegroundColor Red
    Finish 1
}

$manifest = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    Write-Host '[X] No Hub ownership record was found. Nothing was guessed or deleted.' -ForegroundColor Red
    Write-Host '    Use the uninstall guide for a manual review.' -ForegroundColor Gray
    Finish 1
}
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove Witness VR Mod from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish 0 }
}

$live = Join-Path $GameRoot 'openvr_api.dll'
$parked = Join-Path $GameRoot 'openvr_api.dll.pcvrhub_off'
$backup = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup\openvr_api.dll"
if ((Test-Path -LiteralPath $live -PathType Leaf) -and (Test-Path -LiteralPath $parked -PathType Leaf)) {
    $proxyRow = @(Import-Csv -LiteralPath $manifest | Where-Object RelativePath -eq 'openvr_api.dll' | Select-Object -First 1)[0]
    $liveSha = (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash
    $parkedSha = (Get-FileHash -LiteralPath $parked -Algorithm SHA256).Hash
    $backupSha = if (Test-Path -LiteralPath $backup -PathType Leaf) { (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash } else { '' }
    if (-not $proxyRow -or $parkedSha -ne [string]$proxyRow.InstalledSha256 -or -not $backupSha -or $liveSha -ne $backupSha) {
        Write-Host '[X] Flat mode files do not match the ownership record. Nothing was deleted.' -ForegroundColor Red
        Finish 1
    }
    # Uninstall-OwnedModPayload restores the backup to the live path itself.
    # Removing this byte-identical live copy first lets it select and verify
    # the parked mod proxy instead of mistaking the restored original for a
    # user-edited mod file.
    Remove-Item -LiteralPath $live -Force -ErrorAction Stop
}

$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY -ParkedAlternates @{ 'openvr_api.dll'='openvr_api.dll.pcvrhub_off' }
if (-not $result.Found) { Write-Host '[X] The ownership record disappeared before removal. No files were guessed.' -ForegroundColor Red; Finish 1 }

Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] witness_vr_mod\config.ini and witness_vr_mod.log were retained.' -ForegroundColor Gray
Write-Host '[KEEP] The game, saves and unrelated files were not touched.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    $stamp = Join-Path $GameRoot '.pcvrhub_version'
    try { if ((Get-Content -LiteralPath $stamp -Raw).Trim() -eq 'v1.0.0') { Remove-Item -LiteralPath $stamp -Force } } catch {}
    Remove-Item -LiteralPath (Join-Path $StateRoot '.installed_version') -Force -ErrorAction SilentlyContinue
}
Finish 0
