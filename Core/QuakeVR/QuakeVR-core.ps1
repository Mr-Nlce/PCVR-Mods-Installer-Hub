# ============================================================
# Quake VR Installer
# ============================================================
# Self-contained installer for Quake VR by Vittorio Romeo - a
# QuakeSpasm-based VR port of Quake (Enhanced). Downloads the
# release .7z, flattens its version wrapper folder, copies
# PAK0.PAK + PAK1.PAK from the user's Steam/GOG Quake install,
# and creates a desktop shortcut. Never bundles payloads - the
# mod is always downloaded at install time.
# ============================================================

# Load installer-safety helpers (Invoke-SafeDownload,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback, Get-SevenZip).
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Quake VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME    = "Quake VR v0.0.8.1"
$MOD_AUTHOR  = "Vittorio Romeo"
$INFO_URL    = "https://github.com/vittorioromeo/quakevr"
$MOD_URL     = "https://github.com/vittorioromeo/quakevr/releases/download/v0.0.8.1/quakevr_v0.0.8.1.7z"
$GAME_FOLDER = "Quake VR"
$GAME_EXE    = "quakevr.exe"
$STEAM_FOLDER = "Quake"
$QUAKE_APPID  = "2310"
# Hub convention: games with their own folder (separate EXE, not
# Steam-launched) install to C:\Games\<Title> VR - NOT next to the
# Steam library. First writable root wins.
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$VCREDIST_URLS = @(
    "https://aka.ms/vs/17/release/vc_redist.x64.exe",
    "https://aka.ms/vc14/vc_redist.x64.exe"
)
# GOG: rather than hard-code a (potentially wrong) game ID, scan every
# registered GOG game and test each install path for id1\PAK0.PAK.
$GOG_ROOTS = @(
    "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
    "HKLM:\SOFTWARE\GOG.com\Games"
)

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Quake VR Installer" -ForegroundColor Cyan
    Write-Host "  Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
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
# STEP 1: Locate Quake base-game id1 (PAK0.PAK + PAK1.PAK)
# -------------------------------------------------------
Write-Header
Write-Host " Quake VR by Vittorio Romeo - a QuakeSpasm-based VR port of Quake with" -ForegroundColor White
Write-Host " full motion controls and room-scale movement (SteamVR/OpenVR)." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 5 "Locating Quake"

$sourceId1 = $null

$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $candidate = Join-Path $lib "steamapps\common\$STEAM_FOLDER\id1"
        if (Test-Path -LiteralPath "$candidate\PAK0.PAK") {
            $sourceId1 = $candidate
            Write-Info "Quake found via Steam: $sourceId1"
            break
        }
    }
}

if (-not $sourceId1) {
    foreach ($root in $GOG_ROOTS) {
        try {
            Get-ChildItem -Path $root -ErrorAction Stop | ForEach-Object {
                if ($sourceId1) { return }
                try {
                    $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
                    if ($gogPath) {
                        $candidate = Join-Path $gogPath "id1"
                        if (Test-Path -LiteralPath "$candidate\PAK0.PAK") {
                            $sourceId1 = $candidate
                            Write-Info "Quake found via GOG: $sourceId1"
                        }
                    }
                } catch {}
            }
        } catch {}
        if ($sourceId1) { break }
    }
}

