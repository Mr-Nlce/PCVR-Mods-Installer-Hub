# ============================================================
# ScanWarmup.ps1 - background file-system warm-up for the scan
# ============================================================
# Started by VRModHub.ps1 as a SEPARATE hidden PowerShell process right
# after the visible-window handoff. A cold "Scan installed games" (first scan after a
# reboot or a long pause) took ~14 s, the same scan warm ~7 s: the
# difference is Windows reading folder and file metadata from disk. The
# Windows file cache is shared by all processes, so this worker walks the
# places the scan will look at without blocking the Hub startup - the scan
# then finds them in memory.
#
# Two phases inside one time budget:
#   1. TARGETED - loads the catalog (read-only) and, per game, probes exactly
#      what the scan probes: the candidate folders (Steam folder and
#      appmanifest installdir, FallbackPaths with every prefix and drive,
#      paths remembered in HubState.json, VrInstallRoot) and in each existing
#      folder the game/proof/mod/evidence files the catalog names.
#   2. BROAD - with the time left, a shallow walk over all store roots.
#
# Runs separately with reduced resource priority:
#   * own process - nothing runs on the Hub's UI thread
#   * Windows background mode (lowest CPU, disk and memory priority);
#     falls back to Idle CPU priority if that is unavailable
#   * read-only: lists folders, reads small files (*.acf, *.item, the
#     Hub's own .pcvrhub* markers); it writes ONLY its one-line summary
#   * 60 s traversal budget; the Hub also monitors its owned process lifetime
#   * broad walk defaults to at most 3 levels / 250,000 entries
#   * one instance at a time (named mutex)
#
# Output (the only file it writes): the caller's runtime Logs\ScanWarmup.json
#   { started, finished, ms, games, targetRoots, probes, hits, entries, files, roots, state }
# The scan prints one line from it ("[Scan] warm-up: ...").
# Off switch: PCVR_HUB_SCAN_WARMUP=0 before starting the Hub.
# ============================================================
param(
    [string]$ScriptDir = '',
    [string[]]$ExtraRoots = @(),
    [int]$MaxSeconds = 60,
    [int]$MaxEntries = 250000,
    [int]$MaxDepth = 3,
    [string]$SummaryPath = '',
    [string]$CatalogPath = '',
    [string]$StatePath = '',
    [string[]]$SteamLibraries = $null,
    [string]$FixtureRoot = ''
)

