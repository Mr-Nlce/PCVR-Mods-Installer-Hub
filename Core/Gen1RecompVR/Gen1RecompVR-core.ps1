# ============================================================
# Pokemon Gen 1 VR - Installer
#   Gen1Recomp (bryanthaboi)          : the LOVE2D port
#   Dramatic Shape Voxel Mod (DramaticShape) : voxel diorama + VR
# ============================================================
# Two separate downloads, both from GitHub releases:
#   1) the port  -> <install root>\Pokemon Gen 1 VR\gen1recomp.exe
#   2) the mod   -> <user>\AppData\Roaming\pokemon-love2d\mods\DRAMATIC_SHAPE
#                    (resolved at runtime from $env:APPDATA, which IS the
#                     Roaming folder - Local and LocalLow are never used)
#
# WHY THE MOD LEAVES THE GAME FOLDER (the one exception in this Hub):
# the port's mod loader (src/mods/Loader.lua) scans "mods" through
# love.filesystem with no injected fs, so it only ever sees the LOVE
# save directory for identity "pokemon-love2d". A mods folder next to
# the exe is NOT on its read path, and portable.txt does not move it
# either (that marker only redirects save.lua / options.lua / the ROM
# cache through a separate io filesystem). The path is dictated by the
# mod platform, so the installer states it plainly and the README
# repeats it, uninstall included.
#
# VR is a row in the game's own OPTIONS menu (VR: OFF/ON), not a
# separate launch mode - PCVR through OpenXR on Windows.
#
# You supply your own canonical US Red / Blue / Yellow ROM; the port
# verifies its SHA-1 on first launch and builds a private cache. No
# ROM and no game data ship with either download.
#
# WINDOWS DEFENDER: the port is the official LOVE runtime with the
# game archive appended, unsigned - Defender's ML heuristic sometimes
# eats it (a documented false positive on the project's own README).
# Every extraction below is therefore VERIFIED a few seconds later,
# and if files went missing the installer walks the user through an
# exclusion instead of leaving a half-broken folder behind.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Pokemon Gen 1 VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Pokemon Gen 1 VR Installer" -ForegroundColor Cyan
    Write-Host " Gen1Recomp + Dramatic Shape Voxel Mod | your own .gb ROM" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path

$PORT_REPO    = "bryanthaboi/gen1recomp"
$MOD_REPO     = "DramaticShape/DramaticShapeVoxelMod"
$PORT_PAGE    = "https://github.com/$PORT_REPO/releases"
$MOD_PAGE     = "https://github.com/$MOD_REPO/releases"

# Known-good pair, verified together: the mod's manifest.json requires
# the port to be >=0.1.37 and <2.0.0, and this is the newest pair at
# the time of writing.
$PIN_PORT_TAG = "v0.1.60"
$PIN_MOD_TAG  = "v1.5.4"

$GAME_FOLDER  = "Pokemon Gen 1 VR"
$GAME_EXE     = "gen1recomp.exe"
$MOD_ID       = "DRAMATIC_SHAPE"
$LOVE_MODS    = Join-Path $env:APPDATA "pokemon-love2d\mods"
$DEFAULT_ROOTS= @("C:\Games", "D:\Games", "E:\Games")

# Files that must survive the extraction. If Defender ate one, the
# folder looks "installed" but the game will not start.
$PORT_MUST_HAVE = @("gen1recomp.exe", "love.dll", "lua51.dll", "SDL2.dll", "OpenAL32.dll")
$MOD_MUST_HAVE  = @("main.lua", "manifest.json", "assets\vr\openxr_loader.dll")

# ---- GitHub helpers -----------------------------------------
# Resolve a release (latest or a fixed tag) to a download URL.
# Returns @{ Url=...; Tag=... } or $null - callers fall back to the
# browser + drag & drop route, never to a guessed filename.
function Get-GithubAsset {
    param([string]$Repo, [string]$Tag, [string]$NamePattern)
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $api = if ($Tag) { "https://api.github.com/repos/$Repo/releases/tags/$Tag" }
               else      { "https://api.github.com/repos/$Repo/releases/latest" }
        $rel = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
        if ($zips.Count -eq 0) { return $null }
        $pick = $zips | Where-Object { $_.name -match $NamePattern } | Select-Object -First 1
        if (-not $pick) { $pick = $zips[0] }
        return @{ Url = [string]$pick.browser_download_url; Tag = [string]$rel.tag_name; Name = [string]$pick.name }
    } catch { return $null }
}

