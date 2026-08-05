# ============================================================
#  S.T.A.L.K.E.R. GAMMA VR ("Anomaly Gamma") Installer
# ============================================================
# A complete GAMMA VR package (based on Anomaly). The user grabs the
# either the complete "STALKER GAMMA VR v0.3.2.7z" or the small
# "UPDATE FROM v0.3.1 TO v0.3.2c.7z" - which one is offered first depends on
# whether an install already sits in the chosen folder
# from the mod's Discord (same server as
# Anomaly VR) and drags it in. We extract its "Gamma VR" folder into
# a Games root (-> <root>\Gamma VR), switch the language to English,
# drop the game icon, and make a desktop shortcut to GAMMA VR.bat.
# Nothing is bundled except the small game icon.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_TITLE           = "Anomaly Gamma"
$LAUNCH_BAT           = "GAMMA VR.bat"
$MOD_FOLDER           = "Gamma VR"          # folder name inside the .7z
$DEFAULT_ROOTS        = @("C:\Games", "D:\Games", "E:\Games")
$ICON_SRC             = Join-Path $PSScriptRoot "GammaVR.ico"
$DISCORD_INVITE_URL   = "https://discord.gg/kGhd7GvJ5F"
# TWO posts, and both link into the SAME gofile folder - so the file the
# user has to pick is what actually matters. Naming the exact archive is
# the whole point of the branch below.
$POST_FULL_URL        = "https://discord.com/channels/1495664880311734313/1511657141990199356/1530927349837861106"
$POST_UPDATE_URL      = "https://discord.com/channels/1495664880311734313/1511657141990199356/1532382868238766203"
$FILE_FULL            = "STALKER GAMMA VR v0.3.2.7z"
$FILE_UPDATE          = "UPDATE FROM v0.3.1 TO v0.3.2c.7z"

# ---- console helpers ----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  S.T.A.L.K.E.R. GAMMA VR Installer" -ForegroundColor Cyan
    Write-Host "  Anomaly Gamma - complete package, motion controls" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "[$n/$t] $txt" -ForegroundColor Cyan; Write-Host "----------------------------------------" -ForegroundColor DarkGray }
function Write-Do   { param($m) Write-Host "  >> $m" -ForegroundColor Yellow }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "     $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host "  >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

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

function Find-7Zip {
    # Return an existing 7z.exe, or download + silently install 7-Zip if
    # it is missing (the pack ships as a .7z, which PowerShell cannot open).
    $cands = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")
    foreach ($p in $cands) { if (Test-Path $p) { return $p } }
    try { $c = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source; if ($c) { return $c } } catch {}
    Write-Warn "7-Zip is required to unpack the .7z and is not installed."
    Pause-User "Press Enter to download + install 7-Zip (silent - accept the UAC prompt)..."
    $inst = Join-Path $env:TEMP "7z-setup.exe"
    try {
        Invoke-WebRequest -Uri "https://7-zip.org/a/7z2501-x64.exe" -OutFile $inst -UseBasicParsing
        Start-Process -FilePath $inst -ArgumentList "/S" -Verb RunAs -Wait
        Remove-Item $inst -Force -ErrorAction SilentlyContinue
    } catch { Write-Warn "7-Zip install failed: $($_.Exception.Message)" }
    foreach ($p in $cands) { if (Test-Path $p) { return $p } }
    try { $c = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source; if ($c) { return $c } } catch {}
    return $null
}

# Extract with 7-Zip's NATIVE progress (accurate %), but redirect its
# stdout to a temp file so the noisy "NN - filename" lines never reach the
# console. We poll the file and print ONLY the percentage + elapsed timer.
function Invoke-SevenZipExtract {
    param([string]$SevenZip, [string]$Archive, [string]$Dest)
    $progFile = Join-Path ([System.IO.Path]::GetTempPath()) ("7zp_" + [Guid]::NewGuid().ToString("N") + ".log")
    $proc = Start-Process -FilePath $SevenZip `
        -ArgumentList "x","-y","-bso0","-bsp1","`"$Archive`"","-o`"$Dest`"" `
        -PassThru -NoNewWindow -RedirectStandardOutput $progFile
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pct = 0
    while (-not $proc.HasExited) {
        Start-Sleep -Milliseconds 500
        try {
            $fs = [System.IO.File]::Open($progFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $sr = New-Object System.IO.StreamReader($fs)
            $txt = $sr.ReadToEnd()
            $sr.Close(); $fs.Close()
            $mm = [regex]::Matches($txt, '(\d+)%')
            if ($mm.Count -gt 0) { $pct = [int]$mm[$mm.Count - 1].Groups[1].Value }
        } catch { }
        $el = $sw.Elapsed.ToString('mm\:ss')
        Write-Host ("`r  Extracting... {0,3}%   {1} elapsed        " -f $pct, $el) -NoNewline -ForegroundColor Gray
    }
    Write-Host "`r  Extracting... 100%   done                        " -ForegroundColor Gray
    Remove-Item $progFile -Force -ErrorAction SilentlyContinue
}

