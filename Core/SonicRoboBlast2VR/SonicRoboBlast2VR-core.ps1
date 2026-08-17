# ============================================================
# Sonic Robo Blast 2 VR - Full Game Installer (SRB2-VR)
# ============================================================
# SRB2-VR by RaYRoD-TV: a native OpenXR port of Sonic Robo Blast 2,
# forked from the CURRENT official release (STJr/SRB2 2.2.15). Runs
# on any conformant OpenXR runtime (SteamVR, Virtual Desktop VDXR,
# Meta, Pimax). Full VR controller support via the OpenXR action
# system; a regular gamepad and mouse/keyboard still work too.
#
# This is a FULL free fan game: the release bundle ships the game
# plus all its freely distributed 2.2.15 assets. One download,
# unzip, play - headset on = VR, headset off = regular SRB2.
#
# The Hub tracks updates via the GitHub latest-release tag (the
# catalog's GithubRepo field); this installer records the EXACT
# tag_name in .installed_version so the two always compare cleanly.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Sonic Robo Blast 2 VR Installer"
$ErrorActionPreference = "Stop"

$INSTALL_ROOT      = "C:\Games\Sonic Robo Blast 2 VR"
$GAME_EXE          = "srb2win.exe"
$GITHUB_API_LATEST = "https://api.github.com/repos/RaYRoD-TV/SRB2-VR/releases/latest"
$GITHUB_RELEASES   = "https://github.com/RaYRoD-TV/SRB2-VR/releases/latest"
# Pinned direct link as a network fallback if the API is rate-limited.
$PINNED_URL        = "https://github.com/RaYRoD-TV/SRB2-VR/releases/download/v2.2.15-vr2/SRB2-VR-full-win64.zip"
$PINNED_TAG        = "v2.2.15-vr2"
$ASSET_NAME        = "SRB2-VR-full-win64.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Sonic Robo Blast 2 VR - Full Game Installer" -ForegroundColor Cyan
 Write-Host " SRB2-VR (OpenXR) by RaYRoD-TV - game by Sonic Team Junior" -ForegroundColor Gray
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

# -------------------------------------------------------
# STEP 1: Install location (update / reinstall handling)
# -------------------------------------------------------
Write-Host " SRB2-VR (OpenXR) by RaYRoD-TV - the free fan platformer Sonic Robo" -ForegroundColor White
Write-Host " Blast 2 in VR. This installs the full standalone game." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."

# ---- ZWEITER WEG: RaYRoD-TVs eigener Multiverse VR Hub --------
# Er pflegt seine sechs VR-Ports inzwischen ueber einen eigenen
# kleinen Hub und kuendigt an, dass kuenftige Fassungen dort
# erscheinen. Deshalb steht der Weg hier zur Wahl.
# WARUM WIR DEN ORT BESTIMMEN: sein Hub installiert die Spiele
# selbst, an eine Stelle die wir sonst nicht kennen - wir wuessten
# dann weder ob Sonic Robo Blast 2 installiert ist noch was "Start in VR"
# oeffnen soll. Der Nutzer waehlt den Ordner, und genau die Exe
# dort wird danach gestartet.
Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " TWO WAYS TO GET THIS" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "    [1] This installer" -ForegroundColor White
Write-Host "        Installs Sonic Robo Blast 2 VR straight into your game folder." -ForegroundColor Gray
Write-Host "        Start in VR launches the game itself." -ForegroundColor Gray
Write-Host ""
Write-Host "    [2] RaYRoD-TV's own Multiverse VR Hub" -ForegroundColor White
Write-Host "        One small app that installs all six of his ports and" -ForegroundColor Gray
Write-Host "        keeps them updated. Future builds land there first." -ForegroundColor Gray
Write-Host "        You pick the folder; Start in VR then opens that app." -ForegroundColor Gray
Write-Host ""
$mvrhChoice = ""
while ($mvrhChoice -ne "1" -and $mvrhChoice -ne "2") {
    $mvrhChoice = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
    if ($mvrhChoice -eq "") { $mvrhChoice = "1" }
    if ($mvrhChoice -ne "1" -and $mvrhChoice -ne "2") { Write-Warn "Please type 1 or 2." }
}
if ($mvrhChoice -eq "2") {
    $mvrhExe = Install-MultiverseVRHub
    if ($mvrhExe) {
        # Start in VR zeigt auf SEINEN Hub. Wir behaupten NICHTS darueber,
        # welche Spiele darin liegen - wir bringen den Nutzer nur an die
        # Stelle zurueck, an der er sie gestartet hat.
        try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value (Split-Path $mvrhExe -Parent) -Encoding UTF8 -Force } catch {}
        try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".launch_exe")     -Value $mvrhExe -Encoding UTF8 -Force } catch {}
        Write-Host ""
        Write-Host "  Open it, pick Sonic Robo Blast 2 and hit Play - it fetches the" -ForegroundColor White
        Write-Host "  official port and applies the VR patch itself." -ForegroundColor White
        Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
        Write-Host ""
        try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
    }
    Pause-User "Press Enter to exit."
    exit 0
}


