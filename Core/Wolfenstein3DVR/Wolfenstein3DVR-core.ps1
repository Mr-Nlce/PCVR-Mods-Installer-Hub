# ============================================================
# Wolfenstein 3D VR Installer (WolfSharp by Ben McLean)
# ============================================================
# WolfSharp VR is a from-scratch C#/Godot 4 re-implementation of
# id Software's 1992 Wolfenstein 3-D for VR in true stereoscopic
# 3D. It bundles the Wolfenstein 3-D shareware (episode 1), and
# you can add your own full-game / Spear of Destiny data to play
# the rest.
#
# Distributed via itch.io - no automated download is possible, so
# this installer auto-detects wolfsharp-windows-x64.zip in your
# Downloads folder, or you drag-and-drop it in.
#
# Install layout (the ZIP extracts flat):
#   <install_root>\Wolfenstein 3D\BenMcLean.Wolf3D.VR.exe (+ games\, ...)
#   default install_root: C:\Games  (fallback D:\Games, E:\Games)
#
# Nothing here is shipped inside the Hub - the user-supplied ZIP
# (~68 MB) provides the whole game payload.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Wolfenstein 3D VR Installer"

# ---- console helpers ----------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Wolfenstein 3D VR Installer" -ForegroundColor Cyan
    Write-Host " WolfSharp by Ben McLean | itch.io download" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ITCH_PAGE_URL = "https://benmclean.itch.io/wolfsharp"
$EXPECTED_ZIP  = "wolfsharp-windows-x64.zip"
$GAME_FOLDER   = "Wolfenstein 3D"
$GAME_EXE      = "BenMcLean.Wolf3D.VR.exe"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")

# ---- Steam helpers (for optional game-data copy) ------------
function Get-SteamPath {
    foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }
    return $null
}
function Get-SteamLibraries {
    param($sp)
    $libs = New-Object System.Collections.Generic.List[string]
    if (-not $sp) { return $libs }
    $libs.Add($sp)
    $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        try {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s*"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace '\\\\','\'
                if ($p -and (Test-Path -LiteralPath $p)) { $libs.Add($p) }
            }
        } catch {}
    }
    return $libs
}

Write-Header

Write-Host "  WolfSharp VR is a from-scratch re-implementation of id" -ForegroundColor Gray
Write-Host "  Software's 1992 Wolfenstein 3-D, rebuilt for VR in true" -ForegroundColor Gray
Write-Host "  stereoscopic 3D on the Godot 4 engine. It keeps the original" -ForegroundColor Gray
Write-Host "  pixel art and Adlib soundtrack. Runs over OpenXR (SteamVR or" -ForegroundColor Gray
Write-Host "  Quest Link). It's a free itch.io download." -ForegroundColor Gray
Write-Host ""
Write-Host "  The Wolfenstein 3-D shareware (episode 1) is bundled and plays" -ForegroundColor Gray
Write-Host "  out of the box. To play the full game, Spear of Destiny and its" -ForegroundColor Gray
Write-Host "  mission packs, this installer can copy your own game data from" -ForegroundColor Gray
Write-Host "  a Steam / GOG / Xbox / Bethesda install (optional, later step)." -ForegroundColor Gray
Write-Host ""
Write-Host "  Download step:" -ForegroundColor White
Write-Host "   1. The itch.io page opens in your browser" -ForegroundColor White
Write-Host "   2. Under Download, get: $EXPECTED_ZIP (~68 MB)" -ForegroundColor White
Write-Host "   3. Come back here - the installer looks in your Downloads" -ForegroundColor White
Write-Host "      folder automatically, or you can drag the ZIP in." -ForegroundColor White
Write-Host ""
Write-Host "  itch.io page:" -ForegroundColor Cyan
Write-Host "   $ITCH_PAGE_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the itch.io page in your browser..." | Out-Null
try { Start-Process $ITCH_PAGE_URL } catch { Write-Warn "Could not open the browser. Visit the URL above manually." }

# ---- 1. locate the ZIP (Downloads auto-detect, then drag&drop) ----
Write-Step 1 4 "Locate the downloaded ZIP"

$modZip = $null

# Auto-detect in the Downloads folder (exact name first, then any
# wolfsharp*.zip), newest match wins.
$dl = Join-Path $env:USERPROFILE "Downloads"
if (Test-Path -LiteralPath $dl) {
    $exact = Join-Path $dl $EXPECTED_ZIP
    if (Test-Path -LiteralPath $exact) {
        $modZip = $exact
    } else {
        $hit = Get-ChildItem -LiteralPath $dl -Filter "wolfsharp*windows*x64*.zip" -File -EA SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $hit) {
            $hit = Get-ChildItem -LiteralPath $dl -Filter "wolfsharp*.zip" -File -EA SilentlyContinue |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        if ($hit) { $modZip = $hit.FullName }
    }
}
if ($modZip) {
    Write-OK "Found in Downloads: $modZip"
    $keep = (Read-Host "  Use this file? Press Enter to accept, or type N to pick another").Trim()
    if ($keep -in @("n","N")) { $modZip = $null }
}

