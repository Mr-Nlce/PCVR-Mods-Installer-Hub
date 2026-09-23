# Warhammer 40,000: Darktide VR - governed GitHub prerelease installer.
# Steam App 1361210; Darktide Mod Loader and DMF are shared dependencies;
# the VR package owns only mods\darktidevr. The publisher's mode tool owns
# executable/proxy/load-order recovery and is always run in a child process.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Warhammer 40K: Darktide VR Installer'
$APP_ID = '1361210'
$GAME_EXE = 'binaries\Darktide.exe'
$REPO = 'Brobert-in-aus/darktide-vr'
$RELEASES = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'v0.3.0-alpha.1'
$FALLBACK_NAME = 'darktidevr-0.3.0-alpha.1-e2861b5cb045.zip'
$FALLBACK_URL = 'https://github.com/Brobert-in-aus/darktide-vr/releases/download/v0.3.0-alpha.1/darktidevr-0.3.0-alpha.1-e2861b5cb045.zip'
$DEPOT_MOD_TAG = 'v0.1.0-alpha.3'
$DEPOT_MOD_NAME = 'darktidevr-0.1.0-alpha.3-8bc59403fcd8.zip'
$DEPOT_MOD_URL = 'https://github.com/Brobert-in-aus/darktide-vr/releases/download/v0.1.0-alpha.3/darktidevr-0.1.0-alpha.3-8bc59403fcd8.zip'
$LOADER_REPO = 'Darktide-Mod-Loader/Darktide-Mod-Loader'
$LOADER_FALLBACK_TAG = '26.06.24'
$LOADER_FALLBACK_URL = 'https://github.com/user-attachments/files/29280059/Darktide-Mod-Loader.zip'
$DMF_COMMIT = 'fc08c1cb772f86248c7ae9e957543e801a0dbf64'
$DMF_URL = 'https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework/archive/fc08c1cb772f86248c7ae9e957543e801a0dbf64.zip'
$DARKTIDE_DEPOT_BUILD = '24735202'
$DARKTIDE_DEPOT_DEFAULT_PATH = 'C:\Games\Darktide VR 24735202'
$DARKTIDE_DEPOT_MARKER = '.pcvrhub_darktide_depot_24735202'
$DARKTIDE_DEPOT_STACK_MARKER = '.pcvrhub_darktide_depot_stack'
$DARKTIDE_DEPOT_STAGING_MARKER = '.pcvrhub_darktide_depot_staging_24735202'
$DARKTIDE_DEPOTS = @(
    [pscustomobject]@{ DepotId='1361211'; Manifest='8996611047797368886'; Proof='bundle\bundle_database.data'; Label='game data' },
    [pscustomobject]@{ DepotId='1361212'; Manifest='5990150591810997331'; Proof='launcher\launcher.exe'; Label='Fatshark launcher' },
    [pscustomobject]@{ DepotId='1361213'; Manifest='9209862899812953262'; Proof='binaries\Darktide.exe'; Label='Windows executable' }
)
$IDENTITY = 'darktidevr'
$QUIP = 'The Emperor protects, but the hands still have to aim.'
$contract = New-PCVRInstallerContract -Id 'warhammer-40k-darktide-vr' `
    -GameName 'Warhammer 40K: Darktide VR' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @(
        'mods\darktidevr\bin\darktidevr_native_capture.dll',
        'mods\darktidevr\bin\darktidevr-xr-harness.exe',
        'mods\darktidevr\darktidevr-mode.ps1',
        'mods\dmf\dmf.mod','tools\dtkit-patch.exe','binaries\d3d12.dll',
        '.pcvrhub_darktidevr_ownership.csv'
    )
$depotContract = New-PCVRInstallerContract -Id 'warhammer-40k-darktide-vr' `
    -GameName 'Warhammer 40K: Darktide VR' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @(
        'mods\darktidevr\bin\darktidevr_native_capture.dll',
        'mods\darktidevr\bin\darktidevr-xr-harness.exe',
        'mods\darktidevr\darktidevr-mode.ps1',
        'mods\dmf\dmf.mod','tools\dtkit-patch.exe','binaries\d3d12.dll',
        '.pcvrhub_darktidevr_ownership.csv',$DARKTIDE_DEPOT_MARKER,
        $DARKTIDE_DEPOT_STACK_MARKER,'steam_appid.txt','launcher\steam_appid.txt',
        'Start Darktide VR Depot.bat','Switch Darktide Depot Mode.bat'
    )