Write-Header

# -------------------------------------------------------
# STEP 1: where GAMMA VR lives (fresh install target OR existing install)
# -------------------------------------------------------
Write-Host " A motion-controlled VR build of S.T.A.L.K.E.R. GAMMA, the large curated" -ForegroundColor White
Write-Host " Anomaly modpack. GAMMA is a complete standalone package - it includes" -ForegroundColor White
Write-Host " everything; no separate Anomaly or game install is needed." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 5 "Where GAMMA VR lives"
Write-Host "  If you already have GAMMA VR, point this at the folder holding it." -ForegroundColor White
Write-Host "  If not, this is where it gets installed." -ForegroundColor White
Write-Host ""
Write-Host "  Default: C:\Games\$MOD_FOLDER - press Enter to take it, or type another folder." -ForegroundColor Gray
Write-Host "  (C:\Games keeps it away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host "  A fresh install needs at least 110 GB of free space." -ForegroundColor Yellow
Write-Host "  If you type a custom path, the mod authors recommend a folder WITHOUT spaces." -ForegroundColor DarkGray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$gamesRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $gamesRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $gamesRoot) {
    foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $gamesRoot = [string]$r; break } }
}
if (-not $gamesRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    while (-not $gamesRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $gamesRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $gamesRoot"
$installPath = Join-Path $gamesRoot $MOD_FOLDER
$hasOld = Test-Path (Join-Path $installPath $LAUNCH_BAT)
if ($hasOld) { Write-OK "GAMMA VR is already installed in: $installPath" }
else         { Write-Info "GAMMA VR will live in: $installPath" }

# -------------------------------------------------------
# STEP 2: Discord join + download (same server as Anomaly)
# -------------------------------------------------------
Write-Step 2 5 $(if ($hasOld) { "Get the update archive" } else { "Get the GAMMA VR package" })

# The installed state decides what is offered FIRST and what the plain Enter
# does. Someone who already has GAMMA in this folder wants the small update
# in practically every case - a second full copy of the same 110 GB build
# would be pointless - so the update leads, highlighted, and the full build
# stays available underneath without competing for attention.
if ($hasOld) {
    Write-Host "  You already have GAMMA VR here, so you probably want the UPDATE archive." -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] UPDATE to GAMMA VR v0.3.2c" -ForegroundColor Green
    Write-Host "        Download exactly this file:" -ForegroundColor Gray
    Write-Host "         $FILE_UPDATE " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "    [2] Install the complete build again from scratch (about 110 GB)" -ForegroundColor DarkGray
    Write-Host "        Only if your install is broken and you want to start over." -ForegroundColor DarkGray
} else {
    Write-Host "  No GAMMA VR install was found here, so you probably want the COMPLETE build." -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] COMPLETE build of GAMMA VR v0.3.2 - about 110 GB" -ForegroundColor Green
    Write-Host "        Download exactly this file:" -ForegroundColor Gray
    Write-Host "         $FILE_FULL " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "    [2] Update an existing v0.3.1 that lives somewhere else" -ForegroundColor DarkGray
    Write-Host "        Only if you already have GAMMA VR in a different folder." -ForegroundColor DarkGray
}
Write-Host ""
$mode = ""
while ($mode -ne "1" -and $mode -ne "2") {
    $mode = (Read-Host "  Press Enter for [1], or type 2").Trim()
    if ($mode -eq "") { $mode = "1" }
    if ($mode -ne "1" -and $mode -ne "2") { Write-Warn "Please press Enter or type 1 or 2." }
}
# [1] is always the recommended route, so what it MEANS flips with $hasOld.
$isUpdate  = if ($hasOld) { ($mode -eq "1") } else { ($mode -eq "2") }
$wantFile  = if ($isUpdate) { $FILE_UPDATE } else { $FILE_FULL }
$wantPost  = if ($isUpdate) { $POST_UPDATE_URL } else { $POST_FULL_URL }
$wantLabel = if ($isUpdate) { "update archive" } else { "complete build" }

