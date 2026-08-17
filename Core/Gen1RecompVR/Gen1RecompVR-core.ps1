# ============================================================
# Pokemon Gen 1 VR - Installer
#   Gen1Recomp (bryanthaboi)          : the LOVE2D port
#   Dramatic Shape Voxel Mod (DramaticShape) : voxel diorama + VR
# ============================================================
# Two separate downloads, both from GitHub releases:
#   1) the port  -> <install root>\Pokemon Gen 1 VR\gen1recomp.exe
#   2) the mod   -> <user>\AppData\Roaming\pokemon-love2d\mods\DRAMALESS_SHAPE
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
# Der Fork ist die lebende Quelle: DramaticShape/DramaticShapeVoxelMod
# liefert 404 (Repo UND Konto weg). DRAMALESS_SHAPE ist der Fork davon,
# eigene Mod-ID, deshalb aendert sich auch der Zielordner unten.
$MOD_REPO     = "artyrambles/DRAMALESS_SHAPE"
$PORT_PAGE    = "https://github.com/$PORT_REPO/releases"
$MOD_PAGE     = "https://github.com/$MOD_REPO/releases"

# Known-good pair, verified together: the mod's manifest.json requires
# the port to be >=0.1.37 and <2.0.0, and this is the newest pair at
# the time of writing.
# Port auf v0.1.81 gezogen (2026-08-13). BEIDE Mods verlangen laut ihrer
# manifest.json ">=0.1.37 <2.0.0" - 0.1.81 liegt sicher darin. Der Port
# bleibt gepinnt, damit er nicht eines Tages auf 2.x springt und die Mods
# aussperrt.
$PIN_PORT_TAG = "v0.1.81"
$PIN_MOD_TAG  = "v1.6.4"

