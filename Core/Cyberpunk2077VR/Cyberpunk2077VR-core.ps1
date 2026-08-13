# ============================================================
# Cyberpunk 2077 VR Installer
# ============================================================
# Installs CyberpunkVRPort (dariulone) - an OpenXR VR mod. Since 0.1.0 it
# is a RED4ext PLUGIN, not a dxgi.dll proxy any more
# for Cyberpunk 2077 with 6-DoF motion-controlled VR hands (full-arm
# VRIK) and an in-headset F10 overlay. This is an IN-PLACE mod: it
# overlays files into the existing Steam/GOG Cyberpunk 2077 folder
# (bin\x64\... and red4ext\...). The full hands/HUD experience also
# needs two frameworks - RED4ext and Cyber Engine Tweaks (CET) - which
# this installer adds if they are not already present. Nothing is ever
# bundled; every component is downloaded at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Cyberpunk 2077 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME     = "CyberpunkVRPort v0.1.1"
$MOD_AUTHOR   = "dariulone"
$INFO_URL     = "https://github.com/dariulone/cyberpunk-vr-port"
$MOD_URL      = "https://github.com/dariulone/cyberpunk-vr-port/releases/download/0.1.1/CyberpunkVRPort-0.1.1.zip"
# Tag of the pinned fallback build above - recorded as the installed
# version when the live GitHub lookup can't be reached. Must match the
# release tag_name the Hub sees via /releases/latest (no leading "v").
$MOD_PINNED_TAG = "0.1.1"
$MOD_RELEASES = "https://github.com/dariulone/cyberpunk-vr-port/releases"
# Frameworks needed for the motion-controlled hands + VR HUD. Pinned to
# versions known to work with this mod build; only installed if missing.
$RED4EXT_URL  = "https://github.com/wopss/RED4ext/releases/download/v1.30.0/red4ext-1.30.0.zip"
$RED4EXT_REL  = "https://github.com/wopss/RED4ext/releases"
$CET_URL      = "https://github.com/maximegmd/CyberEngineTweaks/releases/download/v1.37.1/cet_1.37.1.zip"
$CET_REL      = "https://github.com/maximegmd/CyberEngineTweaks/releases"

