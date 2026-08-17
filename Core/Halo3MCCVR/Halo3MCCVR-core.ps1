# ============================================================
# Halo 3 MCC VR Installer (Halo MCC VR, by pancreations)
# ============================================================
# A native OpenXR VR mod for Halo: The Master Chief Collection on
# Steam. Halo 3 campaign is the tested path in this alpha.
#
# From alpha 0.1.1 the mod ships NO install.bat - the package is just
# three files (halo3xr.dll, halo3xr_launcher.exe, halomccvr.cfg) plus
# readmes, meant to
# be copied by hand into a "Halo_MCC_VR" folder inside the MCC install.
# So the Hub does that copy itself:
#   1. Resolves the newest release from GitHub (prerelease-aware).
#   2. Downloads and unpacks HaloMCCVR-alpha-<ver>.zip.
#   3. Finds the MCC game folder (Steam library / Xbox / MS Store,
#      with a manual drag & drop fallback).
#   4. Creates <MCC>\Halo_MCC_VR and copies the mod files in,
#      then makes a "Halo MCC VR" desktop shortcut to the launcher.
#      No game files are modified; removing the folder removes the mod.
#
# The launcher starts MCC through its official anti-cheat-DISABLED
# mode. It must never be used in anti-cheat-enabled matchmaking.
#
# Auto-update: the Hub tracks GithubPrerelease releases of
# pancreations/Halo-MCC-VR and flags the tile when a newer alpha
# ships; re-running this installer refreshes the two files in place.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Halo 3 MCC VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Halo 3 MCC VR Installer" -ForegroundColor Cyan
    Write-Host " Halo MCC VR (alpha) by pancreations | Steam MCC + Halo 3" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$REPO              = "pancreations/Halo-MCC-VR"
$REPO_API_RELEASES = "https://api.github.com/repos/$REPO/releases?per_page=5"
$RELEASES_PAGE     = "https://github.com/$REPO/releases"
$INFO_URL          = "https://github.com/$REPO"
# Last-known-good asset, used only if the GitHub API cannot be reached.
$KNOWN_FALLBACK_ZIP = "https://github.com/pancreations/Halo-MCC-VR/releases/download/MCC_VR_ALPHA_0.3.0/MCC_VR_ALPHA_0.3.0.zip"
$KNOWN_FALLBACK_TAG = "MCC_VR_ALPHA_0.3.0"

$MCC_STEAM_FOLDER  = "Halo The Master Chief Collection"
$MCC_APPID         = "976730"
# The Microsoft Store / Game Pass build ships the SAME executable under a
# different name: MCCWinStore-Win64-Shipping.exe instead of
# MCC-Win64-Shipping.exe (renamed by 343 in the Season 6 update). Detection
# has to accept either, or Game Pass owners cannot even get past this step -
# not via auto-detect and not via drag & drop.
$MCC_BIN_DIR       = "MCC\Binaries\Win64"
$MCC_EXE_STEAM     = "MCC-Win64-Shipping.exe"
$MCC_EXE_WINSTORE  = "MCCWinStore-Win64-Shipping.exe"
$MCC_PROBE_EXE     = "$MCC_BIN_DIR\$MCC_EXE_STEAM"
$MOD_FOLDER_NAME   = "Halo_MCC_VR"
$MOD_DLL           = "halo3xr.dll"
$MOD_LAUNCHER      = "halo3xr_launcher.exe"
# 0.3.0 SHIPS halomccvr.cfg and it MUST replace an older one: the new build
# adds settings older files do not have, and anything missing silently falls
# back to a built-in default instead of the shipped value. The visible
# casualty is fit_desktop_window (built-in default OFF, shipped ON), which
# caps the headset frame rate. The user's old file is backed up, not lost.
$MOD_CFG           = "halomccvr.cfg"

# Resolve the newest release ZIP asset (prerelease included) via the
# GitHub API. Returns @{ Url; Tag } or $null on any failure.
function Get-LatestHaloRelease {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri $REPO_API_RELEASES -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        $rel = $rels | Select-Object -First 1
        if ($rel) {
            # Asset naming has changed across releases: older ones are
            # "HaloMCCVR-alpha-<ver>.zip", 0.2.1+ are "MCC_VR_ALPHA_<ver>.zip".
            # GitHub's assets list never includes the auto-generated source
            # zips, so match any .zip, preferring a mod-looking name, then
            # fall back to the first zip - future-proof against renames.
            $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
            $asset = $zips | Where-Object { $_.name -match '(?i)(HaloMCCVR|MCC.?VR)' } | Select-Object -First 1
            if (-not $asset) { $asset = $zips | Select-Object -First 1 }
            if ($asset -and $asset.browser_download_url) {
                return @{ Url = [string]$asset.browser_download_url; Tag = [string]$rel.tag_name }
            }
        }
    } catch { }
    return $null
}

