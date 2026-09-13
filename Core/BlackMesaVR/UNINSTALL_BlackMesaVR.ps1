param(
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$GAME_EXE = 'bms.exe'
$MANIFEST_NAME = '.pcvrhub-blackmesavr-install.tsv'
$BACKUP_NAME = '.pcvrhub-blackmesavr-backup'
$SHORTCUT_STATE = '.pcvrhub-blackmesavr-shortcuts.tsv'
$LOADERS = @('d3d9.dll','bin\d3d9.dll','bin\thirdparty\dxvk-windows-x86\d3d9.dll')
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Finish([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-Root([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf)) }
function Find-SteamGameRoot {
    $steamRoots = New-Object 'System.Collections.Generic.List[string]'
    foreach ($reg in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam','HKCU:\SOFTWARE\Valve\Steam')) {
        try {
            if (-not (Test-Path -LiteralPath $reg)) { continue }
            $properties = Get-ItemProperty -LiteralPath $reg -ErrorAction Stop
            foreach ($candidate in @($properties.InstallPath,$properties.SteamPath)) {
                if ($candidate -and -not $steamRoots.Contains([string]$candidate)) { [void]$steamRoots.Add([string]$candidate) }
            }
        } catch {}
    }
    foreach ($candidate in @("${env:ProgramFiles(x86)}\Steam","${env:ProgramFiles}\Steam",'C:\Steam')) {
        if ($candidate -and -not $steamRoots.Contains($candidate)) { [void]$steamRoots.Add($candidate) }
    }
    $libraries = New-Object 'System.Collections.Generic.List[string]'
    foreach ($steamRoot in $steamRoots) {
        if (-not $libraries.Contains($steamRoot)) { [void]$libraries.Add($steamRoot) }
        $vdf = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $vdf -PathType Leaf)) { continue }
        try {
            foreach ($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $library = $match.Groups[1].Value -replace '\\\\','\'
                if ($library -and -not $libraries.Contains($library)) { [void]$libraries.Add($library) }
            }
        } catch {}
    }
    foreach ($library in $libraries) {
        $candidate = Join-Path $library 'steamapps\common\Black Mesa'
        if (Test-Root $candidate) { return $candidate }
    }
    return $null
}

if (-not (Test-Root $GameRoot)) { try { $GameRoot = (Get-Content -LiteralPath (Join-Path $StateRoot '.installed_path') -Raw).Trim() } catch {} }
if (-not (Test-Root $GameRoot)) { $GameRoot = Find-SteamGameRoot }
if (-not (Test-Root $GameRoot)) {
    Write-Host '[X] The Black Mesa folder was not found. No files were changed.' -ForegroundColor Red
    Finish 1
}
$manifestPath = Join-Path $GameRoot $MANIFEST_NAME
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Host '[X] No Hub ownership manifest exists. Nothing was guessed or deleted.' -ForegroundColor Red
    Write-Host '    Use the uninstall guide for a manual review.' -ForegroundColor Gray
    Finish 1
}
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove Black Mesa VR from '$GameRoot'? [Y/N]")).Trim().ToUpperInvariant()
    if ($answer -notin @('Y','YES')) { Write-Host 'Cancelled. Nothing changed.'; Finish 0 }
}

$rows = @((Get-Content -LiteralPath $manifestPath -Raw) | ConvertFrom-Csv -Delimiter "`t")
$backupRoot = Join-Path (Join-Path $GameRoot $BACKUP_NAME) 'original'
$remaining = New-Object 'System.Collections.Generic.List[object]'
$changed = 0; $kept = 0
foreach ($row in $rows) {
    $relative = [string]$row.RelativePath
    if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\/])\.\.([\/]|$)') { [void]$remaining.Add($row); $kept++; continue }
    $target = Join-Path $GameRoot $relative
    if ([string]$row.Action -in @('remove-line','remove-file-if-only-line')) {
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $lines = @(Get-Content -LiteralPath $target | Where-Object { $_ -notmatch '^\s*exec\s+bmvr\s*$' })
            while ($lines.Count -and -not $lines[-1].Trim()) { if ($lines.Count -eq 1) { $lines=@() } else { $lines=$lines[0..($lines.Count-2)] } }
            if ([string]$row.Action -eq 'remove-file-if-only-line' -and $lines.Count -eq 0) { Remove-Item -LiteralPath $target -Force }
            else { [IO.File]::WriteAllLines($target,[string[]]$lines,(New-Object Text.UTF8Encoding($false))) }
            Write-Host '[REMOVE] exec bmvr from bms\cfg\autoexec.cfg' -ForegroundColor Green
            $changed++
        }
        continue
    }
    if ([string]$row.Action -eq 'keep') { Write-Host "[KEEP] User setting: $relative" -ForegroundColor Gray; continue }
    $actual = $target
    if ($LOADERS -contains $relative -and -not (Test-Path -LiteralPath $actual -PathType Leaf)) {
        $parked = "$target.pcvrhub-off"
        if (Test-Path -LiteralPath $parked -PathType Leaf) { $actual = $parked }
    }
    if (-not (Test-Path -LiteralPath $actual -PathType Leaf)) { continue }
    if ((Get-FileHash -LiteralPath $actual -Algorithm SHA256).Hash -ne [string]$row.InstalledSha256) {
        Write-Host "[KEEP] Changed since installation: $relative" -ForegroundColor Yellow
        [void]$remaining.Add($row); $kept++; continue
    }
    if ([string]$row.Action -eq 'restore') {
        $backup = Join-Path $backupRoot $relative
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { Write-Host "[KEEP] Original backup is missing: $relative" -ForegroundColor Yellow; [void]$remaining.Add($row); $kept++; continue }
        if ($actual -ne $target) { Remove-Item -LiteralPath $actual -Force }
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $backup -Destination $target -Force
        Write-Host "[RESTORE] $relative" -ForegroundColor Green
    } else {
        Remove-Item -LiteralPath $actual -Force
        Write-Host "[REMOVE] $relative" -ForegroundColor Green
    }
    $changed++
}

