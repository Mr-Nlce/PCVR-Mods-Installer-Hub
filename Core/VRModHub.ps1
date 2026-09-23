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

# Load the WPF-free durable-state layer before anything creates runtime files.
# LocalAppData is authoritative; <Hub>\Core\UserData receives only its verified
# recovery copy.  Keeping this ahead of logging/settings also leaves the Hub
# program tree replaceable without losing user state.
. (Join-Path $scriptDir "Modules\HubState.ps1")

# Path to the installer log wrapper (used by Start-LoggedInstaller).
$global:RunInstallerPath = Join-Path $scriptDir "Run-Installer.ps1"

# Session log: capture the Hub's own console output to Core\Logs.
# Windows PowerShell 5.1 has no minimal transcript header and therefore writes
# profile/computer names, its full command line and many runtime internals.
# Keep the live crash evidence, then compact it into a privacy-safe log when
# the Hub closes. A transcript left by a crash is compacted on the next start.
function global:ConvertTo-HubPrivacySafeText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $safeText = [string]$Text
    foreach ($pair in @(
        @($env:LOCALAPPDATA, '%LOCALAPPDATA%'),
        @($env:APPDATA, '%APPDATA%'),
        @($env:TEMP, '%TEMP%'),
        @($env:USERPROFILE, '%USERPROFILE%'),
        @($env:COMPUTERNAME, '%COMPUTERNAME%')
    )) {
        $value = [string]$pair[0]
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        $safeText = [regex]::Replace($safeText, [regex]::Escape($value), [string]$pair[1], [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    return $safeText
}

function global:Compress-HubSessionLog {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    try {
        $rawLines = @(Get-Content -LiteralPath $Path -ErrorAction Stop)
        $started = ''
        $psVersion = ''
        foreach ($line in $rawLines) {
            if (-not $started -and $line -match '^Started:\s*(.+)$') { $started = $matches[1].Trim() }
            if (-not $psVersion -and $line -match '^PSVersion:\s*(.+)$') { $psVersion = $matches[1].Trim() }
            if (-not $psVersion -and $line -match '^PowerShell:\s*([^\s]+)') { $psVersion = $matches[1].Trim() }
        }
        if (-not $started) { $started = (Get-Item -LiteralPath $Path).CreationTime.ToString('yyyy-MM-dd HH:mm:ss') }
        if (-not $psVersion) { $psVersion = '' + $PSVersionTable.PSVersion }

        $payload = New-Object 'System.Collections.Generic.List[string]'
        $seenUpdateEvidence = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
        $lastBlank = $false
        foreach ($rawLine in $rawLines) {
            $line = [string]$rawLine
            if ($line -match '^=== PCVR Mods Installer Hub - Session Log ===$' -or
                $line -match '^Started:\s*' -or $line -match '^Hub Core:\s*' -or
                $line -match '^Windows:\s*' -or $line -match '^PowerShell:\s*' -or
                $line -match '^=+$' -or $line -match '^\*+$' -or
                $line -match '(?i)^(n?Start der Windows PowerShell-Aufzeichnung|Ende der Windows PowerShell-Aufzeichnung|Windows PowerShell transcript (start|end))$' -or
                $line -match '(?i)^(Startzeit|Endzeit|Start time|End time|Benutzername|Username|RunAs-Benutzer|RunAs User|Konfigurationsname|Configuration Name|Computer|Machine|Hostanwendung|Host Application|Prozess-ID|Process ID|PSVersion|PSEdition|PSCompatibleVersions|BuildVersion|CLRVersion|WSManStackVersion|PSRemotingProtocolVersion|SerializationVersion):') {
                continue
            }
            $line = ConvertTo-HubPrivacySafeText $line
            if ($line -match '^\[UpdateCheck\]') {
                if (-not $seenUpdateEvidence.Add($line)) { continue }
            }
            if ([string]::IsNullOrWhiteSpace($line)) {
                if ($lastBlank) { continue }
                $lastBlank = $true
                [void]$payload.Add('')
                continue
            }
            $lastBlank = $false
            [void]$payload.Add($line)
        }
        while ($payload.Count -gt 0 -and [string]::IsNullOrWhiteSpace($payload[$payload.Count - 1])) { $payload.RemoveAt($payload.Count - 1) }

        $clean = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in @(
            '=== PCVR Mods Installer Hub - Session Log ===',
            "Started:    $started",
            "Windows:    $([Environment]::OSVersion.VersionString)",
            "PowerShell: $psVersion ($($PSVersionTable.PSEdition))",
            '============================================='
        )) { [void]$clean.Add($line) }
        if ($payload.Count) { [void]$clean.Add(''); foreach ($line in $payload) { [void]$clean.Add($line) } }
        [IO.File]::WriteAllLines($Path, [string[]]$clean, (New-Object Text.UTF8Encoding($false)))
    } catch {}
}

$script:HubTranscriptStarted = $false
try {
    $logsDir = Get-HubRuntimeLogsRoot
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
    foreach ($oldHubLog in @(Get-ChildItem $logsDir -Filter 'Hub-*.log' -File -ErrorAction SilentlyContinue)) {
        Compress-HubSessionLog -Path $oldHubLog.FullName
    }
    # -File: without it a DIRECTORY called something.log would come back
    # from the filter and get handed to Remove-Item. Cheap guard, and the
    # rule everywhere now is that a delete only ever sees a file.
    Get-ChildItem $logsDir -Filter *.log -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 30 |
        Remove-Item -Force -ErrorAction SilentlyContinue
    $hubLog = Join-Path $logsDir ("Hub-{0}.log" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))
    @(
        '=== PCVR Mods Installer Hub - Session Log ===',
        ('Started:    ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
        ('Windows:    ' + [Environment]::OSVersion.VersionString),
        ('PowerShell: ' + $PSVersionTable.PSVersion + ' (' + $PSVersionTable.PSEdition + ')'),
        '============================================='
    ) | Out-File -LiteralPath $hubLog -Encoding utf8
    Start-Transcript -Path $hubLog -Append -ErrorAction Stop | Out-Null
    $script:HubTranscriptStarted = $true
} catch {}

# -------------------------------------------------------
# Startup timing (diagnostic, opt-in).
# Enable by creating an empty file '.timing' in the Hub root
# or by setting PCVR_HUB_STARTUP_TIMING=1 for an isolated test run.
# When enabled, phase timestamps are
# appended to %TEMP%\PCVRHub_startup.log so we can see where the
# startup time goes. No file is written to the Hub itself
# (state-file ship guard - rule #2 / audit #15).
# -------------------------------------------------------
$global:HubTiming = @{ Enabled = $false; Start = $null; Log = $null }
try {
    $timingFlag = Join-Path $rootDir ".timing"
    if ((Test-Path $timingFlag) -or $env:PCVR_HUB_STARTUP_TIMING -eq '1') {
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
$HUB_VERSION = "0.8.7.6"

$updateInfoFile  = Get-HubUpdateInfoPath
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

# Read the recorded install path. The single LocalAppData state is primary;
# Get-InstalledPathFile names only the old per-installer receipt that existing
# installers may still emit and that is imported once for compatibility.
function Read-InstalledPath {
    param($Game)
    $hubFile = Get-InstalledPathFile -Game $Game
    $hubValue = $null
    if ($hubFile -and (Test-Path -LiteralPath $hubFile -PathType Leaf)) {
        try { $hubValue = ("" + (Get-Content -LiteralPath $hubFile -Raw -ErrorAction Stop)).Trim() } catch {}
    }
    $durableValue = Read-PersistentGameStateValue -Game $Game -Name 'installed_path'
    # LocalAppData is authoritative. The old Hub marker is consulted only
    # when no valid canonical path exists, then imported once. Never mirror
    # the canonical value back into per-game folders: Core\UserData is the
    # only Hub-side copy.
    foreach ($candidate in @($durableValue, $hubValue)) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        if ($candidate -eq $hubValue) {
            Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $candidate
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
                $bRoot = if ($Game.ModBRootLaunch -and $Game.ModBLaunch) { Join-Path $candidate $Game.ModBLaunch } else { $null }
                $evidence = (($a -and (Test-Path -LiteralPath $a -PathType Leaf)) -or
                             ($b -and (Test-Path -LiteralPath $b -PathType Leaf)) -or
                             ($bRoot -and (Test-Path -LiteralPath $bRoot -PathType Leaf)))
            } elseif ($Game.ModFile) {
                $evidence = Test-Path -LiteralPath (Join-Path $candidate $Game.ModFile) -PathType Leaf
            } elseif ($Game.LaunchExe) {
                $evidence = Test-Path -LiteralPath (Join-Path $candidate $Game.LaunchExe) -PathType Leaf
            }
        } catch { $evidence = $false }
        if (-not $evidence) { continue }
        Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $candidate
        return $candidate
    }
    return $null
}

# WHERE DOES THE DEPOT BUILD ACTUALLY LIVE?
# The catalog field DepotPath is a FIXED suggestion
# (C:\Games\<game> VR), but the installer lets the user choose the
# folder freely. Older installers write the chosen one into .installed_path;
# the Hub imports it into the canonical state after confirmed success.
# Anyone installing elsewhere used to be invisible to the Hub: both the
# start-depot button and the split-button detection only looked at the
# catalog path. So query both sources, catalog path first.
# The recorded path only counts when it is NOT under
# steamapps\common - that is where the normal Steam copy lives, and
# that is the other half of a DualMode entry, not the depot build.
function Get-DepotCandidatePaths {
    param($Game)
    $out = @()
    # The disposable installer lab supplies recorded roots for every title and
    # must not probe real C:\Games depots on the host PC. Production never sets
    # HubFileSystemLabRoot, so normal catalog suggestions are unchanged.
    if (-not $global:HubFileSystemLabRoot -and $Game.DepotPath) { $out += [string]$Game.DepotPath }

    # A game may have more than one pinned depot (PEAK: recommended
    # Andrey 2.1.a plus legacy Astien 1.44.a). In that case only the
    # dedicated depot marker may feed the normal Depot button. Falling
    # back to .installed_path would let the last installed legacy copy
    # silently hijack the recommended button.
    if ($Game.DepotInstalledPathFile) {
        try {
            $base = Get-InstalledPathFile -Game $Game
            $variantFile = if ($base) { Join-Path (Split-Path -Parent $base) ([string]$Game.DepotInstalledPathFile) } else { $null }
            $hubValue = if ($variantFile -and (Test-Path -LiteralPath $variantFile -PathType Leaf)) {
                ("" + (Get-Content -LiteralPath $variantFile -Raw -ErrorAction Stop)).Trim()
            } else { $null }
            $durableValue = Read-PersistentGameStateValue -Game $Game -Name 'installed_path_depot'
            foreach ($candidate in @($durableValue, $hubValue)) {
                if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
                if ($out -notcontains $candidate) { $out += $candidate }
                if ($candidate -eq $hubValue) { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_depot' -Value $candidate }
                break
            }
        } catch {}
        return $out
    }
    try {
        $rec = Read-InstalledPath -Game $Game
        # Separator-independent, so the check does not slip past on a
        # forward slash.
        if ($rec -and ($rec -notmatch '(?i)steamapps[\\/]+common') -and ($out -notcontains $rec)) { $out += $rec }
    } catch {}
    return $out
}

function Get-LegacyDepotCandidatePaths {
    param($Game)
    $out = @()
    if (-not $Game -or -not $Game.LegacyDepotPath) { return $out }
    if (-not $global:HubFileSystemLabRoot) {
        $out += [string]$Game.LegacyDepotPath
        foreach ($candidate in @($Game.LegacyDepotFallbackPaths | Where-Object { $_ })) {
            if ($out -notcontains [string]$candidate) { $out += [string]$candidate }
        }
    }
    if (-not $Game.LegacyDepotInstalledPathFile) { return $out }
    $hasDedicatedValue = $false
    try {
        $base = Get-InstalledPathFile -Game $Game
        $variantFile = if ($base) { Join-Path (Split-Path -Parent $base) ([string]$Game.LegacyDepotInstalledPathFile) } else { $null }
        $hubValue = if ($variantFile -and (Test-Path -LiteralPath $variantFile -PathType Leaf)) {
            ("" + (Get-Content -LiteralPath $variantFile -Raw -ErrorAction Stop)).Trim()
        } else { $null }
        $durableValue = Read-PersistentGameStateValue -Game $Game -Name 'installed_path_legacy_depot'
        foreach ($candidate in @($durableValue, $hubValue)) {
            if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
            if ($out -notcontains $candidate) { $out += $candidate }
            $hasDedicatedValue = $true
            if ($candidate -eq $hubValue) { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_legacy_depot' -Value $candidate }
            break
        }
    } catch {}
    # A superseded standalone route may have been the only route when its
    # ordinary .installed_path was written. Use that migration source only
    # until a dedicated legacy receipt exists; every caller still verifies the
    # exact legacy launcher and VR marker before accepting it.
    if ($Game.LegacyDepotUseRecordedPath -and -not $hasDedicatedValue) {
        try {
            $recorded = Read-InstalledPath -Game $Game
            if ($recorded -and (Test-Path -LiteralPath $recorded -PathType Container) -and ($out -notcontains $recorded)) {
                $out += $recorded
            }
        } catch {}
    }
    return $out
}

function Get-CurrentStandaloneCandidatePaths {
    param($Game)
    $out = @()
    if (-not $Game) { return $out }
    if (-not $global:HubFileSystemLabRoot) {
        foreach ($candidate in @($Game.CurrentStandalonePaths | Where-Object { $_ })) {
            if ($out -notcontains [string]$candidate) { $out += [string]$candidate }
        }
    }
    try {
        $durableValue = Read-PersistentGameStateValue -Game $Game -Name 'installed_path_current'
        $hubValue = $null
        if ($Game.CurrentInstalledPathFile) {
            $base = Get-InstalledPathFile -Game $Game
            $variantFile = if ($base) { Join-Path (Split-Path -Parent $base) ([string]$Game.CurrentInstalledPathFile) } else { $null }
            if (Test-Path -LiteralPath $variantFile -PathType Leaf) {
                $hubValue = ('' + (Get-Content -LiteralPath $variantFile -Raw -ErrorAction Stop)).Trim().Trim('"')
            }
        }
        $durableUsable = $durableValue -and (Test-Path -LiteralPath $durableValue -PathType Container)
        $recorded = if ($durableUsable -or $hubValue) { $null } else { Read-InstalledPath -Game $Game }
        foreach ($candidate in @($durableValue, $hubValue,$recorded)) {
            if ([string]::IsNullOrWhiteSpace([string]$candidate) -or
                -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
            if ($out -notcontains [string]$candidate) { $out += [string]$candidate }
            if ($candidate -eq $hubValue) { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_current' -Value $candidate }
        }
    } catch {}
    return $out
}

# The "Locate Game" exe-picker records the exact executable in the canonical
# state (e.g. a differently named exe from another store). The legacy
# .launch_exe path below remains solely as a one-way migration source.
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
    foreach ($candidate in @($durableValue, $hubValue)) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        if ($candidate -eq $hubValue) {
            Write-PersistentGameStateValue -Game $Game -Name 'launch_exe' -Value $candidate
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
# The canonical value now lives in one checksummed LocalAppData document. A
# checksummed install manifest and the compact marker beside the mod provide
# recovery evidence after Hub replacement. Old Hub-folder markers are imported
# only when the canonical value is absent, then become inert.
# Path of the in-game marker. $Second is the B slot for entries that
# track TWO mods in one tile (BioShock), mirroring the Hub-local
# .installed_version / _b pair.
#
# THE NAME IS A LITERAL IN HERE, deliberately. An earlier draft read it
# from a $global set at module load. When that global was empty for any
# reason the name became "", the path combiner handed back THE GAME FOLDER
# ITSELF - and back then this path was handed to a delete. The literal
# cannot be unset, and the guard below refuses any result that is not
# strictly below $GameDir. Nothing in this file deletes these markers (see
# Invalidate-SupersededInstalledVersion), so that class of accident is gone at the
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

# Import an exact installer result even when the UI timer that normally handles
# it did not get a chance to run (Hub closed, scan already busy, Windows focus
# change, etc.). The transaction remains until either post-install refresh or a
# later scan has durably copied its exact value into canonical state. This
# closes the retry loop where the first successful run wrote the new version, a
# missed timer left the old canonical value behind, and every repeat then
# appeared to write "nothing new".
function Import-PendingInstallerVersion {
    param($Game, [string]$GameDir, [switch]$Second)
    if (-not $Game -or -not (Get-Command Get-UpdateOkMarkerPath -ErrorAction SilentlyContinue)) { return $null }
    $path = Get-UpdateOkMarkerPath -Game $Game
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $status = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
        if (-not $status -or ([string]$status.outcome -ne 'success')) { return $null }
        $wasWritten = if ($Second) { [bool]$status.versionBWritten } else { [bool]$status.versionWritten }
        if (-not $wasWritten) { return $null }
        $exact = if ($Second) { ('' + $status.versionBValue).Trim() } else { ('' + $status.versionValue).Trim() }
        if (-not (Test-IsTrackableInstalledVersion -Version $exact)) { return $null }
        $root = $GameDir
        if (-not $root -and $status.installedPath -and (Test-Path -LiteralPath ([string]$status.installedPath) -PathType Container)) {
            $root = [string]$status.installedPath
        }
        if ($Second) { Write-InstalledVersionB -Game $Game -Version $exact -GameDir $root }
        else { Write-InstalledVersion -Game $Game -Version $exact -GameDir $root }
        $saved = if ($Second) {
            Read-PersistentGameStateValue -Game $Game -Name 'installed_version_b'
        } else {
            Read-PersistentGameStateValue -Game $Game -Name 'installed_version'
        }
        if (([string]$saved).Trim() -ceq $exact) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
        return $exact
    } catch { return $null }
}

# Some upstream packages carry their own immutable version file. A catalog
# entry may opt in with InstalledVersionProofFile + InstalledVersionProofRegex.
# Unlike a generic recovery marker, this is release-owned evidence and can
# safely repair a missed transaction when it proves a genuinely newer build.
function Read-InstalledVersionProof {
    param($Game, [string]$GameDir)
    if (-not $Game -or -not $GameDir -or -not $Game.InstalledVersionProofFile) { return $null }
    try {
        $root = [IO.Path]::GetFullPath([string]$GameDir).TrimEnd([char[]]@('\','/'))
        $path = [IO.Path]::GetFullPath([IO.Path]::Combine($root, [string]$Game.InstalledVersionProofFile))
        $prefix = $root + [IO.Path]::DirectorySeparatorChar
        if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $null }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
        $raw = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
        $pattern = '' + $Game.InstalledVersionProofRegex
        if ([string]::IsNullOrWhiteSpace($pattern)) { $pattern = '(?im)^\s*(?:version|tag)\s*:\s*(v?[0-9][^\r\n]*)\s*$' }
        $match = [regex]::Match([string]$raw, $pattern)
        if (-not $match.Success) { return $null }
        $value = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { $match.Value }
        $value = ([string]$value).Trim()
        if (Test-IsTrackableInstalledVersion -Version $value) { return $value }
    } catch {}
    return $null
}

# Read installed version for a game. LocalAppData wins. The checked install
# manifest and old marker files are recovery sources only and are imported
# when the canonical value is absent.
function Read-InstalledVersion {
    param($Game, [string]$GameDir)
    $pending = Import-PendingInstallerVersion -Game $Game -GameDir $GameDir
    if (Test-IsTrackableInstalledVersion -Version $pending) { return ([string]$pending) }
    $vKeep = Read-PersistentGameStateValue -Game $Game -Name 'installed_version'
    if (Test-IsTrackableInstalledVersion -Version $vKeep) {
        $proof = Read-InstalledVersionProof -Game $Game -GameDir $GameDir
        if ($proof -and (Get-Command Test-OnlineVersionIsNewer -ErrorAction SilentlyContinue) -and
            (Test-OnlineVersionIsNewer -Installed ([string]$vKeep) -Online ([string]$proof))) {
            Write-InstalledVersion -Game $Game -Version $proof -GameDir $GameDir
            return ([string]$proof)
        }
        return ([string]$vKeep)
    }

    $proof = Read-InstalledVersionProof -Game $Game -GameDir $GameDir
    if (Test-IsTrackableInstalledVersion -Version $proof) {
        Write-InstalledVersion -Game $Game -Version $proof -GameDir $GameDir
        return ([string]$proof)
    }

    # A confirmed successful legacy installer may be unable to tell us the
    # exact new release (for example while its source is temporarily offline).
    # In that state old game-side recovery is known to be superseded and must
    # not be imported again.  The durable block survives Hub replacement via
    # Core\UserData and is removed as soon as an exact version is written.
    if ((Read-PersistentGameStateValue -Game $Game -Name 'installed_version_recovery_blocked') -eq '1') { return $null }

    $recovery = @(
        (Read-HubInstallManifestVersion -Game $Game -GameDir $GameDir),
        (Read-VersionStampFile -Path (Get-GameStampPath -GameDir $GameDir)),
        (Read-VersionStampFile -Path (Get-InstalledVersionPath -Game $Game))
    )
    foreach ($candidate in $recovery) {
        if (-not (Test-IsTrackableInstalledVersion -Version $candidate)) { continue }
        $chosen = ([string]$candidate).Trim()
        Write-PersistentGameStateValue -Game $Game -Name 'installed_version' -Value $chosen
        if ($GameDir) { Write-HubInstallManifestVersion -Game $Game -GameDir $GameDir -Version $chosen }
        return $chosen
    }
    return $null
}

# Write the installed version to canonical state and, when the install path is
# known, to the installation-side recovery marker and manifest as well.
function Write-InstalledVersion {
    param($Game, $Version, [string]$GameDir)
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { return }
    $val = ([string]$Version).Trim()
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($target in @((Get-GameStampPath -GameDir $GameDir))) {
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
        $targetDir = Split-Path -Parent $target
        if ((Get-Command Test-HubDirectoryWritableQuiet -ErrorAction SilentlyContinue) -and
            -not (Test-HubDirectoryWritableQuiet -Directory $targetDir)) { continue }
        try { [System.IO.File]::WriteAllText($target, $val, $enc) } catch {}
    }
    Write-PersistentGameStateValue -Game $Game -Name 'installed_version' -Value $val
    Reset-PersistentGameStateValue -Game $Game -Name 'installed_version_recovery_blocked'
    if ($GameDir) { Write-HubInstallManifestVersion -Game $Game -GameDir $GameDir -Version $val }
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
    $pending = Import-PendingInstallerVersion -Game $Game -GameDir $GameDir -Second
    if (Test-IsTrackableInstalledVersion -Version $pending) { return ([string]$pending) }
    $keep = Read-PersistentGameStateValue -Game $Game -Name 'installed_version_b'
    if (Test-IsTrackableInstalledVersion -Version $keep) { return ([string]$keep) }
    if ((Read-PersistentGameStateValue -Game $Game -Name 'installed_version_b_recovery_blocked') -eq '1') { return $null }
    foreach ($candidate in @(
        (Read-HubInstallManifestVersion -Game $Game -GameDir $GameDir -Second),
        (Read-VersionStampFile -Path (Get-GameStampPath -GameDir $GameDir -Second)),
        (Read-VersionStampFile -Path (Get-InstalledVersionPathB -Game $Game))
    )) {
        if (-not (Test-IsTrackableInstalledVersion -Version $candidate)) { continue }
        $chosen = ([string]$candidate).Trim()
        Write-PersistentGameStateValue -Game $Game -Name 'installed_version_b' -Value $chosen
        if ($GameDir) { Write-HubInstallManifestVersion -Game $Game -GameDir $GameDir -Version $chosen -Second }
        return $chosen
    }
    return $null
}

function Write-InstalledVersionB {
    param($Game, $Version, [string]$GameDir)
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { return }
    $val = ([string]$Version).Trim()
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($target in @((Get-GameStampPath -GameDir $GameDir -Second))) {
        if (-not $target) { continue }
        $same = $false
        try {
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $cur = Get-Content -LiteralPath $target -Raw -ErrorAction Stop
                if ((([string]$cur -replace '[^\x20-\x7E]', '').Trim()) -eq $val) { $same = $true }
            }
        } catch {}
        if (-not $same) {
            $targetDir = Split-Path -Parent $target
            if ((Get-Command Test-HubDirectoryWritableQuiet -ErrorAction SilentlyContinue) -and
                -not (Test-HubDirectoryWritableQuiet -Directory $targetDir)) { continue }
            try { [System.IO.File]::WriteAllText($target, $val, $enc) } catch {}
        }
    }
    Write-PersistentGameStateValue -Game $Game -Name 'installed_version_b' -Value $val
    Reset-PersistentGameStateValue -Game $Game -Name 'installed_version_b_recovery_blocked'
    if ($GameDir) { Write-HubInstallManifestVersion -Game $Game -GameDir $GameDir -Version $val -Second }
}

# A completed legacy installer and a cancelled installer are different state
# transitions.  Cancellation leaves every recovery source untouched.  A
# CONFIRMED success without an exact version makes the former version stale:
# block its recovery durably, then clear only the selected slot's comparison
# evidence.  Exact known files are blanked rather than deleted, and the central
# block still protects correctness when the game directory is read-only.
function Invalidate-SupersededInstalledVersion {
    param($Game, [string]$GameDir, [switch]$Second)
    if (-not $Game) { return }
    $versionName = if ($Second) { 'installed_version_b' } else { 'installed_version' }
    $blockName = if ($Second) { 'installed_version_b_recovery_blocked' } else { 'installed_version_recovery_blocked' }

    # Block first.  If the process is interrupted between these two writes, the
    # old canonical value still wins; once it is removed no stale fallback can
    # race back in.
    Write-PersistentGameStateValue -Game $Game -Name $blockName -Value '1'
    Reset-PersistentGameStateValue -Game $Game -Name $versionName

    $targets = @(
        (Get-GameStampPath -GameDir $GameDir -Second:$Second),
        $(if ($Second) { Get-InstalledVersionPathB -Game $Game } else { Get-InstalledVersionPath -Game $Game })
    )
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($target in $targets) {
        if (-not $target -or -not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        $leaf = [IO.Path]::GetFileName([string]$target)
        if ($leaf -notmatch '^\.pcvrhub_version(?:_b)?$' -and $leaf -notmatch '^\.installed_version(?:_[A-Za-z0-9_]+)?(?:_b)?$') { continue }
        try { [IO.File]::WriteAllText([string]$target, '', $enc) } catch {}
    }
    if ($GameDir) { Clear-HubInstallManifestVersion -Game $Game -GameDir $GameDir -Second:$Second }
}

# Path to the per-game installer transaction result. It is transient runtime
# data in LocalAppData, never durable state and never part of the Hub folder.
function Get-UpdateOkMarkerPath {
    param($Game)
    $root = Get-HubRuntimeRoot
    $id = Get-HubGameStateId -Game $Game
    if (-not $root -or -not $id) { return $null }
    return [IO.Path]::Combine($root, 'Transactions', ('install_' + $id + '.json'))
}

# Clear a stale completion marker before launching an update installer,
# so only a freshly completed run can clear the tracked version.
# This one stays a delete: it is a presence flag under the fixed per-user
# Transactions directory, never a game file or user save. -PathType Leaf
# ensures a malformed path can never remove a directory.
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
    "CatalogSort.ps1",
    "Startup.ps1"
)) {
    . (Join-Path $modulesDir $mod)
    Write-HubTiming ("module loaded: {0}" -f $mod)
}
