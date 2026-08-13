# ============================================================
# Metroid Prime VR Installer (PrimedGun, by Nobbie)
# ============================================================
# PrimedGun is a Dolphin XR Redux-based build focused on a proper
# VR experience for Metroid Prime (GameCube, NTSC 1.0 (rev 0)). This
# installer downloads the latest PrimedGun release from GitHub,
# unpacks it to C:\Games\Metroid Prime VR (or a folder you pick),
# creates a ROM subfolder, forces Dolphin portable mode and
# pre-points the game-list at that ROM folder so a dropped-in
# Metroid Prime NTSC 1.0 (rev 0) ISO is detected automatically.
#
# The user must supply their own Metroid Prime
# NTSC 1.0 (rev 0) GameCube ISO - no game ROM is downloaded or shipped.
#
# Install layout (the release ZIP extracts under an x64\ folder):
#   <install_root>\Metroid Prime VR\PrimedGun.exe
#   <install_root>\Metroid Prime VR\ROM\        (drop your ISO here)
#   <install_root>\Metroid Prime VR\portable.txt (forces portable)
#   <install_root>\Metroid Prime VR\User\Config\Dolphin.ini (ISO path)
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Metroid Prime VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Metroid Prime VR Installer" -ForegroundColor Cyan
    Write-Host " PrimedGun (Dolphin XR Redux) by Nobbie | GameCube ROM required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR        = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_API_LATEST   = "https://api.github.com/repos/Nobbie248/PrimedGun/releases/latest"
$RELEASES_LATEST   = "https://github.com/Nobbie248/PrimedGun/releases/latest"
$INFO_URL          = "https://github.com/Nobbie248/PrimedGun"
# Last-known-good asset, used only if the GitHub API cannot be reached.
# (The API path above always prefers the newest release.)
# Rueckfall NUR ohne Netz - der Normalweg loest die neueste Fassung auf.
# 2026-08-13 von v1.0.2 auf v1.1.5 gezogen (drei Fassungen Rueckstand).
$KNOWN_FALLBACK_ZIP = "https://github.com/Nobbie248/PrimedGun/releases/download/v1.1.5/PrimedGun.v1.1.5.zip"
$GAME_FOLDER       = "Metroid Prime VR"
$GAME_EXE          = "PrimedGun.exe"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest PrimedGun*.zip asset via the GitHub API. Returns the
# browser_download_url, or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the known URL + manual link.
function Get-LatestPrimedGunZipUrl {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rel = Invoke-RestMethod -Uri $REPO_API_LATEST -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        $asset = $rel.assets | Where-Object { $_.name -match '(?i)^PrimedGun.*\.zip$' } | Select-Object -First 1
        if ($asset -and $asset.browser_download_url) { return [string]$asset.browser_download_url }
    } catch { }
    return $null
}

# Merge a preserved directory back into a newly installed payload.  Files are
# copied one by one so an existing directory from the release archive is merged
# instead of causing an extra nested User\User or ROM\ROM folder.
function Copy-PreservedTree {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    $sourceRoot = [System.IO.Path]::GetFullPath($Source).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $sourceRoot)) { return }
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force -ErrorAction Stop | Out-Null
    }
    Get-ChildItem -LiteralPath $sourceRoot -Directory -Recurse -Force -ErrorAction Stop | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
        New-Item -ItemType Directory -Path (Join-Path $Destination $relative) -Force -ErrorAction Stop | Out-Null
    }
    Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force -ErrorAction Stop | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
        $target = Join-Path $Destination $relative
        $targetParent = Split-Path $target -Parent
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force -ErrorAction Stop | Out-Null
        }
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force -ErrorAction Stop
        $copied = Get-Item -LiteralPath $target -Force -ErrorAction Stop
        if ($copied.Length -ne $_.Length) { throw "Verification failed after restoring '$relative'." }
    }
}

