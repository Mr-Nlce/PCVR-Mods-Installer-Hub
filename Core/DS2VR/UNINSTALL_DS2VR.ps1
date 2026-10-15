param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$receipt = ('' + $env:PCVR_DS2_TEST_RECEIPT).Trim()
if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }
function Finish-DS2Removal([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-DS2OwnedRoot([string]$Root) {
    return [bool]($Root -and
        (Test-Path -LiteralPath (Join-Path $Root 'Game\DarkSoulsII.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root '.pcvrhub_ds2vr_ownership.csv') -PathType Leaf))
}
if (-not (Test-DS2OwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    $GameRoot = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
}
if (-not (Test-DS2OwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned DS2VR install was found.' -ForegroundColor Yellow
    Finish-DS2Removal 0
}
if (Get-Process -Name 'DarkSoulsII' -ErrorAction SilentlyContinue) {
    Write-Host '  [XX] Close Dark Souls II before removing DS2VR.' -ForegroundColor Red
    Finish-DS2Removal 1
}
if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned DS2VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
    Finish-DS2Removal 0
}

# DS2VR INIs are player settings. Leave them in Game\DS2VR even when they
# still match publisher defaults; they must not be treated as disposable files.
$manifest = Join-Path $GameRoot '.pcvrhub_ds2vr_ownership.csv'
$rows = @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)
$settings = @('combat.ini','hands.ini','nr.ini','render.ini','ui.ini') | ForEach-Object { 'Game\DS2VR\' + $_ }
$owned = @($rows | Where-Object { $settings -notcontains [string]$_.RelativePath })
if ($owned.Count -ne $rows.Count) {
    $owned | Export-Csv -LiteralPath "$manifest.new" -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath "$manifest.new" -Destination $manifest -Force -ErrorAction Stop
}
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'ds2vr'
if (-not $result.Found) { throw 'The DS2VR ownership record disappeared before removal.' }
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Game, saves, DS2VR INIs and unrelated mods remain.' -ForegroundColor Gray
if ($result.Preserved -gt 0) { Write-Host '  [!!] Changed VR files remain for your review.' -ForegroundColor Yellow }
Finish-DS2Removal 0
