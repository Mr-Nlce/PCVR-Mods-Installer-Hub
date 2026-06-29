# ============================================================
# Quake 2 VR Installer
# ============================================================
# Self-contained installer for Quake 2 VR (q2vr) by Luke
# Groeninger and Malcolm Smith - a KMQuake II-based VR port of
# Quake II. Offers two editions: a binaries-only build (auto-
# downloaded from GitHub) and a full/HD-textures build (manual
# download via MEGA, dropped into the installer). Copies pak0.pak
# (and optional players/ + videos/) from the user's Steam/GOG
# Quake II install into the q2vr baseq2 folder, and creates a
# desktop shortcut. Never bundles payloads - builds are always
# fetched at install time.
# ============================================================

# Load installer-safety helpers (Invoke-SafeDownload,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback, Get-SevenZip).
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Quake 2 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME     = "Quake 2 VR v2.0.0"
$MOD_AUTHOR   = "Luke Groeninger, Malcolm Smith"
$INFO_URL     = "http://www.malcolm-s.net/q2vr/"
# Binaries edition sources, tried in order. Invoke-SafeDownload also
# auto-adds a web.archive.org mirror for the GitHub URL. The second URL
# is the author's own non-MEGA HTTP host (the shareware package, listed
# on the project page as the "Alternate, non mega.nz link"): same
# engine binaries, just with a shareware pak0.pak that we overwrite
# with the user's real pak0.pak anyway - so it is a valid fallback.
$BIN_URLS     = @(
    "https://github.com/q2vr/quake2vr/releases/download/v2.0.0a/Quake2VR-2.0.0-bin.zip",
    "http://www.malcolm-s.net/q2vr/Quake2VR-2.0.0-shareware.zip"
)
$HD_URL       = "https://mega.nz/#!5k9C3KCb!PeXff81k9-KG1Itptqm1KQPgWIke8d-98A-UL0-IBc8"
$GAME_FOLDER  = "Quake 2 VR"
$GAME_EXE     = "quake2vr.exe"
$STEAM_FOLDER = "Quake 2"
$Q2_APPID     = "2320"
$BASE_PAK     = "pak0.pak"
# Revive: compatibility layer that lets Oculus-runtime games run on
# SteamVR / non-Oculus headsets. Needed by anyone NOT on a Rift or a
# Quest connected via Link cable / AirLink.
$REVIVE_URL   = "https://github.com/LibreVR/Revive/releases/download/3.2.0/ReviveInstaller.exe"
# Hub convention: games with their own folder (separate EXE, not
# Steam-launched) install to C:\Games\<Title> VR - NOT next to the
# Steam library. First writable root wins.
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
# GOG: rather than hard-code a (potentially wrong) game ID, scan every
# registered GOG game and test each install path for baseq2\pak0.pak.
$GOG_ROOTS = @(
    "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
    "HKLM:\SOFTWARE\GOG.com\Games"
)

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Quake 2 VR Installer" -ForegroundColor Cyan
    Write-Host "  Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
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
# Resolve the user's Downloads folder (honours a relocated Downloads via
# the Known Folders registry value, else falls back to %USERPROFILE%\Downloads).
function Get-DownloadsFolder {
    try {
        $key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
        $val = (Get-ItemProperty -Path $key -Name "{374DE290-123F-4565-9164-39C4925E467B}" -ErrorAction Stop)."{374DE290-123F-4565-9164-39C4925E467B}"
        if ($val) { $val = [Environment]::ExpandEnvironmentVariables($val); if (Test-Path $val) { return $val } }
    } catch {}
    $fallback = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path $fallback) { return $fallback }
    return $null
}
# Given a Quake II root folder, return the baseq2 folder that holds
# pak0.pak. The classic 1997 data (what KMQuake II needs) lives in
# <root>\baseq2; the 2023 remaster also ships <root>\rerelease\baseq2.
# Prefer the classic one, then the remaster one, then a recursive scan.
function Find-Baseq2 {
    param([string]$Root)
    if (-not $Root -or -not (Test-Path $Root)) { return $null }
    foreach ($sub in @("baseq2", "rerelease\baseq2")) {
        $cand = Join-Path $Root $sub
        if (Test-Path (Join-Path $cand $BASE_PAK)) { return $cand }
    }
    $hit = Get-ChildItem -Path $Root -Recurse -Filter $BASE_PAK -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { return (Split-Path $hit.FullName -Parent) }
    return $null
}

