# ============================================================
# Ready Or Not VR Installer
# Layers the free "Ready Or Not VRO Mod" (Virtual Reality Oasis
# & KITT) onto an EXISTING, user-owned Steam copy of Ready Or
# Not. We ship ZERO game files. The mod is gated behind a Nexus
# Mods login, so it cannot be fetched automatically - the user
# downloads pakchunk98-VR_OR_NOT_P.zip from Nexus and drags it
# in, and we drop the .pak into the game's Paks folder.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ready Or Not VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME    = "Ready Or Not"
$GAME_EXE     = "ReadyOrNot.exe"
$STEAM_FOLDER = "Ready Or Not"
$PAKS_SUBDIR  = "ReadyOrNot\Content\Paks"
$PAK_NAME     = "pakchunk98-VR_OR_NOT_P.pak"
$ZIP_NAME     = "pakchunk98-VR_OR_NOT_P.zip"
$APP_ID       = "1144200"
$NEXUS_URL    = "https://www.nexusmods.com/readyornot/mods/6914"
$NEXUS_FILES_URL = "$NEXUS_URL`?tab=files"
$DLSS_URL     = "https://github.com/beeradmoore/dlss-swapper/releases"
$DISCORD_URL  = "https://discord.gg/7wHGztfgjM"
$LAUNCH_OPTS  = "-usehmd -VRTweaks -VRMappings"
$LAUNCH_OPTS_AUTOVR = "$LAUNCH_OPTS -autoVR"
$DLSS_INSTALLER_URL = "https://github.com/beeradmoore/dlss-swapper/releases/download/v1.2.4.0/DLSS.Swapper-1.2.4.0-installer.exe"
$DLSS_PORTABLE_URL  = "https://github.com/beeradmoore/dlss-swapper/releases/download/v1.2.4.0/DLSS.Swapper-1.2.4.0-portable.zip"
$TOOLS_DIR          = Join-Path $PSScriptRoot "..\Assets\Tools"
$DLSS_PORTABLE_DIR  = Join-Path $TOOLS_DIR "DLSS Swapper"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " Ready Or Not VR Installer" -ForegroundColor Cyan
    Write-Host " Installs: VRO Mod by Virtual Reality Oasis & KITT" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Auto-detect the Steam copy of Ready Or Not across every Steam
# library (registry -> libraryfolders.vdf). Returns the game root
# (the folder holding ReadyOrNot.exe) or $null.
function Find-SteamRon {
    $steam = $null
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { $steam = $p; break } } catch {}
    }
    if (-not $steam) { return $null }
    $libs = @($steam)
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        try {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace '\\\\', '\'
                if (Test-Path $p) { $libs += $p }
            }
        } catch {}
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $cand = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-Path (Join-Path $cand $GAME_EXE)) { return $cand }
    }
    return $null
}

# Drag the Ready Or Not folder or ReadyOrNot.exe; resolve the game
# root (the folder containing ReadyOrNot.exe). Loops until valid or
# cancelled (empty input).
function Get-RonFolder {
    while ($true) {
        Write-Host ""
        Write-Host " Drag your Ready Or Not folder (or ReadyOrNot.exe) onto" -ForegroundColor White
        Write-Host " this window and press Enter." -ForegroundColor White
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path $p -PathType Container) {
            if (Test-Path (Join-Path $p $GAME_EXE)) { return $p }
            Write-Warn "No $GAME_EXE in that folder. Drag the folder that contains it."
            continue
        }
        $dir = Split-Path -Parent $p
        if (Test-Path (Join-Path $dir $GAME_EXE)) { return $dir }
        Write-Warn "That file is not next to $GAME_EXE. Drag the Ready Or Not folder or $GAME_EXE."
    }
}

# Drag a downloaded file here. Accepts the listed extensions. Loops
# until a valid file is given or the user leaves it empty (skip).
function Get-DroppedFile {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag the downloaded $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p -PathType Leaf)) { Write-Warn "File not found: $p"; continue }
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected one of: $($Exts -join ', ')."
            continue
        }
        return $p
    }
}

# Simple Y/N gate. Loops until the user types Y or N.
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}

# Two-way choice. Loops until the user types 1 or 2.
function Read-OneTwo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [1/2]").Trim()
        if ($a -eq "1") { return 1 }
        if ($a -eq "2") { return 2 }
        Write-Warn "Please type 1 or 2."
    }
}

