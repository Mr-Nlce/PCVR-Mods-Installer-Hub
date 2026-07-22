# ============================================================
# Perfect Dark VR Installer (VR fork by Alex-LeTux)
# ============================================================
# A VR fork of the Perfect Dark decompilation port, targeting
# PCVR. This installer downloads the latest PCVR release ZIP from
# GitHub (never the .apk, which is the Quest standalone build),
# unpacks it to C:\Games\Perfect Dark VR (or a folder you pick),
# then lets you drop in your own Perfect Dark N64 ROM, which it
# renames to pd.ntsc-final.z64 and places in the data folder.
#
# You must provide your OWN Perfect Dark NTSC ROM - no game ROM
# is downloaded or shipped.
#
# Install layout (the release ZIP wraps a Perfect_Dark_PCVR_* folder):
#   <install_root>\Perfect Dark VR\pd.x86_64.exe
#   <install_root>\Perfect Dark VR\data\pd.ntsc-final.z64  (your ROM)
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Perfect Dark VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Perfect Dark VR Installer" -ForegroundColor Cyan
    Write-Host " VR fork by Alex-LeTux | Perfect Dark NTSC v1.1 (.z64) ROM required" -ForegroundColor Gray
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
$REPO_API_LATEST   = "https://api.github.com/repos/Alex-LeTux/perfect_dark_VR/releases/latest"
$RELEASES_LATEST   = "https://github.com/Alex-LeTux/perfect_dark_VR/releases/latest"
$INFO_URL          = "https://github.com/Alex-LeTux/perfect_dark_VR"
# Last-known-good PCVR asset, used only if the GitHub API cannot be reached.
$KNOWN_FALLBACK_ZIP = "https://github.com/Alex-LeTux/perfect_dark_VR/releases/download/v1.1-beta/Perfect_Dark_PCVR_v1.1-beta.zip"
$GAME_FOLDER       = "Perfect Dark VR"
$GAME_EXE          = "pd.x86_64.exe"
$ROM_NAME          = "pd.ntsc-final.z64"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest PCVR *.zip asset via the GitHub API. Matches the PCVR
# ZIP and NEVER the .apk (Quest standalone). Returns the browser_download_url,
# or $null on any failure (rate limit / offline / shape change).
function Get-LatestPcvrZipUrl {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rel = Invoke-RestMethod -Uri $REPO_API_LATEST -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        $asset = $rel.assets | Where-Object { $_.name -match '(?i)pcvr.*\.zip$' } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1 }
        if ($asset -and $asset.browser_download_url) { return [string]$asset.browser_download_url }
    } catch { }
    return $null
}

Write-Header

Write-Host "  Perfect Dark VR is a VR fork of the Perfect Dark decompilation" -ForegroundColor Gray
Write-Host "  port by Alex-LeTux - the classic Rare secret-agent shooter" -ForegroundColor Gray
Write-Host "  starring Joanna Dark, in first-person motion-controlled VR." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Perfect Dark - NTSC version 1.1 (US), in .z64 format." -ForegroundColor Yellow
Write-Host "    Exactly this version is required - a .z64 ROM that you own." -ForegroundColor Gray
Write-Host "  No game ROM is downloaded or included - only the VR port is" -ForegroundColor Gray
Write-Host "  fetched (the newest PCVR build from the official GitHub releases)." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..." | Out-Null

# ---- 1. pick a writable install root ------------------------
Write-Step 1 4 "Choosing an install or update location"

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
Write-Host "  Press Enter to accept it, or type a different folder to install into." -ForegroundColor Gray
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
$dataDir  = Join-Path $gameRoot "data"

# ---- 2. download the latest PCVR release --------------------
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile $GAME_EXE
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the port files (your ROM is kept)." }

$null = Show-UpdateNoticeIfInstalled -TargetDir $installRoot -RelModFile $GAME_EXE -Label "Perfect Dark VR"
Write-Step 2 4 "Downloading Perfect Dark VR (latest PCVR release)"

$tmp = Join-Path $installRoot "_perfectdark_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "PerfectDark_PCVR_latest.zip"

