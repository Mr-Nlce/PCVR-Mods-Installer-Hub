# ============================================================
# GTA Vice City VR - Installer (Vice City VR by #yevhen4817)
# ============================================================
# A native OpenXR VR adaptation of Grand Theft Auto: Vice City
# (2003), built on the reverse-engineered reVC codebase and the
# librw RenderWare reimplementation. It replaces the renderer and
# adds tracked hands, physical melee, holsters and motion-
# controlled firearms - the original game data stays untouched.
#
# The release archive is self-contained apart from the game data:
# reVC.exe plus its runtime DLLs and models\vrhands are merged
# into the Vice City folder next to gta-vc.exe. gta-vc.exe is
# NEVER replaced or modified - the flat game keeps working.
#
# Launch route: reVC.exe, never gta-vc.exe and never steam://.
# The catalog carries LaunchExe = reVC.exe and this installer
# also drops a .launch_exe marker, so "Start in VR" opens the
# mod build on Steam, retail and Rockstar copies alike.
#
# Auto-update: the Hub compares the GitHub latest tag against
# .installed_version, written VERBATIM from tag_name below.
# Re-running this installer refreshes the mod in place; the
# archive deliberately ships no reVC.ini / vr_settings.ini, so
# settings and weapon calibration survive an update.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "GTA Vice City VR Installer"

$STEAM_APPID       = "12110"
$GAME_STEAM_FOLDER = "Grand Theft Auto Vice City"
$GAME_EXE          = "gta-vc.exe"
$MOD_EXE           = "reVC.exe"

$REPO              = "dubrovskiy-yevhen-stakelogic/vice-city-vr"
$REPO_API_LATEST   = "https://api.github.com/repos/$REPO/releases/latest"
$RELEASES_PAGE     = "https://github.com/$REPO/releases"
# Last-known-good asset, used only if the GitHub API cannot be reached.
$PINNED_TAG        = "v0.5.0"
$PINNED_URL        = "https://github.com/$REPO/releases/download/v0.5.0/Vice-City-VR-v0.5.0-alpha.zip"

# Microsoft Visual C++ 2015-2022 x64 runtime - reVC.exe will not start
# without it. Version 14.0 covers 2015/2017/2019/2022 (binary compatible).
$VCRT_REG          = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
$VCRT_URL          = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " GTA Vice City VR - Installer" -ForegroundColor Cyan
    Write-Host " Vice City VR (alpha) by #yevhen4817 | reVC + librw" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Does this folder hold a real Vice City install? The mod needs the
# original game data, and gta-vc.exe is the reliable marker for it.
function Test-ViceCityRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try { return (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $GAME_EXE))) } catch { return $false }
}

Write-Header

Write-Host "  Vice City VR turns the original 2003 Grand Theft Auto: Vice" -ForegroundColor White
Write-Host "  City into a native OpenXR game: stereo rendering, 6DOF head" -ForegroundColor White
Write-Host "  tracking, tracked hands, physical melee and motion-controlled" -ForegroundColor White
Write-Host "  guns. Motion controllers. Needs your own legal PC copy of the" -ForegroundColor White
Write-Host "  2003 game - the mod ships no game data and changes none." -ForegroundColor White
Write-Host ""
Write-Host "  This is an early alpha: the full campaign has not been played" -ForegroundColor Yellow
Write-Host "  through yet. Back up any saves you care about." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: locate Grand Theft Auto: Vice City
# -------------------------------------------------------
Write-Step 1 4 "Locating Grand Theft Auto: Vice City"

$gamePath = $null

