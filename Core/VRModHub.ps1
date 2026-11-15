# ============================================================
#  PCVR Mods Installer Hub
# ============================================================

# ------------------------------------------------------------
# PARALLEL PARSE PREFETCH (test build)
# ------------------------------------------------------------
# PowerShell has to parse ~3.7 MB of module code on every start before a
# single line of it runs, and it does so one file after another on the UI
# thread. Parsing is pure CPU work and thread-safe, so the module files
# are handed to a small runspace pool right here - before the WPF
# assemblies load - and parsed in parallel on the other CPU cores. Each
# module is still dot-sourced in exactly the same order as before; it is
# only handed over as an already-parsed script block (Get-HubModuleScript).
#
# Any doubt falls back to the plain file path: a file that is not in the
# list, a parse error, a failed self-test or PCVR_HUB_PARALLEL_PARSE=0.
$global:HubParsePrefetch = $null
$global:HubParseWaitMs = 0
$global:HubParseHits = 0
$global:HubParseMisses = 0
# Only worth it with spare cores: on a 2-core machine the UI thread would
# mostly wait for a single worker.
if ([string]$env:PCVR_HUB_PARALLEL_PARSE -ne '0' -and [Environment]::ProcessorCount -ge 4) {
    try {
        $__coreDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $__modDir  = Join-Path $__coreDir 'Modules'
        # Self-test: a script block created from a parsed file must report
        # that file's folder as $PSScriptRoot, as a dot-sourced file does.
        $__probeOk = $false
        try {
            $__probeAst = [System.Management.Automation.Language.Parser]::ParseInput('$PSScriptRoot', (Join-Path $__modDir 'probe.ps1'), [ref]$null, [ref]$null)
            $__probeRoot = & { . $__probeAst.GetScriptBlock() }
            $__probeOk = ([string]$__probeRoot -eq $__modDir)
        } catch {
            # Older engines without the ParseInput(fileName) overload: the
            # script block must at least carry its file, which is what
            # $PSScriptRoot is derived from.
            $__probeFile = Join-Path $__modDir 'CardTile.ps1'
            $__probeSb = ([System.Management.Automation.Language.Parser]::ParseFile($__probeFile, [ref]$null, [ref]$null)).GetScriptBlock()
            $__probeOk = ([string]$__probeSb.File -eq $__probeFile)
        }
        if (-not $__probeOk) { throw "PSScriptRoot self-test failed" }

        # Load order. Files missing here simply load the classic way.
        $__parseList = @(
            'Catalog.ps1','CatalogIndex.ps1','DiscordChannels.ps1','BannerColors.ps1','Helpers.ps1','Favorites.ps1',
            'CardTile.ps1','CardTile.Core.ps1','CardTile.Lazy.ps1','CardTile.Frosted.ps1',
            'Window.ps1','Window.Layout.ps1','Window.BannerEffects.ps1','Window.Controls.ps1',
            'ScanSpinner.ps1','DiscoverInit.ps1','UninstallGuide.ps1','ReadmeLinks.ps1','EldenRingSaveUI.ps1',
            '..\EldenRingVR\EldenRingSaveManager.ps1','..\EldenRingVR\EldenRingSettings.ps1',
            'DetailView.ps1','DetailView.Tiles.ps1','DetailView.Power.ps1','DetailView.Actions.ps1',
            'DetailView.Content.ps1','DetailView.Launch.ps1','DetailView.Page.ps1',
            'OverviewPage.ps1','BannerOvFilters.ps1',
            'Filter.ps1','Filter.Banners.ps1','Filter.Controls.ps1','Filter.Search.ps1',
            'Filter.ScanSources.ps1','Filter.Scan.ps1','Filter.InstallRefresh.ps1',
            'CatalogSort.ps1','HeaderFx.ps1','BannerGlass.ps1','BannerFxExtra.ps1',
            'CustomGames.ps1','CustomGames.UI.ps1','Startup.ps1'
        )
        $__threads = [Math]::Max(1, [Math]::Min(6, [Environment]::ProcessorCount - 1))
        # An empty session state: the parse workers need no cmdlets, so the
        # runspaces open in milliseconds instead of loading modules.
        $__iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        $__iss.LanguageMode = [System.Management.Automation.PSLanguageMode]::FullLanguage
        $__pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $__threads, $__iss, $Host)
        $__pool.Open()
        $__jobs = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($__name in $__parseList) {
            $__path = [System.IO.Path]::GetFullPath((Join-Path $__modDir $__name))
            if (-not [System.IO.File]::Exists($__path)) { continue }
            $__ps = [PowerShell]::Create()
            $__ps.RunspacePool = $__pool
            [void]$__ps.AddScript('param($p) $t = $null; $e = $null; $a = [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$t, [ref]$e); if ($e.Count -eq 0) { $a }').AddArgument($__path)
            $__jobs[$__path] = [pscustomobject]@{ PS = $__ps; Handle = $__ps.BeginInvoke() }
        }
        $global:HubParsePrefetch = [pscustomobject]@{ Pool = $__pool; Jobs = $__jobs; Threads = $__threads }
    } catch {
        $global:HubParsePrefetchError = $_.Exception.Message
        $global:HubParsePrefetch = $null
    }
    Remove-Variable __coreDir, __modDir, __probeOk, __probeAst, __probeRoot, __probeFile, __probeSb, __parseList, __threads, __iss, __pool, __jobs, __name, __path, __ps -ErrorAction SilentlyContinue
}

