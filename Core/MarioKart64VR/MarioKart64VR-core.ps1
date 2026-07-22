# ============================================================
# Mario Kart 64 VR - Installer (SpaghettiKart VR by RaYRoD)
# ============================================================
# Mario Kart 64 in PCVR, built on SpaghettiKart (the Mario Kart 64
# PC port). Headset on = sitting in the kart in stereo 3D with full
# head tracking; no headset = the same game runs flat. BETA - expect
# bugs.
#
# The user supplies their own Mario Kart 64 US .z64 ROM. Spaghettify
# itself asks for the ROM once on first launch - this installer only
# explains what is needed. No game ROM is downloaded or shipped.
#
# Update badge: the Hub compares the GitHub latest tag (GithubRepo in
# the catalog) against .installed_version, which this installer
# writes VERBATIM from tag_name.
#
# Optional step: the MK64 Reloaded HD texture pack by GhostlyDark
# (.o2r file into a mods folder next to Spaghettify.exe - loads as a
# mod, no rebuild needed).
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Mario Kart 64 VR Installer"
$ErrorActionPreference = "Stop"

$INSTALL_ROOT      = "C:\Games\Mario Kart 64 VR"
$GAME_EXE          = "Spaghettify.exe"
$GITHUB_API_LATEST = "https://api.github.com/repos/RaYRoD-TV/MarioKart64-VR/releases/latest"
$GITHUB_RELEASES   = "https://github.com/RaYRoD-TV/MarioKart64-VR/releases/latest"
$PINNED_URL        = "https://github.com/RaYRoD-TV/MarioKart64-VR/releases/download/v1.0.0/MarioKart64-VR-win64.zip"
$PINNED_TAG        = "v1.0.0"
# HD texture pack (optional): MK64 Reloaded by GhostlyDark. Must be
# the .o2r asset; there are two SpaghettiKart variants (sk-4k and
# sk-hd) - we prefer 4k, matching the recommended build.
$HD_API_LATEST     = "https://api.github.com/repos/GhostlyDark/MK64-Reloaded/releases/latest"
$HD_RELEASES       = "https://github.com/GhostlyDark/MK64-Reloaded/releases/latest"
$HD_PINNED_URL     = "https://github.com/GhostlyDark/MK64-Reloaded/releases/download/v2026.04.03/mk64-reloaded-v2026.04.03-sk-4k.o2r"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Mario Kart 64 VR - Installer" -ForegroundColor Cyan
 Write-Host " SpaghettiKart VR by RaYRoD | Mario Kart 64 US ROM required" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Header
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Mario Kart 64 - US version, .z64 format, that you own." -ForegroundColor Yellow
Write-Host "    SHA-1: 579C48E211AE952530FFC8738709F078D5DD215E" -ForegroundColor Gray
Write-Host "    (.n64 dump? Convert it: https://hack64.net/tools/swapper.php)" -ForegroundColor Gray
Write-Host "  The game asks for the ROM ONCE on first launch; it is read" -ForegroundColor Gray
Write-Host "  locally and never leaves your PC. No ROM = nothing to install" -ForegroundColor Gray
Write-Host "  here will run, so have it ready." -ForegroundColor Gray
Write-Host ""
Write-Host "  BETA: this port is early and still changing - expect the odd" -ForegroundColor Yellow
Write-Host "  bug. Reports are welcome on the GitHub page." -ForegroundColor Yellow

# -------------------------------------------------------
# STEP 1: Install location (update / reinstall handling)
# -------------------------------------------------------
Pause-User "Press Enter to start..."
Write-Step 1 5 "Install location"

Write-Info "Install folder: $INSTALL_ROOT"
Write-Host ""