# Locate ReviveInjector.exe across the layouts Revive has shipped:
# modern 3.x at C:\Program Files\Revive\ReviveInjector.exe, a nested
# C:\Program Files\Revive\Revive\ReviveInjector.exe, and older x64/x86
# sub-folders. Prefer the unsuffixed modern name, then fall back.
function Find-ReviveInjector {
    $pf   = $env:ProgramFiles
    $pf86 = ${env:ProgramFiles(x86)}
    $cands = @()
    if ($pf) {
        $cands += (Join-Path $pf "Revive\ReviveInjector.exe")
        $cands += (Join-Path $pf "Revive\Revive\ReviveInjector.exe")
        $cands += (Join-Path $pf "Revive\ReviveInjector_x64.exe")
        $cands += (Join-Path $pf "Revive\Revive\x64\ReviveInjector_x64.exe")
    }
    if ($pf86) { $cands += (Join-Path $pf86 "Revive\ReviveInjector.exe") }
    foreach ($c in $cands) { if (Test-Path $c) { return $c } }
    $bases = @()
    if ($pf)   { $bases += (Join-Path $pf "Revive") }
    if ($pf86) { $bases += (Join-Path $pf86 "Revive") }
    foreach ($base in $bases) {
        if (Test-Path $base) {
            $hit = Get-ChildItem -Path $base -Recurse -Filter "ReviveInjector*.exe" -ErrorAction SilentlyContinue |
                   Sort-Object { $_.Name -ne "ReviveInjector.exe" } | Select-Object -First 1
            if ($hit) { return $hit.FullName }
        }
    }
    return $null
}

# Revive only translates Oculus calls - it still needs the Oculus PC
# runtime (the Meta/Oculus app) installed underneath it. Check for it so
# we can warn SteamVR users who do not have it yet.
function Test-OculusRuntime {
    foreach ($key in @("HKLM:\SOFTWARE\WOW6432Node\Oculus VR, LLC\Oculus", "HKLM:\SOFTWARE\Oculus VR, LLC\Oculus")) {
        try { $b = (Get-ItemProperty -Path $key -ErrorAction Stop).Base; if ($b -and (Test-Path $b)) { return $true } } catch {}
    }
    try { if (Get-Service -Name "OVRService" -ErrorAction SilentlyContinue) { return $true } } catch {}
    foreach ($p in @("${env:ProgramW6432}\Oculus\Support\oculus-runtime\OVRServer_x64.exe", "${env:ProgramFiles}\Oculus\Support\oculus-runtime\OVRServer_x64.exe", "${env:ProgramFiles(x86)}\Oculus\Support\oculus-runtime\OVRServer_x64.exe")) {
        if (Test-Path $p) { return $true }
    }
    return $false
}

# -------------------------------------------------------
# STEP 1: Locate Quake II baseq2 (pak0.pak)
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Locating Quake II"

$sourceBaseq2 = $null

$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        $b = Find-Baseq2 $root
        if ($b) { $sourceBaseq2 = $b; Write-Info "Quake II found via Steam: $sourceBaseq2"; break }
    }
}

if (-not $sourceBaseq2) {
    foreach ($root in $GOG_ROOTS) {
        try {
            Get-ChildItem -Path $root -ErrorAction Stop | ForEach-Object {
                if ($sourceBaseq2) { return }
                try {
                    $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
                    if ($gogPath) {
                        $b = Find-Baseq2 $gogPath
                        if ($b) { $sourceBaseq2 = $b; Write-Info "Quake II found via GOG: $sourceBaseq2" }
                    }
                } catch {}
            }
        } catch {}
        if ($sourceBaseq2) { break }
    }
}

