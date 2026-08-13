# ============================================================
# Quake 3 VR Installer
# ============================================================
# Self-contained installer for Quake 3 VR (q3vr) by RippeR37 - a
# PCVR port of Quake III Arena based on ioquake3 + Quake3Quest
# (Team Beef). Downloads the official portable .zip release,
# flattens any version wrapper folder, copies pak0.pk3 (and any
# pak1-8.pk3 point-release/Team-Arena PAKs) from the user's
# Steam/GOG Quake III Arena install into the q3vr baseq3 folder,
# and creates a desktop shortcut. Never bundles payloads - the
# build is always downloaded fresh at install time.
# ============================================================

# Load installer-safety helpers (Invoke-SafeDownload,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback, Get-SevenZip).
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Quake 3 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME     = "Quake 3 VR v1.0"
$MOD_AUTHOR   = "RippeR37"
$INFO_URL     = "https://ripper37.github.io/q3vr/"
$MOD_URL      = "https://github.com/RippeR37/q3vr/releases/download/v1.0/q3vr_v1.0_windows_portable.zip"
$GAME_FOLDER  = "Quake 3 VR"
$GAME_EXE     = "q3vr.exe"
$STEAM_FOLDER = "Quake 3 Arena"
$Q3_APPID     = "2200"
$BASE_PAK     = "pak0.pk3"
# Hub convention: games with their own folder (separate EXE, not
# Steam-launched) install to C:\Games\<Title> VR - NOT next to the
# Steam library. First writable root wins.
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
# GOG: rather than hard-code a (potentially wrong) game ID, scan every
# registered GOG game and test each install path for baseq3\pak0.pk3.
$GOG_ROOTS = @(
    "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
    "HKLM:\SOFTWARE\GOG.com\Games"
)

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Quake 3 VR Installer" -ForegroundColor Cyan
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

# -------------------------------------------------------
# STEP 1: Locate Quake III Arena baseq3 (pak0.pk3)
# -------------------------------------------------------
Write-Header
Write-Host " Quake 3 VR by RippeR37 - a PCVR port of Quake III Arena on ioquake3," -ForegroundColor White
Write-Host " with full 6DoF motion controls. Start SteamVR before playing." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Locating Quake III Arena"

$sourceBaseq3 = $null

$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $candidate = Join-Path $lib "steamapps\common\$STEAM_FOLDER\baseq3"
        if (Test-Path (Join-Path $candidate $BASE_PAK)) {
            $sourceBaseq3 = $candidate
            Write-Info "Quake III Arena found via Steam: $sourceBaseq3"
            break
        }
    }
}

if (-not $sourceBaseq3) {
    foreach ($root in $GOG_ROOTS) {
        try {
            Get-ChildItem -Path $root -ErrorAction Stop | ForEach-Object {
                if ($sourceBaseq3) { return }
                try {
                    $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
                    if ($gogPath) {
                        $candidate = Join-Path $gogPath "baseq3"
                        if (Test-Path (Join-Path $candidate $BASE_PAK)) {
                            $sourceBaseq3 = $candidate
                            Write-Info "Quake III Arena found via GOG: $sourceBaseq3"
                        }
                    }
                } catch {}
            }
        } catch {}
        if ($sourceBaseq3) { break }
    }
}