if (-not $sourceId1) {
    Write-Warn "Quake not found automatically."
    Write-Host "  You need Quake (Enhanced) installed to copy PAK0.PAK + PAK1.PAK." -ForegroundColor White
    Write-Host "  Steam store / install page:" -ForegroundColor Gray
    Write-Host "    https://store.steampowered.com/app/$QUAKE_APPID/" -ForegroundColor Gray
    Write-Host "  Or open it directly in Steam:  steam://install/$QUAKE_APPID" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the path manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$QUAKE_APPID" } catch { try { Start-Process "https://store.steampowered.com/app/$QUAKE_APPID/" } catch {} }
        Pause-User "Install Quake, then press Enter to continue..."
        # Re-scan Steam after the user installs.
        if ($steamPath) {
            foreach ($lib in (Get-SteamLibraries $steamPath)) {
                $candidate = Join-Path $lib "steamapps\common\$STEAM_FOLDER\id1"
                if (Test-Path -LiteralPath "$candidate\PAK0.PAK") { $sourceId1 = $candidate; Write-Info "Quake found: $sourceId1"; break }
            }
        }
    }
    while (-not $sourceId1) {
        Write-Host "  Enter the path to your Quake id1 folder:" -ForegroundColor White
        Write-Host "    Steam: C:\Program Files (x86)\Steam\steamapps\common\Quake\id1" -ForegroundColor Gray
        Write-Host "    GOG:   C:\GOG Games\Quake\id1" -ForegroundColor Gray
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-Path -LiteralPath "$r\PAK0.PAK") { $sourceId1 = $r; Write-Info "Path set: $sourceId1" }
        else { Write-Fail "PAK0.PAK not found at: $r" }
    }
}

# -------------------------------------------------------
# STEP 2: Microsoft Visual C++ x64 Redistributable (recommended)
# -------------------------------------------------------
Write-Step 2 5 "Visual C++ x64 Redistributable"

Write-Host "  Quake VR needs the 'Visual C++ x64 Redistributable' runtime." -ForegroundColor White
Write-Host "  Most systems already have it. You can install/refresh it now, or skip." -ForegroundColor Gray
Write-Host ""
Write-Host "  [Y] Download & install now   [N] Skip (I already have it)" -ForegroundColor White
$vc = ""
while ($vc -notin @("y","Y","n","N")) { $vc = (Read-Host "  Choice (Y/N)").Trim() }
if ($vc -in @("y","Y")) {
    $vcExe = Join-Path $env:TEMP "vc_redist.x64.exe"
    if (Invoke-SafeDownload -Urls $VCREDIST_URLS -Destination $vcExe -Label "Visual C++ x64 Redistributable" `
            -ManualUrl "https://aka.ms/vs/17/release/vc_redist.x64.exe" `
            -Instructions "Download and run vc_redist.x64.exe from the Microsoft link, then choose Retry." `
            -SkipMessage "Skipped - if Quake VR fails to start with a VCRUNTIME error, install it manually.") {
        try {
            Write-Info "Running the redistributable installer (passive)..."
            $p = Start-Process -FilePath $vcExe -ArgumentList "/install","/passive","/norestart" -Wait -PassThru
            if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010 -or $p.ExitCode -eq 1638) {
                Write-OK "Visual C++ Redistributable is installed."
            } else {
                Write-Warn "Installer exited with code $($p.ExitCode). If Quake VR errors on launch, run vc_redist.x64.exe manually."
            }
        } catch {
            Write-Warn "Could not run the installer: $($_.Exception.Message)"
            Write-Host "  Run it manually: $vcExe" -ForegroundColor Gray
        }
        try { Remove-Item $vcExe -Force -ErrorAction SilentlyContinue } catch {}
    }
} else {
    Write-Info "Skipped Visual C++ Redistributable."
}

# -------------------------------------------------------
# STEP 3: Download Quake VR
# -------------------------------------------------------
Write-Step 3 5 "Downloading $MOD_NAME"

$tempDir    = Join-Path $env:TEMP "QuakeVRInstaller_$([System.IO.Path]::GetRandomFileName())"
$modArchive = Join-Path $tempDir "quakevr.7z"
$modExtract = Join-Path $tempDir "extract"
New-Item -ItemType Directory -Path $tempDir   -Force | Out-Null
New-Item -ItemType Directory -Path $modExtract -Force | Out-Null

if (-not (Invoke-SafeDownload -Urls @($MOD_URL) -Destination $modArchive -Label $MOD_NAME `
        -ManualUrl $MOD_URL `
        -Instructions "Download quakevr_v0.0.8.1.7z from the GitHub releases page and drop it into the opened folder, then choose Retry." `
        -SkipMessage "Skipped - Quake VR was NOT downloaded; cannot continue.")) {
    if (-not (Test-Path $modArchive)) {
        Write-Fail "No Quake VR archive available. Aborting."
        Pause-User "Press Enter to exit..."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        exit 1
    }
}

