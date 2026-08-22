# ============================================================
# Metal: Hellsinger VR Mod Installer (HellsingerVR by LivingFray)
# ============================================================
#
# Installs HellsingerVR v0.9.0 onto a PINNED Steam depot build of
# Metal: Hellsinger. The mod requires this exact build - the
# current retail version has broken motion-control weapon
# rendering. We download the pinned build via the Steam Console
# depot command, move it to its own folder, then extract the
# self-contained BepInEx mod on top.
#
# NOTE: An OFFICIAL VR version of Metal: Hellsinger now exists with
# further improvements and performance work:
#   https://store.steampowered.com/app/2878270/Metal_Hellsinger_VR/
# This installer is the community-mod route.
#
# Flow:
#   1) Steam Console download_depot for the pinned manifest
#      (separate copy - your retail Metal: Hellsinger stays untouched)
#   2) Move/rename the depot folder to C:\Games\Metal Hellsinger VR
#   3) Download + extract HellsingerVR v0.9.0 into the game folder
#   4) steam_appid.txt + desktop shortcut + summary
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Metal Hellsinger VR Installer"
$ErrorActionPreference = "Stop"

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
$MOD_URL    = "https://github.com/LivingFray/HellsingerVR/releases/download/0.9.0/Hellsinger_0.9.0.zip"
$MOD_NAME   = "HellsingerVR v0.9.0"
$MOD_AUTHOR = "LivingFray"
$GITHUB_URL = "https://github.com/LivingFray/HellsingerVR"
$OFFICIAL_VR_URL = "https://store.steampowered.com/app/2878270/Metal_Hellsinger_VR/"

# Steam depot - Metal: Hellsinger, pinned build that works with the mod
$DEPOT_APPID    = "1061910"
$DEPOT_DEPOTID  = "1061912"
$DEPOT_MANIFEST = "5779027394296334621"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Target folder - the depot is moved out of steamapps\content into a
# stable location so Steam never overwrites it on a future download.
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME    = "Metal Hellsinger VR"
$DEFAULT_PATH   = Join-Path $DEFAULT_PARENT $TARGET_NAME

# Game executable + the mod plugin we verify after extraction
$GAME_EXE   = "Metal.exe"
$MOD_PROBE  = "BepInEx\plugins\HellsingerVR.dll"

# -------------------------------------------------------
# Console helpers (each installer defines its own)
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Metal: Hellsinger VR - Mod Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header
Write-Host "  Metal: Hellsinger is a rhythm FPS - shoot, dash and slaughter" -ForegroundColor Gray
Write-Host "  demons to the beat of a metal soundtrack. This installs the free" -ForegroundColor Gray
Write-Host "  community HellsingerVR mod onto a pinned Steam depot build (the" -ForegroundColor Gray
Write-Host "  current retail build has broken motion-control weapon rendering)." -ForegroundColor Gray
Write-Host ""
Write-Host "  NOTE: An OFFICIAL VR version now exists with extra improvements" -ForegroundColor Yellow
Write-Host "  and performance optimizations. If you want the most polished" -ForegroundColor Yellow
Write-Host "  experience, consider the official release instead:" -ForegroundColor Yellow
Write-Host "   -> $OFFICIAL_VR_URL" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  You need to own Metal: Hellsinger on Steam for the depot download." -ForegroundColor Gray
Pause-User "Press Enter to continue with the community-mod install..." | Out-Null

# -------------------------------------------------------
# STEP 1: Steam depot download
# -------------------------------------------------------
Write-Step 1 4 "Steam depot download"
Write-Host "  We download the pinned build as a separate copy - your retail" -ForegroundColor White
Write-Host "  Metal: Hellsinger stays untouched." -ForegroundColor White
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "  ACTION REQUIRED - Paste into the Steam Console" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Depot command copied to your clipboard:" -ForegroundColor Yellow
Write-Host "       $DEPOT_COMMAND" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press Enter to open the Steam Console, then click the input" -ForegroundColor Yellow
Write-Host "  field, paste (Ctrl+V) and hit Enter. Wait for it to finish." -ForegroundColor Yellow
Write-Host ""
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
    Write-Host "  (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
    Write-Host "      from inside a VD session. If it doesn't, open it manually:" -ForegroundColor DarkGray
    Write-Host "      Steam menu bar - View - Console, then paste-and-Enter." -ForegroundColor DarkGray
    Write-Host ""
}
Pause-User "Press Enter to open the Steam Console..." | Out-Null
# Both protocol addresses: depending on the Steam build only one works.
$conOk = $false
foreach ($cu in @("steam://open/console", "steam://nav/console")) {
    try { Start-Process $cu; $conOk = $true; Start-Sleep -Milliseconds 900 } catch {}
}
if (-not $conOk) {
    Write-Warn "Could not open the Steam Console automatically."
    Write-Host "  Open Steam, then: View - Console, and paste the command above." -ForegroundColor Gray
}
Write-Info "Steam Console opening..."
Write-Host ""
Pause-User "Press Enter once the depot download is COMPLETE..." | Out-Null

