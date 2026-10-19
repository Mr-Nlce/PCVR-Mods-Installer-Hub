# ============================================================
#  theHunter: Call of the Wild VR - by Vaas993
# ------------------------------------------------------------
#  A SIMPLE FLOW, BUT WITH TWO SPECIAL CASES:
#  1. The mod brings its OWN settings program under "VR Settings".
#     The complete folder must stay together because the executable
#     depends on its adjacent _internal Python runtime.
#  2. It is built against GAME VERSION 9.2 and identifies the game
#     by fingerprint. On a newer game build it does NOT start at
#     all and does not guess either - that is the author's
#     intention and the most common "nothing happens" case.
#
#  STEAM ONLY. Other editions are not supported.
# ============================================================

param(
    [switch]$ElevatedCopy,
    [string]$CopySource,
    [string]$CopyDestination
)

. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "theHunter Call of the Wild VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers.
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
    [void](Wait-PCVRExplicitEnter -Message $text)
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

$GAME_NAME   = "theHunter: Call of the Wild"
$APP_ID      = "518790"
$GAME_EXE    = "theHunterCotW_F.exe"
$MOD_NAME    = "theHunterCotW-VR"
$MOD_AUTHOR  = "Vaas993"
$REPO        = "vaas993/theHunterCotW-VR"
$RELEASES    = "https://github.com/$REPO/releases"
$SETTINGS_EXE = "theHunterCotW VR Settings.exe"
$SETTINGS_REL = "VR Settings\$SETTINGS_EXE"
$DEPOT_BUILD = '23311888'
$DEPOT_ID = '518791'
$DEPOT_MANIFEST = '6760390524926456616'
$DEPOT_COMMAND = "download_depot $APP_ID $DEPOT_ID $DEPOT_MANIFEST"
$DEPOT_PATH = 'C:\Games\theHunterCotW VR 9.2'
$DEPOT_MARKER = '.pcvrhub_hunter_depot_23311888'
$DEPOT_MOD_VERSION = 'v1.3.1'
$DEPOT_MOD_URL = 'https://github.com/vaas993/theHunterCotW-VR/releases/download/v1.3.1/theHunterCotW-VR-v1.3.1.zip'
$CURRENT_FALLBACK_VERSION = 'v1.4.1'
$CURRENT_FALLBACK_URL = 'https://github.com/vaas993/theHunterCotW-VR/releases/download/v1.4.1/theHunterCotW-VR-v1.4.1.zip'

function Get-HunterCurrentCompatibility {
    param([string]$GameRoot)
    if (-not $GameRoot -or -not (Test-Path -LiteralPath (Join-Path $GameRoot $GAME_EXE) -PathType Leaf)) { return 'not found' }
    try {
        $common = Split-Path $GameRoot -Parent
        if ((Split-Path $common -Leaf) -ne 'common') { return 'unknown build' }
        $steamapps = Split-Path $common -Parent
        if ((Split-Path $steamapps -Leaf) -ne 'steamapps') { return 'unknown build' }
        $manifestPath = Join-Path $steamapps "appmanifest_$APP_ID.acf"
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop
        $build = [regex]::Match($manifest,'(?i)"buildid"\s*"([0-9]+)"').Groups[1].Value
        $depot = [regex]::Match($manifest,'(?is)"518791"\s*\{[^{}]*"manifest"\s*"([0-9]+)"').Groups[1].Value
        if ($build -eq $DEPOT_BUILD -and $depot -eq $DEPOT_MANIFEST) { return '9.2 supported' }
        if ($build -eq '25131233' -or $depot -eq '6922288050906191955') { return '9.3 supported by v1.4.1' }
        if ($build) { return "build $build not confirmed by publisher" }
    } catch {}
    return 'unknown build'
}

