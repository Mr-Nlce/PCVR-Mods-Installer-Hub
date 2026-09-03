# =============================================================
#  Elden Ring VR - Ilya's ERVR (motion controls)
# =============================================================
# Called from EldenRingVR-core.ps1 when the user picks mod 2. Kept
# separate because it has nothing in common with Hotbite's install:
# Hotbite runs the game through ModEngine from its own folder under
# LOCALAPPDATA, ERVR drops a ReShade add-on into the game folder.
#
# WHAT GOES WHERE (read from the real archive, 6 entries, 3,038,759 B,
# sha256 ad9ca95a825299b1cf72e06d59e6694fab7e22af2f063ca273b8e0946ccec6e7):
#   <game>\Game\dxgi.dll          ReShade 6.8.0 add-on build, bundled
#   <game>\Game\dinput8.dll       ERVR's proxy loader
#   <game>\Game\ReShade.ini
#   <game>\Game\ERVR\ERVR.dll     the mod
#   <game>\Game\ERVR\ERVR.ini     configuration, hot-reloads
#
# !!! CANNOT COEXIST WITH LUKE ROSS R.E.A.L. Both use dxgi.dll. The
# author says so in his own instructions, and this installer checks for
# R.E.A.L. before writing anything.

param(
    [string]$GameDir = "",
    [string]$BuildMode = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "EldenRingSettings.ps1")
if (-not (Get-Command Write-EldenRingMotionLauncher -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot "EldenRingDepot.ps1")
}

$MOD_NAME    = "Elden Ring VR - ERVR"
$MOD_AUTHOR  = "Ilya"
$MOD_VERSION = "V0.3.0"
$NEXUS_MOD   = "https://www.nexusmods.com/eldenring/mods/10711"
$NEXUS_FILES = "https://www.nexusmods.com/eldenring/mods/10711?tab=files"
$STEAM_APPID = "1245620"
$GAME_FOLDER = "ELDEN RING"
$GAME_PROBE  = "Game\eldenring.exe"
$ERVR_FILES   = @("dxgi.dll", "dinput8.dll", "ReShade.ini")
$ERVR_MARKER  = "ERVR\ERVR.dll"
# Luke Ross's files - if these are here, dxgi.dll is his and ours would
# overwrite it.
$REAL_MARKERS = @("RealRepo\RealVR64.dll", "RealRepo_\RealVR64.dll", "RealVR.ini")

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x  " -ForegroundColor Black -BackgroundColor Cyan; Write-Host "" }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Same as in the other installers that take a hand-fetched archive -
# the shared module carries install machinery, not this.
function Get-DroppedFile {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Warn "File not found: $p"; continue }
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected: $($Exts -join ', ')."
            continue
        }
        return $p
    }
}

function Get-EldenRingFolder {
    $p = $null
    if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
        try { $p = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($GAME_FOLDER) -ProbeExe $GAME_PROBE } catch {}
    }
    if (-not $p) {
        try { $p = Get-GameFolderInteractive -GameName "Elden Ring" -ExeName "eldenring.exe" } catch {}
    }
    return $p
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Elden Ring VR  -  ERVR $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Native stereo into your OpenXR headset, first person with" -ForegroundColor White
Write-Host "  the weapon on your hand, and combat rebuilt around the" -ForegroundColor White
Write-Host "  controllers: the blade is the hitbox, damage follows how" -ForegroundColor White
Write-Host "  fast you actually swing, two-handing is grabbing the hilt." -ForegroundColor White
Write-Host ""
# !!! THE BAN WARNING MOVED TO THE END (2026-08-29). Here it scrolled
# past before anyone could read it - the install output pushed it off
# screen within seconds. It now sits behind an Enter gate at the very
# end, where the reader has to acknowledge it before the window closes.
# One short line stays here so nobody is surprised by it later.
Write-Host "  Offline only, Easy Anti-Cheat off - details at the end. " -NoNewline -ForegroundColor Black -BackgroundColor Red
Write-Host ""
Write-Host ""
Show-AntivirusNotice

# ---- 1. The game folder --------------------------------------
Write-Step 1 3 "Finding Elden Ring"