# Drag-and-drop / manual path fallback
$attempts = 0
while (-not $modZip) {
    $attempts++
    Write-Host "  Drag-and-drop $EXPECTED_ZIP into this window," -ForegroundColor Yellow
    Write-Host "  or paste / type its full path, then press Enter." -ForegroundColor White
    Write-Host "  (Press Enter on an empty line to skip this attempt.)" -ForegroundColor DarkGray
    $r = (Read-Host "  ZIP path").Trim().Trim('"')
    if (-not $r) {
        if ($attempts -ge 5) {
            $fb = Invoke-InstallerFallback -Action "locate the WolfSharp ZIP" `
                -Subject "the WolfSharp download from itch.io" `
                -Url $ITCH_PAGE_URL `
                -Instructions "Open the itch.io page, download '$EXPECTED_ZIP', then come back and drag it in. Choose Retry once the ZIP is on disk." `
                -AllowSkip $false
            if ([string]$fb -eq "quit") { Write-Fail "Cannot continue without the download."; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
            $attempts = 0
        }
        continue
    }
    if (-not (Test-Path $r)) { Write-Fail "File not found: $r"; continue }
    if ($r -notmatch '\.zip$') { Write-Fail "Path is not a ZIP archive: $r"; continue }
    $modZip = [string]$r
}
Write-OK "Archive located: $modZip"

# ---- 2. pick a writable install root ------------------------
Write-Step 2 4 "Choosing an install location"

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

$installRoot = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
}
if (-not $installRoot) {
    Write-Warn "None of the default roots (C:\Games, D:\Games, E:\Games) is writable."
    Write-Host "  C:\Games needs no admin rights, so there's no Windows UAC prompt." -ForegroundColor Gray
    Write-Host "  Enter a folder to install into (will create '$GAME_FOLDER' inside)." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER

if (Test-Path (Join-Path $gameRoot $GAME_EXE)) {
    Write-Warn "An existing Wolfenstein 3D VR install was found at: $gameRoot"
    Write-Host "  Press Enter to overwrite it, or close this window to abort." -ForegroundColor Gray
    Pause-User "Press Enter to overwrite..." | Out-Null
}

# ---- 3. extract the ZIP -------------------------------------
Write-Step 3 4 "Extracting Wolfenstein 3D VR"

$tmp = Join-Path $installRoot "_wolf3d_extract_tmp"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
        Expand-Archive -Path $modZip -DestinationPath $tmp -Force -ErrorAction Stop
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the ZIP: $_"
        $fb = Invoke-InstallerFallback -Action "extract the WolfSharp ZIP" `
            -Subject "the downloaded $EXPECTED_ZIP" `
            -Url $ITCH_PAGE_URL `
            -Instructions "The ZIP may be incomplete or corrupted. Re-download '$EXPECTED_ZIP' from itch.io, then choose Retry. If you have a fresh copy at a different path, drag it in now." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        Write-Host "  Drag in the ZIP again (or press Enter to retry the same file)." -ForegroundColor White
        $again = (Read-Host "  ZIP path").Trim().Trim('"')
        if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) { $modZip = [string]$again }
    }
}

$exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the WolfSharp download" `
        -Url $ITCH_PAGE_URL `
        -Instructions "The ZIP did not contain $GAME_EXE - it may be the wrong file. Make sure you grabbed '$EXPECTED_ZIP' (the windows-x64 build) from the itch.io page, then choose Retry to re-extract." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
    Write-Host "  Drag in the correct ZIP, then press Enter." -ForegroundColor White
    $again = (Read-Host "  ZIP path").Trim().Trim('"')
    if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) {
        $modZip = [string]$again
        try {
            if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
            Expand-Archive -Path $modZip -DestinationPath $tmp -Force -ErrorAction Stop
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$extractedDir = Split-Path -Parent $exeItem.FullName

$placedOk = $false
while (-not $placedOk) {
    try {
        # Merge keeps user-supplied games\WL6, games\M1... data and any
        # additional local files while refreshing the shipped application.
        $null = Merge-DirectoryTreeVerified -Source $extractedDir -Destination $gameRoot -Label "WolfSharp files"
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the game files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the game files into place" `
            -Instructions "Copy the contents of '$extractedDir' into '$gameRoot' (so that $GAME_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$extractedDir" -DestFolder "$gameRoot" -AllowSkip $true
        if ([string]$fb -eq "quit") { try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        if ([string]$fb -eq "skip") { break }
    }
}
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
Write-OK "Game installed at: $gameRoot"

# ---- 4. optional: copy full-game / Spear data ---------------
Write-Step 4 4 "Game data (optional)"

$gamesDir = Join-Path $gameRoot "games"
try { if (-not (Test-Path -LiteralPath $gamesDir)) { New-Item -ItemType Directory -Path $gamesDir -Force | Out-Null } } catch {}

Write-Host "  The shareware (episode 1) is already bundled and playable." -ForegroundColor Gray
Write-Host "  If you own the full Wolfenstein 3-D (*.WL6) or Spear of Destiny" -ForegroundColor Gray
Write-Host "  (*.SOD), this step copies that data in so you can play it too." -ForegroundColor Gray
Write-Host ""
$doData = ""
while ($doData -notin @("y","Y","n","N")) { $doData = (Read-Host "  Look for and copy your full-game data now? (Y/N)").Trim() }

