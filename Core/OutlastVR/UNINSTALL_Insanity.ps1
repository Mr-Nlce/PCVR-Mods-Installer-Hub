param([switch]$HubConfirmed, [string]$GameRoot = '')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot 'OutlastVR-Switch.ps1')

try {
    if (-not $GameRoot) {
        $receipt = Join-Path $PSScriptRoot '.installed_path'
        if (Test-Path -LiteralPath $receipt -PathType Leaf) { $GameRoot = (Get-Content -LiteralPath $receipt -Raw).Trim() }
    }
    if (-not $GameRoot -or -not (Test-Path -LiteralPath (Join-Path $GameRoot 'Binaries\Win64\OLGame.exe') -PathType Leaf)) {
        $GameRoot = Find-SteamGameFolder -AppId '238320' -SteamFolderNames @('Outlast') -ProbeExe 'Binaries\Win64\OLGame.exe'
    }
    if (-not $GameRoot) { throw 'Outlast was not found. Locate the game in the Hub, then retry removal.' }
    $layout = Get-OutlastLayout $GameRoot
    if (Get-Process -Name OLGame,Outlast1VR -ErrorAction SilentlyContinue) { throw 'Close Outlast and its VR launcher before removing the VR mod.' }
    if (-not (Test-OutlastStore $GameRoot 'Insanity')) { throw 'No complete Hub-managed Insanity Engine VR installation was found.' }

    $previous = Get-OutlastActiveMod $GameRoot
    $hadHalcyon = Test-OutlastStore $GameRoot 'Halcyon'
    Write-Host ''
    Write-Host 'Remove Insanity Engine VR' -ForegroundColor Cyan
    Write-Host 'The publisher setup restores your original game settings.' -ForegroundColor White
    Write-Host 'In its window choose [2] Uninstall. Your parked Halcyon mod' -ForegroundColor White
    Write-Host 'and personal Insanity settings will remain available.' -ForegroundColor White
    Read-Host 'Press Enter to open the publisher uninstall'

    if ($previous -ne 'Insanity') { Switch-OutlastMod -GameRoot $GameRoot -Name 'Insanity' }
    $batch = Join-Path $layout.Bin 'Outlast-VR.bat'
    $result = Start-Process -FilePath $batch -WorkingDirectory $layout.Bin -Wait -PassThru -ErrorAction Stop
    if ($result.ExitCode -ne 0 -or
        (Test-Path -LiteralPath (Join-Path $layout.Bin 'd3d9.dll') -PathType Leaf) -or
        (Test-Path -LiteralPath $batch -PathType Leaf)) {
        throw 'Publisher uninstall did not finish. The Hub has kept the mod and its version marker; retry and choose [2] Uninstall.'
    }

    $store = Join-Path $layout.Stores 'Insanity'
    foreach ($file in @('d3d9.dll','openxr_loader.dll','dxvk_d3d9.dll','Outlast-VR.bat')) {
        $path = Join-Path $store $file
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
    }
    $state = Join-Path $layout.Stores '.active_mod.json'
    if (Test-Path -LiteralPath $state -PathType Leaf) { Remove-Item -LiteralPath $state -Force -ErrorAction Stop }
    Write-OutlastLaunchers -GameRoot $GameRoot -RuntimePath (Join-Path $PSScriptRoot 'OutlastVR-Switch.ps1')
    if ($previous -eq 'StrikeZone' -and (Test-OutlastStore $GameRoot 'StrikeZone')) {
        Switch-OutlastMod -GameRoot $GameRoot -Name 'StrikeZone'
    } elseif ($hadHalcyon) { Switch-OutlastMod -GameRoot $GameRoot -Name 'Halcyon' }
    foreach ($marker in @((Join-Path $PSScriptRoot '.installed_version_b'), (Join-Path $GameRoot '.pcvrhub_version_b'))) {
        if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop }
    }
    Write-Host '[OK] Insanity Engine VR removed; the other installed Outlast VR routes remain.' -ForegroundColor Green
} catch {
    Write-Host "[X] Insanity Engine VR was not fully removed: $_" -ForegroundColor Red
    try {
        if ($previous -in @('Halcyon','StrikeZone') -and (Test-OutlastStore $GameRoot $previous)) {
            Switch-OutlastMod -GameRoot $GameRoot -Name $previous
        }
    } catch { Write-Host "[!] Reopen the Halcyon launcher to restore it: $_" -ForegroundColor Yellow }
    exit 1
}
