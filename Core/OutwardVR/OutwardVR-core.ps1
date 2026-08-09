# ============================================================
# Outward VR - Mod Installer
# ============================================================
#
# Installs cybensis/OutwardVR v0.9.2 onto an Outward Definitive
# Edition build pinned to the v1.0 Definitive Edition mono
# release manifest, which
# is the only build the mod is compatible with.
#
# Why DepotDownloader instead of Steam Console?
# Steam's built-in `download_depot` command cannot fetch
# manifests that exist only on public beta branches - it errors
# out with "Failed downloading 1 manifests (No connection)"
# regardless of network state (see valvesoftware/steam-for-
# linux#12138, confirmed across multiple Steam client versions).
# DepotDownloader (an open-source SteamKit2-based tool) does
# not share this limitation and handles beta-only manifests
# reliably. This is the same approach the Outward VR community
# guide recommends.
#
# Flow:
# 1) Download DepotDownloader from GitHub into a temp folder
# 2) Run it with Outward's pinned manifest, prompting the user
# for their Steam username (password / 2FA are handled
# interactively by DepotDownloader itself)
# 3) Download OutwardVR-0.9.2 and extract into Outward_Defed
# 4) Desktop shortcut + summary
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Outward VR Installer"
$ErrorActionPreference = "Stop"

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
$MOD_URL = "https://github.com/cybensis/OutwardVR/releases/download/v0.9.2/OutwardVR-0.9.2.zip"
$MOD_NAME = "OutwardVR v0.9.2"
$MOD_AUTHOR = "cybensis"
$GITHUB_URL = "https://github.com/cybensis/OutwardVR"

# DepotDownloader (stable standalone Windows release, self-contained, no .NET runtime needed)
$DD_VERSION = "3.4.0"
$DD_URL = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_$DD_VERSION/DepotDownloader-windows-x64.zip"

# Outward default-mono pinned manifest (the only one the VR mod is compatible with)
$DD_APPID = "794260"
$DD_DEPOTID = "1758860"
$DD_MANIFEST = "7402433355314190593"
$DD_BRANCH = "default-mono"

# Game structure inside the downloaded depot
$GAME_SUBDIR = "Outward_Defed"
$GAME_EXE = "Outward Definitive Edition.exe"

# Target install folder - created next to your Steam folder or wherever the user picks
$DEFAULT_INSTALL_PARENT = "C:\Games"
$INSTALL_FOLDER_NAME = "Outward VR"
# DepotDownloader downloads into this space-free folder first; the
# installer renames it to $INSTALL_FOLDER_NAME at the end. A space in
# the -dir path is split into two arguments by Start-Process, so the
# download must use a name without spaces.
$DOWNLOAD_FOLDER_NAME = "Outward"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Outward VR - Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
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
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }
function Read-Marked { param($text) Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; return (Read-Host " >") }

function Find-GameRoot {
    # Return the folder that actually contains the game EXE, searching
    # each root directly first, then recursively. Layout-agnostic: works
    # whether the EXE sits in an 'Outward_Defed' subfolder, directly in
    # the download folder, or anywhere under a folder the user points us
    # at. Returns $null if not found.
    param([string[]]$Roots)
    foreach ($r in $Roots) {
        if (-not $r -or -not (Test-Path $r)) { continue }
        if (Test-Path (Join-Path $r $GAME_EXE)) { return $r }
        try {
            $hit = Get-ChildItem -Path $r -Recurse -Filter $GAME_EXE -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { return $hit.Directory.FullName }
        } catch {}
    }
    return $null
}

# -------------------------------------------------------
# STEP 1: Pick install folder + DepotDownloader setup
# -------------------------------------------------------
Write-Header

Write-Host " OutwardVR by cybensis - a full 6DOF VR conversion of Outward Definitive" -ForegroundColor White
Write-Host " Edition with motion-controlled combat." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Pick install location + set up DepotDownloader"