# Does this folder look like a real MCC install?
function Test-MCCRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        $bin = Join-Path $Root $MCC_BIN_DIR
        if (Test-Path -LiteralPath (Join-Path $bin $MCC_EXE_STEAM))    { return $true }
        if (Test-Path -LiteralPath (Join-Path $bin $MCC_EXE_WINSTORE)) { return $true }
        return $false
    } catch { return $false }
}

Write-Header

Write-Host "  Halo MCC VR turns Halo: The Master Chief Collection into a" -ForegroundColor Gray
Write-Host "  native OpenXR VR experience: true per-eye stereo, 6DOF head" -ForegroundColor Gray
Write-Host "  tracking, motion-controller input, and articulated VR arms." -ForegroundColor Gray
Write-Host ""
Write-Host "  THIS IS AN EARLY ALPHA. Halo 3 campaign is the tested path;" -ForegroundColor Yellow
Write-Host "  other modes are not all validated. The code is AI-written," -ForegroundColor Gray
Write-Host "  public, unaudited, MIT-licensed." -ForegroundColor Gray
Write-Host ""
Write-Host "  Halo 3, ODST and Reach must ALL be installed in MCC - with any of" -ForegroundColor Yellow
Write-Host "  them missing the 3D hook does not engage." -ForegroundColor Yellow
Write-Host "  Needs the STEAM version of MCC with Halo 3 and SteamVR set as" -ForegroundColor Gray
Write-Host "  your default OpenXR runtime. Launch MCC in flat once first to" -ForegroundColor Gray
Write-Host "  sign in to your Microsoft account." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: resolve + download the release
# -------------------------------------------------------
Write-Step 1 4 "Fetching the latest Halo MCC VR release"
Write-Info "Resolving the newest release via the GitHub API (prerelease-aware)..."

$rel = Get-LatestHaloRelease
$zipUrl = $null
$relTag = $null
if ($rel) {
    $zipUrl = $rel.Url
    $relTag = $rel.Tag
    Write-OK "Latest release: $relTag"
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known URL."
    $zipUrl = $KNOWN_FALLBACK_ZIP
    $relTag = $KNOWN_FALLBACK_TAG
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("HaloMCCVR_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zipPath = Join-Path $tmp "HaloMCCVR.zip"

$dl = Invoke-DownloadOrFallback -Url $zipUrl -Destination $zipPath `
        -Label "Halo MCC VR ($relTag)" `
        -ManualUrl $RELEASES_PAGE `
        -Instructions "Download the mod .zip asset from the latest release on the releases page, save it as '$zipPath', then choose Retry." `
        -SkipMessage "Skipped - the mod was not downloaded, so nothing can be installed."
if ([string]$dl -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($dl -is [bool] -and $dl)) {
    Write-Fail "No mod archive available - cannot continue."
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..."; exit 1
}
Write-OK "Downloaded: $zipPath"

# -------------------------------------------------------
# STEP 2: unpack + locate the two mod files
# -------------------------------------------------------
Write-Step 2 4 "Unpacking"
$extract = Join-Path $tmp "extract"
New-Item -ItemType Directory -Path $extract -Force | Out-Null
$efb = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $extract `
        -Label "Halo MCC VR archive" `
        -SkipMessage "Skipped - the archive was not unpacked, so the installer cannot continue."
if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }

# The ZIP wraps the files in a HaloMCCVR-alpha-<ver>\ folder. Find the
# dll and launcher wherever they sit inside the extracted tree.
$dllSrc = Get-ChildItem -LiteralPath $extract -Recurse -Filter $MOD_DLL -File -ErrorAction SilentlyContinue | Select-Object -First 1
$lncSrc = Get-ChildItem -LiteralPath $extract -Recurse -Filter $MOD_LAUNCHER -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dllSrc -or -not $lncSrc) {
    Write-Fail "The mod files ($MOD_DLL / $MOD_LAUNCHER) were not found inside the archive."
    Write-Info "The release layout may have changed. Get it manually from:"
    Write-Info "  $RELEASES_PAGE"
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..."; exit 1
}
$modSrcDir = Split-Path -Parent $dllSrc.FullName
Write-OK "Mod files ready."

