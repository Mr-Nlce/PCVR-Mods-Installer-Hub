# ============================================================
# Selaco VR Installer  (SelacoVR 2.0 by emawind84)
# ============================================================
# Selaco VR is a standalone QuestZDoom/GZDoom-based VR engine.
# The release ships only the engine - to play you must OWN
# Selaco on Steam (App 1592280). The installer:
#   1. finds the owned Steam Selaco folder (has Selaco.ipk3)
#   2. downloads the SelacoVR engine and extracts it into a
#      subfolder INSIDE the Selaco game folder (rule: nothing
#      outside hub/game folders), then deletes the archive
#   3. copies Selaco.ipk3 from the game into the engine folder
#   4. enables the engine's Laser Sight aim dot by default
#   5. creates a desktop shortcut to SelacoVR.bat
#
# The engine is downloaded at install time - it is never shipped
# inside the Hub (keeps the Hub small; mod files are never bundled).
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Selaco VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Selaco VR Installer" -ForegroundColor Cyan
    Write-Host " by emawind84 | SelacoVR 2.0 (QuestZDoom-based)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENGINE_URL   = "https://github.com/emawind84/SelacoVR/releases/download/selacovr2.0/selacovr-2-0-Windows-64bit.zip"
$STEAM_APPID  = "1592280"
$STEAM_FOLDER = "Selaco"
$IPK3_NAME    = "Selaco.ipk3"
$REQUIRED_BRANCH = "v0.89-bf"         # the only game version SelacoVR 2.0 supports
$ENGINE_DIR_NAME = "SelacoVR"        # subfolder created inside the game folder
$LAUNCH_BAT   = "SelacoVR.bat"       # default (vr_joy_mode 1)
$INDEX_BAT    = "SelacoVR_ValveIndex.bat"

# ---- helper: minimal Steam finder (same pattern as the shared lib) ----
function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return [string]$p} } catch {}
    }
    return $null
}
function Get-SteamLibraries {
    param($sp); $libs=@($sp)
    $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $c = Get-Content $vdf -Raw
        [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object {
            $l=$_.Groups[1].Value -replace '\\\\','\'
            if (Test-Path $l) { $libs+=$l }
        }
    }
    return $libs
}
function Find-SelacoFolder {
    $sp = Get-SteamPath
    if (-not $sp) { return $null }
    foreach ($lib in (Get-SteamLibraries $sp)) {
        $candidate = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-Path $candidate) { return [string]$candidate }
    }
    return $null
}

Write-Header "Selaco VR Installer"

Write-Host "  Selaco VR is a standalone VR engine for Selaco (GZDoom-based)." -ForegroundColor Gray
Write-Host "  You must OWN Selaco on Steam - the VR engine reuses the game's" -ForegroundColor Gray
Write-Host "  own data file (Selaco.ipk3). Nothing here replaces or modifies" -ForegroundColor Gray
Write-Host "  your Steam copy; the VR engine is installed alongside it." -ForegroundColor Gray
Write-Host ""

# ---- 1. locate the owned Steam Selaco folder ----------------
Write-Step 1 6 "Locating your Steam Selaco installation"
$gameFolder = Find-SelacoFolder
if (-not $gameFolder) { $gameFolder = Find-SteamGameFolder -AppId "1592280" -SteamFolderNames @("Selaco") -ProbeExe "SelacoVR\SelacoVR.bat" }
if (-not $gameFolder) {
    Write-Warn "Could not auto-detect Selaco in your Steam libraries."
    Write-Host "  Make sure Selaco (Steam App $STEAM_APPID) is installed." -ForegroundColor Gray
    Write-Host "  You can also enter the folder path manually." -ForegroundColor Gray
    Write-Host "  (the folder that contains $IPK3_NAME)" -ForegroundColor Gray
    Pause-User "Press Enter to enter the path manually (or close this window to abort)..." | Out-Null
    $attempts = 0
    while ($attempts -lt 3 -and -not $gameFolder) {
        $attempts++
        $raw = (Read-Host "  Selaco folder path").Trim().Trim('"')
        if ($raw -and (Test-Path $raw)) { $gameFolder = [string]$raw }
        else { Write-Fail "Path not found: $raw" }
    }
}
if (-not $gameFolder) {
    Write-Fail "No valid Selaco folder provided. Install cannot continue."
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Selaco folder: $gameFolder"

# ---- 2. verify the ipk3 is present ---------------------------
Write-Step 2 6 "Checking for the game data file ($IPK3_NAME)"
$ipk3 = Join-Path $gameFolder $IPK3_NAME
if (-not (Test-Path $ipk3)) {
    # near-folder recovery: search one level deep
    $found = Get-ChildItem -Path $gameFolder -Filter $IPK3_NAME -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $ipk3 = [string]$found.FullName }
}
if (-not (Test-Path $ipk3)) {
    $ipk3 = $null
    while (-not $ipk3) {
        $fb = Invoke-InstallerFallback -Action "locate $IPK3_NAME" `
            -Subject "the Selaco game data file ($IPK3_NAME)" `
            -Instructions "In Steam, verify Selaco's files (right-click Selaco - Properties - Installed Files - Verify integrity) and make sure the $REQUIRED_BRANCH branch finished downloading. Then choose Retry." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            Write-Fail "Cannot continue without $IPK3_NAME."
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        # Retry: re-probe the game folder for the ipk3.
        $cand = Join-Path $gameFolder $IPK3_NAME
        if (Test-Path $cand) { $ipk3 = [string]$cand; break }
        $found = Get-ChildItem -Path $gameFolder -Filter $IPK3_NAME -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $ipk3 = [string]$found.FullName; break }
        Write-Warn "$IPK3_NAME still not found - try verifying again."
    }
}
Write-OK "Found game data: $ipk3"

