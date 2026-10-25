$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='BannerlordVR Installer'
$APP_ID='261550'
$GAME_EXE='bin\Win64_Shipping_Client\TaleWorlds.MountAndBlade.Launcher.exe'
$REPO='NotLooky/BannerlordVR'
$FALLBACK_URL='https://github.com/NotLooky/BannerlordVR/releases/download/v0.2.7-alpha/BannerlordVR-0.2.7-alpha.1.zip'
$HARMONY_URL='https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files'
$IDENTITY='bannerlordvr'
$MOD_ROOT='Modules\BannerlordVR'
$REQUIRED=@('Modules\BannerlordVR\SubModule.xml','Modules\BannerlordVR\BannerlordVR.default.cfg','Modules\BannerlordVR\NVIDIA-DLSS-LICENSE.txt','Modules\BannerlordVR\bin\Win64_Shipping_Client\BannerlordVR.dll','Modules\BannerlordVR\bin\Win64_Shipping_Client\BannerlordVR.Native.dll','Modules\BannerlordVR\bin\Win64_Shipping_Client\nvngx_dlss.dll')
$HARMONY_REQUIRED=@('Modules\Bannerlord.Harmony\SubModule.xml','Modules\Bannerlord.Harmony\bin\Win64_Shipping_Client\Bannerlord.Harmony.dll','Modules\Bannerlord.Harmony\bin\Win64_Shipping_Client\0Harmony.dll')
$contract=New-PCVRInstallerContract -Id 'bannerlord-vr' -GameName 'Mount & Blade II: Bannerlord VR' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl 'https://github.com/NotLooky/BannerlordVR/releases' -RequiredInstalledFileGroups @($REQUIRED+$HARMONY_REQUIRED+@('.pcvrhub_bannerlordvr_ownership.csv'))

