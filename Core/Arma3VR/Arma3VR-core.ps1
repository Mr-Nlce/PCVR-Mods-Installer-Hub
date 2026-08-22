# ============================================================
#  Arma 3 VR - A3VR Hybrid (gborgogno)
# ------------------------------------------------------------
#  TWO ROUTES, and the user picks in step 1:
#    [1] GitHub build - this installer places @A3VR_Hybrid next to
#        the game and fetches future builds itself.
#    [2] Steam Workshop - the mod is subscribed through Steam and
#        kept current by Steam. We then install NOTHING and open the
#        workshop page showing the procedure instead.
#
#  IMPORTANT FOR BOTH: the archive carries a WRAPPER FOLDER
#  @A3VR_Hybrid - that whole folder belongs in the Arma folder, not
#  its contents. The official Arma launcher looks for exactly that
#  folder name.
#
#  AND: the mod is NOT fully set up at that point. The launcher
#  entry, BattlEye and FreeTrack are hand work inside the game -
#  that appears as a Quick Start on screen at the end.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Arma 3 VR Installer"

# EVERY installer brings its own console helpers - they are NOT in
# InstallerSafety.ps1. Word for word the same as in the other
# installers, so output looks identical across the whole Hub.
function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-Line { Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray }
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
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}
function Read-FolderPath {
    param([string]$Prompt = "  Folder")
    $p = (Read-Host $Prompt).Trim().Trim('"')
    if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    return $null
}
$ErrorActionPreference = "Stop"

$GAME_NAME    = "Arma 3"
$GAME_EXE     = "arma3_x64.exe"
$APP_ID       = "107410"
$MOD_DIR_NAME = "@A3VR_Hybrid"
$MOD_PROBE    = "$MOD_DIR_NAME\A3VRHybridCore_x64.dll"

$MOD_NAME     = "A3VR Hybrid"
$MOD_AUTHOR   = "gborgogno"
$MOD_VERSION  = "v1.13.1-alpha.1 (public alpha)"
$REPO         = "gborgogno/a3vr-arma3"
$RELEASES_URL = "https://github.com/$REPO/releases"
$WORKSHOP_URL = "https://steamcommunity.com/sharedfiles/filedetails/?id=3782798344"
$OPENTRACK_URL = "https://github.com/opentrack/opentrack/releases/latest"
# Fallback for no-network ONLY - the normal path resolves the newest
# build.
$PINNED_TAG   = "v1.13.1-alpha.1"
$PINNED_URL   = "https://github.com/$REPO/releases/download/$PINNED_TAG/A3VR-Hybrid-$($PINNED_TAG.TrimStart('v')).zip"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Arma 3 VR - Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  An OpenXR bridge for 64-bit Arma 3 - it presents the game in" -ForegroundColor White
Write-Host "  your headset, feeds head movement through Arma's own FreeTrack" -ForegroundColor White
Write-Host "  path and maps VR controllers to native Arma controls. No VorpX." -ForegroundColor White
Write-Host ""
Write-Host "  This is an early community alpha and NOT native VR:" -ForegroundColor Yellow
Write-Host "   - Comfort-mono - both eyes get the SAME image, so there is no" -ForegroundColor White
Write-Host "     true stereo depth yet." -ForegroundColor White
Write-Host "   - Moderate black borders are intentional, for clarity." -ForegroundColor White
Write-Host "   - Vehicles, Zeus, scopes and the VR cursor are experimental." -ForegroundColor White
Write-Host "   - Keep keyboard and mouse within reach: Arma has many" -ForegroundColor White
Write-Host "     contextual commands with no VR binding yet." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Pick the route ----------------------------------------
Write-Step 1 4 "How do you want to install it"
Write-Host ""
Write-Host "    [1] From GitHub  (this installer does it)" -ForegroundColor Green
Write-Host "        Places $MOD_DIR_NAME beside your game. The Hub can then" -ForegroundColor Gray
Write-Host "        tell you when a newer alpha appears." -ForegroundColor Gray
Write-Host ""
Write-Host "    [2] From the Steam Workshop  (Steam keeps it updated)" -ForegroundColor White
Write-Host "        Nothing is installed here - the page opens and you" -ForegroundColor Gray
Write-Host "        subscribe. Steam handles updates from then on." -ForegroundColor Gray
Write-Host ""
Write-Host "  Both give you the same mod. Do NOT use both at once." -ForegroundColor Yellow
Write-Host ""
$route = ""
while ($route -ne "1" -and $route -ne "2") {
    $route = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
    if ($route -eq "") { $route = "1" }
    if ($route -ne "1" -and $route -ne "2") { Write-Warn "Please type 1 or 2." }
}

