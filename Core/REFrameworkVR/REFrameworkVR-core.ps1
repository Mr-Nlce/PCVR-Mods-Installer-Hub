# ============================================================
# REFramework VR - Shared Installer
# by praydog | https://github.com/praydog/REFramework
# ============================================================
#
# This installer works for ALL RE Engine games:
# DMC5, Monster Hunter Rise/Wilds/Stories 3,
# Street Fighter 6, Dragon's Dogma 2, Pragmata,
# Mega Man Star Force Legacy Collection,
# Ghosts 'n Goblins Resurrection,
# Apollo Justice: Ace Attorney Trilogy,
# Kunitsu-Gami, Onimusha 2
#
# Downloads the latest nightly REFramework.zip + VR.zip
# from GitHub and extracts both into the game folder.
# ============================================================

param(
 [string]$GameTitle = "",
 [string]$GameFolder = "",
 [string]$GameExe = ""
)


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "REFramework VR Installer"
$ErrorActionPreference = "Stop"

$GITHUB_API = "https://api.github.com/repos/praydog/REFramework-nightly/releases/latest"
$INFO_URL = "https://github.com/praydog/REFramework"

# --- Pragmata AFW (Alternate Frame Warping) performance variant --------
# Pragmata is extremely demanding in VR. PureDark's AFW plugin is a
# separate rendering method that can boost VR performance ~60-80% and
# fixes DLSS wobbling. It is a fixed release (NOT auto-updating like the
# praydog nightly), so choosing it means this game opts out of the
# nightly update flow until the user switches back. Only offered for
# Pragmata. The pack is two flat DLLs (PDAFWPlugin.dll + dinput8.dll)
# that extract straight into the game folder alongside REFramework.
$AFW_PAGE_URL = "https://github.com/PureDark/REFramework/releases/tag/PRAGMATA_AFW_v1.0-beta.1"
$AFW_ZIP_URL  = "https://github.com/PureDark/REFramework/releases/download/PRAGMATA_AFW_v1.0-beta.1/PRAGMATA_AFW_v1.0-beta.1.zip"
$AFW_ZIP_NAME = "PRAGMATA_AFW_v1.0-beta.1.zip"
$AFW_MARKER   = "PDAFWPlugin.dll"   # presence in game folder = AFW installed
$AFW_FILES    = @("PDAFWPlugin.dll", "dinput8.dll")  # what AFW adds

# Game definitions: Title, SteamFolder, EXE
$GAMES = @(
 @{ Title="Apollo Justice: Ace Attorney Trilogy"; Folders=@("Apollo Justice Ace Attorney Trilogy","ApolloJustice"); Exe="GS456.exe"; ExeFallbacks=@("ApolloJustice.exe"); Flavor="Take that! Object in VR. The truth is in the details." },
 @{ Title="Devil May Cry 5"; Folders=@("Devil May Cry 5","DevilMayCry5"); Exe="DevilMayCry5.exe"; Flavor="Stylish ranks await. SSS is just the beginning." },
 @{ Title="Dragon's Dogma 2"; Folders=@("Dragon's Dogma 2","DragonsDogma2"); Exe="DD2.exe"; Flavor="Pawns at your side. The Arisen rises again - this time in VR." },
 @{ Title="Ghosts 'n Goblins Resurrection"; Folders=@("Makaimura_GG_RE","Ghosts n Goblins Resurrection","GhostsnGoblinsResurrection","Ghosts 'n Goblins Resurrection"); Exe="makaimura_GG_RE.exe"; ExeFallbacks=@("GhostsnGoblinsResurrection.exe"); Flavor="Arthur's armor lasts two hits. VR will not save you." },
 @{ Title="Kunitsu-Gami: Path of the Goddess"; Folders=@("KUNITSU-GAMI","Kunitsu-Gami","KunitsuGami"); Exe="KunitsuGami.exe"; Flavor="Purify the mountain. Defend the Maiden. The Seethe creeps closer." },
 @{ Title="Mega Man Star Force Legacy Collection"; Folders=@("Mega Man Star Force Legacy Collection","MegaManStarForceLegacyCollection"); Exe="STARFORCE.exe"; Flavor="EM-Wave Change! Geo Stelar fuses with Omega-Xis - in VR." },
 @{ Title="Monster Hunter Rise"; Folders=@("MonsterHunterRise","Monster Hunter Rise"); Exe="MonsterHunterRise.exe"; Flavor="Wirebug to the skies. Magnamalo is watching." },
 @{ Title="Monster Hunter Stories 3"; Folders=@("MONSTER HUNTER STORIES 3","Monster Hunter Stories 3","MonsterHunterStories3"); Exe="MHSTORIES3.exe"; Flavor="Bond with monsters, ride them into battle." },
 @{ Title="Monster Hunter Wilds"; Folders=@("MonsterHunterWilds","Monster Hunter Wilds"); Exe="MonsterHunterWilds.exe"; Flavor="The Forbidden Lands open up. Hunt in VR." },
 @{ Title="Onimusha 2: Samurai's Destiny"; Folders=@("ONIMUSHA2","Onimusha 2","Onimusha2"); Exe="Onimusha2.exe"; Flavor="Sengoku-era demons. One Oni-blade. In your hands now." },
 @{ Title="Pragmata"; Folders=@("PRAGMATA","Pragmata"); Exe="Pragmata.exe"; Flavor="Lunar station, lost girl, hacked reality. Solve it in VR." },
 @{ Title="Street Fighter 6"; Folders=@("Street Fighter 6","StreetFighter6"); Exe="StreetFighter6.exe"; Flavor="Hadouken in 1:1 scale. Drive impact... incoming." }
)

