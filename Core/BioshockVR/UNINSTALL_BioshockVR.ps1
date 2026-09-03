param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('balouza','biovrdev')]
    [string]$Mod,
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Stop-Here  { param([int]$Code=0); if (-not $NoPause) { Write-Host ''; Read-Host '  Press Enter to exit' | Out-Null }; exit $Code }

$bioFiles = @(
    'dxgi.dll','BioshockVR.dll','BioshockVR.ini','openvr_api.dll',
    'openxr_loader_standard.dll','openxr_loader_steam.dll','openxr_loader.dll',
    'Setup.bat','Uninstall.bat','README.txt','changelog.txt','logs\CollectLogs.bat'
)
$balFiles = @('xinput1_3.dll','bioshockvr.dll','bvr_steamvr32.dll','openvr_api.dll')

function Test-BioRoot([string]$Path) {
    if (-not $Path) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path 'Build\Final\BioshockHD.exe') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'Build\FinalEpic\BioshockHD.exe') -PathType Leaf)
}

if (-not (Test-BioRoot $GameRoot)) {
    try {
        $record = (Get-Content -LiteralPath (Join-Path $StateRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-BioRoot $record) { $GameRoot = $record }
    } catch {}
}
if (-not (Test-BioRoot $GameRoot)) {
    try {
        $found = Find-SteamGameFolder -AppId 409710 -SteamFolderNames @('BioShock Remastered') -ProbeExe 'Build\Final\BioshockHD.exe'
        if (Test-BioRoot $found) { $GameRoot = $found }
    } catch {}
}
if (-not (Test-BioRoot $GameRoot)) {
    foreach ($candidate in @(
        'C:\GOG Games\BioShock Remastered',
        'C:\Program Files (x86)\GOG Galaxy\Games\BioShock Remastered',
        'C:\Program Files\Epic Games\BioshockRemastered'
    )) { if (Test-BioRoot $candidate) { $GameRoot = $candidate; break } }
}
if (-not (Test-BioRoot $GameRoot)) {
    Write-Warn 'BioShock Remastered was not found. Nothing was changed.'
    Stop-Here 1
}

$buildDir = if (Test-Path -LiteralPath (Join-Path $GameRoot 'Build\Final\BioshockHD.exe')) {
    Join-Path $GameRoot 'Build\Final'
} else { Join-Path $GameRoot 'Build\FinalEpic' }
if (Get-Process -Name 'BioshockHD' -ErrorAction SilentlyContinue) {
    Write-Warn 'BioShock is running. Close it before removing a VR mod.'
    Stop-Here 1
}

$storeRoot = Join-Path $buildDir '_vrmods'
$bioStore = Join-Path $storeRoot 'biovrdev'
$balStore = Join-Path $storeRoot 'balouza'
$bioActive = (Test-Path -LiteralPath (Join-Path $buildDir 'dxgi.dll') -PathType Leaf) -or (Test-Path -LiteralPath ((Join-Path $buildDir 'dxgi.dll') + '-') -PathType Leaf)
$balActive = (Test-Path -LiteralPath (Join-Path $buildDir 'xinput1_3.dll') -PathType Leaf) -or (Test-Path -LiteralPath ((Join-Path $buildDir 'xinput1_3.dll') + '-') -PathType Leaf)
$bioPresent = (Test-Path -LiteralPath (Join-Path $bioStore 'dxgi.dll') -PathType Leaf) -or $bioActive
$balPresent = (Test-Path -LiteralPath (Join-Path $balStore 'xinput1_3.dll') -PathType Leaf) -or $balActive
$targetName = if ($Mod -eq 'biovrdev') { 'BioVRDev' } else { 'balouza' }
$targetStore = if ($Mod -eq 'biovrdev') { $bioStore } else { $balStore }
$targetFiles = if ($Mod -eq 'biovrdev') { $bioFiles } else { $balFiles }
$targetInjector = if ($Mod -eq 'biovrdev') { 'dxgi.dll' } else { 'xinput1_3.dll' }
$otherName = if ($Mod -eq 'biovrdev') { 'balouza' } else { 'BioVRDev' }
$otherStore = if ($Mod -eq 'biovrdev') { $balStore } else { $bioStore }
$otherFiles = if ($Mod -eq 'biovrdev') { $balFiles } else { $bioFiles }
$otherInjector = if ($Mod -eq 'biovrdev') { 'xinput1_3.dll' } else { 'dxgi.dll' }
$otherPresent = if ($Mod -eq 'biovrdev') { $balPresent } else { $bioPresent }
$targetPresent = if ($Mod -eq 'biovrdev') { $bioPresent } else { $balPresent }
$targetActive = if ($Mod -eq 'biovrdev') { $bioActive } else { $balActive }

Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host " BioShock Remastered VR - remove $targetName" -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host "  Game: $GameRoot" -ForegroundColor Gray
Write-Host "  Installed: balouza=$balPresent, BioVRDev=$bioPresent" -ForegroundColor Gray
if (-not $targetPresent) {
    Write-Info "$targetName is not present in the Hub's protected mod store. Nothing was changed."
    Stop-Here 0
}
if (-not $HubConfirmed) {
    $answer = (Read-Host "  Type yes to remove $targetName only").Trim()
    if ($answer -ne 'yes') { Write-Info 'Nothing was changed.'; Stop-Here 0 }
}

# If the selected mod is active, verify the complete remaining payload before
# touching anything. A failed switch must never leave a mixture beside the exe.
if ($targetActive -and $otherPresent) {
    $missing = @($otherFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $otherStore $_) -PathType Leaf) })
    if ($missing.Count -gt 0) {
        Write-Warn "Cannot switch safely to $otherName; its protected copy is incomplete: $($missing -join ', ')"
        Write-Info 'Nothing was changed. Re-run the installer to repair the protected copy.'
        Stop-Here 1
    }
}

