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
    # -File: without it a DIRECTORY called something.log would come back
    # from the filter and get handed to Remove-Item. Cheap guard, and the
    # rule everywhere now is that a delete only ever sees a file.
    Get-ChildItem $logsDir -Filter *.log -File -ErrorAction SilentlyContinue |
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
$HUB_VERSION = "0.8.7.0"

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

# A stored version must carry at least one number. Placeholders such as
# "latest", "cached" or "unknown" are download-routing labels, not build
# identities: Test-OnlineVersionIsNewer cannot order them, and a game-side
# placeholder would otherwise outrank every usable Hub/LocalAppData copy.
# Keep this rule in sync with InstallerSafety.ps1, which runs in the separate
# installer process.
function Test-IsTrackableInstalledVersion {
    param($Version)
    if ($null -eq $Version) { return $false }
    # Reject release/package objects instead of stringifying them into state.
    if ($Version -isnot [string] -and $Version -isnot [ValueType] -and $Version -isnot [version]) { return $false }
    $versionText = ([string]$Version).Trim()
    if ([string]::IsNullOrWhiteSpace($versionText)) { return $false }
    return ($versionText -match '\d')
}

# Runtime state must outlive the Hub folder.  The in-game
# .pcvrhub_version file is still the portable source of truth, but it
# cannot solve every case by itself: some mods deliberately live in a
# separate launcher/staging folder, and after replacing the Hub we no
# longer know where that folder is.  Keep a tiny per-game index under
# LocalAppData as the second durable copy.  The files contain paths and
# version strings only; downloaded mods and game data never live here.
function Get-PersistentGameStatePath {
    param($Game, [string]$Name)
    if (-not $Game -or [string]::IsNullOrWhiteSpace($Game.Title) -or [string]::IsNullOrWhiteSpace($Name)) { return $null }
    $root = $null
    if ($global:HubStateRootOverride) {
        $root = [string]$global:HubStateRootOverride
    } else {
        try {
            $localState = [Environment]::GetFolderPath('LocalApplicationData')
            if (-not [string]::IsNullOrWhiteSpace($localState)) {
                $root = [IO.Path]::Combine($localState, 'PCVR Mods Installer Hub', 'State')
            }
        } catch {}
    }
    if ([string]::IsNullOrWhiteSpace($root)) { return $null }
    $safeTitle = ([string]$Game.Title -replace '[^A-Za-z0-9]', '_').Trim('_')
    if (-not $safeTitle) { return $null }
    $key = if ($Game.SteamId) { ([string]$Game.SteamId) + '_' + $safeTitle } else { $safeTitle }
    return ([IO.Path]::Combine($root, $key, ($Name + '.txt')))
}

