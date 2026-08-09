# ============================================================
# Yooka-Laylee - VookaRaylee VR Mod Installer
# Two paths:
# A) Patch the current Steam install (default, works for most)
# B) Downgrade to v1.1.0 via Steam Console + desktop shortcut
# (use only if Option A has performance problems)
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Yooka-Laylee VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_APPID = "360830"
$GAME_NAME = "YookaLaylee"
$GAME_EXE = "YookaLaylee64.exe"
$MOD_URL = "https://github.com/Eusth/VookaRaylee/releases/download/v0.3/VookaRaylee-0.3.zip"
$MOD_INFO_URL = "https://github.com/Eusth/VookaRaylee"

# Version 1.1.0 (Apr/1/2019 - "64-Bit Tonic")
# First 64-bit build, predates the 1.2.0 Switch-geometry regression
# that causes VR performance issues.
$DEPOT_DEPOTID = "360832"
$DEPOT_MANIFEST = "8385432844974171919"
$DEPOT_COMMAND = "download_depot $GAME_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME = "Yooka-Laylee VR"
$DEFAULT_PATH = Join-Path $DEFAULT_PARENT $TARGET_NAME

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Yooka-Laylee - VookaRaylee VR Mod Installer" -ForegroundColor Cyan
 Write-Host " VookaRaylee v0.3 by Eusth (IPA / VRGIN based)" -ForegroundColor Gray
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

# -------------------------------------------------------
# Upfront choice
# -------------------------------------------------------
Write-Header

Write-Host " Pick an install path:" -ForegroundColor White
Write-Host ""
Write-Host " [A] Patch the current Steam version (recommended)" -ForegroundColor Yellow
Write-Host " Fast, simple, launches from Steam as usual." -ForegroundColor Gray
Write-Host " This works for most people." -ForegroundColor Gray
Write-Host ""
Write-Host " [B] Downgrade to v1.1.0 (64-Bit Tonic, Apr 2019)" -ForegroundColor Yellow
Write-Host " Only needed if Option A has bad VR performance." -ForegroundColor Gray
Write-Host " Downloads an older build via Steam Console," -ForegroundColor Gray
Write-Host " creates a desktop shortcut, not launched via Steam." -ForegroundColor Gray
Write-Host ""

$mode = ""
while ($mode -notin @("A","a","B","b")) { $mode = (Read-Host " Your choice (A/B)").Trim() }
$useDepot = ($mode -in @("B","b"))