# -------------------------------------------------------
# Locate the depot folder
# -------------------------------------------------------
Write-Host ""
Write-Host "  Locating depot folder..." -ForegroundColor White

$steamInstallPath = $null
foreach ($reg in @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$depotPath = $null
if ($steamInstallPath) {
    $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
    Write-Info "Expected depot path: $autoPath"
    if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) {
        $depotPath = $autoPath
        Write-Info "Depot folder found automatically."
    } else {
        Write-Warn "Depot folder not found yet (download may still be running)."
    }
} else {
    Write-Warn "Could not find Steam in the registry."
}

if (-not $depotPath) {
    $probePaths = @()
    if ($steamInstallPath) {
        $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID")
    }
    $depotPath = Resolve-DepotPath -GameName "Metal Hellsinger" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided - cannot continue."
        Write-Host "  Re-run the installer once the depot download has finished," -ForegroundColor Gray
        Write-Host "  or use the DepotDownloader fallback option when prompted." -ForegroundColor Gray
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}

$depotExe = Join-Path $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
    Write-Warn "'$GAME_EXE' not found inside the depot - download may be incomplete."
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Continue anyway? (Y/N)").Trim() }
    if ($choice -in @("n","N")) { Write-Info "Aborted by user."; Pause-User "Press Enter to exit..." | Out-Null; exit 0 }
} else {
    Write-Info "$GAME_EXE confirmed in the depot."
}

# -------------------------------------------------------
# STEP 2: Move & rename the depot folder
# -------------------------------------------------------
Write-Step 2 4 "Moving the game to a stable folder"
$parentOfDepot = Split-Path $depotPath -Parent

Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use default, or type a different full path").Trim().Trim('"')
$targetPath = if (-not $userInput) { $DEFAULT_PATH } else { $userInput }

$targetParent = Split-Path $targetPath -Parent
if ($targetParent -and -not (Test-Path $targetParent)) {
    try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
    catch {
        Write-Fail "Could not create parent folder $targetParent : $_"
        $__fb = Invoke-InstallerFallback -Action "create the install folder" `
            -Instructions "Create the folder '$targetParent' manually (or pick a writable location), then choose Retry." `
            -DestFolder "$targetParent" -AllowSkip $false
        if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
    }
}

if (Test-Path $targetPath) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Info "Merging the pinned build; saves, BepInEx configs/plugins and other additional files are preserved."
}

Write-Host ""
Write-Host "  Installing from: $depotPath" -ForegroundColor Gray
Write-Host "      to: $targetPath" -ForegroundColor Gray
$moved = $false
while (-not $moved) {
    try {
        $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "Metal Hellsinger depot build"
        $moved = $true
        Write-Info "Game installed at: $targetPath"
    } catch {
        Write-Fail "Merge failed: $_"
        $__fb = Invoke-InstallerFallback -Action "merge the depot files into the install folder" `
            -Instructions "Copy the contents of '$depotPath' into '$targetPath' without deleting additional destination files, then choose Retry." `
            -SourceFolder "$depotPath" -DestFolder "$targetPath" -AllowSkip $true
        if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        if ([string]$__fb -eq "skip") { $targetPath = $depotPath; $moved = $true }
        elseif (Test-Path $targetPath) { $moved = $true }
    }
}

try {
    if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Item $parentOfDepot -Force -ErrorAction SilentlyContinue
    }
} catch {}

$gamePath    = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
# STEP 3: Download + extract the HellsingerVR mod
# -------------------------------------------------------
Write-Step 3 4 "Installing $MOD_NAME"

$tempDir = Join-Path $env:TEMP "MetalHellsingerVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$modZip     = Join-Path $tempDir "HellsingerVR.zip"
$modExtract = Join-Path $tempDir "HellsingerVR"