# The four frameworks CyberpunkVRPort 0.1.x additionally requires (its own
# INSTALL.txt lists them next to RED4ext and CET). All four are plain
# drop-into-the-game-root archives - layouts read from the real downloads.
#   Tag       : resolved live from the /releases/latest REDIRECT - no API,
#               so the 60-calls-per-hour limit cannot break this.
#   UrlPattern: how that release names its Windows asset. {v} = tag without
#               a leading "v", {tag} = tag as-is. Verified against the
#               current release of each project.
#   Pinned    : last-known-good URL, used if the pattern ever misses.
#   Marker    : the file that proves it is installed.
$FRAMEWORKS = @(
    @{ Name = "redscript"; Repo = "jac3km4/redscript"
       UrlPattern = "https://github.com/jac3km4/redscript/releases/download/{tag}/redscript-{tag}-windows.zip"
       Pinned = "https://github.com/jac3km4/redscript/releases/download/v0.5.31/redscript-v0.5.31-windows.zip"
       Marker = "engine\tools\scc.exe" },
    @{ Name = "TweakXL"; Repo = "psiberx/cp2077-tweak-xl"
       UrlPattern = "https://github.com/psiberx/cp2077-tweak-xl/releases/download/{tag}/TweakXL-{v}.zip"
       Pinned = "https://github.com/psiberx/cp2077-tweak-xl/releases/download/v1.11.4/TweakXL-1.11.4.zip"
       Marker = "red4ext\plugins\TweakXL\TweakXL.dll" },
    @{ Name = "ArchiveXL"; Repo = "psiberx/cp2077-archive-xl"
       UrlPattern = "https://github.com/psiberx/cp2077-archive-xl/releases/download/{tag}/ArchiveXL-{v}.zip"
       Pinned = "https://github.com/psiberx/cp2077-archive-xl/releases/download/v1.27.1/ArchiveXL-1.27.1.zip"
       Marker = "red4ext\plugins\ArchiveXL\ArchiveXL.dll" },
    @{ Name = "Codeware"; Repo = "psiberx/cp2077-codeware"
       UrlPattern = "https://github.com/psiberx/cp2077-codeware/releases/download/{tag}/Codeware-{v}.zip"
       Pinned = "https://github.com/psiberx/cp2077-codeware/releases/download/v1.20.3/Codeware-1.20.3.zip"
       Marker = "red4ext\plugins\Codeware\Codeware.dll" }
)
$STEAM_FOLDER = "Cyberpunk 2077"
$CP_APPID     = "1091500"
$GAME_EXE_REL = "bin\x64\Cyberpunk2077.exe"
# Since 0.1.0 the mod loads through RED4ext instead of proxying dxgi.dll.
# This file is what proves the VR mod is installed.
$MOD_MARKER   = "red4ext\plugins\CyberpunkVR_Stereo\CyberpunkVR_Stereo.dll"
# A leftover dxgi.dll from an older CyberpunkVRPort or from R.E.A.L. VR must
# go: the mod's own INSTALL.txt says two VR paths fight over the same hooks.
$OLD_PROXY    = "bin\x64\dxgi.dll"
$RED4EXT_MARK = "red4ext\RED4ext.dll"
$CET_MARK     = "bin\x64\plugins\cyber_engine_tweaks.asi"
$GOG_ROOTS = @(
    "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
    "HKLM:\SOFTWARE\GOG.com\Games"
)

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Cyberpunk 2077 VR Installer" -ForegroundColor Yellow
    Write-Host "  Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }; return $null
}
function Get-SteamLibraries {
    param($sp); $libs=@($sp)
    $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
    if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
    return $libs
}
# A valid Cyberpunk 2077 root is the folder that contains bin\x64\Cyberpunk2077.exe.
function Test-CP2077Root {
    param([string]$Root)
    if (-not $Root) { return $false }
    return (Test-Path (Join-Path $Root $GAME_EXE_REL))
}
# Merge-copy every file under $Src into $Dst, preserving the relative
# folder layout (creating folders as needed, overwriting existing files).
function Copy-Tree {
    param([string]$Src, [string]$Dst)
    $base = (Resolve-Path $Src).Path.TrimEnd('\')
    Get-ChildItem -Path $base -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length).TrimStart('\')
        $target = Join-Path $Dst $rel
        $tdir = Split-Path $target -Parent
        if ($tdir -and -not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
        Copy-Item -Path $_.FullName -Destination $target -Force
    }
}

# Resolve the latest CyberpunkVRPort release straight from GitHub so each
# install pulls the newest build (the mod updates often). Uses the same
# endpoint the Hub's update check uses (/releases/latest) so the recorded
# version and the Hub's "Update" detection always agree. Returns
# @{ Url; Tag } or $null on any failure (rate limit, offline, no asset) -
# the caller then falls back to the pinned known-good build.
function Resolve-LatestModUrl {
    try {
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub"; "Accept" = "application/vnd.github+json" }
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/dariulone/cyberpunk-vr-port/releases/latest" -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        if (-not $rel) { return $null }
        $asset = $rel.assets | Where-Object { $_.name -match '(?i)^CyberpunkVRPort.*\.zip$' } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1 }
        if ($asset -and $asset.browser_download_url) {
            return @{ Url = $asset.browser_download_url; Tag = $rel.tag_name }
        }
    } catch {}
    return $null
}

# -------------------------------------------------------
# Resolve the live release version up front, so the header line and the
# final summary both show the exact build being installed (not the pinned
# fallback). The result is re-used in STEP 3 - only one GitHub call. The
# notice below is transient: Write-Header clears the screen right after.
# -------------------------------------------------------
Write-Host "  Checking latest CyberpunkVRPort version..." -ForegroundColor DarkGray
$latest = Resolve-LatestModUrl
$installedTag = $MOD_PINNED_TAG
if ($latest -and $latest.Tag) { $installedTag = $latest.Tag }
$MOD_NAME = "CyberpunkVRPort v$installedTag"

