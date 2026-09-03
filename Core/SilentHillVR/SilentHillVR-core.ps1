# =============================================================
#  Silent Hill (1999) VR - installer
# =============================================================
# WHAT THIS IS. Not a mod that patches an installed game: it is a
# complete rebuilt PC port with native stereo compiled in. You get a
# folder holding SilentHillPC.exe, openvr_api.dll and the map DLLs, and
# it runs on its own.
#
# WHAT YOU MUST BRING. Your own legally obtained "Silent Hill (USA).bin"
# disc image. The archive contains no game data and neither does this
# installer - it only puts the build in place and shows you where the
# .bin has to go.
#
# WHY THE ARCHIVE IS NOT DOWNLOADED. It sits behind a MediaFire link on
# the author's Patreon post. We link the post, not the file: the file
# address changes and the author should get the visit. The installer
# takes the .rar from your Downloads folder or by drag and drop.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME     = "Silent Hill VR"
$MOD_VERSION  = "v1.0"
$MOD_AUTHOR   = "VRified Games"
$GAME_FOLDER  = "Silent Hill VR"
$MOD_EXE_REL  = "pc_port\build\SilentHillPC.exe"
$GAMEDATA_REL = "pc_port\build\gamedata"
$BIN_NAME     = "Silent Hill (USA).bin"
$POST_URL     = "https://www.patreon.com/u61517070/posts/silent-hill-1999-167912751"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games", (Join-Path $env:USERPROFILE "Games"))

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
# A step header has to READ as a break. In plain cyan it looked like
# every other line on a page that is mostly white and grey, so the
# reader had nothing to hold on to. Black on cyan makes the start of a
# section unmistakable without adding a single line of height.
function Write-Step {
    param($n,$t,$x)
    Write-Host ""
    Write-Host "  [$n/$t] $x  " -ForegroundColor Black -BackgroundColor Cyan
    Write-Host ""
}
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-WritableRoot {
    param([string]$Root)
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Get-DroppedFile {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Warn "File not found: $p"; continue }
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected: $($Exts -join ', ')."
            continue
        }
        return $p
    }
}

function Copy-SilentHillBuild {
    param([string]$Source, [string]$Destination)
    $sourceRoot = [IO.Path]::GetFullPath($Source).TrimEnd('\') + '\'
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse -Force) {
        $relative = $file.FullName.Substring($sourceRoot.Length)
        if ($relative -match '(^|\\)(?:CMakeFiles|\.git)(\\|$)|(^|\\)(?:\.ninja_.*|CMakeCache\.txt|build\.ninja|cmake_install\.cmake|run_capture\.bat)$|\.(?:obj|o|a|h|cmake)$') { continue }
        $target = Join-Path $Destination $relative
        if ((Test-Path -LiteralPath $target) -and ($relative -eq 'config.cfg' -or $relative -match '^(?:gamedata|saves?)\\')) { continue }
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
    }
}

# ---- Header --------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Silent Hill (1999) VR  -  $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Native stereoscopic VR inside the Silent Hill PC port - the" -ForegroundColor White
Write-Host "  stereo image is generated in the renderer from the game's own" -ForegroundColor White
Write-Host "  geometry, with 6DOF head tracking and roomscale movement." -ForegroundColor White
Write-Host ""
Write-Host "  What you need:" -ForegroundColor White
Write-Host "   - SteamVR and a PC VR headset (wireless is fine: Virtual" -ForegroundColor Gray
Write-Host "     Desktop, Air Link, Link, Steam Link)" -ForegroundColor Gray
Write-Host "   - a gamepad - this release is gamepad only" -ForegroundColor Gray
Write-Host "   - YOUR OWN '$BIN_NAME' disc image" -ForegroundColor Gray
Show-AntivirusNotice

# ---- 1. Where does it go? -----------------------------------
Write-Step 1 4 "Choosing the install folder"

Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  Press Enter to accept it, or type a different root folder." -ForegroundColor Gray
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
$installRoot = Join-Path $rootDir $GAME_FOLDER
Write-OK "Install folder: $installRoot"

# ---- 2. The archive ------------------------------------------
Write-Step 2 4 "Getting the VR build"

# The post carries a MediaFire link. We open the POST - the author's own
# page - and never the file address behind it.
Write-Host "  The download sits on the author's Patreon post. The link at the" -ForegroundColor White
Write-Host "  very top of that post is " -NoNewline -ForegroundColor White
Write-Host "silent-hill-v1.0" -NoNewline -ForegroundColor Cyan
Write-Host " - click that one." -ForegroundColor White
Write-Host ""
Write-Host "  It is free. No Patreon membership is needed for v1.0." -ForegroundColor Gray
Write-Host ""