if (-not $sourceBaseq2) {
    Write-Warn "Quake II not found automatically."
    Write-Host "  You need Quake II installed to copy $BASE_PAK." -ForegroundColor White
    Write-Host "  Steam store / install page:" -ForegroundColor Gray
    Write-Host "    https://store.steampowered.com/app/$Q2_APPID/" -ForegroundColor Gray
    Write-Host "  Or open it directly in Steam:  steam://install/$Q2_APPID" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the path manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$Q2_APPID" } catch { try { Start-Process "https://store.steampowered.com/app/$Q2_APPID/" } catch {} }
        Pause-User "Install Quake II, then press Enter to continue..."
        if ($steamPath) {
            foreach ($lib in (Get-SteamLibraries $steamPath)) {
                $b = Find-Baseq2 (Join-Path $lib "steamapps\common\$STEAM_FOLDER")
                if ($b) { $sourceBaseq2 = $b; Write-Info "Quake II found: $sourceBaseq2"; break }
            }
        }
    }
    while (-not $sourceBaseq2) {
        Write-Host "  Enter the path to your Quake II baseq2 folder:" -ForegroundColor White
        Write-Host "    Steam: C:\Program Files (x86)\Steam\steamapps\common\Quake 2\baseq2" -ForegroundColor Gray
        Write-Host "    GOG:   C:\GOG Games\Quake II Enhanced\baseq2" -ForegroundColor Gray
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-Path (Join-Path $r $BASE_PAK)) { $sourceBaseq2 = $r; Write-Info "Path set: $sourceBaseq2" }
        else { Write-Fail "$BASE_PAK not found at: $r" }
    }
}

# -------------------------------------------------------
# STEP 2: Choose edition + download
# -------------------------------------------------------
Write-Step 2 4 "Choose edition + download $MOD_NAME"

$tempDir    = Join-Path $env:TEMP "Quake2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
$modExtract = Join-Path $tempDir "extract"
New-Item -ItemType Directory -Path $tempDir    -Force | Out-Null
New-Item -ItemType Directory -Path $modExtract -Force | Out-Null

Write-Host "  Two editions are available:" -ForegroundColor White
Write-Host "    [1] Binaries only - no HD textures (downloaded automatically)" -ForegroundColor Gray
Write-Host "    [2] Full / HD textures - HD assets, music, mods (manual MEGA download)" -ForegroundColor Gray
Write-Host ""
$edition = ""
while ($edition -notin @("1","2")) { $edition = (Read-Host "  Choice (1/2)").Trim() }

