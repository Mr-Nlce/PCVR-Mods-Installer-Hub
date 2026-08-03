# ============================================================
#  PCVR Mods Installer Hub
# ============================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Captured as early as possible: used to record the real load time
# (process start -> window first rendered) to %TEMP% so the launcher
# splash can pace its progress bar against the last run's duration.
$global:HubLoadStart = [DateTime]::UtcNow

# PowerShell 5.1 defaults to TLS 1.0/1.1 which Steam CDN (and most
# modern HTTPS endpoints) no longer accept. Without this, BitmapImage
# downloads from cdn.akamai.steamstatic.com silently fail for some
# games and the hero image stays blank. Set before any network access.
try {
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.SecurityProtocolType]::Tls12 -bor `
        [System.Net.SecurityProtocolType]::Tls11 -bor `
        [System.Net.SecurityProtocolType]::Tls
} catch { }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:scriptDir = $scriptDir
$global:scriptDir = $scriptDir   # global mirror for global: functions (cache helpers)
$rootDir   = Split-Path -Parent $scriptDir   # Hub root (one level up from Core\)

# Path to the installer log wrapper (used by Start-LoggedInstaller).
$global:RunInstallerPath = Join-Path $scriptDir "Run-Installer.ps1"

# Session log: capture the Hub's own console output to Logs\Hub-<timestamp>.log.
# Start-Transcript writes live, so the file survives a crash. Best-effort and
# never blocks startup. Logs live in Core\Logs (the installer wrapper uses the
# same folder), keeping the Hub's top folder clean; robocopy /E in
# Update-Hub.ps1 leaves the folder untouched.
try {
    $logsDir = Join-Path $scriptDir "Logs"
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
    Get-ChildItem $logsDir -Filter *.log -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 30 |
        Remove-Item -Force -ErrorAction SilentlyContinue
    $hubLog = Join-Path $logsDir ("Hub-{0}.log" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))
    Start-Transcript -Path $hubLog -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}

# -------------------------------------------------------
# Startup timing (diagnostic, opt-in).
# Enable by creating an empty file '.timing' in the Hub root
# (next to PCVRModsHub.bat). When present, phase timestamps are
# appended to %TEMP%\PCVRHub_startup.log so we can see where the
# startup time goes. No file is written to the Hub itself
# (state-file ship guard - rule #2 / audit #15).
# -------------------------------------------------------
$global:HubTiming = @{ Enabled = $false; Start = $null; Log = $null }
try {
    $timingFlag = Join-Path $rootDir ".timing"
    if (Test-Path $timingFlag) {
        $global:HubTiming.Enabled = $true
        $global:HubTiming.Start = [DateTime]::UtcNow
        $global:HubTiming.Log = Join-Path $env:TEMP "PCVRHub_startup.log"
        $banner = "===== PCVR Hub startup $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') v$HUB_VERSION ====="
        Add-Content -Path $global:HubTiming.Log -Value "" -ErrorAction SilentlyContinue
        Add-Content -Path $global:HubTiming.Log -Value $banner -ErrorAction SilentlyContinue
    }
} catch { }
function global:Write-HubTiming {
    param([string]$Phase)
    if (-not $global:HubTiming.Enabled) { return }
    try {
        $ms = [int]([DateTime]::UtcNow - $global:HubTiming.Start).TotalMilliseconds
        $line = ("{0,7} ms  {1}" -f $ms, $Phase)
        Add-Content -Path $global:HubTiming.Log -Value $line -ErrorAction SilentlyContinue
    } catch { }
}
Write-HubTiming "boot: after assembly load + scriptDir"

# -------------------------------------------------------
# Version & Update check
# -------------------------------------------------------
$HUB_VERSION = "0.8.5.0"

$updateInfoFile  = Join-Path $scriptDir ".update_available"
$script:updateInfo = $null
if (Test-Path $updateInfoFile) {
    try { $script:updateInfo = Get-Content $updateInfoFile -Raw | ConvertFrom-Json } catch {}
}

