# ============================================================
#  Ghost Recon Wildlands VR - Installer (GRW-XR by Firejumper93)
# ============================================================
#  EARLY ALPHA. Stereo depth, head tracking and a fullscreen view
#  work; there are NO motion controls, aiming still follows the flat
#  game's own aim, and the image is soft because the mod captures the
#  game's 1080p output. The catalog carries a Notice saying exactly
#  that, and the title is in $global:WIP_GAME_TITLES.
#
#  HOW IT ATTACHES: a dxgi.dll search-order proxy next to GRW.exe.
#  No game file is ever modified. Three files go into the game folder
#  plus one config:
#    dxgi.dll           the mod
#    openxr_loader.dll  Khronos loader, shipped with the release
#    dxgi_real.dll      a LOCAL COPY OF THE USER'S OWN
#                       C:\Windows\System32\dxgi.dll, used for export
#                       forwarding. It must come from Windows, never
#                       from the archive - that is what the mod's own
#                       install.bat does too.
#    GRWVR\grwxr.cfg    tuning defaults, only if the user has none yet
#
#  LAUNCH: normally through Steam - the proxy loads by itself, there is
#  no launcher exe. Only a non-Steam copy gets a .launch_exe marker and
#  a desktop shortcut pointing at GRW.exe.
#
#  RELEASES are alphas (v0.7.0-alpha as of 2026-08-08), so the newest
#  release is taken from /releases and NOT /releases/latest, which skips
#  prereleases. Nothing to bump here - the newest build arrives by itself.
#
#  AS OF 0.7.0-alpha, "The Update Update": Ubisoft's "Last Rites" patch
#  (August 2026) replaced GRW.exe, so older mod builds only ran flat -
#  the mod does not touch an exe it does not recognise. 0.7.0 rederived
#  every engine offset against the new exe. NEW WITH IT: Steam and
#  Ubisoft Connect now ship a BYTE-IDENTICAL exe and one offset table
#  covers both stores - the Steam-only caveat from 0.5.0 no longer
#  applies.
#
#  ANTI-CHEAT: the game ships Easy Anti-Cheat for multiplayer. The mod
#  is SOLO CAMPAIGN ONLY and that warning is repeated on the end screen.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ghost Recon Wildlands VR Installer"

$MOD_NAME   = "GRW-XR"
$MOD_AUTHOR = "Firejumper93"

$GAME_APPID = "460930"
$GAME_EXE   = "GRW.exe"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$REPO         = "Firejumper93/GhostReconWildlandsVR"
$RELEASES_API = "https://api.github.com/repos/$REPO/releases"
$RELEASES_URL = "https://github.com/$REPO/releases"

$MOD_FILE   = "dxgi.dll"
$LOADER     = "openxr_loader.dll"
$REAL_PROXY = "dxgi_real.dll"
$CFG_REL    = "GRWVR\grwxr.cfg"
# Slider editor for grwxr.cfg, shipped in the release package.
# Optional: if a package lacks it, it is silently skipped.
$CFG_GUI    = "cfg_gui.exe"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Ghost Recon Wildlands VR - Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$n, [int]$t, [string]$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!]  $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [X]  $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-GRWRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $Root)) { return $false }
        return (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $GAME_EXE)))
    } catch { return $false }
}

# Architecture of a PE file, straight from its header: 0x8664 = 64-bit,
# 0x014C = 32-bit. Needed because dxgi_real.dll MUST have the same
# bitness as the game, or the proxy cannot load and the game dies
# silently at launch - no window, no error.
function Get-PEMachine {
    param([string]$Path)
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $br = New-Object System.IO.BinaryReader($fs)
            $fs.Position = 0x3C
            $peOff = $br.ReadInt32()
            $fs.Position = $peOff
            if ($br.ReadUInt32() -ne 0x00004550) { return 0 }   # "PE\0\0"
            return [int]$br.ReadUInt16()
        } finally { $fs.Dispose() }
    } catch { return 0 }
}

