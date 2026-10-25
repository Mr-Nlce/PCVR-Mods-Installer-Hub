param([switch]$HubConfirmed)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$game = if ($env:PCVR_RUSTLER_TEST_GAME) { [IO.Path]::GetFullPath($env:PCVR_RUSTLER_TEST_GAME) } else {
    Get-PCVRRememberedGameFolder -GameId 'rustler-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('Rustler.exe','UnityPlayer.dll')
}
if (-not $game) { $game = Find-SteamGameFolder -AppId '844260' -SteamFolderNames @('Rustler') -ProbeExe 'Rustler.exe' -HubGameId 'rustler-vr' }
if (-not $game -or -not (Test-Path -LiteralPath (Join-Path $game '.pcvrhub_rustlervr_ownership.csv') -PathType Leaf)) {
    throw 'No Hub-owned Rustler VR installation was found.'
}
if (Get-Process -Name Rustler -ErrorAction SilentlyContinue) { throw 'Close Rustler before removing VR mode.' }
if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned Rustler VR from '$game'? Type REMOVE") -cne 'REMOVE') { exit 0 }
$result = Uninstall-OwnedModPayload -GameRoot $game -Identity 'rustlervr'
if (-not (Test-Path -LiteralPath (Join-Path $game 'BepInEx\plugins\RusVR\RusVR.dll') -PathType Leaf)) {
    foreach ($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
    }
}
Write-Host "  [OK] Rustler VR files removed: $($result.Removed); earlier files restored: $($result.Restored)." -ForegroundColor Green
if ($result.Preserved -gt 0) { Write-Host "  Locally changed files kept: $($result.Preserved)." -ForegroundColor Yellow }
Write-Host '  The original game, saves and unrelated files remain.' -ForegroundColor Gray
