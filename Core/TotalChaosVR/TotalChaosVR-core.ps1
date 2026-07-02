# ============================================================
# Total Chaos VR Installer (GZDoom TC -> gzdoomvr / hh79)
# ============================================================
# Total Chaos is a survival-horror total conversion for Doom II
# (Sam Prebble / wadaholic). It is freeware and distributed as a
# "standalone" package on ModDB that already bundles a normal
# (non-VR) GZDoom 3.6.0 under .\gamedata\ together with all of its
# own content (totalchaos.pk3, doom.wad, zd_extra.pk3, ...).
#
# To play it with motion controls we run a matching VR engine:
# this installer downloads "gzdoomvr" (hh79's OpenVR fork of
# GZDoom, GPLv3) into its own .\gzdoomvr\ folder and points it at
# Total Chaos's content with -iwad / -file. The bundled gamedata
# is left untouched. Because Total Chaos bundles GZDoom 3.6.0, the
# installer picks the matching gzdoomvr 3.6.x build.
#
# Nothing game-related is bundled in the Hub:
#   * the user drag-drops the ModDB "Total Chaos Standalone" ZIP
#   * gzdoomvr is downloaded at install time from GitHub
#
# Install layout (under C:\Games\Total Chaos VR by default):
#   <gameRoot>\gamedata\...              (from the ModDB ZIP)
#   <gameRoot>\gzdoomvr\<gzdoom exe>     (downloaded VR engine)
#   <gameRoot>\Play Total Chaos VR.bat
# Requires SteamVR / Virtual Desktop (OpenVR) running before launch.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Total Chaos VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Total Chaos VR Installer" -ForegroundColor Cyan
    Write-Host " GZDoom total conversion (wadaholic) + gzdoomvr by hh79" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Path
$GAME_FOLDER   = "Total Chaos VR"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")

# gzdoomvr (hh79) - OpenVR fork of GZDoom. Total Chaos 1.0 bundles
# GZDoom 3.6.0, so we resolve the matching gzdoomvr 3.6.x build via
# the GitHub API and fall back to the releases page if needed.
$GZVR_API_LIST     = "https://api.github.com/repos/hh79/gzdoomvr/releases?per_page=100"
$GZVR_RELEASES     = "https://github.com/hh79/gzdoomvr/releases"
# ModDB standalone (manual download - 1.42 GB, freeware).
$TC_MODDB          = "https://www.moddb.com/mods/total-chaos/downloads/total-chaos-10"

# Resolve the gzdoomvr*.zip asset that matches Total Chaos's bundled
# GZDoom 3.6.0 (a 3.6.x build). Returns a browser_download_url or $null.
function Get-MatchingGzdoomvrZipUrl {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri $GZVR_API_LIST -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($r in $rels) {
            if ($r.tag_name -notmatch '(?i)3\.6') { continue }
            $asset = $r.assets | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1
            if ($asset -and $asset.browser_download_url) { return [string]$asset.browser_download_url }
        }
    } catch { }
    return $null
}

