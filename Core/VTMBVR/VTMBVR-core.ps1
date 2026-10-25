$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
$Host.UI.RawUI.WindowTitle='Bloodlines VR Installer'
$script:BloodlinesId='vampire-bloodlines-vr'
$script:BloodlinesRepo='atrblizzard/vtmb-vr'
$script:BloodlinesPage='https://github.com/atrblizzard/vtmb-vr/releases'
$script:BloodlinesPatchPage='https://github.com/Ghost2DLL/vtmb-vr-injector/releases/tag/up-11.5-archive'
$script:BloodlinesPatchUrl='https://github.com/Ghost2DLL/vtmb-vr-injector/releases/download/up-11.5-archive/VTMBup115.exe'
$script:BloodlinesIdentity='bloodlinesvr'
$script:BloodlinesArgs='-game Unofficial_Patch -vr -novid -window -w 1920 -h 1080'
$script:BloodlinesRequired=@('vampire.exe','VTMBup-readme.txt','Loader.exe',
    'Unofficial_Patch\cfg\autoexec.cfg','Unofficial_Patch\vdata\system\rules.txt','d3d9.dll','openvr_api.dll',
    'openxr_loader.dll','VR\config.txt','VR\SteamVRActionManifest\action_manifest.json',
    '.pcvrhub_bloodlinesvr_ownership.csv')
$script:BloodlinesContract=New-PCVRInstallerContract -Id $script:BloodlinesId -GameName 'Bloodlines VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:BloodlinesPage -Routes @('Steam','GOG','Retail') `
    -RequiredInstalledFileGroups $script:BloodlinesRequired

