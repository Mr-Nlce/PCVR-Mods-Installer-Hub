# -------------------------------------------------------
# Sayonara Wild Hearts VR Mod Installer
# by Astienth - distributed via Discord
#
# Walks the user through:
# 1. Discord server join + rules acknowledgement
# 2. Mod ZIP download (linked from the Discord post)
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Sayonara Wild Hearts install folder
# 5. OPTIONAL: create a flat-screen-safe copy of the
# game folder (the mod makes the original folder
# unable to launch in flat-screen mode)
# 6. Extract mod files in place (or in the copy)
#
# Sayonara Wild Hearts VR is a depth-only mod with bHaptics
# vest support. Controls remain gamepad or keyboard - no
# motion controls. ViGEmBus is not needed.
#
# IMPORTANT: installing this mod into a game folder makes
# THAT folder VR-only - the game can no longer be launched
# in flat-screen from the same folder. The mod author
# strongly recommends copying the game folder first so the
# original stays flat-playable.
#
# Recenter view: hold the gamepad START button for a few
# seconds, or press Esc on keyboard. SteamVR's own recenter
# also works.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "SayonaraWildHearts_VRMod_bHaptics"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1122720"
$GAME_NAME = "Sayonara Wild Hearts"
$GAME_EXE = "Sayonara Wild Hearts.exe"

# Discord URLs the installer hands the user, in the order they
# appear in the welcome flow. Same FarmerTrueVR server as the
# other Astienth mods; this game's mod channel + post IDs.
$DISCORD_INVITE_URL = "https://discord.gg/G8zZBTGuhP"
$DISCORD_RULES_URL = "https://discord.com/channels/1001138422972432597/1001138600781557862/1111681500711235664"
$DISCORD_INFO_URL = "https://discord.com/channels/1001138422972432597/1253317358735327354/1253317358735327354"
$DISCORD_DOWNLOAD_URL = "https://discord.com/channels/1001138422972432597/1253317358735327354/1253317523835981874"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Sayonara Wild Hearts VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}

function Write-Step {
 param([int]$Step, [int]$Total, [string]$Title)
 Write-Host ""
 Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
 Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @(
 "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
 "HKLM:\SOFTWARE\Valve\Steam",
 "HKCU:\SOFTWARE\Valve\Steam"
 )) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraries {
 param($SteamPath)
 $libs = @()
 if (-not $SteamPath) { return $libs }
 $libs += $SteamPath
 $vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
 $l = $_.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $l) { $libs += $l }
 }
 }
 return ($libs | Select-Object -Unique)
}

