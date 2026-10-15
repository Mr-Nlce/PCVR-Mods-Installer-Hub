$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Arx Fatalis VR Installer'
$script:ArxId='arx-fatalis-vr'
$script:ArxRepo='cmpayc/ArxLibertatisVR'
$script:ArxPage="https://github.com/$script:ArxRepo/releases"
$script:ArxRequired=@('arx.exe','ArxIO.dll','openxr_loader.dll','SDL2.dll','OpenAL32.dll',
    'data\misc\icons.ttf','VERSION.txt','START-ARX-VR.cmd','START-ARX-VR.ps1',
    'launcher-game-path.txt','.pcvrhub_arxvr_ownership.csv')
$script:ArxContract=New-PCVRInstallerContract -Id $script:ArxId -GameName 'Arx Fatalis VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:ArxPage -Routes @('Standalone') `
    -RequiredInstalledFileGroups $script:ArxRequired
function Get-ArxReceiptPath {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ARX_TEST_RECEIPT){
        $path=[IO.Path]::GetFullPath($env:PCVR_ARX_TEST_RECEIPT)
        [void](Assert-ArxFixture (Split-Path -Parent $path))
        return $path
    }
    return (Join-Path $PSScriptRoot '.installed_path')
}

function Test-ArxBase([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath $Root -PathType Container)){return $false}
    foreach($name in @('arx.exe','data.pak','data2.pak','loc.pak','sfx.pak','speech.pak')){
        if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)){return $false}
    }
    return $true
}
function Assert-ArxFixture([string]$Path){
    $full=[IO.Path]::GetFullPath($Path)
    $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
       -not(Test-Path -LiteralPath (Join-Path $full 'arx-fixture.txt') -PathType Leaf)){
        throw 'Arx fixture paths must stay in an isolated temporary folder.'
    }
    return $full
}
function Get-ArxBase {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ARX_TEST_GAME){
        $root=Assert-ArxFixture $env:PCVR_ARX_TEST_GAME
        if(-not(Test-ArxBase $root)){throw 'The isolated Arx game data is incomplete.'}
        return $root
    }
    $paths=[Collections.Generic.List[string]]::new()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:ArxId -StateNames @('base_game_path','user_located') -ProbeFiles @('arx.exe','data.pak')
    if($saved){$paths.Add($saved)}
    try {$steam=Find-SteamGameFolder -AppId '1700' -SteamFolderNames @('Arx Fatalis') -ProbeExe 'arx.exe' -HubGameId $script:ArxId; if($steam){$paths.Add($steam)}} catch {}
    foreach($p in @('C:\Program Files (x86)\Steam\steamapps\common\Arx Fatalis',
        'C:\Program Files (x86)\GOG Galaxy\Games\Arx Fatalis','C:\GOG Games\Arx Fatalis',
        'C:\XboxGames\Arx Fatalis\Content','C:\Program Files\JoWooD\Arxfatalis')){$paths.Add($p)}
    foreach($p in @($paths|Select-Object -Unique)){if(Test-ArxBase $p){return (Get-Item -LiteralPath $p).FullName}}
    $picked=Get-GameFolderInteractive -GameName 'Arx Fatalis' -ProbeFile 'data.pak' -ManualUrl 'https://store.steampowered.com/app/1700/'
    if(Test-ArxBase $picked){return (Get-Item -LiteralPath $picked).FullName}
    throw 'Select your Arx Fatalis folder containing arx.exe and the original .pak game data.'
}
function Get-ArxTarget([string]$Base){
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ARX_TEST_TARGET){return (Assert-ArxFixture $env:PCVR_ARX_TEST_TARGET)}
    $receipt=Get-ArxReceiptPath
    $saved=try{([IO.File]::ReadAllText($receipt)).Trim()}catch{''}
    $default=if($saved -and (Test-Path -LiteralPath $saved -PathType Container)){$saved}else{Join-Path $env:LOCALAPPDATA 'ArxLibertatisVR'}
    while($true){
        Write-Host "  VR install folder: $default" -ForegroundColor Cyan
        $raw=(''+(Read-Host '  Enter = use this folder; paste another folder; Q = cancel')).Trim().Trim('"').Trim("'")
        if($raw -ieq 'Q'){throw 'Arx Fatalis VR setup cancelled; no files were changed.'}
        $target=if($raw){$raw}else{$default}
        try {
            $full=[IO.Path]::GetFullPath($target).TrimEnd('\','/')
            $baseFull=[IO.Path]::GetFullPath($Base).TrimEnd('\','/')
            $hubFull=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\','/')
            if($full -ieq $baseFull -or $full.StartsWith($baseFull+'\',[StringComparison]::OrdinalIgnoreCase) -or
               $full -ieq $hubFull -or $full.StartsWith($hubFull+'\',[StringComparison]::OrdinalIgnoreCase)){
                throw 'Choose a separate folder outside the original game and Hub.'
            }
            if((Get-PCVRInstallerVolumeFreeBytes $full) -lt 30000000L -or -not(Test-InstallerTargetWritable -TargetPath $full)){
                throw 'The VR folder needs at least 30 MB free and write access.'
            }
            return $full
        } catch {Write-Host ('  '+$_.Exception.Message) -ForegroundColor Yellow}
    }
}
function Get-ArxRelease {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ARX_TEST_ARCHIVE){
        $p=[IO.Path]::GetFullPath($env:PCVR_ARX_TEST_ARCHIVE)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $p.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
           -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $p) 'arx-fixture.txt'))){throw 'Arx release fixture is outside isolated temporary state.'}
        if([IO.Path]::GetFileName($p) -notmatch '^ArxLibertatisVR-(\d+(?:\.\d+){2})-win64\.zip$'){throw 'Arx fixture ZIP name has no version.'}
        return [pscustomobject]@{Version=$Matches[1];Tag=('v'+$Matches[1]);Url=$p;Local=$true}
    }
    $r=Resolve-GitHubReleaseAsset -Repo $script:ArxRepo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^ArxLibertatisVR-\d+(?:\.\d+){2}-win64\.zip$') -SkipReleasesWithoutMatchingAsset
    if(-not $r.Resolved -or [string]$r.AssetName -notmatch '(?i)^ArxLibertatisVR-(\d+(?:\.\d+){2})-win64\.zip$'){
        throw 'The current Arx Fatalis VR release could not be resolved. Use Retry or hand over its official ZIP.'
    }
    if(-not(Test-IsTrackableInstalledVersion $Matches[1])){throw 'The Arx VR release has no trackable version.'}
    return [pscustomobject]@{Version=$Matches[1];Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false}
}
function Get-ArxPayload([string]$Archive,[string]$Work,[string]$Version,[string]$Base){
    $expanded=Join-Path $Work 'expanded'
    Write-Host '  [..] Extracting Arx Libertatis VR; this may take a few seconds.' -ForegroundColor Cyan
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'Arx VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The Arx VR ZIP could not be opened.'}
    $stage=Get-ExtractedPayloadRoot -ExtractDir $expanded -RelModFile 'arx.exe'
    if(-not $stage){throw 'The Arx VR ZIP has no arx.exe at its package root.'}
    foreach($name in @('arx.exe','ArxIO.dll','openxr_loader.dll','SDL2.dll','OpenAL32.dll','VERSION.txt','data\misc\icons.ttf')){
        if(-not(Test-Path -LiteralPath (Join-Path $stage $name) -PathType Leaf)){throw "The Arx VR package is missing $name."}
    }
    $versionText=Get-Content -LiteralPath (Join-Path $stage 'VERSION.txt') -Raw
    if($versionText -notmatch "(?m)^Arx Libertatis VR $([regex]::Escape($Version))\b"){
        throw 'The Arx VR package version disagrees with the selected release.'
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'START-ARX-VR.cmd') -Destination (Join-Path $stage 'START-ARX-VR.cmd') -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'START-ARX-VR.ps1') -Destination (Join-Path $stage 'START-ARX-VR.ps1') -Force
    Write-PCVRAtomicText -Path (Join-Path $stage 'launcher-game-path.txt') -Value $Base
    return $stage
}
function Invoke-ArxInstaller {
    $work=$null
    try {
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Arx Fatalis VR Installer' -ForegroundColor Cyan
        Write-Host '  Arx Libertatis VR by cmpayc' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Your original Arx Fatalis .pak files are required.' -ForegroundColor White
        Write-Host '  The VR port installs separately; it reads the original game data.' -ForegroundColor White
        Write-Host '  Start SteamVR or Meta Quest Link before launching in VR.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Arx Fatalis...')
        $base=Get-ArxBase
        $target=Get-ArxTarget $base
        if(Get-Process -Name 'arx' -ErrorAction SilentlyContinue){throw 'Close Arx Fatalis and Arx Libertatis VR before installing.'}
        Write-Host "  Game data: $base" -ForegroundColor Green
        Write-Host "  VR folder: $target" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download Arx Libertatis VR...')
        $release=Get-ArxRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_arx_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'ArxLibertatisVR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive}
        else {
            $download=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Arx Libertatis VR $($release.Tag)" `
                -ExpectedReleaseTag $release.Tag -ManualUrl $script:ArxPage -AllowSkip $false
            if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'Arx VR download did not complete.'}
        }
        $stage=Get-ArxPayload -Archive $archive -Work $work -Version $release.Version -Base $base
        Write-Host '  [..] Installing VR files; this may take a few seconds.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $target -Identity 'arxvr' -AdoptIdenticalExisting -ProgressLabel 'Installing Arx Libertatis VR')
        foreach($name in $script:ArxRequired){if(-not(Test-Path -LiteralPath (Join-Path $target $name) -PathType Leaf)){throw "Installed Arx VR file is missing: $name"}}
        $survivalPaths=@(@('arx.exe','ArxIO.dll','openxr_loader.dll','START-ARX-VR.cmd') | ForEach-Object {Join-Path $target $_})
        if(-not(Confirm-PlacedFilesSurvive -Paths $survivalPaths -GameDir $target -NoClear)){
            throw 'Required Arx VR files did not survive installation.'
        }
        if(-not(Save-HubRememberedGameFolder -GameId $script:ArxId -Title 'Arx Fatalis VR' -GameDir $base -ProbeFiles @('arx.exe','data.pak') -StateName 'base_game_path')){
            throw 'The original game location could not be saved for future Hub scans.'
        }
        [void](Complete-PCVRInstallTransaction -Contract $script:ArxContract -GameDir $target -Version $release.Version `
            -InstalledPathReceiptPaths @((Get-ArxReceiptPath)) -Route Standalone)
        Write-Host "  [OK] Arx Libertatis VR $($release.Version) installed." -ForegroundColor Green
        Write-Host '  Start in VR opens the separate VR port with your original game data.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  The runes are in your hands now.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {
        if($work -and $work.StartsWith(([IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'),[StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path -Leaf $work) -like 'pcvr_arx_*' -and (Test-Path -LiteralPath $work)){
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
if($env:PCVR_ARX_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-ArxInstaller;break}catch{$msg="Arx Fatalis VR setup did not complete: $($_.Exception.Message)";Write-Host $msg -ForegroundColor Red;
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $msg -InstallerFolder $PSScriptRoot)}}
}