# -------------------------------------------------------
# STEP 1: Locate Cyberpunk 2077
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Locating Cyberpunk 2077"

$gameRoot = $null

$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found via Steam: $gameRoot"; break }
    }
}

if (-not $gameRoot) { $gameRoot = Find-SteamGameFolder -AppId "1091500" -SteamFolderNames @("Cyberpunk 2077") -GogNames @("Cyberpunk 2077") -EpicNames @("Cyberpunk 2077") }
if (-not $gameRoot) {
    foreach ($reg in $GOG_ROOTS) {
        try {
            Get-ChildItem -Path $reg -ErrorAction Stop | ForEach-Object {
                if ($gameRoot) { return }
                try {
                    $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
                    if ($gogPath -and (Test-CP2077Root $gogPath)) { $gameRoot = $gogPath; Write-Info "Found via GOG: $gameRoot" }
                } catch {}
            }
        } catch {}
        if ($gameRoot) { break }
    }
    # Common GOG default if the registry scan missed it.
    if (-not $gameRoot) {
        $gogDefault = "C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077"
        if (Test-CP2077Root $gogDefault) { $gameRoot = $gogDefault; Write-Info "Found via GOG default path: $gameRoot" }
    }
}

if (-not $gameRoot) {
    Write-Warn "Cyberpunk 2077 was not found automatically."
    Write-Host "  You need Cyberpunk 2077 installed (Steam or GOG)." -ForegroundColor White
    Write-Host "  Steam store / install:  https://store.steampowered.com/app/$CP_APPID/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the game folder manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$CP_APPID" } catch { try { Start-Process "https://store.steampowered.com/app/$CP_APPID/" } catch {} }
        Pause-User "Install Cyberpunk 2077, then press Enter to continue..."
        if ($steamPath) {
            foreach ($lib in (Get-SteamLibraries $steamPath)) {
                $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
                if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found: $gameRoot"; break }
            }
        }
    }
    while (-not $gameRoot) {
        Write-Host "  Enter the Cyberpunk 2077 folder (the one that holds bin\x64\Cyberpunk2077.exe):" -ForegroundColor White
        Write-Host "    Steam: C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077" -ForegroundColor Gray
        Write-Host "    GOG:   C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077" -ForegroundColor Gray
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-CP2077Root $r) { $gameRoot = $r; Write-Info "Path set: $gameRoot" }
        else { Write-Fail "Cyberpunk2077.exe not found under bin\x64 at: $r" }
    }
}

$tempDir = Join-Path $env:TEMP "CP2077VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download a zip (with mirrors + manual fallback) and overlay it into the
# game folder. Returns $true on success.
function Install-Component {
    param([string]$Label, [string[]]$Urls, [string]$ManualUrl, [string]$ManualName, [string]$PayloadRelFile = "")
    $tmpZip = Join-Path $tempDir ("dl_" + [System.IO.Path]::GetRandomFileName() + ".zip")
    $null = Invoke-SafeDownload -Urls $Urls -Destination $tmpZip -Label $Label `
                -ManualUrl $ManualUrl `
                -Instructions "Download $ManualName from the page that opened and drop it into the opened folder, then choose Retry." `
                -SkipMessage "Skipped - $Label was NOT installed."
    if (-not (Test-Path $tmpZip)) { return $false }
    $exDir = Join-Path $tempDir ("ex_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $exDir -Force | Out-Null
    $res = Expand-ArchiveOrFallback -ArchivePath $tmpZip -DestinationFolder $exDir -Label $Label `
               -SkipMessage "Skipped - $Label was NOT extracted."
    if ([string]$res -eq "quit") { return $false }
    # Layout-change-proof: locate the real payload level (a mod ZIP may
    # wrap everything in a top-level folder, e.g. CyberpunkVRPort-0.0.9\),
    # preferring the known mod file's relative path when provided.
    $payloadRoot = Get-ExtractedPayloadRoot -ExtractDir $exDir -RelModFile $PayloadRelFile -Markers @("bin","red4ext","r6","archive","engine","mods")
    try { Copy-Tree -Src $payloadRoot -Dst $gameRoot } catch { Write-Fail "Copy failed: $($_.Exception.Message)"; return $false }
    return $true
}