function Test-WritableRoot {
    param([string]$Root)
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

Write-Header
Write-Host "  Installs Total Chaos (free GZDoom TC) with motion controls via gzdoomvr." -ForegroundColor Gray
Write-Host ""

# ---- 1. get the (free) Total Chaos Standalone download ------
Write-Step 1 5 "Get the Total Chaos Standalone download"
Write-Host "  Total Chaos is a free download from ModDB, so it can't be fetched automatically." -ForegroundColor White
Write-Host "  Pressing Enter opens the download page:" -ForegroundColor Yellow
Write-Host "      ( $TC_MODDB )" -ForegroundColor Gray
Write-Host ""
Write-Host "  1) Click the red DOWNLOAD NOW button (1.42 GB)." -ForegroundColor White
Write-Host "  2) Come back here and drag the ZIP onto this window." -ForegroundColor White
Pause-User "Press Enter to open the Total Chaos download page..."
try { Start-Process $TC_MODDB | Out-Null } catch { Write-Warn "Open manually: $TC_MODDB" }

$tcZip = $null
while (-not $tcZip) {
    Write-Host ""
    Write-Host " >>> Drag the Total Chaos ZIP here, then press Enter " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "     (the ModDB file: totalchaos_standalone_1000b.zip)" -ForegroundColor DarkGray
    Write-Host "     (or just press Enter to reopen the download page)" -ForegroundColor DarkGray
    $drop = (Read-Host "  File").Trim().Trim('"').Trim("'").Trim()
    if (-not $drop) {
        try { Start-Process $TC_MODDB | Out-Null } catch { Write-Host "    $TC_MODDB" -ForegroundColor Cyan }
        continue
    }
    if (-not (Test-Path -LiteralPath $drop)) { Write-Warn "File not found: $drop"; continue }
    if ((Get-Item -LiteralPath $drop).PSIsContainer) { Write-Warn "That is a folder - drag the .zip file itself."; continue }
    if ($drop -notmatch '(?i)\.zip$') {
        Write-Warn "That does not look like a .zip ($drop)."
        $yn = (Read-Host "  Use it anyway? (y/N)").Trim().ToLower()
        if ($yn -ne "y") { continue }
    }
    $tcZip = [string]$drop
}
Write-OK "Total Chaos ZIP: $tcZip"

# ---- 2. install location ------------------------------------
Write-Step 2 5 "Choose install location"
Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  Press Enter to accept it, or type a different folder to install into." -ForegroundColor Gray
Write-Host "  (Recommended. C:\Games keeps it away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break } }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER

if (Test-Path (Join-Path $gameRoot "gamedata")) {
    Write-Warn "An existing Total Chaos VR install was found at: $gameRoot"
    Write-Host "  Press Enter to reinstall (the folder will be rebuilt)," -ForegroundColor Gray
    Write-Host "  or close this window to abort." -ForegroundColor Gray
    Pause-User "Press Enter to reinstall..."
}

$tmp = Join-Path $installRoot "_totalchaos_vr_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..."
    exit 1
}

# ---- 3. extract the Total Chaos standalone into the game folder
Write-Step 3 5 "Extracting Total Chaos"
$tcUnpack = Join-Path $tmp "tc_unpack"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $tcUnpack) { Remove-Item $tcUnpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tcUnpack -Force -ErrorAction Stop | Out-Null
        Write-Info "Unpacking (this can take a while - it is a 1.4 GB archive)..."
        $r = Expand-ArchiveOrFallback -ArchivePath $tcZip -DestinationFolder $tcUnpack -Label "Total Chaos Standalone" -AllowSkip $false
        if ([string]$r -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the Total Chaos ZIP: $_"
        $alt = (Read-Host "  Paste a fresh ZIP path (or Enter to retry same)").Trim().Trim('"')
        if ($alt -and (Test-Path -LiteralPath $alt)) { $tcZip = [string]$alt }
    }
}

# Locate the standalone root by finding the main content pk3 inside
# .\gamedata\, then treat gamedata's parent as the package root to flatten.
$marker = Get-ChildItem -Path $tcUnpack -Filter "totalchaos.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $marker) {
    Write-Fail "Could not find the Total Chaos content (gamedata\totalchaos.pk3) in the ZIP."
    $fb = Invoke-InstallerFallback -Action "find the Total Chaos content in the ZIP" `
        -Subject "the Total Chaos standalone ZIP" `
        -Url $TC_MODDB `
        -Instructions "The ZIP did not contain the expected gamedata\totalchaos.pk3 - it may be the wrong download. Grab 'Total Chaos - Standalone (1.00.0)' from ModDB, then paste its path and choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    $alt = (Read-Host "  Fresh ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path -LiteralPath $alt)) {
        try {
            Remove-Item $tcUnpack -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Path $tcUnpack -Force -ErrorAction Stop | Out-Null
            Expand-ArchiveOrFallback -ArchivePath $alt -DestinationFolder $tcUnpack -Label "Total Chaos Standalone" -AllowSkip $false | Out-Null
        } catch { }
    }
    $marker = Get-ChildItem -Path $tcUnpack -Filter "totalchaos.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
# marker is inside <pkgRoot>\gamedata\ ; pkgRoot = gamedata's parent.
$gamedataDir = $marker.Directory
$pkgRoot     = $gamedataDir.Parent.FullName

# Rebuild the game folder from the package root.
$placedOk = $false
while (-not $placedOk) {
    try {
        if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
        New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
        Get-ChildItem -Path $pkgRoot -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
        }
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the Total Chaos files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the Total Chaos files into place" `
            -Instructions "Copy the CONTENTS of '$pkgRoot' into '$gameRoot' (so a 'gamedata' folder sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$pkgRoot" -DestFolder "$gameRoot" -AllowSkip $true
        if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
        if ([string]$fb -eq "skip") { break }
    }
}
$gameData = Join-Path $gameRoot "gamedata"
$tcIwad   = Join-Path $gameData "doom.wad"
if (-not (Test-Path $tcIwad)) {
    Write-Warn "doom.wad was not found at the expected path."
    Write-Host "  Expected: $tcIwad" -ForegroundColor DarkGray
    Write-Host "  The launcher may need the IWAD path corrected if the package layout differs." -ForegroundColor Gray
}
Write-OK "Total Chaos installed at: $gameRoot"

