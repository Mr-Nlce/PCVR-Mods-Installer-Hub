param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('naluluna','lufz')]
    [string]$Mod,
    [string]$InstallRoot = '',
    [string[]]$GameRoot = @(),
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

function Test-ForzaVrRoot([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path 'NALULUNA\fh5vr.exe') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'lufz\vrmod-launcher.exe') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'vrmod-launcher.exe') -PathType Leaf)
}

function Resolve-ForzaVrRoot([string]$Preferred, [string]$MarkerRoot) {
    if (Test-ForzaVrRoot $Preferred) { return [IO.Path]::GetFullPath($Preferred) }
    try {
        $record = (Get-Content -LiteralPath (Join-Path $MarkerRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-ForzaVrRoot $record) { return [IO.Path]::GetFullPath($record) }
    } catch {}
    foreach ($candidate in @('C:\Games\Forza Horizon 5 VR','D:\Games\Forza Horizon 5 VR','E:\Games\Forza Horizon 5 VR')) {
        if (Test-ForzaVrRoot $candidate) { return $candidate }
    }
    return $null
}

function Get-JsonPathStrings($Value) {
    $out = New-Object 'System.Collections.Generic.List[string]'
    function Visit-JsonValue($Node) {
        if ($null -eq $Node) { return }
        if ($Node -is [string]) {
            if ([IO.Path]::IsPathRooted([string]$Node)) { [void]$out.Add([string]$Node) }
            return
        }
        if ($Node -is [System.Collections.IDictionary]) {
            foreach ($key in $Node.Keys) { Visit-JsonValue $Node[$key] }
            return
        }
        if (($Node -is [System.Collections.IEnumerable]) -and -not ($Node -is [string])) {
            foreach ($item in $Node) { Visit-JsonValue $item }
            return
        }
        foreach ($property in @($Node.PSObject.Properties)) { Visit-JsonValue $property.Value }
    }
    Visit-JsonValue $Value
    return $out.ToArray()
}

function Get-ForzaGameRoots([string]$LufzRoot, [string[]]$PreferredRoots = @()) {
    $roots = New-Object 'System.Collections.Generic.List[string]'
    $add = {
        param([string]$Path)
        if (-not $Path) { return }
        $candidate = $Path.Trim().Trim('"')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $candidate = Split-Path -Parent $candidate }
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { return }
        $full = [IO.Path]::GetFullPath($candidate).TrimEnd('\')
        if (-not $roots.Contains($full)) { [void]$roots.Add($full) }
    }
    foreach ($preferred in @($PreferredRoots)) { & $add $preferred }
    try { & $add (Find-SteamGameFolder -AppId '1551360' -SteamFolderNames @('ForzaHorizon5','Forza Horizon 5') -ProbeExe 'ForzaHorizon5.exe') } catch {}
    foreach ($drive in @('C','D','E')) {
        foreach ($relative in @('XboxGames\Forza Horizon 5\Content','XboxGames\ForzaHorizon5\Content')) { & $add "${drive}:\$relative" }
    }
    try {
        $package = Get-AppxPackage -Name 'Microsoft.624F8B84B80_8wekyb3d8bbwe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($package -and $package.InstallLocation) { & $add ([string]$package.InstallLocation) }
    } catch {}
    if ($LufzRoot) {
        foreach ($libraryFile in @('profiles\games_library.json','profiles\launcher_settings.json')) {
            $path = Join-Path $LufzRoot $libraryFile
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
            try {
                $json = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
                foreach ($value in (Get-JsonPathStrings $json)) { & $add $value }
            } catch {}
        }
    }
    return $roots.ToArray()
}

function Remove-OwnedLeaf([string]$Root, [string]$Relative) {
    $path = Join-Path $Root $Relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force -ErrorAction Stop
        Write-OK "Removed $Relative"
    }
}