# =======================================================
# PATH A: Patch current Steam install
# =======================================================
if (-not $useDepot) {

 Pause-User "Press Enter to start..."
 Write-Step 1 4 "Locating Yooka-Laylee"

 # --- Try detection library (safe: falls through to legacy lookup on failure) ---
 $gamePath = $null
 try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Yooka-Laylee" -ExeName $GAME_EXE
 }
 } catch {}
 # --- End detection library attempt ---

 if (-not $gamePath) {
 $steamPath = Get-SteamPath
 if (-not $steamPath) {
 Write-Warn "Could not find Steam installation in registry."
 Write-Host " Please enter your Steam installation path manually:" -ForegroundColor White
 while (-not $steamPath) {
 $rawInput = (Read-Host " Steam path").Trim().Trim('"')
 if (Test-Path $rawInput) { $steamPath = $rawInput; Write-OK "Steam path set: $steamPath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
 }

 $libraries = Get-SteamLibraries $steamPath
 foreach ($lib in $libraries) {
 $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $candidate) { $gamePath = $candidate; break }
 }
 }

 if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "360830" -SteamFolderNames @("YookaLaylee") -ProbeExe "YookaLaylee64.exe" -GogNames @("Yooka-Laylee") }
 if (-not $gamePath) {
 Write-Warn "Yooka-Laylee not found in Steam libraries automatically."
 Write-Host " Please enter the game folder manually:" -ForegroundColor White
 while (-not $gamePath) {
 $rawInput = (Read-Host " YookaLaylee path").Trim().Trim('"')
 if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path set: $gamePath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
 } else {
 Write-OK "Yooka-Laylee found: $gamePath"
 }

 $gameExePath = Join-Path $gamePath $GAME_EXE
 if (-not (Test-Path $gameExePath)) {
 Write-Fail "$GAME_EXE not found in game folder."
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
}

# =======================================================
# PATH B: Depot downgrade to v1.1.0
# =======================================================
else {

 Write-Step 1 5 "Steam Depot Download (v1.1.0)"

 Write-Host " Downloading v1.1.0 '64-Bit Tonic' (Apr 2019), the last" -ForegroundColor White
 Write-Host " build before 1.2.0 introduced a potential VR performance regression." -ForegroundColor White
 Write-Host ""
 Write-Host " Here's what's about to happen:" -ForegroundColor Cyan
 Write-Host " 1) The Steam Console will open automatically" -ForegroundColor White
 Write-Host " 2) The download command is already on your clipboard" -ForegroundColor White
 Write-Host " 3) Paste with Ctrl+V into the Steam Console and hit Enter" -ForegroundColor Yellow
 Write-Host " 4) Wait for Steam to finish, then come back here" -ForegroundColor White
 Write-Host ""
 Write-Host " When Steam finishes it will show:" -ForegroundColor Gray
 Write-Host " Depot download complete : ...\depot_$DEPOT_DEPOTID" -ForegroundColor Yellow
 Write-Host ""

 try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
 Write-Host ""
 Write-Host " Press Enter to open the Steam Console..." -ForegroundColor Yellow
 Write-Host " Then click the input field, paste (Ctrl+V) and hit Enter." -ForegroundColor Yellow
 Write-Host ""
 Write-Host ""
 if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
 Write-Host " (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
 Write-Host "     automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
 Write-Host "     doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
 Write-Host "     then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
 Write-Host "     next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
 Write-Host ""
 }
 Pause-User "Press Enter to open the Steam Console..."
 # Beide Protokoll-Adressen: je nach Steam-Version zieht nur eine.
 foreach ($cu in @("steam://open/console", "steam://nav/console")) {
     try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
 }
 Write-OK "Steam Console opening..."

 Write-Host ""
 Pause-User "Press Enter once the Steam depot download is complete..."

 # Find depot
 Write-Host ""
 Write-Host " Looking for Steam installation..." -ForegroundColor White
 $steamInstallPath = Get-SteamPath
 $depotPath = $null
 if ($steamInstallPath) {
 $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$GAME_APPID\depot_$DEPOT_DEPOTID"
 Write-Info "Expected depot path: $autoPath"
 if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) {
 $depotPath = $autoPath
 Write-OK "Depot folder found automatically!"
 } else {
 Write-Warn "Depot folder not found at expected location."
 }
 }
 if (-not $depotPath) {
 $probePaths = @()
 if ($steamInstallPath) {
 $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$GAME_APPID\depot_$DEPOT_DEPOTID")
 }
 $depotPath = Resolve-DepotPath -GameName "Yooka-Laylee" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $GAME_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
 if (-not $depotPath) {
 Write-Fail "No depot folder provided."
 Pause-User "Press Enter to exit..."
 exit 1
 }
 }

 $depotExe = Join-Path $depotPath $GAME_EXE
 if (-not (Test-Path $depotExe)) {
 Write-Fail "$GAME_EXE not found inside depot folder."
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
 Write-OK "$GAME_EXE is present in depot folder."

 # Move & rename
 Write-Step 2 5 "Moving game to stable folder"

 $parentOfDepot = Split-Path $depotPath -Parent # ...\app_360830

 Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
 Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
 Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
 Write-Host ""
 $userInput = (Read-Host " Press Enter to use default, or type a different full path").Trim().Trim('"')
 if (-not $userInput) {
 $targetPath = $DEFAULT_PATH
 } else {
 $targetPath = $userInput
 }

 $targetParent = Split-Path $targetPath -Parent
 if ($targetParent -and -not (Test-Path $targetParent)) {
 try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
 catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
 }

 Write-Host ""
 Write-Host " Current location: $depotPath" -ForegroundColor Gray
 Write-Host " Moving to: $targetPath" -ForegroundColor Gray
 Write-Host ""

 if (Test-Path $targetPath) {
 Write-Warn "A folder already exists at $targetPath"
 Write-Host " This may be from a previous install. Delete it to continue?" -ForegroundColor White
 Write-Host " [Y] Delete existing folder and proceed" -ForegroundColor White
 Write-Host " [N] Keep it, abort install" -ForegroundColor Gray
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Your choice (Y/N)").Trim() }
 if ($choice -in @("n","N")) {
 Write-Info "Aborted by user."
 Pause-User "Press Enter to exit..."
 exit 0
 }
 try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
 catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
 }

 try {
 Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
 Write-OK "Game moved to: $targetPath"
 } catch {
 Write-Fail "Move failed: $_"
 Write-Info "The game files are still at: $depotPath"
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Create the folder manually (right-click in Explorer -> New folder), or choose a different path with write permission." `
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

 # Clean up empty app_360830 folder
 try {
 if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
 Remove-Item $parentOfDepot -Force
 }
 } catch {}

 $gamePath = $targetPath
try { Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value "538210" -Encoding ASCII -NoNewline -Force } catch {}

# Write .installed_path for Hub detection
try {
 Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
} catch {}
 $gameExePath = Join-Path $gamePath $GAME_EXE
}

# =======================================================
# SHARED STEPS: Download mod + IPA patch + summary
# =======================================================

if ($useDepot) { $stepBase = 2; $stepTotal = 5 } else { $stepBase = 1; $stepTotal = 4 }