if (-not $sourceBaseq3) {
    Write-Warn "Quake III Arena not found automatically."
    Write-Host "  You need Quake III Arena installed to copy $BASE_PAK." -ForegroundColor White
    Write-Host "  Steam store / install page:" -ForegroundColor Gray
    Write-Host "    https://store.steampowered.com/app/$Q3_APPID/" -ForegroundColor Gray
    Write-Host "  Or open it directly in Steam:  steam://install/$Q3_APPID" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the path manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$Q3_APPID" } catch { try { Start-Process "https://store.steampowered.com/app/$Q3_APPID/" } catch {} }
        Pause-User "Install Quake III Arena, then press Enter to continue..."
        # Re-scan Steam after the user installs.
        if ($steamPath) {
            foreach ($lib in (Get-SteamLibraries $steamPath)) {
                $candidate = Join-Path $lib "steamapps\common\$STEAM_FOLDER\baseq3"
                if (Test-Path (Join-Path $candidate $BASE_PAK)) { $sourceBaseq3 = $candidate; Write-Info "Quake III Arena found: $sourceBaseq3"; break }
            }
        }
    }
    while (-not $sourceBaseq3) {
        Write-Host "  Enter the path to your Quake III Arena baseq3 folder:" -ForegroundColor White
        Write-Host "    Steam: C:\Program Files (x86)\Steam\steamapps\common\Quake 3 Arena\baseq3" -ForegroundColor Gray
        Write-Host "    GOG:   C:\GOG Games\Quake III - Arena\baseq3" -ForegroundColor Gray
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-Path (Join-Path $r $BASE_PAK)) { $sourceBaseq3 = $r; Write-Info "Path set: $sourceBaseq3" }
        else { Write-Fail "$BASE_PAK not found at: $r" }
    }
}

# -------------------------------------------------------
# STEP 2: Download Quake 3 VR
# -------------------------------------------------------
Write-Step 2 4 "Downloading $MOD_NAME"

$tempDir    = Join-Path $env:TEMP "Quake3VRInstaller_$([System.IO.Path]::GetRandomFileName())"
$modArchive = Join-Path $tempDir "q3vr.zip"
$modExtract = Join-Path $tempDir "extract"
New-Item -ItemType Directory -Path $tempDir    -Force | Out-Null
New-Item -ItemType Directory -Path $modExtract -Force | Out-Null

