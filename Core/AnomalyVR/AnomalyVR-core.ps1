# ============================================================
#  S.T.A.L.K.E.R. Anomaly VR (AoE VR) - launcher bootstrap
# ============================================================
# The mod team ships its own launcher, AoeVrLauncher.exe, which downloads
# the base game + VR modpack from mod.db and SELF-UPDATES. The Hub just
# places that launcher into the Anomaly folder and starts it. The launcher
# is NEVER bundled (Discord-gated + self-updating); the user grabs it and
# drags it in. The Discord post is in RUSSIAN, so we identify the right
# download by POSITION (first link) + the ROCKET icon, never by label text.

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$LAUNCHER_EXE       = "AoeVrLauncher.exe"
$DEFAULT_GAME_DIR   = "C:\games\Anomaly VR"
$DISCORD_INVITE_URL = "https://discord.gg/kGhd7GvJ5F"
$DISCORD_POST_URL   = "https://discord.com/channels/1495664880311734313/1520470650144161923/1520470650144161923"

# ---- console helpers ----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  S.T.A.L.K.E.R. Anomaly VR Mod Installer" -ForegroundColor Cyan
    Write-Host "  Sets up the AoE VR launcher (downloads + auto-updates)" -ForegroundColor Gray
    Write-Host "  Base game: Anomaly 1.5.3 - the launcher fetches it for you" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
}
function Write-Step { param([int]$Step,[int]$Total,[string]$Title)
    Write-Host ""; Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray }
function Write-Do   { param($m) Write-Host "  >> $m" -ForegroundColor Yellow }   # a manual action
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "     $m"  -ForegroundColor Gray }    # quiet aside
function Write-Warn { param($m) Write-Host "  [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [X] $m"  -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host "  >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-ExeFromUser {
    while ($true) {
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (-not $r) { continue }
        if (-not (Test-Path $r)) { Write-Fail "Not found: $r"; continue }
        if ($r -notmatch '\.exe$') { Write-Fail "That's not the .exe (you may have grabbed the archive)."; continue }
        if ([System.IO.Path]::GetFileName($r) -ne $LAUNCHER_EXE) {
            Write-Warn "Expected $LAUNCHER_EXE - using $([System.IO.Path]::GetFileName($r)) anyway."
        }
        return $r
    }
}

Write-Header