# -------------------------------------------------------
# Mod version tracking helpers
# -------------------------------------------------------
# Parse a version number out of a Mod display string, e.g.
#   "L4D2VR v0.6.4"           -> "0.6.4"
#   "R.E.A.L. VR v2603.10.1"  -> "2603.10.1"
#   "NomaiVR 2.10.0"          -> "2.10.0"
#   "Fully Possessed v0.021j" -> "0.021j"
# Returns $null if no version-looking token is found.
function Get-ModVersionFromString {
    param([string]$ModString)
    if (-not $ModString) { return $null }
    $m = [regex]::Match($ModString, '\bv?(\d+\.\d+(?:\.\d+)*[a-zA-Z]?)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# Given a $game hash, return full path to its .installed_version file.
# Derived from the Bat field: "L4D2VR\START_INSTALLER.bat" -> Core\L4D2VR\.installed_version
# Returns $null if game has no Bat or Bat is malformed.
function Get-InstalledVersionPath {
    param($Game)
    if (-not $Game -or -not $Game.Bat) { return $null }
    $modFolder = Split-Path -Parent $Game.Bat
    if (-not $modFolder) { return $null }
    # Multi-game installers (LukeRossVR, REFrameworkVR, QuestZDoomShared)
    # share one Bat folder across many titles. Key the version file by title
    # so each game tracks its own installed build (mirrors Get-InstalledPathFile);
    # otherwise updating one REFramework game would mark all of them current.
    $isMulti = ($modFolder -ieq 'LukeRossVR' -or $modFolder -ieq 'REFrameworkVR' -or $modFolder -ieq 'QuestZDoomShared')
    if ($isMulti) {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_version_$safe"))
    }
    return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_version"))
}

# Given a $game hash, return full path to its .installed_path file.
# Some installers (Outward, Tormented Souls) put the game in a custom
# location the user chose, so we can't guess where to detect the mod.
# If this file exists and points to a real folder, that folder wins
# over any SteamFolder / FallbackPaths heuristic.
function Get-InstalledPathFile {
    param($Game)
    if (-not $Game) { return $null }
    if (-not $Game.Bat) {
        # Bat-less entries (external tools / games the user installs
        # themselves) have no installer folder. Store any user-located
        # path in a shared runtime "Located" folder keyed by title so the
        # "Locate install" button works and the scan can re-verify it.
        if (-not $Game.Title) { return $null }
        $safeL = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path "Located" (".installed_path_" + $safeL)))
    }
    $modFolder = Split-Path -Parent $Game.Bat
    if (-not $modFolder) { return $null }
    # Multi-game installers (LukeRossVR, REFrameworkVR, QuestZDoomShared)
    # all share one Bat folder across many titles. A single .installed_path
    # file would be overwritten on every install. Key the file by title.
    $isMulti = ($modFolder -ieq 'LukeRossVR' -or $modFolder -ieq 'REFrameworkVR' -or $modFolder -ieq 'QuestZDoomShared')
    if ($isMulti) {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_path_$safe"))
    }
    # GZDoom family (Doom / Doom 2 / Heretic / Hexen / Strife): their catalog
    # Bat folder is per-game (DoomVR, HereticVR, ...), but the actual installer
    # is the SHARED QuestZDoomShared, which writes its marker to
    # QuestZDoomShared\.installed_path_<title>. Without this the Hub looked in
    # the wrong folder and the tile never flipped to VR Ready after install.
    if ($modFolder -imatch '^(DoomVR|Doom2VR|HereticVR|HexenVR|StrifeVR)$') {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path 'QuestZDoomShared' ".installed_path_$safe"))
    }
    return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_path"))
}

# Read the recorded install path. Returns $null if file missing, empty,
# or pointing to a folder that no longer exists.
function Read-InstalledPath {
    param($Game)
    $path = Get-InstalledPathFile -Game $Game
    if (-not $path -or -not (Test-Path $path)) { return $null }
    $v = (Get-Content $path -Raw -ErrorAction SilentlyContinue)
    if ($null -eq $v) { return $null }
    $v = $v.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    if (-not (Test-Path $v)) { return $null }
    return $v
}

# The "Locate Game" exe-picker can record the exact exe that launches
# a user-located install (e.g. a differently named exe from another
# store). Stored next to .installed_path as .launch_exe, holding the
# full exe path. Start-GameInVR prefers it over everything else.
function Get-LaunchOverrideFile {
    param($Game)
    $base = Get-InstalledPathFile -Game $Game
    if (-not $base) { return $null }
    return ($base -replace [regex]::Escape('.installed_path'), '.launch_exe')
}