# Best-effort check whether DLSS Swapper is already present. Returns
# "portable" / "installed" / $null. Used to skip a needless download.
function Test-DlssSwapperInstalled {
    if (Test-Path -LiteralPath "$DLSS_PORTABLE_DIR\DLSS Swapper.exe") { return "portable" }
    $cands = @(
        (Join-Path $env:LOCALAPPDATA "Programs\DLSS Swapper\DLSS Swapper.exe"),
        (Join-Path $env:LOCALAPPDATA "DLSS Swapper\DLSS Swapper.exe"),
        "C:\Program Files\DLSS Swapper\DLSS Swapper.exe",
        "C:\Program Files (x86)\DLSS Swapper\DLSS Swapper.exe",
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\DLSS Swapper.lnk"),
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\DLSS Swapper\DLSS Swapper.lnk"),
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\DLSS Swapper.lnk")
    )
    foreach ($c in $cands) { try { if (Test-Path $c) { return "installed" } } catch {} }
    return $null
}

# Create a desktop shortcut. Returns the .lnk path or $null on failure.

Write-Header

# ---- STEP 1: locate Ready Or Not ----
Write-Step 1 5 "Locating your Ready Or Not install"
$gameDir = Find-SteamRon
if (-not $gameDir) { $gameDir = Find-SteamGameFolder -AppId "1144200" -SteamFolderNames @("Ready Or Not") }
if ($gameDir) {
    Write-OK "Found via Steam: $gameDir"
} else {
    Write-Warn "Ready Or Not was not found automatically."
    Write-Host "  You need Ready Or Not installed on Steam (app $APP_ID)." -ForegroundColor White
    Write-Host "  Steam store / install:  https://store.steampowered.com/app/$APP_ID/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the game folder manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$APP_ID" } catch { try { Start-Process "https://store.steampowered.com/app/$APP_ID/" } catch {} }
        Pause-User "Install Ready Or Not, then press Enter to continue..."
        $gameDir = Find-SteamRon
    }
    if (-not $gameDir) { $gameDir = Get-RonFolder }
}
if (-not $gameDir) { Write-Info "No Ready Or Not folder - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
Write-OK "Ready Or Not folder: $gameDir"


$paksDir = Join-Path $gameDir $PAKS_SUBDIR
if (-not (Test-Path $paksDir)) {
    Write-Warn "Expected Paks folder not found:"
    Write-Host "      $paksDir" -ForegroundColor Gray
    Write-Host "      Creating it - if this is the wrong game folder, cancel and re-run." -ForegroundColor Gray
    try { New-Item -ItemType Directory -Force -Path $paksDir | Out-Null } catch { Write-Warn "Could not create the Paks folder." }
}

# ---- STEP 2: download the mod from Nexus ----
Write-Step 2 5 "Downloading the VRO Mod from Nexus Mods"
Write-Host "  The mod is behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host "  downloaded automatically." -ForegroundColor White
Write-Host ""
Write-Host "  Pressing Enter opens the Files page - no need to copy or click:" -ForegroundColor Yellow
Write-Host "      (  $NEXUS_FILES_URL )" -ForegroundColor Gray
Write-Host ""
Write-Host "  1) Log in to Nexus Mods (free account)." -ForegroundColor White
Write-Host "  2) Download the file (Manual download):" -ForegroundColor White
Write-Host "        $ZIP_NAME" -ForegroundColor Gray
Write-Host "  3) Come back here and drag that file onto this window." -ForegroundColor White
Pause-User "Press Enter to open the download page on Nexus Mods..." -Color Yellow
try { Start-Process $NEXUS_FILES_URL } catch { Write-Warn "Open manually: $NEXUS_FILES_URL" }
# No "downloaded?" pause here on purpose - the Get-DroppedFile prompt
# below already waits for an Enter once the file is dragged in.

# Accept the .zip (preferred) or the .pak directly if the user already
# extracted it. Both are fine.
$drop = Get-DroppedFile -Label "$ZIP_NAME (or the .pak inside it)" -Exts @(".zip", ".pak")
if (-not $drop) { Write-Fail "No file provided - cannot install without the mod."; Pause-User "Press Enter to exit..."; exit 1 }
Write-OK "Got: $drop"

# ---- STEP 3: install the .pak into the Paks folder ----
Write-Step 3 5 "Installing the VR pak"
$destPak = Join-Path $paksDir $PAK_NAME
$installedOk = $false
$dropExt = [System.IO.Path]::GetExtension($drop).ToLower()

if ($dropExt -eq ".pak") {
    # User dragged the extracted .pak directly.
    try { Copy-Item -Path $drop -Destination $destPak -Force; $installedOk = $true } catch { Write-Warn "Could not copy the pak: $_" }
} else {
    # Extract the zip and find pakchunk98-VR_OR_NOT_P.pak inside it.
    $xtemp = Join-Path $env:TEMP ("ronvr_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $xtemp | Out-Null } catch {}
    try {
        Expand-Archive -Path $drop -DestinationPath $xtemp -Force
        $pakHit = Get-ChildItem -Path $xtemp -Filter $PAK_NAME -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $pakHit) {
            # Be forgiving: take ANY .pak in the archive if the exact name moved.
            $pakHit = Get-ChildItem -Path $xtemp -Filter *.pak -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($pakHit) {
            Copy-Item -Path $pakHit.FullName -Destination $destPak -Force
            $installedOk = $true
        } else {
            Write-Warn "No .pak file found inside the archive."
        }
    } catch { Write-Warn "Could not extract the archive: $_" }
    try { Remove-Item $xtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

if (-not $installedOk) {
    # Manual fallback: guide the user to drop the pak in by hand.
    Write-Warn "Automatic install did not complete."
    Write-Host "  Please place this file:" -ForegroundColor White
    Write-Host "      $PAK_NAME" -ForegroundColor Gray
    Write-Host "  into this folder:" -ForegroundColor White
    Write-Host "      $paksDir" -ForegroundColor Gray
    try { Start-Process $paksDir } catch {}
    Pause-User "Press Enter once the .pak is in the Paks folder..."
    if (Test-Path $destPak) { $installedOk = $true }
}

if ($installedOk -and (Test-Path $destPak)) {
    Write-OK "VR pak installed: $destPak"
} else {
    Write-Warn "Could not confirm the .pak in the Paks folder - the mod may not load."
}

# ---- STEP 4: Steam launch options (REQUIRED) ----
Write-Step 4 5 "Steam launch options (required)"
Write-Host "  The mod only activates with the right Steam launch options." -ForegroundColor White
Write-Host ""
$clipOk = $false
try { Set-Clipboard -Value $LAUNCH_OPTS; $clipOk = $true } catch { $clipOk = $false }
if ($clipOk) {
    Write-OK "Launch options copied to your clipboard:"
} else {
    Write-Warn "Could not copy to clipboard - type these in by hand:"
}
Write-Host "        $LAUNCH_OPTS" -ForegroundColor Green
Write-Host ""
Write-Host "  In the Steam properties window (opening next):" -ForegroundColor White
Write-Host "   1) Set the 'selected launch option' dropdown to: DirectX 11" -ForegroundColor White
Write-Host "   2) Click the Launch Options field and paste with Ctrl+V" -ForegroundColor White
Write-Host ""
Write-Host "  Tip: paste, do not type - a stray space (like '- usehmd')" -ForegroundColor Gray
Write-Host "  stops VR from starting." -ForegroundColor Gray
Pause-User "Press Enter to open Steam properties for Ready Or Not..."
try { Start-Process "steam://gameproperties/$APP_ID" } catch { Write-Warn "Open Steam manually: right-click Ready Or Not -> Properties -> General." }
Pause-User "Press Enter once you have set DX11, pasted the options, and closed Steam properties..."

# ---- STEP 5: DLSS Swapper (optional) ----
Write-Step 5 5 "DLSS Swapper (optional) and finishing up"
Write-Host "  On an NVIDIA GPU, swapping in a modern DLSS version gives a" -ForegroundColor White
Write-Host "  big performance and clarity boost. DLSS Swapper is a free tool" -ForegroundColor White
Write-Host "  that does this for you - as an install or a portable copy." -ForegroundColor White

$wantDlss = Read-YesNo "Set up DLSS Swapper now?"
if ($wantDlss) {
    $already = Test-DlssSwapperInstalled
    if ($already) {
        Write-OK "DLSS Swapper looks already present ($already) - skipping the download."
        if ($already -eq "portable") {
            try { Start-Process (Join-Path $DLSS_PORTABLE_DIR "DLSS Swapper.exe") } catch {}
        }
    } else {
        Write-Host ""
        Write-Host "  How would you like DLSS Swapper?" -ForegroundColor White
        Write-Host "   1) Install  - integrates into Windows; can self-update inside the app." -ForegroundColor White
        Write-Host "   2) Portable - no install; lives in the Hub Tools folder (no self-update)." -ForegroundColor White
        $mode = Read-OneTwo "Choose 1 or 2"
        if ($mode -eq 1) {
            $tmpInst = Join-Path $env:TEMP "DLSS.Swapper-1.2.4.0-installer.exe"
            $ok = Invoke-DownloadOrFallback -Url $DLSS_INSTALLER_URL -Destination $tmpInst -Label "DLSS Swapper installer" -ManualUrl $DLSS_URL
            if ($ok -and (Test-Path $tmpInst)) {
                Write-OK "Downloaded the installer. Starting it - pick your install location in the setup."
                try { Start-Process $tmpInst } catch { Write-Warn "Run it manually: $tmpInst" }
                Pause-User "Press Enter once the DLSS Swapper setup has finished..."
            } else {
                Write-Warn "Could not download automatically. Get it here: $DLSS_URL"
                try { Start-Process $DLSS_URL } catch {}
                Pause-User "Press Enter once you have installed DLSS Swapper..."
            }
        } else {
            $tmpZip = Join-Path $env:TEMP "DLSS.Swapper-1.2.4.0-portable.zip"
            $ok = Invoke-DownloadOrFallback -Url $DLSS_PORTABLE_URL -Destination $tmpZip -Label "DLSS Swapper (portable)" -ManualUrl $DLSS_URL
            if ($ok -and (Test-Path $tmpZip)) {
                try { if (-not (Test-Path $TOOLS_DIR)) { New-Item -ItemType Directory -Path $TOOLS_DIR -Force | Out-Null } } catch {}
                try { if (Test-Path $DLSS_PORTABLE_DIR) { Remove-Item $DLSS_PORTABLE_DIR -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
                [void](Expand-ArchiveOrFallback -ArchivePath $tmpZip -DestinationFolder $DLSS_PORTABLE_DIR -Label "DLSS Swapper (portable)")
                $exe = $null
                try { $exe = (Get-ChildItem -Path $DLSS_PORTABLE_DIR -Recurse -Filter "DLSS Swapper.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName } catch {}
                if (-not $exe) { try { $exe = (Get-ChildItem -Path $DLSS_PORTABLE_DIR -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*DLSS*Swapper*" } | Select-Object -First 1).FullName } catch {} }
                if ($exe -and (Test-Path $exe)) {
                    $lnk = New-DesktopShortcut -TargetPath $exe -ShortcutName "DLSS Swapper" -WorkingDir (Split-Path $exe -Parent)
                    if ($lnk) { Write-OK "Desktop shortcut created: DLSS Swapper" } else { Write-Warn "Could not create a desktop shortcut - launch it from the Tools folder." }
                    Write-Info "Portable copy lives in: $DLSS_PORTABLE_DIR"
                    Write-Info "It is portable, so you can move or copy that folder anywhere."
                    try { Start-Process $exe } catch { Write-Warn "Start it manually: $exe" }
                } else {
                    Write-Warn "Extracted, but could not find DLSS Swapper.exe under $DLSS_PORTABLE_DIR"
                    try { Start-Process $DLSS_PORTABLE_DIR } catch {}
                }
                Pause-User "Press Enter once DLSS Swapper is open..."
            } else {
                Write-Warn "Could not download automatically. Get the portable zip here: $DLSS_URL"
                try { Start-Process $DLSS_URL } catch {}
                Pause-User "Press Enter once you have DLSS Swapper ready..."
            }
        }
    }
    Write-Host ""
    Write-Host "  In DLSS Swapper: choose the Ready Or Not tile, pick v310.4 or" -ForegroundColor White
    Write-Host "  newer as the DLSS version, set the DLSS Preset to Preset J." -ForegroundColor White
    Write-Host ""
    Write-Host "  When that is set, close DLSS Swapper. The next settings are in" -ForegroundColor White
    Write-Host "  the game itself, not in the Swapper." -ForegroundColor White
    Pause-User "Press Enter once the DLSS version/preset is set and DLSS Swapper is closed..."
} else {
    Write-Info "Skipping DLSS Swapper. You can add it later for extra performance."
}

try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}

# ---- Recommended settings (performance is the big topic) ----
Write-Host ""
Write-Host "  Next, Ready Or Not will start so you can apply a few important" -ForegroundColor White
Write-Host "  settings. Here is what to set:" -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! RECOMMENDED SETTINGS - DO THIS OR PERFORMANCE MAY TANK !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Ready Or Not is VERY demanding in VR. Set these in flat mode" -ForegroundColor White
Write-Host "  before going into VR:" -ForegroundColor White
Write-Host ""
Write-Host "  In-game settings:" -ForegroundColor White
Write-Host "   1) Graphics Preset: Medium" -ForegroundColor White
Write-Host "   2) Open Advanced Graphics Settings" -ForegroundColor White
Write-Host "   3) Scroll down to NVIDIA DLSS and drag the slider to Balanced" -ForegroundColor White
Write-Host "   4) Controller menu: set Aim Assist Strength to Off" -ForegroundColor White
Write-Host "   5) Press Apply." -ForegroundColor White
Write-Host ""
Write-Host "  In the headset / streaming app:" -ForegroundColor White
Write-Host "   - Keep Render Resolution at 1.0x (Meta Quest Link)" -ForegroundColor White
Write-Host "   - Lower the refresh rate to 72 Hz if you need more headroom" -ForegroundColor White
Write-Host "   - Set your default OpenXR runtime correctly (Meta Link / SteamVR)" -ForegroundColor White
Write-Host ""
Write-Host "  Still stuttering? Disable Discord and other overlays, turn off" -ForegroundColor Gray
Write-Host "  OpenXR Toolkit if used, and lower the preset another notch." -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow

# ---- Launch once in flat mode to apply the settings ----
Pause-User "Press Enter to start the game and apply these settings (this installer stays open)..." -Color Yellow
try { Start-Process "steam://rungameid/$APP_ID" } catch { Write-Warn "Launch Ready Or Not from Steam manually." }
Write-Host ""
Write-Host "  The game starts in flat mode for this. Apply the settings above," -ForegroundColor White
Write-Host "  then close the game and come back here." -ForegroundColor White
Pause-User "Press Enter once you have applied the settings and closed the game..."

# ---- Choose how to enter VR ----
Write-Host ""
Write-Host "  Ready Or Not had to start in flat mode for the settings. Now" -ForegroundColor White
Write-Host "  pick how you want to enter VR:" -ForegroundColor White
Write-Host "   1) Manual    - press the U key in-game after the mission loads." -ForegroundColor White
Write-Host "   2) Automatic - drop into VR about 3 seconds after a mission loads." -ForegroundColor White
$vrChoice = Read-OneTwo "Choose 1 or 2"
if ($vrChoice -eq 2) {
    $clip2 = $false
    try { Set-Clipboard -Value $LAUNCH_OPTS_AUTOVR; $clip2 = $true } catch { $clip2 = $false }
    if ($clip2) { Write-OK "New launch options copied to your clipboard:" } else { Write-Warn "Could not copy - type these in by hand:" }
    Write-Host "        $LAUNCH_OPTS_AUTOVR" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Steam properties opens next. Click the Launch Options field," -ForegroundColor White
    Write-Host "  select all (Ctrl+A) and paste (Ctrl+V) to replace the command." -ForegroundColor White
    Pause-User "Press Enter to open Steam properties for Ready Or Not..."
    try { Start-Process "steam://gameproperties/$APP_ID" } catch { Write-Warn "Open Steam manually: right-click Ready Or Not -> Properties -> General." }
    Pause-User "Press Enter once you have replaced the launch options and closed Steam properties..."
} else {
    Write-OK "Manual it is - press U in-game after the mission loads to enter VR."
}

# ---- Done ----
Write-Host ""
Write-Host " Setup complete." -ForegroundColor Green
Write-Host " When you play: start your VR runtime (Meta Quest Link or SteamVR)" -ForegroundColor White
Write-Host " first, then launch Ready Or Not from Steam in flat mode." -ForegroundColor White
Write-Host " Controller bindings and the full troubleshooting list are on the" -ForegroundColor White
Write-Host " game's description page in the Hub." -ForegroundColor White
Write-Host " Help and feedback: $DISCORD_URL" -ForegroundColor Gray
Write-Host ""
Write-Host " Stack up, breach with caution, and bring every officer home." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