# -------------------------------------------------------
# STEP 1: pick the Anomaly folder
# -------------------------------------------------------
# Can we actually create/write here? (catches Program Files / UAC traps for
# a fresh install). For an existing install the caller accepts it before this.
function Test-WritablePath {
    param([string]$Path)
    try {
        $target = if (Test-Path $Path) { $Path } else { Split-Path -Parent $Path }
        if (-not $target) { return $false }
        if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $target ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

Write-Step 1 4 "Choose where to install"
Write-Host "  This installs the Anomaly VR launcher. That launcher then" -ForegroundColor White
Write-Host "  downloads the game + the VR modpack for you and keeps them" -ForegroundColor White
Write-Host "  updated - you do not need anything beforehand." -ForegroundColor White
Write-Host ""
Write-Host "  Press ENTER for a fresh install at the recommended location:" -ForegroundColor Yellow
Write-Host "      $DEFAULT_GAME_DIR" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host "  Or type a different folder to install into." -ForegroundColor Gray
Write-Host "  Or, if you ALREADY have S.T.A.L.K.E.R. Anomaly, drag that folder in." -ForegroundColor DarkGray

$gameDir = $null
while (-not $gameDir) {
    $inputPath = (Read-Host "  Folder [Enter = $DEFAULT_GAME_DIR]").Trim().Trim('"').TrimEnd('\')
    if (-not $inputPath) { $cand = $DEFAULT_GAME_DIR } else { $cand = $inputPath }

    if ((Test-Path $cand) -and (Test-Path -LiteralPath "$cand\fsgame.ltx")) {
        # Existing Anomaly install - use as-is.
        Write-OK "Existing Anomaly install found here."
        $gameDir = $cand
        break
    }
    if (Test-WritablePath -Path $cand) {
        if (Test-Path $cand) {
            Write-Warn "Folder exists but has no fsgame.ltx - using it for a fresh setup."
        } else {
            Write-Info "New folder - created once the launcher is placed."
        }
        $gameDir = $cand
    } else {
        Write-Fail "Cannot write to: $cand"
        Write-Info "Pick a spot outside Program Files (e.g. $DEFAULT_GAME_DIR), or run as admin."
    }
}

# Old-installation cleanup. A previous Hub install layered the VR mod via
# JSGME. Those leftover MODS\ folders + JSGME are what the new launcher's
# File Integrity check reports as "Problem (N mods)". Remove ONLY our known
# leftovers - the base game and vr_mods\ are never touched.
if (Test-Path $gameDir) {
    $leftovers = @()
    $modsDir = Join-Path $gameDir "MODS"
    if (Test-Path $modsDir) {
        $leftovers += Get-ChildItem $modsDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "amomaly_aoe_vr*" -or $_.Name -eq "MCM" } |
            ForEach-Object { $_.FullName }
    }
    foreach ($f in @("JSGME.exe", "JSGME.ini")) {
        $p = Join-Path $gameDir $f
        if (Test-Path $p) { $leftovers += $p }
    }
    if ($leftovers.Count -gt 0) {
        Write-Host ""
        Write-Warn "Looks like an older Hub install (JSGME-based VR mod)."
        Write-Info "The launcher's File Integrity check flags these as 'Problem':"
        foreach ($l in $leftovers) { Write-Host "       - $($l.Substring($gameDir.Length).TrimStart('\'))" -ForegroundColor DarkGray }
        Write-Info "They are retained so the installer never removes local files automatically."
        Write-Host "       Back them up and remove them manually only if the launcher requires it." -ForegroundColor DarkGray
    }
}

# Re-run guard: launcher already here -> skip the download.
$launcherDest = Join-Path $gameDir $LAUNCHER_EXE
$skipDownload = (Test-Path $launcherDest)
if ($skipDownload) { Write-OK "$LAUNCHER_EXE already here - skipping download." }

# -------------------------------------------------------
# STEP 2: get the launcher (Discord-gated, RUSSIAN post)
# -------------------------------------------------------
Write-Step 2 4 "Get the launcher"
if (-not $skipDownload) {
    Write-Host "  The launcher is on the mod's Discord - you must JOIN the server." -ForegroundColor White
    Pause-User "Press Enter to open the invite..."
    try { Start-Process $DISCORD_INVITE_URL } catch { Write-Info $DISCORD_INVITE_URL }

    # Bring focus back to the console BEFORE showing the next instructions,
    # so they don't print in the background while the user is still joining.
    Pause-User "Joined the server? Press Enter for the next step..."
    Write-Host ""
    Write-Do  "In the post that opens: click the FIRST Google Drive link (after the ROCKET icon)."
    Write-Info "The second link is the manual archive - skip it."
    Pause-User "Press Enter to open the download post..."
    try { Start-Process $DISCORD_POST_URL } catch { Write-Info "$DISCORD_POST_URL (must be a server member)" }

    Write-Host ""
    Write-Do  "Once it's downloaded, drag $LAUNCHER_EXE in (or paste its path) and press Enter."
    $src = Get-ExeFromUser

    # Create the folder now - only once we actually have the launcher.
    if (-not (Test-Path $gameDir)) {
        try { New-Item -ItemType Directory -Path $gameDir -Force | Out-Null }
        catch { Write-Fail "Could not create: $gameDir"; Pause-User "Press Enter to exit"; return }
    }
    try {
        Copy-Item -LiteralPath $src -Destination $launcherDest -Force
        Write-OK "Launcher placed in: $gameDir"
    } catch {
        Write-Fail "Could not copy it in."
        Write-Do  "Move it to $gameDir yourself."
        Pause-User "Done? Press Enter (or close to exit)"
        if (-not (Test-Path $launcherDest)) { return }
    }
}

# -------------------------------------------------------
# STEP 3: start the launcher
# -------------------------------------------------------
Write-Step 3 4 "Start the launcher"
Write-Do  "Pressing Enter launches it - accept the UAC / admin prompt that pops up."
Write-Host "  Once it opens (it's in Russian):" -ForegroundColor White
Write-Do  "Top-right: switch RU -> EN (skip if you read Russian)."
Write-Do  "Then click 'Update & Play'."
Pause-User "Press Enter to start the launcher..."
try {
    Start-Process -FilePath $launcherDest -WorkingDirectory $gameDir -Verb RunAs
    Write-OK "Launcher started."
} catch {
    Write-Warn "Couldn't start it (UAC declined?)."
    Write-Do  "Start it yourself: $launcherDest"
}

# -------------------------------------------------------
# STEP 4: desktop shortcut + marker
# -------------------------------------------------------
Write-Step 4 4 "Desktop shortcut"
if (Test-Path $launcherDest) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Anomaly VR.lnk" -TargetPath $launcherDest -WorkingDir $gameDir -IconPath "$launcherDest,0"
        Write-OK "Desktop shortcut 'Anomaly VR' created."
    } catch { Write-Warn "Couldn't create the shortcut." }
} else {
    Write-Warn "Launcher not placed yet - skipping shortcut."
}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Done. Updates run THROUGH the launcher - just hit Updates." -ForegroundColor Green
Write-Host "  The Hub's" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "runs it too." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Stay out of the anomalies, stalker. The Zone notices." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