function Read-LaunchOverride {
    param($Game)
    $p = Get-LaunchOverrideFile -Game $Game
    if (-not $p -or -not (Test-Path $p)) { return $null }
    $v = (Get-Content $p -Raw -ErrorAction SilentlyContinue)
    if ($null -eq $v) { return $null }
    $v = $v.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    if (-not (Test-Path $v)) { return $null }
    return $v
}

# Marker written by "Locate Game" so the detail page knows this entry
# was located by the user (not by an installer / Steam). Lets us swap
# the one-shot "Locate Game" button for "Re-locate Game" + "Clear" so
# user mistakes (wrong folder / wrong exe) stay correctable.
function Get-UserLocatedFile {
    param($Game)
    $base = Get-InstalledPathFile -Game $Game
    if (-not $base) { return $null }
    return ($base -replace [regex]::Escape('.installed_path'), '.user_located')
}

# Read installed version for a game. Returns $null if file missing or empty.
function Read-InstalledVersion {
    param($Game)
    $path = Get-InstalledVersionPath -Game $Game
    if (-not $path -or -not (Test-Path $path)) { return $null }
    $v = (Get-Content $path -Raw -ErrorAction SilentlyContinue)
    if ($null -eq $v) { return $null }
    $v = $v.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    return $v
}

# Write installed version for a game. Silent no-op if no Bat field.
function Write-InstalledVersion {
    param($Game, [string]$Version)
    $path = Get-InstalledVersionPath -Game $Game
    if (-not $path -or [string]::IsNullOrWhiteSpace($Version)) { return }
    try {
        [System.IO.File]::WriteAllText(
            $path, $Version.Trim(),
            (New-Object System.Text.UTF8Encoding $false)
        )
    } catch {}
}

# Second tracked version, for entries that carry TWO independent mods in
# one catalog tile (BioShock: balouza and BioVRDev). Same folder, distinct
# file, so each mod's release can be tracked on its own.
function Get-InstalledVersionPathB {
    param($Game)
    $p = Get-InstalledVersionPath -Game $Game
    if (-not $p) { return $null }
    return ($p + "_b")
}

# Remove installed version file (used when user clicks Update). The second
# marker goes with it - otherwise a two-mod entry would keep a stale
# version for mod B and show Update forever after an install.
function Remove-InstalledVersion {
    param($Game)
    $path = Get-InstalledVersionPath -Game $Game
    if ($path -and (Test-Path $path)) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }
    $pathB = Get-InstalledVersionPathB -Game $Game
    if ($pathB -and (Test-Path $pathB)) {
        Remove-Item $pathB -Force -ErrorAction SilentlyContinue
    }
}

# Path to the per-game ".update_ok" marker the installer wrapper drops
# next to .installed_version when its core ran to completion. A cancel
# inside the core calls 'exit' first, so the marker is absent on cancel.
function Get-UpdateOkMarkerPath {
    param($Game)
    $vp = Get-InstalledVersionPath -Game $Game
    if (-not $vp) { return $null }
    return (Join-Path (Split-Path -Parent $vp) ".update_ok")
}

# Clear a stale completion marker before launching an update installer,
# so only a freshly completed run can clear the tracked version.
function Clear-UpdateOkMarker {
    param($Game)
    $mk = Get-UpdateOkMarkerPath -Game $Game
    if ($mk -and (Test-Path $mk)) {
        Remove-Item $mk -Force -ErrorAction SilentlyContinue
    }
}

# -------------------------------------------------------
# Module loader. The Hub used to live in a single 10k-line
# VRModHub.ps1; it is now split into focused modules under
# .\Modules\. Order matters - each module assumes the prior
# ones have already defined their helpers, $window, globals
# etc. Do not reorder without checking dependencies.
# -------------------------------------------------------
$modulesDir = Join-Path $scriptDir "Modules"
foreach ($mod in @(
    "Catalog.ps1",
    "BannerColors.ps1",
    "Helpers.ps1",
    "CardTile.ps1",
    "Window.ps1",
    "ScanSpinner.ps1",
    "DiscoverInit.ps1",
    "DetailView.ps1",
    "OverviewPage.ps1",
    "BannerOvFilters.ps1",
    "Filter.ps1",
    "Startup.ps1"
)) {
    . (Join-Path $modulesDir $mod)
    Write-HubTiming ("module loaded: {0}" -f $mod)
}
