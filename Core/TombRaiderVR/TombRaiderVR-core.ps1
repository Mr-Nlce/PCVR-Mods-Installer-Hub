# -------------------------------------------------------
# Tomb Raider 1 VR (BeefRaiderXR) Installer
# by Team Beef Studios - GitHub release distribution
#
# Walks the user through:
# 1. .NET 7.0 Desktop Runtime check + install
# 2. 7-Zip check + install (needed to extract the .7z release)
# 3. BeefRaiderXR-1.0.0.7z download from GitHub releases
# 4. Extraction to C:\games\Tomb Raider VR (or user-chosen path)
# 5. SauronDesktop.exe launch for asset extraction from the
# user's Steam/GoG Tomb Raider 1 OR TR I-III Remastered
# 6. Desktop shortcut to BeefRaiderXR.exe
#
# This is NOT a typical VR mod - it's a Team Beef OpenXR port of
# XProger's OpenLara engine. The user must own one of:
# - Tomb Raider I (1996) on Steam (AppID 224960) or GoG
# - Tomb Raider I-III Remastered (AppID 2478970) on Steam
# ...because SauronDesktop extracts the level/texture data from
# whichever install it finds. The port itself ships no copyrighted
# game assets.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "BeefRaiderXR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Team Beef Studios"

$RELEASE_URL = "https://github.com/Team-Beef-Studios/BeefRaiderXR/releases/download/1.0.0/BeefRaiderXR-1.0.0.7z"
$INFO_URL = "https://github.com/Team-Beef-Studios/BeefRaiderXR"

# .NET 7.0.20 Desktop Runtime (x64) - SauronDesktop.exe will refuse
# to start without it. Microsoft direct download (no auth, public).
# IMPORTANT: do NOT add a hardcoded download.visualstudio.microsoft.com
# URL with version GUIDs here. Microsoft rotates those CDN URLs whenever
# they ship a .NET 7 servicing update, so any hardcoded one is fragile
# and will eventually return HTTP 400. aka.ms is Microsoft's official
# stable redirect that always resolves to the current 7.0 x64 desktop
# runtime - that's the only URL we trust.
$DOTNET_FILE = "windowsdesktop-runtime-7.0-x64.exe"

# 7-Zip console installer (used only as a last resort if user has no
# 7-Zip GUI either). Verified URL from the 7-zip.org download page.
$SEVENZIP_URL = "https://www.7-zip.org/a/7z2409-x64.exe"

$DEFAULT_INSTALL_DIR = "C:\games\Tomb Raider VR"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host " Tomb Raider 1 VR (BeefRaiderXR) Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host ""
}