# Steam (registry + libraryfolders + appmanifest), via the shared helper.
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
    $gamePath = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($GAME_STEAM_FOLDER) -ProbeExe $GAME_EXE
}
# Rockstar Games Launcher / Rockstar Store and retail/DVD installs.
# Steam is handled above; these are the only other verified layouts.
# [IO.Path]::Combine + guarded Test-Path, never Join-Path on a drive
# that may not exist.
if (-not (Test-ViceCityRoot $gamePath)) {
    $cands = @(
        "C:\Program Files\Rockstar Games\Grand Theft Auto Vice City",
        "C:\Program Files (x86)\Rockstar Games\Grand Theft Auto Vice City"
    )
    foreach ($c in $cands) { if (Test-ViceCityRoot $c) { $gamePath = $c; break } }
}
# A location recorded by a previous install.
if (-not (Test-ViceCityRoot $gamePath)) {
    try {
        $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1
        if ($rec) { $rec = $rec.Trim(); if (Test-ViceCityRoot $rec) { $gamePath = $rec } }
    } catch {}
}
# Manual fallback: drag & drop the game folder onto the window.
while (-not (Test-ViceCityRoot $gamePath)) {
    Write-Warn "Could not find Vice City automatically."
    Write-Host "  Drag & drop your VICE CITY GAME FOLDER onto this window (the" -ForegroundColor White
    Write-Host "  one containing $GAME_EXE), then press Enter." -ForegroundColor White
    Write-Host "  Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host "  Game folder").Trim().Trim('"')
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit."; exit 1 }
    if (Test-ViceCityRoot $raw) { $gamePath = $raw }
    else { Write-Fail "That folder does not contain $GAME_EXE." }
}
Write-OK "Found Vice City: $gamePath"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile $MOD_EXE -Label "Vice City VR"

# -------------------------------------------------------
# STEP 2: prerequisite - Visual C++ 2015-2022 x64 runtime
# -------------------------------------------------------
Write-Step 2 4 "Checking the Visual C++ runtime"

$vcOk = $false
try {
    $vc = Get-ItemProperty -Path $VCRT_REG -ErrorAction Stop
    if ($vc -and ($vc.Installed -eq 1 -or $vc.Version)) { $vcOk = $true }
} catch { $vcOk = $false }

if ($vcOk) {
    Write-OK "Microsoft Visual C++ 2015-2022 (x64) is installed."
} else {
    Write-Host ""
    Write-Host "  +======================================================+" -ForegroundColor Yellow
    Write-Host "  |            ACTION REQUIRED - MISSING RUNTIME          |" -ForegroundColor Yellow
    Write-Host "  +======================================================+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  The Microsoft Visual C++ 2015-2022 Redistributable (x64)" -ForegroundColor White
    Write-Host "  was not detected. Without it reVC.exe will not start and" -ForegroundColor White
    Write-Host "  Windows reports a missing MSVCP140.dll or VCRUNTIME140.dll." -ForegroundColor White
    Write-Host ""
    Write-Host "  Get it from Microsoft (free, official):" -ForegroundColor White
    Write-Host ""
    Write-Host "  $VCRT_URL" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  The installation continues either way - you can install the" -ForegroundColor Gray
    Write-Host "  runtime afterwards and the mod will work once it is in." -ForegroundColor Gray
    Write-Host ""
    $openVc = (Read-Host "  Open that download page now? [Y/n]").Trim()
    if ($openVc -eq "" -or $openVc -match '^(?i)y') {
        try { Start-Process $VCRT_URL; Write-OK "Opened in your browser." }
        catch { Write-Warn "Could not open the browser - copy the link above manually." }
    }
    Pause-User "Press Enter to continue the installation..."
}

# -------------------------------------------------------
# STEP 3: resolve + download the release
# -------------------------------------------------------
Write-Step 3 4 "Downloading the latest Vice City VR release"
Write-Info "Resolving the newest release via the GitHub API..."

