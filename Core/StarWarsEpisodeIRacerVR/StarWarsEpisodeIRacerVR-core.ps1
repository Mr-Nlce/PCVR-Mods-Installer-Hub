# Star Wars: Episode I Racer PCVR - safe, payload-only installer.
# The Hub downloads the current release; no mod archive is bundled.

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Star Wars Episode I Racer PCVR Installer"
$MOD_NAME = "Racer PCVR"
$MOD_VERSION = "v1.1"
$MOD_AUTHOR = "GameOrDie007"
$GAME_EXE = "SWEP1RCR.EXE"
$GAME_APPID = "808910"
$REPO = "GameOrDie007/Star-Wars-Episode-I-Racer-PCVR"
$RELEASES_URL = "https://github.com/$REPO/releases"
$MANIFEST_NAME = ".pcvrhub-starwars-racer-install.tsv"
$BACKUP_NAME = ".pcvrhub-starwars-racer-backup"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Star Wars Episode I Racer PCVR - Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ""; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!]  $Text" -ForegroundColor Yellow }
function Write-Fail { param([string]$Text) Write-Host " [X]  $Text" -ForegroundColor Red }
function Pause-User { param([string]$Text="Press Enter to continue...") Write-Host ""; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-RacerRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function Find-RacerRoot {
    $found = Find-SteamGameFolder -AppId $GAME_APPID `
        -SteamFolderNames @("Star Wars Episode I Racer") `
        -GogNames @("STAR WARS Racer","Star Wars Episode I Racer") `
        -ProbeExe $GAME_EXE
    if (Test-RacerRoot $found) { return $found }
    $recorded = $null
    try { $recorded = (Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Raw).Trim() } catch {}
    if (Test-RacerRoot $recorded) { return $recorded }
    foreach ($candidate in @(
        "C:\GOG Games\STAR WARS Racer",
        "C:\Program Files (x86)\GOG Galaxy\Games\STAR WARS Racer",
        "C:\Program Files (x86)\LucasArts\Star Wars Episode I Racer",
        "C:\Program Files (x86)\LucasArts\Racer"
    )) { if (Test-RacerRoot $candidate) { return $candidate } }
    return $null
}

function Get-LatestRacerRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -Headers @{"User-Agent"="PCVR-Mods-Hub"} -TimeoutSec 25 -ErrorAction Stop
        $asset = @($release.assets | Where-Object { $_.name -match '(?i)^Star-Wars-Episode-I-Racer-PCVR-v.*\.zip$' } | Select-Object -First 1)[0]
        if (-not $asset) { return $null }
        [pscustomobject]@{ Tag=[string]$release.tag_name; Name=[string]$asset.name; Url=[string]$asset.browser_download_url; Digest=[string]$asset.digest; Body=[string]$release.body }
    } catch { return $null }
}

function Read-InstallManifest([string]$Path) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $map }
    try {
        foreach ($row in @((Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Csv -Delimiter "`t")) {
            if ($row.RelativePath) { $map[[string]$row.RelativePath] = $row }
        }
    } catch {}
    return $map
}

