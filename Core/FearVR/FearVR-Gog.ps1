# F.E.A.R. VR - thefreemike's GOG build.
# The VR archive is acquired at run time and is never bundled with the Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')

$MOD_NAME       = 'F.E.A.R. VR'
$MOD_AUTHOR     = 'thefreemike'
$REPO           = 'thefreemike31/fear-vr'
$RELEASES_URL   = 'https://github.com/thefreemike31/fear-vr/releases'
$GAME_EXE       = 'FEAR.exe'
$MOD_MARKER     = 'fearvr_bridge.dll'
$MOD_LAUNCHER   = 'F.E.A.R. VR.exe'
$MOD_UNINSTALL  = 'FEAR-VR-Install\Uninstall F.E.A.R. VR.exe'
$PUBLIC_MARKER  = '.pcvrhub_thefreemike_public'
$SETUP_EXE      = 'F.E.A.R. VR Setup.exe'
$PIN_VERSION    = 'v0.1.0'
$PIN_NAME       = 'fear-vr-v0.1.0.zip'
$PIN_URL        = 'https://github.com/thefreemike31/fear-vr/releases/download/v0.1.0/fear-vr-v0.1.0.zip'
$PIN_SHA        = '598BEB18A6058D96EB5F2FDFE7C1DD59040CF9CB812DB327501F359052AB4E6B'
$QUIP           = 'Slow time. Check the shadows. Alma is already here.'

function Write-OK   { param([string]$Text) Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "  [$Number/$Total] $Text  " -ForegroundColor Black -BackgroundColor Cyan; Write-Host '' }
function Pause-User { param([string]$Text='Press Enter to continue...') Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }
function Get-Sha {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
    return ''
}

function Get-FearGogFolder {
    foreach ($root in @('C:\GOG Games','D:\GOG Games','E:\GOG Games','C:\Program Files (x86)\GOG Galaxy\Games','C:\Program Files\GOG Galaxy\Games')) {
        foreach ($folder in @('F.E.A.R. Platinum Collection','FEAR Platinum Collection','F.E.A.R. Platinum','FEAR')) {
            $candidate = $root.TrimEnd([char[]]'\/') + '\' + $folder
            if (Test-Path -LiteralPath ($candidate + '\' + $GAME_EXE) -PathType Leaf) { return $candidate }
        }
    }
    return $null
}

function Get-ArchiveInputFolders {
    try {
        $workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        return @(
            (Join-Path $workspace 'Archive Input\F.E.A.R. VR'),
            (Join-Path $workspace 'Archive Input')
        )
    } catch { return @() }
}

function Get-LatestStableRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
            -Headers @{'User-Agent'='PCVR-Mods-Hub';'Accept'='application/vnd.github+json'} -TimeoutSec 25 -ErrorAction Stop
        if (-not $release.draft -and -not $release.prerelease) {
            $asset = @($release.assets | Where-Object {
                [string]$_.browser_download_url -and [string]$_.name -match '(?i)^fear-vr-v.+\.zip$' -and
                [string]$_.name -notmatch '(?i)\.sha256$'
            } | Select-Object -First 1)[0]
            if ($asset) {
                $digest = ('' + $asset.digest).Trim()
                if ($digest -match '^(?i)sha256:([0-9a-f]{64})$') { $digest = $matches[1].ToUpperInvariant() }
                else { $digest = '' }
                return [pscustomobject]@{
                    Tag = [string]$release.tag_name
                    Name = [string]$asset.name
                    Url = [string]$asset.browser_download_url
                    Sha256 = $digest
                }
            }
        }
    } catch { Write-Warn 'GitHub release lookup failed; using the last known public asset URL.' }
    return [pscustomobject]@{ Tag=$PIN_VERSION; Name=$PIN_NAME; Url=$PIN_URL; Sha256=$PIN_SHA }
}

