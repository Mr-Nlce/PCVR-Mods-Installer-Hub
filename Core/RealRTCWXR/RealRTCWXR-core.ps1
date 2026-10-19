$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='RealRTCW XR Installer'
$script:RTCWId='return-to-castle-wolfenstein-vr'
$script:RTCWRepo='Team-Beef-Studios/RealRTCWXR'
$script:RTCWPage="https://github.com/$script:RTCWRepo/releases"
$script:RTCWVrFiles=@('RealRTCWXR.exe','renderer_sp_rend2_xr_64.dll','SDL264.dll','OpenAL64.dll',
    'Main\cgame_sp_xr_64.dll','Main\qagame_sp_xr_64.dll','Main\ui_sp_xr_64.dll',
    'Main\z_zzzRealRTCWXR.pk3','Main\z_realrtcw_models_hands_vr.pk3','Main\z_zzzz_remastered_digitaldeluxe_3.pk3')
$script:RTCWBaseFiles=@('pak0.pk3','sp_pak1.pk3','sp_pak2.pk3','sp_pak3.pk3','sp_pak4.pk3')
$script:RTCWRealFiles=@('realrtcwdefault.cfg','autoexec.cfg','xbox.cfg','xbox_cinematic.cfg',
    'z_realrtcw_localization.pk3','z_realrtcw_maps.pk3','z_realrtcw_models.pk3',
    'z_realrtcw_models_characters.pk3','z_realrtcw_models_weapons.pk3','z_realrtcw_sounds.pk3',
    'z_realrtcw_textures.pk3','z_zperson.pk3','z_zrealrtcw_ui.pk3','z_zzrealrtcw_scripts.pk3','z_zzzsurvival.pk3')
$script:RTCWContract=New-PCVRInstallerContract -Id $script:RTCWId -GameName 'RealRTCW XR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:RTCWPage -Routes @('Full','Minimal') `
    -RequiredInstalledFileGroups @($script:RTCWVrFiles + @('Main\pak0.pk3','Main\sp_pak1.pk3','Main\sp_pak2.pk3','Main\sp_pak3.pk3','Main\sp_pak4.pk3'))