# -------------------------------------------------------
# STEP 3: locate the MCC game folder
# -------------------------------------------------------
Write-Step 3 4 "Locating Halo: The Master Chief Collection"

$mccPath = $null
# Steam (registry + libraryfolders + appmanifest), via the shared helper.
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
    $mccPath = Find-SteamGameFolder -AppId $MCC_APPID -SteamFolderNames @($MCC_STEAM_FOLDER) -ProbeExe $MCC_PROBE_EXE
}
# Xbox app / Microsoft Store install locations (helper is Steam-only).
if (-not (Test-MCCRoot $mccPath)) {
    $xboxCands = @()
    foreach ($d in @("C:","D:","E:","F:")) {
        $xboxCands += "$d\XboxGames\Halo- The Master Chief Collection\Content"
    }
    $xboxCands += "C:\Program Files\ModifiableWindowsApps\Halo- TheMasterChiefCollection"
    foreach ($c in $xboxCands) { if (Test-MCCRoot $c) { $mccPath = $c; break } }
}
# A location recorded by a previous install.
if (-not (Test-MCCRoot $mccPath)) {
    try {
        $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1
        if ($rec) { $rec = $rec.Trim(); if (Test-MCCRoot $rec) { $mccPath = $rec } }
    } catch {}
}
# Manual fallback: drag & drop the MCC folder onto the window.
while (-not (Test-MCCRoot $mccPath)) {
    Write-Warn "Could not find MCC automatically."
    Write-Host "  Drag & drop your MCC GAME FOLDER onto this window (the one" -ForegroundColor White
    Write-Host "  containing the 'MCC' folder), then press Enter." -ForegroundColor White
    Write-Host "  Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host "  MCC folder").Trim().Trim('"')
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }
    if (Test-MCCRoot $raw) { $mccPath = $raw }
    else { Write-Fail "That folder does not contain $MCC_BIN_DIR\$MCC_EXE_STEAM (or $MCC_EXE_WINSTORE)." }
}
Write-OK "Found MCC: $mccPath"

