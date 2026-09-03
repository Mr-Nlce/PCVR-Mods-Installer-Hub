# =============================================================
#  Dishonored VR - GingasVR
# =============================================================
# A d3d9.dll proxy over a forked DXVK: true stereo, 6DOF with lean,
# motion controls on Arkane's own animation rig, hand-aimed Blink and
# roomscale walking through the game's own collision.
#
# !!! STEAM ONLY, AND LAUNCHED THROUGH STEAM. The author is explicit
# about both: other stores are not supported at this time, and a direct
# .exe launch crashes at the menu. So this does not offer GOG, Epic or
# the Xbox app even though the game exists there.
#
# WHAT THE ARCHIVE HOLDS (read, not guessed: 16 entries, 4,720,770 B,
# sha256 c0a80a53...20e30 which MATCHES the published one):
#   Binaries\Win32\d3d9.dll          the proxy - this is the switch
#   Binaries\Win32\dxvk_d3d9.dll     the DXVK fork, 10 MB
#   Binaries\Win32\dishonored_vr.ini settings, incl. the lean deadzone
#   Binaries\Win32\openvr_api.dll, steam_appid.txt, dxvk_stereo.txt
#   DishonoredGame\Movies\*.bik      eight stub videos - they replace
#                                    the intro logos and the broken
#                                    prologue cutscene
#   setup_resolution.bat             writes ResX/ResY into the per-user
#                                    DishonoredEngine.ini

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME     = "Dishonored VR"
$MOD_AUTHOR   = "GingasVR"
$REPO         = "GingasVRFO/Dishonored-VR"
$RELEASES_URL = "https://github.com/GingasVRFO/Dishonored-VR/releases"
$INFO_URL     = "https://github.com/GingasVRFO/Dishonored-VR"
$STEAM_APPID  = "205100"
$STEAM_FOLDER = "Dishonored"
$BIN_SUB      = "Binaries\Win32"
$GAME_EXE     = "Dishonored.exe"
$MOD_MARKER   = "Binaries\Win32\dxvk_d3d9.dll"
$PROXY        = "Binaries\Win32\d3d9.dll"
$PROXY_OFF    = "Binaries\Win32\d3d9.dll.flat"
$SETUP_BAT    = "setup_resolution.bat"
$INSTALL_MANIFEST = ".pcvrhub-dishonored-install.tsv"

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x  " -ForegroundColor Black -BackgroundColor Cyan; Write-Host "" }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }
function Pause-FreshEnter {
    param($text = "Press Enter to finish setup and close...")
    # setup_resolution.bat runs in a child console. Discard a key it may have
    # left behind, otherwise the final instructions can disappear at once.
    Start-Sleep -Milliseconds 250
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    try {
        do { $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } while ($key.VirtualKeyCode -ne 13)
    } catch {
        [void](Read-Host)
    }
}

function Find-DishonoredEngineIni {
    param([string]$DocumentsPath = [Environment]::GetFolderPath("MyDocuments"))
    if ([string]::IsNullOrWhiteSpace($DocumentsPath)) { return $null }
    try {
        $settingsRoot = Join-PathLexical $DocumentsPath "My Games\Dishonored"
        if (-not (Test-Path -LiteralPath $settingsRoot -PathType Container)) { return $null }
        $hit = Get-ChildItem -LiteralPath $settingsRoot -Filter "DishonoredEngine.ini" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    } catch {}
    return $null
}

