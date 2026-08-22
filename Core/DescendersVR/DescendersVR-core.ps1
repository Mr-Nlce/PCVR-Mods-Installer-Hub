# ============================================================
# Descenders VR Mod Installer
# Mod by Holydh, a fork of kyanite-rock - the newest build is fetched
# https://github.com/kyanite-rock/DescendersVRMod
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Descenders VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Descenders"
$GAME_EXE = "Descenders.exe"
$STEAM_APP_ID = "681280"
# !!! A FIXED ADDRESS FOR v1.0.5 USED TO STAND HERE - EVERY NEW BUILD
# WOULD HAVE PASSED US BY !!! After a long pause the author published
# v1.0.6 (support for the "Community Gear Update"), and the installer
# would have kept fetching 1.0.5.
# The newest build is now resolved at run time; the fixed address is only
# the no-network fallback.
$MOD_REPO = "kyanite-rock/DescendersVRMod"
$PINNED_TAG = "descenders_vr_mod_v1.0.6"
$MOD_URL = "https://github.com/$MOD_REPO/releases/download/$PINNED_TAG/DescendersVRMod_v1.0.6.zip"

# Fetch the newest build from GitHub. The asset is matched by its NAME
# (DescendersVRMod*.zip), not by the version number - that way a rename
# breaks nothing.
function Get-DescendersLatest {
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$MOD_REPO/releases/latest" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
        foreach ($a in @($rel.assets)) {
            if ($a.name -match '(?i)^DescendersVRMod.*\.zip$') {
                return @{ Url = [string]$a.browser_download_url; Name = [string]$a.name; Tag = [string]$rel.tag_name }
            }
        }
    } catch {}
    return $null
}
$rel = Get-DescendersLatest
if ($rel) {
    $MOD_URL    = $rel.Url
    $PINNED_TAG = $rel.Tag
    $MOD_ZIPNAME = $rel.Name
} else {
    $MOD_ZIPNAME = "DescendersVRMod_v1.0.6.zip"
}

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host " Descenders VR Mod Installer" -ForegroundColor Magenta; Write-Host " Installs: DescendersVRMod $PINNED_TAG by Holydh / kyanite-rock" -ForegroundColor Gray; Write-Host " Note: Gamepad ONLY - no motion controls, no KB&M ingame" -ForegroundColor Yellow; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
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

Write-Header

# ------------------------------------------------------------
# Critical pre-installation warning
# ------------------------------------------------------------
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " IMPORTANT - READ BEFORE INSTALLING" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Descenders is GAMEPAD ONLY in VR." -ForegroundColor White
Write-Host " The mod uses an XInput-only controller plugin (OVRGamepad.dll)." -ForegroundColor Gray
Write-Host ""
Write-Host " To avoid controller dropouts and dead inputs:" -ForegroundColor White
Write-Host ""
Write-Host " * Have ONLY ONE gamepad connected when playing." -ForegroundColor White
Write-Host " Disconnect HOTAS, wheels, joysticks, second pads." -ForegroundColor Gray
Write-Host ""
Write-Host " * Quest 3 + Virtual Desktop users:" -ForegroundColor White
Write-Host " Enable 'Gamepad Mode' in VD BEFORE launching the game." -ForegroundColor Gray
Write-Host ""
Write-Host " * If your pad is DInput-only (older 8BitDo, vJoy, etc):" -ForegroundColor White
Write-Host " use an XInput wrapper like x360ce - native DInput won't work." -ForegroundColor Gray
Write-Host ""
Write-Host " * Steam Input override will be set to 'Enable Steam Input'" -ForegroundColor White
Write-Host " later in this installer - this is the most reliable fix." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to continue..."

# ------------------------------------------------------------
# STEP 1: Locate Descenders
# ------------------------------------------------------------
Write-Step 1 6 "Locating Descenders"

$gamePath = $null
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Descenders VR" -AppID $STEAM_APP_ID -ExeName $GAME_EXE
 }
} catch {}

if (-not $gamePath) {
 $steamPath = Get-SteamPath
 if ($steamPath) {
 foreach ($lib in (Get-SteamLibraries $steamPath)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $c) { $gamePath = $c; break }
 }
 }
}

if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "681280" -SteamFolderNames @("Descenders") -EpicNames @("Descenders") }
if ($gamePath) {
 Write-Info "Game found: $gamePath"
} else {
 Write-Warn "Descenders not found automatically."
 Write-Host " Please enter the game installation folder:" -ForegroundColor White
 Write-Host " Example: C:\Program Files (x86)\Steam\steamapps\common\Descenders" -ForegroundColor Gray
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path $r){$gamePath=$r; Write-Info "Path set: $gamePath"} else{Write-Fail "Not found: $r"}
 }
}

