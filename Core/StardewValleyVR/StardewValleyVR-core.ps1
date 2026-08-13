# -------------------------------------------------------
# Stardew Valley VR Mod Installer
# Stardew3D by GingasVR - distributed via Nexus Mods
#
# Three downloads, all behind a free Nexus login, so none of them can be
# fetched automatically:
#   1. SMAPI                    - the mod loader (its own installer)
#   2. Generic Mod Config Menu  - required by the mod, drop-in folder
#   3. Stardew3D                - the VR mod itself, drop-in folder
#
# For each one the installer opens the right Nexus page, then looks in the
# Downloads folder or takes a drag-and-drop. Nothing is bundled.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Stardew Valley VR Installer"

$MOD_NAME   = "Stardew3D"
$MOD_AUTHOR = "GingasVR"
$GAME_APPID = "413150"
$GAME_EXE   = "Stardew Valley.exe"

$NEXUS_MOD   = "https://www.nexusmods.com/stardewvalley/mods/49812?tab=files"
$NEXUS_SMAPI = "https://www.nexusmods.com/stardewvalley/mods/2400?tab=files"
$NEXUS_GMCM  = "https://www.nexusmods.com/stardewvalley/mods/5098?tab=files"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Stardew Valley VR Mod Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { return $p } } catch {}
    }
    return $null
}

function Find-StardewFolder {
    $sp = Get-SteamPath
    if ($sp) {
        $libs = @($sp)
        $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
                $l = $_.Groups[1].Value -replace '\\\\', '\'
                if (Test-Path $l) { $libs += $l }
            }
        }
        foreach ($lib in ($libs | Select-Object -Unique)) {
            $c = Join-Path $lib "steamapps\common\Stardew Valley"
            if (Test-Path -LiteralPath (Join-Path $c $GAME_EXE)) { return $c }
        }
    }
    # GOG, Xbox app / Microsoft Store. Built with .NET Combine so a drive
    # letter that isn't mounted can never raise an error here.
    foreach ($c in @(
        "C:\GOG Games\Stardew Valley",
        "C:\Program Files (x86)\GOG Galaxy\Games\Stardew Valley",
        "C:\XboxGames\Stardew Valley\Content",
        "C:\Program Files\ModifiableWindowsApps\Stardew Valley"
    )) {
        try { if (Test-Path -LiteralPath ([System.IO.Path]::Combine($c, $GAME_EXE))) { return $c } } catch {}
    }
    return $null
}

