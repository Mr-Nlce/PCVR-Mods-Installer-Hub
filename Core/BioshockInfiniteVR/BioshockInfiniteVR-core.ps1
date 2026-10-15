# ============================================================
# BioShock Infinite VR - Installer (bioshock-vr by mohamad-balouza)
# ============================================================
# Native VR for BioShock Infinite: stereo rendering, 6DOF head
# tracking and motion controllers - the gun in one hand, the vigor in the
# other. Since v0.7.0 ONE release serves both BioShock games: the same
# two DLLs detect which game loaded them.
#
# Install = copy two files next to the game exe:
#   <game>\Binaries\Win32\xinput1_3.dll     (the injector)
#   <game>\Binaries\Win32\bioshockvr.dll    (the mod)
# NOTE: NOT Build\Final as in BioShock 1 and 2 - Infinite runs on
# Unreal Engine 3 and keeps its binaries elsewhere. Both are
# handled. No game file is modified; uninstalling is deleting the two.
#
# The calibration is BUILT INTO the DLL, so nothing has to be written to
# %LOCALAPPDATA%. The zip's preset-bsi folder is only the author's own
# tuning for people who experimented and want it back - the README says
# where it goes, the installer stays out of that folder.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "BioShock Infinite VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " BioShock Infinite VR - Installer" -ForegroundColor Cyan
    Write-Host " bioshock-vr by balouza | BioShock Infinite | motion controls" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
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
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO         = "mohamad-balouza/bioshock-vr"
$REPO_API     = "https://api.github.com/repos/$REPO/releases"
$RELEASES_URL = "https://github.com/$REPO/releases"
$APP_ID       = "8870"
$GAME_EXE     = "BioShockInfinite.exe"
$MOD_FILES    = @("xinput1_3.dll", "bioshockvr.dll", "bvr_steamvr32.dll", "openvr_api.dll")
# Steam, GOG and Epic all put the binaries under Binaries\Win32.
# !!! NOT Build\Final - THAT IS THE DIFFERENCE TO BIOSHOCK 1 AND 2 !!!
# Infinite runs on Unreal Engine 3 and keeps its binaries elsewhere:
# Binaries\Win32. The author spells this out in his notes because it
# is the most common mix-up.
$BIN_SUBDIRS  = @("Binaries\Win32")
$CANDIDATE_ROOTS = @(
    "C:\Program Files (x86)\Steam\steamapps\common\BioShock Infinite",
    "C:\GOG Games\BioShock Infinite",
    "C:\Program Files (x86)\GOG Galaxy\Games\BioShock Infinite",
    "C:\Program Files\Epic Games\BioshockInfiniteCompleteEdition",
    "C:\Program Files (x86)\Epic Games\BioshockInfiniteCompleteEdition"
)

# Find the folder that really holds BioShockInfinite.exe, whatever the store.
function Find-BioshockInfiniteBin {
    $roots = New-Object System.Collections.Generic.List[string]
    try {
        $steam = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("BioShock Infinite") -ProbeExe "Binaries\Win32\$GAME_EXE"
        if ($steam) { [void]$roots.Add([string]$steam) }
    } catch { }
    foreach ($c in $CANDIDATE_ROOTS) { [void]$roots.Add($c) }
    foreach ($r in $roots) {
        if (-not $r) { continue }
        foreach ($sub in $BIN_SUBDIRS) {
            $cand = Join-Path $r $sub
            if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { return $cand }
        }
    }
    return $null
}

function Get-LatestBioshockVR {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri "$REPO_API`?per_page=5" -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($rel in @($rels)) {
            $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
            if ($zips.Count -gt 0) {
                $pick = $zips | Where-Object { $_.name -match '(?i)bioshock' } | Select-Object -First 1
                if (-not $pick) { $pick = $zips[0] }
                return @{ Url = [string]$pick.browser_download_url; Tag = [string]$rel.tag_name; Name = [string]$pick.name }
            }
        }
    } catch { }
    return $null
}

