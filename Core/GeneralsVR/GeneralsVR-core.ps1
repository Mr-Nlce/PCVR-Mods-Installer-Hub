# ============================================================
#  Command & Conquer Generals Zero Hour VR - GeneralsVR
#  by Gonzorro
# ------------------------------------------------------------
#  THIS MOD NEVER TOUCHES THE GAME. It lives entirely in
#  %LOCALAPPDATA%\GeneralsVR and merely points the game engine at
#  the existing Zero Hour install. Uninstalling means deleting that
#  folder and the shortcut.
#
#  WHICH IS ALSO WHY THIS INSTALLER DOES NOT SEARCH FOR THE GAME -
#  the mod's launcher finds Steam, EA and GOG by itself and asks
#  once if it cannot. Reimplementing it here would only make it worse.
#
#  TWO ROUTES, both intended by the author and equivalent:
#    [1] Setup.cmd - downloads the newest build and sets everything
#        up. Nothing to unpack.
#    [2] the ZIP - the same result by hand.
#  The launcher then updates itself on EVERY game start; an
#  auto-update from us is not needed.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Generals Zero Hour VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers - they are NOT in
# InstallerSafety.ps1, and WHICH ones exist differs from installer to
# installer.
function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m"  -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m"  -ForegroundColor Red }
function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}

$MOD_NAME    = "GeneralsVR"
$MOD_AUTHOR  = "Gonzorro"
$MOD_VERSION = "v0.2.0.2-alpha"
$REPO        = "Gonzorro/GeneralsVR"
$RELEASES    = "https://github.com/$REPO/releases"
$SETUP_CMD   = "GeneralsVR-Setup.cmd"
$START_CMD   = "START-GeneralsVR.cmd"
$INSTALL_DIR = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "GeneralsVR"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Command & Conquer Generals Zero Hour VR - Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  The original game running natively in a headset. You stand" -ForegroundColor White
Write-Host "  over the battlefield like a general at a war table: point a" -ForegroundColor White
Write-Host "  laser to select, give orders with the controllers, and resize" -ForegroundColor White
Write-Host "  yourself from the whole war on a table down to standing among" -ForegroundColor White
Write-Host "  the tanks." -ForegroundColor White
Write-Host ""
Write-Host "  Your Zero Hour install is NEVER touched. Everything lives in" -ForegroundColor Gray
Write-Host "     $INSTALL_DIR" -ForegroundColor Gray
Write-Host ""
Write-Host "  Early alpha, and the author asks for reports. Skirmish plays" -ForegroundColor Yellow
Write-Host "  end to end; expect rough edges." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Before you start, three things:" -ForegroundColor White
Write-Host "   - Install Zero Hour and launch it ONCE normally" -ForegroundColor White
Write-Host "   - Install the Meta Quest Link app and connect the headset" -ForegroundColor White
Write-Host "   - Set Meta as the active OpenXR runtime (Quest Link app," -ForegroundColor White
Write-Host "     Settings, General). Quest 3 over Link is the tested path;" -ForegroundColor White
Write-Host "     other PC VR headsets are untested." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Pick the route ----------------------------------------
Write-Step 1 3 "How do you want to install it"
Write-Host ""
Write-Host "    [1] The setup file" -ForegroundColor White
Write-Host "        A small .cmd that pulls the newest build down as it" -ForegroundColor Gray
Write-Host "        runs. Nothing is extracted here." -ForegroundColor Gray
Write-Host ""
Write-Host "    [2] The full ZIP" -ForegroundColor White
Write-Host "        The complete package. This installer unpacks it for you" -ForegroundColor Gray
Write-Host "        and starts it - same as [1], just a bigger download." -ForegroundColor Gray
Write-Host ""
Write-Host "  EITHER WAY THIS INSTALLER DOES THE WORK - you are only" -ForegroundColor White
Write-Host "  choosing which file it fetches. Both end up in the same" -ForegroundColor White
Write-Host "  place, and the author offers both." -ForegroundColor White
Write-Host ""
$route = ""
while ($route -ne "1" -and $route -ne "2") {
    $route = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
    if ($route -eq "") { $route = "1" }
    if ($route -ne "1" -and $route -ne "2") { Write-Warn "Please type 1 or 2." }
}

function Show-Afterwards {
    Write-Host ""
    Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " WHAT HAPPENS NOW" -ForegroundColor Cyan
    Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Windows SmartScreen may warn about an unrecognized app -" -ForegroundColor White
    Write-Host "  normal for an unsigned community mod. Click 'More info'," -ForegroundColor White
    Write-Host "  then 'Run anyway'." -ForegroundColor White
    Write-Host ""
    Write-Host "  It asks for administrator rights ONCE, to write the registry" -ForegroundColor White
    Write-Host "  entries the game engine needs, and puts a GeneralsVR" -ForegroundColor White
    Write-Host "  shortcut on your desktop. Use that shortcut from then on." -ForegroundColor White
    Write-Host ""
    Write-Host "  THE HEADSET STAYS DARK IN THE MENUS - that is not a fault." -ForegroundColor Yellow
    Write-Host "  Only the battlefield is rendered, so start a Skirmish before" -ForegroundColor White
    Write-Host "  you go looking for the picture." -ForegroundColor White
    Write-Host ""
    Write-Host "  The launcher updates itself to the newest build every time" -ForegroundColor Gray
    Write-Host "  you play. If an update ever breaks something, press V in the" -ForegroundColor Gray
    Write-Host "  launcher and pick the previous version." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Found a bug? Attach the files from" -ForegroundColor Gray
    Write-Host "     $INSTALL_DIR\Debug" -ForegroundColor Cyan
    Write-Host "  mainly DebugLogFile.txt and xrhost_log.txt." -ForegroundColor Gray
    Write-Host ""
}

