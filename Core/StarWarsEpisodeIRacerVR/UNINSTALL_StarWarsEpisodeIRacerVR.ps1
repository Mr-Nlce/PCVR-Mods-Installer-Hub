param(
    [string]$GameRoot = "",
    [string]$StateRoot = "",
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
$GAME_EXE = "SWEP1RCR.EXE"
$MANIFEST_NAME = ".pcvrhub-starwars-racer-install.tsv"
$BACKUP_NAME = ".pcvrhub-starwars-racer-backup"
$knownDinput = "9A9E83FD2E01DC12D0C556CA9231C58C65E7B9B92C7262BE280DFBA00B47BB83"
$knownLoader = "431FFE5A374059C8B75C33E54A71F4FECA38962D7DECCF3518FDDF99707360E5"
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
    $GameRoot = Find-SteamGameFolder -AppId "808910" -SteamFolderNames @("Star Wars Episode I Racer") -GogNames @("STAR WARS Racer","Star Wars Episode I Racer") -ProbeExe $GAME_EXE
}
if (-not (Test-Root $GameRoot)) {
    foreach ($candidate in @("C:\GOG Games\STAR WARS Racer","C:\Program Files (x86)\GOG Galaxy\Games\STAR WARS Racer","C:\Program Files (x86)\LucasArts\Star Wars Episode I Racer","C:\Program Files (x86)\LucasArts\Racer")) {
        if (Test-Root $candidate) { $GameRoot = $candidate; break }
    }
}
if (-not (Test-Root $GameRoot)) {
    Write-Host "[X] The recorded game folder is unavailable. No files were changed." -ForegroundColor Red
    Finish 1
}
if (-not $HubConfirmed) {
    $answer = ("" + (Read-Host "Remove Racer PCVR from '$GameRoot'? [Y/N]")).Trim().ToUpperInvariant()
    if ($answer -notin @("Y","YES")) { Write-Host "Cancelled. Nothing changed."; Finish 0 }
}

$manifestPath = Join-Path $GameRoot $MANIFEST_NAME
$backupRoot = Join-Path $GameRoot $BACKUP_NAME
$remaining = New-Object 'System.Collections.Generic.List[string]'
$changed = 0

if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    $rows = @((Get-Content -LiteralPath $manifestPath -Raw) | ConvertFrom-Csv -Delimiter "`t")
    foreach ($row in $rows) {
        $relative = [string]$row.RelativePath
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { [void]$remaining.Add($relative); continue }
        $target = Join-Path $GameRoot $relative
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        $currentHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        if ($currentHash -ne [string]$row.InstalledSha256) {
            Write-Host "[KEEP] Changed since installation: $relative" -ForegroundColor Yellow
            [void]$remaining.Add($relative)
            continue
        }
        if ([string]$row.Action -eq "restore") {
            $backup = Join-Path (Join-Path $backupRoot "original") $relative
            if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
                Write-Host "[KEEP] Original backup is missing: $relative" -ForegroundColor Yellow
                [void]$remaining.Add($relative)
                continue
            }
            Copy-Item -LiteralPath $backup -Destination $target -Force
            Write-Host "[RESTORE] $relative" -ForegroundColor Green
        } else {
            Remove-Item -LiteralPath $target -Force
            Write-Host "[REMOVE] $relative" -ForegroundColor Green
        }
        $changed++
    }
    if ($remaining.Count -eq 0) {
        Remove-Item -LiteralPath $manifestPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host ""
        Write-Host "Some files were deliberately kept. Their manifest remains for review." -ForegroundColor Yellow
    }
} else {
    # Conservative fallback for a manual v1.1 installation: only the two
    # exact verified binaries are eligible. Shared assets are never guessed.
    foreach ($item in @(
        @{ Name="dinput.dll"; Hash=$knownDinput },
        @{ Name="openxr_loader.dll"; Hash=$knownLoader }
    )) {
        $path = Join-Path $GameRoot $item.Name
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            if ($hash -eq $item.Hash) { Remove-Item -LiteralPath $path -Force; Write-Host "[REMOVE] $($item.Name) (verified v1.1)" -ForegroundColor Green; $changed++ }
            else { Write-Host "[KEEP] $($item.Name) does not match the verified v1.1 file." -ForegroundColor Yellow }
        }
    }
    Write-Host "No Hub manifest existed, so assets, tracks and settings were left untouched." -ForegroundColor Gray
}

if ($remaining.Count -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $GameRoot "openxr_loader.dll") -PathType Leaf)) {
    foreach ($marker in @(".installed_path",".installed_version")) { Remove-Item -LiteralPath (Join-Path $StateRoot $marker) -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath (Join-Path $GameRoot ".pcvrhub_version") -Force -ErrorAction SilentlyContinue
}
Write-Host ""
Write-Host "Racer PCVR removal finished. Game, saves, config and community tracks were not deleted." -ForegroundColor Magenta
Finish 0
