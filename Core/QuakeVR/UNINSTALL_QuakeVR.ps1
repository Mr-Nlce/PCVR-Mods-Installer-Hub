param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('romeo','pcvr','unleashed')]
    [string]$Mod,
    [string]$InstallRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Stop-Here  { param([int]$Code=0); if (-not $NoPause) { Write-Host ''; Read-Host '  Press Enter to exit' | Out-Null }; exit $Code }

function Test-QuakeVrRoot([string]$Path, [string]$Kind) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    if ($Kind -eq 'romeo') { return (Test-Path -LiteralPath (Join-Path $Path 'quakevr.exe') -PathType Leaf) }
    if ($Kind -eq 'unleashed') {
        if (-not (Test-Path -LiteralPath (Join-Path $Path 'ironwail.exe') -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $Path 'setup\QuakeVR-Setup.exe') -PathType Leaf)) { return $false }
        try { return ((Get-Content -LiteralPath (Join-Path $Path 'install.json') -Raw | ConvertFrom-Json).product -ceq 'Quake VR: Unleashed') } catch { return $false }
    }
    return (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_ready') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'darkplaces-sdl.exe') -PathType Leaf)
}

function Resolve-QuakeVrRoot([string]$Preferred, [string]$Kind, [string]$MarkerRoot) {
    if (Test-QuakeVrRoot $Preferred $Kind) { return [IO.Path]::GetFullPath($Preferred) }
    $markerName = switch ($Kind) { 'romeo' { '.installed_path_romeo' } 'pcvr' { '.installed_path_pcvr' } 'unleashed' { '.installed_path_unleashed' } }
    try {
        $record = (Get-Content -LiteralPath (Join-Path $MarkerRoot $markerName) -Raw -ErrorAction Stop).Trim()
        if (Test-QuakeVrRoot $record $Kind) { return [IO.Path]::GetFullPath($record) }
    } catch {}
    if ($Kind -eq 'unleashed') {
        $local=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\QuakeVR'
        if (Test-QuakeVrRoot $local $Kind) { return $local }
    }
    $folders = if ($Kind -eq 'romeo') { @('Quake VR') } elseif ($Kind -eq 'pcvr') { @('Quake PCVR') } else { @() }
    foreach ($drive in @('C','D','E')) {
        foreach ($folder in $folders) {
            $candidate = "${drive}:\Games\$folder"
            if (Test-QuakeVrRoot $candidate $Kind) { return $candidate }
        }
    }
    return $null
}

function Remove-QuakeOwnedFiles([string]$Root, [string[]]$RelativeFiles) {
    foreach ($relative in $RelativeFiles) {
        $path = Join-Path $Root $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path -Force -ErrorAction Stop
            Write-OK "Removed $relative"
        }
    }
}

