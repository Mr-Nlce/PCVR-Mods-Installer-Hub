# ============================================================
# Mass Effect 2 VR - Installer (MELE2-VR by dhalcyon)
# ============================================================
# Mass Effect 2 Legendary Edition in full head-tracked PCVR:
# real stereo depth, 6DOF, three VR modes (Stereo / AER / DIBR,
# plus Mono) and an optional first-person camera. Gamepad only.
#
# The mod ships its OWN interactive setup batch (MELE2-VR.bat)
# that deliberately does NO game detection - it must sit in the
# game's ...\Game\ME2\Binaries\Win64 folder (next to
# MassEffect2.exe) and run FROM there; it self-elevates when the
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

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Mass Effect 2 VR Installer"
$ErrorActionPreference = "Stop"

$PATREON_URL   = "https://www.patreon.com/dhalcyon/posts/suicide-mission-165506412"
$DIRECT_URL    = "https://www.patreon.com/file?h=165506412&m=709853965"
$STEAM_APPID   = "1328670"
$STEAM_FOLDER  = "Mass Effect Legendary Edition"
$ME2_SUBPATH   = "Game\ME2\Binaries\Win64"
$ME2_EXE       = "MassEffect2.exe"
$LAUNCHER_SUB  = "Game\Launcher\MassEffectLauncher.exe"
$MOD_FILES     = @("MELE2-VR.bat", "dxgi.dll", "openxr_loader.dll", "MELE2VR.ini")

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Mass Effect 2 VR - Installer" -ForegroundColor Cyan
 Write-Host " MELE2-VR by dhalcyon | Legendary Edition (ME2) | gamepad" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-Mele2Root {
 param([string]$Root)
 if (-not $Root) { return $false }
 $ok = $false
 try { $ok = Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $ME2_SUBPATH, $ME2_EXE)) } catch {}
 return $ok
}

Write-Header
Write-Host "  Mass Effect 2 Legendary Edition in full head-tracked VR with" -ForegroundColor Gray
Write-Host "  real stereo depth. VR modes: Stereo, AER and DIBR (plus Mono);" -ForegroundColor Gray
Write-Host "  cutscenes and conversations are in VR too, first-person camera" -ForegroundColor Gray
Write-Host "  is optional." -ForegroundColor Gray
Write-Host "  Originally a third-person game - do not expect a full FPS" -ForegroundColor Gray
Write-Host "  conversion. Gamepad only." -ForegroundColor Gray
Write-Host ""
Write-Host "  You need Mass Effect Legendary Edition installed (any store)." -ForegroundColor White
Pause-User "Press Enter to start the installation..." | Out-Null

# -------------------------------------------------------
# STEP 1: Locate Mass Effect Legendary Edition (any store)
# -------------------------------------------------------
Write-Step 1 5 "Locating Mass Effect Legendary Edition"

