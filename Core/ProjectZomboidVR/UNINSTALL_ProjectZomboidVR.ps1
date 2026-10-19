param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
function Finish-PZRemoval([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-PZOwnedRoot([string]$Root) {
    return [bool]($Root -and
        (Test-Path -LiteralPath (Join-Path $Root 'ProjectZomboid64.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root '.pcvrhub_pzvr_activation.json') -PathType Leaf))
}
$receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_RECEIPT) {
    $env:PCVR_PZ_TEST_RECEIPT
} else { Join-Path $PSScriptRoot '.installed_path' }
if (-not (Test-PZOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    $GameRoot = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
}
if (-not (Test-PZOwnedRoot $GameRoot)) {
    $saved = Get-PCVRRememberedGameFolder -GameId 'project-zomboid-vr' `
        -ProbeFiles @('ProjectZomboid64.exe','.pcvrhub_pzvr_activation.json') `
        -StateNames @('installed_path','user_located')
    if (Test-PZOwnedRoot $saved) { $GameRoot = $saved }
}
if (-not (Test-PZOwnedRoot $GameRoot)) {
    $found = Find-SteamGameFolder -AppId '108600' -SteamFolderNames @('ProjectZomboid') `
        -ProbeExe 'ProjectZomboid64.exe' -HubGameId 'project-zomboid-vr'
    if (Test-PZOwnedRoot $found) { $GameRoot = $found }
}
if (-not (Test-PZOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-verified Project Zomboid VR setup was found.' -ForegroundColor Yellow
    Finish-PZRemoval 0
}
if ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'ProjectZomboid64' -ErrorAction SilentlyContinue)) {
    Write-Host '  Close Project Zomboid before removing its Hub setup record.' -ForegroundColor Yellow
    Finish-PZRemoval 1
}
if (-not $HubConfirmed -and (Read-Host "Remove the Hub VR setup record from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
    Finish-PZRemoval 0
}
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_pzvr_activation.json') -Force -ErrorAction Stop
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host '  [OK] Removed the Hub VR setup record.' -ForegroundColor Green
Write-Host '  Steam Workshop subscriptions, ZombieBuddy, approvals, the game and saves remain.' -ForegroundColor White
Write-Host '  To remove ZombieBuddy itself, run its publisher installer and choose Uninstall.' -ForegroundColor Gray
Finish-PZRemoval 0