# Opens the Nexus page for one download, then finds the ZIP: newest match in
# Downloads, otherwise drag-and-drop. Returns the path, or $null if skipped.
function Get-NexusZip {
    param([string]$Label, [string]$Url, [string]$Pattern, [switch]$Optional)

    Write-Host "  $Label is downloaded from Nexus Mods (free account)." -ForegroundColor Gray

    # Check the disk before the browser - the file is often already there.
    $pre = Find-PredownloadedFile -Patterns @($Pattern) -Label $Label
    if ($pre) { return $pre }

    Pause-User "Press Enter to open the download page..." | Out-Null
    try { Start-Process $Url } catch { Write-Warn "Open manually: $Url" }

    $dl = Join-Path $env:USERPROFILE "Downloads"
    while ($true) {
        $hit = $null
        if (Test-Path -LiteralPath $dl) {
            $hit = Get-ChildItem -LiteralPath $dl -Filter $Pattern -File -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        if ($hit) {
            Write-Host "  Found in Downloads: $($hit.Name)" -ForegroundColor Cyan
            $use = (Read-Host "  Use this file? Press Enter to accept, or type N to pick another").Trim()
            if ($use -notin @("n","N")) { return $hit.FullName }
        }
        Write-Host ""
        Write-Host "  Drag the downloaded ZIP into this window and press Enter" -ForegroundColor Yellow
        if ($Optional) { Write-Host "  (or press Enter on its own to skip $Label)" -ForegroundColor DarkGray }
        else { Write-Host "  (or press Enter on its own to check the Downloads folder again)" -ForegroundColor DarkGray }
        $r = (Read-Host "  ZIP path").Trim().Trim('"').Trim("'")
        if (-not $r) { if ($Optional) { return $null } else { continue } }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
        if ($r -notmatch '\.zip$') { Write-Fail "Not a ZIP file: $r"; continue }
        return $r
    }
}

# Extracts a ZIP and copies the folder named $FolderName into the Mods folder.
function Install-ModFolder {
    param([string]$Zip, [string]$FolderName, [string]$ModsDir)
    $tmp = Join-Path $env:TEMP ("sdv_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        Expand-Archive -LiteralPath $Zip -DestinationPath $tmp -Force -ErrorAction Stop
    } catch {
        Write-Fail "Could not extract: $($_.Exception.Message)"
        try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
        return $false
    }
    # The folder may sit at the root or one level down - find it either way.
    $src = Get-ChildItem -LiteralPath $tmp -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -eq $FolderName } | Select-Object -First 1
    if (-not $src) {
        # Some archives ship the files loose; treat a manifest.json as the marker.
        $mf = Get-ChildItem -LiteralPath $tmp -Filter "manifest.json" -Recurse -Depth 2 -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($mf) { $src = Get-Item -LiteralPath $mf.DirectoryName }
    }
    if (-not $src) {
        Write-Fail "Couldn't find a '$FolderName' folder inside the ZIP."
        try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
        return $false
    }
    $dest = Join-Path $ModsDir $FolderName
    try {
        $null = Merge-DirectoryTreeVerified -Source $src.FullName -Destination $dest -Label "$FolderName mod files"
    } catch {
        Write-Fail "Could not copy into Mods: $($_.Exception.Message)"
        try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
        return $false
    }
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    return (Test-Path -LiteralPath $dest)
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header
Write-Host " Stardew3D turns Stardew Valley into a first-person 3D world you" -ForegroundColor White
Write-Host " can play flat or in VR - switch any time with a hotkey. Your save" -ForegroundColor White
Write-Host " is never touched, and the mod can be removed at any point." -ForegroundColor White
Write-Host ""
Write-Host " Three free downloads from Nexus are needed: SMAPI, Generic Mod" -ForegroundColor Gray
Write-Host " Config Menu, and the mod itself." -ForegroundColor Gray
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
# STEP 1: locate the game
# -------------------------------------------------------
Write-Step 1 4 "Locating Stardew Valley"
$gamePath = Find-StardewFolder
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Stardew Valley") -ProbeExe $GAME_EXE }
if ($gamePath) {
    Write-OK "Found: $gamePath"
} else {
    Write-Warn "Could not find Stardew Valley automatically."
    Write-Host "  Paste the folder that contains $GAME_EXE." -ForegroundColor White
    while (-not $gamePath) {
        $r = (Read-Host "  Stardew Valley folder").Trim().Trim('"').Trim("'")
        if (-not $r) { continue }
        if (Test-Path -LiteralPath $r) { $gamePath = $r; Write-OK "Game folder set: $gamePath" }
        else { Write-Fail "Folder not found: $r" }
    }
}
$modsDir = Join-Path $gamePath "Mods"

# -------------------------------------------------------
# STEP 2: SMAPI
# -------------------------------------------------------
Write-Step 2 4 "SMAPI (mod loader)"
$smapiExe = Join-Path $gamePath "StardewModdingAPI.exe"
if (Test-Path -LiteralPath $smapiExe) {
    Write-OK "SMAPI is already installed."
} else {
    Write-Warn "SMAPI is not installed - Stardew3D cannot load without it."
    $smapiZip = Get-NexusZip -Label "SMAPI" -Url $NEXUS_SMAPI -Pattern "SMAPI*.zip"
    if ($smapiZip) {
        $tmp = Join-Path $env:TEMP ("smapi_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
        $ok = $false
        try { Expand-Archive -LiteralPath $smapiZip -DestinationPath $tmp -Force -ErrorAction Stop; $ok = $true }
        catch { Write-Fail "Could not extract SMAPI: $($_.Exception.Message)" }
        if ($ok) {
            # SMAPI's installer takes command-line flags, so it can run start
            # to finish on its own with the folder we already found - no
            # menu for the user to get wrong. Falls back to the interactive
            # installer if the executable isn't where we expect it.
            $sExe = Get-ChildItem -LiteralPath $tmp -Filter "SMAPI.Installer.exe" -Recurse -Depth 3 -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($sExe) {
                Write-Info "Installing SMAPI into $gamePath ..."
                try {
                    Start-Process -FilePath $sExe.FullName -WorkingDirectory $sExe.DirectoryName -Wait `
                        -ArgumentList @("--install","--no-prompt","--game-path","`"$gamePath`"")
                } catch {
                    Write-Fail "Could not run SMAPI's installer: $($_.Exception.Message)"
                }
            }
            if (-not (Test-Path -LiteralPath $smapiExe)) {
                $bat = Get-ChildItem -LiteralPath $tmp -Filter "install on Windows.bat" -Recurse -Depth 2 -File -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($bat) {
                    Write-Host ""
                    Write-Host " >>> SMAPI's own installer opens now. Pick option 1 (install) and " -ForegroundColor Black -BackgroundColor Yellow
                    Write-Host " >>> confirm the game folder it offers. This window waits for it.  " -ForegroundColor Black -BackgroundColor Yellow
                    Write-Host ""
                    try { Start-Process -FilePath $bat.FullName -WorkingDirectory $bat.DirectoryName -Wait }
                    catch { Write-Fail "Could not start SMAPI's installer: $($_.Exception.Message)" }
                } elseif (-not $sExe) {
                    Write-Fail "The SMAPI ZIP didn't contain an installer."
                }
            }
        }
        try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    }
    if (Test-Path -LiteralPath $smapiExe) {
        Write-OK "SMAPI installed."
    } else {
        Write-Warn "SMAPI still isn't detected in the game folder."
        Write-Host "  You can finish it later - the VR mod only loads once SMAPI is in place." -ForegroundColor Gray
    }
}

if (-not (Test-Path -LiteralPath $modsDir)) {
    try { New-Item -ItemType Directory -Path $modsDir -Force | Out-Null } catch {}
}

# -------------------------------------------------------
# STEP 3: Generic Mod Config Menu
# -------------------------------------------------------
Write-Step 3 4 "Generic Mod Config Menu (required)"
if (Test-Path -LiteralPath (Join-Path $modsDir "GenericModConfigMenu")) {
    Write-OK "Already installed."
} else {
    $gmcmZip = Get-NexusZip -Label "Generic Mod Config Menu" -Url $NEXUS_GMCM -Pattern "*Generic*Mod*Config*.zip"
    if ($gmcmZip) {
        if (Install-ModFolder -Zip $gmcmZip -FolderName "GenericModConfigMenu" -ModsDir $modsDir) {
            Write-OK "Generic Mod Config Menu installed."
        } else {
            Write-Warn "Generic Mod Config Menu was not installed - the mod's settings menu won't open."
        }
    }
}

# -------------------------------------------------------
# STEP 4: the VR mod
# -------------------------------------------------------
Write-Step 4 4 "Stardew3D VR mod"
$modZip = Get-NexusZip -Label "Stardew3D" -Url $NEXUS_MOD -Pattern "*Stardew3D*.zip"
if (-not $modZip) {
    Write-Fail "No mod archive provided - nothing was installed."
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
if (-not (Install-ModFolder -Zip $modZip -FolderName "Stardew3D" -ModsDir $modsDir)) {
    Write-Fail "The VR mod could not be installed."
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Stardew3D installed."

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " What to do now:" -ForegroundColor White
Write-Host "   1) Start the game with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or through" -ForegroundColor Gray
Write-Host "      StardewModdingAPI.exe - NOT the normal Stardew shortcut." -ForegroundColor Gray
Write-Host "   2) On Quest (Virtual Desktop or Link): open the mod's settings" -ForegroundColor Gray
Write-Host "      menu, turn ON 'Use OpenXR runtime' at the top, then restart" -ForegroundColor Gray
Write-Host "      the game. SteamVR headsets need no change." -ForegroundColor Gray
Write-Host "   3) Put the headset on and press F8 in-game." -ForegroundColor Gray
Write-Host ""
Write-Host " Hotkeys: F5 flat 3D, F8 VR, F9 recenter, F10 wrist HUD," -ForegroundColor Gray
Write-Host " F7 writes debug info for bug reports. You can switch between" -ForegroundColor Gray
Write-Host " 2D, 3D and VR at any time." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to exit." | Out-Null