$modArchive = $null
if ($edition -eq "1") {
    $modArchive = Join-Path $tempDir "quake2vr-bin.zip"
    if (-not (Invoke-SafeDownload -Urls $BIN_URLS -Destination $modArchive -Label "$MOD_NAME (binaries)" `
            -ManualUrl $INFO_URL `
            -Instructions "Download Quake2VR-2.0.0-bin.zip from the Q2VR releases page and drop it into the opened folder, then choose Retry." `
            -SkipMessage "Skipped - Quake 2 VR was NOT downloaded; cannot continue.")) {
        if (-not (Test-Path $modArchive)) {
            Write-Fail "No Quake 2 VR archive available. Aborting."
            try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..."; exit 1
        }
    }
} else {
    # HD edition. First, see if the user already has the full/HD package
    # in their Downloads folder (e.g. from an earlier MEGA download). If
    # so, use it and skip the manual step entirely.
    $dlFolder = Get-DownloadsFolder
    if ($dlFolder) {
        $preHd = Get-ChildItem -Path $dlFolder -Filter "*.zip" -ErrorAction SilentlyContinue |
                 Where-Object { ($_.Name -match '(?i)(quake.?2.?vr|q2vr)') -and (($_.Name -match '(?i)full|hd') -or ($_.Length -gt 200MB)) } |
                 Sort-Object Length -Descending | Select-Object -First 1
        if ($preHd) {
            Write-OK "Found an existing Quake 2 VR HD package in Downloads:"
            Write-Host "       $($preHd.Name)" -ForegroundColor Cyan
            $modArchive = $preHd.FullName
        }
    }
    if (-not $modArchive) {
        # MEGA cannot be scripted. Standard Hub pattern for manual-only
        # downloads: open the page, the user downloads the .zip, then drags
        # it straight into THIS window (Read-Host captures the dropped path).
        Write-Host ""
        Write-Host "  The HD edition is hosted on MEGA, which cannot be downloaded" -ForegroundColor White
        Write-Host "  automatically. The page opens in your browser - download the full" -ForegroundColor Gray
        Write-Host "  package there (HD textures, music, mods), then drag the .zip into" -ForegroundColor Gray
        Write-Host "  THIS window." -ForegroundColor Gray
        Write-Host "  -> $HD_URL" -ForegroundColor DarkGray
        Pause-User "Press Enter to open the MEGA page..."
        try { Start-Process $HD_URL } catch { Write-Warn "Could not open browser. Visit the URL above manually." }
        Write-Host ""
        while (-not $modArchive) {
            Write-Host "  Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
            Write-Host "  or paste/type its full path, then press Enter:" -ForegroundColor White
            $r = (Read-Host "  ZIP path").Trim().Trim('"')
            if (-not $r) { continue }
            if (Test-Path $r) {
                if ($r -match '\.zip$|\.7z$|\.rar$') {
                    $modArchive = $r
                    Write-OK "Archive located: $modArchive"
                } else { Write-Fail "Path is not a ZIP/7z/RAR archive: $r" }
            } else { Write-Fail "File not found: $r" }
        }
    }
}

# -------------------------------------------------------
# STEP 3: Extract + install + copy base data
# -------------------------------------------------------
Write-Step 3 4 "Installing"

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
        Write-Host "  Close any running Quake 2 VR window, then re-run the installer." -ForegroundColor Yellow
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

$exResult = Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modExtract `
                -Label "Quake 2 VR" `
                -SkipMessage "Skipped - Quake 2 VR archive was NOT extracted; install is incomplete."
if ([string]$exResult -eq "quit") {
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..."; exit 1
}

# Flatten: if the archive wraps everything in a single folder, treat
# that as the payload root; otherwise locate quake2vr.exe one level down.
$payload = $modExtract
$probe = @(Get-ChildItem -Path $modExtract -ErrorAction SilentlyContinue)
if ($probe.Count -eq 1 -and $probe[0].PSIsContainer) { $payload = $probe[0].FullName }
if (-not (Test-Path (Join-Path $payload $GAME_EXE))) {
    $hit = Get-ChildItem -Path $modExtract -Recurse -Filter $GAME_EXE -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $payload = Split-Path $hit.FullName -Parent }
}

Write-Host "  Copying Quake 2 VR files ... " -NoNewline -ForegroundColor White
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

# Ensure baseq2 exists, then copy the base-game pak0.pak (required)
# plus players\ and videos\ (optional) from the source install.
$destBaseq2 = Join-Path $installRoot "baseq2"
if (-not (Test-Path $destBaseq2)) {
    $existing = Get-ChildItem -Path $installRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq "baseq2" } | Select-Object -First 1
    if ($existing) { $destBaseq2 = $existing.FullName } else { New-Item -ItemType Directory -Path $destBaseq2 -Force | Out-Null }
}

$failed = @()
$srcPak = Join-Path $sourceBaseq2 $BASE_PAK
Write-Host "  Copying $BASE_PAK ... " -NoNewline -ForegroundColor White
if (Test-Path $srcPak) {
    try { Copy-Item -Path $srcPak -Destination $destBaseq2 -Force; Write-Host "OK" -ForegroundColor Green }
    catch { Write-Host "FAILED" -ForegroundColor Red; $failed += $BASE_PAK }
} else {
    $alt = Get-ChildItem -Path $sourceBaseq2 -Filter $BASE_PAK -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($alt) {
        try { Copy-Item -Path $alt.FullName -Destination (Join-Path $destBaseq2 $BASE_PAK) -Force; Write-Host "OK" -ForegroundColor Green }
        catch { Write-Host "FAILED" -ForegroundColor Red; $failed += $BASE_PAK }
    } else { Write-Host "NOT FOUND" -ForegroundColor Red; $failed += $BASE_PAK }
}

# Optional content - best-effort, never blocks the install.
foreach ($opt in @("players","videos")) {
    $src = Join-Path $sourceBaseq2 $opt
    if (Test-Path $src) {
        Write-Host "  Copying $opt\ (optional) ... " -NoNewline -ForegroundColor White
        try { Copy-Item -Path $src -Destination $destBaseq2 -Recurse -Force; Write-Host "OK" -ForegroundColor Green }
        catch { Write-Host "skipped" -ForegroundColor DarkGray }
    }
}

# Optional: mission-pack data - Ground Zero (rogue) and The Reckoning
# (xatrix). The full / HD edition ships these add-on folders with their
# VR engine files but WITHOUT pak0.pak. If the user's Quake II has the
# mission-pack data, copy it in so the bundled add-on launchers work.
# Purely best-effort and additive: we ONLY act when the install already
# has the add-on folder (so the binaries edition is skipped entirely)
# AND the source pak exists. Nothing here can break the base install.
$missionDone = @()
$q2Roots = @()
$pp = Split-Path $sourceBaseq2 -Parent
if ($pp) {
    $q2Roots += $pp
    $gp = Split-Path $pp -Parent
    if ($gp) { $q2Roots += $gp }
}
$q2Roots = @($q2Roots | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) })

foreach ($mp in @(
    @{ Dir = "rogue";  Name = "Ground Zero" },
    @{ Dir = "xatrix"; Name = "The Reckoning" }
)) {
    $destPackDir = Join-Path $installRoot $mp.Dir
    if (-not (Test-Path $destPackDir)) { continue }   # binaries edition: no add-on folder
    $srcMpPak = $null
    foreach ($r in $q2Roots) {
        $cand = Join-Path (Join-Path $r $mp.Dir) $BASE_PAK
        if (Test-Path $cand) { $srcMpPak = $cand; break }
    }
    if ($srcMpPak) {
        Write-Host "  Copying $($mp.Dir)\$BASE_PAK ($($mp.Name)) ... " -NoNewline -ForegroundColor White
        try {
            Copy-Item -Path $srcMpPak -Destination (Join-Path $destPackDir $BASE_PAK) -Force
            Write-Host "OK" -ForegroundColor Green
            $missionDone += $mp.Name
        } catch { Write-Host "skipped" -ForegroundColor DarkGray }
    } else {
        Write-Info "$($mp.Name) add-on is included, but its data was not found in your Quake II - its launcher will not work until you place $($mp.Dir)\$BASE_PAK there."
    }
}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 4: Summary + desktop shortcut + first-launch notes
# -------------------------------------------------------
Write-Step 4 4 "Headset, Revive & shortcut"

$gameExePath = Join-Path $installRoot $GAME_EXE

# --- Headset check: Oculus-direct vs Revive ---------------
# Quake 2 VR uses the Oculus runtime. It launches in VR only on a Rift
# or a Quest connected through Link / AirLink. Quest over Virtual
# Desktop or Steam Link, and every non-Oculus headset (Index, Vive,
# Pico, WMR), needs Revive to translate the Oculus calls to OpenVR.
Write-Host "  Quake 2 VR runs on the Oculus runtime. How you launch depends on your gear:" -ForegroundColor White
Write-Host ""
Write-Host "    [1] Oculus Rift, or Meta Quest via Link cable or AirLink" -ForegroundColor Gray
Write-Host "        -> runs directly, nothing else needed" -ForegroundColor DarkGray
Write-Host "    [2] Quest via Virtual Desktop or Steam Link, or a non-Oculus headset" -ForegroundColor Gray
Write-Host "        (Valve Index, HTC Vive, Pico, WMR, ...) -> needs Revive" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Not sure? Unless you use a Rift or a Quest over a Link / AirLink" -ForegroundColor White
Write-Host "  Oculus connection, pick [2] - Revive is the safe choice." -ForegroundColor White
Write-Host ""
$headset = ""
while ($headset -notin @("1","2")) { $headset = (Read-Host "  Choice (1/2)").Trim() }
$useRevive = ($headset -eq "2")

$injectorPath = $null
if ($useRevive) {
    # Revive needs the Oculus PC runtime installed underneath it. Check
    # first and point the user to it if missing - otherwise Revive (and
    # the game) will not start in VR even once Revive itself is installed.
    if (Test-OculusRuntime) {
        Write-OK "Oculus runtime detected - Revive has what it needs."
    } else {
        Write-Warn "The Oculus PC runtime / app was NOT found. Revive needs it to work"
        Write-Host "      (you can skip the headset first-time setup; no account needed to" -ForegroundColor Gray
        Write-Host "      finish). Opening the Meta/Oculus PC software download page:" -ForegroundColor Gray
        $OCULUS_SETUP = "https://www.meta.com/quest/setup/"
        Write-Host "        $OCULUS_SETUP" -ForegroundColor Gray
        try { Start-Process $OCULUS_SETUP } catch { Write-Warn "Open manually: $OCULUS_SETUP" }
        Pause-User "Press Enter to continue (install the Oculus runtime now or later)..."
    }
    $injectorPath = Find-ReviveInjector
    if ($injectorPath) {
        Write-OK "Revive is already installed: $injectorPath"
    } else {
        # Prefer an existing Revive installer in Downloads (e.g. a manual
        # download). Only fall back to fetching it if none is there.
        $reviveExe = $null
        $reviveFromDownloads = $false
        $dlFolder = Get-DownloadsFolder
        if ($dlFolder) {
            $preRev = Get-ChildItem -Path $dlFolder -Filter "ReviveInstaller*.exe" -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if (-not $preRev) {
                $preRev = Get-ChildItem -Path $dlFolder -Filter "Revive*.exe" -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -match '(?i)install|setup' } |
                          Sort-Object LastWriteTime -Descending | Select-Object -First 1
            }
            if ($preRev) {
                Write-OK "Found an existing Revive installer in Downloads: $($preRev.Name)"
                $reviveExe = $preRev.FullName
                $reviveFromDownloads = $true
            }
        }
        if (-not $reviveExe) {
            Write-Info "Revive not found - fetching the official installer (v3.2.0)..."
            $reviveExe = Join-Path $env:TEMP "ReviveInstaller_$([System.IO.Path]::GetRandomFileName()).exe"
            $null = Invoke-SafeDownload -Urls @($REVIVE_URL) -Destination $reviveExe -Label "Revive 3.2.0" `
                        -ManualUrl "https://github.com/LibreVR/Revive/releases" `
                        -Instructions "Download ReviveInstaller.exe from the Revive releases page and drop it into the opened folder, then choose Retry." `
                        -SkipMessage "Skipped Revive - you can install it later from the link above."
        }
        if (Test-Path $reviveExe) {
            Write-Host ""
            Write-Host "  The Revive installer will now open (a UAC prompt will appear - allow it)." -ForegroundColor White
            Write-Host "  Click through it (I Agree / Next / Install) and keep the default install location." -ForegroundColor White
            Write-Host "  When it finishes, close the Oculus dashboard window it opens AND the" -ForegroundColor White
            Write-Host "  Revive Setup window. THEN come back to this window." -ForegroundColor White
            Pause-User "Press Enter to launch the Revive installer..."
            try {
                $p = Start-Process -FilePath $reviveExe -PassThru
                Write-Host "  Waiting for the Revive installer to close..." -ForegroundColor Gray
                if ($p) { $p.WaitForExit() }
            } catch { Write-Warn "Could not launch the Revive installer: $($_.Exception.Message)" }
            Pause-User "Once Revive has finished installing, press Enter to continue..."
            # Only delete a file WE downloaded to TEMP - never the user's Downloads copy.
            if (-not $reviveFromDownloads) { try { Remove-Item $reviveExe -Force -ErrorAction SilentlyContinue } catch {} }
            $injectorPath = Find-ReviveInjector
        }
        if ($injectorPath) { Write-OK "Revive installed: $injectorPath" }
        else { Write-Warn "Revive injector not detected yet - I'll still create the shortcut at the default path; see the manual note below if it doesn't work." }
    }
}