# The system folder holding DLLs of the SAME bitness as $Machine.
# The trap: a 32-bit PowerShell sees C:\Windows\System32 redirected to
# SysWOW64 by WOW64, so hardcoding "System32" hands out a 32-bit DLL for
# a 64-bit game. Sysnative is the unredirected view and only exists for
# a 32-bit process, which is exactly when it is needed.
function Get-SystemDllPath {
    param([int]$Machine, [string]$Name)
    $is64Proc = [Environment]::Is64BitProcess
    $cands = @()
    if ($Machine -eq 0x8664) {
        if ($is64Proc) { $cands += [System.IO.Path]::Combine($env:WINDIR, "System32") }
        else           { $cands += [System.IO.Path]::Combine($env:WINDIR, "Sysnative") }
    } else {
        if ([Environment]::Is64BitOperatingSystem) { $cands += [System.IO.Path]::Combine($env:WINDIR, "SysWOW64") }
        else                                       { $cands += [System.IO.Path]::Combine($env:WINDIR, "System32") }
    }
    foreach ($c in $cands) {
        $full = [System.IO.Path]::Combine($c, $Name)
        if (Test-Path -LiteralPath $full) { return $full }
    }
    return $null
}

# Newest release INCLUDING alphas. /releases/latest would skip a
# prerelease, and every build of this mod so far is one.
function Get-NewestRelease {
    try {
        $rels = Invoke-RestMethod -Uri $RELEASES_API -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
        $rel = $rels | Select-Object -First 1
        if (-not $rel) { return $null }
        $asset = $rel.assets | Where-Object { $_.name -like "*.zip" -and $_.name -notlike "*source*" } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 }
        if (-not $asset) { return $null }
        return [pscustomobject]@{ Tag = $rel.tag_name; Url = $asset.browser_download_url; Name = $asset.name }
    } catch { return $null }
}

Write-Header
Write-Host " GRW-XR renders Ghost Recon Wildlands in real stereoscopic 3D" -ForegroundColor White
Write-Host " with head tracking, through the game's own engine." -ForegroundColor White
Write-Host ""
Write-Host " This is an EARLY ALPHA. Working today: stereo depth, head" -ForegroundColor Yellow
Write-Host " tracking, a fullscreen view, working scopes and a first-person" -ForegroundColor Yellow
Write-Host " demo mode. NOT there yet: motion controls - you aim with the" -ForegroundColor Yellow
Write-Host " gamepad exactly as in the flat game - and the image is soft." -ForegroundColor Yellow
Write-Host ""
Write-Host " No game file is ever modified. The mod sits next to the exe" -ForegroundColor Gray
Write-Host " and can be switched off by renaming one file." -ForegroundColor Gray
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
#  STEP 1: locate the game
# -------------------------------------------------------
Write-Step 1 3 "Locating Ghost Recon Wildlands"

