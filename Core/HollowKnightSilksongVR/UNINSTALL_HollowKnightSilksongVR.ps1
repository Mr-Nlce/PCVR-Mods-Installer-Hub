param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('astienth','flat')]
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

function Test-SilksongVrRoot([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path 'Hollow Knight Silksong_Data') -PathType Container) -or
           (Test-Path -LiteralPath (Join-Path $Path 'BepInEx\plugins\HollowKnightSilksong_VR.dll') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'BepInEx\plugins\HollowKnightSilksong_VR.dll.off') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'BepInEx\plugins\SilksongFlatToVR4.dll') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'BepInEx\plugins\SilksongFlatToVR4.dll.off') -PathType Leaf)
}

function Resolve-SilksongVrRoot([string]$Preferred, [string]$MarkerRoot) {
    if (Test-SilksongVrRoot $Preferred) { return [IO.Path]::GetFullPath($Preferred) }
    try {
        $record = (Get-Content -LiteralPath (Join-Path $MarkerRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-SilksongVrRoot $record) { return [IO.Path]::GetFullPath($record) }
    } catch {}
    try {
        $found = Find-SteamGameFolder -AppId '1030300' -SteamFolderNames @('Hollow Knight Silksong','HollowKnightSilksong','Silksong') -GogNames @('Hollow Knight Silksong')
        if (Test-SilksongVrRoot $found) { return [IO.Path]::GetFullPath($found) }
    } catch {}
    return $null
}

function Get-SilksongModPresence([string]$Root) {
    $pluginRoot = Join-Path $Root 'BepInEx\plugins'
    return [pscustomobject]@{
        Astienth = (Test-Path -LiteralPath (Join-Path $pluginRoot 'HollowKnightSilksong_VR.dll') -PathType Leaf) -or
                    (Test-Path -LiteralPath (Join-Path $pluginRoot 'HollowKnightSilksong_VR.dll.off') -PathType Leaf)
        Flat = (Test-Path -LiteralPath (Join-Path $pluginRoot 'SilksongFlatToVR4.dll') -PathType Leaf) -or
               (Test-Path -LiteralPath (Join-Path $pluginRoot 'SilksongFlatToVR4.dll.off') -PathType Leaf)
    }
}

function Set-SilksongSinglePluginActive([string]$Root, [string]$PluginName) {
    $pluginRoot = Join-Path $Root 'BepInEx\plugins'
    $live = Join-Path $pluginRoot $PluginName
    $parked = $live + '.off'
    if ((Test-Path -LiteralPath $parked -PathType Leaf) -and -not (Test-Path -LiteralPath $live -PathType Leaf)) {
        Rename-Item -LiteralPath $parked -NewName $PluginName -Force -ErrorAction Stop
        Write-OK "Activated the remaining plugin: $PluginName"
    }
}

$GameRoot = Resolve-SilksongVrRoot -Preferred $GameRoot -MarkerRoot $StateRoot
if (-not $GameRoot) { Write-Warn 'Hollow Knight Silksong was not found. Nothing was changed.'; Stop-Here 1 }
if (Get-Process -Name 'Hollow Knight Silksong' -ErrorAction SilentlyContinue) { Write-Warn 'Close Hollow Knight Silksong before removing or switching a plugin.'; Stop-Here 1 }

$pluginName = if ($Mod -eq 'astienth') { 'HollowKnightSilksong_VR.dll' } else { 'SilksongFlatToVR4.dll' }
$displayName = if ($Mod -eq 'astienth') { 'Astienth' } else { 'Flat to VR' }
$plugin = Join-Path $GameRoot "BepInEx\plugins\$pluginName"
$present = (Test-Path -LiteralPath $plugin -PathType Leaf) -or (Test-Path -LiteralPath ($plugin + '.off') -PathType Leaf)
if (-not $present) { Write-Info "$displayName is not detected. Nothing was changed."; Stop-Here 0 }
if (-not $HubConfirmed) {
    $answer = (Read-Host "  Type yes to remove $displayName only").Trim()
    if ($answer -ne 'yes') { Write-Info 'Nothing was changed.'; Stop-Here 0 }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host " Hollow Knight Silksong VR - remove $displayName" -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host "  Game: $GameRoot" -ForegroundColor Gray

foreach ($candidate in @($plugin, ($plugin + '.off'))) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { Remove-Item -LiteralPath $candidate -Force -ErrorAction Stop }
}
Write-OK "Removed the $displayName plugin."

$after = Get-SilksongModPresence -Root $GameRoot
$launchRoot = Join-Path $GameRoot 'VRLaunch'
foreach ($launcher in @('Silksong VR (Astienth).bat','Silksong VR (Flat to VR).bat')) {
    $path = Join-Path $launchRoot $launcher
    if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
}

if ($after.Astienth -and -not $after.Flat) {
    Set-SilksongSinglePluginActive -Root $GameRoot -PluginName 'HollowKnightSilksong_VR.dll'
    Write-Info 'Shared BepInEx and Astienth game-data support files were retained.'
} elseif ($after.Flat -and -not $after.Astienth) {
    Set-SilksongSinglePluginActive -Root $GameRoot -PluginName 'SilksongFlatToVR4.dll'
    Write-Info 'Shared BepInEx and OpenVR support files were retained.'
} elseif (-not $after.Astienth -and -not $after.Flat) {
    $loader = Join-Path $GameRoot 'winhttp.dll'
    $parkedLoader = Join-Path $GameRoot 'winhttp.dll.pcvrhub_off'
    if (Test-Path -LiteralPath $loader -PathType Leaf) {
        if (Test-Path -LiteralPath $parkedLoader -PathType Leaf) {
            try {
                if ((Get-FileHash -LiteralPath $loader -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $parkedLoader -Algorithm SHA256).Hash) {
                    Remove-Item -LiteralPath $loader -Force -ErrorAction Stop
                    Write-OK 'Removed the byte-identical active duplicate; the shared loader remains parked.'
                } else {
                    Write-Warn 'Both active and parked winhttp loaders exist but differ. The active loader was left untouched; resolve the duplicate manually.'
                }
            } catch { Write-Warn 'Both active and parked winhttp loaders exist. They could not be verified, so neither was changed.' }
        } else {
            Rename-Item -LiteralPath $loader -NewName 'winhttp.dll.pcvrhub_off' -Force -ErrorAction Stop
            Write-OK 'Parked the shared BepInEx loader; the game now starts flat.'
        }
    }
    $marker = Join-Path $StateRoot '.installed_path'
    if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue }
    Write-Info 'Inert shared runtime files and settings were kept so no original or shared game file is guessed away.'
}

if ((Test-Path -LiteralPath $launchRoot -PathType Container) -and @(Get-ChildItem -LiteralPath $launchRoot -Force -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item -LiteralPath $launchRoot -Force -ErrorAction SilentlyContinue
}
Write-OK "$displayName was removed. Saves and the other VR mod were preserved."
Stop-Here 0
