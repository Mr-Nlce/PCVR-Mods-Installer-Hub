param(
    [ValidateSet("VR","Prerequisites")][string]$Scope = "VR",
    [string]$GameRoot = "",
    [string]$StateRoot = "",
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
$GAME_EXE = "sh3.exe"
$MANIFEST_NAME = ".pcvrhub-sh3vr-install.tsv"
$BACKUP_NAME = ".pcvrhub-sh3vr-backup"
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Finish([int]$Code) {
    if (-not $NoPause) { Write-Host ""; Read-Host "Press Enter to exit" | Out-Null }
    exit $Code
}
function Test-Root([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf)) }

if (-not (Test-Root $GameRoot)) {
    try { $GameRoot = (Get-Content -LiteralPath (Join-Path $StateRoot ".installed_path") -Raw).Trim() } catch {}
}
if (-not (Test-Root $GameRoot)) {
    foreach ($candidate in @("C:\Program Files (x86)\KONAMI\SILENT HILL 3","C:\Program Files\KONAMI\SILENT HILL 3")) {
        if (Test-Root $candidate) { $GameRoot = $candidate; break }
    }
}
if (-not (Test-Root $GameRoot)) {
    Write-Host "[X] The recorded Silent Hill 3 folder is unavailable. No files were changed." -ForegroundColor Red
    Finish 1
}

$manifestPath = Join-Path $GameRoot $MANIFEST_NAME
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Host "[X] No Hub ownership manifest exists. Nothing was guessed or deleted." -ForegroundColor Red
    Write-Host "    Use the uninstall guide for a manual review." -ForegroundColor Gray
    Finish 1
}
$rows = @((Get-Content -LiteralPath $manifestPath -Raw) | ConvertFrom-Csv -Delimiter "`t")

if ($Scope -eq "Prerequisites") {
    $vrRows = @($rows | Where-Object Component -eq "VR")
    $vrMarker = Test-Path -LiteralPath (Join-Path $GameRoot "sh3vr_host64.exe") -PathType Leaf
    if ($vrRows.Count -gt 0 -or $vrMarker) {
        Write-Host "[X] Silent Hill 3 VR still requires these components." -ForegroundColor Red
        Write-Host "    Use Remove SH3 VR first, then Remove prerequisites." -ForegroundColor Yellow
        Finish 1
    }
}

$components = if ($Scope -eq "VR") { @("VR") } else { @("PCFix","Camera") }
$displayName = if ($Scope -eq "VR") { "Silent Hill 3 VR" } else { "the PC Fix and Camera Mod installed by the Hub" }
if (-not $HubConfirmed) {
    $answer = ("" + (Read-Host "Remove $displayName from '$GameRoot'? [Y/N]")).Trim().ToUpperInvariant()
    if ($answer -notin @("Y","YES")) { Write-Host "Cancelled. Nothing changed."; Finish 0 }
}

$backupRoot = Join-Path (Join-Path $GameRoot $BACKUP_NAME) "original"
$remaining = New-Object 'System.Collections.Generic.List[object]'
$changed = 0
$kept = 0
$removeBackupRoot = $false
foreach ($row in $rows) {
    if ([string]$row.Component -notin $components) { [void]$remaining.Add($row); continue }
    $relative = [string]$row.RelativePath
    if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\/])\.\.([\/]|$)') {
        [void]$remaining.Add($row); $kept++; continue
    }
    if ([string]$row.Action -eq "keep") {
        Write-Host "[KEEP] User setting or pre-existing component: $relative" -ForegroundColor Gray
        continue
    }

    $target = Join-Path $GameRoot $relative
    $actualTarget = $target
    if ($relative -ieq "dinput8.dll" -and -not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $parked = Join-Path $GameRoot "dinput8.dll.pcvrhub-off"
        if (Test-Path -LiteralPath $parked -PathType Leaf) { $actualTarget = $parked }
    }
    if (-not (Test-Path -LiteralPath $actualTarget -PathType Leaf)) { continue }
    $currentHash = (Get-FileHash -LiteralPath $actualTarget -Algorithm SHA256).Hash
    if ($currentHash -ne [string]$row.InstalledSha256) {
        Write-Host "[KEEP] Changed since installation: $relative" -ForegroundColor Yellow
        [void]$remaining.Add($row); $kept++; continue
    }
    if ([string]$row.Action -eq "restore") {
        $backup = Join-Path $backupRoot $relative
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            Write-Host "[KEEP] Original backup is missing: $relative" -ForegroundColor Yellow
            [void]$remaining.Add($row); $kept++; continue
        }
        if ($actualTarget -ne $target) { Remove-Item -LiteralPath $actualTarget -Force }
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $backup -Destination $target -Force
        Write-Host "[RESTORE] $relative" -ForegroundColor Green
    } else {
        Remove-Item -LiteralPath $actualTarget -Force
        Write-Host "[REMOVE] $relative" -ForegroundColor Green
    }
    $changed++
}

