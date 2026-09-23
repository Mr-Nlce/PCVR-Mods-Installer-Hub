param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-DarktideUninstall([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-DarktideOwnedRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'binaries\Darktide.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_darktidevr_ownership.csv') -PathType Leaf))
}
$selectedRoute=''
if (Test-DarktideOwnedRoot $GameRoot) {
    $selectedRoute=if (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_darktide_depot_24735202') -PathType Leaf) { 'Depot' } else { 'Current' }
} else {
    $roots=@()
    foreach ($entry in @(
        [pscustomobject]@{ Route='Current'; Receipt='.installed_path' },
        [pscustomobject]@{ Route='Depot'; Receipt='.installed_path_depot' }
    )) {
        try {
            $saved=(Get-Content -LiteralPath (Join-Path $PSScriptRoot $entry.Receipt) -Raw -ErrorAction Stop).Trim()
            if (Test-DarktideOwnedRoot $saved) { $roots+=[pscustomobject]@{ Route=$entry.Route; Root=$saved } }
        } catch {}
    }
    $roots=@($roots | Group-Object Root | ForEach-Object { $_.Group[0] })
    if ($roots.Count -gt 1) {
        Write-Host 'Choose the independent DarktideVR copy to remove:' -ForegroundColor Yellow
        for ($i=0; $i -lt $roots.Count; $i++) { Write-Host "  [$($i+1)] $($roots[$i].Route): $($roots[$i].Root)" -ForegroundColor White }
        Write-Host '  [Q] Cancel' -ForegroundColor Gray
        while ($true) {
            $choice=([string](Read-Host 'Your choice')).Trim().ToUpperInvariant()
            if ($choice -eq 'Q') { Finish-DarktideUninstall 0 }
            $number=0
            if ([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $roots.Count) {
                $GameRoot=$roots[$number-1].Root; $selectedRoute=$roots[$number-1].Route; break
            }
        }
    } elseif ($roots.Count -eq 1) {
        $GameRoot=$roots[0].Root; $selectedRoute=$roots[0].Route
    }
}
if (-not (Test-DarktideOwnedRoot $GameRoot)) { Write-Host '[X] No Hub-owned DarktideVR installation was found. Nothing was guessed or deleted.' -ForegroundColor Red; Finish-DarktideUninstall 1 }
if (Get-Process -Name Darktide -ErrorAction SilentlyContinue) { Write-Host '[X] Close Darktide before removing VR mode.' -ForegroundColor Red; Finish-DarktideUninstall 1 }
if (-not $HubConfirmed) { if ((Read-Host "Remove Hub-owned DarktideVR files from '$GameRoot'? Type REMOVE").Trim() -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-DarktideUninstall 0 } }
$modeScript=Join-Path $GameRoot 'mods\darktidevr\darktidevr-mode.ps1'
if (Test-Path -LiteralPath $modeScript -PathType Leaf) {
    $oldLocalAppData=$env:LOCALAPPDATA
    try {
        if ($selectedRoute -eq 'Depot') {
            $depotState=Join-Path $GameRoot '.pcvrhub_darktide_state'
            if (-not (Test-Path -LiteralPath $depotState -PathType Container)) { [void][IO.Directory]::CreateDirectory($depotState) }
            $env:LOCALAPPDATA=(Get-Item -LiteralPath $depotState).FullName
        }
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $modeScript -Mode flat -GameRoot $GameRoot
        if ($LASTEXITCODE -ne 0) { Write-Host '[X] The publisher mode switch could not restore flat mode. VR files were left in place.' -ForegroundColor Red; Finish-DarktideUninstall 1 }
    } finally { $env:LOCALAPPDATA=$oldLocalAppData }
}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'darktidevr'
Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] Darktide Mod Loader and Darktide Mod Framework remain for other mods.' -ForegroundColor Gray
Write-Host '[KEEP] Flat/VR user settings and recovery data under LocalAppData remain.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_darktidevr_ownership.csv') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if ($selectedRoute -ne 'Depot') { Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Force -ErrorAction SilentlyContinue }
}
Finish-DarktideUninstall 0
