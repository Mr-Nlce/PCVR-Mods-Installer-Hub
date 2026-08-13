# ============================================================
# Penumbra: Overture VR Installer
# ============================================================
# Adds head + hand tracking (HTC Vive era) to the classic
# Frictional Games horror game. The mod ships its own
# Penumbra_vr.exe + openvr_api.dll and is copied INTO the base
# game's redist\ folder (it needs the original game data next
# to it). Requires Penumbra: Overture on Steam (AppID 22180),
# owned + installed. Never bundles the payload - downloads it.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Penumbra Overture VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME   = "Penumbra Overture"
$GAME_EXE    = "Penumbra.exe"          # original game exe (in redist\) - used for the shortcut icon
$MOD_EXE     = "Penumbra_vr.exe"       # VR mod exe shipped in the zip
$REDIST_SUB  = "redist"                # mod files go here, next to the original game data
$MOD_NAME    = "Penumbra: Overture VR"
$MOD_AUTHOR  = "simply-jos / newyork167"
$STEAM_APPID = "22180"
# Install target: HPL1 engine throws "couldn't load pointlight2d" when
# run from Program Files (UAC). So we copy the whole game out to
# C:\Games\Penumbra Overture VR (first writable root wins) and add the
# VR mod there - the Steam copy stays untouched.
$GAME_FOLDER   = "Penumbra Overture VR"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$INFO_URL    = "https://github.com/newyork167/penumbra_vr"
$DL_URLS     = @(
    "https://github.com/newyork167/penumbra_vr/releases/download/untagged-aceffe2e650abce1e795/penumbra_vr_v01.zip"
)
$MANUAL_URL  = "https://github.com/newyork167/penumbra_vr/releases/"

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Penumbra: Overture VR Installer" -ForegroundColor Cyan
    Write-Host "  Adds head + hand tracking to the Frictional horror classic" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

function Get-SteamLibraryFolders {
    $steam = Get-SteamPath
    if (-not $steam) { return @() }
    $libs = @($steam)
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $content = Get-Content $vdf -Raw
        $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
        foreach ($m in $matches) {
            $path = $m.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $path) { $libs += $path }
        }
    }
    return $libs | Select-Object -Unique
}

# Find the game folder that actually contains redist\Penumbra.exe.
function Find-PenumbraGamePath {
    foreach ($lib in (Get-SteamLibraryFolders)) {
        $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path $candidate) {
            $exe = Join-Path $candidate "$REDIST_SUB\$GAME_EXE"
            if (Test-Path $exe) { return $candidate }
        }
    }
    return $null
}

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

# -------------------------------------------------------
# STEP 0: Welcome
# -------------------------------------------------------
Write-Header
Write-Host "  About this mod:" -ForegroundColor White
Write-Host "  - Penumbra: Overture VR adds head + hand tracking to the" -ForegroundColor Gray
Write-Host "    classic Frictional Games survival-horror game." -ForegroundColor Gray
Write-Host "  - REQUIRES Penumbra: Overture on Steam (owned + installed)." -ForegroundColor Gray
Write-Host "  - Motion controls (built for the HTC Vive era; works with" -ForegroundColor Gray
Write-Host "    modern controllers via SteamVR bindings)." -ForegroundColor Gray
Write-Host ""
Write-Host "  How this installs:" -ForegroundColor White
Write-Host "  - The game's old engine can fail under Program Files (UAC)." -ForegroundColor Gray
Write-Host "  - So we COPY the game to C:\Games\$GAME_FOLDER and add the" -ForegroundColor Gray
Write-Host "    VR mod there. Your Steam copy stays untouched." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
# STEP 1: Locate the Penumbra install in Steam
# -------------------------------------------------------
Write-Step 1 5 "Locating Penumbra: Overture (Steam)"