# !!! WITHOUT AN EXPECTATION THE HELPER DOES NOT EVEN LOOK. It returns
# null unless it is told a name, a size, a hash or -AllowUnverified, so
# the patterns alone found nothing and drag-and-drop was the only way in.
#
# !!! EXACT SIZE, NO TOLERANCE. I first allowed five percent, which on
# a 152 MB file is a 15 MB window - and anyone who has been through a
# couple of update cycles has an OLDER build of this very mod sitting in
# Downloads, most likely inside that window. Offering it would install
# the wrong version over a working setup.
#
# Exact is right here because the version is pinned: v1.0 is 159,834,056
# bytes, read from the real archive. If the author ever repacks it, the
# match fails and the installer asks you to drag the file in - slower,
# and correct. A wrong archive accepted silently is the expensive
# outcome; one extra drag is not.
#
# The patterns stay loose on purpose: browsers save this as
# silent-hill-v1.0.rar or silent-hill-v1_0.rar depending on where it
# came from, and both are the same download.
$rar = Find-PredownloadedFile -Patterns @("silent-hill-v1*.rar", "silent-hill*V1*.rar", "silent-hill*.rar") `
        -ExpectedSize 159834056 `
        -Label "the Silent Hill VR archive"
if (-not $rar) {
    Pause-User "Press Enter to open the download page..."
    try { Start-Process $POST_URL } catch { Write-Warn "Open manually: $POST_URL" }
    Write-Host ""
    Write-Do "Download the archive, then drag it in below."
    $rar = Get-DroppedFile -Label "silent-hill-v1.0.rar" -Exts @(".rar", ".zip")
}
if (-not $rar) {
    Write-Info "Nothing was changed."
    Pause-User "Press Enter to exit."
    exit 0
}
Write-OK "Archive: $rar"

# ---- 3. Unpack ------------------------------------------------
Write-Step 3 4 "Unpacking"

