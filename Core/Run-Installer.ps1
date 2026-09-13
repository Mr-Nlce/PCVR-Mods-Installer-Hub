# ============================================================
#  PCVR Mods Installer Hub - installer log wrapper
# ============================================================
# Runs a single installer with its console output captured to
#   Core\Logs\<Title>-<timestamp>.log
# so a failed install can be attached to a GitHub bug report.
#
# Launched via Start-Process by Start-LoggedInstaller (Helpers.ps1); it is
# never started by hand. The installer's core .ps1 runs in a child PowerShell
# runspace attached to this console host. That preserves Write-Host colours and
# interactive prompts, while containing old cores that finish with `exit` so
# the wrapper can always finalize evidence and show its recovery screen.
param(
    [string]$Title      = "Installer",
    [string]$Kind       = "Bat",     # Bat | LukeRoss | Ref
    [string]$BatPath    = "",
    [string]$Ps1Path    = "",
    [string]$GameTitle  = "",
    [string]$GameFolder = "",
    [string]$GameExe    = "",
    [string]$GameId     = "",
    [string]$LogsDir    = "",
    [string]$StatusPath = "",
    [string]$VersionPath = "",
    [string]$VersionPathB = "",
    [string]$InstallPath = "",
    [string]$InstallerChoice = "",
    [switch]$NoProcessExit
)