$gamePath = $null
$isSteam  = $false
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
 $cand = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($STEAM_FOLDER) `
   -EpicNames @("Mass Effect Legendary Edition")
 if (Test-Mele2Root -Root $cand) { $gamePath = $cand; $isSteam = $true }
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
 foreach ($c in $candidates) { if (Test-Mele2Root -Root $c) { $gamePath = $c; break } }
}
if (-not $gamePath) {
 $rec = $null
 try { $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
 if ($rec) { $rec = $rec.Trim() }
 if (Test-Mele2Root -Root $rec) { $gamePath = $rec }
}
while (-not $gamePath) {
 Write-Warn "Could not find the game automatically."
 Write-Host " Drag & drop your 'Mass Effect Legendary Edition' folder onto" -ForegroundColor White
 Write-Host " this window (the one containing the 'Game' folder), then" -ForegroundColor White
 Write-Host " press Enter. Or press Enter on an empty line to exit." -ForegroundColor Gray
 $raw = (Read-Host " Game folder").Trim().Trim('"')
 if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit."; exit 1 }
 if (Test-Mele2Root -Root $raw) { $gamePath = $raw }
 else { Write-Fail "That folder has no Game\ME2\Binaries\Win64\$ME2_EXE inside." }
}
if ($gamePath -match '(?i)\\steamapps\\common\\') { $isSteam = $true }
$win64 = [System.IO.Path]::Combine($gamePath, $ME2_SUBPATH)
Write-OK "Found: $gamePath"
if ($isSteam) { Write-Info "Steam install detected." }
Write-Info "Mod target: $win64"

# -------------------------------------------------------
# STEP 2: Get the mod from Patreon
# -------------------------------------------------------
Write-Step 2 5 "Getting MELE2-VR (Patreon)"

$zip = $null
$dl = Join-Path $env:USERPROFILE "Downloads"
# MELE2*, not MELE* - the ME1 zip (MELE-VR.zip) sits in the same
# Downloads folder for anyone who installed part 1, and picking it
# here would place ME1 files into the ME2 folder.
$found = Get-ChildItem -Path $dl -Filter "MELE2*VR*.zip" -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($found) {
 Write-Host " Found in Downloads: $($found.Name)" -ForegroundColor Cyan
 Write-Host " [1] Use this file" -ForegroundColor White
 Write-Host " [2] Open Patreon to get a fresh copy instead" -ForegroundColor White
 $c = ""
 while ($c -notin @("1","2")) { $c = (Read-Host " Enter 1 or 2").Trim() }
 if ($c -eq "1") { $zip = $found.FullName } else { $askedForPatreon = $true }
}

if (-not $zip -and $DIRECT_URL) {
 $tmpZip = Join-Path $env:TEMP ("MELE2VR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
 if (Invoke-DownloadOrFallback -Url $DIRECT_URL -Destination $tmpZip -Label "MELE2-VR" -ManualUrl $PATREON_URL `
    -Instructions "Download MELE2-VR.zip from the Patreon post, then retry.") { $zip = $tmpZip }
}

if (-not $zip) {
 # Gate BEFORE the browser opens (same lesson as the Nexus flow).
 if (-not $askedForPatreon) {
  Write-Host " The mod is distributed through a public Patreon post by its" -ForegroundColor White
  Write-Host " creator dhalcyon - the download there is free." -ForegroundColor White
  Pause-User "Press Enter to open the Patreon post for MELE2-VR"
 }
 try { Start-Process $PATREON_URL } catch { Write-Warn "Could not open the browser. Visit: $PATREON_URL" }
 Write-Host ""
 Write-Host " The Patreon post is now open in your browser." -ForegroundColor Cyan
 Write-Host " - Scroll to the post's attachment and download MELE2-VR.zip" -ForegroundColor Gray
 Write-Host " - Save it to your Downloads folder, OR drag & drop the" -ForegroundColor Gray
 Write-Host "   downloaded zip into THIS window" -ForegroundColor Gray
 while (-not $zip) {
  Write-Host ""
  Write-Host " >>> Drag & drop the zip here, or just press Enter when the download is done " -ForegroundColor Black -BackgroundColor Yellow
  $r = (Read-Host).Trim().Trim('"')
  if ($r -and (Test-Path -LiteralPath $r)) { $zip = $r }
  elseif (-not $r) {
   $found = Get-ChildItem -Path $dl -Filter "MELE2*VR*.zip" -ErrorAction SilentlyContinue |
     Sort-Object LastWriteTime -Descending | Select-Object -First 1
   if ($found) { $zip = $found.FullName }
   else { Write-Warn "No MELE2*VR*.zip in Downloads yet - finish the download first." }
  }
  else { Write-Fail "Not a valid file path: $r" }
 }
}
Write-OK "Using: $zip"

# -------------------------------------------------------
# STEP 3: Place the four mod files into Win64
# -------------------------------------------------------
Write-Step 3 5 "Placing the mod files next to $ME2_EXE"

