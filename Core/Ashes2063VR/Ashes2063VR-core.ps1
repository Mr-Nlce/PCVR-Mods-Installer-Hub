# ============================================================
# Ashes 2063 VR Installer (GZDoom TC -> gzdoomvr / hh79)
# ============================================================
# Ashes 2063 is a post-apocalyptic total conversion for GZDoom
# (Vostyok / ASHES DEV GROUP). It is freeware and distributed as
# a "standalone" package on ModDB that already bundles a normal
# (non-VR) GZDoom plus FreeDoom.
#
# To play it in VR with motion controls we swap the engine: this
# installer downloads "gzdoomvr" (hh79's OpenVR fork of GZDoom,
# GPLv3) and runs the Ashes CONTENT pk3s on top of FreeDoom with
# it. The 2D weapon sprites are aimed via a tracked hand + the
# built-in laser-sight (mmaulwurff), exactly like other 2D-sprite
# VR ports.
#
# Nothing game-related is bundled in the Hub:
#   * the user drag-drops the ModDB "Ashes Standalone" ZIP
#   * gzdoomvr is downloaded at install time from GitHub
#
# Install layout (under C:\Games\Ashes 2063 VR by default):
#   <gameRoot>\Resources\...           (from the ModDB ZIP)
#   <gameRoot>\gzdoomvr\<gzdoom exe>    (downloaded VR engine)
#   <gameRoot>\Play Ashes 2063 VR.bat   (Enriched / Episode 1+DMW)
#   <gameRoot>\Play Afterglow VR.bat
#   <gameRoot>\Play Hard Reset VR.bat
# Requires SteamVR / Virtual Desktop (OpenVR) running before launch.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ashes 2063 VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Ashes 2063 VR Installer" -ForegroundColor Cyan
    Write-Host " GZDoom total conversion (Vostyok) + gzdoomvr by hh79" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }

$SCRIPT_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Path
$GAME_FOLDER   = "Ashes 2063 VR"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")

# gzdoomvr (hh79) - OpenVR fork of GZDoom. Verified asset, plus the
# releases page as a manual fallback. We also try the API for a newer
# release first, so a future update is picked up automatically.
$GZVR_API_LIST     = "https://api.github.com/repos/hh79/gzdoomvr/releases"
$GZVR_RELEASES     = "https://github.com/hh79/gzdoomvr/releases"
$GZVR_KNOWN_ZIP    = "https://github.com/hh79/gzdoomvr/releases/download/gvr4.13.2.2/gzdoomvr-4-13-2-2.zip"
# ModDB standalone (manual download - 665 MB, freeware).
$ASHES_MODDB       = "https://www.moddb.com/mods/ashes-2063/downloads/ashes-stand-alone-version-101"