function Remove-EmptyOwnedFolders([string]$Root, [string[]]$RelativeFolders) {
    foreach ($relative in $RelativeFolders) {
        $path = Join-Path $Root $relative
        if ((Test-Path -LiteralPath $path -PathType Container) -and @(Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-ForzaShortcut([string]$RemovedLauncher, [string]$RemainingLauncher, [string]$SharedRoot) {
    $shortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Forza Horizon 5 VR.lnk'
    if (-not (Test-Path -LiteralPath $shortcut -PathType Leaf)) { return }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $current = $shell.CreateShortcut($shortcut)
        if (-not $current.TargetPath -or ([IO.Path]::GetFullPath($current.TargetPath) -ine [IO.Path]::GetFullPath($RemovedLauncher))) { return }
        if ($RemainingLauncher -and (Test-Path -LiteralPath $RemainingLauncher -PathType Leaf)) {
            $current.TargetPath = $RemainingLauncher
            $current.WorkingDirectory = Split-Path -Parent $RemainingLauncher
            $icon = Join-Path $SharedRoot 'ForzaHorizon5_VR.ico'
            $current.IconLocation = if (Test-Path -LiteralPath $icon) { $icon } else { $RemainingLauncher }
            $current.Save()
            Write-OK 'Desktop shortcut now starts the remaining VR mod.'
        } else {
            Remove-Item -LiteralPath $shortcut -Force
            Write-OK 'Removed the obsolete desktop shortcut.'
        }
    } catch { Write-Warn 'Could not update the desktop shortcut; the VR payload itself was removed.' }
}

$InstallRoot = Resolve-ForzaVrRoot -Preferred $InstallRoot -MarkerRoot $StateRoot
if (-not $InstallRoot) { Write-Warn 'The separate Forza Horizon 5 VR folder was not found. Nothing was changed.'; Stop-Here 1 }
$nalRoot = Join-Path $InstallRoot 'NALULUNA'
$lufzSubRoot = Join-Path $InstallRoot 'lufz'
$lufzRoot = if (Test-Path -LiteralPath (Join-Path $lufzSubRoot 'vrmod-launcher.exe') -PathType Leaf) { $lufzSubRoot }
            elseif (Test-Path -LiteralPath (Join-Path $InstallRoot 'vrmod-launcher.exe') -PathType Leaf) { $InstallRoot }
            else { $lufzSubRoot }
$selectedRoot = if ($Mod -eq 'naluluna') { $nalRoot } else { $lufzRoot }
$selectedLauncher = if ($Mod -eq 'naluluna') { Join-Path $nalRoot 'fh5vr.exe' } else { Join-Path $lufzRoot 'vrmod-launcher.exe' }
$remainingLauncher = if ($Mod -eq 'naluluna') { Join-Path $lufzRoot 'vrmod-launcher.exe' } else { Join-Path $nalRoot 'fh5vr.exe' }
if (-not (Test-Path -LiteralPath $selectedLauncher -PathType Leaf)) { Write-Info "$Mod is not detected. Nothing was changed."; Stop-Here 0 }

foreach ($processName in @('ForzaHorizon5','fh5vr','vrmod-launcher')) {
    if (Get-Process -Name $processName -ErrorAction SilentlyContinue) { Write-Warn 'Close Forza Horizon 5 and both VR launchers before uninstalling.'; Stop-Here 1 }
}
if (-not $HubConfirmed) {
    $answer = (Read-Host "  Type yes to remove $Mod only").Trim()
    if ($answer -ne 'yes') { Write-Info 'Nothing was changed.'; Stop-Here 0 }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host " Forza Horizon 5 VR - remove $Mod" -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host "  VR package: $selectedRoot" -ForegroundColor Gray

$gameRoots = @(Get-ForzaGameRoots -LufzRoot $lufzRoot -PreferredRoots $GameRoot)
if ($Mod -eq 'naluluna') {
    if ($gameRoots.Count -eq 0) {
        Write-Warn 'No retail game folder could be verified. The NALULUNA package was kept.'
        Write-Info 'This preserves the matching hook needed to identify a copied dxgi.dll later.'
        Stop-Here 1
    }
    $hook = Join-Path $nalRoot 'fh5vrhook.dll'
    foreach ($gameDir in $gameRoots) {
        $proxy = Join-Path $gameDir 'dxgi.dll'
        if (-not (Test-Path -LiteralPath $proxy -PathType Leaf) -or -not (Test-Path -LiteralPath $hook -PathType Leaf)) { continue }
        try {
            if ((Get-FileHash -LiteralPath $proxy -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $hook -Algorithm SHA256).Hash) {
                Remove-Item -LiteralPath $proxy -Force
                Write-OK "Removed the verified NALULUNA proxy from $gameDir"
            } else { Write-Warn "Left $proxy untouched: it is not byte-identical to this NALULUNA hook." }
        } catch { Write-Warn "Could not verify or remove $proxy; it was left untouched." }
    }
    foreach ($file in @('fh5vr.exe','fh5vrhook.dll','openxr_loader.dll')) { Remove-OwnedLeaf -Root $nalRoot -Relative $file }
    Remove-EmptyOwnedFolders -Root $nalRoot -RelativeFolders @('.')
} else {
    Write-Host ''
    Write-Host '  The author-provided VRMod launcher will open now.' -ForegroundColor White
    Write-Host "  Select Forza Horizon 5, click 'Uninstall VR Mod', then close VRMod." -ForegroundColor Yellow
    Write-Host '  The Hub will verify the deployment before removing the launcher package.' -ForegroundColor Gray
    Write-Host ''
    try { Start-Process -FilePath $selectedLauncher -WorkingDirectory $lufzRoot -Wait -ErrorAction Stop }
    catch { Write-Warn "Could not start the author's uninstaller: $($_.Exception.Message)"; Stop-Here 1 }

    if ($gameRoots.Count -eq 0) {
        Write-Warn 'No deployed game folder could be verified after the author launcher closed.'
        Write-Info 'The separate launcher package was kept so the Hub cannot strand an unverified DXGI deployment.'
        Stop-Here 1
    }
    $deployments = @()
    foreach ($gameDir in $gameRoots) {
        if (Test-Path -LiteralPath (Join-Path $gameDir '.vrmod_install.json') -PathType Leaf) { $deployments += $gameDir }
    }
    if ($deployments.Count) {
        Write-Warn "VRMod is still deployed in: $($deployments -join ', ')"
        Write-Info "The separate launcher package was kept. Open it again and complete 'Uninstall VR Mod'."
        Stop-Here 1
    }
    $lufzFiles = @(
        'dxgi.dll','openxr_loader.dll','README.md','VERSION','vrmod_inject_dll.dll','vrmod-fg-worker.exe','vrmod-launcher.exe',
        'profiles\default.json','profiles\forza_horizon_5.json','profiles\forza_horizon_6.json',
        'profiles\game_icons\forzahorizon5.png','profiles\game_icons\forzahorizon6.png','profiles\game_icons\mnm.png',
        'profiles\headset_catalog.json','profiles\layout_catalog.json','profiles\monsters_and_memories.json'
    )
    foreach ($file in $lufzFiles) { Remove-OwnedLeaf -Root $lufzRoot -Relative $file }
    Remove-EmptyOwnedFolders -Root $lufzRoot -RelativeFolders @('profiles\game_icons','profiles','.')
    $versionMarker = Join-Path $StateRoot '.installed_version'
    if (Test-Path -LiteralPath $versionMarker -PathType Leaf) { Remove-Item -LiteralPath $versionMarker -Force -ErrorAction SilentlyContinue }
    $durable = Join-Path $InstallRoot '.pcvrhub_version'
    if (Test-Path -LiteralPath $durable -PathType Leaf) { Remove-Item -LiteralPath $durable -Force -ErrorAction SilentlyContinue }
}

Update-ForzaShortcut -RemovedLauncher $selectedLauncher -RemainingLauncher $remainingLauncher -SharedRoot $InstallRoot
$nalPresent = Test-Path -LiteralPath (Join-Path $nalRoot 'fh5vr.exe') -PathType Leaf
$lufzPresent = (Test-Path -LiteralPath (Join-Path $lufzSubRoot 'vrmod-launcher.exe') -PathType Leaf) -or
               (Test-Path -LiteralPath (Join-Path $InstallRoot 'vrmod-launcher.exe') -PathType Leaf)
if (-not $nalPresent -and -not $lufzPresent) {
    foreach ($file in @('.installed_path','.installed_version','.launch_exe')) {
        $path = Join-Path $StateRoot $file
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
    }
    $icon = Join-Path $InstallRoot 'ForzaHorizon5_VR.ico'
    if (Test-Path -LiteralPath $icon -PathType Leaf) { Remove-Item -LiteralPath $icon -Force -ErrorAction SilentlyContinue }
}

Write-OK "$Mod was removed without deleting the retail game, saves, settings, or unrelated files."
Stop-Here 0
