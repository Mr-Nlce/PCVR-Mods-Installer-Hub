# ============================================================
# Left 4 Dead 2 - L4D2VR Mod Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Left 4 Dead 2 VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Left 4 Dead 2"
$GAME_EXE = "left4dead2.exe"

# L4D2VR is now hosted under keyou91 (was liu547161153). The author
# sometimes updates the ZIP under the same release tag without bumping
# the version, so we always fetch the latest asset via GitHub API
# rather than pinning a static download URL.
$GITHUB_API = "https://api.github.com/repos/keyou91/l4d2vr/releases/latest"
$GITHUB_RELEASES_URL = "https://github.com/keyou91/l4d2vr/releases"
$L4D2VR_ASSET_NAME = "L4D2VR.zip"

$LAUNCH_PARAMS = "-heapsize 524288 -processheap -high -novid +crosshair 0 -w 1280 -h 720 +mat_queue_mode 0 +mat_vsync 0 +mat_antialias 0 +mat_grain_scale_override 0"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Left 4 Dead 2 - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " L4D2VR by keyou91" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
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

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraries {
 param($steamPath)
 $libraries = @($steamPath)
 $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdfPath) {
 $content = Get-Content $vdfPath -Raw
 $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
 foreach ($m in $found) {
 $lib = $m.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $lib) { $libraries += $lib }
 }
 }
 return $libraries
}

