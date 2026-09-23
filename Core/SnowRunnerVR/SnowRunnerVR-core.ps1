. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'SnowRunner VR Installer'
$repo = 'Timguin-87/Snowrunner-VR'
$appId = '1465360'
$depotId = '1465361'
$depotManifest = '1017218816943865737'
$depotCommand = "download_depot $appId $depotId $depotManifest"
$depotGameVersion = '1.886173'
$depotBuild = '25096372'
$depotExpectedBytes = [int64]73390577922
$depotDefaultPath = 'C:\Games\SnowRunner VR'
$currentFallbackTag = 'v0.4'
$currentFallbackUrl = 'https://github.com/Timguin-87/Snowrunner-VR/releases/download/v0.4/dxgi.dll'
$confirmedModTag = 'v0.3'
$confirmedModUrl = 'https://github.com/Timguin-87/Snowrunner-VR/releases/download/v0.3/dxgi.dll'
$knownOfficialHashes = @(
    'E982FB695273F259F03E658F3D6DFFED3589FFECDB17970898A4A1481CFEF92D',
    '2697B17C3BA3046834CA87365960E5869286C02DF0E7E98A2CA82E73F00CCBF5',
    '47ACD7C04C3AC1CFF883A6FD16FA0F8431CE7A099CE13F42815FF8078C985F59',
    'B7DDBB24D6A63EB9C608DE845E3F190F969EEFC4DCF6425C3DADACFBD3ECE0B'
)
$temp = ''