$updateMode = $false
if (Test-Path -LiteralPath (Join-Path $INSTALL_ROOT $GAME_EXE)) {
 Write-Host " An existing install was found." -ForegroundColor Cyan
 Write-Host " [U] Update    - download the latest release over it (your ROM" -ForegroundColor White
 Write-Host "                 choice, settings and mods folder are kept)" -ForegroundColor White
 Write-Host " [R] Reinstall - wipe the folder and set up fresh (mods and" -ForegroundColor White
 Write-Host "                 settings in the folder are removed too)" -ForegroundColor White
 Write-Host ""
 $ans = ""
 while ($ans -notin @("U","R")) { $ans = (Read-Host " Enter U or R").Trim().ToUpper() }
 if ($ans -eq "U") {
  $updateMode = $true
  Write-OK "Update mode."
 } else {
  Write-Info "Removing the old install..."
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
$null = Show-UpdateNoticeIfInstalled -TargetDir $INSTALL_ROOT -RelModFile $GAME_EXE -Label "Mario Kart 64 VR"
Write-Step 2 5 "Downloading the latest release"

$dlUrl = $null
$relTag = $null
try {
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 $rel = Invoke-RestMethod -Uri $GITHUB_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
 $asset = $rel.assets | Where-Object { $_.name -like "MarioKart64-VR*win64*.zip" } | Select-Object -First 1
 if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 }
 if ($asset) {
  $dlUrl = $asset.browser_download_url
  $relTag = [string]$rel.tag_name
  Write-Info "Latest release: $relTag"
 }
} catch {
 Write-Warn "Could not query GitHub for the latest release (rate limit / offline)."
 Write-Warn "Falling back to the pinned $PINNED_TAG build."
}
if (-not $dlUrl) { $dlUrl = $PINNED_URL; $relTag = $PINNED_TAG }

$zipPath = Join-Path $env:TEMP ("MK64VR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
if (-not (Invoke-DownloadOrFallback -Url $dlUrl -Destination $zipPath -Label "Mario Kart 64 VR" `
   -ManualUrl $GITHUB_RELEASES `
   -Instructions "Download MarioKart64-VR-win64.zip from the Releases page, then drop it into your Downloads folder and retry.")) {
 $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter "MarioKart64-VR*.zip" -ErrorAction SilentlyContinue |
   Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($manualZip) {
  Write-OK "Found a manual download: $($manualZip.Name)"
  $zipPath = $manualZip.FullName
 } else {
  Write-Fail "No Mario Kart 64 VR bundle available - cannot continue."
  Pause-User "Press Enter to exit."; exit 1
 }
}

# -------------------------------------------------------
# STEP 3: Extract + flatten + verify
# -------------------------------------------------------
Write-Step 3 5 "Installing to $INSTALL_ROOT"

$exRes = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $INSTALL_ROOT -Label "Mario Kart 64 VR"
if (-not $exRes) {
 Write-Fail "Extraction failed."
 Pause-User "Press Enter to exit."; exit 1
}
# The release zip wraps everything in a "MarioKart64-VR" folder
# (verified against v1.0.0: Spaghettify.exe is NOT at the zip root).
# Flatten so the exe sits directly in the install root - and stay
# generic in case a future release renames or drops the wrapper.
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
if ($zipPath -like (Join-Path $env:TEMP "*")) { try { Remove-Item -LiteralPath $zipPath -Force } catch {} }

# -------------------------------------------------------
# STEP 4: Optional HD texture pack (MK64 Reloaded)
# -------------------------------------------------------
Write-Step 4 5 "Optional: HD textures (MK64 Reloaded by GhostlyDark)"

Write-Host " Want it in HD? The MK64 Reloaded texture pack loads as a mod -" -ForegroundColor White
Write-Host " one .o2r file in a mods folder, no rebuild needed. Recommended." -ForegroundColor White
Write-Host ""
$hdAns = ""
while ($hdAns -notin @("Y","N")) { $hdAns = (Read-Host " Install the HD texture pack? [Y/N]").Trim().ToUpper() }
if ($hdAns -eq "Y") {
 # Resolve the newest .o2r via the GitHub API. It MUST be the .o2r
 # asset; the release ships two SpaghettiKart variants (sk-4k and
 # sk-hd) - prefer 4k, then any sk build, then any .o2r at all.
 $hdUrl = $null
 $hdName = $null
 try {
  $hdRel = Invoke-RestMethod -Uri $HD_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
  $hdAsset = $hdRel.assets | Where-Object { $_.name -like "*-sk-4k.o2r" } | Select-Object -First 1
  if (-not $hdAsset) { $hdAsset = $hdRel.assets | Where-Object { $_.name -like "*sk*.o2r" } | Select-Object -First 1 }
  if (-not $hdAsset) { $hdAsset = $hdRel.assets | Where-Object { $_.name -like "*.o2r" } | Select-Object -First 1 }
  if ($hdAsset) {
   $hdUrl = $hdAsset.browser_download_url
   $hdName = $hdAsset.name
   Write-Info "Latest texture pack: $($hdRel.tag_name) ($hdName)"
  }
 } catch {
  Write-Warn "Could not query GitHub for the latest texture pack."
  Write-Warn "Falling back to the pinned v2026.04.03 4k build."
 }
 if (-not $hdUrl) { $hdUrl = $HD_PINNED_URL; $hdName = ($HD_PINNED_URL -split '/')[-1] }

 $modsDir = Join-Path $INSTALL_ROOT "mods"
 New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
 $hdDest = Join-Path $modsDir $hdName
 if (Invoke-DownloadOrFallback -Url $hdUrl -Destination $hdDest -Label "MK64 Reloaded texture pack" `
    -ManualUrl $HD_RELEASES `
    -Instructions "Download the -sk-4k .o2r file from the Releases page and drop it into $modsDir - then just continue." `
    -SkipMessage "Skipped - the game runs fine with the original textures; rerun this installer any time to add HD.") {
  # Clear any OLDER Reloaded builds so two packs never fight.
  Get-ChildItem -Path $modsDir -Filter "mk64-reloaded*.o2r" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne $hdName } | ForEach-Object {
     Write-Info "Removing older texture pack: $($_.Name)"
     Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
    }
  Write-OK "HD texture pack installed to mods\$hdName"
 }
} else {
 Write-Info "Skipping HD textures - the original look it is. Rerun this"
 Write-Info "installer any time to add them."
}

# -------------------------------------------------------
# STEP 5: Desktop shortcut + Hub markers
# -------------------------------------------------------
Write-Step 5 5 "Desktop shortcut"

try {
 $sh = New-Object -ComObject WScript.Shell
 $lnk = $sh.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Mario Kart 64 VR.lnk"))
 $lnk.TargetPath = Join-Path $INSTALL_ROOT $GAME_EXE
 $lnk.WorkingDirectory = $INSTALL_ROOT
 $lnk.IconLocation = (Join-Path $INSTALL_ROOT $GAME_EXE) + ",0"
 $lnk.Description = "Mario Kart 64 VR (SpaghettiKart) - headset on = VR, headset off = flat"
 $lnk.Save()
 Write-OK "Desktop shortcut created."
} catch {
 Write-Warn "Could not create the desktop shortcut: $_"
}

# Hub markers: install path for "Start in VR" + the EXACT release tag
# for the update badge (string-compared against the GitHub latest tag).
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
Write-Host "  1. Start your VR runtime (Virtual Desktop, SteamVR, Quest" -ForegroundColor White
Write-Host "     Link / Air Link) - or skip this to play flat." -ForegroundColor White
Write-Host "  2. Launch via the desktop shortcut or 'Start in VR' in the Hub." -ForegroundColor White
Write-Host "  3. FIRST LAUNCH ONLY: the game asks for your Mario Kart 64" -ForegroundColor White
Write-Host "     US .z64 ROM. Pick it once and you are set." -ForegroundColor White
Write-Host "  4. Pause, then pull the right trigger (R1 on gamepad): the" -ForegroundColor White
Write-Host "     VR OPTIONS menu floats in front of you - view mode, world" -ForegroundColor White
Write-Host "     scale, stereo depth, HUD and more, all live." -ForegroundColor White
Write-Host ""
Write-Host " QUICK CONTROLS (VR controllers - gamepad works alongside):" -ForegroundColor Yellow
Write-Host "  A gas, B brake/reverse, left trigger or X item, right" -ForegroundColor White
Write-Host "  trigger/grip hop & drift, hold Y look behind, right-stick" -ForegroundColor White
Write-Host "  click switches Third/First Person, Theater, Diorama." -ForegroundColor White
Write-Host ""
Write-Host " Rainbow Road has no guardrails. Neither does karma." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
