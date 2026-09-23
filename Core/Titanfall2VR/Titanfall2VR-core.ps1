# Titanfall 2 VR - governed GitHub prerelease installer.
# Steam or EA App base game; current stable Northstar is installed only when
# absent and intentionally remains on VR removal; personal INI survives.

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Titanfall 2 VR Installer'
$APP_ID='1237970';$GAME_EXE='Titanfall2.exe';$REPO='TinyBlkDog/titanfall2vr';$RELEASES="https://github.com/$REPO/releases"
$FALLBACK_TAG='v0.1.1-alpha';$FALLBACK_NAME='titanfall2vr-v0.1.1.zip';$FALLBACK_URL='https://github.com/TinyBlkDog/titanfall2vr/releases/download/v0.1.1-alpha/titanfall2vr-v0.1.1.zip'
$NORTHSTAR_REPO='R2Northstar/Northstar';$NORTHSTAR_TAG='v1.31.13';$NORTHSTAR_NAME='Northstar.release.v1.31.13.zip';$NORTHSTAR_URL='https://github.com/R2Northstar/Northstar/releases/download/v1.31.13/Northstar.release.v1.31.13.zip'
$IDENTITY='titanfall2vr';$QUIP='Stand by for Titanfall, now at full human scale.'
$contract=New-PCVRInstallerContract -Id 'titanfall-2-vr' -GameName 'Titanfall 2 VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES `
    -RequiredInstalledFileGroups @('R2Northstar\plugins\titanfall2vr.dll','NorthstarLauncher.exe','.pcvrhub_titanfall2vr_ownership.csv')

function Write-TFStep([int]$Number,[int]$Total,[string]$Text){Write-Host '';Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan;Write-Host ''}
function Write-TFOK([string]$Text){Write-Host "  [OK] $Text" -ForegroundColor Green}
function Write-TFInfo([string]$Text){Write-Host "  [..] $Text" -ForegroundColor Gray}
function Write-TFWarn([string]$Text){Write-Host "  [!!] $Text" -ForegroundColor Yellow}
function Test-TitanfallRoot([string]$Path){return [bool]($Path -and(Test-Path -LiteralPath (Join-Path $Path 'Titanfall2.exe') -PathType Leaf))}
function Test-Northstar([string]$Path){return [bool]($Path -and(Test-Path -LiteralPath (Join-Path $Path 'NorthstarLauncher.exe') -PathType Leaf) -and(Test-Path -LiteralPath (Join-Path $Path 'R2Northstar') -PathType Container))}
function Find-TitanfallVrPayload([string]$ExtractRoot){$dll=Get-ChildItem -LiteralPath $ExtractRoot -Filter 'titanfall2vr.dll' -File -Recurse -ErrorAction SilentlyContinue|Select-Object -First 1;if($dll){return $dll.DirectoryName};return $null}
function Find-NorthstarPayload([string]$ExtractRoot){$exe=Get-ChildItem -LiteralPath $ExtractRoot -Filter 'NorthstarLauncher.exe' -File -Recurse -ErrorAction SilentlyContinue|Select-Object -First 1;if($exe){return $exe.DirectoryName};return $null}
function Save-TitanfallSnapshot([string]$GameRoot,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot);$records=@()
    foreach($relative in @('R2Northstar\plugins\titanfall2vr.dll','R2Northstar\plugins\titanfall2vr.ini','R2Northstar\plugins\titanfall2vr.headset.cache','.pcvrhub_titanfall2vr_ownership.csv','.pcvrhub_titanfall2vr_backup','.pcvrhub_version')){$source=Join-Path $GameRoot $relative;$exists=Test-Path -LiteralPath $source;$records+=[pscustomobject]@{Relative=$relative;Exists=$exists};if($exists){$copy=Join-Path $SnapshotRoot ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_'));Copy-Item -LiteralPath $source -Destination $copy -Recurse -Force}}
    return $records
}
function Restore-TitanfallSnapshot([string]$GameRoot,[string]$SnapshotRoot,$Records){if(-not(Test-TitanfallRoot $GameRoot)){throw 'Rollback target is no longer a verified Titanfall 2 folder.'};foreach($record in @($Records)){$target=Join-Path $GameRoot ([string]$record.Relative);if(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue};if($record.Exists){$copy=Join-Path $SnapshotRoot ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$record.Relative)).Replace('/','_'));$parent=Split-Path -Parent $target;if(-not(Test-Path $parent)){[void][IO.Directory]::CreateDirectory($parent)};Copy-Item -LiteralPath $copy -Destination $target -Recurse -Force}}}

