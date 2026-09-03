# ============================================================
#  RETROWAVE 2 VR - UUVR, preconfigured
# ============================================================
#  The mod is a PRECONFIGURED UUVR setup (Raicuparta's Universal
#  Unity VR) - BepInEx plus the Uuvr plugins and a ready-made
#  raicuparta.uuvr-modern.cfg. Nothing is compiled for this game
#  specifically; the value is the configuration.
#
#  !!! THE DOWNLOAD SITS BEHIND A DISCORD LOGIN. It is a message
#  attachment in the Flat2VR Modding server, so it cannot be
#  fetched without an account that has JOINED that server. The
#  installer therefore opens the invite and the post, and then
#  picks the file up from the Downloads folder.
#
#  !!! THE ARCHIVE CARRIES THE AUTHOR'S LEFTOVERS: BepInEx\
#  LogOutput.log and BepInEx\cache\*.dat are runtime state from
#  HIS machine. The cache files in particular are built from the
#  assemblies of a specific install and are rebuilt on first
#  start anyway - copying them over is at best pointless and at
#  worst a stale-cache bug. They are skipped.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Retrowave 2 VR Installer"
$ErrorActionPreference = "Stop"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x" -ForegroundColor Cyan; Write-Host "  ----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$MOD_NAME    = "Retrowave 2 VR"
$STEAM_APPID = "3331000"
$GAME_FOLDER = "Retrowave 2"
$GAME_EXE    = "Retrowave 2.exe"
$MOD_MARKER  = "BepInEx\plugins\Uuvr.dll"

$DISCORD_INVITE_URL   = "https://discord.gg/uAeQkYBM4n"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/747967102895390741/1541093763768782919/1541094326422081566"