function Write-DarkStep([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-DarkOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-DarkInfo([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }
function Write-DarkWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Read-DarkChoice {
    param([string[]]$Allowed,[string]$Prompt)
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $choice=([string](Read-Host $Prompt)).Trim().ToUpperInvariant()
        if ($choice -in $Allowed) { return $choice }
        Write-DarkWarn "Choose $($Allowed -join ', ')."
    }
    throw 'No valid setup option was selected after 10 attempts.'
}

function Test-DarktideRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'binaries\Darktide.exe') -PathType Leaf))
}
function Test-DarktideLoader([string]$GameRoot) {
    return [bool]((Test-Path -LiteralPath (Join-Path $GameRoot 'binaries\mod_loader') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $GameRoot 'tools\dtkit-patch.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $GameRoot 'mods\mod_load_order.txt') -PathType Leaf))
}
function Test-DarktideFramework([string]$GameRoot) {
    return [bool](Test-Path -LiteralPath (Join-Path $GameRoot 'mods\dmf\dmf.mod') -PathType Leaf)
}
function Find-DarktideVrPayload([string]$ExtractRoot) {
    $marker = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'darktidevr.mod' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'darktidevr' } | Select-Object -First 1
    if (-not $marker) { return $null }
    return (Split-Path -Parent (Split-Path -Parent $marker.DirectoryName))
}
function Find-DarktideLoaderPayload([string]$ExtractRoot) {
    $marker = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'mod_loader' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'binaries' } | Select-Object -First 1
    if (-not $marker) { return $null }
    return (Split-Path -Parent $marker.DirectoryName)
}
function Find-DarktideFrameworkPayload([string]$ExtractRoot) {
    $marker = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'dmf.mod' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'dmf' } | Select-Object -First 1
    if ($marker) { return $marker.DirectoryName }
    return $null
}

function Resolve-DarktideLoaderDownload {
    param($ReleaseData = $null)
    $page = "https://github.com/$LOADER_REPO/releases"
    try {
        $releases = $ReleaseData
        if ($null -eq $releases) {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$LOADER_REPO/releases?per_page=10" `
                -Headers @{ 'User-Agent'='PCVR-Mods-Hub'; 'Accept'='application/vnd.github+json' } -TimeoutSec 20
        }
        $release = @($releases | Where-Object { $_ -and -not [bool]$_.draft } | Sort-Object published_at -Descending)[0]
        if ($release) {
            $body = [string]$release.body
            $match = [regex]::Match($body,'https://github\.com/user-attachments/files/[^\s\)\]"'']+/Darktide-Mod-Loader\.zip','IgnoreCase')
            if ($match.Success) {
                return [pscustomobject]@{ Url=$match.Value; Tag=[string]$release.tag_name; PageUrl=[string]$release.html_url; Resolved=$true }
            }
        }
    } catch {}
    return [pscustomobject]@{ Url=$LOADER_FALLBACK_URL; Tag=$LOADER_FALLBACK_TAG; PageUrl=$page; Resolved=$false }
}

