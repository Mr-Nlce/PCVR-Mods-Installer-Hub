$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='XIII VR Installer'
$script:XIIIId='xiii-remake-vr'
$script:XIIIRepo='CastleTroy28/XIII-VR'
$script:XIIIPage="https://github.com/$script:XIIIRepo/releases"
$script:XIIIBepInExName='BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.788+5b766a3.zip'
$script:XIIIBepInExUrl='https://builds.bepinex.dev/projects/bepinex_be/788/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.788%2B5b766a3.zip'
$script:XIIIBepInExPage='https://builds.bepinex.dev/projects/bepinex_be'
$script:XIIIRequired=@('XIII.exe','GameAssembly.dll','UnityPlayer.dll',
    'BepInEx\plugins\XIII.XRBootstrap.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll',
    'doorstop_config.ini','winhttp.dll','XIII_Data\Plugins\xiii_openxr.dll',
    'XIII_Data\Plugins\openxr_loader.dll')
$script:XIIIContract=New-PCVRInstallerContract -Id $script:XIIIId -GameName 'XIII VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $script:XIIIPage -RequiredInstalledFileGroups $script:XIIIRequired
function Get-XIIIReceiptPath {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_XIII_TEST_RECEIPT){
        $path=[IO.Path]::GetFullPath($env:PCVR_XIII_TEST_RECEIPT)
        [void](Assert-XIIIFixture (Split-Path -Parent $path))
        return $path
    }
    return (Join-Path $PSScriptRoot '.installed_path')
}

