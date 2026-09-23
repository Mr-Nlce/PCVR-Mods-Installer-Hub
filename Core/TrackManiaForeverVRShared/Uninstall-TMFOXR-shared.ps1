param(
    [ValidateSet('Nations','United')][string]$Edition = 'Nations',
    [string]$GameRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'TMFOXRElevatedOperations.ps1')

function Get-TMFOXRRemovalConfig([string]$Name) {
    if ($Name -eq 'United') {
        return [pscustomobject]@{
            Title='TrackMania United Forever'; AppId='7200'; SteamFolders=@('TrackMania United')
            FallbackPaths=@('C:\Program Files (x86)\TmUnitedForever'); HubFolder='TrackManiaUnitedForeverVR'
            Identity='tmfoxr_united_direct'
        }
    }
    return [pscustomobject]@{
        Title='TrackMania Nations Forever'; AppId='11020'; SteamFolders=@('TrackMania Nations Forever')
        FallbackPaths=@('C:\Program Files (x86)\TmNationsForever'); HubFolder='TrackManiaNationsForeverVR'
        Identity='tmfoxr_nations_direct'
    }
}

function Finish-TMFOXRRemoval([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}

function Get-TMFOXRProductsRoot {
    $override = ('' + $env:PCVR_TMFOXR_PRODUCTS_ROOT).Trim()
    if ($override) { return [IO.Path]::GetFullPath($override) }
    return [IO.Path]::Combine([Environment]::GetFolderPath('LocalApplicationData'),'TMLoader','database','TmForever','products')
}

function Get-TMFOXRRemovalCoreRoot {
    $override = ('' + $env:PCVR_TMFOXR_CORE_ROOT).Trim()
    if ($override) { return [IO.Path]::GetFullPath($override) }
    return [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

function Test-TMFOXRDirectRoot([string]$Path,[string]$Identity) {
    if (-not $Path) { return $false }
    try {
        return ((Test-Path -LiteralPath (Join-Path $Path 'TmForever.exe') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $Path ('.pcvrhub_' + $Identity + '_ownership.csv')) -PathType Leaf))
    } catch { return $false }
}

function Find-TMFOXRDirectRoot($Config,[string]$Suggested='') {
    if (Test-TMFOXRDirectRoot $Suggested $Config.Identity) { return [IO.Path]::GetFullPath($Suggested) }
    $receipt = Join-Path (Join-Path (Get-TMFOXRRemovalCoreRoot) $Config.HubFolder) '.installed_path'
    try {
        $recorded = (Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop).Trim()
        if (Test-TMFOXRDirectRoot $recorded $Config.Identity) { return [IO.Path]::GetFullPath($recorded) }
    } catch {}
    try {
        $found = Find-SteamGameFolder -AppId $Config.AppId -SteamFolderNames $Config.SteamFolders -ProbeExe 'TmForever.exe'
        if (Test-TMFOXRDirectRoot $found $Config.Identity) { return [IO.Path]::GetFullPath($found) }
    } catch {}
    foreach ($candidate in $Config.FallbackPaths) {
        if (Test-TMFOXRDirectRoot $candidate $Config.Identity) { return [IO.Path]::GetFullPath($candidate) }
    }
    return $null
}

function Test-TMFOXRLoaderOwned([string]$ProductsRoot) {
    return [bool]($ProductsRoot -and (Test-Path -LiteralPath (Join-Path $ProductsRoot '.pcvrhub_tmfoxr_loader_ownership.csv') -PathType Leaf -ErrorAction SilentlyContinue))
}

function Set-TMFOXRReceipt([string]$Folder,[string]$Value='') {
    $receipt = Join-Path (Join-Path (Get-TMFOXRRemovalCoreRoot) $Folder) '.installed_path'
    if ($Value) { Write-PCVRAtomicText -Path $receipt -Value ([IO.Path]::GetFullPath($Value)) }
    else { Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue }
}

function Remove-TMFOXRDirect($Config,[string]$Root) {
    if (Test-InstallerTargetWritable -TargetPath (Join-Path $Root 'd3d9.dll')) {
        $result = Uninstall-OwnedModPayload -GameRoot $Root -Identity $Config.Identity
    } else {
        Write-Host 'The game folder needs administrator rights to remove the Hub-owned direct files.' -ForegroundColor Yellow
        Read-Host 'Press Enter to approve the Windows UAC request' | Out-Null
        $result = Invoke-TMFOXRElevatedOwnedOperation -Action UninstallDirect -Edition $Edition -GameRoot $Root
    }
    Write-Host ("[OK] Direct route: removed {0}, restored {1}, preserved {2} changed file(s)." -f $result.Removed,$result.Restored,$result.Preserved) -ForegroundColor Green
    $manifest = Join-Path $Root ('.pcvrhub_' + $Config.Identity + '_ownership.csv')
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        Remove-Item -LiteralPath (Join-Path $Root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    }
    return $result
}

function Find-OtherTMFOXRDirectRoot([string]$Name) {
    return (Find-TMFOXRDirectRoot -Config (Get-TMFOXRRemovalConfig $Name))
}

try {
    $config = Get-TMFOXRRemovalConfig $Edition
    $productsRoot = Get-TMFOXRProductsRoot
    $directRoot = Find-TMFOXRDirectRoot -Config $config -Suggested $GameRoot
    $hasDirect = [bool]$directRoot
    $hasLoader = Test-TMFOXRLoaderOwned $productsRoot
    if (-not $hasDirect -and -not $hasLoader) {
        Write-Host '[X] No Hub-owned TMFOXR installation was found. Nothing was guessed or deleted.' -ForegroundColor Red
        Finish-TMFOXRRemoval 1
    }
    if (Get-Process -Name @('TmForever','TmForeverLauncher','TMLoader') -ErrorAction SilentlyContinue) {
        Write-Host '[X] Close TrackMania and TMLoader before removing TMFOXR.' -ForegroundColor Red
        Finish-TMFOXRRemoval 1
    }

    $removeDirect = $hasDirect
    $removeLoader = $hasLoader
    if ($hasDirect -and $hasLoader) {
        Write-Host 'Both TMFOXR routes are installed:' -ForegroundColor Yellow
        Write-Host ("[1] Direct route for " + $config.Title) -ForegroundColor Cyan
        Write-Host '[2] Shared TMLoader product (affects both TrackMania Forever games)' -ForegroundColor Cyan
        Write-Host '[3] Both routes' -ForegroundColor Cyan
        Write-Host '[Q] Cancel' -ForegroundColor Cyan
        while ($true) {
            $choice = ('' + (Read-Host 'Choose 1, 2, 3 or Q')).Trim().ToUpperInvariant()
            if ($choice -eq '1') { $removeDirect=$true; $removeLoader=$false; break }
            if ($choice -eq '2') { $removeDirect=$false; $removeLoader=$true; break }
            if ($choice -eq '3') { $removeDirect=$true; $removeLoader=$true; break }
            if ($choice -eq 'Q') { Write-Host 'Cancelled. Nothing changed.'; Finish-TMFOXRRemoval 0 }
        }
    } elseif (-not $HubConfirmed) {
        $routeText = if ($hasDirect) { 'the Direct TMFOXR route' } else { 'the shared TMLoader TMFOXR product for both games' }
        $answer = ('' + (Read-Host ("Remove $routeText? Type REMOVE"))).Trim()
        if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-TMFOXRRemoval 0 }
    }

    if ($removeDirect) { [void](Remove-TMFOXRDirect -Config $config -Root $directRoot) }
    if ($removeLoader) {
        $result = Uninstall-OwnedModPayload -GameRoot $productsRoot -Identity 'tmfoxr_loader'
        Write-Host ("[OK] TMLoader route: removed {0}, restored {1}, preserved {2} changed file(s)." -f $result.Removed,$result.Restored,$result.Preserved) -ForegroundColor Green
        if (-not (Test-TMFOXRLoaderOwned $productsRoot)) {
            Remove-Item -LiteralPath (Join-Path $productsRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
        }
    }

    $loaderRemains = Test-TMFOXRLoaderOwned $productsRoot
    foreach ($name in @('Nations','United')) {
        $editionConfig = Get-TMFOXRRemovalConfig $name
        $remainingDirect = Find-TMFOXRDirectRoot -Config $editionConfig
        if ($remainingDirect) { Set-TMFOXRReceipt -Folder $editionConfig.HubFolder -Value $remainingDirect }
        elseif ($loaderRemains) { Set-TMFOXRReceipt -Folder $editionConfig.HubFolder -Value $productsRoot }
        else { Set-TMFOXRReceipt -Folder $editionConfig.HubFolder }
    }

    Write-Host '[KEEP] TMLoader, CoreMod, both games, profiles and generated settings remain untouched.' -ForegroundColor Gray
    Finish-TMFOXRRemoval 0
} catch {
    Write-Host ('[X] ' + $_.Exception.Message) -ForegroundColor Red
    Finish-TMFOXRRemoval 1
}
