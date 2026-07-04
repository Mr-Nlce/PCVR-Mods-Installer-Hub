# -------------------------------------------------------
# Half-Life 2: VR Mod - Unleashed (HL2VRU) Installer
# by Vittorio Romeo - GitHub release distribution
#
# This is an ADD-ON installer that extends an existing
# Half-Life 2: VR Mod (HL2VR) installation. It is NOT a
# standalone VR conversion - the base HL2VR mod MUST be
# installed first via Steam (AppID 658920).
#
# HL2VRU works with all three SourceVR-team HL2VR titles
# (base + Episode 1 + Episode 2). They all share the same
# Steam folder (`Half-Life 2 VR`), so this installer is
# invoked the same way from each card's "Install Unleashed
# add-on" button.
#
# Walks the user through:
# 1. Detect Steam library + HL2VR install folder
# 2. Refuse to proceed if HL2VR is missing
# 3. 7-Zip check + install (needed to extract the .7z release)
# 4. HL2VRU_0.0.7.7z download from GitHub releases
# 5. Extract directly on top of the HL2VR folder
# 6. Write .installed_path so the hub recognises the add-on
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "HL2VRU"
$MOD_VERSION = "v0.0.7"
$MOD_AUTHOR = "Vittorio Romeo"

$RELEASE_URL = "https://github.com/vittorioromeo/HL2VRU/releases/download/v0.0.7/HL2VRU_0.0.7.7z"
$ARCHIVE_NAME = "HL2VRU_0.0.7.7z"
$INFO_URL = "https://github.com/vittorioromeo/HL2VRU"

$BASE_APPID = "658920"
$BASE_FOLDERNAME = "Half-Life 2 VR"

# 7-Zip console installer (used only as a last resort if user has no
# 7-Zip GUI either). Verified URL from the 7-zip.org download page.
$SEVENZIP_URL = "https://www.7-zip.org/a/7z2409-x64.exe"

# -------------------------------------------------------
# Helpers (match the style of other installers in the hub)
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host ""
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " HL2VRU (Half-Life 2 VR - Unleashed) Add-on Installer" -ForegroundColor Cyan
 Write-Host " by $MOD_AUTHOR" -ForegroundColor Cyan
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$total,$txt)
 Write-Host ""
 Write-Host "--- [$n/$total] $txt ---" -ForegroundColor Cyan
 Write-Host ""
}
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " HL2VRU 'Unleashed' is a community add-on for the official" -ForegroundColor White
Write-Host " Half-Life 2: VR Mod. It adds:" -ForegroundColor White
Write-Host ""
Write-Host " - Dual-wielding" -ForegroundColor Gray
Write-Host " - Universal melee (physical attacks with any weapon)" -ForegroundColor Gray
Write-Host " - Physical jumping" -ForegroundColor Gray
Write-Host " - Virtual stock for stable two-handed aiming" -ForegroundColor Gray
Write-Host " - Grip-holster mode" -ForegroundColor Gray
Write-Host " - Weapon weight simulation" -ForegroundColor Gray
Write-Host " - Difficulty tweaks (damage / recoil / spread)" -ForegroundColor Gray
Write-Host ""
Write-Host " REQUIREMENT: The original Half-Life 2: VR Mod must already" -ForegroundColor Yellow
Write-Host " be installed via Steam (AppID $BASE_APPID). HL2VRU works with" -ForegroundColor Yellow
Write-Host " the base mod AND with Episode One + Episode Two if you" -ForegroundColor Yellow
Write-Host " have them installed." -ForegroundColor Yellow
Write-Host ""
Write-Host " REMOVAL: To uninstall, right-click 'Half-Life 2: VR Mod' in" -ForegroundColor Gray
Write-Host " your Steam library, Properties -> Installed Files ->" -ForegroundColor Gray
Write-Host " 'Verify integrity of game files'. Steam will re-download" -ForegroundColor Gray
Write-Host " the original files and the add-on is gone." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to continue..."