# Returns the prefetched, already-parsed script block for a module file,
# or the path itself (dot-sourcing either is equivalent). Every caller
# dot-sources the result: . (Get-HubModuleScript $path)
function global:Get-HubModuleScript {
    param([string]$Path)
    $pf = $global:HubParsePrefetch
    if (-not $pf) { return $Path }
    $full = $Path
    try { $full = [System.IO.Path]::GetFullPath($Path) } catch { return $Path }
    $job = $null
    if (-not $pf.Jobs.TryGetValue($full, [ref]$job)) { $global:HubParseMisses++; return $Path }
    [void]$pf.Jobs.Remove($full)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ast = $null
    try {
        $res = $job.PS.EndInvoke($job.Handle)
        if ($res -and $res.Count -gt 0) {
            $ast = $res[0]
            if ($ast -is [psobject]) { $ast = $ast.psobject.BaseObject }
        }
    } catch { $ast = $null }
    finally { try { $job.PS.Dispose() } catch { } }
    $sw.Stop()
    $global:HubParseWaitMs += $sw.ElapsedMilliseconds
    if ($ast -is [System.Management.Automation.Language.ScriptBlockAst]) {
        $global:HubParseHits++
        return $ast.GetScriptBlock()
    }
    $global:HubParseMisses++
    return $Path
}

