# ============================================================
#  Outlast VR - Halcyon (dhalcyon)
# ------------------------------------------------------------
#  THE MOD BRINGS ITS OWN INSTALLER: Outlast-VR.bat.
#  It MUST run from inside the game folder - it checks for
#  OLGame.exe next to it and aborts otherwise. So the four files
#  are copied into Binaries\Win64 and the bat is started THERE.
#  It handles the rest from then on, including the configuration
#  under Documents\My Games\Outlast.
#
#  THE DOWNLOAD IS HOSTED ON PATREON BUT NEEDS NO ACCOUNT: an
#  address of the form patreon.com/file?h=...&m=... is public, so
#  the installer fetches it directly (same as the Luke Ross one).
#  A copy already on disk is used first; the page is only opened
#  if the download itself fails.
#
#  THE TARGET FOLDER IS Binaries\Win64, NOT the game folder
#  itself - the most common mix-up with this game.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot 'OutlastVR-Switch.ps1')

$Host.UI.RawUI.WindowTitle = "Outlast VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers - they are NOT in
# InstallerSafety.ps1.
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

$GAME_NAME   = "Outlast"
$APP_ID      = "238320"
$GAME_EXE    = "OLGame.exe"
$BIN_SUB     = "Binaries\Win64"
$MOD_NAME    = "Outlast VR"
$MOD_AUTHOR  = "Halcyon"
$MOD_VERSION = "August 2026"
$MOD_BAT     = "Outlast-VR.bat"
$MOD_FILES   = @("Outlast-VR.bat", "d3d9.dll", "openxr_loader.dll", "outlastvr.ini")
$POST_URL    = "https://www.patreon.com/dhalcyon/posts/nowhere-to-hide-165840706"
$FILE_URL    = "https://www.patreon.com/file?h=165840706&m=712144361"
$GRAIN_URL   = "https://www.nexusmods.com/outlast/mods/65?tab=files"
$TFC_URL     = "https://www.nexusmods.com/site/mods/588?tab=files"
$DOTNET6_URL = "https://aka.ms/dotnet/6.0/windowsdesktop-runtime-win-x64.exe"

# ---- The SECOND mod, added 2026-08-20 -------------------------
# The original Hammerthis alpha injected into the running game.
# Version 1.0 instead copies its runtime beside OLGame.exe.
#
# WE STILL PUT IT UNDER THE GAME - in <game>\_vrmods\hammerthis\ -
# so each mod has a separate store. The Hub can then find
# it the same way it finds every other mod, uninstalling is one
# folder to delete, and the two mods sit side by side where anyone
# can see both. No file of the game itself is touched either way.
#
# Query the release list to support both stable and prerelease builds.
$MODB_NAME   = "Outlast VR (drop-in)"
$MODB_AUTHOR = "Hammerthis"
$MODB_REPO   = "Hammerthis/Outlast-Vr-Mod"
$MODB_RELEASES = "https://github.com/$MODB_REPO/releases"
# !!! v1.0 CHANGED THE WHOLE DELIVERY MODEL (2026-08-28). Up to the
# alpha this was an INJECTOR: extract anywhere, launch Steam, inject a
# DLL. v1.0 is a DROP-IN - its README says so outright: no injector, no
# build tools, no extra launcher, extract into the game folder.
#
# AND IT SHIPS THE SAME FILE NAMES AS HALCYON'S MOD. Read from the real
# archive: d3d9.dll, openxr_loader.dll and outlastvr.ini all land in
# Binaries\Win64, exactly where Halcyon's do. The two cannot lie in that
# folder at the same time, and the old trick of renaming d3d9.dll to
# .off is useless now - the file the other mod needs is called the same.
#
# So both are PARKED, the way BioShock does it: each keeps its files in
# a store, only the active one has them in Binaries\Win64, and the two
# launchers swap them using the verified OutlastVR-Switch.ps1 runtime.
$MODB_DIR    = "_vrmods\hammerthis"
$MODA_DIR    = "_vrmods\halcyon"
# $MODB_BAT is gone: v1.0 ships no launcher of its own (drop-in).
# Read from the real v1.0 archive, not guessed: 7 entries, 6,072,933 B,
# sha256 3fc1491e413cfec68636670212de9bbd06dff3e3262e328546de82051f3e5a86.
# Everything sits under Binaries\Win64 except the readme.
# openxr_loader_real.dll is new in v1.0: the mod's own loader ships
# beside the proxy it replaces.
$MODB_FILES  = @("d3d9.dll", "openxr_loader.dll", "openxr_loader_real.dll",
                 "outlastvr.ini", "assets\miles\body_albedo.tga")