# ---- checksum verification ----------------------------------
# Both projects publish a sha256sums.txt ALONGSIDE the release assets,
# so the Hub can do the verification the user cannot do when the Hub
# downloads for them. Returns:
#   "ok"       hash found in the published list
#   "mismatch" list fetched, our file is NOT in it
#   "unknown"  list not reachable (offline, or a release without it)
# A mismatch is treated as a failed download, not as a scare message:
# the archive is discarded and fetched again.
function Test-ReleaseChecksum {
    param([string]$Repo, [string]$Tag, [string]$File)
    if (-not (Test-Path -LiteralPath $File)) { return "unknown" }
    $urls = @()
    if ($Tag) { $urls += "https://github.com/$Repo/releases/download/$Tag/sha256sums.txt" }
    $urls += "https://github.com/$Repo/releases/latest/download/sha256sums.txt"
    $list = $null
    foreach ($u in $urls) {
        try {
            $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
            if ($r -and $r.Content) {
                # GitHub serves sha256sums.txt as application/octet-stream, so
                # .Content comes back as a BYTE ARRAY, not a string. Casting it
                # with [string] yields "98 55 99 ..." and every hash lookup
                # silently fails - verified in a real run against the live file.
                if ($r.Content -is [byte[]]) { $list = [System.Text.Encoding]::UTF8.GetString($r.Content) }
                else { $list = [string]$r.Content }
                if ($list) { break }
            }
        } catch { }
    }
    if (-not $list) { return "unknown" }
    try { $mine = (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLower() } catch { return "unknown" }
    # Match on the HASH, not on the file name: that also covers an archive
    # the user downloaded by hand under a different name.
    $known = @()
    foreach ($line in ($list -split "`r?`n")) {
        $m = [regex]::Match($line, '^\s*([0-9a-fA-F]{64})\s')
        if ($m.Success) { $known += $m.Groups[1].Value.ToLower() }
    }
    if ($known.Count -eq 0) { return "unknown" }
    if ($known -contains $mine) { return "ok" }
    return "mismatch"
}

# ---- Defender guard -----------------------------------------
# Defender removes files ASYNCHRONOUSLY, so a check straight after
# Expand-Archive can still see a complete folder. Poll for a few
# seconds and report what is actually missing.
function Test-FilesSurvived {
    param([string]$Root, [string[]]$Relative, [int]$Seconds = 4)
    $deadline = (Get-Date).AddSeconds($Seconds)
    $missing = @()
    do {
        $missing = @()
        foreach ($rel in $Relative) {
            if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $rel)))) { $missing += $rel }
        }
        if ($missing.Count -gt 0) { break }
        Start-Sleep -Milliseconds 700
    } while ((Get-Date) -lt $deadline)
    return ,$missing
}

# Explain the false positive, open the exclusion UI, wait for Enter.
# windowsdefender://exclusions is not documented everywhere, so the
# Windows Security home page is tried as well and the click path is
# printed either way.
function Invoke-DefenderExclusion {
    param([string]$FolderToExclude, [string]$Reason)
    Write-Host ""
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |   WINDOWS DEFENDER REMOVED FILES - KNOWN FALSE POSITIVE  |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  $Reason" -ForegroundColor Gray
    Write-Host "  Gen1Recomp is the official LOVE game runtime with the game" -ForegroundColor Gray
    Write-Host "  archive appended - the normal way LOVE games ship. Defender's" -ForegroundColor Gray
    Write-Host "  heuristic distrusts unsigned exe files built that way. The" -ForegroundColor Gray
    Write-Host "  project documents this and publishes SHA-256 checksums." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Add this folder as an exclusion:" -ForegroundColor White
    Write-Host "   $FolderToExclude " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "  In the window that opens:" -ForegroundColor Gray
    Write-Host "    Virus & threat protection -> Manage settings ->" -ForegroundColor Gray
    Write-Host "    Exclusions: Add or remove exclusions -> Add an exclusion" -ForegroundColor Gray
    Write-Host "    -> Folder -> paste the path above" -ForegroundColor Gray
    $opened = $false
    try { Start-Process "windowsdefender://exclusions" -ErrorAction Stop; $opened = $true } catch { }
    if (-not $opened) {
        try { Start-Process "windowsdefender:" -ErrorAction Stop; $opened = $true } catch { }
    }
    if (-not $opened) {
        Write-Warn "Could not open Windows Security automatically."
        Write-Host "    Open it from the Start menu: search for 'Windows Security'." -ForegroundColor Gray
    }
    Pause-User "Press Enter once the exclusion is added..." | Out-Null
}