if ($isUpdate -and -not $hasOld) {
    Write-Warn "No install was found in $installPath - the update can only go on top of an existing one."
    Write-Info "If yours sits elsewhere, restart the installer and enter that folder in step 1."
}

Write-Host ""
Write-Host "  The download is on the mod's Discord (same server as Anomaly VR)." -ForegroundColor White
Write-Do  "Join the server. If you are already a member, still press Enter - just skip the joining."
Pause-User "Press Enter to open the Discord invite..."
try { Start-Process $DISCORD_INVITE_URL } catch { Write-Info $DISCORD_INVITE_URL }
Write-Host ""
Write-Host "  Both archives sit in the same download folder. Take this one:" -ForegroundColor White
Write-Host "   $wantFile " -ForegroundColor Black -BackgroundColor Yellow
Pause-User "Press Enter to open the download post..."
try { Start-Process $wantPost } catch { Write-Info "$wantPost (must be a server member)" }

# -------------------------------------------------------
# STEP 3: drag the .7z + extract into the Games root
# -------------------------------------------------------
Write-Step 3 5 $(if ($isUpdate) { "Apply the update to $installPath" } else { "Extract into $gamesRoot" })
Write-Do  "Drag the downloaded file here (or paste its path), then Enter:"
Write-Host "   $wantFile " -ForegroundColor Black -BackgroundColor Yellow
$arc = $null
while (-not $arc) {
    $r = (Read-Host "  Archive").Trim().Trim('"').Trim("'")
    if (-not $r) { Write-Warn "No archive provided - cannot continue."; Pause-User "Press Enter to exit..."; return }
    if (-not (Test-Path -LiteralPath $r)) { Write-Fail "Not found: $r"; continue }
    $leaf  = Split-Path $r -Leaf
    $other = if ($isUpdate) { $FILE_FULL } else { $FILE_UPDATE }
    if ($leaf -ieq $other) {
        Write-Warn "That is the other archive: $leaf"
        Write-Info "You picked the $wantLabel, which is: $wantFile"
        $go = (Read-Host "  Use the dropped file anyway? (y/N)").Trim()
        if ($go -notmatch '^(?i)y') { continue }
    }
    $arc = $r
}
try { New-Item -ItemType Directory -Force -Path $gamesRoot | Out-Null } catch {}
$sevenZip = Find-7Zip
$extracted = $false
if ($sevenZip) {
    if ($isUpdate) { Write-Info "Applying the update over the existing install, replacing files..." }
    else           { Write-Info "Extracting the complete build with 7-Zip - 110 GB, give it time..." }
    try {
        Invoke-SevenZipExtract -SevenZip $sevenZip -Archive $arc -Dest $gamesRoot
        if (Test-Path (Join-Path $installPath $LAUNCH_BAT)) { $extracted = $true }
    } catch { Write-Warn "7-Zip extraction failed: $($_.Exception.Message)" }
}
if (-not $extracted) {
    Write-Warn "Could not auto-extract (7-Zip missing, or the archive layout differs)."
    if ($isUpdate) {
        Write-Do  "Extract the archive over your existing install in: $gamesRoot"
        Write-Info "Agree to replace files. Afterwards this must still exist: $installPath\$LAUNCH_BAT"
    } else {
        Write-Do  "Extract the '$MOD_FOLDER' folder from the archive into: $gamesRoot"
        Write-Info "So that this exists: $installPath\$LAUNCH_BAT"
    }
    try { Start-Process (Split-Path -Parent $arc) } catch {}
    try { Start-Process $gamesRoot } catch {}
    if ($isUpdate) { Pause-User "Press Enter once the update is unpacked over $installPath..." }
    else           { Pause-User "Press Enter once '$MOD_FOLDER' is extracted into $gamesRoot..." }
    if (Test-Path (Join-Path $installPath $LAUNCH_BAT)) { $extracted = $true }
}
if ($extracted) {
    if ($isUpdate) { Write-OK "Update applied to: $installPath" }
    else           { Write-OK "GAMMA VR is in: $installPath" }
}
else {
    if ($isUpdate) { Write-Fail "$LAUNCH_BAT is not under $installPath - the update was not applied to an install." }
    else           { Write-Fail "$LAUNCH_BAT not found under $installPath - extraction incomplete." }
    Pause-User "Press Enter to exit..."; return
}