function Get-FearArchive([string]$Destination,$Release) {
    $found = Find-PredownloadedFile -Patterns @([string]$Release.Name) `
        -ExtraFolders (Get-ArchiveInputFolders) -Label "$MOD_NAME $($Release.Tag)"
    if ($found) {
        Copy-Item -LiteralPath $found -Destination $Destination -Force -ErrorAction Stop
        return $Destination
    }

    $result = Invoke-SafeDownload -Urls @([string]$Release.Url) -Destination $Destination `
        -Label "$MOD_NAME $($Release.Tag)" -ManualUrl $RELEASES_URL -AllowSkip $false
    if (($result -eq $true -or [string]$result -in @('retry','manual')) -and
        (Test-Path -LiteralPath $Destination -PathType Leaf)) { return $Destination }
    return $null
}

function Show-AdvisorySha {
    param([string]$Path,[string]$ExpectedSha256)
    $expected = ('' + $ExpectedSha256).Trim().ToUpperInvariant()
    $actual = Get-Sha $Path
    if ($expected -and $actual -and $actual -eq $expected) {
        Write-OK "SHA-256 matches GitHub's release digest: $actual"
    } elseif ($expected) {
        Write-Info 'SHA-256 does not match the reviewed digest; the release asset may have been replaced. Continuing without blocking setup.'
    } else {
        Write-Info 'GitHub supplied no SHA-256 digest for this asset. Continuing without an identity gate.'
    }
}

function Test-InstalledRelease {
    param([string]$GameDir)
    foreach ($relative in @($MOD_MARKER,$MOD_LAUNCHER,$MOD_UNINSTALL)) {
        if (-not (Test-Path -LiteralPath (Join-Path $GameDir $relative) -PathType Leaf)) { return $false }
    }
    return $true
}

function Write-InstallState {
    param([string]$GameDir,[string]$Version)
    $utf8 = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$GameDir,$utf8)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path_gog'),$GameDir,$utf8)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version_gog'),$Version,$utf8)
    # The shared Hub tile tracks the GOG alternative in its second version
    # slot. Write both the wrapper-facing receipt and game-side recovery copy
    # so a successful public update remains provable after replacing the Hub.
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version_b'),$Version,$utf8)
    [IO.File]::WriteAllText((Join-Path $GameDir '.pcvrhub_version_b'),$Version,$utf8)
    [IO.File]::WriteAllText((Join-Path $GameDir $PUBLIC_MARKER),$Version,$utf8)
}