$ErrorActionPreference = 'Continue'
# Whether THIS wrapper process is already elevated. Set when the
# RequiresAdmin path (Start-LoggedInstaller) relaunched us via RunAs - in
# that case a self-elevating installer .bat can run its core in-process here
# instead of spawning a second elevated window.
$wrapperIsAdmin = $false
try { $wrapperIsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch {}
try { [Console]::Title = "$Title - Installer" } catch {}

# This wrapper runs inside a fresh powershell.exe window, whose default
# background is the classic PowerShell blue. Force the standard installer
# look (black background, cyan text - same as the START_INSTALLER.bat
# 'color 0B') so logged installs match the non-logged ones. The installer
# cores now run in-process (see below), so the per-bat 'color' no longer
# executes when launched from the Hub - this is what sets the look.
$wrapperExitCode = 0
$oldInstallStatusPath = $env:PCVR_HUB_INSTALL_STATUS_PATH
$oldInstallRunId = $env:PCVR_HUB_INSTALL_RUN_ID
$oldHubGameId = $env:PCVR_HUB_GAME_ID
if (-not [string]::IsNullOrWhiteSpace($GameId)) { $env:PCVR_HUB_GAME_ID = $GameId }
if (-not [string]::IsNullOrWhiteSpace($StatusPath)) {
    $env:PCVR_HUB_INSTALL_STATUS_PATH = $StatusPath
    $env:PCVR_HUB_INSTALL_RUN_ID = [Guid]::NewGuid().ToString('N')
}
:InstallerRun while ($true) {
$wrapperExitCode = 0
try {
    $rawUI = $Host.UI.RawUI
    $rawUI.BackgroundColor = 'Black'
    $rawUI.ForegroundColor = 'Cyan'
    Clear-Host
} catch {}

$wrapperDir = Split-Path -Parent $PSCommandPath  # Core
if ([string]::IsNullOrWhiteSpace($LogsDir)) {
    $LogsDir = [IO.Path]::Combine($wrapperDir, 'Logs')
}
$logsDir = $LogsDir
try { if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null } } catch {}

# Keep the folder tidy: most recent 30 logs only.
try {
    Get-ChildItem $logsDir -Filter *.log -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 30 |
        Remove-Item -Force -ErrorAction SilentlyContinue
} catch {}

$safe = ($Title -replace '[\\/:*?"<>|]', '').Trim()
if ([string]::IsNullOrWhiteSpace($safe)) { $safe = "Installer" }
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$log = Join-Path $logsDir ("{0}-{1}.log" -f $safe, $stamp)

function Get-InstallerLogHeader {
    return @(
        '=== PCVR Mods Installer Hub - Installer Log ===',
        "Title:      $Title",
        "Date:       $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Windows:    $([Environment]::OSVersion.VersionString)",
        "PowerShell: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))",
        '================================================'
    )
}

function ConvertTo-PrivacySafeInstallerLogText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $safeText = [string]$Text
    # Installer paths are useful, but a Windows profile name and machine name
    # are not. Replace only known local identity roots; game and mod paths
    # outside the profile remain visible for diagnosis.
    $replacements = @(
        @($env:LOCALAPPDATA, '%LOCALAPPDATA%'),
        @($env:APPDATA, '%APPDATA%'),
        @($env:TEMP, '%TEMP%'),
        @($env:USERPROFILE, '%USERPROFILE%'),
        @($env:COMPUTERNAME, '%COMPUTERNAME%')
    )
    foreach ($pair in $replacements) {
        $value = [string]$pair[0]
        if ([string]::IsNullOrWhiteSpace($value)) { continue }
        $safeText = [regex]::Replace($safeText, [regex]::Escape($value), [string]$pair[1], [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    return $safeText
}

Get-InstallerLogHeader | Out-File -FilePath $log -Encoding utf8

# Resolve the installer's core .ps1 so we can run it IN-PROCESS, in this
# wrapper's own console. This is what brings the text colors back: piping a
# child through "2>&1 | Tee-Object" makes PowerShell drop every Write-Host
# color (redirected output becomes plain text) - that is why the installers
# went monochrome. Running the core in-process keeps a real console (colors
# intact). A temporary child transcript makes output visible in the log while
# the installer is still open; completion immediately rewrites that transcript
# into one concise, privacy-safe copy of the captured installer output.
# Calling a .ps1 with "&" runs it in its own child scope AND sets that
# script's own $PSScriptRoot, so its relative paths keep working and nothing
# leaks into this wrapper.
$coreScript = $null
$coreArgs   = @{}
switch ($Kind) {
    "LukeRoss" { $coreScript = $BatPath; $coreArgs = @{ GameTitle = $GameTitle } }
    "Ref"      { $coreScript = $Ps1Path; $coreArgs = @{ GameTitle = $GameTitle; GameFolder = $GameFolder; GameExe = $GameExe } }
    "Direct"   { $coreScript = $BatPath }
    default {
        # Bat kind: normally pull the -File "%~dp0<core>.ps1" the bat launches
        # and run that core in-process (keeps colors + full transcript).
        # EXCEPTION: if the bat manages its own admin elevation (net session /
        # RunAs - e.g. Alien Isolation), leave $coreScript null so the bat runs
        # as-is below. Bypassing it would skip the UAC prompt and the core
        # would just print "needs admin". Such elevated installs can't be
        # transcript-logged across the UAC boundary anyway, so nothing is lost.
        try {
            $batText = Get-Content -LiteralPath $BatPath -Raw -ErrorAction Stop
            $selfElevates = ($batText -match '(?i)net session|RunAs')
            # Pull the core .ps1 and run it in-process (keeps colors + a full
            # transcript). For a self-elevating bat (e.g. Alien Isolation) only
            # do this when THIS wrapper is ALREADY elevated - i.e. the
            # RequiresAdmin path relaunched us via RunAs - so the core runs here
            # under the transcript. If we are not elevated, leave it to the
            # bat's own RunAs (a fresh, unavoidably unlogged elevated window) so
            # the UAC prompt still appears.
            if ((-not $selfElevates) -or $wrapperIsAdmin) {
                $m = [regex]::Match($batText, '(?i)-File\s+"%~dp0([^"]+\.ps1)"')
                if ($m.Success) { $coreScript = Join-Path (Split-Path $BatPath -Parent) $m.Groups[1].Value }
                else {
                    # 32 of the bats build the path in a variable first
                    # (set "PS1=%SCRIPT_DIR%X-core.ps1" ... -File "%PS1%"),
                    # which the pattern above cannot see. Those installers ran
                    # fine, but OUTSIDE this wrapper: no full transcript and no
                    # .update_ok marker, so a mod that had just been updated
                    # could keep showing "Update available".
                    # So: take any .ps1 NAME the bat mentions and accept the
                    # first one that really sits next to the bat. Works for
                    # both styles and for whatever a future bat invents.
                    $batDir = Split-Path $BatPath -Parent
                    foreach ($cand in [regex]::Matches($batText, '(?i)([A-Za-z0-9._-]+\.ps1)')) {
                        $try = Join-Path $batDir $cand.Groups[1].Value
                        if (Test-Path -LiteralPath $try) { $coreScript = $try; break }
                    }
                }
            }
        } catch {}
    }
}
if ($InstallerChoice) { $coreArgs['Mod'] = $InstallerChoice }

# Snapshot the exact files the Hub reads before the installer runs.  A
# successful core may write an authoritative downloaded tag; generic older
# installers write no version at all.  The parent must distinguish those
# cases, otherwise its old "clear and reseed" step erases good Forza-style
# markers as soon as they are written.
function Get-MarkerSnapshot {
    param([string]$Path)
    $o = [ordered]@{ Path = $Path; Exists = $false; Ticks = 0; Length = 0; Value = '' }
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [pscustomobject]$o }
    try {
        $i = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        $o.Exists = $true
        $o.Ticks = $i.LastWriteTimeUtc.Ticks
        $o.Length = $i.Length
        $o.Value = "" + (Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
    } catch {}
    return [pscustomobject]$o
}

function Test-MarkerChanged {
    param($Before, $After)
    if (-not $Before -or -not $After) { return $false }
    return (($Before.Path -cne $After.Path) -or ($Before.Exists -ne $After.Exists) -or ($Before.Ticks -ne $After.Ticks) -or
            ($Before.Length -ne $After.Length) -or ($Before.Value -cne $After.Value))
}

function Get-RecordedInstallRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        $v = ("" + (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop)).Trim()
        if ($v -and (Test-Path -LiteralPath $v -PathType Container)) { return $v }
    } catch {}
    return $null
}

# Defence in depth: Start-LoggedInstaller already clears this marker before
# spawning us, but the wrapper is also used directly by regression tests and
# may be called by future launch routes. A previous success must never be
# mistaken for the result of this run.
if (-not [string]::IsNullOrWhiteSpace($StatusPath) -and (Test-Path -LiteralPath $StatusPath -PathType Leaf)) {
    try { Remove-Item -LiteralPath $StatusPath -Force -ErrorAction Stop } catch {}
}

$beforeVersion  = Get-MarkerSnapshot -Path $VersionPath
$beforeVersionB = Get-MarkerSnapshot -Path $VersionPathB
$beforeInstallPath = Get-MarkerSnapshot -Path $InstallPath
$beforeRoot = Get-RecordedInstallRoot -Path $InstallPath
$beforeGameVersion  = Get-MarkerSnapshot -Path $(if ($beforeRoot) { Join-Path $beforeRoot '.pcvrhub_version' } else { '' })
$beforeGameVersionB = Get-MarkerSnapshot -Path $(if ($beforeRoot) { Join-Path $beforeRoot '.pcvrhub_version_b' } else { '' })

# Finalize a successful installer from fresh evidence only. This is a function
# because many older installer cores end with `exit 0`. PowerShell executes a
# surrounding finally block before honoring that exit, but code placed after
# the `& $coreScript` call is skipped completely. Keeping the finalizer in the
# finally block below makes both normal returns and successful exit-based cores
# produce the same typed transaction result. A cancel/failure still has no
# freshly changed version/path marker and therefore cannot claim success.
function Write-FreshInstallerSuccessResult {
    try {
        $afterVersion  = Get-MarkerSnapshot -Path $VersionPath
        $afterVersionB = Get-MarkerSnapshot -Path $VersionPathB
        $afterInstallPath = Get-MarkerSnapshot -Path $InstallPath
        $afterRoot = Get-RecordedInstallRoot -Path $InstallPath
        $afterGameVersion  = Get-MarkerSnapshot -Path $(if ($afterRoot) { Join-Path $afterRoot '.pcvrhub_version' } else { '' })
        $afterGameVersionB = Get-MarkerSnapshot -Path $(if ($afterRoot) { Join-Path $afterRoot '.pcvrhub_version_b' } else { '' })
        # A path becoming known is not version evidence. The resulting marker
        # must actually exist and differ from the pre-run snapshot; otherwise a
        # newly written install path could make an absent game-folder marker
        # look like a freshly written version marker.
        $primaryWritten = ($afterVersion.Exists -and (Test-MarkerChanged -Before $beforeVersion -After $afterVersion)) -or
                          ($afterGameVersion.Exists -and (Test-MarkerChanged -Before $beforeGameVersion -After $afterGameVersion))
        $secondaryWritten = ($afterVersionB.Exists -and (Test-MarkerChanged -Before $beforeVersionB -After $afterVersionB)) -or
                            ($afterGameVersionB.Exists -and (Test-MarkerChanged -Before $beforeGameVersionB -After $afterGameVersionB))
        # A normal return is NOT proof of success. Several older cores display
        # [X] and use `return` after a handled failure. Only a freshly written
        # marker is authoritative enough to clear an Update badge.
        $installPathWritten = $afterInstallPath.Exists -and
                              (Test-MarkerChanged -Before $beforeInstallPath -After $afterInstallPath) -and [bool]$afterRoot
        $successEvidence = @()
        if ($primaryWritten)     { $successEvidence += 'version' }
        if ($secondaryWritten)   { $successEvidence += 'version_b' }
        if ($installPathWritten) { $successEvidence += 'installed_path' }

        if ($successEvidence.Count -gt 0) {
            $okMk = $StatusPath
            if ([string]::IsNullOrWhiteSpace($okMk)) { $okMk = Join-Path (Split-Path $coreScript -Parent) ".update_ok" }
            $okParent = Split-Path -Parent $okMk
            if ($okParent -and -not (Test-Path -LiteralPath $okParent)) { New-Item -ItemType Directory -Path $okParent -Force | Out-Null }
            $status = [ordered]@{
                outcome = 'success'
                completedAt = (Get-Date -Format o)
                evidence = @($successEvidence)
                versionWritten = [bool]$primaryWritten
                versionBWritten = [bool]$secondaryWritten
                installedPathWritten = [bool]$installPathWritten
                installedPath = [string]$afterRoot
                versionValue = if ($primaryWritten) {
                    if ((Test-MarkerChanged -Before $beforeVersion -After $afterVersion) -and $afterVersion.Value) { [string]$afterVersion.Value }
                    elseif ($afterGameVersion.Value) { [string]$afterGameVersion.Value }
                    else { '' }
                } else { '' }
                versionBValue = if ($secondaryWritten) {
                    if ((Test-MarkerChanged -Before $beforeVersionB -After $afterVersionB) -and $afterVersionB.Value) { [string]$afterVersionB.Value }
                    elseif ($afterGameVersionB.Value) { [string]$afterGameVersionB.Value }
                    else { '' }
                } else { '' }
            }
            [System.IO.File]::WriteAllText($okMk, ($status | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding $false))
        }
    } catch {}
}

# Run installer cores in their own PowerShell runspace while keeping this
# wrapper's console host. Old cores commonly use `exit 0` / `exit 1`. When a
# core was invoked directly with `&`, either exit terminated THIS wrapper too:
# a failure could flash and vanish before the Retry / Log screen was reached.
# A child runspace contains that exit, preserves interactive Read-Host and
# Write-Host colours through the shared host, and returns an inspectable exit
# state to the wrapper.
function Invoke-InstallerCoreRunspace {
    param([string]$Path,[hashtable]$Arguments,[string]$TranscriptPath='')
    $runspace = $null
    $pipeline = $null
    try {
        $runspace = [RunspaceFactory]::CreateRunspace($Host)
        $runspace.Open()
        try { $runspace.SessionStateProxy.Path.SetLocation((Split-Path $Path -Parent)) } catch {}
        $pipeline = [PowerShell]::Create()
        $pipeline.Runspace = $runspace
        # A transcript started in the PARENT wrapper cannot see Write-Host from
        # this child runspace. Start one inside the runspace instead so the log
        # fills while an interactive installer is still open, not only after
        # its last "Press Enter" prompt has closed.
        $invokeScript = {
            param([string]$InstallerPath,[hashtable]$InstallerArguments,[string]$LiveTranscriptPath)
            $liveTranscript = $false
            try {
                if ($LiveTranscriptPath) {
                    Start-Transcript -LiteralPath $LiveTranscriptPath -Append -ErrorAction Stop | Out-Null
                    $liveTranscript = $true
                }
                & $InstallerPath @InstallerArguments
            } finally {
                if ($liveTranscript) { try { Stop-Transcript | Out-Null } catch {} }
            }
        }
        [void]$pipeline.AddScript($invokeScript.ToString())
        [void]$pipeline.AddArgument($Path)
        [void]$pipeline.AddArgument($Arguments)
        [void]$pipeline.AddArgument($TranscriptPath)

        $invokeFailure = $null
        $output = @()
        try { $output = @($pipeline.Invoke()) } catch { $invokeFailure = $_ }
        $exitCode = $runspace.SessionStateProxy.GetVariable('LASTEXITCODE')
        $state = $pipeline.InvocationStateInfo.State
        $reason = $pipeline.InvocationStateInfo.Reason

        $capture = New-Object System.Collections.Generic.List[string]
        foreach ($item in $output) {
            $line = ('' + $item).TrimEnd()
            if ($line) { [void]$capture.Add($line); Write-Host $line }
        }
        foreach ($record in @($pipeline.Streams.Information)) {
            $message = $null
            try {
                if ($record.MessageData -is [Management.Automation.HostInformationMessage]) { $message = [string]$record.MessageData.Message }
                else { $message = [string]$record.MessageData }
            } catch { $message = '' + $record }
            if ($message) { [void]$capture.Add($message) }
        }
        foreach ($record in @($pipeline.Streams.Warning)) { [void]$capture.Add('[WARNING] ' + $record) }
        foreach ($record in @($pipeline.Streams.Error))   { [void]$capture.Add('[ERROR] ' + $record) }
        foreach ($record in @($pipeline.Streams.Verbose)) { [void]$capture.Add('[VERBOSE] ' + $record) }
        foreach ($record in @($pipeline.Streams.Debug))   { [void]$capture.Add('[DEBUG] ' + $record) }

        $numericExit = 0
        $hasNumericExit = ($null -ne $exitCode -and [int]::TryParse(('' + $exitCode),[ref]$numericExit))
        $success = (-not $invokeFailure) -and (-not $pipeline.HadErrors) -and
                   ($state -eq [Management.Automation.PSInvocationState]::Completed) -and
                   ((-not $hasNumericExit) -or $numericExit -eq 0)
        [void]$capture.Add(('[WRAPPER] Core state={0}; exit={1}; hadErrors={2}' -f $state,$(if($hasNumericExit){$numericExit}else{'none'}),$pipeline.HadErrors))
        return [pscustomobject]@{
            Success = $success
            ExitCode = $(if ($hasNumericExit) { $numericExit } else { $null })
            State = $state
            Failure = $invokeFailure
            Reason = $reason
            Capture = @($capture)
        }
    } finally {
        if ($pipeline) { $pipeline.Dispose() }
        if ($runspace) { $runspace.Dispose() }
    }
}

function Save-InstallerCoreCapture {
    param($Result)
    if (-not $Result -or -not $log) { return }
    # The child transcript above is useful only while an installer is still
    # running. Its automatic header repeats usernames, computer names, command
    # lines and PowerShell internals, and the transcript already contains the
    # same Write-Host output as Capture. Replace it atomically with one compact
    # diagnostic record as soon as the core returns.
    try {
        $lines = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in @(Get-InstallerLogHeader)) { [void]$lines.Add([string]$line) }
        [void]$lines.Add('')
        [void]$lines.Add('=== Installer output ===')
        foreach ($line in @($Result.Capture)) {
            [void]$lines.Add((ConvertTo-PrivacySafeInstallerLogText ([string]$line)))
        }
        [void]$lines.Add('=== End installer output ===')
        [void]$lines.Add('')
        [IO.File]::WriteAllLines($log, [string[]]$lines, (New-Object Text.UTF8Encoding($false)))
    } catch {}
}

