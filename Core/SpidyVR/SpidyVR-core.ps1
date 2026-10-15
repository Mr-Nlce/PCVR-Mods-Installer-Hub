$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Spider-Man Remastered - Spidy VR Installer'
$script:SpidyId='spiderman-remastered-spidy-vr'
$script:SpidyPage='https://github.com/IlyaMez/SpidyVR/releases'
$script:SpidyRequired=@('Spidy Launcher.exe','build\windows-ninja\spidy_bridge.dll',
    'build\windows-ninja\spidy_movement_bridge.dll','build\windows-ninja\spidy_ray_bridge.dll',
    'python\python.exe','python\python312.dll','tools\vr_launcher.py','tools\run_game_vr.py',
    '.pcvrhub_spidy_ownership.csv')
$script:SpidyContract=New-PCVRInstallerContract -Id $script:SpidyId -GameName 'Spider-Man Remastered - Spidy VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:SpidyPage -RequiredInstalledFileGroups $script:SpidyRequired

function Assert-SpidyFixture([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path)
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
        -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'spidy-fixture.txt') -PathType Leaf)){
        throw 'Spidy test paths must stay in an isolated temporary fixture.'
    }
    return $full
}
function Test-SpidyGame([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Spider-Man.exe') -PathType Leaf))
}
function Get-SpidyGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_GAME){
        $root=Assert-SpidyFixture $env:PCVR_SPIDY_TEST_GAME
        if(-not(Test-SpidyGame $root)){throw 'The isolated Steam game lacks Spider-Man.exe.'}
        return $root
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:SpidyId -StateNames @('base_game_path','user_located') -ProbeFiles @('Spider-Man.exe')
    if(Test-SpidyGame $saved){return $saved}
    $found=Find-SteamGameFolder -AppId '1817070' -SteamFolderNames @("Marvel's Spider-Man Remastered") `
        -ProbeExe 'Spider-Man.exe' -HubGameId $script:SpidyId
    if(Test-SpidyGame $found){return $found}
    $picked=Get-GameFolderInteractive -GameName "Marvel's Spider-Man Remastered (Steam)" -ProbeFile 'Spider-Man.exe' `
        -ManualUrl 'https://store.steampowered.com/app/1817070/'
    if(Test-SpidyGame $picked){return $picked}
    return $null
}
function Get-SpidyTarget {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_ROOT){
        return (Assert-SpidyFixture $env:PCVR_SPIDY_TEST_ROOT)
    }
    $candidates=@((Join-Path $env:LOCALAPPDATA 'SpidyVR'),'D:\Games\SpidyVR','E:\Games\SpidyVR')
    $preserved=@($candidates|Where-Object {Test-Path -LiteralPath ([IO.Path]::Combine($_,'.pcvrhub_spidy_preserved.csv')) -PathType Leaf})
    if($preserved.Count -gt 0){
        throw "Previously changed Spidy files were preserved in $($preserved[0]). Review them before reinstalling."
    }
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    $recorded=if(Test-Path -LiteralPath $receipt -PathType Leaf){([IO.File]::ReadAllText($receipt)).Trim()}else{''}
    $owned=@($candidates|Where-Object {Test-Path -LiteralPath ([IO.Path]::Combine($_,'.pcvrhub_spidy_ownership.csv')) -PathType Leaf})
    if($owned.Count -gt 1){
        if($recorded -and @($owned|Where-Object {$_ -ieq $recorded}).Count -eq 1){$owned=@($recorded)}
        else{throw 'Several Spidy launcher installations exist. Remove the extra copy before updating.'}
    }
    if($owned.Count -eq 1){$candidates=@($owned[0])}
    foreach($candidate in $candidates){
        $full=[IO.Path]::GetFullPath($candidate)
        if(Test-Path -LiteralPath $full){
            $item=Get-Item -LiteralPath $full -Force
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
        }
        if((Get-PCVRInstallerVolumeFreeBytes $full) -lt 104857600L){continue}
        if(Test-InstallerTargetWritable -TargetPath $full){return $full}
    }
    if($owned.Count -eq 1){throw "The existing Spidy destination lacks space or write access: $($owned[0])"}
    throw 'No writable Spidy destination has at least 100 MB free. Free space on C: or use a writable D:/E: Games drive.'
}
function Get-SpidyRelease([object]$ReleaseData=$null){
    if($null -eq $ReleaseData -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_RELEASE_JSON){
        $file=Assert-SpidyFixture $env:PCVR_SPIDY_TEST_RELEASE_JSON
        $ReleaseData=Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
    }
    $args=@{Repo='IlyaMez/SpidyVR';IncludePrerelease=$true;
        AssetPatterns=@('(?i)^Spidy-\d+(?:\.\d+){2}-win64\.zip$');SkipReleasesWithoutMatchingAsset=$true}
    if($null -ne $ReleaseData){$args.ReleaseData=$ReleaseData}
    $release=Resolve-GitHubReleaseAsset @args
    if(-not $release.Resolved -or -not $release.Url -or $release.AssetName -notmatch '(?i)^Spidy-(\d+(?:\.\d+){2})-win64\.zip$'){
        throw "No unambiguous Windows Spidy release is available: $($release.Error)"
    }
    $version=$Matches[1]
    if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The Spidy release has no trackable version.'}
    return [pscustomobject]@{Version=$version;Tag=[string]$release.Tag;Url=[string]$release.Url;
        PageUrl=[string]$release.PageUrl;Name=[string]$release.AssetName;Local=$false}
}
function Get-SpidyLocalRelease([string]$Path){
    $file=[IO.Path]::GetFullPath($Path.Trim().Trim('"'))
    if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw 'The chosen Spidy ZIP does not exist.'}
    if([IO.Path]::GetFileName($file) -notmatch '(?i)^Spidy-(\d+(?:\.\d+){2})-win64\.zip$'){
        throw 'Select the publisher Spidy win64 ZIP with a versioned filename.'
    }
    return [pscustomobject]@{Version=$Matches[1];Tag=('v'+$Matches[1]);Url=$file;
        PageUrl=$script:SpidyPage;Name=[IO.Path]::GetFileName($file);Local=$true}
}
function Get-SpidyPayload([string]$Archive,[string]$Work){
    $expanded=Join-Path $Work 'expanded'
    Write-Host '  [..] Extracting the publisher ZIP; this can take a little time.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'Spidy VR' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The Spidy ZIP could not be extracted.'}
    $root=Get-ExtractedPayloadRoot -ExtractDir $expanded -RelModFile 'Spidy Launcher.exe'
    if(-not $root){throw 'The ZIP has no Spidy Launcher.exe at a supported package root.'}
    foreach($relative in $script:SpidyRequired | Where-Object {$_ -ne '.pcvrhub_spidy_ownership.csv'}){
        if(-not(Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)){
            throw "The publisher ZIP is missing $relative."
        }
    }
    return $root
}
function Save-SpidySnapshot([string]$Target,[string]$Payload,[string]$Backup){
    [void][IO.Directory]::CreateDirectory($Backup)
    $names=[Collections.Generic.List[string]]::new()
    $base=[IO.Path]::GetFullPath($Payload).TrimEnd([char[]]'\/')
    foreach($file in @(Get-ChildItem -LiteralPath $Payload -Recurse -File)){
        $names.Add($file.FullName.Substring($base.Length+1))
    }
    $manifest=Join-Path $Target '.pcvrhub_spidy_ownership.csv'
    if(Test-Path -LiteralPath $manifest){
        foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$names.Add((Assert-PCVROwnedRelativePath $row.RelativePath))}}
    }
    foreach($name in @('.pcvrhub_spidy_ownership.csv','.pcvrhub_version')){$names.Add($name)}
    $records=@()
    foreach($relative in @($names|Select-Object -Unique)){
        $source=Join-OwnedRelativePath $Target $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){
            $copy=Join-OwnedRelativePath (Join-Path $Backup 'files') $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $ownedBackup=Join-Path $Target '.pcvrhub_spidy_backup'
    $hadBackup=Test-Path -LiteralPath $ownedBackup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $ownedBackup -Destination (Join-Path $Backup 'ownership-backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Records=$records;HadBackup=$hadBackup;Root=$Backup}
}
function Restore-SpidySnapshot([string]$Target,$Snapshot){
    foreach($record in @($Snapshot.Records)){
        $dest=Join-OwnedRelativePath $Target ([string]$record.Relative)
        if(Test-Path -LiteralPath $dest -PathType Leaf){Remove-Item -LiteralPath $dest -Force -ErrorAction Stop}
        if($record.Exists){
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest))
            Copy-Item -LiteralPath (Join-OwnedRelativePath (Join-Path $Snapshot.Root 'files') ([string]$record.Relative)) -Destination $dest -Force -ErrorAction Stop
        }
    }
    $ownedBackup=Join-Path $Target '.pcvrhub_spidy_backup'
    if(Test-Path -LiteralPath $ownedBackup){Remove-Item -LiteralPath $ownedBackup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $ownedBackup -Recurse -Force -ErrorAction Stop}
}
function Invoke-SpidyInstaller {
    $work=$null;$target=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Spider-Man Remastered - Spidy VR' -ForegroundColor Cyan
        Write-Host ' Steam game + separate OpenXR publisher launcher' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' Steam Marvel''s Spider-Man Remastered is required.' -ForegroundColor White
        Write-Host ' Close the game and Spidy Launcher before installation.' -ForegroundColor Yellow
        Write-Host ' The launcher checks the exact supported game build.' -ForegroundColor White
        Write-Host ' This setup leaves the game folder and Luke Ross mod untouched.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        $handover=Get-PCVRRecoveryInput -PathType Leaf
        $choice=if($handover){'L'}else{(''+(Read-Host 'Press Enter for the current GitHub release, L for your downloaded ZIP, or Q to quit')).Trim().ToUpperInvariant()}
        if($choice -eq 'Q'){return}
        if($choice -notin @('','L')){throw 'Choose Enter, L or Q.'}
        if($choice -eq 'L'){
            if(-not $handover){$handover=(''+(Read-Host 'Paste the full path of your downloaded Spidy ZIP')).Trim()}
            $release=Get-SpidyLocalRelease $handover
        } else {
            Write-Host '  [..] Checking GitHub releases; this may take a few seconds.' -ForegroundColor Cyan
            $release=Get-SpidyRelease
        }
        Write-Host "  Selected $($release.Tag): $($release.Name)" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate the Steam game and prepare this release...')
        $game=Get-SpidyGame
        if(-not(Test-SpidyGame $game)){throw 'A Steam game folder containing Spider-Man.exe is required.'}
        if(($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_PROCESS_RUNNING -eq '1') -or
            ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name @('Spider-Man','Spidy Launcher') -ErrorAction SilentlyContinue))){
            throw 'Close the game and Spidy Launcher before setup.'
        }
        $target=Get-SpidyTarget
        Write-Host "  Separate launcher destination: $target" -ForegroundColor Gray
        if(Test-Path -LiteralPath (Join-Path $target '.pcvrhub_spidy_preserved.csv') -PathType Leaf){
            throw 'Previously changed Spidy files were preserved here. Review them before reinstalling into this folder.'
        }
        $tempChoice=Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes 104857600L
        if(-not $tempChoice.BasePath){throw 'No writable temporary location has enough space.'}
        $work=New-PCVRInstallerTempSession -BasePath $tempChoice.BasePath
        $archive=Join-Path $work $release.Name
        Write-Host '  [..] Preparing the publisher package; download may take some time.' -ForegroundColor Cyan
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{
            $download=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Spidy $($release.Version)" -ExpectedReleaseTag ([string]$release.Version) -ManualUrl $release.PageUrl -AllowSkip $false
            if(-not($download -eq $true -or [string]$download -in @('retry','manual'))){throw 'The publisher ZIP was not downloaded.'}
        }
        if(-not(Test-DownloadedPayload -Path $archive -IntendedPath $release.Name)){throw 'The downloaded file is not a usable ZIP.'}
        $payload=Get-SpidyPayload -Archive $archive -Work $work
        [void][IO.Directory]::CreateDirectory($target)
        $snapshot=Save-SpidySnapshot -Target $target -Payload $payload -Backup (Join-Path $work 'rollback')
        $changed=$true
        Write-Host '  [..] Installing the launcher; file copy can take a little time.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity 'spidy' -AdoptIdenticalExisting -ProgressLabel 'Installing Spidy VR')
        $watch=@($script:SpidyRequired | ForEach-Object {Join-Path $target $_})
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $target)){
            throw 'Required Spidy launcher files did not survive the post-copy check.'
        }
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_RECEIPT){Assert-SpidyFixture $env:PCVR_SPIDY_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        if($env:PCVR_HUB_TEST_MODE -ne '1'){
            if(-not(Save-HubRememberedGameFolder -GameId $script:SpidyId -Title 'Spider-Man Remastered VR' -GameDir $game -ProbeFiles @('Spider-Man.exe') -StateName 'base_game_path')){
                throw 'The proven Steam game path could not be remembered.'
            }
        }
        [void](Complete-PCVRInstallTransaction -Contract $script:SpidyContract -GameDir $target -Version $release.Version -Route Current -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host "  [OK] Spidy VR $($release.Version) is installed separately from the Steam game." -ForegroundColor Green
        Write-Host '  Use Start in VR to open Spidy Launcher. Resolve its checks, choose' -ForegroundColor White
        Write-Host '  your OpenXR runtime and press START VR there.' -ForegroundColor White
        Write-Host '  Keep the game window foreground and close the game after STOP VR.' -ForegroundColor White
        Write-Host ''
        Write-Host '  The city is yours. Take the next swing.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $target){
            try{Restore-SpidySnapshot -Target $target -Snapshot $snapshot;Write-Host '  [..] Previous Spidy files restored.' -ForegroundColor Yellow}
            catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
        }
        $message="Spidy VR setup did not complete: $($_.Exception.Message)"
        Write-Host "  [X] $message" -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{
        if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
if($env:PCVR_SPIDY_LIBRARY_ONLY -ne '1'){Invoke-SpidyInstaller}