# Restore ROMs, saves, save states and settings from the durable backup next to
# the install directory.  The backup is deleted only after every file copied
# and passed the size check; an interrupted update therefore remains recoverable.
function Restore-PrimedGunUserData {
    param(
        [Parameter(Mandatory=$true)][string]$BackupRoot,
        [Parameter(Mandatory=$true)][string]$GameRoot
    )
    if (-not (Test-Path -LiteralPath $BackupRoot)) { return $true }
    try {
        foreach ($folder in @("ROM", "User")) {
            $source = Join-Path $BackupRoot $folder
            if (Test-Path -LiteralPath $source) {
                Copy-PreservedTree -Source $source -Destination (Join-Path $GameRoot $folder)
                Write-OK "Preserved $folder folder restored."
            }
        }
        Remove-Item -LiteralPath $BackupRoot -Recurse -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Fail "Could not fully restore preserved PrimedGun user data: $_"
        Write-Warn "The safety backup has NOT been deleted: $BackupRoot"
        return $false
    }
}

# Update only the keys owned by this installer.  Replacing Dolphin.ini outright
# would erase controller, graphics, audio and other user preferences.
function Set-IniSectionValues {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Values
    )
    $lines = New-Object 'System.Collections.Generic.List[string]'
    if (Test-Path -LiteralPath $Path) {
        foreach ($line in [System.IO.File]::ReadAllLines($Path)) { [void]$lines.Add($line) }
    }
    $sectionPattern = '^\s*\[' + [regex]::Escape($Section) + '\]\s*$'
    $sectionStart = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $sectionPattern) { $sectionStart = $i; break }
    }
    if ($sectionStart -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') { [void]$lines.Add('') }
        [void]$lines.Add("[$Section]")
        $sectionStart = $lines.Count - 1
    }
    $sectionEnd = $lines.Count
    for ($i = $sectionStart + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[.+\]\s*$') { $sectionEnd = $i; break }
    }
    foreach ($entry in $Values.GetEnumerator()) {
        $keyPattern = '^\s*' + [regex]::Escape([string]$entry.Key) + '\s*='
        $found = -1
        for ($i = $sectionStart + 1; $i -lt $sectionEnd; $i++) {
            if ($lines[$i] -match $keyPattern) { $found = $i; break }
        }
        $newLine = "$($entry.Key) = $($entry.Value)"
        if ($found -ge 0) { $lines[$found] = $newLine }
        else { $lines.Insert($sectionEnd, $newLine); $sectionEnd++ }
    }
    [System.IO.File]::WriteAllLines($Path, $lines, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Header

Write-Host "  PrimedGun is a Dolphin XR Redux-based build that turns Metroid" -ForegroundColor Gray
Write-Host "  Prime (GameCube) into a proper motion-controlled experience:" -ForegroundColor Gray
Write-Host "  6DOF arm-cannon tracking, visor head tracking, gesture input," -ForegroundColor Gray
Write-Host "  full directional movement and an in-headset settings menu." -ForegroundColor Gray
Write-Host "  Created by Nobbie, built on iChris4's Dolphin XR Redux." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Metroid Prime - NTSC 1.0 (Revision 0)  (NOT rev 1 or rev 2)" -ForegroundColor Yellow
Write-Host "    A GameCube disc image (.iso / .rvz / .gcm) that you own." -ForegroundColor Gray
Write-Host "    Tip: you can verify the disc revision in Dolphin." -ForegroundColor Gray
Write-Host "  No game ROM is downloaded or included - only the PrimedGun" -ForegroundColor Gray
Write-Host "  application is fetched (from the official GitHub releases)." -ForegroundColor Gray
Write-Host ""
Write-Host "  PrimedGun is STANDALONE - you do NOT need Dolphin installed." -ForegroundColor Gray
Write-Host "  It installs into its own clean folder, separate from any Dolphin." -ForegroundColor Gray
Write-Host ""
Write-Host "  Oculus/Meta runtime is NOT recommended - use SteamVR." -ForegroundColor Yellow
Pause-User "Press Enter to begin the installation or update..." | Out-Null

# ---- 1. pick a writable install root ------------------------
Write-Step 1 5 "Choosing an install or update location"

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  Press Enter to accept it, or type a different folder to install into" -ForegroundColor Gray
Write-Host "  (the '$GAME_FOLDER' folder is created inside whatever you choose)." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) {
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
    }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    Write-Host "  Enter a folder where the game should be installed." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER
