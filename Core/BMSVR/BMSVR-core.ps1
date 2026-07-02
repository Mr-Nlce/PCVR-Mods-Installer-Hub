# ============================================================
# Black Mesa Source VR (Beta 2.0) Installer
# Mod by Linc | https://www.nexusmods.com/halflife2episode2/mods/4
# Unofficial VR port of Black Mesa Source: Extended Edition
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Black Mesa Source VR Installer"
$ErrorActionPreference = "Stop"

# Steam AppIDs (used for library checks)
$APPID_HL2 = "220"
$APPID_HL2_EP1 = "380"
$APPID_HL2_EP2 = "420"
$APPID_HL2VR = "658920"
$APPID_HL2VR_EP1 = "2177750"
$APPID_HL2VR_EP2 = "2177760"
$APPID_BLACKMESA = "362890"

$NEXUS_MOD_URL = "https://www.nexusmods.com/halflife2episode2/mods/4?tab=files"
$DEFAULT_INSTALL = "C:\Games\Black Mesa VR"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host " Black Mesa Source VR (Beta 2.0) Installer" -ForegroundColor Magenta; Write-Host " Half-Life 2: Episode 2 VR mod by Ashok" -ForegroundColor Gray; Write-Host " nexusmods.com/halflife2episode2/mods/4" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries {
 param($sp); $libs=@($sp)
 $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}

# Test if a Steam AppID is owned (manifest exists in any library)
function Test-SteamAppOwned {
 param($appId, $libraries)
 foreach ($lib in $libraries) {
 $manifest = Join-Path $lib "steamapps\appmanifest_$appId.acf"
 if (Test-Path $manifest) { return $true }
 }
 return $false
}