# Ensure 7-Zip is available (the release ships as .7z). Get-SevenZip
# resolves an installed 7z.exe or offers to install it, with a
# clickable manual URL fallback.
$null = Get-SevenZip

# -------------------------------------------------------
# STEP 4: Extract + install + copy base PAKs
# -------------------------------------------------------
Write-Step 4 5 "Installing"

# Pick the install root by Hub convention: first writable C:\Games
# (then D:, E:), with a manual fallback. The game lands in
# <root>\Quake VR - a self-contained folder, NOT inside the Steam
# library (Quake VR ships its own quakevr.exe and is not launched
# through Steam).
$installParent = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $installParent = [string]$r; break }
}
if (-not $installParent) {
    Write-Warn "None of the default roots (C:\Games, D:\Games, E:\Games) is writable."
    Write-Host "  Enter a folder to install into (will create '$GAME_FOLDER' inside)." -ForegroundColor White
    Write-Host "  Avoid Program Files / Users - pick e.g. C:\Games" -ForegroundColor Gray
    while (-not $installParent) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installParent = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installParent"
$installRoot = Join-Path $installParent $GAME_FOLDER

if (Test-Path $installRoot) {
    Write-Warn "Folder already exists: $installRoot"
    Write-Host "  [Y] Delete and reinstall   [N] Abort" -ForegroundColor White
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Choice (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 0
    }
    try { Remove-Item $installRoot -Recurse -Force -ErrorAction Stop }
    catch {
        Write-Fail "Could not delete: $($_.Exception.Message)"
        Write-Host "  Close any running Quake VR window, then re-run the installer." -ForegroundColor Yellow
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

# Extract (handles .7z via 7z.exe, with interactive manual fallback).
$exResult = Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modExtract `
                -Label "Quake VR" `
                -SkipMessage "Skipped - Quake VR archive was NOT extracted; install is incomplete."
if ([string]$exResult -eq "quit") {
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..."; exit 1
}

# The release wraps everything in a version folder (e.g. "v0.0.8.1").
# Flatten: if the extract dir holds exactly one folder, treat that as
# the payload root. This also recovers if 7-Zip nested it one deeper.
$payload = $modExtract
$probe = @(Get-ChildItem -Path $modExtract -ErrorAction SilentlyContinue)
if ($probe.Count -eq 1 -and $probe[0].PSIsContainer) { $payload = $probe[0].FullName }
# Near-folder recovery: if quakevr.exe still is not at the payload
# root, search one level down for the folder that contains it.
if (-not (Test-Path (Join-Path $payload $GAME_EXE))) {
    $hit = Get-ChildItem -Path $modExtract -Recurse -Filter $GAME_EXE -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $payload = Split-Path $hit.FullName -Parent }
}

Write-Host "  Copying Quake VR files ... " -NoNewline -ForegroundColor White
try {
    Get-ChildItem -Path $payload | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force
    }
    Write-Host "OK" -ForegroundColor Green
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Fail "Copy failed: $($_.Exception.Message)"
    Write-Host "  Copy the contents of '$payload' into '$installRoot' manually." -ForegroundColor Yellow
    Pause-User "Press Enter when done (or to exit)..."
}

# Quake VR ships its Id1 (PAK10/11/12 etc). Ensure it exists, then add
# the base-game PAK0/PAK1. The archive uses "Id1"; if missing, fall
# back to any case-variant or create it.
$destId1 = Join-Path $installRoot "Id1"
if (-not (Test-Path $destId1)) {
    $existing = Get-ChildItem -Path $installRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq "id1" } | Select-Object -First 1
    if ($existing) { $destId1 = $existing.FullName } else { New-Item -ItemType Directory -Path $destId1 -Force | Out-Null }
}