# The update ships new weapon shaders, and the engine would keep serving the
# compiled ones. The mod author calls deleting this folder mandatory, so the
# installer does it instead of asking. The folder name is searched rather than
# assumed, because the appdata folder sits under the install root and its
# parent has been named differently across builds.
if ($isUpdate) {
    $cacheHits = @()
    try {
        $cacheHits = @(Get-ChildItem -LiteralPath $installPath -Directory -Recurse -Depth 3 -Filter "shaders_cache" -ErrorAction SilentlyContinue |
                       Where-Object { $_.Parent.Name -ieq "appdata" })
    } catch {}
    if ($cacheHits.Count -gt 0) {
        foreach ($h in $cacheHits) {
            try { Remove-Item -LiteralPath $h.FullName -Recurse -Force -ErrorAction Stop; Write-OK "Cleared shader cache: $($h.FullName)" }
            catch { Write-Warn "Could not delete $($h.FullName) - delete it by hand before playing." }
        }
    } else {
        Write-Warn "No appdata\shaders_cache folder found - if the game looks broken after the update,"
        Write-Info "delete the 'shaders_cache' folder inside the 'appdata' folder of your GAMMA install."
    }
}

# -------------------------------------------------------
# STEP 4: language -> English + game icon
# -------------------------------------------------------
Write-Step 4 5 "Set language to English + icon"
$loc = Join-Path $installPath "overwrite\gamedata\configs\localization.ltx"
if (Test-Path -LiteralPath $loc) {
    try {
        # Byte-preserving edit: read with Latin1 (each byte -> one char, 1:1),
        # swap ONLY "rus" -> "eng" on the language line, then write the exact
        # bytes back. This never adds a BOM or re-encodes the file - the X-Ray
        # engine rejects a BOM here (fatal error: Can't open section 'string_table').
        $enc  = [System.Text.Encoding]::GetEncoding(28591)
        $txt  = $enc.GetString([System.IO.File]::ReadAllBytes($loc))
        $txt2 = $txt -replace '(?m)^(\s*language\s*=\s*)rus\b', '${1}eng'
        [System.IO.File]::WriteAllBytes($loc, $enc.GetBytes($txt2))
        Write-OK "Language set to English (localization.ltx)."
    } catch { Write-Warn "Could not edit localization.ltx - set 'language = eng' by hand (plain text, no BOM)." }
} else {
    Write-Warn "localization.ltx not found - if the game starts in Russian, change it in-game:"
    Write-Info "Open the 4th item in the main menu, then the second-to-last item in that list;"
    Write-Info "the language option is at the top-right. (Or set 'language = eng' in the .ltx.)"
}
$iconDest = Join-Path $installPath "GammaVR.ico"
if (Test-Path $ICON_SRC) { try { Copy-Item -LiteralPath $ICON_SRC -Destination $iconDest -Force } catch {} }

# -------------------------------------------------------
# STEP 5: desktop shortcut + record
# -------------------------------------------------------
Write-Step 5 5 "Desktop shortcut"
$launchPath = Join-Path $installPath $LAUNCH_BAT
$iconArg = if (Test-Path $iconDest) { $iconDest } else { "$launchPath,0" }
$lnkPath = "$env:USERPROFILE\Desktop\Anomaly Gamma.lnk"
# On the update route the shortcut is nearly always there already.
$lnkExisted = Test-Path -LiteralPath $lnkPath
try {
    $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $launchPath -WorkingDir $installPath -IconPath $iconArg
    if ($lnkExisted) { Write-OK "Desktop shortcut 'Anomaly Gamma' exists." }
    else             { Write-OK "Desktop shortcut 'Anomaly Gamma' created." }
} catch { Write-Warn "Could not create the shortcut - launch '$launchPath' yourself." }
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installPath -Encoding UTF8 -Force } catch {}
# Version stamp IN THE GAME FOLDER. The pack carries no version anywhere on
# disk, and file dates inside the archives do not match their release - so
# without this the Hub can only guess from timestamps and keeps offering an
# update that is already installed. The catalog compares this file.
try { Set-Content -Path (Join-Path $installPath "gamma_vr_version.txt") -Value "0.3.2c" -Encoding ASCII -Force } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host $(if ($isUpdate) { "  Updated to v0.3.2c. Launch via the desktop shortcut or the Hub's Start in VR." }
             else { "  Done. Launch via the desktop shortcut or the Hub's Start in VR." }) -ForegroundColor Green
Write-Host "  On launch, VR stays BLACK for 10-15s while it loads - that is" -ForegroundColor Gray
Write-Host "  normal, and the same happens during in-game loading screens." -ForegroundColor Gray
Write-Host "  If something goes wrong, you will hear an error sound." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Into the Zone, stalker - GAMMA and all. The atom hums." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