$GAME_FOLDER  = "Pokemon Gen 1 VR"
$GAME_EXE     = "gen1recomp.exe"
# Aus der manifest.json des echten Archivs: "id": "DRAMALESS_SHAPE".
# Die Mod-Plattform legt danach den Ordner an, der Name ist also nicht frei.
# ZWEI MODS ZUR AUSWAHL, beide mit VR. Welche es wird, entscheidet der
# Nutzer in Schritt 1; $MOD_ID, $OTHER_MOD_ID und die Adressen werden
# danach gesetzt. Beide landen im GLEICHEN Ordner mods\, aber unter
# IHRER EIGENEN Kennung aus der manifest.json - deshalb kann immer nur
# eine aktiv sein, und die andere muss ganz aus mods\ heraus.
#
# ORIGINAL: DRAMATIC_SHAPE 1.8.2 von scottcandy34 gespiegelt. Die volle
# Mod mit allem, was Dramaless spaeter herausgeworfen hat - unter anderem
# der eingebaute First-Person-Modus. 310 Dateien, 19,7 MB entpackt.
# KEIN AUTO-UPDATE: fest auf v1.8.2, weil es eine SPIEGELUNG ist und
# jederzeit verschwinden kann.
$DRAMATIC_ID   = "DRAMATIC_SHAPE"
$DRAMATIC_TAG  = "v1.8.2"
$DRAMATIC_URL  = "https://github.com/scottcandy34/DramaticShapeVoxelMod-latest/releases/download/v1.8.2/DRAMATIC_SHAPE-1.8.2.zip"
$DRAMATIC_PAGE = "https://github.com/scottcandy34/DramaticShapeVoxelMod-latest/releases"
# FORK: DRAMALESS_SHAPE 1.6.4, die letzte Fassung MIT VR. Schlanker,
# aber ohne die Funktionen, die 2.0.0 endgueltig entfernt hat.
$DRAMALESS_ID  = "DRAMALESS_SHAPE"
$MOD_ID       = $DRAMALESS_ID
# Die jeweils ANDERE Mod - wird in Schritt 1 gesetzt. Laut manifest.json
# stehen die beiden gegenseitig in "conflicts": liegen beide in mods\,
# laedt keiner richtig.
$OLD_MOD_ID   = $DRAMATIC_ID
$LOVE_MODS    = Join-Path $env:APPDATA "pokemon-love2d\mods"
# Ablage fuer abgeloeste Mods, NEBEN mods\ - nicht darin. Der Mod-Loader
# liest jeden Unterordner von mods\ und richtet sich nach der manifest.json
# darin, nicht nach dem Ordnernamen: eine Umbenennung in .disabled genuegt
# also NICHT, die alte Mod wird weiter geladen und meldet den Konflikt.
$LOVE_MODS_OFF = Join-Path $env:APPDATA "pokemon-love2d\mods-disabled"
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
        $unpackDir = Join-Path ([IO.Path]::GetTempPath()) ("PCVRHub_Gen1_" + [Guid]::NewGuid().ToString("N"))
        try {
            New-Item -ItemType Directory -Path $unpackDir -Force -ErrorAction Stop | Out-Null
            Expand-Archive -LiteralPath $ZipPath -DestinationPath $unpackDir -Force -ErrorAction Stop
        } catch {
            Write-Fail "Unpacking failed: $($_.Exception.Message)"
            try { Remove-Item -LiteralPath $unpackDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            return $false
        }

        # Flatten a single wrapper folder (the port ships gen1recomp-win64\).
        if ($FlattenMarker) {
            $inner = Get-ChildItem -LiteralPath $unpackDir -Directory -ErrorAction SilentlyContinue
            $files = Get-ChildItem -LiteralPath $unpackDir -File -ErrorAction SilentlyContinue
            if ($inner.Count -eq 1 -and $files.Count -eq 0) {
                Write-Info "Flattening wrapper folder '$($inner[0].Name)' ..."
                Get-ChildItem -LiteralPath $inner[0].FullName -Force | ForEach-Object {
                    Move-Item -LiteralPath $_.FullName -Destination $unpackDir -Force
                }
                Remove-Item -LiteralPath $inner[0].FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        try {
            $null = Merge-DirectoryTreeVerified -Source $unpackDir -Destination $TargetDir -Label $Label
        } catch {
            Write-Fail "Could not merge $Label into the existing installation: $($_.Exception.Message)"
            try { Remove-Item -LiteralPath $unpackDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            return $false
        }
        try { Remove-Item -LiteralPath $unpackDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

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

# !!! DIE REIHENFOLGE IST SEIT DRAMALESS 2.0.0 UMGEDREHT !!!
# In 2.0.0 hat der Autor die VR-Unterstuetzung KOMPLETT ENTFERNT. Aus dem
# Archiv nachgezaehlt: assets\vr\openxr_loader.dll (2.133.504 B) sowie
# lib\VR.lua, VRGL.lua, VRRig.lua und VRXR.lua sind ersatzlos weg - vier
# Dateien und der Loader. In seinem eigenen Changelog steht "VR support was
# removed entirely for the time being ... I have no equipment to test and
# debug it", und im README "The removed OpenXR loader is not distributed
# in 2.0."
# Fuer einen VR-Hub ist die neueste Fassung damit WERTLOS. v1.6.4 ist die
# letzte mit VR und deshalb die Vorgabe.
Write-Host "  Two mods draw this game as a 3D voxel world, and both still" -ForegroundColor Gray
Write-Host "  have VR. Pick one - only one can be active at a time." -ForegroundColor Gray
Write-Host ""
Write-Host "    [1] Dramatic Shape $DRAMATIC_TAG  - the original, everything in it" -ForegroundColor Green
Write-Host "        Built-in first person, the battle and Stadium features, VR." -ForegroundColor Gray
Write-Host "        Downloaded from a MIRROR, so it may go away one day." -ForegroundColor Gray
Write-Host ""
Write-Host "    [2] Dramaless $PIN_MOD_TAG        - the slimmed-down fork" -ForegroundColor White
Write-Host "        Still has VR, but its author later removed a lot -" -ForegroundColor Gray
Write-Host "        first person and the battle features among it." -ForegroundColor Gray
Write-Host ""
Write-Host "  Neither auto-updates. Dramaless 2.0.0 and later have NO VR at all" -ForegroundColor DarkGray
Write-Host "  (the author removed it - he has no headset to test with), so the" -ForegroundColor DarkGray
Write-Host "  Hub deliberately stays on these two." -ForegroundColor DarkGray
Write-Host ""
$modChoice = ""
while ($modChoice -ne "1" -and $modChoice -ne "2") {
    $modChoice = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
    if ($modChoice -eq "") { $modChoice = "1" }
    if ($modChoice -ne "1" -and $modChoice -ne "2") { Write-Warn "Please type 1 or 2." }
}
# Der Port bleibt in beiden Faellen gepinnt: BEIDE manifest.json verlangen
# ">=0.1.37 <2.0.0", der Port darf also nicht auf 2.x springen.
$portTag = $PIN_PORT_TAG
if ($modChoice -eq "1") {
    $MOD_ID     = $DRAMATIC_ID
    $OLD_MOD_ID = $DRAMALESS_ID
    $MOD_LABEL  = "Dramatic Shape Voxel Mod"
    $modTag     = $DRAMATIC_TAG
    $MOD_PAGE   = $DRAMATIC_PAGE
    $MOD_DIRECT = $DRAMATIC_URL
    Write-Info "Dramatic Shape $DRAMATIC_TAG selected - the full mod."
} else {
    $MOD_ID     = $DRAMALESS_ID
    $OLD_MOD_ID = $DRAMATIC_ID
    $MOD_LABEL  = "Dramaless Shape Voxel Mod"
    $modTag     = $PIN_MOD_TAG
    $MOD_DIRECT = $null
    Write-Info "Dramaless $PIN_MOD_TAG selected - the last fork version with VR."
}
Write-Info "Port pinned to $portTag (both mods need it below 2.0.0)."

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
# Bei der GESPIEGELTEN Originalmod steht die Adresse fest - dort wird keine
# Release-Liste abgefragt, weil es genau diese eine Fassung sein soll.
if ($MOD_DIRECT) {
    [void]$modUrls.Add($MOD_DIRECT)
    Write-OK "Mod release: $modTag  (mirror)"
}
$modRel = if ($MOD_DIRECT) { $null } else { Get-GithubAsset -Repo $MOD_REPO -Tag $modTag -NamePattern '(?i)(dramaless|dramatic|shape)' }
if ($modRel) {
    Write-OK "Mod release: $($modRel.Tag)  ($($modRel.Name))"
    [void]$modUrls.Add($modRel.Url)
    $modTag = $modRel.Tag
} else {
    Write-Warn "GitHub API not reachable - you will be pointed at the releases page."
}
$modZip = Join-Path $tmp "voxel_mod.zip"
$modDir = Join-Path $LOVE_MODS $MOD_ID
try { New-Item -ItemType Directory -Path $LOVE_MODS -Force -ErrorAction Stop | Out-Null } catch {}
# Vorgaenger beiseite legen (umbenennen, nicht loeschen) - beide zusammen
# laden nicht, das steht so in der manifest.json des Forks.
# Alles, was zur alten Mod gehoert, MUSS AUS mods\ HERAUS. Umbenennen reicht
# nicht: der Loader geht nach der manifest.json im Ordner, nicht nach dem
# Namen - eine DRAMATIC_SHAPE.disabled wird also weiter geladen und meldet
# genau denselben Konflikt. Verschoben wird nach mods-disabled\ daneben,
# nichts wird geloescht.
$oldDirs = @()
try {
    $oldDirs = @(Get-ChildItem -LiteralPath $LOVE_MODS -Directory -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -like "$OLD_MOD_ID*" })
} catch {}
if ($oldDirs.Count -gt 0) {
    try { New-Item -ItemType Directory -Path $LOVE_MODS_OFF -Force -ErrorAction Stop | Out-Null } catch {}
    foreach ($od in $oldDirs) {
        $dest = Join-Path $LOVE_MODS_OFF $od.Name
        if (Test-Path -LiteralPath $dest) { $dest = "$dest-$(Get-Date -Format yyyyMMddHHmmss)" }
        try {
            Move-Item -LiteralPath $od.FullName -Destination $dest -ErrorAction Stop
            Write-OK "Moved the old mod out of mods\: $($od.Name)"
        } catch {
            Write-Warn "Could not move $($od.Name). Move this folder out of mods\ by hand:"
            Write-Host "   $($od.FullName)" -ForegroundColor Yellow
            Write-Host "   (anything left in mods\ keeps loading and reports the conflict)" -ForegroundColor Gray
        }
    }
    Write-Info "Kept in: $LOVE_MODS_OFF"
}
$modOk = Install-Package -Label $MOD_LABEL -Urls $modUrls -PageUrl $MOD_PAGE `
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

# !!! DIE ERFOLGSMARKER NUR SETZEN, WENN DIE VR-MOD WIRKLICH LIEGT !!!
# Frueher liefen sie auch dann, wenn Install-Package gescheitert war: der
# PORT allein war installiert, die Kachel zeigte trotzdem "VR Ready", und
# der Katalog prueft ja nur gen1recomp.exe - die gehoert aber zum flachen
# Port, nicht zur Mod. Ergebnis waere ein Spiel ohne VR mit gruener Kachel.
# Geprueft wird am ERGEBNIS im Dateisystem, nicht nur an $modOk: die
# manifest.json muss im Mod-Ordner liegen.
$modManifest = Join-Path $modDir "manifest.json"
$modReallyThere = (Test-Path -LiteralPath $modManifest)

# NACHWEIS IM SPIELORDNER, nicht nur im Installerordner. Der Hub findet
# das Spiel notfalls ueber die FallbackPaths (C:\Games\Pokemon Gen 1 VR),
# und ModFile zeigt auf gen1recomp.exe - die gehoert zum FLACHEN Port.
# Ohne diesen Merker waere die Kachel also auch dann gruen, wenn nur der
# Port da ist. Die Mod selbst liegt in %APPDATA%\pokemon-love2d\mods\ und
# damit AUSSERHALB des Spielordners, kann also nicht direkt geprueft werden.
$vrMarker = Join-Path $gameRoot ".pcvrhub_voxelmod"
if ($modReallyThere) {
    try { Set-Content -Path $vrMarker -Value "$MOD_ID $modTag" -Encoding UTF8 -Force } catch {}
} else {
    try { Remove-Item -LiteralPath $vrMarker -Force -ErrorAction SilentlyContinue } catch {}
}

if ($modReallyThere) {
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exePath -Encoding UTF8 -Force } catch {}
    try { if ($modTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $modTag -Encoding UTF8 -Force } } catch {}
} else {
    # Alte Marker aus einem frueheren, erfolgreichen Lauf wuerden das Bild
    # ebenso verfaelschen - die muessen weg, sonst bleibt die Kachel gruen.
    foreach ($m in @(".installed_path", ".launch_exe", ".installed_version")) {
        try { Remove-Item -LiteralPath (Join-Path $SCRIPT_DIR $m) -Force -ErrorAction SilentlyContinue } catch {}
    }
    Write-Host ""
    Write-Warn "The VR mod is NOT installed - only the flat port is."
    Write-Host "  The Hub will not show this as VR Ready, which is correct:" -ForegroundColor Gray
    Write-Host "  $MOD_ID is missing from" -ForegroundColor Gray
    Write-Host "     $modDir" -ForegroundColor Yellow
    Write-Host "  Run this installer again, or fetch the mod by hand from:" -ForegroundColor Gray
    Write-Host "     $MOD_PAGE" -ForegroundColor Cyan
}

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
Write-Host "    Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or use the new" -ForegroundColor Gray
Write-Host "    'Pokemon Gen 1 VR' desktop shortcut." -ForegroundColor Gray
Write-Host ""
Write-Host "  The mod lives outside the game folder, at:" -ForegroundColor Gray
Write-Host "    $modDir" -ForegroundColor Cyan
Write-Host "  Delete that folder to remove it. This game's page in the Hub" -ForegroundColor DarkGray
Write-Host "  has the VR controls and the options rows." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  That Snorlax is blocking the road at full size now. Still no flute." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