# --- Microsoft Store / Game Pass: provide the expected executable name ---
# The mod's launcher looks for MCC-Win64-Shipping.exe. The Store build only
# has MCCWinStore-Win64-Shipping.exe, so without this the launcher finds
# nothing. We COPY rather than rename on purpose: the original file stays
# exactly where the Xbox app expects it, so its integrity check does not
# flag a missing file and trigger a repair download, and the game still
# launches normally outside VR. The copy is just a second name for the same
# bytes - it costs disk space, nothing else.
$mccBinDir   = Join-Path $mccPath $MCC_BIN_DIR
$exeSteam    = Join-Path $mccBinDir $MCC_EXE_STEAM
$exeWinStore = Join-Path $mccBinDir $MCC_EXE_WINSTORE
if ((-not (Test-Path -LiteralPath $exeSteam)) -and (Test-Path -LiteralPath $exeWinStore)) {
    Write-Info "Microsoft Store / Game Pass build detected."
    Write-Info "The mod expects '$MCC_EXE_STEAM' - creating a copy under that name."
    Write-Info "The original '$MCC_EXE_WINSTORE' is kept untouched."
    $copied = $false
    try {
        Copy-Item -LiteralPath $exeWinStore -Destination $exeSteam -Force -ErrorAction Stop
        $copied = $true
    } catch {
        # XboxGames / ModifiableWindowsApps folders are usually not writable
        # for a normal user: retry the copy elevated (same pattern as the
        # Mass Effect installer).
        Write-Warn "Need Administrator rights to write into the game folder - a prompt will appear."
        $cmd = "Copy-Item -LiteralPath '$exeWinStore' -Destination '$exeSteam' -Force"
        try { Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile","-Command",$cmd } catch {}
        if (Test-Path -LiteralPath $exeSteam) { $copied = $true }
    }
    if ($copied) {
        Write-OK "Created $MCC_EXE_STEAM (copy of the Store executable)."
    } else {
        # Not fatal: the mod files still get installed. Tell the user exactly
        # what to do by hand instead of aborting the whole setup.
        Write-Warn "Could not create the copy automatically."
        Write-Host ""
        Write-Host "  +======================================================+" -ForegroundColor Yellow
        Write-Host "  |            ONE MANUAL STEP NEEDED                    |" -ForegroundColor Yellow
        Write-Host "  +======================================================+" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Open this folder:" -ForegroundColor White
        Write-Host "    $mccBinDir" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  COPY (do not rename) this file:" -ForegroundColor White
        Write-Host "    $MCC_EXE_WINSTORE" -ForegroundColor Cyan
        Write-Host "  and name the copy:" -ForegroundColor White
        Write-Host "    $MCC_EXE_STEAM" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Keeping the original means the Xbox app will not try to" -ForegroundColor Gray
        Write-Host "  repair the installation." -ForegroundColor Gray
        Write-Host ""
        Pause-User "Press Enter to continue the installation..."
    }
}

# -------------------------------------------------------
# STEP 4: install the mod files into <MCC>\Halo_MCC_VR
# -------------------------------------------------------
Write-Step 4 4 "Installing the mod"

# MCC must be closed or the launcher/dll copy is locked.
$mccProc = Get-Process -Name "MCC-Win64-Shipping","MCCWinStore-Win64-Shipping" -ErrorAction SilentlyContinue
if ($mccProc) {
    Write-Warn "Halo MCC is running - close it completely, then press Enter."
    Pause-User "Press Enter once MCC is closed..."
}

$modDir = Join-Path $mccPath $MOD_FOLDER_NAME

# If an old 0.1.0-style "halo3xr" folder exists, leave it alone but note
# it: the new build uses Halo_MCC_VR and never merges the two.
$oldDir = Join-Path $mccPath "halo3xr"
if ((Test-Path -LiteralPath $oldDir) -and -not (Test-Path -LiteralPath $modDir)) {
    Write-Info "An older 'halo3xr' folder is present; installing the new build"
    Write-Info "into '$MOD_FOLDER_NAME' separately (your old one is left untouched)."
}

$isUpgrade = (Test-Path -LiteralPath (Join-Path $modDir $MOD_LAUNCHER))
try {
    if (-not (Test-Path -LiteralPath $modDir)) { New-Item -ItemType Directory -Path $modDir -Force -ErrorAction Stop | Out-Null }

    # The author's release notes say to remove the old files before adding the
    # new ones. Overwriting would usually do, but a stale file that is no
    # longer shipped would survive - so the known ones go first. The user's
    # own config is copied aside beforehand, never just deleted.
    if ($isUpgrade) {
        $cfgOld = Join-Path $modDir $MOD_CFG
        if (Test-Path -LiteralPath $cfgOld) {
            $cfgBak = Join-Path $modDir ($MOD_CFG + ".previous")
            try {
                Copy-Item -LiteralPath $cfgOld -Destination $cfgBak -Force -ErrorAction Stop
                Write-Info "Your old config was kept as $MOD_CFG.previous"
            } catch {}
        }
        foreach ($stale in @($MOD_DLL, $MOD_LAUNCHER, $MOD_CFG, "MANUAL-README.txt", "ALPHA-README.txt", "BUILD-INFO.txt")) {
            $sp = Join-Path $modDir $stale
            if (Test-Path -LiteralPath $sp) { try { Remove-Item -LiteralPath $sp -Force -ErrorAction Stop } catch {} }
        }
    }

    Copy-Item -LiteralPath $dllSrc.FullName -Destination (Join-Path $modDir $MOD_DLL) -Force -ErrorAction Stop
    Copy-Item -LiteralPath $lncSrc.FullName -Destination (Join-Path $modDir $MOD_LAUNCHER) -Force -ErrorAction Stop

    # The shipped config MUST land, replacing any older one.
    $cfgSrc = Get-ChildItem -LiteralPath $modSrcDir -Filter $MOD_CFG -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cfgSrc) {
        Copy-Item -LiteralPath $cfgSrc.FullName -Destination (Join-Path $modDir $MOD_CFG) -Force -ErrorAction Stop
        Write-OK "Installed the shipped $MOD_CFG (tuned by the author)."
    } else {
        Write-Warn "$MOD_CFG was not in the package - the mod will fall back to built-in defaults."
    }

    # Carry the readmes across too, so the notes sit next to the mod.
    foreach ($doc in @("MANUAL-README.txt","ALPHA-README.txt","BUILD-INFO.txt")) {
        $ds = Join-Path $modSrcDir $doc
        if (Test-Path -LiteralPath $ds) { Copy-Item -LiteralPath $ds -Destination (Join-Path $modDir $doc) -Force -ErrorAction SilentlyContinue }
    }
    if ($isUpgrade) { Write-OK "Updated the mod files in $modDir" }
    else { Write-OK "Installed the mod into $modDir" }
} catch {
    Write-Fail "Could not copy the mod files: $($_.Exception.Message)"
    Write-Info "Make sure MCC is closed and try again."
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}