function Test-XIIIBase([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath $Root -PathType Container)){return $false}
    foreach($name in @('XIII.exe','GameAssembly.dll','UnityPlayer.dll','XIII_Data\il2cpp_data\Metadata\global-metadata.dat')){
        if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)){return $false}
    }
    $v=(Get-Item -LiteralPath (Join-Path $Root 'UnityPlayer.dll')).VersionInfo
    return ($v.FileMajorPart -eq 2020 -and $v.FileMinorPart -eq 3 -and $v.FileBuildPart -eq 25)
}
function Assert-XIIIFixture([string]$Path){
    $full=[IO.Path]::GetFullPath($Path)
    $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
       -not(Test-Path -LiteralPath (Join-Path $full 'xiii-fixture.txt') -PathType Leaf)){
        throw 'XIII fixture paths must stay in an isolated temporary folder.'
    }
    return $full
}
function Get-XIIIBase {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_XIII_TEST_GAME){
        $root=Assert-XIIIFixture $env:PCVR_XIII_TEST_GAME
        if(-not(Test-XIIIBase $root)){throw 'The isolated XIII Remake fixture is incomplete or has the wrong Unity build.'}
        return $root
    }
    $paths=[Collections.Generic.List[string]]::new()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:XIIIId -StateNames @('installed_path','user_located') -ProbeFiles @('XIII.exe','UnityPlayer.dll')
    if($saved){$paths.Add($saved)}
    try{$steam=Find-SteamGameFolder -AppId '1154790' -SteamFolderNames @('XIII') -ProbeExe 'XIII.exe' -HubGameId $script:XIIIId;if($steam){$paths.Add($steam)}}catch{}
    foreach($p in @('C:\Program Files (x86)\Steam\steamapps\common\XIII',
        'C:\Program Files\Epic Games\XIII','C:\Program Files (x86)\GOG Galaxy\Games\XIII - Remake',
        'C:\GOG Games\XIII - Remake','C:\XboxGames\XIII\Content')){$paths.Add($p)}
    foreach($p in @($paths|Select-Object -Unique)){if(Test-XIIIBase $p){return (Get-Item -LiteralPath $p).FullName}}
    $picked=Get-GameFolderInteractive -GameName 'XIII (2020 Remake)' -ProbeFile 'XIII.exe' -ManualUrl 'https://store.steampowered.com/app/1154790/'
    if(Test-XIIIBase $picked){return (Get-Item -LiteralPath $picked).FullName}
    throw 'Select the XIII Remake folder with XIII.exe and Unity 2020.3.25f1.'
}
function Get-XIIIRelease {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_XIII_TEST_ARCHIVE){
        $p=[IO.Path]::GetFullPath($env:PCVR_XIII_TEST_ARCHIVE)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $p.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
           -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $p) 'xiii-fixture.txt'))){throw 'XIII release fixture is outside isolated temporary state.'}
        if([IO.Path]::GetFileName($p) -notmatch '(?i)^XIII-VR-(\d+(?:\.\d+){2})\.zip$'){throw 'XIII fixture ZIP name has no version.'}
        return [pscustomobject]@{Version=$Matches[1];Tag=('v'+$Matches[1]);Url=$p;Local=$true}
    }
    $r=Resolve-GitHubReleaseAsset -Repo $script:XIIIRepo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^XIII-VR-\d+(?:\.\d+){2}\.zip$') -SkipReleasesWithoutMatchingAsset
    if(-not $r.Resolved -or [string]$r.AssetName -notmatch '(?i)^XIII-VR-(\d+(?:\.\d+){2})\.zip$'){
        Write-Host '  [!!] The current XIII VR release could not be checked on GitHub.' -ForegroundColor Yellow
        if($r.ReleaseFound){
            Write-Host '  GitHub returned a release with a different asset layout. Choose its ZIP on the release page.' -ForegroundColor Yellow
            return [pscustomobject]@{Version='';Tag='';Url='';Local=$false;Manual=$true}
        }
        Write-Host '  The last reviewed publisher version is 0.1.256 (10 October 2026).' -ForegroundColor Yellow
        Write-Host '  A newer release may exist. You can use 0.1.256 or choose a current ZIP from the release page.' -ForegroundColor White
        $choice=(Read-Host '  Download the reviewed 0.1.256 ZIP? Y/N').Trim()
        if($choice -match '^(?i)y(?:es)?$'){
            return [pscustomobject]@{Version='0.1.256';Tag='v0.1.256';
                Url='https://github.com/CastleTroy28/XIII-VR/releases/download/v0.1.256/XIII-VR-0.1.256.zip';Local=$false;Manual=$false}
        }
        return [pscustomobject]@{Version='';Tag='';Url='';Local=$false;Manual=$true}
    }
    if(-not(Test-IsTrackableInstalledVersion $Matches[1])){throw 'The XIII VR release has no trackable version.'}
    return [pscustomobject]@{Version=$Matches[1];Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false;Manual=$false}
}
function Get-XIIIPayload([string]$Archive,[string]$Work){
    $stage=Join-Path $Work 'publisher'
    Write-Host '  [..] Extracting the XIII VR publisher ZIP; this may take a few seconds.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $stage -Label 'XIII VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The XIII VR ZIP could not be opened.'}
    foreach($name in @('Install-XIII-VR.ps1','BepInEx-plugins\XIII.XRBootstrap.dll.bin',
        'GameFolder\XIII_Data\Plugins\xiii_openxr.dll','GameFolder\XIII_Data\Plugins\openxr_loader.dll')){
        if(-not(Test-Path -LiteralPath (Join-Path $stage $name) -PathType Leaf)){throw "The XIII VR package is missing $name."}
    }
    return $stage
}
function Get-XIIIJournal([string]$Root){
    $parent=Join-Path $Root 'XIII-VR-backups'
    foreach($file in @(Get-ChildItem -LiteralPath $parent -Filter install.json -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending)){
        try {$j=Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
            if($j.status -eq 'installed' -and [IO.Path]::GetFullPath([string]$j.gameDir).TrimEnd('\') -ieq [IO.Path]::GetFullPath($Root).TrimEnd('\')){
                return [pscustomobject]@{Path=$file.FullName;Journal=$j}
            }
        }catch{}
    }
    return $null
}
function Get-XIIICacheRoot {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_XIII_TEST_CACHE){return (Assert-XIIIFixture $env:PCVR_XIII_TEST_CACHE)}
    return (Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\Publisher\XIIIVR')
}
function Test-XIIIBepInExArchive([string]$Path){
    if(-not $Path -or -not(Test-Path -LiteralPath $Path -PathType Leaf)){return $false}
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try {
            $names=@($zip.Entries|ForEach-Object {$_.FullName.Replace('/','\')})
            foreach($name in @('BepInEx\core\BepInEx.Unity.IL2CPP.dll','doorstop_config.ini','winhttp.dll','dotnet\coreclr.dll')){
                if($names -notcontains $name){return $false}
            }
            return $true
        } finally {$zip.Dispose()}
    } catch {return $false}
}
function Get-XIIIBepInExArchive([string]$Game,[string]$Work){
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    if($handover){
        if(-not(Test-XIIIBepInExArchive $handover)){throw 'The supplied file is not the required BepInEx Windows IL2CPP x64 ZIP.'}
        return $handover
    }
    if(Test-Path -LiteralPath (Join-Path $Game 'doorstop_config.ini') -PathType Leaf){return ''}
    $target=Join-Path $Work $script:XIIIBepInExName
    Write-Host '  [..] Downloading the official BepInEx be.788 ZIP; this may take a few minutes.' -ForegroundColor Cyan
    $download=Invoke-SafeDownload -Urls @($script:XIIIBepInExUrl) -Destination $target -Label 'BepInEx be.788 Windows IL2CPP x64' `
        -ManualUrl $script:XIIIBepInExPage -AllowSkip $false -Validator {param($candidate) Test-XIIIBepInExArchive $candidate} `
        -Instructions 'On the official BepInEx builds page, choose build #788 and its Unity IL2CPP Windows x64 ZIP.'
    if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'The required BepInEx ZIP was not obtained.'}
    if(-not(Test-XIIIBepInExArchive $target)){throw 'The BepInEx ZIP is missing required loader files.'}
    return $target
}
function Invoke-XIIIPublisher([string]$Script,[string]$Game,[string]$BepInExZip='',[switch]$Uninstall){
    $arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "'+$Script+'" -GameDir "'+$Game+'"'
    if($BepInExZip){$arguments+=' -BepInExZip "'+$BepInExZip+'"'}
    if($Uninstall){$arguments+=' -Uninstall'}
    $process=Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -NoNewWindow -Wait -PassThru -ErrorAction Stop
    if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher installer ended with exit code $($process.ExitCode)."}
}
function Invoke-XIIIInstaller {
    $work=$null
    try {
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  XIII VR Installer' -ForegroundColor Cyan
        Write-Host '  XIII VR by CastleTroy28' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  XIII Remake (2020), 64-bit, with Unity 2020.3.25f1 is required.' -ForegroundColor White
        Write-Host '  The publisher installer backs up changed files and preserves settings.' -ForegroundColor White
        Write-Host '  First setup downloads its tested BepInEx loader and may take minutes.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate XIII Remake...')
        $game=Get-XIIIBase
        if(Get-Process -Name 'XIII' -ErrorAction SilentlyContinue){throw 'Close XIII before installing or updating.'}
        Write-Host "  Game: $game" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download XIII VR...')
        $release=Get-XIIIRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_xiii_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'XIIIVR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive}
        elseif($release.Manual){
            $info=@{}
            [void](Invoke-SafeDownload -Urls @() -Destination $archive -Label 'XIII VR publisher ZIP' `
                -ManualUrl $script:XIIIPage -AllowSkip $false -DownloadInfo $info)
            $leaf=[IO.Path]::GetFileName([string]$info.SourcePath)
            if($leaf -notmatch '(?i)^XIII-VR-(\d+(?:\.\d+){2})\.zip$'){
                throw 'Choose the official versioned XIII VR ZIP; the selected file was not installed.'
            }
            $release.Version=$Matches[1];$release.Tag='v'+$Matches[1]
            Write-Host "  Selected publisher version: $($release.Version)." -ForegroundColor Yellow
            if((Read-Host '  Use this version? Y/N').Trim() -notmatch '^(?i)y(?:es)?$'){
                throw 'Publisher version was not confirmed; no game files were changed.'
            }
        } else {
            $download=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "XIII VR $($release.Tag)" `
                -ExpectedReleaseTag $release.Tag -ManualUrl $script:XIIIPage -AllowSkip $false
            if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'XIII VR download did not complete.'}
        }
        $stage=Get-XIIIPayload -Archive $archive -Work $work
        $loaderZip=Get-XIIIBepInExArchive -Game $game -Work $work
        Write-Host '  [..] Running the publisher installer; this may take several minutes.' -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run XIII VR publisher setup...')
        Invoke-XIIIPublisher -Script (Join-Path $stage 'Install-XIII-VR.ps1') -Game $game -BepInExZip $loaderZip
        foreach($name in $script:XIIIRequired){if(-not(Test-Path -LiteralPath (Join-Path $game $name) -PathType Leaf)){throw "Installed XIII VR file is missing: $name"}}
        $journal=Get-XIIIJournal $game
        if(-not $journal){throw 'Publisher Setup did not leave an installed restore journal.'}
        $cache=Get-XIIICacheRoot
        [void][IO.Directory]::CreateDirectory($cache)
        Copy-Item -LiteralPath (Join-Path $stage 'Install-XIII-VR.ps1') -Destination (Join-Path $cache 'Install-XIII-VR.ps1') -Force
        if(-not(Save-HubRememberedGameFolder -GameId $script:XIIIId -Title 'XIII VR' -GameDir $game -ProbeFiles @('XIII.exe','UnityPlayer.dll'))){
            throw 'The XIII game location could not be saved for future Hub scans.'
        }
        [void](Complete-PCVRInstallTransaction -Contract $script:XIIIContract -GameDir $game -Version $release.Version `
            -InstalledPathReceiptPaths @((Get-XIIIReceiptPath)))
        Write-Host "  [OK] XIII VR release $($release.Version) installed." -ForegroundColor Green
        Write-Host '  Start in VR opens XIII.exe; the first BepInEx start can take longer.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Follow the clues. Trust your hands.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {
        if($work -and $work.StartsWith(([IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'),[StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path -Leaf $work) -like 'pcvr_xiii_*' -and (Test-Path -LiteralPath $work)){
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
if($env:PCVR_XIII_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-XIIIInstaller;break}catch{$msg="XIII VR setup did not complete: $($_.Exception.Message)";Write-Host $msg -ForegroundColor Red;
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $msg -InstallerFolder $PSScriptRoot)}}
}