function Install-DishonoredPayloadSafely {
    param(
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$GameRoot
    )
    # The alpha replaces all eight stock intro/cutscene movies and may also
    # collide with an existing d3d9 proxy. Keep each differing pre-install
    # file once as .hubbak, and record whether uninstall should restore or
    # remove every payload path. Reinstalling/updating keeps the first record.
    $manifestPath = Join-PathLexical $GameRoot $INSTALL_MANIFEST
    $ownership = @{}
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        foreach ($line in @(Get-Content -LiteralPath $manifestPath -ErrorAction SilentlyContinue)) {
            $parts = @($line -split "`t", 2)
            if ($parts.Count -eq 2 -and $parts[0] -in @("restore","remove")) { $ownership[$parts[1]] = $parts[0] }
        }
    }

    $sourceBase = $SourceRoot.TrimEnd([char[]]"\/")
    $records = @()
    foreach ($source in @(Get-ChildItem -LiteralPath $sourceBase -File -Recurse -ErrorAction Stop)) {
        $relative = $source.FullName.Substring($sourceBase.Length).TrimStart([char[]]"\/")
        $destination = Join-PathLexical $GameRoot $relative
        $mode = if ($ownership.ContainsKey($relative)) { [string]$ownership[$relative] } else { "" }
        if (-not $mode) {
            if (Test-Path -LiteralPath $destination -PathType Leaf) {
                $same = $false
                try {
                    $same = ((Get-Item -LiteralPath $destination).Length -eq $source.Length) -and
                            ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -eq
                             (Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash)
                } catch {}
                if ($same) {
                    # A previous Hub install may predate the ownership file.
                    $mode = "remove"
                } else {
                    $backup = "$destination.hubbak"
                    if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
                        $backupParent = Split-Path -Parent $backup
                        if (-not (Test-Path -LiteralPath $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
                        Copy-Item -LiteralPath $destination -Destination $backup -ErrorAction Stop
                        if ((Get-Item -LiteralPath $destination).Length -ne (Get-Item -LiteralPath $backup).Length -or
                            (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne
                            (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash) {
                            throw "Backup verification failed for $destination"
                        }
                        Write-Info "Protected existing file: $relative.hubbak"
                    }
                    $mode = "restore"
                }
            } else {
                $mode = "remove"
            }
        }
        $records += ($mode + "`t" + $relative)
    }

    [void](Copy-DirectoryTreeVerified -Source $sourceBase -Destination $GameRoot)
    Set-Content -LiteralPath $manifestPath -Value $records -Encoding UTF8 -Force -ErrorAction Stop
    return $manifestPath
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Dishonored VR  -  by $MOD_AUTHOR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  True stereo, 6DOF with lean and peek, and both hands on" -ForegroundColor White
Write-Host "  Arkane's own animation rig - sword swings, blocking, the power" -ForegroundColor White
Write-Host "  wheel. Blink aims with your hand." -ForegroundColor White
Write-Host ""
Write-Host "  ALPHA, AND IT RENDERS AT 4032x2268. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The author developed it on an RTX 4090 and the game is CPU-bound" -ForegroundColor Gray
Write-Host "  in places. Expect to tune settings." -ForegroundColor Gray
Write-Host ""
Write-Host "  Dishonored should have been started once before this setup so" -ForegroundColor White
Write-Host "  it can create DishonoredEngine.ini. If it is missing, the" -ForegroundColor White
Write-Host "  installer will launch the game once through Steam for you." -ForegroundColor White
Write-Host ""
Show-AntivirusNotice
Pause-User "Press Enter to proceed with setup..."

# ---- 1. The game ---------------------------------------------
Write-Step 1 4 "Finding Dishonored"

# !!! NO GOG, EPIC OR XBOX HERE ON PURPOSE. The game exists on all of
# them, but the author supports Steam alone - and the mod needs the
# Steam launch path to work at all.
$gameRoot = $null
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
    try { $gameRoot = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($STEAM_FOLDER) -ProbeExe "$BIN_SUB\$GAME_EXE" } catch {}
}
if (-not $gameRoot) {
    Write-Warn "No Steam copy of Dishonored found."
    Write-Host "  This mod supports the Steam version only - the author says so" -ForegroundColor White
    Write-Host "  plainly, and it has to be launched through Steam." -ForegroundColor White
    Write-Host ""
    $manual = (Read-Host "  Paste your Dishonored folder (or Enter to exit)").Trim().Trim('"')
    if (-not $manual -or -not (Test-Path -LiteralPath (Join-PathLexical $manual "$BIN_SUB\$GAME_EXE"))) {
        Write-Fail "No usable game folder - nothing was changed."
        Pause-User "Press Enter to exit."
        exit 1
    }
    $gameRoot = $manual.TrimEnd([char[]]"\/")
}
Write-OK "Game folder: $gameRoot"

# setup_resolution.bat edits this per-user file. Check before downloading or
# changing the game so a first-time user can create it in the clean flat game.
$engineIni = Find-DishonoredEngineIni
if (-not $engineIni) {
    Write-Warn "DishonoredEngine.ini does not exist yet."
    Write-Host "  Dishonored will now start once through Steam to create it." -ForegroundColor White
    Write-Host "  When the main menu appears, quit the game from the menu," -ForegroundColor White
    Write-Host "  return to this installer, and continue here." -ForegroundColor White
    Pause-User "Press Enter to launch Dishonored once through Steam..."
    try {
        Start-Process "steam://rungameid/$STEAM_APPID" -ErrorAction Stop
    } catch {
        Write-Fail "Could not start Dishonored through Steam: $($_.Exception.Message)"
        Pause-User "Press Enter to exit."
        exit 1
    }
    Pause-User "Quit Dishonored from its menu, return here, then press Enter to continue..."
    while (@(Get-Process -Name "Dishonored" -ErrorAction SilentlyContinue).Count -gt 0) {
        Write-Warn "Dishonored is still running."
        Pause-User "Close the game, then press Enter to check again..."
    }
    $engineIni = Find-DishonoredEngineIni
    if (-not $engineIni) {
        Write-Fail "DishonoredEngine.ini is still missing, so resolution setup cannot continue safely."
        Write-Do "Start Dishonored through Steam, reach the main menu, quit, then run this installer again."
        Pause-User "Press Enter to exit; nothing was changed."
        exit 1
    }
}
Write-OK "Game config ready: $engineIni"

$proxyOnPath = Join-PathLexical $gameRoot $PROXY
$proxyOffPath = Join-PathLexical $gameRoot $PROXY_OFF
$wasFlat = (Test-Path -LiteralPath $proxyOffPath -PathType Leaf) -and -not (Test-Path -LiteralPath $proxyOnPath -PathType Leaf)
if ((Test-Path -LiteralPath $proxyOffPath -PathType Leaf) -and (Test-Path -LiteralPath $proxyOnPath -PathType Leaf)) {
    Write-Fail "Both d3d9.dll and d3d9.dll.flat exist. The active VR mode is ambiguous."
    Write-Do "Return to Dishonored's page in the Hub, use Uninstall Guide, then reinstall."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 2. Download ---------------------------------------------
Write-Step 2 4 "Getting the mod"

$tmp = Join-PathLexical $env:TEMP ("DishonoredVR_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-PathLexical $tmp "DishonoredVR.zip"

# Prereleases count here - the alpha IS the release.
$dlUrl = $null; $relTag = $null
try {
    $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
                -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25
    foreach ($r in @($rels)) {
        if ($r.draft) { continue }
        $pick = Select-PayloadAsset -Assets $r.assets -PlatformPattern '(?i)dishonored.?vr' -MinBytes 500000
        if ($pick) { $dlUrl = [string]$pick.browser_download_url; $relTag = [string]$r.tag_name; break }
    }
} catch { Write-Warn "Could not read the releases list: $($_.Exception.Message)" }

if (-not $dlUrl) {
    Write-Warn "No release asset found automatically."
    Pause-User "Press Enter to open the releases page..."
    try { Start-Process $RELEASES_URL } catch {}
    Write-Do "Download DishonoredVR-alpha.zip, then drag it in below."
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

# ---- 3. Install ----------------------------------------------
Write-Step 3 4 "Copying into the game"

$ex = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label $MOD_NAME
if ([string]$ex -eq "quit") {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# Everything sits under DishonoredVR-alpha\ - find the marker and work
# from its grandparent, so a re-zip with different nesting still lands.
$probe = Get-ChildItem -LiteralPath $tmp -Filter "dxvk_d3d9.dll" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $probe) {
    Write-Fail "dxvk_d3d9.dll was not in that archive - wrong download?"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$srcRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $probe.FullName))

$requiredPayload = @(
    "Binaries\Win32\d3d9.dll",
    "Binaries\Win32\dxvk_d3d9.dll",
    "Binaries\Win32\dishonored_vr.ini",
    "Binaries\Win32\openvr_api.dll",
    "DishonoredGame\Movies\INTRO_LOC.bik",
    "setup_resolution.bat"
)
$missingPayload = @($requiredPayload | Where-Object { -not (Test-Path -LiteralPath (Join-PathLexical $srcRoot $_) -PathType Leaf) })
if ($missingPayload.Count -gt 0) {
    Write-Fail "The archive is incomplete or its resolution helper is missing."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

try {
    $installManifest = Install-DishonoredPayloadSafely -SourceRoot $srcRoot -GameRoot $gameRoot
} catch {
    Write-Fail "Could not copy the mod: $($_.Exception.Message)"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$markerPath = Join-PathLexical $gameRoot $MOD_MARKER
if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Fail "dxvk_d3d9.dll did not arrive in $gameRoot\$BIN_SUB"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Mod files in place."
Write-Info "Reversible install record: $installManifest"

# An unsigned proxy DLL next to a game exe is what scanners react to.
$survived = Confirm-PlacedFilesSurvive `
    -Paths @($markerPath, (Join-PathLexical $gameRoot $PROXY)) `
    -GameDir $gameRoot `
    -ArchivePath $zip
if (-not $survived) {
    Write-Fail "The Dishonored VR DLLs were removed or quarantined after installation."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# Updating while the user had deliberately selected flat mode must not leave
# both proxy names behind. Preserve the old parked DLL as a dated rollback,
# then park the newly installed proxy under the normal .flat name too.
if ($wasFlat) {
    try {
        $previousFlat = "$proxyOffPath.pre-update-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Move-Item -LiteralPath $proxyOffPath -Destination $previousFlat -ErrorAction Stop
        Move-Item -LiteralPath $proxyOnPath -Destination $proxyOffPath -ErrorAction Stop
        Write-OK "Flat mode was preserved after the update."
        Write-Info "Previous parked proxy: $previousFlat"
    } catch {
        Write-Fail "The files installed, but flat mode could not be preserved: $($_.Exception.Message)"
        Pause-User "Press Enter to exit."
        exit 1
    }
}

# ---- 4. Resolution -------------------------------------------
Write-Step 4 4 "Setting the resolution"

# setup_resolution.bat writes the per-user INI found and verified before any
# mod files were downloaded or copied. The author's helper backs it up first.
Write-Info "Found: $engineIni"
$run = ""
for ($k = 1; $k -le 20; $k++) {
    $run = ("" + (Read-Host "  Apply the recommended 4032x2268 windowed resolution now? [y/n]")).Trim().ToLower()
    if ($run -in @("y","n","yes","no")) { break }
    Write-Host "  Please answer y or n." -ForegroundColor Yellow
}
if ($run -in @("y","yes")) {
    try {
        Start-Process -FilePath (Join-PathLexical $gameRoot $SETUP_BAT) -WorkingDirectory $gameRoot -Wait
        Write-OK "Resolution set to 4032x2268, windowed."
    } catch { Write-Warn "Could not run it: $($_.Exception.Message)" }
} else {
    Write-Do "Resolution setup skipped. Run Install Mod again later to apply it."
}

try {
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force
    if ($relTag) {
        Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force
        Save-InstalledStamp -GameDir $gameRoot -HubDir $PSScriptRoot -Version $relTag
    }
} catch { Write-Warn "Could not save the Hub install record: $($_.Exception.Message)" }
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- Closing -------------------------------------------------
Write-Host ""
Write-Host "  START IN VR FROM THE HUB - OR LAUNCH THROUGH STEAM " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "  The Hub's Start in VR button launches Dishonored through Steam." -ForegroundColor White
Write-Host "  You can also launch it from Steam yourself. Never use the .exe" -ForegroundColor White
Write-Host "  directly: that crashes at the menu - the author says so." -ForegroundColor White
Write-Host ""
Write-Host "   Vive / Index : SteamVR running, then use either launch route." -ForegroundColor White
Write-Host "   Quest        : Virtual Desktop streaming, SteamVR NOT running." -ForegroundColor White
Write-Host "                  VD at 72 Hz, SSW off; use either launch route." -ForegroundColor Gray
Write-Host ""
Write-Host "  F5 recenters and sets your standing height. F10 opens the" -ForegroundColor White
Write-Host "  overlay - mouse only for now. Turn Motion Blur off in the" -ForegroundColor White
Write-Host "  game's video options." -ForegroundColor White
Write-Host ""
Write-Host "  THE FIRST MISSION IS ROUGH IN VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The prologue cutscene is glitched. The mod teleports you to the" -ForegroundColor White
Write-Host "  prison after a few seconds. If you get stuck, return to" -ForegroundColor White
Write-Host "  Dishonored's game detail page in the Hub and use " -NoNewline -ForegroundColor White
Write-Host "VR / Flat" -ForegroundColor Cyan
Write-Host "  to switch to Flat. Play past the opening, quit the game, then" -ForegroundColor White
Write-Host "  use the same Hub switch to turn VR back on." -ForegroundColor White
Write-Host ""
Write-OK "$MOD_NAME installed."
Write-Host ""
Write-Host "  The Outsider has marked your headset. What could possibly go wrong?" -ForegroundColor Magenta
Pause-FreshEnter
