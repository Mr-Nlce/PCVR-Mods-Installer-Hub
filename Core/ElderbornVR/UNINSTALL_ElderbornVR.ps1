param(
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$IDENTITY = 'elderbornvr'
$VERSION = 'discord-2026-08-28+elderbornvrmod-1.27.0'
$GAME_EXE = 'ELDERBORN.exe'
$CONFIG_PATHS = @('BepInEx\config\BepInEx.cfg','BepInEx\config\raicuparta.uuvr-modern.cfg')
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Finish-ElderbornUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-ElderbornUninstallRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue))
}
function Preserve-ElderbornConfigs([string]$Manifest) {
    if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) { return }
    $rows = @(Import-Csv -LiteralPath $Manifest)
    $keep = @($rows | Where-Object { $CONFIG_PATHS -notcontains ([string]$_.RelativePath) })
    if ($keep.Count -eq $rows.Count) { return }
    $temp = "$Manifest.new"
    $keep | Export-Csv -LiteralPath $temp -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath $temp -Destination $Manifest -Force -ErrorAction Stop
}

if (-not (Test-ElderbornUninstallRoot $GameRoot)) {
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $StateRoot '.installed_path') -Raw).Trim()
        if (Test-ElderbornUninstallRoot $recorded) { $GameRoot = $recorded }
    } catch {}
}
if (-not (Test-ElderbornUninstallRoot $GameRoot)) {
    $GameRoot = Find-SteamGameFolder -AppId '727850' -SteamFolderNames @('ELDERBORN') -ProbeExe $GAME_EXE -GogNames @('ELDERBORN') -HubGameId 'elderborn-vr'
}
if (-not (Test-ElderbornUninstallRoot $GameRoot)) {
    Write-Host '[XX] ELDERBORN was not found. No files were changed.' -ForegroundColor Red
    Finish-ElderbornUninstall 1
}
if (Get-Process -Name 'ELDERBORN' -ErrorAction SilentlyContinue) {
    Write-Host '[XX] Close ELDERBORN before removing its VR files.' -ForegroundColor Red
    Finish-ElderbornUninstall 1
}

$manifest = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    Write-Host '[XX] No Hub ownership record was found. Nothing was guessed or deleted.' -ForegroundColor Red
    Finish-ElderbornUninstall 1
}
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove Hub-owned ELDERBORN VR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-ElderbornUninstall 0 }
}

Preserve-ElderbornConfigs -Manifest $manifest
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY -ParkedAlternates @{ 'winhttp.dll'='winhttp.dll.pcvrhub_off' }
if (-not $result.Found) {
    Write-Host '[XX] The ownership record disappeared before removal. Nothing was guessed.' -ForegroundColor Red
    Finish-ElderbornUninstall 1
}

Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] UUVR and BepInEx configuration files were retained.' -ForegroundColor Gray
Write-Host '[KEEP] ELDERBORN, saves and unrelated mods were not touched.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    $stamp = Join-Path $GameRoot '.pcvrhub_version'
    try { if ((Get-Content -LiteralPath $stamp -Raw).Trim() -eq $VERSION) { Remove-Item -LiteralPath $stamp -Force } } catch {}
    Remove-Item -LiteralPath (Join-Path $StateRoot '.installed_version') -Force -ErrorAction SilentlyContinue
}
Finish-ElderbornUninstall 0