function Get-DarktideVrRelease {
    param([ValidateSet('Current','Depot')][string]$InstallMode='Current')
    if ($InstallMode -eq 'Depot') {
        return [pscustomobject]@{ Tag=$DEPOT_MOD_TAG; Url=$DEPOT_MOD_URL; PageUrl="$RELEASES/tag/$DEPOT_MOD_TAG"; AssetName=$DEPOT_MOD_NAME; Pinned=$true }
    }
    return Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -AssetPatterns @('(?i)^darktidevr[-_.].*\.zip$') `
        -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_NAME
}

function Get-DarktideLoaderRelease {
    param([ValidateSet('Current','Depot')][string]$InstallMode='Current',$ReleaseData=$null)
    if ($InstallMode -eq 'Depot') {
        return [pscustomobject]@{ Url=$LOADER_FALLBACK_URL; Tag=$LOADER_FALLBACK_TAG; PageUrl="https://github.com/$LOADER_REPO/releases/tag/$LOADER_FALLBACK_TAG"; Resolved=$true; Pinned=$true }
    }
    return Resolve-DarktideLoaderDownload -ReleaseData $ReleaseData
}

function Get-DarktideDepotMarkerText {
    return (@(
        "AppId=$APP_ID",
        "BuildId=$DARKTIDE_DEPOT_BUILD",
        'Depot.1361211=8996611047797368886',
        'Depot.1361212=5990150591810997331',
        'Depot.1361213=9209862899812953262'
    ) -join "`r`n")
}

function Test-DarktideDepotMarker([string]$Path,[string]$MarkerName=$DARKTIDE_DEPOT_MARKER) {
    if (-not $Path) { return $false }
    $marker=Join-Path $Path $MarkerName
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { return $false }
    try {
        $text=[IO.File]::ReadAllText($marker)
        foreach ($line in @((Get-DarktideDepotMarkerText) -split "`r?`n")) {
            if ($text -notmatch ('(?m)^'+[regex]::Escape($line)+'\s*$')) { return $false }
        }
        return $true
    } catch { return $false }
}

function Test-DarktidePinnedRoot([string]$Path,[switch]$AllowStaging) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    foreach ($relative in @('bundle\bundle_database.data','launcher\launcher.exe','binaries\Darktide.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $relative) -PathType Leaf)) { return $false }
    }
    if (Test-DarktideDepotMarker -Path $Path) { return $true }
    if ($AllowStaging -and (Test-DarktideDepotMarker -Path $Path -MarkerName $DARKTIDE_DEPOT_STAGING_MARKER)) { return $true }
    return $false
}

function Write-DarktideDepotSupportFiles([string]$GameRoot) {
    if (-not (Test-DarktideRoot $GameRoot) -or
        -not (Test-Path -LiteralPath (Join-Path $GameRoot 'bundle\bundle_database.data') -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $GameRoot 'launcher\launcher.exe') -PathType Leaf)) {
        throw 'The merged Darktide depot is incomplete; support files were not written.'
    }
    [IO.File]::WriteAllText((Join-Path $GameRoot 'steam_appid.txt'),$APP_ID,[Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $GameRoot 'launcher\steam_appid.txt'),$APP_ID,[Text.Encoding]::ASCII)
    $start=@'
@echo off
setlocal
start "" "steam://open/main"
for /L %%I in (1,1,30) do (
  tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I "steam.exe" >NUL && goto steam_ready
  timeout /t 1 /nobreak >NUL
)
:steam_ready
start "" /D "%~dp0launcher" "%~dp0launcher\launcher.exe"
endlocal
exit /b 0
'@
    $switch=@'
@echo off
setlocal
set "LOCALAPPDATA=%~dp0.pcvrhub_darktide_state"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
call "%~dp0mods\darktidevr\Darktide VR Mode.bat"
endlocal
'@
    [IO.File]::WriteAllText((Join-Path $GameRoot 'Start Darktide VR Depot.bat'),$start.TrimStart(),[Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $GameRoot 'Switch Darktide Depot Mode.bat'),$switch.TrimStart(),[Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $GameRoot $DARKTIDE_DEPOT_MARKER),(Get-DarktideDepotMarkerText),(New-Object Text.UTF8Encoding $false))
}

function Get-ExistingDarktideDepot {
    $candidates=@()
    $pathFile=Join-Path $PSScriptRoot '.installed_path_depot'
    if (Test-Path -LiteralPath $pathFile -PathType Leaf) {
        try { $candidates+=([IO.File]::ReadAllText($pathFile)).Trim() } catch {}
    }
    $candidates+=$DARKTIDE_DEPOT_DEFAULT_PATH
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-DarktidePinnedRoot -Path $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    return $null
}

function Install-DarktidePinnedDepot {
    Write-DarkStep 1 5 "Preparing confirmed Steam build $DARKTIDE_DEPOT_BUILD"
    $existing=Get-ExistingDarktideDepot
    if ($existing) {
        Write-DarktideDepotSupportFiles -GameRoot $existing
        Write-DarkOK "Using existing pinned copy: $existing"
        return $existing
    }

    Write-Host '  This route downloads all three Windows depots (about 96.4 GiB)' -ForegroundColor White
    Write-Host "  and keeps them separate from your normal Steam installation." -ForegroundColor White
    Write-Host "  Default destination: $DARKTIDE_DEPOT_DEFAULT_PATH" -ForegroundColor Gray
    $entered=([string](Read-Host 'Press Enter for the default, or type a different full path')).Trim().Trim('"')
    $target=if ($entered) { $entered } else { $DARKTIDE_DEPOT_DEFAULT_PATH }
    if (-not (Test-InstallerTargetWritable -TargetPath $target)) { throw "The depot target is not writable: $target" }
    $normal=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Warhammer 40,000 DARKTIDE') -ProbeExe $GAME_EXE
    if ($normal -and ([IO.Path]::GetFullPath($target) -ieq [IO.Path]::GetFullPath($normal))) {
        throw 'The pinned depot cannot replace or merge into the normal Steam installation.'
    }
    if (Test-Path -LiteralPath $target -PathType Container) {
        if (-not (Test-DarktideDepotMarker -Path $target) -and
            -not (Test-DarktideDepotMarker -Path $target -MarkerName $DARKTIDE_DEPOT_STAGING_MARKER)) {
            throw 'The selected existing folder is not a Hub-created partial Darktide depot. Choose an empty, new destination.'
        }
    }

    $steamRoot=Get-SteamPath
    $sources=@{}
    foreach ($row in $DARKTIDE_DEPOTS) {
        if ((Test-Path -LiteralPath $target -PathType Container) -and
            (Test-Path -LiteralPath (Join-Path $target $row.Proof) -PathType Leaf)) { continue }
        $source=Find-SteamDepotPath -AppId $APP_ID -DepotId $row.DepotId -GameExe $row.Proof -AdditionalSteamRoots @($steamRoot)
        if (-not $source) {
            $command="download_depot $APP_ID $($row.DepotId) $($row.Manifest)"
            Write-Host ''
            Write-Host "  Required $($row.Label) depot $($row.DepotId):" -ForegroundColor White
            Write-Host "  $command" -ForegroundColor DarkGray
            [void](Wait-PCVRExplicitEnter -Message "Press Enter to copy this command and open Steam Console...")
            try { Set-Clipboard -Value $command -DeferManualFallback } catch {}
            foreach ($uri in @('steam://open/console','steam://nav/console')) {
                try { Start-Process $uri; Start-Sleep -Milliseconds 700 } catch {}
            }
            Show-PCVRClipboardManualFallback -Text $command
            Write-Host '  Paste with Ctrl+V in Steam Console and wait for the download' -ForegroundColor White
            Write-Host "  of depot_$($row.DepotId) to complete." -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter here only after that depot has finished...')
            $source=Find-SteamDepotPath -AppId $APP_ID -DepotId $row.DepotId -GameExe $row.Proof -AdditionalSteamRoots @($steamRoot)
            if (-not $source) {
                $probes=@(Get-SteamDepotProbePaths -AppId $APP_ID -DepotId $row.DepotId -AdditionalSteamRoots @($steamRoot))
                $source=Resolve-DepotPath -GameName "Darktide build $DARKTIDE_DEPOT_BUILD, depot $($row.DepotId)" `
                    -DepotCommand $command -GameExe $row.Proof -ProbePaths $probes -AppId $APP_ID -DepotId $row.DepotId -Manifest $row.Manifest
            }
        }
        if (-not $source -or -not (Test-Path -LiteralPath (Join-Path $source $row.Proof) -PathType Leaf)) {
            throw "Pinned depot $($row.DepotId) did not provide $($row.Proof)."
        }
        $sources[$row.DepotId]=$source
    }

    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        $mainSource=[string]$sources['1361211']
        if (-not $mainSource) { throw 'The main Darktide game-data depot is unavailable.' }
        [void](Merge-DirectoryTreeVerified -Source $mainSource -Destination $target -RemoveSource -Label 'Darktide game-data depot')
        [IO.File]::WriteAllText((Join-Path $target $DARKTIDE_DEPOT_STAGING_MARKER),(Get-DarktideDepotMarkerText),(New-Object Text.UTF8Encoding $false))
    }
    foreach ($row in $DARKTIDE_DEPOTS) {
        if (Test-Path -LiteralPath (Join-Path $target $row.Proof) -PathType Leaf) { continue }
        $source=[string]$sources[$row.DepotId]
        if (-not $source) { throw "The $($row.Label) depot is unavailable for the merge." }
        [void](Merge-DirectoryTreeVerified -Source $source -Destination $target -RemoveSource -Label "Darktide $($row.Label) depot")
    }
    foreach ($row in $DARKTIDE_DEPOTS) {
        if (-not (Test-Path -LiteralPath (Join-Path $target $row.Proof) -PathType Leaf)) { throw "The merged depot is missing $($row.Proof)." }
    }
    Write-DarktideDepotSupportFiles -GameRoot $target
    Remove-Item -LiteralPath (Join-Path $target $DARKTIDE_DEPOT_STAGING_MARKER) -Force -ErrorAction SilentlyContinue
    if (-not (Test-DarktidePinnedRoot -Path $target)) { throw 'The completed pinned Darktide root failed its route check.' }
    Write-DarkOK "Steam build $DARKTIDE_DEPOT_BUILD assembled at: $target"
    return (Get-Item -LiteralPath $target).FullName
}