# Resolve the newest gzdoomvr*.zip asset via the GitHub API. Returns a
# browser_download_url or $null (rate limit / offline / shape change),
# in which case the caller falls back to the known-good URL.
function Get-LatestGzdoomvrZipUrl {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri $GZVR_API_LIST -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($r in $rels) {
            if ($r.prerelease) { continue }
            $asset = $r.assets | Where-Object { $_.name -match '(?i)^gzdoomvr.*\.zip$' } | Select-Object -First 1
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

# Download + extract the optional 3D models addon into <gameRoot>\Resources.
# Returns $true if the addon pk3s were placed. Shared by the full install
# (step 5) and the "3D only" retrofit path.
function Install-Ashes3DAddon {
    param([string]$GameRoot, [string]$ScriptDir)
    Write-Host "  A community addon turns the WORLD objects into 3D models -" -ForegroundColor White
    Write-Host "  ammo, quest items, powerups, props and weapons lying on the" -ForegroundColor Gray
    Write-Host "  ground. The weapon in your hand stays 2D (Ashes 2063 +" -ForegroundColor Gray
    Write-Host "  Afterglow; Hard Reset is not covered)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Download steps (do these now):" -ForegroundColor White
    Write-Host "   1. The ModDB addon page opens in your browser." -ForegroundColor White
    Write-Host "   2. Click the red 'Download Now' button (about 33 MB)." -ForegroundColor White
    Write-Host "   3. Come back here and drag the downloaded ZIP into this window." -ForegroundColor White
    Write-Host ""
    Write-Host "  ModDB addon URL:" -ForegroundColor Cyan
    Write-Host "   -> https://www.moddb.com/mods/ashes-2063/addons/ashes-3d-models-2063-afterglow" -ForegroundColor DarkGray
    Pause-User "Press Enter to open the ModDB addon page in your browser..."
    try { Start-Process "https://www.moddb.com/mods/ashes-2063/addons/ashes-3d-models-2063-afterglow" } catch { Write-Warn "Could not open the browser. Open manually: https://www.moddb.com/mods/ashes-2063/addons/ashes-3d-models-2063-afterglow" }

    $addonZip = $null
    while (-not $addonZip) {
        Write-Host ""
        Write-Host "  Drag the downloaded 3D-models ZIP onto this window and press Enter." -ForegroundColor Yellow
        Write-Host "  (Leave empty and press Enter to skip the addon.)" -ForegroundColor DarkGray
        $rawAd = Read-Host "  3D addon ZIP path"
        if ([string]::IsNullOrWhiteSpace($rawAd)) { Write-Info "Skipped the 3D models addon."; return $false }
        $pa = $rawAd.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $pa)) { Write-Warn "Path not found: $pa"; continue }
        if (Test-Path -LiteralPath $pa -PathType Container) { Write-Warn "That is a folder. Drag the .zip file itself."; continue }
        if ([System.IO.Path]::GetExtension($pa) -ne ".zip") { Write-Warn "That is not a .zip file."; continue }
        $addonZip = $pa
    }

    $adTmp = Join-Path $env:TEMP ("Ashes3D_" + [System.Guid]::NewGuid().ToString("N"))
    try {
        New-Item -ItemType Directory -Path $adTmp -Force -ErrorAction Stop | Out-Null
        Expand-Archive -LiteralPath $addonZip -DestinationPath $adTmp -Force -ErrorAction Stop
        $resDest = Join-Path $GameRoot "Resources"
        if (-not (Test-Path -LiteralPath $resDest)) { New-Item -ItemType Directory -Path $resDest -Force -ErrorAction SilentlyContinue | Out-Null }
        $pk2063 = Get-ChildItem -LiteralPath $adTmp -Filter "Ashes2063-3D.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        $pkGlow = Get-ChildItem -LiteralPath $adTmp -Filter "AshesAfterglow-3D.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $pk2063 -and -not $pkGlow) {
            Write-Warn "Could not find the 3D .pk3 files inside the ZIP - skipping addon."
            return $false
        }
        if ($pk2063) { Copy-Item -LiteralPath $pk2063.FullName -Destination (Join-Path $resDest "Ashes2063-3D.pk3") -Force -ErrorAction Stop }
        if ($pkGlow) { Copy-Item -LiteralPath $pkGlow.FullName -Destination (Join-Path $resDest "AshesAfterglow-3D.pk3") -Force -ErrorAction Stop }
        Write-OK "3D models addon installed (loads on top of Ashes 2063 and Afterglow)."
        try { Set-Content -Path (Join-Path $ScriptDir ".addon3d_installed") -Value "1" -Encoding ASCII -Force } catch {}
        return $true
    } catch {
        Write-Warn "3D addon install failed: $($_.Exception.Message)"
        Write-Host "  You can add it later by placing the .pk3 files in Resources and" -ForegroundColor Yellow
        Write-Host "  re-running this installer." -ForegroundColor Yellow
        return $false
    } finally {
        try { Remove-Item -LiteralPath $adTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}

# Write the three VR launcher .bat files. When $Has3D, the matching 3D
# pk3 is appended AFTER each episode's content pk3 (so models override
# sprites). Needs $ExeName (gzdoomvr exe) resolved by the caller.
function Write-AshesLaunchers {
    param([string]$GameRoot, [string]$ExeName, [bool]$Has3D)
    $mkBat = {
        param($Path, $Title, $Pk3Line)
        $exeRel = ".\gzdoomvr\$ExeName"
        $content = @"
@echo off
cd /d "%~dp0"
echo ============================================================
echo  Launching $Title in VR
echo  Make sure SteamVR / Virtual Desktop (OpenVR) is running first!
echo ============================================================
"$exeRel" -iwad ".\Resources\freedoom-0.12.1\freedoom2.wad" -file $Pk3Line -config ".\gzdoomvr\ashes-vr.ini" +set language "enu" +vr_mode 10
"@
        Set-Content -Path $Path -Value $content -Encoding ASCII -Force
    }
    $pkBase   = '".\Resources\AshesSAMenu.pk3" ".\Resources\lightmodepatch.pk3"'
    $pk3D_2063 = if ($Has3D) { ' ".\Resources\Ashes2063-3D.pk3"' } else { '' }
    $pk3D_Glow = if ($Has3D) { ' ".\Resources\AshesAfterglow-3D.pk3"' } else { '' }
    & $mkBat (Join-Path $GameRoot "Play Ashes 2063 VR.bat") "Ashes 2063 (Enriched / Episode 1 + DMW)" "$pkBase `".\Resources\Ashes2063Enriched2_23.pk3`" `".\Resources\Ashes2063EnrichedFDPatch.pk3`"$pk3D_2063"
    & $mkBat (Join-Path $GameRoot "Play Afterglow VR.bat") "Ashes Afterglow" "$pkBase `".\Resources\AshesAfterglow1_16.pk3`"$pk3D_Glow"
    & $mkBat (Join-Path $GameRoot "Play Hard Reset VR.bat") "Ashes Hard Reset" "$pkBase `".\Resources\AshesHardReset_105.pk3`""
}

# Resolve the gzdoomvr exe name inside <gameRoot>\gzdoomvr (gzdoom.exe or
# gzdoomvr.exe). Returns $null if the folder/exe isn't there.
function Get-AshesGzExeName {
    param([string]$GameRoot)
    $gzDir = Join-Path $GameRoot "gzdoomvr"
    if (-not (Test-Path -LiteralPath $gzDir)) { return $null }
    $exe = Get-ChildItem -LiteralPath $gzDir -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)gzdoom' } | Select-Object -First 1
    if ($exe) { return $exe.Name }
    return $null
}