# Desktop shortcut to the mod launcher (anti-cheat-off VR route).
try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Halo MCC VR.lnk"))
    $lnk.TargetPath = Join-Path $modDir $MOD_LAUNCHER
    $lnk.WorkingDirectory = $modDir
    # Use whichever MCC executable actually exists - on a Store install
    # where the copy above could not be made, only the WinStore name is
    # there, and a dead icon path would leave the shortcut blank.
    $iconSrc = if (Test-Path -LiteralPath $exeSteam) { $exeSteam }
               elseif (Test-Path -LiteralPath $exeWinStore) { $exeWinStore }
               else { Join-Path $modDir $MOD_LAUNCHER }
    $lnk.IconLocation = "$iconSrc,0"
    $lnk.Description = "Halo MCC with the VR mod (anti-cheat off)"
    $lnk.Save()
    Write-OK "Desktop shortcut 'Halo MCC VR' created."
} catch {
    Write-Warn "Could not create the desktop shortcut - you can still launch from the Hub."
}

# -------------------------------------------------------
# Record the install so the Hub can detect + flag updates
# -------------------------------------------------------
# ModFile = Halo_MCC_VR\halo3xr.dll, verified inside this recorded path,
# so a fresh Hub with no marker still confirms the real file on disk.
try {
    if ($relTag) { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force }
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $mccPath -Encoding UTF8 -Force
} catch {}

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# Done - important play notes
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |             SET THESE OUTSIDE THE GAME               |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Default OpenXR runtime  " -NoNewline -ForegroundColor White; Write-Host " SteamVR " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   SteamVR branch          " -NoNewline -ForegroundColor White; Write-Host " Beta " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Steam Input (gamepad)   " -NoNewline -ForegroundColor White; Write-Host " OFF " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The mod requires SteamVR as the default OpenXR runtime AND its" -ForegroundColor Gray
Write-Host "  Beta branch (Steam library > SteamVR > Properties > Betas >" -ForegroundColor Gray
Write-Host "  beta). If the mod does not hook, check both first." -ForegroundColor Gray
Write-Host ""
Write-Host "  With Steam Input left on, shots can land away from your aim." -ForegroundColor Gray
Write-Host "  In the Steam library: right-click MCC > Properties > Controller," -ForegroundColor Gray
Write-Host "  set the dropdown to 'Disable Steam Input' (older Steam builds" -ForegroundColor Gray
Write-Host "  call it 'Steam Input Per-Game Setting' > 'Force Off')." -ForegroundColor Gray
Write-Host ""
Write-Host "  Still hitting nothing? In MCC: Settings > Controls > gamepad" -ForegroundColor Gray
Write-Host "  layout - if a weapon/aim option shows INVERTED, un-invert it." -ForegroundColor Gray
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |              IMPORTANT IN-GAME SETTINGS              |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Set these in MCC's OWN menus before playing. Without them" -ForegroundColor White
Write-Host "  the mod is nearly unplayable:" -ForegroundColor White
Write-Host ""
# Der Autor verlangt seit Alpha 0.3.3 UNLIMITED, nicht mehr 120.
Write-Host "   Settings > Video > Max Frame Rate " -NoNewline -ForegroundColor White; Write-Host " Unlimited " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Settings > Video > V-Sync         " -NoNewline -ForegroundColor White; Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Halo 3  > Settings > Field of View" -NoNewline -ForegroundColor White; Write-Host " 120 " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   ODST    > Look Sensitivity        " -NoNewline -ForegroundColor White; Write-Host " Maximum " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   ODST    > Look Acceleration       " -NoNewline -ForegroundColor White; Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Do NOT enable FSR in MCC          " -NoNewline -ForegroundColor White; Write-Host " use mod's picture setting " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'Halo MCC VR'" -ForegroundColor Gray
Write-Host "    desktop shortcut (only that route loads the mod, anti-cheat" -ForegroundColor Gray
Write-Host "    OFF). Press F1 in game for settings incl. picture quality." -ForegroundColor Gray
Write-Host ""
Write-Host "  NEVER use this in anti-cheat-enabled matchmaking." -NoNewline -ForegroundColor White; Write-Host " " -NoNewline; Write-Host " AC OFF ONLY " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Controls and tips are on this game's page in the Hub." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Finish the fight - now from inside the visor." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