function Write-SnowHeader {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  SnowRunner VR' -ForegroundColor Cyan
    Write-Host '  Installs: SnowRunner VR by Timguin-87' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function Write-SnowStep([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-SnowOk([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-SnowWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Pause-Snow([string]$Text='Press Enter to continue...') { Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }

function Read-SnowChoice {
    param([string[]]$Allowed,[string]$Prompt)
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $choice = ([string](Read-Host $Prompt)).Trim().ToUpperInvariant()
        if ($choice -in $Allowed) { return $choice }
        Write-SnowWarn "Choose $($Allowed -join ', ')."
    }
    throw 'No valid setup option was selected after 10 attempts.'
}

function Test-SnowRunnerPinnedRoot {
    param([string]$Path,[switch]$RequireCompleteDepot)
    if (-not $Path -or -not (Test-LiteralPathSafe -Path $Path -PathType Container)) { return $false }
    foreach ($required in @('Sources\Bin\SnowRunner.exe','Media','preload','Sources')) {
        $candidate = Join-PathLexical $Path $required
        $type = if ($required -like '*.exe') { 'Leaf' } else { 'Container' }
        if (-not (Test-LiteralPathSafe -Path $candidate -PathType $type)) { return $false }
    }
    try {
        $product = [string](Get-Item -LiteralPath (Join-PathLexical $Path 'Sources\Bin\SnowRunner.exe') -ErrorAction Stop).VersionInfo.ProductVersion
        if (-not $product.StartsWith($depotGameVersion,[StringComparison]::OrdinalIgnoreCase)) { return $false }
        if ($RequireCompleteDepot) {
            [int64]$bytes = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction Stop | Measure-Object -Property Length -Sum).Sum
            if ($bytes -lt $depotExpectedBytes) { return $false }
        }
        return $true
    } catch { return $false }
}

function Get-ExistingSnowRunnerDepot {
    $candidates = @()
    $pathFile = Join-Path $PSScriptRoot '.installed_path_depot'
    if (Test-Path -LiteralPath $pathFile -PathType Leaf) {
        try { $candidates += ([IO.File]::ReadAllText($pathFile)).Trim() } catch {}
    }
    $located = Get-HubLocatedGameFolder -GameId 'snowrunner-vr' -ProbeFiles @('Sources\Bin\SnowRunner.exe')
    if ($located) { $candidates += $located }
    $candidates += $depotDefaultPath
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-SnowRunnerPinnedRoot -Path $candidate) { return $candidate }
    }
    return $null
}

function Write-SnowRunnerDepotAppId {
    param([string]$GameRoot)
    $appidFile = Join-PathLexical $GameRoot 'Sources\Bin\steam_appid.txt'
    [IO.File]::WriteAllText($appidFile,$appId,[Text.Encoding]::ASCII)
    Write-SnowOk "steam_appid.txt created beside SnowRunner.exe ($appId)."
}

function Install-SnowRunnerPinnedDepot {
    Write-SnowStep 1 4 "Preparing the last confirmed game version $depotGameVersion"
    $existing = Get-ExistingSnowRunnerDepot
    if ($existing) {
        Write-SnowRunnerDepotAppId -GameRoot $existing
        Write-SnowOk "Using the existing confirmed copy: $existing"
        return $existing
    }

    # Always look first. A completed Steam Console depot from an earlier run
    # must bypass every browser/console prompt and must never be downloaded twice.
    $steamPath = Get-SteamPath
    $depotPath = Find-SteamDepotPath -AppId $appId -DepotId $depotId -GameExe 'Sources\Bin\SnowRunner.exe' -AdditionalSteamRoots @($steamPath)
    if ($depotPath -and -not (Test-SnowRunnerPinnedRoot -Path $depotPath -RequireCompleteDepot)) {
        Write-SnowWarn 'A SnowRunner depot folder exists, but its version or content is incomplete.'
        $depotPath = $null
    }
    if (-not $depotPath) {
        Write-Host "  This downloads the Windows depot matched to SnowRunner VR ${confirmedModTag}:" -ForegroundColor White
        Write-Host "  Game $depotGameVersion, Steam build $depotBuild" -ForegroundColor White
        Write-Host "  $depotCommand" -ForegroundColor DarkGray
        try { Set-Clipboard -Value $depotCommand -DeferManualFallback } catch {}
        Pause-Snow 'Press Enter to open the Steam Console...'
        foreach ($uri in @('steam://open/console','steam://nav/console')) {
            try { Start-Process $uri; Start-Sleep -Milliseconds 900 } catch {}
        }
        Show-PCVRClipboardManualFallback -Text $depotCommand
        Write-Host '  Paste the command with Ctrl+V, press Enter, and wait for:' -ForegroundColor White
        Write-Host "  Depot download complete ...\depot_$depotId" -ForegroundColor Black -BackgroundColor Yellow
        Pause-Snow 'Press Enter only after the depot download has finished...'
        $depotPath = Find-SteamDepotPath -AppId $appId -DepotId $depotId -GameExe 'Sources\Bin\SnowRunner.exe' -AdditionalSteamRoots @($steamPath)
        if (-not $depotPath) {
            $probes = @(Get-SteamDepotProbePaths -AppId $appId -DepotId $depotId -AdditionalSteamRoots @($steamPath))
            $depotPath = Resolve-DepotPath -GameName "SnowRunner $depotGameVersion" -DepotCommand $depotCommand -GameExe 'Sources\Bin\SnowRunner.exe' -ProbePaths $probes -AppId $appId -DepotId $depotId -Manifest $depotManifest
        }
    }
    if (-not $depotPath -or -not (Test-SnowRunnerPinnedRoot -Path $depotPath -RequireCompleteDepot)) {
        throw "The complete SnowRunner $depotGameVersion depot was not verified. Nothing was moved."
    }

    Write-Host "  Default install location: $depotDefaultPath" -ForegroundColor Gray
    $entered = ([string](Read-Host 'Press Enter for the default, or type a different full path')).Trim().Trim('"')
    $targetPath = if ($entered) { $entered } else { $depotDefaultPath }
    if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) { throw "The depot target is not writable: $targetPath" }
    $normalSteamGame = Find-SteamGameFolder -AppId $appId -SteamFolderNames @('SnowRunner','Codename - SR') -ProbeExe 'Sources\Bin\SnowRunner.exe'
    if ($normalSteamGame -and ([IO.Path]::GetFullPath($targetPath) -ieq [IO.Path]::GetFullPath($normalSteamGame))) {
        throw 'The pinned depot cannot replace or merge into the normal Steam installation. Choose a separate folder.'
    }
    if ((Test-LiteralPathSafe -Path $targetPath -PathType Container) -and -not (Test-SnowRunnerPinnedRoot -Path $targetPath)) {
        throw "The existing target is not a verified SnowRunner $depotGameVersion copy. Choose another empty folder."
    }
    $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "SnowRunner $depotGameVersion depot build"
    if (-not (Test-SnowRunnerPinnedRoot -Path $targetPath)) { throw 'The moved depot failed its version and structure check.' }

    # SnowRunner.exe is nested. Steamworks therefore needs the ID beside that
    # executable, not merely at the depot root.
    Write-SnowRunnerDepotAppId -GameRoot $targetPath
    return $targetPath
}

function Get-SnowRunnerRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers @{'User-Agent'='PCVR-Mods-Hub';'Accept'='application/vnd.github+json'} -TimeoutSec 15 -ErrorAction Stop
        $asset = @($release.assets | Where-Object { $_.name -ieq 'dxgi.dll' } | Select-Object -First 1)[0]
        if (-not $asset -or -not $asset.browser_download_url -or [int64]$asset.size -lt 70000) { throw 'The latest stable release has no valid dxgi.dll asset.' }
        return [pscustomobject]@{ Tag=[string]$release.tag_name; Url=[string]$asset.browser_download_url }
    } catch {
        Write-SnowWarn "GitHub did not answer; using the last known $currentFallbackTag release URL."
        return [pscustomobject]@{ Tag=$currentFallbackTag; Url=$currentFallbackUrl }
    }
}