function Read-PersistentGameStateValue {
    param($Game, [string]$Name)
    $p = Get-PersistentGameStatePath -Game $Game -Name $Name
    if (-not $p -or -not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    try {
        $v = (("" + (Get-Content -LiteralPath $p -Raw -ErrorAction Stop)) -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', '').Trim()
        if ([string]::IsNullOrWhiteSpace($v)) { return $null }
        return $v
    } catch { return $null }
}

function Write-PersistentGameStateValue {
    param($Game, [string]$Name, [string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return }
    $p = Get-PersistentGameStatePath -Game $Game -Name $Name
    if (-not $p) { return }
    try {
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $current = ("" + (Get-Content -LiteralPath $p -Raw -ErrorAction Stop)).Trim()
            if ($current -ceq $Value.Trim()) { return }
        }
        $parent = Split-Path -Parent $p
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
        $enc = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($p, $Value.Trim(), $enc)
    } catch {}
}

function Reset-PersistentGameStateValue {
    param($Game, [string]$Name)
    $p = Get-PersistentGameStatePath -Game $Game -Name $Name
    if (-not $p -or -not (Test-Path -LiteralPath $p -PathType Leaf)) { return }
    try { [System.IO.File]::WriteAllText($p, '', (New-Object System.Text.UTF8Encoding $false)) } catch {}
}

# Given a $game hash, return full path to its .installed_version file.
# Derived from the Bat field: "L4D2VR\START_INSTALLER.bat" -> Core\L4D2VR\.installed_version
# Returns $null if game has no Bat or Bat is malformed.
function Get-HubRelativeDirectory {
    param([string]$RelativePath)
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $null }

    # Catalog paths are intentionally Windows-style because the shipped Hub
    # runs on Windows.  Tests also load the catalog on Linux, where '\' is a
    # valid filename character rather than a separator.  Split both separator
    # forms explicitly, then rebuild with the current host's separator.
    $parts = @($RelativePath -split '[\\/]' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts.Count -lt 2) { return $null }
    $directory = [string]$parts[0]
    for ($i = 1; $i -lt ($parts.Count - 1); $i++) {
        $directory = [IO.Path]::Combine($directory, [string]$parts[$i])
    }
    return $directory
}

function Get-InstalledVersionPath {
    param($Game)
    if (-not $Game -or -not $Game.Bat) { return $null }
    $modFolder = Get-HubRelativeDirectory -RelativePath ([string]$Game.Bat)
    if (-not $modFolder) { return $null }
    # Multi-game installers (LukeRossVR, REFrameworkVR, QuestZDoomShared)
    # share one Bat folder across many titles. Key the version file by title
    # so each game tracks its own installed build (mirrors Get-InstalledPathFile);
    # otherwise updating one REFramework game would mark all of them current.
    $isMulti = ($modFolder -ieq 'LukeRossVR' -or $modFolder -ieq 'REFrameworkVR' -or $modFolder -ieq 'QuestZDoomShared')
    if ($isMulti) {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return ([IO.Path]::Combine($script:scriptDir, $modFolder, ".installed_version_$safe"))
    }
    return ([IO.Path]::Combine($script:scriptDir, $modFolder, ".installed_version"))
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
        return ([IO.Path]::Combine($script:scriptDir, "Located", (".installed_path_" + $safeL)))
    }
    $modFolder = Get-HubRelativeDirectory -RelativePath ([string]$Game.Bat)
    if (-not $modFolder) { return $null }
    # Multi-game installers (LukeRossVR, REFrameworkVR, QuestZDoomShared)
    # all share one Bat folder across many titles. A single .installed_path
    # file would be overwritten on every install. Key the file by title.
    $isMulti = ($modFolder -ieq 'LukeRossVR' -or $modFolder -ieq 'REFrameworkVR' -or $modFolder -ieq 'QuestZDoomShared')
    if ($isMulti) {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return ([IO.Path]::Combine($script:scriptDir, $modFolder, ".installed_path_$safe"))
    }
    # GZDoom family (Doom / Doom 2 / Heretic / Hexen / Strife): their catalog
    # Bat folder is per-game (DoomVR, HereticVR, ...), but the actual installer
    # is the SHARED QuestZDoomShared, which writes its marker to
    # QuestZDoomShared\.installed_path_<title>. Without this the Hub looked in
    # the wrong folder and the tile never flipped to VR Ready after install.
    if ($modFolder -imatch '^(DoomVR|Doom2VR|HereticVR|HexenVR|StrifeVR)$') {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return ([IO.Path]::Combine($script:scriptDir, 'QuestZDoomShared', ".installed_path_$safe"))
    }
    return ([IO.Path]::Combine($script:scriptDir, $modFolder, ".installed_path"))
}