# ---- 3. require the supported Steam beta branch -------------
Write-Step 3 6 "Switch Selaco to the supported version"
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "  ACTION REQUIRED - Switch Steam beta branch" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  SelacoVR 2.0 only supports Selaco $REQUIRED_BRANCH." -ForegroundColor White
Write-Host "  Newer game versions will not load correctly." -ForegroundColor White
Write-Host ""
Write-Host "  In the Steam properties window that opens:" -ForegroundColor White
Write-Host "    1) Go to the Betas tab" -ForegroundColor White
Write-Host "    2) Beta Participation - select:  $REQUIRED_BRANCH" -ForegroundColor White
Write-Host "       (shown as '$REQUIRED_BRANCH - Burger Flipper Content Update')" -ForegroundColor White
Write-Host "    3) Close Properties and wait for Steam to finish updating" -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to open Selaco properties in Steam..." | Out-Null
try { Start-Process "steam://gameproperties/$STEAM_APPID" -ErrorAction SilentlyContinue | Out-Null } catch {}
Write-Host ""
Write-Host "  If the properties window did not open, open Steam, right-click" -ForegroundColor Gray
Write-Host "  Selaco - Properties - Betas, and select $REQUIRED_BRANCH there." -ForegroundColor Gray
Pause-User "Press Enter once the branch is set and Steam has finished updating..." | Out-Null

# ---- 4. download + install the SelacoVR engine --------------
Write-Step 4 6 "Downloading and installing the Selaco VR engine"