$gamePath = $null
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
    $gamePath = Find-SteamGameFolder -AppId $GAME_APPID `
        -SteamFolderNames @("Wildlands", "Tom Clancy's Ghost Recon Wildlands") `
        -ProbeExe $GAME_EXE `
        -EpicNames @("GhostReconWildlands")
    if ($gamePath -and -not (Test-GRWRoot -Root $gamePath)) { $gamePath = $null }
}
# Ubisoft Connect and Epic keep the game elsewhere. Since 0.7.0-alpha
# the Ubisoft Connect copy is explicitly covered (byte-identical exe to
# Steam), so it is searched there just the same.
if (-not $gamePath) {
    $candidates = @()
    foreach ($d in @("C:", "D:", "E:")) {
        $candidates += "$d\Steam\steamapps\common\Wildlands"
        $candidates += "$d\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy's Ghost Recon Wildlands"
        $candidates += "$d\Program Files\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy's Ghost Recon Wildlands"
        $candidates += "$d\Program Files\Epic Games\GhostReconWildlands"
        $candidates += "$d\Program Files (x86)\Epic Games\GhostReconWildlands"
        $candidates += "$d\Games\Wildlands"
        $candidates += "$d\Wildlands"
    }
    foreach ($c in $candidates) { if (Test-GRWRoot -Root $c) { $gamePath = $c; break } }
}
if (-not $gamePath) {
    $rec = $null
    try { $rec = Get-Content -LiteralPath (Join-Path $SCRIPT_DIR ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
    if ($rec) { $rec = $rec.Trim() }
    if (Test-GRWRoot -Root $rec) { $gamePath = $rec }
}
while (-not $gamePath) {
    Write-Warn "Could not find Ghost Recon Wildlands automatically."
    Write-Host " Drag & drop the game folder onto this window - the one that" -ForegroundColor White
    Write-Host " contains $GAME_EXE - then press Enter." -ForegroundColor White
    Write-Host " In Steam: right-click the game > Manage > Browse local files." -ForegroundColor Gray
    Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host " Game folder").Trim().Trim('"').Trim("'")
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-GRWRoot -Root $raw) { $gamePath = $raw }
    else { Write-Fail "$GAME_EXE is not in that folder." }
}
Write-OK "Found: $gamePath"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile $MOD_FILE -Label "GRW-XR"

# The game must be closed - the proxy DLL is loaded while it runs.
try {
    $running = Get-Process -Name "GRW" -ErrorAction SilentlyContinue
    if ($running) {
        Write-Warn "Ghost Recon Wildlands is running. Close it, then continue."
        Pause-User "Press Enter once the game is closed..." | Out-Null
    }
} catch {}

# -------------------------------------------------------
#  STEP 2: download the newest alpha
# -------------------------------------------------------
Write-Step 2 3 "Downloading $MOD_NAME"

$work = Join-Path $env:TEMP ("grwxr_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$zipPath = Join-Path $work "GRW-XR.zip"
$relTag  = $null

$rel = Get-NewestRelease
if ($rel) {
    $relTag = $rel.Tag
    Write-Info "Newest release: $($rel.Tag)"
    Invoke-SafeDownload -Urls @($rel.Url) -Destination $zipPath -Label "$MOD_NAME $($rel.Tag)" -ManualUrl $RELEASES_URL | Out-Null
}
if (-not (Test-Path -LiteralPath $zipPath)) {
    $found = Find-PredownloadedFile -Patterns @("*GRW-XR*.zip", "*GhostRecon*VR*.zip", "*Wildlands*VR*.zip") -Label "the GRW-XR package"
    if ($found) { Copy-Item -LiteralPath $found -Destination $zipPath -Force }
}
while (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Warn "Automatic download did not work."
    Pause-User "Press Enter to open the releases page..." | Out-Null
    try { Start-Process $RELEASES_URL } catch { Write-Warn "Open manually: $RELEASES_URL" }
    $raw = (Read-Host " Drag the downloaded ZIP here (empty to exit)").Trim().Trim('"').Trim("'")
    if (-not $raw) { Write-Fail "Nothing to install."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-Path -LiteralPath $raw) { Copy-Item -LiteralPath $raw -Destination $zipPath -Force }
    else { Write-Fail "File not found: $raw" }
}

# -------------------------------------------------------
#  STEP 3: install next to the game exe
# -------------------------------------------------------
Write-Step 3 3 "Installing the mod"

$extract = Join-Path $work "extracted"
New-Item -ItemType Directory -Path $extract -Force | Out-Null
try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not extract the archive: $($_.Exception.Message)"
    $fb = Invoke-InstallerFallback -Action "extracting the mod archive" `
        -Instructions "Open '$zipPath' and extract everything into '$extract'. Then choose Retry." `
        -SkipMessage "Skipped - nothing was installed." `
        -SourceFolder (Split-Path -Parent $zipPath) -DestFolder $extract -AllowSkip $true
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit." | Out-Null; exit 1 }
}

$srcRoot = $extract
$hit = $null
try { $hit = Get-ChildItem -LiteralPath $extract -Filter $MOD_FILE -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
if ($hit) { $srcRoot = $hit.DirectoryName }
else {
    Write-Fail "$MOD_FILE was not in the archive - wrong file, or the package layout changed."
    Pause-User "Press Enter to exit." | Out-Null; exit 1
}

# The two mod DLLs. A pre-existing dxgi.dll (ReShade, another wrapper)
# is backed up once as .hubbak before it is replaced.
$copied = 0
foreach ($f in @($MOD_FILE, $LOADER)) {
    $src = [System.IO.Path]::Combine($srcRoot, $f)
    if (-not (Test-Path -LiteralPath $src)) { continue }
    $dest = [System.IO.Path]::Combine($gamePath, $f)
    try {
        if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
            Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
            Write-Info "Kept your existing $f as $f.hubbak"
        }
        Copy-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
        $copied++
    } catch { Write-Fail "Could not write $f`: $($_.Exception.Message)" }
}