function Write-Header { param($title)
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " REFramework VR Installer" -ForegroundColor Cyan
 Write-Host " $title" -ForegroundColor Gray
 Write-Host " by praydog | Auto-updates from GitHub nightly" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries { param($sp)
 $libs=@($sp); $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object {
 $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}

# -------------------------------------------------------
# STEP 1: Select game (if not passed as parameter)
# -------------------------------------------------------

if ($GameTitle -and $GameFolder -and $GameExe) {
 # Hub passes SteamFolder as GameFolder - also try no-spaces variant
 $altFolder = $GameFolder -replace ' ',''
 $folders = if ($altFolder -ne $GameFolder) { @($GameFolder, $altFolder) } else { @($GameFolder) }
 # Look up ExeFallbacks from the local GAMES table by title.
 # Hub-launched installs (where -GameExe is passed) would otherwise
 # bypass the fallback list since we'd build a fresh hashtable here.
 # Title match is case-insensitive and tolerant of small punctuation
 # variations (Ghosts 'n Goblins vs Ghosts n Goblins).
 $exeFallbacks = @()
 # Hub now passes titles with trailing " VR" suffix (e.g. "Devil May
 # Cry 5 VR"). The internal GAMES table uses original names, so strip
 # " VR" before computing the match key.
 $cleanGameTitle = $GameTitle -replace " VR$",""
 $titleKey = ($cleanGameTitle -replace "[^A-Za-z0-9]","").ToLower()
 $matchedFlavor = ""
 foreach ($g in $GAMES) {
 $gKey = ($g.Title -replace "[^A-Za-z0-9]","").ToLower()
 if ($gKey -eq $titleKey) {
 if ($g.ExeFallbacks) { $exeFallbacks = $g.ExeFallbacks }
 $matchedFlavor = $g.Flavor
 break
 }
 }
 $selectedGame = @{ Title=$cleanGameTitle; Folders=$folders; Exe=$GameExe; ExeFallbacks=$exeFallbacks; Flavor=$matchedFlavor }
} else {
 Write-Header "Select Game"
 Write-Host " Select the game to install REFramework VR for:" -ForegroundColor White
 Write-Host ""
 for ($i=0; $i -lt $GAMES.Count; $i++) {
 Write-Host " [$($i+1)] $($GAMES[$i].Title)" -ForegroundColor White
 }
 Write-Host ""
 $sel = ""
 while (-not ($sel -match "^\d+$") -or [int]$sel -lt 1 -or [int]$sel -gt $GAMES.Count) {
 $sel = (Read-Host " Choice (1-$($GAMES.Count))").Trim()
 }
 $selectedGame = $GAMES[[int]$sel - 1]
}

Write-Header $selectedGame.Title
Write-Host " REFramework VR by praydog adds generic 6DOF VR to RE Engine games." -ForegroundColor White
Write-Host " Played on a gamepad. Auto-updates from praydog's GitHub nightly." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 3 "Locating $($selectedGame.Title)"

$gamePath = $null
# Build the full list of executables to test: primary Exe first,
# then any ExeFallbacks (used for games where the binary name was
# renamed between releases - e.g. makaimura_GG_RE.exe replaces
# the old GhostsnGoblinsResurrection.exe). The found EXE is also
# stashed back into $selectedGame.Exe so downstream prompts ("game
# folder must contain X.exe") show whichever name we actually use.
$exeCandidates = @($selectedGame.Exe)
if ($selectedGame.ExeFallbacks) { $exeCandidates += $selectedGame.ExeFallbacks }
$sp = Get-SteamPath
if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 foreach ($folder in $selectedGame.Folders) {
 $c = Join-Path $lib "steamapps\common\$folder"
 foreach ($exe in $exeCandidates) {
 if (Test-Path (Join-Path $c $exe)) {
 $gamePath = $c
 $selectedGame.Exe = $exe
 Write-OK "Found: $gamePath"
 break
 }
 }
 if ($gamePath) { break }
 }
 if ($gamePath) { break }
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -SteamFolderNames $selectedGame.Folders -GogNames $selectedGame.Folders -EpicNames $selectedGame.Folders -ProbeExe $selectedGame.Exe }
if (-not $gamePath) {
 Write-Warn "$($selectedGame.Title) not found automatically."
 Write-Host " Enter the game folder (must contain $($selectedGame.Exe)):" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 $found = $false
 foreach ($exe in $exeCandidates) {
 if(Test-Path(Join-Path $r $exe)) {
 $gamePath = $r
 $selectedGame.Exe = $exe
 Write-OK "Path set: $gamePath"
 $found = $true
 break
 }
 }
 if (-not $found) { Write-Fail "$($selectedGame.Exe) not found: $r" }
 }
}