# BioVRDev changes Bioshock.ini and records a byte-for-byte backup. Restore all
# exact known locations before its config file is parked or removed.
if ($Mod -eq 'biovrdev') {
    $iniCandidates = New-Object 'System.Collections.Generic.List[string]'
    foreach ($iniSource in @((Join-Path $buildDir 'BioshockVR.ini'), (Join-Path $bioStore 'BioshockVR.ini'))) {
        if (-not (Test-Path -LiteralPath $iniSource -PathType Leaf)) { continue }
        try {
            $line = Get-Content -LiteralPath $iniSource | Where-Object { $_ -match '^GameIniPath=' } | Select-Object -First 1
            if ($line) { [void]$iniCandidates.Add(($line -replace '^GameIniPath=', '').Trim()) }
        } catch {}
    }
    foreach ($known in @(
        (Join-Path $env:APPDATA 'My Games\BioshockHD\Bioshock\Bioshock.ini'),
        (Join-Path $env:APPDATA 'BioshockHD\Bioshock\Bioshock.ini'),
        (Join-Path $env:APPDATA 'My Games\Bioshock Epic HD\Bioshock\Bioshock.ini'),
        (Join-Path $env:APPDATA 'Bioshock Epic HD\Bioshock\Bioshock.ini'),
        (Join-Path $env:USERPROFILE 'Documents\My Games\BioshockHD\Bioshock\Bioshock.ini'),
        (Join-Path $env:USERPROFILE 'Documents\My Games\Bioshock Epic HD\Bioshock\Bioshock.ini')
    )) { if (-not $iniCandidates.Contains($known)) { [void]$iniCandidates.Add($known) } }
    foreach ($ini in $iniCandidates) {
        $backup = $ini + '.vrbackup'
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { continue }
        try {
            Copy-Item -LiteralPath $backup -Destination $ini -Force
            if ((Get-FileHash -LiteralPath $backup).Hash -ne (Get-FileHash -LiteralPath $ini).Hash) { throw 'verification failed' }
            Remove-Item -LiteralPath $backup -Force
            Write-OK "Restored $ini"
        } catch { Write-Warn "Could not restore $backup; it was kept."; Stop-Here 1 }
    }
    $tuned = Join-Path $buildDir 'BioshockVR.ini'
    if ($targetActive -and (Test-Path -LiteralPath $tuned -PathType Leaf)) {
        try { Copy-Item -LiteralPath $tuned -Destination ($tuned + '.bak') -Force; Write-OK 'Kept BioVRDev tuning as BioshockVR.ini.bak' } catch {}
    }
}

if ($targetActive) {
    foreach ($file in $targetFiles) {
        $dest = Join-Path $buildDir $file
        foreach ($victim in @($dest, ($dest + '-'))) {
            if (Test-Path -LiteralPath $victim) { Remove-Item -LiteralPath $victim -Force }
        }
        # Restore a wrapper which the Hub backed up before it installed this
        # filename. When the remaining mod owns the same name it will replace it
        # immediately below, so no mixed intermediate install is launched.
        if (Test-Path -LiteralPath ($dest + '.hubbak') -PathType Leaf) {
            Move-Item -LiteralPath ($dest + '.hubbak') -Destination $dest -Force
        }
    }
    if ($otherPresent) {
        foreach ($file in $otherFiles) {
            $src = Join-Path $otherStore $file
            $dest = Join-Path $buildDir $file
            $parent = Split-Path $dest -Parent
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            if (Test-Path -LiteralPath ($dest + '-')) { Remove-Item -LiteralPath ($dest + '-') -Force }
            Copy-Item -LiteralPath $src -Destination $dest -Force
        }
        if (-not (Test-Path -LiteralPath (Join-Path $buildDir $otherInjector) -PathType Leaf)) {
            Write-Warn "The switch to $otherName did not verify. Its protected store was kept."
            Stop-Here 1
        }
        Write-OK "$otherName is now the active VR mod."
    }
}

# Only exact Hub-owned targets below the validated Build directory are removed.
if (Test-Path -LiteralPath $targetStore -PathType Container) { Remove-Item -LiteralPath $targetStore -Recurse -Force }
$launchRel = if ($Mod -eq 'biovrdev') { 'VRLaunch\BioShock VR (BioVRDev).bat' } else { 'VRLaunch\BioShock VR (balouza).bat' }
$launch = Join-Path $buildDir $launchRel
if (Test-Path -LiteralPath $launch) { Remove-Item -LiteralPath $launch -Force }
$launchDir = Join-Path $buildDir 'VRLaunch'
if ((Test-Path -LiteralPath $launchDir -PathType Container) -and @(Get-ChildItem -LiteralPath $launchDir -Force).Count -eq 0) {
    Remove-Item -LiteralPath $launchDir -Force
}
$versionMarkerName = if ($Mod -eq 'biovrdev') { '.installed_version_b' } else { '.installed_version' }
$versionMarker = Join-Path $StateRoot $versionMarkerName
if (Test-Path -LiteralPath $versionMarker) { Remove-Item -LiteralPath $versionMarker -Force }
if (-not $otherPresent) {
    $pathMarker = Join-Path $StateRoot '.installed_path'
    if (Test-Path -LiteralPath $pathMarker) { Remove-Item -LiteralPath $pathMarker -Force }
}

Write-OK "$targetName was removed. The base game and save games were preserved."
if ($Mod -eq 'biovrdev') { Write-Info 'LocalAppData logs/settings were kept deliberately, as was BioshockVR.ini.bak.' }
Stop-Here 0