# -------------------------------------------------------
# STEP 2: Frameworks (RED4ext + CET) - only if missing
# -------------------------------------------------------
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameRoot -RelModFile $MOD_MARKER -Label "CyberpunkVRPort"
Write-Step 2 4 "Frameworks (RED4ext + Cyber Engine Tweaks)"
Write-Host "  These power the motion-controlled hands and the VR HUD." -ForegroundColor Gray
Write-Host "  Installed only if you don't already have them." -ForegroundColor Gray
Write-Host ""

$red4extState = "present"
if (Test-Path (Join-Path $gameRoot $RED4EXT_MARK)) {
    Write-OK "RED4ext already present - keeping your install."
} else {
    Write-Host "  Installing RED4ext (v1.30.0) ..." -ForegroundColor White
    if (Install-Component -Label "RED4ext" -Urls @($RED4EXT_URL) -ManualUrl $RED4EXT_REL -ManualName "red4ext-1.30.0.zip") {
        Write-OK "RED4ext installed."; $red4extState = "installed"
    } else { Write-Warn "RED4ext was not installed - VR hands/HUD may not load (camera/stereo will still work)."; $red4extState = "missing" }
}

$cetState = "present"
if (Test-Path (Join-Path $gameRoot $CET_MARK)) {
    Write-OK "Cyber Engine Tweaks already present - keeping your install."
} else {
    Write-Host "  Installing Cyber Engine Tweaks (v1.37.1) ..." -ForegroundColor White
    if (Install-Component -Label "Cyber Engine Tweaks" -Urls @($CET_URL) -ManualUrl $CET_REL -ManualName "cet_1.37.1.zip") {
        Write-OK "Cyber Engine Tweaks installed."; $cetState = "installed"
    } else { Write-Warn "CET was not installed - VR hands/HUD may not load (camera/stereo will still work)."; $cetState = "missing" }
}

# The four frameworks the mod additionally needs since 0.1.x. Each is only
# fetched when its marker file is missing, so a machine that already has a
# modded Cyberpunk downloads nothing here.
#
# The tag comes from the /releases/latest REDIRECT, not from the GitHub API:
# the redirect has no hourly limit, so a busy API cannot leave the user with
# a half-installed setup. The pinned URL stays behind it as a fallback, and
# behind that the normal manual route of Install-Component.
function Get-LatestTagByRedirect {
    param([string]$Repo)
    try {
        $url = "https://github.com/$Repo/releases/latest"
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.Method = "HEAD"
        $req.AllowAutoRedirect = $false
        $req.UserAgent = "PCVR-Mods-Hub"
        $req.Timeout = 15000
        $resp = $req.GetResponse()
        $loc  = $resp.Headers["Location"]
        $resp.Close()
        if ($loc -and $loc -match '/tag/(.+)$') { return $Matches[1] }
    } catch { }
    return $null
}

$fwStates = @{}
foreach ($fw in $FRAMEWORKS) {
    if (Test-Path (Join-Path $gameRoot $fw.Marker)) {
        Write-OK "$($fw.Name) already present - keeping your install."
        $fwStates[$fw.Name] = "present"
        continue
    }
    $urls = @()
    $tag  = Get-LatestTagByRedirect -Repo $fw.Repo
    if ($tag) {
        $ver = $tag.TrimStart("v")
        $urls += ($fw.UrlPattern -replace '\{tag\}', $tag -replace '\{v\}', $ver)
        Write-Host "  Installing $($fw.Name) ($tag) ..." -ForegroundColor White
    } else {
        Write-Host "  Installing $($fw.Name) (known build - GitHub not reachable) ..." -ForegroundColor White
    }
    if ($urls -notcontains $fw.Pinned) { $urls += $fw.Pinned }
    if (Install-Component -Label $fw.Name -Urls $urls -ManualUrl "https://github.com/$($fw.Repo)/releases" -ManualName "the latest $($fw.Name) .zip") {
        Write-OK "$($fw.Name) installed."
        $fwStates[$fw.Name] = "installed"
    } else {
        Write-Warn "$($fw.Name) was not installed - the VR mod's scripts will not load without it."
        $fwStates[$fw.Name] = "missing"
    }
}

