param(
    [string]$GameRoot = "",
    [string]$StateRoot = "",
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }
$mainState = Join-Path $PSScriptRoot "..\StarWarsEpisodeIRacerVR\.installed_path"

function Finish([int]$Code) { if (-not $NoPause) { Write-Host ""; Read-Host "Press Enter to exit" | Out-Null }; exit $Code }
function Test-RacerRoot([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path "SWEP1RCR.EXE") -PathType Leaf)) }

if (-not (Test-RacerRoot $GameRoot)) { try { $GameRoot = (Get-Content -LiteralPath (Join-Path $StateRoot ".installed_path") -Raw).Trim() } catch {} }
if (-not (Test-RacerRoot $GameRoot)) { try { $GameRoot = (Get-Content -LiteralPath $mainState -Raw).Trim() } catch {} }
if (-not (Test-RacerRoot $GameRoot)) { $GameRoot = Find-SteamGameFolder -AppId "808910" -SteamFolderNames @("Star Wars Episode I Racer") -GogNames @("STAR WARS Racer","Star Wars Episode I Racer") -ProbeExe "SWEP1RCR.EXE" }
if (-not (Test-RacerRoot $GameRoot)) {
    foreach ($candidate in @("C:\GOG Games\STAR WARS Racer","C:\Program Files (x86)\GOG Galaxy\Games\STAR WARS Racer","C:\Program Files (x86)\LucasArts\Star Wars Episode I Racer","C:\Program Files (x86)\LucasArts\Racer")) {
        if (Test-RacerRoot $candidate) { $GameRoot = $candidate; break }
    }
}
if (-not (Test-RacerRoot $GameRoot)) { Write-Host "[X] Racer game folder unavailable. Nothing changed." -ForegroundColor Red; Finish 1 }
if (-not $HubConfirmed) {
    $answer = ("" + (Read-Host "Remove Hub-installed Racer community tracks from '$GameRoot'? [Y/N]")).Trim().ToUpperInvariant()
    if ($answer -notin @("Y","YES")) { Write-Host "Cancelled. Nothing changed."; Finish 0 }
}

$sets = @(
    @{ Name="community tracks"; Manifest=".pcvrhub-starwars-racer-tracks.tsv"; Backup=".pcvrhub-starwars-racer-tracks-backup"; Strip="assets\custom_tracks\" }
)
$kept = 0; $handled = 0
foreach ($set in $sets) {
    $manifestPath = Join-Path $GameRoot $set.Manifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
    $setKept = 0
    foreach ($row in @((Get-Content -LiteralPath $manifestPath -Raw) | ConvertFrom-Csv -Delimiter "`t")) {
        $relative = [string]$row.RelativePath
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { $setKept++; continue }
        $target = Join-Path $GameRoot $relative
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne [string]$row.InstalledSha256) {
            Write-Host "[KEEP] Changed since installation: $relative" -ForegroundColor Yellow
            $setKept++; continue
        }
        if ([string]$row.Action -eq "restore") {
            $backupRelative = $relative
            if ($set.Strip -and $backupRelative.StartsWith($set.Strip, [StringComparison]::OrdinalIgnoreCase)) { $backupRelative = $backupRelative.Substring($set.Strip.Length) }
            $backup = Join-Path (Join-Path $GameRoot $set.Backup) $backupRelative
            if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { Write-Host "[KEEP] Original backup missing: $relative" -ForegroundColor Yellow; $setKept++; continue }
            Copy-Item -LiteralPath $backup -Destination $target -Force
            Write-Host "[RESTORE] $relative" -ForegroundColor Green
        } else {
            Remove-Item -LiteralPath $target -Force
            Write-Host "[REMOVE] $relative" -ForegroundColor Green
        }
        $handled++
    }
    if ($setKept -eq 0) {
        Remove-Item -LiteralPath $manifestPath -Force -ErrorAction SilentlyContinue
        $backupTop = Join-Path $GameRoot ($set.Backup.Split('\')[0])
        Remove-Item -LiteralPath $backupTop -Recurse -Force -ErrorAction SilentlyContinue
    } else { $kept += $setKept }
}
if ($handled -eq 0 -and $kept -eq 0) { Write-Host "No Hub-owned extras manifest was found; nothing was guessed or deleted." -ForegroundColor Gray }
if ($kept -eq 0) { foreach ($marker in @(".installed_path",".installed_version")) { Remove-Item -LiteralPath (Join-Path $StateRoot $marker) -Force -ErrorAction SilentlyContinue } }
Write-Host ""
Write-Host "Racer track removal finished. Game, saves, PCVR port and unknown custom content were preserved." -ForegroundColor Magenta
Finish 0
