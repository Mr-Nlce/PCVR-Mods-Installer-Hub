$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Modern Warfare 2 Campaign Remastered VR Installer'
$script:MW2Id='modern-warfare-2-campaign-remastered-vr'
$script:MW2Page='https://github.com/Aeka0/Overlord/releases'
$script:MW2Required=@('MW2CR.exe','oo2core_5_win64.dll|oo2core_8_win64.dll','overlord.exe','openxr_loader.dll','overlord.vrmanifest',
    'vr_input\actions.json','h2-mod\ui_scripts\branding\__init__.lua','.pcvrhub_mw2overlord_ownership.csv')
$script:MW2Contract=New-PCVRInstallerContract -Id $script:MW2Id -GameName 'Modern Warfare 2 Campaign Remastered VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:MW2Page -Routes @('BattleNet') -RequiredInstalledFileGroups $script:MW2Required

function Test-MW2Game([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root 'MW2CR.exe') -PathType Leaf)){return $false}
    if(-not((Test-Path -LiteralPath (Join-Path $Root 'oo2core_5_win64.dll') -PathType Leaf) -or
             (Test-Path -LiteralPath (Join-Path $Root 'oo2core_8_win64.dll') -PathType Leaf))){return $false}
    $data=Join-Path $Root 'Data\data'
    if(-not(Test-Path -LiteralPath $data -PathType Container)){return $false}
    try{foreach($file in [IO.Directory]::EnumerateFiles($data)){if((Get-Item -LiteralPath $file).Length -gt 0){return $true}}}catch{return $false}
    return $false
}
function Get-MW2Game{
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MW2_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_MW2_TEST_GAME)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'mw2-fixture.txt') -PathType Leaf) -or -not(Test-MW2Game $root)){throw 'MW2 test game must be an isolated fixture.'}
        return $root
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:MW2Id -StateNames @('installed_path','user_located','base_game_path') -ProbeFiles @('MW2CR.exe')
    if(Test-MW2Game $saved){return [IO.Path]::GetFullPath($saved)}
    $default='C:\Program Files (x86)\Call of Duty Modern Warfare 2 Campaign Remastered'
    if(Test-MW2Game $default){return [IO.Path]::GetFullPath($default)}
    $picked=Get-GameFolderInteractive -GameName 'Call of Duty: Modern Warfare 2 Campaign Remastered (Battle.net)' -ProbeFile 'MW2CR.exe'
    if(Test-MW2Game $picked){
        [void](Save-HubRememberedGameFolder -GameId $script:MW2Id -Title 'Modern Warfare 2 Campaign Remastered VR' -GameDir $picked -ProbeFiles @('MW2CR.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'A complete Battle.net game folder needs MW2CR.exe, the game codec and nonempty Data\\data storage.'
}
function Get-MW2Release{
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MW2_TEST_ARCHIVE){
        return [pscustomobject]@{Tag='v0.6.0-beta';Url=$env:PCVR_MW2_TEST_ARCHIVE;Local=$true;Name='Overlord.Beta.6.7z'}
    }
    $r=Resolve-GitHubReleaseAsset -Repo 'Aeka0/Overlord' -IncludePrerelease $true `
        -AssetPatterns @('(?i)^Overlord(?:[._ -]Beta[._ -]?\d+)?\.7z$') -SkipReleasesWithoutMatchingAsset $true
    if(-not $r.Resolved -or -not $r.Url -or -not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){
        throw 'The current Overlord beta could not be confirmed. Use recovery to open the official release page and hand over its current archive.'
    }
    return [pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Local=$false;Name=[IO.Path]::GetFileName(([uri]$r.Url).AbsolutePath)}
}
function Assert-MW2Archive([string]$SevenZip,[string]$Archive){
    if(-not(Test-DownloadedPayload -Path $Archive -IntendedPath 'Overlord.7z')){throw 'The download is not a readable 7z file.'}
    $lines=@(& $SevenZip l -slt $Archive 2>&1)
    if($LASTEXITCODE -ne 0){throw '7-Zip could not list the publisher archive.'}
    $started=$false;$paths=0
    foreach($line in $lines){
        $value=[string]$line
        if($value -match '^[-]{8,}\s*$'){$started=$true;continue}
        if(-not $started){continue}
        if($value -match '^Path = (.*)$'){
            $relative=$Matches[1].Replace('/','\');$paths++
            if([IO.Path]::IsPathRooted($relative) -or $relative -match '[:\x00-\x1F]' -or $relative -match '(^|\\)\.\.?(\\|$)' -or $relative.StartsWith('\')){
                throw "Unsafe archive path: $relative"
            }
        }
        if($value -match '^(Symbolic Link|Hard Link) = ' -or $value -match '^Attributes = .*\bL\b'){
            throw 'Archive links are not accepted in a game folder.'
        }
    }
    if($paths -lt 10){throw 'The publisher archive has no usable file inventory.'}
    $null=& $SevenZip t $Archive 2>&1
    if($LASTEXITCODE -ne 0){throw 'The publisher archive failed its integrity check.'}
}
function Get-MW2Payload([string]$Stage){
    $launchers=@(Get-ChildItem -LiteralPath $Stage -Filter 'overlord.exe' -File -Recurse -ErrorAction Stop)
    foreach($launcher in $launchers){
        $root=$launcher.Directory.FullName
        if((Test-Path -LiteralPath (Join-Path $root 'openxr_loader.dll') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $root 'overlord.vrmanifest') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $root 'vr_input\actions.json') -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $root 'h2-mod\ui_scripts\branding\__init__.lua') -PathType Leaf)){
            return $root
        }
    }
    throw 'Overlord package lacks the launcher, VR bindings or base H2-Mod data.'
}
function Save-MW2Rollback([string]$Game,[string]$Payload,[string]$Work){
    $folder=Join-Path $Work 'rollback';[void][IO.Directory]::CreateDirectory($folder)
    $names=@(Get-ChildItem -LiteralPath $Payload -File -Recurse|Where-Object{$_.Name -ne 'overlord.pdb'}|ForEach-Object{$_.FullName.Substring($Payload.Length+1).Replace('/','\')})
    $manifest=Join-Path $Game '.pcvrhub_mw2overlord_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf){$names+=@(Import-Csv -LiteralPath $manifest|ForEach-Object RelativePath)}
    $names+=@('.pcvrhub_mw2overlord_ownership.csv','.pcvrhub_version')
    $rows=@()
    foreach($name in @($names|Select-Object -Unique)){
        $name=Assert-PCVROwnedRelativePath -Relative $name
        $target=Join-OwnedRelativePath $Game $name;$exists=Test-Path -LiteralPath $target -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($name)).Replace('/','_')
        $rows+=[pscustomobject]@{Name=$name;Key=$key;Exists=$exists}
        if($exists){Copy-Item -LiteralPath $target -Destination (Join-Path $folder $key) -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_mw2overlord_backup';$hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $folder 'backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Rows=$rows;Folder=$folder;HadBackup=$hadBackup}
}
function Restore-MW2Rollback([string]$Game,$Snapshot){
    foreach($row in $Snapshot.Rows){
        $target=Join-OwnedRelativePath $Game $row.Name
        if($row.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $target -Force -ErrorAction Stop}
        elseif(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_mw2overlord_backup'
    if(Test-Path -LiteralPath $backup -PathType Container){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Invoke-MW2Installer{
    $work=$null;$snapshot=$null;$changed=$false;$game=$null
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Modern Warfare 2 Campaign Remastered VR - Installer' -ForegroundColor Cyan
        Write-Host '  Overlord beta by Aeka0 - Battle.net campaign' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  The original Battle.net game is required; this package contains no game.' -ForegroundColor White
        Write-Host '  Connect your headset and controllers before starting Singleplayer.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate the Battle.net game...')
        $game=Get-MW2Game
        Write-Host "  [OK] Battle.net game: $game" -ForegroundColor Green
        if(Get-Process -Name MW2CR,overlord -ErrorAction SilentlyContinue){throw 'Close MW2CR and Overlord before installing or updating.'}
        if(-not(Test-InstallerTargetWritable $game)){throw 'The Battle.net game folder is not writable. Restart with permission to write there.'}
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Overlord beta...')
        $release=Get-MW2Release
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'Overlord.7z'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Overlord $($release.Tag)" -ManualUrl $script:MW2Page -ExpectedReleaseTag $release.Tag -AllowSkip:$false)}
        $sevenZip=Get-SevenZip -Required
        if(-not $sevenZip){throw '7-Zip is required to extract the publisher archive.'}
        Assert-MW2Archive -SevenZip $sevenZip -Archive $archive
        $stage=Join-Path $work 'stage'
        Write-Host '  [..] Extracting the complete publisher runtime; this may take a minute.' -ForegroundColor Cyan
        if(-not(Expand-7zWithProgress -SevenZip $sevenZip -Archive $archive -Dest $stage -Label 'Overlord VR')){throw 'The publisher archive could not be extracted.'}
        $payload=Get-MW2Payload $stage
        $package=Get-Content -LiteralPath (Join-Path $payload 'version.json') -Raw -ErrorAction Stop|ConvertFrom-Json
        if($release.Tag -match '^v0\.(?<beta>\d+)\.0-beta$' -and [string]$package.name -ne ('Beta '+$Matches.beta)){
            throw 'The selected package does not match the resolved publisher beta.'
        }
        Write-Host "  [OK] Publisher package: $($package.name); release $($release.Tag)" -ForegroundColor Green
        $snapshot=Save-MW2Rollback -Game $game -Payload $payload -Work $work
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the publisher runtime beside MW2CR.exe...')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $game -Identity 'mw2overlord' -SkipRelativePaths @('overlord.pdb') -ProgressLabel 'Installing Overlord VR')
        $proof=@('overlord.exe','openxr_loader.dll','overlord.vrmanifest','vr_input\actions.json','h2-mod\ui_scripts\branding\__init__.lua','.pcvrhub_mw2overlord_ownership.csv')|ForEach-Object{Join-Path $game $_}
        if(-not(Confirm-PlacedFilesSurvive -Paths $proof -GameDir $game -NoClear)){throw 'Required Overlord files are missing after installation.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MW2_TEST_RECEIPT){$env:PCVR_MW2_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:MW2Contract -GameDir $game -Version $release.Tag -Route BattleNet -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host "  [OK] Overlord $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub; it opens Overlord in the game folder.' -ForegroundColor White
        Write-Host '  In Overlord, finish first-use setup and choose Singleplayer.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Switching to your pistol is faster than reloading, even in VR.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $snapshot -and $game){
            try{Restore-MW2Rollback -Game $game -Snapshot $snapshot;Write-Host '  Earlier game-folder files were restored.' -ForegroundColor Yellow}
            catch{Write-Host "  Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
        }
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_MW2_LIBRARY_ONLY -ne '1'){while($true){try{Invoke-MW2Installer;break}catch{
    $message="Overlord VR setup did not complete: $($_.Exception.Message)"
    Write-Host $message -ForegroundColor Red
    if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
    [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
}}}