function Write-Step {
 param([int]$Step, [int]$Total, [string]$Title)
 Write-Host ""
 Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
 Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# -------------------------------------------------------
# Detection helpers
# -------------------------------------------------------
function Test-DotNet7Desktop {
 # `dotnet --list-runtimes` lists installed runtimes one per line.
 # We need a Microsoft.WindowsDesktop.App 7.x.y entry.
 try {
 $out = & dotnet --list-runtimes 2>$null
 if ($LASTEXITCODE -eq 0 -and $out) {
 foreach ($line in $out) {
 if ($line -match '^Microsoft\.WindowsDesktop\.App\s+7\.') {
 return $true
 }
 }
 }
 } catch { }
 return $false
}

function Find-SevenZipExe {
 # Common 7-Zip install locations. Returns first-found 7z.exe
 # path, or $null. We check PATH last so the user's installed
 # GUI version takes priority over a stray copy in PATH.
 $candidates = @(
 "$env:ProgramFiles\7-Zip\7z.exe",
 "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
 "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
 )
 foreach ($c in $candidates) {
 if ($c -and (Test-Path $c)) { return $c }
 }
 try {
 $where = (Get-Command 7z.exe -ErrorAction Stop).Source
 if ($where -and (Test-Path $where)) { return $where }
 } catch { }
 return $null
}

# -------------------------------------------------------
# Tomb Raider source detection
# Looks for any of:
# - Tomb Raider I (1996) on Steam, folder "Tomb Raider (I)",
# AppID 224960 (verified via Steam community + dosgamers.com)
# - Tomb Raider I-III Remastered on Steam, folder
# "Tomb Raider I-III Remastered", AppID 2478970
# (verified via Steam forum + OpenLara discussion - the TR1
# data lives in <RemasteredFolder>\1\ subfolder, which is
# exactly what SauronDesktop needs)
# - Tomb Raider 1 on GoG, product ID 1207663463 (gogdb.org)
# - Tomb Raider 1+2+3 GoG bundle, product ID 1207659052
# - Tomb Raider I-III Remastered on GoG, product ID 1407750955
# We don't need the path - just count what's there so the user
# knows whether SauronDesktop will find something later.
# -------------------------------------------------------
function Find-TombRaiderSource {
 . "$PSScriptRoot\..\Utils\GameDetection.ps1"
 $sources = @()

 # TR1 (1996) Steam - verified folder name "Tomb Raider (I)"
 $tr1 = Find-GameInstall -GameName "Tomb Raider I (1996)" `
 -Steam @{ AppID = "224960"; Folder = "Tomb Raider (I)" } `
 -Gog @{ GameID = "1207663463" }
 if ($tr1.Found) { $sources += "$($tr1.Source): $($tr1.Path)" }

 # TR1+2+3 GoG bundle - sometimes installed by users who want
 # multiple TR classics; same TOMBRAID data structure.
 $trBundle = Find-GameInstall -GameName "Tomb Raider 1+2+3 (GoG)" `
 -Gog @{ GameID = "1207659052" }
 if ($trBundle.Found) { $sources += "$($trBundle.Source): $($trBundle.Path)" }

 # TR I-III Remastered (2024) - verified folder name
 # "Tomb Raider I-III Remastered" (no parentheses). TR1
 # asset data sits in the \1\ subfolder of this install,
 # which SauronDesktop reads.
 $trR = Find-GameInstall -GameName "Tomb Raider I-III Remastered" `
 -Steam @{ AppID = "2478970"; Folder = "Tomb Raider I-III Remastered" } `
 -Gog @{ GameID = "1407750955" }
 if ($trR.Found) { $sources += "$($trR.Source): $($trR.Path)" }

 return $sources
}

# -------------------------------------------------------
# Downloads
# -------------------------------------------------------
function Download-File {
 param([string]$Url, [string]$Destination, [string]$Label)
 # Try direct URL, then web archive mirror. Callers loop over multiple
 # primary URLs and own the interactive fallback - we just add the
 # mirror tier here so each call gets a free second chance.
 $sources = @($Url)
 if ($Url -notmatch '^https?://web\.archive\.org/') {
   $sources += "https://web.archive.org/web/0/$Url"
 }
 foreach ($u in $sources) {
   Write-Info "Downloading $Label..."
   Write-Host " From : $u" -ForegroundColor DarkGray
   Write-Host " To   : $Destination" -ForegroundColor DarkGray
   try {
     $ProgressPreference = "SilentlyContinue"
     Invoke-WebRequest -Uri $u -OutFile $Destination -UseBasicParsing -ErrorAction Stop
     $ProgressPreference = "Continue"
     if (Test-Path $Destination) {
       $sz = (Get-Item $Destination).Length
       if ($sz -gt 0) {
         Write-OK "Downloaded ($([math]::Round($sz/1MB,2)) MB)"
         return $true
       }
     }
   } catch {
     Write-Fail "Source failed: $($_.Exception.Message)"
   }
 }
 return $false
}

# =======================================================
# INSTALLER FLOW
# =======================================================
Write-Header

Write-Host " This installer sets up BeefRaiderXR, a Team Beef VR port" -ForegroundColor White
Write-Host " of the original Tomb Raider (1996) built on the OpenLara" -ForegroundColor White
Write-Host " engine by XProger. It requires:" -ForegroundColor White
Write-Host ""
Write-Host " 1. .NET 7.0 Desktop Runtime (for the asset extractor)" -ForegroundColor Gray
Write-Host " 2. 7-Zip (to extract the release archive)" -ForegroundColor Gray
Write-Host " 3. An installed copy of one of:" -ForegroundColor Gray
Write-Host " - Tomb Raider I (1996) on Steam or GoG" -ForegroundColor DarkGray
Write-Host " - Tomb Raider I-III Remastered on Steam or GoG" -ForegroundColor DarkGray
Write-Host ""
Write-Host " The port itself ships NO copyrighted Tomb Raider assets." -ForegroundColor White
Write-Host " SauronDesktop extracts the levels/textures from whichever" -ForegroundColor White
Write-Host " copy you own at the end of this installer." -ForegroundColor White
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# STEP 1: Detect Tomb Raider source
# -------------------------------------------------------
Write-Step 1 6 "Looking for an installed Tomb Raider"

$sources = Find-TombRaiderSource
if ($sources.Count -gt 0) {
 foreach ($s in $sources) { Write-OK $s }
} else {
 Write-Warn "No Tomb Raider 1 install detected on this PC."
 Write-Host " SauronDesktop may say 'Game not found' later - that's fine," -ForegroundColor Gray
 Write-Host " you can still click 'Extract Files' and the port will run." -ForegroundColor Gray
 Write-Host " But ideally install one of these first:" -ForegroundColor Gray
 Write-Host " - Tomb Raider I (1996) on Steam, AppID 224960" -ForegroundColor DarkGray
 Write-Host " - Tomb Raider I-III Remastered, AppID 2478970" -ForegroundColor DarkGray
 Write-Host " - Tomb Raider 1 from GoG" -ForegroundColor DarkGray
}
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# STEP 2: .NET 7 Desktop Runtime
# -------------------------------------------------------
Write-Step 2 6 ".NET 7.0 Desktop Runtime check"

if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime is already installed."
} else {
 Write-Warn ".NET 7 Desktop Runtime not found."
 Write-Host " SauronDesktop.exe requires it. We'll try to download and" -ForegroundColor Gray
 Write-Host " install it now (~58 MB). The installer window may pop up." -ForegroundColor Gray
 Pause-User "Press Enter to start the .NET install..."

 $tmpDir = Join-Path $env:TEMP "TombRaiderVR_install"
 New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
 $dotnetInstaller = Join-Path $tmpDir $DOTNET_FILE

 # Multiple stable download sources in priority order. .NET 7 is
 # end-of-life as of May 2024 (final version 7.0.20), so the version
 # URLs are now frozen and safe to hardcode. aka.ms is Microsoft's
 # official stable redirect (primary). builds.dotnet.microsoft.com
 # is the secondary CDN path (Chocolatey + winget both use this).
 # winget is the last resort. Hard abort is forbidden here.
 $dotnetSources = @(
 @{ Url = "https://aka.ms/dotnet/7.0/windowsdesktop-runtime-win-x64.exe";
 Label = ".NET 7 Desktop Runtime (Microsoft aka.ms stable redirect)" }
 @{ Url = "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/7.0.20/windowsdesktop-runtime-7.0.20-win-x64.exe";
 Label = ".NET 7.0.20 Desktop Runtime (Microsoft builds CDN, EOL-frozen)" }
 )

 $downloaded = $false
 foreach ($src in $dotnetSources) {
 Write-Info "Trying: $($src.Label)"
 if (Download-File -Url $src.Url -Destination $dotnetInstaller -Label $src.Label) {
 $downloaded = $true
 break
 }
 Write-Warn "Source failed, trying next..."
 }

 # Last-ditch: winget if the user has it (Windows 10 1809+ / 11)
 if (-not $downloaded) {
 $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
 if ($winget) {
 Write-Info "Trying winget as a last-resort source..."
 try {
 $wp = Start-Process -FilePath "winget.exe" `
 -ArgumentList "install","--id","Microsoft.DotNet.DesktopRuntime.7", `
 "--silent","--accept-package-agreements", `
 "--accept-source-agreements" `
 -Wait -PassThru -NoNewWindow
 Start-Sleep -Seconds 2
 if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime installed via winget."
 Pause-User "Press Enter to continue..."
 # Skip the regular installer code path below by
 # marking as already handled.
 $downloaded = "winget-handled"
 }
 } catch {
 Write-Warn "winget attempt failed: $($_.Exception.Message)"
 }
 }
 }

 if ($downloaded -eq $true) {
 Write-Host ""
 Write-Host "  A Windows User Account Control (UAC) prompt will appear." -ForegroundColor Yellow
 Write-Host "  Click 'Yes' to allow the .NET 7 Runtime to install." -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to launch the .NET installer..."
 Write-Info "Running the .NET 7 Desktop Runtime installer..."
 Write-Host "  (A progress window will open. Wait for it to close.)" -ForegroundColor Gray
 try {
 # Use /passive instead of /quiet so the user sees a progress
 # bar - /quiet shows NOTHING and looks like a hang. UAC must
 # still be confirmed but at least the user can see something
 # is happening once they click Yes.
 Start-Process -FilePath $dotnetInstaller `
 -ArgumentList "/install","/passive","/norestart" -Wait
 Start-Sleep -Seconds 2
 if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime installed."
 } else {
 Write-Warn ".NET runtime install command completed but detection still fails."
 Write-Host " You may need to reboot, or run the installer manually:" -ForegroundColor Gray
 Write-Host " $dotnetInstaller" -ForegroundColor DarkGray
 }
 } catch {
 Write-Fail ".NET installer threw: $($_.Exception.Message)"
 Write-Host "  If you cancelled the UAC prompt, you can run it manually:" -ForegroundColor Gray
 Write-Host "  $dotnetInstaller" -ForegroundColor DarkGray
 }
 } elseif ($downloaded -ne "winget-handled") {
 # All automatic options exhausted. Offer a manual fallback
 # path instead of exiting - the user can install .NET 7
 # themselves and resume the rest of this installer.
 Write-Host ""
 Write-Host " All automatic .NET 7 download sources failed." -ForegroundColor Yellow
 Write-Host " This usually happens when Microsoft rotates their CDN" -ForegroundColor Gray
 Write-Host " storage hashes faster than this installer is updated." -ForegroundColor Gray
 Write-Host ""
 Write-Host " MANUAL FALLBACK:" -ForegroundColor White
 Write-Host " 1. Open this page in your browser:" -ForegroundColor White
 Write-Host " https://dotnet.microsoft.com/download/dotnet/7.0" -ForegroundColor Cyan
 Write-Host " 2. Under '.NET Desktop Runtime 7.0.x', click the" -ForegroundColor White
 Write-Host " 'x64' download link for Windows." -ForegroundColor White
 Write-Host " 3. Run the downloaded .exe to install." -ForegroundColor White
 Write-Host " 4. Come back here and press [R] to retry, or [S]" -ForegroundColor White
 Write-Host " to skip and continue without it (TR1 won't launch)." -ForegroundColor White
 Write-Host ""
 # Try to open the page in the default browser
 try { Start-Process "https://dotnet.microsoft.com/download/dotnet/7.0" } catch { }

 $choice = ""
 while ($choice -notin @("r","R","s","S","q","Q")) {
 Write-Host " [R]etry detection / [S]kip and continue / [Q]uit installer" -ForegroundColor Yellow
 $choice = (Read-Host " Your choice").Trim()
 if ($choice -in @("r","R")) {
 if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime detected. Continuing."
 break
 } else {
 Write-Warn "Still not detected. Did the install finish?"
 $choice = ""
 }
 } elseif ($choice -in @("s","S")) {
 Write-Warn "Continuing without .NET 7. TR1 won't launch until you install it."
 break
 } elseif ($choice -in @("q","Q")) {
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action ".NET runtime download" `
 -Url "https://dotnet.microsoft.com/download/dotnet/7.0" `
 -Instructions "Install .NET 7 Desktop Runtime manually from https://dotnet.microsoft.com/download/dotnet/7.0 (x64 build)." `
 -SkipMessage "Skipped - the tool that needs .NET will not run; you can install .NET later and re-run." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-detect .NET 7 Desktop Runtime
 if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime detected."
 } else {
 Pause-User "Still no .NET 7. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
 }
 }
 }
}
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# STEP 3: 7-Zip check + optional install
# -------------------------------------------------------
Write-Step 3 6 "7-Zip check"

$sevenZip = Find-SevenZipExe
if ($sevenZip) {
 Write-OK "7-Zip found at: $sevenZip"
} else {
 Write-Warn "7-Zip not found."
 Write-Host " The BeefRaiderXR release is a .7z archive, so we need" -ForegroundColor Gray
 Write-Host " 7-Zip to extract it. Install it now? (~1.6 MB)" -ForegroundColor Gray
 Write-Host ""
 Write-Host " >>> [Y] Yes, download and install 7-Zip silently" -ForegroundColor Yellow
 Write-Host " >>> [N] I'll install it myself - exit and re-run later" -ForegroundColor Yellow
 Write-Host ""
 $do7z = ""
 while ($do7z -notin @("y","Y","n","N")) {
 $do7z = (Read-Host " Your choice (Y/N)").Trim()
 }
 if ($do7z -in @("n","N")) {
 Write-Info "Install 7-Zip from https://www.7-zip.org/ and re-run this installer."
 Pause-User "Press Enter to exit..."
 exit 0
 }

 $tmpDir = Join-Path $env:TEMP "TombRaiderVR_install"
 New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
 $sevenZipInstaller = Join-Path $tmpDir "7z-installer.exe"

 if (Download-File -Url $SEVENZIP_URL -Destination $sevenZipInstaller -Label "7-Zip installer") {
 Write-Info "Running 7-Zip installer (silent)..."
 try {
 Start-Process -FilePath $sevenZipInstaller -ArgumentList "/S" -Wait
 Start-Sleep -Seconds 2
 $sevenZip = Find-SevenZipExe
 if ($sevenZip) {
 Write-OK "7-Zip installed at: $sevenZip"
 } else {
 Write-Fail "7-Zip install finished but 7z.exe still not found."
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "7-Zip detection" `
 -Url "https://www.7-zip.org" `
 -Instructions "Install 7-Zip from https://www.7-zip.org and re-run this installer, OR extract the .7z manually using any 7z-capable tool." `
 -SkipMessage "Skipped - cannot extract .7z archives; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check 7-Zip availability
 $sevenZipNow = $null
 foreach ($c in @("C:\Program Files\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe", "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe")) {
 if (Test-Path $c) { $sevenZipNow = $c; break }
 }
 if ($sevenZipNow) {
 Write-OK "7-Zip detected at: $sevenZipNow"
 } else {
 Pause-User "Still no 7-Zip detected. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
 }
 } catch {
 Write-Fail "7-Zip installer threw: $($_.Exception.Message)"
 $__fb = Invoke-InstallerFallback -Action "7-Zip detection" `
 -Url "https://www.7-zip.org" `
 -Instructions "Install 7-Zip from https://www.7-zip.org and re-run this installer, OR extract the .7z manually using any 7z-capable tool." `
 -SkipMessage "Skipped - cannot extract .7z archives; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check 7-Zip availability
 $sevenZipNow = $null
 foreach ($c in @("C:\Program Files\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe", "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe")) {
 if (Test-Path $c) { $sevenZipNow = $c; break }
 }
 if ($sevenZipNow) {
 Write-OK "7-Zip detected at: $sevenZipNow"
 } else {
 Pause-User "Still no 7-Zip detected. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
 }
 } else {
 Write-Fail "Could not download 7-Zip. Aborting."
 $__fb = Invoke-InstallerFallback -Action "7-Zip detection" `
 -Url "https://www.7-zip.org" `
 -Instructions "Install 7-Zip from https://www.7-zip.org and re-run this installer, OR extract the .7z manually using any 7z-capable tool." `
 -SkipMessage "Skipped - cannot extract .7z archives; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check 7-Zip availability
 $sevenZipNow = $null
 foreach ($c in @("C:\Program Files\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe", "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe")) {
 if (Test-Path $c) { $sevenZipNow = $c; break }
 }
 if ($sevenZipNow) {
 Write-OK "7-Zip detected at: $sevenZipNow"
 } else {
 Pause-User "Still no 7-Zip detected. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
 }
}
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# STEP 4: Pick install destination
# -------------------------------------------------------
Write-Step 4 6 "Choose install destination"

Write-Host " Default location: $DEFAULT_INSTALL_DIR" -ForegroundColor White
Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor Gray
Write-Host " library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor Gray
Write-Host ""
Write-Host " >>> [Enter] Use the default" -ForegroundColor Yellow
Write-Host " >>> Or type/paste a different folder path" -ForegroundColor Yellow
Write-Host ""
$customPath = (Read-Host " Install folder").Trim().Trim('"')
if (-not $customPath) {
 $installDir = $DEFAULT_INSTALL_DIR
} else {
 $installDir = $customPath
}
Write-Info "Will install to: $installDir"

# Create the install folder up front so the 7-Zip extraction has a
# target. -Force is fine because if it already exists we just reuse
# the directory (the extraction will overwrite the BeefRaiderXR
# files inside).
try {
 New-Item -ItemType Directory -Path $installDir -Force | Out-Null
} catch {
 Write-Fail "Could not create $installDir : $($_.Exception.Message)"
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$installDir' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
 -SkipMessage "Skipped - no install folder; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Retry folder create
 try {
 if (-not (Test-Path $gameDir)) {
 New-Item -ItemType Directory -Path $gameDir -Force -ErrorAction Stop | Out-Null
 }
 Write-OK "Folder ready: $gameDir"
 } catch {
 Pause-User "Still cannot create folder. Choose a different path then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# STEP 5: Download + extract BeefRaiderXR release
# -------------------------------------------------------
Write-Step 5 6 "Download + extract BeefRaiderXR-1.0.0.7z"

$tmpDir = Join-Path $env:TEMP "TombRaiderVR_install"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$releaseArchive = Join-Path $tmpDir "BeefRaiderXR-1.0.0.7z"

if (Test-Path $releaseArchive) {
 Write-Info "Release archive already in cache: $releaseArchive"
} else {
 if (-not (Download-File -Url $RELEASE_URL -Destination $releaseArchive -Label "BeefRaiderXR-1.0.0.7z")) {
 $__fb = Invoke-InstallerFallback -Action "BeefRaiderXR download" `
 -Url "https://github.com/Team-Beef-Studios/BeefRaiderXR/releases" `
 -Instructions "Open the GitHub page that just opened, download BeefRaiderXR-1.0.0.7z manually, then place it in '$tmpDir' (folder will be created), and choose Retry." `
 -SkipMessage "Skipped - mod files cannot be installed; Tomb Raider will launch flat. Re-run when you have a working connection." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Retry: re-check if user dropped the file into tmpDir manually
 if (Test-Path $releaseArchive) {
 Write-OK "Found manually placed archive: $releaseArchive"
 } else {
 Pause-User "Archive still missing - please re-run installer once it is in place. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
 }
}

Write-Info "Extracting into $installDir ..."
$extractOk = $false
try {
 & $sevenZip x -y "-o$installDir" $releaseArchive | Out-Null
 if ($LASTEXITCODE -eq 0) {
 Write-OK "Extraction complete (7-Zip)."
 $extractOk = $true
 } else {
 Write-Warn "7-Zip extraction returned code $LASTEXITCODE."
 }
} catch {
 Write-Warn "7-Zip threw: $($_.Exception.Message)"
}

# Auto-fallback chain: if 7-Zip failed, try the built-in Expand-Archive
# (works for ZIP, fails for 7z, but worth a shot in case the user
# replaced the .7z with a manually-converted .zip). Only after both
# automatic methods fail do we fall back to interactive prompt.
if (-not $extractOk) {
 Write-Info "Trying PowerShell built-in extractor as a fallback..."
 try {
 Expand-Archive -Path $releaseArchive -DestinationPath $installDir -Force -ErrorAction Stop
 Write-OK "Extraction complete (PowerShell Expand-Archive)."
 $extractOk = $true
 } catch {
 Write-Warn "Built-in extractor also failed: $($_.Exception.Message)"
 }
}

if (-not $extractOk) {
 Write-Fail "All automatic extraction methods failed."
 $__fb = Invoke-InstallerFallback -Action "BeefRaiderXR archive extraction" `
 -Url "https://www.7-zip.org/" `
 -Instructions "Open '$releaseArchive' manually with 7-Zip (right-click -> 7-Zip -> Extract Here, or use the 7-Zip GUI) and extract all contents into '$installDir'. After that, choose Retry so we can verify and continue." `
 -SkipMessage "Skipped - mod files are NOT extracted; the next steps will likely fail." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Verify the user did the manual extraction by looking for any
 # BeefRaiderXR file under the install folder.
 $check = Get-ChildItem -Path $installDir -Recurse -Filter "SauronDesktop.exe" -EA SilentlyContinue | Select-Object -First 1
 if ($check) {
 Write-OK "Manual extraction verified - found SauronDesktop.exe."
 $extractOk = $true
 } else {
 Pause-User "Still no SauronDesktop.exe found inside $installDir. Press Enter to exit and re-run installer..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

# Locate SauronDesktop.exe inside the install. The 7z archive
# layout is:
# <installDir>\BeefRaiderExtractionTool\SauronDesktop.exe
# <installDir>\BeefRaiderExtractionTool\BeefRaiderXR\BeefRaiderXR.exe (after SauronDesktop runs)
# We test the documented path first, then fall back to a recursive
# scan in case the archive layout changes in a future release.
$sauron = Join-Path $installDir "BeefRaiderExtractionTool\SauronDesktop.exe"
if (-not (Test-Path $sauron)) {
 $found = Get-ChildItem -Path $installDir -Recurse -Filter "SauronDesktop.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
 if ($found) { $sauron = $found.FullName }
}
if (-not (Test-Path $sauron)) {
 Write-Fail "Could not find SauronDesktop.exe after extraction."
 $__fb = Invoke-InstallerFallback -Action "SauronDesktop.exe detection" `
 -Url "https://github.com/Team-Beef-Studios/BeefRaiderXR/releases" `
 -Instructions "The BeefRaiderXR archive did not produce SauronDesktop.exe inside '$installDir'. Open the archive page that opened in your browser, download v1.0.0 again (might be a corrupted local copy), extract the 7z manually into '$installDir', then choose Retry. SauronDesktop.exe should live in '$installDir\BeefRaiderExtractionTool\'." `
 -SkipMessage "Skipped - the asset extractor is unavailable; the game will not be VR-ready." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-scan after manual fix
 $sauron = Join-Path $installDir "BeefRaiderExtractionTool\SauronDesktop.exe"
 if (-not (Test-Path $sauron)) {
 $found = Get-ChildItem -Path $installDir -Recurse -Filter "SauronDesktop.exe" -EA SilentlyContinue | Select-Object -First 1
 if ($found) { $sauron = $found.FullName }
 }
 if (-not (Test-Path $sauron)) {
 Pause-User "Still no SauronDesktop.exe. Press Enter to exit..."
 exit 1
 }
 Write-OK "SauronDesktop.exe found at: $sauron"
 }
 # User chose Skip - continue at own risk
}
Write-OK "SauronDesktop.exe ready: $sauron"

# -------------------------------------------------------
# STEP 6: Run SauronDesktop + create shortcut
# -------------------------------------------------------
Write-Step 6 6 "Asset extraction via SauronDesktop"

Write-Host ""
Write-Host " IMPORTANT - what to do in SauronDesktop:" -ForegroundColor Yellow
Write-Host " ----------------------------------------" -ForegroundColor Yellow
Write-Host " Windows may show a SmartScreen warning. SauronDesktop is" -ForegroundColor White
Write-Host " unsigned but safe (Team Beef GitHub release)." -ForegroundColor White
Write-Host " -> Click 'More info'" -ForegroundColor Gray
Write-Host " -> Click 'Run anyway'" -ForegroundColor Gray
Write-Host ""
Write-Host " Inside the SauronDesktop window:" -ForegroundColor White
Write-Host " 1. Click 'Locate from Steam Install'" -ForegroundColor Gray
Write-Host " (the button BELOW the manual path field)" -ForegroundColor DarkGray
Write-Host " 2. It may say 'Game not found' - that's OK. Ignore it." -ForegroundColor Gray
Write-Host " 3. A bit below is the 'Tomb Raider Version' section." -ForegroundColor Gray
Write-Host " 4. Click 'Extract Files'. Watch the right pane for progress." -ForegroundColor Gray
Write-Host " ('DATA Folder: Missing Files (21 of 22 found)' warning" -ForegroundColor DarkGray
Write-Host " is harmless - the port still runs fine.)" -ForegroundColor DarkGray
Write-Host " 5. Optional: click 'Download Audio Tracks' for the OST." -ForegroundColor Gray
Write-Host " 6. Close SauronDesktop when done." -ForegroundColor Gray
Pause-User "Press Enter to start SauronDesktop now..."

try {
 # Run SauronDesktop *in* its own folder so its relative paths
 # behave (it creates a sibling BeefRaiderXR\ folder).
 $sauronDir = Split-Path -Parent $sauron
 Start-Process -FilePath $sauron -WorkingDirectory $sauronDir -Wait
 Write-OK "SauronDesktop closed."
} catch {
 Write-Warn "Could not start SauronDesktop: $($_.Exception.Message)"
 Write-Host " Run it manually: $sauron" -ForegroundColor Gray
}

# After SauronDesktop runs, BeefRaiderXR.exe should sit in a
# subfolder named BeefRaiderXR inside the install root.
$gameExe = Join-Path (Split-Path -Parent $sauron) "BeefRaiderXR\BeefRaiderXR.exe"
if (-not (Test-Path $gameExe)) {
 $found = Get-ChildItem -Path $installDir -Recurse -Filter "BeefRaiderXR.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
 if ($found) { $gameExe = $found.FullName }
}

# -------------------------------------------------------
# Desktop shortcut (only games not launched via Steam get
# one per the hub policy - this game runs from C:\games).
# -------------------------------------------------------
if (Test-Path $gameExe) {
 Write-OK "Game executable: $gameExe"
 try {
 $desktop = [Environment]::GetFolderPath("Desktop")
 $shortcutPath = Join-Path $desktop "Tomb Raider VR.lnk"
 $sc = New-DesktopShortcut -LnkPath $shortcutPath -TargetPath $gameExe -WorkingDir Split-Path -Parent $gameExe -IconPath "$gameExe,0"
 Write-OK "Desktop shortcut created: Tomb Raider VR.lnk"
 } catch {
 Write-Warn "Could not create desktop shortcut: $($_.Exception.Message)"
 }
} else {
 Write-Warn "BeefRaiderXR.exe not found - did SauronDesktop finish?"
 Write-Host " You can re-run SauronDesktop from: $sauron" -ForegroundColor Gray
}

# Persist the install path so the hub's Check-Installed feature
# picks up this non-Steam install location next time. We record
# the BeefRaiderXR subfolder (where the EXE actually lives) rather
# than the parent install dir - the hub uses .installed_path as
# WorkingDirectory at launch time, and BeefRaiderXR.exe needs to
# run with its own folder as CWD. The hub will write
# .installed_version on its own first scan (normalized to match
# Get-ModVersionFromString output - we MUST NOT write it here
# with a "v" prefix or the version compare will treat it as
# permanently out-of-date).
try {
 $beefRaiderFolder = Split-Path -Parent $gameExe
 if (-not $beefRaiderFolder -or -not (Test-Path $beefRaiderFolder)) {
 # Fallback if gameExe wasn't resolved (SauronDesktop didn't run).
 # The 7z archive extracts a BeefRaiderExtractionTool folder
 # containing SauronDesktop.exe, and SauronDesktop creates a
 # BeefRaiderXR folder inside that with the actual game EXE.
 $beefRaiderFolder = Join-Path $installDir "BeefRaiderExtractionTool\BeefRaiderXR"
 }
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $beefRaiderFolder -Encoding UTF8 -Force
 # Clean up any stale .installed_version left by an older
 # buggy version of this installer (which wrote "v1.0.0" while
 # the hub expects "1.0.0"). Removing it lets the hub's first
 # scan rewrite it correctly.
 $verFile = Join-Path $PSScriptRoot ".installed_version"
 if (Test-Path $verFile) { Remove-Item $verFile -Force -EA SilentlyContinue }
} catch { }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Tomb Raider 1 VR install complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Lost city. Stolen artifact. Same Lara, new dimension." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