# ---- 4. download + place the gzdoomvr VR engine -------------
Write-Step 4 5 "Downloading the VR engine (gzdoomvr)"
$gzZip = Join-Path $tmp "gzdoomvr.zip"
$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the gzdoomvr build that matches Total Chaos (GZDoom 3.6) ..."
$apiUrl = Get-MatchingGzdoomvrZipUrl
if ($apiUrl) { Write-OK "gzdoomvr asset: $apiUrl"; [void]$urls.Add($apiUrl) }
else { Write-Warn "GitHub API not reachable (rate limit / offline)." }

Invoke-SafeDownload -Urls $urls -Destination $gzZip `
    -Label "gzdoomvr (VR engine)" `
    -ManualUrl $GZVR_RELEASES `
    -Instructions "Open the releases page, download the gzdoomvr 3.6 build (tag gvr3.6.0.2), save it as '$gzZip', then choose Retry." `
    -SkipMessage "" | Out-Null

while (-not (Test-Path $gzZip)) {
    Write-Fail "The gzdoomvr download is not present at: $gzZip"
    $fb = Invoke-InstallerFallback -Action "download gzdoomvr" `
        -Subject "the gzdoomvr VR engine" -Url $GZVR_RELEASES `
        -Instructions "Download the gzdoomvr 3.6 build (tag gvr3.6.0.2) from the releases page, save it as '$gzZip', then choose Retry. You can also paste the path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    $alt = (Read-Host "  ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path -LiteralPath $alt) -and ($alt -match '(?i)\.zip$')) { $gzZip = [string]$alt }
}

$gzUnpack = Join-Path $tmp "gzdoomvr_unpack"
$gzExtractOk = $false
while (-not $gzExtractOk) {
    try {
        if (Test-Path $gzUnpack) { Remove-Item $gzUnpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $gzUnpack -Force -ErrorAction Stop | Out-Null
        $r = Expand-ArchiveOrFallback -ArchivePath $gzZip -DestinationFolder $gzUnpack -Label "gzdoomvr" -AllowSkip $false
        if ([string]$r -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
        $gzExtractOk = $true
    } catch {
        Write-Fail "Could not extract gzdoomvr: $_"
        $alt = (Read-Host "  Paste a fresh gzdoomvr ZIP path (or Enter to retry)").Trim().Trim('"')
        if ($alt -and (Test-Path -LiteralPath $alt)) { $gzZip = [string]$alt }
    }
}

# Find the VR gzdoom executable. Its folder is the engine payload root,
# which becomes <gameRoot>\gzdoomvr (kept separate from Total Chaos's
# own gamedata so the VR engine uses its OWN matching gzdoom.pk3).
$gzExe = Get-ChildItem -Path $gzUnpack -Filter "gzdoom*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $gzExe) {
    $gzExe = Get-ChildItem -Path $gzUnpack -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '(?i)unins|setup|vcredist|crash' } | Select-Object -First 1
}
while (-not $gzExe) {
    Write-Fail "No gzdoom executable found in the gzdoomvr download."
    $fb = Invoke-InstallerFallback -Action "find the gzdoomvr executable" `
        -Subject "the gzdoomvr ZIP" -Url $GZVR_RELEASES `
        -Instructions "The ZIP did not contain a gzdoom*.exe. Re-download the gzdoomvr 3.6 build, save it as '$gzZip', then choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    $alt = (Read-Host "  Fresh gzdoomvr ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path -LiteralPath $alt)) {
        try {
            Remove-Item $gzUnpack -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Path $gzUnpack -Force -ErrorAction Stop | Out-Null
            Expand-ArchiveOrFallback -ArchivePath $alt -DestinationFolder $gzUnpack -Label "gzdoomvr" -AllowSkip $false | Out-Null
        } catch { }
    }
    $gzExe = Get-ChildItem -Path $gzUnpack -Filter "gzdoom*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$gzSrcDir  = Split-Path -Parent $gzExe.FullName