# Frees the parse workers once every startup module is loaded.
function global:Close-HubParsePrefetch {
    $pf = $global:HubParsePrefetch
    if (-not $pf) { return }
    $global:HubParsePrefetch = $null
    foreach ($j in @($pf.Jobs.Values)) { try { $j.PS.Stop(); $j.PS.Dispose() } catch { } }
    try { $pf.Pool.Close(); $pf.Pool.Dispose() } catch { }
    try {
        Write-HubTiming ("parse prefetch: {0} modules pre-parsed on {1} threads, {2} classic, waited {3} ms in total" -f `
            $global:HubParseHits, $pf.Threads, $global:HubParseMisses, $global:HubParseWaitMs)
    } catch { }
}

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
. (Join-Path $scriptDir 'Modules\GitHubTransport.ps1')

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

function global:Test-HubRawTranscriptHeader {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        # Bound both bytes and lines: ReadLine() could allocate a damaged
        # multi-gigabyte first line before discovering there is no header.
        $stream = [IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
        try {
            $buffer = New-Object byte[] 8192
            $count = $stream.Read($buffer,0,$buffer.Length)
        } finally { $stream.Dispose() }
        if ($count -eq 0) { return $false }
        $prefix = [Text.Encoding]::UTF8.GetString($buffer,0,$count)
        foreach ($line in @($prefix -split "`r?`n" | Select-Object -First 10)) {
            if ($line.Trim() -match '^\*{10,}$') { return $true }
        }
    } catch {}
    return $false
}

function global:Compress-HubSessionLog {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    # A completed log has no transcript delimiter. Do not read or rewrite it
    # again on later starts; this also makes UTF-8 cleanup strictly one-time.
    if (-not (Test-HubRawTranscriptHeader -Path $Path)) { return }
    try {
        $logInfo = Get-Item -LiteralPath $Path -ErrorAction Stop
        # A damaged transcript can contain a multi-gigabyte line. Never load
        # one into PowerShell: retain the time and size, then reclaim the log.
        if ($logInfo.Length -gt 8MB) {
            [IO.File]::WriteAllLines($Path,[string[]]@(
                '=== PCVR Mods Installer Hub - Session Log ===',
                ('Started:    ' + $logInfo.CreationTime.ToString('yyyy-MM-dd HH:mm:ss')),
                ('PowerShell: ' + $PSVersionTable.PSVersion + ' (' + $PSVersionTable.PSEdition + ')'),
                '=============================================',
                '',
                ('[Log limit] An oversized session log (' + $logInfo.Length + ' bytes) was compacted without reading its contents.'),
                '[Log limit] Check newer session logs for current diagnostics.'
            ),(New-Object Text.UTF8Encoding($false)))
            return
        }
        # Windows PowerShell 5.1 otherwise reads BOM-less UTF-8 as the system
        # ANSI code page. Each later compaction then multiplies mojibake.
        $rawLines = @(Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop)
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
        $insideTranscriptHeader = $false
        foreach ($rawLine in $rawLines) {
            $line = [string]$rawLine
            if ($line.Trim() -match '^\*{10,}$') {
                $insideTranscriptHeader = -not $insideTranscriptHeader
                continue
            }
            if ($insideTranscriptHeader) { continue }
            if ($line -match '^=== PCVR Mods Installer Hub - Session Log ===$' -or
                $line -match '^Started:\s*' -or $line -match '^Hub Core:\s*' -or
                $line -match '^Windows:\s*' -or $line -match '^PowerShell:\s*' -or
                $line -match '^=+$' -or $line -match '^\*+$' -or
                $line -match '(?i)^(n?Start der Windows PowerShell-Aufzeichnung|Ende der Windows PowerShell-Aufzeichnung|Windows PowerShell transcript (start|end)|Inicio de la transcripci.n de Windows PowerShell|Fin de la transcripci.n de Windows PowerShell)$' -or
                $line -match '(?i)^(Startzeit|Endzeit|Start time|End time|Benutzername|Username|RunAs-Benutzer|RunAs User|Konfigurationsname|Configuration Name|Computer|Machine|Hostanwendung|Host Application|Prozess-ID|Process ID|Hora de inicio|Hora de fin|Nombre de usuario|Usuario RunAs|Nombre de la configuraci.n|M.quina|Aplicaci.n host|Id\. de proceso|PSVersion|PSEdition|PSCompatibleVersions|BuildVersion|CLRVersion|WSManStackVersion|PSRemotingProtocolVersion|SerializationVersion):') {
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

function global:Limit-HubLogStorage {
    param([string]$Directory,[string]$ActivePath = '')
    if (-not $Directory -or -not (Test-Path -LiteralPath $Directory -PathType Container)) { return }
    $total = [long]0
    foreach ($file in @(Get-ChildItem -LiteralPath $Directory -Filter '*.log' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending)) {
        if ($ActivePath -and $file.FullName -ieq $ActivePath) { $total += [long]$file.Length; continue }
        if ($total + [long]$file.Length -gt 100MB) {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
        } else { $total += [long]$file.Length }
    }
}

function global:Update-HubLogRotation {
    $rotation = $global:HubLogRotation
    if (-not $rotation -or -not $rotation.Active -or -not $rotation.Path) { return $false }
    if ((Get-Item -LiteralPath $rotation.Path -ErrorAction Stop).Length -lt [long]$rotation.LimitBytes) { return $false }
    Stop-Transcript -ErrorAction Stop | Out-Null
    $rotation.Active = $false
    Compress-HubSessionLog -Path $rotation.Path
    Limit-HubLogStorage -Directory $rotation.Directory
    $nextLog = Join-Path $rotation.Directory ("Hub-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss-fff'))
    [IO.File]::WriteAllLines($nextLog,[string[]]@(
        '=== PCVR Mods Installer Hub - Session Log ===',
        ('Started:    ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
        '=============================================',
        '[Log limit] Previous session segment reached its size limit; logging continues here.'
    ),(New-Object Text.UTF8Encoding($false)))
    Start-Transcript -Path $nextLog -Append -ErrorAction Stop | Out-Null
    $rotation.Path = $nextLog
    $rotation.Active = $true
    return $true
}

$global:HubLogRotation = @{ Active = $false; Path = ''; Directory = ''; Timer = $null; LimitBytes = [long](100MB) }
try {
    $logsDir = Get-HubRuntimeLogsRoot
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
    # -File: without it a DIRECTORY called something.log would come back
    # from the filter and get handed to Remove-Item. Cheap guard, and the
    # rule everywhere now is that a delete only ever sees a file.
    Get-ChildItem $logsDir -Filter *.log -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 30 |
        Remove-Item -Force -ErrorAction SilentlyContinue
    foreach ($oldHubLog in @(Get-ChildItem $logsDir -Filter 'Hub-*.log' -File -ErrorAction SilentlyContinue)) {
        Compress-HubSessionLog -Path $oldHubLog.FullName
    }
    Limit-HubLogStorage -Directory $logsDir
    $hubLog = Join-Path $logsDir ("Hub-{0}.log" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))
    @(
        '=== PCVR Mods Installer Hub - Session Log ===',
        ('Started:    ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
        ('Windows:    ' + [Environment]::OSVersion.VersionString),
        ('PowerShell: ' + $PSVersionTable.PSVersion + ' (' + $PSVersionTable.PSEdition + ')'),
        '============================================='
    ) | Out-File -LiteralPath $hubLog -Encoding utf8
    Start-Transcript -Path $hubLog -Append -ErrorAction Stop | Out-Null
    $global:HubLogRotation.Active = $true
    $global:HubLogRotation.Path = $hubLog
    $global:HubLogRotation.Directory = $logsDir
} catch {}

# The optional worker starts only after the visible-window handoff.
# Its metadata reads never establish installation state. The Hub owns its
# captured process handle and stops it on close or after a hard 75 s ceiling.
$global:HubScanWarmupStartedUtc = $null
$global:HubScanWarmupProcess = $null
$global:HubScanWarmupTimer = $null
$global:HubScanWarmupClock = $null
$global:HubScanWarmupQueued = $false
function global:Stop-HubScanWarmup {
    if ($global:HubScanWarmupTimer) { try { $global:HubScanWarmupTimer.Stop() } catch {} }
    $global:HubScanWarmupTimer = $null
    $owned = $global:HubScanWarmupProcess
    $global:HubScanWarmupProcess = $null
    if ($owned) {
        try { if (-not $owned.HasExited) { $owned.Kill(); [void]$owned.WaitForExit(1000) } } catch {}
        try { $owned.Dispose() } catch {}
    }
    if ($global:HubScanWarmupClock) { try { $global:HubScanWarmupClock.Stop() } catch {} }
    $global:HubScanWarmupClock = $null
}
function global:Update-HubScanWarmupLifetime {
    $owned = $global:HubScanWarmupProcess
    if (-not $owned) { Stop-HubScanWarmup; return }
    try {
        if ($owned.HasExited -or ($global:HubScanWarmupClock -and $global:HubScanWarmupClock.ElapsedMilliseconds -ge 75000)) { Stop-HubScanWarmup }
    } catch { Stop-HubScanWarmup }
}
function global:Start-HubScanWarmup {
    param([string]$CoreDirectory)
    if ($env:PCVR_HUB_SCAN_WARMUP -eq '0' -or $env:PCVR_HUB_TEST_MODE -eq '1' -or $global:HubScanWarmupStartedUtc) { return }
    if (-not $global:HubStartupTransitionComplete -or -not $global:window -or -not $global:window.IsVisible) { return }
    try {
        $CoreDirectory = [IO.Path]::GetFullPath($CoreDirectory).TrimEnd([char[]]'\/')
        $warmupScript = Join-Path $CoreDirectory 'Modules\ScanWarmup.ps1'
        if (-not [IO.File]::Exists($warmupScript)) { return }
        $summaryPath = Join-Path (Get-HubRuntimeLogsRoot) 'ScanWarmup.json'
        $global:HubScanWarmupProcess = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru -ArgumentList @(
            '-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden',
            '-File',('"'+$warmupScript+'"'),'-ScriptDir',('"'+$CoreDirectory+'"'),'-SummaryPath',('"'+$summaryPath+'"'))
        # Hold the original process object, even if Windows later reuses its PID.
        [void]$global:HubScanWarmupProcess.Handle
        $global:HubScanWarmupStartedUtc = [DateTime]::UtcNow
        $global:HubScanWarmupClock = [Diagnostics.Stopwatch]::StartNew()
        $global:HubScanWarmupTimer = [Windows.Threading.DispatcherTimer]::new()
        $global:HubScanWarmupTimer.Interval = [TimeSpan]::FromSeconds(1)
        $global:HubScanWarmupTimer.Add_Tick({ Update-HubScanWarmupLifetime })
        $global:HubScanWarmupTimer.Start()
    } catch { Stop-HubScanWarmup }
}

# Keep an active transcript bounded as well. Rotation runs on the Hub UI
# dispatcher, in the same runspace that owns Start-Transcript.
$global:HubLogRotation.Timer = $null
if ($global:HubLogRotation.Active) {
    $global:HubLogRotation.Timer = New-Object System.Windows.Threading.DispatcherTimer
    $global:HubLogRotation.Timer.Interval = [TimeSpan]::FromSeconds(2)
    $global:HubLogRotation.Timer.Add_Tick({
        try {
            [void](Update-HubLogRotation)
        } catch {}
    })
    $global:HubLogRotation.Timer.Start()
}

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
$global:HubPerformanceLog = $null
try {
    . (Join-Path $PSScriptRoot 'Modules\HubPerformance.ps1')
    $performanceRoot = [Environment]::GetFolderPath('LocalApplicationData')
    if ($env:PCVR_HUB_TEST_MODE -eq '1') { $performanceRoot = $env:PCVR_HUB_TEST_LOCALAPPDATA }
    $global:HubPerformanceLog = New-PCVRPerformanceLog -LocalRoot $performanceRoot -Process classic
} catch { }
try {
    $timingFlag = Join-Path $rootDir ".timing"
    if ((Test-Path $timingFlag) -or $env:PCVR_HUB_STARTUP_TIMING -eq '1') {
        $global:HubTiming.Enabled = $true
        # Count from the PROCESS start (test build): the log then also covers
        # powershell.exe start-up, the WPF assembly load and HubState.ps1,
        # which used to happen before the old zero point.
        $global:HubTiming.Start = [DateTime]::UtcNow
        try { $global:HubTiming.Start = [System.Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime() } catch { }
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
if ($global:HubParsePrefetch) { Write-HubTiming ("parse prefetch: running on {0} threads" -f $global:HubParsePrefetch.Threads) }
elseif ($global:HubParsePrefetchError) { Write-HubTiming ("parse prefetch: disabled ({0})" -f $global:HubParsePrefetchError) }
else { Write-HubTiming "parse prefetch: off (PCVR_HUB_PARALLEL_PARSE=0 or fewer than 4 CPUs)" }

# -------------------------------------------------------
# Version & Update check
# -------------------------------------------------------
$HUB_VERSION = "0.8.8.8"
$global:HubCurrentVersion = $HUB_VERSION

$updateInfoFile  = Get-HubUpdateInfoPath
$script:updateInfo = $null
if ($updateInfoFile -and (Test-Path $updateInfoFile)) {
    try {
        $candidate = Get-Content $updateInfoFile -Raw | ConvertFrom-Json
        if (Test-HubUpdateInfoIsNewer -Info $candidate -CurrentVersion $HUB_VERSION) {
            $script:updateInfo = $candidate
        }
    } catch {}
}

# HUB-MODULE-PART: Modules\InstalledState.ps1
. (Join-Path $scriptDir "Modules\InstalledState.ps1")

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
    "Favorites.ps1",
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
    "HeaderFx.ps1",
    "BannerGlass.ps1",
    "BannerFxExtra.ps1",
    "CustomGames.ps1",
    "Startup.ps1"
)) {
    $__modScript = Get-HubModuleScript (Join-Path $modulesDir $mod)
    # Startup.ps1 ends in ShowDialog: release the parse workers first.
    if ($mod -eq "Startup.ps1") {
        Close-HubParsePrefetch
        $window.Add_ContentRendered({
            if ($global:HubScanWarmupQueued) { return }
            $global:HubScanWarmupQueued = $true
            # Run after all ContentRendered handlers, including the real ready
            # signal. Startup scan pumping cannot precede that visible handoff.
            [void]$window.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background,[action]{
                Start-HubScanWarmup -CoreDirectory $global:scriptDir
            })
        })
        $window.Add_Closed({ Stop-HubScanWarmup })
    }
    . $__modScript
    Write-HubTiming ("module loaded: {0}" -f $mod)
}