$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest PCVR release via the GitHub API..."
$apiUrl = Get-LatestPcvrZipUrl
if ($apiUrl) {
    Write-OK "Latest PCVR asset: $apiUrl"
    [void]$urls.Add($apiUrl)
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known URL."
}
if ([string]$apiUrl -ne [string]$KNOWN_FALLBACK_ZIP) { [void]$urls.Add($KNOWN_FALLBACK_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $zipDest `
    -Label "Perfect Dark VR (PCVR build)" `
    -ManualUrl $RELEASES_LATEST `
    -Instructions "Open the releases page, download the newest 'Perfect_Dark_PCVR_*.zip' (NOT the .apk), save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

while (-not (Test-Path $zipDest)) {
    Write-Fail "The Perfect Dark VR download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download Perfect Dark VR" `
        -Subject "the latest PCVR release" `
        -Url $RELEASES_LATEST `
        -Instructions "Download the newest 'Perfect_Dark_PCVR_*.zip' (NOT the .apk) from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    Write-Host "  If you already have the ZIP, paste its full path (or Enter to recheck '$zipDest')." -ForegroundColor White
    $alt = (Read-Host "  ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path -LiteralPath $alt) -and ($alt -match '\.zip$')) { $zipDest = [string]$alt }
}
Write-OK "Perfect Dark VR archive ready: $zipDest"

# ---- 3. extract + flatten into the game folder --------------
Write-Step 3 4 "Installing Perfect Dark VR"

$unpack = Join-Path $tmp "unpack"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
        Expand-Archive -LiteralPath $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the ZIP: $_"
        $fb = Invoke-InstallerFallback -Action "extract the Perfect Dark VR ZIP" `
            -Subject "the downloaded PCVR ZIP" `
            -Url $RELEASES_LATEST `
            -Instructions "The ZIP may be incomplete. Re-download the newest 'Perfect_Dark_PCVR_*.zip', save it as '$zipDest', then choose Retry. Or paste the path to a fresh ZIP." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
        if ($again -and (Test-Path -LiteralPath $again) -and ($again -match '\.zip$')) { $zipDest = [string]$again }
    }
}

# The release ZIP wraps everything in a Perfect_Dark_PCVR_* folder. Find
# pd.x86_64.exe anywhere in the tree and treat its folder as the real
# payload root, so this works whether the layout is wrapped or flat.
$exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the Perfect Dark VR download" `
        -Url $RELEASES_LATEST `
        -Instructions "The ZIP did not contain $GAME_EXE - it may be the wrong file (e.g. the .apk). Grab the newest 'Perfect_Dark_PCVR_*.zip' from the releases page, save it as '$zipDest', then choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
    if ($again -and (Test-Path -LiteralPath $again) -and ($again -match '\.zip$')) {
        $zipDest = [string]$again
        try {
            if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
            Expand-Archive -LiteralPath $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$payloadDir = Split-Path -Parent $exeItem.FullName

# Preserve an existing ROM across a reinstall/update.
$romBackup = $null
$oldRom = Join-Path $dataDir $ROM_NAME
if (Test-Path $oldRom) {
    $romBackup = Join-Path $tmp $ROM_NAME
    try { Move-Item -Path $oldRom -Destination $romBackup -Force -ErrorAction Stop } catch { $romBackup = $null }
}

$placedOk = $false
while (-not $placedOk) {
    try {
        if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
        New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
        $null = Get-ChildItem -Path $payloadDir -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
        }
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the game files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the Perfect Dark VR files into place" `
            -Instructions "Copy the CONTENTS of '$payloadDir' into '$gameRoot' (so that $GAME_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$payloadDir" `
            -DestFolder "$gameRoot" `
            -AllowSkip $true
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        if ([string]$fb -eq "skip") { break }
    }
}
Write-OK "Game installed at: $gameRoot"

# Make sure the data folder exists (it ships in the ZIP, but be safe).
try { if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force -ErrorAction Stop | Out-Null } } catch { }

# Restore a preserved ROM.
if ($romBackup -and (Test-Path $romBackup)) {
    try { Move-Item -Path $romBackup -Destination (Join-Path $dataDir $ROM_NAME) -Force -ErrorAction Stop; Write-OK "Existing ROM preserved." } catch { }
}

# ---- 4. ROM: drag-and-drop, rename, place in data -----------
Write-Step 4 4 "Adding your Perfect Dark ROM"