$zipUrl = $null
$relTag = $null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri $REPO_API_LATEST -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    # Asset names may change between releases, so match any .zip and only
    # PREFER a Vice-City-looking name - never hard-require one exact form.
    $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
    $asset = $zips | Where-Object { $_.name -match '(?i)vice.?city' } | Select-Object -First 1
    if (-not $asset) { $asset = $zips | Select-Object -First 1 }
    if ($asset -and $asset.browser_download_url) {
        $zipUrl = [string]$asset.browser_download_url
        $relTag = [string]$rel.tag_name
        Write-OK "Latest release: $relTag"
    }
} catch { }
if (-not $zipUrl) {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known build."
    $zipUrl = $PINNED_URL
    $relTag = $PINNED_TAG
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ViceCityVR_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zipPath = Join-Path $tmp "ViceCityVR.zip"

$dl = Invoke-DownloadOrFallback -Url $zipUrl -Destination $zipPath `
        -Label "Vice City VR ($relTag)" `
        -ManualUrl $RELEASES_PAGE `
        -Instructions "Download the Vice-City-VR-*.zip asset from the latest release, save it as '$zipPath', then choose Retry." `
        -SkipMessage "Skipped - the mod was not downloaded, so nothing can be installed."
if ([string]$dl -eq "quit") { try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }
if (-not ($dl -is [bool] -and $dl)) {
    # Last resort before giving up: a manual download sitting in Downloads.
    $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter "*Vice*City*VR*.zip" -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($manualZip) {
        Write-OK "Found a manual download: $($manualZip.Name)"
        $zipPath = $manualZip.FullName
    } else {
        Write-Fail "No mod archive available - cannot continue."
        try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."; exit 1
    }
}
Write-OK "Archive ready."

# -------------------------------------------------------
# STEP 4: install into the game folder
# -------------------------------------------------------
Write-Step 4 4 "Installing into the game folder"

# The game must be closed or reVC.exe / the DLLs stay locked.
$vcProc = Get-Process -Name "reVC","gta-vc" -ErrorAction SilentlyContinue
if ($vcProc) {
    Write-Warn "Vice City is running - close it completely, then press Enter."
    Pause-User "Press Enter once the game is closed..."
}

# Payload-verified extract. The archive wraps everything in a
# Vice-City-VR-<ver>\ folder and the modder can change that any day, so
# resolve the real payload root from the known mod exe, merge into the
# game folder and verify reVC.exe actually arrived. The merge is
# per-file, so models\vrhands lands INSIDE the existing models folder
# without touching gta3.img or any other original game data.
$exRes = Expand-ArchiveToTarget -ArchivePath $zipPath -TargetDir $gamePath `
            -RelModFile $MOD_EXE -Markers @("reVC.exe","openxr_loader.dll") `
            -Label "Vice City VR" `
            -SkipMessage "Skipped - the archive was not unpacked, so the mod is not installed."
if ([string]$exRes -eq "quit") { try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }

if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $MOD_EXE)))) {
    Write-Fail "$MOD_EXE is missing after extraction - the package layout may have changed."
    Write-Info "Get it manually from:"
    Write-Info "  $RELEASES_PAGE"
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}
Write-OK "Mod files in place ($MOD_EXE next to $GAME_EXE)."
Write-Info "$GAME_EXE was not touched - the flat game still works."

# Hub markers: install path, EXACT release tag for the update badge, and
# .launch_exe so "Start in VR" opens reVC.exe rather than the flat game
# (Steam would otherwise start gta-vc.exe through steam://rungameid).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value ([System.IO.Path]::Combine($gamePath, $MOD_EXE)) -Encoding UTF8 -Force } catch {}

# Desktop shortcut straight to the mod exe. reVC.exe is the only build
# carrying the mod (Steam launches the flat gta-vc.exe), so the shortcut
# is the outside-the-Hub way to start the VR version. Uses the exe's own
# icon; working dir = game root so reVC finds the original game data.
$modExePath = [System.IO.Path]::Combine($gamePath, $MOD_EXE)
$lnk = New-DesktopShortcut -TargetPath $modExePath -ShortcutName "GTA Vice City VR" `
         -WorkingDir $gamePath -IconPath $modExePath `
         -Description "Grand Theft Auto: Vice City in VR (reVC + Vice City VR)"
if ($lnk) { Write-OK "Desktop shortcut created: GTA Vice City VR" }
else      { Write-Warn "Could not create the desktop shortcut - start $MOD_EXE from the game folder or use 'Start in VR' in the Hub." }

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |            SET THIS BEFORE YOU PLAY                   |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Active OpenXR runtime  " -NoNewline -ForegroundColor White; Write-Host " your headset software " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Connect the headset    " -NoNewline -ForegroundColor White; Write-Host " BEFORE starting the game " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Quest Link, Air Link, SteamVR or an equivalent PC link all" -ForegroundColor Gray
Write-Host "  work. Quest 3 is the modder's primary tested setup." -ForegroundColor Gray
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or use the new" -ForegroundColor Gray
Write-Host "    'GTA Vice City VR' desktop shortcut. Both run $MOD_EXE," -ForegroundColor Gray
Write-Host "    which is the only build with the mod - starting the game" -ForegroundColor Gray
Write-Host "    from Steam gives you the normal flat version." -ForegroundColor Gray
Write-Host ""
Write-Host "    Misaligned view? Both grips + both thumbstick clicks recenters." -ForegroundColor Gray
Write-Host "    Both grips + Menu opens the in-headset settings." -ForegroundColor Gray
Write-Host ""
Write-Host "  See the README for the full control scheme and troubleshooting." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Welcome to the 1980s - the neon, the pastels, the whole coast." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