function Test-BloodlinesGame([string]$Root){
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'vampire.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'Vampire') -PathType Container))
}
function Get-BloodlinesPatchVersion([string]$Game){
    foreach($name in @('Loader.exe','Unofficial_Patch\cfg\autoexec.cfg',
        'Unofficial_Patch\vdata\system\rules.txt','VTMBup-readme.txt')){
        if(-not(Test-Path -LiteralPath (Join-Path $Game $name) -PathType Leaf)){return $null}
    }
    $match=[regex]::Match([IO.File]::ReadAllText((Join-Path $Game 'VTMBup-readme.txt')),
        '(?m)^Version Changelog:\s*\r?\n-+\s*\r?\n\s*v(?<version>\d+(?:\.\d+)*)[ \t]+\d{2}\.\d{2}\.\d{4}')
    if($match.Success){return $match.Groups['version'].Value}
    return $null
}
function Get-BloodlinesGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLOODLINES_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_BLOODLINES_TEST_GAME)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
           -not(Test-Path -LiteralPath (Join-Path $root 'bloodlines-fixture.txt') -PathType Leaf) -or
           -not(Test-BloodlinesGame $root)){throw 'Bloodlines test game must be an isolated fixture.'}
        return $root
    }
    $paths=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:BloodlinesId -StateNames @('installed_path','user_located') -ProbeFiles @('vampire.exe')
    if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '2600' -SteamFolderNames @('Vampire The Masquerade - Bloodlines') -ProbeExe 'vampire.exe' -HubGameId $script:BloodlinesId;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Vampire The Masquerade - Bloodlines',
        'C:\Program Files (x86)\GOG Galaxy\Games\Vampire The Masquerade - Bloodlines',
        'C:\GOG Games\Vampire The Masquerade - Bloodlines',
        'C:\Program Files (x86)\Activision\Vampire - Bloodlines')
    foreach($path in @($paths|Select-Object -Unique)){if(Test-BloodlinesGame $path){return [IO.Path]::GetFullPath($path)}}
    $picked=Get-GameFolderInteractive -GameName 'Vampire: The Masquerade - Bloodlines' -ProbeFile 'vampire.exe'
    if(Test-BloodlinesGame $picked){
        [void](Save-HubRememberedGameFolder -GameId $script:BloodlinesId -Title 'Bloodlines VR' -GameDir $picked -ProbeFiles @('vampire.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose the complete Bloodlines game folder containing vampire.exe and Vampire.'
}
function Install-BloodlinesPatch([string]$Game){
    $session=$null
    try{
        Write-Host ''
        Write-Host '  REQUIRED PUBLISHER PATCH: Unofficial Patch 11.5' -ForegroundColor Yellow
        Write-Host "  Select this exact game folder in its Setup: $Game" -ForegroundColor White
        Write-Host '  The patch changes game files. Back up existing saves and patch settings first.' -ForegroundColor White
        Write-Host '  Windows will request administrator approval when Setup opens.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download Unofficial Patch 11.5 (Setup requires UAC)...')
        $session=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $patch=Join-Path $session 'VTMBup115.exe'
        $downloaded=Invoke-SafeDownload -Urls @($script:BloodlinesPatchUrl) -Destination $patch `
            -Label 'Unofficial Patch 11.5 Setup' -ManualUrl $script:BloodlinesPatchPage -AllowSkip:$false
        if($downloaded -ne $true -and [string]$downloaded -ne 'retry'){
            throw 'Unofficial Patch 11.5 was not downloaded. No VR files were changed.'
        }
        if(-not(Test-DownloadedPayload -Path $patch -IntendedPath $patch)){
            throw 'The downloaded patch is not a usable Windows Setup EXE. No VR files were changed.'
        }
        Write-Host "  [OK] Downloaded publisher Setup: $patch" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open and install Patch 11.5 (UAC required)...')
        $process=Start-Process -FilePath $patch -Verb RunAs -Wait -PassThru
        if($null -eq $process -or $null -eq $process.ExitCode -or [int]$process.ExitCode -ne 0){
            throw "Unofficial Patch Setup did not finish successfully (exit $($process.ExitCode)). No VR files were changed."
        }
        if((Get-BloodlinesPatchVersion $Game) -ne '11.5'){
            throw "Patch 11.5 was not verified in $Game. Check that publisher Setup used this game folder and completed all patch files, then Retry. No VR files were changed."
        }
        Write-Host '  [OK] Patch 11.5 Setup completed in the selected game folder.' -ForegroundColor Green
        return $true
    }finally{
        if($session){Remove-PCVRInstallerTempSession -Path $session}
    }
}
function Assert-BloodlinesPatch([string]$Game){
    $version=Get-BloodlinesPatchVersion $Game
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if($version -ne '11.5'){throw 'Fixture lacks Unofficial Patch 11.5 proof.'}
        return
    }
    Write-Host ''
    Write-Host '  REQUIRED: Unofficial Patch 11.5, exactly.' -ForegroundColor Yellow
    Write-Host '  Other patch builds may have incompatible 32-bit hooks.' -ForegroundColor White
    Write-Host "  Archived 11.5 installer: $script:BloodlinesPatchPage" -ForegroundColor Cyan
    if($version -eq '11.5'){
        Write-Host '  [OK] Unofficial Patch 11.5 files and version verified in this game folder.' -ForegroundColor Green
        return
    }
    if(Test-Path -LiteralPath (Join-Path $Game 'Unofficial_Patch') -PathType Container){
        throw "An existing Unofficial Patch in $Game could not be verified as complete version 11.5. Review its files and back up saves/settings before repairing it. No VR files were changed."
    }
    Write-Host '  Unofficial Patch 11.5 is not installed in this game folder.' -ForegroundColor Yellow
    [void](Install-BloodlinesPatch -Game $Game)
}
function Get-BloodlinesArchiveInfo([string]$Path){
    try{
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try{
            foreach($name in @('d3d9.dll','openvr_api.dll','openxr_loader.dll','VR/config.txt',
                'VR/SteamVRActionManifest/action_manifest.json','README-VR.txt')){
                if(-not $zip.GetEntry($name)){return $false}
            }
            return $true
        }finally{$zip.Dispose()}
    }catch{return $false}
}
function Get-BloodlinesArchive([string]$Destination){
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLOODLINES_TEST_ARCHIVE){
        Copy-Item -LiteralPath $env:PCVR_BLOODLINES_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop
        if(-not(Get-BloodlinesArchiveInfo $Destination)){throw 'Bloodlines publisher fixture is incomplete.'}
        return 'v0.5-preview'
    }
    $release=Resolve-GitHubReleaseAsset -Repo $script:BloodlinesRepo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^VTMB-VR-[0-9].*\.zip$') -SkipReleasesWithoutMatchingAsset $true
    if(-not $release.Resolved -or -not $release.Url -or -not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){
        throw 'The current Bloodlines VR preview could not be resolved. Use recovery to open the publisher release and hand over its ZIP.'
    }
    [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label 'Bloodlines VR ZIP' `
        -ManualUrl $script:BloodlinesPage -AllowSkip:$false -Validator {param($p) Get-BloodlinesArchiveInfo $p})
    if(-not(Get-BloodlinesArchiveInfo $Destination)){throw 'The publisher ZIP is missing essential VR files.'}
    return [string]$release.Tag
}
function Get-BloodlinesDesktop {
    $desktop=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLOODLINES_TEST_DESKTOP){$env:PCVR_BLOODLINES_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
    return (Join-Path $desktop 'Bloodlines VR.lnk')
}
function New-BloodlinesShortcut([string]$Game){
    $path=Get-BloodlinesDesktop
    $created=-not(Test-Path -LiteralPath $path -PathType Leaf)
    $oldArgs='-game Unofficial_Patch -vr -console -novid -window -w 1920 -h 1080'
    if(Test-Path -LiteralPath $path -PathType Leaf){
        $existing=(New-Object -ComObject WScript.Shell).CreateShortcut($path)
        if($existing.TargetPath -ine (Join-Path $Game 'vampire.exe') -or $existing.Arguments -notin @($script:BloodlinesArgs,$oldArgs)){
            throw 'An unrelated desktop shortcut already uses the Bloodlines VR name.'
        }
        if($existing.Arguments -eq $oldArgs){$existing.Arguments=$script:BloodlinesArgs;$existing.Save()}
    }else{
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
        $link=(New-Object -ComObject WScript.Shell).CreateShortcut($path)
        $link.TargetPath=Join-Path $Game 'vampire.exe';$link.Arguments=$script:BloodlinesArgs
        $link.WorkingDirectory=$Game;$link.IconLocation=(Join-Path $Game 'vampire.exe')+',0';$link.Save()
    }
    $legacy=Join-Path (Split-Path -Parent $path) 'Bloodlines VR (Hub).lnk'
    if(Test-Path -LiteralPath $legacy -PathType Leaf){
        $old=(New-Object -ComObject WScript.Shell).CreateShortcut($legacy)
        if($old.TargetPath -ieq (Join-Path $Game 'vampire.exe') -and $old.Arguments -in @($script:BloodlinesArgs,$oldArgs)){
            Remove-Item -LiteralPath $legacy -Force;$created=$false
        }
    }
    return $created
}
function Invoke-BloodlinesInstaller {
    $work=$null;$snapshot=$null;$changed=$false;$game=$null;$newShortcut=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Vampire: The Masquerade - Bloodlines VR Installer' -ForegroundColor Cyan
        Write-Host '  WIP preview; tracked hands; Unofficial Patch 11.5 required' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Existing root mod DLLs and VR bindings are backed up or preserved.' -ForegroundColor White
        Write-Host '  The patch installer changes game files separately; check its target folder carefully.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Bloodlines...')
        $game=Get-BloodlinesGame
        Write-Host "  Game: $game" -ForegroundColor Green
        if(Get-Process -Name vampire -ErrorAction SilentlyContinue){throw 'Close Bloodlines before installing or updating VR.'}
        Assert-BloodlinesPatch $game
        if(-not(Test-InstallerTargetWritable $game)){throw 'The Bloodlines game folder is not writable.'}
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'BloodlinesVR.zip'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Bloodlines VR preview...')
        $version=Get-BloodlinesArchive $archive
        $stage=Join-Path $work 'stage'
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Bloodlines VR' -AllowSkip:$false) -ne 'ok'){
            throw 'The publisher ZIP could not be extracted.'
        }
        foreach($name in @('d3d9.dll','openvr_api.dll','openxr_loader.dll','VR\config.txt','VR\SteamVRActionManifest\action_manifest.json')){
            if(-not(Test-Path -LiteralPath (Join-Path $stage $name) -PathType Leaf)){throw "Publisher package lacks $name."}
        }
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity $script:BloodlinesIdentity -SnapshotRoot (Join-Path $work 'rollback')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Bloodlines VR...')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:BloodlinesIdentity `
            -KeepExistingRelativePaths @('VR\config.txt','VR\SteamVRActionManifest\bindings_knuckles.json',
                'VR\SteamVRActionManifest\bindings_oculus_touch.json','VR\SteamVRActionManifest\bindings_vive_cosmos_controller.json') `
            -AdoptIdenticalExisting)
        $needed=@('d3d9.dll','openvr_api.dll','openxr_loader.dll','VR\SteamVRActionManifest\action_manifest.json',
            '.pcvrhub_bloodlinesvr_ownership.csv')|ForEach-Object{Join-Path $game $_}
        if(-not(Confirm-PlacedFilesSurvive -Paths $needed -GameDir $game -NoClear)){throw 'Required Bloodlines VR files did not survive installation.'}
        $newShortcut=New-BloodlinesShortcut $game
        $receipt=if($env:PCVR_BLOODLINES_TEST_RECEIPT){$env:PCVR_BLOODLINES_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:BloodlinesContract -GameDir $game -Version $version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false
        Write-Host "  [OK] Bloodlines VR $version installed for confirmed Patch 11.5." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub with SteamVR and your headset ready.' -ForegroundColor White
        Write-Host "  Alternatively, use desktop shortcut: $(Get-BloodlinesDesktop)" -ForegroundColor White
        Write-Host ''
        Write-Host '  The Masquerade still applies, even when your hands give you away.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot;Write-Host '  [!!] Previous Bloodlines VR files were restored.' -ForegroundColor Yellow}
            catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
            if($newShortcut){Remove-Item -LiteralPath (Get-BloodlinesDesktop) -Force -ErrorAction SilentlyContinue}
        }
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_BLOODLINES_LIBRARY_ONLY -ne '1'){
    while($true){
        try{Invoke-BloodlinesInstaller;break}
        catch{
            $message="Bloodlines VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
