param([switch]$HubConfirmed, [switch]$NoPause, [string]$GameRoot = '')
$ErrorActionPreference = 'Stop'
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
    if (Get-Process -Name OLGame,Outlast1VR -ErrorAction SilentlyContinue) { throw 'Close Outlast and Outlast1VR.exe before removal.' }
    if (-not (Test-OutlastStore $GameRoot 'StrikeZone')) { throw 'No complete Hub-managed StrikeZoneVR installation was found.' }

    Write-Host ''
    Write-Host 'Remove StrikeZoneVR Outlast VR' -ForegroundColor Cyan
    Write-Host 'The Hub removes only this parked runtime and launcher.' -ForegroundColor White
    Write-Host 'Your game, Documents settings, tuned outlastvr.ini and other' -ForegroundColor White
    Write-Host 'parked Outlast VR mods remain available.' -ForegroundColor White
    if (-not $NoPause) { Read-Host 'Press Enter to remove this route' }

    $previous = Get-OutlastActiveMod $GameRoot
    $store = Join-Path $layout.Stores 'StrikeZone'
    if ($previous -eq 'StrikeZone') {
        Save-OutlastGameConfig -GameRoot $GameRoot -Name 'StrikeZone'
        Save-OutlastActiveConfig -GameRoot $GameRoot
        $next = if (Test-OutlastStore $GameRoot 'Insanity') { 'Insanity' }
                elseif (Test-OutlastStore $GameRoot 'Halcyon') { 'Halcyon' }
                else { '' }
        if ($next) {
            Switch-OutlastMod -GameRoot $GameRoot -Name $next
        } else {
            $files = @(Get-OutlastModFiles 'StrikeZone')
            $targets = @($files | ForEach-Object { Join-Path $layout.Bin $_ }) + @($layout.State, (Join-Path $layout.Bin 'd3d9.dll.off'))
            Invoke-OutlastFileTransaction -GameRoot $GameRoot -Targets $targets -Action {
                foreach ($file in $files) {
                    $live = Join-Path $layout.Bin $file
                    $stored = Join-Path (Join-Path $layout.Stores 'StrikeZone') $file
                    if (Test-Path -LiteralPath $live -PathType Leaf) {
                        if ((Get-FileHash -LiteralPath $live).Hash -ne (Get-FileHash -LiteralPath $stored).Hash) {
                            throw "Changed active file cannot be removed automatically: $live"
                        }
                        Remove-Item -LiteralPath $live -Force -ErrorAction Stop
                    }
                }
                $off = Join-Path $layout.Bin 'd3d9.dll.off'
                if (Test-Path -LiteralPath $off -PathType Leaf) {
                    $stored = Join-Path $store 'd3d9.dll'
                    if ((Get-FileHash -LiteralPath $off).Hash -ne (Get-FileHash -LiteralPath $stored).Hash) {
                        throw "Changed disabled proxy cannot be removed automatically: $off"
                    }
                    Remove-Item -LiteralPath $off -Force -ErrorAction Stop
                }
                if (Test-Path -LiteralPath $layout.State -PathType Leaf) { Remove-Item -LiteralPath $layout.State -Force -ErrorAction Stop }
            }
        }
    }

    # Keep the user's tuned INI and Documents profile as recovery material.
    foreach ($file in @('d3d9.dll','openxr_loader.dll','Outlast1VR.exe','strikezone_logo.jpg')) {
        $path = Join-Path $store $file
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
    }
    Write-OutlastLaunchers -GameRoot $GameRoot -RuntimePath (Join-Path $PSScriptRoot 'OutlastVR-Switch.ps1')
    foreach ($marker in @((Join-Path $PSScriptRoot '.installed_version_c'), (Join-Path $GameRoot '.pcvrhub_version_c'))) {
        if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force -ErrorAction Stop }
    }
    Write-Host '[OK] StrikeZoneVR removed; other installed Outlast VR routes were preserved.' -ForegroundColor Green
} catch {
    Write-Host "[X] StrikeZoneVR was not fully removed: $_" -ForegroundColor Red
    exit 1
}