# Read from the real archive: 58 entries, BepInEx at the root next to
# winhttp.dll. These two prefixes are what must NOT travel.
$SKIP_PATTERNS = @("BepInEx\LogOutput.log", "BepInEx\cache\")

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Retrowave 2 - VR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  A preconfigured UUVR setup, tuned for this game." -ForegroundColor White
Write-Host ""
Write-Host "  The download sits behind a Discord login." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Find the game ------------------------------------------
Write-Step 1 4 "Finding Retrowave 2"

$gamePath = $null
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
    try { $gamePath = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($GAME_FOLDER) -ProbeExe $GAME_EXE } catch {}
}
if (-not $gamePath -or -not (Test-Path -LiteralPath "$($gamePath.TrimEnd('\'))\$GAME_EXE")) {
    # Only Steam sells this game - there is no Epic, GOG or Store
    # edition to fall back on, so a manual pick is the only other route.
    $gamePath = Get-GameFolderInteractive -GameName "Retrowave 2" -ExeName $GAME_EXE
}
if (-not $gamePath) {
    Write-Fail "No game folder - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gamePath"

# ---- 2. Get the file off Discord -------------------------------
Write-Step 2 4 "Getting the mod from Discord"

# TWO STOPS, ONE THING EACH. The invite and the download are separate
# actions - joining a server and fetching a file - and bundling them
# into one wall of text is how people miss the join and then wonder
# why the link shows nothing.
Write-Host ""
Pause-User "Press Enter to open the Discord invite - join the server, or skip if already done, then come back..." | Out-Null
try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open: $DISCORD_INVITE_URL" }

Write-Host ""
Pause-User "Press Enter to open the download post..." | Out-Null
try { Start-Process $DISCORD_DOWNLOAD_URL } catch { Write-Warn "Could not open: $DISCORD_DOWNLOAD_URL" }

Write-Host ""
Write-Host "  Download the ZIP. Do not unpack it." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter once it is downloaded..." | Out-Null

# THE NAME IS NOT PROOF, THE CONTENT IS. Every zip in Downloads is
# opened and only accepted when it really carries Uuvr.dll - a file
# called "Retrowave2_UUVR.zip" could be anything, and the author may
# rename his upload at any time.
$dl = Join-Path ([Environment]::GetFolderPath('UserProfile')) "Downloads"
$zip = $null
foreach ($c in @(Get-ChildItem -Path $dl -Filter "*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)) {
    if (Test-ArchiveContains -ArchivePath $c.FullName -Entry "Uuvr.dll") { $zip = $c.FullName; break }
}

# Not in Downloads? Then let the user point at it instead of giving up -
# a browser set to "ask where to save" puts it anywhere.
if (-not $zip) {
    Write-Host ""
    Write-Warn "No archive with the mod in it was found in your Downloads folder."
    Write-Host "  Drag the ZIP into this window and press Enter (or press Enter to quit)." -ForegroundColor White
    Write-Host ""
    for ($try = 1; $try -le 10; $try++) {
        $raw = ("" + (Read-Host "  Drop the ZIP here")).Trim().Trim('"').Trim("'")
        if (-not $raw) { break }
        if (-not (Test-Path -LiteralPath $raw)) { Write-Warn "Not found: $raw"; continue }
        if (-not (Test-ArchiveContains -ArchivePath $raw -Entry "Uuvr.dll")) {
            Write-Warn "That archive does not contain the mod (no Uuvr.dll)."
            continue
        }
        $zip = $raw; break
    }
}
if (-not $zip) {
    Write-Fail "No mod archive - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Found: $(Split-Path -Leaf $zip)"

# ---- 3. Unpack and place --------------------------------------
Write-Step 3 4 "Installing the mod files"

$tmp = Join-Path $env:TEMP ("rw2vr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$st = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label $MOD_NAME
if ([string]$st -ne "ok" -and [string]$st -ne "manual") {
    Write-Fail "The archive could not be unpacked."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# Resolve the payload root through a file that must be there, so a
# wrapper folder in a future upload changes nothing.
$srcRoot = $tmp
$probe = Get-ChildItem -LiteralPath $tmp -Recurse -Filter "winhttp.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($probe) { $srcRoot = $probe.DirectoryName }

$copied = 0; $skipped = 0
foreach ($f in @(Get-ChildItem -LiteralPath $srcRoot -Recurse -File -ErrorAction SilentlyContinue)) {
    $rel = $f.FullName.Substring($srcRoot.Length).TrimStart('\')
    $skip = $false
    foreach ($p in $SKIP_PATTERNS) { if ($rel -like "$p*") { $skip = $true; break } }
    if ($skip) { $skipped++; continue }
    $dest = "$($gamePath.TrimEnd('\'))\$rel"
    try {
        $dd = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
        Copy-Item -LiteralPath $f.FullName -Destination $dest -Force -ErrorAction Stop
        $copied++
    } catch { Write-Warn "Could not place $rel : $($_.Exception.Message)" }
}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if (-not (Test-Path -LiteralPath "$($gamePath.TrimEnd('\'))\$MOD_MARKER")) {
    Write-Fail "Uuvr.dll did not arrive in the game folder."
    Pause-User "Press Enter to exit."
    exit 1
}

# !!! THE PACKAGE IS MISSING ITS DOORSTOP CONFIG, AND WITHOUT IT NOTHING
# LOADS AT ALL - no BepInEx console, no log, no F3, nothing.
#
# winhttp.dll is Unity Doorstop. Windows loads it with the game, but the
# only thing it does on its own is read doorstop_config.ini. No ini, no
# instruction to load BepInEx, so the DLL sits there doing nothing and
# the game runs exactly as if the mod were not installed.
#
# Every other BepInEx package in this Hub (Away, MFNVR, MousePI - all the
# same 26,112-byte doorstop 4.5.0) ships that ini. This one does not, so
# it is written here.
#
# The target assembly is NOT guessed: the preloader that is actually on
# disk decides, because Mono and IL2CPP builds use different ones.
$dsIni = Join-Path $gamePath "doorstop_config.ini"
if (-not (Test-Path -LiteralPath $dsIni)) {
    $coreDir = Join-Path $gamePath "BepInEx\core"
    $target  = $null
    foreach ($cand in @("BepInEx.Preloader.dll", "BepInEx.Unity.IL2CPP.dll", "BepInEx.IL2CPP.dll", "BepInEx.Preloader.Unity.dll")) {
        if (Test-Path -LiteralPath (Join-Path $coreDir $cand)) { $target = "BepInEx\core\$cand"; break }
    }
    if (-not $target) {
        Write-Warn "No BepInEx preloader found in BepInEx\core - cannot write doorstop_config.ini."
    } else {
        $ini = @"
# General options for Unity Doorstop
[General]

# Enable Doorstop?
enabled = true

# Path to the assembly to load and execute
target_assembly=$target

# If true, Unity's output log is redirected to <current folder>\output_log.txt
redirect_output_log = false

# Overrides the default boot.config file path
boot_config_override =

# If enabled, DOORSTOP_DISABLE env var value is ignored
ignore_disable_switch = false

# Options specific to running under Unity Mono runtime
[UnityMono]

# Overrides default Mono DLL search path
dll_search_path_override =

# If true, Mono debugger server will be enabled
debug_enabled = false

# When debug_enabled is true, specifies the address to use for the debugger server
debug_address = 127.0.0.1:10000

# If true and debug_enabled is true, Mono debugger server will suspend the game
debug_suspend = false
"@
        try {
            Set-Content -LiteralPath $dsIni -Value $ini -Encoding ASCII -Force
            Write-OK "Wrote the missing doorstop_config.ini (target: $target)."
        } catch { Write-Warn "Could not write doorstop_config.ini : $($_.Exception.Message)" }
    }
    # Doorstop 4.5 also looks for this next to the game.
    $dsVer = Join-Path $gamePath ".doorstop_version"
    if (-not (Test-Path -LiteralPath $dsVer)) {
        try { Set-Content -LiteralPath $dsVer -Value "4.5.0" -Encoding ASCII -Force -NoNewline } catch {}
    }
}
Write-OK "$copied file(s) placed, $skipped leftover file(s) skipped."

# ---- 4. Done ---------------------------------------------------
Write-Step 4 4 "Finished"
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   HOW TO PLAY" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Start your VR RUNTIME first - before the game." -ForegroundColor White
Write-Host "  2. Launch Retrowave 2 as usual, from Steam." -ForegroundColor White
Write-Host "  3. In the game, press these two - EVERY session:" -ForegroundColor White
Write-Host ""
Write-Host "        F3 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  turns VR ON. The game starts FLAT." -ForegroundColor White
Write-Host ""
Write-Host "        F5 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  shows the game's UI in VR." -ForegroundColor White
Write-Host ""
Write-Host "     UUVR does not switch itself on, and does not remember" -ForegroundColor Gray
Write-Host "     that you did it last time." -ForegroundColor Gray
Write-Host ""
Write-Host "  If F3 does nothing, the runtime was not running when the game" -ForegroundColor Gray
Write-Host "  started. Close it, start the runtime, launch again." -ForegroundColor Gray
Write-Host ""
Write-Host "  A GAMEPAD IS THE WAY TO PLAY THIS. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "   - Xbox pads are often NOT seen over Bluetooth. Plug the" -ForegroundColor White
Write-Host "     pad in with a USB cable and it works." -ForegroundColor White
Write-Host "   - " -NoNewline -ForegroundColor White
Write-Host "Y" -NoNewline -ForegroundColor Black -BackgroundColor Cyan
Write-Host " switches the view while driving - including the" -ForegroundColor White
Write-Host "     steering wheel view." -ForegroundColor White
Write-Host "   - The MENUS take the ARROW KEYS, not the pad. The game" -ForegroundColor White
Write-Host "     has no controller support there." -ForegroundColor White
Write-Host ""
Write-Host "  Preconfigured by Jean-Francois, built on UUVR by" -ForegroundColor Gray
Write-Host "  Raicuparta." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
