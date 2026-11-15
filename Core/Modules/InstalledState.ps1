# Installed-state helpers (moved from VRModHub.ps1). Shared by the WPF Hub,
# Helpers.ps1 consumers and the native Hub's PowerShell game modules.
# Defined global: so a later global: override (native launch) wins.
# -------------------------------------------------------
# Mod version tracking helpers
# -------------------------------------------------------
# Parse a version number out of a Mod display string, e.g.
#   "L4D2VR v0.6.4"           -> "0.6.4"
#   "R.E.A.L. VR v2603.10.1"  -> "2603.10.1"
#   "NomaiVR 2.10.0"          -> "2.10.0"
#   "Fully Possessed v0.021j" -> "0.021j"
# Returns $null if no version-looking token is found.
function global:Get-ModVersionFromString {
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
function global:Test-IsTrackableInstalledVersion {
    param($Version)
    if ($null -eq $Version) { return $false }
    # Reject release/package objects instead of stringifying them into state.
    if ($Version -isnot [string] -and $Version -isnot [ValueType] -and $Version -isnot [version]) { return $false }
    $versionText = ([string]$Version).Trim()
    if ([string]::IsNullOrWhiteSpace($versionText) -or $versionText.Length -gt 128 -or $versionText -match '[\r\n{}]') { return $false }
    return ($versionText -match '\d')
}

# Given a $game hash, return full path to its .installed_version file.
# Derived from the Bat field: "L4D2VR\START_INSTALLER.bat" -> Core\L4D2VR\.installed_version
# Returns $null if game has no Bat or Bat is malformed.
function global:Get-HubRelativeDirectory {
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

function global:Get-InstalledVersionPath {
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
function global:Get-InstalledPathFile {
    param($Game)
    if (-not $Game) { return $null }
    # Pure function of the catalog entry, asked several times per game and
    # scan. Memoized for the scan's lifetime only (HubScanEvidenceCache).
    $memo = $null
    if ($global:HubScanEvidenceCache) {
        $memo = $global:HubScanEvidenceCache['PathFiles']
        if ($null -eq $memo) { $memo = [Collections.Generic.Dictionary[object,object]]::new(); $global:HubScanEvidenceCache['PathFiles'] = $memo }
        $hit = $null
        if ($memo.TryGetValue($Game, [ref]$hit)) { return $hit }
    }
    $value = . {
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
    if ($null -ne $memo) { $memo[$Game] = $value }
    return $value
}

# Read the recorded install path. The single LocalAppData state is primary;
# Get-InstalledPathFile names only the old per-installer receipt that existing
# installers may still emit and that is imported once for compatibility.
function global:Read-InstalledPath {
    param($Game)
    # Preserve the canonical -> explicit Locate -> legacy priority, but do
    # not read two unused fallbacks for every already-known installed title.
    $durableValue=Read-PersistentGameStateValue -Game $Game -Name 'installed_path'
    if($durableValue -and [IO.Directory]::Exists($durableValue)){return $durableValue}
    $locatedValue=Read-PersistentGameStateValue -Game $Game -Name 'user_located'
    if($locatedValue -and [IO.Directory]::Exists($locatedValue)){return $locatedValue}
    $hubFile=Get-InstalledPathFile -Game $Game
    if($hubFile -and [IO.File]::Exists($hubFile)){
        try{
            $hubValue=[IO.File]::ReadAllText($hubFile).Trim()
            if($hubValue -and [IO.Directory]::Exists($hubValue)){
                Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $hubValue
                return $hubValue
            }
        }catch{}
    }

    # Related editions may share a game folder, but never share presence or
    # version claims. Recover only a folder with this title's full base proof.
    foreach ($relatedId in @($Game.RelatedGameLocationIds)) {
        if (-not $relatedId -or -not $Game.BaseGameProofFiles) { continue }
        $related = [pscustomobject]@{Id=$relatedId;Title=''}
        foreach ($name in @('user_located','installed_path')) {
            $candidate = Read-PersistentGameStateValue -Game $related -Name $name
            if ($candidate -and (Test-BaseGameInstallProof -Game $Game -Root $candidate)) {
                Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $candidate
                if ((Read-PersistentGameStateValue -Game $Game -Name 'installed_path') -cne $candidate) { throw 'Recovered game location could not be saved.' }
                return $candidate
            }
        }
    }

    # Migration path for known external launcher roots created by older Hub
    # builds before the LocalAppData index existed.  Evidence is mandatory:
    # merely having C:\Games\<name> is not enough to claim an install.
    $recoveryRoots=@($Game.DurableInstallRoots)
    if ($Game.SeparateLauncherBaseGame -or $Game.VrInstallRoot -or $Game.RequiresRom) {
        try { $recoveryRoots+=@(Resolve-VrInstallRoot $Game.VrInstallRoot) } catch {}
        $recoveryRoots+=@($Game.FallbackPaths | Where-Object { $_ -and [IO.Path]::IsPathRooted([string]$_) })
    }
    foreach ($candidate in @($recoveryRoots | Where-Object { $_ } | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        if ($global:HubFileSystemLabRoot) {
            $labPrefix=[IO.Path]::GetFullPath($global:HubFileSystemLabRoot).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
            if (-not [IO.Path]::GetFullPath($candidate).StartsWith($labPrefix,[StringComparison]::OrdinalIgnoreCase)) { continue }
        }
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
        if (Get-Command Test-LocatedVrRuntime -ErrorAction SilentlyContinue) {
            if (-not (Test-LocatedVrRuntime -Game $Game -Root $candidate -Requested)) { continue }
        }
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
function global:Get-DepotCandidatePaths {
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
    # Opted-in historical installers used one generic receipt for both roots.
    # Keep that ordinary source first; a separately recovered location is only
    # an additional candidate, and the scanner still proves its Depot files.
    if ($Game.DepotRecoveryInstalledPathFile) {
        try {
            $durable = Read-PersistentGameStateValue -Game $Game -Name 'installed_path_depot'
            $base = Get-InstalledPathFile -Game $Game
            $file = if ($base) { Join-Path (Split-Path -Parent $base) ([string]$Game.DepotRecoveryInstalledPathFile) } else { $null }
            $portable = if ($file -and (Test-Path -LiteralPath $file -PathType Leaf)) { [IO.File]::ReadAllText($file).Trim() } else { $null }
            foreach ($candidate in @($durable,$portable)) {
                if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container) -and $out -notcontains $candidate) { $out += $candidate }
            }
        } catch {}
    }
    return $out
}

function global:Get-LegacyDepotCandidatePaths {
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
    # A renamed Depot can still be recorded under its former dedicated key.
    # These are candidate roots only; the scanner separately proves the exact
    # legacy marker, runtime and launcher before adopting the legacy state.
    if ($Game.LegacyDepotRecoveryInstalledPathFile) {
        try {
            $oldFile=[string]$Game.LegacyDepotRecoveryInstalledPathFile
            if ([IO.Path]::GetFileName($oldFile) -eq $oldFile -and $oldFile -match '^\.installed_path_[a-z0-9_]+$') {
                $recorded=Read-PersistentGameStateValue -Game $Game -Name $oldFile.TrimStart('.')
                $base=Get-InstalledPathFile -Game $Game
                $portable=if ($base) { Join-Path (Split-Path -Parent $base) $oldFile } else { $null }
                $legacyValue=if ($portable -and (Test-Path -LiteralPath $portable -PathType Leaf)) { [IO.File]::ReadAllText($portable).Trim() } else { $null }
                foreach ($candidate in @($recorded,$legacyValue)) {
                    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container) -and $out -notcontains $candidate) { $out += $candidate }
                }
            }
        } catch {}
    }
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

function global:Get-CurrentStandaloneCandidatePaths {
    param($Game)
    $out = @()
    if (-not $Game) { return $out }
    if (-not $global:HubFileSystemLabRoot -and -not $Game.CurrentPreferRememberedPath) {
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
    if($Game.CurrentPreferRememberedPath -and -not $global:HubFileSystemLabRoot){
        foreach($candidate in @($Game.CurrentStandalonePaths|Where-Object {$_})){
            if($out -notcontains [string]$candidate){$out+=[string]$candidate}
        }
    }
    return $out
}

# The "Locate Game" exe-picker records the exact executable in the canonical
# state (e.g. a differently named exe from another store). The legacy
# .launch_exe path below remains solely as a one-way migration source.
function global:Get-LaunchOverrideFile {
    param($Game)
    $base = Get-InstalledPathFile -Game $Game
    if (-not $base) { return $null }
    return ($base -replace [regex]::Escape('.installed_path'), '.launch_exe')
}

function global:Read-LaunchOverride {
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
function global:Get-UserLocatedFile {
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
function global:Get-GameStampPath {
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

function global:Read-VersionStampFile {
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
function global:Import-PendingInstallerVersion {
    param($Game, [string]$GameDir, [switch]$Second)
    if (-not $Game -or -not (Get-Command Get-UpdateOkMarkerPath -ErrorAction SilentlyContinue)) { return $null }
    $path = Get-UpdateOkMarkerPath -Game $Game
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $status = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
        if (-not $status -or ([string]$status.outcome -ne 'success')) { return $null }
        # Consume the entire completed result together. Reading A first must
        # never discard B/C, and a pinned Depot must not overwrite Current.
        $depot = [bool]($Game.DepotPinnedReceipt -and ([string]$status.route -eq 'Depot'))
        $root = $GameDir
        if ($status.installedPath -and (Test-Path -LiteralPath ([string]$status.installedPath) -PathType Container)) {
            $root = [string]$status.installedPath
        }
        $allSaved = $true
        $anyWritten = $false
        $expectedSaved = @{}
        $requested = $null
        foreach ($slot in @(
            @{ Flag='versionWritten'; Field='versionValue'; Key=$(if ($depot) { 'installed_version_depot' } else { 'installed_version' }); Mode='A' },
            @{ Flag='versionBWritten'; Field='versionBValue'; Key='installed_version_b'; Mode='B' },
            @{ Flag='versionCWritten'; Field='versionCValue'; Key='installed_version_c'; Mode='C' }
        )) {
            if (-not [bool]$status.($slot.Flag)) { continue }
            $anyWritten = $true
            $exact = ('' + $status.($slot.Field)).Trim()
            if (-not (Test-IsTrackableInstalledVersion -Version $exact)) { $allSaved = $false; continue }
            $expectedSaved[$slot.Key] = $exact
            if ($slot.Mode -eq 'A' -and -not $depot) {
                Write-InstalledVersion -Game $Game -Version $exact -GameDir $root
            } elseif ($slot.Mode -eq 'B') {
                Write-InstalledVersionB -Game $Game -Version $exact -GameDir $root
            } else {
                Write-PersistentGameStateValue -Game $Game -Name $slot.Key -Value $exact
            }
            $saved = Read-PersistentGameStateValue -Game $Game -Name $slot.Key
            if (([string]$saved).Trim() -cne $exact) { $allSaved = $false; continue }
            if (($Second -and $slot.Mode -eq 'B') -or (-not $Second -and $slot.Mode -eq 'A' -and -not $depot)) {
                $requested = $exact
            }
        }
        # A scan batch still has only an in-memory overlay. Keep the recovery
        # receipt until a later read can confirm a committed state document.
        $durable = -not $script:HubStateBatchActive
        if ($anyWritten -and $allSaved -and -not $durable) {
            # A later scan may already have committed this result. Check the
            # checksummed committed envelope cache, never the batch overlay, so
            # completed receipts do not linger on every subsequent scan.
            $disk = Get-HubStateEnvelope
            $id = Get-HubGameStateId -Game $Game
            if ($disk -and $disk.Data.games.Contains($id)) {
                $values = $disk.Data.games[$id].values
                $durable = [bool]$values
                foreach ($key in $expectedSaved.Keys) {
                    if (-not $values -or (('' + $values[$key]).Trim() -cne $expectedSaved[$key])) { $durable = $false }
                }
            }
        }
        if ($anyWritten -and $allSaved -and $durable) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
        return $requested
    } catch { return $null }
}

# Some upstream packages carry their own immutable version file. A catalog
# entry may opt in with InstalledVersionProofFile + InstalledVersionProofRegex.
# Unlike a generic recovery marker, this is release-owned evidence and can
# safely repair a missed transaction when it proves a genuinely newer build.
function global:Read-InstalledVersionProof {
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
        if ($Game.Id -eq 'cyberpunk-2077') {
            if ([IO.File]::Exists([IO.Path]::Combine($root,'.pcvrhub_cyberpunk_depot_231'))) { return $null }
            $plugin = [IO.Path]::Combine($root,[string]$Game.ModFile)
            if (-not [IO.File]::Exists($plugin)) { $plugin += '.pcvrhub_off' }
            if (-not [IO.File]::Exists($plugin) -or ([IO.FileInfo]::new($plugin)).Length -eq 0) { return $null }
            $required = @($Game.CurrentRequiredFile | Where-Object { $_ -like 'red4ext\plugins\cyberpunkvrport\*' })
            if ([version]$value -ge [version]'0.2.2') {
                $required += @('red4ext\plugins\cyberpunkvrport\dxc\dxcompiler.dll','red4ext\plugins\cyberpunkvrport\dxc\dxil.dll')
            }
            foreach ($file in $required) {
                $runtime = [IO.FileInfo]::new([IO.Path]::Combine($root,$file))
                if (-not $runtime.Exists -or $runtime.Length -eq 0) { return $null }
            }
        }
        if (Test-IsTrackableInstalledVersion -Version $value) { return $value }
    } catch {}
    return $null
}

# Read installed version for a game. LocalAppData wins. The checked install
# manifest and old marker files are recovery sources only and are imported
# when the canonical value is absent.
function global:Read-InstalledVersion {
    param($Game, [string]$GameDir)
    if ($Game.PublisherInnoAppId) {
        if (-not $GameDir -or -not [IO.Path]::IsPathRooted($GameDir) -or $Game.PublisherInnoAppId -notmatch '^\{[0-9a-f-]{36}\}$') { return $null }
        try { $root = [IO.Path]::GetFullPath($GameDir).TrimEnd('\','/') } catch { return $null }
        $key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($Game.PublisherInnoAppId)_is1"
        $versions = @(
            foreach ($hive in [Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryHive]::CurrentUser) {
                foreach ($view in [Microsoft.Win32.RegistryView]::Registry32,[Microsoft.Win32.RegistryView]::Registry64) {
                    try {
                        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($hive,$view)
                        try {
                            $entry = $base.OpenSubKey($key)
                            if (-not $entry) { continue }
                            try {
                                $location = ([string]$entry.GetValue('InstallLocation')).Trim().Trim('"')
                                if (-not $location) { $location = ([string]$entry.GetValue('Inno Setup: App Path')).Trim().Trim('"') }
                                $version = ([string]$entry.GetValue('DisplayVersion')).Trim()
                                if ([IO.Path]::IsPathRooted($location) -and [IO.Path]::GetFullPath($location).TrimEnd('\','/') -ieq $root -and
                                    $version -match '^[0-9]+(?:\.[0-9]+){1,3}$') { $version }
                            } finally { $entry.Dispose() }
                        } finally { $base.Dispose() }
                    } catch {}
                }
            }
        ) | Select-Object -Unique
        if (@($versions).Count -eq 1) { return [string]$versions }
        return $null
    }
    $pending = Import-PendingInstallerVersion -Game $Game -GameDir $GameDir
    if (Test-IsTrackableInstalledVersion -Version $pending) {
        # A publisher launcher may have updated again after this Hub receipt.
        $proof = Read-InstalledVersionProof -Game $Game -GameDir $GameDir
        if ($proof -and (Get-Command Test-OnlineVersionIsNewer -ErrorAction SilentlyContinue) -and
            (Test-OnlineVersionIsNewer -Installed ([string]$pending) -Online ([string]$proof))) {
            Write-InstalledVersion -Game $Game -Version $proof -GameDir $GameDir
            return ([string]$proof)
        }
        return ([string]$pending)
    }
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
function global:Write-InstalledVersion {
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
function global:Get-InstalledVersionPathB {
    param($Game)
    $p = Get-InstalledVersionPath -Game $Game
    if (-not $p) { return $null }
    return ($p + "_b")
}

function global:Read-InstalledVersionB {
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

function global:Write-InstalledVersionB {
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
function global:Invalidate-SupersededInstalledVersion {
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
function global:Get-UpdateOkMarkerPath {
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
function global:Clear-UpdateOkMarker {
    param($Game)
    $mk = Get-UpdateOkMarkerPath -Game $Game
    if ($mk -and (Test-Path -LiteralPath $mk -PathType Leaf)) {
        Remove-Item -LiteralPath $mk -Force -ErrorAction SilentlyContinue
    }
}

$global:HubInstalledStateModuleSource=[IO.Path]::GetFullPath($PSCommandPath)
