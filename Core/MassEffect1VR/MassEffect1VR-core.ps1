# ============================================================
# Mass Effect 1 VR - Installer (MELE-VR by dhalcyon)
# ============================================================
# Mass Effect 1 Legendary Edition in full head-tracked PCVR:
# real stereo depth, 6DOF, three VR modes (Stereo / AER / DIBR,
# plus Mono) and an optional first-person camera. Gamepad only.
#
# The mod ships its OWN interactive setup batch (MELE-VR.bat)
# that deliberately does NO game detection - it must sit in the
# game's ...\Game\ME1\Binaries\Win64 folder (next to
# MassEffect1.exe) and run FROM there; it self-elevates when the
# folder needs admin rights. So this installer does what the bat
# will not: find the game across all five store layouts, place
# the four mod files, then hand over to the bat for the VR-mode
# and quality choices.
#
# Download source is a public Patreon post (Luke Ross pattern):
# a direct patreon.com/file?h=<post>&m=<media> URL downloads the
# attachment without a login. Flow: reuse a zip already sitting in
# Downloads, else direct-download via $DIRECT_URL, else open the
# post in the browser (behind an Enter gate) and take the zip via
# drag & drop - so a dead link degrades gracefully, never blocks.
# ============================================================

param([ValidateSet('','motion','gamepad')][string]$Mod='')

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'MEVR-State.ps1')

$Host.UI.RawUI.WindowTitle = "Mass Effect 1 VR Installer"
$ErrorActionPreference = "Stop"

$PATREON_URL   = "https://www.patreon.com/dhalcyon/posts/mass-effect-vr-167394663"
$DIRECT_URL    = "https://www.patreon.com/file?h=167394663&m=723054662"
$STEAM_APPID   = "1328670"
$STEAM_FOLDER  = "Mass Effect Legendary Edition"
$ME1_SUBPATH   = "Game\ME1\Binaries\Win64"
$ME1_EXE       = "MassEffect1.exe"
$LAUNCHER_SUB  = "Game\Launcher\MassEffectLauncher.exe"
$MOD_FILES     = @("MELE-VR.bat", "dxgi.dll", "openxr_loader.dll", "MELEVR.ini")

function New-MELEFileBackup {
 param([string]$Directory,[string[]]$Files)
 $backup = Join-Path $env:TEMP ('MELE-VR-backup-' + [guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $backup -ErrorAction Stop | Out-Null
 foreach ($file in $Files) {
  $old = Join-Path $Directory $file
  if (Test-Path -LiteralPath $old -PathType Leaf) {
   Copy-Item -LiteralPath $old -Destination (Join-Path $backup $file) -Force -ErrorAction Stop
  }
 }
 return $backup
}
function Restore-MELEFileBackup {
 param([string]$Directory,[string[]]$Files,[string]$Backup)
 foreach ($file in $Files) {
  $old = Join-Path $Backup $file
  $target = Join-Path $Directory $file
  if (Test-Path -LiteralPath $old -PathType Leaf) {
   Copy-Item -LiteralPath $old -Destination $target -Force -ErrorAction Stop
  } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
   Remove-Item -LiteralPath $target -Force -ErrorAction Stop
  }
 }
 Remove-Item -LiteralPath $Backup -Recurse -Force -ErrorAction Stop
}

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Mass Effect 1 VR - Installer" -ForegroundColor Cyan
 Write-Host " Legendary Edition (ME1) | Motion Controls or Gamepad" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-MeleRoot {
 param([string]$Root)
    if (-not (Test-PCVRGameInstallProof -GameId 'mass-effect-1-le-vr' -Root $Root)) { return $false }

 if (-not $Root) { return $false }
 $ok = $false
 try { $ok = Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $ME1_SUBPATH, $ME1_EXE)) } catch {}
 return $ok
}