$gameExe = Join-Path $gamePath $GAME_EXE
if (Test-Path $gameExe) { Write-OK "EXE verified: $GAME_EXE" }
else { Write-Warn "$GAME_EXE not found - path may still be correct." }

$gameDataDir = Join-Path $gamePath "Descenders_Data"
if (-not (Test-Path $gameDataDir)) {
 Write-Fail "Descenders_Data folder not found at: $gameDataDir"
 Write-Fail "This does not look like a valid Descenders installation."
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "game install verification" `
 -Instructions "Verify the game is installed via Steam and its folder contains the expected Data subfolder. Re-run after installing the game." `
 -SkipMessage "Skipped - cannot verify game; mod copy may fail." `
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

# ------------------------------------------------------------
# STEP 2: Select VR Platform
# ------------------------------------------------------------
Write-Step 2 6 "Select VR Platform"

Write-Host " Which VR runtime do you want the mod to use?" -ForegroundColor White
Write-Host ""
Write-Host " [1] SteamVR (Quest via Link/Air Link/Virtual Desktop SteamVR, Index, Pico, etc.)" -ForegroundColor White
Write-Host " [2] Oculus (Quest via Oculus PC app / native Oculus Link)" -ForegroundColor White
Write-Host ""
Write-Host " Tip: If unsure, pick SteamVR. Most setups including Virtual Desktop work on it." -ForegroundColor Gray
Write-Host ""
$vrMode = ""
while ($vrMode -notin @("1","2")) { $vrMode = (Read-Host " Enter 1 or 2").Trim() }
if ($vrMode -eq "1") {
 $vrModeText = "SteamVR"
 $launchOptions = "-vrmode OpenVR"
} else {
 $vrModeText = "Oculus"
 $launchOptions = "-vrmode Oculus"
}
Write-OK "VR platform selected: $vrModeText (launch option: $launchOptions)"

# ------------------------------------------------------------
# STEP 3: Backup original globalgamemanagers
# ------------------------------------------------------------
Write-Step 3 6 "Backing Up Original Game Files"

$ggmPath = Join-Path $gameDataDir "globalgamemanagers"
$ggmBak = Join-Path $gameDataDir "globalgamemanagers.flatbackup"

if (Test-Path $ggmBak) {
 Write-Info "Existing flat backup detected - keeping it (so VR doesn't overwrite it)."
} elseif (Test-Path $ggmPath) {
 Copy-Item -Path $ggmPath -Destination $ggmBak -Force
 Write-OK "Flat 'globalgamemanagers' backed up as 'globalgamemanagers.flatbackup'."
} else {
 Write-Warn "Original globalgamemanagers not found - skipping backup."
}

# ------------------------------------------------------------
# STEP 4: Download and Install Mod
# ------------------------------------------------------------
Write-Step 4 6 "Downloading and Installing VR Mod"

$tempDir = Join-Path $env:TEMP "DescendersVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$modZip = Join-Path $tempDir $MOD_ZIPNAME
Write-Host " Downloading $MOD_ZIPNAME ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Host " $_" -ForegroundColor Gray
 Write-Host ""
 Write-Host " Manual download fallback:" -ForegroundColor Yellow
 Write-Host " $MOD_URL" -ForegroundColor White
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files into '$ggmBak'. Watch for UAC permission prompts. Then choose Skip below to continue with downstream installer steps." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -DestFolder "$ggmBak" `
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

# Extract to temp first so we can move the inner folder contents into the game folder
$extractDir = Join-Path $tempDir "extracted"
Write-Host " Extracting archive ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $modZip -DestinationPath $extractDir -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Host " $_" -ForegroundColor Gray
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
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

# The archive has a wrapper folder with the version in its name
# (DescendersVRMod_v1.0.6 and so on) - so the FIRST subfolder is taken,
# not a fixed name.
$inner = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
if (-not $inner) {
 Write-Fail "Extracted archive does not contain expected folder structure."
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
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

Write-Host " Copying VR mod files into game folder ... " -NoNewline -ForegroundColor White
try {
 # Copy contents of the inner folder (BepInEx, Descenders_Data, doorstop_config.ini, winhttp.dll)
 Copy-Item -Path (Join-Path $inner.FullName "*") -Destination $gamePath -Recurse -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Host " $_" -ForegroundColor Gray
 $__fb = Invoke-InstallerFallback -Action "BepInEx download" `
 -Url "https://github.com/BepInEx/BepInEx/releases" `
 -Instructions "Open https://github.com/BepInEx/BepInEx/releases in the browser, download BepInEx 5.x Windows x64 ZIP, extract it directly into '$gamePath', then choose Retry." `
 -SkipMessage "Skipped - the mod loader will be missing; the VR mod will not load." `
 -DestFolder "$gamePath" `
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

# Verify key files
$verifyTargets = @(
 "winhttp.dll",
 "BepInEx\plugins\DescendersVRmod.dll",
 "Descenders_Data\Plugins\OVRGamepad.dll",
 "Descenders_Data\Plugins\openvr_api.dll"
)
$missing = @()
foreach ($t in $verifyTargets) {
 $tp = Join-Path $gamePath $t
 if (-not (Test-Path $tp)) { $missing += $t }
}
if ($missing.Count -eq 0) {
 Write-OK "All VR mod files installed correctly."
} else {
 Write-Warn "Some files appear to be missing:"
 foreach ($m in $missing) { Write-Host " - $m" -ForegroundColor Yellow }
}

# Write a small marker file so VR mode is identifiable later
$vrModeTxt = Join-Path $gamePath "VRMODE.txt"
Set-Content -Path $vrModeTxt -Value $vrModeText -Encoding ASCII -NoNewline
Write-OK "VRMODE.txt written: $vrModeText"

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ------------------------------------------------------------
# STEP 5: Steam Launch Options
# ------------------------------------------------------------
Write-Step 5 6 "Steam Launch Options"

try { Set-Clipboard -Value $launchOptions } catch {}

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Steam Launch Options" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Launch parameter copied to clipboard: $launchOptions" -ForegroundColor White
Write-Host ""
Write-Host " When Steam Properties open:" -ForegroundColor White
Write-Host " 1. Find the 'Launch Options' field at the bottom" -ForegroundColor Gray
Write-Host " 2. Paste with Ctrl+V" -ForegroundColor Gray
Write-Host " 3. Close the Properties window" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to open Steam Launch Options..."

Start-Process "steam://gameproperties/$STEAM_APP_ID"
try { Set-Clipboard -Value $launchOptions } catch {}

Pause-User "Press Enter once you have pasted the launch option and closed Properties..."

# ------------------------------------------------------------
# STEP 5b: Steam Input Override
# ------------------------------------------------------------
Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Steam Controller Settings" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Descenders' built-in gamepad plugin has issues with many" -ForegroundColor White
Write-Host " controllers. Forcing 'Enable Steam Input' is the most" -ForegroundColor White
Write-Host " reliable fix and recommended by PCGamingWiki." -ForegroundColor White
Write-Host ""
Write-Host " In the Steam Properties window that opens next:" -ForegroundColor White
Write-Host " 1. Click the 'Controller' tab on the left" -ForegroundColor Gray
Write-Host " 2. Set 'Override for Descenders' to 'Enable Steam Input'" -ForegroundColor Gray
Write-Host " 3. Close the Properties window" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to open Steam Properties (Controller tab)..."

Start-Process "steam://gameproperties/$STEAM_APP_ID"

Pause-User "Press Enter once you have set the controller override and closed Properties..."

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# ------------------------------------------------------------
# STEP 6: Desktop Shortcut + Final Notes
# ------------------------------------------------------------
Write-Step 6 6 "Creating Desktop Shortcut"

try {
  $shortcut = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Descenders VR.lnk" -TargetPath "steam://rungameid/$STEAM_APP_ID" -IconPath "$gameExe,0" -Description "Descenders VR ($vrModeText)"
 Write-OK "Desktop shortcut 'Descenders VR' created (launches via Steam)."
} catch {
 Write-Warn "Could not create shortcut: $_"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host " Platform: $vrModeText" -ForegroundColor White
Write-Host " Launch option: $launchOptions" -ForegroundColor White
Write-Host ""
Write-Host " In-game graphics settings (do this on first launch):" -ForegroundColor Yellow
Write-Host " * Disable Depth of Field" -ForegroundColor Gray
Write-Host " * Disable Bloom" -ForegroundColor Gray
Write-Host " * Disable VSync" -ForegroundColor Gray
Write-Host ""
Write-Host " Controller checklist before each play session:" -ForegroundColor Yellow
Write-Host " * Only ONE gamepad connected" -ForegroundColor Gray
Write-Host " * Virtual Desktop: enable Gamepad Mode BEFORE starting the game" -ForegroundColor Gray
Write-Host " * If controls die: restart the game with the pad already connected" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch back to flat (non-VR) version anytime:" -ForegroundColor Yellow
Write-Host " Replace Descenders_Data\globalgamemanagers with .flatbackup" -ForegroundColor Gray
Write-Host " and rename BepInEx\plugins\DescendersVRmod.dll to .dll.off" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Send it. Send it harder. Send it in VR." -ForegroundColor Magenta
Write-Host ""

try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
Pause-User "Press Enter to exit."
