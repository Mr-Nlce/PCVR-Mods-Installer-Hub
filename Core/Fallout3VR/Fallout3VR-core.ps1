$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$script:Id='fallout-3-vr';$script:Repo='THEwill2002/Fallout3VR';$script:Page='https://github.com/THEwill2002/Fallout3VR/releases'
$script:FO3DeclinedPath=''
$script:Proof=@('THEwill_Fallout3_VR.exe','Launch-HD.cmd','Launch.ps1','Launcher.Core.ps1','settings.json','payload-manifest.json','payload\HD\loader\dinput8.dll','payload\HD\loader\Fallout3VR-Bootstrap.dll','payload\HD\scene\Fallout3VR-Scene-Menu.exe','payload\HD\scene\openxr_loader.dll','.pcvrhub_fo3vr_ownership.csv')
$script:Contract=New-PCVRInstallerContract -Id $script:Id -GameName 'Fallout 3 VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:Page -RequiredInstalledFileGroups $script:Proof
function Test-FO3Game([string]$Root){return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Fallout3.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Root 'Data\Fallout3.esm') -PathType Leaf))}
function Assert-FO3Fixture([string]$Path,[string]$Marker){$full=[IO.Path]::GetFullPath($Path);$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\';if(-not $full.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full $Marker) -PathType Leaf)){throw 'Fallout 3 test path must stay in an isolated temporary fixture.'};return $full}
function Get-FO3Game {
    if($env:PCVR_FO3_TEST_GAME){$test=Assert-FO3Fixture $env:PCVR_FO3_TEST_GAME 'fo3vr-test-fixture.txt';if(Test-FO3Game $test){return $test};throw 'The Fallout 3 test game is incomplete.'}
    $c=@();$saved=Get-PCVRRememberedGameFolder -GameId $script:Id -StateNames @('base_game_path','user_located') -ProbeFiles @('Fallout3.exe','Data\Fallout3.esm');if($saved){$c+=$saved}
    foreach($app in @('22370','22300')){try{$found=Find-SteamGameFolder -AppId $app -SteamFolderNames @('Fallout 3 goty','Fallout 3') -ProbeExe 'Fallout3.exe' -HubGameId $script:Id;if($found){$c+=$found}}catch{}}
    $c+=@('C:\Program Files (x86)\Steam\steamapps\common\Fallout 3 goty','C:\Program Files (x86)\Steam\steamapps\common\Fallout 3')
    foreach($p in @($c|Select-Object -Unique)){if(Test-FO3Game $p){return [IO.Path]::GetFullPath($p)}}
    $p=Get-GameFolderInteractive -GameName 'Fallout 3 (Steam, version 1.7.0.4)' -ProbeFile 'Fallout3.exe' -ManualUrl 'https://store.steampowered.com/app/22370/'
    if(Test-FO3Game $p){return [IO.Path]::GetFullPath($p)}
    throw 'Choose the Steam game folder containing Fallout3.exe and Data\Fallout3.esm.'
}
function Get-FO3Release {
    if($env:PCVR_FO3_TEST_ARCHIVE){return [pscustomobject]@{Tag='v0.1.0-alpha.6';Url=$env:PCVR_FO3_TEST_ARCHIVE;Local=$true}}
    try{$r=Resolve-GitHubReleaseAsset -Repo $script:Repo -IncludePrerelease $true -AssetPatterns @('(?i)^Fallout3VR-v[0-9].*-win64\.zip$') -SkipReleasesWithoutMatchingAsset}catch{$r=[pscustomobject]@{Resolved=$false}}
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    if(-not $handover -and -not $r.Resolved){
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('Fallout3VR-v*-win64.zip')
        if($candidate -and (Test-DownloadedPayload -Path $candidate -IntendedPath $candidate)){
            Write-Host " Found in Downloads: $candidate" -ForegroundColor Cyan
            if((Read-Host ' Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){$handover=$candidate}
            else{$script:FO3DeclinedPath=$candidate}
        }
    }
    if($handover){
        $leaf=[IO.Path]::GetFileName($handover)
        if($leaf -notmatch '(?i)^Fallout3VR-(v[0-9]+(?:\.[0-9]+)+(?:-(?:alpha|beta|rc)\.[0-9]+)?)(?:-rc\.[0-9]+)?-win64\.zip$'){throw 'Choose an official versioned Fallout3VR Windows ZIP.'}
        $version=$Matches[1]
        if($r.Resolved -and $version -ine [string]$r.Tag){throw "That ZIP is $version; the current GitHub release is $($r.Tag). Download the current ZIP instead."}
        if(-not $r.Resolved){Write-Host " Publisher version could not be checked online. Selected: $leaf ($version)." -ForegroundColor Yellow;if((Read-Host ' Use this version? Y/N') -notmatch '^(?i:y|yes)$'){throw 'Publisher version was not confirmed.'}}
        return [pscustomobject]@{Tag=$version;Url=$handover;Local=$true}
    }
    if(-not $r.Resolved -or -not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){
        Write-Host ' [!!] The current Fallout 3 VR prerelease could not be checked on GitHub.' -ForegroundColor Yellow
        if(-not $r.ReleaseFound){
            Write-Host ' The last reviewed publisher prerelease is v0.1.0-alpha.6. A newer release may exist.' -ForegroundColor Yellow
            if((Read-Host ' Download the reviewed v0.1.0-alpha.6 ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){
                return [pscustomobject]@{Tag='v0.1.0-alpha.6';Url='https://github.com/THEwill2002/Fallout3VR/releases/download/v0.1.0-alpha.6/Fallout3VR-v0.1.0-alpha.6-rc.10-win64.zip';Local=$false;Manual=$false}
            }
        }
        Write-Host ' Select the current official Windows ZIP on the release page.' -ForegroundColor White
        return [pscustomobject]@{Tag='';Url='';Local=$false;Manual=$true}
    }
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false;Manual=$false}
}
function Get-FO3ManualArchive([string]$Destination){
    $declined=$script:FO3DeclinedPath
    $opened=$false
    while($true){
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('Fallout3VR-v*-win64.zip')
        if($candidate -and $candidate -eq $declined){$candidate=$null}
        if($candidate -and -not(Test-DownloadedPayload -Path $candidate -IntendedPath $Destination)){$candidate=$null}
        if($candidate){
            Write-Host " Found in Downloads: $candidate" -ForegroundColor Cyan
            if((Read-Host ' Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){
                Copy-Item -LiteralPath $candidate -Destination $Destination -Force -ErrorAction Stop
                return $candidate
            }
            $declined=$candidate
        }
        if(-not $opened){
            Write-Host ' Download the current Fallout 3 VR Windows ZIP from the official release page.' -ForegroundColor White
            [void](Open-PCVRPageAfterEnter -Url $script:Page -Message 'Press Enter to open the Fallout 3 VR releases page...')
            $opened=$true
        }
        [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
        $candidate=Find-PCVRDownloadedCandidate -Patterns @('Fallout3VR-v*-win64.zip')
        if($candidate -and $candidate -ne $declined){continue}
        $raw=(Read-Host ' Drag the downloaded ZIP here, or press Enter to open the page again').Trim().Trim('"').Trim("'")
        if($raw -and (Test-Path -LiteralPath $raw -PathType Leaf)){
            if(Test-DownloadedPayload -Path $raw -IntendedPath $Destination){
                Write-Host " Selected ZIP: $raw" -ForegroundColor Cyan
                if((Read-Host ' Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){
                    Copy-Item -LiteralPath $raw -Destination $Destination -Force -ErrorAction Stop
                    return $raw
                }
            }else{Write-Host ' This is not a usable ZIP.' -ForegroundColor Yellow}
        }else{Start-Process $script:Page -ErrorAction Stop|Out-Null}
    }
}
function Get-FO3Target {
    if($env:PCVR_FO3_TEST_ROOT){return (Assert-FO3Fixture $env:PCVR_FO3_TEST_ROOT 'fo3vr-test-fixture.txt')}
    return (Join-Path $env:LOCALAPPDATA 'Programs\Fallout3VR')
}
function Test-FO3DeferredRequirement([string]$Message){
    return [bool]($Message -match '^Run Fallout 3 normally once to create FalloutPrefs\.ini' -or $Message -match '^No supported OpenXR runtime found\.')
}
function Invoke-FO3PublisherCheck([string]$Root){
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        [void](Assert-FO3Fixture $Root 'fo3vr-test-fixture.txt')
        $fixtureError=[string]$env:PCVR_FO3_TEST_CHECK_MESSAGE
        if(-not $fixtureError){return ''}
        if(Test-FO3DeferredRequirement $fixtureError){return $fixtureError}
        throw "Publisher check: $fixtureError"
    }
    $errorFile=Join-Path $env:LOCALAPPDATA 'Fallout3VR\last-error.txt'
    $before=if(Test-Path -LiteralPath $errorFile -PathType Leaf){(Get-Item -LiteralPath $errorFile).LastWriteTimeUtc}else{[datetime]::MinValue}
    $p=Start-Process -FilePath (Join-Path $Root 'THEwill_Fallout3_VR.exe') -ArgumentList '--check' -WorkingDirectory $Root -NoNewWindow -Wait -PassThru -ErrorAction Stop
    if($null -ne $p.ExitCode -and $p.ExitCode -eq 0){return ''}
    $detail=''
    if(Test-Path -LiteralPath $errorFile -PathType Leaf){
        $file=Get-Item -LiteralPath $errorFile
        if($file.LastWriteTimeUtc -gt $before){$detail=(Get-Content -LiteralPath $errorFile -Raw -ErrorAction Stop).Trim()}
    }
    if(-not $detail){$detail="Publisher check exited with code $($p.ExitCode); see $errorFile."}
    if(Test-FO3DeferredRequirement $detail){return $detail}
    throw "Publisher check: $detail"
}
function New-FO3Stage([string]$Archive,[string]$Work,[string]$Game){
    $expanded=Join-Path $Work 'publisher';$status=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'Fallout 3 VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$status -notin @('ok','manual','retry')){throw 'The Fallout 3 VR ZIP could not be opened.'}
    $source=Join-Path $expanded 'Fallout3VR-Alpha'
    foreach($name in @('THEwill_Fallout3_VR.exe','Launch-HD.cmd','Launch.ps1','Launcher.Core.ps1','Profile.Ini.ps1','payload-manifest.json','settings.json','payload\HD\loader\dinput8.dll','payload\HD\loader\Fallout3VR-Bootstrap.dll','payload\HD\scene\Fallout3VR-Scene-Menu.exe','payload\HD\scene\openxr_loader.dll')){if(-not(Test-Path -LiteralPath (Join-Path $source $name) -PathType Leaf)){throw "The publisher ZIP lacks $name."}}
    $stage=Join-Path $Work 'stage';Copy-Item -LiteralPath $source -Destination $stage -Recurse -Force -ErrorAction Stop
    $settings=Join-Path $stage 'settings.json';$target=Get-FO3Target;$existing=Join-Path $target 'settings.json'
    $cfg=if(Test-Path -LiteralPath $existing -PathType Leaf){Get-Content -LiteralPath $existing -Raw | ConvertFrom-Json -ErrorAction Stop}else{Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json -ErrorAction Stop}
    $cfg.GamePath=$Game
    if($cfg.Profile -eq 'UHD'){Write-Host ' Existing UHD profile is currently broken; Start in VR forces HD.' -ForegroundColor Yellow}
    $cfg|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $settings -Encoding UTF8
    return $stage
}
function Save-FO3Snapshot([string]$Root,[string]$Stage,[string]$Backup){
    [void][IO.Directory]::CreateDirectory($Backup);$paths=[Collections.Generic.List[string]]::new()
    foreach($f in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$paths.Add($f.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Root '.pcvrhub_fo3vr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($r in @(Import-Csv -LiteralPath $manifest)){if($r.RelativePath){$paths.Add((Assert-PCVROwnedRelativePath $r.RelativePath))}}}
    foreach($n in @('.pcvrhub_fo3vr_ownership.csv','.pcvrhub_fo3vr_ownership.csv.new','.pcvrhub_version')){$paths.Add($n)}
    $rows=@();foreach($rel in @($paths|Select-Object -Unique)){$src=Join-OwnedRelativePath $Root $rel;$had=Test-Path -LiteralPath $src -PathType Leaf;$rows+=[pscustomobject]@{Relative=$rel;Had=$had};if($had){$dst=Join-OwnedRelativePath (Join-Path $Backup 'files') $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dst));Copy-Item -LiteralPath $src -Destination $dst -Force}}
    $old=Join-Path $Root '.pcvrhub_fo3vr_backup';$hadBackup=Test-Path -LiteralPath $old -PathType Container;if($hadBackup){Copy-Item -LiteralPath $old -Destination (Join-Path $Backup 'ownership') -Recurse -Force}
    return [pscustomobject]@{Root=$Backup;Rows=$rows;HadBackup=$hadBackup}
}
function Restore-FO3Snapshot([string]$Root,$S){
    foreach($r in @($S.Rows)){$p=Join-OwnedRelativePath $Root $r.Relative;if($r.Had){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $p));Copy-Item -LiteralPath (Join-OwnedRelativePath (Join-Path $S.Root 'files') $r.Relative) -Destination $p -Force}else{if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}}}
    $b=Join-Path $Root '.pcvrhub_fo3vr_backup';if(Test-Path -LiteralPath $b){Remove-Item -LiteralPath $b -Recurse -Force};if($S.HadBackup){Copy-Item -LiteralPath (Join-Path $S.Root 'ownership') -Destination $b -Recurse -Force}
}
function Invoke-FO3Installer {
    $work=$null;$game=$null;$root=$null;$snapshot=$null;$changed=$false;$keep=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ' Fallout 3 VR - Installer' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Publisher-confirmed route: Steam Fallout 3 1.7.0.4 on Windows x64.' -ForegroundColor White
        Write-Host ' This alpha is a test candidate. UHD is currently broken; Hub Play uses HD.' -ForegroundColor Yellow
        Write-Host ' The complete VR launcher stays outside your game folder.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Fallout 3...')
        Write-Host ' [..] Checking Steam game locations; this may take a few seconds.' -ForegroundColor Cyan
        $game=Get-FO3Game;if(Get-Process -Name 'Fallout3','THEwill_Fallout3_VR' -ErrorAction SilentlyContinue){throw 'Close Fallout 3 and its VR launcher before setup.'}
        Write-Host " [OK] Game: $game" -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest Fallout 3 VR prerelease...')
        Write-Host ' [..] Checking GitHub prereleases; this may take a few seconds.' -ForegroundColor Cyan
        $release=Get-FO3Release;$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_fo3_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'Fallout3VR.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force}
        elseif($release.Manual){
            $selected=Get-FO3ManualArchive -Destination $archive
            $leaf=[IO.Path]::GetFileName([string]$selected)
            if($leaf -notmatch '(?i)^Fallout3VR-(v[0-9]+(?:\.[0-9]+)+(?:-(?:alpha|beta|rc)\.[0-9]+)?)(?:-rc\.[0-9]+)?-win64\.zip$'){
                throw 'Choose an official versioned Fallout3VR Windows ZIP. No game files were changed.'
            }
            $release.Tag=$Matches[1]
            Write-Host " Selected publisher file: $leaf ($($release.Tag))." -ForegroundColor Yellow
            if((Read-Host ' Use this ZIP and version? Y/N').Trim() -notmatch '^(?i:y|yes)$'){
                throw 'Publisher version was not confirmed. No game files were changed.'
            }
        }else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Fallout 3 VR $($release.Tag)" -ManualUrl $script:Page -ExpectedReleaseTag $release.Tag -AllowSkip $false)}
        Write-Host ' [..] Inspecting and staging the complete publisher package; this may take a few seconds.' -ForegroundColor Cyan
        $stage=New-FO3Stage -Archive $archive -Work $work -Game $game
        $root=Get-FO3Target;if(-not(Test-Path -LiteralPath $root -PathType Container)){[void][IO.Directory]::CreateDirectory($root)}
        if(-not(Test-InstallerTargetWritable -TargetPath $root)){throw 'The VR launcher folder is not writable.'}
        $snapshot=Save-FO3Snapshot -Root $root -Stage $stage -Backup (Join-Path $work 'rollback')
        $changed=$true;Write-Host ' [..] Installing Fallout 3 VR and checking copied files; this may take a few seconds.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $root -Identity 'fo3vr' -AdoptIdenticalExisting -ReplaceChangedOwnedRelativePaths @('settings.json'))
        $watch=@($script:Proof|ForEach-Object{Join-Path $root $_});if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $root -NoClear)){throw 'Required Fallout 3 VR files did not survive the copy check.'}
        $cfg=Get-Content -LiteralPath (Join-Path $root 'settings.json') -Raw|ConvertFrom-Json
        if([string]$cfg.GamePath -ine $game){throw 'The publisher launcher did not retain the verified game path.'}
        if($env:PCVR_HUB_TEST_MODE -ne '1'){
            if(-not(Save-HubRememberedGameFolder -GameId $script:Id -Title 'Fallout 3 VR' -GameDir $game -ProbeFiles @('Fallout3.exe','Data\Fallout3.esm') -StateName 'base_game_path')){throw 'The Steam game location could not be saved.'}
        }
        Write-Host ' [..] Running the publisher package check; this may take a few seconds.' -ForegroundColor Cyan
        $deferred=Invoke-FO3PublisherCheck -Root $root
        if($deferred){Write-Host " [!!] Installation files are complete. Before Start in VR: $deferred" -ForegroundColor Yellow}
        $receipt=if($env:PCVR_FO3_TEST_RECEIPT){$env:PCVR_FO3_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:Contract -GameDir $root -Version $release.Tag -InstalledPathReceiptPaths @($receipt) -Route HD)
        $changed=$false;Write-Host " [OK] Fallout 3 VR $($release.Tag) installed." -ForegroundColor Green
        Write-Host ' Connect the headset, then choose Start in VR in the Hub.' -ForegroundColor White
        Write-Host ' VR settings: keep Virtual Desktop / SteamVR OpenXR active and both controllers awake.' -ForegroundColor Yellow
        Write-Host ' Start in VR uses HD. UHD is broken in this alpha; do not select it.' -ForegroundColor Yellow
        Write-Host ' A wavering image can remain: the publisher renders alternating eyes and reports limited reprojection.' -ForegroundColor Yellow
        Write-Host ' No verified graphics switch fixes this yet. For a visible defect, press F8 once;' -ForegroundColor Yellow
        Write-Host ' after closing the game, run Collect-Diagnostics.cmd and send the report privately.' -ForegroundColor Yellow
        Write-Host '';Write-Host ' Step out of the Vault and look around.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $root){try{Restore-FO3Snapshot -Root $root -S $snapshot}catch{$keep=$true;Write-Host " Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red}}
        $message="Fallout 3 VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{if($work -and -not $keep -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_FO3_LIBRARY_ONLY -ne '1'){Invoke-FO3Installer}