function Remove-SnowTemp {
    if (-not $temp -or -not (Test-Path -LiteralPath $temp)) { return }
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $candidate = [IO.Path]::GetFullPath($temp)
    if ($candidate.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $candidate -Recurse -Force -ErrorAction SilentlyContinue }
}

trap {
    Remove-SnowTemp
    Write-SnowWarn ("Setup could not finish: " + $_.Exception.Message)
    Write-Host '  No unverified installation state was committed. Run setup again to retry.' -ForegroundColor Gray
    Pause-Snow 'Press Enter to exit'
    exit 1
}

Write-SnowHeader
Write-Host '  Adds native stereo, 6DoF head tracking and OpenXR rendering.' -ForegroundColor White
Write-Host '  This early gamepad mod supports the Steam DirectX 11 build only.' -ForegroundColor White
Write-Host ''
Write-SnowWarn 'SnowRunner updates can temporarily break this WIP mod.'
Write-Host ''
Write-Host '  [1] Current Steam version' -ForegroundColor Cyan
Write-Host '      Uses your normal game and follows the current stable VR release.' -ForegroundColor Gray
Write-Host "  [2] Last confirmed working version - $depotGameVersion (recommended fallback)" -ForegroundColor Cyan
Write-Host "      Downloads Steam build $depotBuild into $depotDefaultPath." -ForegroundColor Gray
Write-Host '      Your normal Steam installation remains untouched.' -ForegroundColor Gray
Write-Host '  [Q] Quit' -ForegroundColor Gray
Write-Host ''
$installMode = Read-SnowChoice -Allowed @('1','2','Q') -Prompt 'Select setup option'
if ($installMode -eq 'Q') {
    Write-Host ''
    Write-Host '  The road ends here. The mud has other plans.' -ForegroundColor Magenta
    Pause-Snow 'Press Enter to exit'
    exit 0
}
Show-AntivirusNotice -Compact
Pause-Snow 'Press Enter to start setup...'

Write-SnowHeader
if ($installMode -eq '2') {
    $game = Install-SnowRunnerPinnedDepot
} else {
    Write-SnowStep 1 4 'Locating the current Steam game'
    $game = Find-SteamGameFolder -AppId $appId -SteamFolderNames @('SnowRunner','Codename - SR') -ProbeExe 'Sources\Bin\SnowRunner.exe' -HubGameId 'snowrunner-vr'
    if (-not $game) { $game = Get-GameFolderInteractive -GameName 'SnowRunner' -ProbeFile 'Sources\Bin\SnowRunner.exe' -ManualUrl 'https://store.steampowered.com/app/1465360/' }
    if ($game -in @('quit','skip',$null)) { throw 'No verified SnowRunner Steam folder was selected.' }
}
$gameExe = Join-Path $game 'Sources\Bin\SnowRunner.exe'
if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { throw 'Sources\Bin\SnowRunner.exe was not found in the selected folder.' }
$bin = Split-Path -Parent $gameExe
if (Get-Process -Name 'SnowRunner' -ErrorAction SilentlyContinue) { throw 'SnowRunner is still running. Close the game and run setup again.' }
Write-SnowOk "Found: $gameExe"

