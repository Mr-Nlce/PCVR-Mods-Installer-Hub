# -------------------------------------------------------
# BioShock Remastered VR Mod Installer
# Bioshock Remastered VR by BioVRDev - native OpenXR VR
#
# The mod is five files that live next to BioshockHD.exe. There is no
# injector and no plugin folder: dxgi.dll loads it when the game starts.
# After copying, the mod's own FirstTimeSetup.bat has to run once - it
# writes the resolution, FOV and windowed-mode values the mod needs into
# Bioshock.ini before the game can overwrite them again.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "BioShock Remastered VR Installer"

$MOD_AUTHOR = "BioVRDev"
$GAME_APPID = "409710"
$GAME_EXE   = "BioshockHD.exe"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$REPO         = "BioVRDev/Bioshock-Remastered-VR"
$RELEASES_API = "https://api.github.com/repos/$REPO/releases/latest"
$RELEASES_URL = "https://github.com/$REPO/releases"
$NEXUS_CUTSCENES = "https://www.nexusmods.com/bioshock/mods/81?tab=files"

# Everything the release ships. All of it belongs beside the game exe.
$MOD_FILES = @("dxgi.dll", "BioshockVR.dll", "BioshockVR.ini", "openxr_loader.dll", "FirstTimeSetup.bat")

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " BioShock Remastered VR Installer" -ForegroundColor Cyan
    Write-Host " Installs: Bioshock Remastered VR by $MOD_AUTHOR" -ForegroundColor Gray
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

# Returns the folder that actually holds BioshockHD.exe. Steam and GOG use
# Build\Final, Epic uses Build\FinalEpic - so the exe is searched for rather
# than assumed.
function Get-BuildFolder {
    param([string]$GameRoot)
    foreach ($sub in @("Build\Final", "Build\FinalEpic")) {
        try {
            $c = [System.IO.Path]::Combine($GameRoot, $sub)
            if (Test-Path -LiteralPath ([System.IO.Path]::Combine($c, $GAME_EXE))) { return $c }
        } catch {}
    }
    try {
        $hit = Get-ChildItem -LiteralPath $GameRoot -Filter $GAME_EXE -Recurse -Depth 3 -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    } catch {}
    return $null
}

function Find-BioshockRoot {
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
            $c = Join-Path $lib "steamapps\common\BioShock Remastered"
            if ((Test-Path -LiteralPath $c) -and (Get-BuildFolder -GameRoot $c)) { return $c }
        }
    }
    foreach ($c in @(
        "C:\GOG Games\BioShock Remastered",
        "C:\Program Files (x86)\GOG Galaxy\Games\BioShock Remastered",
        "C:\Program Files\Epic Games\BioShockRemastered"
    )) {
        try { if ((Test-Path -LiteralPath $c) -and (Get-BuildFolder -GameRoot $c)) { return $c } } catch {}
    }
    return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header