function Show-QuickStart {
    Write-Host ""
    Write-Line
    Write-Host " QUICK START - none of this is automatic" -ForegroundColor Cyan
    Write-Line
    Write-Host "  1. Start the headset and activate the OpenXR runtime you" -ForegroundColor White
    Write-Host "     intend to use." -ForegroundColor White
    if ($dest) {
        Write-Host "  2. In the official Arma 3 Launcher, open MODS and click the" -ForegroundColor White
        Write-Host "     + Local mod button, then pick this folder:" -ForegroundColor White
        Write-Host "       $dest " -ForegroundColor Black -BackgroundColor Yellow
        Write-Host "     THE LAUNCHER DOES NOT FIND MOD FOLDERS BY ITSELF - it" -ForegroundColor Yellow
        Write-Host "     has to be added once. Dragging the folder onto the MODS" -ForegroundColor White
        Write-Host "     page does the same thing." -ForegroundColor White
        Write-Host "  3. Now enable 'A3VR - Arma 3 Hybrid VR' in that list." -ForegroundColor White
        Write-Host "     Enable ONLY this one - never two A3VR variants." -ForegroundColor White
    } else {
        Write-Host "  2. In the official Arma 3 Launcher, enable" -ForegroundColor White
        Write-Host "     'A3VR - Arma 3 Hybrid VR' - Steam registers Workshop" -ForegroundColor White
        Write-Host "     mods with the Launcher by itself." -ForegroundColor White
        Write-Host "     Enable ONLY this one - never two A3VR variants." -ForegroundColor White
    }
    Write-Host "  4. Disable BattlEye. The bridge is unsigned, so protected" -ForegroundColor White
    Write-Host "     multiplayer is out." -ForegroundColor White
    Write-Host "  5. In Arma's controller/device settings, enable FreeTrack" -ForegroundColor White
    Write-Host "     when it is listed - WITHOUT IT THERE IS NO HEAD TRACKING." -ForegroundColor White
    Write-Host "  6. Start the game. Press F8 once to recenter." -ForegroundColor White
    Write-Host "  7. If the right controller does not move your aim, press F9." -ForegroundColor White
    Write-Host ""
    Write-Host "  NO FreeTrack ENTRY IN ARMA'S CONTROLLER SETTINGS AT ALL?" -ForegroundColor Yellow
    Write-Host "  Then Windows is missing the FreeTrack registry keys. Arma" -ForegroundColor White
    Write-Host "  only shows the device when they exist, and a PC that has" -ForegroundColor White
    Write-Host "  never run head tracking does not have them." -ForegroundColor White
    Write-Host "  This installer can fix that - it is the last step." -ForegroundColor White
    Write-Host ""
    Write-Host "  Tested by the author on Quest over Air Link with the Meta" -ForegroundColor Gray
    Write-Host "  OpenXR runtime. VDXR is reported to work. Virtual Desktop" -ForegroundColor Gray
    Write-Host "  through SteamVR, native SteamVR headsets and Pimax are NOT" -ForegroundColor Gray
    Write-Host "  validated yet." -ForegroundColor Gray
    Write-Host ""
}

if ($route -eq "2") {
    Write-Step 2 4 "Opening the Steam Workshop page"
    Write-Host ""
    Write-Host "  Subscribe there, then enable the mod in the official Arma 3" -ForegroundColor White
    Write-Host "  Launcher. Steam keeps it up to date - this installer will" -ForegroundColor White
    Write-Host "  not place any files." -ForegroundColor White
    Write-Host ""
    Pause-User "Press Enter to open the Workshop page..." | Out-Null
    try { Start-Process $WORKSHOP_URL } catch { Write-Warn "Open it manually: $WORKSHOP_URL" }
    Write-Step 3 4 "One more thing the Workshop does NOT do"
    Write-Host ""
    Write-Host "  Subscribing does not apply the mod's FOV and graphics" -ForegroundColor White
    Write-Host "  profile. With Arma CLOSED, run START_A3VR_LAUNCHER.cmd once" -ForegroundColor White
    Write-Host "  from the mod folder to apply it - it backs up your Arma" -ForegroundColor White
    Write-Host "  profile first. Without it the image looks zoomed in." -ForegroundColor White
    Write-Host ""
    Write-Step 4 4 "Done"
    Show-QuickStart
    Write-Host "  Someone already took the high ground. It is always the sniper." -ForegroundColor Magenta
    Write-Host ""
    Pause-User "Press Enter to exit."
    return
}