$srcGamePath = Find-PenumbraGamePath
if (-not $srcGamePath) { $srcGamePath = Find-SteamGameFolder -AppId "22180" -SteamFolderNames @("Penumbra Overture") -ProbeExe "redist\Penumbra_vr.exe" -GogNames @("Penumbra Overture") }
if ($srcGamePath) {
    Write-OK "Found Penumbra: Overture at: $srcGamePath"
} else {
    Write-Warn "Could not auto-locate Penumbra: Overture in any Steam library."
    Write-Host "  Paste the path to your Penumbra Overture folder" -ForegroundColor White
    Write-Host "  (the folder that contains the 'redist' subfolder), then press Enter:" -ForegroundColor White
    while (-not $srcGamePath) {
        $r = (Read-Host "  Penumbra folder").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-Path $r) {
            $exe = Join-Path $r "$REDIST_SUB\$GAME_EXE"
            $exeAlt = Join-Path $r $GAME_EXE
            if (Test-Path $exe) {
                $srcGamePath = $r
                Write-OK "Confirmed Penumbra folder: $srcGamePath"
            } elseif (Test-Path $exeAlt) {
                # User pointed directly at the redist folder - step up one level.
                $srcGamePath = Split-Path $r -Parent
                Write-OK "Confirmed Penumbra folder: $srcGamePath"
            } else {
                Write-Fail "No redist\$GAME_EXE found under: $r"
            }
        } else {
            Write-Fail "Folder not found: $r"
        }
    }
}

# -------------------------------------------------------
# STEP 2: Copy the game out to C:\Games (UAC-safe location)
# -------------------------------------------------------
Write-Step 2 5 "Copying the game to a UAC-safe folder"

$installParent = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $installParent = [string]$r; break }
}
if (-not $installParent) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    Write-Host "  Enter a folder to install into (NOT Program Files):" -ForegroundColor White
    while (-not $installParent) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installParent = [string]$r }
        else { Write-Fail "Not writable: $r" }
    }
}
$gamePath = Join-Path $installParent $GAME_FOLDER
Write-Info "Target: $gamePath"

if (Test-Path $gamePath) {
    Write-Warn "A folder already exists at $gamePath"
    Write-Info "Merging the fresh game files; saves, configs, mods and other additional files are preserved."
}
if (-not (Test-Path $gamePath)) { New-Item -ItemType Directory -Path $gamePath -Force | Out-Null }

