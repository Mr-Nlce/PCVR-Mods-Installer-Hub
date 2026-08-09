# ============================================================
# Dr. Robotnik's Ring Racers VR - Full Game Installer
# ============================================================
# RingRacers-VR by RaYRoD-TV: a native OpenXR port of Dr.
# Robotnik's Ring Racers (the Kart Krew racer built on the SRB2
# engine). Runs on any conformant OpenXR runtime (SteamVR,
# Virtual Desktop VDXR, Meta, Pimax). Headset on = VR, headset
# off = regular flat Ring Racers. A gamepad and KB&M still work.
#
# This is a FULL free fan game. Two download shapes exist:
#   - RingRacers-VR-full-win64.zip : game + VR exe (first install)
#   - RingRacers-VR-win64.zip      : the VR exe ALONE (updates,
#                                    dropped over an existing game)
# New installs pull the full bundle; updates over an existing
# install pull just the small VR exe and overwrite it in place.
#
# The Hub tracks updates via the GitHub latest-release tag (the
# catalog's GithubRepo field); this installer records the EXACT
# tag_name in .installed_version so the two always compare cleanly.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ring Racers VR Installer"
$ErrorActionPreference = "Stop"

$GAME_FOLDER       = "Ring Racers VR"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")
$GAME_EXE          = "ringracers-vr.exe"
$GITHUB_API_LATEST = "https://api.github.com/repos/RaYRoD-TV/RingRacers-VR/releases/latest"
$GITHUB_RELEASES   = "https://github.com/RaYRoD-TV/RingRacers-VR/releases"
# Pinned direct links as a network fallback if the API is rate-limited.
$PINNED_FULL_URL   = "https://github.com/RaYRoD-TV/RingRacers-VR/releases/download/v2.5-vr1/RingRacers-VR-full-win64.zip"
$PINNED_VRONLY_URL = "https://github.com/RaYRoD-TV/RingRacers-VR/releases/download/v2.5-vr1/RingRacers-VR-win64.zip"
$PINNED_TAG        = "v2.5-vr1"
$ASSET_FULL        = "RingRacers-VR-full-win64.zip"
$ASSET_VRONLY      = "RingRacers-VR-win64.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Dr. Robotnik's Ring Racers VR - Full Game Installer" -ForegroundColor Cyan
 Write-Host " RingRacers-VR (OpenXR) by RaYRoD-TV - game by Kart Krew" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host ""
}

function Write-Step {
 param($num, $total, $text)
 Write-Host ""
 Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
 Write-Host ""
}

function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Header
Write-Host " Ring Racers VR is a free, standalone fan game - no Steam copy needed." -ForegroundColor White
Write-Host " The full game is a large download; a progress bar shows it while it runs." -ForegroundColor Gray
Write-Host " You'll pick where to install it on the next screen." -ForegroundColor Gray
Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: Install location (choose folder, then update / reinstall)
# -------------------------------------------------------
Write-Step 1 4 "Install location"

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  Press Enter to accept it, or type a different folder to install into" -ForegroundColor Gray
Write-Host "  (the '$GAME_FOLDER' folder is created inside whatever you choose)." -ForegroundColor Gray
Write-Host "  C:\Games needs no admin rights, so there's no Windows UAC prompt." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) {
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
    }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    Write-Host "  Enter a folder where the game should be installed." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
$INSTALL_ROOT = Join-Path $installRoot $GAME_FOLDER
Write-OK "Install location: $INSTALL_ROOT"

# updateMode: overwrite an existing install with just the small VR exe.
$updateMode = $false
if (Test-Path -LiteralPath (Join-Path $INSTALL_ROOT $GAME_EXE)) {
 Write-Host "" 
 Write-Host " An existing install was found." -ForegroundColor Cyan
 Write-Host " [U] Update    - fetch just the latest VR exe and drop it" -ForegroundColor White
 Write-Host "                 over your game (saves/addons/settings kept)" -ForegroundColor White
 Write-Host " [R] Reinstall - wipe the folder and set up fresh (full game)" -ForegroundColor White
 Write-Host ""
 $ans = ""
 while ($ans -notin @("U","R")) { $ans = (Read-Host " Enter U or R").Trim().ToUpper() }
 if ($ans -eq "U") {
  $updateMode = $true
  Write-OK "Update mode - VR exe only."
 } else {
  Write-Host " Removing the old install..." -ForegroundColor Gray
  try { Remove-Item -LiteralPath $INSTALL_ROOT -Recurse -Force } catch {
   Write-Warn "Could not fully remove the old folder (files in use?)."
   Write-Warn "Close the game if it is running, then rerun this installer."
   Pause-User "Press Enter to exit."; exit 1
  }
  Write-OK "Old install removed."
 }
}
if (-not (Test-Path -LiteralPath $INSTALL_ROOT)) {
 New-Item -ItemType Directory -Path $INSTALL_ROOT -Force | Out-Null
 Write-OK "Created $INSTALL_ROOT"
}

# -------------------------------------------------------
# STEP 2: Download the latest release from GitHub
# -------------------------------------------------------
$null = Show-UpdateNoticeIfInstalled -TargetDir $installRoot -RelModFile $GAME_EXE -Label "Ring Racers VR"
Write-Step 2 4 "Downloading the latest release"

# Choose which asset we want: full bundle for a fresh install, the
# small VR exe zip for an update over an existing game.
$wantAsset  = if ($updateMode) { $ASSET_VRONLY } else { $ASSET_FULL }
$pinnedUrl  = if ($updateMode) { $PINNED_VRONLY_URL } else { $PINNED_FULL_URL }