# Re-run = update: tell the user when the mod is already present.
if ($gamePath) { $null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile "openxr_loader.dll" -Label "REFramework VR" }

# -------------------------------------------------------
# Pragmata AFW variant selection
# -------------------------------------------------------
# Only Pragmata offers the AFW performance variant. $wantAFW decides
# whether we also lay down PureDark's AFW plugin after the base install;
# $removeAFW cleans an existing AFW install when switching back to the
# plain auto-updating nightly. For every other game these stay false.
$isPragmata = (($selectedGame.Title -replace "[^A-Za-z0-9]","").ToLower() -eq "pragmata")
$wantAFW   = $false
$removeAFW = $false
if ($isPragmata -and $gamePath) {
    $afwInstalled = Test-Path (Join-Path $gamePath $AFW_MARKER)
    Write-Header $selectedGame.Title
    Write-Host " Pragmata is extremely demanding in VR. You can install the" -ForegroundColor White
    Write-Host " standard REFramework VR mod, or a performance-focused variant" -ForegroundColor White
    Write-Host " that adds PureDark's AFW (Alternate Frame Warping) plugin." -ForegroundColor White
    Write-Host ""
    Write-Host " [1] Standard REFramework VR (by praydog)" -ForegroundColor Cyan
    Write-Host "     Auto-updates from the GitHub nightly. Recommended if the" -ForegroundColor Gray
    Write-Host "     game already runs well for you." -ForegroundColor Gray
    Write-Host ""
    Write-Host " [2] REFramework VR + AFW performance plugin (by PureDark)" -ForegroundColor Cyan
    Write-Host "     Adds AFW on top of REFramework: can boost VR performance" -ForegroundColor Gray
    Write-Host "     by roughly 60-80% and fixes DLSS wobbling. Uses ~500 MB" -ForegroundColor Gray
    Write-Host "     more VRAM. This is a fixed release, so while it's active" -ForegroundColor Gray
    Write-Host "     the game won't auto-update the nightly until you switch" -ForegroundColor Gray
    Write-Host "     back to [1]. Aim for 90 fps; turn off Hair Strands and" -ForegroundColor Gray
    Write-Host "     don't use Motion Smoothing/ASW/SSW (see the notes after" -ForegroundColor Gray
    Write-Host "     install)." -ForegroundColor Gray
    Write-Host ""
    if ($afwInstalled) {
        Write-Host " The AFW variant is currently installed here." -ForegroundColor Yellow
        Write-Host " Choosing [1] will remove the AFW plugin and return to the" -ForegroundColor Gray
        Write-Host " standard auto-updating nightly." -ForegroundColor Gray
        Write-Host ""
    }
    $afwSel = ""
    while (-not ($afwSel -match "^[12]$")) {
        $afwSel = (Read-Host " Choice (1-2)").Trim()
    }
    if ($afwSel -eq "2") {
        $wantAFW = $true
    } elseif ($afwInstalled) {
        # Chose standard while AFW is present -> switch back: remove AFW.
        $removeAFW = $true
    }
}