Write-Header
Write-Host "  Installs Ashes 2063 (free GZDoom TC) with motion controls via" -ForegroundColor Gray
Write-Host "  gzdoomvr and an optional 3D pack mod." -ForegroundColor Gray
Write-Host ""

# ---- Existing install? Offer 3D-pack retrofit without a full reinstall.
# The base download is huge (~665 MB); if the VR mod is already here, let
# the user just add the 3D pack instead of fetching everything again.
$existingRoot = $null
try {
    # Detect from FILES ON DISK (a fresh Hub has no .installed_path). A
    # valid install has both Resources\ and gzdoomvr\ under the folder.
    $probeRoots = New-Object System.Collections.Generic.List[string]
    # 1) The recorded path, if the marker happens to be present.
    try {
        $ipFile = Join-Path $SCRIPT_DIR ".installed_path"
        if (Test-Path -LiteralPath $ipFile) {
            $cand = (Get-Content -LiteralPath $ipFile -Raw -ErrorAction SilentlyContinue)
            if ($cand) { [void]$probeRoots.Add($cand.Trim()) }
        }
    } catch {}
    # 2) The standard install locations (C:/D:/E:\Games\Ashes 2063 VR).
    # Build these WITHOUT Join-Path: on some PowerShell versions Join-Path
    # throws DriveNotFound if D:/E: don't exist, which would abort the
    # whole detection. Plain string join never validates the drive.
    foreach ($r in $DEFAULT_ROOTS) { [void]$probeRoots.Add(($r.TrimEnd('\') + '\' + $GAME_FOLDER)) }
    foreach ($cand in $probeRoots) {
        try {
            if ($cand -and (Test-Path -LiteralPath ($cand.TrimEnd('\') + '\Resources')) -and (Test-Path -LiteralPath ($cand.TrimEnd('\') + '\gzdoomvr'))) {
                $existingRoot = $cand
                break
            }
        } catch { }
    }
} catch {}

if ($existingRoot) {
    Write-Host "  An existing Ashes 2063 VR install was found here:" -ForegroundColor Green
    Write-Host "    $existingRoot" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  What would you like to do?" -ForegroundColor White
    Write-Host "    [1] Add the 3D ammo + props mod only (no big re-download)" -ForegroundColor Yellow
    Write-Host "    [2] Reinstall everything from scratch" -ForegroundColor Yellow
    Write-Host ""
    $modeChoice = (Read-Host "  Choose 1 or 2").Trim()
    if ($modeChoice -eq "1") {
        Pause-User "Press Enter to start..."
        Write-Step 1 1 "Adding the 3D models addon"
        $gzName = Get-AshesGzExeName -GameRoot $existingRoot
        if (-not $gzName) {
            Write-Fail "Could not find the gzdoomvr executable under $existingRoot\gzdoomvr."
            Write-Host "  The install looks incomplete - run a full reinstall instead." -ForegroundColor Yellow
            Pause-User "Press Enter to close..."
            return
        }
        $ok3d = Install-Ashes3DAddon -GameRoot $existingRoot -ScriptDir $SCRIPT_DIR
        if ($ok3d) {
            # Rewrite the launchers so the 3D pk3s are loaded.
            try {
                Write-AshesLaunchers -GameRoot $existingRoot -ExeName $gzName -Has3D $true
                Write-OK "Launchers updated - the 3D pack now loads for Ashes 2063 and Afterglow."
            } catch { Write-Warn "Could not update the launchers: $($_.Exception.Message)" }
            Write-Host ""
            Write-Host "  Done. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub or your existing" -ForegroundColor White
Write-Host "  desktop shortcuts as usual." -ForegroundColor White
            Write-Host ""
            Write-Host "  Tune in to Spire Radio, scavenger - now in glorious 3D." -ForegroundColor Magenta
        } else {
            Write-Host ""
            Write-Host "  No changes made. You can re-run this any time." -ForegroundColor Gray
        }
        Write-Host ""
        Pause-User "Press Enter to close..."
        return
    }
    # Choice 2 (or anything else) falls through to a normal full install.
    Write-Info "Continuing with a full reinstall."
    Write-Host ""
}


# ---- 1. get the (free) Ashes Standalone download ------------
Write-Step 1 6 "Get the Ashes Standalone download"
Write-Host "  Ashes is a free download from ModDB, so it can't be fetched automatically." -ForegroundColor White
Write-Host "  Pressing Enter opens the download page:" -ForegroundColor Yellow
Write-Host "      ( $ASHES_MODDB )" -ForegroundColor Gray
Write-Host ""
Write-Host "  1) Click the red DOWNLOAD NOW button (665,65MB)." -ForegroundColor White
Write-Host "  2) Come back here and drag the ZIP onto this window." -ForegroundColor White
Pause-User "Press Enter to open the Ashes download page..."
try { Start-Process $ASHES_MODDB | Out-Null } catch { Write-Warn "Open manually: $ASHES_MODDB" }

$ashesZip = $null
while (-not $ashesZip) {
    Write-Host ""
    Write-Host " >>> Drag the Ashes ZIP here, then press Enter " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "     (the ModDB file, e.g. AshesStandalone_V1_51.zip)" -ForegroundColor DarkGray
    Write-Host "     (or just press Enter to reopen the download page)" -ForegroundColor DarkGray
    $drop = (Read-Host "  File").Trim().Trim('"').Trim("'").Trim()
    if (-not $drop) {
        try { Start-Process $ASHES_MODDB | Out-Null } catch { Write-Host "    $ASHES_MODDB" -ForegroundColor Cyan }
        continue
    }
    if (-not (Test-Path -LiteralPath $drop)) { Write-Warn "File not found: $drop"; continue }
    if ((Get-Item -LiteralPath $drop).PSIsContainer) { Write-Warn "That is a folder - drag the .zip file itself."; continue }
    if ($drop -notmatch '(?i)\.zip$') {
        Write-Warn "That does not look like a .zip ($drop)."
        $yn = (Read-Host "  Use it anyway? (y/N)").Trim().ToLower()
        if ($yn -ne "y") { continue }
    }
    $ashesZip = [string]$drop
}
Write-OK "Ashes ZIP: $ashesZip"

# ---- 2. install location ------------------------------------
Write-Step 2 6 "Choose install location"
Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  Press Enter to accept it, or type a different folder to install into." -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
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

if (Test-Path -LiteralPath "$gameRoot\Resources") {
    Write-Warn "An existing Ashes 2063 VR install was found at: $gameRoot"
    Write-Host "  Press Enter to reinstall (the folder will be rebuilt)," -ForegroundColor Gray
    Write-Host "  or close this window to abort." -ForegroundColor Gray
    Pause-User "Press Enter to reinstall..."
}

$tmp = Join-Path $installRoot "_ashes_vr_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..."
    exit 1
}

# ---- 3. extract the Ashes standalone into the game folder ---
Write-Step 3 6 "Extracting Ashes 2063"
$ashesUnpack = Join-Path $tmp "ashes_unpack"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $ashesUnpack) { Remove-Item $ashesUnpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $ashesUnpack -Force -ErrorAction Stop | Out-Null
        Write-Info "Unpacking (this can take a minute - it is a big archive)..."
        $r = Expand-ArchiveOrFallback -ArchivePath $ashesZip -DestinationFolder $ashesUnpack -Label "Ashes Standalone" -AllowSkip $false
        if ([string]$r -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the Ashes ZIP: $_"
        $alt = (Read-Host "  Paste a fresh ZIP path (or Enter to retry same)").Trim().Trim('"')
        if ($alt -and (Test-Path -LiteralPath $alt)) { $ashesZip = [string]$alt }
    }
}

# Locate the standalone root by finding a known content pk3, then treat
# its grandparent (Resources' parent) as the package root to flatten.
$marker = Get-ChildItem -Path $ashesUnpack -Filter "Ashes2063Enriched2_23.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $marker) {
    $marker = Get-ChildItem -Path $ashesUnpack -Filter "AshesSAMenu.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
while (-not $marker) {
    Write-Fail "Could not find the Ashes content (Ashes2063Enriched2_23.pk3) in the ZIP."
    $fb = Invoke-InstallerFallback -Action "find the Ashes content in the ZIP" `
        -Subject "the Ashes standalone ZIP" `
        -Url $ASHES_MODDB `
        -Instructions "The ZIP did not contain the expected Ashes .pk3 files - it may be the wrong download. Grab the 'Ashes Standalone' from ModDB, then paste its path and choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    $alt = (Read-Host "  Fresh ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path -LiteralPath $alt)) {
        try {
            Remove-Item $ashesUnpack -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Path $ashesUnpack -Force -ErrorAction Stop | Out-Null
            Expand-ArchiveOrFallback -ArchivePath $alt -DestinationFolder $ashesUnpack -Label "Ashes Standalone" -AllowSkip $false | Out-Null
        } catch { }
    }
    $marker = Get-ChildItem -Path $ashesUnpack -Filter "Ashes2063Enriched2_23.pk3" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
# marker is inside <pkgRoot>\Resources\ ; pkgRoot = Resources' parent.
$resourcesDir = $marker.Directory
$pkgRoot      = $resourcesDir.Parent.FullName

# Merge the refreshed package into the game folder.  Existing saves, engine
# configuration, addons and other user-created files stay in place.
$placedOk = $false
while (-not $placedOk) {
    try {
        $null = Merge-DirectoryTreeVerified -Source $pkgRoot -Destination $gameRoot -Label "Ashes 2063 files"
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the Ashes files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the Ashes files into place" `
            -Instructions "Copy the CONTENTS of '$pkgRoot' into '$gameRoot' (so a 'Resources' folder sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$pkgRoot" -DestFolder "$gameRoot" -AllowSkip $true
        if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
        if ([string]$fb -eq "skip") { break }
    }
}
$freedoom = Join-Path $gameRoot "Resources\freedoom-0.12.1\freedoom2.wad"
if (-not (Test-Path $freedoom)) {
    Write-Warn "freedoom2.wad was not found at the expected path."
    Write-Host "  Expected: $freedoom" -ForegroundColor DarkGray
    Write-Host "  The launchers may need the IWAD path corrected if the package layout differs." -ForegroundColor Gray
}
Write-OK "Ashes installed at: $gameRoot"

# ---- 4. download + place the gzdoomvr VR engine -------------
Write-Step 4 6 "Downloading the VR engine (gzdoomvr)"
$gzZip = Join-Path $tmp "gzdoomvr.zip"
$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest gzdoomvr release via the GitHub API..."
$apiUrl = Get-LatestGzdoomvrZipUrl
if ($apiUrl) { Write-OK "Latest gzdoomvr asset: $apiUrl"; [void]$urls.Add($apiUrl) }
else { Write-Warn "GitHub API not reachable (rate limit / offline). Using the known-good version." }
if ([string]$apiUrl -ne [string]$GZVR_KNOWN_ZIP) { [void]$urls.Add($GZVR_KNOWN_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $gzZip `
    -Label "gzdoomvr (VR engine)" `
    -ManualUrl $GZVR_RELEASES `
    -Instructions "Open the releases page, download the newest 'gzdoomvr-*.zip', save it as '$gzZip', then choose Retry." `
    -SkipMessage "" | Out-Null

while (-not (Test-Path $gzZip)) {
    Write-Fail "The gzdoomvr download is not present at: $gzZip"
    $fb = Invoke-InstallerFallback -Action "download gzdoomvr" `
        -Subject "the gzdoomvr VR engine" -Url $GZVR_RELEASES `
        -Instructions "Download the newest 'gzdoomvr-*.zip' from the releases page, save it as '$gzZip', then choose Retry. You can also paste the path to an already-downloaded ZIP." `
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

# The exe name inside the build is not guaranteed (gzdoom.exe / gzdoomvr.exe),
# so find it rather than assume. Its folder is the engine payload root.
$gzExe = Get-ChildItem -Path $gzUnpack -Filter "gzdoom*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $gzExe) {
    $gzExe = Get-ChildItem -Path $gzUnpack -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '(?i)unins|setup|vcredist|crash' } | Select-Object -First 1
}
while (-not $gzExe) {
    Write-Fail "No gzdoom executable found in the gzdoomvr download."
    $fb = Invoke-InstallerFallback -Action "find the gzdoomvr executable" `
        -Subject "the gzdoomvr ZIP" -Url $GZVR_RELEASES `
        -Instructions "The ZIP did not contain a gzdoom*.exe. Re-download the newest 'gzdoomvr-*.zip', save it as '$gzZip', then choose Retry." `
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
$gzSrcDir = Split-Path -Parent $gzExe.FullName
$gzExeName = $gzExe.Name
$gzDestDir = Join-Path $gameRoot "gzdoomvr"
try {
    $null = Merge-DirectoryTreeVerified -Source $gzSrcDir -Destination $gzDestDir -Label "gzdoomvr files" `
        -KeepExistingRelativePaths @("ashes-vr.ini")
} catch {
    Write-Fail "Could not place the gzdoomvr files: $_"
    Invoke-InstallerFallback -Action "copy the gzdoomvr files into place" `
        -Instructions "Copy the CONTENTS of '$gzSrcDir' into '$gzDestDir' (so $gzExeName sits at its root). Then choose Retry, or Skip." `
        -SourceFolder "$gzSrcDir" -DestFolder "$gzDestDir" -AllowSkip $true | Out-Null
}
Write-OK "VR engine ready: gzdoomvr\$gzExeName"

# ---- 5. optional: 3D models addon (ModDB) -------------------
Write-Step 5 6 "Optional: 3D models addon"
$has3D = $false
$addon3DChoice = Read-Host "  Install the optional 3D models addon now? (Y/N)"
if ($addon3DChoice -match '^(y|yes|j|ja)$') {
    $has3D = (Install-Ashes3DAddon -GameRoot $gameRoot -ScriptDir $SCRIPT_DIR)
} else {
    Write-Info "Skipping the 3D models addon. You can re-run this installer to add it later."
}

# ---- 6. write VR launchers + desktop shortcuts --------------
Write-Step 6 6 "Creating VR launchers and shortcuts"

$batEp1    = Join-Path $gameRoot "Play Ashes 2063 VR.bat"
$batGlow   = Join-Path $gameRoot "Play Afterglow VR.bat"
$batReset  = Join-Path $gameRoot "Play Hard Reset VR.bat"
try {
    Write-AshesLaunchers -GameRoot $gameRoot -ExeName $gzExeName -Has3D $has3D
    Write-OK "VR launchers written (Enriched / Afterglow / Hard Reset)."
} catch {
    Write-Warn "Could not write one or more launcher .bat files: $_"
}

# Desktop shortcuts (game is not Steam-launched, so each episode gets one).
$iconExe = Join-Path $gameRoot "Resources\Ashes.exe"
if (-not (Test-Path $iconExe)) { $iconExe = Join-Path $gzDestDir $gzExeName }
$icoEp1   = Join-Path $gameRoot "Ashes2063_VR.ico"
$icoGlow  = Join-Path $gameRoot "AshesAfterglow_VR.ico"
$icoReset = Join-Path $gameRoot "AshesHardReset_VR.ico"
try { Copy-Item -LiteralPath (Join-Path $PSScriptRoot "Ashes2063_VR.ico") -Destination $icoEp1 -Force } catch {}
try { Copy-Item -LiteralPath (Join-Path $PSScriptRoot "AshesAfterglow_VR.ico") -Destination $icoGlow -Force } catch {}
try { Copy-Item -LiteralPath (Join-Path $PSScriptRoot "AshesHardReset_VR.ico") -Destination $icoReset -Force } catch {}
if (Test-Path $batEp1)   { New-DesktopShortcut -ShortcutName "Ashes 2063 VR" -TargetPath $batEp1 -WorkingDir $gameRoot -IconPath $(if (Test-Path $icoEp1) { $icoEp1 } elseif (Test-Path $iconExe) { $iconExe } else { "" }) -Description "Ashes 2063 Enriched in VR (gzdoomvr)" }
if (Test-Path $batGlow)  { New-DesktopShortcut -ShortcutName "Ashes Afterglow VR" -TargetPath $batGlow -WorkingDir $gameRoot -IconPath $(if (Test-Path $icoGlow) { $icoGlow } elseif (Test-Path $iconExe) { $iconExe } else { "" }) -Description "Ashes Afterglow in VR (gzdoomvr)" }
if (Test-Path $batReset) { New-DesktopShortcut -ShortcutName "Ashes Hard Reset VR" -TargetPath $batReset -WorkingDir $gameRoot -IconPath $(if (Test-Path $icoReset) { $icoReset } elseif (Test-Path $iconExe) { $iconExe } else { "" }) -Description "Ashes Hard Reset in VR (gzdoomvr)" }

# Record the install path so the Hub's VR Ready check + Start-in-VR find it.
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Force -ErrorAction Stop } catch {}

# cleanup temp
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub (main episode), or per" -ForegroundColor White
Write-Host "  episode - three episodes, three desktop shortcuts:" -ForegroundColor White
Write-Host "    * Ashes 2063 VR        (Enriched / Episode 1 + Dead Man Walking)" -ForegroundColor Gray
Write-Host "    * Ashes Afterglow VR" -ForegroundColor Gray
Write-Host "    * Ashes Hard Reset VR" -ForegroundColor Gray
Write-Host ""
Write-Host "  Launch SteamVR (or Virtual Desktop's OpenVR) before the game to" -ForegroundColor Yellow
Write-Host "  avoid it potentially starting sometimes out of focus." -ForegroundColor Yellow
Write-Host "  Aiming uses your tracked hand + the built-in laser sight." -ForegroundColor Gray
Write-Host "  VR settings (comfort, snap-turn, weapon angle) are in Options -> VR." -ForegroundColor Gray
Write-Host "  Controller bindings: SteamVR -> per-game bindings for gzdoomvr." -ForegroundColor Gray
Write-Host ""
Write-Host "  Tune in to Spire Radio, scavenger - the wasteland is hungry tonight." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close..."