$gameDir = $GameDir
if (-not $gameDir) { $gameDir = Get-EldenRingFolder }
if (-not $gameDir) {
    Write-Fail "Could not find your Elden Ring folder."
    Pause-User "Press Enter to exit."
    exit 1
}
$gameSub = Join-Path $gameDir "Game"
if (-not (Test-Path -LiteralPath (Join-Path $gameSub "eldenring.exe"))) {
    Write-Fail "No eldenring.exe in $gameSub"
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameSub"

# !!! REFUSE TO OVERWRITE R.E.A.L. SILENTLY.
$realHere = @($REAL_MARKERS | Where-Object { Test-Path -LiteralPath (Join-Path $gameSub $_) })
if ($realHere.Count -gt 0) {
    Write-Host ""
    Write-Host "  LUKE ROSS R.E.A.L. IS INSTALLED HERE. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host ""
    Write-Host "  Both mods use dxgi.dll and cannot both be in place - the" -ForegroundColor White
    Write-Host "  author of ERVR says the same in his instructions." -ForegroundColor White
    Write-Host ""
    Write-Host "  R.E.A.L. files found:" -ForegroundColor Gray
    foreach ($f in $realHere) { Write-Host "    $f" -ForegroundColor DarkGray }
    Write-Host ""
    Write-Do "Remove R.E.A.L. first, then install ERVR."
    Write-Host "  Its files are dxgi.dll, RealVR64.dll, openvr_api.dll," -ForegroundColor Gray
    Write-Host "  cudart64_12.dll and RealVR.ini." -ForegroundColor Gray
    Write-Host ""
    Write-Warn "Installation is blocked to prevent a mixed, broken loader state."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 2. The archive ------------------------------------------
Write-Step 2 3 "Getting ERVR $MOD_VERSION"

Write-Host "  ERVR is a free Nexus download. A Nexus account is needed," -ForegroundColor White
Write-Host "  and the file has to be fetched by hand - Nexus does not" -ForegroundColor White
Write-Host "  allow direct links." -ForegroundColor White
Write-Host ""

# The size is NOT pinned here: Nexus re-packages per version and this
# mod moves fast. Matching only the name would offer an older build
# from a previous update cycle, so the search is left to the drop.
$zip = Find-PredownloadedFile -Patterns @("ERVR_V*.zip", "ERVR*.zip") `
        -ExpectedSize 3038759 `
        -Label "the ERVR $MOD_VERSION archive"
if (-not $zip) {
    Pause-User "Press Enter to open the ERVR files page..."
    try { Start-Process $NEXUS_FILES } catch { Write-Warn "Open manually: $NEXUS_FILES" }
    Write-Host ""
    Write-Do "Download the main file, then drag it in below."
    $zip = Get-DroppedFile -Label "the ERVR archive" -Exts @(".zip", ".7z", ".rar")
}
if (-not $zip) {
    Write-Info "Nothing was changed."
    Pause-User "Press Enter to exit."
    exit 0
}
Write-OK "Archive: $zip"

# ---- 3. Install ----------------------------------------------
Write-Step 3 3 "Installing into the game folder"

$tmp = Join-Path $env:TEMP ("ERVR_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$ex = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label "$MOD_NAME $MOD_VERSION"
if ([string]$ex -eq "quit") {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The payload sits at the archive root, but a re-zip can nest it - find
# ERVR.dll and work from its parent's parent.
$probe = Get-ChildItem -LiteralPath $tmp -Filter "ERVR.dll" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $probe) {
    Write-Fail "ERVR.dll was not in that archive - is it the right download?"
    Write-Info "Expected the main file from $NEXUS_MOD"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$srcRoot = Split-Path -Parent (Split-Path -Parent $probe.FullName)

$backupDir = Join-Path $gameSub ".pcvrhub-ervr-backup"
$backupManifest = Join-Path $backupDir "manifest.txt"
$wasErvrInstalled = Test-Path -LiteralPath (Join-Path $gameSub $ERVR_MARKER) -PathType Leaf

# A marker-less ERVR folder is an unknown partial/manual layout. Deleting or
# merging it would make rollback ambiguous, so leave it untouched.
if (-not $wasErvrInstalled -and (Test-Path -LiteralPath (Join-Path $gameSub "ERVR") -PathType Container)) {
    Write-Fail "Game\ERVR already exists but contains no ERVR.dll marker."
    Write-Info "Move or remove that partial folder, then run the installer again. Nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# A foreign dinput8 proxy cannot safely be replaced: the author's advanced
# route is to keep that loader and register ERVR.dll through it, which is not
# the layout this automated installer manages. Stop before touching anything.
if (-not $wasErvrInstalled -and (Test-Path -LiteralPath (Join-Path $gameSub "dinput8.dll"))) {
    Write-Fail "Game\dinput8.dll already belongs to another mod loader."
    Write-Info "Keep that loader and follow ERVR's advanced manual-loader instructions, or remove it before using this installer."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# First install ownership record. Files that existed beforehand are backed up
# and restored by the uninstaller; files ERVR introduced are removed. A
# personal ReShade.ini stays live and is never overwritten.
if (-not $wasErvrInstalled -and -not (Test-Path -LiteralPath $backupManifest)) {
    try {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $manifestLines = @()
        foreach ($managed in $ERVR_FILES) {
            $existing = Join-Path $gameSub $managed
            if (Test-Path -LiteralPath $existing -PathType Leaf) {
                if ($managed -eq "ReShade.ini") {
                    $manifestLines += "$managed=keep"
                } else {
                    Copy-Item -LiteralPath $existing -Destination (Join-Path $backupDir $managed) -Force -ErrorAction Stop
                    $manifestLines += "$managed=restore"
                }
            } else {
                $manifestLines += "$managed=remove"
            }
        }
        Set-Content -LiteralPath $backupManifest -Value $manifestLines -Encoding ASCII -Force
    } catch {
        Write-Fail "Could not create the ERVR rollback record: $($_.Exception.Message)"
        try { Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        exit 1
    }
}

function Restore-ErvrFirstInstallState {
    if ($wasErvrInstalled -or -not (Test-Path -LiteralPath $backupManifest -PathType Leaf)) { return }
    foreach ($line in (Get-Content -LiteralPath $backupManifest -ErrorAction Stop)) {
        if ($line -notmatch '^([^=]+)=(restore|remove|keep)$') { continue }
        $name = $matches[1]; $mode = $matches[2]
        $live = Join-Path $gameSub $name
        $saved = Join-Path $backupDir $name
        if ($mode -eq "restore" -and (Test-Path -LiteralPath $saved -PathType Leaf)) {
            Copy-Item -LiteralPath $saved -Destination $live -Force -ErrorAction Stop
        } elseif ($mode -eq "remove" -and (Test-Path -LiteralPath $live)) {
            Remove-Item -LiteralPath $live -Force -ErrorAction Stop
        }
    }
    $partialErvr = Join-Path $gameSub "ERVR"
    if (Test-Path -LiteralPath $partialErvr) { Remove-Item -LiteralPath $partialErvr -Recurse -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue
}

$copied = 0
try {
    foreach ($f in $ERVR_FILES) {
        $src = Join-Path $srcRoot $f
        if (Test-Path -LiteralPath $src) {
            if ($f -eq "ReShade.ini" -and (Test-Path -LiteralPath (Join-Path $gameSub $f))) {
                Write-Info "Kept the existing Game\ReShade.ini."
                continue
            }
            Copy-Item -LiteralPath $src -Destination (Join-Path $gameSub $f) -Force -ErrorAction Stop
            $copied++
        }
    }
    $ervrDir = Join-Path $gameSub "ERVR"
    if (-not (Test-Path -LiteralPath $ervrDir)) { New-Item -ItemType Directory -Path $ervrDir -Force | Out-Null }
    foreach ($f in @("ERVR.dll", "ERVR.ini")) {
        $src = Join-Path (Join-Path $srcRoot "ERVR") $f
        # ERVR.ini holds every combat threshold and hot-reloads while
        # playing - someone who has tuned it should not lose that to a
        # reinstall. Backed up, then replaced.
        $dst = Join-Path $ervrDir $f
        if ($f -eq "ERVR.ini" -and (Test-Path -LiteralPath $dst)) {
            try { Copy-Item -LiteralPath $dst -Destination "$dst.pre-update" -Force -ErrorAction Stop; Write-Info "Your ERVR.ini was kept as ERVR.ini.pre-update" } catch {}
        }
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop
            $copied++
        }
    }
} catch {
    Write-Fail "Could not copy the files: $($_.Exception.Message)"
    if (-not $wasErvrInstalled -and (Test-Path -LiteralPath $backupManifest -PathType Leaf)) {
        try {
            Restore-ErvrFirstInstallState
            Write-Info "The pre-install loader state was restored."
        } catch { Write-Warn "Automatic rollback was incomplete; run the included uninstaller." }
    }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $gameSub $ERVR_MARKER))) {
    Write-Fail "ERVR.dll did not arrive in $gameSub\ERVR"
    try { Restore-ErvrFirstInstallState } catch { Write-Warn "Automatic rollback was incomplete; run the included uninstaller." }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "$copied files placed."

# The archive currently ships in cinema mode: a flat game window on a
# head-locked quad. That is useful for diagnostics, but it is a terrible
# first impression of a VR mod. A Hub install is expected to start in the
# real stereoscopic mode; the detail page can change it again at any time.
$ervrConfig = Join-Path $gameSub 'ERVR\ERVR.ini'
$full3D = Set-EldenRingErvrFull3D -Path $ervrConfig -NoBackup
if ($full3D.Success) { Write-OK "ERVR starts in Full 3D (StereoMode=full)." }
else { Write-Warn "Could not enable Full 3D automatically: $($full3D.Reason)" }

# dxgi.dll is ReShade's unsigned add-on build and ERVR.dll injects into
# a running process - the two things scanners react to hardest.
$survived = Confirm-PlacedFilesSurvive `
    -Paths @((Join-Path $gameSub "dxgi.dll"), (Join-Path $gameSub $ERVR_MARKER)) `
    -GameDir $gameDir `
    -ArchivePath $zip
if (-not $survived) {
    Write-Fail "ERVR was removed or quarantined after installation."
    try { Restore-ErvrFirstInstallState } catch { Write-Warn "Automatic rollback was incomplete; run the included uninstaller." }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- Launcher + records --------------------------------------
try {
    $launcher = Write-EldenRingMotionLauncher -GameDir $gameDir
    Write-OK "Registered with the Hub."
} catch { Write-Warn "Could not write the launcher: $($_.Exception.Message)" }

try {
    if ($launcher -and (Test-Path -LiteralPath $launcher)) {
        $suffix = if ($BuildMode -eq "Depot") { "Depot 1.16.2" } else { "Current" }
        $ws = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Motion ($suffix).lnk"))
        $lnk.TargetPath = $launcher
        $lnk.WorkingDirectory = Split-Path -Parent $launcher
        $lnk.Description = "Elden Ring VR motion controls ($suffix, offline only)"
        $lnk.Save()
    }
} catch { Write-Warn "Could not create the desktop shortcut." }

Write-ModStamp -GameDir $gameDir -Version $MOD_VERSION
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- What now ------------------------------------------------
Write-Host ""
Write-Host "  BEFORE YOU LAUNCH " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "   - Disable Easy Anti-Cheat and play OFFLINE." -ForegroundColor White
Write-Host "   - Set your headset's OpenXR runtime as the active one:" -ForegroundColor White
Write-Host "     Oculus for Link and Air Link, VDXR for Virtual Desktop," -ForegroundColor Gray
Write-Host "     or SteamVR." -ForegroundColor Gray
Write-Host ""
Write-Host "  If it does not work, read " -NoNewline -ForegroundColor White
Write-Host "Game\ERVR\ERVR.log" -ForegroundColor Cyan
Write-Host "  It should contain '[reshade] registered as add-on' and" -ForegroundColor Gray
Write-Host "  'Active VR backend: openxr'. If the [reshade] lines never" -ForegroundColor Gray
Write-Host "  appear, the dxgi.dll in your Game folder is not the bundled one." -ForegroundColor Gray
Write-Host ""
Write-Host "  Every combat threshold is in Game\ERVR\ERVR.ini and reloads" -ForegroundColor Gray
Write-Host "  about a second after you save it - tune it while playing." -ForegroundColor Gray
Write-Host "  The Hub detail page also has ERVR Full 3D and ERVR config." -ForegroundColor Cyan
Write-Host ""
Write-OK "$MOD_NAME $MOD_VERSION installed."

# The one thing that can cost the reader their account, last and alone,
# with nothing scrolling past it.
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Red
Write-Host "  READ THIS BEFORE YOU PLAY " -NoNewline -ForegroundColor Black -BackgroundColor Red
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Red
Write-Host ""
Write-Host "  OFFLINE ONLY. EASY ANTI-CHEAT MUST BE OFF." -ForegroundColor Yellow
Write-Host ""
Write-Host "  ERVR injects into eldenring.exe and writes game memory." -ForegroundColor White
Write-Host "  Running it online risks a PERMANENT BAN on your account -" -ForegroundColor White
Write-Host "  the author's own words. Multiplayer is not supported and" -ForegroundColor White
Write-Host "  never will be." -ForegroundColor White
Write-Host ""
Write-Host "  Launch through the VR launcher, never Steam's Play button." -ForegroundColor Gray
Write-Host ""
Pause-User "Read the above, then press Enter to exit"