# --- Desktop shortcut -------------------------------------
# For Revive users the shortcut targets ReviveInjector.exe and passes
# quake2vr.exe as its argument - exactly what 'drag the EXE onto the
# injector' / the Revive tray 'Add a shortcut' produces, just automated.
$reviveManualHint = $false
if (Test-Path $gameExePath) {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Quake 2 VR.lnk")
        if ($useRevive) {
            $inj = if ($injectorPath) { $injectorPath } else { Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe" }
            $shortcut.TargetPath       = $inj
            $shortcut.Arguments        = "`"$gameExePath`""
            $shortcut.WorkingDirectory = $installRoot
            $shortcut.Description      = "Quake 2 VR via Revive"
            $shortcut.IconLocation     = "$gameExePath,0"
            if (-not $injectorPath) { $reviveManualHint = $true }
        } else {
            $shortcut.TargetPath       = $gameExePath
            $shortcut.WorkingDirectory = $installRoot
            $shortcut.Description      = "Quake 2 VR (by Luke Groeninger / Malcolm Smith)"
            $shortcut.IconLocation     = "$gameExePath,0"
        }
        $shortcut.Save()
        if ($useRevive) { Write-OK "Desktop shortcut 'Quake 2 VR' created (launches through Revive)." }
        else { Write-OK "Desktop shortcut 'Quake 2 VR' created." }
    } catch {
        Write-Warn "Could not create shortcut: $($_.Exception.Message)"
        Write-Host "  Launch manually from: $gameExePath" -ForegroundColor Gray
    }
} else {
    Write-Warn "quake2vr.exe not found in the install folder."
    Write-Host "  Expected at: $gameExePath" -ForegroundColor Gray
}

# Persist the launch route. When Revive is needed we drop a hidden
# ".revive_launch" marker (holding the injector path) in the install
# folder so the Hub's "Start in VR" runs the game through Revive too -
# independent of the desktop shortcut, which the user might delete. The
# marker is ONLY written for the Revive route; for the Oculus-direct
# route we make sure no stale marker lingers.
$reviveMarkerFile = Join-Path $installRoot ".revive_launch"
if ($useRevive) {
    try {
        $injForMarker = if ($injectorPath) { $injectorPath } else { Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe" }
        Set-Content -Path $reviveMarkerFile -Value $injForMarker -Encoding ASCII -Force
        try { (Get-Item $reviveMarkerFile).Attributes = 'Hidden' } catch {}
    } catch {}
} else {
    try { if (Test-Path $reviveMarkerFile) { Remove-Item $reviveMarkerFile -Force -ErrorAction SilentlyContinue } } catch {}
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($failed.Count -eq 0) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {} }

# --- Summary ----------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Installation folder: $installRoot" -ForegroundColor Gray
Write-Host "  [x] $MOD_NAME" -ForegroundColor Green
if ($failed.Count -eq 0) {
    Write-Host "  [x] $BASE_PAK copied into baseq2" -ForegroundColor Green
} else {
    Write-Host "  [ ] Base PAK missing: $($failed -join ', ')" -ForegroundColor Red
    Write-Host "      Copy it manually into: $destBaseq2" -ForegroundColor Yellow
    Write-Host "      Source: $sourceBaseq2" -ForegroundColor Yellow
}
if ($missionDone.Count -gt 0) {
    Write-Host "  [x] Mission packs ready to launch: $($missionDone -join ', ')" -ForegroundColor Green
}
if ($useRevive) {
    Write-Host "  [x] Launch route: Revive (SteamVR / non-Oculus headset)" -ForegroundColor Green
} else {
    Write-Host "  [x] Launch route: Oculus runtime (Rift / Quest Link / AirLink)" -ForegroundColor Green
}
Write-Host ""

# --- First launch -----------------------------------------
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
if ($useRevive) {
    Write-Host "  1. Start SteamVR (put your headset on)." -ForegroundColor White
    Write-Host "  2. Launch the 'Quake 2 VR' desktop shortcut - it runs the game" -ForegroundColor White
    Write-Host "     through Revive so the Oculus-only build works on your headset." -ForegroundColor White
    if ($reviveManualHint) {
        Write-Host ""
        Write-Host "  If the shortcut does nothing: open the Revive folder and drag" -ForegroundColor Gray
        Write-Host "  quake2vr.exe onto ReviveInjector.exe - or right-click the Revive" -ForegroundColor Gray
        Write-Host "  tray icon -> Add a shortcut -> pick quake2vr.exe." -ForegroundColor Gray
    }
} else {
    Write-Host "  1. Start the Oculus/Meta app (or connect your Quest via Link/AirLink)." -ForegroundColor White
    Write-Host "  2. Launch the 'Quake 2 VR' desktop shortcut." -ForegroundColor White
}
if ($missionDone.Count -gt 0) {
    Write-Host ""
    Write-Host "  Add-on launchers ($($missionDone -join ', ')) are in the install" -ForegroundColor White
    Write-Host "  folder as 'Quake II VR - <name>.bat'." -ForegroundColor White
}
Write-Host ""
Write-Host "  If VR does not start automatically, open the console (~ key)" -ForegroundColor Gray
Write-Host "  and type:  vr_enable" -ForegroundColor Gray
Write-Host ""
Write-Host "  In Options -> VR: a good starting point is AimMode = Decoupled" -ForegroundColor Gray
Write-Host "  View/Aiming, with VR Controller Support and Comfort Turning to taste." -ForegroundColor Gray
Write-Host "  A gamepad (or Oculus Touch as gamepad) is recommended." -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Strogg ahead. The Big Gun is yours - go crack Stroggos open." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$installRoot`"" } catch {}
