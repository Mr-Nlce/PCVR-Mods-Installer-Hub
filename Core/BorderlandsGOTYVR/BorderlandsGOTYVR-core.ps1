# Borderlands GOTY Enhanced VR - safe stable-channel installer.
# Downloads are acquired at run time. No VR-mod archive is bundled with the Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Borderlands GOTY Enhanced VR Installer'
$APP_ID = '729040'
$GAME_EXE = 'Binaries\Win64\BorderlandsGOTY.exe'
$BIN_REL = 'Binaries\Win64'
$MOD_NAME = 'BL1GOTYVR'
$MOD_AUTHOR = 'Mastersellz'
$REPO = 'Mastersellz/BL1GOTYVR'
$RELEASES_URL = "https://github.com/$REPO/releases"
$PIN_TAG = 'BL1GOTYVR_V0.5.6.5'
$PIN_NAME = 'BL1GOTYVR.V0.5.6.5.zip'
$PIN_URL = "https://github.com/$REPO/releases/download/$PIN_TAG/$PIN_NAME"
$IDENTITY = 'borderlandsgotyenhancedvr'
$QUIP = 'The vault was full of guns. Marcus still sold you another.'

function Write-Header {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' Borderlands GOTY Enhanced VR - Installer' -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!!] $Text" -ForegroundColor Yellow }
function Pause-User { param([string]$Text='Press Enter to continue...') Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }

function Test-GameRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function Test-BL1FirstRunReady {
    param([string]$DocumentsPath = [Environment]::GetFolderPath('MyDocuments'))
    if (-not $DocumentsPath) { return $false }
    foreach ($folder in @('Borderlands Game of the Year','Borderlands Game of the Year Enhanced')) {
        $configDir = Join-Path $DocumentsPath ("My Games\$folder\WillowGame\Config")
        if ((Test-Path -LiteralPath (Join-Path $configDir 'WillowEngine.ini') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $configDir 'WillowGame.ini') -PathType Leaf)) {
            return $true
        }
    }
    return $false
}

function Set-BL1IniValue {
    param([string]$Path,[string]$Name,[string]$Value)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Cannot update missing configuration: $Path" }
    $text = [IO.File]::ReadAllText($Path)
    $line = "$Name=$Value"
    $pattern = '(?m)^\s*' + [regex]::Escape($Name) + '\s*=.*$'
    if ($text -match $pattern) { $text = [regex]::Replace($text,$pattern,$line) }
    else { $text = $text.TrimEnd() + "`r`n$line`r`n" }
    [IO.File]::WriteAllText($Path,$text,(New-Object Text.UTF8Encoding($false)))
}

function Test-BL1IncompleteOpenXRStart {
    param([string]$Bin,[string]$IniPath)
    try {
        if (-not (Test-Path -LiteralPath $IniPath -PathType Leaf)) { return $false }
        $ini = [IO.File]::ReadAllText($IniPath)
        if ($ini -notmatch '(?m)^\s*SameFrameStereo\s*=\s*1\s*$') { return $false }
        $logPath = Join-Path $Bin 'BL1GOTYVR.log'
        if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) { return $false }
        $log = [IO.File]::ReadAllText($logPath)
        return ($log -match '\[BL1GOTYVR\] OpenXR will initialize on first Present' -and
                $log -notmatch '\[OpenXR\] Initializing\.\.\.')
    } catch { return $false }
}

function Get-ArchiveInputFolders {
    try {
        $workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        return @(
            (Join-Path $workspace 'Archive Input\Borderlands GOTY Enhanced'),
            (Join-Path $workspace 'Archive Input\Neue Spiele')
        )
    } catch { return @() }
}

function Get-LatestStableRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -Headers @{'User-Agent'='PCVR-Mods-Hub';'Accept'='application/vnd.github+json'} -TimeoutSec 25 -ErrorAction Stop
        if (-not $release.draft -and -not $release.prerelease) {
            $asset = @($release.assets | Where-Object { $_.name -match '^BL1GOTYVR.*\.zip$' } | Select-Object -First 1)[0]
            if ($asset) {
                return [pscustomobject]@{
                    Tag = [string]$release.tag_name
                    Name = [string]$asset.name
                    Url = [string]$asset.browser_download_url
                }
            }
        }
    } catch { Write-Warn 'GitHub release lookup failed; using the last known stable asset URL.' }
    return [pscustomobject]@{ Tag=$PIN_TAG; Name=$PIN_NAME; Url=$PIN_URL }
}

function Get-ReleaseArchive([string]$Destination,$Release) {
    $found = Find-PredownloadedFile -Patterns @([string]$Release.Name,'BL1GOTYVR*.zip') `
        -ExtraFolders (Get-ArchiveInputFolders) -Label "BL1GOTYVR $($Release.Tag)"
    if ($found) { Copy-Item -LiteralPath $found -Destination $Destination -Force; return $Destination }
    $ok = Invoke-SafeDownload -Urls @([string]$Release.Url) -Destination $Destination -Label "BL1GOTYVR $($Release.Tag)" `
        -ManualUrl $RELEASES_URL -AllowSkip $false
    if ($ok -eq $true -or [string]$ok -in @('retry','manual')) { return $Destination }
    return $null
}