$work = $null
$installSucceeded = $false
$installError = $null
try {
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host " F.E.A.R. VR - $MOD_AUTHOR public GOG build" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  GOG F.E.A.R. PLATINUM COLLECTION ONLY. ' -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ''
    Write-Host '  The current stable public release is downloaded from GitHub.' -ForegroundColor White
    Write-Host '  RC6.2 and other private betas upgrade directly; saves, profiles' -ForegroundColor White
    Write-Host '  and the author setup recovery data are preserved.' -ForegroundColor White
    Write-Host '  Start the unmodified game once, reach the menu and load a level,' -ForegroundColor Yellow
    Write-Host '  then close it before installing the VR mod.' -ForegroundColor Yellow
    Show-AntivirusNotice -Compact
    Pause-User 'Press Enter to proceed with setup...'

    Write-Step 1 4 'Finding the supported GOG game'
    $gameDir = Get-FearGogFolder
    if (-not $gameDir) {
        Write-Warn 'No GOG F.E.A.R. Platinum Collection was found automatically.'
        $manual = ('' + (Read-Host '  Paste the folder that holds FEAR.exe')).Trim().Trim('"').Trim("'")
        if (-not $manual -or -not (Test-Path -LiteralPath (Join-Path $manual $GAME_EXE) -PathType Leaf)) { throw 'No supported game folder was supplied. Nothing was changed.' }
        $gameDir = (Get-Item -LiteralPath $manual).FullName
    }
    Write-OK "Game folder: $gameDir"

    Write-Step 2 4 'Getting the current stable GitHub release'
    $release = Get-LatestStableRelease
    Write-Info "Stable release: $($release.Tag)"
    $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_fear_gog_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $archive = Get-FearArchive -Destination (Join-Path $work ([string]$release.Name)) -Release $release
    if (-not $archive) { throw 'The current F.E.A.R. VR GitHub release could not be acquired.' }
    Show-AdvisorySha -Path $archive -ExpectedSha256 ([string]$release.Sha256)

    Write-Step 3 4 'Opening the author setup'
    $extract = Join-Path $work 'release'
    $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'F.E.A.R. VR release archive' -AllowSkip $false
    if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The release could not be extracted safely.' }
    $setup = Join-Path $extract $SETUP_EXE
    if (-not (Test-Path -LiteralPath $setup -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $extract 'setup-files') -PathType Container)) {
        throw 'The downloaded release cannot be opened because Setup or its setup-files folder is missing.'
    }

    if (Test-Path -LiteralPath (Join-Path $gameDir $MOD_MARKER) -PathType Leaf) {
        Write-Info 'An older or current thefreemike build is present. Choose Upgrade in Setup.'
    } else {
        Write-Info 'Choose Install in Setup and confirm the game folder shown above.'
    }
    Write-Host '  Keep setup-files beside F.E.A.R. VR Setup.exe.' -ForegroundColor Gray
    Write-Host "  Target game folder: $gameDir" -ForegroundColor Cyan
    Write-Host ''

    $installed = $false
    for ($attempt = 1; $attempt -le 10 -and -not $installed; $attempt++) {
        try { Start-Process -FilePath $setup -WorkingDirectory $extract -Wait -ErrorAction Stop } catch { Write-Warn "Setup could not be opened: $($_.Exception.Message)" }
        $installed = Test-InstalledRelease $gameDir
        if ($installed) { break }
        Write-Warn "The playable $($release.Tag) launcher and bridge were not found in the selected game folder."
        if ($attempt -ge 10) { break }
        $answer = ('' + (Read-Host "  [R]un Setup again, [C]heck files again, or [Q]uit? ($attempt/10)")).Trim().ToUpperInvariant()
        if ($answer -eq 'Q') { break }
        if ($answer -eq 'C') {
            $installed = Test-InstalledRelease $gameDir
        }
    }
    if (-not $installed) { throw 'Setup did not confirm a complete installation. No Hub success state was written.' }

    Write-Step 4 4 'Verifying the installation and saving recovery state'
    $watch = @($MOD_MARKER,$MOD_LAUNCHER,$MOD_UNINSTALL) | ForEach-Object { Join-Path $gameDir $_ }
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $gameDir -ArchivePath $archive)) { throw 'One or more required files did not survive the antivirus check.' }
    Write-InstallState -GameDir $gameDir -Version ([string]$release.Tag)
    Write-OK "$MOD_NAME $($release.Tag) is installed and will be detected as VR Ready."

    Write-Host ''
    Write-Host '  STARTING THE GAME ' -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ''
    Write-Host '  Use Start in VR in the Hub; it launches F.E.A.R. VR.exe.' -ForegroundColor White
    Write-Host '  Virtual Desktop: connect through VDXR and keep SteamVR closed.' -ForegroundColor White
    Write-Host '  Steam Link / SteamVR: start SteamVR and connect first.' -ForegroundColor White
    Write-Host '  Meta Link and Air Link are unsupported, even through SteamVR.' -ForegroundColor Yellow
    Write-Host '  Use the current SteamVR Beta (at least 2.17.3) for troubleshooting.' -ForegroundColor Gray
    Write-Host ''
    Write-Host "  $QUIP" -ForegroundColor Magenta
    $installSucceeded = $true
} catch {
    $installError = $_.Exception
    Write-Host ''
    Write-Host "  [X] $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Pause-User 'Press Enter to exit'
if (-not $installSucceeded) { throw $installError }