# -------------------------------------------------------
# STEP 3: CyberpunkVRPort (the VR mod itself) - latest release
# -------------------------------------------------------
Write-Host " CyberpunkVRPort by dariulone - an OpenXR VR proxy for Cyberpunk 2077" -ForegroundColor White
Write-Host " with 6DoF motion-controlled VR hands (full-arm VRIK) and head tracking." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start the installation..."

Write-Step 3 4 "Installing CyberpunkVRPort (latest release)"

# A dxgi.dll in bin\x64 is either an OLD CyberpunkVRPort (pre-0.1.0, when the
# mod still proxied dxgi) or R.E.A.L. VR. Either way it hooks the same engine
# entry points as the new plugin, and the mod's own INSTALL.txt says the two
# fight over them. Move it aside instead of deleting - it is not our file.
$oldProxyPath = Join-Path $gameRoot $OLD_PROXY
if (Test-Path -LiteralPath $oldProxyPath) {
    Write-Warn "An old dxgi.dll VR proxy is in bin\x64 - it clashes with the new plugin."
    $stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $parked = "$oldProxyPath.disabled-$stamp"
    try {
        Move-Item -LiteralPath $oldProxyPath -Destination $parked -Force -ErrorAction Stop
        Write-OK "Moved aside: dxgi.dll.disabled-$stamp (rename it back to undo)"
    } catch {
        Write-Fail "Could not move it: $($_.Exception.Message)"
        Write-Host "    Move bin\x64\dxgi.dll out of the folder yourself, then run this again." -ForegroundColor Yellow
        Pause-User "Press Enter to continue anyway..."
    }
}

Write-Info "Checking GitHub for the latest CyberpunkVRPort release..."
# $latest / $installedTag were already resolved up front (for the header
# line); re-use them here so there is only one GitHub call per run.
$modUrls = @()
if ($latest -and $latest.Url) {
    Write-OK "Latest release: $installedTag"
    $modUrls += $latest.Url
} else {
    Write-Warn "Could not query GitHub (rate limit or offline) - using the known build $MOD_PINNED_TAG."
}
# Always keep the known-good pinned build as a fallback behind the latest.
if ($modUrls -notcontains $MOD_URL) { $modUrls += $MOD_URL }