$ErrorActionPreference = 'SilentlyContinue'
$watch = [Diagnostics.Stopwatch]::StartNew()
$started = [DateTime]::UtcNow
$deadline = [TimeSpan]::FromSeconds($MaxSeconds)
$entries = 0L
$state = 'complete'
function Test-WarmBudget {
    if ($watch.Elapsed -ge $deadline) { $script:state='time budget'; return $false }
    if ($script:entries -ge $MaxEntries) { $script:state='entry budget'; return $false }
    return $true
}
$fixturePrefix = ''
if ($FixtureRoot) {
    $FixtureRoot = [IO.Path]::GetFullPath($FixtureRoot).TrimEnd([char[]]'\/')
    $temporary = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    if ($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $FixtureRoot.StartsWith($temporary,[StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists([IO.Path]::Combine($FixtureRoot,'.pcvrhub_scanwarm_fixture'))) { throw 'An isolated warm-up fixture sentinel is required.' }
    if (([IO.File]::GetAttributes($FixtureRoot) -band [IO.FileAttributes]::ReparsePoint) -or @(Get-ChildItem -LiteralPath $FixtureRoot -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Warm-up fixtures cannot contain links.' }
    $fixturePrefix = $FixtureRoot + [IO.Path]::DirectorySeparatorChar
}
function Test-WarmFixturePath([string]$Path) {
    if (-not $FixtureRoot) { return $true }
    try { $full=[IO.Path]::GetFullPath($Path); return ($full -eq $FixtureRoot -or $full.StartsWith($fixturePrefix,[StringComparison]::OrdinalIgnoreCase)) } catch { return $false }
}
foreach ($inputPath in @($CatalogPath,$StatePath,$SummaryPath)+@($SteamLibraries)+@($ExtraRoots)) { if ($inputPath -and -not (Test-WarmFixturePath $inputPath)) { throw 'A warm-up fixture path escaped its sentinel.' } }

$mutex = $null
try {
    $created = $false
    $mutexName = 'Local\PCVRModsInstallerHub_ScanWarmup'
    if ($FixtureRoot) { $mutexName += '_' + [IO.Path]::GetFileName($FixtureRoot) }
    $mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$created)
    if (-not $created) { exit 0 }
} catch { }

# Lowest priority. PROCESS_MODE_BACKGROUND_BEGIN lowers CPU, I/O and memory
# priority together; Idle is the CPU-only fallback.
$background = $false
try {
    Add-Type -Namespace PcvrWarmup -Name Native -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern System.IntPtr GetCurrentProcess();
[DllImport("kernel32.dll")] public static extern bool SetPriorityClass(System.IntPtr process, uint priorityClass);
'@ -ErrorAction Stop
    $background = [PcvrWarmup.Native]::SetPriorityClass([PcvrWarmup.Native]::GetCurrentProcess(), 0x00100000)
} catch { }
if (-not $background) {
    try { [Diagnostics.Process]::GetCurrentProcess().PriorityClass = [Diagnostics.ProcessPriorityClass]::Idle } catch { }
}
try { [Threading.Thread]::CurrentThread.Priority = [Threading.ThreadPriority]::Lowest } catch { }

function Read-RegistryValueQuiet([string]$Hive, [string]$SubKey, [string]$Name) {
    if ($FixtureRoot) { return $null }
    try {
        $base = if ($Hive -eq 'HKCU') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine }
        $key = $base.OpenSubKey($SubKey)
        if (-not $key) { return $null }
        try { return [string]$key.GetValue($Name) } finally { $key.Dispose() }
    } catch { return $null }
}

# ---------- Roots: the same places the scan probes ----------
$roots = New-Object 'System.Collections.Generic.List[string]'
$seenRoots = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
function Add-Root([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if (-not (Test-WarmFixturePath $Path)) { return }
    $p = $Path.Trim().Trim('"').TrimEnd([char[]]'\/')
    if (-not $p) { return }
    try { if (-not [IO.Directory]::Exists($p)) { return } } catch { return }
    if ($seenRoots.Add($p)) { $roots.Add($p) }
}
$smallFiles = New-Object 'System.Collections.Generic.List[string]'

# Steam: libraryfolders.vdf lists every library (never guess).
$steamRoot = Read-RegistryValueQuiet 'HKCU' 'Software\Valve\Steam' 'SteamPath'
if (-not $steamRoot) { $steamRoot = Read-RegistryValueQuiet 'HKLM' 'SOFTWARE\WOW6432Node\Valve\Steam' 'InstallPath' }
if (-not $steamRoot) { $steamRoot = Read-RegistryValueQuiet 'HKLM' 'SOFTWARE\Valve\Steam' 'InstallPath' }
$steamLibs = New-Object 'System.Collections.Generic.List[string]'
if ($null -ne $SteamLibraries) { foreach ($l in $SteamLibraries) { if ($l) { $steamLibs.Add($l) } }; $steamRoot = $null }
if ($steamRoot) {
    $steamRoot = $steamRoot -replace '/', '\'
    $steamLibs.Add($steamRoot)
    $vdf = [IO.Path]::Combine($steamRoot, 'steamapps', 'libraryfolders.vdf')
    try {
        if ([IO.File]::Exists($vdf)) {
            foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) {
                $lib = $m.Groups[1].Value -replace '\\\\', '\'
                if ($steamLibs -notcontains $lib) { $steamLibs.Add($lib) }
            }
        }
    } catch { }
}
foreach ($lib in $steamLibs) {
    $steamapps = [IO.Path]::Combine($lib, 'steamapps')
    try {
        if ([IO.Directory]::Exists($steamapps)) {
            foreach ($acf in [IO.Directory]::EnumerateFiles($steamapps, 'appmanifest_*.acf')) { $smallFiles.Add($acf) }
        }
    } catch { }
    Add-Root ([IO.Path]::Combine($steamapps, 'common'))
    Add-Root ([IO.Path]::Combine($steamapps, 'content'))
}

# GOG / Epic / Xbox / Ubisoft: the scan's guessed roots plus the real ones.
$pf = $env:ProgramFiles; $pf86 = ${env:ProgramFiles(x86)}
$storeRoots = @{ GOG = [Collections.Generic.List[string]]::new(); EPIC = [Collections.Generic.List[string]]::new(); XBOX = [Collections.Generic.List[string]]::new(); UBI = [Collections.Generic.List[string]]::new() }
function Add-StoreRoot([string]$Store, [string]$Path) {
    if (-not (Test-WarmFixturePath $Path)) { return }
    try { if (-not $Path -or -not [IO.Directory]::Exists($Path)) { return } } catch { return }
    if ($storeRoots[$Store] -notcontains $Path) { $storeRoots[$Store].Add($Path) }
    Add-Root $Path
}
foreach ($sub in @('SOFTWARE\GOG.com\GalaxyClient\paths', 'SOFTWARE\WOW6432Node\GOG.com\GalaxyClient\paths')) {
    $client = Read-RegistryValueQuiet 'HKLM' $sub 'client'
    if ($client) { Add-StoreRoot 'GOG' ([IO.Path]::Combine($client, 'Games')) }
}
foreach ($r in @('C:\GOG Games', 'D:\GOG Games', 'E:\GOG Games', "$pf86\GOG Galaxy\Games", "$pf\GOG Galaxy\Games", 'C:\Program Files (x86)\GalaxyClient\Games')) { Add-StoreRoot 'GOG' $r }
foreach ($r in @("$pf\Epic Games", "$pf86\Epic Games", 'C:\Program Files\Epic Games', 'C:\Epic Games', 'D:\Epic Games', 'E:\Epic Games',
                 'D:\Program Files\Epic Games', 'E:\Program Files\Epic Games')) { Add-StoreRoot 'EPIC' $r }
foreach ($r in @('C:\XboxGames', 'D:\XboxGames', 'E:\XboxGames', 'F:\XboxGames')) { Add-StoreRoot 'XBOX' $r }
foreach ($r in @("$pf86\Ubisoft\Ubisoft Game Launcher\games", "$pf\Ubisoft\Ubisoft Game Launcher\games",
                 'C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games', 'C:\Ubisoft\Ubisoft Game Launcher\games',
                 'D:\Ubisoft\Ubisoft Game Launcher\games', 'E:\Ubisoft\Ubisoft Game Launcher\games')) { Add-StoreRoot 'UBI' $r }
if (-not $FixtureRoot -and $env:ProgramData) {
    $manifests = [IO.Path]::Combine($env:ProgramData, 'Epic', 'EpicGamesLauncher', 'Data', 'Manifests')
    try {
        if ([IO.Directory]::Exists($manifests)) {
            foreach ($item in [IO.Directory]::EnumerateFiles($manifests, '*.item')) {
                $smallFiles.Add($item)
                try {
                    $m = [regex]::Match([IO.File]::ReadAllText($item), '"InstallLocation"\s*:\s*"([^"]+)"')
                    if ($m.Success) {
                        $loc = $m.Groups[1].Value -replace '\\\\', '\'
                        Add-Root $loc
                        try { Add-StoreRoot 'EPIC' ([IO.Path]::GetDirectoryName($loc.TrimEnd('\'))) } catch { }
                    }
                } catch { }
            }
        }
    } catch { }
}

# Windows Uninstall entries (the scan's registry index lists these).
foreach ($hive in $(if ($FixtureRoot) { @() } else { @('HKLM', 'HKCU') })) {
    foreach ($sub in @('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
        try {
            $base = if ($hive -eq 'HKCU') { [Microsoft.Win32.Registry]::CurrentUser } else { [Microsoft.Win32.Registry]::LocalMachine }
            $key = $base.OpenSubKey($sub)
            if (-not $key) { continue }
            try {
                foreach ($name in $key.GetSubKeyNames()) {
                    $app = $key.OpenSubKey($name)
                    if (-not $app) { continue }
                    try { Add-Root ([string]$app.GetValue('InstallLocation')) } finally { $app.Dispose() }
                }
            } finally { $key.Dispose() }
        } catch { }
    }
}

# Fixed drives: their top level and a Games folder (catalog FallbackPaths
# such as C:\Games\<Mod> live there).
$fixedDrives = [Collections.Generic.List[string]]::new()
try {
    foreach ($drive in $(if ($FixtureRoot) { @() } else { [IO.DriveInfo]::GetDrives() })) {
        if ($drive.DriveType -ne [IO.DriveType]::Fixed -or -not $drive.IsReady) { continue }
        $fixedDrives.Add($drive.RootDirectory.FullName)
        Add-Root ([IO.Path]::Combine($drive.RootDirectory.FullName, 'Games'))
        try { foreach ($top in [IO.Directory]::EnumerateDirectories($drive.RootDirectory.FullName)) { } } catch { }
    }
} catch { }
foreach ($r in @($ExtraRoots)) { Add-Root $r }


# ---------- Phase 1: targeted probes from the catalog ----------
$files = 0L
$games = 0; $targetRoots = 0L; $probes = 0L; $hits = 0L
$catalogGames = @()
if (-not $CatalogPath -and $ScriptDir) { $CatalogPath = [IO.Path]::Combine($ScriptDir, 'Modules', 'Catalog.ps1') }
if ($CatalogPath -and [IO.File]::Exists($CatalogPath)) {
    try {
        $global:scriptDir = $ScriptDir; $script:scriptDir = $ScriptDir
        . $CatalogPath
        $catalogGames = @(@($ownGames) + @($ownGamesGP) + @($externalGames) | Where-Object { $_ })
    } catch { $catalogGames = @() }
}
# Paths the Hub remembered per game (Locate, installers), read-only.
$statePaths = @{}
if (-not $FixtureRoot -and -not $StatePath -and $env:LOCALAPPDATA) { $StatePath = [IO.Path]::Combine($env:LOCALAPPDATA, 'PCVR Mods Installer Hub', 'State', 'HubState.json') }
if ($StatePath -and [IO.File]::Exists($StatePath)) {
    try {
        $doc = [IO.File]::ReadAllText($StatePath) | ConvertFrom-Json
        foreach ($p in @($doc.data.games.PSObject.Properties)) {
            $title = [string]$p.Value.title
            if (-not $title -or -not $p.Value.values) { continue }
            foreach ($v in @($p.Value.values.PSObject.Properties)) {
                $text = [string]$v.Value
                if ($text -match '^[A-Za-z]:[\\/]' -or $text.StartsWith('\\') -or $text.StartsWith('/')) {
                    if (-not $statePaths.ContainsKey($title)) { $statePaths[$title] = [Collections.Generic.List[string]]::new() }
                    $statePaths[$title].Add($text)
                }
            }
        }
    } catch { }
}
# Steam appmanifest installdir per AppId.
$installDirs = @{}
foreach ($acf in $smallFiles) {
    if ($acf -notmatch 'appmanifest_(\d+)\.acf$') { continue }
    $appId = $matches[1]
    try {
        $m = [regex]::Match([IO.File]::ReadAllText($acf), '"installdir"\s+"([^"]+)"')
        if ($m.Success) {
            $common = [IO.Path]::Combine([IO.Path]::GetDirectoryName($acf), 'common', $m.Groups[1].Value)
            if (-not $installDirs.ContainsKey($appId)) { $installDirs[$appId] = [Collections.Generic.List[string]]::new() }
            $installDirs[$appId].Add($common)
        }
    } catch { }
}
$sepPattern = '[\\/]'
function Join-WarmPath([string]$Base, [string]$Tail) {
    $parts = @($Tail -split $sepPattern | Where-Object { $_ })
    $p = $Base
    foreach ($part in $parts) { $p = [IO.Path]::Combine($p, $part) }
    return $p
}
function Expand-WarmCandidate([string]$Value) {
    $out = [Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Value)) { return , $out }
    $v = $Value.Trim()
    $prefix = [regex]::Match($v, '^(STEAM_CONTENT|STEAM_COMMON|STEAM:|GOG:|EPIC:|XBOX:|UBI:|APPDATA:|LOCALAPPDATA:|PROGRAMDATA:|USERPROFILE:)')
    if ($prefix.Success) {
        $tail = $v.Substring($prefix.Length)
        switch ($prefix.Value) {
            'STEAM_CONTENT' { foreach ($lib in $steamLibs) { $out.Add((Join-WarmPath ([IO.Path]::Combine($lib, 'steamapps', 'content')) $tail)) } }
            'STEAM_COMMON'  { foreach ($lib in $steamLibs) { $out.Add((Join-WarmPath ([IO.Path]::Combine($lib, 'steamapps', 'common')) $tail)) } }
            'STEAM:'        { foreach ($lib in $steamLibs) { $out.Add((Join-WarmPath ([IO.Path]::Combine($lib, 'steamapps', 'common')) $tail)) } }
            'GOG:'          { foreach ($r in $storeRoots.GOG) { $out.Add((Join-WarmPath $r $tail)) } }
            'EPIC:'         { foreach ($r in $storeRoots.EPIC) { $out.Add((Join-WarmPath $r $tail)) } }
            'XBOX:'         { foreach ($r in $storeRoots.XBOX) { $out.Add((Join-WarmPath (Join-WarmPath $r $tail) 'Content')) } }
            'UBI:'          { foreach ($r in $storeRoots.UBI) { $out.Add((Join-WarmPath $r $tail)) } }
            'APPDATA:'      { if ($env:APPDATA) { $p = Join-WarmPath $env:APPDATA $tail; if ($p -match '\.exe$') { $p = [IO.Path]::GetDirectoryName($p) }; $out.Add($p) } }
            'LOCALAPPDATA:' { if ($env:LOCALAPPDATA) { $out.Add((Join-WarmPath $env:LOCALAPPDATA $tail)) } }
            'PROGRAMDATA:'  { if ($env:ProgramData) { $out.Add((Join-WarmPath $env:ProgramData $tail)) } }
            'USERPROFILE:'  { if ($env:USERPROFILE) { $out.Add((Join-WarmPath $env:USERPROFILE $tail)) } }
        }
        return , $out
    }
    $out.Add(($v -replace '[\\/]', [string][IO.Path]::DirectorySeparatorChar))
    $drive = [regex]::Match($v, '^[A-Za-z]:[\\/](.+)$')
    if ($drive.Success) { foreach ($d in $fixedDrives) { $out.Add((Join-WarmPath $d $drive.Groups[1].Value)) } }
    return , $out
}
# Every relative file the catalog names for a game (proofs, mod files, evidence).
function Add-WarmRelative($List, $Value) {
    if ($null -eq $Value) { return }
    if ($Value -is [string]) {
        foreach ($piece in $Value.Split('|')) {
            $t = $piece.Trim()
            if (-not $t -or $t.Length -gt 240 -or $t.Contains('://') -or $t -match '^[A-Za-z]:' -or $t.StartsWith('\') -or $t.StartsWith('/') -or $t -match '(^|[\\/])\.\.([\\/]|$)' -or $t -match '[*?]') { continue }
            if (-not $List.Contains($t)) { $List.Add($t) }
        }
        return
    }
    if ($Value -is [Collections.IDictionary]) { foreach ($k in @($Value.Keys)) { Add-WarmRelative $List $Value[$k] }; return }
    if ($Value -is [Collections.IEnumerable]) { foreach ($item in $Value) { Add-WarmRelative $List $item } }
}
$rootFields = @('FallbackPaths', 'DepotPath', 'LegacyDepotPath', 'LegacyDepotFallbackPaths', 'CurrentStandalonePaths', 'VrInstallRoot', 'DurableInstallRoots', 'HubLaunchRuntimeRoot')
$seenTarget = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($g in $catalogGames) {
    if (-not (Test-WarmBudget)) { break }
    $games++
    $candidates = [Collections.Generic.List[string]]::new()
    if ($g.SteamFolder) {
        foreach ($lib in $steamLibs) {
            $c = Join-WarmPath ([IO.Path]::Combine($lib, 'steamapps', 'common')) ([string]$g.SteamFolder)
            $candidates.Add($c)
            if ($g.OriginalGameSteamSubdir) { $candidates.Add((Join-WarmPath $c ([string]$g.OriginalGameSteamSubdir))) }
        }
    }
    foreach ($id in @($g.SteamId) + @($g.SteamAppIds)) {
        if ($id -and $installDirs.ContainsKey([string]$id)) { foreach ($c in $installDirs[[string]$id]) { $candidates.Add($c) } }
    }
    foreach ($field in $rootFields) {
        foreach ($v in @($g[$field])) { if ($v -is [string]) { foreach ($c in (Expand-WarmCandidate $v)) { $candidates.Add($c) } } }
    }
    if ($g.Title -and $statePaths.ContainsKey([string]$g.Title)) { foreach ($c in $statePaths[[string]$g.Title]) { $candidates.Add($c) } }
    $relatives = [Collections.Generic.List[string]]::new()
    foreach ($k in @($g.Keys)) {
        if ($k -match '(File|Files|Exe|Evidence|Groups|ProofSets)$' -and $k -notmatch '(InstalledPathFile|SteamAppIdFile|IniFile)$') { Add-WarmRelative $relatives $g[$k] }
    }
    foreach ($c in $candidates) {
        if (-not (Test-WarmBudget)) { break }
        if (-not (Test-WarmFixturePath $c)) { continue }
        if (-not $c -or -not $seenTarget.Add($c)) { continue }
        $exists = $false
        try { $exists = [IO.Directory]::Exists($c) } catch { }
        if (-not $exists) { continue }
        $targetRoots++
        try {
            foreach ($entry in [IO.DirectoryInfo]::new($c).EnumerateFileSystemInfos()) {
                if (-not (Test-WarmBudget)) { break }
                $entries++
                if (($entry.Attributes -band [IO.FileAttributes]::Directory) -eq 0 -and $entry.Name.StartsWith('.pcvrhub', [StringComparison]::OrdinalIgnoreCase)) { $smallFiles.Add($entry.FullName) }
            }
        } catch { }
        foreach ($rel in $relatives) {
            if (-not (Test-WarmBudget)) { break }
            $probes++
            try {
                $p = Join-WarmPath $c $rel
                if ([IO.File]::Exists($p) -or [IO.Directory]::Exists($p)) { $hits++ }
            } catch { }
        }
    }
}

# ---------- Phase 2: breadth-first over ALL roots, shallow levels first ----------
$level = New-Object 'System.Collections.Generic.List[string]'
foreach ($r in $roots) { $level.Add($r) }
if ($watch.Elapsed -gt $deadline) { $state = 'time budget' }
for ($depth = 0; $depth -lt $MaxDepth -and $level.Count -gt 0; $depth++) {
    $next = New-Object 'System.Collections.Generic.List[string]'
    foreach ($dir in $level) {
        if (-not (Test-WarmBudget)) { break }
        try {
            foreach ($entry in [IO.DirectoryInfo]::new($dir).EnumerateFileSystemInfos()) {
                if (-not (Test-WarmBudget)) { break }
                $entries++
                if (($entry.Attributes -band [IO.FileAttributes]::Directory) -ne 0) {
                    # Never follow junctions (they can point back into a game or another drive).
                    if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) { $next.Add($entry.FullName) }
                } elseif ($entry.Name.StartsWith('.pcvrhub', [StringComparison]::OrdinalIgnoreCase)) {
                    $smallFiles.Add($entry.FullName)
                }
            }
        } catch { }
    }
    if ($state -ne 'complete') { break }
    $level = $next
}

# Small files the scan reads: Steam manifests, Epic items, Hub markers.
foreach ($f in $smallFiles) {
    if (-not (Test-WarmBudget)) { break }
    try {
        $info = [IO.FileInfo]::new($f)
        if ($info.Exists -and $info.Length -le 262144) { [void][IO.File]::ReadAllBytes($f); $files++ }
    } catch { }
}

# ---------- Summary ----------
$watch.Stop()
if (-not $SummaryPath -and $ScriptDir) { $SummaryPath = [IO.Path]::Combine($ScriptDir, 'Logs', 'ScanWarmup.json') }
if ($SummaryPath -and -not (Test-WarmFixturePath $SummaryPath)) { throw 'Warm-up summary escaped its fixture.' }
if ($SummaryPath) {
    try {
        $dir = [IO.Path]::GetDirectoryName($SummaryPath)
        if ($dir -and -not [IO.Directory]::Exists($dir)) { [void][IO.Directory]::CreateDirectory($dir) }
        $summary = [ordered]@{
            started  = $started.ToString('o')
            finished = [DateTime]::UtcNow.ToString('o')
            ms       = [long]$watch.ElapsedMilliseconds
            games    = $games
            targetRoots = $targetRoots
            probes   = $probes
            hits     = $hits
            entries  = $entries
            files    = $files
            roots    = $roots.Count
            state    = $state
            background = $background
        }
        [IO.File]::WriteAllText($SummaryPath, ($summary | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))
    } catch { }
}
try { if ($mutex) { $mutex.ReleaseMutex(); $mutex.Dispose() } } catch { }
exit 0