# ---- download + extract with the Defender guard --------------
# Returns $true when everything asked for is on disk afterwards.
function Install-Package {
    param(
        [string]$Label,
        [string[]]$Urls,
        [string]$PageUrl,
        [string]$ZipPath,
        [string]$TargetDir,
        [string[]]$MustHave,
        [string]$FlattenMarker,
        [string]$Repo,
        [string]$Tag
    )
    $dlDir = Split-Path $ZipPath -Parent

    for ($attempt = 1; $attempt -le 3; $attempt++) {

        if (-not (Test-Path -LiteralPath $ZipPath)) {
            Invoke-SafeDownload -Urls $Urls -Destination $ZipPath -Label $Label `
                -ManualUrl $PageUrl `
                -Instructions "Download the $Label archive from the releases page, save it as '$ZipPath', then choose Retry." `
                -SkipMessage "" | Out-Null
        }

        # The ZIP itself can vanish between download and extraction.
        if (-not (Test-Path -LiteralPath $ZipPath)) {
            Write-Fail "The downloaded archive is gone: $ZipPath"
            Invoke-DefenderExclusion -FolderToExclude $dlDir `
                -Reason "The archive disappeared right after downloading, which is what a Defender removal looks like."
            continue
        }

        # Verify against the checksums the project publishes with the
        # release, BEFORE anything is unpacked into the target folder.
        if ($Repo) {
            $sum = Test-ReleaseChecksum -Repo $Repo -Tag $Tag -File $ZipPath
            if ($sum -eq "ok") {
                Write-OK "SHA-256 matches the published checksum."
            } elseif ($sum -eq "mismatch") {
                Write-Fail "SHA-256 does NOT match the published checksums - the download is damaged or incomplete."
                try { Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue } catch {}
                Write-Info "Discarded the file, downloading again ..."
                continue
            } else {
                Write-Info "No checksum list reachable for this release - skipping the hash check."
            }
        }

        Write-Info "Unpacking $Label ..."
        try {
            if (Test-Path -LiteralPath $TargetDir) { Remove-Item -LiteralPath $TargetDir -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $TargetDir -Force -ErrorAction Stop | Out-Null
            Expand-Archive -LiteralPath $ZipPath -DestinationPath $TargetDir -Force -ErrorAction Stop
        } catch {
            Write-Fail "Unpacking failed: $($_.Exception.Message)"
            return $false
        }

        # Flatten a single wrapper folder (the port ships gen1recomp-win64\).
        if ($FlattenMarker) {
            $inner = Get-ChildItem -LiteralPath $TargetDir -Directory -ErrorAction SilentlyContinue
            $files = Get-ChildItem -LiteralPath $TargetDir -File -ErrorAction SilentlyContinue
            if ($inner.Count -eq 1 -and $files.Count -eq 0) {
                Write-Info "Flattening wrapper folder '$($inner[0].Name)' ..."
                Get-ChildItem -LiteralPath $inner[0].FullName -Force | ForEach-Object {
                    Move-Item -LiteralPath $_.FullName -Destination $TargetDir -Force
                }
                Remove-Item -LiteralPath $inner[0].FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        $missing = Test-FilesSurvived -Root $TargetDir -Relative $MustHave
        if ($missing.Count -eq 0) {
            Write-OK "$Label is complete on disk."
            return $true
        }

        Write-Fail "Files are missing after unpacking:"
        foreach ($m in $missing) { Write-Host "        $m" -ForegroundColor Red }
        Invoke-DefenderExclusion -FolderToExclude $TargetDir `
            -Reason "Everything unpacked, but some files were gone seconds later."
        Write-Info "Trying again ..."
    }

    Write-Fail "$Label could not be installed completely after three attempts."
    return $false
}

# =============================================================
Write-Header
Write-Host "  Gen 1 Pokemon as a voxel diorama you can lean over - and, with" -ForegroundColor Gray
Write-Host "  the VR row switched on, in a PCVR headset through OpenXR." -ForegroundColor Gray
Write-Host "  Two parts are installed: the Gen1Recomp port (a native LOVE2D" -ForegroundColor Gray
Write-Host "  recreation) and the Dramatic Shape Voxel Mod on top of it." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU PROVIDE THE GAME:" -ForegroundColor White
Write-Host "    a canonical US Red, Blue or Yellow .gb / .gbc ROM you own." -ForegroundColor Yellow
Write-Host "  The port checks its SHA-1 on first launch, builds its own data" -ForegroundColor Gray
Write-Host "  and never copies the ROM. Nothing from Nintendo is downloaded." -ForegroundColor Gray
Pause-User "Press Enter to start the installation..." | Out-Null

# ---- 1. version choice --------------------------------------
Write-Step 1 5 "Choosing which versions to install"

Write-Host "  The port and the mod move fast and must match: the mod needs" -ForegroundColor Gray
Write-Host "  the port to be 0.1.37 or newer." -ForegroundColor Gray
Write-Host ""
Write-Host "    [1] Newest release of both  (auto-update, recommended)" -ForegroundColor White
Write-Host "    [2] Pinned pair             (port $PIN_PORT_TAG + mod $PIN_MOD_TAG, verified together)" -ForegroundColor White
Write-Host ""
$verChoice = ""
while ($verChoice -ne "1" -and $verChoice -ne "2") {
    $verChoice = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
    if ($verChoice -eq "") { $verChoice = "1" }
    if ($verChoice -ne "1" -and $verChoice -ne "2") { Write-Warn "Please type 1 or 2." }
}
$portTag = $null; $modTag = $null
if ($verChoice -eq "2") { $portTag = $PIN_PORT_TAG; $modTag = $PIN_MOD_TAG; Write-Info "Pinned pair selected." }
else { Write-Info "Newest releases selected." }

# ---- 2. install location ------------------------------------
Write-Step 2 5 "Choosing an install location"

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

Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  C:\Games needs no admin rights, so there's no Windows UAC prompt." -ForegroundColor Gray
Write-Host "  Press Enter to accept it, or type a different folder" -ForegroundColor Gray
Write-Host "  (the '$GAME_FOLDER' folder is created inside whatever you choose)." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break } }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
$gameRoot = Join-Path $installRoot $GAME_FOLDER
Write-OK "Install root: $installRoot"

$tmp = Join-Path $installRoot "_hub_gen1_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null; exit 1
}

# ---- 3. the port --------------------------------------------
Write-Step 3 5 "Installing the Gen1Recomp port"

$portUrls = New-Object System.Collections.Generic.List[string]
$portRel = Get-GithubAsset -Repo $PORT_REPO -Tag $portTag -NamePattern '(?i)win'
if ($portRel) {
    Write-OK "Port release: $($portRel.Tag)  ($($portRel.Name))"
    [void]$portUrls.Add($portRel.Url)
    $portTag = $portRel.Tag
} else {
    Write-Warn "GitHub API not reachable - you will be pointed at the releases page."
}
$portZip = Join-Path $tmp "gen1recomp_windows.zip"
$portOk = Install-Package -Label "Gen1Recomp (Windows)" -Urls $portUrls -PageUrl $PORT_PAGE `
            -ZipPath $portZip -TargetDir $gameRoot -MustHave $PORT_MUST_HAVE -FlattenMarker $GAME_EXE `
            -Repo $PORT_REPO -Tag $portTag
if (-not $portOk) {
    Write-Host "  Get it manually from:" -ForegroundColor Gray
    Write-Host "  $PORT_PAGE" -ForegroundColor Cyan
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}

# ---- 4. the voxel mod ---------------------------------------
Write-Step 4 5 "Installing the Dramatic Shape Voxel Mod"

Write-Host "  The port's mod loader only reads mods from your Windows user" -ForegroundColor Gray
Write-Host "  profile, so the mod goes here - not into the game folder:" -ForegroundColor Gray
Write-Host "   $LOVE_MODS\$MOD_ID " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  That path is fixed by the mod platform, not by this installer." -ForegroundColor Gray
Write-Host ""

$modUrls = New-Object System.Collections.Generic.List[string]
$modRel = Get-GithubAsset -Repo $MOD_REPO -Tag $modTag -NamePattern '(?i)(dramatic|shape)'
if ($modRel) {
    Write-OK "Mod release: $($modRel.Tag)  ($($modRel.Name))"
    [void]$modUrls.Add($modRel.Url)
    $modTag = $modRel.Tag
} else {
    Write-Warn "GitHub API not reachable - you will be pointed at the releases page."
}
$modZip = Join-Path $tmp "dramatic_shape_mod.zip"
$modDir = Join-Path $LOVE_MODS $MOD_ID
try { New-Item -ItemType Directory -Path $LOVE_MODS -Force -ErrorAction Stop | Out-Null } catch {}
$modOk = Install-Package -Label "Dramatic Shape Voxel Mod" -Urls $modUrls -PageUrl $MOD_PAGE `
           -ZipPath $modZip -TargetDir $modDir -MustHave $MOD_MUST_HAVE -FlattenMarker "manifest.json" `
           -Repo $MOD_REPO -Tag $modTag
if (-not $modOk) {
    Write-Host "  Get it manually from:" -ForegroundColor Gray
    Write-Host "  $MOD_PAGE" -ForegroundColor Cyan
    Write-Warn "The port is installed and playable flat, but without the mod there is no VR."
}
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- 5. shortcut + markers ----------------------------------
Write-Step 5 5 "Finishing up"

$exePath = Join-Path $gameRoot $GAME_EXE
$lnk = New-DesktopShortcut -TargetPath $exePath -ShortcutName "Pokemon Gen 1 VR" `
         -WorkingDir $gameRoot -IconPath $exePath `
         -Description "Gen1Recomp with the Dramatic Shape Voxel Mod (VR)"
if ($lnk) { Write-OK "Desktop shortcut created: Pokemon Gen 1 VR" }
else      { Write-Warn "Could not create the desktop shortcut - use 'Start in VR' in the Hub." }

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exePath -Encoding UTF8 -Force } catch {}
try { if ($modTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $modTag -Encoding UTF8 -Force } } catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Pokemon Gen 1 VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |            TURN VR ON INSIDE THE GAME                |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Launcher window, gear icon at the top: " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     Colors: SGB -> ADVANCED        Max FPS: 120" -ForegroundColor White
Write-Host ""
Write-Host "   In-game OPTIONS menu (press down a few times): " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     VOXEL -> on        VR -> ON   (start SteamVR first)" -ForegroundColor White
Write-Host ""
Write-Host "  On the very first start the game asks for your Red, Blue or" -ForegroundColor Gray
Write-Host "  Yellow ROM and builds its data - that takes a few seconds." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with 'Start in VR' in the Hub, or use the new" -ForegroundColor Gray
Write-Host "    'Pokemon Gen 1 VR' desktop shortcut." -ForegroundColor Gray
Write-Host ""
Write-Host "  The mod lives outside the game folder, at:" -ForegroundColor Gray
Write-Host "    $modDir" -ForegroundColor Cyan
Write-Host "  Delete that folder to remove it. See the README for the" -ForegroundColor DarkGray
Write-Host "  VR controls and the options rows." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  That Snorlax is blocking the road at full size now. Still no flute." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