$modOk = Install-Component -Label "CyberpunkVRPort $installedTag" -Urls $modUrls -ManualUrl $MOD_RELEASES -ManualName "the latest CyberpunkVRPort .zip" -PayloadRelFile $MOD_MARKER
if ($modOk) {
    Write-OK "CyberpunkVRPort $installedTag installed into the game folder."
    # Record the installed release tag so the Hub can flip the card to
    # "Update" when GitHub publishes a newer release (same scheme as the
    # other GitHub-tracked mods). File lives next to this installer.
    try {
        [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_version"), $installedTag, (New-Object System.Text.UTF8Encoding $false))
    } catch {}
} else {
    if (Test-Path (Join-Path $gameRoot $MOD_MARKER)) {
        Write-Warn "Could not (re)install the VR mod, but a previous install is still present."
    } else {
        Write-Fail "The VR mod was not installed. Aborting."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 3b: the four mods the author recommends on top
# -------------------------------------------------------
# These live on Nexus, so the Hub cannot fetch them - Nexus needs a login and
# hands out no direct links. The installer therefore does the part it can:
# open the right page, wait, and take the ZIP either from the Downloads
# folder or dropped onto the window. Each one is skippable with Enter, and
# anything already installed is not offered at all.
$EXTRA_MODS = @(
    @{ Name = "Visible Bullets"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/22251?tab=files"
       Marker = "archive\pc\mod\Velocity.archive"; What = "projectiles you can actually see in flight" },
    @{ Name = "Visual Holsters"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/21936?tab=files"
       Marker = "bin\x64\plugins\cyber_engine_tweaks\mods\VisualHolster"; What = "the visible holster the hand-to-holster grip reaches for" },
    @{ Name = "Equipment-EX"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/6945?tab=files"
       Marker = "archive\pc\mod\EquipmentEx.archive"; What = "extra equipment slots" },
    @{ Name = "Nova Optics"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/29190?tab=files"
       Marker = "r6\scripts\NovaOptics\NovaOptics.reds"; What = "reworked sights, which the collimated reflex shader draws into" }
)

$missingExtras = @($EXTRA_MODS | Where-Object { -not (Test-Path (Join-Path $gameRoot $_.Marker)) })
if ($missingExtras.Count -gt 0) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host " Recommended extra mods" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  The mod author recommends $($missingExtras.Count) more mods. They are on Nexus," -ForegroundColor Gray
    Write-Host "  so they cannot be downloaded automatically." -ForegroundColor Gray
    Write-Host "  For each one the page opens; download the file and drop it here." -ForegroundColor Gray
    Write-Host "  Press Enter alone to skip one." -ForegroundColor Gray

    foreach ($ex in $missingExtras) {
        Write-Host ""
        Write-Host "  $($ex.Name) - $($ex.What)" -ForegroundColor White
        Write-Host "   $($ex.Url) " -ForegroundColor Cyan
        $ans = Pause-User "Press Enter to open the page (or type s to skip this one)..."
        if ("$ans".Trim() -match '^(?i)s') { Write-Info "Skipped $($ex.Name)."; continue }
        try { Start-Process $ex.Url } catch { }

        # Downloads first: after a Nexus download the file is usually right
        # there, and picking it beats asking the user to find it.
        $zip = $null
        $dl  = Join-Path $env:USERPROFILE "Downloads"
        $key = ($ex.Name -replace '[^A-Za-z]', '')
        if (Test-Path -LiteralPath $dl) {
            $cand = Get-ChildItem -LiteralPath $dl -Filter "*.zip" -File -ErrorAction SilentlyContinue |
                    Where-Object { ($_.Name -replace '[^A-Za-z]', '') -match "(?i)$key" } |
                    Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($cand) {
                Write-OK "Found in Downloads: $($cand.Name)"
                $zip = $cand.FullName
            }
        }
        while (-not $zip) {
            $inp = (Read-Host "  Drag the $($ex.Name) .zip here and press Enter (or Enter alone to skip)").Trim().Trim('"')
            if (-not $inp) { break }
            if (Test-Path -LiteralPath $inp) { $zip = $inp } else { Write-Fail "Not found: $inp" }
        }
        if (-not $zip) { Write-Info "Skipped $($ex.Name)."; continue }

        $exDir = Join-Path $tempDir ("nx_" + [System.IO.Path]::GetRandomFileName())
        try {
            New-Item -ItemType Directory -Path $exDir -Force | Out-Null
            Expand-Archive -LiteralPath $zip -DestinationPath $exDir -Force -ErrorAction Stop
            # Same payload search as the frameworks: a Nexus ZIP may wrap
            # everything in one folder.
            $root = Get-ExtractedPayloadRoot -ExtractDir $exDir -RelModFile $ex.Marker -Markers @("bin","red4ext","r6","archive","engine","mods")
            Copy-Tree -Src $root -Dst $gameRoot
            if (Test-Path (Join-Path $gameRoot $ex.Marker)) { Write-OK "$($ex.Name) installed." }
            else { Write-Warn "$($ex.Name): files copied, but its main file is not where expected." }
        } catch {
            Write-Fail "$($ex.Name) could not be installed: $($_.Exception.Message)"
        }
    }
}

# -------------------------------------------------------
# STEP 4: Summary + first-launch notes
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

$modPresent = Test-Path (Join-Path $gameRoot $MOD_MARKER)

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($modPresent) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {} }

Write-Host "  Game folder: $gameRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
if ($modPresent) { Write-Host "  [x] $MOD_NAME (RED4ext plugin + VR hands)" -ForegroundColor Green }
else { Write-Host "  [ ] VR mod missing" -ForegroundColor Red }
switch ($red4extState) {
    "present"   { Write-Host "  [x] RED4ext (already installed)" -ForegroundColor Green }
    "installed" { Write-Host "  [x] RED4ext" -ForegroundColor Green }
    default     { Write-Host "  [ ] RED4ext - hands/HUD will not load until added" -ForegroundColor Yellow }
}
switch ($cetState) {
    "present"   { Write-Host "  [x] Cyber Engine Tweaks (already installed)" -ForegroundColor Green }
    "installed" { Write-Host "  [x] Cyber Engine Tweaks" -ForegroundColor Green }
    default     { Write-Host "  [ ] Cyber Engine Tweaks - hands/HUD will not load until added" -ForegroundColor Yellow }
}
foreach ($fw in $FRAMEWORKS) {
    switch ($fwStates[$fw.Name]) {
        "present"   { Write-Host "  [x] $($fw.Name) (already installed)" -ForegroundColor Green }
        "installed" { Write-Host "  [x] $($fw.Name)" -ForegroundColor Green }
        default     { Write-Host "  [ ] $($fw.Name) - the VR mod's scripts need it" -ForegroundColor Yellow }
    }
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Start your OpenXR runtime FIRST (Virtual Desktop / VDXR," -ForegroundColor White
Write-Host "     SteamVR, etc.) - before launching the game." -ForegroundColor White
Write-Host "  2. Launch Cyberpunk 2077 normally (Steam / GOG, or the Hub)." -ForegroundColor White
Write-Host "  3. In-game:  F10 or Insert = VR settings overlay,  F7 = recenter." -ForegroundColor White
Write-Host ""
Write-Host "  - Open the F10 overlay -> VRIK tab to start hand tracking and" -ForegroundColor Gray
Write-Host "    calibrate reach / height / elbow per hand." -ForegroundColor Gray
Write-Host "  - On the very first launch the mod swaps in its own tuned" -ForegroundColor Gray
Write-Host "    Cyberpunk settings and backs yours up next to the original." -ForegroundColor Gray
Write-Host "  - Log for bug reports: bin\x64\cyberpunkvrport.log" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue to the recommended settings..."
Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! RECOMMENDED SETTINGS - DO THIS OR PERFORMANCE MAY TANK !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Cyberpunk 2077 is VERY demanding in VR. On first launch the" -ForegroundColor White
Write-Host "  CyberpunkVRPort VR configuration window appears:" -ForegroundColor White
Write-Host ""
Write-Host "   - Resolution: do NOT go too high. 2560 x 2560 fits most setups." -ForegroundColor White
Write-Host "   - Leave the DEBUG tick-box OFF - it arms every diagnostic probe" -ForegroundColor White
Write-Host "     and costs frame time plus a very large log." -ForegroundColor White
Write-Host ""
Write-Host "  In-game graphics settings:" -ForegroundColor White
Write-Host "   - Quick Preset: Low  (Medium at most)" -ForegroundColor White
Write-Host "   - Resolution Scaling: Off" -ForegroundColor White
Write-Host "   - Turn OFF: Ray Tracing, Frame Generation, Film Grain," -ForegroundColor White
Write-Host "               Chromatic Aberration, Depth of Field, Lens Flare" -ForegroundColor White
Write-Host "   - Press Apply when done." -ForegroundColor White
Write-Host "   - Video: lower Gamma Correction a touch (it is a bit too bright)." -ForegroundColor White
Write-Host ""
Write-Host "  In the F10 VR menu (General, Controls, Stereo, VRIK, HUD):" -ForegroundColor White
Write-Host "   - VRIK tab: start hand tracking and calibrate reach, height," -ForegroundColor White
Write-Host "     elbow and wrist offset." -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Wake up, samurai. Night City won't burn itself down." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter once you've read the settings above to finish..."
try { Start-Process explorer.exe "`"$gameRoot\bin\x64`"" } catch {}