function Find-GamePath {
 param($libraries)
 foreach ($lib in $libraries) {
 $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

# -------------------------------------------------------
# Start mode: Full Install vs Update Only
# -------------------------------------------------------
# L4D2VR releases sometimes ship a new ZIP under the same git tag,
# so users who already configured Steam launch options + in-game
# video settings just need to refresh the mod files. The full
# installer would force them through every step again. Update mode
# skips Steps 2-3 (video settings, launch params) and only redoes
# Step 1 (find game) + Step 4 (download + extract latest ZIP) plus
# the optional Config Tool prompt at the end.
Write-Header
Write-Host " Choose what to do:" -ForegroundColor White
Write-Host ""
Write-Host " [1] Full Install - first time, or to redo everything" -ForegroundColor White
Write-Host " (video settings + launch params + mod files)" -ForegroundColor Gray
Write-Host " [2] Update Mod - refresh the L4D2VR mod ZIP only" -ForegroundColor White
Write-Host " (use this when a new release ships)" -ForegroundColor Gray
Write-Host ""

$modeChoice = ""
while ($modeChoice -notin @("1","2")) {
 $modeChoice = (Read-Host " Your choice (1/2)").Trim()
}

$updateOnly = ($modeChoice -eq "2")
if ($updateOnly) {
 $totalSteps = 2
 Write-Host ""
 Write-OK "Update mode selected - mod files will be refreshed."
} else {
 $totalSteps = 4
}

# -------------------------------------------------------
# STEP 1: Locate Left 4 Dead 2
# -------------------------------------------------------
Pause-User "Press Enter to start..."
Write-Step 1 $totalSteps "Locating Left 4 Dead 2"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Left 4 Dead 2"
 }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath

if (-not $steamPath) {
 Write-Warn "Could not find Steam installation in registry."
 Write-Host " Please enter your Steam installation path manually:" -ForegroundColor White
 Write-Host " Example: C:\Program Files (x86)\Steam" -ForegroundColor Gray
 while (-not $steamPath) {
 $rawInput = (Read-Host " Steam path").Trim().Trim('"')
 if (Test-Path $rawInput) {
 $steamPath = $rawInput
 Write-OK "Steam path set: $steamPath"
 } else {
 Write-Fail "Path not found: $rawInput"
 }
 }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "550" -SteamFolderNames @("Left 4 Dead 2") }

if (-not $gamePath) {
 Write-Warn "Left 4 Dead 2 not found in Steam libraries automatically."
 Write-Host " Please enter the Left 4 Dead 2 installation folder path manually:" -ForegroundColor White
 Write-Host " Example: C:\Program Files (x86)\Steam\steamapps\common\Left 4 Dead 2" -ForegroundColor Gray
 while (-not $gamePath) {
 $rawInput = (Read-Host " Game path").Trim().Trim('"')
 if (Test-Path $rawInput) {
 $gamePath = $rawInput
 Write-OK "Game path set: $gamePath"
 } else {
 Write-Fail "Path not found: $rawInput"
 }
 }
} else {
 Write-OK "Left 4 Dead 2 found: $gamePath"
}

# -------------------------------------------------------
# STEP 2: In-game video settings (full install only)
# -------------------------------------------------------
if (-not $updateOnly) {
 Write-Step 2 $totalSteps "Video Settings"

 Write-Host " Before installing, please set the following in-game video settings:" -ForegroundColor White
 Write-Host ""
 Write-Host " Film Grain Amount -> all the way down (0)" -ForegroundColor Yellow
 Write-Host " Filtering Mode -> Anisotropic 16x" -ForegroundColor Yellow
 Write-Host " Shader Detail -> Very High" -ForegroundColor Yellow
 Write-Host " Effect Detail -> High" -ForegroundColor Yellow
 Write-Host " Model / Texture Detail -> High" -ForegroundColor Yellow
 Write-Host " PAGED Pool Memory -> High" -ForegroundColor Yellow
 Write-Host ""
 Write-Info "Note: If you use many Workshop mods or HD texture packs, set"
 Write-Info "PAGED Pool Memory to Low instead - this prevents crashes."
 Write-Host ""

 Pause-User "Press Enter to launch Left 4 Dead 2 and apply these settings..."
 Start-Process "steam://rungameid/550"

 Write-Host ""
 Write-Host " Left 4 Dead 2 is launching." -ForegroundColor White
 Write-Host " Go to Options -> Video -> Advanced and apply the settings listed above." -ForegroundColor Gray
 Write-Host ""

 Pause-User "Press Enter once you have applied the video settings and closed the game..."

 # -------------------------------------------------------
 # STEP 3: Steam launch parameters
 # -------------------------------------------------------
 Write-Step 3 $totalSteps "Steam Launch Parameters"

 try { Set-Clipboard -Value $LAUNCH_PARAMS } catch {}

 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Steam Launch Parameters" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
 Write-Host ""
 Write-Host " Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
 Write-Host " Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to open Steam game properties..."
 Start-Process "steam://gameproperties/550"
 Pause-User "Press Enter once you have pasted the launch parameters and closed Steam properties..."
}

# -------------------------------------------------------
# STEP 4 (full) / STEP 2 (update): Download and install L4D2VR
# -------------------------------------------------------
if ($updateOnly) {
 Write-Step 2 $totalSteps "Updating L4D2VR (latest release)"
} else {
 Write-Step 4 $totalSteps "Installing L4D2VR (latest release)"
}

# Resolve the latest release asset URL via GitHub API. The author sometimes
# replaces the ZIP under an existing tag without bumping the version, so
# pinning a static URL would miss updates. The API always points at the
# currently-uploaded asset under the latest release tag.
$l4d2vrUrl = $null
$tagName = $null
Write-Host " Querying GitHub for latest release ... " -NoNewline -ForegroundColor White
try {
 $apiResp = Invoke-WebRequest -Uri $GITHUB_API -UseBasicParsing -ErrorAction Stop `
 -Headers @{ "User-Agent"="PCVR-Mods-Hub"; "Accept"="application/vnd.github+json" }
 $release = $apiResp.Content | ConvertFrom-Json
 $tagName = $release.tag_name
 foreach ($asset in $release.assets) {
 if ($asset.name -eq $L4D2VR_ASSET_NAME) {
 $l4d2vrUrl = $asset.browser_download_url
 break
 }
 }
 Write-Host "OK" -ForegroundColor Green
 if ($tagName) { Write-Info "Latest release: $tagName" }
 if (-not $l4d2vrUrl) {
 Write-Fail "Could not find $L4D2VR_ASSET_NAME in the latest release assets."
 Write-Info "Browse releases manually:"
 Write-Info " $GITHUB_RELEASES_URL"
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "mod download" `
 -Url "https://github.com/keyou91/l4d2vr/releases" `
 -Instructions "Open https://github.com/keyou91/l4d2vr/releases in the browser that just opened, download the latest ZIP, place it at '$zipPath' (the installer's temp file), then choose Retry." `
 -SkipMessage "Skipped - the VR mod files were NOT installed." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
 }
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Warn "Could not reach GitHub API: $_"
 Write-Info "Check your internet connection, or download manually from:"
 Write-Info " $GITHUB_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "mod download" `
 -Url "https://github.com/keyou91/l4d2vr/releases" `
 -Instructions "Open https://github.com/keyou91/l4d2vr/releases in the browser, download the latest L4D2VR ZIP and place it at '$zipPath', then choose Retry." `
 -SkipMessage "Skipped - the VR mod files were NOT installed." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

$tempDir = Join-Path $env:TEMP "L4D2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$vrZip = Join-Path $tempDir "L4D2VR.zip"
$vrExtract = Join-Path $tempDir "L4D2VR"

Write-Host " Downloading L4D2VR ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $l4d2vrUrl -OutFile $vrZip -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green

 Write-Host " Extracting ... " -NoNewline -ForegroundColor White
 Expand-Archive -Path $vrZip -DestinationPath $vrExtract -Force

 # Copy all files directly into game root (no subfolder).
 # Payload-verified: releases/LATEST can change its layout any day.
 $vrPayload = Get-ExtractedPayloadRoot -ExtractDir $vrExtract -RelModFile "openvr_api.dll"
 Get-ChildItem -Path $vrPayload | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 $null = Assert-PayloadDelivered -ExtractDir $vrExtract -TargetDir $gamePath -RelModFile "openvr_api.dll" -Label "L4D2VR"
 Write-Host "OK" -ForegroundColor Green
 if ($tagName) {
 Write-OK "L4D2VR $tagName downloaded and extracted!"
 } else {
 Write-OK "L4D2VR downloaded and extracted!"
 }
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download error: $_"
 Write-Info "You can download manually from:"
 Write-Info " $GITHUB_RELEASES_URL"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$vrZip' with 7-Zip or Windows Explorer, and extract its contents into '$vrExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$vrZip" -Parent) `
 -DestFolder "$vrExtract" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # User claims they extracted manually. Re-run extract logic
 # by exiting and forcing re-run (we don't know which archive
 # variable this catch belongs to without context).
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# VR Config Tool
# -------------------------------------------------------
Write-Host ""
Write-Host " Downloaded and extracted." -ForegroundColor Green
Write-Host ""
Write-Host " Would you like to open the VR Mod settings?" -ForegroundColor White
Write-Info " If you change anything, remember to click Save at the top."
Write-Host ""
Write-Host " [Y] Yes, open L4D2VR Config Tool" -ForegroundColor White
Write-Host " [N] No, I am done" -ForegroundColor Gray
Write-Host ""

$choice = ""
while ($choice -notin @("y","n","Y","N")) {
 $choice = (Read-Host " Your choice (Y/N)").Trim()
}

if ($choice -in @("y","Y")) {
 $configTool = Join-Path $gamePath "L4D2VRConfigTool.exe"
 if (Test-Path $configTool) {
 Write-OK "Opening L4D2VR Config Tool..."
 Start-Process $configTool
 } else {
 Write-Warn "L4D2VRConfigTool.exe not found in game folder."
 Write-Info "Expected location: $configTool"
 }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
if ($updateOnly) {
 Write-Host " Update Complete" -ForegroundColor White
 Write-Host ""
 Write-Host " [x] L4D2VR$(if ($tagName) { " $tagName" }) mod files refreshed" -ForegroundColor Green
 Write-Host " [-] Video settings and launch parameters untouched" -ForegroundColor Gray
} else {
 Write-Host " Installation Complete" -ForegroundColor White
 Write-Host ""
 Write-Host " [x] L4D2VR$(if ($tagName) { " $tagName" }) installed" -ForegroundColor Green
 Write-Host " [x] Video settings configured in-game" -ForegroundColor Green
 Write-Host " [x] Launch parameters set in Steam" -ForegroundColor Green
}
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "--- Before You Play ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " - Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host "   starting sometimes out of focus." -ForegroundColor White
Write-Host " - Press LEFT STICK DOWN to recenter camera height." -ForegroundColor White
Write-Host " Aim controller UP or DOWN to show the HUD." -ForegroundColor Gray
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " In SteamVR Dashboard -> Settings:" -ForegroundColor White
Write-Host " Disable 'Present Non-VR Applications on Theater Screen Upon Launch'" -ForegroundColor Gray
Write-Host ""
Write-Host " No Mercy. Dead Center. Now in VR. Good luck, Survivor!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit..."
