$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Diablo II Resurrected VR Installer'
$id='diablo-ii-resurrected-vr'
$page='https://github.com/natpoh/diablo2-vr-port'
$download='https://bodywalkvr.com/api/download/latest?product=d2r_vr'
$versionSource='https://raw.githubusercontent.com/natpoh/diablo2-vr-port/main/README.md'
$required=@('D2R.exe','D2RLoader.exe','D2R_VR_Settings.exe',
    'd2rloader\plugins\d2rl-vrcam.dll','FlatVR_DepthProvider.addon64','ReShade64.dll')
$contract=New-PCVRInstallerContract -Id $id -GameName 'Diablo II Resurrected VR' -Acquisition External `
    -ReleasePageUrl $page -AntivirusNotice -RequiredInstalledFileGroups $required

function Test-D2RGame([string]$Root){return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'D2R.exe') -PathType Leaf))}
function Get-D2RGameRoot {
    $fixture=(''+$env:PCVR_D2R_TEST_GAME_ROOT).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){
        $full=[IO.Path]::GetFullPath($fixture);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'd2r-fixture.txt'))){throw 'D2R fixture must stay in an isolated temporary folder.'}
        return $full
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $id -StateNames @('installed_path','user_located') -ProbeFiles @('D2R.exe')
    if(Test-D2RGame $saved){return (Get-Item -LiteralPath $saved).FullName}
    $steam=Find-SteamGameFolder -AppId '2536520' -SteamFolderNames @('Diablo II Resurrected') -ProbeExe 'D2R.exe' -HubGameId $id
    if(Test-D2RGame $steam){return (Get-Item -LiteralPath $steam).FullName}
    foreach($candidate in @('C:\Program Files (x86)\Diablo II Resurrected','C:\Program Files (x86)\Steam\steamapps\common\Diablo II Resurrected','C:\XboxGames\Diablo II Resurrected - PC\Content')){
        if(Test-D2RGame $candidate){return (Get-Item -LiteralPath $candidate).FullName}
    }
    $picked=Get-GameFolderInteractive -GameName 'Diablo II Resurrected' -ProbeFile 'D2R.exe' -ManualUrl 'https://d2rloader.net/'
    if(Test-D2RGame $picked){
        [void](Save-HubRememberedGameFolder -GameId $id -Title 'Diablo II Resurrected VR' -GameDir $picked -ProbeFiles @('D2R.exe') -UserSelected)
        return (Get-Item -LiteralPath $picked).FullName
    }
    return $null
}
function Test-D2RVRInstalled([string]$Root){
    foreach($rel in $required){if(-not(Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)){return $false}}
    $localRoot=$env:LOCALAPPDATA
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2R_TEST_LOCALAPPDATA){
        $localRoot=[IO.Path]::GetFullPath($env:PCVR_D2R_TEST_LOCALAPPDATA)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $localRoot.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $localRoot 'd2r-fixture.txt'))){throw 'D2R local state fixture must stay in an isolated temporary folder.'}
    }
    $bridge=Join-Path $localRoot 'BodyWalkVR\plugins\d2r_bridge\d2r_bridge.dll'
    return [bool](Test-Path -LiteralPath $bridge -PathType Leaf)
}
function Get-D2RLoaderArchive {
    param([scriptblock]$ReadInput=$null,[scriptblock]$OpenUrl=$null,[scriptblock]$DownloadFile=$null)
    $fixture=(''+$env:PCVR_D2R_TEST_LOADER_ARCHIVE).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){return (Get-Item -LiteralPath $fixture -ErrorAction Stop).FullName}
    $downloads=Get-PCVRDownloadsFolder
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    $candidate=$null
    if($downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
        $candidate=Get-ChildItem -LiteralPath $downloads -Filter 'D2RLoader*.zip' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    }
    if(-not $candidate -and $handover -and [IO.Path]::GetFileName($handover) -match '(?i)^D2RLoader.*\.zip$'){
        $candidate=Get-Item -LiteralPath $handover -ErrorAction SilentlyContinue
    }
    if($candidate){
        Write-Host "  Found D2RLoader ZIP: $($candidate.FullName)" -ForegroundColor Cyan
        while($true){
            $raw=if($ReadInput){& $ReadInput 'Use this archive? [Y/N]'}else{Read-Host '  Use this archive? [Y/N]'}
            $choice=(''+$raw).Trim().ToUpperInvariant()
            if($choice -in @('Y','YES')){return $candidate.FullName}
            if($choice -in @('N','NO')){break}
            Write-Host '  Please answer Y or N.' -ForegroundColor Yellow
        }
    }else{
        Write-Host '  D2RLoader ZIP was not found in your registered Downloads folder.' -ForegroundColor White
        Write-Host '  The Hub can download the official ZIP automatically.' -ForegroundColor White
        Write-Host '  This may take a few minutes; download progress will be shown.' -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download D2RLoader...' -ReadInput $ReadInput)
        $automatic=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-d2rloader-download-'+[Guid]::NewGuid().ToString('N')+'.zip')
        try{
            $downloaded=if($DownloadFile){& $DownloadFile 'https://d2rloader.net/downloads/latest' $automatic}else{
                _Invoke-DownloadWithProgress -Url 'https://d2rloader.net/downloads/latest' -Destination $automatic -Label 'D2RLoader ZIP'
            }
            if($downloaded -and (Test-DownloadedPayload -Path $automatic -IntendedPath 'D2RLoader.zip')){
                $script:D2RLoaderTemporaryDownload=$automatic
                Write-Host '  [OK] Official D2RLoader ZIP downloaded.' -ForegroundColor Green
                return $automatic
            }
            Write-Host '  Automatic download did not provide a usable ZIP.' -ForegroundColor Yellow
        }catch{Write-Host "  Automatic download failed: $($_.Exception.Message)" -ForegroundColor Yellow}
        finally{if(-not $script:D2RLoaderTemporaryDownload -and (Test-Path -LiteralPath $automatic -PathType Leaf)){Remove-Item -LiteralPath $automatic -Force -ErrorAction SilentlyContinue}}
        Write-Host '  Download the D2RLoader ZIP from the official page.' -ForegroundColor White
        Write-Host '  After the download finishes, return to this window.' -ForegroundColor White
        [void](Open-PCVRPageAfterEnter -Url 'https://d2rloader.net/download.html' -Message 'Press Enter to open the D2RLoader download page...' -ReadInput $ReadInput -OpenUrl $OpenUrl)
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter after the D2RLoader ZIP download is complete...' -ReadInput $ReadInput)
        $downloads=Get-PCVRDownloadsFolder
        if($downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
            $candidate=Get-ChildItem -LiteralPath $downloads -Filter 'D2RLoader*.zip' -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        }
        if($candidate){
            Write-Host "  Found D2RLoader ZIP: $($candidate.FullName)" -ForegroundColor Cyan
            while($true){
                $raw=if($ReadInput){& $ReadInput 'Use this archive? [Y/N]'}else{Read-Host '  Use this archive? [Y/N]'}
                $choice=(''+$raw).Trim().ToUpperInvariant()
                if($choice -in @('Y','YES')){return $candidate.FullName}
                if($choice -in @('N','NO')){break}
                Write-Host '  Please answer Y or N.' -ForegroundColor Yellow
            }
        }
    }
    while($true){
        Write-Host '  Drag the D2RLoader ZIP here or paste its full path.' -ForegroundColor White
        $raw=if($ReadInput){& $ReadInput 'ZIP path (Enter: reopen download page, Q: cancel)'}else{Read-Host '  ZIP path (Enter: reopen download page, Q: cancel)'}
        $path=(''+$raw).Trim().Trim('"').Trim("'")
        if($path -ieq 'Q'){throw 'D2RLoader download was cancelled. No game files were changed.'}
        if(-not $path){
            Write-Host '  Download the D2RLoader ZIP from the official page.' -ForegroundColor White
            [void](Open-PCVRPageAfterEnter -Url 'https://d2rloader.net/download.html' -Message 'Press Enter to reopen the D2RLoader download page...' -ReadInput $ReadInput -OpenUrl $OpenUrl)
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter after the D2RLoader ZIP download is complete...' -ReadInput $ReadInput)
            $downloads=Get-PCVRDownloadsFolder
            if($downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
                $candidate=Get-ChildItem -LiteralPath $downloads -Filter 'D2RLoader*.zip' -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
                if($candidate){
                    Write-Host "  Found D2RLoader ZIP: $($candidate.FullName)" -ForegroundColor Cyan
                    $answer=if($ReadInput){& $ReadInput 'Use this archive? [Y/N]'}else{Read-Host '  Use this archive? [Y/N]'}
                    if((''+$answer).Trim().ToUpperInvariant() -in @('Y','YES')){return $candidate.FullName}
                }
            }
            continue
        }
        if((Test-Path -LiteralPath $path -PathType Leaf) -and [IO.Path]::GetExtension($path) -ieq '.zip'){return (Get-Item -LiteralPath $path).FullName}
        Write-Host '  The selected ZIP was not found.' -ForegroundColor Yellow
    }
}
function Install-D2RLoaderArchive([string]$Archive,[string]$Game){
    $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-d2rloader-'+[Guid]::NewGuid().ToString('N'))
    try{
        $safety=Test-ZipArchiveEntrySafety -ArchivePath $Archive -DestinationFolder $work
        if(-not $safety.Inspectable -or -not $safety.Safe){throw 'D2RLoader ZIP is unreadable or contains an unsafe path.'}
        Write-Host '  [..] Extracting D2RLoader; this may take a minute...' -ForegroundColor Cyan
        $expanded=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $work -Label 'D2RLoader' -AllowSkip $false -QuietProgress
        if([string]$expanded -ne 'ok'){throw 'D2RLoader ZIP was not extracted.'}
        foreach($rel in @('D2RLoader.exe','D2RCore.dll','d2rloader.mpq','d2rloader\config\d2rloader.toml')){
            if(-not(Test-Path -LiteralPath (Join-Path $work $rel) -PathType Leaf)){throw "D2RLoader ZIP is missing $rel."}
        }
        Write-Host '  [..] Installing D2RLoader; this may take a few seconds...' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $work -GameRoot $Game -Identity 'd2rvrloader' `
            -KeepExistingRelativePaths @('d2rloader\config\d2rloader.toml') -ProgressLabel 'Installing D2RLoader')
        if(-not(Test-Path -LiteralPath (Join-Path $Game 'D2RLoader.exe') -PathType Leaf)){throw 'D2RLoader.exe was not installed beside D2R.exe.'}
    }finally{if(Test-Path -LiteralPath $work){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_D2R_LIBRARY_ONLY -eq '1'){return}
while($true){
    $setup=$null
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Diablo II Resurrected VR - Installer' -ForegroundColor Cyan
        Write-Host '  D2R VR by BodyWalkVR / natpoh' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  OFFLINE SINGLE-PLAYER ONLY. Do not use this mod online:' -ForegroundColor Yellow
        Write-Host '  injected code can put your Blizzard account at risk.' -ForegroundColor Yellow
        Write-Host '  The Hub installs D2RLoader from its official ZIP if needed.' -ForegroundColor White
        Write-Host '  Publisher Setup installs the mod, ReShade and BodyWalk bridge.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Diablo II Resurrected...')
        $root=Get-D2RGameRoot
        if(-not $root){throw 'Diablo II Resurrected was not located. No files were changed.'}
        if(Get-Process -Name 'D2R','D2RLoader' -ErrorAction SilentlyContinue){throw 'Close Diablo II Resurrected and D2RLoader before installing.'}
        if(-not(Test-Path -LiteralPath (Join-Path $root 'D2RLoader.exe') -PathType Leaf)){
            $loaderArchive=Get-D2RLoaderArchive
            try{Install-D2RLoaderArchive -Archive $loaderArchive -Game $root}
            finally{
                if($script:D2RLoaderTemporaryDownload -and (Test-Path -LiteralPath $script:D2RLoaderTemporaryDownload -PathType Leaf)){
                    Remove-Item -LiteralPath $script:D2RLoaderTemporaryDownload -Force -ErrorAction SilentlyContinue
                    $script:D2RLoaderTemporaryDownload=$null
                }
            }
        }
        Write-Host "  Game: $root" -ForegroundColor Green
        Write-Host '  The publisher endpoint always delivers its latest Setup.' -ForegroundColor Cyan
        Write-Host '  Download can take several minutes; progress remains visible.' -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the latest publisher Setup...')
        $setup=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-d2r-'+[Guid]::NewGuid().ToString('N')+'.exe')
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2R_TEST_SETUP){
            $fixture=[IO.Path]::GetFullPath($env:PCVR_D2R_TEST_SETUP);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
            if(-not $fixture.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $fixture) 'd2r-fixture.txt'))){throw 'Publisher fixture must stay in an isolated temporary folder.'}
            $setup=$fixture;$ok=$true
        }else{$ok=Invoke-SafeDownload -Urls @($download) -Destination $setup -Label 'D2R VR publisher Setup' -ManualUrl $page -AllowSkip:$false}
        if(-not $ok -or -not(Test-DownloadedPayload -Path $setup -IntendedPath 'D2R_VR_Setup.exe')){throw 'Publisher Setup was not downloaded as a usable EXE.'}
        $version=([string](Get-Item -LiteralPath $setup).VersionInfo.ProductVersion).Trim()
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2R_TEST_SETUP -and $env:PCVR_D2R_TEST_VERSION){$version=$env:PCVR_D2R_TEST_VERSION}
        if(-not(Test-IsTrackableInstalledVersion $version)){throw 'Publisher Setup has no trackable product version; no version was recorded.'}
        Write-Host "  Downloaded publisher version: $version" -ForegroundColor Green
        Write-Host '  In Setup choose the VR headset mode and confirm this game folder.' -ForegroundColor White
        Write-Host '  Setup can download ReShade and may install BodyWalk Lite.' -ForegroundColor White
        Write-Host '  Windows may request administrator approval (UAC).' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            if($env:PCVR_D2R_TEST_EXIT_CODE -and [int]$env:PCVR_D2R_TEST_EXIT_CODE -ne 0){throw "Publisher Setup ended with exit code $env:PCVR_D2R_TEST_EXIT_CODE."}
            $output=[IO.Path]::GetFullPath($env:PCVR_D2R_TEST_PUBLISHER_OUTPUT)
            $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
            if(-not $output.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $output 'd2r-fixture.txt'))){throw 'Publisher output fixture is invalid.'}
            foreach($rel in @($required|Where-Object{$_ -notin @('D2R.exe','D2RLoader.exe')})){
                $src=Join-Path $output $rel;if(Test-Path -LiteralPath $src -PathType Leaf){$dest=Join-Path $root $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath $src -Destination $dest -Force}
            }
            $bridgeSource=Join-Path $output 'BodyWalkVR\plugins\d2r_bridge\d2r_bridge.dll'
            if(Test-Path -LiteralPath $bridgeSource -PathType Leaf){
                $localRoot=[IO.Path]::GetFullPath($env:PCVR_D2R_TEST_LOCALAPPDATA)
                if(-not $localRoot.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $localRoot 'd2r-fixture.txt'))){throw 'D2R local state fixture is invalid.'}
                $bridgeTarget=Join-Path $localRoot 'BodyWalkVR\plugins\d2r_bridge\d2r_bridge.dll'
                [void][IO.Directory]::CreateDirectory((Split-Path -Parent $bridgeTarget));Copy-Item -LiteralPath $bridgeSource -Destination $bridgeTarget -Force
            }
        }else{
            $process=Start-Process -FilePath $setup -Wait -PassThru -ErrorAction Stop
            if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher Setup ended with exit code $($process.ExitCode)."}
        }
        if(-not(Test-D2RVRInstalled $root)){throw 'Publisher Setup did not leave all VR-mode files and the BodyWalk bridge; no success was recorded.'}
        $receipt=Join-Path $PSScriptRoot '.installed_path'
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2R_TEST_SETUP){$receipt=Join-Path (Split-Path -Parent $env:PCVR_D2R_TEST_SETUP) 'installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $version -Route Current -InstalledPathReceiptPaths @($receipt))
        Write-Host "  [OK] D2R VR $version is installed." -ForegroundColor Green
        Write-Host '  Start in VR opens D2R VR Settings.' -ForegroundColor White
        Write-Host '  On Home, select Start BodyWalk, then Launch Diablo II (D2RLoader).' -ForegroundColor White
        Write-Host ''
        Write-Host '  Even Deckard Cain never identified a drop this immersive.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
        exit 0
    }catch{
        $message="Diablo II Resurrected VR setup did not complete: $($_.Exception.Message)"
        Write-Host "  $message" -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{
        if($setup -and $env:PCVR_HUB_TEST_MODE -ne '1' -and (Test-Path -LiteralPath $setup -PathType Leaf)){Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue}
    }
}