$romDir   = Join-Path $gameRoot "ROM"
$userDir  = Join-Path $gameRoot "User"
$preserveRoot = Join-Path $installRoot "_PCVRHub_PrimedGun_UserData_Backup"

# Recover automatically from an earlier update that was interrupted after its
# user data had been moved out of the install directory.
if (Test-Path -LiteralPath $preserveRoot) {
    Write-Warn "Found a PrimedGun user-data backup from an interrupted update. Restoring it first."
    if (-not (Restore-PrimedGunUserData -BackupRoot $preserveRoot -GameRoot $gameRoot)) {
        Pause-User "Press Enter to exit without changing the installation." | Out-Null
        exit 1
    }
}

# ---- 2. download the latest PrimedGun release ---------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile "PrimedGun.exe"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") {
    Write-Info "Update mode - merging the latest mod files into the existing install; user data is preserved."
}

$null = Show-UpdateNoticeIfInstalled -TargetDir $installRoot -RelModFile $GAME_EXE -Label "PrimedGun"
Write-Step 2 5 "Downloading PrimedGun (latest release)"

$tmp = Join-Path $installRoot "_primedgun_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "PrimedGun_latest.zip"

$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest release via the GitHub API..."
$apiUrl = Get-LatestPrimedGunZipUrl
if ($apiUrl) {
    Write-OK "Latest release asset: $apiUrl"
    [void]$urls.Add($apiUrl)
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known URL."
}
# Always also queue the known-good URL as a secondary source.
if ([string]$apiUrl -ne [string]$KNOWN_FALLBACK_ZIP) { [void]$urls.Add($KNOWN_FALLBACK_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $zipDest `
    -Label "PrimedGun (Metroid Prime VR build)" `
    -ManualUrl $RELEASES_LATEST `
    -Instructions "Open the releases page, download the newest 'PrimedGun.vX.Y.Z.zip', save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

# Hard guarantee: regardless of the helper's outcome, make sure we have a ZIP.
while (-not (Test-Path $zipDest)) {
    Write-Fail "The PrimedGun download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download PrimedGun" `
        -Subject "the latest PrimedGun release" `
        -Url $RELEASES_LATEST `
        -Instructions "Download the newest 'PrimedGun.vX.Y.Z.zip' from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    Write-Host "  If you already have the ZIP, paste its full path (or Enter to recheck '$zipDest')." -ForegroundColor White
    $alt = (Read-Host "  ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path $alt) -and ($alt -match '\.zip$')) { $zipDest = [string]$alt }
}
Write-OK "PrimedGun archive ready: $zipDest"

# ---- 3. extract + flatten into the game folder --------------
Write-Step 3 5 "Installing PrimedGun"

$unpack = Join-Path $tmp "unpack"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
        Expand-Archive -Path $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the ZIP: $_"
        $fb = Invoke-InstallerFallback -Action "extract the PrimedGun ZIP" `
            -Subject "the downloaded PrimedGun ZIP" `
            -Url $RELEASES_LATEST `
            -Instructions "The ZIP may be incomplete. Re-download the newest 'PrimedGun.vX.Y.Z.zip', save it as '$zipDest', then choose Retry. Or paste the path to a fresh ZIP." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
        if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) { $zipDest = [string]$again }
    }
}

# The release ZIP wraps everything in an x64\ folder. Find PrimedGun.exe
# anywhere in the tree and treat its folder as the real payload root, so
# this works whether the layout is wrapped or flat.
$exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the PrimedGun download" `
        -Url $RELEASES_LATEST `
        -Instructions "The ZIP did not contain $GAME_EXE - it may be the wrong file. Grab the newest 'PrimedGun.vX.Y.Z.zip' from the releases page, save it as '$zipDest', then choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
    if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) {
        $zipDest = [string]$again
        try {
            if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
            Expand-Archive -Path $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$payloadDir = Split-Path -Parent $exeItem.FullName

# Move all user-owned data outside the directory that is about to be replaced.
# A move on the same volume is immediate even for a large ROM.  Unlike the old
# temp backup, this durable folder is never removed by generic temp cleanup.
try {
    foreach ($folder in @("ROM", "User")) {
        $source = Join-Path $gameRoot $folder
        if (Test-Path -LiteralPath $source) {
            if (-not (Test-Path -LiteralPath $preserveRoot)) {
                New-Item -ItemType Directory -Path $preserveRoot -Force -ErrorAction Stop | Out-Null
            }
            Move-Item -LiteralPath $source -Destination (Join-Path $preserveRoot $folder) -Force -ErrorAction Stop
            Write-OK "$folder folder secured before replacing the mod files."
        }
    }
} catch {
    Write-Fail "Could not safely preserve PrimedGun user data: $_"
    if (Test-Path -LiteralPath $preserveRoot) {
        $null = Restore-PrimedGunUserData -BackupRoot $preserveRoot -GameRoot $gameRoot
    }
    Pause-User "Press Enter to exit without replacing the installation." | Out-Null
    exit 1
}

$placedOk = $false
while (-not $placedOk) {
    try {
        # Always merge release files. Anything user-created and not present in
        # the archive remains untouched, including during a repair install.
        Copy-PreservedTree -Source $payloadDir -Destination $gameRoot
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the game files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the PrimedGun files into place" `
            -Instructions "Copy the CONTENTS of '$payloadDir' into '$gameRoot' (so that $GAME_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$payloadDir" `
            -DestFolder "$gameRoot" `
            -AllowSkip $true
        if ([string]$fb -eq "quit") {
            if (Test-Path -LiteralPath $preserveRoot) {
                $null = Restore-PrimedGunUserData -BackupRoot $preserveRoot -GameRoot $gameRoot
            }
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        if ([string]$fb -eq "skip") { break }
    }
}
Write-OK "Game installed at: $gameRoot"

if (Test-Path -LiteralPath $preserveRoot) {
    if (-not (Restore-PrimedGunUserData -BackupRoot $preserveRoot -GameRoot $gameRoot)) {
        Pause-User "Press Enter to exit. Your safety backup remains at the path shown above." | Out-Null
        exit 1
    }
}

# ---- 4. ROM folder + portable mode + auto-bind the ROM path -
Write-Step 4 5 "Setting up the ROM folder and auto-detection"

# 4a. ROM folder (an existing one was restored above).
try {
    if (-not (Test-Path -LiteralPath $romDir)) {
        New-Item -ItemType Directory -Path $romDir -Force -ErrorAction Stop | Out-Null
        Write-OK "ROM folder created: $romDir"
    } else {
        Write-OK "Existing ROM folder preserved: $romDir"
    }
} catch {
    Write-Warn "Could not create the ROM folder automatically: $_"
    Write-Host "  Please create this folder yourself and put your ISO there:" -ForegroundColor Gray
    Write-Host "    $romDir" -ForegroundColor Cyan
}

# 4b. portable.txt next to the exe -> forces Dolphin to use the local
# User\ folder (verified: dolphin-emu.org docs + Dolphin wiki). Without
# it Dolphin would use %AppData% and ignore the bundled User\ + our
# pre-set ISO path.
try {
    Set-Content -Path (Join-Path $gameRoot "portable.txt") -Value "" -Encoding ASCII -ErrorAction Stop
    Write-OK "Portable mode enabled (portable.txt)"
} catch {
    Write-Warn "Could not write portable.txt: $_ (auto-detection of the ROM may not work; use Select Game... in-app)."
}

# 4c. Pre-point Dolphin's game list at the ROM folder via
# User\Config\Dolphin.ini [General] ISOPath0 (verified key). This makes
# a dropped-in ISO show up automatically - no manual Select Game needed.
try {
    $cfgDir = Join-Path $gameRoot "User\Config"
    if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force -ErrorAction Stop | Out-Null }
    $iniPath = Join-Path $cfgDir "Dolphin.ini"
    Set-IniSectionValues -Path $iniPath -Section "General" -Values ([ordered]@{
        ISOPaths = "1"
        RecursiveISOPaths = "True"
        ISOPath0 = $romDir
    })
    Write-OK "Game list pre-pointed at the ROM folder (auto-detect on)"
} catch {
    Write-Warn "Could not pre-configure the ROM path: $_"
    Write-Host "  No problem - in PrimedGun just click 'Select Game...', pick your ISO," -ForegroundColor Gray
    Write-Host "  and it will be remembered." -ForegroundColor Gray
}