$gzExeName = $gzExe.Name
$gzDestDir = Join-Path $gameRoot "gzdoomvr"
try {
    if (Test-Path $gzDestDir) { Remove-Item $gzDestDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $gzDestDir -Force -ErrorAction Stop | Out-Null
    Get-ChildItem -Path $gzSrcDir -Force | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $gzDestDir -Force -ErrorAction Stop
    }
} catch {
    Write-Fail "Could not place the gzdoomvr files: $_"
    Invoke-InstallerFallback -Action "copy the gzdoomvr files into place" `
        -Instructions "Copy the CONTENTS of '$gzSrcDir' into '$gzDestDir' (so $gzExeName sits at its root). Then choose Retry, or Skip." `
        -SourceFolder "$gzSrcDir" -DestFolder "$gzDestDir" -AllowSkip $true | Out-Null
}
Write-OK "VR engine ready: gzdoomvr\$gzExeName"

# ---- 5. write the VR launcher + desktop shortcut ------------
Write-Step 5 5 "Creating the VR launcher and shortcut"

$batPlay = Join-Path $gameRoot "Play Total Chaos VR.bat"
$exeRel  = ".\gzdoomvr\$gzExeName"
$batBody = @"
@echo off
cd /d "%~dp0"
echo ============================================================
echo  Launching Total Chaos in VR
echo  Make sure SteamVR / Virtual Desktop (OpenVR) is running first!
echo ============================================================
"$exeRel" -iwad ".\gamedata\doom.wad" -file ".\gamedata\totalchaos.pk3" ".\gamedata\zd_extra.pk3" +vr_mode 10
"@
try {
    Set-Content -Path $batPlay -Value $batBody -Encoding ASCII -Force
    Write-OK "VR launcher written: Play Total Chaos VR.bat"
} catch {
    Write-Warn "Could not write the launcher .bat file: $_"
}

# Desktop shortcut (game is not Steam-launched, so it gets its own).
$iconExe = Join-Path $gzDestDir $gzExeName
$tcIco = Join-Path $gameRoot "TotalChaos_VR.ico"
try { Copy-Item -LiteralPath (Join-Path $PSScriptRoot "TotalChaos_VR.ico") -Destination $tcIco -Force } catch {}
$tcIcon = $(if (Test-Path $tcIco) { $tcIco } elseif (Test-Path $iconExe) { $iconExe } else { "" })
if (Test-Path $batPlay) { New-DesktopShortcut -ShortcutName "Total Chaos VR" -TargetPath $batPlay -WorkingDir $gameRoot -IconPath $tcIcon -Description "Total Chaos in VR (gzdoomvr)" }

# Record the install path so the Hub's VR Ready check + Start-in-VR find it.
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Force -ErrorAction Stop } catch {}

# cleanup temp
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Desktop shortcut: Total Chaos VR" -ForegroundColor White
Write-Host ""
Write-Host "  BEFORE launching: start SteamVR (or Virtual Desktop's OpenVR)." -ForegroundColor Yellow
Write-Host "  Aiming uses your tracked hand; firearms have a built-in laser sight." -ForegroundColor Gray
Write-Host "  VR settings (comfort, snap-turn, weapon angle) are in Options -> VR." -ForegroundColor Gray
Write-Host "  Controller bindings: SteamVR -> per-game bindings for gzdoomvr." -ForegroundColor Gray
Write-Host ""
Write-Host "  Fort Oasis kept the lights off for a reason - don't make it personal." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close..."