Write-Header
Write-Host "  Columbia at eye level: stereo rendering, 6DOF head tracking and" -ForegroundColor Gray
Write-Host "  motion controllers - the gun in your right hand, the vigor" -ForegroundColor Gray
Write-Host "  in your left, each aiming from that hand. The HUD rides a" -ForegroundColor Gray
Write-Host "  readable floating panel, and the calibration ships tuned." -ForegroundColor Gray
Write-Host ""
Write-Host "  Needed: BioShock Infinite and an OpenXR runtime." -ForegroundColor White
Write-Host "  Virtual Desktop (VDXR), Steam Link or SteamVR can provide OpenXR." -ForegroundColor White
Show-AntivirusNotice
Pause-User "Press Enter to start the installation..." | Out-Null

# ---- 1. locate the game -------------------------------------
Write-Step 1 5 "Locating BioShock Infinite"

$binDir = Find-BioshockInfiniteBin
if ($binDir) { Write-OK "Found: $binDir" }
else {
    Write-Warn "BioShock Infinite was not found automatically."
    Write-Host "  Drag the game folder here and press Enter - the one holding" -ForegroundColor White
    Write-Host "  Binaries\Win32\$GAME_EXE, for example:" -ForegroundColor White
    Write-Host "    C:\Program Files (x86)\Steam\steamapps\common\BioShock Infinite" -ForegroundColor Gray
    while (-not $binDir) {
        $r = (Read-Host "  Folder").Trim().Trim('"')
        if (-not $r) { Write-Fail "Nothing entered."; continue }
        foreach ($sub in @("", "Binaries\Win32")) {
            $cand = if ($sub) { Join-Path $r $sub } else { $r }
            if (Test-Path -LiteralPath (Join-Path $cand $GAME_EXE)) { $binDir = $cand; break }
        }
        if (-not $binDir) { Write-Fail "$GAME_EXE not found under: $r" }
    }
    Write-OK "Using: $binDir"
}

