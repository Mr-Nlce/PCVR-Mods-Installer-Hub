# Deus Ex: Human Revolution Director's Cut VR - governed GitHub prerelease installer.
# Only the publisher-supported Steam Director's Cut 2.0.66.0 executable is
# accepted. The four native bridge files are owned together; user INI settings
# and unrelated files are preserved across updates and removal.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'DeusExHRVRElevatedOperations.ps1')
. (Join-Path $PSScriptRoot 'DeusExHRVRElevatedWorker.ps1')

$Host.UI.RawUI.WindowTitle = "Deus Ex: Human Revolution Director's Cut VR Installer"
$APP_ID='238010'
$GAME_EXE='DXHRDC.exe'
$REPO='farmerarmor/DeusExHRVR'
$RELEASES="https://github.com/$REPO/releases"
$FALLBACK_TAG='v0.3.0'
$FALLBACK_ASSET='DeusExHRVR-0.3.0-release.zip'
$FALLBACK_URL='https://github.com/farmerarmor/DeusExHRVR/releases/download/v0.3.0/DeusExHRVR-0.3.0-release.zip'
$EXPECTED_EXE_SHA256='8266B6B4A5BF25F2F4E8DE068AA3720F6289C962BB1C2BB70A7B1C111BA510A1'
$HIGH_CORE_EXE_SHA256='B883591D023650B91C5C8D052C299AE23FE050DB66A221192035C3A9542D7F28'
$QUIP='Human revolution was only the beginning. Augmented reality just became literal.'
$REQUIRED_PAYLOAD=@('d3d11.dll','atidxx32.dll','atiadlxy.dll','DeusExHRVR\DeusExHRVRHost.exe')

function Write-DeusExStep([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-DeusExOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-DeusExWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function global:Test-DeusExRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function global:Find-DeusExReleasePayload([string]$ExtractRoot) {
    foreach ($dll in @(Get-ChildItem -LiteralPath $ExtractRoot -Filter 'd3d11.dll' -File -Recurse -ErrorAction SilentlyContinue)) {
        $root=$dll.DirectoryName
        $valid=$true
        foreach ($relative in $REQUIRED_PAYLOAD) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { $valid=$false; break }
        }
        if ($valid) { return $root }
    }
    return $null
}

function global:New-DeusExVrConfig {
    param([Parameter(Mandatory=$true)][string]$ExamplePath,[Parameter(Mandatory=$true)][string]$Destination)
    $text=[IO.File]::ReadAllText($ExamplePath)
    $values=[ordered]@{
        WorldUnitsPerMetre='300'
        LockVerticalCamera='1'
        MotionControls='1'
        InteractionAim='Headset'
        MovementDirection='Headset'
        ExperimentalMotionControls='1'
    }
    foreach ($name in $values.Keys) {
        $pattern='(?m)^\s*' + [regex]::Escape($name) + '\s*=.*$'
        if (-not [regex]::IsMatch($text,$pattern)) { throw "The publisher configuration example is missing $name." }
        $text=[regex]::Replace($text,$pattern,("$name=" + $values[$name]),1)
    }
    [IO.File]::WriteAllText($Destination,$text,(New-Object Text.UTF8Encoding $false))
}

function global:New-DeusExVrStage([string]$Payload,[string]$ExamplePath,[string]$WorkRoot) {
    $stage=Join-Path $WorkRoot 'stage'
    foreach ($relative in $REQUIRED_PAYLOAD) {
        $source=Join-Path $Payload $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "The current release is missing $relative." }
        $target=Join-Path $stage $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
    }
    New-DeusExVrConfig -ExamplePath $ExamplePath -Destination (Join-Path $stage 'DeusExHRVR.ini')
    return $stage
}

