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
$l4d2FixtureMode = $env:PCVR_HUB_TEST_MODE -eq '1' -and [bool]$env:PCVR_L4D2_TEST_ROOT
if ($l4d2FixtureMode) {
 $l4d2FixtureRoot = [IO.Path]::GetFullPath($env:PCVR_L4D2_TEST_ROOT)
 $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
 if (-not $l4d2FixtureRoot.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or
     -not (Test-Path -LiteralPath (Join-Path $l4d2FixtureRoot 'l4d2-fixture.txt') -PathType Leaf)) {
  throw 'L4D2 test fixture must stay in an isolated temporary folder.'
 }
}

$LAUNCH_PARAMS = "-heapsize 524288 -processheap -high -novid +crosshair 0 -w 1280 -h 720 +mat_queue_mode 0 +mat_vsync 0 +mat_antialias 0 +mat_grain_scale_override 0"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 try { Clear-Host } catch { }
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

function Test-L4D2VRArchive([string]$Path) {
 if (-not $Path -or -not (Test-DownloadedPayload -Path $Path -IntendedPath 'L4D2VR.zip')) { return $false }
 try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
  $archive = [IO.Compression.ZipFile]::OpenRead($Path)
  try {
   $found = $false
   foreach ($entry in $archive.Entries) {
    $name = $entry.FullName.Replace('/', '\')
    if ($name.StartsWith('\') -or $name -match '(^|\\)\.\.(\\|$)|^[A-Za-z]:') { return $false }
    if ($name -match '(^|\\)openvr_api\.dll$') { $found = $true }
   }
   return $found
  } finally { $archive.Dispose() }
 } catch { return $false }
}

function Find-L4D2VRManualArchive([string]$Destination) {
 $folder = Get-PCVRDownloadsFolder
 if (-not $folder -or -not (Test-Path -LiteralPath $folder -PathType Container)) { return $false }
 foreach ($candidate in @(Get-ChildItem -LiteralPath $folder -Filter 'L4D2VR*.zip' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending)) {
  if (-not (Test-L4D2VRArchive $candidate.FullName)) { continue }
  Write-Host "  Found in your registered Downloads folder: $($candidate.FullName)" -ForegroundColor Cyan
  $choice = ([string](Read-Host '  Use this archive? [Y/N]')).Trim()
  if ($choice -notin @('Y','y')) { continue }
  Copy-Item -LiteralPath $candidate.FullName -Destination $Destination -Force -ErrorAction Stop
  return [bool](Test-L4D2VRArchive $Destination)
 }
 return $false
}

if ($env:PCVR_L4D2_LIBRARY_ONLY -eq '1') { return }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 if ($l4d2FixtureMode) { return (Join-Path $l4d2FixtureRoot 'Steam') }
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

 try { Set-Clipboard -Value $LAUNCH_PARAMS -DeferManualFallback } catch {}

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
 Show-PCVRClipboardManualFallback -Text $LAUNCH_PARAMS
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

# Resolve release metadata when the API is available. GitHub's latest asset
# URL remains usable when its unauthenticated API limit has been reached.
$tempDir = Join-Path $env:TEMP "L4D2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$vrZip = Join-Path $tempDir 'L4D2VR.zip'
$vrExtract = Join-Path $tempDir 'L4D2VR'
$tagName = $null
$assetStamp = $null
$verifiedAssetStamp = $null
$l4d2vrUrl = $null
Write-Info 'Checking the current GitHub release; this can take a few seconds.'
try {
 if ($l4d2FixtureMode) { throw 'API rate limit exceeded (isolated fixture)' }
 $apiResp = Invoke-WebRequest -Uri $GITHUB_API -UseBasicParsing -ErrorAction Stop -TimeoutSec 15 `
  -Headers @{ 'User-Agent'='PCVR-Mods-Hub'; 'Accept'='application/vnd.github+json' }
 $release = $apiResp.Content | ConvertFrom-Json
 foreach ($asset in @($release.assets)) {
  if ($asset.name -eq $L4D2VR_ASSET_NAME) {
   $l4d2vrUrl = [string]$asset.browser_download_url
   $tagName = [string]$release.tag_name
   $assetStamp = [string]$asset.updated_at
   break
  }
 }
 if (-not $l4d2vrUrl) { Write-Warn 'The API release has no L4D2VR.zip asset; trying the direct latest-download URL.' }
} catch {
 Write-Warn "The GitHub API is unavailable ($($_.Exception.Message)). Trying the direct latest-download URL."
}

$latestAssetUrl = 'https://github.com/keyou91/l4d2vr/releases/latest/download/L4D2VR.zip'
$downloaded = $false
try {
 foreach ($url in @($l4d2vrUrl,$latestAssetUrl) | Where-Object { $_ } | Select-Object -Unique) {
  Write-Info 'Downloading L4D2VR; this may take several minutes.'
  try {
   if ($l4d2FixtureMode) { throw 'Direct asset unavailable (isolated fixture)' }
   Invoke-WebRequest -Uri $url -OutFile $vrZip -UseBasicParsing -ErrorAction Stop -TimeoutSec 120
   if (-not (Test-L4D2VRArchive $vrZip)) { throw 'The response is not a usable L4D2VR ZIP.' }
   $downloaded = $true
   if ($l4d2vrUrl -and $url -eq $l4d2vrUrl -and $assetStamp) { $verifiedAssetStamp = $assetStamp }
   Write-OK 'Downloaded the L4D2VR ZIP.'
   break
  } catch { Write-Warn "Direct download failed: $($_.Exception.Message)" }
 }
 if (-not $downloaded) {
  $registeredDownloads = Get-PCVRDownloadsFolder
  Write-Warn 'Automatic download did not complete. The installer can search your registered Downloads folder or take a dropped file.'
  if ($registeredDownloads) { Write-Info "Registered Downloads folder: $registeredDownloads" }
  $retryCheck = {
   if (Test-L4D2VRArchive $vrZip) { return $true }
   return (Find-L4D2VRManualArchive -Destination $vrZip)
  }
  $fallbackPage = if ($l4d2FixtureMode) { '' } else { $GITHUB_RELEASES_URL }
  $fallback = Invoke-InstallerFallback -Action 'mod download' -Url $fallbackPage `
   -DestFile $vrZip -FileValidator { param($candidate) Test-L4D2VRArchive $candidate } `
   -RetryCheck $retryCheck -AllowSkip $false
  if ($fallback -ne 'retry' -or -not (Test-L4D2VRArchive $vrZip)) {
   throw 'No usable L4D2VR ZIP was selected.'
  }
 }

 Write-Info 'Extracting and copying the mod; this may take several minutes.'
 Expand-Archive -LiteralPath $vrZip -DestinationPath $vrExtract -Force -ErrorAction Stop
 $vrPayload = Get-ExtractedPayloadRoot -ExtractDir $vrExtract -RelModFile 'openvr_api.dll'
 Get-ChildItem -LiteralPath $vrPayload | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $gamePath -Recurse -Force -ErrorAction Stop
 }
 $null = Assert-PayloadDelivered -ExtractDir $vrExtract -TargetDir $gamePath -RelModFile 'openvr_api.dll' -Label 'L4D2VR'
 if ($tagName) { Write-OK "L4D2VR $tagName downloaded and extracted!" }
 else { Write-OK 'L4D2VR downloaded and extracted!' }
} finally {
 if (Test-Path -LiteralPath $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
}

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
# Rolling-release source of truth: this repo can replace L4D2VR.zip under
# the same tag, so the Hub compares the asset's updated_at timestamp rather
# than tag_name. Record that exact timestamp beside the installed payload.
if ($verifiedAssetStamp) {
 Save-InstalledStamp -GameDir $gamePath -Version $verifiedAssetStamp -HubDir $PSScriptRoot
} else {
 # A direct latest redirect or user-selected ZIP has no proof of the API
 # asset's updated_at value. Keep the working mod, but do not claim that
 # the current online build was installed or retain an older false receipt.
 foreach ($receipt in @((Join-Path $gamePath '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_version'))) {
  Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
 }
 Write-Warn 'The mod files are installed, but this download has no verified release timestamp. The Hub cannot confirm the update version yet.'
}

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