# Where the two switch launchers go - same shape as BioShock.
$VRLAUNCH    = "_vrmods\VRLaunch"
$LAUNCH_A    = "Outlast VR (Halcyon).bat"
$LAUNCH_B    = "Outlast VR (Hammerthis).bat"

function Install-OutlastPackage {
    param([string]$GameRoot, [string]$Name, [string]$ArchivePath)
    $layout = Get-OutlastLayout $GameRoot
    $listing = Get-ArchiveTopLevel -ArchivePath $ArchivePath
    if ($listing.Ok) {
        foreach ($file in Get-OutlastModFiles $Name) {
            $found = @($listing.Entries | Where-Object { $_.Replace('/','\') -eq $file -or $_.Replace('/','\').EndsWith('\' + $file, [StringComparison]::OrdinalIgnoreCase) })
            if (-not $found.Count) { throw "Wrong or incomplete $Name archive: $file is not included." }
        }
    }
    $stage = Join-Path $layout.Stores ('.install-' + [Guid]::NewGuid().ToString('N'))
    try {
        $status = Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $stage -Label $Name -AllowSkip $false
        if ([string]$status -notin @('ok','manual')) { throw "$Name extraction was not completed." }
        $source = Get-ExtractedPayloadRoot -ExtractDir $stage -RelModFile 'd3d9.dll' -Markers @('outlastvr.ini','openxr_loader.dll')
        $paths = @(Get-OutlastModFiles $Name | ForEach-Object { Join-Path $source $_ })
        $stageSurvived = Confirm-PlacedFilesSurvive -Paths $paths -GameDir $GameRoot -ArchivePath $ArchivePath
        if (-not $stageSurvived) { throw "$Name files are missing; installation stopped." }
        Install-OutlastStore -GameRoot $GameRoot -Name $Name -Source $source
    } finally {
        if (Test-Path -LiteralPath $stage) {
            $resolved = (Resolve-Path -LiteralPath $stage).Path
            if ($resolved.StartsWith($layout.Stores + '\.install-', [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction Stop }
        }
    }
}

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Outlast VR - Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Stereo rendering, full head tracking and VR cutscenes for" -ForegroundColor White
Write-Host "  Outlast. Two mods exist: one is gamepad-only, the other" -ForegroundColor White
Write-Host "  adds tracked controllers and VR hands." -ForegroundColor White
Write-Host ""
Show-AntivirusNotice
Write-Host "  One thing before you start:" -ForegroundColor White
Write-Host "   - " -NoNewline -ForegroundColor White
Write-Host " RUN OUTLAST ONCE NORMALLY FIRST " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     The game creates its settings files on that first launch," -ForegroundColor White
Write-Host "     and the mod's own installer needs them to be there." -ForegroundColor White
Write-Host ""

# ---- 0. WHICH MOD? --------------------------------------------
# Two mods, two very different approaches - the choice is not a
# matter of taste, so both are described before it is made.
Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "   Two Outlast VR mods exist. Which one?" -ForegroundColor Cyan
Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "   [1] $MOD_NAME by $MOD_AUTHOR" -ForegroundColor White
Write-Host "       Controls: " -NoNewline -ForegroundColor Gray
Write-Host " GAMEPAD ONLY " -ForegroundColor Black -BackgroundColor DarkCyan
Write-Host "       Stereo rendering, full head tracking, VR cutscenes." -ForegroundColor Gray
Write-Host "       You hold a gamepad. There are no VR hands, and the" -ForegroundColor Gray
Write-Host "       camcorder is raised with a button, not with your arm." -ForegroundColor Gray
Write-Host "       The more mature of the two. Available via Patreon." -ForegroundColor Gray
Write-Host ""
Write-Host "   [2] $MODB_NAME by $MODB_AUTHOR" -ForegroundColor White
Write-Host "       Controls: " -NoNewline -ForegroundColor Gray
Write-Host " VR CONTROLLERS " -ForegroundColor Black -BackgroundColor Magenta
Write-Host "       Tracked controllers and VR hands. You reach out and" -ForegroundColor Gray
Write-Host "       GRAB the camcorder, raise it to your face yourself," -ForegroundColor Gray
Write-Host "       and R3 on it gives you the night vision." -ForegroundColor Gray
Write-Host "       " -NoNewline
Write-Host " DROP-IN BUILD - expect rough edges " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "       Props can vanish at some angles, shadows can shift," -ForegroundColor Gray
Write-Host "       framerate can drop, and the motion interactions are" -ForegroundColor Gray
Write-Host "       incomplete. Free, on GitHub." -ForegroundColor Gray
Write-Host ""
Write-Host "   [3] Both - installed side by side, switchable afterwards." -ForegroundColor White
Write-Host "       The Hub then shows one Play button per mod, so you" -ForegroundColor Gray
Write-Host "       can pick gamepad or VR controllers per session." -ForegroundColor Gray
Write-Host ""
$modChoice = ""
for ($i = 1; $i -le 20; $i++) {
    $modChoice = ("" + (Read-Host "  Your choice [1/2/3]")).Trim()
    if ($modChoice -in @("1","2","3")) { break }
    Write-Host "  Please answer 1, 2 or 3." -ForegroundColor Yellow
}
if ($modChoice -notin @("1","2","3")) {
    Write-Fail "No choice made - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
$doA = ($modChoice -eq "1" -or $modChoice -eq "3")
$doB = ($modChoice -eq "2" -or $modChoice -eq "3")
Write-Host ""

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gameRoot = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Outlast") -ProbeExe "$BIN_SUB\$GAME_EXE"
if (-not $gameRoot) {
    # GOG and Epic create the same structure, just elsewhere.
    foreach ($c in @("C:\GOG Games\Outlast",
                     "C:\Program Files (x86)\GOG Galaxy\Games\Outlast",
                     "C:\Program Files\Epic Games\Outlast",
                     "C:\Program Files (x86)\Epic Games\Outlast")) {
        if (Test-Path -LiteralPath (Join-Path $c "$BIN_SUB\$GAME_EXE")) { $gameRoot = $c; break }
    }
}
if (-not $gameRoot) {
    Write-Warn "Could not find $GAME_NAME automatically."
    Write-Host "  Point me at the folder that CONTAINS Binaries\, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\Outlast" -ForegroundColor Gray
    $gameRoot = (Read-Host "  Game folder").Trim().Trim('"')
}
$binDir = Join-Path $gameRoot $BIN_SUB
if (-not (Test-Path -LiteralPath (Join-Path $binDir $GAME_EXE))) {
    Write-Fail "No $GAME_EXE under $BIN_SUB - stopping rather than guessing."
    Write-Host "  Expected: $binDir\$GAME_EXE" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameRoot"
Write-OK "Mod files go into: $binDir"
Initialize-OutlastStores -GameRoot $gameRoot

if ($doA) {
# ---- Halcyon: the file-copy route -----------------------------
    # ---- 2. Fetch the archive -------------------------------------
    Write-Step 2 5 "The download"
    Write-Host ""
    # !!! PATREON FILE LINKS ARE PUBLIC - WE CAN FETCH THEM !!!
    # An address of the form patreon.com/file?h=...&m=... needs NO login
    # and works independently of any account. The Luke Ross installer has
    # always downloaded its mod exactly that way.
    # So no hand-placement is requested here, it is downloaded directly -
    # the search on disk is only the fallback for when the file is
    # already there or the network is down.
    $patterns = @("Outlast-VR*.zip", "*Outlast*Halcyon*.zip")
    $modZip = Find-PredownloadedFile -Patterns $patterns -Label "the Outlast VR mod"
    if (-not $modZip) {
        $tmpDl = Join-Path $env:TEMP ("outlastvr_dl_" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tmpDl -Force | Out-Null
        $dest = Join-Path $tmpDl "Outlast-VR.zip"
        $download = Invoke-SafeDownload -Urls @($FILE_URL) -Destination $dest -Label "$MOD_NAME" `
            -ManualUrl $POST_URL `
            -Instructions "Download the Outlast VR ZIP from the Patreon post, save it as '$dest', then choose Retry."
        if ([string]$download -in @('skip','quit')) { throw 'Halcyon download was cancelled.' }
        if (Test-Path -LiteralPath $dest) { $modZip = $dest }
    }
    if (-not $modZip -or -not (Test-Path -LiteralPath $modZip)) {
        Write-Fail "No archive found - nothing was changed."
        Write-Host "  Download it from:" -ForegroundColor White
        Write-Host "     $POST_URL" -ForegroundColor Cyan
        Pause-User "Press Enter to exit."
        exit 1
    }
    Write-OK "Using: $modZip"

    # Validate the whole package before replacing any active file.
    Write-Step 3 5 "Installing Halcyon into its own store"
    Install-OutlastPackage -GameRoot $gameRoot -Name 'Halcyon' -ArchivePath $modZip
    Switch-OutlastMod -GameRoot $gameRoot -Name 'Halcyon'

    # ---- 4. The mod's own installer -------------------------------
    Write-Step 4 5 "Running the mod's own installer"
    Write-Host ""
    Write-Host "  $MOD_BAT does the actual setup, and it has to run from the" -ForegroundColor White
    Write-Host "  game folder - which is where it now sits. It also writes to" -ForegroundColor White
    Write-Host "  Outlast's config under your Documents folder." -ForegroundColor White
    Write-Host ""
    Write-Host "  Make sure Outlast is CLOSED - the script checks and refuses" -ForegroundColor White
    Write-Host "  to run otherwise." -ForegroundColor White
    Write-Host ""
    $batPath = Join-Path $binDir $MOD_BAT
    Pause-User "Press Enter to run $MOD_BAT..." | Out-Null
    try {
        $setup = Start-Process -FilePath $batPath -WorkingDirectory $binDir -Wait -PassThru -ErrorAction Stop
        if ($setup.ExitCode -ne 0) { throw "The mod's setup exited with code $($setup.ExitCode)." }
        Write-OK "$MOD_BAT finished."
    } catch {
        throw "Halcyon setup did not complete. Run $batPath manually. $($_.Exception.Message)"
    }

    # Marker for the Hub - into the INSTALLER folder, not the game folder.
    Save-OutlastActiveConfig -GameRoot $gameRoot

} else {
    Write-Info "Skipping the Halcyon mod - not chosen."
    $grainRemoved = $false
}

# ---- 4b. Hammerthis: stage the drop-in files in its own store ---
if ($doB) {
    Write-Host ""
    Write-Info "Installing $MODB_NAME by $MODB_AUTHOR"
    $bDir = Join-Path $gameRoot $MODB_DIR

    # Include stable v1.0 as well as any future prerelease packages.
    $bUrl = 'https://github.com/Hammerthis/Outlast-Vr-Mod/releases/download/v1.0/OutlastVR_v1.0.zip'
    $bTag = 'v1.0'; $bAsset = 'OutlastVR_v1.0.zip'; $bSize = 6072933
    $bHash = '3fc1491e413cfec68636670212de9bbd06dff3e3262e328546de82051f3e5a86'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$MODB_REPO/releases" `
                    -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
        foreach ($r in @($rels)) {
            if ($r.draft) { continue }
            $a = @($r.assets) | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1
            if ($a) { $bUrl = [string]$a.browser_download_url; $bTag = [string]$r.tag_name
                      $bAsset = [string]$a.name; $bSize = [long]$a.size
                      $bHash = if ($a.digest -match '^sha256:(\w{64})$') { $Matches[1] } else { $null }; break }
        }
    } catch { Write-Warn "GitHub could not be reached." }
    Write-OK "Release: $bTag  ($bAsset)"

    # Keep the downloaded package under the game root. Defender has been
    # observed quarantining the v1.0 ZIP itself, before extraction. If that
    # happens, the same game-folder exclusion used for the DLL recovery also
    # protects the retry; a retry in %TEMP% would simply be removed again.
    $bTmp = Join-Path $gameRoot ("_vrmods\.download-hammerthis-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $bTmp -Force | Out-Null
    $safeAssetName = [IO.Path]::GetFileName($bAsset)
    if (-not $safeAssetName) { $safeAssetName = 'OutlastVR.zip' }
    $bZip = Join-Path $bTmp $safeAssetName
    $bDownload = @{}

    try {
        # Name AND size have to match the current release, or an older copy
        # in the downloads folder would install silently. Even a matching
        # copy is first moved onto the protected game-folder staging ground.
        $bHave = Find-PredownloadedFile -Patterns @('OutlastVR_v*.zip','OutlastVR-v*.zip') -Label 'the Hammerthis mod' `
                     -ExpectedName $bAsset -ExpectedSize $bSize
        $copiedExisting = $false
        if ($bHave -and (Test-Path -LiteralPath $bHave)) {
            try {
                Copy-Item -LiteralPath $bHave -Destination $bZip -Force -ErrorAction Stop
                $copiedExisting = $true
                Write-Info "Using the copy you already downloaded."
            } catch { Write-Warn "The downloaded copy could not be staged; downloading a clean copy instead." }
        }
        if (-not $copiedExisting) {
            $download = Invoke-SafeDownload -Urls @($bUrl) -Destination $bZip -Label "$MODB_NAME $bTag" `
                -DownloadInfo $bDownload `
                -ManualUrl $MODB_RELEASES `
                -Instructions "Download the OutlastVR zip from the releases page, save it as '$bZip', then choose Retry."
            if ([string]$download -in @('skip','quit')) { throw 'Hammerthis download was cancelled.' }
        }

        # This is deliberately a separate survival check for the ZIP itself.
        # The package can disappear before Install-OutlastPackage ever gets a
        # chance to inspect or unpack it. After the user excludes the game
        # folder, retry straight into that folder and verify it again.
        $archiveSurvived = Confirm-PlacedFilesSurvive -Paths @($bZip) -GameDir $gameRoot -Recopy {
            $retry = Invoke-SafeDownload -Urls @($bUrl) -Destination $bZip -Label "$MODB_NAME $bTag" `
                -DownloadInfo $bDownload `
                -ManualUrl $MODB_RELEASES `
                -Instructions "Download the OutlastVR zip from the releases page, save it as '$bZip', then choose Retry."
            if ([string]$retry -in @('skip','quit')) { throw 'Hammerthis download was cancelled.' }
        }
        if (-not $archiveSurvived) { throw 'The Hammerthis package was removed before it could be installed.' }

        if ($bDownload.Url -match 'github\.com/Hammerthis/Outlast-Vr-Mod/releases/download/([^/]+)/') {
            $actualTag = [Uri]::UnescapeDataString($Matches[1])
            if ($actualTag -ne $bTag) { $bHash = $null }
            $bTag = $actualTag
        } elseif ($bDownload.Count -gt 0) { $bTag = ''; $bHash = $null }

        if ($bHash -and (Get-FileHash -LiteralPath $bZip -Algorithm SHA256).Hash -ne $bHash) { throw 'Hammerthis package checksum mismatch; no files were installed.' }
        Install-OutlastPackage -GameRoot $gameRoot -Name 'Hammerthis' -ArchivePath $bZip
    } finally {
        try { Remove-Item -LiteralPath $bTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}

# Activate even a single-mod installation. Never infer Halcyon's identity
# from the shared d3d9.dll filename; stores and deployed hashes identify it.
$selectedMod = if ($doA) { 'Halcyon' } else { 'Hammerthis' }
Switch-OutlastMod -GameRoot $gameRoot -Name $selectedMod
$placed = @(Get-OutlastModFiles $selectedMod | ForEach-Object { Join-Path $binDir $_ })
$activeSurvived = Confirm-PlacedFilesSurvive -Paths $placed -GameDir $gameRoot -Recopy {
    Switch-OutlastMod -GameRoot $gameRoot -Name $selectedMod
}
if (-not $activeSurvived) { throw 'The active Outlast mod did not survive verification.' }
Write-OutlastLaunchers -GameRoot $gameRoot -RuntimePath (Join-Path $PSScriptRoot 'OutlastVR-Switch.ps1')
Set-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Value $gameRoot -Encoding UTF8 -ErrorAction Stop
if ($doB -and $bTag) {
    [void](Write-ModStamp -GameDir $gameRoot -Version $bTag -Second)
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_version_b') -Value $bTag -Encoding UTF8
} elseif ($doB) {
    foreach ($record in @((Join-Path $gameRoot '.pcvrhub_version_b'), (Join-Path $PSScriptRoot '.installed_version_b'))) {
        if (Test-Path -LiteralPath $record) { Remove-Item -LiteralPath $record -Force }
    }
    Write-Warn 'The manually supplied Hammerthis version is unknown; no version was guessed.'
}
Write-OK "$selectedMod is active. Each installed mod has a verified launcher."

# ---- 5. Remove the film grain (optional) ----------------------
# !!! THIS COMPANION MOD CANNOT BE INSTALLED BY COPYING !!!
# Counted: the archive holds SEVEN files and NOT ONE of them belongs
# in the game - they are GameProfile.xml, ObjectDescriptors and a
# TexturePack, i.e. INSTRUCTIONS FOR A PATCHING TOOL. Per
# GameProfile.xml it modifies the .upk packages under
# OLGame\CookedPCConsole.
# Without that tool there is NOTHING to copy, and we do not pretend
# otherwise. What we can do: fetch the file and put it where the user
# will find it.
$grainRemoved = $false
Write-Step 5 5 "Optional: remove the film grain"
Write-Host ""
Write-Host "  Outlast has film grain baked in - it is the game, not the mod." -ForegroundColor White
Write-Host "  A Nexus mod removes it without touching the other post effects." -ForegroundColor White
Write-Host "" 
Write-Host "  Purely cosmetic - VR works fine without it. It takes about five" -ForegroundColor Gray
Write-Host "  minutes: two downloads, then three clicks in a small tool that" -ForegroundColor Gray
Write-Host "  this installer opens and walks you through." -ForegroundColor Gray
Write-Host ""
if (Read-YesNo "  Fetch the film-grain mod as well?") {
    # Counterpart to the heading of the second half further down -
    # otherwise only that one looks like a section of its own.
    Write-Host ""
    Write-Host " ============================================================" -ForegroundColor Magenta
    Write-Host "  FIRST HALF - getting the two downloads" -ForegroundColor Cyan
    Write-Host " ============================================================" -ForegroundColor Magenta
    $fgPatterns = @("*Remove*Film*Grain*.zip", "*FilmGrain*.zip")
    $fgZip = Find-PredownloadedFile -Patterns $fgPatterns -Label "the film-grain mod"
    if (-not $fgZip) {
        Pause-User "Press Enter to open the Nexus page..." | Out-Null
        try { Start-Process $GRAIN_URL } catch { Write-Warn "Open manually: $GRAIN_URL" }
        Pause-User "Press Enter once the download has finished..." | Out-Null
        $fgZip = Find-PredownloadedFile -Patterns $fgPatterns -Label "the film-grain mod" -PageAlreadyOpen
    }
    if ($fgZip -and (Test-Path -LiteralPath $fgZip)) {
        # Put it NEXT TO the game - not inside, it does not belong there.
        $fgDir = Join-Path $gameRoot "_FilmGrainMod"
        try {
            New-Item -ItemType Directory -Path $fgDir -Force -ErrorAction Stop | Out-Null
            [void](Expand-ArchiveOrFallback -ArchivePath $fgZip -DestinationFolder $fgDir -Label "film-grain mod")
            # The archive holds a subfolder with the GameProfile.xml -
            # and THAT is the one the tool wants, not the one above it.
            $gp = Get-ChildItem -LiteralPath $fgDir -Recurse -File -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -ieq "GameProfile.xml" } | Select-Object -First 1
            if ($gp) { $fgDir = $gp.DirectoryName }
            Write-OK "Mod folder ready: $fgDir"
        } catch { Write-Warn "Could not unpack it: $($_.Exception.Message)" }

        # ---- Fetch the tool -------------------------------------------
        # !!! TEXT ALONE HELPS NOBODY - it scrolls away before it is
        # needed. So the tool is fetched too, placed next to the mod
        # folder and started. The three steps then sit directly above the
        # running window.
        # !!! THIS TRANSITION USED TO DROWN IN THE DOWNLOAD NOISE !!!
        # The user has just answered two download questions and sees a
        # wall of [OK] lines. A white paragraph in between does not
        # stand out - but a SEPARATE section starts here. So it gets the
        # same heading as the steps further down.
        Write-Host ""
        Write-Host ""
        Write-Host " ============================================================" -ForegroundColor Magenta
        Write-Host "  NOW THE SECOND HALF - a small tool does the actual work" -ForegroundColor Cyan
        Write-Host " ============================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  What you just downloaded is NOT copied into the game. It is" -ForegroundColor White
        Write-Host "  a texture pack, and a tool has to patch it into Outlast's" -ForegroundColor White
        Write-Host "  own packages. That tool is free, and this installer fetches" -ForegroundColor White
        Write-Host "  it, opens it and walks you through three clicks." -ForegroundColor White
        Write-Host ""
        Write-Host "     TFC Installer for UE2-UE3" -ForegroundColor Cyan
        Write-Host ""
        $tfcPatterns = @("*TFC*Installer*.zip", "*TFCInstaller*.zip")
        $tfcZip = Find-PredownloadedFile -Patterns $tfcPatterns -Label "the TFC Installer"
        if (-not $tfcZip) {
            Pause-User "Press Enter to open its download page..." | Out-Null
            try { Start-Process $TFC_URL } catch { Write-Warn "Open manually: $TFC_URL" }
            Write-Host ""
            Write-Host "  Grab the file under Main files, then come back here." -ForegroundColor White
            Pause-User "Press Enter once the download has finished..." | Out-Null
            $tfcZip = Find-PredownloadedFile -Patterns $tfcPatterns -Label "the TFC Installer" -PageAlreadyOpen
        }

        $tfcExe = $null
        if ($tfcZip -and (Test-Path -LiteralPath $tfcZip)) {
            $tfcDir = Join-Path $gameRoot "_FilmGrainMod\TFCInstaller"
            try {
                New-Item -ItemType Directory -Path $tfcDir -Force -ErrorAction Stop | Out-Null
                [void](Expand-ArchiveOrFallback -ArchivePath $tfcZip -DestinationFolder $tfcDir -Label "TFC Installer")
                $hit = Get-ChildItem -LiteralPath $tfcDir -Recurse -File -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -ieq "TFCInstaller.exe" } | Select-Object -First 1
                if ($hit) { $tfcExe = $hit.FullName; Write-OK "Tool ready: $tfcExe" }
                else { Write-Warn "No TFCInstaller.exe inside that archive." }
            } catch { Write-Warn "Could not unpack the tool: $($_.Exception.Message)" }
        }

        if ($tfcExe) {
            # ---- START IT FIRST, THEN WALK THROUGH IT -----------------
            # All three steps used to be printed at once and only then
            # came the launch - by the time the user needed them they had
            # scrolled away. Now: open the tool, check that it runs, and
            # THEN one step at a time, each with its own Enter gate and
            # the matching path on the clipboard.
            Write-Host ""
            Write-Host "  The tool opens now. Leave this window where it is -" -ForegroundColor White
            Write-Host "  it will walk you through three steps, one at a time." -ForegroundColor White
            Pause-User "Press Enter to open the tool..." | Out-Null
            try { Start-Process -FilePath $tfcExe -WorkingDirectory (Split-Path $tfcExe -Parent) } catch {
                Write-Warn "Could not start it: $($_.Exception.Message)"
            }

            # ---- Is it running at all? --------------------------------
            Write-Host ""
            Write-Host "  Did a window open?" -ForegroundColor White
            Write-Host "     Enter        yes - carry on" -ForegroundColor Gray
            Write-Host "     I  + Enter   no, nothing happened" -ForegroundColor Gray
            $ans = ""
            try { $ans = (Read-Host "  Your answer").Trim().ToUpper() } catch {}
            if ($ans -eq "I") {
                # The tool names .NET 6 in its own requirements.txt.
                # If that is missing, there is NEITHER a window NOR an
                # error message - which is why the question above is the
                # only reliable way to detect this.
                Write-Host ""
                Write-Host "  Then the .NET Desktop Runtime 6 is missing - the tool" -ForegroundColor White
                Write-Host "  needs it and says so in its own requirements. Without it" -ForegroundColor White
                Write-Host "  nothing appears at all, not even an error." -ForegroundColor White
                Write-Host ""
                $rtDir = Join-Path $env:TEMP ("dotnet6_" + [System.IO.Path]::GetRandomFileName())
                New-Item -ItemType Directory -Path $rtDir -Force | Out-Null
                $rtExe = Join-Path $rtDir "windowsdesktop-runtime-6-win-x64.exe"
                Invoke-SafeDownload -Urls @($DOTNET6_URL) -Destination $rtExe -Label ".NET Desktop Runtime 6" `
                    -ManualUrl $DOTNET6_URL `
                    -Instructions "Download the .NET Desktop Runtime 6 (x64) installer, save it as '$rtExe', then choose Retry."
                if (Test-Path -LiteralPath $rtExe) {
                    Pause-User "Press Enter to install it - UAC required..." | Out-Null
                    try { Start-Process -FilePath $rtExe -Wait -Verb RunAs -ErrorAction Stop; Write-OK "Runtime installed." }
                    catch { Write-Warn "The install was declined or failed: $($_.Exception.Message)" }
                    Pause-User "Press Enter to open the tool again..." | Out-Null
                    try { Start-Process -FilePath $tfcExe -WorkingDirectory (Split-Path $tfcExe -Parent) } catch {
                        Write-Warn "Still could not start it. Run it by hand: $tfcExe"
                    }
                }
                try { Remove-Item -LiteralPath $rtDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            }

            # ---- Step 1 of 3 ------------------------------------------
            try { Set-Clipboard -Value $gameRoot } catch {}
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 1 of 3 - the Game folder" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  In the tool:" -ForegroundColor White
            Write-Host "   a) click the " -NoNewline -ForegroundColor White
            Write-Host " Game folder " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " button" -ForegroundColor White
            Write-Host "   b) click into the LOWER text field" -ForegroundColor White
            Write-Host "   c) Ctrl+V, press " -NoNewline -ForegroundColor White
            Write-Host " Select Folder " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Write-Host "  This path is on your clipboard now:" -ForegroundColor White
            Write-Host ""
            Write-Host "   $gameRoot " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Pause-User "Done? Press Enter for step 2..." | Out-Null

            # ---- Step 2 of 3 ------------------------------------------
            try { Set-Clipboard -Value $fgDir } catch {}
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 2 of 3 - the Mod folder" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "   a) click the " -NoNewline -ForegroundColor White
            Write-Host " Mod folder " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " button" -ForegroundColor White
            Write-Host "   b) click into the same LOWER text field" -ForegroundColor White
            Write-Host "   c) Ctrl+V, press " -NoNewline -ForegroundColor White
            Write-Host " Select Folder " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Write-Host "  This path is on your clipboard now:" -ForegroundColor White
            Write-Host ""
            Write-Host "   $fgDir " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Pause-User "Done? Press Enter for step 3..." | Out-Null

            # ---- Step 3 of 3 ------------------------------------------
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 3 of 3 - apply it" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  Click " -NoNewline -ForegroundColor White
            Write-Host " Update Outlast + DLCs " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " and wait." -ForegroundColor White
            Write-Host "  It just skips the DLCs if they are not installed." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  It copies your original packages aside first, inside the" -ForegroundColor Gray
            Write-Host "  game folder. Restore Backup in the same tool puts them" -ForegroundColor Gray
            Write-Host "  back, so nothing here is permanent." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  When it says it finished, CLOSE the tool - you do not need" -ForegroundColor White
            Write-Host "  it again unless you want to undo this." -ForegroundColor White
            Write-Host ""
            Pause-User "Closed it? Press Enter to finish..." | Out-Null
            Write-OK "Film grain removed. Start the game and see."
            # Remember this, so the closing text further down does not
            # claim the film grain is still there.
            $grainRemoved = $true
        } else {
            Write-Info "Without the tool the files just sit there - they are here when you want them:"
            Write-Host "     $fgDir" -ForegroundColor Yellow
            Write-Host "  Get the tool at: $TFC_URL" -ForegroundColor Cyan
        }

    } else {
        Write-Info "Skipped - nothing was changed."
    }
} else {
    Write-Info "Skipped. You can run this installer again later."
}

Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " IN THE GAME" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
if ($doA) {
    Write-Host "  Halcyon: press Insert to open the menu, then the VR tab." -ForegroundColor White
    Write-Host "  Tune Eye Separation and Convergence until it sits right." -ForegroundColor White
    Write-Host "  Halcyon's known issue: light flares can pass through walls." -ForegroundColor Gray
}
if ($doB) {
    Write-Host "  Hammerthis: use its launcher under _vrmods\VRLaunch." -ForegroundColor White
    Write-Host "  Its settings are in the active Binaries\Win64\outlastvr.ini." -ForegroundColor White
}
Write-Host "  Turn motion blur OFF in Outlast's own settings." -ForegroundColor White
Write-Host ""
if ($grainRemoved) {
    Write-Host "  Outlast has film grain baked in - but you just removed it" -ForegroundColor Gray
    Write-Host "  with the Remove Film Grain mod, so that one is handled." -ForegroundColor Gray
} else {
    Write-Host "  Outlast also has film grain baked in. Run this installer" -ForegroundColor Gray
    Write-Host "  again if you want to remove it - it is the last step." -ForegroundColor Gray
}
Write-Host ""
Write-Host "  You are not armed. You never were. Now you can look behind you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