function Find-SayonaraGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir mirrors the title with spaces. The Unity
 # data folder is "Sayonara Wild Hearts_Data".
 foreach ($folder in @("Sayonara Wild Hearts", "SayonaraWildHearts")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Sayonara Wild Hearts_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 1: Discord onboarding
# -------------------------------------------------------
Write-Header

Write-Host " Sayonara Wild Hearts VR is distributed by Astienth via Discord." -ForegroundColor White
Write-Host " Are you already a member of the FarmerTrueVR" -ForegroundColor White
Write-Host " Discord server (with rules accepted)?" -ForegroundColor White
Write-Host ""
Write-Host " >>> [Y] Yes, skip straight to the download link" -ForegroundColor Yellow
Write-Host " >>> [N] No, walk me through joining + accepting rules" -ForegroundColor Yellow
Write-Host "     [S] Show a short walkthrough of what happens first" -ForegroundColor DarkGray
Write-Host ""
$alreadyMember = ""
while ($alreadyMember -notin @("y","Y","n","N")) {
 $alreadyMember = (Read-Host " Your choice (Y/N/S)").Trim()
 if ($alreadyMember -in @("s","S")) {
  Write-Host ""
  Write-Host " Short walkthrough - what the installer does WITH you:" -ForegroundColor White
 Write-Host " 1. Join the FarmerTrueVR Discord server" -ForegroundColor Gray
 Write-Host " 2. Read the rules and click the AK-47 emoji to confirm" -ForegroundColor Gray
 Write-Host " 3. Download the Sayonara Wild Hearts VR ZIP from the mod post" -ForegroundColor Gray
 Write-Host " 4. Come back here and drag-drop the ZIP into this window" -ForegroundColor Gray
  Write-Host ""
  $alreadyMember = ""
 }
}
$skipJoin = ($alreadyMember -in @("y","Y"))
Write-Host ""

# Heads-up about the depth-only nature + the flat-screen warning.
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " Sayonara Wild Hearts VR is a DEPTH-ONLY mod - it adds" -ForegroundColor White
Write-Host " stereoscopic 3D and bHaptics vest support, but no motion" -ForegroundColor White
Write-Host " controls. Controls remain GAMEPAD or KEYBOARD. ViGEmBus" -ForegroundColor White
Write-Host " is not needed." -ForegroundColor White
Write-Host ""
Write-Host " Seated experience recommended. Recenter view by holding" -ForegroundColor White
Write-Host " gamepad START for a few seconds (or pressing Esc on" -ForegroundColor White
Write-Host " keyboard). SteamVR's own recenter also works." -ForegroundColor White
Write-Host ""
Write-Host " CRITICAL HEADS-UP:" -ForegroundColor Yellow
Write-Host " Installing this mod into a game folder makes that folder" -ForegroundColor White
Write-Host " VR-ONLY - flat-screen mode will no longer work from the" -ForegroundColor White
Write-Host " same folder. The author strongly recommends copying the" -ForegroundColor White
Write-Host " game folder first so the original stays flat-playable." -ForegroundColor White
Write-Host " The installer will offer to make the copy for you in" -ForegroundColor White
Write-Host " step 4." -ForegroundColor White
Write-Host ""
Write-Host " bHaptics: only the VEST is supported. Launch the bHaptics" -ForegroundColor White
Write-Host " Player and connect your vest before launching the game." -ForegroundColor White
Write-Host ""

if (-not $skipJoin) {
 Write-Host " HOW THIS WORKS: at each step press Enter - the installer opens the page for you." -ForegroundColor White
 Write-Host " Do ONLY the highlighted action on that page, then come back here and press Enter for the next step." -ForegroundColor White
 Write-Host ""

 Write-Host " [Step 1/3] Discord server invite   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: Accept Invite" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_INVITE_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the invite in your browser..."
 try { Start-Process $DISCORD_INVITE_URL } catch { Write-Warn "Could not open browser. Visit the URL above manually." }

 Write-Host ""
 Write-Host " [Step 2/3] Rules channel - read the rules, then   " -ForegroundColor Cyan -NoNewline
 Write-Host "Click: the AK-47 emoji under the rules post" -ForegroundColor Yellow
 Write-Host "   (this unlocks the rest of the server)" -ForegroundColor DarkGray
 Write-Host "   (auto-opens: $DISCORD_RULES_URL)" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the rules channel..."
 try { Start-Process $DISCORD_RULES_URL } catch {}
}

Write-Host ""
 Write-Host " [Step 3/3] Mod download post   " -ForegroundColor Cyan -NoNewline
 Write-Host "Download: the mod ZIP" -ForegroundColor Yellow
 Write-Host "   (auto-opens: $DISCORD_DOWNLOAD_URL)" -ForegroundColor DarkGray
Write-Host " Background info: $DISCORD_INFO_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the download post..."
try { Start-Process $DISCORD_DOWNLOAD_URL } catch {}

# -------------------------------------------------------
# STEP 2: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 4 "Locate the downloaded ZIP"
Write-Host " Once the Sayonara Wild Hearts VR mod ZIP is on your disk, drop it here." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter after the Discord ZIP download is complete..."

$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP, type its path, or Q to quit:" -ForegroundColor Yellow
 $answer = Read-Host " ZIP path or Q"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (-not (Test-Path -LiteralPath $r -PathType Leaf)) { Write-Fail "File not found: $r"; continue }
 if ($r -notmatch '(?i)\.zip$') { Write-Fail 'Choose the complete Sayonara Wild Hearts VR ZIP from the Discord post.'; continue }
 $anchors = @('(?i)(?:^|\\)winhttp\.dll$',
              '(?i)(?:^|\\)BepInEx\\plugins\\UnityVRPlugin_SayonaraWildHearts\.dll$',
              '(?i)(?:^|\\)BepInEx\\core\\BepInEx\.Preloader\.dll$',
              '(?i)(?:^|\\)BepInEx\\config\\UnityVR_Bepinex\.cfg$')
 if (-not (Test-ZipPayloadAnchors -Path $r -AnchorPatterns $anchors -MinimumMatches $anchors.Count)) {
  Write-Fail 'The ZIP is unreadable, unsafe, or missing the Sayonara VR runtime. Select another ZIP or Q.'
  continue
 }
 $modZip = $r
 Write-OK "VR archive located and checked: $modZip"
}

# -------------------------------------------------------
# STEP 3: Locate the Sayonara Wild Hearts install
# -------------------------------------------------------
Write-Step 2 4 "Locating Sayonara Wild Hearts"