# Resolve the newest matching asset via the GitHub API. Falls back
# to the pinned release link, and finally to a manual browser grab.
$dlUrl = $null
$relTag = $null
try {
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 $rel = Invoke-RestMethod -Uri $GITHUB_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
 $asset = $rel.assets | Where-Object { $_.name -eq $wantAsset } | Select-Object -First 1
 if (-not $asset -and $updateMode) { $asset = $rel.assets | Where-Object { $_.name -like "*win64*.zip" -and $_.name -notlike "*full*" } | Select-Object -First 1 }
 if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -like "*full*win64*.zip" } | Select-Object -First 1 }
 if ($asset) {
  $dlUrl = $asset.browser_download_url
  $relTag = [string]$rel.tag_name
  Write-Info "Latest release: $relTag"
 }
} catch {
 Write-Warn "Could not query GitHub for the latest release (rate limit / offline)."
 Write-Warn "Falling back to the pinned $PINNED_TAG build."
}
if (-not $dlUrl) { $dlUrl = $pinnedUrl; $relTag = $PINNED_TAG }

$zipPath = Join-Path $env:TEMP ("RingRacersVR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
if (-not (Invoke-DownloadOrFallback -Url $dlUrl -Destination $zipPath -Label "Ring Racers VR ($wantAsset)" `
   -ManualUrl $GITHUB_RELEASES `
   -Instructions "Download $wantAsset from the Releases page, then drop it into your Downloads folder and retry.")) {
 # Last resort: a copy the user downloaded by hand
 $pat = if ($updateMode) { "RingRacers-VR-win64*.zip" } else { "RingRacers-VR-full*.zip" }
 $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter $pat -ErrorAction SilentlyContinue |
   Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($manualZip) {
  Write-OK "Found a manual download: $($manualZip.Name)"
  $zipPath = $manualZip.FullName
 } else {
  Write-Fail "No Ring Racers VR bundle available - cannot continue."
  Pause-User "Press Enter to exit."; exit 1
 }
}

# -------------------------------------------------------
# STEP 3: Extract + verify
# -------------------------------------------------------
Write-Step 3 4 "Installing to $INSTALL_ROOT"

$exRes = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $INSTALL_ROOT -Label "Ring Racers VR"
if (-not $exRes) {
 Write-Fail "Extraction failed."
 Pause-User "Press Enter to exit."; exit 1
}
# The bundle is flat (ringracers-vr.exe at the zip root); if a future
# release wraps everything in one folder, flatten it.
if (-not (Test-Path -LiteralPath (Join-Path $INSTALL_ROOT $GAME_EXE))) {
 $inner = Get-ChildItem -Path $INSTALL_ROOT -Directory | Where-Object {
  Test-Path -LiteralPath (Join-Path $_.FullName $GAME_EXE)
 } | Select-Object -First 1
 if ($inner) {
  Write-Info "Flattening wrapper folder '$($inner.Name)'..."
  Get-ChildItem -Path $inner.FullName -Force | ForEach-Object {
   Move-Item -LiteralPath $_.FullName -Destination $INSTALL_ROOT -Force
  }
  Remove-Item -LiteralPath $inner.FullName -Recurse -Force
 }
}
if (Test-Path -LiteralPath (Join-Path $INSTALL_ROOT $GAME_EXE)) {
 Write-OK "Game files in place ($GAME_EXE found)."
} else {
 Write-Fail "$GAME_EXE missing after extraction - the bundle layout may have changed."
 Pause-User "Press Enter to exit."; exit 1
}
# Clean up the temp zip (keep a manual Downloads copy untouched)
if ($zipPath -like (Join-Path $env:TEMP "*")) { try { Remove-Item -LiteralPath $zipPath -Force } catch {} }

# -------------------------------------------------------
# STEP 4: Desktop shortcut + Hub markers
# -------------------------------------------------------
Write-Step 4 4 "Desktop shortcut"

try {
 $sh = New-Object -ComObject WScript.Shell
 $lnk = $sh.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Ring Racers VR.lnk"))
 $lnk.TargetPath = Join-Path $INSTALL_ROOT $GAME_EXE
 $lnk.WorkingDirectory = $INSTALL_ROOT
 $lnk.IconLocation = (Join-Path $INSTALL_ROOT $GAME_EXE) + ",0"
 $lnk.Description = "Dr. Robotnik's Ring Racers VR (OpenXR) - headset on = VR, headset off = regular Ring Racers"
 $lnk.Save()
 Write-OK "Desktop shortcut created."
} catch {
 Write-Warn "Could not create the desktop shortcut: $_"
}

# Hub markers: install path for "Start in VR" + the EXACT release tag
# for the update badge (the Hub compares this string against the
# GitHub latest tag, so it must match tag_name verbatim).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $INSTALL_ROOT -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""
Write-Host " HOW TO PLAY:" -ForegroundColor Yellow
Write-Host "  Put your headset on, then launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the" -ForegroundColor White
Write-Host "  Hub or the 'Ring Racers VR' desktop shortcut. Headset on = VR," -ForegroundColor White
Write-Host "  headset off = regular flat Ring Racers." -ForegroundColor White
Write-Host "  VR settings live in Options -> VR Options." -ForegroundColor White
Write-Host ""
Write-Host " See the README for controls and tips." -ForegroundColor DarkGray
Write-Host ""
Write-Host " Start your engines - the rings are RIGHT there now." -ForegroundColor Blue
Write-Host ""
Pause-User "Press Enter to exit."