# Resolve this before installation: the exclusion covers the complete game
# root, while the watched DLLs themselves land in Binaries\Win32.
$gameRoot = $binDir
foreach ($sub in $BIN_SUBDIRS) {
    if ($gameRoot -like ("*\" + $sub)) { $gameRoot = $gameRoot.Substring(0, $gameRoot.Length - $sub.Length - 1); break }
}

# A leftover injector from the other head-tracking mod uses the SAME file
# name - the mod's own README says the two cannot coexist.
$existing = Join-Path $binDir "xinput1_3.dll"
$foreignInjector = $false
if (Test-Path -LiteralPath $existing) {
    try {
        $desc = (Get-Item -LiteralPath $existing).VersionInfo.FileDescription
        if ($desc -and ($desc -notmatch '(?i)bioshock ?vr|balouza')) { $foreignInjector = $true }
    } catch { }
}

# ---- 2. download --------------------------------------------
Write-Step 2 5 "Downloading the mod"

$tmp = Join-Path $env:TEMP ("bs2vr_" + [Guid]::NewGuid().ToString("N"))
try { New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null }
catch { Write-Fail "Could not create a temp folder: $_"; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
$zipDest = Join-Path $tmp "bioshock-vr.zip"

$urls = New-Object System.Collections.Generic.List[string]
$relTag = $null
Write-Info "Resolving the newest release ..."
$latest = Get-LatestBioshockVR
if ($latest) {
    Write-OK "Release: $($latest.Tag)  ($($latest.Name))"
    $relTag = [string]$latest.Tag
    [void]$urls.Add([string]$latest.Url)
} else {
    Write-Warn "GitHub API not reachable - you will be pointed at the releases page."
}

$downloadInfo = @{}
if (-not $latest) { throw 'The current BioShock VR release could not be verified; no game files were changed.' }
Invoke-SafeDownload -Urls $urls -Destination $zipDest -Label "bioshock-vr" -DownloadInfo $downloadInfo -AllowSkip $false `
    -ManualUrl $RELEASES_URL `
    -Instructions "Download the newest 'bioshock-vr-*.zip' from the releases page, save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null
if (-not $latest -or [string]$downloadInfo.Url -ne [string]$latest.Url) {
    throw 'The BioShock Infinite VR archive has no verified release identity; no game files were changed.'
}

while (-not (Test-Path -LiteralPath $zipDest)) {
    Write-Fail "The archive is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download bioshock-vr" -Subject "the bioshock-vr release archive" `
        -Url $RELEASES_URL -DestFile $zipDest `
        -Instructions "Download the .zip from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded archive." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null; exit 1
    }
}
Write-OK "Archive ready."

# ---- 3. install ---------------------------------------------
Write-Step 3 5 "Installing into $binDir"

$exDir = Join-Path $tmp "x"
try {
    New-Item -ItemType Directory -Path $exDir -Force -ErrorAction Stop | Out-Null
    Expand-Archive -LiteralPath $zipDest -DestinationPath $exDir -Force -ErrorAction Stop
} catch {
    Write-Fail "Unpacking failed: $($_.Exception.Message)"
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}

# A complete package and preset are required before changing either the game
# or the user's settings. All old files are snapshotted for rollback.
$payload = @{}
foreach ($f in $MOD_FILES) {
    $hit = Get-ChildItem -LiteralPath $exDir -Filter $f -Recurse -File -ErrorAction SilentlyContinue |
           Where-Object { $_.DirectoryName -notmatch '(?i)preset' } | Select-Object -First 1
    if (-not $hit -or $hit.Length -le 0) {
        Write-Fail "Required mod file is absent or empty: $f"
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit, then retry with a complete archive." | Out-Null
        exit 1
    }
    $payload[$f] = $hit.FullName
}
$presetSrc = Get-ChildItem -LiteralPath $exDir -Filter 'vrpreset.ini' -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $_.DirectoryName -match '(?i)preset-bsi' } | Select-Object -First 1
if (-not $presetSrc -or $presetSrc.Length -le 0 -or -not $relTag -or
    -not (Test-IsTrackableInstalledVersion -Version $relTag)) {
    Write-Fail 'The archive has no Infinite VR preset or trackable release version. Nothing was installed.'
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User 'Press Enter to exit.' | Out-Null
    exit 1
}

Write-Step 4 5 'Turning VR on'
$presetDir = Join-Path $env:LOCALAPPDATA 'BioshockVR\bsi'
$presetDst = Join-Path $presetDir 'vrpreset.ini'
$presetBackup = "$presetDst.bak"
$writePreset = $true
if (Test-Path -LiteralPath $presetDst -PathType Leaf) {
    Write-Host ''
    Write-Host '  You already have VR settings for Infinite:' -ForegroundColor White
    Write-Host "     $presetDst" -ForegroundColor Gray
    Write-Host '  Replacing them enables stereo/head tracking and backs up your tuning.' -ForegroundColor White
    $writePreset = Read-YesNo "  Replace them with the author's tested settings?"
}

$versionPath = Join-Path $gameRoot '.pcvrhub_version'
$pathMarker = Join-Path $SCRIPT_DIR '.installed_path'
$versionMarker = Join-Path $SCRIPT_DIR '.installed_version'
$statusPath = [string]$env:PCVR_HUB_INSTALL_STATUS_PATH
$targets = @($MOD_FILES | ForEach-Object { Join-Path $binDir $_ }) + @($presetDst,$presetBackup,$versionPath,$pathMarker,$versionMarker)
if ($statusPath) { $targets += $statusPath }
$snapshots = @{}
$rollbackDir = Join-Path $tmp 'rollback'
$parked = $null
$installError = $null
try {
    New-Item -ItemType Directory -Path $rollbackDir -Force -ErrorAction Stop | Out-Null
    foreach ($target in $targets) {
        if (Test-Path -LiteralPath $target -PathType Container) { throw "A file target is a directory: $target" }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $snapshot = Join-Path $rollbackDir ([string]$snapshots.Count)
            Copy-Item -LiteralPath $target -Destination $snapshot -ErrorAction Stop
            $snapshots[$target] = $snapshot
        } else { $snapshots[$target] = $null }
    }
    if ($foreignInjector) {
        Write-Warn "Another mod's xinput1_3.dll is already there - the two cannot coexist."
        $parked = "$existing.replaced-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if (Test-Path -LiteralPath $parked) { throw "Backup destination already exists: $parked" }
        Copy-Item -LiteralPath $existing -Destination $parked -ErrorAction Stop
        Write-OK "Kept the previous injector as $(Split-Path $parked -Leaf)"
    }
    foreach ($f in $MOD_FILES) {
        $target = Join-Path $binDir $f
        Copy-Item -LiteralPath $payload[$f] -Destination $target -Force -ErrorAction Stop
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $payload[$f] -Algorithm SHA256).Hash) { throw "Copy verification failed: $f" }
        Write-OK "$f installed."
    }
    if ($writePreset) {
        if (-not (Test-Path -LiteralPath $presetDir -PathType Container)) {
            New-Item -ItemType Directory -Path $presetDir -Force -ErrorAction Stop | Out-Null
        }
        if ($snapshots[$presetDst]) {
            Copy-Item -LiteralPath $presetDst -Destination $presetBackup -Force -ErrorAction Stop
            Write-OK 'Your settings were backed up as vrpreset.ini.bak.'
        }
        Copy-Item -LiteralPath $presetSrc.FullName -Destination $presetDst -Force -ErrorAction Stop
        if ((Get-FileHash -LiteralPath $presetDst -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $presetSrc.FullName -Algorithm SHA256).Hash) { throw 'VR preset copy verification failed.' }
        Write-OK 'VR switches set: stereo on, head tracking on, near-square resolution.'
    } else { Write-Info 'Kept your own settings.' }
    $avFilesOk = Confirm-PlacedFilesSurvive `
        -Paths @($MOD_FILES | ForEach-Object { Join-Path $binDir $_ }) `
        -GameDir $gameRoot -ArchivePath $zipDest
    if (-not $avFilesOk) { throw 'Required mod files did not survive the post-copy check.' }
    foreach ($f in $MOD_FILES) {
        $target = Join-Path $binDir $f
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Required mod file is missing: $f" }
    }
    if (-not (Test-Path -LiteralPath $presetDst -PathType Leaf)) { throw 'Infinite VR preset is missing.' }

    Write-Step 5 5 'Finishing up'
    Set-Content -LiteralPath $pathMarker -Value $gameRoot -Encoding UTF8 -Force -ErrorAction Stop
    Set-Content -LiteralPath $versionMarker -Value $relTag -Encoding UTF8 -Force -ErrorAction Stop
    Save-InstalledStamp -GameDir $gameRoot -Version $relTag -HubDir $SCRIPT_DIR
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or
        (Get-Content -LiteralPath $versionPath -Raw).Trim() -ne $relTag) {
        throw 'The installed version receipt could not be written.'
    }
    if ($statusPath -and -not (Test-Path -LiteralPath $statusPath -PathType Leaf)) {
        throw 'The Hub install status receipt could not be written.'
    }
} catch { $installError = $_ }