if ($installMode -eq '2') {
    Write-SnowStep 2 4 "Downloading the pinned VR release $confirmedModTag"
    # The confirmed game depot and its confirmed VR binary are one immutable
    # pairing.  Never resolve GitHub latest for this route: a newer mod may
    # target a newer game build and would destroy the purpose of the fallback.
    $release = [pscustomobject]@{ Tag=$confirmedModTag; Url=$confirmedModUrl }
} else {
    Write-SnowStep 2 4 'Downloading the current official stable release'
    $release = Get-SnowRunnerRelease
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('SnowRunnerVR_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$download = Join-Path $temp 'dxgi.dll'
$got = Invoke-SafeDownload -Urls @($release.Url) -Destination $download -Label "SnowRunner VR $($release.Tag)" -ManualUrl "https://github.com/$repo/releases" -AllowSkip $false
if (-not $got -or $got -in @('quit','skip')) { throw 'The official SnowRunner VR DLL was not obtained.' }
Write-SnowOk "Official stable release $($release.Tag) downloaded."

Write-SnowStep 3 4 'Installing with exact-file recovery'
$stage = Join-Path $temp 'stage'
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item -LiteralPath $download -Destination (Join-Path $stage 'dxgi.dll') -Force
[IO.File]::WriteAllText((Join-Path $stage '.pcvrhub-snowrunner-vr'),[string]$release.Tag,(New-Object Text.UTF8Encoding($false)))
$live = Join-Path $bin 'dxgi.dll'
$parked = Join-Path $bin 'dxgi.dll.pcvrhub_off'
$manifest = Join-Path $bin '.pcvrhub_snowrunnervr_ownership.csv'
if ((Test-Path -LiteralPath $live) -and (Test-Path -LiteralPath $parked)) { throw 'Both active and parked dxgi.dll files exist. Remove the duplicate before updating.' }
$restoreFlat = ((-not (Test-Path -LiteralPath $live)) -and (Test-Path -LiteralPath $parked))
if ($restoreFlat) { Rename-Item -LiteralPath $parked -NewName 'dxgi.dll'; Write-SnowOk 'The parked official proxy was restored temporarily for a safe update.' }

if ((Test-Path -LiteralPath $live -PathType Leaf) -and -not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    $existingHash = (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash
    $newHash = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash
    if ($existingHash -ne $newHash -and $existingHash -in $knownOfficialHashes) {
        Remove-Item -LiteralPath $live -Force
        Write-SnowOk 'An older official SnowRunner VR proxy was recognized and prepared for update.'
    } elseif ($existingHash -ne $newHash) {
        Write-SnowWarn 'An unknown dxgi.dll already exists beside SnowRunner.exe.'
        Write-Host '  It may belong to another graphics mod. Setup has not overwritten it.' -ForegroundColor Gray
        $resolution = Invoke-InstallerFallback -Action 'existing dxgi.dll conflict' -Url "https://github.com/$repo" -Instructions "Close the game, identify that proxy, and move it out of the Bin folder only if you know it is safe. Then choose Retry. The Hub will not guess ownership of an unknown DLL." -RetryCheck { -not (Test-Path -LiteralPath $live -PathType Leaf) } -AllowSkip $false
        if ($resolution -eq 'quit') { throw 'The existing unknown dxgi.dll was left untouched.' }
    }
}

Install-OwnedModPayload -SourceRoot $stage -GameRoot $bin -Identity 'snowrunnervr' -AdoptIdenticalExisting | Out-Null
$watch = @((Join-Path $bin 'dxgi.dll'),(Join-Path $bin '.pcvrhub-snowrunner-vr'))
foreach ($required in $watch) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Installed-file verification failed: $(Split-Path -Leaf $required)" } }
$recoverSnow = { Install-OwnedModPayload -SourceRoot $stage -GameRoot $bin -Identity 'snowrunnervr' -AdoptIdenticalExisting | Out-Null }.GetNewClosure()
if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $bin -Recopy $recoverSnow)) { throw 'The required SnowRunner VR files did not survive the antivirus check.' }
if ($restoreFlat) {
    Rename-Item -LiteralPath $live -NewName 'dxgi.dll.pcvrhub_off'
    Write-SnowOk 'The previous flat state was preserved after updating.'
}
$pathStateFile = if ($installMode -eq '2') { '.installed_path_depot' } else { '.installed_path' }
$versionStateFile = if ($installMode -eq '2') { '.installed_version_depot' } else { '.installed_version' }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot $pathStateFile),$game,(New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot $versionStateFile),[string]$release.Tag,(New-Object Text.UTF8Encoding($false)))
Save-InstalledStamp -GameDir $game -Version ([string]$release.Tag) -HubDir $PSScriptRoot
if ($installMode -eq '2') {
    $shortcut = New-DesktopShortcut -ShortcutName "SnowRunner VR $depotGameVersion" -TargetPath $gameExe -WorkingDir $bin -IconPath $gameExe -Description "SnowRunner $depotGameVersion with SnowRunner VR"
    if ($shortcut) { Write-SnowOk "Desktop shortcut created: SnowRunner VR $depotGameVersion" }
    else { Write-SnowWarn 'The desktop shortcut could not be created; use the Hub button instead.' }
}
Write-SnowOk 'VR proxy, marker, ownership manifest and recovery stamp verified.'

Write-SnowStep 4 4 'First launch and image settings'
Write-Host '  1. Select Windowed mode in SnowRunner.' -ForegroundColor White
Write-Host '  2. Disable temporal anti-aliasing; use FXAA only.' -ForegroundColor White
Write-Host '  3. Start one OpenXR runtime, then use the matching Start button' -ForegroundColor White
if ($installMode -eq '2') {
    Write-Host "     in the Hub or the SnowRunner VR $depotGameVersion desktop shortcut." -ForegroundColor White
} else {
    Write-Host '     in the Hub or launch SnowRunner through Steam.' -ForegroundColor White
}
Write-Host '  4. The first VR start writes the headset resolution and config.' -ForegroundColor White
Write-Host '     Close SnowRunner once, then launch it again.' -ForegroundColor White
Remove-SnowTemp

Write-Host ''
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host '  SnowRunner VR installed.' -ForegroundColor Green
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host ''
Write-Host '  The road ends here. The mud has other plans.' -ForegroundColor Magenta
Write-Host ''
Pause-Snow 'Press Enter to exit'
