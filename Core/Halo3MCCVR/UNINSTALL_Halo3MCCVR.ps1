param(
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }
$MCC_BIN_DIR = 'MCC\Binaries\Win64'
$MCC_EXES = @('MCC-Win64-Shipping.exe','MCCWinStore-Win64-Shipping.exe')

function Finish([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-MCCRoot([string]$Root) {
    if (-not $Root) { return $false }
    foreach ($exe in $MCC_EXES) {
        if (Test-Path -LiteralPath (Join-Path (Join-Path $Root $MCC_BIN_DIR) $exe) -PathType Leaf) { return $true }
    }
    return $false
}
function Find-MCCRoot {
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $StateRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-MCCRoot $recorded) { return $recorded }
    } catch {}
    $roots = New-Object 'System.Collections.Generic.List[string]'
    foreach ($reg in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam','HKCU:\SOFTWARE\Valve\Steam')) {
        try {
            if (-not (Test-Path -LiteralPath $reg)) { continue }
            $properties = Get-ItemProperty -LiteralPath $reg -ErrorAction Stop
            foreach ($candidate in @($properties.InstallPath,$properties.SteamPath)) {
                if ($candidate -and -not $roots.Contains([string]$candidate)) { [void]$roots.Add([string]$candidate) }
            }
        } catch {}
    }
    foreach ($candidate in @([Environment]::GetFolderPath('ProgramFilesX86') + '\Steam',[Environment]::GetFolderPath('ProgramFiles') + '\Steam','C:\Steam')) {
        if ($candidate -and -not $roots.Contains($candidate)) { [void]$roots.Add($candidate) }
    }
    $libraries = New-Object 'System.Collections.Generic.List[string]'
    foreach ($root in $roots) {
        if (-not $libraries.Contains($root)) { [void]$libraries.Add($root) }
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $vdf -PathType Leaf)) { continue }
        try {
            foreach ($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $library = $match.Groups[1].Value -replace '\\\\','\'
                if ($library -and -not $libraries.Contains($library)) { [void]$libraries.Add($library) }
            }
        } catch {}
    }
    foreach ($library in $libraries) {
        $candidate = Join-Path $library 'steamapps\common\Halo The Master Chief Collection'
        if (Test-MCCRoot $candidate) { return $candidate }
    }
    foreach ($drive in @('C:','D:','E:','F:')) {
        foreach ($relative in @('XboxGames\Halo- The Master Chief Collection\Content','XboxGames\Halo The Master Chief Collection\Content')) {
            $candidate = Join-Path $drive $relative
            if (Test-MCCRoot $candidate) { return $candidate }
        }
    }
    return $null
}

if (-not (Test-MCCRoot $GameRoot)) { $GameRoot = Find-MCCRoot }
if (-not (Test-MCCRoot $GameRoot)) {
    Write-Host '[X] The MCC installation was not found. Nothing was changed.' -ForegroundColor Red
    Finish 1
}

$definition = [pscustomobject]@{
    Label='Maintained'; Folder='Halo_MCC_VR_community'; Manifest='.pcvrhub-halomccvr-community-install.tsv'
    Marker='.pcvrhub-halomccvr-community'; Shortcut='Halo MCC VR'; Version='.pcvrhub_version'; HubVersion='.installed_version'
}
$modRoot = Join-Path $GameRoot $definition.Folder
$manifestPath = Join-Path $modRoot $definition.Manifest
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Host "[X] No Hub ownership manifest exists for the $($definition.Label) build." -ForegroundColor Red
    Write-Host '    Nothing was guessed or deleted. Use the uninstall guide for an older manual install.' -ForegroundColor Gray
    Finish 1
}
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove the $($definition.Label) Halo MCC VR build? [Y/N]")).Trim().ToUpperInvariant()
    if ($answer -notin @('Y','YES')) { Write-Host 'Cancelled. Nothing changed.'; Finish 0 }
}
if (@(Get-Process -Name 'MCC-Win64-Shipping','MCCWinStore-Win64-Shipping' -ErrorAction SilentlyContinue).Count) {
    Write-Host '[X] MCC is running. Close it completely and try again.' -ForegroundColor Red
    Finish 1
}