# 4d. Place the ROM now (drag & drop) or skip for later. We open the ROM
# folder in Explorer so the destination is visible, then accept a path
# dragged onto this window. Dropping a file at a Read-Host prompt pastes
# its full path (quoted when it contains spaces) - we strip the quotes and
# copy it in. Pressing Enter with no path skips; the ROM can be added later
# by dropping it into the (now open) ROM folder.
Write-Host ""
Write-Host "  >>> Your ROM goes here:" -ForegroundColor White
Write-Host "      $romDir" -ForegroundColor Cyan
Write-Host "      (Metroid Prime NTSC 1.0 / rev 0 only - NOT rev 1 or rev 2)" -ForegroundColor Yellow
Write-Host ""

$romExt = @(".iso", ".rvz", ".gcm", ".ciso", ".gcz", ".wbfs")
$romPlaced = $false
# On an update or reinstall the ROM folder is preserved. If a disc image
# is already sitting there, keep it and skip the drag prompt - the ROM is
# already in the right place, so re-adding it would be pointless.
$existingRom = $null
if (Test-Path $romDir) {
    $existingRom = Get-ChildItem -LiteralPath $romDir -File -ErrorAction SilentlyContinue |
        Where-Object { $romExt -contains $_.Extension.ToLower() } | Select-Object -First 1
}
if ($existingRom) {
    Write-OK "ROM already in place: $($existingRom.Name) - keeping your existing disc image."
    Write-Info "To swap it, drop a different file into the ROM folder shown above."
    $romPlaced = $true
}
while (-not $romPlaced) {
    Write-Host ""
    Write-Host "  Drag your Metroid Prime ROM onto this window and press Enter. A .zip" -ForegroundColor White
    Write-Host "  that contains the ROM works too - it is unpacked automatically." -ForegroundColor White
    Write-Host "  Or just press Enter to skip and add it later." -ForegroundColor Gray
    $drop = (Read-Host "  ROM file (drag here, or Enter to skip)").Trim().Trim('"').Trim()
    if (-not $drop) {
        Write-Info "Skipped - drop your ISO into the ROM folder whenever you are ready."
        break
    }
    if (-not (Test-Path -LiteralPath $drop)) {
        Write-Fail "That path does not exist: $drop"
        continue
    }
    if ((Get-Item -LiteralPath $drop).PSIsContainer) {
        Write-Fail "That is a folder, not a ROM file - drag the disc image itself."
        continue
    }
    $ext = [System.IO.Path]::GetExtension($drop).ToLower()

    # If a .zip was dropped, unpack it and locate the disc image inside. ROM
    # downloads are often a .zip holding the .iso (sometimes with a nested
    # .zip too - that inner archive is ignored; we match on disc-image
    # extensions and take the largest, which is the real image).
    $romSource = $drop
    $romTmp = $null
    if ($ext -eq ".zip") {
        Write-Info "Zip detected - unpacking and locating the disc image inside..."
        $romTmp = Join-Path $env:TEMP ("mp_rom_" + [Guid]::NewGuid().ToString("N"))
        try {
            New-Item -ItemType Directory -Path $romTmp -Force -ErrorAction Stop | Out-Null
            Expand-Archive -LiteralPath $drop -DestinationPath $romTmp -Force -ErrorAction Stop
            $inner = Get-ChildItem -LiteralPath $romTmp -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $romExt -contains $_.Extension.ToLower() } | Sort-Object Length -Descending | Select-Object -First 1
            if ($inner) {
                $romSource = $inner.FullName
                Write-OK "Found disc image in zip: $($inner.Name)"
            } else {
                Write-Fail "No GameCube disc image (.iso / .rvz / .gcm ...) found inside the zip."
                try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                continue
            }
        } catch {
            Write-Fail "Could not unpack the zip: $_"
            try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            continue
        }
    } elseif ($romExt -notcontains $ext) {
        Write-Warn "That does not look like a GameCube disc image ($ext)."
        $yn = (Read-Host "  Copy it anyway? (y/N)").Trim().ToLower()
        if ($yn -ne "y") { if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }; continue }
    }
    try {
        $destFile = Join-Path $romDir ([System.IO.Path]::GetFileName($romSource))
        Copy-Item -LiteralPath $romSource -Destination $destFile -Force -ErrorAction Stop
        Write-OK "ROM copied into place: $destFile"
        $romPlaced = $true
    } catch {
        Write-Fail "Could not copy the ROM: $_"
        Write-Host "  You can copy it into the ROM folder yourself:" -ForegroundColor Gray
        Write-Host "    $romDir" -ForegroundColor Cyan
        $retry = (Read-Host "  Press Enter to try again, or type 'skip' to continue").Trim().ToLower()
        if ($retry -eq "skip") { if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }; break }
    }
    if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
}