# Read the recorded install path. Returns $null if file missing, empty,
# or pointing to a folder that no longer exists.
function Read-InstalledPath {
    param($Game)
    $hubFile = Get-InstalledPathFile -Game $Game
    $hubValue = $null
    if ($hubFile -and (Test-Path -LiteralPath $hubFile -PathType Leaf)) {
        try { $hubValue = ("" + (Get-Content -LiteralPath $hubFile -Raw -ErrorAction Stop)).Trim() } catch {}
    }
    $durableValue = Read-PersistentGameStateValue -Game $Game -Name 'installed_path'
    foreach ($candidate in @($hubValue, $durableValue)) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        # Migrate in either direction.  A fresh Hub rebuilds its fast local
        # cache from LocalAppData; an older Hub install automatically gains
        # the durable copy the first time it is seen.
        if ($candidate -eq $hubValue) {
            Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $candidate
        } elseif ($hubFile) {
            try {
                $parent = Split-Path -Parent $hubFile
                if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
                [System.IO.File]::WriteAllText($hubFile, $candidate, (New-Object System.Text.UTF8Encoding $false))
            } catch {}
        }
        return $candidate
    }

    # Migration path for known external launcher roots created by older Hub
    # builds before the LocalAppData index existed.  Evidence is mandatory:
    # merely having C:\Games\<name> is not enough to claim an install.
    foreach ($candidate in @($Game.DurableInstallRoots)) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        $evidence = $false
        try {
            if ($Game.TwoMods) {
                $a = if ($Game.ModASub -and $Game.ModALaunch) { Join-Path $candidate (Join-Path $Game.ModASub $Game.ModALaunch) } else { $null }
                $b = if ($Game.ModBSub -and $Game.ModBLaunch) { Join-Path $candidate (Join-Path $Game.ModBSub $Game.ModBLaunch) } else { $null }
                $evidence = (($a -and (Test-Path -LiteralPath $a -PathType Leaf)) -or ($b -and (Test-Path -LiteralPath $b -PathType Leaf)))
            } elseif ($Game.ModFile) {
                $evidence = Test-Path -LiteralPath (Join-Path $candidate $Game.ModFile) -PathType Leaf
            } elseif ($Game.LaunchExe) {
                $evidence = Test-Path -LiteralPath (Join-Path $candidate $Game.LaunchExe) -PathType Leaf
            }
        } catch { $evidence = $false }
        if (-not $evidence) { continue }
        Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $candidate
        if ($hubFile) {
            try {
                $parent = Split-Path -Parent $hubFile
                if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
                [System.IO.File]::WriteAllText($hubFile, $candidate, (New-Object System.Text.UTF8Encoding $false))
            } catch {}
        }
        return $candidate
    }
    return $null
}

# WHERE DOES THE DEPOT BUILD ACTUALLY LIVE?
# The catalog field DepotPath is a FIXED suggestion
# (C:\Games\<game> VR), but the installer lets the user choose the
# folder freely - and writes the chosen one into .installed_path.
# Anyone installing elsewhere used to be invisible to the Hub: both the
# start-depot button and the split-button detection only looked at the
# catalog path. So query both sources, catalog path first.
# The recorded path only counts when it is NOT under
# steamapps\common - that is where the normal Steam copy lives, and
# that is the other half of a DualMode entry, not the depot build.
function Get-DepotCandidatePaths {
    param($Game)
    $out = @()
    if ($Game.DepotPath) { $out += [string]$Game.DepotPath }
    try {
        $rec = Read-InstalledPath -Game $Game
        # Separator-independent, so the check does not slip past on a
        # forward slash.
        if ($rec -and ($rec -notmatch '(?i)steamapps[\\/]+common') -and ($out -notcontains $rec)) { $out += $rec }
    } catch {}
    return $out
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
    $hubValue = $null
    if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) {
        try { $hubValue = ("" + (Get-Content -LiteralPath $p -Raw -ErrorAction Stop)).Trim() } catch {}
    }
    $durableValue = Read-PersistentGameStateValue -Game $Game -Name 'launch_exe'
    foreach ($candidate in @($hubValue, $durableValue)) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        if ($candidate -eq $hubValue) {
            Write-PersistentGameStateValue -Game $Game -Name 'launch_exe' -Value $candidate
        } elseif ($p) {
            try {
                $parent = Split-Path -Parent $p
                if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
                [System.IO.File]::WriteAllText($p, $candidate, (New-Object System.Text.UTF8Encoding $false))
            } catch {}
        }
        return $candidate
    }
    # Older external-launcher installs may have only the durable install
    # root.  Reconstruct an unambiguous executable override from catalog
    # evidence (FH5's ModFile is vrmod-launcher.exe), then persist it.
    if (-not $Game.TwoMods) {
        $root = Read-InstalledPath -Game $Game
        $relativeExe = if ($Game.LaunchExe -and ([IO.Path]::GetExtension([string]$Game.LaunchExe) -ieq '.exe')) { [string]$Game.LaunchExe }
                       elseif ($Game.ModFile -and ([IO.Path]::GetExtension([string]$Game.ModFile) -ieq '.exe')) { [string]$Game.ModFile }
                       else { $null }
        if ($root -and $relativeExe) {
            try {
                $candidate = Join-Path $root $relativeExe
                if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    Write-PersistentGameStateValue -Game $Game -Name 'launch_exe' -Value $candidate
                    if ($p) {
                        $parent = Split-Path -Parent $p
                        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
                        [System.IO.File]::WriteAllText($p, $candidate, (New-Object System.Text.UTF8Encoding $false))
                    }
                    return $candidate
                }
            } catch {}
        }
    }
    return $null
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