# dxgi_real.dll is the export-forwarding target and MUST be the user's
# own Windows DLL, not anything from the archive. Never overwritten -
# an existing one is already a valid local copy.
$realDest = [System.IO.Path]::Combine($gamePath, $REAL_PROXY)
# Bitness must match the GAME, not this script. Ghost Recon Wildlands is
# 64-bit; handing it a 32-bit dxgi_real.dll makes the proxy fail to load
# and the game exits instantly with no window and no message.
$gameMachine = Get-PEMachine -Path ([System.IO.Path]::Combine($gamePath, $GAME_EXE))
$archName = if ($gameMachine -eq 0x8664) { "64-bit" } elseif ($gameMachine -eq 0x14C) { "32-bit" } else { "unknown" }

# A dxgi_real.dll left over from an earlier run may have the WRONG
# bitness (this installer used to take it from whichever system folder
# the script itself saw). Check what is there and replace it if it does
# not match the game.
if (Test-Path -LiteralPath $realDest) {
    $haveMachine = Get-PEMachine -Path $realDest
    if ($gameMachine -ne 0 -and $haveMachine -ne 0 -and $haveMachine -ne $gameMachine) {
        Write-Warn "The existing $REAL_PROXY is the wrong architecture - replacing it."
        try { Remove-Item -LiteralPath $realDest -Force -ErrorAction Stop } catch {}
    }
}

if (-not (Test-Path -LiteralPath $realDest)) {
    $sysDxgi = Get-SystemDllPath -Machine $gameMachine -Name "dxgi.dll"
    if (-not $sysDxgi) {
        Write-Fail "Could not find a $archName dxgi.dll in your Windows folder."
        Write-Warn "Copy the $archName C:\Windows\System32\dxgi.dll to $realDest by hand."
    } else {
        try {
            Copy-Item -LiteralPath $sysDxgi -Destination $realDest -Force -ErrorAction Stop
            $chk = Get-PEMachine -Path $realDest
            if ($gameMachine -ne 0 -and $chk -ne $gameMachine) {
                Write-Fail "$REAL_PROXY came out $(if ($chk -eq 0x8664) { '64-bit' } else { '32-bit' }) but the game is $archName."
                Write-Warn "The game will not start with this file. Replace it with the $archName dxgi.dll."
            } else {
                Write-OK "$REAL_PROXY created from your own Windows dxgi.dll ($archName)."
            }
        } catch {
            Write-Fail "Could not create $REAL_PROXY`: $($_.Exception.Message)"
            Write-Warn "Copy $sysDxgi to $realDest by hand - without it the game will not start."
        }
    }
} else {
    Write-Info "$REAL_PROXY already there and matches the game - kept."
}

# Tuning defaults, only if the user has none. Their own tuning wins.
$cfgDest = [System.IO.Path]::Combine($gamePath, $CFG_REL)
if (-not (Test-Path -LiteralPath $cfgDest)) {
    $cfgSrc = Get-ChildItem -LiteralPath $srcRoot -Filter "grwxr.cfg" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cfgSrc) {
        try {
            $cfgDir = [System.IO.Path]::GetDirectoryName($cfgDest)
            if (-not (Test-Path -LiteralPath $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }
            Copy-Item -LiteralPath $cfgSrc.FullName -Destination $cfgDest -Force -ErrorAction Stop
            Write-Info "Default tuning written to $CFG_REL"
        } catch {}
    }
} else {
    Write-Info "Your existing $CFG_REL was kept."
}

