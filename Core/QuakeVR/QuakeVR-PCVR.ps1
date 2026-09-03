# =============================================================
#  Quake PCVR - Team Beef's QuakeQuest, ported (GameOrDie007)
# =============================================================
# THE SECOND MOD ON THIS TILE. Vittorio Romeo's Quake VR is a VR mod of
# its own design; this one is Simon Brown's QuakeQuest - the standalone
# Quest build - brought across to PCVR over OpenXR from the exact
# DarkPlaces commit his Android build forked.
#
# !!! IT IS SELF-CONTAINED AND INSTALLS NOWHERE. The archive extracts to
# a folder of its own and stays there: config, saves and screenshots all
# live inside it. Nothing is written into your Quake install - the Hub
# only READS from it to copy the game data across.
#
# Read from the real archive, not guessed: 19 entries, 4,259,934 bytes,
# sha256 cc7f86f0...88067 which MATCHES the one published with the
# release. The playable marker is written only after both licensed base
# PAKs are present; Romeo's build ships quakevr.exe, so the two can never
# be confused.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME     = "Quake PCVR"
$MOD_AUTHOR   = "GameOrDie007"
$REPO         = "GameOrDie007/Quake-PCVR"
$RELEASES_URL = "https://github.com/GameOrDie007/Quake-PCVR/releases"
$INFO_URL     = "https://github.com/GameOrDie007/Quake-PCVR"
$FOLDER_NAME  = "Quake PCVR"
$MOD_MARKER   = "darkplaces-sdl.exe"
$READY_MARKER = ".pcvrhub_ready"
$LAUNCH_BAT   = "Quake VR.bat"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games", (Join-Path $env:USERPROFILE "Games"))

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x  " -ForegroundColor Black -BackgroundColor Cyan; Write-Host "" }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-WritableRoot {
    param([string]$Root)
    try {
        if (-not (Test-Path -LiteralPath $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-PathLexical $Root ".pcvrhub_write_probe"
        Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Find-QuakeFileInFolder {
    param([string]$Folder, [string]$Name)
    if (-not $Folder -or -not (Test-Path -LiteralPath $Folder -PathType Container)) { return $null }
    return @(Get-ChildItem -LiteralPath $Folder -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq $Name } | Select-Object -First 1).FullName
}

function Find-QuakeBasePak {
    param([string]$Root, [string]$Name)
    if (-not $Root) { return $null }
    foreach ($relative in @("id1", "rerelease\id1")) {
        $found = Find-QuakeFileInFolder -Folder (Join-PathLexical $Root $relative) -Name $Name
        if ($found) { return [string]$found }
    }
    return $null
}

function Test-QuakeGameData {
    param([string]$Root)
    return [bool]((Find-QuakeBasePak -Root $Root -Name "pak0.pak") -and
                  (Find-QuakeBasePak -Root $Root -Name "pak1.pak"))
}

function Find-QuakeGameDataRoot {
    param([string[]]$PreferredRoots = @())

    $candidates = @($PreferredRoots)
    if ($env:QQ_QUAKEDIR) { $candidates += [string]$env:QQ_QUAKEDIR }

    # App 2310's appmanifest is authoritative for Steam libraries; the
    # same shared finder also reads GOG's installed-game registry paths.
    try {
        $automatic = Find-SteamGameFolder -AppId "2310" -SteamFolderNames @("Quake") `
            -GogNames @("Quake", "Quake: The Offering", "Quake Enhanced")
        if ($automatic) { $candidates += [string]$automatic }
    } catch {}

    $candidates += @(
        "C:\Program Files (x86)\Steam\steamapps\common\Quake",
        "C:\Program Files\Steam\steamapps\common\Quake",
        "C:\GOG Games\Quake",
        "C:\Program Files (x86)\GOG Galaxy\Games\Quake",
        "C:\Program Files\GOG Galaxy\Games\Quake"
    )
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        $root = ([string]$candidate).Trim().Trim('"')
        if (Test-QuakeGameData -Root $root) { return $root }
    }
    return $null
}

function Copy-QuakeOwnedFile {
    param([string]$Source, [string]$Destination)
    if (-not $Source -or -not (Test-Path -LiteralPath $Source -PathType Leaf)) { return $false }
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    $copy = -not (Test-Path -LiteralPath $Destination -PathType Leaf)
    if (-not $copy) {
        $copy = ((Get-Item -LiteralPath $Source).Length -ne (Get-Item -LiteralPath $Destination).Length)
    }
    if ($copy) { Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop }
    return $copy
}

function Set-QuakeExpansionLauncher {
    param([string]$InstallRoot, [string]$Label, [string]$Arguments)
    $body = @"
@echo off
rem Start Virtual Desktop on the headset and connect it FIRST.
cd /d "%~dp0"
start "" "%~dp0darkplaces-sdl.exe" -basedir . -nohome $Arguments %*
"@
    Set-Content -LiteralPath (Join-PathLexical $InstallRoot ($Label + ".bat")) `
        -Value $body -Encoding ASCII -Force
}

function Copy-QuakeOwnedData {
    param([string]$SourceRoot, [string]$InstallRoot)
    if (-not (Test-QuakeGameData -Root $SourceRoot)) { return $false }

    $id1 = Join-PathLexical $InstallRoot "id1"
    New-Item -ItemType Directory -Path $id1 -Force -ErrorAction Stop | Out-Null
    foreach ($pakName in @("pak0.pak", "pak1.pak")) {
        $sourcePak = Find-QuakeBasePak -Root $SourceRoot -Name $pakName
        [void](Copy-QuakeOwnedFile -Source $sourcePak -Destination (Join-PathLexical $id1 $pakName))
    }

    $expansions = @(
        @{ Folder="hipnotic"; Source="hipnotic\pak0.pak"; Label="Scourge of Armagon";       Args="-hipnotic" },
        @{ Folder="rogue";    Source="rogue\pak0.pak";    Label="Dissolution of Eternity";  Args="-rogue" },
        @{ Folder="dopa";     Source="rerelease\dopa\pak0.pak"; Label="Dimension of the Past";    Args="-game dopa" },
        @{ Folder="mg1";      Source="rerelease\mg1\pak0.pak";  Label="Dimension of the Machine"; Args="-game mg1" },
        @{ Folder="mg3";      Source="rerelease\mg3\pak0.pak";  Label="Dawn of the Machine";      Args="-game mg3" }
    )
    foreach ($expansion in $expansions) {
        $sourcePak = Join-PathLexical $SourceRoot $expansion.Source
        if (-not (Test-Path -LiteralPath $sourcePak -PathType Leaf)) { continue }
        $targetPak = Join-PathLexical (Join-PathLexical $InstallRoot $expansion.Folder) "pak0.pak"
        [void](Copy-QuakeOwnedFile -Source $sourcePak -Destination $targetPak)
        Set-QuakeExpansionLauncher -InstallRoot $InstallRoot -Label $expansion.Label -Arguments $expansion.Args
    }

    $musicSource = Join-PathLexical $SourceRoot "rerelease\id1\music"
    if (Test-Path -LiteralPath $musicSource -PathType Container) {
        $musicTarget = Join-PathLexical $InstallRoot "id1\sound\cdtracks"
        New-Item -ItemType Directory -Path $musicTarget -Force -ErrorAction Stop | Out-Null
        foreach ($track in (Get-ChildItem -LiteralPath $musicSource -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in @('.ogg','.mp3','.wav','.flac') })) {
            [void](Copy-QuakeOwnedFile -Source $track.FullName `
                -Destination (Join-PathLexical $musicTarget $track.Name.ToLowerInvariant()))
        }
    }
    return (Test-QuakeGameData -Root $InstallRoot)
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Quake PCVR  -  Team Beef's QuakeQuest, ported" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Everything QuakeQuest does on a Quest, on your PC at whatever" -ForegroundColor White
Write-Host "  resolution it can drive: stereo, roomscale, the weapon in hand," -ForegroundColor White
Write-Host "  the weapon wheel, haptics, snap and smooth turning." -ForegroundColor White
Write-Host ""
Write-Host "  All six games from Single Player without leaving the headset -" -ForegroundColor Gray
Write-Host "  Quake, both mission packs and all four official episodes." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU PROVIDE YOUR OWN QUAKE. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  No game data ships with this and none is downloaded. Setup" -ForegroundColor Gray
Write-Host "  copies it out of your own Steam or GOG install." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice

# ---- 1. Where does it go? ------------------------------------
Write-Step 1 4 "Choosing the folder"

# !!! IT DOES NOT GO INTO YOUR QUAKE FOLDER. The build is self-contained
# and keeps its config, saves and screenshots inside itself, so it gets
# a folder of its own - and Romeo's Quake VR keeps its own separately.
Write-Host "  This build lives in its own folder and never writes into your" -ForegroundColor White
Write-Host "  Quake install - Setup only reads from it." -ForegroundColor White
Write-Host ""
Write-Host "  Default: C:\Games\$FOLDER_NAME" -ForegroundColor White
Write-Host "  Press Enter to accept, or type a different root folder." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$rootDir = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $rootDir = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $rootDir) {
    foreach ($r in $DEFAULT_ROOTS) {
        if (Test-WritableRoot -Root $r) { $rootDir = [string]$r; break }
    }
}
if (-not $rootDir) {
    Write-Fail "No writable install root found."
    Pause-User "Press Enter to exit."
    exit 1
}
$installDir = Join-PathLexical $rootDir $FOLDER_NAME
Write-OK "Install folder: $installDir"

# ---- 2. Download ---------------------------------------------
Write-Step 2 4 "Getting the build"

$tmp = Join-PathLexical $env:TEMP ("QuakePCVR_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-PathLexical $tmp "quake-vr-pc.zip"

# Resolve the newest release rather than pinning a version - the author
# publishes through GitHub releases.
$dlUrl = $null; $relTag = $null
try {
    $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
                -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25
    foreach ($r in @($rels)) {
        if ($r.draft) { continue }
        $pick = Select-PayloadAsset -Assets $r.assets -PlatformPattern '(?i)quake.?vr.?pc' -MinBytes 500000
        if ($pick) { $dlUrl = [string]$pick.browser_download_url; $relTag = [string]$r.tag_name; break }
    }
} catch { Write-Warn "Could not read the releases list: $($_.Exception.Message)" }

if (-not $dlUrl) {
    Write-Warn "No release asset found automatically."
    Pause-User "Press Enter to open the releases page..."
    try { Start-Process $RELEASES_URL } catch {}
    Write-Do "Download 'quake-vr-pc.zip', then drag it in below."
    $manual = (Read-Host "  ZIP file").Trim().Trim('"')
    if (-not $manual -or -not (Test-Path -LiteralPath $manual -PathType Leaf)) {
        Write-Info "Nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
    Copy-Item -LiteralPath $manual -Destination $zip -Force
} else {
    Write-Info "Newest release: $relTag"
    $dl = Invoke-DownloadOrFallback -Url $dlUrl -Destination $zip -Label "$MOD_NAME $relTag" -ManualUrl $RELEASES_URL
    if (-not $dl) {
        Write-Fail "Could not download it."
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        exit 1
    }
}
Write-OK "Archive ready."

# ---- 3. Unpack -----------------------------------------------
Write-Step 3 4 "Unpacking"

$ex = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label "$MOD_NAME"
if ([string]$ex -eq "quit") {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive nests everything under quake-vr-pc\.
$probe = Get-ChildItem -LiteralPath $tmp -Filter $MOD_MARKER -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $probe) {
    Write-Fail "$MOD_MARKER was not in that archive - wrong download?"
    Write-Info "Expected quake-vr-pc.zip from $RELEASES_URL"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$srcRoot = Split-Path -Parent $probe.FullName

try {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Copy-Item -Path (Join-PathLexical $srcRoot "*") -Destination $installDir -Recurse -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not copy the build: $($_.Exception.Message)"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

$markerPath = Join-PathLexical $installDir $MOD_MARKER
if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Fail "$MOD_MARKER did not arrive in $installDir"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Build in place."

[void](Confirm-PlacedFilesSurvive -Paths @($markerPath) -GameDir $installDir -ArchivePath $zip)
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- 4. Licensed game data -----------------------------------
# Setup.bat used to be launched here. Its exit code was ignored, which
# produced a false [OK] when Python was missing and left id1 unplayable.
# The Hub now performs the essential copy itself. Python/Pillow are only
# optional author tooling for generated artwork and message strings.
Write-Step 4 4 "Preparing your Quake data"

$quakeSource = $null
if (-not (Test-QuakeGameData -Root $installDir)) {
    $quakeSource = Find-QuakeGameDataRoot
    if (-not $quakeSource) {
        Write-Warn "Quake was not found automatically."
        Write-Host "  Enter the Quake folder that contains id1, or press Enter to stop." -ForegroundColor Gray
        for ($attempt = 1; $attempt -le 3 -and -not $quakeSource; $attempt++) {
            $manualRoot = ("" + (Read-Host "  Quake folder")).Trim().Trim('"')
            if (-not $manualRoot) { break }
            $quakeSource = Find-QuakeGameDataRoot -PreferredRoots @($manualRoot)
            if (-not $quakeSource) { Write-Warn "That folder does not contain both pak0.pak and pak1.pak." }
        }
    }
    if ($quakeSource) {
        Write-OK "Quake found: $quakeSource"
        try {
            if (-not (Copy-QuakeOwnedData -SourceRoot $quakeSource -InstallRoot $installDir)) {
                throw "pak0.pak and pak1.pak did not arrive in id1"
            }
        } catch {
            Write-Fail "Could not prepare the Quake data: $($_.Exception.Message)"
        }
    }
}

if (-not (Test-QuakeGameData -Root $installDir)) {
    Write-Fail "The PCVR build is present, but it is not playable without your two base PAKs."
    Write-Host "  No installed marker was written. Run this installer again after Quake is installed." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive's Setup note describes the obsolete manual fallback. Once
# both PAKs have been verified, keeping it would only confuse the user.
$oldHint = Join-PathLexical $installDir "id1\IF SETUP COULD NOT FIND QUAKE.txt"
if (Test-Path -LiteralPath $oldHint -PathType Leaf) {
    Remove-Item -LiteralPath $oldHint -Force -ErrorAction SilentlyContinue
}

$readyPath = Join-PathLexical $installDir $READY_MARKER
Set-Content -LiteralPath $readyPath -Value "Quake base game data verified by PCVR Mods Hub." -Encoding ASCII -Force
Write-OK "Quake game data ready (pak0.pak + pak1.pak)."

# If Python already exists, retain the author's optional generated menu
# artwork/message text. Never claim the playable install failed without it.
if ($quakeSource) {
    $setupPy = Join-PathLexical $installDir "tools\setup.py"
    $python = Get-Command python.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $py = Get-Command py.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ((Test-Path -LiteralPath $setupPy -PathType Leaf) -and ($python -or $py)) {
        Write-Info "Generating optional menu artwork and episode text..."
        try {
            if ($python) { & $python.Source $setupPy $installDir $quakeSource }
            else { & $py.Source -3 $setupPy $installDir $quakeSource }
            if ($LASTEXITCODE -ne 0) { Write-Warn "Optional artwork generation did not finish; the game is still ready." }
        } catch { Write-Warn "Optional artwork generation was skipped; the game is still ready." }
    } else {
        Write-Info "Optional generated menu artwork skipped (Python/Pillow are not required to play)."
    }
}

try {
    # Records are deliberately written only after the playable marker.
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path") -Value $installDir -Encoding UTF8 -Force
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path_pcvr") -Value $installDir -Encoding UTF8 -Force
    if ($relTag) {
        Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_version_b") -Value $relTag -Encoding UTF8 -Force
        Set-Content -LiteralPath (Join-PathLexical $installDir ".pcvrhub_version_b") -Value $relTag -Encoding UTF8 -Force
    }
} catch {}

# ---- Done ----------------------------------------------------
Write-Host ""
Write-Host "  START VIRTUAL DESKTOP FIRST " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "  Connect it before launching so VDXR is the running OpenXR" -ForegroundColor White
Write-Host "  runtime. SteamVR and the Oculus runtime expose OpenXR too and" -ForegroundColor White
Write-Host "  should work, but the author has not tested them." -ForegroundColor White
Write-Host ""
Write-Host "  Then run " -NoNewline -ForegroundColor White
Write-Host "$LAUNCH_BAT" -NoNewline -ForegroundColor Cyan
Write-Host " in $installDir" -ForegroundColor White
Write-Host "  'Quake VR (flatscreen).bat' runs it in a window without a headset." -ForegroundColor Gray
Write-Host ""
Write-OK "$MOD_NAME installed."
Write-Host ""
Pause-User "Press Enter to exit"