# ============================================================
#  WHERE THE INSTALLED VERSION IS RECORDED
# ============================================================
# The tracked version used to live ONLY in the Hub's own folder
# (Core\<Game>\.installed_version). That is a bad place for it: the
# Hub is a thing people replace. The built-in updater is careful
# (robocopy, no /MIR, .installed_version in /XF), but anyone who
# unpacks a fresh Hub over a new folder - or moves to another PC,
# or reinstalls the Hub by hand - loses every marker at once. The
# next scan then finds no version, SEEDS it with whatever is current
# online, and every outdated mod silently counts as up to date. No
# Update badge, ever, and nothing looks broken.
#
# So the marker now lives WITH THE MOD, in the game folder, under one
# name for every game. That file survives any Hub replacement, and it
# is the same fact the Hub needs: which build is on this disk. The
# Hub-local copy is still written as a mirror, so nothing that reads
# it directly breaks, and it still answers when a game folder is not
# resolvable at that moment.
#
# Reading order is deliberate: game folder first, Hub folder second.
# The game folder is the ground truth; the Hub copy is a cache.
# Path of the in-game marker. $Second is the B slot for entries that
# track TWO mods in one tile (BioShock), mirroring the Hub-local
# .installed_version / _b pair.
#
# THE NAME IS A LITERAL IN HERE, deliberately. An earlier draft read it
# from a $global set at module load. When that global was empty for any
# reason the name became "", the path combiner handed back THE GAME FOLDER
# ITSELF - and back then this path was handed to a delete. The literal
# cannot be unset, and the guard below refuses any result that is not
# strictly below $GameDir. Nothing in this file deletes any more (see
# Reset-InstalledVersion), so that class of accident is gone at the
# root rather than merely guarded against.
# InstallerSafety.ps1 carries the same literal for Write-ModStamp,
# because installers run in their own process and never load this file.
# The two must stay in step.
function Get-GameStampPath {
    param([string]$GameDir, [switch]$Second)
    if ([string]::IsNullOrWhiteSpace($GameDir)) { return $null }
    $n = ".pcvrhub_version"
    if ($Second) { $n = "$n" + "_b" }
    # Path.Combine is provider-independent: unlike Join-Path it does not
    # require a referenced drive to be mounted, and unlike a literal '\'
    # it remains testable on non-Windows hosts.
    $full = [IO.Path]::Combine($GameDir, $n)
    # Never hand back the folder itself.
    if ([string]::IsNullOrWhiteSpace($full)) { return $null }
    if ((Split-Path -Leaf $full) -notlike ".pcvrhub_version*") { return $null }
    return $full
}