try {
    if ($coreScript -and (Test-Path $coreScript)) {
        $coreResult = Invoke-InstallerCoreRunspace -Path $coreScript -Arguments $coreArgs -TranscriptPath $log
        Save-InstallerCoreCapture -Result $coreResult
        if (-not $coreResult.Success) {
            $why = if ($coreResult.Failure) { $coreResult.Failure.Exception.Message }
                   elseif ($coreResult.Reason) { $coreResult.Reason.Message }
                   elseif ($null -ne $coreResult.ExitCode) { "Installer stopped with exit code $($coreResult.ExitCode)." }
                   else { "Installer stopped in state $($coreResult.State)." }
            throw $why
        }
        Write-FreshInstallerSuccessResult
    } else {
        # Could not resolve a core .ps1: run the bat the old way. No pipe, so
        # colors still work; the bat's nested powershell just isn't captured.
        & cmd.exe /c $BatPath
        if ($LASTEXITCODE -ne 0) { throw "Installer stopped with exit code $LASTEXITCODE." }
    }
    break InstallerRun
} catch {
    $wrapperExitCode = 1
    try {
        Add-Content -LiteralPath $log -Value ("[WRAPPER] Failure: " + (ConvertTo-PrivacySafeInstallerLogText ([string]$_.Exception.Message))) -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  The installer hit an unexpected error" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host ("  " + $_.Exception.Message) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Nothing is marked complete. You can retry the same installer" -ForegroundColor White
    Write-Host "  without returning to the Hub, or inspect the installer log first." -ForegroundColor White
    Write-Host "  Download and extraction failures normally use the richer" -ForegroundColor DarkGray
    Write-Host "  Retry / drag-and-drop screen before they can reach this point." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [R] Retry installer from the beginning" -ForegroundColor Cyan
    Write-Host "  [L] Open the installer log" -ForegroundColor Cyan
    Write-Host "  [F] Open the installer folder" -ForegroundColor Cyan
    Write-Host "  [Q] Close this installer" -ForegroundColor Cyan
    Write-Host ""
    while ($true) {
        $errorChoice = ("" + (Read-Host "  Your choice")).Trim().ToLowerInvariant()
        if ($errorChoice -in @('r','retry')) {
            Write-Host ""
            Write-Host "  Retrying..." -ForegroundColor Green
            continue InstallerRun
        }
        if ($errorChoice -in @('l','log')) {
            try { Start-Process notepad.exe -ArgumentList "`"$log`"" -ErrorAction Stop | Out-Null }
            catch { Write-Host "  Log: $log" -ForegroundColor Yellow }
            continue
        }
        if ($errorChoice -in @('f','folder')) {
            $installerFolder = if ($coreScript) { Split-Path -Parent $coreScript } elseif ($BatPath) { Split-Path -Parent $BatPath } else { $wrapperDir }
            try { Start-Process explorer.exe -ArgumentList "`"$installerFolder`"" -ErrorAction Stop | Out-Null }
            catch { Write-Host "  Folder: $installerFolder" -ForegroundColor Yellow }
            continue
        }
        if ($errorChoice -in @('q','quit','close')) { break InstallerRun }
        Write-Host "  Please choose R, L, F or Q." -ForegroundColor Yellow
    }
}
}

try {
    $transaction = if ($StatusPath -and (Test-Path -LiteralPath $StatusPath -PathType Leaf)) { 'confirmed' } else { 'not confirmed' }
    Add-Content -LiteralPath $log -Value ("[WRAPPER] Finished with exit code {0}; installation transaction: {1}." -f $wrapperExitCode,$transaction) -Encoding UTF8 -ErrorAction SilentlyContinue
} catch {}
if ($null -eq $oldInstallStatusPath) { Remove-Item Env:PCVR_HUB_INSTALL_STATUS_PATH -ErrorAction SilentlyContinue } else { $env:PCVR_HUB_INSTALL_STATUS_PATH = $oldInstallStatusPath }
if ($null -eq $oldInstallRunId) { Remove-Item Env:PCVR_HUB_INSTALL_RUN_ID -ErrorAction SilentlyContinue } else { $env:PCVR_HUB_INSTALL_RUN_ID = $oldInstallRunId }
if ($null -eq $oldHubGameId) { Remove-Item Env:PCVR_HUB_GAME_ID -ErrorAction SilentlyContinue } else { $env:PCVR_HUB_GAME_ID = $oldHubGameId }
if (-not $NoProcessExit) { exit $wrapperExitCode }