if ($remaining.Count -gt 0) {
    $lines = @("Component`tAction`tRelativePath`tInstalledSha256")
    foreach ($row in $remaining) { $lines += "$($row.Component)`t$($row.Action)`t$($row.RelativePath)`t$($row.InstalledSha256)" }
    [IO.File]::WriteAllLines($manifestPath, [string[]]$lines, (New-Object Text.UTF8Encoding($false)))
} else {
    Remove-Item -LiteralPath $manifestPath -Force -ErrorAction SilentlyContinue
    $removeBackupRoot = $true
}

foreach ($dir in @("sh3vr_assets","plugins\OTSMod","plugins","Licenses","SH3FixData\Sounds","SH3FixData")) {
    $full = Join-Path $GameRoot $dir
    if ((Test-Path -LiteralPath $full -PathType Container) -and @(Get-ChildItem -LiteralPath $full -Force -ErrorAction SilentlyContinue).Count -eq 0) {
        Remove-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
    }
}

if ($Scope -eq "VR" -and -not (Test-Path -LiteralPath (Join-Path $GameRoot "sh3vr_host64.exe") -PathType Leaf)) {
    foreach ($marker in @(".installed_version")) { Remove-Item -LiteralPath (Join-Path $StateRoot $marker) -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath (Join-Path $GameRoot ".pcvrhub_version") -Force -ErrorAction SilentlyContinue
    $shortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Silent Hill 3 VR.lnk"
    $shortcutState = Join-Path $GameRoot ".pcvrhub-sh3vr-shortcut-state.txt"
    $shortcutBackup = Join-Path (Join-Path $GameRoot $BACKUP_NAME) "original-shortcut.lnk"
    $ownedShortcut = $false
    if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
        try {
            $shell = New-Object -ComObject WScript.Shell
            $ownedShortcut = ($shell.CreateShortcut($shortcut).TargetPath -ieq (Join-Path $GameRoot $GAME_EXE))
        } catch {}
    }
    $shortcutMode = ""
    try { $shortcutMode = (Get-Content -LiteralPath $shortcutState -Raw).Trim() } catch {}
    if ($ownedShortcut -and $shortcutMode -eq "restore" -and (Test-Path -LiteralPath $shortcutBackup -PathType Leaf)) {
        Copy-Item -LiteralPath $shortcutBackup -Destination $shortcut -Force
        Write-Host "[RESTORE] Previous desktop shortcut" -ForegroundColor Green
    } elseif ($ownedShortcut -and $shortcutMode -eq "remove") {
        Remove-Item -LiteralPath $shortcut -Force
        Write-Host "[REMOVE] Silent Hill 3 VR desktop shortcut" -ForegroundColor Green
    }
    Remove-Item -LiteralPath $shortcutState -Force -ErrorAction SilentlyContinue
}
if ($removeBackupRoot) { Remove-Item -LiteralPath (Join-Path $GameRoot $BACKUP_NAME) -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ""
if ($kept -gt 0) {
    Write-Host "Removal finished with $kept protected file(s) left for review." -ForegroundColor Yellow
} else {
    Write-Host "$displayName removed safely. Game, saves and user settings were kept." -ForegroundColor Magenta
}
Write-Host "$changed verified file(s) removed or restored." -ForegroundColor Gray
Finish 0