function global:Add-DeusExHighCoreFixToStage([string]$GameRoot,[string]$Stage) {
    $patched=Join-Path $Stage 'DXHRDC.exe'
    [void](New-DeusExHighCoreExecutable -SourceExe (Join-Path $GameRoot 'DXHRDC.exe') -DestinationExe $patched `
        -ExpectedOriginalSha256 $EXPECTED_EXE_SHA256 -ExpectedPatchedSha256 $HIGH_CORE_EXE_SHA256)
    [IO.File]::WriteAllText((Join-Path $Stage '.pcvrhub_deusexhrvr_highcore'),
        "DXHRDC.exe SHA256=$HIGH_CORE_EXE_SHA256`r`nPatchOffset=864613`r`nBytes=E8 46 F0 FF FF -> 90 90 90 90 90`r`n",
        (New-Object Text.UTF8Encoding $false))
}

function global:Save-DeusExSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot,[ValidateSet('Windows','Fixture')][string]$RegistryBackend='Windows',[string]$FixtureRegistryPath='') {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths=[Collections.Generic.List[string]]::new()
    foreach ($relative in @($REQUIRED_PAYLOAD + @('DXHRDC.exe','DeusExHRVR.ini','.pcvrhub_deusexhrvr_highcore','.pcvrhub_deusexhrvr_ownership.csv','.pcvrhub_deusexhrvr_ownership.csv.new','.pcvrhub_deusexhrvr_registry.json','.pcvrhub_version'))) { $paths.Add($relative) }
    $manifest=Join-Path $GameRoot '.pcvrhub_deusexhrvr_ownership.csv'
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $paths.Add([string]$row.RelativePath) } } } catch {}
    }
    $records=@()
    foreach ($relative in @($paths | Select-Object -Unique)) {
        $source=Join-Path $GameRoot $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Existed=$exists}
        if ($exists) {
            $copy=Join-Path (Join-Path $SnapshotRoot 'files') $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $records | Export-Csv -LiteralPath (Join-Path $SnapshotRoot 'records.csv') -NoTypeInformation -Encoding UTF8
    $backup=Join-Path $GameRoot '.pcvrhub_deusexhrvr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop }
    $registry=Get-DeusExRegistryState -Backend $RegistryBackend -FixturePath $FixtureRegistryPath
    [IO.File]::WriteAllText((Join-Path $SnapshotRoot 'registry-current.json'),($registry | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
    return $SnapshotRoot
}

function global:Install-DeusExPayload([string]$GameRoot,[string]$Stage,[string]$Version,[string]$SnapshotRoot) {
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-InstallerTargetWritable -TargetPath $GameRoot) {
        $result=Install-DeusExVrOwnedPayload -GameRoot $GameRoot -SourceRoot $Stage -Version $Version -InstalledPathReceipt $receipt
    } else {
        Write-Host '  Copying into the Steam game folder needs administrator rights.' -ForegroundColor Yellow
        Write-Host '  The next UAC request is only for the recoverable VR-file and graphics-settings transaction.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to request administrator rights and install the VR files...')
        $result=Invoke-DeusExHRVRElevatedOperation -Action Install -GameRoot $GameRoot -SourceRoot $Stage -Version $Version -SnapshotRoot $SnapshotRoot
    }
    if ($result -and [string]$result.FailureKind -eq 'MissingAfterCopy') {
        $watch=@($REQUIRED_PAYLOAD + @('DXHRDC.exe','.pcvrhub_deusexhrvr_highcore') | ForEach-Object { Join-Path $GameRoot $_ })
        $recopy={
            if (Test-InstallerTargetWritable -TargetPath $GameRoot) {
                $retry=Install-DeusExVrOwnedPayload -GameRoot $GameRoot -SourceRoot $Stage -Version $Version -InstalledPathReceipt $receipt
            } else {
                $retry=Invoke-DeusExHRVRElevatedOperation -Action Install -GameRoot $GameRoot -SourceRoot $Stage -Version $Version -SnapshotRoot $SnapshotRoot
            }
            if (-not $retry -or -not [bool]$retry.Success) { throw ([string]$retry.Error) }
        }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $GameRoot -Recopy $recopy -NoClear)) { throw 'Required Deus Ex HR VR files are still missing.' }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -PathType Leaf)) { throw 'The exact installed-version receipt was not committed.' }
}

function global:Invoke-DeusExHRVRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $changesStarted=$false; $usedElevation=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host "  Deus Ex: Human Revolution Director's Cut VR" -ForegroundColor Cyan
        Write-Host '  Installs: DeusExHRVR by farmerarmor' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  Experimental native same-frame OpenXR stereo with headset tracking,' -ForegroundColor White
        Write-Host '  motion-controlled weapons and Xbox-style motion-controller input.' -ForegroundColor White
        Write-Host "  This prerelease supports only Steam Director's Cut 2.0.66.0." -ForegroundColor Yellow
        Write-Host "  GOG and the original non-Director's Cut game are not supported." -ForegroundColor Yellow
        Write-Host '  Oculus and VDXR are reported working; the current SteamVR runtime' -ForegroundColor Gray
        Write-Host '  is not confirmed and has current black-screen reports.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start setup...')

        Write-DeusExStep 1 4 "Locating the supported Steam Director's Cut"
        $game=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Deus Ex Human Revolution Director's Cut") -ProbeExe $GAME_EXE -HubGameId 'deus-ex-human-revolution-directors-cut-vr'
        if (-not (Test-DeusExRoot $game)) {
            $game=Get-GameFolderInteractive -GameName "Deus Ex: Human Revolution Director's Cut (Steam)" -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/238010/'
        }
        if ($game -in @('quit','skip',$null) -or -not (Test-DeusExRoot $game)) { throw 'Setup stopped before any game file was changed.' }
        $game=(Get-Item -LiteralPath $game).FullName
        if (-not (Test-DeusExSupportedExecutable -GameRoot $game -ExpectedSha256 $EXPECTED_EXE_SHA256 -ExpectedPatchedSha256 $HIGH_CORE_EXE_SHA256)) {
            throw "DXHRDC.exe is not the supported Steam Director's Cut 2.0.66.0 build. GOG, the original edition and other executable versions are not modified."
        }
        if (Get-Process -Name 'DXHRDC','DeusExHRVRHost' -ErrorAction SilentlyContinue) { throw 'Deus Ex or its VR host is running. Close it completely and retry.' }
        Write-DeusExOK "Supported Steam build verified: $game"

        Write-DeusExStep 2 4 'Getting the newest installable GitHub prerelease'
        $release=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset `
            -AssetPatterns @('(?i)^DeusExHRVR-[0-9].*-release\.zip$') `
            -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_deusexhrvr_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'DeusExHRVR-release.zip'
        $downloaded=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "DeusExHRVR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($downloaded -eq $true -or [string]$downloaded -in @('retry','manual'))) { throw 'The DeusExHRVR prerelease was not downloaded.' }
        Write-DeusExOK "Selected publisher asset for $($release.Tag)."

        Write-DeusExStep 3 4 'Validating and staging the native stereo bridge'
        $extract=Join-Path $work 'release'
        $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'DeusExHRVR release' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The DeusExHRVR archive could not be extracted.' }
        $payload=Find-DeusExReleasePayload $extract
        if (-not $payload) { throw 'The current prerelease has no complete four-file native bridge.' }
        $example=Get-ChildItem -LiteralPath $extract -Filter 'DeusExHRVR.ini.example' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $example) { throw 'The current prerelease has no configuration example.' }
        $stage=New-DeusExVrStage -Payload $payload -ExamplePath $example.FullName -WorkRoot $work
        Add-DeusExHighCoreFixToStage -GameRoot $game -Stage $stage
        Write-DeusExOK 'Four runtime files, motion-control settings and the reviewed high-core fix are staged.'

        Write-DeusExStep 4 4 'Installing recoverably and enabling the tested graphics mode'
        Write-Host '  Setup preserves an existing DeusExHRVR.ini and backs up every file' -ForegroundColor White
        Write-Host '  it replaces, including the original game executable.' -ForegroundColor White
        Write-Host '  A five-byte high-core compatibility fix prevents the verified' -ForegroundColor Yellow
        Write-Host '  startup crash on CPUs with many logical processors.' -ForegroundColor Yellow
        Write-Host '  DX11/native stereo are enabled;' -ForegroundColor White
        Write-Host '  VSync and game antialiasing are disabled for the tested mode.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the VR runtime and graphics settings...')
        $snapshot=Save-DeusExSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback')
        $changesStarted=$true
        $usedElevation=-not (Test-InstallerTargetWritable -TargetPath $game)
        Install-DeusExPayload -GameRoot $game -Stage $stage -Version ([string]$release.Tag) -SnapshotRoot $snapshot
        $changesStarted=$false
        Write-DeusExOK "DeusExHRVR $($release.Tag) and the recoverable high-core fix are installed."

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Setup complete.' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  1. Use Start in VR in the Hub, then load a save.' -ForegroundColor Yellow
        Write-Host '  2. Launching normally through Steam is the fallback.' -ForegroundColor White
        Write-Host '  Gameplay enters VR automatically. Press [F9] to recenter.' -ForegroundColor White
        Write-Host '  Menus, hacking, videos and the sniper scope use a virtual screen.' -ForegroundColor Gray
        Write-Host '  The complete controls and current prerelease limits are on the game page.' -ForegroundColor Gray
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot) {
            try {
                if ($usedElevation) { [void](Invoke-DeusExHRVRElevatedOperation -Action Restore -GameRoot $game -SnapshotRoot $snapshot) }
                else { Restore-DeusExSnapshot -GameRoot $game -SnapshotRoot $snapshot }
                Write-DeusExWarn 'The previous Deus Ex game and graphics state was restored.'
            } catch { Write-DeusExWarn ('Rollback also needs attention: ' + $_.Exception.Message) }
        }
        Write-Host ''; Write-Host ('  [XX] ' + $_.Exception.Message) -ForegroundColor Red
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_DEUSEXHRVR_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-DeusExHRVRInstaller }
