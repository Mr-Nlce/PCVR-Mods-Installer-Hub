$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='A Kingdom for Keflings VR Installer'
$script:KeflingsId='a-kingdom-for-keflings-vr'
$script:KeflingsRepo='GameOrDie007/A-Kingdom-for-Keflings-VR'
$script:KeflingsReleasePage='https://github.com/GameOrDie007/A-Kingdom-for-Keflings-VR/releases'
$script:KeflingsGamePage='https://ninjabee.itch.io/a-kingdom-for-keflings'
$script:KeflingsExe='A Kingdom for Keflings.exe'
$script:KeflingsIdentity='keflingsvr'
$script:KeflingsRequired=@('opengl32.dll','openxr_loader.dll','VR\version.txt','VR\UNINSTALL.bat','.pcvrhub_keflingsvr_ownership.csv')

function Test-KeflingsGame([string]$Root){return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root $script:KeflingsExe) -PathType Leaf))}
function Get-KeflingsGame {
    $fixture=(''+$env:PCVR_KEFLINGS_TEST_GAME).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){
        $full=[IO.Path]::GetFullPath($fixture);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'keflings-fixture.txt') -PathType Leaf) -or -not(Test-KeflingsGame $full)){throw 'Keflings test game must be a complete isolated fixture.'}
        return $full
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:KeflingsId -StateNames @('installed_path','user_located') -ProbeFiles @($script:KeflingsExe)
    if(Test-KeflingsGame $saved){return [IO.Path]::GetFullPath($saved)}
    foreach($key in @('HKLM:\SOFTWARE\WOW6432Node\NinjaBee\A Kingdom for Keflings','HKLM:\SOFTWARE\NinjaBee\A Kingdom for Keflings','HKCU:\SOFTWARE\NinjaBee\A Kingdom for Keflings')){
        try{$found=[string](Get-ItemProperty -LiteralPath $key -ErrorAction Stop).Install_Dir;if(Test-KeflingsGame $found){return [IO.Path]::GetFullPath($found)}}catch{}
    }
    foreach($candidate in @('C:\Program Files (x86)\NinjaBee\AKingdomForKeflings','C:\Program Files\NinjaBee\AKingdomForKeflings')){if(Test-KeflingsGame $candidate){return [IO.Path]::GetFullPath($candidate)}}
    Write-Host '  A Kingdom for Keflings was not found automatically.' -ForegroundColor Yellow
    Write-Host '  The licensed PC game is required. NinjaBee provides a demo installer;' -ForegroundColor White
    Write-Host '  your own license key unlocks the full game.' -ForegroundColor White
    while($true){
        Write-Host '  [Enter] Open the official NinjaBee itch.io game page.' -ForegroundColor Yellow
        Write-Host '  [P] Enter or drag the installed game folder (or its EXE).' -ForegroundColor White
        Write-Host '  [Q] Cancel setup.' -ForegroundColor White
        $choice=(''+(Read-Host '  Choose Enter, P or Q')).Trim().ToUpperInvariant()
        if($choice -eq 'Q'){throw 'Setup cancelled before any game file was changed.'}
        if($choice -eq ''){Start-Process $script:KeflingsGamePage -ErrorAction Stop;[void](Wait-PCVRExplicitEnter -Message 'After installing the game, press Enter to locate it...')}
        elseif($choice -ne 'P'){continue}
        $path=(''+(Read-Host '  Game folder or EXE path')).Trim().Trim('"').Trim("'")
        if(-not $path){continue}
        if(Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue){$path=Split-Path -Parent $path}
        if(Test-KeflingsGame $path){return [IO.Path]::GetFullPath($path)}
        Write-Host "  $($script:KeflingsExe) was not found there." -ForegroundColor Yellow
    }
}
function Get-KeflingsRelease {
    $fixture=(''+$env:PCVR_KEFLINGS_TEST_ARCHIVE).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){if(-not(Test-Path -LiteralPath $fixture -PathType Leaf)){throw 'Keflings publisher fixture is missing.'};return [pscustomobject]@{Tag=$(if($env:PCVR_KEFLINGS_TEST_TAG){$env:PCVR_KEFLINGS_TEST_TAG}else{'v1.0'});Url=$fixture;Local=$true}}
    $asset=Resolve-GitHubReleaseAsset -Repo $script:KeflingsRepo -AssetPatterns @('(?i)^A-Kingdom-for-Keflings-VR-[0-9].*\.zip$') -SkipReleasesWithoutMatchingAsset
    if(-not $asset.Resolved -or -not $asset.Url -or -not(Test-IsTrackableInstalledVersion -Version ([string]$asset.Tag))){throw 'No usable Keflings VR release with a trackable version was found.'}
    return [pscustomobject]@{Tag=[string]$asset.Tag;Url=[string]$asset.Url;Local=$false}
}
function Get-KeflingsPayload([string]$Archive,[string]$Work,[string]$Version='v1.0'){
    $extract=Join-Path $Work 'release'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $extract -Label 'Keflings VR package' -AllowSkip:$false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The Keflings publisher ZIP could not be extracted.'}
    $current=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'opengl32.dll'
    if($current -and (Test-Path -LiteralPath (Join-Path $current 'setup.ps1') -PathType Leaf)){
        foreach($name in @('opengl32.dll','openxr_loader.dll','UNINSTALL.bat','collect-log.bat','setup.ps1')){
            if(-not(Test-Path -LiteralPath (Join-Path $current $name) -PathType Leaf)){throw "The publisher package is missing $name."}
        }
        if(-not(Test-IsTrackableInstalledVersion $Version)){throw 'The publisher settings kit needs its release version.'}
        $stage=Join-Path $Work 'stage';$kit=Join-Path $stage 'VR'
        [void][IO.Directory]::CreateDirectory($kit)
        foreach($item in @(Get-ChildItem -LiteralPath $current -Force)){Copy-Item -LiteralPath $item.FullName -Destination $kit -Recurse -Force -ErrorAction Stop}
        foreach($name in @('opengl32.dll','openxr_loader.dll')){Copy-Item -LiteralPath (Join-Path $current $name) -Destination $stage -ErrorAction Stop}
        $parent=Split-Path $current -Parent
        foreach($name in @('LICENSES','READ ME FIRST.txt')){if(Test-Path -LiteralPath (Join-Path $parent $name)){Copy-Item -LiteralPath (Join-Path $parent $name) -Destination $kit -Recurse -Force -ErrorAction Stop}}
        [IO.File]::WriteAllText((Join-Path $kit 'version.txt'),('A Kingdom for Keflings VR '+$Version.TrimStart('v')),[Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $kit 'SETUP.bat'),"@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0setup.ps1`" -GamePath `"%~dp0..`" %*`r`n",[Text.Encoding]::ASCII)
        return $stage
    }
    $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'tools\setup.ps1'
    foreach($relative in @('opengl32.dll','openxr_loader.dll','version.txt','SETUP.bat','UNINSTALL.bat','collect-log.bat','READ ME FIRST.txt','tools\setup.ps1','LICENSES\Apache-2.0.txt','LICENSES\GPL-3.0.txt')){
        if(-not $payload -or -not(Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)){throw "The publisher package is missing $relative."}
    }
    $stage=Join-Path $Work 'stage';$kit=Join-Path $stage 'VR'
    [void][IO.Directory]::CreateDirectory($kit)
    foreach($name in @('opengl32.dll','openxr_loader.dll')){Copy-Item -LiteralPath (Join-Path $payload $name) -Destination (Join-Path $stage $name) -ErrorAction Stop}
    foreach($relative in @('opengl32.dll','openxr_loader.dll','version.txt','SETUP.bat','UNINSTALL.bat','collect-log.bat','READ ME FIRST.txt','tools\setup.ps1','LICENSES\README.txt','LICENSES\Apache-2.0.txt','LICENSES\GPL-3.0.txt')){
        $source=Join-Path $payload $relative
        if(-not(Test-Path -LiteralPath $source -PathType Leaf)){continue}
        $dest=Join-Path $kit $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath $source -Destination $dest -ErrorAction Stop
    }
    return $stage
}
function Save-KeflingsSnapshot([string]$Game,[string]$Stage,[string]$Root){
    [void][IO.Directory]::CreateDirectory($Root)
    $paths=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)){[void]$paths.Add($file.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Game '.pcvrhub_keflingsvr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)){if($row.RelativePath){[void]$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}}}
    foreach($name in @('.pcvrhub_keflingsvr_ownership.csv','.pcvrhub_keflingsvr_ownership.csv.new','.pcvrhub_version')){[void]$paths.Add($name)}
    $records=@()
    foreach($relative in @($paths|Select-Object -Unique)){
        $source=Join-OwnedRelativePath -Root $Game -Relative $relative;$exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-OwnedRelativePath -Root (Join-Path $Root 'files') -Relative $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_keflingsvr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Root 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Root=$Root;Records=$records;HadBackup=$hadBackup}
}
function Restore-KeflingsSnapshot([string]$Game,$Snapshot){
    foreach($row in @($Snapshot.Records)){
        $target=Join-OwnedRelativePath -Root $Game -Relative ([string]$row.Relative)
        if($row.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$row.Relative)) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_keflingsvr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Invoke-KeflingsInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try{
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  A Kingdom for Keflings VR - Installer' -ForegroundColor Cyan
        Write-Host '  Game Or Die OpenXR tabletop port' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Requires your installed licensed PC game and a 32-bit' -ForegroundColor White
        Write-Host '  OpenXR runtime. No game files or license are supplied.' -ForegroundColor White
        Write-Host '  Setup backs up same-name files and keeps saves and settings.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate the game and get the VR release...')
        $game=Get-KeflingsGame
        if(Get-Process -Name 'A Kingdom for Keflings' -ErrorAction SilentlyContinue){throw 'Close A Kingdom for Keflings before installing or updating VR.'}
        if(-not(Test-InstallerTargetWritable -TargetPath (Join-Path $game 'opengl32.dll'))){throw 'The game folder is not writable. Run the Hub installer as administrator, then retry.'}
        Write-Host "  [OK] Game found: $game" -ForegroundColor Green
        $release=Get-KeflingsRelease
        Write-Host "  Latest supported release: $($release.Tag)" -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download and prepare the publisher package...')
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-keflings-'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work);$archive=Join-Path $work 'publisher.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{$ok=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Keflings VR $($release.Tag)" -ManualUrl $script:KeflingsReleasePage -AllowSkip:$false;if(-not $ok){throw 'The publisher package was not downloaded.'}}
        Write-Host '  Preparing the VR package and backup. This may take several seconds.' -ForegroundColor Cyan
        $stage=Get-KeflingsPayload -Archive $archive -Work $work -Version $release.Tag
        $publisherVersion=[regex]::Match(([string](Get-Content -LiteralPath (Join-Path $stage 'VR\version.txt') -Raw -ErrorAction Stop)),'(?i)A Kingdom for Keflings VR\s+(\d+(?:\.\d+){1,3})').Groups[1].Value
        $selectedVersion=[regex]::Match([string]$release.Tag,'\d+(?:\.\d+){1,3}').Value
        if(-not $publisherVersion -or $publisherVersion -ne $selectedVersion){throw "Keflings package version $publisherVersion does not match selected release $($release.Tag). No game files were changed."}
        $installedVersion='v'+$publisherVersion
        $snapshot=Save-KeflingsSnapshot -Game $game -Stage $stage -Root (Join-Path $work 'rollback')
        Write-Host '  Original same-name files and previous VR state are protected.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the checked VR files...')
        Write-Host '  Installing and verifying VR files. This may take several seconds.' -ForegroundColor Cyan
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:KeflingsIdentity -AdoptIdenticalExisting -KeepExistingRelativePaths @('VR\READ ME FIRST.txt'))
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KEFLINGS_TEST_REMOVE_AFTER_COPY -eq '1'){Remove-Item -LiteralPath (Join-Path $game 'openxr_loader.dll') -Force -ErrorAction Stop}
        $watch=@($script:KeflingsRequired|ForEach-Object{Join-Path $game $_})
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required Keflings VR files are missing after installation.'}
        $contract=New-PCVRInstallerContract -Id $script:KeflingsId -GameName 'A Kingdom for Keflings VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:KeflingsReleasePage -RequiredInstalledFileGroups $script:KeflingsRequired
        $receipt=(''+$env:PCVR_KEFLINGS_TEST_RECEIPT).Trim();if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $installedVersion -InstalledPathReceiptPaths @($receipt) -Route Current)
        [void](Save-HubRememberedGameFolder -GameId $script:KeflingsId -Title 'A Kingdom for Keflings VR' -GameDir $game -ProbeFiles @($script:KeflingsExe) -StateName 'base_game_path')
        $changed=$false
        Write-Host "  [OK] Keflings VR $($release.Tag) is installed and tracked." -ForegroundColor Green
        Write-Host '  Start your 32-bit OpenXR runtime, then use Start in VR.' -ForegroundColor White
        Write-Host ''
        Write-Host '  A giant hand in the kingdom is helpful until it starts redecorating.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $failure=$_.Exception.Message
        if($changed -and $snapshot -and $game){try{Restore-KeflingsSnapshot -Game $game -Snapshot $snapshot;Write-Host '  [!!] Previous game and VR files restored.' -ForegroundColor Yellow}catch{$keepWork=$true;Write-Host "  [!!] Rollback needs review; snapshot kept at $work. $($_.Exception.Message)" -ForegroundColor Red}}
        Write-Host "  [XX] $failure" -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $failure -InstallerFolder $PSScriptRoot)
    }finally{if($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_KEFLINGS_LIBRARY_ONLY -ne '1'){Invoke-KeflingsInstaller}