Write-Host " Outward VR requires a specific older build of the game pinned" -ForegroundColor White
Write-Host " to the v1.0 Definitive Edition mono release. We'll use" -ForegroundColor White
Write-Host " DepotDownloader (open-source, SteamRE) to fetch the exact" -ForegroundColor White
Write-Host " pinned manifest. It logs into your Steam account just long" -ForegroundColor White
Write-Host " enough to download, same as any Steam client." -ForegroundColor White
Write-Host ""
Write-Host " Requirements:" -ForegroundColor Cyan
Write-Host " - A Steam account that owns Outward Definitive Edition" -ForegroundColor White
Write-Host " - Your Steam username (and password + Steam Guard code" -ForegroundColor White
Write-Host " if prompted - entered directly into DepotDownloader," -ForegroundColor White
Write-Host " never stored by this installer)" -ForegroundColor White
Write-Host ""

# Ask for install location
Write-Host " Where should the VR install live? (about 6 GB)" -ForegroundColor White
Write-Host " Default: $DEFAULT_INSTALL_PARENT\$INSTALL_FOLDER_NAME" -ForegroundColor Gray
Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$parentDir = (Read-Host " Press Enter for default, or type a different parent folder").Trim().Trim('"')
if (-not $parentDir) { $parentDir = $DEFAULT_INSTALL_PARENT }