$shortcutState = Join-Path $GameRoot $SHORTCUT_STATE
if (Test-Path -LiteralPath $shortcutState -PathType Leaf) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    foreach ($row in @((Get-Content -LiteralPath $shortcutState -Raw) | ConvertFrom-Csv -Delimiter "`t")) {
        $link = Join-Path $desktop ([string]$row.Name + '.lnk')
        $owned = $false
        if (Test-Path -LiteralPath $link -PathType Leaf) {
            try {
                $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($link)
                $owned = ($shortcut.TargetPath -ieq [string]$row.Target -and $shortcut.Arguments -eq [string]$row.Arguments)
            } catch {}
        }
        if (-not $owned) { if (Test-Path -LiteralPath $link) { Write-Host "[KEEP] Changed desktop shortcut: $($row.Name)" -ForegroundColor Yellow; $kept++ }; continue }
        if ([string]$row.Action -eq 'restore') {
            $backup = Join-Path (Join-Path $GameRoot $BACKUP_NAME) ('desktop-' + (([string]$row.Name) -replace '[^A-Za-z0-9]','_') + '.lnk')
            if (Test-Path -LiteralPath $backup -PathType Leaf) { Copy-Item -LiteralPath $backup -Destination $link -Force; Write-Host "[RESTORE] Previous $($row.Name) shortcut" -ForegroundColor Green }
            else { Write-Host "[KEEP] Shortcut backup is missing: $($row.Name)" -ForegroundColor Yellow; $kept++ }
        } else { Remove-Item -LiteralPath $link -Force; Write-Host "[REMOVE] $($row.Name) desktop shortcut" -ForegroundColor Green }
    }
    if ($kept -eq 0) { Remove-Item -LiteralPath $shortcutState -Force }
}

if ($remaining.Count -gt 0) {
    $lines = @("Component`tAction`tRelativePath`tInstalledSha256")
    foreach ($row in $remaining) { $lines += "$($row.Component)`t$($row.Action)`t$($row.RelativePath)`t$($row.InstalledSha256)" }
    [IO.File]::WriteAllLines($manifestPath,[string[]]$lines,(New-Object Text.UTF8Encoding($false)))
} elseif ($kept -eq 0) {
    Remove-Item -LiteralPath $manifestPath -Force
    Remove-Item -LiteralPath (Join-Path $GameRoot $BACKUP_NAME) -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($dir in @('VRLaunch','VR\weapon_wheel','VR\SteamVRActionManifest','VR\openxr_helper64','VR\hands','VR')) {
    $full = Join-Path $GameRoot $dir
    if ((Test-Path -LiteralPath $full -PathType Container) -and @(Get-ChildItem -LiteralPath $full -Force -ErrorAction SilentlyContinue).Count -eq 0) { Remove-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue }
}
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot 'VR\openxr_helper64\OpenXRHelper64.exe') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $StateRoot '.installed_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
}
Write-Host ''
if ($kept) { Write-Host "Removal finished with $kept protected item(s) left for review." -ForegroundColor Yellow }
else { Write-Host 'Black Mesa VR removed safely. Black Mesa, Blue Shift, saves and user settings were kept.' -ForegroundColor Magenta }
Write-Host "$changed verified file(s) removed or restored." -ForegroundColor Gray
Finish 0