function Read-VersionStampFile {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        # -Raw returns $null for an EMPTY file, and $null -replace yields an
        # ARRAY - .Trim() on that throws. Cast first, or an empty marker
        # silently kills the whole check.
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $v = ([string]$raw -replace '[^\x20-\x7E]', '').Trim()
        if (-not (Test-IsTrackableInstalledVersion -Version $v)) { return $null }
        return $v
    } catch { return $null }
}

# Read installed version for a game. Game folder wins over the Hub copy.
# Returns $null if neither has a usable value.
function Read-InstalledVersion {
    param($Game, [string]$GameDir)

    # !!! TAKE THE NEWER OF THE TWO, NOT THE FIRST ONE FOUND (2026-08-20).
    # There are two markers and they can disagree:
    #   <GameDir>\.pcvrhub_version  - survives a Hub replacement
    #   <Core>\<Installer>\...      - what the installer just wrote
    # Several mods install OUTSIDE the game folder on purpose (Forza's
    # VRMod lives in C:\Games\Forza Horizon 5 VR). Their installer
    # cannot write into the game folder, while the SCAN seeds a stamp
    # there. Preferring the game stamp then pins an old value forever:
    # the user updates, the installer records the new version, and the
    # tile still reads the stale stamp and shows an Update badge that no
    # reinstall can clear. That is exactly what happened on Forza.
    # Taking the newer value is right in BOTH directions - after a Hub
    # replacement the game stamp is the only one left and still wins.
    $vGame = Read-VersionStampFile -Path (Get-GameStampPath -GameDir $GameDir)
    $vHub  = Read-VersionStampFile -Path (Get-InstalledVersionPath -Game $Game)
    $vKeep = Read-PersistentGameStateValue -Game $Game -Name 'installed_version'
    if (-not (Test-IsTrackableInstalledVersion -Version $vKeep)) { $vKeep = $null }

    $values = @(@($vGame, $vHub, $vKeep) | Where-Object { Test-IsTrackableInstalledVersion -Version ([string]$_) })
    if ($values.Count -eq 0) { return $null }
    $chosen = [string]$values[0]

    # Reconcile old installations in which only one of the copies was
    # refreshed.  Prefer a genuinely newer comparable value; when two
    # opaque tags cannot be ordered, the game-side value remains first.
    foreach ($candidate in $values | Select-Object -Skip 1) {
        try {
            if (Test-OnlineVersionIsNewer -Installed $chosen -Online $candidate) { $chosen = [string]$candidate }
        } catch {}
    }
    return $chosen
}

# Write installed version for a game - into the game folder AND the Hub
# copy. Passing no $GameDir keeps the old behaviour (Hub copy only), so
# a caller that has not resolved a folder yet still works.
function Write-InstalledVersion {
    param($Game, $Version, [string]$GameDir)
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { return }
    $val = ([string]$Version).Trim()
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($target in @(
        (Get-GameStampPath -GameDir $GameDir),
        (Get-InstalledVersionPath -Game $Game)
    )) {
        if (-not $target) { continue }
        # DO NOT WRITE WHEN THE SAME VALUE IS ALREADY THERE. One of the
        # callers in the scan reports "up to date" and writes the same
        # value while doing so - without this brake, every scan would
        # rewrite a file in the GAME FOLDER just to confirm itself. In
        # the settled state no write happens at all now.
        $same = $false
        try {
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $cur = Get-Content -LiteralPath $target -Raw -ErrorAction Stop
                if ((([string]$cur -replace '[^\x20-\x7E]', '').Trim()) -eq $val) { $same = $true }
            }
        } catch {}
        if ($same) { continue }
        try { [System.IO.File]::WriteAllText($target, $val, $enc) } catch {}
    }
    Write-PersistentGameStateValue -Game $Game -Name 'installed_version' -Value $val
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