function Test-RTCWBase([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root 'WolfSP.exe') -PathType Leaf)){return $false}
    foreach($name in $script:RTCWBaseFiles){if(-not(Test-Path -LiteralPath (Join-Path $Root ('Main\'+$name)) -PathType Leaf)){return $false}}
    return $true
}
function Get-RTCWBase {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_GAME){
        if(-not(Test-RTCWBase $env:PCVR_RTCW_TEST_GAME)){throw 'The isolated RTCW game fixture is incomplete.'}
        return [IO.Path]::GetFullPath($env:PCVR_RTCW_TEST_GAME)
    }
    $paths=[Collections.Generic.List[string]]::new()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:RTCWId -StateNames @('installed_path','user_located') -ProbeFiles @('WolfSP.exe')
    if($saved){$paths.Add($saved)}
    try{$steam=Find-SteamGameFolder -AppId '9010' -SteamFolderNames @('Return To Castle Wolfenstein','Return to Castle Wolfenstein') -ProbeExe 'WolfSP.exe' -HubGameId $script:RTCWId;if($steam){$paths.Add($steam)}}catch{}
    foreach($p in @('C:\Program Files (x86)\Steam\steamapps\common\Return to Castle Wolfenstein',
        'C:\Program Files (x86)\GOG Galaxy\Games\Return to Castle Wolfenstein',
        'C:\GOG Games\Return to Castle Wolfenstein','C:\XboxGames\Return to Castle Wolfenstein\Content',
        'C:\Program Files (x86)\Return to Castle Wolfenstein',
        'C:\Program Files (x86)\Return to Castle Wolfenstein - Game of The Year Edition')){$paths.Add($p)}
    foreach($p in @($paths|Select-Object -Unique)){if(Test-RTCWBase $p){return (Get-Item -LiteralPath $p).FullName}}
    $picked=Get-GameFolderInteractive -GameName 'Return to Castle Wolfenstein' -ProbeFile 'WolfSP.exe' -ManualUrl 'https://store.steampowered.com/app/9010/'
    if(Test-RTCWBase $picked){return (Get-Item -LiteralPath $picked).FullName}
    throw 'Choose the original RTCW folder containing WolfSP.exe and the five Main game PK3 files.'
}
function Get-RTCWBundleChoice {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_BUNDLE){return $env:PCVR_RTCW_TEST_BUNDLE}
    Write-Host '  [1] Full - RealRTCW data included; only your original RTCW is needed.' -ForegroundColor Green
    Write-Host '  [2] Minimal - needs RealRTCW 5.0 beta as well as original RTCW.' -ForegroundColor White
    while($true){
        $answer=(Read-Host 'Choose 1 or 2 (Enter: Full)').Trim()
        if(-not $answer -or $answer -eq '1'){return 'Full'}
        if($answer -eq '2'){return 'Minimal'}
        Write-Host '  Choose 1 or 2.' -ForegroundColor Yellow
    }
}
function Get-RTCWRelease([string]$Bundle){
    $pattern='(?i)^RealRTCWXR-(\d+(?:\.\d+){2})-(?:Release-)?'+[regex]::Escape($Bundle)+'-Setup\.exe$'
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_SETUP){
        $name=[IO.Path]::GetFileName($env:PCVR_RTCW_TEST_SETUP)
        if($name -notmatch $pattern){throw 'The publisher Setup does not match the selected bundle.'}
        return [pscustomobject]@{Version=$Matches[1];Tag=$Matches[1];Name=$name;Url=$env:PCVR_RTCW_TEST_SETUP;Local=$true}
    }
    $r=Resolve-GitHubReleaseAsset -Repo $script:RTCWRepo -IncludePrerelease $true -AssetPatterns @($pattern) -SkipReleasesWithoutMatchingAsset
    if(-not $r.Resolved -or [string]$r.AssetName -notmatch $pattern){
        Write-Host "  [!!] The current $Bundle release could not be checked on GitHub." -ForegroundColor Yellow
        if($r.ReleaseFound){
            Write-Host '  GitHub returned a release with a different asset layout. Choose its Setup on the release page.' -ForegroundColor Yellow
            return [pscustomobject]@{Version='';Tag='';Name="RealRTCWXR-$Bundle-Setup.exe";Url='';Local=$false;Manual=$true}
        }
        Write-Host '  The last reviewed publisher version is 0.8.7 (10 October 2026).' -ForegroundColor Yellow
        Write-Host '  A newer release may exist. You can use 0.8.7 or choose a current file from the release page.' -ForegroundColor White
        $choice=(Read-Host '  Download the reviewed 0.8.7 Setup? Y/N').Trim()
        if($choice -match '^(?i)y(?:es)?$'){
            $name="RealRTCWXR-0.8.7-Release-$Bundle-Setup.exe"
            return [pscustomobject]@{Version='0.8.7';Tag='0.8.7';Name=$name;
                Url="https://github.com/$script:RTCWRepo/releases/download/0.8.7/$name";Local=$false;Manual=$false}
        }
        return [pscustomobject]@{Version='';Tag='';Name="RealRTCWXR-$Bundle-Setup.exe";Url='';Local=$false;Manual=$true}
    }
    return [pscustomobject]@{Version=$Matches[1];Tag=[string]$r.Tag;Name=[string]$r.AssetName;Url=[string]$r.Url;Local=$false;Manual=$false}
}
function Test-RTCWInstalled([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath $Root -PathType Container)){return $false}
    foreach($name in $script:RTCWVrFiles){if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)){return $false}}
    foreach($name in @($script:RTCWBaseFiles+$script:RTCWRealFiles)){
        if(-not(Test-Path -LiteralPath (Join-Path $Root ('Main\'+$name)) -PathType Leaf)){return $false}
    }
    return $true
}
function Find-RTCWInstalled([string]$DefaultRoot){
    $paths=[Collections.Generic.List[string]]::new()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_INSTALL_ROOT){$paths.Add($env:PCVR_RTCW_TEST_INSTALL_ROOT)}
    if(Test-Path -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -PathType Leaf){$paths.Add(([string](Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw)).Trim())}
    if($DefaultRoot){$paths.Add($DefaultRoot)}
    foreach($desktop in @([Environment]::GetFolderPath('DesktopDirectory'),[Environment]::GetFolderPath('CommonDesktopDirectory'))){
        $link=Join-Path $desktop 'RealRTCW XR.lnk'
        if(Test-Path -LiteralPath $link -PathType Leaf){try{$shell=New-Object -ComObject WScript.Shell;$target=$shell.CreateShortcut($link).TargetPath
            if([IO.Path]::GetFileName($target) -ieq 'RealRTCWXR.exe'){$paths.Add((Split-Path -Parent $target))}}catch{}}
    }
    foreach($p in @($paths|Where-Object {$_}|Select-Object -Unique)){if(Test-RTCWInstalled $p){return [IO.Path]::GetFullPath($p)}}
    return ''
}
function Write-RTCWOwnership([string]$Root){
    $rows=@(foreach($name in $script:RTCWVrFiles){$p=Join-Path $Root $name;[pscustomobject]@{Path=$name;Sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}})
    $rows | Export-Csv -LiteralPath (Join-Path $Root '.pcvrhub_rtcwxr_ownership.csv') -NoTypeInformation -Encoding UTF8
}
function Get-RTCWPayloadFingerprint([string]$Root){
    if(-not(Test-RTCWInstalled $Root)){return ''}
    $parts=@(foreach($name in $script:RTCWVrFiles){(Get-FileHash -LiteralPath (Join-Path $Root $name) -Algorithm SHA256).Hash})
    return ($parts -join ':')
}
function Invoke-RTCWInstaller {
    $work=''
    try {
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  RealRTCW XR - Return to Castle Wolfenstein in VR' -ForegroundColor Cyan
        Write-Host '  VR port by Team Beef Studios' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  The original RTCW game is required for both setup options.' -ForegroundColor White
        Write-Host '  Full includes the RealRTCW overhaul; Minimal needs RealRTCW 5.0 beta.' -ForegroundColor White
        Write-Host '  The publisher installs a separate VR copy, leaving your game intact.' -ForegroundColor White
        Write-Host '  Full downloads about 2 GB. Choose a drive with room for setup.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate RTCW...')
        $game=Get-RTCWBase
        if(Get-Process -Name 'WolfSP','RealRTCWXR' -ErrorAction SilentlyContinue){throw 'Close RTCW and RealRTCW XR before installing or updating.'}
        Write-Host "  Game: $game" -ForegroundColor Green
        $bundle=Get-RTCWBundleChoice
        Write-Host "  Selected: $bundle" -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the publisher Setup...')
        $release=Get-RTCWRelease $bundle
        $minimum=if($bundle -eq 'Full'){4500000000L}else{1000000000L}
        $tempChoice=Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes $minimum
        if(-not $tempChoice.BasePath){throw 'Choose a drive with enough free space for the publisher Setup.'}
        $work=New-PCVRInstallerTempSession -BasePath $tempChoice.BasePath
        $setup=Join-Path $work $release.Name
        if($release.Local){$setup=$release.Url}
        elseif($release.Manual){
            $info=@{}
            [void](Invoke-SafeDownload -Urls @() -Destination $setup -Label "RealRTCW XR $bundle Setup" `
                -ManualUrl $script:RTCWPage -AllowSkip $false -DownloadInfo $info)
            $leaf=[IO.Path]::GetFileName([string]$info.SourcePath)
            $pattern='(?i)^RealRTCWXR-(\d+(?:\.\d+){2})-(?:Release-)?'+[regex]::Escape($bundle)+'-Setup\.exe$'
            if($leaf -notmatch $pattern){throw "Choose the official $bundle publisher Setup EXE; the selected file was not installed."}
            $release.Version=$Matches[1];$release.Tag=$Matches[1];$release.Name=$leaf
            Write-Host "  Selected publisher version: $($release.Version) ($bundle)." -ForegroundColor Yellow
            if((Read-Host '  Use this version? Y/N').Trim() -notmatch '^(?i)y(?:es)?$'){throw 'Publisher version was not confirmed; no game files were changed.'}
        } else {
            $r=Invoke-SafeDownload -Urls @($release.Url) -Destination $setup -Label "RealRTCW XR $($release.Version) $bundle Setup" `
                -ExpectedReleaseTag $release.Tag -ManualUrl $script:RTCWPage -AllowSkip $false
            if($r -ne $true -and [string]$r -notin @('manual','retry')){throw 'Publisher Setup download did not complete.'}
        }
        if(-not(Test-DownloadedPayload -Path $setup -IntendedPath $release.Name)){throw 'The publisher Setup EXE is not usable.'}
        $default=Join-Path $env:LOCALAPPDATA 'RealRTCWXR'
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_INSTALL_ROOT){$default=$env:PCVR_RTCW_TEST_INSTALL_ROOT}
        Write-Host '  In publisher Setup, choose where to install the separate VR copy.' -ForegroundColor White
        Write-Host '  Steam: choose Copy game data from my Steam installation.' -ForegroundColor White
        Write-Host '  GOG, Xbox or disc: choose I will provide the game files myself.' -ForegroundColor White
        Write-Host '  Copy the listed files into its Main folder and click Install again.' -ForegroundColor White
        if($bundle -eq 'Minimal'){Write-Host '  RealRTCW must be on its Steam 5.0 beta branch.' -ForegroundColor Yellow}
        Write-Host '  Windows may request administrator approval for a protected location.' -ForegroundColor Yellow
        Write-Host '  Setup and data copying can take several minutes.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
        $before=Find-RTCWInstalled $default
        $beforeVersion='';$beforeFingerprint=''
        if($before){
            $versionPath=Join-Path $before '.pcvrhub_version'
            if(Test-Path -LiteralPath $versionPath -PathType Leaf){$beforeVersion=([IO.File]::ReadAllText($versionPath)).Trim()}
            if($beforeVersion -ne $release.Version){$beforeFingerprint=Get-RTCWPayloadFingerprint $before}
        }
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_PUBLISHER_OUTPUT){
            $source=$env:PCVR_RTCW_TEST_PUBLISHER_OUTPUT
            if(-not(Test-Path -LiteralPath (Join-Path $source 'RealRTCWXR.exe'))){throw 'Publisher fixture is incomplete.'}
            foreach($item in @(Get-ChildItem -LiteralPath $source -Force)){
                Copy-Item -LiteralPath $item.FullName -Destination $default -Recurse -Force
            }
        }else{
            $process=Start-Process -FilePath $setup -ArgumentList ('/D="'+$default+'"') -Wait -PassThru -ErrorAction Stop
            if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher Setup ended with exit code $($process.ExitCode)."}
        }
        $root=Find-RTCWInstalled $default
        if(-not $root){
            $picked=Get-GameFolderInteractive -GameName 'RealRTCW XR installed VR copy' -ProbeFile 'RealRTCWXR.exe' -ManualUrl $script:RTCWPage
            if(Test-RTCWInstalled $picked){$root=[IO.Path]::GetFullPath($picked)}
        }
        if(-not $root){throw 'Publisher Setup has no complete VR copy. Reopen Setup and finish its game-data step.'}
        if($before -and $before -ieq $root -and $beforeVersion -ne $release.Version -and
            $beforeFingerprint -eq (Get-RTCWPayloadFingerprint $root)){
            throw 'Publisher Setup made no VR-file change. The previous version remains recorded; reopen Setup and finish Install.'
        }
        if($before -and $before -ieq $root -and $env:PCVR_HUB_TEST_MODE -ne '1'){
            Write-Host '  [..] Existing VR copy verified after publisher Setup.' -ForegroundColor Gray
        }
        Write-RTCWOwnership $root
        [IO.File]::WriteAllText((Join-Path $root '.pcvrhub_rtcwxr_bundle'),$bundle)
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_RECEIPT){$env:PCVR_RTCW_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Save-HubRememberedGameFolder -GameId $script:RTCWId -Title 'Return to Castle Wolfenstein VR' -GameDir $game -ProbeFiles @('WolfSP.exe'))
        [void](Complete-PCVRInstallTransaction -Contract $script:RTCWContract -GameDir $root -Version $release.Version -Route $bundle -InstalledPathReceiptPaths @($receipt))
        Write-Host "  [OK] RealRTCW XR $($release.Version) ($bundle) installed at $root." -ForegroundColor Green
        Write-Host '  Start in VR opens RealRTCWXR.exe from that VR copy.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Castle Wolfenstein is waiting. Stay sharp.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {if($work){try{Remove-PCVRInstallerTempSession -Path $work}catch{}}}
}
if($env:PCVR_RTCW_LIBRARY_ONLY -ne '1'){
    while($true){try{Invoke-RTCWInstaller;break}catch{$msg="RealRTCW XR setup did not complete: $($_.Exception.Message)";Write-Host $msg -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $msg -InstallerFolder $PSScriptRoot)}}
}