$tmp = Join-Path $env:TEMP ("MELE2VR_x_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$exRes = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label "MELE2-VR"
if (-not $exRes) {
 Write-Fail "Extraction failed."
 Pause-User "Press Enter to exit."; exit 1
}
# The zip is flat (verified: 4 payload files + a README at the root),
# but stay tolerant of a future wrapper folder.
$srcDir = $tmp
if (-not (Test-Path -LiteralPath (Join-Path $tmp "MELE2-VR.bat"))) {
 $inner = Get-ChildItem -Path $tmp -Directory | Where-Object {
  Test-Path -LiteralPath (Join-Path $_.FullName "MELE2-VR.bat")
 } | Select-Object -First 1
 if ($inner) { $srcDir = $inner.FullName }
}
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
if ($missing.Count -gt 0) {
 Write-Fail ("Could not place: " + ($missing -join ", "))
 Pause-User "Press Enter to exit."; exit 1
}
Write-OK "All four mod files are in place."
try { Remove-Item -LiteralPath $tmp -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 4: Run the mod's own setup (VR mode + quality)
# -------------------------------------------------------
Write-Step 4 5 "Running the mod's setup"

Write-Host " MELE2-VR brings its own interactive setup. It will ask:" -ForegroundColor White
Write-Host "   - VR mode: Stereo / Mono / AER / DIBR" -ForegroundColor Gray
Write-Host "   - Image quality: Performance / Balanced / Sharp / Max" -ForegroundColor Gray
Write-Host "     plus Extreme (expect dropped frames)" -ForegroundColor Gray
Write-Host " Recommended default: " -NoNewline -ForegroundColor White
Write-Host "Stereo + Balanced" -ForegroundColor Green
Write-Host " You can switch the VR MODE later in the in-game menu; a" -ForegroundColor Gray
Write-Host " QUALITY change means rerunning this installer." -ForegroundColor Gray
Write-Host " If Windows asks for Administrator permission, click Yes -" -ForegroundColor Gray
Write-Host " that is the mod writing into a protected game folder." -ForegroundColor Gray
Pause-User "Press Enter to start the MELE2-VR setup..."
try {
 Start-Process -FilePath (Join-Path $win64 "MELE2-VR.bat") -WorkingDirectory $win64 -Wait
 Write-OK "Mod setup finished."
} catch {
 Write-Warn "Could not run the setup automatically: $_"
 Write-Warn "Open $win64 and double-click MELE2-VR.bat yourself, then return here."
 Pause-User "Press Enter once the MELE2-VR setup is done..."
}

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
# Either way we do NOT point at MassEffect2.exe directly: that drags
# up the EA launcher and, on a machine that never ran the game, nags
# that EA/Origin is missing.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
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
Write-Host " The MELE2-VR setup has configured resolution and turned HDR" -ForegroundColor White
Write-Host " off for you - HDR is the #1 cause of a blue or doubled" -ForegroundColor White
Write-Host " headset image, so the mod handles it automatically." -ForegroundColor White
Write-Host ""
Write-Host " Only if the setup printed a WARNING that it could not write" -ForegroundColor Gray
Write-Host " GamerSettings.ini: rerun this installer as administrator, or" -ForegroundColor Gray
Write-Host " turn " -NoNewline -ForegroundColor Gray
Write-Host "HDR OFF" -NoNewline -ForegroundColor Green
Write-Host " and Motion Blur off yourself in the in-game video menu." -ForegroundColor Gray
Pause-User "Press Enter to finish..."

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " HOW TO PLAY:" -ForegroundColor Yellow
Write-Host "  1. Start your OpenXR runtime (SteamVR, Virtual Desktop, Meta)." -ForegroundColor White
Write-Host "  2. Launch the game (any store) or 'Start in VR' in the Hub -" -ForegroundColor White
Write-Host "     pick Mass Effect 2 in the launcher; the mod loads with it." -ForegroundColor White
Write-Host ""
Write-Host " IN-VR CONTROLS (keyboard, gamepad plays the game):" -ForegroundColor Yellow
Write-Host "   INSERT  open/close the mod menu    R  recenter view" -ForegroundColor White
Write-Host "   K       first-person toggle        1-4  settings profiles" -ForegroundColor White
Write-Host "   Gamepad BACK, tapped twice: recenter" -ForegroundColor White
Write-Host ""
Write-Host " Assemble the team. The Omega-4 relay is a one-way trip." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