if (-not (Test-Path $parentDir)) {
 try { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
 catch { Write-Fail "Could not create: $parentDir"; Pause-User "Press Enter to exit..."; exit 1 }
}

$installPath = Join-Path $parentDir $INSTALL_FOLDER_NAME
$downloadPath = Join-Path $parentDir $DOWNLOAD_FOLDER_NAME
if (Test-Path $installPath) {
 Write-Warn "A folder already exists at $installPath"
 Write-Host " [Y] Delete existing folder and proceed" -ForegroundColor White
 Write-Host " [N] Keep it, abort install" -ForegroundColor Gray
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Your choice (Y/N)").Trim() }
 if ($choice -in @("n","N")) {
 Write-Info "Aborted by user."
 Pause-User "Press Enter to exit..."
 exit 0
 }
 try { Remove-Item $installPath -Recurse -Force -ErrorAction Stop }
 catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
}
# Clear a leftover download folder from a previous interrupted run so
# the rename at the end has a clean target.
if (Test-Path $downloadPath) {
 try { Remove-Item $downloadPath -Recurse -Force -ErrorAction Stop }
 catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
}
try {
 New-Item -ItemType Directory -Path $downloadPath -Force -ErrorAction Stop | Out-Null
} catch {
 Write-Fail "Could not create the download folder: $downloadPath"
 Write-Host " $_" -ForegroundColor Gray
 Write-Host " Check the drive has space and you have write permission, then re-run." -ForegroundColor Yellow
 Pause-User "Press Enter to exit..."
 exit 1
}
Write-OK "Install target: $installPath"

# Download DepotDownloader to a temp folder next to the install
Write-Host ""
Write-Host " Downloading DepotDownloader $DD_VERSION ..." -ForegroundColor White

$toolsDir = Join-Path $env:TEMP "OutwardVRInstaller_$([System.IO.Path]::GetRandomFileName())"
try {
 New-Item -ItemType Directory -Path $toolsDir -Force -ErrorAction Stop | Out-Null
} catch {
 Write-Warn "Could not use TEMP for tools: $_"
 # Fallback: a tools folder next to the install instead of %TEMP%.
 $toolsDir = Join-Path $parentDir "_OutwardVR_tools"
 try {
 New-Item -ItemType Directory -Path $toolsDir -Force -ErrorAction Stop | Out-Null
 Write-Info "Using fallback tools folder: $toolsDir"
 } catch {
 Write-Fail "Could not create a working tools folder anywhere: $_"
 Write-Host " Free up disk space or check folder permissions, then re-run." -ForegroundColor Yellow
 Pause-User "Press Enter to exit..."
 exit 1
 }
}
$ddZip = Join-Path $toolsDir "DepotDownloader.zip"
$ddDir = Join-Path $toolsDir "DD"

try {
 Invoke-WebRequest -Uri $DD_URL -OutFile $ddZip -UseBasicParsing -ErrorAction Stop
 Expand-Archive -Path $ddZip -DestinationPath $ddDir -Force
 Write-OK "DepotDownloader ready."
} catch {
 Write-Fail "Could not download DepotDownloader: $_"
 Write-Host " Check your connection and try again." -ForegroundColor Gray
 $__fb = Invoke-InstallerFallback -Action "DepotDownloader setup" `
 -Url "https://github.com/SteamRE/DepotDownloader/releases" `
 -Instructions "Download 'DepotDownloader-windows-x64.zip' from the releases page and extract its contents into '$ddDir'. Then choose Retry." `
 -SkipMessage "Skipped - DepotDownloader is not available; the depot cannot be downloaded." `
 -SourceFolder (Split-Path "$ddZip" -Parent) `
 -DestFolder "$ddDir" `
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

$ddExe = Join-Path $ddDir "DepotDownloader.exe"
if (-not (Test-Path $ddExe)) {
 Write-Fail "DepotDownloader.exe not found after extraction."
 $__fb = Invoke-InstallerFallback -Action "DepotDownloader setup" `
 -Url "https://github.com/SteamRE/DepotDownloader/releases" `
 -Instructions "Download 'DepotDownloader-windows-x64.zip' from the releases page and extract its contents into '$ddDir' so 'DepotDownloader.exe' sits there. Then choose Retry." `
 -SkipMessage "Skipped - DepotDownloader is not available; the depot cannot be downloaded." `
 -SourceFolder (Split-Path "$ddZip" -Parent) `
 -DestFolder "$ddDir" `
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

# -------------------------------------------------------
# STEP 2: Run DepotDownloader
# -------------------------------------------------------
Write-Step 2 4 "Download pinned manifest via DepotDownloader"

Write-Host " Enter your Steam username (the one that owns Outward Definitive Edition)." -ForegroundColor White
Write-Host " DepotDownloader will prompt for your password and Steam Guard" -ForegroundColor Gray
Write-Host " code next - those go directly into the tool, not here." -ForegroundColor Gray
Write-Host ""

$steamUser = ""
while (-not $steamUser) {
 $steamUser = (Read-Host " Steam username").Trim()
 if (-not $steamUser) { Write-Fail "Username cannot be empty." }
}

Write-Host ""
Write-Host " Starting DepotDownloader..." -ForegroundColor White
Write-Host " -> It will prompt for your password in its own window." -ForegroundColor Yellow
Write-Host " -> If you have Steam Guard, you'll also be asked for the code" -ForegroundColor Yellow
Write-Host " that Steam emails you. Watch the window closely." -ForegroundColor Yellow
Write-Host " -> The download is ~5 GB - expect 5-20 minutes depending on" -ForegroundColor Yellow
Write-Host " your connection and Steam CDN availability." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to launch DepotDownloader..."

$ddArgs = @(
 "-app", $DD_APPID,
 "-depot", $DD_DEPOTID,
 "-manifest", $DD_MANIFEST,
 "-branch", $DD_BRANCH,
 "-username", $steamUser,
 "-dir", $downloadPath
)

try {
 # Launch DepotDownloader in its own console window. This keeps its
 # progress output (lots of \r carriage returns, live updates) from
 # corrupting OUR window's buffer. User still sees everything - DD's
 # window stays open until download completes.
 Write-Host " -> DepotDownloader is opening in a separate window." -ForegroundColor Cyan
 Write-Host " Complete the login there, then come back here." -ForegroundColor Gray
 Write-Host ""
 Write-Host " NOTE: You may see messages like 'Failed to download chunk'," -ForegroundColor Yellow
 Write-Host " 'connection timeout', or 'internal server error' during the" -ForegroundColor Yellow
 Write-Host " download. These are harmless - any failed chunk is retried" -ForegroundColor Yellow
 Write-Host " automatically until it succeeds." -ForegroundColor Yellow
 Write-Host ""
 $ddProc = Start-Process -FilePath $ddExe -ArgumentList $ddArgs `
 -WorkingDirectory $ddDir -Wait -PassThru
 if ($ddProc.ExitCode -ne 0) {
 Write-Fail "DepotDownloader exited with code $($ddProc.ExitCode)"
 Write-Host " Common causes:" -ForegroundColor Gray
 Write-Host " - Wrong password or Steam Guard code" -ForegroundColor Gray
 Write-Host " - Your account does not own Outward Definitive Edition" -ForegroundColor Gray
 Write-Host " - Your account has no access to the '$DD_BRANCH' branch" -ForegroundColor Gray
 Write-Host " (normally 'default-mono' is public - restart Steam and retry)" -ForegroundColor Gray
 Write-Host " - Temporary Steam CDN issue (try again in a few minutes)" -ForegroundColor Gray
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "DepotDownloader download" `
 -Url "https://github.com/SteamRE/DepotDownloader/releases" `
 -Instructions "The depot download did not complete. Make sure you own Outward Definitive Edition, close Steam, and retry." `
 -SkipMessage "Skipped - cannot fetch the depot version of this game." `
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
 Write-OK "Depot download complete."
} catch {
 Write-Fail "Could not start DepotDownloader: $_"
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "DepotDownloader download" `
 -Url "https://github.com/SteamRE/DepotDownloader/releases" `
 -Instructions "The depot download did not complete. Make sure you own Outward Definitive Edition, close Steam, and retry." `
 -SkipMessage "Skipped - cannot fetch the depot version of this game." `
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

# Locate the game EXE wherever DepotDownloader actually wrote it.
# Different depot layouts / drives can put it in slightly different
# places, so we SEARCH for the EXE rather than assume one fixed
# subfolder. Whatever folder holds the EXE becomes the game root.
$gameRoot = Find-GameRoot -Roots @((Join-Path $downloadPath $GAME_SUBDIR), $downloadPath, $parentDir)

# If still not found, let the user point us straight at the folder that
# DepotDownloader wrote (drag it into this window, or paste the path)
# and re-scan - WITHOUT re-downloading anything.
while (-not $gameRoot) {
    Write-Host ""
    Write-Fail "The download finished, but the game EXE wasn't found automatically."
    Write-Host "  DepotDownloader was told to write here:" -ForegroundColor Gray
    Write-Host "    $downloadPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Open that folder, find '$GAME_EXE', then give me the folder" -ForegroundColor White
    Write-Host "  that CONTAINS it. No need to download anything again." -ForegroundColor White
    Write-Host ""
    Write-Host "    [P] Paste or drag-and-drop that folder here" -ForegroundColor White
    Write-Host "    [R] I checked / moved it - scan again" -ForegroundColor White
    Write-Host "    [Q] Quit" -ForegroundColor Gray
    $pick = (Read-Marked "Your choice (P/R/Q)").Trim()
    if ($pick -match '^[Qq]') { Pause-User "Press Enter to exit..."; exit 1 }
    if ($pick -match '^[Pp]') {
        $typed = (Read-Marked "Folder path (drag the folder in, or paste it)").Trim().Trim('"')
        if ($typed) {
            $gameRoot = Find-GameRoot -Roots @($typed)
            if (-not $gameRoot) { Write-Warn "No '$GAME_EXE' found in or under that folder." }
        }
    } else {
        $gameRoot = Find-GameRoot -Roots @((Join-Path $downloadPath $GAME_SUBDIR), $downloadPath, $parentDir)
        if (-not $gameRoot) { Write-Warn "Still couldn't find '$GAME_EXE'. Check the download finished." }
    }
}

$defedPath = $gameRoot
$gameExe   = Join-Path $defedPath $GAME_EXE
# Keep $downloadPath pointing at the staging folder to be renamed later:
# the PARENT of an 'Outward_Defed' game root, otherwise the root itself.
if ((Split-Path $defedPath -Leaf) -ieq $GAME_SUBDIR) {
    $downloadPath = Split-Path $defedPath -Parent
} else {
    $downloadPath = $defedPath
}
Write-OK "Game files found: $defedPath"

# -------------------------------------------------------
# STEP 3: Install the VR mod
# -------------------------------------------------------
Write-Step 3 4 "Installing the VR mod"

$modTempDir = Join-Path $toolsDir "mod"
$modZip = Join-Path $toolsDir "OutwardVR.zip"

Write-Host " Downloading $MOD_NAME from GitHub..." -ForegroundColor White
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -ErrorAction Stop
 Write-OK "Mod downloaded."
} catch {
 Write-Fail "Mod download failed: $_"
 Write-Host ""
 Write-Host " Please download the mod manually from:" -ForegroundColor Yellow
 Write-Host " $GITHUB_URL/releases" -ForegroundColor Yellow
 Write-Host " Then extract the contents of the wrapper folder into:" -ForegroundColor Yellow
 Write-Host " $defedPath" -ForegroundColor Yellow
 $__fb = Invoke-InstallerFallback -Action "mod download" `
 -Url "$GITHUB_URL/releases" `
 -Instructions "Download 'OutwardVR-0.9.2.zip' from the releases page and save it as '$modZip'. Then choose Retry." `
 -SkipMessage "Skipped - the VR mod was NOT downloaded; the game will run without VR." `
 -DestFolder (Split-Path "$modZip" -Parent) `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Retry the actual mod download.
 try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -ErrorAction Stop
 Write-OK "Mod downloaded."
 } catch {
 Write-Warn "Mod still could not be downloaded: $_"
 Write-Host " Place 'OutwardVR-0.9.2.zip' at '$modZip' and re-run, or continue without VR." -ForegroundColor Gray
 }
 }
 # User chose Skip - continue at own risk
}

Write-Host " Extracting mod files..." -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $modZip -DestinationPath $modTempDir -Force -ErrorAction Stop
 Write-Host " OK" -ForegroundColor Green
} catch {
 Write-Host " FAILED" -ForegroundColor Red
 Write-Fail "Extraction failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$modTempDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$modTempDir" `
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

# The mod zip contains a wrapper folder 'OutwardVR-0.9.2/' - descend into it
$wrapper = Get-ChildItem -Path $modTempDir -Directory -Filter "OutwardVR-*" |
 Select-Object -First 1
if ($wrapper) {
 $sourceRoot = $wrapper.FullName
 Write-Info "Wrapper folder: $($wrapper.Name)"
} else {
 $sourceRoot = $modTempDir
 Write-Info "No wrapper folder found - using zip root."
}

Write-Host " Copying mod files into $GAME_SUBDIR ..." -NoNewline -ForegroundColor White
try {
 Get-ChildItem -Path $sourceRoot -Force | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $defedPath -Recurse -Force
 }
 Write-Host " OK" -ForegroundColor Green
 Write-OK "Mod installed to: $defedPath"
} catch {
 Write-Host " FAILED" -ForegroundColor Red
 Write-Fail "Copy failed: $_"
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files into '$defedPath'. Watch for UAC permission prompts. Then choose Skip below to continue with downstream installer steps." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -DestFolder "$defedPath" `
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

$bepinexPath = Join-Path $defedPath "BepInEx"
if (Test-Path $bepinexPath) {
 Write-OK "BepInEx structure confirmed at: $bepinexPath"
} else {
 Write-Warn "BepInEx folder not visible at expected location."
}

# Rename the download folder (no space, e.g. C:\Games\Outward) to the
# final install folder (C:\Games\Outward VR). Done now - after the mod
# is in place - so the whole VR install carries the proper name. Only
# rename when it stays within the same parent (Rename-Item can't move
# across folders/drives); otherwise the files are used where they are.
$sameParent = $false
try { $sameParent = ((Split-Path $downloadPath -Parent) -ieq (Split-Path $installPath -Parent)) } catch {}
$rootUnderDownload = $false
try { $rootUnderDownload = $defedPath.ToLower().StartsWith($downloadPath.ToLower()) } catch {}

if ($downloadPath -ne $installPath -and (Test-Path $downloadPath) -and $sameParent -and $rootUnderDownload) {
    try {
        if (Test-Path $installPath) { Remove-Item $installPath -Recurse -Force -ErrorAction Stop }
        Rename-Item -Path $downloadPath -NewName $INSTALL_FOLDER_NAME -ErrorAction Stop
        # Re-locate the EXE under the renamed folder (layout-agnostic).
        $newRoot = Find-GameRoot -Roots @($installPath)
        if ($newRoot) { $defedPath = $newRoot } else { $defedPath = Join-Path $installPath $GAME_SUBDIR }
        $gameExe = Join-Path $defedPath $GAME_EXE
        Write-OK "Renamed install folder to: $installPath"
    } catch {
        Write-Warn "Could not rename to '$INSTALL_FOLDER_NAME' - using '$downloadPath' instead."
        $installPath = $downloadPath
    }
} else {
    # EXE is not inside the staging folder (e.g. user pointed us at a
    # folder elsewhere) - use it in place, no rename.
    $installPath = Split-Path $defedPath -Parent
    Write-Info "Using the game files in place: $installPath"
}

# Drop a steam_appid.txt next to the EXE. Without this, Steam detects
# the running game, notices the Library entry isn't pointing here, and
# prompts the user to reinstall Outward. With this file, the Steam API
# knows which AppID this is and lets it run normally alongside Steam.
try {
 $steamAppIdFile = Join-Path $defedPath "steam_appid.txt"
 Set-Content -Path $steamAppIdFile -Value $DD_APPID -Encoding ASCII -NoNewline -Force
 Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
} catch {
 Write-Warn "Could not create steam_appid.txt: $_"
 Write-Host " If Steam prompts you to reinstall Outward Definitive Edition, manually create" -ForegroundColor Gray
 Write-Host " a file called 'steam_appid.txt' next to the game EXE," -ForegroundColor Gray
 Write-Host " containing just the number: $DD_APPID" -ForegroundColor Gray
}

# Record the install path for the Hub. Outward is installed in a user-
# chosen folder (e.g. C:\Games\Outward-VR), so the Hub can't guess where
# to look. Writing the actual game-root path here lets the Hub's card
# detection find the install and check for the VR mod presence.
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 # Hub stores the parent install folder; ModFile and LaunchExe
 # in the game-def are relative to it (Outward_Defed\...).
 Set-Content -Path $pathFile -Value $installPath -Encoding UTF8 -Force
} catch {}