function Install-MEVRMotion {
    param([string]$GameRoot,[switch]$Steam)
    $releasePage = 'https://github.com/dnehring/MEVR/releases'
    $pattern = '(?i)^MEVR-[0-9]+(?:\.[0-9]+){2,3}\.zip$'
    $win64 = Join-Path $GameRoot 'Game\ME1\Binaries\Win64'
    $required = @(
        'Game\ME1\Binaries\Win64\ASI\LE1MEVR.asi'
        'Game\ME1\Binaries\Win64\ASI\MEVR-install.json'
        'Game\ME1\Binaries\Win64\ASI\MEVR-Setup.exe'
        'Game\ME1\Binaries\Win64\ASI\menu\main.rml'
        'Game\ME1\BioGame\CookedPCConsole\BIOG_MEVR_Cockpit.pcc'
        'Game\ME1\Binaries\Win64\bink2w64.dll'
        'Game\ME1\Binaries\Win64\bink2w64_original.dll'
        'Game\Launcher\bink2w64.dll'
        'Game\Launcher\bink2w64_original.dll'
    )
    $contract = New-PCVRInstallerContract -Id 'mass-effect-1-le-vr' -GameName 'Mass Effect 1 Legendary Edition' -Acquisition GitHub -Routes @('motion') -ReleasePageUrl $releasePage -RequiredInstalledFileGroups $required -AntivirusNotice
    if (Get-Process -Name MassEffect1,MassEffectLauncher -ErrorAction SilentlyContinue) {
        throw 'Close Mass Effect and the Legendary Edition launcher before continuing.'
    }
    if (-not (Test-InstallerTargetWritable (Join-Path $win64 'bink2w64.dll'))) {
        throw 'The ME1 folder is not writable. Run the Hub as administrator or make the game folder writable, then retry.'
    }
    $scratch = Join-Path ([IO.Path]::GetTempPath()) ('PCVR-MEVR-' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $scratch | Out-Null
        $archive = Join-Path $scratch 'MEVR.zip'
        $staging = Join-Path $scratch 'expanded'
        $zipProof = { param($candidate) (Test-ArchiveContains $candidate 'MEVR-Setup.exe') -and (Test-ArchiveContains $candidate 'LE1MEVR.asi') }

        Write-Step 2 4 'Finding the latest Windows release'
        if (-not (Wait-PCVRExplicitEnter -Message 'Press Enter to check GitHub and download MEVR.')) { throw 'Cancelled.' }
        $release = Resolve-GitHubReleaseAsset -Repo 'dnehring/MEVR' -AssetPatterns @($pattern) -SkipReleasesWithoutMatchingAsset
        if ($release.Resolved -and $release.Url) {
            $downloaded = Invoke-DownloadOrFallback -Url $release.Url -Destination $archive -Label "MEVR $($release.Tag)" -ManualUrl $releasePage -Validator $zipProof -AllowSkip $false
        } else {
            $downloaded = Invoke-InstallerFallback -Action 'MEVR Windows download' -Url $releasePage -DestFile $archive -DestFolder $scratch -FileValidator $zipProof -RetryCheck { & $zipProof $archive } -AllowSkip $false
        }
        if (-not $downloaded -or -not (Test-Path -LiteralPath $archive -PathType Leaf)) { throw 'No usable MEVR Windows archive was supplied.' }
        if (-not (Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $staging -Label 'MEVR Windows release' -AllowSkip $false -QuietProgress)) {
            throw 'The MEVR Windows archive could not be extracted.'
        }
        $setup = @(Get-ChildItem -LiteralPath $staging -Filter 'MEVR-Setup.exe' -Recurse -File)
        if ($setup.Count -ne 1) { throw 'The archive must contain one MEVR-Setup.exe.' }
        $payload = Join-Path $setup[0].DirectoryName 'payload'
        foreach ($file in @('LE1MEVR.asi','bink2w64.dll','menu\main.rml','cockpit\BIOG_MEVR_Cockpit.pcc')) {
            if (-not [IO.File]::Exists((Join-Path $payload $file))) { throw "MEVR package is missing payload\$file." }
        }

        Write-Step 3 4 'Running the publisher setup'
        Write-Host ' MEVR keeps your game settings. It parks active MELE-VR DLLs until MEVR is removed.'
        Write-Host ' The publisher setup verifies the supported Legendary Edition build before it writes game files.'
        if (-not (Wait-PCVRExplicitEnter -Message 'Press Enter to run MEVR Setup.')) { throw 'Cancelled.' }
        $out = Join-Path $scratch 'setup.txt'
        $source = if ($Steam) { 'Steam' } else { 'Folder' }
        $arguments = '--install --game "{0}" --payload "{1}" --source {2} --no-settings --quality keep --out "{3}"' -f $GameRoot.TrimEnd('\'),$payload,$source,$out
        $process = Start-Process -FilePath $setup[0].FullName -WorkingDirectory $setup[0].DirectoryName -ArgumentList $arguments -Wait -PassThru
        if (Test-Path -LiteralPath $out -PathType Leaf) { Get-Content -LiteralPath $out | ForEach-Object { Write-Host " $_" } }
        if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "MEVR Setup did not finish successfully (exit $($process.ExitCode))." }

        Write-Step 4 4 'Verifying the installation'
        $version = Get-MEVRInstalledVersion $GameRoot
        Write-Host " MEVR version and active loaders: $(if ($version) { $version } else { 'missing' })"
        if (-not $version) { throw 'MEVR did not leave a valid installation manifest and active ASI loaders. Use the publisher setup to repair it.' }
        Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $version -Route 'motion' -VersionSlot Secondary -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) | Out-Null
        Write-OK "MEVR $version installed. Start MEVR from the Hub with your OpenXR runtime running."
    } finally {
        if (Test-Path -LiteralPath $scratch) {
            $resolvedScratch = [IO.Path]::GetFullPath($scratch)
            $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\PCVR-MEVR-'
            if ($resolvedScratch.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase)) {
                Remove-Item -LiteralPath $resolvedScratch -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Header
if (-not $Mod) {
 Write-Host ' [1] MEVR by dnehring (Motion Controls)' -ForegroundColor White
 Write-Host ' [2] MELE-VR by dhalcyon (Gamepad)' -ForegroundColor White
 Write-Host ' [Q] Cancel' -ForegroundColor Gray
 do { $choice = (Read-Host 'Choose 1, 2 or Q').Trim() } until ($choice -in @('1','2','Q'))
 if ($choice -eq 'Q') { exit 1 }
 $Mod = if ($choice -eq '1') { 'motion' } else { 'gamepad' }
}
if ($Mod -eq 'motion') {
 Write-Host ' MEVR adds motion-controlled combat and uses your active OpenXR runtime.'
 Write-Host ' Start Mass Effect 1 normally once before installing. MEVR only changes ME1.'
 Show-AntivirusNotice -Compact
} else {
 Write-Host ' MELE-VR is the Gamepad route. Its setup configures stereo and other VR modes.'
}
# -------------------------------------------------------
# STEP 1: Locate Mass Effect Legendary Edition (any store)
# -------------------------------------------------------
if ($Mod -eq "motion") { Write-Step 1 4 "Locating Mass Effect Legendary Edition" } else { Write-Step 1 5 "Locating Mass Effect Legendary Edition" }

$remembered = Get-HubLocatedGameFolder -GameId 'mass-effect-1-le-vr' -ProbeFiles @('Game\ME1\Binaries\Win64\MassEffect1.exe')
$gamePath = if (Test-MeleRoot -Root $remembered) { $remembered }
$isSteam  = $false
if (-not $gamePath -and (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue)) {
 $cand = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($STEAM_FOLDER) `
   -EpicNames @("Mass Effect Legendary Edition")
 if (Test-MeleRoot -Root $cand) { $gamePath = $cand }
}
if (-not $gamePath) {
 # EA App / EA Play Pro, Origin legacy, Epic and Game Pass default
 # layouts (Game Pass uses the EA App path). Drive-safe via Combine.
 $candidates = @(
  "C:\Program Files\EA Games\Mass Effect Legendary Edition",
  "C:\Program Files (x86)\Origin Games\Mass Effect Legendary Edition",
  "C:\Program Files\Epic Games\Mass Effect Legendary Edition",
  "D:\Program Files\EA Games\Mass Effect Legendary Edition",
  "E:\Program Files\EA Games\Mass Effect Legendary Edition",
  "D:\Games\Mass Effect Legendary Edition",
  "E:\Games\Mass Effect Legendary Edition"
 )
 foreach ($c in $candidates) { if (Test-MeleRoot -Root $c) { $gamePath = $c; break } }
}
if (-not $gamePath) {
 $rec = $null
 try { $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
 if ($rec) { $rec = $rec.Trim() }
 if (Test-MeleRoot -Root $rec) { $gamePath = $rec }
}
while (-not $gamePath) {
 Write-Warn "Could not find the game automatically."
 Write-Host " Drag & drop your 'Mass Effect Legendary Edition' folder onto" -ForegroundColor White
 Write-Host " this window (the one containing the 'Game' folder), then" -ForegroundColor White
 Write-Host " press Enter. Or press Enter on an empty line to exit." -ForegroundColor Gray
 $raw = (Read-Host " Game folder").Trim().Trim('"')
 if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit."; exit 1 }
 if (Test-MeleRoot -Root $raw) { $gamePath = $raw }
 else { Write-Fail "That folder has no Game\ME1\Binaries\Win64\$ME1_EXE inside." }
}
if ($gamePath -match '(?i)\\steamapps\\common\\') { $isSteam = $true }
$win64 = [System.IO.Path]::Combine($gamePath, $ME1_SUBPATH)
Write-OK "Found: $gamePath"
if ($isSteam) { Write-Info "Steam install detected." }
Write-Info "Mod target: $win64"

if ($Mod -eq 'motion') {
 try { Install-MEVRMotion -GameRoot $gamePath -Steam:$isSteam }
 catch { Write-Fail $_.Exception.Message; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
 Write-Host ''
 Write-Host " I'm Commander Shepard, and this is my favorite mod on the Citadel." -ForegroundColor Magenta
 Pause-User "Press Enter to finish." | Out-Null
 exit 0
}
if ([IO.File]::Exists((Join-Path $win64 'ASI\MEVR-install.json')) -or [IO.File]::Exists((Join-Path $win64 'ASI\LE1MEVR.asi'))) {
 Write-Fail 'Remove MEVR with its publisher uninstaller before installing or updating the Gamepad mod on this copy.'
 Pause-User "Press Enter to exit." | Out-Null
 exit 1
}

# -------------------------------------------------------
# STEP 2: Get the mod from Patreon
# -------------------------------------------------------
Write-Step 2 5 "Getting MELE-VR (Patreon)"

$zip = $null
$dl = Get-PCVRDownloadsFolder
# !!! THE NAME IS NOT PROOF, THE CONTENT IS (2026-08-20). All three
# Mass Effect games now ship in ONE MELE-VR.zip, and older
# per-game downloads may still sit in the same Downloads folder.
# Matching on the name alone offered MELE2-VR.zip while installing
# ME3 - which would have put one game's mod into another game's
# folder. So every candidate is OPENED and only accepted when it
# really carries this game's payload: MELE1VR.zip inside the
# combined package, or MELE-VR.bat in a single-game download.
$cands = @(Get-ChildItem -Path $dl -Filter "*.zip" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending)
$found = $null
foreach ($c in $cands) {
    if ((Test-ArchiveContains -ArchivePath $c.FullName -Entry "MELE1VR.zip") -or
        (Test-ArchiveContains -ArchivePath $c.FullName -Entry "MELE-VR.bat")) {
        $found = $c; break
    }
}
if ($found) {
 Write-Host " Found in Downloads: $($found.Name)" -ForegroundColor Cyan
 Write-Host " [1] Use this file" -ForegroundColor White
 Write-Host " [2] Open Patreon to get a fresh copy instead" -ForegroundColor White
 $c = ""
 while ($c -notin @("1","2")) { $c = (Read-Host " Enter 1 or 2").Trim() }
 if ($c -eq "1") { $zip = $found.FullName } else { $askedForPatreon = $true }
}

if (-not $zip -and $DIRECT_URL) {
 $tmpZip = Join-Path $env:TEMP ("MELE1VR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
 if (Invoke-DownloadOrFallback -Url $DIRECT_URL -Destination $tmpZip -Label "MELE-VR" -ManualUrl $PATREON_URL `
    -Instructions "Download MELE1-VR.zip from the Patreon post, then retry.") { $zip = $tmpZip }
}

if (-not $zip) {
 # Gate BEFORE the browser opens (same lesson as the Nexus flow).
 if (-not $askedForPatreon) {
  Write-Host " The mod is distributed through a public Patreon post by its" -ForegroundColor White
  Write-Host " creator dhalcyon - the download there is free." -ForegroundColor White
  Pause-User "Press Enter to open the Patreon post for MELE-VR"
 }
 try { Start-Process $PATREON_URL } catch { Write-Warn "Could not open the browser. Visit: $PATREON_URL" }
 Write-Host ""
 Write-Host " The Patreon post is now open in your browser." -ForegroundColor Cyan
 Write-Host " - Scroll to the post's attachment and download MELE1-VR.zip" -ForegroundColor Gray
 Write-Host " - Save it to your Downloads folder, OR drag & drop the" -ForegroundColor Gray
 Write-Host "   downloaded zip into THIS window" -ForegroundColor Gray
 while (-not $zip) {
  Write-Host ""
  Write-Host " >>> Drag & drop the zip here, or just press Enter when the download is done " -ForegroundColor Black -BackgroundColor Yellow
  $r = (Read-Host).Trim().Trim('"')
  if ($r -and (Test-Path -LiteralPath $r)) { $zip = $r }
  elseif (-not $r) {
   $found = Get-ChildItem -Path $dl -Filter "MELE*VR*.zip" -ErrorAction SilentlyContinue |
     Where-Object { $_.Name -notmatch "(?i)MELE2" } |
     Sort-Object LastWriteTime -Descending | Select-Object -First 1
   if ($found) { $zip = $found.FullName }
   else { Write-Warn "No MELE*VR*.zip in Downloads yet - finish the download first." }
  }
  else { Write-Fail "Not a valid file path: $r" }
 }
}
Write-OK "Using: $zip"

# -------------------------------------------------------
# STEP 3: Place the four mod files into Win64
# -------------------------------------------------------
Write-Step 3 5 "Placing the mod files next to $ME1_EXE"

$tmp = Join-Path $env:TEMP ("MELE1VR_x_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$exRes = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label "MELE-VR"
if (-not $exRes) {
 Write-Fail "Extraction failed."
 Pause-User "Press Enter to exit."; exit 1
}
# THE DOWNLOAD IS NOW AN ARCHIVE OF ARCHIVES (2026-08-20): the
# author ships ONE MELE-VR.zip holding MELE1VR.zip, MELE2VR.zip
# and MELE3VR.zip - one per game. Unpacking the outer file alone
# leaves three zips and no payload, so the shared helper is used:
# it walks a wrapper folder OR unpacks the inner archive that
# really carries this game's marker - never a sibling belonging
# to one of the other two games.
$srcDir = Expand-NestedArchive -Root $tmp -Marker "MELE-VR.bat" -Label "MELE-VR"
if (-not $srcDir) {
 Write-Fail "MELE-VR.bat is not in the download - neither loose nor in an inner archive."
 Pause-User "Press Enter to exit."; exit 1
}
$missingSource = @($MOD_FILES | Where-Object { -not (Test-Path -LiteralPath (Join-Path $srcDir $_) -PathType Leaf) })
if ($missingSource.Count -gt 0) {
 Write-Fail ("The publisher package is missing: " + ($missingSource -join ', '))
 Pause-User "Press Enter to exit."; exit 1
}
$fileBackup = New-MELEFileBackup -Directory $win64 -Files $MOD_FILES
$missing = @()
foreach ($f in $MOD_FILES) {
 $src = Join-Path $srcDir $f
 if (Test-Path -LiteralPath $src) {
  try {
   Copy-Item -LiteralPath $src -Destination (Join-Path $win64 $f) -Force -ErrorAction Stop
  } catch {
   # Program Files without write access: retry the copy elevated.
   Write-Warn "Need Administrator rights to write into the game folder - a prompt will appear."
   $cmd = "Copy-Item -LiteralPath '$src' -Destination '$(Join-Path $win64 $f)' -Force"
   try {
    Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile","-Command",$cmd
   } catch {}
   if (-not (Test-Path -LiteralPath (Join-Path $win64 $f))) { $missing += $f }
  }
 } else { $missing += $f }
}
foreach ($file in $MOD_FILES) {
 $target = Join-Path $win64 $file
 if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or
     (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne
     (Get-FileHash -LiteralPath (Join-Path $srcDir $file) -Algorithm SHA256).Hash) {
  $missing += $file
 }
}
$missing = @($missing | Select-Object -Unique)
if ($missing.Count -gt 0) {
 Write-Fail ("Could not place: " + ($missing -join ", "))
 try { Restore-MELEFileBackup -Directory $win64 -Files $MOD_FILES -Backup $fileBackup }
 catch { Write-Fail "Restoring the previous files failed: $_" }
 Pause-User "Press Enter to exit."; exit 1
}
Write-OK "All four mod files are in place."

# -------------------------------------------------------
# STEP 4: Run the mod's own setup (VR mode + quality)
# -------------------------------------------------------
Write-Step 4 5 "Running the mod's setup"

Write-Host " MELE-VR brings its own interactive setup. It will ask:" -ForegroundColor White
Write-Host "   - VR mode: Stereo / Mono / AER / DIBR" -ForegroundColor Gray
Write-Host "   - Image quality: Performance / Balanced / Sharp / Max" -ForegroundColor Gray
Write-Host "     (plus Extreme for Stereo only)" -ForegroundColor Gray
Write-Host " Recommended default: " -NoNewline -ForegroundColor White
Write-Host "Stereo + Sharp" -ForegroundColor Green
Write-Host " You can switch the VR MODE later in the in-game menu; a" -ForegroundColor Gray
Write-Host " QUALITY change means rerunning this installer." -ForegroundColor Gray
Write-Host " If Windows asks for Administrator permission, click Yes -" -ForegroundColor Gray
Write-Host " that is the mod writing into a protected game folder." -ForegroundColor Gray
Pause-User "Press Enter to start the MELE-VR setup..."
try {
 $setupProcess = Start-Process -FilePath (Join-Path $win64 "MELE-VR.bat") -WorkingDirectory $win64 -Wait -PassThru -ErrorAction Stop
 if ($setupProcess.ExitCode -ne 0) { throw "Publisher setup exited with code $($setupProcess.ExitCode)." }
 $setupIni = Join-Path $win64 "MELEVR.ini"
 $setupSettings = if (Test-Path -LiteralPath $setupIni -PathType Leaf) { Get-Content -LiteralPath $setupIni -Raw } else { '' }
 if ($setupSettings -notmatch '(?m)^expectedResX\s*=\s*[1-9][0-9]*\s*$') { throw "Publisher setup did not confirm VR configuration in MELEVR.ini." }
 $gamepadFiles = @('Game\ME1\Binaries\Win64\dxgi.dll','Game\ME1\Binaries\Win64\openxr_loader.dll','Game\ME1\Binaries\Win64\MELEVR.ini')
 $gamepadContract = New-PCVRInstallerContract -Id 'mass-effect-1-le-vr' -GameName 'Mass Effect 1 Legendary Edition' -Acquisition External -RequiredInstalledFileGroups $gamepadFiles -Routes @('gamepad')
 $build = (Get-Item -LiteralPath (Join-Path $win64 'dxgi.dll')).LastWriteTime.ToString('yyyyMMdd.HHmmss',[Globalization.CultureInfo]::InvariantCulture)
 Complete-PCVRInstallTransaction -Contract $gamepadContract -GameDir $gamePath -Version $build -Route 'gamepad' -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) | Out-Null
 Write-OK "Mod setup finished."
} catch {
 Write-Fail "Mod setup did not complete: $_"
 try { Restore-MELEFileBackup -Directory $win64 -Files $MOD_FILES -Backup $fileBackup }
 catch { Write-Fail "Restoring the previous files failed: $_" }
 Pause-User "Press Enter to exit."; exit 1
}
try { Remove-Item -LiteralPath $fileBackup -Recurse -Force -ErrorAction Stop }
catch { Write-Warn "Temporary backup cleanup failed: $_" }

# Hub markers: MELE root for the tile scan + how "Start in VR" launches.
# LAUNCH ROUTE (deliberate):
#   Steam install  -> NO .launch_exe. The Hub then falls back to
#     steam://rungameid/$SteamId, which routes through Steam. If the
#     EA App layer is not installed yet, Steam triggers ITS install
#     instead of erroring - the smooth path for first-time launches.
#   non-Steam (EA / Origin / Epic / Game Pass) -> record the game's
#     OWN launcher exe (MassEffectLauncher.exe) as .launch_exe. These
#     have no steam://id, and their launcher is the correct entry
#     point; the AC installers use the same .launch_exe mechanism.
# Either way we do NOT point at MassEffect1.exe directly: that drags
# up the EA launcher and, on a machine that never ran the game, nags
# that EA/Origin is missing.
$leProbe = Join-Path $PSScriptRoot ".launch_exe"
if ($isSteam) {
 # Remove any .launch_exe from an earlier non-Steam run so the Hub
 # cleanly falls through to the steam:// route.
 try { if (Test-Path -LiteralPath $leProbe) { Remove-Item -LiteralPath $leProbe -Force } } catch {}
} else {
 try { Set-Content -Path $leProbe -Value ([System.IO.Path]::Combine($gamePath, $LAUNCHER_SUB)) -Encoding UTF8 -Force } catch {}
}

# -------------------------------------------------------
# STEP 5: Confirm the mod's own setup did its job
# -------------------------------------------------------
Write-Step 5 5 "Wrapping up"

# The mod's setup handles HDR ITSELF: it writes DesiredRange=
# DynamicRange_SDR into the game's GamerSettings.ini (the same file
# the in-game HDR toggle uses), and does it BEFORE the launcher runs,
# which is more reliable than the in-game menu - so there is nothing
# for the user to toggle here, and on many installs there is no HDR
# option in the menu at all. We only surface it as a FALLBACK, for
# the one case where the mod's own setup reported it could not write
# that file (a permissions/AV case it warns about on screen).
Write-Host " The MELE-VR setup has configured resolution and turned HDR" -ForegroundColor White
Write-Host " off for you - HDR is the #1 cause of a blue or doubled" -ForegroundColor White
Write-Host " headset image, so the mod handles it automatically." -ForegroundColor White
Write-Host ""
Write-Host " Only if the setup printed a WARNING that it could not write" -ForegroundColor Gray
Write-Host " GamerSettings.ini: rerun this installer as administrator, or" -ForegroundColor Gray
Write-Host " turn " -NoNewline -ForegroundColor Gray
Write-Host "HDR OFF" -NoNewline -ForegroundColor Green
Write-Host " and Motion Blur off yourself in the in-game video menu." -ForegroundColor Gray

# -------------------------------------------------------
# OPTIONAL: the other two games from the SAME download
# -------------------------------------------------------
# One MELE-VR.zip now carries all three games, and the whole
# Legendary Edition sits under ONE folder - so the other two are
# a copy and a setup run away, with nothing more to download.
# ASKED, never assumed: someone may own the trilogy but only want
# VR in one part, and each game runs its own interactive setup.
$ALL_GAMES = @(
    @{ Key = "ME1"; Name = "Mass Effect 1"; Sub = "Game\ME1\Binaries\Win64"; Exe = "MassEffect1.exe"; Bat = "MELE-VR.bat";  Ini = "MELEVR.ini" }
    @{ Key = "ME2"; Name = "Mass Effect 2"; Sub = "Game\ME2\Binaries\Win64"; Exe = "MassEffect2.exe"; Bat = "MELE2-VR.bat"; Ini = "MELE2VR.ini" }
    @{ Key = "ME3"; Name = "Mass Effect 3"; Sub = "Game\ME3\Binaries\Win64"; Exe = "MassEffect3.exe"; Bat = "MELE3-VR.bat"; Ini = "MELE3VR.ini" }
)
$others = @($ALL_GAMES | Where-Object { $_.Key -ne "ME1" -and (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $_.Sub, $_.Exe))) })
if ($others.Count -gt 0 -and $srcDir) {
    Write-Host ""
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "   The same download also covers the other games you own" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    foreach ($o in $others) { Write-Host "   - $($o.Name)" -ForegroundColor White }
    Write-Host ""
    Write-Host "   Nothing more to download - each one just needs its files" -ForegroundColor Gray
    Write-Host "   copied and its own setup answered (VR mode + quality)." -ForegroundColor Gray
    Write-Host ""
    $doAll = ""
    for ($i = 1; $i -le 20; $i++) {
        $doAll = ("" + (Read-Host "  Install VR for those too? [y/n]")).Trim().ToLower()
        if ($doAll -in @("y","n","yes","no")) { break }
        Write-Host "  Please answer y or n." -ForegroundColor Yellow
    }
    if ($doAll -in @("y","yes")) {
        foreach ($o in $others) {
            Write-Host ""
            Write-Host "  === $($o.Name) ===" -ForegroundColor Cyan
            # Each game has its OWN payload inside the download - the
            # dxgi.dll differs per game, so the folders must not be mixed.
            $oSrc = Expand-NestedArchive -Root $tmp -Marker $o.Bat -Label $o.Name
            if (-not $oSrc) { Write-Warn "$($o.Bat) is not in this download - skipping $($o.Name)."; continue }
            $oDir = [System.IO.Path]::Combine($gamePath, $o.Sub)
            $oFiles = @($o.Bat, "dxgi.dll", "openxr_loader.dll", $o.Ini)
            $oMissingSource = @($oFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $oSrc $_) -PathType Leaf) })
            if ($oMissingSource.Count -gt 0) {
                Write-Warn ("Package for $($o.Name) is missing: " + ($oMissingSource -join ', '))
                continue
            }
            $oBackup = New-MELEFileBackup -Directory $oDir -Files $oFiles
            $oOk = $true
            foreach ($f in $oFiles) {
                $src = Join-Path $oSrc $f
                if (-not (Test-Path -LiteralPath $src)) { Write-Warn "Missing in the package: $f"; $oOk = $false; continue }
                try { Copy-Item -LiteralPath $src -Destination (Join-Path $oDir $f) -Force -ErrorAction Stop }
                catch {
                    $cmd = "Copy-Item -LiteralPath '$src' -Destination '$(Join-Path $oDir $f)' -Force"
                    try { Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile","-Command",$cmd } catch {}
                    if (-not (Test-Path -LiteralPath (Join-Path $oDir $f))) { Write-Warn "Could not place $f"; $oOk = $false }
                }
            }
            foreach ($f in $oFiles) {
                $oTarget = Join-Path $oDir $f
                if (-not (Test-Path -LiteralPath $oTarget -PathType Leaf) -or
                    (Get-FileHash -LiteralPath $oTarget -Algorithm SHA256).Hash -ne
                    (Get-FileHash -LiteralPath (Join-Path $oSrc $f) -Algorithm SHA256).Hash) { $oOk = $false }
            }
            if (-not $oOk) {
                try { Restore-MELEFileBackup -Directory $oDir -Files $oFiles -Backup $oBackup }
                catch { Write-Warn "Restoring previous $($o.Name) files failed: $_" }
                Write-Warn "$($o.Name) was not completed."
                continue
            }
            Write-OK "Files placed for $($o.Name)."
            Write-Host "  Its setup opens now - answer VR mode and quality." -ForegroundColor White
            Pause-User "Press Enter to start the $($o.Name) setup..." | Out-Null
            try {
                $otherProcess = Start-Process -FilePath (Join-Path $oDir $o.Bat) -WorkingDirectory $oDir -Wait -PassThru -ErrorAction Stop
                if ($otherProcess.ExitCode -ne 0) { throw "Publisher setup exited with code $($otherProcess.ExitCode)." }
                $otherIni = Join-Path $oDir $o.Ini
                $otherSettings = if (Test-Path -LiteralPath $otherIni -PathType Leaf) { Get-Content -LiteralPath $otherIni -Raw } else { '' }
                $otherConfigured = if ($o.Key -eq 'ME1') {
                    $otherSettings -match '(?m)^expectedResX\s*=\s*[1-9][0-9]*\s*$'
                } else {
                    $otherSettings -match '(?m)^InstallerRun=1\s*$'
                }
                if (-not $otherConfigured) { throw "Publisher setup did not confirm VR configuration." }
                Write-OK "$($o.Name) is set up."
                try { Remove-Item -LiteralPath $oBackup -Recurse -Force -ErrorAction Stop }
                catch { Write-Warn "Temporary backup cleanup failed: $_" }
            } catch {
                Write-Warn "$($o.Name) setup did not complete: $($_.Exception.Message)"
                try { Restore-MELEFileBackup -Directory $oDir -Files $oFiles -Backup $oBackup }
                catch { Write-Warn "Restoring previous $($o.Name) files failed: $_" }
            }
        }
    }
}

try { Remove-Item -LiteralPath $tmp -Recurse -Force } catch {}
Pause-User "Press Enter to finish..."

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Blue
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""
Write-Host " HOW TO PLAY:" -ForegroundColor Yellow
Write-Host "  1. Start your OpenXR runtime (SteamVR, Virtual Desktop, Meta)." -ForegroundColor White
Write-Host "  2. Launch the game (any store) or" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub -" -ForegroundColor White
Write-Host "     pick Mass Effect 1 in the launcher; the mod loads with it." -ForegroundColor White
Write-Host ""
Write-Host " IN-VR CONTROLS (keyboard, gamepad plays the game):" -ForegroundColor Yellow
Write-Host "   INSERT  open/close the mod menu    R  recenter view" -ForegroundColor White
Write-Host "   K       first-person toggle        P  depth pop toggle" -ForegroundColor White
Write-Host "   1-4     load settings profiles" -ForegroundColor White
Write-Host ""
Write-Host " I'm Commander Shepard, and this is my favorite mod on the Citadel." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
