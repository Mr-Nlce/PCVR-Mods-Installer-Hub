# ============================================================
# BioShock Infinite VR - Installer (bioshock-vr by mohamad-balouza)
# ============================================================
# Native VR for BioShock Infinite: stereo rendering, 6DOF head
# tracking and motion controllers - the gun in one hand, the vigor in the
# other. Since v0.7.0 ONE release serves both BioShock games: the same
# two DLLs detect which game loaded them.
#
# Install = copy two files next to the game exe:
#   <game>\Binaries\Win32\xinput1_3.dll     (the injector)
#   <game>\Binaries\Win32\bioshockvr.dll    (the mod)
# NOTE: NOT Build\Final as in BioShock 1 and 2 - Infinite runs on
# Unreal Engine 3 and keeps its binaries elsewhere. Both are
# handled. No game file is modified; uninstalling is deleting the two.
#
# The calibration is BUILT INTO the DLL, so nothing has to be written to
# %LOCALAPPDATA%. The zip's preset-bsi folder is only the author's own
# tuning for people who experimented and want it back - the README says
# where it goes, the installer stays out of that folder.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "BioShock Infinite VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " BioShock Infinite VR - Installer" -ForegroundColor Cyan
    Write-Host " bioshock-vr by balouza | BioShock Infinite | motion controls" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO         = "mohamad-balouza/bioshock-vr"
$REPO_API     = "https://api.github.com/repos/$REPO/releases"
$RELEASES_URL = "https://github.com/$REPO/releases"
$APP_ID       = "8870"
$GAME_EXE     = "BioShockInfinite.exe"
$MOD_FILES    = @("xinput1_3.dll", "bioshockvr.dll", "bvr_steamvr32.dll", "openvr_api.dll")
# Steam, GOG and Epic all put the binaries under Binaries\Win32.
# !!! NOT Build\Final - THAT IS THE DIFFERENCE TO BIOSHOCK 1 AND 2 !!!
# Infinite runs on Unreal Engine 3 and keeps its binaries elsewhere:
# Binaries\Win32. The author spells this out in his notes because it
# is the most common mix-up.
$BIN_SUBDIRS  = @("Binaries\Win32")
$CANDIDATE_ROOTS = @(
    "C:\Program Files (x86)\Steam\steamapps\common\BioShock Infinite",
    "C:\GOG Games\BioShock Infinite",
    "C:\Program Files (x86)\GOG Galaxy\Games\BioShock Infinite",
    "C:\Program Files\Epic Games\BioShock2Remastered"
)