function Install-RacerPayload([string]$PayloadRoot,[string]$GameRoot) {
    $manifestPath = Join-Path $GameRoot $MANIFEST_NAME
    $backupRoot = Join-Path $GameRoot $BACKUP_NAME
    $oldRows = Read-InstallManifest $manifestPath
    $sources = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
    foreach ($leaf in @("dinput.dll","openxr_loader.dll")) {
        $source = Join-Path $PayloadRoot $leaf
        if (Test-Path -LiteralPath $source -PathType Leaf) { [void]$sources.Add((Get-Item -LiteralPath $source)) }
    }
    $assetsRoot = Join-Path $PayloadRoot "assets"
    if (Test-Path -LiteralPath $assetsRoot -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $assetsRoot -Recurse -File)) { [void]$sources.Add($file) }
    }
    if (-not ($sources.Name -contains "dinput.dll") -or -not ($sources.Name -contains "openxr_loader.dll") -or $sources.Count -lt 3) {
        throw "The release does not contain the expected Racer PCVR payload. Nothing was installed."
    }

    $newRows = New-Object 'System.Collections.Generic.List[object]'
    foreach ($file in $sources) {
        $relative = $file.FullName.Substring($PayloadRoot.TrimEnd('\').Length).TrimStart('\')
        $destination = Join-Path $GameRoot $relative
        $destParent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }

        $action = "remove"
        if ($oldRows.ContainsKey($relative)) {
            $action = [string]$oldRows[$relative].Action
        } elseif (Test-Path -LiteralPath $destination -PathType Leaf) {
            $backup = Join-Path (Join-Path $backupRoot "original") $relative
            $backupParent = Split-Path -Parent $backup
            if (-not (Test-Path -LiteralPath $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
            Copy-Item -LiteralPath $destination -Destination $backup -Force -ErrorAction Stop
            $action = "restore"
        }

        # If a file changed after our preceding install, keep that version as
        # a conflict copy before updating the port. It is never discarded.
        if ($oldRows.ContainsKey($relative) -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $oldHash = [string]$oldRows[$relative].InstalledSha256
            $currentHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            if ($oldHash -and $currentHash -ne $oldHash) {
                $conflict = Join-Path (Join-Path $GameRoot ".pcvrhub-starwars-racer-conflicts") ($relative + "." + (Get-Date -Format "yyyyMMddHHmmss"))
                $conflictParent = Split-Path -Parent $conflict
                if (-not (Test-Path -LiteralPath $conflictParent)) { New-Item -ItemType Directory -Path $conflictParent -Force | Out-Null }
                Copy-Item -LiteralPath $destination -Destination $conflict -Force
                Write-Warn "Preserved a changed file before updating: $relative"
            }
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force -ErrorAction Stop
        [void]$newRows.Add([pscustomobject]@{ Action=$action; RelativePath=$relative; InstalledSha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash })
    }
    $lines = @("Action`tRelativePath`tInstalledSha256")
    foreach ($row in $newRows) { $lines += "$($row.Action)`t$($row.RelativePath)`t$($row.InstalledSha256)" }
    [IO.File]::WriteAllLines($manifestPath, [string[]]$lines, (New-Object Text.UTF8Encoding($false)))
    return @($newRows | ForEach-Object { Join-Path $GameRoot $_.RelativePath })
}

Write-Header
Write-Host " This port adds stereo rendering, head tracking and Quest" -ForegroundColor White
Write-Host " motion controls to the original podracing game." -ForegroundColor White
Write-Host ""
Write-Host " REQUIRED: a 32-bit OpenXR runtime." -ForegroundColor Yellow
Write-Host " Virtual Desktop with VDXR works. SteamVR is 64-bit only and" -ForegroundColor Yellow
Write-Host " cannot load this port. Connect the headset before launch." -ForegroundColor Yellow
Show-AntivirusNotice
Pause-User "Press Enter to proceed with setup..." | Out-Null

Write-Step 1 3 "Locating the game"
$gamePath = Find-RacerRoot
while (-not (Test-RacerRoot $gamePath)) {
    Write-Warn "The game folder was not found automatically."
    Write-Host " Drag the folder containing $GAME_EXE onto this window," -ForegroundColor White
    Write-Host " then press Enter. Leave it empty to cancel." -ForegroundColor Gray
    $picked = ("" + (Read-Host " Game folder")).Trim().Trim('"').Trim("'")
    if (-not $picked) { Write-Fail "Setup cancelled."; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
    if (Test-RacerRoot $picked) { $gamePath = $picked } else { Write-Fail "$GAME_EXE is not in that folder." }
}
Write-OK "Found: $gamePath"
try {
    if (@(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($GAME_EXE)) -ErrorAction SilentlyContinue).Count) {
        Write-Warn "The game is running. Close it before continuing."
        Pause-User "Press Enter once the game is closed..." | Out-Null
    }
} catch {}

Write-Step 2 3 "Downloading the newest Racer PCVR release"
$work = Join-Path $env:TEMP ("pcvr_racer_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$zipPath = Join-Path $work "RacerPCVR.zip"
$release = Get-LatestRacerRelease
$installedTag = "v1.1"
if ($release) {
    $installedTag = $release.Tag
    Write-Info "Newest release: $installedTag"
    $downloaded = Invoke-SafeDownload -Urls @($release.Url) -Destination $zipPath -Label "$MOD_NAME $installedTag" -ManualUrl $RELEASES_URL
    if ($downloaded -and $release.Digest -match '^sha256:([0-9a-fA-F]{64})$') {
        $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
        if ($actual -ne $matches[1]) { throw "The downloaded archive does not match GitHub's SHA-256 digest." }
    }
}
if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
    $local = Find-PredownloadedFile -Patterns @("Star-Wars-Episode-I-Racer-PCVR-v1.1.zip") `
        -ExpectedName "Star-Wars-Episode-I-Racer-PCVR-v1.1.zip" -ExpectedSize 3355298 `
        -ExpectedSha256 "C25F1480CBB20A94687CBC707F09D372822023AF64006B245F7AB792F56E1534" `
        -ExtraFolders @((Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "Archive Input\Neue Spiele")) `
        -Label "Racer PCVR v1.1"
    if ($local) { Copy-Item -LiteralPath $local -Destination $zipPath -Force }
}
while (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
    Write-Warn "Automatic download did not complete."
    try { Start-Process $RELEASES_URL } catch {}
    $picked = ("" + (Read-Host " Drag the downloaded ZIP here (empty to cancel)")).Trim().Trim('"').Trim("'")
    if (-not $picked) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue; exit 1 }
    if (Test-Path -LiteralPath $picked -PathType Leaf) { Copy-Item -LiteralPath $picked -Destination $zipPath -Force }
}

Write-Step 3 3 "Installing safely beside $GAME_EXE"
$extract = Join-Path $work "extracted"
New-Item -ItemType Directory -Path $extract -Force | Out-Null
try { Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force -ErrorAction Stop }
catch { throw "Could not extract the Racer PCVR archive: $($_.Exception.Message)" }
$payload = Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile "dinput.dll"
$placed = Install-RacerPayload -PayloadRoot $payload -GameRoot $gamePath
if (-not (Test-Path -LiteralPath (Join-Path $gamePath "openxr_loader.dll")) -or -not (Test-Path -LiteralPath (Join-Path $gamePath "dinput.dll"))) {
    throw "Installation verification failed. The game was not marked VR Ready."
}
$archiveForRecovery = $zipPath
$gameForRecovery = $gamePath
$recoverBinaries = {
    $stage = Join-Path $gameForRecovery ".pcvrhub-racer-recovery"
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    Expand-Archive -LiteralPath $archiveForRecovery -DestinationPath $stage -Force
    $root = Get-ExtractedPayloadRoot -ExtractDir $stage -RelModFile "dinput.dll"
    foreach ($leaf in @("dinput.dll","openxr_loader.dll")) {
        Copy-Item -LiteralPath (Join-Path $root $leaf) -Destination (Join-Path $gameForRecovery $leaf) -Force
    }
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}.GetNewClosure()
if (-not (Confirm-PlacedFilesSurvive -Paths @((Join-Path $gamePath "dinput.dll"),(Join-Path $gamePath "openxr_loader.dll")) -GameDir $gamePath -Recopy $recoverBinaries)) {
    throw "The VR loader did not survive the antivirus check."
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_path"), $gamePath, (New-Object Text.UTF8Encoding($false)))
Save-InstalledStamp -GameDir $gamePath -Version $installedTag -HubDir $PSScriptRoot
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "$MOD_NAME $installedTag installed."

Write-Host ""
Write-Host " OPTIONAL COMMUNITY TRACKS" -ForegroundColor Cyan
Write-Host " Add the current SW_RACER_RE community tracks now?" -ForegroundColor White
Write-Host " [Y] Install community tracks" -ForegroundColor White
Write-Host " [S] Skip for now" -ForegroundColor Gray
Write-Host ""
Write-Host " The track setup copies only assets\custom_tracks; the community" -ForegroundColor Yellow
Write-Host " pack's different dinput.dll never replaces the PCVR build." -ForegroundColor Yellow
$tracksChoice = ""
do {
    $tracksChoice = ("" + (Read-Host " Choose Y or S (Enter = skip)")).Trim().ToUpperInvariant()
    if (-not $tracksChoice) { $tracksChoice = "S" }
} while ($tracksChoice -notin @("Y","YES","S"))

$tracksInstaller = Join-Path $PSScriptRoot "..\StarWarsEpisodeIRacerTracks\StarWarsEpisodeIRacerTracks-core.ps1"
if ($tracksChoice -in @("Y","YES")) {
    Write-Host ""
    Write-Host " Installing community tracks..." -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tracksInstaller -GameRoot $gamePath -NoIntro -NoPause
    $tracksExit = $LASTEXITCODE
    if ($tracksExit -ne 0) { Write-Warn "Community tracks were not installed. Racer PCVR remains ready; use Community tracks on the game's Hub page to retry." }
}
if ($tracksChoice -eq "S") {
    Write-Info "Skipped. Community tracks remains available on this game's Hub page."
}

Write-Host ""
Write-Host " STARTING THE GAME" -ForegroundColor Cyan
Write-Host " Use Start in VR in the Hub, or launch the game normally from" -ForegroundColor White
Write-Host " Steam/GOG. Virtual Desktop and VDXR must already be connected." -ForegroundColor White
Write-Host " The Hub launches $GAME_EXE with the correct game-folder context." -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Now this is podracing. Sebulba still thinks the track is his." -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Pause-User "Press Enter to exit..." | Out-Null
