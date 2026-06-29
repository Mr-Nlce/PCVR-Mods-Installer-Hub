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
    [string]$LogsDir    = ""
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
            }
        } catch {}
    }
}

$transcriptOn = $false
try { Start-Transcript -LiteralPath $log -Append -ErrorAction Stop | Out-Null; $transcriptOn = $true } catch {}

try {
    if ($coreScript -and (Test-Path $coreScript)) {
        Push-Location (Split-Path $coreScript -Parent)
        try { & $coreScript @coreArgs } finally { Pop-Location }
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