# Find the folder that really holds BioShockInfinite.exe, whatever the store.
function Find-BioshockInfiniteBin {
    $roots = New-Object System.Collections.Generic.List[string]
    try {
        $steam = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("BioShock Infinite") -ProbeExe "Binaries\Win32\$GAME_EXE"
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
Write-Host "  Columbia at eye level: stereo rendering, 6DOF head tracking and" -ForegroundColor Gray
Write-Host "  motion controllers - the gun in your right hand, the vigor" -ForegroundColor Gray
Write-Host "  in your left, each aiming from that hand. The HUD rides a" -ForegroundColor Gray
Write-Host "  readable floating panel, and the calibration ships tuned." -ForegroundColor Gray
Write-Host ""
Write-Host "  Needed: BioShock Infinite REMASTERED (not the 2010 original) and an" -ForegroundColor White
Write-Host "  OpenXR runtime - Virtual Desktop (VDXR), Steam Link or SteamVR." -ForegroundColor White
Show-AntivirusNotice
Pause-User "Press Enter to start the installation..." | Out-Null

# ---- 1. locate the game -------------------------------------
Write-Step 1 5 "Locating BioShock Infinite"

$binDir = Find-BioshockInfiniteBin
if ($binDir) { Write-OK "Found: $binDir" }
else {
    Write-Warn "BioShock Infinite was not found automatically."
    Write-Host "  Drag the game folder here and press Enter - the one holding" -ForegroundColor White
    Write-Host "  Binaries\Win32\$GAME_EXE, for example:" -ForegroundColor White
    Write-Host "    C:\Program Files (x86)\Steam\steamapps\common\BioShock Infinite" -ForegroundColor Gray
    while (-not $binDir) {
        $r = (Read-Host "  Folder").Trim().Trim('"')
        if (-not $r) { Write-Fail "Nothing entered."; continue }
        foreach ($sub in @("", "Binaries\Win32")) {
            $cand = if ($sub) { Join-Path $r $sub } else { $r }
            if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { $binDir = $cand; break }
        }
        if (-not $binDir) { Write-Fail "$GAME_EXE not found under: $r" }
    }
    Write-OK "Using: $binDir"
}

# Resolve this before installation: the exclusion covers the complete game
# root, while the watched DLLs themselves land in Binaries\Win32.
$gameRoot = $binDir
foreach ($sub in $BIN_SUBDIRS) {
    if ($gameRoot -like ("*\" + $sub)) { $gameRoot = $gameRoot.Substring(0, $gameRoot.Length - $sub.Length - 1); break }
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
Write-Step 2 5 "Downloading the mod"

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
Write-Step 3 5 "Installing into $binDir"

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
Write-Step 4 5 "Turning VR on"
# ---- THE PRESET, AND WHY IT IS MANDATORY HERE ------------------
# FINDING FROM THE PACKAGE'S THREE PRESETS: bs1 and bs2 carry
# "toggles are implied ON" in their header plus autoVr=1 - the mod
# arms itself there. preset-bsi has NO autoVr but is the ONLY one of
# the three to list vrstereoOn=1 and driveHmd=1 explicitly.
# On top of that the README mentions the one-click button only for
# BS1 and BS2 ("VR PRESET 1 (BS1) / APPLY PRESET (BS2)") - Infinite
# does not appear in it. The result without this file: the VR session
# starts, but stereo and head tracking stay off - a flat panel in the
# headset with black bars, because the game renders 16:9 while the
# panel is nearly square. That is exactly what was observed, by more
# than one person.
# The file sets all of it in one go: stereo on, head tracking on, and
# the nearly square resolution 2064x2208.
# IT DOES NOT BELONG IN THE GAME FOLDER but in THIS game's settings
# folder - the three BioShocks share no files.
$presetSrc = Get-ChildItem -LiteralPath $exDir -Filter "vrpreset.ini" -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $_.DirectoryName -match '(?i)preset-bsi' } | Select-Object -First 1
$presetDir = Join-Path $env:LOCALAPPDATA "BioshockVR\bsi"
$presetDst = Join-Path $presetDir "vrpreset.ini"

if (-not $presetSrc) {
    Write-Warn "No preset-bsi\vrpreset.ini in the archive - skipping the VR switches."
} else {
    try { New-Item -ItemType Directory -Path $presetDir -Force -ErrorAction Stop | Out-Null } catch {}
    $haveOld = Test-Path -LiteralPath $presetDst
    $write   = $true
    if ($haveOld) {
        # An existing file may hold the user's own tuning - that is not
        # overwritten silently.
        Write-Host ""
        Write-Host "  You already have VR settings for Infinite:" -ForegroundColor White
        Write-Host "     $presetDst" -ForegroundColor Gray
        Write-Host "  Replacing them turns stereo and head tracking on and sets a" -ForegroundColor White
        Write-Host "  near-square resolution. Your own tuning would be backed up." -ForegroundColor White
        $write = Read-YesNo "  Replace them with the author's tested settings?"
        if ($write) {
            try { Copy-Item -LiteralPath $presetDst -Destination ($presetDst + ".bak") -Force -ErrorAction Stop
                  Write-OK "Your settings backed up as vrpreset.ini.bak" } catch {}
        }
    }
    if ($write) {
        try {
            Copy-Item -LiteralPath $presetSrc.FullName -Destination $presetDst -Force -ErrorAction Stop
            Write-OK "VR switches set: stereo on, head tracking on, near-square resolution."
        } catch { Write-Warn "Could not write the preset: $($_.Exception.Message)" }
    } else {
        Write-Info "Kept your own settings."
    }
}

# A scanner usually sweeps a moment AFTER the write, so the files can be
# gone right after this point. If they are, the user is walked through an
# exclusion and they are put back FROM INSIDE the game folder.
$avFilesOk = Confirm-PlacedFilesSurvive `
    -Paths @($MOD_FILES | ForEach-Object { Join-Path $binDir $_ }) `
    -GameDir $gameRoot `
    -ArchivePath $zipDest
if (-not $avFilesOk) {
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Write-Fail "The VR mod could not be restored after the antivirus check."
    Pause-User "Press Enter to exit, then run the installer again."
    exit 1
}

try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if ($copied -lt $MOD_FILES.Count) {
    Write-Fail "The mod is not fully installed."
    Write-Host "  Copy both DLLs into: $binDir" -ForegroundColor Cyan
    Pause-User "Press Enter to exit."; exit 1
}

# ---- 4. markers ---------------------------------------------
Write-Step 5 5 "Finishing up"
# RECORD THE GAME ROOT, NOT THE BIN FOLDER. The post-install refresh joins
# the catalog's ModFile ("Binaries\Win32\xinput1_3.dll") onto this path, so
# recording ...\Binaries\Win32 here would make it look for
# ...\Binaries\Win32\Binaries\Win32\xinput1_3.dll - never found, and the tile
# would stay on "Needs Mod" until the next full scan.
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
if ($relTag) { Save-InstalledStamp -GameDir $gameRoot -Version $relTag -HubDir $SCRIPT_DIR }

Write-OK "Installed."

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " BioShock Infinite VR is installed!" -ForegroundColor Green
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
Write-Host "  Right hand = gun, left hand = vigor. Aim laser and dot are on." -ForegroundColor DarkGray
Write-Host "  Press F10 in the headset for the tuning overlay." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Bring us the girl. Look up while you do it." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
