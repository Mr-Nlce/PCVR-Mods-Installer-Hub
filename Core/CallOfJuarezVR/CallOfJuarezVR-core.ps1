$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='Call of Juarez VR Installer'
$script:CojId='call-of-juarez-vr';$script:CojRepo='rubocopter/call_of_juarez_vr'
$script:CojPage='https://github.com/rubocopter/call_of_juarez_vr/releases'
$script:CojContract=New-PCVRInstallerContract -Id $script:CojId -GameName 'Call of Juarez VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $script:CojPage -Routes @('Steam') `
    -RequiredInstalledFileGroups @('CoJ.exe','d3d9.dll','.cojvr-public-install.json','.cojvr-d3d9-stage.json')
function Get-CojCacheRoot{
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_CACHE){return (Assert-CojFixture $env:PCVR_COJ_TEST_CACHE)}
    return (Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\PublisherCache\CallOfJuarezVR')
}
function Assert-CojFixture([string]$Root){
    $full=[IO.Path]::GetFullPath($Root);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'coj-fixture.txt') -PathType Leaf)){throw 'CoJ test path must be an isolated temporary fixture.'}
    return $full
}
function Get-CojGame{
    if($env:PCVR_COJ_TEST_GAME){$p=Assert-CojFixture $env:PCVR_COJ_TEST_GAME;if(Test-Path -LiteralPath (Join-Path $p 'CoJ.exe') -PathType Leaf){return $p};throw 'CoJ fixture game is missing.'}
    $paths=@();$saved=Get-PCVRRememberedGameFolder -GameId $script:CojId -StateNames @('base_game_path','user_located','installed_path') -ProbeFiles @('CoJ.exe');if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '3020' -SteamFolderNames @('Call of Juarez') -ProbeExe 'CoJ.exe' -HubGameId $script:CojId;if($steam){$paths+=$steam}}catch{}
    $paths+='C:\Program Files (x86)\Steam\steamapps\common\Call of Juarez'
    foreach($p in @($paths|Where-Object{$_}|Select-Object -Unique)){if($p -match '(?i)[\\/]steamapps[\\/]common[\\/]' -and (Test-Path -LiteralPath (Join-Path $p 'CoJ.exe') -PathType Leaf)){return [IO.Path]::GetFullPath($p)}}
    $picked=Get-GameFolderInteractive -GameName 'Call of Juarez (2006, original Steam D3D9 version only)' -ProbeFile 'CoJ.exe' -ManualUrl 'https://store.steampowered.com/app/3020/'
    if($picked -and $picked -match '(?i)[\\/]steamapps[\\/]common[\\/]' -and (Test-Path -LiteralPath (Join-Path $picked 'CoJ.exe') -PathType Leaf)){
        [void](Save-HubRememberedGameFolder -GameId $script:CojId -Title 'Call of Juarez VR' -GameDir $picked -ProbeFiles @('CoJ.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Only the confirmed Steam D3D9 CoJ.exe route is currently supported. Do not select CoJ_DX10.exe or another store build.'
}
function Get-CojPackageVersion([string]$Archive){
    $safe=Test-ZipArchiveEntrySafety -ArchivePath $Archive -DestinationFolder (Join-Path ([IO.Path]::GetTempPath()) 'pcvr-coj-safety')
    if(-not $safe.Safe -or -not $safe.Inspectable){throw 'CoJ publisher ZIP is unreadable or has unsafe paths.'}
    Add-Type -AssemblyName System.IO.Compression.FileSystem;$zip=[IO.Compression.ZipFile]::OpenRead($Archive)
    try{
        foreach($name in @('cojvr.ps1','release_common.ps1','CoJ-VR.cmd','release-manifest.json','payload/d3d9_native_stereo.build-manifest.json')){
            if(-not @($zip.Entries|Where-Object{$_.FullName.Replace('\','/') -ieq $name}).Count){throw "Publisher package is missing $name."}
        }
        $entry=@($zip.Entries|Where-Object{$_.FullName -ieq 'release-manifest.json'})|Select-Object -First 1
        $reader=[IO.StreamReader]::new($entry.Open());try{$record=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
        if($record.manifestType -ne 'cojvr-release' -or $record.version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$'){throw 'Publisher package has no trackable CoJ version.'}
        return [string]$record.version
    }finally{$zip.Dispose()}
}
function Get-CojArchive([string]$Destination){
    if($env:PCVR_COJ_TEST_ARCHIVE){[void](Assert-CojFixture (Split-Path $env:PCVR_COJ_TEST_ARCHIVE -Parent));Copy-Item -LiteralPath $env:PCVR_COJ_TEST_ARCHIVE -Destination $Destination -Force;return (Get-CojPackageVersion $Destination)}
    try{$release=Resolve-GitHubReleaseAsset -Repo $script:CojRepo -IncludePrerelease $true -AssetPatterns @('(?i)^CoJ-VR-.*-windows-x64\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$release=$null}
    if($release -and $release.Resolved -and $release.Url){
        [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label 'Call of Juarez VR' -ManualUrl $script:CojPage -AllowSkip:$false)
    }else{
        Write-Host '  Current prerelease lookup failed. Use the official publisher ZIP from Downloads.' -ForegroundColor Yellow
        [void](Open-PCVRPageAfterEnter -Url $script:CojPage -Message 'Press Enter to open Call of Juarez VR releases...')
        while($true){[void](Wait-PCVRExplicitEnter -Message 'After downloading, press Enter to check Downloads...');$found=Find-PCVRDownloadedCandidate -Patterns @('CoJ-VR-*-windows-x64.zip')
            if($found){Write-Host "  Found: $found" -ForegroundColor Cyan;if((Read-Host '  Use this ZIP? Y/N') -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $found -Destination $Destination -Force;break}}
            $path=(Read-Host '  Drag/paste the ZIP path, or press Enter to reopen the page').Trim().Trim('"').Trim("'")
            if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){Copy-Item -LiteralPath $path -Destination $Destination -Force;break}
            [void](Open-PCVRPageAfterEnter -Url $script:CojPage -Message 'Press Enter to reopen publisher releases...')
        }
    }
    return (Get-CojPackageVersion $Destination)
}
function Invoke-CojPublisher([string]$Script,[string]$Game,[string]$Action){
    $args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$Script+'"'),'-Action',$Action,'-GameDirectory',('"'+$Game+'"'))
    $p=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -ErrorAction Stop
    if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "Publisher $Action failed (exit $($p.ExitCode))."}
}
function Wait-CojVideoSettings {
    param(
        [Parameter(Mandatory=$true)][string]$VideoPath,
        [scriptblock]$ReadChoice=$null,
        [scriptblock]$LaunchFlat=$null,
        [scriptblock]$AfterFlatLaunch=$null
    )
    if(Test-Path -LiteralPath $VideoPath -PathType Leaf){return}
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Yellow
    Write-Host '  ONE-TIME FLAT START NEEDED - Video.scr is missing' -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Yellow
    Write-Host '  Call of Juarez must create its video settings before VR setup.' -ForegroundColor White
    Write-Host ('  Required file: '+$VideoPath) -ForegroundColor Cyan
    Write-Host '  Start the original Steam game normally, reach its main menu,' -ForegroundColor White
    Write-Host '  then close it completely. No game or mod files were changed.' -ForegroundColor White
    while(-not(Test-Path -LiteralPath $VideoPath -PathType Leaf)){
        Write-Host ''
        Write-Host '  [F] Start Call of Juarez flat through Steam' -ForegroundColor Green
        Write-Host '  [R] Recheck Video.scr and continue this setup' -ForegroundColor Cyan
        Write-Host '  [D] Open Documents to inspect the settings folder' -ForegroundColor Cyan
        Write-Host '  [G] Open the general installer recovery menu' -ForegroundColor Cyan
        $answer=if($ReadChoice){& $ReadChoice '  Choose F, R, D or G'}else{Read-Host '  Choose F, R, D or G'}
        if($null -eq $answer -or (-not $ReadChoice -and [Console]::IsInputRedirected -and (''+$answer).Length -eq 0)){
            throw [IO.EndOfStreamException]::new('Video.scr recovery needs interactive input.')
        }
        switch((''+$answer).Trim().ToUpperInvariant()){
            'F' {
                $uri='steam://rungameid/3020'
                try{
                    if($LaunchFlat){& $LaunchFlat $uri|Out-Null}
                    elseif($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_VIDEO_FILE){
                        [void](Assert-CojFixture (Split-Path $VideoPath -Parent))
                        if($VideoPath -ine $env:PCVR_COJ_TEST_VIDEO_FILE){throw 'CoJ video fixture path mismatch.'}
                        $capture=$env:PCVR_COJ_TEST_FLAT_LAUNCH_CAPTURE
                        if(-not $capture -or (Split-Path $capture -Parent) -ine (Split-Path $VideoPath -Parent)){throw 'CoJ flat launch capture is outside the fixture.'}
                        [IO.File]::WriteAllText($capture,$uri)
                        [IO.File]::WriteAllText($VideoPath,'flat settings fixture')
                    }else{Start-Process $uri -ErrorAction Stop|Out-Null}
                    if($AfterFlatLaunch){& $AfterFlatLaunch $VideoPath|Out-Null}
                    elseif(-not ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_VIDEO_FILE)){
                        [void](Wait-PCVRExplicitEnter -Message 'After reaching the flat main menu and closing the game, press Enter to recheck Video.scr...')
                    }
                }catch{Write-Host ('  Flat launch failed: '+$_.Exception.Message) -ForegroundColor Yellow}
            }
            'R' { }
            'D' {
                try{Start-Process explorer.exe -ArgumentList ('"'+([Environment]::GetFolderPath('MyDocuments'))+'"') -ErrorAction Stop|Out-Null}
                catch{Write-Host ('  Could not open Documents: '+$_.Exception.Message) -ForegroundColor Yellow}
            }
            'G' {throw 'Video.scr is missing. Run Call of Juarez flat once, close it, then retry this setup.'}
            default {Write-Host '  Choose F, R, D or G.' -ForegroundColor Yellow}
        }
        if(-not(Test-Path -LiteralPath $VideoPath -PathType Leaf)){
            Write-Host '  [!!] Video.scr is still missing. Choose F to launch flat or R to recheck.' -ForegroundColor Yellow
        }
    }
    Write-Host '  [OK] Video.scr found. Continuing this installer.' -ForegroundColor Green
}
function Invoke-CojInstaller{
    $work=$null;$game=$null
    try{
        Write-Host 'Call of Juarez VR - Installer' -ForegroundColor Cyan
        Write-Host 'Community pre-alpha: original Steam 2006 D3D9 game only. Back up your saves before testing.' -ForegroundColor Yellow
        Write-Host 'Start SteamVR before setup. Run Call of Juarez flat once to create Documents\call of juarez\out\Settings\Video.scr.' -ForegroundColor White
        Write-Host 'The Hub prepares a fresh VR session before every Start in VR.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Call of Juarez...')
        $game=Get-CojGame;Write-Host "  Game (Steam D3D9): $game" -ForegroundColor Green
        if(-not $env:PCVR_COJ_TEST_GAME -and (Get-Process -Name CoJ -ErrorAction SilentlyContinue)){throw 'Close Call of Juarez before installation.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The Steam game folder is not writable.'}
        if(-not $env:PCVR_COJ_TEST_GAME -or $env:PCVR_COJ_TEST_VIDEO_FILE){
            $video=if($env:PCVR_COJ_TEST_GAME){
                [void](Assert-CojFixture (Split-Path $env:PCVR_COJ_TEST_VIDEO_FILE -Parent))
                $env:PCVR_COJ_TEST_VIDEO_FILE
            }else{Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'call of juarez\out\Settings\Video.scr'}
            Wait-CojVideoSettings -VideoPath $video
            if(Get-Process -Name CoJ -ErrorAction SilentlyContinue){throw 'Close Call of Juarez before continuing setup.'}
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current CoJ VR prerelease...')
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'CoJ-VR.zip';$version=Get-CojArchive $archive
        $stage=Join-Path $work 'package';[void][IO.Directory]::CreateDirectory($stage)
        [IO.Compression.ZipFile]::ExtractToDirectory($archive,$stage)
        $publisher=Join-Path $stage 'cojvr.ps1'
        Write-Host '  Publisher will patch its tracked D3D9 files and keep its own recovery backups.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run publisher Install / Update...')
        Invoke-CojPublisher -Script $publisher -Game $game -Action Install
        foreach($relative in @('d3d9.dll','.cojvr-public-install.json','.cojvr-d3d9-stage.json')){
            if(-not(Test-Path -LiteralPath (Join-Path $game $relative) -PathType Leaf)){throw "Publisher did not leave required file $relative; nothing was marked complete."}
        }
        if($env:PCVR_HUB_TEST_MODE -ne '1' -or $env:PCVR_COJ_TEST_CACHE){
            $cache=Get-CojCacheRoot
            [void][IO.Directory]::CreateDirectory($cache)
            $target=Join-Path $cache $version
            if(-not(Test-Path -LiteralPath $target -PathType Container)){Copy-Item -LiteralPath $stage -Destination $target -Recurse -Force -ErrorAction Stop}
        }
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_RECEIPT){$env:PCVR_COJ_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:CojContract -GameDir $game -Version $version -Route Steam -InstalledPathReceiptPaths @($receipt))
        Write-Host '  1. Start in VR from the Hub, with SteamVR running.' -ForegroundColor Green
        Write-Host '  The Hub prepares the session, then starts the D3D9 game.' -ForegroundColor White
        Write-Host '  Avoid switching desktop focus while playing; the original game can crash.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host 'The frontier looks different from this side of the revolver.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_COJ_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-CojInstaller;break}catch{$message="Call of Juarez VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)}}
}