# -------------------------------------------------------
# Hub cache: REFramework.zip + VR.zip are saved under the Hub so the same
# nightly is not re-downloaded every install, and so there is an offline
# fallback. Both files share one nightly version (version.txt).
# -------------------------------------------------------
$REF_CACHE_DIR = Join-Path $PSScriptRoot "..\Assets\Tools\REFramework"
$REF_CACHE_REF = Join-Path $REF_CACHE_DIR "REFramework.zip"
$REF_CACHE_VR  = Join-Path $REF_CACHE_DIR "VR.zip"
$REF_CACHE_VER = Join-Path $REF_CACHE_DIR "version.txt"

# True only if the file really begins with the ZIP magic bytes "PK" - guards
# against a stray HTML error page being trusted as a cached/downloaded zip.
function Test-IsZip {
    param([string]$Path)
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try { $b = New-Object byte[] 2; $n = $fs.Read($b,0,2); return ($n -eq 2 -and $b[0] -eq 0x50 -and $b[1] -eq 0x4B) }
        finally { $fs.Close() }
    } catch { return $false }
}

# -------------------------------------------------------
# STEP 2: Get latest nightly URLs from GitHub API
# -------------------------------------------------------
Write-Step 2 3 "Fetching latest nightly from GitHub"

$refZipUrl = $null
$vrZipUrl = $null
$tagName = $null