# ---- 2. Locate the game ---------------------------------------
Write-Step 2 4 "Locating $GAME_NAME"
$gamePath = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Arma 3") -ProbeExe $GAME_EXE
if (-not $gamePath) {
    Write-Warn "Could not find $GAME_NAME automatically."
    Write-Host "  Point me at the folder that holds $GAME_EXE, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\Arma 3" -ForegroundColor Gray
    $gamePath = Read-FolderPath -Prompt "  Game folder"
}
if (-not $gamePath -or -not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE))) {
    Write-Fail "No $GAME_EXE in that folder - stopping here rather than guessing."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gamePath"

# Probe write access quietly - the announcement comes only where it
# applies.
$needsAdmin = $false
try {
    $probe = Join-Path $gamePath ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }

# ---- 3. Fetch and unpack --------------------------------------
Write-Step 3 4 "Downloading $MOD_NAME"

$dlUrl = $PINNED_URL; $relTag = $PINNED_TAG
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
    foreach ($r in @($rel)) {
        if ($r.draft) { continue }
        # Skip source and patch releases (see InstallerSafety).
        if (-not (Test-IsPayloadRelease -Release $r)) { continue }
        $pick = Select-PayloadAsset -Assets $r.assets -PlatformPattern '(?i)A3VR' -MinBytes 50000
        if ($pick -and $pick.browser_download_url) {
            $dlUrl = [string]$pick.browser_download_url
            $relTag = [string]$r.tag_name
            break
        }
    }
    Write-OK "Release: $relTag"
} catch {
    Write-Warn "GitHub could not be reached - falling back to the pinned $PINNED_TAG."
}

$tmp = Join-Path $env:TEMP ("a3vr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "A3VR-Hybrid.zip"
Invoke-SafeDownload -Urls @($dlUrl, $PINNED_URL) -Destination $zip -Label "$MOD_NAME $relTag" `
    -ManualUrl $RELEASES_URL `
    -Instructions "Download the A3VR-Hybrid ZIP from the releases page, save it as '$zip', then choose Retry."
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No archive - nothing was changed."
    Pause-User "Press Enter to exit."
    exit 1
}

$ex = Join-Path $tmp "x"
New-Item -ItemType Directory -Path $ex -Force | Out-Null
[void](Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ex -Label $MOD_NAME)

# THE WRAPPER FOLDER IS THE PAYLOAD. The official Arma launcher looks
# for exactly the name @A3VR_Hybrid - so the FOLDER is copied, not its
# contents.
$srcDir = Get-ChildItem -LiteralPath $ex -Recurse -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -ieq $MOD_DIR_NAME } | Select-Object -First 1
if (-not $srcDir) {
    Write-Fail "No $MOD_DIR_NAME folder inside the archive - stopping."
    Write-Host "  Extract it by hand into $gamePath so that" -ForegroundColor White
    Write-Host "  $gamePath\$MOD_DIR_NAME\ exists." -ForegroundColor White
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

if ($needsAdmin) {
    Pause-User "Press Enter to copy the mod into the game folder - UAC required..." | Out-Null
}
$dest = Join-Path $gamePath $MOD_DIR_NAME
$copyFailed = $false
try {
    Copy-Item -LiteralPath $srcDir.FullName -Destination $gamePath -Recurse -Force -ErrorAction Stop
} catch { $copyFailed = $true }
if ($copyFailed) {
    Write-Warn "Copying needs administrator rights. Asking for them ..."
    $ps = "Copy-Item -LiteralPath '$($srcDir.FullName)' -Destination '$gamePath' -Recurse -Force"
    try { Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop }
    catch { Write-Warn "The elevated copy was declined or failed." }
}

if (Test-Path -LiteralPath (Join-Path $gamePath $MOD_PROBE)) {
    Write-OK "$MOD_DIR_NAME is in place."
} else {
    Write-Fail "$MOD_PROBE is not there - the install did not complete."
    Write-Host "  Extract the archive by hand so that this exists:" -ForegroundColor White
    Write-Host "     $gamePath\$MOD_PROBE" -ForegroundColor Yellow
}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Marker for the Hub - into the INSTALLER folder, not the game folder.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force } catch {}