if ($doData -in @("y","Y")) {
    # Build the list of candidate game folders to search.
    $roots = New-Object System.Collections.Generic.List[string]
    foreach ($lib in (Get-SteamLibraries (Get-SteamPath))) {
        $c = "$lib\steamapps\common\Wolfenstein 3D"
        if (Test-Path -LiteralPath $c) { [void]$roots.Add($c) }
    }
    foreach ($c in @(
        "C:\GOG Games\Wolfenstein 3D",
        "C:\XboxGames\Wolfenstein 3D\Content",
        "${env:ProgramFiles(x86)}\Bethesda.net Launcher\games\Wolfenstein 3D",
        "C:\Program Files (x86)\Bethesda.net Launcher\games\Wolfenstein 3D"
    )) { if ($c -and (Test-Path -LiteralPath $c)) { [void]$roots.Add($c) } }

    # Finds the folder holding files that match $Pattern within any root.
    function Find-DataDir {
        param([string[]]$Roots, [string]$Pattern)
        foreach ($root in $Roots) {
            try {
                $hit = Get-ChildItem -LiteralPath $root -Recurse -Filter $Pattern -File -EA SilentlyContinue | Select-Object -First 1
                if ($hit) { return $hit.Directory.FullName }
            } catch {}
        }
        return $null
    }

    # If nothing auto-detected, let the user point at their game folder.
    if ($roots.Count -eq 0) {
        Write-Warn "No Wolfenstein 3D install auto-detected."
        Write-Host "  If you have one, drag its folder here (or the folder holding" -ForegroundColor White
        Write-Host "  the .WL6 / .SOD files), or press Enter to skip." -ForegroundColor White
        $p = (Read-Host "  Game folder").Trim().Trim('"')
        if ($p -and (Test-Path -LiteralPath $p)) { [void]$roots.Add($p) }
    }

    if ($roots.Count -gt 0) {
        $copied = $false
        # Full Wolfenstein 3-D -> games\WL6
        $wl6Dir = Find-DataDir -Roots $roots -Pattern "*.WL6"
        if ($wl6Dir) {
            $dest = Join-Path $gamesDir "WL6"
            try {
                if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
                Get-ChildItem -LiteralPath $wl6Dir -Filter "*.WL6" -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dest $_.Name) -Force
                }
                Write-OK "Full Wolfenstein 3-D data copied to games\WL6"
                $copied = $true
            } catch { Write-Warn "Could not copy the *.WL6 data: $($_.Exception.Message)" }
        }
        # Spear of Destiny -> games\M1
        $sodDir = Find-DataDir -Roots $roots -Pattern "*.SOD"
        if ($sodDir) {
            $dest = Join-Path $gamesDir "M1"
            try {
                if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
                Get-ChildItem -LiteralPath $sodDir -Filter "*.SOD" -File | ForEach-Object {
                    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dest $_.Name) -Force
                }
                Write-OK "Spear of Destiny data copied to games\M1"
                $copied = $true
            } catch { Write-Warn "Could not copy the *.SOD data: $($_.Exception.Message)" }
        }
        if (-not $copied) {
            Write-Warn "No *.WL6 or *.SOD data files were found in the detected folders."
            Write-Host "  You can add them later: put *.WL6 in '$gamesDir\WL6' and" -ForegroundColor Gray
            Write-Host "  *.SOD in '$gamesDir\M1'. The full table is on this game's page" -ForegroundColor Gray
            Write-Host "  in the Hub." -ForegroundColor Gray
        }
    } else {
        Write-Info "Skipped - shareware episode 1 is still installed and playable."
    }
} else {
    Write-Info "Skipped - shareware episode 1 is installed and playable."
    Write-Host "  Add full data later: *.WL6 -> '$gamesDir\WL6', *.SOD -> '$gamesDir\M1'." -ForegroundColor Gray
}

# ---- desktop shortcut + Hub markers -------------------------
$exePath = Join-Path $gameRoot $GAME_EXE
if (Test-Path -LiteralPath $exePath) {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Wolfenstein 3D VR.lnk"
        [void](New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath)
        Write-OK "Desktop shortcut created: Wolfenstein 3D VR"
    } catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }
}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Wolfenstein 3D VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Start SteamVR (or your OpenXR runtime) first, then launch with" -ForegroundColor White
Write-Host " " -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'Wolfenstein 3D VR' desktop" -ForegroundColor White
Write-Host "  shortcut." -ForegroundColor White
Write-Host ""
Write-Host "  Episode 1 (shareware) plays out of the box. If you copied full" -ForegroundColor Gray
Write-Host "  data, pick the game from WolfSharp's in-game menu." -ForegroundColor Gray
Write-Host ""
Write-Host "  Adding game data and the controls are covered on this game's" -ForegroundColor DarkGray
Write-Host "  page in the Hub." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Storm Castle Wolfenstein - now the maze wraps around your head." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