function Test-DarktideWasActive([string]$GameRoot) {
    $loadOrder = Join-Path $GameRoot 'mods\mod_load_order.txt'
    $listed = $false
    try { $listed = [bool](Get-Content -LiteralPath $loadOrder -ErrorAction Stop | Where-Object { $_.Trim() -eq 'darktidevr' }) } catch {}
    return [bool]($listed -and (Test-Path -LiteralPath (Join-Path $GameRoot 'binaries\d3d12.dll') -PathType Leaf))
}
function Invoke-DarktideNativeTool {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList=@(),
        [Parameter(Mandatory=$true)][string]$FailureMessage,
        [switch]$IgnoreFailure
    )
    $resolvedPath=$null
    if (Test-Path -LiteralPath $FilePath -PathType Leaf) {
        $resolvedPath=(Get-Item -LiteralPath $FilePath -ErrorAction Stop).FullName
    } else {
        $command=Get-Command $FilePath -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $resolvedPath=$command.Source }
    }
    if (-not $resolvedPath) {
        if ($IgnoreFailure) { return $false }
        throw "$FailureMessage (publisher tool was not found)."
    }

    $previousPreference=$ErrorActionPreference
    $nativeOutput=@(); $nativeExitCode=$null; $invocationFailure=$null
    try {
        # Windows PowerShell 5 turns native stderr into ErrorRecord objects. Some
        # Darktide publisher tools print successful status there, so only their
        # process exit code may decide whether the transaction failed.
        $ErrorActionPreference='Continue'
        $global:LASTEXITCODE=$null
        try {
            $nativeOutput=@(& $resolvedPath @ArgumentList 2>&1)
            $nativeExitCode=$global:LASTEXITCODE
        } catch {
            $invocationFailure=$_.Exception.Message
        }
    } finally {
        $ErrorActionPreference=$previousPreference
    }
    foreach ($entry in @($nativeOutput)) {
        $line=[string]$entry
        if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Host ('  '+$line.TrimEnd()) -ForegroundColor Gray }
    }

    if ($invocationFailure -or $null -eq $nativeExitCode -or [int]$nativeExitCode -ne 0) {
        if ($IgnoreFailure) { return $false }
        if ($invocationFailure) { throw "$FailureMessage ($invocationFailure)" }
        if ($null -eq $nativeExitCode) { throw "$FailureMessage (publisher tool returned no exit code)." }
        throw "$FailureMessage (exit code $nativeExitCode)."
    }
    return $true
}
function global:Invoke-DarktideMode([string]$GameRoot,[ValidateSet('vr','flat','status')][string]$Mode,[string]$StateRoot='',[switch]$IgnoreFailure) {
    $scriptPath = Join-Path $GameRoot 'mods\darktidevr\darktidevr-mode.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        if ($IgnoreFailure) { return $false }
        throw 'The DarktideVR mode script is missing.'
    }
    $oldLocalAppData=$env:LOCALAPPDATA
    try {
        if ($StateRoot) {
            if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) { [void][IO.Directory]::CreateDirectory($StateRoot) }
            $env:LOCALAPPDATA=(Get-Item -LiteralPath $StateRoot).FullName
        }
        return [bool](Invoke-DarktideNativeTool -FilePath 'powershell.exe' `
            -ArgumentList @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath,'-Mode',$Mode,'-GameRoot',$GameRoot) `
            -FailureMessage "The publisher's Darktide $Mode mode switch failed" -IgnoreFailure:$IgnoreFailure)
    } finally {
        $env:LOCALAPPDATA=$oldLocalAppData
    }
}

