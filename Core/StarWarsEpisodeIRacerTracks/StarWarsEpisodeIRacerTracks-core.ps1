param(
    [string]$GameRoot = "",
    [switch]$NoIntro,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

function Get-RacerSha256([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
    finally { $stream.Dispose(); $sha.Dispose() }
}

$GAME_EXE = "SWEP1RCR.EXE"
$REPO = "tim-tim707/SW_RACER_RE"
$RELEASES_URL = "https://github.com/$REPO/releases"
$mainState = Join-Path (Join-Path $PSScriptRoot "..\StarWarsEpisodeIRacerVR") ".installed_path"

function Test-RacerRoot([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf)) }
function Pause-User([string]$Text="Press Enter to continue...") { if ($NoPause) { return }; Write-Host ""; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

if (-not $NoIntro) {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Star Wars Episode I Racer - Community Tracks" -ForegroundColor Cyan
    Write-Host " Installs: SW_RACER_RE community tracks by tim-tim707 community" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " This optional setup copies ONLY assets\custom_tracks." -ForegroundColor White
    Write-Host " The community archive's different dinput.dll, shaders and other" -ForegroundColor Yellow
    Write-Host " files are deliberately ignored so Racer PCVR stays intact." -ForegroundColor Yellow
    Pause-User "Press Enter to proceed with setup..." | Out-Null
}

if (-not (Test-RacerRoot $GameRoot)) { try { $GameRoot = (Get-Content -LiteralPath $mainState -Raw).Trim() } catch {} }
if (-not (Test-RacerRoot $GameRoot)) {
    Write-Host "[X] Install Racer PCVR first, then use this button again." -ForegroundColor Red
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot "openxr_loader.dll") -PathType Leaf)) {
    Write-Host "[X] Racer PCVR is not detected in this game folder." -ForegroundColor Red
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

$release = $null
try {
    $rel = Invoke-PCVRRestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -Headers @{"User-Agent"="PCVR-Mods-Hub"} -TimeoutSec 25 -ErrorAction Stop
    $asset = @($rel.assets | Where-Object { $_.name -match '(?i)^community_improvement_mod.*\.zip$' } | Select-Object -First 1)[0]
    if ($asset) { $release = [pscustomobject]@{ Tag=[string]$rel.tag_name; Name=[string]$asset.name; Url=[string]$asset.browser_download_url; Digest=[string]$asset.digest } }
} catch {}

$work = Join-Path $env:TEMP ("pcvr_racer_tracks_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$zipPath = Join-Path $work "community_tracks.zip"
$tag = "v0.17"
if ($release) {
    $tag = $release.Tag
    $releaseSha = ''
    if ($release.Digest -match '^sha256:([0-9a-fA-F]{64})$') { $releaseSha = $matches[1] }
    $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $zipPath -Label "SW_RACER_RE $tag" `
        -ManualUrl $RELEASES_URL
    if ($ok -and $releaseSha) {
        if ((Get-RacerSha256 $zipPath) -eq $releaseSha) { Write-Host '  [OK] The publisher SHA-256 also matches.' -ForegroundColor Green }
    }
}
while (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
    Write-Host '  The community ZIP was not downloaded automatically.' -ForegroundColor Yellow
    Write-Host '  Press Enter to open the release page, or drag/paste your chosen ZIP path.' -ForegroundColor White
    Write-Host '  Type Q to leave the current Racer PCVR installation unchanged.' -ForegroundColor Gray
    $picked = ("" + (Read-Host 'Community ZIP path, Enter or Q')).Trim().Trim('"').Trim("'")
    if ($picked -ieq 'Q') { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue; exit 1 }
    if (-not $picked) { try { Start-Process $RELEASES_URL } catch { Write-Host ("  Could not open the browser: " + $_.Exception.Message) -ForegroundColor Yellow }; continue }
    if (Test-Path -LiteralPath $picked -PathType Leaf) { Copy-Item -LiteralPath $picked -Destination $zipPath -Force }
    else { Write-Host '  The selected ZIP path does not exist yet.' -ForegroundColor Yellow }
}

$extract = Join-Path $work "extracted"
New-Item -ItemType Directory -Path $extract -Force | Out-Null
Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force
$payload = Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile "dinput.dll"
$sourceTracks = Join-Path $payload "assets\custom_tracks"
$trackFiles = if (Test-Path -LiteralPath $sourceTracks -PathType Container) { @(Get-ChildItem -LiteralPath $sourceTracks -Recurse -File) } else { @() }
if ($trackFiles.Count -eq 0) {
    throw "No assets\custom_tracks payload was found. Nothing was installed."
}
$targetTracks = Join-Path $GameRoot "assets\custom_tracks"
$backupRoot = Join-Path $GameRoot ".pcvrhub-starwars-racer-tracks-backup"
$manifestPath = Join-Path $GameRoot ".pcvrhub-starwars-racer-tracks.tsv"
$oldRows = @{}
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try { foreach ($row in @((Get-Content -LiteralPath $manifestPath -Raw) | ConvertFrom-Csv -Delimiter "`t")) { if ($row.RelativePath) { $oldRows[[string]$row.RelativePath] = $row } } } catch {}
}
$newRows = @("Action`tRelativePath`tInstalledSha256")
New-Item -ItemType Directory -Path $targetTracks -Force | Out-Null
foreach ($file in $trackFiles) {
    $relative = $file.FullName.Substring($sourceTracks.TrimEnd('\').Length).TrimStart('\')
    $target = Join-Path $targetTracks $relative
    $targetParent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $targetParent)) { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
    $gameRelative = "assets\custom_tracks\$relative"
    $backup = Join-Path $backupRoot $relative
    $action = if ($oldRows.ContainsKey($gameRelative)) { [string]$oldRows[$gameRelative].Action } else { "remove" }
    if (-not $oldRows.ContainsKey($gameRelative) -and (Test-Path -LiteralPath $target -PathType Leaf)) {
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            $backupParent = Split-Path -Parent $backup
            if (-not (Test-Path -LiteralPath $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
            Copy-Item -LiteralPath $target -Destination $backup -Force
        }
        $action = "restore"
    }
    if ($oldRows.ContainsKey($gameRelative) -and (Test-Path -LiteralPath $target -PathType Leaf)) {
        $currentHash = Get-RacerSha256 $target
        if ($oldRows[$gameRelative].InstalledSha256 -and $currentHash -ne [string]$oldRows[$gameRelative].InstalledSha256) {
            $conflict = Join-Path (Join-Path $GameRoot ".pcvrhub-starwars-racer-tracks-conflicts") ($relative + "." + (Get-Date -Format "yyyyMMddHHmmss"))
            $conflictParent = Split-Path -Parent $conflict
            if (-not (Test-Path -LiteralPath $conflictParent)) { New-Item -ItemType Directory -Path $conflictParent -Force | Out-Null }
            Copy-Item -LiteralPath $target -Destination $conflict -Force
            Write-Host "[KEEP] Preserved changed track before reinstall: $gameRelative" -ForegroundColor Yellow
        }
    }
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    $newRows += "$action`t$gameRelative`t$(Get-RacerSha256 $target)"
}
foreach ($file in $trackFiles) {
    $relative = $file.FullName.Substring($sourceTracks.TrimEnd('\').Length).TrimStart('\')
    if (-not (Test-Path -LiteralPath (Join-Path $targetTracks $relative) -PathType Leaf)) { throw "Track copy verification failed: $relative" }
}
[IO.File]::WriteAllLines($manifestPath, [string[]]$newRows, (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_path"), $GameRoot, (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_version"), $tag, (New-Object Text.UTF8Encoding($false)))
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "[OK] Community tracks installed. Racer PCVR binaries were not touched." -ForegroundColor Green
Write-Host "Now this is podracing. The bonus circuits just opened." -ForegroundColor Magenta
Pause-User "Press Enter to exit..." | Out-Null
