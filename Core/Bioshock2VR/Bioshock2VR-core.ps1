# ============================================================
# BioShock 2 VR - Installer (bioshock-vr by mohamad-balouza)
# ============================================================
# Native VR for BioShock 2 Remastered: stereo rendering, 6DOF head
# tracking and motion controllers - weapons in one hand, plasmids in the
# other. Since v0.7.0 ONE release serves both BioShock games: the same
# two DLLs detect which game loaded them.
#
# Install = copy two files next to the game exe:
#   <game>\Build\Final\xinput1_3.dll     (the injector)
#   <game>\Build\Final\bioshockvr.dll    (the mod)
# Epic ships its binaries in Build\FinalEpic instead - both layouts are
# handled. No game file is modified; uninstalling is deleting the two.
#
# The calibration is BUILT INTO the DLL, so nothing has to be written to
# %LOCALAPPDATA%. The zip's preset-bs2 folder is only the author's own
# tuning for people who experimented and want it back - the README says
# where it goes, the installer stays out of that folder.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "BioShock 2 VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " BioShock 2 VR - Installer" -ForegroundColor Cyan
    Write-Host " bioshock-vr by balouza | BioShock 2 Remastered | motion controls" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO         = "mohamad-balouza/bioshock-vr"
$REPO_API     = "https://api.github.com/repos/$REPO/releases"
$RELEASES_URL = "https://github.com/$REPO/releases"
$APP_ID       = "409720"
$GAME_EXE     = "Bioshock2HD.exe"
$MOD_FILES    = @("xinput1_3.dll", "bioshockvr.dll")
# Steam and GOG put the binaries in Build\Final, Epic in Build\FinalEpic.
$BIN_SUBDIRS  = @("Build\Final", "Build\FinalEpic")
$CANDIDATE_ROOTS = @(
    "C:\Program Files (x86)\Steam\steamapps\common\BioShock 2 Remastered",
    "C:\GOG Games\BioShock 2 Remastered",
    "C:\Program Files (x86)\GOG Galaxy\Games\BioShock 2 Remastered",
    "C:\Program Files\Epic Games\BioShock2Remastered"
)

# Find the folder that really holds Bioshock2HD.exe, whatever the store.
function Find-Bioshock2Bin {
    $roots = New-Object System.Collections.Generic.List[string]
    try {
        $steam = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("BioShock 2 Remastered") -ProbeExe "Build\Final\$GAME_EXE"
        if ($steam) { [void]$roots.Add([string]$steam) }
    } catch { }
    foreach ($c in $CANDIDATE_ROOTS) { [void]$roots.Add($c) }
    foreach ($r in $roots) {
        if (-not $r) { continue }
        foreach ($sub in $BIN_SUBDIRS) {
            $cand = Join-Path $r $sub
            if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { return $cand }
        }
    }
    return $null
}

function Get-LatestBioshockVR {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri "$REPO_API`?per_page=5" -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($rel in @($rels)) {
            $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
            if ($zips.Count -gt 0) {
                $pick = $zips | Where-Object { $_.name -match '(?i)bioshock' } | Select-Object -First 1
                if (-not $pick) { $pick = $zips[0] }
                return @{ Url = [string]$pick.browser_download_url; Tag = [string]$rel.tag_name; Name = [string]$pick.name }
            }
        }
    } catch { }
    return $null
}

Write-Header
Write-Host "  Rapture at eye level: stereo rendering, 6DOF head tracking and" -ForegroundColor Gray
Write-Host "  motion controllers - the weapon in your right hand, the plasmid" -ForegroundColor Gray
Write-Host "  in your left, each aiming from that hand. The HUD rides a" -ForegroundColor Gray
Write-Host "  readable floating panel, and the calibration ships tuned." -ForegroundColor Gray
Write-Host ""
Write-Host "  Needed: BioShock 2 REMASTERED (not the 2010 original) and an" -ForegroundColor White
Write-Host "  OpenXR runtime - Virtual Desktop (VDXR), Steam Link or SteamVR." -ForegroundColor White
Pause-User "Press Enter to start the installation..." | Out-Null

# ---- 1. locate the game -------------------------------------
Write-Step 1 4 "Locating BioShock 2 Remastered"

$binDir = Find-Bioshock2Bin
if ($binDir) { Write-OK "Found: $binDir" }
else {
    Write-Warn "BioShock 2 Remastered was not found automatically."
    Write-Host "  Drag the game folder here and press Enter - the one holding" -ForegroundColor White
    Write-Host "  Build\Final\$GAME_EXE, for example:" -ForegroundColor White
    Write-Host "    C:\Program Files (x86)\Steam\steamapps\common\BioShock 2 Remastered" -ForegroundColor Gray
    while (-not $binDir) {
        $r = (Read-Host "  Folder").Trim().Trim('"')
        if (-not $r) { Write-Fail "Nothing entered."; continue }
        foreach ($sub in @("", "Build\Final", "Build\FinalEpic")) {
            $cand = if ($sub) { Join-Path $r $sub } else { $r }
            if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { $binDir = $cand; break }
        }
        if (-not $binDir) { Write-Fail "$GAME_EXE not found under: $r" }
    }
    Write-OK "Using: $binDir"
}