$rows = @((Get-Content -LiteralPath $manifestPath -Raw) | ConvertFrom-Csv -Delimiter ([char]9))
$remaining = New-Object 'System.Collections.Generic.List[object]'
$removed = 0
$kept = 0
foreach ($row in $rows) {
    $relative = [string]$row.RelativePath
    if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') {
        [void]$remaining.Add($row); $kept++; continue
    }
    $target = Join-Path $modRoot $relative
    if ([string]$row.Action -eq 'preserve') {
        if (Test-Path -LiteralPath $target -PathType Leaf) { Write-Host "[KEEP] Setting: $relative" -ForegroundColor Gray }
        continue
    }
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
    $hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($hash -ne [string]$row.InstalledSha256) {
        Write-Host "[KEEP] Changed since installation: $relative" -ForegroundColor Yellow
        [void]$remaining.Add($row); $kept++; continue
    }
    Remove-Item -LiteralPath $target -Force
    Write-Host "[REMOVE] $relative" -ForegroundColor Green
    $removed++
}

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = if ($desktop) { Join-Path $desktop ($definition.Shortcut + '.lnk') } else { $null }
if ($shortcutPath -and (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) {
    try {
        $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
        $expectedTargets = @(
            (Join-Path $modRoot 'HaloMCCVRLauncher.exe'),
            (Join-Path $modRoot 'halo3xr_launcher.exe'),
            (Join-Path $modRoot 'HaloMCCVRHubLauncher.bat')
        )
        if ($shortcut.TargetPath -in $expectedTargets) {
            Remove-Item -LiteralPath $shortcutPath -Force
            Write-Host "[REMOVE] $($definition.Shortcut) desktop shortcut" -ForegroundColor Green
        } else {
            Write-Host '[KEEP] Desktop shortcut no longer belongs to this install.' -ForegroundColor Yellow
        }
    } catch { Write-Host '[KEEP] Desktop shortcut could not be verified.' -ForegroundColor Yellow }
}
$legacyShortcutPath = if ($desktop) { Join-Path $desktop 'Halo MCC Community VR.lnk' } else { $null }
if ($legacyShortcutPath -and (Test-Path -LiteralPath $legacyShortcutPath -PathType Leaf)) {
    try {
        $legacyShortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($legacyShortcutPath)
        if ($legacyShortcut.TargetPath -in @((Join-Path $modRoot 'HaloMCCVRLauncher.exe'),(Join-Path $modRoot 'halo3xr_launcher.exe'))) {
            Remove-Item -LiteralPath $legacyShortcutPath -Force
            Write-Host '[REMOVE] Former Halo MCC Community VR desktop shortcut' -ForegroundColor Green
        }
    } catch { Write-Host '[KEEP] Former desktop shortcut could not be verified.' -ForegroundColor Yellow }
}

if ($remaining.Count) {
    $tab = [char]9
    $lines = @("Action$($tab)RelativePath$($tab)InstalledSha256")
    foreach ($row in $remaining) { $lines += "$($row.Action)$($tab)$($row.RelativePath)$($tab)$($row.InstalledSha256)" }
    [IO.File]::WriteAllLines($manifestPath,[string[]]$lines,(New-Object Text.UTF8Encoding($false)))
} else {
    Remove-Item -LiteralPath $manifestPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $GameRoot $definition.Version) -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $StateRoot $definition.HubVersion) -Force -ErrorAction SilentlyContinue
}

if ((Test-Path -LiteralPath $modRoot -PathType Container) -and @(Get-ChildItem -LiteralPath $modRoot -Force -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item -LiteralPath $modRoot -Force
}
Write-Host ''
if ($kept) {
    Write-Host "$($definition.Label) removal finished with $kept changed item(s) kept for review." -ForegroundColor Yellow
} else {
    Write-Host "$($definition.Label) Halo MCC VR removed safely." -ForegroundColor Magenta
}
Write-Host "MCC, campaigns, saves and settings were kept. $removed verified file(s) removed." -ForegroundColor Gray
Finish 0