# ---- 2. Fetch the file ----------------------------------------
Write-Step 2 3 "Getting the files"

$tmp = Join-Path $env:TEMP ("generalsvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$runMe = $null

if ($route -eq "1") {
    $patterns = @("GeneralsVR-Setup.cmd", "*GeneralsVR*Setup*.cmd")
    $found = Find-PredownloadedFile -Patterns $patterns -Label "the GeneralsVR setup file"
    if (-not $found) {
        $dest = Join-Path $tmp $SETUP_CMD
        Invoke-SafeDownload -Urls @("https://github.com/$REPO/releases/latest/download/$SETUP_CMD") `
            -Destination $dest -Label "$MOD_NAME setup" -ManualUrl $RELEASES `
            -Instructions "Download $SETUP_CMD from the releases page, save it as '$dest', then choose Retry."
        if (Test-Path -LiteralPath $dest) { $found = $dest }
    }
    $runMe = $found
} else {
    $patterns = @("GeneralsVR-v*.zip", "*GeneralsVR*.zip")
    $zip = Find-PredownloadedFile -Patterns $patterns -Label "the GeneralsVR ZIP"
    if (-not $zip) {
        $dest = Join-Path $tmp "GeneralsVR.zip"
        # The asset carries the version in its name, so resolve it
        # through the API instead of guessing a fixed address.
        $url = $null
        try {
            $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
                       -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
            if (Test-IsPayloadRelease -Release $rel) {
                $pick = Select-PayloadAsset -Assets $rel.assets -PlatformPattern '(?i)GeneralsVR' -MinBytes 500000
                if ($pick) { $url = [string]$pick.browser_download_url }
            }
        } catch {}
        if ($url) {
            Invoke-SafeDownload -Urls @($url) -Destination $dest -Label "$MOD_NAME" -ManualUrl $RELEASES `
                -Instructions "Download the GeneralsVR ZIP from the releases page, save it as '$dest', then choose Retry."
            if (Test-Path -LiteralPath $dest) { $zip = $dest }
        } else {
            Write-Warn "Could not resolve the release automatically."
            Pause-User "Press Enter to open the releases page..." | Out-Null
            try { Start-Process $RELEASES } catch { Write-Warn "Open manually: $RELEASES" }
            Pause-User "Press Enter once the download has finished..." | Out-Null
            $zip = Find-PredownloadedFile -Patterns $patterns -Label "the GeneralsVR ZIP" -PageAlreadyOpen
        }
    }
    if ($zip -and (Test-Path -LiteralPath $zip)) {
        # A PERMANENT folder, NOT %TEMP%: the launcher keeps running
        # from here. A deleted folder underneath a running program is
        # exactly the fault the ZIP route used to have.
        $ex = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\GeneralsVR-setup"
        try { New-Item -ItemType Directory -Path $ex -Force -ErrorAction Stop | Out-Null }
        catch { $ex = Join-Path $tmp "x"; New-Item -ItemType Directory -Path $ex -Force | Out-Null }
        [void](Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ex -Label $MOD_NAME)
        # START-GeneralsVR sits at the archive root - search the whole
        # tree in case a wrapper folder gets in between.
        $hit = Get-ChildItem -LiteralPath $ex -Recurse -File -Force -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -ieq $START_CMD } | Select-Object -First 1
        if ($hit) { $runMe = $hit.FullName }
        else { Write-Fail "No $START_CMD inside the archive." }
    }
}

if (-not $runMe -or -not (Test-Path -LiteralPath $runMe)) {
    Write-Fail "Nothing to run - nothing was changed."
    Write-Host "  Get it from: $RELEASES" -ForegroundColor Cyan
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Using: $runMe"

# ---- 3. Run the mod's own launcher ----------------------------
Write-Step 3 3 "Running the author's own installer"
Write-Host ""
Write-Host "  From here the mod takes over: it finds your Zero Hour install" -ForegroundColor White
Write-Host "  (Steam, EA app, Origin, GOG or retail), fetches the newest" -ForegroundColor White
Write-Host "  build and sets everything up in its own folder." -ForegroundColor White
Show-Afterwards
Pause-User "Press Enter to run it - UAC required..." | Out-Null
try {
    Start-Process -FilePath $runMe -WorkingDirectory (Split-Path $runMe -Parent) -Wait -ErrorAction Stop
    Write-OK "Finished."
} catch {
    Write-Warn "Could not start it: $($_.Exception.Message)"
    Write-Host "  Run it yourself: $runMe" -ForegroundColor Yellow
}

if (Test-Path -LiteralPath (Join-Path $INSTALL_DIR "Data\generalszhv.exe")) {
    Write-OK "GeneralsVR is installed in $INSTALL_DIR"
    # Marker for the Hub - into the INSTALLER folder, not the game.
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $INSTALL_DIR -Encoding UTF8 -Force } catch {}
} else {
    Write-Info "If you cancelled, run this installer again - nothing was left behind."
}
# Only clean up the temporary download directory. The EXTRACTED folder
# stays - the launcher keeps working out of it.
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
if ($ex -and (Test-Path -LiteralPath $ex) -and ($ex -notlike "$tmp*")) {
    Write-Host ""
    Write-Host "  The extracted files stay here - do not delete them while" -ForegroundColor Gray
    Write-Host "  the launcher is still doing its first run:" -ForegroundColor Gray
    Write-Host "     $ex" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Sir, the war table is ready. Mind the tanks near your boots." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