Write-Step ($stepBase + 1) $stepTotal "Downloading VookaRaylee v0.3"

[System.Net.ServicePointManager]::SecurityProtocol = `
 [System.Net.ServicePointManager]::SecurityProtocol -bor `
 [System.Net.SecurityProtocolType]::Tls12

$tempDir = Join-Path $env:TEMP "YookaVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$zipPath = Join-Path $tempDir "VookaRaylee.zip"
$extractDir = Join-Path $tempDir "extract"

Write-Host " Downloading from GitHub ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download error: $_"
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

Write-Host " Extracting ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Extract error: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$zipPath' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder "$zipPath" `
 -DestFolder "$extractDir" `
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

$payloadRoot = $extractDir
$ipaCheck = Get-ChildItem -Path $extractDir -Filter "IPA.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ipaCheck) { $payloadRoot = $ipaCheck.Directory.FullName }

Write-Host " Copying mod files into game folder ... " -NoNewline -ForegroundColor White
try {
 $rc = @($payloadRoot, $gamePath, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/R:2", "/W:1")
 & robocopy @rc | Out-Null
 if ($LASTEXITCODE -ge 8) { throw "robocopy exit code $LASTEXITCODE" }
 Write-Host "OK" -ForegroundColor Green
 Write-OK "Mod files installed."
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Copy error: $_"
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files from '$payloadRoot' into '$gamePath' (your Yooka-Laylee install). Watch for UAC permission prompts. Then choose Skip to continue." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -SourceFolder "$payloadRoot" `
 -DestFolder "$gamePath" `
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

# IPA patch
Write-Step ($stepBase + 2) $stepTotal "Patching game with IPA"

$ipaExe = Join-Path $gamePath "IPA.exe"
if (-not (Test-Path $ipaExe)) {
 Write-Fail "IPA.exe was not found in the game folder after extraction."
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Create the folder manually (right-click in Explorer -> New folder), or choose a different path with write permission." `
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

Write-Host " Running: IPA.exe `"$GAME_EXE`" --nowait" -ForegroundColor Gray
Write-Host " (equivalent of dragging $GAME_EXE onto IPA.exe)" -ForegroundColor Gray
Write-Host ""
try {
 $proc = Start-Process -FilePath $ipaExe `
 -ArgumentList @("`"$gameExePath`"", "--nowait") `
 -WorkingDirectory $gamePath `
 -Wait -PassThru -ErrorAction Stop
 if ($proc.ExitCode -ne 0) {
 Write-Warn "IPA exited with code $($proc.ExitCode). Patch may have had issues."
 } else {
 Write-OK "IPA patching completed."
 }
} catch {
 Write-Fail "Could not run IPA.exe: $_"
 Write-Warn "You can patch manually: drag $GAME_EXE onto IPA.exe in the game folder."
 Pause-User "Press Enter to continue anyway..."
}

# Desktop shortcut (only in depot mode - Steam already has the launch button in path A)
if ($useDepot) {
 Write-Step 5 5 "Desktop Shortcut"

 $shortcutPath = Join-Path $env:USERPROFILE "Desktop\Yooka-Laylee VR.lnk"
 try {
 $sc = New-DesktopShortcut -LnkPath $shortcutPath -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0"
 Write-OK "Desktop shortcut 'Yooka-Laylee VR' created."
 } catch {
 Write-Warn "Could not create desktop shortcut: $_"
 Write-Info "You can create one manually, pointing at: $gameExePath"
 }
}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Magenta
if ($useDepot) {
 Write-Host " Mode: Depot downgrade (v1.1.0 64-Bit Tonic)" -ForegroundColor Gray
} else {
 Write-Host " Mode: Patched current Steam install" -ForegroundColor Gray
}
Write-Host " Install path: $gamePath" -ForegroundColor Gray
Write-Host " Game exe: $GAME_EXE (patched with VookaRaylee)" -ForegroundColor Gray
Write-Host " VR settings: vr_settings.xml in the game folder" -ForegroundColor Gray
Write-Host ""

Write-Host "--- How to play ---" -ForegroundColor Cyan
Write-Host " 1. Start SteamVR" -ForegroundColor White
if ($useDepot) {
 Write-Host " 2. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host "    'Yooka-Laylee VR' desktop shortcut" -ForegroundColor White
 Write-Host " NOT via Steam - Steam would replace this version!" -ForegroundColor Yellow
} else {
 Write-Host " 2. Launch Yooka-Laylee from Steam as usual" -ForegroundColor White
}
Write-Host " 3. (If a message about 'VR not supported' appears, just click it away)" -ForegroundColor Gray
Write-Host " 4. VR mode activates automatically" -ForegroundColor White
Write-Host ""

Write-Host " Mod page: $MOD_INFO_URL" -ForegroundColor Gray
Write-Host ""
Write-Host " Grab the quill, find the Pagies - now in glorious 3D." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the game folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