# !!! THE ARCHIVE CARRIES FAR MORE THAN THE GAME. It ships the author's
# whole source tree - a .git history, CMake caches, ninja logs and object
# files, 4159 entries in total for 299 MB unpacked. Only pc_port\build
# is needed to play. Everything is extracted first (the archive nests
# silent-hill-v1.0\silent-hill-V1.0\...), then the build folder is
# lifted out and the rest discarded.
$tmp = Join-Path $env:TEMP ("SilentHillVR_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$ex = Expand-ArchiveOrFallback -ArchivePath $rar -DestinationFolder $tmp -Label "$MOD_NAME $MOD_VERSION"
if ([string]$ex -notin @('ok','manual')) {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# Find the build folder wherever the nesting put it.
$buildSrc = $null
$probe = Get-ChildItem -LiteralPath $tmp -Filter "SilentHillPC.exe" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($probe) { $buildSrc = Split-Path -Parent $probe.FullName }
if (-not $buildSrc) {
    Write-Fail "SilentHillPC.exe was not in that archive - is it the right one?"
    Write-Info "Expected the v1.0 release from the Patreon post."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Found the build."

$destBuild = Join-Path $installRoot "pc_port\build"
try {
    New-Item -ItemType Directory -Path $destBuild -Force | Out-Null
    Copy-SilentHillBuild -Source $buildSrc -Destination $destBuild
} catch {
    Write-Fail "Could not copy the build: $($_.Exception.Message)"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

$modExe   = Join-Path $installRoot $MOD_EXE_REL
$gameData = Join-Path $installRoot $GAMEDATA_REL
if (-not (Test-Path -LiteralPath $destBuild -PathType Container)) {
    Write-Fail "The executable did not arrive at $modExe"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
try { New-Item -ItemType Directory -Path $gameData -Force | Out-Null } catch {}
Write-OK "Build in place."

# The scanner usually sweeps a moment after the write, and openvr_api.dll
# next to an unsigned executable is the shape scanners react to.
$runtimeFiles = @('SilentHillPC.exe','openvr_api.dll','SDL2.dll','libgcc_s_seh-1.dll','libjpeg-8.dll','libopenal-1.dll','libstdc++-6.dll','libwinpthread-1.dll')
$runtimePaths = @($runtimeFiles | ForEach-Object { Join-Path $destBuild $_ })
if (-not (Confirm-PlacedFilesSurvive `
    -Paths $runtimePaths `
    -GameDir $installRoot `
    -ArchivePath $rar)) { throw 'Silent Hill runtime files are missing after recovery; installation was not completed.' }

Write-ModStamp -GameDir $installRoot -Version $MOD_VERSION
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}
if (Test-IsTrackableInstalledVersion -Version $MOD_VERSION) {
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $MOD_VERSION -Encoding UTF8 -Force } catch {}
    Save-InstalledStamp -GameDir $installRoot -Version $MOD_VERSION
}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- 4. Your disc image --------------------------------------
Write-Step 4 4 "Your own game data"

Write-Host "  One file is missing, and only you can supply it:" -ForegroundColor White
Write-Host ""
Write-Host "    $BIN_NAME" -ForegroundColor Yellow
Write-Host ""
Write-Host "  It has to sit in the gamedata folder:" -ForegroundColor White
Write-Host "    $gameData" -ForegroundColor Cyan
Write-Host ""
Write-Host "  If your Silent Hill PC port already runs, you have this file" -ForegroundColor Gray
Write-Host "  already - copy it over." -ForegroundColor Gray
Write-Host ""

$binPath = Join-Path $gameData $BIN_NAME
Pause-User "Press Enter to open the gamedata folder..."
try { Start-Process -FilePath explorer.exe -ArgumentList ('"' + $gameData + '"') } catch {}
Pause-User "Press Enter once the .bin is in there (or to carry on without it)..."

if (Test-Path -LiteralPath $binPath) {
    Write-OK "$BIN_NAME found."
} else {
    $anyBin = @(Get-ChildItem -LiteralPath $gameData -Filter "*.bin" -File -ErrorAction SilentlyContinue)
    if ($anyBin.Count -eq 1) {
        # !!! RENAME IT RATHER THAN ASK. Telling someone to rename a file
        # to an exact string with a space and brackets in it is asking
        # for a second wrong name - and the build simply will not start,
        # with nothing on screen to say why. Exactly one .bin is
        # unambiguous: it can only be the disc image, so it is renamed
        # and the user is told what happened.
        $wrong = $anyBin[0]
        Write-Warn "The disc image is called '$($wrong.Name)', not '$BIN_NAME'."
        try {
            Rename-Item -LiteralPath $wrong.FullName -NewName $BIN_NAME -ErrorAction Stop
            Write-OK "Renamed to '$BIN_NAME' - the build looks for that exact name."
        } catch {
            Write-Fail "Could not rename it: $($_.Exception.Message)"
            Write-Do "Rename it to exactly '$BIN_NAME' yourself, or the build will not find it."
        }
    } elseif ($anyBin.Count -gt 1) {
        # More than one, so guessing which is the game would be a
        # coin toss - and renaming the wrong one leaves two files that
        # both look right.
        Write-Warn "There are $($anyBin.Count) .bin files in there:"
        foreach ($b in ($anyBin | Select-Object -First 5)) { Write-Host "     $($b.Name)" -ForegroundColor Gray }
        Write-Do "Leave only your Silent Hill disc image and name it '$BIN_NAME'."
    } else {
        Write-Warn "No .bin in the gamedata folder yet - the game will not start without it."
        Write-Do "Put it there before launching."
    }
}

# ---- Shortcut ------------------------------------------------
$iconSrc = Join-Path $PSScriptRoot "SilentHill_VR.ico"
try {
    $lnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Silent Hill VR.lnk"
    $icon = if (Test-Path -LiteralPath $iconSrc) { $iconSrc } else { $modExe }
    [void](New-DesktopShortcut -LnkPath $lnk -TargetPath $modExe -WorkingDir (Split-Path -Parent $modExe) -IconPath $icon -Description "Silent Hill (1999) in VR")
    Write-OK "Desktop shortcut created."
} catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }

# ---- Getting into VR -----------------------------------------
Write-Host ""
Write-Host "  GETTING INTO VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "   1. Start SteamVR and check your headset is tracking." -ForegroundColor White
Write-Host "   2. Launch the game. A virtual screen appears." -ForegroundColor White
Write-Host "   3. Press " -NoNewline -ForegroundColor White
Write-Host "Numpad Enter" -NoNewline -ForegroundColor Cyan
Write-Host " to cycle: OFF / 3D SCREEN / FULL." -ForegroundColor White
Write-Host "   4. Choose FULL, then recenter in your play space." -ForegroundColor White
Write-Host "   5. Adjust depth with " -NoNewline -ForegroundColor White
Write-Host "Numpad + / -" -NoNewline -ForegroundColor Cyan
Write-Host " if you need to." -ForegroundColor White
Write-Host ""
Write-Host "  THE WORLD LOOKS TOO SMALL? " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Several testers reported a dollhouse scale. The author's fix:" -ForegroundColor White
Write-Host "  Options > PC Options > last page > VR convergence 1.0, VR depth 0.3" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Careful with the PC port's own debug controls: its freecam uses" -ForegroundColor Gray
Write-Host "  the numpad too and will fight these hotkeys. Leave them off." -ForegroundColor Gray
Write-Host ""
Write-Host "  Gamepad only for now - motion controllers track your position" -ForegroundColor Gray
Write-Host "  but aiming and interaction are on the pad." -ForegroundColor Gray

Write-Host ""
Write-OK "$MOD_NAME $MOD_VERSION installed."
Write-Host ""
Write-Host "  Take a radio. And whatever you do, don't look too closely at the walls." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
