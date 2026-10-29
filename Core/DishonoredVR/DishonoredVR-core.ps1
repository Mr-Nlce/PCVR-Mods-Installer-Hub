param([switch]$Manage)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot 'DishonoredMigration.ps1')
try { $Host.UI.RawUI.WindowTitle = 'Dishonored VR Installer' } catch {}

$releasePage = 'https://github.com/VR-Stereo-Hub/Dishonored-VR/releases'
$gameProbe = 'Binaries\Win32\Dishonored.exe'
$recordName = 'Binaries\Win32\dishonored_vr_install.json'
$legacyRecord = '.pcvrhub-dishonored-install.tsv'

function Pause-DishonoredEnter([string]$Message) {
    Start-Sleep -Milliseconds 200
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    Write-Host "`n  $Message" -ForegroundColor Cyan
    try { do { $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } while ($key.VirtualKeyCode -ne 13) }
    catch { [void](Read-Host '[Enter]') }
}
function Write-DishonoredHeader {
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ' Dishonored VR Installer' -ForegroundColor Cyan
    Write-Host ' VR-Stereo-Hub release for Steam and GOG Galaxy' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function Write-DishonoredStep([int]$Number,[string]$Label) {
    Write-Host ''
    Write-Host "  [$Number/4] $Label" -ForegroundColor Cyan
    Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
}
function Test-DishonoredGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-PathLexical $Root 'Binaries\Win32\Dishonored.exe') -PathType Leaf))
}
function Get-DishonoredPublisherProof([string]$Root) {
    if (-not (Test-DishonoredGame $Root)) { return $null }
    $bin = Join-PathLexical $Root 'Binaries\Win32'
    foreach ($name in @('d3d9.dll','dvr_steamvr32.dll','openvr_api.dll','dishonored_vr.ini','dishonored_vr_install.json')) {
        if (-not (Test-Path -LiteralPath (Join-PathLexical $bin $name) -PathType Leaf)) { return $null }
    }
    try {
        $record = Get-Content -LiteralPath (Join-PathLexical $bin 'dishonored_vr_install.json') -Raw -ErrorAction Stop | ConvertFrom-Json
        $version = (''+$record.version).Trim()
        if ($version -notmatch '^v?\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.-]+)?$') { return $null }
        $expected = (''+$record.d3d9Sha256).Trim()
        if ($expected -notmatch '^[0-9A-Fa-f]{64}$') { return $null }
        $actual = (Get-FileHash -LiteralPath (Join-PathLexical $bin 'd3d9.dll') -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($actual -ine $expected) { return $null }
        return ($version -replace '^v', '')
    } catch { return $null }
}
function Get-DishonoredSavedRoot {
    $saved = Join-PathLexical $PSScriptRoot '.installed_path'
    if (-not (Test-Path -LiteralPath $saved -PathType Leaf)) { return $null }
    try {
        $candidate = ([IO.File]::ReadAllText($saved)).Trim().Trim('"')
        if (Test-DishonoredGame $candidate) { return $candidate }
    } catch {}
    return $null
}
function Get-DishonoredRelease {
    try {
        $r = Invoke-PCVRRestMethod -Uri 'https://api.github.com/repos/VR-Stereo-Hub/Dishonored-VR/releases/latest' -Headers @{'User-Agent'='PCVR-Mods-Hub'} -TimeoutSec 25
        if ($r.draft -or $r.prerelease -or [string]$r.tag_name -notmatch '^v(\d+\.\d+\.\d+)$') { return $null }
        $version = $matches[1]
        $name = "DishonoredVR-Launcher-v$version.exe"
        $asset = @($r.assets | Where-Object { $_.name -ieq $name -and $_.browser_download_url -match '^https://github\.com/VR-Stereo-Hub/Dishonored-VR/releases/download/' }) | Select-Object -First 1
        if (-not $asset) { return $null }
        return @{ Version=$version; Url=[string]$asset.browser_download_url; Name=$name }
    } catch { return $null }
}
function Read-DishonoredManualLauncher {
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    if ($handover -and (Test-DownloadedPayload -Path $handover -IntendedPath 'DishonoredVR-Launcher.exe')) {
        Write-Host "  Using the selected launcher: $handover" -ForegroundColor Cyan
        return $handover
    }
    while ($true) {
        Write-Host '  Download the Launcher EXE from the publisher release page, then enter its path.'
        Write-Host '  [O] Open releases  [P] Enter EXE path  [Q] Cancel'
        $choice = (''+(Read-Host 'Choice')).Trim().ToUpperInvariant()
        if ($choice -eq 'Q') { return $null }
        if ($choice -eq 'O') {
            Pause-DishonoredEnter 'Read the publisher release page. Press [Enter] to open it.'
            try { Start-Process $releasePage } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
            continue
        }
        if ($choice -ne 'P') { continue }
        $path = (''+(Read-Host 'Launcher EXE path')).Trim().Trim('"')
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf) -and
            (Test-DownloadedPayload -Path $path -IntendedPath 'DishonoredVR-Launcher.exe')) { return (Get-Item -LiteralPath $path).FullName }
        Write-Host '  The selected file is not a usable EXE.' -ForegroundColor Yellow
    }
}