function global:Test-BannerlordGameRoot([string]$Path){
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue) -and
        (Test-Path -LiteralPath (Join-Path $Path 'Modules\Native\SubModule.xml') -PathType Leaf -ErrorAction SilentlyContinue))
}
function global:Assert-BannerlordCompatibleGameVersion([string]$NativeXmlPath){
    $nativeText=Get-Content -LiteralPath $NativeXmlPath -Raw -ErrorAction Stop
    if($nativeText -match '(?i)<Version\s+value\s*=\s*["'']v?(\d+(?:\.\d+){2,3})["'']'){
        if($Matches[1] -notmatch '^1\.(?:4\.8|5\.5)(?:\.\d+)?$'){
            throw "Bannerlord $($Matches[1]) is installed; the current VR release supports v1.4.8 stable or v1.5.5. No game files were changed."
        }
        if($Matches[1] -match '^1\.5\.5(?:\.\d+)?$'){
            Write-Host '  v1.5.5 is listed by the publisher, but the latest ZIP was built against v1.4.8 stable.' -ForegroundColor Yellow
        }
        return
    }
    Write-Host '  Could not read the game version. Confirm v1.4.8 or v1.5.5 before playing.' -ForegroundColor Yellow
}
function global:Wait-BannerlordCompatibleGameVersion([string]$NativeXmlPath,[scriptblock]$ReadInput=$null,[scriptblock]$OpenUrl=$null){
    while($true){
        try { Assert-BannerlordCompatibleGameVersion -NativeXmlPath $NativeXmlPath; return }
        catch {
            if ($_.Exception.Message -notmatch '^Bannerlord .+ is installed;') { throw }
            Write-Host ('  '+$_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  In Steam Properties > Betas, select None for v1.4.8 stable,' -ForegroundColor White
            Write-Host '  or select the supported v1.5.5 beta.' -ForegroundColor White
            Write-Host '  Wait until Steam finishes the game update before continuing here.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open Bannerlord Steam Properties...' -ReadInput $ReadInput)
            if($OpenUrl){& $OpenUrl "steam://gameproperties/$APP_ID"}
            else {try {Start-Process "steam://gameproperties/$APP_ID"} catch {Write-Host '  Open Bannerlord Properties from your Steam Library.' -ForegroundColor Yellow}}
            [void](Wait-PCVRExplicitEnter -Message 'After Steam finishes updating, press Enter to check again...' -ReadInput $ReadInput)
        }
    }
}
function global:Get-BannerlordGameRoot {
    $found=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Mount & Blade II Bannerlord','Mount and Blade II Bannerlord') -ProbeExe $GAME_EXE -HubGameId 'bannerlord-vr'
    if(Test-BannerlordGameRoot $found){return (Get-Item -LiteralPath $found).FullName}
    foreach($candidate in @('C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord','C:\Program Files\Steam\steamapps\common\Mount & Blade II Bannerlord')){
        if(Test-BannerlordGameRoot $candidate){return (Get-Item -LiteralPath $candidate).FullName}
    }
    while($true){
        $raw=([string](Read-Host 'Drag the Bannerlord game folder here (or type its path)')).Trim().Trim('"').Trim("'")
        if(Test-BannerlordGameRoot $raw){return (Get-Item -LiteralPath $raw).FullName}
        Write-Host "  That folder needs both $GAME_EXE and Modules\Native\SubModule.xml. Try again." -ForegroundColor Yellow
    }
}
function global:Test-BannerlordPayload([string]$Root){
    if(-not $Root){return $false}
    foreach($relative in $REQUIRED){if(-not(Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)){return $false}}
    return $true
}
function global:Find-BannerlordHarmonyDownload([string]$Downloads,[datetime]$Since,[switch]$FreshOnly){
    if(-not(Test-Path -LiteralPath $Downloads -PathType Container)){return $null}
    # A completed Nexus download may predate this installer run. Prefer a new
    # download, then offer the newest existing archive for payload validation.
    $archives=@(Get-ChildItem -LiteralPath $Downloads -File -ErrorAction SilentlyContinue |
        Where-Object {$_.Name -match '(?i)^Harmony.*\.(7z|zip)$' -and $_.Length -gt 0} |
        Sort-Object LastWriteTime -Descending)
    $candidate=@($archives | Where-Object {$_.LastWriteTime -ge $Since.AddSeconds(-5) -or $_.CreationTime -ge $Since.AddSeconds(-5)} | Select-Object -First 1)
    if($candidate.Count -eq 0 -and -not $FreshOnly){$candidate=@($archives|Select-Object -First 1)}
    if($candidate.Count -gt 0){return $candidate[0].FullName}
    return $null
}
function global:Request-BannerlordHarmonyArchive([string]$Downloads,[string]$Url,[scriptblock]$ReadInput=$null,[scriptblock]$OpenUrl=$null,[switch]$Retry){
    $started=Get-Date
    $candidate=$null
    if(-not $Retry){
        $existing=Find-BannerlordHarmonyDownload -Downloads $Downloads -Since $started
        if($existing){
            Write-Host "  Harmony archive already in Downloads: $existing" -ForegroundColor Cyan
            Write-Host '  [Enter] checks this archive; [N] opens Nexus for a new download; [Q] cancels.' -ForegroundColor White
            $answer=if($ReadInput){& $ReadInput 'Enter, N or Q'}else{Read-Host 'Enter, N or Q'}
            $answer=(''+$answer).Trim()
            if($answer -match '^(?i:q|quit|exit)$'){throw 'Harmony setup cancelled.'}
            if(-not $answer){$candidate=$existing}
            elseif($answer -ine 'N'){Write-Host '  Choose [Enter], [N] or [Q].' -ForegroundColor Yellow}
        }
    }
    if(-not $candidate -and -not $Retry){
        Write-Host '  Harmony is missing from this Bannerlord installation.' -ForegroundColor Yellow
        Write-Host '  Nexus login is required. On the Files tab choose the Harmony' -ForegroundColor White
        Write-Host '  main file and click Manual download, then finish the download.' -ForegroundColor White
        Write-Host '  Harmony is a shared dependency; the Hub will not own or remove it.' -ForegroundColor Gray
        Open-PCVRPageAfterEnter -Message 'Press [Enter] to open Harmony files on Nexus...' -Url $Url -ReadInput $ReadInput -OpenUrl $OpenUrl
        [void](Wait-PCVRExplicitEnter -Message 'After the Harmony download finishes, press [Enter] to search Downloads...' -ReadInput $ReadInput)
        $candidate=Find-BannerlordHarmonyDownload -Downloads $Downloads -Since $started -FreshOnly
    }
    while(-not $candidate){
        Write-Host '  No Harmony ZIP or 7z was selected.' -ForegroundColor Yellow
        Write-Host '  Drag the downloaded archive here and press Enter, [R] retry search,' -ForegroundColor White
        Write-Host '  [N] reopen Nexus files, or [Q] cancel.' -ForegroundColor White
        $raw=if($ReadInput){& $ReadInput 'Archive, R, N or Q'}else{Read-Host 'Archive, R, N or Q'}
        $value=(''+$raw).Trim().Trim('"').Trim("'")
        if($value -match '^(?i:q|quit|exit)$'){throw 'Harmony setup cancelled.'}
        if($value -ieq 'R'){$candidate=Find-BannerlordHarmonyDownload -Downloads $Downloads -Since $started -FreshOnly;continue}
        if($value -ieq 'N'){
            Open-PCVRPageAfterEnter -Message 'Press [Enter] to reopen Harmony files on Nexus...' -Url $Url -ReadInput $ReadInput -OpenUrl $OpenUrl
            [void](Wait-PCVRExplicitEnter -Message 'After downloading, press [Enter] to search Downloads again...' -ReadInput $ReadInput)
            $candidate=Find-BannerlordHarmonyDownload -Downloads $Downloads -Since $started -FreshOnly;continue
        }
        if((Test-Path -LiteralPath $value -PathType Leaf) -and $value -match '(?i)\.(7z|zip)$'){$candidate=(Get-Item -LiteralPath $value).FullName;continue}
        Write-Host '  Select a completed Harmony ZIP or 7z archive.' -ForegroundColor Yellow
    }
    Write-Host "  Found Harmony archive: $candidate" -ForegroundColor Green
    return $candidate
}
function global:Get-BannerlordHarmonyFolder([string]$Archive,[string]$Work){
    $extract=Join-Path $Work 'harmony-extract'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $extract -Label 'Harmony archive' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The Harmony archive could not be opened.'}
    $incomplete=@()
    foreach($xml in @(Get-ChildItem -LiteralPath $extract -Filter 'SubModule.xml' -Recurse -File -ErrorAction SilentlyContinue)){
        $folder=Split-Path -Parent $xml.FullName
        if((Split-Path -Leaf $folder) -ine 'Bannerlord.Harmony'){continue}
        $problems=@(Get-BannerlordHarmonyProblems -Folder $folder)
        if($problems.Count -eq 0){return $folder}
        $incomplete+=$problems
    }
    if($incomplete.Count -gt 0){throw ('The Harmony archive is incomplete: '+(@($incomplete|Select-Object -Unique -First 4) -join ', '))}
    throw 'The selected archive does not contain Bannerlord.Harmony\SubModule.xml.'
}
function global:Get-BannerlordHarmonyProblems([string]$Folder){
    $problems=[Collections.Generic.List[string]]::new()
    if(-not $Folder -or (Split-Path -Leaf $Folder) -ine 'Bannerlord.Harmony'){
        $problems.Add('Modules\Bannerlord.Harmony folder');return $problems.ToArray()
    }
    $xmlPath=Join-Path $Folder 'SubModule.xml'
    if(-not(Test-Path -LiteralPath $xmlPath -PathType Leaf)){
        $problems.Add('SubModule.xml');return $problems.ToArray()
    }
    try{
        [xml]$module=Get-Content -LiteralPath $xmlPath -Raw -ErrorAction Stop
        $id=$module.SelectSingleNode('/Module/Id')
        if(-not $id -or $id.GetAttribute('value') -ine 'Bannerlord.Harmony'){
            $problems.Add('Harmony module ID');return $problems.ToArray()
        }
        $names=[Collections.Generic.List[string]]::new()
        foreach($submodule in @($module.SelectNodes('/Module/SubModules/SubModule'))){
            $dll=$submodule.SelectSingleNode('DLLName')
            if($dll){$names.Add([string]$dll.GetAttribute('value'))}
            foreach($assembly in @($submodule.SelectNodes('Assemblies/Assembly'))){$names.Add([string]$assembly.GetAttribute('value'))}
        }
        if($names.Count -eq 0){$problems.Add('Harmony DLL declarations');return $problems.ToArray()}
        foreach($name in @($names|Select-Object -Unique)){
            if(-not $name -or $name -notmatch '^[A-Za-z0-9_.-]+\.dll$' -or $name -in @('.dll','..dll')){
                $problems.Add('Unsafe Harmony DLL declaration');continue
            }
            $relative='bin\Win64_Shipping_Client\'+$name
            $file=Join-Path $Folder $relative
            if(-not(Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -eq 0){$problems.Add($relative)}
        }
    }catch{$problems.Add('Unreadable Harmony SubModule.xml')}
    return $problems.ToArray()
}
function global:Install-BannerlordHarmonyShared([string]$SourceFolder,[string]$GameRoot){
    $sourceProblems=@(Get-BannerlordHarmonyProblems -Folder $SourceFolder)
    if($sourceProblems.Count -gt 0){throw ('Downloaded Harmony is incomplete: '+($sourceProblems -join ', '))}
    $modules=Join-Path $GameRoot 'Modules'
    if(-not(Test-Path -LiteralPath $modules -PathType Container)){throw 'The Bannerlord Modules folder is missing.'}
    $target=Join-Path $modules 'Bannerlord.Harmony'
    if(Test-Path -LiteralPath $target){
        if(@(Get-BannerlordHarmonyProblems -Folder $target).Count -eq 0){return 'existing'}
        throw 'An incomplete shared Harmony folder already exists; review it before replacing shared mod files.'
    }
    $stageRoot=Join-Path $modules ('.pcvrhub_harmony_stage_'+[Guid]::NewGuid().ToString('N'))
    $stage=Join-Path $stageRoot 'Bannerlord.Harmony'
    $moved=$false
    try{
        [void][IO.Directory]::CreateDirectory($stageRoot)
        [void](Copy-DirectoryTreeVerified -Source $SourceFolder -Destination $stage)
        $stageProblems=@(Get-BannerlordHarmonyProblems -Folder $stage)
        if($stageProblems.Count -gt 0){throw ('Copied Harmony is incomplete: '+($stageProblems -join ', '))}
        foreach($file in @(Get-ChildItem -LiteralPath $SourceFolder -Recurse -File -Force -ErrorAction Stop)){
            $relative=$file.FullName.Substring($SourceFolder.Length).TrimStart('\')
            $copied=Join-Path $stage $relative
            if(-not(Test-Path -LiteralPath $copied -PathType Leaf) -or
                (Get-FileHash -LiteralPath $copied -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash){
                throw "Harmony copy did not match the extracted archive: $relative"
            }
        }
        if(Test-Path -LiteralPath $target){throw 'Harmony appeared while setup was running; the existing shared module was left untouched.'}
        Move-Item -LiteralPath $stage -Destination $target -ErrorAction Stop
        $moved=$true
        if(@(Get-BannerlordHarmonyProblems -Folder $target).Count -gt 0){throw 'Harmony became incomplete after installation.'}
        return 'installed'
    }catch{
        if($moved -and (Test-Path -LiteralPath $target)){Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue}
        throw
    }finally{
        if(Test-Path -LiteralPath $stageRoot){Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
function global:Get-BannerlordRelease {
    $release=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -AssetPatterns @('(?i)^BannerlordVR-?v?\d[^/]*\.zip$') `
        -FallbackUrl $FALLBACK_URL -FallbackTag 'v0.2.7-alpha' -FallbackAssetName 'BannerlordVR-0.2.7-alpha.1.zip' -SkipReleasesWithoutMatchingAsset
    if(-not $release.Url){throw 'No official BannerlordVR release ZIP is available.'}
    $version=if([string]$release.AssetName -match '(?i)^BannerlordVR-?v?(\d+(?:\.\d+){1,3}(?:[-+][A-Za-z0-9.]+)?)\.zip$'){'v'+$Matches[1]}else{[string]$release.Tag}
    if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The official release has no trackable build version.'}
    return [pscustomobject]@{Url=[string]$release.Url;Version=$version;PageUrl=[string]$release.PageUrl}
}
function global:Save-BannerlordSnapshot([string]$GameRoot,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths=@($REQUIRED+@('.pcvrhub_bannerlordvr_ownership.csv','.pcvrhub_version'))
    $manifest=Join-Path $GameRoot '.pcvrhub_bannerlordvr_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$paths+=Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)}}}
    $records=@();foreach($relative in @($paths|Where-Object{$_}|Select-Object -Unique)){
        $source=Join-Path $GameRoot $relative;$exists=Test-Path -LiteralPath $source -PathType Leaf
        $records+=[pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$dest=Join-Path (Join-Path $SnapshotRoot 'files') $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest));Copy-Item -LiteralPath $source -Destination $dest -Force}
    }
    $backup=Join-Path $GameRoot '.pcvrhub_bannerlordvr_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force}
    return [pscustomobject]@{Root=$SnapshotRoot;Records=$records;HadBackup=$hadBackup}
}
function global:Restore-BannerlordSnapshot([string]$GameRoot,$Snapshot){
    foreach($entry in $Snapshot.Records){
        $target=Join-Path $GameRoot $entry.Relative
        if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force}
        if($entry.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.Root 'files') $entry.Relative) -Destination $target -Force}
    }
    $backup=Join-Path $GameRoot '.pcvrhub_bannerlordvr_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force}
}
function global:Invoke-BannerlordVRInstaller {
    $work=$null;$harmonyWork=$null;$game=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host;Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Mount & Blade II: Bannerlord VR - Installer' -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Alpha; current package built for Bannerlord v1.4.8 stable.' -ForegroundColor Yellow
        Write-Host '  The publisher also lists v1.5.5; exact-package testing is pending.' -ForegroundColor Yellow
        Write-Host '  Enabled Bannerlord.Harmony and tracked controllers are required.' -ForegroundColor Yellow
        Write-Host '  Steam: BLSE is optional; download Harmony only from its Nexus Files tab.' -ForegroundColor White
        Write-Host '  VDXR, SteamVR and Meta/Oculus OpenXR are listed by the publisher.' -ForegroundColor Yellow
        Write-Host '  Physical hands and weapons are new in v0.2.0; alpha crashes remain possible.' -ForegroundColor Yellow
        Write-Host '  Disable Bannerlord VR in launcher > Mods for flat play.' -ForegroundColor White
        Write-Host '  Windows Security may remove a mod DLL; setup checks without assuming why.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading the requirements, press Enter to continue...')

        Write-Host '';Write-Host '--- [1/4] Finding Bannerlord ---' -ForegroundColor Cyan
        $game=Get-BannerlordGameRoot
        if(Get-Process -Name 'Bannerlord','Bannerlord.Native','TaleWorlds.MountAndBlade.Launcher' -ErrorAction SilentlyContinue){throw 'Close Bannerlord and its launcher before installation.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Retry as administrator.'}
        Wait-BannerlordCompatibleGameVersion -NativeXmlPath (Join-Path $game 'Modules\Native\SubModule.xml')
        $harmony=Join-Path $game 'Modules\Bannerlord.Harmony'
        if(@(Get-BannerlordHarmonyProblems -Folder $harmony).Count -gt 0){
            $harmonyWork=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_harmony_'+[Guid]::NewGuid().ToString('N'))
            [void][IO.Directory]::CreateDirectory($harmonyWork)
            $harmonyFolder=$null;$retryHarmony=$false
            while(-not $harmonyFolder){
                $archive=Request-BannerlordHarmonyArchive -Downloads (Get-PCVRDownloadsFolder) -Url $HARMONY_URL -Retry:$retryHarmony
                try{$harmonyFolder=Get-BannerlordHarmonyFolder -Archive $archive -Work (Join-Path $harmonyWork ([Guid]::NewGuid().ToString('N')))}
                catch{Write-Host ('  That archive is not usable: '+$_.Exception.Message) -ForegroundColor Yellow;$retryHarmony=$true}
            }
            try{
                $harmonyResult=Install-BannerlordHarmonyShared -SourceFolder $harmonyFolder -GameRoot $game
                Write-Host "  [OK] Complete shared Harmony module: $harmonyResult" -ForegroundColor Green
            }catch{
                if(-not(Test-Path -LiteralPath $harmony)) { throw }
                Write-Host ('  Automatic Harmony copy stopped: '+$_.Exception.Message) -ForegroundColor Yellow
                Write-Host '  The existing shared module was not overwritten.' -ForegroundColor Yellow
                Write-Host "  Reviewed archive folder: $harmonyFolder" -ForegroundColor Cyan
                Write-Host "  Existing game folder: $harmony" -ForegroundColor Cyan
                [void](Wait-PCVRExplicitEnter -Message 'Press [Enter] to open the extracted Harmony folder for manual review...')
                Start-Process explorer.exe -ArgumentList ('"'+(Split-Path -Parent $harmonyFolder)+'"') -ErrorAction Stop
                while(@(Get-BannerlordHarmonyProblems -Folder $harmony).Count -gt 0){
                    $answer=(''+(Read-Host 'After repairing Harmony, press Enter to check or Q to cancel')).Trim()
                    if($answer -match '^(?i:q|quit|exit)$'){throw 'Harmony setup cancelled.'}
                    $problems=@(Get-BannerlordHarmonyProblems -Folder $harmony)
                    if($problems.Count -gt 0){Write-Host ('  Harmony is incomplete: '+(@($problems|Select-Object -First 4) -join ', ')) -ForegroundColor Yellow}
                }
            }
        }
        Write-Host "  [OK] Game and Harmony: $game" -ForegroundColor Green

        Write-Host '';Write-Host '--- [2/4] Downloading the newest BannerlordVR release ---' -ForegroundColor Cyan
        Write-Host '  The next step checks the official GitHub release and downloads its ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download BannerlordVR...')
        $release=Get-BannerlordRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_bannerlord_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $zip=Join-Path $work 'BannerlordVR.zip'
        $result=Invoke-SafeDownload -Urls @($release.Url) -Destination $zip -Label "BannerlordVR $($release.Version)" -ManualUrl $release.PageUrl -AllowSkip $false
        if($result -notin @($true,'retry','manual')){throw 'The BannerlordVR release was not downloaded.'}
        $extract=Join-Path $work 'extract'
        $expanded=Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $extract -Label 'BannerlordVR release' -AllowSkip $false -QuietProgress
        if($expanded -notin @('ok','manual','retry')){throw 'The BannerlordVR release could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'Modules\BannerlordVR\SubModule.xml'
        if(-not(Test-BannerlordPayload $payload)){throw 'The downloaded release lacks its SubModule.xml or one of its two required DLLs.'}
        $moduleXml=Get-Content -LiteralPath (Join-Path $payload 'Modules\BannerlordVR\SubModule.xml') -Raw -ErrorAction Stop
        $moduleVersionMatch=[regex]::Match($moduleXml,'(?i)<Version\s+value\s*=\s*["''](v\d+(?:\.\d+){1,3})["'']')
        $releaseBase=([string]$release.Version -replace '[-+].*$','')
        if(-not $moduleVersionMatch.Success -or $moduleVersionMatch.Groups[1].Value -ne $releaseBase){
            throw "BannerlordVR archive version does not match the selected release $($release.Version). No game files were changed."
        }
        $stage=Join-Path $work 'stage'
        foreach($relative in $REQUIRED){$target=Join-Path $stage $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path $payload $relative) -Destination $target -Force}
        Write-Host "  [OK] Publisher package $($release.Version) verified." -ForegroundColor Green

        Write-Host '';Write-Host '--- [3/4] Installing and checking the VR module ---' -ForegroundColor Cyan
        $snapshot=Save-BannerlordSnapshot -GameRoot $game -SnapshotRoot (Join-Path $work 'rollback');$changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting)
        $watch=@($REQUIRED|ForEach-Object{Join-Path $game $_})+@(Join-Path $game '.pcvrhub_bannerlordvr_ownership.csv')
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required BannerlordVR files are missing after installation.'}
        $harmonyProblems=@(Get-BannerlordHarmonyProblems -Folder $harmony)
        if($harmonyProblems.Count -gt 0){throw ('Harmony became incomplete before the success receipt: '+($harmonyProblems -join ', '))}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $release.Version -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route 'Current')
        $changed=$false

        Write-Host '';Write-Host '--- [4/4] Ready to launch ---' -ForegroundColor Cyan
        Write-Host '  Start VDXR or SteamVR OpenXR, then select Start in VR in the Hub.' -ForegroundColor White
        Write-Host '  In the game launcher, enable Harmony above Bannerlord VR.' -ForegroundColor Yellow
        Write-Host '  If Bannerlord VR is greyed out, check Harmony installation/enabling.' -ForegroundColor Yellow
        Write-Host '  Swing, block, grip weapons and draw bows with tracked hands.' -ForegroundColor White
        Write-Host '  [End] opens VR settings; [F10] recenters the headset view.' -ForegroundColor Cyan
        Write-Host '  Native stereo is the default; AFR is optional in VR settings.' -ForegroundColor White
        Write-Host '  Single-player only; menus, interactions and performance are still alpha.' -ForegroundColor Yellow
        Write-Host '  In launcher > Mods, tick Harmony and Bannerlord VR, with Harmony first.' -ForegroundColor Yellow
        Write-Host '  If scenes hang, untick Bannerlord VR there for flat play.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Raise your banner, then hold the line in VR.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $game -and $snapshot){try{Restore-BannerlordSnapshot -GameRoot $game -Snapshot $snapshot;Write-Host '  [!!] Previous Bannerlord files restored.' -ForegroundColor Yellow}catch{Write-Host ('  [!!] Rollback needs attention: '+$_.Exception.Message) -ForegroundColor Yellow}}
        throw
    }finally{
        if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
        if($harmonyWork -and (Test-Path -LiteralPath $harmonyWork)){Remove-Item -LiteralPath $harmonyWork -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
if(((''+$env:PCVR_BANNERLORD_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-BannerlordVRInstaller}