if ($installError) {
    $rollbackErrors = @()
    foreach ($target in $targets) {
        try {
            if ($snapshots.ContainsKey($target) -and $snapshots[$target]) {
                Copy-Item -LiteralPath $snapshots[$target] -Destination $target -Force -ErrorAction Stop
            } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
                Remove-Item -LiteralPath $target -Force -ErrorAction Stop
            }
        } catch { $rollbackErrors += "$target : $($_.Exception.Message)" }
    }
    if ($parked -and (Test-Path -LiteralPath $parked -PathType Leaf)) {
        try { Remove-Item -LiteralPath $parked -Force -ErrorAction Stop } catch { $rollbackErrors += "$parked : $($_.Exception.Message)" }
    }
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Write-Fail "Installation did not complete: $($installError.Exception.Message)"
    if ($rollbackErrors.Count) { Write-Fail "Rollback needs attention: $($rollbackErrors -join '; ')" }
    else { Write-Warn 'Earlier game and Hub files were restored.' }
    Pause-User 'Press Enter to exit.' | Out-Null
    exit 1
}
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
Write-OK 'Installed.'

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " BioShock Infinite VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |          SET A SQUARE RESOLUTION IN THE GAME          |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Something like 2700 x 2700, not 16:9 " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Headset panels are near square. A 16:9 picture renders a wide" -ForegroundColor Gray
Write-Host "  strip that the headset throws away - square is sharper AND faster." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Start your runtime first (Virtual Desktop: set OpenXR to VDXR)," -ForegroundColor Gray
Write-Host "    then launch the game through Steam. Load your save - you are in VR." -ForegroundColor Gray
Write-Host "    Press F10 for the mod menu; APPLY at the top arms everything." -ForegroundColor Gray
Write-Host ""
Write-Host "  Right hand = gun, left hand = vigor. Aim laser and dot are on." -ForegroundColor DarkGray
Write-Host "  Press F10 in the headset for the tuning overlay." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Bring us the girl. Look up while you do it." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
