# ============================================================
#  PCVR Mods Installer Hub - installer log wrapper
# ============================================================
# Runs a single installer with its console output captured to
#   <HubRoot>\Logs\<Title>-<yyyy-MM-dd_HH-mm-ss>.log
# so a failed install can be attached to a GitHub bug report.
#
# Launched via Start-Process by Start-LoggedInstaller (Helpers.ps1); it is
# never started by hand. The installer's core .ps1 is run IN-PROCESS (via the
# "&" call operator) inside this window, with Start-Transcript capturing the
# whole session to the log. This keeps the installers' Write-Host colors -
# an earlier "2>&1 | Tee-Object" approach captured the log but stripped all
# colors, because redirecting a child's output forces plain text. Running
# in-process keeps a real console (colors) and a full transcript (log).
param(
    [string]$Title      = "Installer",
    [string]$Kind       = "Bat",     # Bat | LukeRoss | Ref
    [string]$BatPath    = "",
    [string]$Ps1Path    = "",
    [string]$GameTitle  = "",
    [string]$GameFolder = "",
    [string]$GameExe    = "",
    [string]$LogsDir    = "",
    [string]$StatusPath = "",
    [string]$VersionPath = "",
    [string]$VersionPathB = "",
    [string]$InstallPath = "",
    [string]$InstallerChoice = ""
)

$ErrorActionPreference = 'Continue'
# Whether THIS wrapper process is already elevated. Set when the
# RequiresAdmin path (Start-LoggedInstaller) relaunched us via RunAs - in
# that case a self-elevating installer .bat can run its core in-process here
# (so Start-Transcript captures it) instead of spawning its own unlogged
# elevated window.
$wrapperIsAdmin = $false
try { $wrapperIsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch {}
try { [Console]::Title = "$Title - Installer" } catch {}

# This wrapper runs inside a fresh powershell.exe window, whose default
# background is the classic PowerShell blue. Force the standard installer
# look (black background, cyan text - same as the START_INSTALLER.bat
# 'color 0B') so logged installs match the non-logged ones. The installer
# cores now run in-process (see below), so the per-bat 'color' no longer
# executes when launched from the Hub - this is what sets the look.
try {
    $rawUI = $Host.UI.RawUI
    $rawUI.BackgroundColor = 'Black'
    $rawUI.ForegroundColor = 'Cyan'
    Clear-Host
} catch {}

$wrapperDir = Split-Path -Parent $PSCommandPath  # Core
if ([string]::IsNullOrWhiteSpace($LogsDir)) { $LogsDir = Join-Path $wrapperDir "Logs" }
$logsDir    = $LogsDir                            # Core\Logs (keeps the top folder clean)
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

@(
    "=== PCVR Mods Installer Hub - Installer Log ===",
    "Title:    $Title",
    "Date:     $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Kind:     $Kind",
    "User:     $env:USERNAME    Computer: $env:COMPUTERNAME",
    "OS:       $([Environment]::OSVersion.VersionString)",
    "==============================================="
) | Out-File -FilePath $log -Encoding utf8

# Resolve the installer's core .ps1 so we can run it IN-PROCESS, in this
# wrapper's own console. This is what brings the text colors back: piping a
# child through "2>&1 | Tee-Object" makes PowerShell drop every Write-Host
# color (redirected output becomes plain text) - that is why the installers
# went monochrome. Running the core in-process keeps a real console (colors
# intact) while Start-Transcript captures the whole session to the log.
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

$transcriptOn = $false
try { Start-Transcript -LiteralPath $log -Append -ErrorAction Stop | Out-Null; $transcriptOn = $true } catch {}

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

$beforeVersion  = Get-MarkerSnapshot -Path $VersionPath
$beforeVersionB = Get-MarkerSnapshot -Path $VersionPathB
$beforeRoot = Get-RecordedInstallRoot -Path $InstallPath
$beforeGameVersion  = Get-MarkerSnapshot -Path $(if ($beforeRoot) { Join-Path $beforeRoot '.pcvrhub_version' } else { '' })
$beforeGameVersionB = Get-MarkerSnapshot -Path $(if ($beforeRoot) { Join-Path $beforeRoot '.pcvrhub_version_b' } else { '' })

try {
    if ($coreScript -and (Test-Path $coreScript)) {
        Push-Location (Split-Path $coreScript -Parent)
        try { & $coreScript @coreArgs } finally { Pop-Location }
        # Core returned normally (no 'exit') = the install ran to the
        # end. A cancel inside the core calls 'exit' first and never
        # reaches here. Record whether either authoritative version marker
        # was really written during THIS run; the parent uses that fact to
        # preserve exact installer values and only seeds legacy installers.
        try {
            $afterVersion  = Get-MarkerSnapshot -Path $VersionPath
            $afterVersionB = Get-MarkerSnapshot -Path $VersionPathB
            $afterRoot = Get-RecordedInstallRoot -Path $InstallPath
            $afterGameVersion  = Get-MarkerSnapshot -Path $(if ($afterRoot) { Join-Path $afterRoot '.pcvrhub_version' } else { '' })
            $afterGameVersionB = Get-MarkerSnapshot -Path $(if ($afterRoot) { Join-Path $afterRoot '.pcvrhub_version_b' } else { '' })
            $primaryWritten = (Test-MarkerChanged -Before $beforeVersion -After $afterVersion) -or
                              (Test-MarkerChanged -Before $beforeGameVersion -After $afterGameVersion)
            $secondaryWritten = (Test-MarkerChanged -Before $beforeVersionB -After $afterVersionB) -or
                                (Test-MarkerChanged -Before $beforeGameVersionB -After $afterGameVersionB)
            $okMk = $StatusPath
            if ([string]::IsNullOrWhiteSpace($okMk)) { $okMk = Join-Path (Split-Path $coreScript -Parent) ".update_ok" }
            $okParent = Split-Path -Parent $okMk
            if ($okParent -and -not (Test-Path -LiteralPath $okParent)) { New-Item -ItemType Directory -Path $okParent -Force | Out-Null }
            $status = [ordered]@{
                completedAt = (Get-Date -Format o)
                versionWritten = [bool]$primaryWritten
                versionBWritten = [bool]$secondaryWritten
                installedPath = [string]$afterRoot
            }
            [System.IO.File]::WriteAllText($okMk, ($status | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding $false))
        } catch {}
    } else {
        # Could not resolve a core .ps1: run the bat the old way. No pipe, so
        # colors still work; the bat's nested powershell just isn't captured.
        & cmd.exe /c $BatPath
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($transcriptOn) { try { Stop-Transcript | Out-Null } catch {}; $transcriptOn = $false }
    Write-Host "Log saved to: $log" -ForegroundColor Cyan
    Write-Host "Press Enter to close..." -ForegroundColor DarkGray
    [void](Read-Host)
}

# Normal completion: the installer's own "Press Enter to exit" already held
# the window, so just stop the transcript. (On error the catch above paused.)
if ($transcriptOn) { try { Stop-Transcript | Out-Null } catch {} }