function Restore-FlatChoice([string]$Bin,[bool]$WasFlat) {
    if (-not $WasFlat -or -not $Bin) { return }
    $live = Join-Path $Bin 'dxgi.dll'
    $parked = Join-Path $Bin 'dxgi.dll.pcvrhub_off'
    if ((Test-Path -LiteralPath $live -PathType Leaf) -and -not (Test-Path -LiteralPath $parked)) {
        Rename-Item -LiteralPath $live -NewName 'dxgi.dll.pcvrhub_off' -ErrorAction Stop
    }
}

$work = $null
$gamePath = $null
$binPath = $null
$restoreFlat = $false
try {
    Write-Header
    Write-Host ' This setup is only for Borderlands GOTY Enhanced (2019).' -ForegroundColor White
    Write-Host ' The original 2009 Borderlands release is not compatible.' -ForegroundColor Yellow
    Write-Host ' It downloads the current stable GitHub release and keeps' -ForegroundColor White
    Write-Host ' existing VR settings and replaced files recoverable.' -ForegroundColor White
    Write-Host ''
    Write-Host ' IMPORTANT: Start the game in Flat mode once, reach the main' -ForegroundColor Yellow
    Write-Host ' menu, then close it before setup. This creates the required' -ForegroundColor Yellow
    Write-Host ' Willow configuration files.' -ForegroundColor Yellow
    Write-Host ' Stable alternate-eye stereo is used first; experimental' -ForegroundColor Gray
    Write-Host ' same-frame stereo can be enabled later in the configurator.' -ForegroundColor Gray
    Write-Host ' After installation, setup opens the VR configurator and' -ForegroundColor Gray
    Write-Host ' waits while you choose and save a render preset.' -ForegroundColor Gray
    Show-AntivirusNotice -Compact
    Pause-User 'Press Enter to proceed with setup...'

    Write-Step 1 5 'Locating Borderlands GOTY Enhanced'
    $gamePath = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('BorderlandsGOTYEnhanced') -ProbeExe $GAME_EXE -HubGameId 'borderlands-goty-enhanced'
    if (-not (Test-GameRoot $gamePath)) {
        $picked = Get-GameFolderInteractive -GameName 'Borderlands GOTY Enhanced' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/729040/'
        if ($picked -in @('quit','skip',$null) -or -not (Test-GameRoot $picked)) { throw 'Setup cancelled before any game file was changed.' }
        $gamePath = (Get-Item -LiteralPath $picked).FullName
    }
    if (@(Get-Process -Name 'BorderlandsGOTY' -ErrorAction SilentlyContinue).Count) { throw 'Borderlands GOTY Enhanced is running. Close it completely and run setup again.' }
    if (-not (Test-BL1FirstRunReady)) {
        throw 'Required game configuration is missing. Start Borderlands GOTY Enhanced in Flat mode, reach the main menu, close it, then run setup again. No game file was changed.'
    }
    $binPath = Join-Path $gamePath $BIN_REL
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$gamePath,(New-Object Text.UTF8Encoding($false)))
    Write-OK "Found: $gamePath"

    Write-Step 2 5 'Getting the current stable VR release'
    $release = Get-LatestStableRelease
    Write-Info "Stable release: $($release.Tag)"
    $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_bl1goty_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $archive = Get-ReleaseArchive -Destination (Join-Path $work ([string]$release.Name)) -Release $release
    if (-not $archive) { throw 'Could not acquire the BL1GOTYVR release.' }

    Write-Step 3 5 'Validating and installing with recovery data'
    $extract = Join-Path $work 'payload'
    $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'BL1GOTYVR archive' -AllowSkip $false
    if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The BL1GOTYVR archive was not extracted.' }
    $payload = Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'BL1GOTYVR.dll'
    foreach ($required in @('BL1GOTYVR.dll','BL1GOTYVR.ini','BL1GOTYVRConfig.exe','dxgi.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $payload $required) -PathType Leaf)) { throw "Release is incomplete: missing $required" }
    }
    $fileCount = @(Get-ChildItem -LiteralPath $payload -Recurse -File).Count
    if ($fileCount -lt 4 -or $fileCount -gt 20) { throw "Unexpected release layout ($fileCount files)." }

    $liveProxy = Join-Path $binPath 'dxgi.dll'
    $parkedProxy = Join-Path $binPath 'dxgi.dll.pcvrhub_off'
    if ((Test-Path -LiteralPath $liveProxy) -and (Test-Path -LiteralPath $parkedProxy)) { throw 'Both active and parked dxgi.dll copies exist. Resolve the duplicate before updating.' }
    if (-not (Test-Path -LiteralPath $liveProxy) -and (Test-Path -LiteralPath $parkedProxy)) {
        Rename-Item -LiteralPath $parkedProxy -NewName 'dxgi.dll' -ErrorAction Stop
        $restoreFlat = $true
        Write-Info 'Your parked VR proxy was enabled temporarily for the update.'
    }

    $iniSource = Join-Path $payload 'BL1GOTYVR.ini'
    $iniTarget = Join-Path $binPath 'BL1GOTYVR.ini'
    $recoverExperimentalStart = Test-BL1IncompleteOpenXRStart -Bin $binPath -IniPath $iniTarget
    if (-not (Test-Path -LiteralPath $iniTarget -PathType Leaf)) {
        Merge-PathItemVerified -Source $iniSource -Destination $iniTarget -Label 'default BL1GOTYVR configuration' | Out-Null
        Set-BL1IniValue -Path $iniTarget -Name 'SameFrameStereo' -Value '0'
        Write-OK 'Stable alternate-eye stereo selected for the first launch.'
    } elseif ($recoverExperimentalStart) {
        $settingsBackupDir = Join-Path $binPath '.pcvrhub_borderlandsgotyenhancedvr_user_backup'
        $settingsBackup = Join-Path $settingsBackupDir 'BL1GOTYVR.ini.before-safe-start'
        if (-not (Test-Path -LiteralPath $settingsBackup -PathType Leaf)) {
            New-Item -ItemType Directory -Path $settingsBackupDir -Force | Out-Null
            Copy-Item -LiteralPath $iniTarget -Destination $settingsBackup -Force -ErrorAction Stop
        }
        Set-BL1IniValue -Path $iniTarget -Name 'SameFrameStereo' -Value '0'
        Write-Warn 'The previous run stopped before OpenXR initialized. Experimental same-frame stereo was disabled; your prior INI was backed up.'
    } else { Write-OK 'Existing BL1GOTYVR.ini preserved.' }
    Install-OwnedModPayload -SourceRoot $payload -GameRoot $binPath -Identity $IDENTITY -SkipRelativePaths @('BL1GOTYVR.ini') | Out-Null

    Write-Step 4 5 'Verifying the installed files'
    $watch = @('BL1GOTYVR.dll','BL1GOTYVRConfig.exe','dxgi.dll') | ForEach-Object { Join-Path $binPath $_ }
    foreach ($path in $watch) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Installation verification failed: $(Split-Path -Leaf $path) is missing." } }
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $binPath -ArchivePath $archive)) { throw 'One or more required VR binaries did not survive the antivirus check.' }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),([string]$release.Tag),(New-Object Text.UTF8Encoding($false)))
    Save-InstalledStamp -GameDir $gamePath -Version ([string]$release.Tag) -HubDir $PSScriptRoot
    if ($restoreFlat) { Restore-FlatChoice -Bin $binPath -WasFlat $true; $restoreFlat = $false; Write-Info 'Your previous Flat mode was preserved.' }
    Write-OK "BL1GOTYVR $($release.Tag) is installed and detected as VR Ready."

    Write-Step 5 5 'Choosing VR render settings'
    $configTool = Join-Path $binPath 'BL1GOTYVRConfig.exe'
    Write-Host ' Keep this installer open while using the VR config tool.' -ForegroundColor White
    Write-Host ' Under Render Options, choose Low, Medium, High, Ultra or' -ForegroundColor White
    Write-Host ' Mega to suit your PC, then press Save Settings.' -ForegroundColor White
    Write-Host ' Keep Same-frame stereo OFF for the first VR launch.' -ForegroundColor Gray
    Write-Host ''
    Pause-User 'Press Enter to open the VR config tool...'
    try {
        Start-Process -FilePath $configTool -WorkingDirectory $binPath -ErrorAction Stop | Out-Null
        Write-Info 'The VR config tool is open. This installer will keep waiting.'
    } catch {
        Write-Warn 'The VR config tool could not be opened automatically.'
        Write-Host "  Open this file manually: $configTool" -ForegroundColor DarkGray
    }
    Pause-User 'After choosing a render preset and pressing Save Settings, return here and press Enter...'

    Write-Host ''
    Write-Host ' FIRST VR TEST' -ForegroundColor Cyan
    Write-Host ' Start the game now with the render preset you saved.' -ForegroundColor White
    Write-Host ' Set one OpenXR runtime, then use Start in VR in the Hub' -ForegroundColor White
    Write-Host ' or launch through Steam. Virtual Desktop users select VDXR' -ForegroundColor Gray
    Write-Host ' and leave SteamVR closed.' -ForegroundColor Gray
    Write-Host ''
    Write-Warn 'If the two headset images sit too far apart, reopen the'
    Write-Warn 'config tool and lower Convergence Shift. Although 10.0 is'
    Write-Warn 'labelled recommended, 1.0 or lower may fit much better.'
    Write-Host ''
    Write-Host " $QUIP" -ForegroundColor Magenta
} catch {
    Write-Host ''
    Write-Host " [X] $($_.Exception.Message)" -ForegroundColor Red
    throw
} finally {
    if ($restoreFlat -and $binPath) {
        try { Restore-FlatChoice -Bin $binPath -WasFlat $true } catch { Write-Warn 'Setup could not restore the parked Flat mode; use the Hub Flat / VR switch after reviewing the two proxy files.' }
    }
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Pause-User 'Press Enter to exit...'