function Remove-EmptyQuakeFolders([string]$Root, [string[]]$RelativeFolders) {
    foreach ($relative in $RelativeFolders) {
        $path = if ($relative -eq '.') { $Root } else { Join-Path $Root $relative }
        if ((Test-Path -LiteralPath $path -PathType Container) -and @(Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}

function Remove-ShortcutWhenOwned([string]$Name, [string]$OwnedTarget) {
    $path = Join-Path ([Environment]::GetFolderPath('Desktop')) $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($path)
        if ($shortcut.TargetPath -and ([IO.Path]::GetFullPath($shortcut.TargetPath) -ieq [IO.Path]::GetFullPath($OwnedTarget))) {
            Remove-Item -LiteralPath $path -Force
            Write-OK "Removed desktop shortcut $Name"
        }
    } catch { Write-Warn "Could not inspect desktop shortcut $Name; it was left untouched." }
}

$InstallRoot = Resolve-QuakeVrRoot -Preferred $InstallRoot -Kind $Mod -MarkerRoot $StateRoot
if (-not $InstallRoot) { Write-Warn "The $Mod Quake VR installation was not found. Nothing was changed."; Stop-Here 1 }
$displayName = switch ($Mod) { 'romeo' { 'Vittorio Romeo' } 'pcvr' { 'Team Beef port' } 'unleashed' { 'Unleashed' } }
$processName = switch ($Mod) { 'romeo' { 'quakevr' } 'pcvr' { 'darkplaces-sdl' } 'unleashed' { 'ironwail' } }
if (Get-Process -Name $processName -ErrorAction SilentlyContinue) { Write-Warn "Close $displayName before uninstalling."; Stop-Here 1 }
if (-not $HubConfirmed) {
    $answer = (Read-Host "  Type yes to remove $displayName only").Trim()
    if ($answer -ne 'yes') { Write-Info 'Nothing was changed.'; Stop-Here 0 }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host " Quake VR - remove $displayName" -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host "  Standalone folder: $InstallRoot" -ForegroundColor Gray

if ($Mod -eq 'unleashed') {
    $publisher=Join-Path $InstallRoot 'setup\QuakeVR-Setup.exe'
    if (-not (Test-QuakeVrRoot $InstallRoot 'unleashed')) { Write-Warn 'The publisher installation is incomplete. Nothing was changed.'; Stop-Here 1 }
    Write-Info 'Publisher Setup removes only its owned files and preserves personal files.'
    $process=Start-Process -FilePath $publisher -ArgumentList ('--uninstall --quiet --target "'+$InstallRoot+'"') -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0 -or
        (Test-Path -LiteralPath (Join-Path $InstallRoot 'ironwail.exe') -PathType Leaf)) {
        Write-Warn 'Publisher removal did not complete; the Hub kept its installation record.'
        Stop-Here 1
    }
    foreach ($name in @('.installed_path_unleashed','.installed_version_c')) {
        $marker=Join-Path $StateRoot $name
        if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force }
    }
    $versionMarker=Join-Path $InstallRoot '.pcvrhub_version_c'
    if (Test-Path -LiteralPath $versionMarker -PathType Leaf) { Remove-Item -LiteralPath $versionMarker -Force }
    Write-OK 'Unleashed was removed. Original Quake and personal files remain.'
    Stop-Here 0
}

if ($Mod -eq 'romeo') {
    # Exact v0.0.8.1 compiled Windows payload. Id1\config.cfg is deliberately
    # absent: it is shipped as a default but becomes the user's live settings.
    # PAK0/PAK1, saves, music, screenshots and every unknown file are likewise
    # outside this ownership list and therefore survive.
    $owned = @(
        'actions.json','bindings_cosmos.json','bindings_generic.json','bindings_holographic.json',
        'bindings_knuckles.json','bindings_touch.json','bindings_vive.json',
        'quakevr-debug-novr.bat','quakevr-dedicated.bat','quakevr-novr.bat',
        'glew32.dll','libFLAC-8.dll','libmad-0.dll','libmikmod-3.dll','libmpg123-0.dll',
        'libogg-0.dll','libopus-0.dll','libopusfile-0.dll','libvorbis-0.dll',
        'libvorbisfile-3.dll','libvorbisidec-1.dll','libxmp.dll','openvr_api.dll',
        'quakevr-debug.exe','quakevr.exe','SDL2.dll',
        'Id1\maps\vrfiringrange.bsp','Id1\maps\vrfiringrange.pts',
        'Id1\maps\vrstart.bsp','Id1\maps\vrstart.log','Id1\maps\vrstart.pts',
        'Id1\maps\vrtutorial.bsp','Id1\maps\vrtutorial.log','Id1\maps\vrtutorial.pts',
        'Id1\pak10.pak','Id1\pak11.pak','Id1\pak12.pak',
        'Id1\textures\particle_blood.tga','Id1\textures\particle_blood_mist.tga',
        'Id1\textures\particle_explosion.tga','Id1\textures\particle_gun_smoke.tga',
        'Id1\textures\particle_lightning.tga','Id1\textures\particle_rock.tga',
        'Id1\textures\particle_smoke.tga','Id1\textures\particle_spark.tga'
    )
    Remove-QuakeOwnedFiles -Root $InstallRoot -RelativeFiles $owned
    Remove-ShortcutWhenOwned -Name 'Quake VR.lnk' -OwnedTarget (Join-Path $InstallRoot 'quakevr.exe')
    Remove-EmptyQuakeFolders -Root $InstallRoot -RelativeFolders @('Id1\maps','Id1\textures','Id1','.')
    $markerName = '.installed_path_romeo'
} else {
    $owned = @(
        'darkplaces-sdl.exe','libgcc_s_seh-1.dll','libogg-0.dll','libopenxr_loader.dll',
        'libstdc++-6.dll','libvorbis-0.dll','libvorbisfile-3.dll','libwinpthread-1.dll',
        'LICENSE.txt','Quake VR (flatscreen).bat','Quake VR.bat','README.txt','SDL2.dll',
        'Setup.bat','THIRD-PARTY.txt','tools\make-menu-art.py','tools\make-qc-strings.py','tools\setup.py',
        'id1\IF SETUP COULD NOT FIND QUAKE.txt','.pcvrhub_ready','.pcvrhub_version_b',
        'Scourge of Armagon.bat','Dissolution of Eternity.bat','Dimension of the Past.bat',
        'Dimension of the Machine.bat','Dawn of the Machine.bat'
    )
    Remove-QuakeOwnedFiles -Root $InstallRoot -RelativeFiles $owned
    Remove-EmptyQuakeFolders -Root $InstallRoot -RelativeFolders @('tools','.')
    $markerName = '.installed_path_pcvr'
}

$marker = Join-Path $StateRoot $markerName
if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue }
if ($Mod -eq 'pcvr') {
    $versionMarker = Join-Path $StateRoot '.installed_version_b'
    if (Test-Path -LiteralPath $versionMarker -PathType Leaf) { Remove-Item -LiteralPath $versionMarker -Force -ErrorAction SilentlyContinue }
}
$otherMarker = Join-Path $StateRoot $(if ($Mod -eq 'romeo') { '.installed_path_pcvr' } else { '.installed_path_romeo' })
$sharedMarker = Join-Path $StateRoot '.installed_path'
if (Test-Path -LiteralPath $otherMarker -PathType Leaf) {
    try {
        $otherRoot = (Get-Content -LiteralPath $otherMarker -Raw -ErrorAction Stop).Trim()
        if ($otherRoot) { Set-Content -LiteralPath $sharedMarker -Value $otherRoot -Encoding UTF8 -Force }
    } catch {}
} elseif (Test-Path -LiteralPath $sharedMarker -PathType Leaf) {
    Remove-Item -LiteralPath $sharedMarker -Force -ErrorAction SilentlyContinue
}

Write-OK "$displayName was removed."
Write-Info 'Licensed base PAKs, saves, settings, screenshots, music, custom content and unknown files were preserved.'
Stop-Here 0