# Clean up tools + temp
try { Remove-Item $toolsDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 4: Summary + Desktop Shortcut
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

Write-Host " Your Outward VR installation is ready." -ForegroundColor White
Write-Host ""
Write-Host " Game folder: $installPath" -ForegroundColor Yellow
Write-Host " Launch EXE: $gameExe" -ForegroundColor Yellow
Write-Host ""

Write-Host " IMPORTANT notes before you play:" -ForegroundColor Cyan
Write-Host ""
Write-Host " >> Launch SteamVR before the game to avoid it potentially" -ForegroundColor Yellow
Write-Host "    starting sometimes out of focus." -ForegroundColor Yellow
Write-Host " >> Launch with" -NoNewline -ForegroundColor Yellow; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub or the desktop" -ForegroundColor Yellow
Write-Host "    shortcut - NOT via Steam." -ForegroundColor Yellow
Write-Host " (This VR install is fully standalone and independent" -ForegroundColor Gray
Write-Host " from your Steam library copy of Outward.)" -ForegroundColor Gray
Write-Host ""
Write-Host " Quick control reminders:" -ForegroundColor White
Write-Host " - Melee: physically swing your weapon at the target" -ForegroundColor Gray
Write-Host " - Block: hold weapon parallel to your body (or right grip)" -ForegroundColor Gray
Write-Host " - Height recalibration: hold X button at preferred height" -ForegroundColor Gray
Write-Host " - Third-person toggle: hold right joystick for 1.5 seconds" -ForegroundColor Gray
Write-Host ""

# Desktop shortcut
if (Test-Path $gameExe) {
 try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Outward VR.lnk" -TargetPath $gameExe -WorkingDir $defedPath -IconPath "$gameExe,0"
 Write-OK "Desktop shortcut 'Outward VR' created."
 } catch {
 Write-Warn "Could not create shortcut: $_"
 Write-Host " Launch manually from:" -ForegroundColor Gray
 Write-Host " $gameExe" -ForegroundColor Yellow
 }
}

Write-Host ""
Write-Host " Opening installation folder..." -ForegroundColor Gray
try { Start-Process explorer.exe "`"$installPath`"" } catch {}

Write-Host ""
Write-Host " The wilds of Aurai await, Outlander." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