# ---- 5. desktop shortcut + finish ---------------------------
Write-Step 5 5 "Creating a desktop shortcut"
$exePath = Join-Path $gameRoot $GAME_EXE
if (-not (Test-Path $exePath)) {
    Write-Warn "Game EXE not found after install - shortcut skipped."
    Write-Host "  Open '$gameRoot' and confirm $GAME_EXE is there; if it sits in a" -ForegroundColor Gray
    Write-Host "  subfolder, move that folder's contents up one level." -ForegroundColor Gray
} else {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Metroid Prime VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: Metroid Prime VR"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
        Write-Host "  You can launch the game manually with:" -ForegroundColor Gray
        Write-Host "    $exePath" -ForegroundColor Cyan
    }
}

# Record the install path so the Hub's "VR Installed" check + Start-in-VR find it.
try {
    Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Force -ErrorAction Stop
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Metroid Prime VR (PrimedGun) is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  How to play:" -ForegroundColor White
if ($romPlaced) {
    Write-Host "   1. Start SteamVR first (Oculus/Meta runtime is not recommended)." -ForegroundColor White
    Write-Host "   2. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'Metroid" -ForegroundColor White
Write-Host "      Prime VR' desktop shortcut, or run:" -ForegroundColor White
    Write-Host "        $exePath" -ForegroundColor Cyan
    Write-Host "   3. Your ROM is already in place - select it in the list and press Play." -ForegroundColor White
} else {
    Write-Host "   1. Put your Metroid Prime NTSC 1.0 (rev 0) ISO into:" -ForegroundColor White
    Write-Host "        $romDir" -ForegroundColor Cyan
    Write-Host "   2. Start SteamVR first (Oculus/Meta runtime is not recommended)." -ForegroundColor White
    Write-Host "   3. Launch with the 'Metroid Prime VR' desktop shortcut, or run:" -ForegroundColor White
    Write-Host "        $exePath" -ForegroundColor Cyan
    Write-Host "   4. Your ROM should appear in the list - select it and press Play." -ForegroundColor White
    Write-Host "      If it is NOT listed, click 'Select Game...', pick your ISO once, then Play." -ForegroundColor White
}
Write-Host ""
Write-Host "  Tips: use the in-headset settings menu for one-click height" -ForegroundColor Gray
Write-Host "  calibration and cannon position/rotation tuning." -ForegroundColor Gray
Write-Host ""

try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# If no ROM was added during install, open the ROM folder now so the user
# can drop the ISO in with the destination right in front of them.
if (-not $romPlaced) {
    try {
        Start-Process explorer.exe $romDir -ErrorAction Stop
        Write-Info "Opened the ROM folder - drop your Metroid Prime ISO in there."
    } catch {
        Write-Host "  Open this folder and drop your ISO in:" -ForegroundColor Gray
        Write-Host "    $romDir" -ForegroundColor Cyan
    }
    Write-Host ""
}

Write-Host "  Scan the unknown, lock on, and let the arm cannon do the talking." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