Write-Step 1 4 "Install location"

Write-Info "SRB2-VR is a free, standalone fan game - no Steam copy needed."
Write-Info "Install folder: $INSTALL_ROOT"
Write-Host ""

if (Test-Path -LiteralPath (Join-Path $INSTALL_ROOT $GAME_EXE)) {
 Write-OK "Existing install found - merging the latest release; additional files are kept."
}
if (-not (Test-Path -LiteralPath $INSTALL_ROOT)) {
 New-Item -ItemType Directory -Path $INSTALL_ROOT -Force | Out-Null
 Write-OK "Created $INSTALL_ROOT"
}

# -------------------------------------------------------
# STEP 2: Download the latest release from GitHub
# -------------------------------------------------------
$null = Show-UpdateNoticeIfInstalled -TargetDir $INSTALL_ROOT -RelModFile $GAME_EXE -Label "SRB2-VR"
Write-Step 2 4 "Downloading the latest release"

# Resolve the newest full-bundle asset via the GitHub API. Falls back
# to the pinned release link, and finally to a manual browser grab.
$dlUrl = $null
$relTag = $null
try {
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 $rel = Invoke-RestMethod -Uri $GITHUB_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
 $asset = $rel.assets | Where-Object { $_.name -eq $ASSET_NAME } | Select-Object -First 1
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
if (-not $dlUrl) { $dlUrl = $PINNED_URL; $relTag = $PINNED_TAG }

$zipPath = Join-Path $env:TEMP ("SRB2VR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
if (-not (Invoke-DownloadOrFallback -Url $dlUrl -Destination $zipPath -Label "SRB2-VR full bundle" `
   -ManualUrl $GITHUB_RELEASES `
   -Instructions "Download $ASSET_NAME from the Releases page, then drop it into your Downloads folder and retry.")) {
 # Last resort: a copy the user downloaded by hand
 $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter "SRB2-VR-full*.zip" -ErrorAction SilentlyContinue |
   Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($manualZip) {
  Write-OK "Found a manual download: $($manualZip.Name)"
  $zipPath = $manualZip.FullName
 } else {
  Write-Fail "No SRB2-VR bundle available - cannot continue."
  Pause-User "Press Enter to exit."; exit 1
 }
}

# -------------------------------------------------------
# STEP 3: Extract + verify
# -------------------------------------------------------
Write-Step 3 4 "Installing to $INSTALL_ROOT"

$exRes = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $INSTALL_ROOT -Label "SRB2-VR"
if (-not $exRes) {
 Write-Fail "Extraction failed."
 Pause-User "Press Enter to exit."; exit 1
}
# The bundle is flat (srb2win.exe at the zip root); if a future
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
 $lnk = $sh.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Sonic Robo Blast 2 VR.lnk"))
 $lnk.TargetPath = Join-Path $INSTALL_ROOT $GAME_EXE
 $lnk.WorkingDirectory = $INSTALL_ROOT
 $lnk.IconLocation = (Join-Path $INSTALL_ROOT $GAME_EXE) + ",0"
 $lnk.Description = "Sonic Robo Blast 2 VR (OpenXR) - headset on = VR, headset off = regular SRB2"
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
Write-Host "  1. Put your headset on (SteamVR, Virtual Desktop, Meta or" -ForegroundColor White
Write-Host "     Pimax - any OpenXR runtime works)." -ForegroundColor White
Write-Host "  2. Launch via the desktop shortcut or" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub." -ForegroundColor White
Write-Host "     Headset on = VR. Headset off = regular flat SRB2." -ForegroundColor White
Write-Host "  3. Options -> VR Options has everything: VR mode, world scale," -ForegroundColor White
Write-Host "     screen distance/size, HUD opacity, recenter." -ForegroundColor White
Write-Host ""
Write-Host " CONTROLS (VR controllers, OpenXR native):" -ForegroundColor Yellow
Write-Host "  Left stick moves, right stick turns. A jumps, X spins," -ForegroundColor White
Write-Host "  triggers throw rings, right grip locks on. Right-stick click" -ForegroundColor White
Write-Host "  switches first/third person. Gamepad and KB&M work too." -ForegroundColor White
Write-Host ""
Write-Host " Gotta go fast. The rings are RIGHT there now." -ForegroundColor Blue
Write-Host ""
Pause-User "Press Enter to exit."