$romTarget = Join-Path $dataDir $ROM_NAME
$romExt = @(".z64", ".n64", ".v64", ".rom")
$romPlaced = (Test-Path $romTarget)
if ($romPlaced) {
    Write-OK "ROM already in place: $romTarget - keeping it."
    Write-Info "To swap it, replace that file with your own NTSC v1.1 .z64 ROM (same name)."
}
while (-not $romPlaced) {
    Write-Host "  Required: Perfect Dark NTSC version 1.1 (US), in .z64 format." -ForegroundColor Yellow
    Write-Host "  Drag your ROM (.z64) onto this window and press Enter. A .zip that" -ForegroundColor White
    Write-Host "  contains the ROM works too - it is unpacked automatically." -ForegroundColor White
    Write-Host "  Or press Enter to skip and add it later." -ForegroundColor Gray
    $drop = (Read-Host "  ROM or zip (drag here, or Enter to skip)").Trim().Trim('"').Trim()
    if (-not $drop) {
        Write-Info "Skipped - you can add the ROM later (see the final instructions)."
        break
    }
    if (-not (Test-Path -LiteralPath $drop)) { Write-Fail "That path does not exist: $drop"; continue }
    if ((Get-Item -LiteralPath $drop).PSIsContainer) { Write-Fail "That is a folder, not a file - drag the ROM or zip itself."; continue }
    $ext = [System.IO.Path]::GetExtension($drop).ToLower()

    # Resolve the actual ROM source. A dropped .zip is unpacked and the ROM
    # inside is located (prefer .z64); otherwise the dropped file is the ROM.
    $romSource = $drop
    $romTmp = $null
    if ($ext -eq ".zip") {
        Write-Info "Zip detected - unpacking and locating the ROM inside..."
        $romTmp = Join-Path $env:TEMP ("pd_rom_" + [Guid]::NewGuid().ToString("N"))
        try {
            New-Item -ItemType Directory -Path $romTmp -Force -ErrorAction Stop | Out-Null
            Expand-Archive -LiteralPath $drop -DestinationPath $romTmp -Force -ErrorAction Stop
            $inner = Get-ChildItem -Path $romTmp -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension.ToLower() -eq ".z64" } | Select-Object -First 1
            if (-not $inner) { $inner = Get-ChildItem -Path $romTmp -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $romExt -contains $_.Extension.ToLower() } | Select-Object -First 1 }
            if ($inner) {
                $romSource = $inner.FullName
                Write-OK "Found ROM in zip: $($inner.Name)"
            } else {
                Write-Fail "No .z64 ROM found inside the zip."
                try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                continue
            }
        } catch {
            Write-Fail "Could not unpack the zip: $_"
            try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            continue
        }
    } elseif ($romExt -notcontains $ext) {
        Write-Warn "That does not look like a ROM or zip ($ext)."
        $yn = (Read-Host "  Use it anyway? (y/N)").Trim().ToLower()
        if ($yn -ne "y") { if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }; continue }
    }
    # The game needs the big-endian .z64 format. Warn (but allow) other orders.
    $srcExt = [System.IO.Path]::GetExtension($romSource).ToLower()
    if (@(".n64", ".v64") -contains $srcExt) {
        Write-Warn "That is a $srcExt ROM - the game needs the .z64 (big-endian) format."
        Write-Host "  It will be placed anyway, but if it fails to load, use the .z64 version." -ForegroundColor Gray
    }
    try {
        Copy-Item -LiteralPath $romSource -Destination $romTarget -Force -ErrorAction Stop
        Write-OK "ROM copied and renamed to: $romTarget"
        $romPlaced = $true
    } catch {
        Write-Fail "Could not copy the ROM: $_"
        Write-Host "  You can place it yourself: copy your ROM into the data folder and" -ForegroundColor Gray
        Write-Host "  rename it to exactly '$ROM_NAME':" -ForegroundColor Gray
        Write-Host "    $dataDir" -ForegroundColor Cyan
        $retry = (Read-Host "  Press Enter to try again, or type 'skip' to continue").Trim().ToLower()
        if ($retry -eq "skip") { if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }; break }
    }
    if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
}

# ---- desktop shortcut + finish ------------------------------
$exePath = Join-Path $gameRoot $GAME_EXE
if (Test-Path $exePath) {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Perfect Dark VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: Perfect Dark VR"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
    }
} else {
    Write-Warn "Game EXE not found after install - shortcut skipped."
}

# Record the install path so the Hub's "VR Installed" check + Start-in-VR find it.
try {
    Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Force -ErrorAction Stop
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Perfect Dark VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if (-not $romPlaced) {
    Write-Host "  Add your ROM first: copy your Perfect Dark NTSC v1.1 .z64 ROM into" -ForegroundColor White
    Write-Host "  data folder and rename it to exactly '$ROM_NAME':" -ForegroundColor White
    Write-Host "    $dataDir" -ForegroundColor Cyan
    Write-Host ""
}
Write-Host "  Start your VR runtime first, then launch from the Hub with the" -ForegroundColor White
Write-Host "  'Start in VR' button. You can also use the 'Perfect Dark VR'" -ForegroundColor White
Write-Host "  desktop shortcut." -ForegroundColor White
Write-Host ""

try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if (-not $romPlaced) {
    try { Start-Process explorer.exe $dataDir -ErrorAction Stop; Write-Info "Opened the data folder - drop your ROM in and rename it to $ROM_NAME." } catch { }
    Write-Host ""
}

Write-Host "  Joanna Dark goes hands-on - dataDyne never saw it coming." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