$originalGamePath = Find-SayonaraGamePath
if (-not $originalGamePath) { $originalGamePath = Find-SteamGameFolder -AppId "1122720" -SteamFolderNames @("Sayonara Wild Hearts") -GogNames @("Sayonara Wild Hearts") -EpicNames @("Sayonara Wild Hearts","SayonaraWildHearts") }
if ($originalGamePath -and -not (Test-Path -LiteralPath (Join-Path $originalGamePath $GAME_EXE) -PathType Leaf)) {
 Write-Warn "Found a folder without ${GAME_EXE}: $originalGamePath"
 $originalGamePath = $null
}
if ($originalGamePath) {
 Write-OK "Found Sayonara Wild Hearts at: $originalGamePath"
} else {
 Write-Warn "Could not auto-locate Sayonara Wild Hearts in any Steam library."
 Write-Host " Looking for a folder containing 'Sayonara Wild Hearts.exe'." -ForegroundColor Gray
 Write-Host " Please paste the path to your Sayonara Wild Hearts folder." -ForegroundColor White
 Write-Host ""
 while (-not $originalGamePath) {
 $answer = Read-Host " Sayonara Wild Hearts folder or Q to quit"
 if ($null -eq $answer) { exit 1 }
 $r = $answer.Trim().Trim('"')
 if ($r -ieq 'Q') { exit 1 }
 if (-not $r) { continue }
 if (Test-Path -LiteralPath (Join-Path $r $GAME_EXE) -PathType Leaf) {
 $originalGamePath = $r
 Write-OK "Game folder set: $originalGamePath"
 } else {
 Write-Fail "$GAME_EXE not found in: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 4: Optional copy of the game folder (flat-screen-safe)
# -------------------------------------------------------
Write-Step 3 4 "Make a flat-screen-safe copy?"

Write-Host " The mod author strongly recommends copying the game folder" -ForegroundColor White
Write-Host " before installing the VR mod, because the modded folder" -ForegroundColor White
Write-Host " cannot be launched in flat-screen mode." -ForegroundColor White
Write-Host ""
Write-Host " Original folder:" -ForegroundColor Gray
Write-Host " $originalGamePath" -ForegroundColor Cyan
Write-Host ""
Write-Host " [Y] Make a copy and install the mod into the COPY" -ForegroundColor Yellow
Write-Host " (recommended - flat-screen play stays available" -ForegroundColor Gray
Write-Host " from the original Steam folder)" -ForegroundColor Gray
Write-Host " [N] Install the mod directly into the original folder" -ForegroundColor Yellow
Write-Host " (you will only be able to play in VR from this" -ForegroundColor Gray
Write-Host " folder afterwards - Steam will keep launching" -ForegroundColor Gray
Write-Host " the modded VR build)" -ForegroundColor Gray
Write-Host ""
$wantCopy = ""
while ($wantCopy -notin @("y","Y","n","N")) {
 $wantCopy = (Read-Host " Your choice (Y/N)").Trim()
}

if ($wantCopy -in @("y","Y")) {
 $baseData = Join-Path $originalGamePath 'Sayonara Wild Hearts_Data\globalgamemanagers'
 if (-not (Test-Path -LiteralPath $baseData -PathType Leaf)) {
  Write-Fail 'The original game data is incomplete. No copy or mod installation was started.'
  Pause-User 'Press Enter to exit...'
  exit 1
 }
 # Default copy location: sibling folder named "<original> VR".
 # User can override.
 $parentDir = Split-Path -Parent $originalGamePath
 $defaultCopy = Join-Path $parentDir "Sayonara Wild Hearts VR"

 Write-Host ""
 Write-Host " Default copy location:" -ForegroundColor Gray
 Write-Host " $defaultCopy" -ForegroundColor Cyan
 Write-Host ""
 Write-Host " [Y] Use the default location" -ForegroundColor Yellow
 Write-Host " [N] Pick a different folder" -ForegroundColor Yellow
 $useDefault = ""
 while ($useDefault -notin @("y","Y","n","N")) { $useDefault = (Read-Host " Your choice (Y/N)").Trim() }

 if ($useDefault -in @("y","Y")) {
 $copyTarget = $defaultCopy
 } else {
 $copyTarget = $null
 while (-not $copyTarget) {
 $r = (Read-Host " Full path for the copy (must NOT exist yet)").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 Write-Fail "Path already exists: $r"
 continue
 }
 $copyTarget = $r
 }
 }

 $originalFull = [IO.Path]::GetFullPath($originalGamePath).TrimEnd('\','/')
 $copyFull = [IO.Path]::GetFullPath($copyTarget).TrimEnd('\','/')
 $sep = [IO.Path]::DirectorySeparatorChar
 if ($copyFull.Equals($originalFull,[StringComparison]::OrdinalIgnoreCase) -or
     $copyFull.StartsWith($originalFull + $sep,[StringComparison]::OrdinalIgnoreCase) -or
     $originalFull.StartsWith($copyFull + $sep,[StringComparison]::OrdinalIgnoreCase)) {
  Write-Fail 'The VR copy must be a separate folder outside the original game folder.'
  Pause-User 'Press Enter to exit...'
  exit 1
 }
 if (Test-Path -LiteralPath $copyTarget) {
  if (-not (Test-Path -LiteralPath $copyTarget -PathType Container) -or
      -not (Test-Path -LiteralPath (Join-Path $copyTarget $GAME_EXE) -PathType Leaf) -or
      -not (Test-Path -LiteralPath (Join-Path $copyTarget 'Sayonara Wild Hearts_Data\globalgamemanagers') -PathType Leaf)) {
   Write-Fail "Existing VR copy is incomplete: $copyTarget"
   Write-Host ' Choose a different destination on the next installer run; the original was not changed.' -ForegroundColor Yellow
   Pause-User 'Press Enter to exit...'
   exit 1
  }
  Write-OK "Using the existing complete VR copy: $copyTarget"
 } else {
  $copied = $false
  while (-not $copied) {
   Write-Host ""
   Write-Host " Copying game folder (this may take a minute)..." -ForegroundColor Gray
   Write-Host " From: $originalGamePath" -ForegroundColor DarkGray
   Write-Host " To: $copyTarget" -ForegroundColor DarkGray
   try {
    [void][IO.Directory]::CreateDirectory($copyTarget)
    Copy-Item -Path (Join-Path $originalGamePath '*') -Destination $copyTarget -Recurse -Force -ErrorAction Stop
    if (-not (Test-Path -LiteralPath (Join-Path $copyTarget $GAME_EXE) -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $copyTarget 'Sayonara Wild Hearts_Data\globalgamemanagers') -PathType Leaf)) {
     throw 'The copy is missing the game executable or Unity game data.'
    }
    $copied = $true
    Write-OK 'Game copy completed and checked.'
   } catch {
    Write-Fail "Copy failed: $_"
    Write-Host " The original game was not changed. Partial copy, if any: $copyTarget" -ForegroundColor Yellow
    $answer = Read-Host ' [R] Retry the copy / [Q] Quit without installing'
    if ($null -eq $answer -or $answer.Trim() -notmatch '^(?i:r)$') { exit 1 }
   }
  }
 }
 $gamePath = $copyTarget
} else {
 Write-Warn "Installing into the ORIGINAL folder. Flat-screen play"
 Write-Warn "will not be available from this folder afterwards."
 $gamePath = $originalGamePath
}

# -------------------------------------------------------
# STEP 5: Extract mod files into the (chosen) game folder
# -------------------------------------------------------
Write-Step 4 4 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "SayonaraVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

$extractResult = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract `
 -Label 'Sayonara Wild Hearts VR' -AllowSkip $false
if ([string]$extractResult -notin @('ok','manual','retry')) {
 Write-Fail 'The VR archive was not extracted. The game was not changed.'
 Pause-User 'Press Enter to exit...'
 exit 1
}

$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 if ($rootEntries[0].Name -ne "BepInEx") {
 $srcRoot = $rootEntries[0].FullName
 }
}

$requiredModFiles = @('winhttp.dll', 'BepInEx\core\BepInEx.Preloader.dll',
 'BepInEx\plugins\UnityVRPlugin_SayonaraWildHearts.dll', 'BepInEx\config\UnityVR_Bepinex.cfg')
try { $payloadHashes = Get-PCVRDropInSourceHashes -SourceRoot $srcRoot -RequiredFiles $requiredModFiles }
catch { Write-Fail "The extracted VR package is incomplete: $_"; Pause-User 'Press Enter to exit...'; exit 1 }

Write-Host " Copying files into: $gamePath" -ForegroundColor Gray
$contract = New-PCVRInstallerContract -Id 'sayonara-wild-hearts-vr' -GameName 'Sayonara Wild Hearts VR' -Acquisition Discord `
 -DiscordInviteUrl $DISCORD_INVITE_URL -DiscordDownloadUrl $DISCORD_DOWNLOAD_URL `
 -RequiredInstalledFileGroups (@($GAME_EXE, 'Sayonara Wild Hearts_Data\globalgamemanagers', 'winhttp.dll|winhttp_bak.dll') + @($requiredModFiles | Where-Object { $_ -ne 'winhttp.dll' }))
$keepConfigs = @('BepInEx\config\BepInEx.cfg', 'BepInEx\config\UnityVR_Bepinex.cfg')
$activeProxy = Join-Path $gamePath 'winhttp.dll'
$parkedProxy = Join-Path $gamePath 'winhttp_bak.dll'
$wasFlat = (Test-Path -LiteralPath $parkedProxy -PathType Leaf) -and -not (Test-Path -LiteralPath $activeProxy -PathType Leaf)
$oldParkedBytes = if ($wasFlat) { [IO.File]::ReadAllBytes($parkedProxy) } else { $null }
$preservedConfigs = @($keepConfigs | Where-Object { Test-Path -LiteralPath (Join-Path $gamePath $_) -PathType Leaf })
$installed = $false
while (-not $installed) {
 $copyTransaction = $null
 try {
  $copyTransaction = Install-PCVRDropInCopy -SourceRoot $srcRoot -GameRoot $gamePath `
   -SourceHashes $payloadHashes -KeepExistingFiles $keepConfigs
  Assert-PCVRDropInCopiedFiles -GameRoot $gamePath -SourceHashes $payloadHashes -PreservedExistingFiles $preservedConfigs
  if ($wasFlat) {
   Copy-Item -LiteralPath $activeProxy -Destination $parkedProxy -Force -ErrorAction Stop
   Remove-Item -LiteralPath $activeProxy -Force -ErrorAction Stop
  }
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gamePath -Version $MOD_VERSION `
   -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
  $installed = $true
 } catch {
  $failure = $_
  if ($copyTransaction) {
   try { Undo-PCVRDropInCopy -Transaction $copyTransaction }
   catch { throw "Sayonara Wild Hearts install failed and rollback failed: $failure; $_" }
  }
  if ($wasFlat) { [IO.File]::WriteAllBytes($parkedProxy,[byte[]]$oldParkedBytes) }
  Write-Fail "Installation failed; previous files were restored: $failure"
  Write-Host ' Correct the file or permission problem, then choose [R] to retry.' -ForegroundColor Yellow
  $retry = Read-Host ' [R] Retry / [Q] Quit'
  if ($null -eq $retry -or $retry.Trim() -notmatch '^(?i:r)$') { exit 1 }
 }
}
try { Complete-PCVRDropInCopy -Transaction $copyTransaction }
catch { Write-Warn "Temporary rollback snapshot could not be removed: $_" }
Write-OK 'VR runtime and version verified; existing configuration kept.'
try { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ($gamePath -eq $originalGamePath) {
 Write-Host " Mod installed into the ORIGINAL Steam folder:" -ForegroundColor White
 Write-Host " $gamePath" -ForegroundColor Cyan
 Write-Host " Steam will now launch the VR build. To go back to" -ForegroundColor Yellow
 Write-Host " flat-screen, rename winhttp.dll in this folder." -ForegroundColor Yellow
} else {
 Write-Host " Mod installed into the COPY:" -ForegroundColor White
 Write-Host " $gamePath" -ForegroundColor Cyan
 Write-Host " Original folder is untouched - flat-screen play still" -ForegroundColor Gray
 Write-Host " works via Steam." -ForegroundColor Gray
 Write-Host ""
 Write-Host " Launch the VR build with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host " .exe inside the copy:" -ForegroundColor White
 Write-Host " $gamePath\Sayonara Wild Hearts.exe" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host " BEFORE LAUNCHING:" -ForegroundColor Yellow
Write-Host " If you have a bHaptics vest, launch the bHaptics Player" -ForegroundColor White
Write-Host " and connect the vest. The mod connects automatically." -ForegroundColor White
Write-Host ""
Write-Host " Use a GAMEPAD or KEYBOARD - no VR controller support." -ForegroundColor Yellow
Write-Host " Game controls are unchanged." -ForegroundColor Gray
Write-Host ""
Write-Host " Recenter view:" -ForegroundColor Gray
Write-Host " Hold gamepad START for a few seconds, OR" -ForegroundColor Gray
Write-Host " Press Esc on keyboard, OR" -ForegroundColor Gray
Write-Host " Use SteamVR's own recenter function" -ForegroundColor Gray
Write-Host ""
Write-Host " Seated experience recommended." -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " modded game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host ""
Write-Host " Heartbreak at 200 BPM. Ride the rhythm." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