# GitHub API call - try direct, then web archive mirror, then interactive fallback
$apiOk = $false
foreach ($apiSrc in @($GITHUB_API, "https://web.archive.org/web/0/$GITHUB_API")) {
  Write-Host " Querying GitHub API ($apiSrc) ... " -NoNewline -ForegroundColor White
  try {
    $apiResp = Invoke-WebRequest -Uri $apiSrc -UseBasicParsing -EA Stop `
                  -Headers @{ "User-Agent"="PCVR-Mods-Hub"; "Accept"="application/vnd.github+json" }
    $release = $apiResp.Content | ConvertFrom-Json
    $tagName = $release.tag_name
    foreach ($asset in $release.assets) {
      if ($asset.name -eq "REFramework.zip") { $refZipUrl = $asset.browser_download_url }
      if ($asset.name -eq "VR.zip") { $vrZipUrl = $asset.browser_download_url }
    }
    Write-Host "OK" -ForegroundColor Green
    Write-Info "Latest build: $tagName"
    if ($refZipUrl) { Write-Info "REFramework.zip found" } else { Write-Warn "REFramework.zip not in release assets" }
    if ($vrZipUrl) { Write-Info "VR.zip found" } else { Write-Warn "VR.zip not in release assets" }
    $apiOk = $true
    break
  } catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Warn "Source failed: $_"
  }
}

# Decide where the two zips come from: the Hub cache, a fresh download, or
# a manual drop. Read the saved cache state first.
$cacheValid = (Test-Path $REF_CACHE_REF) -and (Test-Path $REF_CACHE_VR) -and (Test-IsZip $REF_CACHE_REF) -and (Test-IsZip $REF_CACHE_VR)
$cachedVer  = ""
if (Test-Path $REF_CACHE_VER) { try { $cachedVer = (Get-Content $REF_CACHE_VER -Raw -EA Stop).Trim() } catch {} }

$useCache     = $false   # extract straight from the Hub cache (no download)
$refreshCache = $false   # after a fresh download, copy the zips into the cache

if ($apiOk -and $refZipUrl -and $vrZipUrl) {
  # Online check worked. Reuse the saved copy only if it is the SAME build;
  # otherwise download the new build and refresh the saved copy.
  if ($cacheValid -and $cachedVer -and ($cachedVer -eq $tagName)) {
    $useCache = $true
    Write-OK "Latest build $tagName is already saved in the Hub - no download needed."
  } else {
    $refreshCache = $true
    if ($cacheValid) { Write-Info "Newer build available ($tagName) - downloading and refreshing the saved copy." }
    else { Write-Info "Downloading build $tagName and saving it to the Hub for next time." }
  }
} elseif ($cacheValid) {
  # Online check failed (API down / assets missing) but a saved copy exists:
  # use it as the fallback instead of forcing a manual download.
  $useCache = $true
  $tagName  = if ($cachedVer) { $cachedVer } else { "cached" }
  Write-Warn "GitHub could not be reached - using the REFramework build saved in the Hub ($tagName)."
} else {
  # No saved copy and no online build: interactive manual fallback - point the
  # user at the releases page so they can drop the two zips into our folder.
  $tmpManual = Join-Path $env:TEMP "REFrameworkVR_manual"
  New-Item -ItemType Directory -Path $tmpManual -Force | Out-Null
  $r = Invoke-InstallerFallback `
          -Action "REFramework Nightly release lookup" `
          -Url "$INFO_URL/releases" `
          -Instructions "Open the REFramework-nightly releases page that just opened, download both 'REFramework.zip' and 'VR.zip' from the latest release, place them into '$tmpManual', then choose Retry." `
          -SkipMessage "Skipped - REFramework cannot be installed without those files; install is incomplete (questionable result)." `
          -DestFolder $tmpManual `
          -AllowSkip $true
  if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
  if ([string]$r -eq "retry") {
    $refLocal = Join-Path $tmpManual "REFramework.zip"
    $vrLocal  = Join-Path $tmpManual "VR.zip"
    if ((Test-Path $refLocal) -and (Test-Path $vrLocal)) {
      $refZipUrl = $refLocal
      $vrZipUrl  = $vrLocal
      $tagName   = "manual"
      $refreshCache = $true
      Write-OK "Using manually-placed ZIPs from $tmpManual"
    } else {
      Pause-User "REFramework.zip and/or VR.zip still missing in $tmpManual. Press Enter to exit..."
      exit 1
    }
  } else {
    $refZipUrl = $null
    $vrZipUrl  = $null
  }
}

# -------------------------------------------------------
# STEP 3: Install (from the saved copy or a fresh download)
# -------------------------------------------------------
Write-Step 3 3 "Installing"

$tmp = Join-Path $env:TEMP "REFrameworkVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null
$failed = @()

foreach ($dl in @(@{Name="REFramework.zip"; Url=$refZipUrl; Cache=$REF_CACHE_REF; Verify="dinput8.dll"}, @{Name="VR.zip"; Url=$vrZipUrl; Cache=$REF_CACHE_VR; Verify="openxr_loader.dll"})) {
 # Pick the source zip: the saved copy, a manual local file, or a download.
 if ($useCache) {
   $dest = $dl.Cache
 } else {
   if (-not $dl.Url) { continue }
   $dest = Join-Path $tmp $dl.Name
   # If the URL is already a local file path (manual fallback), copy it.
   if (Test-Path $dl.Url) {
     Copy-Item -Path $dl.Url -Destination $dest -Force
   } else {
     $r = Invoke-DownloadOrFallback -Url $dl.Url -Destination $dest `
            -Label "$($dl.Name) ($tagName)" `
            -ManualUrl "$INFO_URL/releases" `
            -Instructions "Download '$($dl.Name)' from the REFramework-nightly releases page (build $tagName). Place it at '$dest' and choose Retry." `
            -SkipMessage "Skipped - $($dl.Name) was not downloaded; install is incomplete (questionable result)."
     if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
     if (-not ($r -is [bool] -and $r)) { $failed += $dl.Name; continue }
   }
 }

 # Payload-verified extract: pulled from releases/LATEST, so the ZIP
 # layout can change any day - extract to temp, resolve the real payload
 # root, merge into the game folder, verify the key file arrived.
 $efb = Expand-ArchiveToTarget -ArchivePath $dest -TargetDir $gamePath `
          -RelModFile $dl.Verify `
          -Label "$($dl.Name) extraction" `
          -SkipMessage "Skipped - $($dl.Name) was not extracted into the game folder."
 if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
   Write-Info "Extracted $($dl.Name) -> game folder"
 } else {
   $failed += $dl.Name
 }
}