$modDone = $false
while (-not $modDone) {
    Write-Host "  Downloading $MOD_NAME ... " -NoNewline -ForegroundColor White
    $dlOk = $false
    try {
        Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -ErrorAction Stop
        Write-Host "OK" -ForegroundColor Green
        $dlOk = $true
    } catch {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Fail "Mod download failed: $_"
        Write-Host "  Download it manually from:" -ForegroundColor Yellow
        Write-Host "   $GITHUB_URL/releases" -ForegroundColor Yellow
        Write-Host "  Save '$([System.IO.Path]::GetFileName($MOD_URL))' to: $tempDir" -ForegroundColor Yellow
        $__fb = Invoke-InstallerFallback -Action "download the HellsingerVR mod" `
            -Subject "$MOD_NAME" -Url "$GITHUB_URL/releases" `
            -Instructions "Download the mod ZIP from the releases page and save it as '$modZip'. Then choose Retry." `
            -DestFolder "$tempDir" -AllowSkip $false
        if ([string]$__fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        if (Test-Path $modZip) { $dlOk = $true }
    }
    if (-not $dlOk) { continue }

    try {
        if (Test-Path $modExtract) { Remove-Item $modExtract -Recurse -Force -ErrorAction SilentlyContinue }
        Expand-Archive -Path $modZip -DestinationPath $modExtract -Force -ErrorAction Stop
    } catch {
        Write-Fail "Could not extract the mod ZIP: $_"
        $__fb = Invoke-InstallerFallback -Action "extract the HellsingerVR mod" `
            -Subject "the downloaded mod ZIP" -Url "$GITHUB_URL/releases" `
            -Instructions "The ZIP may be incomplete. Re-download it to '$modZip', then choose Retry." `
            -DestFolder "$tempDir" -AllowSkip $false
        if ([string]$__fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        continue
    }

    # The mod ZIP extracts flat (winhttp.dll, openvr_api.dll, BepInEx\,
    # dotnet\, Metal_Data\ at the root). A defensive single-folder
    # unwrap handles a wrapped archive too.
    $modChildren = @(Get-ChildItem -Path $modExtract)
    if ($modChildren.Count -eq 1 -and $modChildren[0].PSIsContainer) {
        $modPayload = $modChildren[0].FullName
        Write-Info "ZIP root folder detected: '$($modChildren[0].Name)' - unwrapping."
    } else {
        $modPayload = $modExtract
    }

    try {
        $null = Merge-DirectoryTreeVerified -Source $modPayload -Destination $gamePath -Label "HellsingerVR mod files" `
            -KeepExistingRelativePaths @("BepInEx\config")
    } catch {
        Write-Fail "Could not copy mod files into the game folder: $_"
        $__fb = Invoke-InstallerFallback -Action "copy the mod files into the game folder" `
            -Instructions "Copy everything inside '$modPayload' into '$gamePath' (merge folders), then choose Retry, or Skip to finish manually." `
            -SourceFolder "$modPayload" -DestFolder "$gamePath" -AllowSkip $true
        if ([string]$__fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        if ([string]$__fb -eq "skip") { $modDone = $true; continue }
        continue
    }

    if (Test-Path (Join-Path $gamePath $MOD_PROBE)) {
        Write-OK "HellsingerVR.dll verified."
    } else {
        Write-Warn "HellsingerVR.dll not found at the expected path - check the install."
    }
    $modDone = $true
}

# steam_appid.txt so the depot build launches without Steam prompting
try {
    Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
    Write-Info "steam_appid.txt created."
} catch { Write-Warn "Could not create steam_appid.txt: $_" }

# Record install path for the Hub's VR-installed detection
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 4: Shortcut + summary
# -------------------------------------------------------
Write-Step 4 4 "Finishing up"

if (Test-Path $gameExePath) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Metal Hellsinger VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0"
        Write-OK "Desktop shortcut 'Metal Hellsinger VR' created."
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
        Write-Host "  Launch manually from: $gameExePath" -ForegroundColor Cyan
    }
} else {
    Write-Warn "Game EXE not found - shortcut skipped. Check: $gamePath"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Metal: Hellsinger VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Game folder: $gamePath" -ForegroundColor Gray
Write-Host "  Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host "  'Metal Hellsinger VR' desktop shortcut, or:" -ForegroundColor White
Write-Host "    $gameExePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "  FIRST LAUNCH:" -ForegroundColor Yellow
Write-Host "   - Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host "     starting sometimes out of focus." -ForegroundColor White
Write-Host "   - The game window must have focus to get past the logo/login" -ForegroundColor White
Write-Host "     screen - if you can't proceed (pressing a trigger), click the" -ForegroundColor White
Write-Host "     game window so it has focus." -ForegroundColor White
Write-Host ""
Write-Host "  Performance: Metal: Hellsinger is graphically heavy in VR. High" -ForegroundColor Gray
Write-Host "  -> Mid settings gives the biggest gain; vrperfkit can help more." -ForegroundColor Gray
Write-Host "  Tweak the mod in BepInEx\config\LivingFray.HellsingerVR.cfg." -ForegroundColor Gray
Write-Host ""
Write-Host "  Reminder: an official VR version with extra polish exists:" -ForegroundColor Yellow
Write-Host "   -> $OFFICIAL_VR_URL" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  Shoot to the beat. Slaughter to the rhythm. Burn through the hells." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