while ($true) {
try {
Write-DishonoredHeader
Write-Host '  Publisher: VR-Stereo-Hub / BioVRDev and VOID'
Write-Host '  The launcher installs, updates, disables VR and removes this release.'
Write-Host '  Supported stores: Steam and GOG Galaxy. Close Dishonored first.'
Show-AntivirusNotice -Compact
Pause-DishonoredEnter 'Press [Enter] to begin.'

Write-DishonoredStep 1 'Find your Dishonored installation'
$handover=Get-PCVRRecoveryInput -PathType Container
$root=if (Test-DishonoredGame $handover) { $handover } else { Get-DishonoredSavedRoot }
if (-not $root) {
    try { $root = Find-SteamGameFolder -AppId '205100' -SteamFolderNames @('Dishonored') -GogNames @('Dishonored') -ProbeExe $gameProbe -HubGameId 'dishonored-vr' } catch {}
}
if ($root) { Write-Host "  Found game: $root" }
else {
    Write-Host '  The publisher launcher can find Steam and GOG Galaxy copies.'
    Write-Host '  If your old Hub alpha is in another folder, select that folder before updating.' -ForegroundColor Yellow
    while ($true) {
        $candidate=(''+(Read-Host 'Game folder path, C to let the launcher find it, or Q to cancel')).Trim().Trim('"')
        if ($candidate -ieq 'Q') { exit 0 }
        if ($candidate -ieq 'C') { break }
        if (Test-DishonoredGame $candidate) { $root=(Get-Item -LiteralPath $candidate).FullName; break }
        Write-Host '  Select the folder containing Binaries\Win32\Dishonored.exe.' -ForegroundColor Yellow
    }
}

if (Get-Process -Name 'Dishonored' -ErrorAction SilentlyContinue) {
    Write-Host '  Close Dishonored before using the launcher.' -ForegroundColor Yellow
    Pause-DishonoredEnter 'Press [Enter] after closing the game.'
    if (Get-Process -Name 'Dishonored' -ErrorAction SilentlyContinue) { throw 'Dishonored is still running. Close it, then retry.' }
}
Write-DishonoredStep 2 'Prepare the current VR release'
$legacyRollback=$null
$publisherVerified=$false
try {
$release = Get-DishonoredRelease
$launcher = $null
$temp = $null
if ($release) {
    $temp = Join-PathLexical $env:TEMP ('DishonoredVR-Launcher-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temp -Force | Out-Null
    $launcher = Join-PathLexical $temp $release.Name
    Write-Host "  Latest stable launcher: v$($release.Version)"
    $result = Invoke-DownloadOrFallback -Url $release.Url -Destination $launcher -Label "Dishonored VR v$($release.Version) launcher" -ManualUrl $releasePage -AllowSkip $false
    if (-not $result -or [string]$result -in @('quit','skip') -or -not (Test-DownloadedPayload -Path $launcher -IntendedPath $release.Name)) { $launcher = $null }
}
if (-not $launcher) {
    Write-Host '  Automatic download unavailable. Select the publisher launcher manually.' -ForegroundColor Yellow
    $launcher = Read-DishonoredManualLauncher
}
if (-not $launcher) {
    Write-Host '  Cancelled. The game was not changed by the Hub.'
    if ($temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    exit 0
}
if ($root -and -not $Manage -and (Test-Path -LiteralPath (Join-PathLexical $root $legacyRecord) -PathType Leaf)) {
    Write-Host '  An older Hub alpha is installed. This installer will replace it now.' -ForegroundColor Yellow
    Write-Host '  Owned alpha files are removed; original game backups are restored.'
    Write-Host '  Changed old mod files are saved in a separate legacy backup folder.'
    Write-Host '  Saves, settings and unrelated game files stay in place.'
    Pause-DishonoredEnter 'Press [Enter] to migrate the old alpha and continue.'
    $migration=Invoke-DishonoredLegacyMigration -GameRoot $root -RetainRollback
    $legacyRollback=$migration
    if (Test-Path -LiteralPath (Join-PathLexical $root $legacyRecord) -PathType Leaf) { throw 'The old alpha ownership list remains after migration.' }
    Write-Host "  [OK] Old alpha prepared for replacement: $($migration.Removed) removed, $($migration.Restored) originals restored." -ForegroundColor Green
    if ($migration.BackupFolder) { Write-Host "  Changed files saved: $($migration.BackupFolder)" -ForegroundColor Yellow }
}

Write-DishonoredStep 3 'Run the publisher launcher'
Write-Host "`n  The publisher launcher will now open. Select your game and headset in its window."
if ($Manage) { Write-Host '  Select Update, Disable VR or Uninstall in that window.' }
else { Write-Host '  Select Install or Update in that window.' }
Pause-DishonoredEnter 'Press [Enter] to open the publisher launcher.'
try {
    $process = Start-Process -FilePath $launcher -PassThru -Wait -ErrorAction Stop
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) { throw "Launcher exit code $($process.ExitCode)" }
} catch {
    Write-Host "  Could not complete launcher run: $($_.Exception.Message)" -ForegroundColor Red
    if ($temp) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    throw
}
Write-DishonoredStep 4 'Verify the installed VR files'
Pause-DishonoredEnter 'After closing the launcher, press [Enter] to check the installed files.'

if (-not $root) {
    while ($true) {
        $candidate = (''+(Read-Host 'Game folder containing Binaries\Win32\Dishonored.exe, or Q to cancel')).Trim().Trim('"')
        if ($candidate -ieq 'Q' -or -not $candidate) { exit 0 }
        if (Test-DishonoredGame $candidate) { $root = (Get-Item -LiteralPath $candidate).FullName; break }
        Write-Host '  Dishonored.exe was not found under Binaries\Win32.' -ForegroundColor Yellow
    }
}
$installed = Get-DishonoredPublisherProof $root
if (-not $installed -and -not $Manage) {
    Write-Host '  The selected or detected folder does not yet prove a complete install.' -ForegroundColor Yellow
    Write-Host '  If the launcher installed another copy, enter that game folder now.'
    $other = (''+(Read-Host 'Other Dishonored game folder, or Enter to keep this result')).Trim().Trim('"')
    if ($other -and (Test-DishonoredGame $other)) {
        $otherProof = Get-DishonoredPublisherProof $other
        if ($otherProof) { $root=(Get-Item -LiteralPath $other).FullName; $installed=$otherProof }
    }
}
if (-not $Manage) {
    $required=@('d3d9.dll','dvr_steamvr32.dll','openvr_api.dll','dishonored_vr.ini','dishonored_vr_install.json') |
        ForEach-Object { Join-PathLexical $root ("Binaries\Win32\$_") }
    $survived=Confirm-PlacedFilesSurvive -Paths $required -GameDir $root -Recopy {
        $retry=Start-Process -FilePath $launcher -PassThru -Wait -ErrorAction Stop
        if ($null -eq $retry.ExitCode -or $retry.ExitCode -ne 0) { throw "Publisher launcher retry exited with $($retry.ExitCode)." }
    }
    if (-not $survived) { throw 'Required publisher files did not survive the install check.' }
    $installed=Get-DishonoredPublisherProof $root
}
if ($Manage -and -not $installed -and
    -not (Test-Path -LiteralPath (Join-PathLexical $root 'Binaries\Win32\d3d9.dll') -PathType Leaf) -and
    -not (Test-Path -LiteralPath (Join-PathLexical $root $recordName) -PathType Leaf)) {
    foreach ($marker in @((Join-PathLexical $root '.pcvrhub_version'), (Join-PathLexical $PSScriptRoot '.installed_version'))) {
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
    }
    Write-Host '  Publisher VR files were removed. The game path remains saved.' -ForegroundColor Green
    Pause-DishonoredEnter 'Press [Enter] to finish.'
    exit 0
}
if (-not $installed) {
    Write-Host '  No complete publisher installation was proven. Check the launcher result and retry.' -ForegroundColor Yellow
    throw 'The publisher installation is incomplete. Use recovery to retry or select its game folder.'
}
$publisherVerified=$true
try {
    Save-InstalledStamp -GameDir $root -HubDir $PSScriptRoot -Version ("v$installed")
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot '.installed_path') -Value $root -Encoding UTF8 -Force
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot '.installed_version') -Value ("v$installed") -Encoding UTF8 -Force
    Write-Host "  Dishonored VR v$installed verified in $root" -ForegroundColor Green
} catch {
    Write-Host "  Installed files found; Hub state could not be saved: $($_.Exception.Message)" -ForegroundColor Yellow
    throw
}
Write-Host '  Steam: start through Steam. GOG: start through GOG Galaxy.'
Write-Host '  In the launcher, Disable VR and Uninstall remain available later.'
Write-Host ''
Write-Host '  The Empress is dead. Take the mask, take the city.' -ForegroundColor Magenta
Pause-DishonoredEnter 'Press [Enter] to finish.'
} finally {
    if ($legacyRollback) {
        if ($publisherVerified) {
            Complete-DishonoredLegacyMigration -Migration $legacyRollback
        } else {
            Restore-DishonoredLegacyMigration -Migration $legacyRollback
            Write-Host '  [OK] The old Hub alpha was restored after the publisher update did not complete.' -ForegroundColor Green
        }
    }
    if ($temp -and (Test-Path -LiteralPath $temp -PathType Container)) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
break
} catch {
    $message="Dishonored VR setup did not complete: $($_.Exception.Message)"
    Write-Host "  $message" -ForegroundColor Red
    [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
}
}