function Test-HunterDepotBase {
    param([string]$Root)
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
    foreach ($relative in @($GAME_EXE,'steam_api64.dll','versions.518791.txt','archives_win64\game0.arc')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    return $true
}

function Test-HunterCompletedDepot {
    param([string]$Root)
    if (-not (Test-HunterDepotBase $Root)) { return $false }
    $marker = Join-Path $Root $DEPOT_MARKER
    $appid = Join-Path $Root 'steam_appid.txt'
    $version = Join-Path $Root '.pcvrhub_version'
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf) -or
        -not (Test-Path -LiteralPath $appid -PathType Leaf) -or
        -not (Test-Path -LiteralPath $version -PathType Leaf)) { return $false }
    $expected = "AppId=$APP_ID`nDepotId=$DEPOT_ID`nManifest=$DEPOT_MANIFEST`nBuildId=$DEPOT_BUILD`nMod=$DEPOT_MOD_VERSION"
    try {
        if ((Get-Content -LiteralPath $marker -Raw).Trim() -ne $expected -or
            (Get-Content -LiteralPath $appid -Raw).Trim() -ne $APP_ID -or
            (Get-Content -LiteralPath $version -Raw).Trim() -ne $DEPOT_MOD_VERSION) { return $false }
        foreach ($relative in @('cotwvr.dll','XINPUT9_1_0.dll','openxr_loader.dll',$SETTINGS_REL,
            'VR Settings\_internal\base_library.zip','VR Settings\_internal\libcrypto-1_1.dll',
            'VR Settings\_internal\ucrtbase.dll','VR Settings\_internal\VCRUNTIME140.dll')) {
            if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
        }
        $python = @(Get-ChildItem -LiteralPath (Join-Path $Root 'VR Settings\_internal') -File -Filter 'python*.dll' -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '^python[0-9]+\.dll$' } | Select-Object -First 1)
        return ($python.Count -gt 0)
    } catch { return $false }
}

function Get-HunterDepotTarget {
    $candidates = @()
    $receipt = Join-Path $PSScriptRoot '.installed_path_depot'
    try { if (Test-Path -LiteralPath $receipt -PathType Leaf) { $candidates += (Get-Content -LiteralPath $receipt -Raw).Trim() } } catch {}
    try {
        $saved = Get-HubLocatedGameFolder -GameId 'thehunter-call-of-the-wild-vr' -ProbeFiles @($GAME_EXE) -StateNames @('installed_path_depot')
        if ($saved) { $candidates += $saved }
    } catch {}
    $candidates += $DEPOT_PATH
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-HunterCompletedDepot $candidate) { return $candidate }
    }
    return $null
}

function Get-HunterDepotSource {
    while ($true) {
        Write-Host ''
        Write-Host "  Steam will download game update 9.2, build $DEPOT_BUILD." -ForegroundColor White
        Write-Host "  This is a large game download. Keep the normal Steam game intact." -ForegroundColor Yellow
        Write-Host "  Exact command: $DEPOT_COMMAND" -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy the command and open Steam Console...')
        try { Set-Clipboard -Value $DEPOT_COMMAND -DeferManualFallback } catch {}
        [void](Open-PCVRSteamConsole)
        Show-PCVRClipboardManualFallback -Text $DEPOT_COMMAND
        Write-Host '  Paste the command into Steam Console and wait for Depot download complete.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'After that exact depot finishes, press Enter to find its files...')
        $found = Find-SteamDepotPath -AppId $APP_ID -DepotId $DEPOT_ID -GameExe $GAME_EXE
        if ($found -and (Test-HunterDepotBase $found)) { return $found }
        Write-Warn 'A complete depot folder was not found yet.'
        while ($true) {
            $answer = ([string](Read-Host '  [R]etry Steam, [M]anual depot folder, [C]ancel')).Trim().ToUpperInvariant()
            if ($answer -eq 'C') { return $null }
            if ($answer -eq 'R') { break }
            if ($answer -eq 'M') {
                $manual = ([string](Read-Host '  Full path to depot_518791')).Trim().Trim('"')
                if ($manual -and (Split-Path $manual -Leaf) -eq 'depot_518791' -and (Test-HunterDepotBase $manual)) { return $manual }
                Write-Warn 'That is not a complete depot_518791 folder.'
            }
        }
    }
}