$missing = @()
foreach ($f in @($MOD_FILE, $LOADER, $REAL_PROXY)) {
    if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $f)))) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Fail "Missing after install: $($missing -join ', ')"
    Write-Warn "Extract the ZIP into $gamePath by hand, next to $GAME_EXE."
    try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit." | Out-Null
    exit 1
}
# Place cfg_gui.exe alongside if the package ships it - that is the
# editor for grwxr.cfg the README mentions. Without it the user would
# have to edit the cfg in a text editor.
$guiSrc = Get-ChildItem -LiteralPath $srcRoot -Filter $CFG_GUI -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($guiSrc) {
    try {
        Copy-Item -LiteralPath $guiSrc.FullName -Destination (Join-Path $gamePath $CFG_GUI) -Force -ErrorAction Stop
        Write-OK "Mod files in place ($MOD_FILE, $LOADER, $REAL_PROXY, $CFG_GUI)."
    } catch {
        Write-Warn "Could not copy $CFG_GUI - edit GRWVR\grwxr.cfg in a text editor instead."
        Write-OK "Mod files in place ($MOD_FILE, $LOADER, $REAL_PROXY)."
    }
} else {
    Write-OK "Mod files in place ($MOD_FILE, $LOADER, $REAL_PROXY)."
}

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
if ($relTag) { try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } catch {} }
if ($relTag) { Save-InstalledStamp -GameDir $gamePath -Version $relTag -HubDir $SCRIPT_DIR }

# Steam starts the game and the proxy loads itself - no launcher, no
# shortcut needed. Only a copy from another store gets a direct route.
$isSteamInstall = ($gamePath -match '(?i)steamapps\\common' -or $gamePath -match '(?i)\\Steam\\')
if (-not $isSteamInstall) {
    $exeFull = [System.IO.Path]::Combine($gamePath, $GAME_EXE)
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exeFull -Encoding UTF8 -Force } catch {}
    try {
        [void](New-DesktopShortcut -ShortcutName "Ghost Recon Wildlands VR" `
            -TargetPath $exeFull -WorkingDir $gamePath -IconPath "$exeFull,0" `
            -Description "Launch Ghost Recon Wildlands in VR (GRW-XR)")
        Write-OK "Desktop shortcut created: Ghost Recon Wildlands VR"
    } catch {}
} else {
    try { Remove-Item -LiteralPath (Join-Path $SCRIPT_DIR ".launch_exe") -Force -ErrorAction SilentlyContinue } catch {}
}
try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
#  DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Ghost Recon Wildlands VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |            SOLO CAMPAIGN ONLY                            |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   The game runs Easy Anti-Cheat for multiplayer. Never play" -ForegroundColor White
Write-Host "   co-op, PvP or matchmaking with this mod installed." -ForegroundColor White
Write-Host "   Offline mode is recommended while the mod is this young." -ForegroundColor White
Write-Host ""
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |            BEFORE YOU LAUNCH                             |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   Async Spacewarp " -NoNewline -ForegroundColor White
Write-Host " OFF " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " (Oculus Debug Tool) - the mod" -ForegroundColor White
Write-Host "   handles the stale eye itself and ASW stacks artifacts on top." -ForegroundColor White
Write-Host "   Motion blur " -NoNewline -ForegroundColor White
Write-Host " OFF " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " . Leave the window mode ALONE -" -ForegroundColor White
Write-Host "   since v0.8.5 the mod keeps the game windowed by itself." -ForegroundColor White
Write-Host "   Exclusive fullscreen is what made the headset go black after" -ForegroundColor White
Write-Host "   one frame; the mod now declines it for you." -ForegroundColor White
Write-Host "   Put the headset on and let it track BEFORE you launch: the" -ForegroundColor White
Write-Host "   VR session is created once, at startup." -ForegroundColor White
Write-Host ""
Write-Host "  Then start the game through Steam and press " -NoNewline -ForegroundColor White
Write-Host " Home " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " to recenter." -ForegroundColor White
Write-Host "  You play on a gamepad - there are no motion controls yet." -ForegroundColor White
Write-Host ""
Write-Host "  Everything is tuned live on the numpad and written to" -ForegroundColor Gray
Write-Host "  GRWVR\grwxr.cfg - eye separation, field of view and the" -ForegroundColor Gray
Write-Host "  first-person camera. This game's page in the Hub has the full" -ForegroundColor Gray
Write-Host "  key list." -ForegroundColor Gray
Write-Host "  To switch VR off, rename dxgi.dll in the game folder." -ForegroundColor Gray
Write-Host ""
Write-Host "  Sync up, Ghosts - Bolivia in stereo." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close." | Out-Null