Write-Host "  Copying game files (this can take a moment)..." -ForegroundColor Gray
$copyOk = $false
try {
    $rc = @($srcGamePath, $gamePath, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/R:2", "/W:1")
    & robocopy @rc | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy exit code $LASTEXITCODE" }
    $copyOk = $true
} catch {
    Write-Warn "robocopy failed ($($_.Exception.Message)); trying Copy-Item fallback."
    try {
        Copy-Item -Path (Join-Path $srcGamePath "*") -Destination $gamePath -Recurse -Force -ErrorAction Stop
        $copyOk = $true
    } catch { Write-Fail "Copy fallback failed: $($_.Exception.Message)" }
}

$redistPath = Join-Path $gamePath $REDIST_SUB
if ($copyOk -and (Test-Path (Join-Path $redistPath $GAME_EXE))) {
    Write-OK "Game copied to $gamePath"
} else {
    Write-Warn "Game copy may be incomplete - check $redistPath for $GAME_EXE."
    $__fb = Invoke-InstallerFallback -Action "copying the game to C:\Games" `
        -Instructions "Copy your entire '$srcGamePath' folder into '$gamePath' (so that $REDIST_SUB\$GAME_EXE exists there), then choose Retry." `
        -SkipMessage "Skipped - game was not copied; install will fail." `
        -SourceFolder "$srcGamePath" `
        -DestFolder "$gamePath" `
        -AllowSkip $true
    if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
}

if (-not (Test-Path $redistPath)) {
    try { New-Item -ItemType Directory -Path $redistPath -Force | Out-Null } catch {}
}

# -------------------------------------------------------
# STEP 3: Download the VR mod
# -------------------------------------------------------
Write-Step 3 5 "Downloading $MOD_NAME"

$tmpZip = Join-Path $env:TEMP "penumbra_vr_v01.zip"
if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue }

if (-not (Invoke-SafeDownload -Urls $DL_URLS -Destination $tmpZip -Label $MOD_NAME `
        -ManualUrl $MANUAL_URL `
        -Instructions "Download 'penumbra_vr_v01.zip' from the Penumbra VR releases page, then drop it into the opened folder and choose Retry." `
        -SkipMessage "Skipped - the VR mod was NOT downloaded; cannot continue.")) {
    if (-not (Test-Path $tmpZip)) {
        Write-Fail "No mod archive available. Aborting."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 3: Extract the mod into redist\
# -------------------------------------------------------
Write-Step 4 5 "Installing mod files into redist\"

$extractTmp = Join-Path $env:TEMP "_penumbra_extract_tmp"
if (Test-Path $extractTmp) { Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $extractTmp -Force | Out-Null

$extracted = $false
try {
    Expand-Archive -LiteralPath $tmpZip -DestinationPath $extractTmp -Force -ErrorAction Stop
    $extracted = $true
} catch {
    Write-Warn "Built-in extraction failed: $($_.Exception.Message)"
    # Fallback to 7-Zip if available
    try {
        $sevenZip = Get-SevenZip
        if ($sevenZip) {
            & $sevenZip x "$tmpZip" "-o$extractTmp" -y | Out-Null
            if (Test-Path (Join-Path $extractTmp $MOD_EXE)) { $extracted = $true }
        }
    } catch {}
}

if (-not $extracted) {
    Write-Fail "Could not extract the mod archive automatically."
    $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
        -Instructions "Open '$tmpZip' with 7-Zip or Explorer and copy ALL its contents into '$redistPath'. Then choose Retry." `
        -SkipMessage "Skipped - mod files were NOT installed." `
        -SourceFolder (Split-Path "$tmpZip" -Parent) `
        -DestFolder "$redistPath" `
        -AllowSkip $true
    if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") { Pause-User "Re-run the installer after extracting manually. Press Enter to exit..."; exit 1 }
}

# The zip has files at top level (Penumbra_vr.exe, openvr_api.dll,
# models\, maps\, config\). If a single wrapper folder slipped in,
# flatten it so the copy lands directly in redist\.
$srcRoot = $extractTmp
$topItems = @(Get-ChildItem -LiteralPath $extractTmp -Force)
if ($topItems.Count -eq 1 -and $topItems[0].PSIsContainer -and -not (Test-Path (Join-Path $extractTmp $MOD_EXE))) {
    $srcRoot = $topItems[0].FullName
}

# Copy everything into redist\ (merge over existing game files).
$copied = $false
try {
    $null = Merge-DirectoryTreeVerified -Source $srcRoot -Destination $redistPath -Label "Penumbra VR mod files" `
        -KeepExistingRelativePaths @("config")
    $copied = $true
    Write-OK "Mod files copied into redist\."
} catch {
    Write-Warn "Copy failed: $($_.Exception.Message)"
    $__fb = Invoke-InstallerFallback -Action "copying mod files into redist" `
        -Instructions "Copy everything inside '$srcRoot' into '$redistPath'. Then choose Retry." `
        -SkipMessage "Skipped - mod files were NOT copied." `
        -SourceFolder "$srcRoot" `
        -DestFolder "$redistPath" `
        -AllowSkip $true
    if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") {
        try {
            $null = Merge-DirectoryTreeVerified -Source $srcRoot -Destination $redistPath -Label "Penumbra VR mod files" `
                -KeepExistingRelativePaths @("config")
            $copied = $true
        } catch {}
    }
}

# SICHERUNG: nicht nur die Exe, sondern der ganze Satz. Vorher wurde nur
# Penumbra_vr.exe geprueft - ein Archiv, dem die Modelle, Karten oder die
# openvr_api.dll fehlen, waere damit als vollstaendig durchgegangen und das
# Spiel haette erst im Betrieb versagt. Diese vier Wege deckt das Archiv
# ab: die Mod-Exe, die OpenVR-Bibliothek, das VR-Tutorial-Level und die
# VR-Handmodelle. Aus dem echten Archiv gelesen, nicht geraten.
$MOD_MUST_HAVE = @(
    $MOD_EXE,
    "openvr_api.dll",
    "maps\level00_00_vr_tutorial.hps",
    "models\hud_objects\hud_object_hand.hud"
)
$modExePath = Join-Path $redistPath $MOD_EXE
$modMissing = @()
foreach ($m in $MOD_MUST_HAVE) {
    if (-not (Test-Path -LiteralPath (Join-Path $redistPath $m))) { $modMissing += $m }
}
if ($modMissing.Count -gt 0) {
    Write-Fail "The mod archive did not arrive completely - missing in $REDIST_SUB\:"
    foreach ($m in $modMissing) { Write-Host "   $m" -ForegroundColor Yellow }
    Write-Host "  Folder checked: $redistPath" -ForegroundColor Gray
    Write-Host "  Most likely the wrong file was used - it must be" -ForegroundColor White
    Write-Host "  penumbra_vr_v01.zip from the mod's releases page." -ForegroundColor White
    $__fbv = Invoke-InstallerFallback -Action "install the Penumbra VR files" `
        -Subject "the Penumbra VR archive" `
        -Url $MANUAL_URL `
        -Instructions "Copy EVERYTHING from penumbra_vr_v01.zip into '$redistPath' - that includes config\, maps\, models\, openvr_api.dll and $MOD_EXE. Then choose Retry." `
        -DestFolder "$redistPath" `
        -AllowSkip $true
    if ([string]$__fbv -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    $modMissing = @()
    foreach ($m in $MOD_MUST_HAVE) {
        if (-not (Test-Path -LiteralPath (Join-Path $redistPath $m))) { $modMissing += $m }
    }
    if ($modMissing.Count -gt 0) { Write-Warn "Still missing: $($modMissing -join ', ') - VR will not work." }
}
if (Test-Path $modExePath) {
    if ($modMissing.Count -eq 0) { Write-OK "Mod files verified in $REDIST_SUB\ ($($MOD_MUST_HAVE.Count) checks)." }
    else { Write-OK "$MOD_EXE present in redist\." }
    # steam_appid.txt so the game does not bounce to Steam's
    # "install this game" dialog when launched outside the Steam
    # library. Written in BOTH the folder the exe runs from
    # (redist\) and the game root, mirroring the depot-game
    # defense-line approach.
    foreach ($appidDir in @($redistPath, $gamePath)) {
        try {
            Set-Content -Path (Join-Path $appidDir "steam_appid.txt") -Value $STEAM_APPID -Encoding ASCII -NoNewline -Force
        } catch {}
    }
    Write-OK "steam_appid.txt written ($STEAM_APPID)."
    # Record install path so the Hub flips this game to "VR Ready"
    # immediately on next start - same pattern as every other
    # installer. The Hub checks ModFile (redist\Penumbra_vr.exe)
    # against this recorded base path.
    try {
        $pathFile = Join-Path $PSScriptRoot ".installed_path"
        Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
    } catch {}
} else {
    Write-Warn "$MOD_EXE not found in redist\ after install."
    Write-Host "  Check $redistPath for a subfolder and move $MOD_EXE up." -ForegroundColor Yellow
}

# Cleanup temp.
try { Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
try { Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 4: Desktop shortcut (original game icon, VR exe target)
# -------------------------------------------------------
Write-Step 5 5 "Creating Desktop Shortcut"

$gameExePath = Join-Path $redistPath $GAME_EXE
if (Test-Path $modExePath) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Penumbra Overture VR.lnk" -TargetPath $modExePath -WorkingDir $redistPath -IconPath $(if (Test-Path $gameExePath) { "$gameExePath,0" } else { "$modExePath,0" }) -Description "Penumbra: Overture VR - head + hand tracking mod"
        Write-OK "Desktop shortcut 'Penumbra Overture VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $($_.Exception.Message)"
        Write-Info "Launch manually: $modExePath"
    }
} else {
    Write-Warn "Skipping shortcut - $MOD_EXE not found."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Installed to: $gamePath" -ForegroundColor Gray
Write-Host "  (copied out of Steam so the old engine runs without UAC issues)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Start SteamVR first, then launch:" -ForegroundColor White
Write-Host "  - Via the Hub: Start in VR  ->  runs redist\$MOD_EXE" -ForegroundColor Gray
Write-Host "  - Desktop shortcut: 'Penumbra Overture VR'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Tip: in-game, open Options -> VR Settings to toggle the" -ForegroundColor Gray
Write-Host "  monitor mirror (disable it for better performance)." -ForegroundColor Gray
Write-Host ""
Write-Host "  No weapons. No backup. Just you, the cold, and whatever is breathing down there." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