function Initialize-HunterDepotGame {
    $completed = Get-HunterDepotTarget
    if ($completed) { Write-OK "Existing pinned 9.2 depot: $completed"; return $completed }
    $stageName = '.pcvrhub_hunter_depot_staging_23311888'
    $stageText = "AppId=$APP_ID`nDepotId=$DEPOT_ID`nManifest=$DEPOT_MANIFEST`nBuildId=$DEPOT_BUILD"
    while ($true) {
        Write-Host ''
        $target = Select-PCVRDepotInstallPath -DefaultPath $DEPOT_PATH
        if (-not [IO.Path]::IsPathRooted($target) -or $target -match '(?i)[\\/]steamapps[\\/]common[\\/]') {
            Write-Warn 'Choose a full path outside the normal Steam game folder.'; continue
        }
        $target = [IO.Path]::GetFullPath($target).TrimEnd([char[]]'\/')
        if (-not (Test-InstallerTargetWritable -TargetPath $target)) {
            Write-Warn 'That destination is not writable. Choose another folder.'; continue
        }
        if (Test-Path -LiteralPath $target -PathType Container) {
            $stage = Join-Path $target $stageName
            $ownedStage = $false
            try { $ownedStage = ((Get-Content -LiteralPath $stage -Raw -ErrorAction Stop).Trim() -eq $stageText) } catch {}
            if (-not $ownedStage -and @(Get-ChildItem -LiteralPath $target -Force -ErrorAction SilentlyContinue | Select-Object -First 1).Count -gt 0) {
                Write-Warn 'That folder already has unrelated contents. Choose an empty folder.'; continue
            }
            if ($ownedStage -and (Test-HunterDepotBase $target)) {
                Write-OK "Resuming the pinned depot at $target"
                return $target
            }
        }
        $source = Get-HunterDepotSource
        if (-not $source) { return $null }
        $source = [IO.Path]::GetFullPath($source).TrimEnd([char[]]'\/')
        if ((Split-Path $source -Leaf) -ne "depot_$DEPOT_ID" -or -not (Test-HunterDepotBase $source)) {
            Write-Fail 'Steam did not supply a complete matching depot folder.'; return $null
        }
        if ($source.Equals($target,[StringComparison]::OrdinalIgnoreCase) -or
            $target.StartsWith(($source+'\'),[StringComparison]::OrdinalIgnoreCase) -or
            $source.StartsWith(($target+'\'),[StringComparison]::OrdinalIgnoreCase)) {
            Write-Fail 'The depot source and destination must be separate folders.'; return $null
        }
        if (-not (Test-Path -LiteralPath $target -PathType Container) -and
            [IO.Path]::GetPathRoot($source).Equals([IO.Path]::GetPathRoot($target),[StringComparison]::OrdinalIgnoreCase)) {
            Move-Item -LiteralPath $source -Destination $target -ErrorAction Stop
        } else {
            if (-not (Test-Path -LiteralPath $target -PathType Container)) { [void][IO.Directory]::CreateDirectory($target) }
            [IO.File]::WriteAllText((Join-Path $target $stageName),$stageText,(New-Object Text.UTF8Encoding $false))
            [void](Copy-DirectoryTreeVerified -Source $source -Destination $target)
        }
        if (-not (Test-HunterDepotBase $target)) { throw 'The 9.2 depot copy is incomplete; rerun setup to resume.' }
        [IO.File]::WriteAllText((Join-Path $target $stageName),$stageText,(New-Object Text.UTF8Encoding $false))
        Write-OK "Pinned game build copied to $target"
        return $target
    }
}

function Install-TheHunterPayload {
    param(
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$DestinationRoot
    )

    if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $DestinationRoot -Force -ErrorAction Stop | Out-Null
    }

    # These are exactly the mod-owned runtime items named by the author's
    # uninstall instructions. Merge complete folders: copying only the
    # settings EXE strands it without VR Settings\_internal\python*.dll.
    foreach ($name in @('cotwvr.dll','XINPUT9_1_0.dll','openxr_loader.dll',
                         'nvngx_dlss.dll','cotwvr.ini','cotwvr_launcher.cfg')) {
        $source = Join-Path $SourceRoot $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }
        $target = Join-Path $DestinationRoot $name
        if ($name -ieq 'cotwvr.ini' -and (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
        if ((Get-Item -LiteralPath $target -Force -ErrorAction Stop).Length -ne
            (Get-Item -LiteralPath $source -Force -ErrorAction Stop).Length) {
            throw "Verification failed after copying '$name'."
        }
    }
    foreach ($name in @('VR Settings','cotwvr-nr')) {
        $source = Join-Path $SourceRoot $name
        if (Test-Path -LiteralPath $source -PathType Container) {
            Copy-DirectoryTreeVerified -Source $source -Destination (Join-Path $DestinationRoot $name)
        }
    }

    # Pre-v1.3 installs may leave a second copy of the settings EXE in the
    # game root. That copy looks valid but has no adjacent _internal runtime;
    # a saved launch override can keep starting it after the new install.
    # Remove it only when it is byte-identical to the complete nested copy.
    $oldLauncher = Join-Path $DestinationRoot $SETTINGS_EXE
    $newLauncher = Join-Path $DestinationRoot $SETTINGS_REL
    $oldRuntime = @(Get-ChildItem -LiteralPath (Join-Path $DestinationRoot '_internal') -Filter 'python*.dll' -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '^python[0-9]+\.dll$' } | Select-Object -First 1)
    if ((Test-Path -LiteralPath $oldLauncher -PathType Leaf) -and
        (Test-Path -LiteralPath $newLauncher -PathType Leaf) -and $oldRuntime.Count -eq 0) {
        $oldHash = (Get-FileHash -LiteralPath $oldLauncher -Algorithm SHA256 -ErrorAction Stop).Hash
        $newHash = (Get-FileHash -LiteralPath $newLauncher -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($oldHash -eq $newHash) { Remove-Item -LiteralPath $oldLauncher -Force -ErrorAction Stop }
    }
}

function Get-HunterSettingsTreeProblems {
    param([string]$SourceRoot,[string]$DestinationRoot)
    $sourceSettings = Join-Path $SourceRoot 'VR Settings'
    $destinationSettings = Join-Path $DestinationRoot 'VR Settings'
    if (-not (Test-Path -LiteralPath $sourceSettings -PathType Container)) { return @('VR Settings source folder') }
    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-ChildItem -LiteralPath $sourceSettings -File -Recurse -ErrorAction Stop)) {
        $relative = $file.FullName.Substring($sourceSettings.Length).TrimStart([char[]]'\/')
        $destination = Join-Path $destinationSettings $relative
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $problems.Add($relative)
            continue
        }
        try {
            $placed = Get-Item -LiteralPath $destination -ErrorAction Stop
            if ($placed.Length -ne $file.Length -or
                (Get-FileHash -LiteralPath $destination -Algorithm SHA256 -ErrorAction Stop).Hash -ne
                (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash) {
                $problems.Add($relative)
            }
        } catch { $problems.Add($relative) }
    }
    return @($problems)
}

# The same script performs only the protected copy when Windows starts it
# elevated. No second installer UI is shown in that helper process.
if ($ElevatedCopy) {
    try {
        if (-not $CopySource -or -not $CopyDestination) { throw 'Elevated copy paths are missing.' }
        Install-TheHunterPayload -SourceRoot $CopySource -DestinationRoot $CopyDestination
        exit 0
    } catch {
        [Console]::Error.WriteLine($_.Exception.Message)
        exit 1
    }
}

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " theHunter: Call of the Wild VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Real stereo VR: the world is drawn once per eye from the" -ForegroundColor White
Write-Host "  game's own camera. Your head turns the view, you can lean" -ForegroundColor White
Write-Host "  and step around inside it, and the weapon has depth." -ForegroundColor White
Write-Host ""
Write-Host "  Choose the normal Steam build or a separate pinned 9.2 depot." -ForegroundColor White
Write-Host ""
Write-Host "  Publisher v1.4.1 supports the September 2026 game update." -ForegroundColor White
Write-Host "  The depot stays on game 9.2 and VR mod v1.3.1." -ForegroundColor White
Write-Host "  Unconfirmed future game builds may still need a new mod." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Single player only - do not use it in multiplayer sessions." -ForegroundColor Gray
Write-Host "  No RTX card? You lose nothing: the mod brings its own" -ForegroundColor Gray
Write-Host "  per-eye smoothing for every other card. DLSS is optional." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice

$currentProbe = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('theHunterCotW') -ProbeExe $GAME_EXE -HubGameId 'thehunter-call-of-the-wild-vr'
$currentStatus = Get-HunterCurrentCompatibility -GameRoot $currentProbe
Write-Host "  [1] Current Steam game ($currentStatus)" -ForegroundColor Yellow
Write-Host '      Installs the newest publisher mod into the normal Steam copy.' -ForegroundColor Gray
Write-Host '      Publisher v1.4.1 supports the September 2026 game update.' -ForegroundColor Gray
Write-Host ''
Write-Host "  [2] Separate pinned game depot 9.2 (build $DEPOT_BUILD)" -ForegroundColor Green
Write-Host "      Default game folder: $DEPOT_PATH (or choose another)." -ForegroundColor Gray
Write-Host '      Steam downloads the pinned 9.2 game; this route keeps the' -ForegroundColor Gray
Write-Host '      publisher VR mod pinned to v1.3.1. The normal copy stays put.' -ForegroundColor Gray
Write-Host ''
$mode = ''
while ($mode -notin @('1','2','C')) {
    $mode = ([string](Read-Host '  Choose [1] Current, [2] Depot, [C] Cancel')).Trim().ToUpperInvariant()
}
if ($mode -eq 'C') { Write-Info 'Setup cancelled before making changes.'; exit 0 }
$installMode = if ($mode -eq '2') { 'Depot' } else { 'Current' }

# ---- 1. Locate or prepare the selected game route ------------
Write-Step 1 5 $(if ($installMode -eq 'Depot') { 'Preparing the pinned 9.2 Steam depot' } else { "Locating $GAME_NAME" })
if ($installMode -eq 'Depot') {
    $gameDir = Initialize-HunterDepotGame
    if (-not $gameDir) { Write-Fail 'The depot was not completed.'; Pause-User 'Press Enter to exit.'; exit 1 }
} else {
    $gameDir = $currentProbe
}
if (-not $gameDir) {
    Write-Warn "Could not find the game automatically."
    Write-Host "  Point me at the folder that holds $GAME_EXE, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\theHunterCotW" -ForegroundColor Gray
    $gameDir = (Read-Host "  Game folder").Trim().Trim('"')
}
if (-not $gameDir -or -not (Test-Path -LiteralPath (Join-Path $gameDir $GAME_EXE))) {
    Write-Fail "No $GAME_EXE in that folder - stopping rather than guessing."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameDir"

# Probe write access quietly - the announcement comes where it applies.
$needsAdmin = $false
try {
    $probe = Join-Path $gameDir ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }

# ---- 2. Download ----------------------------------------------
# ---- 2. The game first, in flat mode ---------------------------
# Open the game flat first so the user can set the video options the
# mod requires.
Write-Step 2 5 "The game's own settings - do this first, flat"
Write-Host ""
Write-Host "  The game opens now, WITHOUT VR. In its VIDEO menu set:" -ForegroundColor White
Write-Host ""
Write-Host "        Anti-aliasing    FXAA + TAA " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Display mode     windowed   " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        V-Sync           off        " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Field of view    90         " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Motion blur      off        " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  FIELD OF VIEW 90 IS THE ONE THAT MATTERS MOST - 90 is the" -ForegroundColor Yellow
Write-Host "  game's maximum, and the mod builds its picture around it." -ForegroundColor White
Write-Host ""
Write-Host "  Then CLOSE the game and come back here." -ForegroundColor White
Write-Host ""
if (Read-YesNo "  Open the game now?") {
    Pause-User 'Press Enter to open the selected game in flat mode...' | Out-Null
    try { Start-Process -FilePath (Join-Path $gameDir $GAME_EXE) -WorkingDirectory $gameDir }
    catch { Write-Warn "Could not start it - open it from Steam instead." }
    Pause-User "Press Enter when the game is CLOSED again..." | Out-Null
} else {
    Write-Info "Skipped - but the five settings above still have to be set."
}

Write-Step 3 5 "Downloading $MOD_NAME"

$tmp = Join-Path $env:TEMP ("cotwvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "theHunterCotW-VR.zip"

$url = $null; $tag = 'latest'
if ($installMode -eq 'Depot') {
    $url = $DEPOT_MOD_URL
    $tag = $DEPOT_MOD_VERSION
    Write-Info "Depot mod pinned to $tag; no live release resolver is used."
} else {
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
        if (Test-IsPayloadRelease -Release $rel) {
            # The release also carries a much smaller Source archive. Select only
            # the publisher's runtime package; never install a source bundle.
            $pick = $rel.assets | Where-Object {
                $_.name -match '(?i)^theHunterCotW-VR-v[^/]+\.zip$' -and
                $_.name -notmatch '(?i)source'
            } | Select-Object -First 1
            if ($pick -and $pick.browser_download_url) {
                $url = [string]$pick.browser_download_url
                $tag = [string]$rel.tag_name
            }
        }
        if ($url) { Write-OK "Release: $tag" }
    } catch { Write-Warn "GitHub could not be reached - trying the direct link." }
    if (-not $url) {
        $url = $CURRENT_FALLBACK_URL
        $tag = $CURRENT_FALLBACK_VERSION
    }
}

Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
    -ManualUrl $RELEASES `
    -Instructions "Download the theHunterCotW-VR zip from the releases page, save it as '$zip', then choose Retry."
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No archive - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 4. Put the files in place --------------------------------
Write-Step 4 5 "Extracting and copying the VR mod files"
Write-Host ""
Write-Host "  The VR mod archive will now be extracted and its files" -ForegroundColor White
Write-Host "  copied into the game folder beside $GAME_EXE." -ForegroundColor White
Write-Host "  Windows may show a UAC prompt for PowerShell so the Hub can" -ForegroundColor Yellow
Write-Host "  write there. Approve it to complete the installation." -ForegroundColor Yellow
Pause-User "Press Enter to extract and copy the VR mod files..." | Out-Null

$ex = Join-Path $tmp "x"
New-Item -ItemType Directory -Path $ex -Force | Out-Null
[void](Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ex -Label $MOD_NAME)

# Allow one harmless wrapper folder, but require only files that are actually
# needed to run the mod and its settings application. No historical size,
# filename-version or content identity is used as a download gate.
$payloadRoot = Get-ChildItem -LiteralPath $ex -Filter 'cotwvr.dll' -File -Recurse -ErrorAction SilentlyContinue |
               ForEach-Object { $_.DirectoryName } |
               Where-Object { Test-Path -LiteralPath (Join-Path $_ $SETTINGS_REL) -PathType Leaf } |
               Select-Object -First 1
if (-not $payloadRoot) {
    Write-Fail "The extracted release does not contain the VR runtime and its complete settings folder."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$settingsInternal = Join-Path $payloadRoot 'VR Settings\_internal'
$pythonRuntime = Get-ChildItem -LiteralPath $settingsInternal -Filter 'python*.dll' -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -match '^python[0-9]+\.dll$' } |
                 Select-Object -First 1
$settingsSupport = @('VR Settings\_internal\base_library.zip','VR Settings\_internal\libcrypto-1_1.dll',
                     'VR Settings\_internal\ucrtbase.dll','VR Settings\_internal\VCRUNTIME140.dll')
$sourceRequired = @('cotwvr.dll','XINPUT9_1_0.dll','openxr_loader.dll',$SETTINGS_REL) + $settingsSupport
$sourceMissing = @($sourceRequired | Where-Object { -not (Test-Path -LiteralPath (Join-Path $payloadRoot $_) -PathType Leaf) })
if (-not $pythonRuntime) { $sourceMissing += 'VR Settings\_internal\python*.dll' }
if ($sourceMissing.Count -gt 0) {
    Write-Fail "The publisher package is missing required runtime files:"
    foreach ($m in $sourceMissing) { Write-Host "   $m" -ForegroundColor Yellow }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

$preservedIni = Test-Path -LiteralPath (Join-Path $gameDir 'cotwvr.ini') -PathType Leaf
$copyFailed = $needsAdmin
if (-not $copyFailed) {
    try { Install-TheHunterPayload -SourceRoot $payloadRoot -DestinationRoot $gameDir }
    catch { $copyFailed = $true }
}
if ($copyFailed) {
    Write-Warn "Copying into that folder needs administrator rights. Asking for them ..."
    try {
        $copyProcess = Start-Process powershell.exe -ArgumentList @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",
            '-ElevatedCopy','-CopySource',"`"$payloadRoot`"",
            '-CopyDestination',"`"$gameDir`""
        ) -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
        $copyFailed = ($copyProcess.ExitCode -ne 0)
    } catch { $copyFailed = $true }
    if ($copyFailed) { Write-Warn "The elevated copy was declined or failed." }
}

# The settings executable is not standalone. Its adjacent Python runtime is a
# load-bearing part of the v1.3.1 layout and is verified at the destination.
$pythonRelative = $pythonRuntime.FullName.Substring($payloadRoot.Length).TrimStart('\')
$core = @('cotwvr.dll','XINPUT9_1_0.dll','openxr_loader.dll',$SETTINGS_REL,$pythonRelative) + $settingsSupport
$missing = @($core | Where-Object { -not (Test-Path -LiteralPath (Join-Path $gameDir $_)) })

# BEFORE THE TEMP FOLDER GOES. A scanner usually sweeps a moment after
# the write, so the files can vanish right after this check passes - and
# the recovery needs the archive, which the cleanup below deletes.
if ($missing.Count -eq 0) {
    $avFilesOk = Confirm-PlacedFilesSurvive `
        -Paths @($core | ForEach-Object { Join-Path $gameDir $_ }) `
        -GameDir $gameDir `
        -ArchivePath $zip
    if (-not $avFilesOk) {
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Write-Fail "theHunter VR could not be restored after the antivirus check."
        Pause-User "Press Enter to exit, then run the installer again."
        exit 1
    }
}

# A valid Python DLL alone cannot prove that the bundled settings app can
# load. Compare the entire live publisher settings tree before committing a
# receipt; retry the staged source in this window if a file was lost.
$treeProblems = @(Get-HunterSettingsTreeProblems -SourceRoot $payloadRoot -DestinationRoot $gameDir)
while ($missing.Count -gt 0 -or $treeProblems.Count -gt 0) {
    Write-Fail 'The settings runtime is incomplete in the game folder.'
    foreach ($problem in @($missing + $treeProblems | Select-Object -Unique -First 12)) {
        Write-Host "   $problem" -ForegroundColor Yellow
    }
    if (($missing.Count + $treeProblems.Count) -gt 12) { Write-Host '   ...more files are missing or differ.' -ForegroundColor Yellow }
    Write-Host '  This can be a copy, path, rights or external-removal problem.' -ForegroundColor White
    $repair = ([string](Read-Host '  [R]etry copy, [O]pen game folder, [C]ancel')).Trim().ToUpperInvariant()
    if ($repair -eq 'O') { try { Start-Process explorer.exe -ArgumentList @($gameDir) } catch {}; continue }
    if ($repair -eq 'C') {
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        exit 1
    }
    if ($repair -ne 'R') { continue }
    try { Install-TheHunterPayload -SourceRoot $payloadRoot -DestinationRoot $gameDir }
    catch {
        Write-Warn ('Direct copy failed: ' + $_.Exception.Message)
        try {
            $retryProcess = Start-Process powershell.exe -ArgumentList @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",
                '-ElevatedCopy','-CopySource',"`"$payloadRoot`"",'-CopyDestination',"`"$gameDir`""
            ) -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
            if ($retryProcess.ExitCode -ne 0) { Write-Warn 'Elevated retry failed or was declined.' }
        } catch { Write-Warn ('Elevated retry failed: ' + $_.Exception.Message) }
    }
    $missing = @($core | Where-Object { -not (Test-Path -LiteralPath (Join-Path $gameDir $_) -PathType Leaf) })
    $treeProblems = @(Get-HunterSettingsTreeProblems -SourceRoot $payloadRoot -DestinationRoot $gameDir)
}

try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if ($missing.Count -gt 0) {
    Write-Fail "These files did not arrive:"
    foreach ($m in $missing) { Write-Host "   $m" -ForegroundColor Yellow }
    Write-Host "  Copy every file from the zip by hand into:" -ForegroundColor White
    Write-Host "     $gameDir" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Files are in place."
if ($preservedIni) { Write-Info "Your existing cotwvr.ini settings were preserved." }

# Commit each route only after its own game, mod and settings-runtime proof.
# The depot marker is tied to the fixed Steam manifest and mod release; the
# current route remains independent and may follow later publisher releases.
try {
    if ($installMode -eq 'Depot') {
        if (-not (Test-HunterDepotBase $gameDir) -or $tag -ne $DEPOT_MOD_VERSION) {
            throw 'The pinned depot game or mod version is incomplete.'
        }
        [IO.File]::WriteAllText((Join-Path $gameDir 'steam_appid.txt'),$APP_ID,[Text.Encoding]::ASCII)
        $depotText = "AppId=$APP_ID`nDepotId=$DEPOT_ID`nManifest=$DEPOT_MANIFEST`nBuildId=$DEPOT_BUILD`nMod=$DEPOT_MOD_VERSION"
        [IO.File]::WriteAllText((Join-Path $gameDir $DEPOT_MARKER),$depotText,(New-Object Text.UTF8Encoding $false))
    }
    $required = @($GAME_EXE,'cotwvr.dll','XINPUT9_1_0.dll','openxr_loader.dll',$SETTINGS_REL,$pythonRelative) + $settingsSupport
    if ($installMode -eq 'Depot') { $required += @('steam_appid.txt',$DEPOT_MARKER,'archives_win64\game0.arc','versions.518791.txt') }
    $contract = New-PCVRInstallerContract -Id 'thehunter-call-of-the-wild-vr' `
        -GameName 'theHunter: Call of the Wild VR' `
        -Acquisition $(if ($installMode -eq 'Depot') { 'SteamDepot' } else { 'GitHub' }) `
        -Routes @($installMode) -RequiredInstalledFileGroups $required `
        -ReleasePageUrl $RELEASES -AntivirusNotice `
        -PinnedDepot:($installMode -eq 'Depot')
    $pathReceipt = Join-Path $PSScriptRoot $(if ($installMode -eq 'Depot') { '.installed_path_depot' } else { '.installed_path' })
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gameDir -Version $tag `
        -InstalledPathReceiptPaths @($pathReceipt) -Route $installMode)
    $versionReceipt = Join-Path $PSScriptRoot $(if ($installMode -eq 'Depot') { '.installed_version_depot' } else { '.installed_version' })
    try { Set-Content -LiteralPath $versionReceipt -Value $tag -Encoding UTF8 -Force } catch {}
    [void](Save-HubRememberedGameFolder -GameId 'thehunter-call-of-the-wild-vr' `
        -Title 'theHunter: Call of the Wild VR' -GameDir $gameDir -ProbeFiles @($GAME_EXE) `
        -StateName $(if ($installMode -eq 'Depot') { 'installed_path_depot' } else { 'installed_path' }))
    if ($installMode -eq 'Depot') {
        Remove-Item -LiteralPath (Join-Path $gameDir '.pcvrhub_hunter_depot_staging_23311888') -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Fail "The selected route was not committed: $($_.Exception.Message)"
    Pause-User 'Press Enter to exit; rerun setup to recover.'
    exit 1
}

# ---- 5. The mod's settings program ----------------------------
Write-Step 5 5 "Setting it up"
Write-Host ""
Write-Host "  The mod brings its own settings program, and it has to run" -ForegroundColor White
Write-Host "  once - the copied files alone do not configure anything." -ForegroundColor White
Write-Host ""
Write-Host "  Set these options:" -ForegroundColor White
Write-Host "   a) Field of View > Field of View given to the game: " -NoNewline -ForegroundColor White
Write-Host " 90 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " (the game's maximum)" -ForegroundColor White
Write-Host ""
Write-Host "   b) Picture > Anti-aliasing: try the available settings." -ForegroundColor White
Write-Host "      If one causes a black screen, set it to " -NoNewline -ForegroundColor Yellow
Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "      The game will use its own DLSS instead." -ForegroundColor White
Write-Host ""
Write-Host "   c) Head tracking mode: " -NoNewline -ForegroundColor White
Write-Host " 6-DoF " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "      That is the one that lets you lean and step around." -ForegroundColor White
Write-Host ""
Write-Host "   d) Then click " -NoNewline -ForegroundColor White
Write-Host " Save " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " and accept the notice regarding the config file." -ForegroundColor White
Write-Host "      Afterwards close the launcher and press Enter." -ForegroundColor White
Write-Host ""
$settingsPath = Join-Path $gameDir $SETTINGS_REL
if (Read-YesNo "  Open the settings program now?") {
    try { Start-Process -FilePath $settingsPath -WorkingDirectory (Split-Path $settingsPath -Parent) }
    catch { Write-Warn "Could not start it: $($_.Exception.Message)" }
    # THE GATE SITS HERE SO THE FIVE POINTS ABOVE STAY ON SCREEN for
    # as long as the user needs them. Only after the Enter does the
    # rest of the text follow - otherwise the instructions scroll away
    # while they are still working through them.
    Pause-User "Launcher closed? Press Enter to continue..." | Out-Null
} else {
    Write-Info "You can open it any time - Start in VR in the Hub opens it too."
}

Write-Host ""
Write-Host "  From now on, Start in VR in the Hub opens this program so" -ForegroundColor Gray
Write-Host "  you can change options." -ForegroundColor Gray

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host "  STARTING AND PLAYING" -ForegroundColor Cyan
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Start the game the way you always do - and PUT THE HEADSET" -ForegroundColor White
Write-Host "  ON BEFORE IT FINISHES LOADING." -ForegroundColor Yellow
Write-Host ""
Write-Host "   Insert        open the settings panel in the headset" -ForegroundColor White
Write-Host "   Pause         recentre - use it whenever forward stops" -ForegroundColor White
Write-Host "                 being forward" -ForegroundColor White
Write-Host "   Delete        show the flat game screen, for menus and map" -ForegroundColor White
Write-Host "   Alt (held)    free look - the view turns, the weapon stays" -ForegroundColor White
Write-Host ""
Write-Host "  Everything is rebindable in the panel, and the panel works" -ForegroundColor Gray
Write-Host "  with a gamepad. A gamepad plays better than mouse and" -ForegroundColor Gray
Write-Host "  keyboard here." -ForegroundColor Gray
Write-Host ""
Write-Host "  BLACK IN THE HEADSET, GAME FINE ON THE MONITOR?" -ForegroundColor Yellow
Write-Host "   1. Try Picture > Anti-aliasing modes; if one causes this," -ForegroundColor White
Write-Host "      set it to Off. The game will use its own DLSS instead." -ForegroundColor White
Write-Host "   2. Turn HDR off in Windows: press Win+Alt+B" -ForegroundColor White
Write-Host "      Windows 11: Settings > System > Display > Use HDR" -ForegroundColor Cyan
Write-Host "      Windows 10: Settings > System > Display > Windows HD Color" -ForegroundColor Cyan
Write-Host "  Still black? Check the log:" -ForegroundColor Gray
Write-Host "     %LOCALAPPDATA%\theHunterCotWVR\cotwvr.log" -ForegroundColor Cyan
Write-Host ""
Write-Host "  A bad shot in VR still counts. The elk knows." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