function global:Invoke-Titanfall2VRInstaller{
    $work=$null;$game=$null;$snapshot=$null;$records=$null;$changesStarted=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Titanfall 2 VR - Installer' -ForegroundColor Cyan;Write-Host '  Installs: titanfall2vr by TinyBlkDog' -ForegroundColor Gray;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Alpha VR for Titanfall 2''s single-player campaign with' -ForegroundColor White
        Write-Host '  stereo OpenXR, 6DoF head tracking and hand-aimed weapons.' -ForegroundColor White
        Write-Host '  Northstar is required; setup installs its current stable release' -ForegroundColor Yellow
        Write-Host '  only when a functional Northstar installation is not found.' -ForegroundColor Yellow
        Write-Host '  Steam users must disable the Steam Overlay for Titanfall 2.' -ForegroundColor Yellow
        Write-Host '  Do not use this alpha on official multiplayer servers.' -ForegroundColor Red
        Write-Host '  On first launch, EA/Origin may update before the game can start;' -ForegroundColor Yellow
        Write-Host '  when it finishes, use Start in VR again.' -ForegroundColor Yellow
        Write-Host '  The opening look-at-lights prompt can stay frozen in the headset.' -ForegroundColor Gray
        Write-Host '  Complete it on the monitor with the mouse, or play that tutorial flat first.' -ForegroundColor Gray
        Write-Host '  Existing titanfall2vr settings and Northstar are preserved.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        Write-TFStep 1 4 'Locating Titanfall 2'
        $game=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Titanfall2') -ProbeExe $GAME_EXE -HubGameId 'titanfall-2-vr'
        if(-not(Test-TitanfallRoot $game)){foreach($candidate in @('C:\Program Files\EA Games\Titanfall2','C:\Program Files (x86)\Origin Games\Titanfall2','D:\EA Games\Titanfall2','E:\EA Games\Titanfall2')){if(Test-TitanfallRoot $candidate){$game=$candidate;break}}}
        if(-not(Test-TitanfallRoot $game)){$game=Get-GameFolderInteractive -GameName 'Titanfall2' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/1237970/'}
        if($game -in @('quit','skip',$null) -or -not(Test-TitanfallRoot $game)){throw 'Setup cancelled before any game file was changed.'};$game=(Get-Item $game).FullName
        if(Get-Process -Name Titanfall2,NorthstarLauncher -ErrorAction SilentlyContinue){throw 'Titanfall 2 or Northstar is running. Close it completely and retry.'};Write-TFOK "Found: $game"

        Write-TFStep 2 4 'Getting the newest titanfall2vr release, including prereleases'
        $release=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -AssetPatterns @('(?i)^titanfall2vr-v?[0-9].*\.zip$') -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_NAME
        Write-TFInfo "Prerelease: $($release.Tag)";$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_titanfall2vr_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'titanfall2vr.zip';$got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "titanfall2vr $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if(-not($got -eq $true -or [string]$got -in @('retry','manual'))){throw 'The titanfall2vr release was not downloaded.'}
        $extract=Join-Path $work 'vr';$x=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'titanfall2vr release' -AllowSkip $false
        if([string]$x -notin @('ok','manual','retry')){throw 'The titanfall2vr archive could not be extracted.'};$payload=Find-TitanfallVrPayload $extract
        if(-not $payload -or -not(Test-Path -LiteralPath (Join-Path $payload 'titanfall2vr.ini') -PathType Leaf)){throw 'The current release has no usable titanfall2vr DLL and INI pair.'}

        Write-TFStep 3 4 'Ensuring Northstar and installing the VR plugin'
        if(-not(Test-Northstar $game)){
            Write-TFInfo 'A functional Northstar installation was not found; downloading the current stable release.'
            $northstar=Resolve-GitHubReleaseAsset -Repo $NORTHSTAR_REPO -AssetPatterns @('(?i)^Northstar\.release\.v?[0-9].*\.zip$') -FallbackUrl $NORTHSTAR_URL -FallbackTag $NORTHSTAR_TAG -FallbackAssetName $NORTHSTAR_NAME
            $northArchive=Join-Path $work 'Northstar.zip';$gotNorth=Invoke-SafeDownload -Urls @([string]$northstar.Url) -Destination $northArchive -Label "Northstar $($northstar.Tag)" -ManualUrl ([string]$northstar.PageUrl) -AllowSkip $false
            if(-not($gotNorth -eq $true -or [string]$gotNorth -in @('retry','manual'))){throw 'Northstar was not downloaded.'};$northExtract=Join-Path $work 'northstar';$x=Expand-ArchiveOrFallback -ArchivePath $northArchive -DestinationFolder $northExtract -Label 'Northstar release' -AllowSkip $false
            if([string]$x -notin @('ok','manual','retry')){throw 'Northstar could not be extracted.'};$northPayload=Find-NorthstarPayload $northExtract;if(-not $northPayload){throw 'The current Northstar package has no NorthstarLauncher.exe.'}
            [void](Install-OwnedModPayload -SourceRoot $northPayload -GameRoot $game -Identity 'titanfall2vr_northstar' -AdoptIdenticalExisting);Write-TFOK "Northstar $($northstar.Tag) installed."
        }else{Write-TFOK 'Existing functional Northstar installation preserved.'}
        Write-Host '  The VR plugin is now copied to R2Northstar\plugins.' -ForegroundColor White
        Write-Host '  Windows may request PowerShell permission for a protected game folder.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the VR plugin...')
        $snapshot=Join-Path $work 'rollback';$records=Save-TitanfallSnapshot -GameRoot $game -SnapshotRoot $snapshot;$changesStarted=$true
        $stage=Join-Path $work 'stage\R2Northstar\plugins';[void][IO.Directory]::CreateDirectory($stage);Copy-Item -LiteralPath (Join-Path $payload 'titanfall2vr.dll') -Destination (Join-Path $stage 'titanfall2vr.dll') -Force
        [void](Install-OwnedModPayload -SourceRoot (Join-Path $work 'stage') -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting)
        $ini=Join-Path $game 'R2Northstar\plugins\titanfall2vr.ini';if(-not(Test-Path -LiteralPath $ini -PathType Leaf)){Copy-Item -LiteralPath (Join-Path $payload 'titanfall2vr.ini') -Destination $ini -Force;Write-TFOK 'Documented default settings INI installed.'}else{Write-TFOK 'Existing titanfall2vr.ini settings preserved.'}
        $cacheSource=Join-Path $payload 'optional\titanfall2vr.headset.cache'
        if(Test-Path -LiteralPath $cacheSource -PathType Leaf){Write-Host '';Write-Host '  The package includes an optional Quest 3 + VDXR cache.' -ForegroundColor White;Write-Host '  It skips the first-minute geometry calibration only on an exact match;' -ForegroundColor Gray;Write-Host '  other headsets ignore it. Install this optional cache? [Y/N]' -ForegroundColor Yellow;$answer=(''+(Read-Host '  Choice')).Trim().ToUpperInvariant();if($answer -eq 'Y'){Copy-Item -LiteralPath $cacheSource -Destination (Join-Path $stage 'titanfall2vr.headset.cache') -Force;[void](Install-OwnedModPayload -SourceRoot (Join-Path $work 'stage') -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting);Write-TFOK 'Optional headset cache installed.'}}
        $watch=@(Join-Path $game 'R2Northstar\plugins\titanfall2vr.dll');$recopy={ [void](Install-OwnedModPayload -SourceRoot (Join-Path $work 'stage') -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting) }.GetNewClosure()
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recopy)){throw 'The titanfall2vr plugin did not survive antivirus recovery.'}

        Write-TFStep 4 4 'Verifying the Northstar launch route'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current);$changesStarted=$false
        Write-TFOK "titanfall2vr $($release.Tag) is installed and tracked."
        Write-Host '  Set the OpenXR runtime, connect the headset and use Start in VR.' -ForegroundColor White
        Write-Host '  The Hub launches NorthstarLauncher.exe; start the campaign there.' -ForegroundColor White
        Write-Host '  Click both thumbsticks for settings. The mod starts at 75% resolution;' -ForegroundColor Yellow
        Write-Host '  raise Resolution toward 100% only while frame rate remains stable.' -ForegroundColor Yellow
        Write-Host '';Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Setup complete.' -ForegroundColor Green;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '';Write-Host "  $QUIP" -ForegroundColor Magenta;Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{if($changesStarted -and $game -and $snapshot){try{Restore-TitanfallSnapshot -GameRoot $game -SnapshotRoot $snapshot -Records $records;Write-TFWarn 'The previous titanfall2vr plugin state was restored.'}catch{Write-TFWarn "Rollback needs review: $($_.Exception.Message)"}};Write-Host '';Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red;throw
    }finally{if($work -and(Test-Path $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_TITANFALL2VR_LIBRARY_ONLY -ne '1'){Invoke-Titanfall2VRInstaller}