function Read-InstalledVersionB {
    param($Game, [string]$GameDir)
    $values = @(@(
        (Read-VersionStampFile -Path (Get-GameStampPath -GameDir $GameDir -Second)),
        (Read-VersionStampFile -Path (Get-InstalledVersionPathB -Game $Game)),
        (Read-PersistentGameStateValue -Game $Game -Name 'installed_version_b')
    ) | Where-Object { Test-IsTrackableInstalledVersion -Version ([string]$_) })
    if ($values.Count -eq 0) { return $null }
    $chosen = [string]$values[0]
    foreach ($candidate in $values | Select-Object -Skip 1) {
        try {
            if (Test-OnlineVersionIsNewer -Installed $chosen -Online $candidate) { $chosen = [string]$candidate }
        } catch {}
    }
    return $chosen
}

function Write-InstalledVersionB {
    param($Game, $Version, [string]$GameDir)
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { return }
    $val = ([string]$Version).Trim()
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($target in @(
        (Get-GameStampPath -GameDir $GameDir -Second),
        (Get-InstalledVersionPathB -Game $Game)
    )) {
        if (-not $target) { continue }
        $same = $false
        try {
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $cur = Get-Content -LiteralPath $target -Raw -ErrorAction Stop
                if ((([string]$cur -replace '[^\x20-\x7E]', '').Trim()) -eq $val) { $same = $true }
            }
        } catch {}
        if (-not $same) { try { [System.IO.File]::WriteAllText($target, $val, $enc) } catch {} }
    }
    Write-PersistentGameStateValue -Game $Game -Name 'installed_version_b' -Value $val
}

# Remove installed version file (used when user clicks Update). The second
# marker goes with it - otherwise a two-mod entry would keep a stale
# version for mod B and show Update forever after an install.
# Mark the tracked version as UNKNOWN after a completed (re)install, so
# the next scan fills it in with whatever is current online.
#
# THIS DOES NOT DELETE ANYTHING, ON PURPOSE. It used to, and that was
# wrong twice over. First, a delete is a bigger operation than the job
# needs: the job is "this value is stale", and emptying a file says that
# just as well. Second, a delete is the one operation whose blast radius
# depends entirely on the path being right - get the path wrong by one
# empty string and you are removing a directory instead of a marker.
# Overwriting cannot do that: the worst a wrong path can do here is
# create or blank a stray 0-byte file, which the next scan overwrites.
#
# An empty marker reads back as $null (see Read-VersionStampFile), which
# is exactly the "no version recorded" state the scan already handles.
# Files that do not exist are left alone - no new files are created.
function Reset-InstalledVersion {
    param($Game, [string]$GameDir)
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($path in @(
        (Get-InstalledVersionPath  -Game $Game),
        (Get-InstalledVersionPathB -Game $Game),
        (Get-GameStampPath -GameDir $GameDir),
        (Get-GameStampPath -GameDir $GameDir -Second)
    )) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            try { [System.IO.File]::WriteAllText($path, "", $enc) } catch {}
        }
    }
    Reset-PersistentGameStateValue -Game $Game -Name 'installed_version'
    Reset-PersistentGameStateValue -Game $Game -Name 'installed_version_b'
}

# Path to the per-game ".update_ok" marker the installer wrapper drops
# next to .installed_version when its core ran to completion. A cancel
# inside the core calls 'exit' first, so the marker is absent on cancel.
function Get-UpdateOkMarkerPath {
    param($Game)
    $vp = Get-InstalledVersionPath -Game $Game
    if (-not $vp) { return $null }
    $leaf = Split-Path -Leaf $vp
    if ($leaf -like '.installed_version_*') {
        return ([IO.Path]::Combine((Split-Path -Parent $vp), ($leaf -replace '^\.installed_version_', '.update_ok_')))
    }
    return ([IO.Path]::Combine((Split-Path -Parent $vp), ".update_ok"))
}