# -------------------------------------------------------
# Step 1: Locate HL2VR install folder
# -------------------------------------------------------
Write-Step 1 4 "Locate Half-Life 2: VR Mod install"

# Walk Steam libraryfolders.vdf to find every library path the user
# has. HL2VR can be on any of them - the default C:\Program Files
# (x86)\Steam path is only one option.
$steamRoot = $null
try {
 $rk = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
 if (Test-Path $rk) {
 $steamRoot = (Get-ItemProperty -Path $rk -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
 }
 if (-not $steamRoot) {
 $rk2 = "HKLM:\SOFTWARE\Valve\Steam"
 if (Test-Path $rk2) {
 $steamRoot = (Get-ItemProperty -Path $rk2 -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
 }
 }
} catch { }

if (-not $steamRoot -or -not (Test-Path $steamRoot)) {
 Write-Fail "Could not find Steam in the Windows registry."
 Write-Info "Make sure Steam is installed before running this add-on."
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "Steam detection" `
 -Url "https://store.steampowered.com/about" `
 -Instructions "Install Steam from https://store.steampowered.com/about and run it at least once." `
 -SkipMessage "Skipped - cannot locate Steam libraries; downstream steps will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-read Steam registry
 $steamNow = $null
 try {
 $r = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name InstallPath -EA SilentlyContinue
 if ($r) { $steamNow = $r.InstallPath }
 } catch { }
 if (-not $steamNow) {
 try {
 $r = Get-ItemProperty -Path "HKLM:\SOFTWARE\Valve\Steam" -Name InstallPath -EA SilentlyContinue
 if ($r) { $steamNow = $r.InstallPath }
 } catch { }
 }
 if ($steamNow) {
 Write-OK "Steam detected at: $steamNow"
 } else {
 Pause-User "Still cannot find Steam. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}
Write-OK "Steam root: $steamRoot"

# Parse libraryfolders.vdf for additional library paths
$libs = @($steamRoot)
$vdf = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
if (Test-Path $vdf) {
 $vdfText = Get-Content $vdf -Raw
 $pathMatches = [regex]::Matches($vdfText, '"path"\s+"([^"]+)"')
 foreach ($m in $pathMatches) {
 $p = $m.Groups[1].Value -replace '\\\\', '\'
 if ($p -and (Test-Path $p) -and ($libs -notcontains $p)) {
 $libs += $p
 }
 }
}

$hl2vrPath = $null
foreach ($lib in $libs) {
 $candidate = Join-Path $lib "steamapps\common\$BASE_FOLDERNAME"
 if (Test-Path $candidate) {
 $hl2vrPath = $candidate
 Write-OK "Found HL2VR install: $candidate"
 break
 }
}

if (-not $hl2vrPath) {
 Write-Fail "Half-Life 2: VR Mod is not installed yet."
 Write-Host ""
 Write-Host " HL2VRU is an add-on for the official Half-Life 2: VR Mod." -ForegroundColor Yellow
 Write-Host " Before installing the add-on, please:" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " 1. Open Steam." -ForegroundColor White
 Write-Host " 2. Install 'Half-Life 2: VR Mod' (AppID $BASE_APPID)." -ForegroundColor White
 Write-Host " Optionally also Episode One (2177750) and" -ForegroundColor White
 Write-Host " Episode Two (2177760)." -ForegroundColor White
 Write-Host " 3. Launch the base VR mod once so Steam finishes the" -ForegroundColor White
 Write-Host " installation." -ForegroundColor White
 Write-Host " 4. Run this Unleashed installer again." -ForegroundColor White
 Write-Host ""
 $__fb = Invoke-InstallerFallback -Action "Half-Life 2: VR Mod base install" `
 -Url "https://store.steampowered.com/app/658920" `
 -Instructions "Install 'Half-Life 2: VR Mod' (AppID 658920) from Steam first (free), launch it once so Steam finishes setup, then choose Retry. The Unleashed add-on needs the base mod present." `
 -SkipMessage "Skipped - the Unleashed add-on cannot install without the base mod." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-walk Steam libraries to find HL2VR
 $hl2vrPath = $null
 foreach ($lib in $libs) {
 $candidate = Join-Path $lib "steamapps\common\Half-Life 2 VR"
 if (Test-Path $candidate) { $hl2vrPath = $candidate; break }
 }
 if ($hl2vrPath) {
 Write-OK "Found HL2VR install: $hl2vrPath"
 } else {
 Pause-User "Still no HL2VR install detected. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

# Sanity check: the HL2VR executable should be in the folder we found.
# If it's missing the user probably has a partial Steam download.
$hl2vrExe = Join-Path $hl2vrPath "hl2vr.exe"
if (-not (Test-Path $hl2vrExe)) {
 Write-Warn "Folder exists but hl2vr.exe is missing inside it."
 Write-Warn "Steam may still be downloading - finish the install first."
 $__fb = Invoke-InstallerFallback -Action "HL2VR install completion check" `
 -Url "https://store.steampowered.com/app/658920" `
 -Instructions "Open Steam, wait for 'Half-Life 2: VR Mod' to finish downloading, launch it once, then choose Retry." `
 -SkipMessage "Skipped - extracting the add-on on top of an incomplete install may cause Steam to overwrite the add-on later." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check hl2vr.exe
 if (Test-Path $hl2vrExe) {
 Write-OK "hl2vr.exe found."
 } else {
 Pause-User "Still no hl2vr.exe. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

# -------------------------------------------------------
# Step 2: 7-Zip check (release ships as .7z)
# -------------------------------------------------------
Write-Step 2 4 "Check 7-Zip availability"

$sevenZipExe = $null
$candidates = @(
 "C:\Program Files\7-Zip\7z.exe",
 "C:\Program Files (x86)\7-Zip\7z.exe",
 "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
)
foreach ($c in $candidates) {
 if (Test-Path $c) { $sevenZipExe = $c; break }
}
if (-not $sevenZipExe) {
 try {
 $found = Get-Command "7z.exe" -ErrorAction SilentlyContinue
 if ($found) { $sevenZipExe = $found.Source }
 } catch { }
}

if ($sevenZipExe) {
 Write-OK "Found 7-Zip: $sevenZipExe"
} else {
 Write-Warn "7-Zip is not installed - the HL2VRU release ships as .7z"
 Write-Host ""
 Write-Host " Download and install 7-Zip now? (y/n)" -ForegroundColor White
 $ans = (Read-Host " > ").Trim().ToLower()
 if ($ans -ne "y" -and $ans -ne "yes") {
 Write-Fail "Cannot proceed without 7-Zip."
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
 $tmpInst = Join-Path $env:TEMP "7z2409-x64.exe"
 Write-Info "Downloading 7-Zip installer..."
 try {
 Invoke-WebRequest -Uri $SEVENZIP_URL -OutFile $tmpInst -UseBasicParsing
 } catch {
 Write-Fail "Failed to download 7-Zip: $($_.Exception.Message)"
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
 Write-Info "Running 7-Zip silent installer (UAC prompt may appear)..."
 Start-Process -FilePath $tmpInst -ArgumentList "/S" -Wait
 Remove-Item $tmpInst -Force -ErrorAction SilentlyContinue
 foreach ($c in $candidates) {
 if (Test-Path $c) { $sevenZipExe = $c; break }
 }
 if (-not $sevenZipExe) {
 Write-Fail "7-Zip install seems to have failed."
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
 Write-OK "7-Zip installed: $sevenZipExe"
}

# -------------------------------------------------------
# Step 3: Download HL2VRU release
# -------------------------------------------------------
Write-Step 3 4 "Download HL2VRU $MOD_VERSION"

$tmpDir = Join-Path $env:TEMP "HL2VRU-install"
if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
$archivePath = Join-Path $tmpDir $ARCHIVE_NAME

Write-Info "Downloading from GitHub release page..."
Write-Info "URL: $RELEASE_URL"
try {
 $oldPP = $ProgressPreference
 $ProgressPreference = 'SilentlyContinue'
 Invoke-WebRequest -Uri $RELEASE_URL -OutFile $archivePath -UseBasicParsing
 $ProgressPreference = $oldPP
} catch {
 Write-Fail "Download failed: $($_.Exception.Message)"
 Write-Info "Check your internet connection and try again."
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
if (-not (Test-Path $archivePath)) {
 Write-Fail "Archive missing after download."
 $__fb = Invoke-InstallerFallback -Action "mod download" `
 -Url "https://github.com/vittorioromeo/HL2VRU/releases" `
 -Instructions "Open https://github.com/vittorioromeo/HL2VRU/releases in the browser that just opened, download HL2VRU_0.0.7.7z and place it at '$archivePath', then choose Retry." `
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
$sz = (Get-Item $archivePath).Length
Write-OK "Downloaded $ARCHIVE_NAME ($([math]::Round($sz/1MB,1)) MB)"

# -------------------------------------------------------
# Step 4: Extract on top of HL2VR folder
# -------------------------------------------------------
Write-Step 4 4 "Extract Unleashed on top of HL2VR install"

Write-Info "Extracting into: $hl2vrPath"
Write-Host ""
Write-Host " The archive overlays its hlvr/, episodicvr/, and bin/ folders" -ForegroundColor Gray
Write-Host " on top of the existing HL2VR install. Vanilla files are kept" -ForegroundColor Gray
Write-Host " by Steam internally - 'Verify integrity of game files' in the" -ForegroundColor Gray
Write-Host " Steam library properties restores them at any time." -ForegroundColor Gray
Write-Host ""

# 7z extract with overwrite-all flag (-aoa). -o sets the output folder.
$extractArgs = @("x", "-aoa", "-o`"$hl2vrPath`"", "`"$archivePath`"")
try {
 $p = Start-Process -FilePath $sevenZipExe -ArgumentList $extractArgs -Wait -PassThru -WindowStyle Hidden
 if ($p.ExitCode -ne 0) {
 Write-Fail "7-Zip extraction failed with exit code $($p.ExitCode)."
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$sevenZip' with 7-Zip or Windows Explorer, and extract its contents into your game install folder. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
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
} catch {
 Write-Fail "Extraction error: $($_.Exception.Message)"
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
Write-OK "Extraction complete."

# Clean up downloaded archive
Remove-Item $archivePath -Force -ErrorAction SilentlyContinue
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

# -------------------------------------------------------
# Persist install state for the hub
# -------------------------------------------------------
# .installed_path = the HL2VR folder where we just dropped the add-on.
# The hub's add-on detection logic looks at this file's existence to
# decide whether to show "+ Reinstall Unleashed" instead of "+ Install
# Unleashed add-on" in the detail view of the three HL2VR cards.
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $hl2vrPath -Encoding UTF8 -Force
} catch { }

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " HL2VRU Unleashed installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " - Launch Half-Life 2: VR Mod from Steam." -ForegroundColor White
Write-Host " - The title screen will show 'UNLEASHED' in the logo if" -ForegroundColor White
Write-Host " the add-on loaded correctly." -ForegroundColor White
Write-Host " - Open the SteamVR controller bindings menu and bind:" -ForegroundColor White
Write-Host " Fire, Alt Fire, Eject Magazine, Open Weapon Selection" -ForegroundColor White
Write-Host " on BOTH controllers (required for dual wielding)." -ForegroundColor White
Write-Host " - Recommended: rebind 'Toggle Menu' to a long press or" -ForegroundColor White
Write-Host " chord so it doesn't conflict with left-hand Alt Fire." -ForegroundColor White
Write-Host " - Recommended: unbind 'Sprint' on the left hand. Sprint" -ForegroundColor White
Write-Host " still works via double-tap on the joystick." -ForegroundColor White
Write-Host ""
Write-Host " Tip: to uninstall, right-click 'Half-Life 2: VR Mod' in" -ForegroundColor Gray
Write-Host " Steam, Properties -> Installed Files -> Verify integrity." -ForegroundColor Gray
Write-Host ""
Write-Host " Dual wield the crowbar. Two-fist the gravity gun. Unleashed." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit..."