Write-Host " Native VR for BioShock Remastered: real stereo rendering, head" -ForegroundColor White
Write-Host " tracking, motion controllers and 6-DOF weapon holding." -ForegroundColor White
Write-Host ""
Write-Host " Works with any OpenXR runtime - Quest via Link or Air Link," -ForegroundColor Gray
Write-Host " SteamVR, or WMR." -ForegroundColor Gray
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
# STEP 1: locate the game
# -------------------------------------------------------
Write-Step 1 4 "Locating BioShock Remastered"
$gameRoot = Find-BioshockRoot
if (-not $gameRoot) {
    $gameRoot = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("BioShock Remastered") -ProbeExe "Build\Final\$GAME_EXE"
}
if (-not $gameRoot) {
    Write-Warn "Could not find BioShock Remastered automatically."
    Write-Host "  Paste the game's main folder (the one containing Build)." -ForegroundColor White
    while (-not $gameRoot) {
        $r = (Read-Host "  BioShock Remastered folder").Trim().Trim('"').Trim("'")
        if (-not $r) { continue }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "Folder not found: $r"; continue }
        if (-not (Get-BuildFolder -GameRoot $r)) {
            Write-Fail "That folder doesn't contain $GAME_EXE (expected under Build\Final)."
            continue
        }
        $gameRoot = $r
    }
}
$buildDir = Get-BuildFolder -GameRoot $gameRoot
if (-not $buildDir) {
    Write-Fail "Found the game folder, but not $GAME_EXE inside it."
    Write-Host "  Expected under Build\Final (or Build\FinalEpic on Epic)." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Found: $buildDir"

# -------------------------------------------------------
# STEP 2: download + copy the mod
# -------------------------------------------------------
Write-Step 2 4 "Downloading the VR mod"

$work = Join-Path $env:TEMP ("bioshockvr_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$zipPath = Join-Path $work "BioshockVR.zip"
$relTag  = $null
$gotZip  = $false

try {
    $rel = Invoke-RestMethod -Uri $RELEASES_API -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -ErrorAction Stop
    $relTag = $rel.tag_name
    $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    if ($asset) {
        Write-Info "Release $relTag - downloading $($asset.name)"
        Invoke-SafeDownload -Urls @($asset.browser_download_url) -Destination $zipPath `
            -Label "Bioshock Remastered VR $relTag" -ManualUrl $RELEASES_URL | Out-Null
        $gotZip = (Test-Path -LiteralPath $zipPath)
    }
} catch { }

if (-not $gotZip) {
    # Downloads folder, then drag-and-drop - the release is public, so this
    # only happens when GitHub itself is unreachable.
    $dl = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path -LiteralPath $dl) {
        $hit = Get-ChildItem -LiteralPath $dl -Filter "*.zip" -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '(?i)bioshock' } |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($hit) {
            Write-Host "  Found in Downloads: $($hit.Name)" -ForegroundColor Cyan
            $use = (Read-Host "  Use this file? Press Enter to accept, or type N").Trim()
            if ($use -notin @("n","N")) { Copy-Item -LiteralPath $hit.FullName -Destination $zipPath -Force; $gotZip = $true }
        }
    }
}
if (-not $gotZip) {
    Write-Warn "Automatic download didn't work."
    Pause-User "Press Enter to open the releases page..." | Out-Null
    try { Start-Process $RELEASES_URL } catch {}
    while (-not $gotZip) {
        $r = (Read-Host "  Drag the downloaded ZIP here (empty to cancel)").Trim().Trim('"').Trim("'")
        if (-not $r) { Write-Fail "Nothing to install."; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
        Copy-Item -LiteralPath $r -Destination $zipPath -Force
        $gotZip = $true
    }
}

$extract = Join-Path $work "extracted"
New-Item -ItemType Directory -Path $extract -Force | Out-Null
try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not extract the archive: $($_.Exception.Message)"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

$copied = @(); $missing = @()
foreach ($f in $MOD_FILES) {
    $hit = Get-ChildItem -LiteralPath $extract -Filter $f -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $hit) { $missing += $f; continue }
    $dest = Join-Path $buildDir $f
    try {
        # Never overwrite something already there without keeping a copy.
        if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
            Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
        }
        Copy-Item -LiteralPath $hit.FullName -Destination $dest -Force -ErrorAction Stop
        $copied += $f
    } catch { $missing += $f }
}

if ($copied -notcontains "BioshockVR.dll" -or $copied -notcontains "dxgi.dll") {
    Write-Fail "The mod's core files did not land in the game folder."
    if ($missing.Count -gt 0) { Write-Host "  Missing: $($missing -join ', ')" -ForegroundColor Gray }
    try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Mod files copied: $($copied -join ', ')"
if ($missing.Count -gt 0) { Write-Warn "Not in this release: $($missing -join ', ')" }

# -------------------------------------------------------
# STEP 3: the mod's one-time setup
# -------------------------------------------------------
Write-Step 3 4 "One-time setup"
Write-Host "  BioShock rewrites its own config on exit, so a fresh install can" -ForegroundColor Gray
Write-Host "  never keep the VR resolution and FOV. The mod's setup writes them" -ForegroundColor Gray
Write-Host "  before the game runs and breaks that loop. It backs up your" -ForegroundColor Gray
Write-Host "  Bioshock.ini first and restores it if anything goes wrong." -ForegroundColor Gray

$setup = Join-Path $buildDir "FirstTimeSetup.bat"
if (Test-Path -LiteralPath $setup) {
    Write-Host ""
    Write-Host " >>> Make sure BioShock is CLOSED, then let the setup run.        " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " >>> It finishes on its own - this window waits for it.           " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Pause-User "Press Enter to run the setup..." | Out-Null
    try {
        Start-Process -FilePath $setup -WorkingDirectory $buildDir -Wait
        Write-OK "Setup finished."
    } catch {
        Write-Fail "Could not run it: $($_.Exception.Message)"
        Write-Host "  Run FirstTimeSetup.bat yourself in $buildDir" -ForegroundColor Yellow
    }
} else {
    Write-Warn "FirstTimeSetup.bat isn't in this release - skipping."
}

# -------------------------------------------------------
# STEP 4: Fullscreen Cutscenes (optional, recommended by the mod author)
# -------------------------------------------------------
Write-Step 4 4 "Fullscreen cutscenes (optional)"
Write-Host "  BioShock's cutscenes play with black bars top and bottom, which" -ForegroundColor Gray
Write-Host "  stay visible on the VR screen. This community mod removes them." -ForegroundColor Gray
Write-Host ""
$wantCut = ""
while ($wantCut -notin @("y","Y","n","N")) {
    $wantCut = (Read-Host "  Install the fullscreen cutscenes mod? (Y/N)").Trim()
}

if ($wantCut -in @("y","Y")) {
    $flashDir = [System.IO.Path]::Combine($gameRoot, "ContentBaked", "pc", "FlashMovies")
    if (-not (Test-Path -LiteralPath $flashDir)) {
        Write-Warn "Couldn't find ContentBaked\pc\FlashMovies - skipping."
    } else {
        Pause-User "Press Enter to open the Nexus download page..." | Out-Null
        try { Start-Process $NEXUS_CUTSCENES } catch { Write-Warn "Open manually: $NEXUS_CUTSCENES" }

        $dl = Join-Path $env:USERPROFILE "Downloads"
        $cutArc = $null
        while (-not $cutArc) {
            $hit = $null
            if (Test-Path -LiteralPath $dl) {
                $hit = Get-ChildItem -LiteralPath $dl -File -ErrorAction SilentlyContinue |
                       Where-Object { $_.Extension -match '(?i)\.(rar|zip|7z)$' -and $_.Name -match '(?i)cutscene' } |
                       Sort-Object LastWriteTime -Descending | Select-Object -First 1
            }
            if ($hit) {
                Write-Host "  Found in Downloads: $($hit.Name)" -ForegroundColor Cyan
                $use = (Read-Host "  Use this file? Press Enter to accept, or type N").Trim()
                if ($use -notin @("n","N")) { $cutArc = $hit.FullName; break }
            }
            $r = (Read-Host "  Drag the downloaded archive here (empty to skip)").Trim().Trim('"').Trim("'")
            if (-not $r) { break }
            if (Test-Path -LiteralPath $r) { $cutArc = $r } else { Write-Fail "File not found: $r" }
        }

        if ($cutArc) {
            $cutTmp = Join-Path $env:TEMP ("bscut_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
            New-Item -ItemType Directory -Path $cutTmp -Force | Out-Null
            # The download is a .rar, which Expand-Archive can't read - 7-Zip can.
            $sevenZip = $null
            try { $sevenZip = Get-SevenZip } catch {}
            $ok = $false
            if ($sevenZip) {
                try { & $sevenZip x "-o$cutTmp" $cutArc -y *> $null; $ok = $true } catch {}
            }
            if (-not $ok) {
                try { Expand-Archive -LiteralPath $cutArc -DestinationPath $cutTmp -Force -ErrorAction Stop; $ok = $true } catch {}
            }

            $swfs = @()
            if ($ok) { $swfs = @(Get-ChildItem -LiteralPath $cutTmp -Filter "HUDPC.swf" -Recurse -File -ErrorAction SilentlyContinue) }
            if ($swfs.Count -eq 0) {
                Write-Fail "No HUDPC.swf found inside the archive - skipping."
            } else {
                # The archive ships a plain version and one combined with the
                # Deep Pockets HUD mod. Only the plain one is wanted here, so
                # pick it outright instead of asking - "Vanilla" if it's
                # labelled that way, otherwise the one that isn't the combo.
                $chosen = $swfs | Where-Object { $_.FullName -match '(?i)vanilla' } | Select-Object -First 1
                if (-not $chosen) { $chosen = $swfs | Where-Object { $_.FullName -notmatch '(?i)deep\s*pockets' } | Select-Object -First 1 }
                if (-not $chosen) { $chosen = $swfs[0] }
                $dest = Join-Path $flashDir "HUDPC.swf"
                try {
                    if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
                        Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
                    }
                    Copy-Item -LiteralPath $chosen.FullName -Destination $dest -Force -ErrorAction Stop
                    Write-OK "Fullscreen cutscenes installed."
                    Write-Host "  Note: this replaces the game's HUD file, so it removes any" -ForegroundColor DarkGray
                    Write-Host "  other HUD mod. The original is kept as HUDPC.swf.hubbak" -ForegroundColor DarkGray
                } catch {
                    Write-Fail "Could not copy HUDPC.swf: $($_.Exception.Message)"
                }
            }
            try { Remove-Item $cutTmp -Recurse -Force -EA SilentlyContinue } catch {}
        } else {
            Write-Info "Skipped."
        }
    }
}

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
if ($relTag) { try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } catch {} }
try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " What to do now:" -ForegroundColor White
Write-Host "   1) Start your OpenXR runtime and put the headset on." -ForegroundColor Gray
Write-Host "   2) Launch with 'Start in VR' in the Hub, or from Steam -" -ForegroundColor Gray
Write-Host "      no injector, no launcher." -ForegroundColor Gray
Write-Host "   3) Play with motion controllers; the weapon follows your hand." -ForegroundColor Gray
Write-Host ""
Write-Host " Re-run the setup only if you change ResolutionX, ResolutionY or" -ForegroundColor Gray
Write-Host " GameFovDegrees in BioshockVR.ini." -ForegroundColor Gray
Write-Host ""
Write-Host " Note: dxgi.dll can only be owned by one mod. ReShade, DXVK and" -ForegroundColor Gray
Write-Host " Special K use the same filename and can't run alongside it." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to exit." | Out-Null