# Refresh the Hub cache from the freshly downloaded (or manual) zips, but only
# if BOTH extracted cleanly - never save a broken/partial set.
if ($refreshCache -and $failed.Count -eq 0) {
  try {
    if (-not (Test-Path $REF_CACHE_DIR)) { New-Item -ItemType Directory -Path $REF_CACHE_DIR -Force | Out-Null }
    $tmpRef = Join-Path $tmp "REFramework.zip"
    $tmpVr  = Join-Path $tmp "VR.zip"
    if ((Test-Path $tmpRef) -and (Test-IsZip $tmpRef)) { Copy-Item $tmpRef $REF_CACHE_REF -Force }
    if ((Test-Path $tmpVr)  -and (Test-IsZip $tmpVr))  { Copy-Item $tmpVr  $REF_CACHE_VR  -Force }
    Set-Content $REF_CACHE_VER $tagName -Encoding UTF8 -Force
    Write-Info "Saved this build to the Hub ($tagName) for future installs."
  } catch { Write-Warn "Could not update the Hub cache: $($_.Exception.Message)" }
}

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# Pragmata AFW: install the plugin, or remove it on switch-back
# -------------------------------------------------------
# Runs only for Pragmata (both flags default false elsewhere). AFW is
# laid down AFTER the base REFramework install so it sits alongside it.
$afwStatus = $null   # "installed" | "removed" | "failed" | $null
if ($removeAFW) {
    $anyRemoved = $false
    foreach ($f in $AFW_FILES) {
        $p = Join-Path $gamePath $f
        if (Test-Path $p) {
            try { Remove-Item $p -Force -EA Stop; $anyRemoved = $true }
            catch { Write-Warn "Could not remove $f : $($_.Exception.Message)" }
        }
    }
    $afwStatus = if ($anyRemoved) { "removed" } else { $null }
}
elseif ($wantAFW) {
    $afwTmp = Join-Path ([System.IO.Path]::GetTempPath()) ("afw_" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $afwTmp -Force | Out-Null
    $afwDest = Join-Path $afwTmp $AFW_ZIP_NAME
    $afwOk = $false
    $r = Invoke-DownloadOrFallback -Url $AFW_ZIP_URL -Destination $afwDest `
           -Label "AFW plugin (PRAGMATA_AFW_v1.0-beta.1)" `
           -ManualUrl $AFW_PAGE_URL `
           -Instructions "Download '$AFW_ZIP_NAME' from PureDark's release page. Place it at '$afwDest' and choose Retry." `
           -SkipMessage "Skipped - AFW was not downloaded; the standard REFramework install is still in place."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ($r -is [bool] -and $r) {
        # Flat zip (PDAFWPlugin.dll + dinput8.dll) - payload-verified extract.
        $efb = Expand-ArchiveToTarget -ArchivePath $afwDest -TargetDir $gamePath `
                 -RelModFile $AFW_MARKER `
                 -Label "AFW plugin extraction" `
                 -SkipMessage "Skipped - AFW was not extracted; the standard REFramework install is still in place."
        if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        if (([string]$efb -eq "ok" -or [string]$efb -eq "manual") -and (Test-Path (Join-Path $gamePath $AFW_MARKER))) {
            $afwOk = $true
        }
    }
    $afwStatus = if ($afwOk) { "installed" } else { "failed" }
    try { Remove-Item $afwTmp -Recurse -Force -EA SilentlyContinue } catch {}
}

# Record whether AFW is active, next to the version marker, so the Hub
# and a future installer run can tell which variant is in place. Only
# meaningful for Pragmata; harmless elsewhere.
if ($isPragmata) {
    $afwFlagFile = Join-Path $PSScriptRoot ".afw_active_pragmata"
    try {
        if (Test-Path (Join-Path $gamePath $AFW_MARKER)) {
            Set-Content $afwFlagFile "1" -Encoding UTF8 -Force
        } elseif (Test-Path $afwFlagFile) {
            Remove-Item $afwFlagFile -Force -EA SilentlyContinue
        }
    } catch {}
}

# Record the installed build tag where the Hub's Check-Installed scan reads
# it (.installed_version_<safe title>), so the game tile flips to "Update"
# when a newer nightly is published. Keyed by title because all REFramework
# games share this folder (matches Get-InstalledVersionPath / .installed_path).
$verSafe = if ($GameTitle) { ($GameTitle -replace '[^A-Za-z0-9]','_') } else { ($selectedGame.Title -replace '[^A-Za-z0-9]','_') }
$tagFile = Join-Path $PSScriptRoot ".installed_version_$verSafe"
try { Set-Content $tagFile $tagName -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
Clear-Host
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary - $($selectedGame.Title)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ("REFramework.zip" -notin $failed) { Write-Host " [x] REFramework.zip ($tagName)" -ForegroundColor Green }
else { Write-Host " [ ] REFramework.zip -- FAILED" -ForegroundColor Red }
if ("VR.zip" -notin $failed) { Write-Host " [x] VR.zip" -ForegroundColor Green }
else { Write-Host " [ ] VR.zip -- FAILED" -ForegroundColor Red }
if ($afwStatus -eq "installed") { Write-Host " [x] AFW performance plugin (by PureDark)" -ForegroundColor Green }
elseif ($afwStatus -eq "failed") { Write-Host " [ ] AFW performance plugin -- FAILED (standard install is intact)" -ForegroundColor Red }
elseif ($afwStatus -eq "removed") { Write-Host " [x] AFW performance plugin removed - back to the standard nightly" -ForegroundColor Green }
Write-Host ""
Write-Host " Launch SteamVR before the game to avoid it potentially starting" -ForegroundColor White
Write-Host " sometimes out of focus." -ForegroundColor White
Write-Host " Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or via Steam normally." -ForegroundColor White
Write-Host " REFramework loads automatically - configure VR in its menu." -ForegroundColor Gray
Write-Host ""
if ($afwStatus -eq "installed") {
    Write-Host " AFW is active - a few things to get the best out of it:" -ForegroundColor Cyan
    Write-Host "   - In-game, turn ON DLSS/DLAA (or FSR); AFW fixes the VR" -ForegroundColor Gray
    Write-Host "     wobbling, so DLSS Quality/Balanced/Performance are fine." -ForegroundColor Gray
    Write-Host "   - Turn OFF Hair Strands (it causes a ghosting hair edge)." -ForegroundColor Gray
    Write-Host "   - Aim for 90 fps, not 72 - AFW works best at 90." -ForegroundColor Gray
    Write-Host "   - Do NOT use Motion Smoothing / ASW / SSW in SteamVR," -ForegroundColor Gray
    Write-Host "     Quest Link or Virtual Desktop - AFW replaces them and" -ForegroundColor Gray
    Write-Host "     they'd halve the engine fps and add input lag." -ForegroundColor Gray
    Write-Host "   - Needs ~500 MB extra VRAM; if you're short it can drop to" -ForegroundColor Gray
    Write-Host "     single-digit fps. Minor artifacts can happen - just judge" -ForegroundColor Gray
    Write-Host "     whether the performance gain is worth it." -ForegroundColor Gray
    Write-Host "   - Debug hotkeys: Numpad 7 toggles AFW vs default rendering," -ForegroundColor Gray
    Write-Host "     Numpad 4 toggles the DLSS wobbling fix, Numpad 6 shows the" -ForegroundColor Gray
    Write-Host "     AFW debug tint, Numpad * toggles sharpening (+/- adjusts)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "   AFW is a fixed release and won't auto-update. Run this" -ForegroundColor Gray
    Write-Host "   installer again and pick [1] to switch back to the" -ForegroundColor Gray
    Write-Host "   auto-updating nightly. Thanks to PureDark for the plugin." -ForegroundColor Gray
    Write-Host "   AFW page: $AFW_PAGE_URL" -ForegroundColor Gray
    Write-Host ""
    Write-Host " To update REFramework itself: run this installer again." -ForegroundColor Gray
} else {
    Write-Host " To update: run this installer again." -ForegroundColor Gray
}
Write-Host " More info: $INFO_URL" -ForegroundColor Gray
Write-Host ""
if ($selectedGame.Flavor) {
 Write-Host " $($selectedGame.Flavor)" -ForegroundColor Magenta
 Write-Host ""
}
Write-Host ""
Pause-User "Press Enter to exit."