# ---- 4. What the installer CANNOT do --------------------------
Write-Step 4 4 "The parts you have to do yourself"
Write-Host ""
Write-Host "  The FOV and graphics profile is NOT applied by copying files." -ForegroundColor White
Write-Host "  With Arma CLOSED, run this once from the mod folder:" -ForegroundColor White
Write-Host "     $dest\START_A3VR_LAUNCHER.cmd " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  It backs up your Arma profile before changing anything." -ForegroundColor Gray
Write-Host "  Without it the image looks zoomed in." -ForegroundColor Gray
Show-QuickStart

# ---- The FreeTrack registry entry in Windows ------------------
# DOCUMENTED FROM THE AUTHOR'S DISCORD: Arma only shows FreeTrack in
# its device settings when the FreeTrack registry keys (NPClient.dll)
# exist. A machine that never ran head tracking does not have them -
# the entry is then missing and there is no head tracking, however
# often the mod is reinstalled. A tester hit exactly that; after
# installing OpenTrack the entry was there and it worked.
# The author checked: his mod does NOT need OpenTrack - only its
# registry keys.
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host "  ONE MORE THING - the FreeTrack entry in Windows" -ForegroundColor Cyan
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Have you ever used head tracking on this PC - TrackIR," -ForegroundColor White
Write-Host "  OpenTrack, AITrack or similar?" -ForegroundColor White
Write-Host "     Enter        yes, or I will check in Arma first" -ForegroundColor Gray
Write-Host "     N  + Enter   no, never" -ForegroundColor Gray
$ftAns = ""
try { $ftAns = (Read-Host "  Your answer").Trim().ToUpper() } catch {}
if ($ftAns -eq "N") {
    Write-Host ""
    Write-Host "  Then Arma will most likely show NO FreeTrack device, and" -ForegroundColor White
    Write-Host "  without it there is no head tracking at all." -ForegroundColor White
    Write-Host ""
    Write-Host "  Install OpenTrack, then run one real tracking session so" -ForegroundColor White
    Write-Host "  it creates the FreeTrack file and registration A3VR needs." -ForegroundColor White
    Write-Host "  OpenTrack itself is not needed while playing." -ForegroundColor White
    Write-Host ""
    if (Read-YesNo "  Fetch and install OpenTrack now?") {
        $otDir = Join-Path $env:TEMP ("opentrack_" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $otDir -Force | Out-Null
        $otExe = Join-Path $otDir "opentrack-setup.exe"
        $url = $null
        try {
            $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/opentrack/opentrack/releases/latest" `
                       -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
            foreach ($a in @($rel.assets)) {
                if ($a.name -match '(?i)win32-setup\.exe$') { $url = [string]$a.browser_download_url; break }
            }
        } catch {}
        if (-not $url) { $url = "https://github.com/opentrack/opentrack/releases/latest" }
        Invoke-SafeDownload -Urls @($url) -Destination $otExe -Label "OpenTrack" `
            -ManualUrl $OPENTRACK_URL `
            -Instructions "Download the win32-setup.exe from the OpenTrack releases page, save it as '$otExe', then choose Retry."
        if (Test-Path -LiteralPath $otExe) {
            Pause-User "Press Enter to install OpenTrack - UAC required..." | Out-Null
            try { Start-Process -FilePath $otExe -Wait -Verb RunAs -ErrorAction Stop; Write-OK "OpenTrack installed." }
            catch { Write-Warn "The install was declined or failed: $($_.Exception.Message)" }
            Write-Host ""
            Write-Host "  Now open OpenTrack once. Under Input, select either" -ForegroundColor White
            Write-Host "  'Oculus Rift Runtime' or 'SteamVR' - whichever matches" -ForegroundColor White
            Write-Host "  your setup. Put on the headset, click Start, and let" -ForegroundColor White
            Write-Host "  tracking run for a few seconds." -ForegroundColor White
            Write-Host "  This should create the required FreeTrack file and" -ForegroundColor White
            Write-Host "  registration. You can then stop and close OpenTrack; it" -ForegroundColor White
            Write-Host "  is not needed while playing. FreeTrack should now appear" -ForegroundColor White
            Write-Host "  in Arma's controller settings, where you can enable it." -ForegroundColor White
        }
        try { Remove-Item -LiteralPath $otDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    } else {
        Write-Info "Skipped. If FreeTrack is missing in Arma, this is the reason."
        Write-Host "     $OPENTRACK_URL" -ForegroundColor Cyan
    }
}
Write-Host ""
Write-Host "  Someone already took the high ground. It is always the sniper." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