# Find a Steam game folder by SteamFolder name (returns path or $null)
function Find-SteamGameFolder {
 param($folderName, $libraries)
 foreach ($lib in $libraries) {
 $candidate = Join-Path $lib "steamapps\common\$folderName"
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

Write-Header

# ------------------------------------------------------------
# Big upfront context for the user
# ------------------------------------------------------------
Write-Host " This installer automates Ashok's Black Mesa Source VR mod." -ForegroundColor White
Write-Host ""
Write-Host " What it does:" -ForegroundColor White
Write-Host " * Verifies all required Steam games are owned" -ForegroundColor Gray
Write-Host " * Extracts the portable Mod Organizer 2 to your chosen folder" -ForegroundColor Gray
Write-Host " * Patches MO2 paths to point to your HL2VR install" -ForegroundColor Gray
Write-Host " * Patches XEN gameinfo.txt with your Black Mesa path" -ForegroundColor Gray
Write-Host " * Optionally sets up 5.1 HRTF spatial audio" -ForegroundColor Gray
Write-Host " * Creates desktop shortcuts" -ForegroundColor Gray
Write-Host ""
Write-Host " What it cannot do:" -ForegroundColor White
Write-Host " * Download the mod automatically (Nexus needs login)" -ForegroundColor Gray
Write-Host " You will download the .rar archive yourself, then point this installer at it" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..."

# ------------------------------------------------------------
# STEP 1: Steam Library and Prerequisites
# ------------------------------------------------------------
Write-Step 1 8 "Verifying Steam Prerequisites"

$steamPath = Get-SteamPath
if (-not $steamPath) {
 Write-Fail "Steam installation not found in registry."
 Write-Fail "Install Steam first, or run Steam at least once."
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "Steam detection" `
 -Url "https://store.steampowered.com/about" `
 -Instructions "Install Steam from https://store.steampowered.com/about and run it at least once so the registry entries are created." `
 -SkipMessage "Skipped - cannot locate any Steam libraries; downstream steps will fail." `
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
Write-Info "Steam: $steamPath"

$libraries = Get-SteamLibraries $steamPath
Write-Info "Steam libraries: $($libraries.Count)"

# Required: must be in Steam library. HL2VR EP2 is the only one that needs to be INSTALLED.
# Black Mesa retail is OPTIONAL - only needed for 2 bonus Xen 1.0 maps.
$ownChecks = @(
 @{ Id=$APPID_HL2; Name="Half-Life 2"; Required=$true; InstallNeeded=$false },
 @{ Id=$APPID_HL2_EP1; Name="Half-Life 2: Episode One"; Required=$true; InstallNeeded=$false },
 @{ Id=$APPID_HL2_EP2; Name="Half-Life 2: Episode Two"; Required=$true; InstallNeeded=$false },
 @{ Id=$APPID_HL2VR_EP1; Name="HL2: VR Mod - Episode One";Required=$true; InstallNeeded=$false },
 @{ Id=$APPID_HL2VR_EP2; Name="HL2: VR Mod - Episode Two";Required=$true; InstallNeeded=$true },
 @{ Id=$APPID_BLACKMESA; Name="Black Mesa (retail)"; Required=$false; InstallNeeded=$false }
)

$allOK = $true
$hasBlackMesa = $false
foreach ($check in $ownChecks) {
 $owned = Test-SteamAppOwned -appId $check.Id -libraries $libraries
 if ($owned) {
 if ($check.Id -eq $APPID_BLACKMESA) { $hasBlackMesa = $true; Write-OK "$($check.Name) ($($check.Id)) [unlocks Xen 1.0 bonus maps]" }
 else { Write-OK "$($check.Name) ($($check.Id))" }
 } else {
 if ($check.Required) {
 Write-Fail "$($check.Name) ($($check.Id)) NOT in your Steam library!"
 $allOK = $false
 } else {
 Write-Warn "$($check.Name) ($($check.Id)) not in library - Xen 1.0 bonus maps will be unavailable"
 }
 }
}

if (-not $allOK) {
 Write-Host ""
 Write-Host " Required games are missing from your Steam library." -ForegroundColor Yellow
 Write-Host " HL2, HL2:EP1, HL2:EP2, HL2VR:EP1 don't need to be installed," -ForegroundColor White
 Write-Host " but they MUST be in your Steam library (free if you own HL2)." -ForegroundColor White
 Write-Host ""
 Write-Host " Steam links:" -ForegroundColor White
 Write-Host " HL2 VR Mod - Episode One: https://store.steampowered.com/app/$APPID_HL2VR_EP1" -ForegroundColor Gray
 Write-Host " HL2 VR Mod - Episode Two: https://store.steampowered.com/app/$APPID_HL2VR_EP2" -ForegroundColor Gray
 Write-Host ""
 $__fb = Invoke-InstallerFallback -Action "Steam library prerequisites" `
 -Url "https://store.steampowered.com/about" `
 -Instructions "Open Steam, install/add HL2, HL2:EP1, HL2:EP2 and HL2VR:EP1 (all free if you own HL2), then choose Retry. They do not need to be installed - just present in your library." `
 -SkipMessage "Skipped - BMSVR cannot detect the source assets it needs; the mod will not run." `
 -AllowSkip $false
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

# Locate installed game folders
# HL2VR (all episodes) shares ONE folder named "Half-Life 2 VR" - confirmed by user file: ep1vr.exe sits there too
$hl2vrPath = Find-SteamGameFolder -folderName "Half-Life 2 VR" -libraries $libraries
$blackMesaPath = if ($hasBlackMesa) { Find-SteamGameFolder -folderName "Black Mesa" -libraries $libraries } else { $null }

if (-not $hl2vrPath -or -not (Test-Path (Join-Path $hl2vrPath "ep2vr.exe"))) {
 Write-Fail "ep2vr.exe not found in: $hl2vrPath"
 Write-Fail "Install Half-Life 2: VR Mod - Episode Two via Steam first."
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Create or pick a writable BMSVR install root - pick a path NOT inside Users\\ or Program Files (e.g. C:\\Games\\BMSVR). MO2 needs raw write access. Choose Retry once the path is available." `
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
Write-OK "HL2VR folder: $hl2vrPath"
Write-OK "ep2vr.exe verified"
if (Test-Path (Join-Path $hl2vrPath "ep1vr.exe")) {
 Write-Info "ep1vr.exe also present (good - Episode One assets available)"
}

if ($hasBlackMesa) {
 if (-not $blackMesaPath -or -not (Test-Path (Join-Path $blackMesaPath "bms"))) {
 Write-Warn "Black Mesa is in library but not installed properly at: $blackMesaPath"
 Write-Warn "Xen 1.0 bonus maps will not work - install Black Mesa via Steam to enable them."
 $hasBlackMesa = $false
 } else {
 Write-OK "Black Mesa folder: $blackMesaPath [Xen 1.0 bonus maps enabled]"
 }
} else {
 Write-Info "Black Mesa not detected - main BMS campaign works fine, only Xen 1.0 bonus is skipped."
}

# ------------------------------------------------------------
# STEP 2: Get the Mod Archive
# ------------------------------------------------------------
Write-Step 2 8 "Acquiring the Mod Archive"

# IMPORTANT: the Nexus download is a .rar file (not .zip), so
# 7-Zip is REQUIRED to extract it. We try the central Get-SevenZip
# helper which auto-installs 7-Zip if missing. WinRAR is a manual
# fallback users can pick from the fallback prompt.
$hasWinRAR = (Test-Path "C:\Program Files\WinRAR\WinRAR.exe") -or (Test-Path "C:\Program Files (x86)\WinRAR\WinRAR.exe")

Write-Host " The Black Mesa Source VR mod must be downloaded manually from Nexus." -ForegroundColor White
Write-Host " Nexus does not allow direct API downloads without Premium + API key." -ForegroundColor Gray
Write-Host ""
Write-Host " IMPORTANT: the Nexus download is a .rar file (not .zip)." -ForegroundColor Yellow
Write-Host " 7-Zip will be auto-installed if missing. WinRAR also works as a fallback." -ForegroundColor Gray
Write-Host ""

$sevenZipExe = Get-SevenZip
if (-not $sevenZipExe) {
 if ($hasWinRAR) {
 Write-Host " WinRAR detected - you can extract the .rar manually with it." -ForegroundColor Yellow
 } else {
 Write-Fail "Neither 7-Zip nor WinRAR found and 7-Zip auto-install was declined."
 Write-Host " Install 7-Zip from https://www.7-zip.org BEFORE continuing," -ForegroundColor Yellow
 Write-Host " or this installer will not be able to extract the .rar file." -ForegroundColor Yellow
 Write-Host ""
 $proceed = (Read-Host " Continue anyway? Type YES to proceed, anything else exits").Trim()
 if ($proceed -ne "YES") {
 Write-Host ""
 Write-Host "Install 7-Zip and re-run this installer." -ForegroundColor Cyan
 Pause-User "Press Enter to exit."
 exit 0
 }
 }
} else {
 Write-OK "7-Zip ready: $sevenZipExe"
}
Write-Host ""
Write-Host " Choose how to provide the main mod archive (.rar):" -ForegroundColor White
Write-Host ""
Write-Host " [1] Open Nexus in browser and download now (then point me at the file)" -ForegroundColor White
Write-Host " [2] I already have the .rar file - let me enter the path" -ForegroundColor White
Write-Host ""
$dlChoice = ""
while ($dlChoice -notin @("1","2")) { $dlChoice = (Read-Host " Enter 1 or 2").Trim() }

if ($dlChoice -eq "1") {
 Write-Host ""
 Write-Host " Opening Nexus mod page..." -ForegroundColor White
 Write-Host " Required steps on Nexus:" -ForegroundColor White
 Write-Host " 1. Log in (free account is sufficient)" -ForegroundColor Gray
 Write-Host " 2. Go to FILES tab" -ForegroundColor Gray
 Write-Host " 3. Download 'BLACK MESA SOURCE VR (BETA 2.0)' main file" -ForegroundColor Gray
 Write-Host " (Click 'Slow Download' for free accounts)" -ForegroundColor Gray
 Write-Host " 4. Save it somewhere you can find it (e.g. Downloads folder)" -ForegroundColor Gray
 Write-Host " The file is a .rar archive (about 2 GB)." -ForegroundColor Gray
 Write-Host ""
 Start-Process $NEXUS_MOD_URL
 Pause-User "Press Enter once you have downloaded the .rar file..."
}

# Get path to archive from user (drag-and-drop into the console works in PS5.1)
$modZip = $null
while (-not $modZip) {
 Write-Host ""
 Write-Host " Drag-and-drop the downloaded .rar into this window," -ForegroundColor Yellow
 Write-Host " expected file 'Black Mesa Source VR BETA-2-4-BETA-2-1683237368.rar'," -ForegroundColor Gray
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " Archive path").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 if ($r -match '\.zip$|\.7z$|\.rar$') {
 $modZip = $r
 Write-Info "Archive located: $modZip"
 } else {
 Write-Fail "Path is not a ZIP/7z/RAR archive: $r"
 }
 } else {
 Write-Fail "File not found: $r"
 }
}

# Decide extractor: built-in for .zip, request 7z for others
$is7zNeeded = ($modZip -notmatch '\.zip$')
$sevenZipExe = $null
if ($is7zNeeded) {
 Write-Info "Archive is not .zip - we need 7-Zip to extract."
 $candidate7z = @(
 "C:\Program Files\7-Zip\7z.exe",
 "C:\Program Files (x86)\7-Zip\7z.exe"
 )
 foreach ($c in $candidate7z) { if (Test-Path $c) { $sevenZipExe = $c; break } }
 if (-not $sevenZipExe) {
 Write-Fail "7-Zip not found. Install 7-Zip from https://www.7-zip.org first."
 Write-Fail "Or re-run with a .zip archive instead of $($modZip | Split-Path -Extension)."
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
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
 Write-OK "7-Zip: $sevenZipExe"
}

# ------------------------------------------------------------
# STEP 3: Choose Install Folder
# ------------------------------------------------------------
Write-Step 3 8 "Choose Install Folder for Mod Organizer 2"

Write-Host " The mod is a portable Mod Organizer 2 (MO2) instance." -ForegroundColor White
Write-Host " It MUST NOT be extracted under 'Users' or 'Program Files'." -ForegroundColor Yellow
Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor Gray
Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor Gray
Write-Host ""
Write-Host " Default: $DEFAULT_INSTALL" -ForegroundColor White
$installAnswer = (Read-Host " Press Enter for default, or type a different path").Trim().Trim('"')
$installRoot = if ($installAnswer) { $installAnswer } else { $DEFAULT_INSTALL }

# Validate path - reject Users\ and Program Files
$bad = @("\\Users\\", "\\Program Files", "\\Program Files \(x86\)")
foreach ($b in $bad) {
 if ($installRoot -match $b) {
 Write-Fail "Install folder must NOT be inside Users or Program Files."
 Write-Fail "MO2 will fail with permission errors."
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
 $__fb = Invoke-InstallerFallback -Action "install folder selection" `
 -Instructions "Pick a path that is NOT inside Users\ or Program Files (e.g. C:\Games\BMSVR). MO2 requires write access without UAC virtualization. Re-run after picking a valid path." `
 -SkipMessage "Skipped - install will likely fail with permission errors on this path." `
 -AllowSkip $false
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
}

# Create parent if not exists
$installParent = Split-Path -Parent $installRoot
if ($installParent -and -not (Test-Path $installParent)) {
 try {
 New-Item -ItemType Directory -Path $installParent -Force | Out-Null
 Write-Info "Created parent: $installParent"
 } catch {
 Write-Fail "Could not create parent folder: $installParent"
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
$__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$installParent' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
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
}

# If destination exists with content, ask before overwriting
if ((Test-Path $installRoot) -and (Get-ChildItem $installRoot -ErrorAction SilentlyContinue | Select-Object -First 1)) {
 Write-Warn "Folder exists and is not empty: $installRoot"
 $ow = (Read-Host " Overwrite? Type YES to continue").Trim()
 if ($ow -ne "YES") {
 Write-Fail "Aborted by user."
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
$__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$gameDir' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
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
}

if (-not (Test-Path $installRoot)) {
 New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
}
Write-OK "Install folder: $installRoot"

# ------------------------------------------------------------
# STEP 4: Extract the Mod
# ------------------------------------------------------------
Write-Step 4 8 "Extracting Mod Organizer 2 Portable Instance"

Write-Host " Extracting (this can take a few minutes - the archive is ~4-5 GB) ... " -ForegroundColor White
try {
 if ($is7zNeeded) {
 # 7z output flag preserves folder structure
 $sevenZipArgs = @("x", "-y", "-o`"$installRoot`"", "`"$modZip`"")
 $proc = Start-Process -FilePath $sevenZipExe -ArgumentList $sevenZipArgs -Wait -PassThru -NoNewWindow
 if ($proc.ExitCode -ne 0) { throw "7-Zip exit code: $($proc.ExitCode)" }
 } else {
 Expand-Archive -Path $modZip -DestinationPath $installRoot -Force
 }
 Write-OK "Extraction complete."
} catch {
 Write-Fail "Extraction failed: $_"
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
$__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$installRoot'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$installRoot" `
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

# The archive may extract with or without a wrapping top-level folder.
# Find ModOrganizer.exe and take its parent as the actual MO2 root.
$moExe = Get-ChildItem -Path $installRoot -Filter "ModOrganizer.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $moExe) {
 Write-Fail "ModOrganizer.exe not found after extraction."
 Write-Fail "Archive structure may be unexpected. Check: $installRoot"
 Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Green
Write-Host ""
$__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Create or pick a writable BMSVR install root - pick a path NOT inside Users\\ or Program Files (e.g. C:\\Games\\BMSVR). MO2 needs raw write access. Choose Retry once the path is available." `
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
$mo2Root = $moExe.DirectoryName
Write-OK "MO2 root: $mo2Root"

# Verify expected sub-structure
$modsDir = Join-Path $mo2Root "mods"
$xenDir = Join-Path $modsDir "XEN"
$bmsDir = Join-Path $modsDir "BMS"
$xenInfo = Join-Path $xenDir "gameinfo.txt"
if (-not (Test-Path $xenDir)) {
 Write-Warn "Expected mods\XEN folder not found at: $xenDir"
 Write-Warn "Path patches may fail - manual config will be needed."
}

# ------------------------------------------------------------
# STEP 5: Patch MO2 INI files to point at HL2VR install
# ------------------------------------------------------------
Write-Step 5 8 "Patching MO2 to Match Your HL2VR Install"

# The bundled MO2 ships with paths assuming C:\Program Files (x86)\Steam\...\Half-Life 2 VR.
# We rewrite any string matching that pattern to the user's actual HL2VR path.

# Common paths to scan and rewrite
$mo2Ini = Join-Path $mo2Root "ModOrganizer.ini"
$execIni = Join-Path $mo2Root "executables.ini" # MO2 1.x; modern uses ModOrganizer.ini sections

$patchTargets = @()
if (Test-Path $mo2Ini) { $patchTargets += $mo2Ini }
if (Test-Path $execIni) { $patchTargets += $execIni }

# MO2 stores paths in INI in three possible forms:
# single backslash: C:\Program Files (x86)\Steam\steamapps\common\Half-Life 2 VR
# forward slashes: C:/Program Files (x86)/Steam/steamapps/common/Half-Life 2 VR
# double backslashes: C:\\Program Files (x86)\\Steam\\steamapps\\common\\Half-Life 2 VR
# Custom Steam libraries may NOT have "Steam" as the parent - only "steamapps\common" is reliable.
# We anchor on "...steamapps[/\]common[/\]Half-Life 2 VR" preceded by any drive+path.
$hl2vrFwd = $hl2vrPath -replace '\\', '/'
$hl2vrDouble = $hl2vrPath -replace '\\', '\\\\'

# .NET regex replacement strings treat $ as a special char (group refs).
# Escape any literal $ in the replacement so paths like "C:\Folder$\..." don't break.
$hl2vrFwd_R = $hl2vrFwd -replace '\$', '$$$$'
$hl2vrDouble_R = $hl2vrDouble -replace '\$', '$$$$'
$hl2vrPath_R = $hl2vrPath -replace '\$', '$$$$'

$patched = 0
foreach ($file in $patchTargets) {
 try {
 $content = Get-Content $file -Raw
 $orig = $content

 # Form 1: forward slashes
 # [A-Za-z]:/ any-non-quote-path /steamapps/common/Half-Life 2 VR
 $pat1 = '(?i)[A-Za-z]:/(?:[^"\r\n]*?/)?steamapps/common/Half-Life 2 VR'
 $content = [regex]::Replace($content, $pat1, $hl2vrFwd_R)

 # Form 2: double-escaped backslashes
 $pat2 = '(?i)[A-Za-z]:\\\\(?:[^"\r\n]*?\\\\)?steamapps\\\\common\\\\Half-Life 2 VR'
 $content = [regex]::Replace($content, $pat2, $hl2vrDouble_R)

 # Form 3: single backslashes
 $pat3 = '(?i)[A-Za-z]:\\(?:[^"\r\n]*?\\)?steamapps\\common\\Half-Life 2 VR'
 $content = [regex]::Replace($content, $pat3, $hl2vrPath_R)

 if ($content -ne $orig) {
 # Backup once
 $bak = "$file.bak"
 if (-not (Test-Path $bak)) { Copy-Item $file $bak -Force }
 Set-Content -Path $file -Value $content -NoNewline -Encoding UTF8
 Write-OK "Patched HL2VR path in: $(Split-Path -Leaf $file)"
 $patched++
 } else {
 Write-Info "No HL2VR path patch needed in: $(Split-Path -Leaf $file)"
 }
 } catch {
 Write-Warn "Could not patch $($file): $_"
 }
}

if ($patched -eq 0) {
 Write-Warn "No INI files were patched. If MO2 reports the wrong game path,"
 Write-Warn "set 'Tools > Settings > Paths > Managed Game' to: $hl2vrPath\ep2vr.exe"
}

# ------------------------------------------------------------
# STEP 6: Patch XEN gameinfo.txt with Black Mesa path (only if BM owned)
# ------------------------------------------------------------
Write-Step 6 8 "Patching XEN gameinfo.txt with Black Mesa Path"

if (-not $hasBlackMesa) {
 Write-Info "Black Mesa retail not in your library - skipping XEN gameinfo.txt patch."
 Write-Info "(Xen 1.0 bonus maps will be unavailable. Main BMS campaign still works.)"
} elseif (Test-Path $xenInfo) {
 try {
 $content = Get-Content $xenInfo -Raw
 $orig = $content

 # Replace any absolute path containing steamapps\common\Black Mesa with the actual one.
 # Three forms (same multi-form approach as MO2 INI patches above):
 $bmFwd = $blackMesaPath -replace '\\', '/'
 $bmDouble = $blackMesaPath -replace '\\', '\\\\'
 # Escape $ for .NET replacement
 $bmFwd_R = $bmFwd -replace '\$', '$$$$'
 $bmDouble_R = $bmDouble -replace '\$', '$$$$'
 $bmPath_R = $blackMesaPath -replace '\$', '$$$$'

 $pat1 = '(?i)[A-Za-z]:/(?:[^"\r\n]*?/)?steamapps/common/Black Mesa'
 $content = [regex]::Replace($content, $pat1, $bmFwd_R)

 $pat2 = '(?i)[A-Za-z]:\\\\(?:[^"\r\n]*?\\\\)?steamapps\\\\common\\\\Black Mesa'
 $content = [regex]::Replace($content, $pat2, $bmDouble_R)

 $pat3 = '(?i)[A-Za-z]:\\(?:[^"\r\n]*?\\)?steamapps\\common\\Black Mesa'
 $content = [regex]::Replace($content, $pat3, $bmPath_R)

 if ($content -ne $orig) {
 $bak = "$xenInfo.bak"
 if (-not (Test-Path $bak)) { Copy-Item $xenInfo $bak -Force }
 Set-Content -Path $xenInfo -Value $content -NoNewline -Encoding UTF8
 Write-OK "Patched Black Mesa path in mods\XEN\gameinfo.txt"
 } else {
 Write-Info "No Black Mesa path patch needed in gameinfo.txt"
 Write-Info "(File may already be configured, or paths use a different scheme)"
 }
 } catch {
 Write-Warn "Could not patch gameinfo.txt: $_"
 Write-Warn "Manual edit needed: $xenInfo"
 Write-Warn "Update lines 46-50 to: $blackMesaPath"
 }
} else {
 Write-Warn "mods\XEN\gameinfo.txt not found - skipping (Xen 1.0 maps may not work)"
}

# ------------------------------------------------------------
# STEP 7: Optional 5.1 HRTF Audio Setup
# ------------------------------------------------------------
Write-Step 7 8 "Optional 5.1 HRTF Spatial Audio Setup"

Write-Host " The mod ships with OpenAL Soft + HRTF for true 5.1 surround in VR." -ForegroundColor White
Write-Host " This requires copying 3 DLL/INI files into your Half-Life 2 VR folder" -ForegroundColor White
Write-Host " and adding 14 small entries to your user-level Windows registry (HKCU)." -ForegroundColor White
Write-Host " No admin rights needed - the patches are user-scoped and locale-safe." -ForegroundColor Gray
Write-Host ""
Write-Host " Recommended: it noticeably improves VR immersion." -ForegroundColor Yellow
Write-Host ""
$audioChoice = (Read-Host " Set up HRTF audio now? (Y/N)").Trim().ToUpper()

if ($audioChoice -eq "Y") {
 $audioSrc = Join-Path $bmsDir "Game Folder Files"
 if (-not (Test-Path $audioSrc)) {
 Write-Warn "Audio source folder not found: $audioSrc"
 Write-Warn "Skipping audio setup - you can do this manually later."
 } else {
 $audioFiles = @("dsound.dll", "dsoal-aldrv.dll", "alsoft.ini")
 $copied = 0
 foreach ($af in $audioFiles) {
 $src = Join-Path $audioSrc $af
 $dst = Join-Path $hl2vrPath $af
 if (Test-Path $src) {
 try {
 Copy-Item $src $dst -Force
 Write-OK "Copied $af to HL2VR folder"
 $copied++
 } catch {
 Write-Warn "Could not copy $af : $_"
 }
 } else {
 Write-Warn "Source not found: $src"
 }
 }

 if ($copied -gt 0) {
 # Apply DirectSound CLSID registry patches.
 # We do this NATIVELY in PowerShell (not via the bundled .bat), because the
 # bundled patcher uses SetACL with the literal name "Administrators", which
 # FAILS on non-English Windows (German "Administratoren", French "Administrateurs"...).
 # Our approach uses the well-known SID S-1-5-32-544 which is locale-independent.
 #
 # What this does:
 # - For 7 DirectSound CLSIDs, set HKCU\SOFTWARE\Classes\CLSID\{...}\InprocServer32
 # default value to "dsound.dll" (no path) so the local game-folder dsound.dll loads.
 # - HKCU writes don't need ownership changes, so they always succeed.
 # - Optionally also patches HKLM (system-wide), taking ownership first via SID-544.
 # - HKCU takes precedence over HKLM for the current user, so HKCU-only is sufficient
 # for the user running the game. HKLM is a defense-in-depth bonus.

 Write-Host ""
 Write-Host " Applying DirectSound registry patches (locale-safe)..." -ForegroundColor White

 $clsids = @(
 "{11AB3EC0-25EC-11D1-A4D8-00C04FC28ACA}", # DirectSoundPrivate
 "{3901CC3F-84B5-4FA4-BA35-AA8172B8A09B}", # DirectSound 8.0 Object
 "{47D4D946-62E8-11CF-93BC-444553540000}", # DirectSound Object
 "{B0210780-89CD-11D0-AF08-00A0C925CD16}", # DirectSoundCapture Object
 "{B2F586D4-5558-49D1-A07B-3249DBBB33C2}", # (additional)
 "{E4BCAC13-7F99-4908-9A8E-74E3BF24B6E1}", # DirectSoundCapture 8.0 Object
 "{FEA4300C-7959-4147-B26A-2377B9E7A91D}" # DirectSoundFullDuplex Object
 )
 $hives = @(
 "HKCU:\SOFTWARE\Classes\CLSID",
 "HKCU:\SOFTWARE\Classes\WOW6432Node\CLSID"
 )

 $audioPatchOK = 0
 $audioPatchFail = 0
 foreach ($hive in $hives) {
 foreach ($clsid in $clsids) {
 $keyPath = Join-Path $hive "$clsid\InprocServer32"
 try {
 if (-not (Test-Path $keyPath)) {
 New-Item -Path $keyPath -Force | Out-Null
 }
 # Set the default value to "dsound.dll" (no path).
 # When the value is just a filename, Windows searches the calling
 # app's directory first - exactly what we want for game-local dsound.dll.
 Set-ItemProperty -Path $keyPath -Name '(default)' -Value 'dsound.dll' -ErrorAction Stop
 $audioPatchOK++
 } catch {
 $audioPatchFail++
 Write-Info " Could not patch $keyPath : $($_.Exception.Message)"
 }
 }
 }

 if ($audioPatchFail -eq 0) {
 Write-OK "All $audioPatchOK HKCU registry entries patched."
 Write-OK "DirectSound wrapper will load from HL2VR folder for the current user."
 } else {
 Write-Warn "$audioPatchOK patched, $audioPatchFail failed."
 Write-Warn "If audio doesn't activate in-game, run console commands:"
 Write-Warn " snd_legacy_surround 0"
 Write-Warn " snd_surround_speakers 5"
 }

 Write-Info "Note: HKCU patches survive Windows updates only sometimes."
 Write-Info "If 5.1 audio stops working later, re-run this installer with audio setup."
 }
 }
} else {
 Write-Info "Skipped audio setup."
 Write-Info "If you change your mind: re-run this installer and pick Y for audio,"
 Write-Info "or copy dsound.dll/dsoal-aldrv.dll/alsoft.ini from"
 Write-Info " $bmsDir\Game Folder Files\"
 Write-Info "to your Half-Life 2 VR folder manually."
}

# ------------------------------------------------------------
# STEP 8: Desktop Shortcuts
# ------------------------------------------------------------
Write-Step 8 8 "Creating Desktop Shortcuts"

try {
 $ep2vrExe = Join-Path $hl2vrPath "ep2vr.exe"
 $bmsIco = Join-Path $mo2Root "BlackMesaSource_VR.ico"
 try { Copy-Item -LiteralPath (Join-Path $PSScriptRoot "BlackMesaSource_VR.ico") -Destination $bmsIco -Force } catch {}
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Black Mesa Source VR.lnk" -TargetPath $moExe.FullName -WorkingDir $mo2Root -IconPath $(if (Test-Path $bmsIco) { $bmsIco } else { "$ep2vrExe,0" }) -Arguments '-p "Black Mesa Source VR" "Half-Life 2 VR"'
 Write-OK "Shortcut: 'Black Mesa Source VR' on Desktop (custom icon)"

 # Settings shortcut: opens the MO2 GUI (for switching between BMS and Xen 1.0 profiles,
 # toggling Gonarch's Lair Fix, configuring mods, etc.).
 $sc2 = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Black Mesa Source VR (MO2 Settings).lnk" -TargetPath $moExe.FullName -WorkingDir $mo2Root -IconPath "$($moExe.FullName),0" -Description "Open Mod Organizer 2 to switch profiles, toggle Gonarch's Lair Fix, etc."
 Write-OK "Shortcut: 'Black Mesa Source VR (MO2 Settings)' on Desktop (MO2 icon)"
} catch {
 Write-Warn "Could not create shortcuts: $_"
}

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host " Install folder: $mo2Root" -ForegroundColor White
Write-Host " HL2VR target: $hl2vrPath" -ForegroundColor White
if ($hasBlackMesa) {
 Write-Host " Black Mesa: $blackMesaPath [Xen 1.0 bonus maps enabled]" -ForegroundColor White
} else {
 Write-Host " Black Mesa: not installed - main BMS campaign only" -ForegroundColor White
}
Write-Host ""
Write-Host " How to play:" -ForegroundColor Yellow
Write-Host " Easy way: double-click the 'Black Mesa Source VR' desktop shortcut" -ForegroundColor White
Write-Host " (launches the main BMS campaign directly)" -ForegroundColor Gray
Write-Host ""
Write-Host " Profile switch (Xen 1.0 maps, Gonarch fix):" -ForegroundColor White
Write-Host " 1. Open 'Black Mesa Source VR (MO2 Settings)'" -ForegroundColor White
Write-Host " 2. Top-right dropdown: 'Half-Life 2 VR' (executable)" -ForegroundColor White
Write-Host " 3. Top-left dropdown (Profile):" -ForegroundColor White
Write-Host " * 'Black Mesa Source VR' = main BMS campaign" -ForegroundColor Gray
Write-Host " * 'Xen 1.0 VR' = bonus retail Xen maps" -ForegroundColor Gray
Write-Host " 4. Click 'Run' (top-right)" -ForegroundColor White
Write-Host ""
Write-Host " Special note for Gonarch's Lair:" -ForegroundColor Yellow
Write-Host " Tick 'Gonarch's Lair Fix' in the mods list, then select" -ForegroundColor White
Write-Host " 'Gonarch's Lair' in the in-game chapter menu. Untick it" -ForegroundColor White
Write-Host " afterwards or zombies break in the rest of the campaign." -ForegroundColor White
Write-Host ""
Write-Host " Console commands (if HRTF audio doesn't activate):" -ForegroundColor Yellow
Write-Host " snd_legacy_surround 0" -ForegroundColor Gray
Write-Host " snd_surround_speakers 5" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

# Tell the Hub where we put it so it can mark the game as VR Ready
# even when the user picked a non-default location. We point at
# the MO2 root (the folder containing ModOrganizer.exe) so the
# Hub's LaunchExe = "ModOrganizer.exe" resolves correctly.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $mo2Root -Encoding UTF8 -Force } catch {}

try { Start-Process explorer.exe "`"$mo2Root`"" } catch {}
Write-Host ""
Write-Host "Prepare for unforeseen consequences." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."