# Clear a stale completion marker before launching an update installer,
# so only a freshly completed run can clear the tracked version.
# This one stays a delete: it is a PRESENCE flag - "the installer core
# finished" - and a flag you cannot remove is not a flag. It lives in the
# Hub's own Core\<Game>\ folder under a fixed literal name, so no path
# here can ever point at user data. -PathType Leaf all the same.
function Clear-UpdateOkMarker {
    param($Game)
    $mk = Get-UpdateOkMarkerPath -Game $Game
    if ($mk -and (Test-Path -LiteralPath $mk -PathType Leaf)) {
        Remove-Item -LiteralPath $mk -Force -ErrorAction SilentlyContinue
    }
}

# -------------------------------------------------------
# Module loader. The Hub used to live in a single 10k-line
# VRModHub.ps1; it is now split into focused modules under
# .\Modules\. Order matters - each module assumes the prior
# ones have already defined their helpers, $window, globals
# etc. Do not reorder without checking dependencies.
# -------------------------------------------------------
# HERE, BEFORE THE MODULES ARE LOADED. Startup.ps1 is the LAST module
# in the loop below and calls $window.ShowDialog() inside it - so
# anything placed AFTER the loop only runs when the window closes.
# This repair has to take effect before the first scan, so it goes
# ahead of the loop.
# -------------------------------------------------------
#  ONE-OFF REPAIR: wrong version marker for BotW
#  THROWAWAY CODE - ADDED 2026-08-10, REMOVE FROM HUB 0.8.6.x
# -------------------------------------------------------
# One shipped bundle accidentally contained
# Core\BreathOfTheWildVR\.installed_version holding "1.0" - written
# during the build, not by an install. The scan compares that value
# against BetterVR's GitHub tag (0.9.x) and therefore shows a permanent
# update badge that never goes away.
#
# WHY A NEW BUNDLE ALONE IS NOT ENOUGH: the updater copies with
# robocopy and has .installed_version on its exclusion list (/XF) so
# real user data survives. The wrong file therefore stays behind even
# after a Hub update and has to be cleared actively.
#
# NOTHING IS LEFT BEHIND. No marker, no new file in the Hub folder:
# this block needs none because it DISARMS ITSELF. After clearing, the
# file no longer says "1.0", and the next scan writes the real tag into
# it - so the condition never holds again. An earlier draft created
# .repair_botw_marker for this; that was needless litter in a folder
# updates never remove anything from.
#
# CLEARED, NOT DELETED, and only on exactly this content.
try {
    $badMarker = Join-Path $scriptDir "BreathOfTheWildVR\.installed_version"
    if (Test-Path -LiteralPath $badMarker -PathType Leaf) {
        # -ErrorAction Stop, NOT SilentlyContinue: a failed
        # A FAILED READ (file locked, antivirus, permissions) must not
        # pass as "the content is not 1.0". It lands in the catch, and
        # the next start tries again.
        $cur = Get-Content -LiteralPath $badMarker -Raw -ErrorAction Stop
        if ((([string]$cur -replace '[^\x20-\x7E]', '').Trim()) -eq "1.0") {
            [System.IO.File]::WriteAllText($badMarker, "", (New-Object System.Text.UTF8Encoding $false))
        }
    }
} catch {}

$modulesDir = Join-Path $scriptDir "Modules"
foreach ($mod in @(
    "Catalog.ps1",
    "BannerColors.ps1",
    "Helpers.ps1",
    "CardTile.ps1",
    "Window.ps1",
    "ScanSpinner.ps1",
    "DiscoverInit.ps1",
    "UninstallGuide.ps1",
    "ReadmeLinks.ps1",
    "EldenRingSaveUI.ps1",
    "DetailView.ps1",
    "OverviewPage.ps1",
    "BannerOvFilters.ps1",
    "Filter.ps1",
    "Startup.ps1"
)) {
    . (Join-Path $modulesDir $mod)
    Write-HubTiming ("module loaded: {0}" -f $mod)
}