# Engine lives in a subfolder INSIDE the game folder (rule #30).
$engineRoot = Join-Path $gameFolder $ENGINE_DIR_NAME
try {
    if (-not (Test-Path $engineRoot)) { New-Item -ItemType Directory -Path $engineRoot -Force -ErrorAction Stop | Out-Null }
} catch {
    Write-Fail "Could not create the engine folder: $_"
    Write-Host "  The Steam folder may be in a write-protected location" -ForegroundColor Gray
    Write-Host "  (e.g. Program Files). Move the Steam library, or run this" -ForegroundColor Gray
    Write-Host "  installer as administrator, then try again." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

# Download the engine archive into the engine folder. Invoke-SafeDownload
# auto-adds a Web Archive mirror and prompts a manual download/retry/skip
# if GitHub is unreachable (never a hard abort).
$ENGINE_ZIP = Join-Path $engineRoot "selacovr-2-0-Windows-64bit.zip"
if (-not (Test-Path $ENGINE_ZIP)) {
    Invoke-SafeDownload -Urls @($ENGINE_URL) -Destination $ENGINE_ZIP `
        -Label "the SelacoVR engine" `
        -ManualUrl $ENGINE_URL `
        -Instructions "Download 'selacovr-2-0-Windows-64bit.zip' from the SelacoVR releases page and save it as: $ENGINE_ZIP - then choose Retry." | Out-Null
}
if (-not (Test-Path $ENGINE_ZIP)) {
    Write-Fail "The SelacoVR engine archive could not be obtained."
    Write-Host "  Download it manually from:" -ForegroundColor Gray
    Write-Host "    $ENGINE_URL" -ForegroundColor Cyan
    Write-Host "  and save it as: $ENGINE_ZIP, then re-run." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

# Extract to a temp area inside the engine folder, then flatten
# the single top-level "selacovr-2-0-Windows-64bit" subfolder.
$tmpExtract = Join-Path $engineRoot "_extract_tmp"
try {
    if (Test-Path $tmpExtract) { Remove-Item $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmpExtract -Force -ErrorAction Stop | Out-Null
    Expand-Archive -Path $ENGINE_ZIP -DestinationPath $tmpExtract -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not extract the engine: $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
# Find the engine .exe inside the extracted tree and use its folder.
$exeItem = Get-ChildItem -Path $tmpExtract -Filter "Selaco.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exeItem) {
    Write-Fail "Selaco.exe not found in the extracted engine."
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$extractedDir = Split-Path -Parent $exeItem.FullName
# Move all engine files up into $engineRoot.
try {
    $null = Get-ChildItem -Path $extractedDir -Force | ForEach-Object {
        $dest = Join-Path $engineRoot $_.Name
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue }
        Move-Item -Path $_.FullName -Destination $engineRoot -Force -ErrorAction Stop
    }
    Remove-Item $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Fail "Could not place the engine files: $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
# Clean up the downloaded archive - keep only the extracted engine.
Remove-Item $ENGINE_ZIP -Force -ErrorAction SilentlyContinue
Write-OK "Engine installed at: $engineRoot"

# ---- 4. copy ipk3 + drop the extra mods ---------------------
Write-Step 5 6 "Linking the game data and adding mods"
$engineIpk3 = Join-Path $engineRoot $IPK3_NAME
try {
    Copy-Item -Path $ipk3 -Destination $engineIpk3 -Force -ErrorAction Stop
    Write-OK "Copied $IPK3_NAME into the engine folder."
} catch {
    Write-Fail "Could not copy $IPK3_NAME : $_"
    Write-Host "  Manually copy '$ipk3'" -ForegroundColor Gray
    Write-Host "  into '$engineRoot' before launching." -ForegroundColor Gray
    Pause-User "Press Enter to continue anyway..." | Out-Null
}

# Mods go in the engine's mods folder (auto-loaded by the engine).
$modsDir = Join-Path $engineRoot "mods"
try {
    if (-not (Test-Path $modsDir)) { New-Item -ItemType Directory -Path $modsDir -Force -ErrorAction Stop | Out-Null }
} catch {}
# The engine ships a Selaco-tested Laser Sight (VR build) in its mods
# folder. No other mod is auto-installed: many GZDoom mods (e.g. the
# Virtual Tactical Vest) rely on the classic Doom 'Weapon' base class,
# which Selaco's engine replaced - they crash Selaco on compile. Extra
# mods are listed in the README for the user to add at their own risk.

# Turn the Laser Sight ON by default via autoexec.cfg. Without this the
# engine has no usable aim indicator: the only built-in option is a zoom
# aim mode that occupies the fire trigger. These cvars (verified from the
# laser-sight mod's cvarinfo.txt) give a permanent aim dot at the weapon's
# point of impact, visible at all ranges, fire trigger left free.
$autoexec = Join-Path $engineRoot "autoexec.cfg"
$laserBlock = @(
    "// PCVR Hub - enable Laser Sight aim dot by default",
    "m8f_wm_ShowLaserSight 1",
    "m8f_ls_hide_close 0",
    "m8f_ls_OnlyWhenReady 0"
)
try {
    $existing = ""
    if (Test-Path $autoexec) { $existing = Get-Content $autoexec -Raw -ErrorAction SilentlyContinue }
    if ($existing -notmatch "m8f_wm_ShowLaserSight") {
        # Append (preserve the engine's existing "logfile log.txt" line).
        $prefix = ""
        if ($existing -and -not $existing.EndsWith("`n")) { $prefix = "`r`n" }
        Add-Content -Path $autoexec -Value ($prefix + ($laserBlock -join "`r`n")) -ErrorAction Stop
        Write-OK "Laser Sight aim dot enabled by default."
    } else {
        Write-Info "Laser Sight already enabled in autoexec.cfg - left as is."
    }
} catch {
    Write-Warn "Could not auto-enable the Laser Sight: $_"
    Write-Host "  You can turn it on in-game: VR Options - Laser Sight - Show," -ForegroundColor Gray
    Write-Host "  or open the console (~) and type: m8f_wm_ShowLaserSight 1" -ForegroundColor Gray
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameFolder -Encoding UTF8 -Force } catch {}

# ---- 5. desktop shortcut ------------------------------------
Write-Step 6 6 "Creating a desktop shortcut"
$batPath = Join-Path $engineRoot $LAUNCH_BAT
if (-not (Test-Path $batPath)) {
    Write-Warn "$LAUNCH_BAT not found - shortcut skipped."
} else {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Selaco VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $batPath -WorkingDir $engineRoot -IconPath (Join-Path $engineRoot "Selaco.exe")
        Write-OK "Desktop shortcut created: Selaco VR"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
        Write-Host "  You can launch the game manually with:" -ForegroundColor Gray
        Write-Host "    $batPath" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Selaco VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Launch with the 'Selaco VR' desktop shortcut, or run:" -ForegroundColor White
Write-Host "    $batPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Valve Index users: use $INDEX_BAT instead (different" -ForegroundColor Gray
Write-Host "  joystick mode). It's in the same folder." -ForegroundColor Gray
Write-Host "  Start SteamVR first, then launch." -ForegroundColor Gray
Write-Host ""

Write-Host "  Lock and load, Security. ACE is watching." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