$failed = @()
foreach ($pak in @("PAK0.PAK","PAK1.PAK")) {
    $src = Join-Path $sourceId1 $pak
    Write-Host "  Copying $pak ... " -NoNewline -ForegroundColor White
    if (Test-Path $src) {
        try { Copy-Item -Path $src -Destination $destId1 -Force; Write-Host "OK" -ForegroundColor Green }
        catch { Write-Host "FAILED" -ForegroundColor Red; $failed += $pak }
    } else {
        # Fallback search candidate: some installs differ in case.
        $alt = Get-ChildItem -Path $sourceId1 -Filter $pak -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($alt) {
            try { Copy-Item -Path $alt.FullName -Destination (Join-Path $destId1 $pak) -Force; Write-Host "OK" -ForegroundColor Green }
            catch { Write-Host "FAILED" -ForegroundColor Red; $failed += $pak }
        } else { Write-Host "NOT FOUND" -ForegroundColor Red; $failed += $pak }
    }
}

# Optional: copy the Enhanced 'rerelease' music folder if present, so
# in-game music works. Best-effort only - never blocks the install.
$musicSrc = Join-Path (Split-Path $sourceId1 -Parent) "rerelease\id1\music"
$musicDst = Join-Path $destId1 "music"
if ((Test-Path $musicSrc) -and -not (Test-Path $musicDst)) {
    Write-Host "  Copying soundtrack (optional) ... " -NoNewline -ForegroundColor White
    try { Copy-Item -Path $musicSrc -Destination $destId1 -Recurse -Force; Write-Host "OK" -ForegroundColor Green }
    catch { Write-Host "skipped" -ForegroundColor DarkGray }
}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($failed.Count -eq 0) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# STEP 5: Summary + desktop shortcut + first-launch notes
# -------------------------------------------------------
Write-Step 5 5 "All Done!"

$gameExePath = Join-Path $installRoot $GAME_EXE

Write-Host "  Installation folder: $installRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [x] $MOD_NAME" -ForegroundColor Green
if ($failed.Count -eq 0) {
    Write-Host "  [x] PAK0.PAK + PAK1.PAK copied" -ForegroundColor Green
} else {
    Write-Host "  [ ] PAK files missing: $($failed -join ', ')" -ForegroundColor Red
    Write-Host "      Copy them manually into: $destId1" -ForegroundColor Yellow
    Write-Host "      Source: $sourceId1" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host "  starting sometimes out of focus." -ForegroundColor White
Write-Host "  Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the desktop" -ForegroundColor White
Write-Host "  shortcut 'Quake VR'." -ForegroundColor White
Write-Host ""
Write-Host "  After first launch, open SteamVR -> Controller Bindings and" -ForegroundColor Gray
Write-Host "  confirm both action sets (in-game + menu) are mapped to your" -ForegroundColor Gray
Write-Host "  motion controllers." -ForegroundColor Gray
Write-Host ""
Write-Host "  In 'Quake VR Settings': calibrate height, tune the VR torso" -ForegroundColor Gray
Write-Host "  and holster hotspots, and review the Immersion Settings." -ForegroundColor Gray
Write-Host ""
Write-Host "  SteamVR Theatre Mode must be OFF:" -ForegroundColor Gray
Write-Host "    SteamVR -> Settings -> Dashboard -> 'Present Non-VR Applications...' -> OFF" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue..."

if (Test-Path $gameExePath) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Quake VR.lnk" -TargetPath $gameExePath -WorkingDir $installRoot -IconPath "$gameExePath,0"
        Write-OK "Desktop shortcut 'Quake VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $($_.Exception.Message)"
        Write-Host "  Launch manually from: $gameExePath" -ForegroundColor Gray
    }
} else {
    Write-Warn "quakevr.exe not found in the install folder."
    Write-Host "  Expected at: $gameExePath" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  The slipgate hums. Grab the shotgun - the Shamblers are waiting." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$installRoot`"" } catch {}