# A leftover injector from the other head-tracking mod uses the SAME file
# name - the mod's own README says the two cannot coexist.
$existing = Join-Path $binDir "xinput1_3.dll"
$foreignInjector = $false
if (Test-Path -LiteralPath $existing) {
    try {
        $desc = (Get-Item -LiteralPath $existing).VersionInfo.FileDescription
        if ($desc -and ($desc -notmatch '(?i)bioshock ?vr|balouza')) { $foreignInjector = $true }
    } catch { }
}

# ---- 2. download --------------------------------------------
Write-Step 2 4 "Downloading the mod"

$tmp = Join-Path $env:TEMP ("bs2vr_" + [Guid]::NewGuid().ToString("N"))
try { New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null }
catch { Write-Fail "Could not create a temp folder: $_"; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
$zipDest = Join-Path $tmp "bioshock-vr.zip"

$urls = New-Object System.Collections.Generic.List[string]
$relTag = $null
Write-Info "Resolving the newest release ..."
$latest = Get-LatestBioshockVR
if ($latest) {
    Write-OK "Release: $($latest.Tag)  ($($latest.Name))"
    $relTag = [string]$latest.Tag
    [void]$urls.Add([string]$latest.Url)
} else {
    Write-Warn "GitHub API not reachable - you will be pointed at the releases page."
}

Invoke-SafeDownload -Urls $urls -Destination $zipDest -Label "bioshock-vr" `
    -ManualUrl $RELEASES_URL `
    -Instructions "Download the newest 'bioshock-vr-*.zip' from the releases page, save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

while (-not (Test-Path -LiteralPath $zipDest)) {
    Write-Fail "The archive is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download bioshock-vr" -Subject "the bioshock-vr release archive" `
        -Url $RELEASES_URL -DestFile $zipDest `
        -Instructions "Download the .zip from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded archive." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null; exit 1
    }
}
Write-OK "Archive ready."

# ---- 3. install ---------------------------------------------
Write-Step 3 4 "Installing into $binDir"

$exDir = Join-Path $tmp "x"
try {
    New-Item -ItemType Directory -Path $exDir -Force -ErrorAction Stop | Out-Null
    Expand-Archive -LiteralPath $zipDest -DestinationPath $exDir -Force -ErrorAction Stop
} catch {
    Write-Fail "Unpacking failed: $($_.Exception.Message)"
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}

if ($foreignInjector) {
    Write-Warn "Another mod's xinput1_3.dll is already there - the two cannot coexist."
    $stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $parked = "$existing.replaced-$stamp"
    try {
        Copy-Item -LiteralPath $existing -Destination $parked -Force -ErrorAction Stop
        Write-OK "Kept a copy as xinput1_3.dll.replaced-$stamp (rename it back to undo)"
    } catch { Write-Warn "Could not back it up: $($_.Exception.Message)" }
}

# The two DLLs sit at the archive root, but search for them so a future
# release can move them into a subfolder without breaking this.
$copied = 0
foreach ($f in $MOD_FILES) {
    $hit = Get-ChildItem -LiteralPath $exDir -Filter $f -Recurse -File -ErrorAction SilentlyContinue |
           Where-Object { $_.DirectoryName -notmatch '(?i)preset' } | Select-Object -First 1
    if (-not $hit) { Write-Fail "$f is not in the archive."; continue }
    try {
        Copy-Item -LiteralPath $hit.FullName -Destination (Join-Path $binDir $f) -Force -ErrorAction Stop
        Write-OK "$f installed."
        $copied++
    } catch {
        Write-Fail "Could not copy $f - is the game running? ($($_.Exception.Message))"
    }
}
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if ($copied -lt $MOD_FILES.Count) {
    Write-Fail "The mod is not fully installed."
    Write-Host "  Copy both DLLs into: $binDir" -ForegroundColor Cyan
    Pause-User "Press Enter to exit."; exit 1
}

# ---- 4. markers ---------------------------------------------
Write-Step 4 4 "Finishing up"
# RECORD THE GAME ROOT, NOT THE BIN FOLDER. The post-install refresh joins
# the catalog's ModFile ("Build\Final\xinput1_3.dll") onto this path, so
# recording ...\Build\Final here would make it look for
# ...\Build\Final\Build\Final\xinput1_3.dll - never found, and the tile
# would stay on "Needs Mod" until the next full scan.
$gameRoot = $binDir
foreach ($sub in $BIN_SUBDIRS) {
    if ($gameRoot -like ("*\" + $sub)) { $gameRoot = $gameRoot.Substring(0, $gameRoot.Length - $sub.Length - 1); break }
}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
Write-OK "Installed."

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " BioShock 2 VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |          SET A SQUARE RESOLUTION IN THE GAME          |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Something like 2700 x 2700, not 16:9 " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Headset panels are near square. A 16:9 picture renders a wide" -ForegroundColor Gray
Write-Host "  strip that the headset throws away - square is sharper AND faster." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Start your runtime first (Virtual Desktop: set OpenXR to VDXR)," -ForegroundColor Gray
Write-Host "    then launch the game through Steam. Load your save - you are in VR." -ForegroundColor Gray
Write-Host "    Press F10 for the mod menu; APPLY at the top arms everything." -ForegroundColor Gray
Write-Host ""
Write-Host "  Right hand = weapons, left hand = plasmids. The shipped" -ForegroundColor DarkGray
Write-Host "  calibration is already tuned; see the README for the rest." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Rapture never asked you to look away. Now you cannot." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