if (-not (Invoke-SafeDownload -Urls @($MOD_URL) -Destination $modArchive -Label $MOD_NAME `
        -ManualUrl $INFO_URL `
        -Instructions "Download the latest Windows portable .zip from the Q3VR releases page and drop it into the opened folder, then choose Retry." `
        -SkipMessage "Skipped - Quake 3 VR was NOT downloaded; cannot continue.")) {
    if (-not (Test-Path $modArchive)) {
        Write-Fail "No Quake 3 VR archive available. Aborting."
        Pause-User "Press Enter to exit..."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        exit 1
    }
}

# -------------------------------------------------------
# STEP 3: Extract + install + copy base PAKs
# -------------------------------------------------------
Write-Step 3 4 "Installing"

# Pick the install root by Hub convention: first writable C:\Games
# (then D:, E:), with a manual fallback. The game lands in
# <root>\Quake 3 VR - a self-contained folder, NOT inside the Steam
# library (q3vr ships its own q3vr.exe and is not launched through
# Steam).
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
    Write-Info "Existing installation found. Quake 3 VR files will be merged; additional files are preserved."
}
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

# Extract (the release is a .zip; Expand-ArchiveOrFallback handles it
# via 7z.exe if present, else PowerShell's Expand-Archive, with an
# interactive manual fallback).
$exResult = Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modExtract `
                -Label "Quake 3 VR" `
                -SkipMessage "Skipped - Quake 3 VR archive was NOT extracted; install is incomplete."
if ([string]$exResult -eq "quit") {
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..."; exit 1
}

# The portable release may wrap everything in a version folder. Flatten:
# if the extract dir holds exactly one folder, treat that as the payload
# root. This also recovers if the extractor nested it one deeper.
$payload = $modExtract
$probe = @(Get-ChildItem -Path $modExtract -ErrorAction SilentlyContinue)
if ($probe.Count -eq 1 -and $probe[0].PSIsContainer) { $payload = $probe[0].FullName }
# Near-folder recovery: if q3vr.exe still is not at the payload root,
# search one level down for the folder that contains it.
if (-not (Test-Path (Join-Path $payload $GAME_EXE))) {
    $hit = Get-ChildItem -Path $modExtract -Recurse -Filter $GAME_EXE -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $payload = Split-Path $hit.FullName -Parent }
}

Write-Host "  Copying Quake 3 VR files ... " -NoNewline -ForegroundColor White
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

# q3vr ships its own baseq3 (with pakQ3VR.pk3). Ensure it exists, then
# add the base-game pak0.pk3 (required) plus any pak1-8.pk3 the user
# owns (point releases / Team Arena content). The archive uses
# "baseq3"; if missing, fall back to any case-variant or create it.
$destBaseq3 = Join-Path $installRoot "baseq3"
if (-not (Test-Path $destBaseq3)) {
    $existing = Get-ChildItem -Path $installRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq "baseq3" } | Select-Object -First 1
    if ($existing) { $destBaseq3 = $existing.FullName } else { New-Item -ItemType Directory -Path $destBaseq3 -Force | Out-Null }
}

$failed = @()
$copiedOptional = 0
# pak0.pk3 is mandatory; pak1.pk3 - pak8.pk3 are optional and only
# copied when present in the source install.
$pakList = @("pak0.pk3","pak1.pk3","pak2.pk3","pak3.pk3","pak4.pk3","pak5.pk3","pak6.pk3","pak7.pk3","pak8.pk3")
foreach ($pak in $pakList) {
    $src = Join-Path $sourceBaseq3 $pak
    $required = ($pak -ieq $BASE_PAK)
    if (Test-Path $src) {
        Write-Host "  Copying $pak ... " -NoNewline -ForegroundColor White
        try {
            Copy-Item -Path $src -Destination $destBaseq3 -Force
            Write-Host "OK" -ForegroundColor Green
            if (-not $required) { $copiedOptional++ }
        } catch {
            Write-Host "FAILED" -ForegroundColor Red
            if ($required) { $failed += $pak }
        }
    } else {
        # Case-variant fallback search for the required pak only.
        if ($required) {
            $alt = Get-ChildItem -Path $sourceBaseq3 -Filter $pak -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($alt) {
                Write-Host "  Copying $pak ... " -NoNewline -ForegroundColor White
                try { Copy-Item -Path $alt.FullName -Destination (Join-Path $destBaseq3 $pak) -Force; Write-Host "OK" -ForegroundColor Green }
                catch { Write-Host "FAILED" -ForegroundColor Red; $failed += $pak }
            } else {
                Write-Host "  $pak ... NOT FOUND" -ForegroundColor Red
                $failed += $pak
            }
        }
    }
}
if ($copiedOptional -gt 0) { Write-Info "Copied $copiedOptional additional pak file(s) (point release / Team Arena)." }

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($failed.Count -eq 0) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# STEP 4: Summary + desktop shortcut + first-launch notes
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

$gameExePath = Join-Path $installRoot $GAME_EXE

Write-Host "  Installation folder: $installRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  [x] $MOD_NAME" -ForegroundColor Green
if ($failed.Count -eq 0) {
    Write-Host "  [x] $BASE_PAK copied into baseq3" -ForegroundColor Green
} else {
    Write-Host "  [ ] Base PAK missing: $($failed -join ', ')" -ForegroundColor Red
    Write-Host "      Copy it manually into: $destBaseq3" -ForegroundColor Yellow
    Write-Host "      Source: $sourceBaseq3" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host "  starting sometimes out of focus." -ForegroundColor White
Write-Host "  Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the desktop" -ForegroundColor White
Write-Host "  shortcut 'Quake 3 VR'." -ForegroundColor White
Write-Host ""
Write-Host "  Before jumping in, open the in-game Setup menu and set your" -ForegroundColor Gray
Write-Host "  controls, turning, and comfort options to your liking." -ForegroundColor Gray
Write-Host ""
Write-Host "  Bindings can also be changed in SteamVR -> Controller Bindings," -ForegroundColor Gray
Write-Host "  or by creating an autoexec.cfg in the baseq3 folder." -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue..."

if (Test-Path $gameExePath) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Quake 3 VR.lnk" -TargetPath $gameExePath -WorkingDir $installRoot -IconPath "$gameExePath,0"
        Write-OK "Desktop shortcut 'Quake 3 VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $($_.Exception.Message)"
        Write-Host "  Launch manually from: $gameExePath" -ForegroundColor Gray
    }
} else {
    Write-Warn "q3vr.exe not found in the install folder."
    Write-Host "  Expected at: $gameExePath" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Welcome to the Arena. Rocket launcher up - it's fragging time." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$installRoot`"" } catch {}