function Save-DarktideSnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $records = @()
    foreach ($relative in @('mods\darktidevr','.pcvrhub_darktidevr_ownership.csv','.pcvrhub_darktidevr_backup','.pcvrhub_version')) {
        $source = Join-Path $GameRoot $relative
        $exists = Test-Path -LiteralPath $source
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists; IsDirectory=(Test-Path -LiteralPath $source -PathType Container) }
        if ($exists) { Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot ([IO.Path]::GetFileName($relative))) -Recurse -Force }
    }
    return $records
}
function Restore-DarktideSnapshot([string]$GameRoot,[string]$SnapshotRoot,$Records) {
    if (-not (Test-DarktideRoot $GameRoot)) { throw 'Rollback target is no longer a verified Darktide folder.' }
    foreach ($record in @($Records)) {
        $target = Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            $source = Join-Path $SnapshotRoot ([IO.Path]::GetFileName([string]$record.Relative))
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
        }
    }
}

function global:Invoke-DarktideVRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $snapshotRecords=$null; $changesStarted=$false; $wasActive=$false
    $installMode='Current'; $stateRoot=''
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Warhammer 40K: Darktide VR - Installer' -ForegroundColor Cyan
        Write-Host '  Installs: DarktideVR by Brobert-in-aus' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Native OpenXR VR with roomscale tracking,' -ForegroundColor White
        Write-Host '  tracked hands, hand-aimed weapons and controller menus.' -ForegroundColor White
        Write-Host '  Darktide Mod Loader and DMF are required; setup adds' -ForegroundColor Yellow
        Write-Host '  missing framework pieces and enables VR mode.' -ForegroundColor Yellow
        Write-Host '  A Darktide update can disable the loader or temporarily' -ForegroundColor Yellow
        Write-Host '  become unsupported until DarktideVR is updated.' -ForegroundColor Yellow
        Write-Host '  Setup patches the game executable with the publisher tool;' -ForegroundColor Gray
        Write-Host '  its pristine recovery copy and separate flat/VR settings remain.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  [1] Current game and newest DarktideVR prerelease' -ForegroundColor Cyan
        Write-Host '      Uses the normal Steam/Xbox installation and auto-updates the VR mod.' -ForegroundColor Gray
        Write-Host "  [2] Confirmed Steam build $DARKTIDE_DEPOT_BUILD with pinned VR stack" -ForegroundColor Cyan
        Write-Host "      Separate $DARKTIDE_DEPOT_DEFAULT_PATH copy; normal Steam files stay untouched." -ForegroundColor Gray
        Write-Host '      Darktide is online: a future Fatshark backend may reject an old client.' -ForegroundColor Yellow
        Write-Host '  [Q] Quit' -ForegroundColor Gray
        Write-Host ''
        $routeChoice=Read-DarkChoice -Allowed @('1','2','Q') -Prompt 'Select setup option'
        if ($routeChoice -eq 'Q') {
            Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
            return
        }
        $installMode=if ($routeChoice -eq '2') { 'Depot' } else { 'Current' }
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        if ($installMode -eq 'Depot') {
            $game=Install-DarktidePinnedDepot
            $stateRoot=Join-Path $game '.pcvrhub_darktide_state'
        } else {
            Write-DarkStep 1 5 'Locating Warhammer 40,000: Darktide'
            $game = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Warhammer 40,000 DARKTIDE') -ProbeExe $GAME_EXE -HubGameId 'warhammer-40k-darktide-vr'
            if (-not (Test-DarktideRoot $game)) {
                foreach ($candidate in @('C:\XboxGames\Warhammer 40,000- Darktide\Content')) {
                    if (Test-DarktideRoot $candidate) { $game=$candidate; break }
                }
            }
            if (-not (Test-DarktideRoot $game)) {
                $game = Get-GameFolderInteractive -GameName 'Warhammer 40,000 DARKTIDE' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/1361210/'
            }
        }
        if ($game -in @('quit','skip',$null) -or -not (Test-DarktideRoot $game)) { throw 'Setup cancelled before any game file was changed.' }
        $game=(Get-Item -LiteralPath $game).FullName
        if (Get-Process -Name Darktide -ErrorAction SilentlyContinue) { throw 'Darktide is running. Close it completely and run setup again.' }
        Write-DarkOK "Found: $game"

        Write-DarkStep 2 5 $(if ($installMode -eq 'Depot') { "Getting pinned DarktideVR $FALLBACK_TAG" } else { 'Getting the newest DarktideVR release, including prereleases' })
        $release = Get-DarktideVrRelease -InstallMode $installMode
        Write-DarkInfo "Release: $($release.Tag)"
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_darktidevr_'+[Guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'darktidevr.zip'
        $got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "DarktideVR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The DarktideVR release was not downloaded.' }
        $extract=Join-Path $work 'vr'; $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'DarktideVR release' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The DarktideVR archive could not be extracted.' }
        $vrPayload=Find-DarktideVrPayload $extract
        if (-not $vrPayload -or -not (Test-Path -LiteralPath (Join-Path $vrPayload 'mods\darktidevr\bin\darktidevr_native_capture.dll') -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $vrPayload 'mods\darktidevr\bin\darktidevr-xr-harness.exe') -PathType Leaf)) {
            throw 'The current release has no usable DarktideVR runtime payload.'
        }

        Write-DarkStep 3 5 $(if ($installMode -eq 'Depot') { 'Installing the pinned loader and framework dependencies' } else { 'Ensuring the shared Darktide loader and framework' })
        if ($installMode -eq 'Depot' -or -not (Test-DarktideLoader $game)) {
            $loader=Get-DarktideLoaderRelease -InstallMode $installMode; Write-DarkInfo "Darktide Mod Loader: $($loader.Tag)"
            $loaderArchive=Join-Path $work 'loader.zip'
            $gotLoader=Invoke-SafeDownload -Urls @([string]$loader.Url) -Destination $loaderArchive -Label "Darktide Mod Loader $($loader.Tag)" -ManualUrl ([string]$loader.PageUrl) -AllowSkip $false
            if (-not ($gotLoader -eq $true -or [string]$gotLoader -in @('retry','manual'))) { throw 'The Darktide Mod Loader was not downloaded.' }
            $loaderExtract=Join-Path $work 'loader'; $x=Expand-ArchiveOrFallback -ArchivePath $loaderArchive -DestinationFolder $loaderExtract -Label 'Darktide Mod Loader' -AllowSkip $false
            if ([string]$x -notin @('ok','manual','retry')) { throw 'The Darktide Mod Loader archive could not be extracted.' }
            $loaderPayload=Find-DarktideLoaderPayload $loaderExtract
            if (-not $loaderPayload) { throw 'The current loader package has no binaries\mod_loader runtime.' }
            [void](Install-OwnedModPayload -SourceRoot $loaderPayload -GameRoot $game -Identity 'darktidevr_loader' -KeepExistingRelativePaths @('mods\mod_load_order.txt'))
            if ($installMode -eq 'Depot') { Write-DarkOK "Pinned Darktide Mod Loader $LOADER_FALLBACK_TAG installed; load order preserved." }
            else { Write-DarkOK 'Missing Darktide Mod Loader files installed; existing load order preserved.' }
        } else { Write-DarkOK 'Existing functional Darktide Mod Loader preserved.' }
        if ($installMode -eq 'Depot' -or -not (Test-DarktideFramework $game)) {
            $dmfArchive=Join-Path $work 'dmf.zip'; $gotDmf=Invoke-SafeDownload -Urls @($DMF_URL) -Destination $dmfArchive -Label 'Darktide Mod Framework' -ManualUrl 'https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework' -AllowSkip $false
            if (-not ($gotDmf -eq $true -or [string]$gotDmf -in @('retry','manual'))) { throw 'Darktide Mod Framework was not downloaded.' }
            $dmfExtract=Join-Path $work 'dmf'; $x=Expand-ArchiveOrFallback -ArchivePath $dmfArchive -DestinationFolder $dmfExtract -Label 'Darktide Mod Framework' -AllowSkip $false
            if ([string]$x -notin @('ok','manual','retry')) { throw 'Darktide Mod Framework could not be extracted.' }
            $dmfPayload=Find-DarktideFrameworkPayload $dmfExtract
            if (-not $dmfPayload) { throw 'The framework package has no dmf\dmf.mod payload.' }
            $dmfStage=Join-Path $work 'dmf-stage\mods\dmf'; [void][IO.Directory]::CreateDirectory($dmfStage); Copy-DirectoryTreeVerified -Source $dmfPayload -Destination $dmfStage
            [void](Install-OwnedModPayload -SourceRoot (Join-Path $work 'dmf-stage') -GameRoot $game -Identity 'darktidevr_dmf')
            if ($installMode -eq 'Depot') { Write-DarkOK "Pinned Darktide Mod Framework commit $DMF_COMMIT installed." }
            else { Write-DarkOK 'Darktide Mod Framework installed.' }
        } else { Write-DarkOK 'Existing Darktide Mod Framework preserved.' }
        if (-not (Test-DarktideLoader $game) -or -not (Test-DarktideFramework $game)) { throw 'Shared Darktide dependencies are incomplete after setup.' }
        if ($installMode -eq 'Depot') {
            $stackText="GameBuild=$DARKTIDE_DEPOT_BUILD`r`nDarktideVR=$DEPOT_MOD_TAG`r`nDarktideModLoader=$LOADER_FALLBACK_TAG`r`nDarktideModFramework=$DMF_COMMIT"
            [IO.File]::WriteAllText((Join-Path $game $DARKTIDE_DEPOT_STACK_MARKER),$stackText,(New-Object Text.UTF8Encoding $false))
        }

        Write-DarkStep 4 5 'Installing the VR runtime and activating VR mode'
        Write-Host '  The publisher patchers now enable mod loading and Darktide VR.' -ForegroundColor White
        Write-Host '  Darktide must stay closed. Windows may request permission because' -ForegroundColor Yellow
        Write-Host '  the game folder and executable are being changed recoverably.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the two required publisher patchers...')
        $wasActive=Test-DarktideWasActive $game
        if ($wasActive) { [void](Invoke-DarktideMode -GameRoot $game -Mode flat -StateRoot $stateRoot) }
        $snapshot=Join-Path $work 'rollback'; $snapshotRecords=Save-DarktideSnapshot -GameRoot $game -SnapshotRoot $snapshot
        $changesStarted=$true
        [void](Install-OwnedModPayload -SourceRoot $vrPayload -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting)
        $patcher=Join-Path $game 'tools\dtkit-patch.exe'
        [void](Invoke-DarktideNativeTool -FilePath $patcher -ArgumentList @('--patch',(Join-Path $game 'bundle')) `
            -FailureMessage 'The Darktide Mod Loader bundle patch failed')
        [void](Invoke-DarktideMode -GameRoot $game -Mode vr -StateRoot $stateRoot)
        $watch=@('mods\darktidevr\bin\darktidevr_native_capture.dll','mods\darktidevr\bin\darktidevr-xr-harness.exe','binaries\d3d12.dll') | ForEach-Object { Join-Path $game $_ }
        $recopy={ [void](Install-OwnedModPayload -SourceRoot $vrPayload -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting); [void](Invoke-DarktideMode -GameRoot $game -Mode vr -StateRoot $stateRoot) }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recopy)) { throw 'Required DarktideVR runtime files did not survive antivirus recovery.' }

        Write-DarkStep 5 5 $(if ($installMode -eq 'Depot') { 'Verifying the isolated pinned launch route' } else { 'Verifying the tracked store launch route' })
        $receipt=Join-Path $PSScriptRoot $(if ($installMode -eq 'Depot') { '.installed_path_depot' } else { '.installed_path' })
        $selectedContract=if ($installMode -eq 'Depot') { $depotContract } else { $contract }
        $routeName=if ($installMode -eq 'Depot') { "Depot-$DARKTIDE_DEPOT_BUILD" } else { 'Current' }
        [void](Complete-PCVRInstallTransaction -Contract $selectedContract -GameDir $game -Version ([string]$release.Tag) -InstalledPathReceiptPaths @($receipt) -Route $routeName)
        $changesStarted=$false
        Write-DarkOK "DarktideVR $($release.Tag) is active and tracked."
        Write-Host '  Connect the selected OpenXR runtime, then use Start in VR from the Hub.' -ForegroundColor White
        if ($installMode -eq 'Depot') {
            try {
                $shortcut=New-DesktopShortcut -ShortcutName "Darktide VR $DARKTIDE_DEPOT_BUILD" -TargetPath (Join-Path $game 'Start Darktide VR Depot.bat') -WorkingDir $game -IconPath (Join-Path $game 'launcher\launcher.exe') -Description "Darktide Steam build $DARKTIDE_DEPOT_BUILD with pinned DarktideVR"
                if ($shortcut) { Write-DarkOK "Desktop shortcut created: Darktide VR $DARKTIDE_DEPOT_BUILD" }
            } catch { Write-DarkWarn 'The optional desktop shortcut could not be created; use the Hub button.' }
            Write-Host '  Keep Steam signed in. The Depot button starts its own Fatshark launcher;' -ForegroundColor White
            Write-Host '  press Play there. It never redirects to the normal Steam game folder.' -ForegroundColor White
            Write-Host '  Use Switch Darktide Depot Mode.bat for flat/VR switching in this copy.' -ForegroundColor Gray
        } else {
            Write-Host '  For Steam, the Hub opens Steam; press Play in the Fatshark launcher.' -ForegroundColor White
        }
        Write-Host '  Calibrate the two-pose body height when prompted; mod options contain' -ForegroundColor Gray
        Write-Host '  turning, HUD, aim-pitch and experimental keyboard/mouse settings.' -ForegroundColor Gray
        Write-Host ''
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host '  Setup complete.' -ForegroundColor Green; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot) {
            try {
                [void](Invoke-DarktideMode -GameRoot $game -Mode flat -StateRoot $stateRoot -IgnoreFailure)
                [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $IDENTITY)
                Restore-DarktideSnapshot -GameRoot $game -SnapshotRoot $snapshot -Records $snapshotRecords
                if ($wasActive) { [void](Invoke-DarktideMode -GameRoot $game -Mode vr -StateRoot $stateRoot -IgnoreFailure) }
                Write-DarkWarn 'The prior DarktideVR package and mode were restored.'
            } catch { Write-DarkWarn "Rollback needs review: $($_.Exception.Message)" }
        }
        Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red; throw
    } finally { if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($env:PCVR_DARKTIDEVR_LIBRARY_ONLY -ne '1') { Invoke-DarktideVRInstaller }
