# EARTH DEFENSE FORCE 6 VR - governed GitHub prerelease installer.
# Steam-only game; shared EDFModLoader is preserved on removal; personal INI
# files are never overwritten. The installed route may remain VR or Flat.

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='EARTH DEFENSE FORCE 6 VR Installer'
$APP_ID='2291060'; $GAME_EXE='EDF6.exe'; $REPO='momotori01/EARTH-DEFENSE-FORCE-6-VR-MOD'
$RELEASES="https://github.com/$REPO/releases"; $FALLBACK_TAG='EDF6VR-3.2.9'; $FALLBACK_NAME='EDF6VR-3.2.9.zip'
$FALLBACK_URL='https://github.com/momotori01/EARTH-DEFENSE-FORCE-6-VR-MOD/releases/download/EDF6VR-3.2.9/EDF6VR-3.2.9.zip'; $IDENTITY='edf6vr'
$QUIP='EDF deploys in stereo, and this time both hands answer the call.'
$contract=New-PCVRInstallerContract -Id 'earth-defense-force-6-vr' -GameName 'EARTH DEFENSE FORCE 6 VR' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @('Mods\Plugins\EDF6VR.dll|Mods\Plugins\EDF6VR.dll.disabled','EDF6 VR setting.exe','winmm.dll','.pcvrhub_edf6vr_ownership.csv')

function Write-EDFStep([int]$Number,[int]$Total,[string]$Text){Write-Host '';Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan;Write-Host ''}
function Write-EDFOK([string]$Text){Write-Host "  [OK] $Text" -ForegroundColor Green}
function Write-EDFInfo([string]$Text){Write-Host "  [i] $Text" -ForegroundColor Gray}
function Write-EDFWarn([string]$Text){Write-Host "  [!!] $Text" -ForegroundColor Yellow}
function Test-EDF6Root([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'EDF6.exe') -PathType Leaf))}
function Find-EDF6Payload([string]$ExtractRoot){
    $dll=Get-ChildItem -LiteralPath $ExtractRoot -Filter 'EDF6VR.dll' -File -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.DirectoryName -match '[\\/]Mods[\\/]Plugins$'} | Select-Object -First 1
    if(-not $dll){return $null}; return (Split-Path -Parent (Split-Path -Parent $dll.DirectoryName))
}
function Save-EDF6Snapshot([string]$GameRoot,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot);$records=@()
    foreach($relative in @('README_ClearLoot.txt','README_EDF6VR.txt','VR_Play.bat','HD_Texture_2x.bat','Set_Resolution.bat','EDF6 VR setting.exe','Update_EDF6VR.bat','EDF6VR','Mods\HDTexture','Mods\Plugins\EDF6ClearLoot.dll','Mods\Plugins\EDF6VR.dll','Mods\Plugins\EDF6VR.dll.disabled','winmm.dll','ModLoader.ini','.pcvrhub_edf6vr_ownership.csv','.pcvrhub_edf6vr_backup','.pcvrhub_edf6vr_loader_ownership.csv','.pcvrhub_edf6vr_loader_backup','.pcvrhub_version')){
        $source=Join-Path $GameRoot $relative;$exists=Test-Path -LiteralPath $source;$records+=[pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-Path $SnapshotRoot ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_'));Copy-Item -LiteralPath $source -Destination $copy -Recurse -Force}
    };return $records
}
function Restore-EDF6Snapshot([string]$GameRoot,[string]$SnapshotRoot,$Records){
    if(-not(Test-EDF6Root $GameRoot)){throw 'Rollback target is no longer a verified EDF6 folder.'}
    foreach($record in @($Records)){$target=Join-Path $GameRoot ([string]$record.Relative);if(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue};if($record.Exists){$copy=Join-Path $SnapshotRoot ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$record.Relative)).Replace('/','_'));$parent=Split-Path -Parent $target;if(-not(Test-Path $parent)){[void][IO.Directory]::CreateDirectory($parent)};Copy-Item -LiteralPath $copy -Destination $target -Recurse -Force}}
}
function Get-EDF6RequiredRuntimePaths([string]$GameRoot,[bool]$FlatMode) {
    $modeFile = if ($FlatMode) { 'Mods\Plugins\EDF6VR.dll.disabled' } else { 'Mods\Plugins\EDF6VR.dll' }
    return [string[]]@(
        (Join-Path $GameRoot $modeFile)
        (Join-Path $GameRoot 'EDF6 VR setting.exe')
        (Join-Path $GameRoot 'winmm.dll')
    )
}

function global:Restore-EDF6FilesInsideGame([string]$ArchivePath,[string]$GameRoot,[bool]$FlatMode) {
    $enabled = Join-Path $GameRoot 'Mods\Plugins\EDF6VR.dll'
    $disabled = $enabled + '.disabled'
    $settings = Join-Path $GameRoot 'EDF6 VR setting.exe'
    $loader = Join-Path $GameRoot 'winmm.dll'
    # The publisher archive contains EDF6VR.dll only. In preserved Flat mode
    # restore that source name on excluded ground, then park it again before
    # the survival check evaluates the original .disabled watch path.
    [void](Restore-FromArchiveInGameFolder -ArchivePath $ArchivePath -GameDir $GameRoot -Paths @($enabled,$settings,$loader))
    if ($FlatMode -and (Test-Path -LiteralPath $enabled -PathType Leaf)) {
        if (Test-Path -LiteralPath $disabled -PathType Leaf) {
            Remove-Item -LiteralPath $enabled -Force -ErrorAction Stop
        } else {
            Move-Item -LiteralPath $enabled -Destination $disabled -Force -ErrorAction Stop
        }
    }
    $modeFile = if ($FlatMode) { $disabled } else { $enabled }
    return [bool]((Test-Path -LiteralPath $modeFile -PathType Leaf) -and
        (Test-Path -LiteralPath $settings -PathType Leaf) -and
        (Test-Path -LiteralPath $loader -PathType Leaf))
}

function global:Invoke-EDF6VRInstaller{
    $work=$null;$game=$null;$snapshot=$null;$records=$null;$changesStarted=$false;$wasFlat=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  EARTH DEFENSE FORCE 6 VR - Installer' -ForegroundColor Cyan;Write-Host '  Installs: EDF6VR by momotori01' -ForegroundColor Gray;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Native stereo, roomscale 6DoF, one- and two-hand aiming,' -ForegroundColor White
        Write-Host '  all four classes, vehicles, Ranger dual wield, automatic' -ForegroundColor White
        Write-Host '  headset FOV, resolution control and optional HD textures.' -ForegroundColor White
        Write-Host '  Steam and the usual Epic install path are recognized. Start' -ForegroundColor Yellow
        Write-Host '  the unmodded game normally once before setup, reach the menu,' -ForegroundColor Yellow
        Write-Host '  close it, then continue here.' -ForegroundColor Yellow
        Write-Host '  This is an early release: not every weapon or vehicle is tested.' -ForegroundColor Yellow
        Write-Host '  Personal EDF6VR and Clear Loot settings are preserved.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        Write-EDFStep 1 4 'Locating EARTH DEFENSE FORCE 6'
        $game=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('EARTH DEFENSE FORCE 6') -ProbeExe $GAME_EXE -HubGameId 'earth-defense-force-6-vr'
        if(-not(Test-EDF6Root $game)){foreach($candidate in @('C:\Program Files\Epic Games\EarthDefenseForce6')){if(Test-EDF6Root $candidate){$game=$candidate;break}}}
        if(-not(Test-EDF6Root $game)){$game=Get-GameFolderInteractive -GameName 'EARTH DEFENSE FORCE 6' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/2291060/'}
        if($game -in @('quit','skip',$null) -or -not(Test-EDF6Root $game)){throw 'Setup cancelled before any game file was changed.'};$game=(Get-Item $game).FullName
        if(Get-Process -Name EDF6,LaunchGame -ErrorAction SilentlyContinue){throw 'EDF6 is running. Close it completely and run setup again.'};Write-EDFOK "Found: $game"

        Write-EDFStep 2 4 'Getting the newest installable EDF6VR package, including prereleases'
        $release=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -AssetPatterns @('(?i)^EDF6VR[-_.].*\.zip$') -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_NAME
        if (@($release.SkippedReleaseTags).Count -gt 0) {
            Write-Host "  Publisher notes without a package were skipped: $(@($release.SkippedReleaseTags) -join ', ')" -ForegroundColor Yellow
        }
        Write-EDFInfo "Release: $($release.Tag)";$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_edf6vr_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'EDF6VR.zip';$got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "EDF6VR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if(-not($got -eq $true -or [string]$got -in @('retry','manual'))){throw 'The EDF6VR release was not downloaded.'}
        $extract=Join-Path $work 'release';$x=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'EDF6VR release' -AllowSkip $false
        if([string]$x -notin @('ok','manual','retry')){throw 'The EDF6VR archive could not be extracted.'};$payload=Find-EDF6Payload $extract
        if(-not $payload -or -not(Test-Path -LiteralPath (Join-Path $payload 'EDF6 VR setting.exe') -PathType Leaf) -or -not(Test-Path -LiteralPath (Join-Path $payload 'winmm.dll') -PathType Leaf)){throw 'The current release has no usable EDF6VR runtime payload.'}
          $publisherManifest=Join-Path $payload 'EDF6VR\PACKAGE_MANIFEST.json'
          if(-not(Test-Path -LiteralPath $publisherManifest -PathType Leaf)){throw 'EDF6VR package has no version manifest. No game files were changed.'}
          $publisherVersion=[string]((Get-Content -LiteralPath $publisherManifest -Raw -ErrorAction Stop | ConvertFrom-Json).version)
          $selectedVersion=[regex]::Match([string]$release.Tag,'\d+(?:\.\d+){1,3}').Value
          if(-not $publisherVersion -or $publisherVersion -ne $selectedVersion){throw "EDF6VR package version $publisherVersion does not match selected release $($release.Tag). No game files were changed."}

        Write-EDFStep 3 4 'Installing recoverably next to EDF6.exe'
        Write-Host '  VR mod files are now extracted and copied into the game folder.' -ForegroundColor White
        Write-Host '  Windows may request PowerShell permission for a protected Steam folder.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the reviewed runtime files...')
        $publisherLoader=Join-Path $payload 'winmm.dll';$gameLoader=Join-Path $game 'winmm.dll'
        $publisherLoaderHash=(Get-FileHash -LiteralPath $publisherLoader -Algorithm SHA256 -ErrorAction Stop).Hash
        $existingLoaderHash=if(Test-Path -LiteralPath $gameLoader -PathType Leaf){(Get-FileHash -LiteralPath $gameLoader -Algorithm SHA256 -ErrorAction Stop).Hash}else{''}
        $loaderManifest=Join-Path $game '.pcvrhub_edf6vr_loader_ownership.csv';$ownedLoader=$false
        if(Test-Path -LiteralPath $loaderManifest -PathType Leaf){
            $loaderRow=@(Import-Csv -LiteralPath $loaderManifest -ErrorAction Stop | Where-Object {$_.RelativePath -ieq 'winmm.dll'})|Select-Object -First 1
            if($loaderRow){
                if($existingLoaderHash -and $existingLoaderHash -ne [string]$loaderRow.InstalledSha256){throw 'The previously Hub-owned winmm.dll changed after installation. Restore or move it aside before retrying; the Hub will not overwrite it.'}
                $ownedLoader=[bool]$existingLoaderHash
            }
        }
        if($existingLoaderHash -and $existingLoaderHash -ne $publisherLoaderHash -and -not $ownedLoader){
            Write-EDFWarn 'An existing shared winmm.dll differs from the publisher loader required by this EDF6VR release.'
            Write-Host '  Updating it may affect other EDF6 mods. The previous file will be backed up in the game folder.' -ForegroundColor White
            Write-Host '  [U] Back up and update this shared loader' -ForegroundColor Cyan
            Write-Host '  [C] Cancel without changing the game' -ForegroundColor Cyan
            $choice=(''+(Read-Host 'Choose U or C')).Trim()
            if($choice -ine 'U'){throw 'Setup cancelled before the shared loader was changed.'}
        }
        $wasFlat=(-not(Test-Path -LiteralPath (Join-Path $game 'Mods\Plugins\EDF6VR.dll') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $game 'Mods\Plugins\EDF6VR.dll.disabled') -PathType Leaf))
        if($wasFlat){
            $modManifest=Join-Path $game '.pcvrhub_edf6vr_ownership.csv'
            $oldModRow=if(Test-Path -LiteralPath $modManifest -PathType Leaf){@(Import-Csv -LiteralPath $modManifest -ErrorAction Stop | Where-Object {$_.RelativePath -ieq 'Mods\Plugins\EDF6VR.dll'} | Select-Object -First 1)[0]}else{$null}
            $disabledPath=Join-Path $game 'Mods\Plugins\EDF6VR.dll.disabled'
            if(-not $oldModRow -or -not $oldModRow.InstalledSha256 -or
                (Get-FileHash -LiteralPath $disabledPath -Algorithm SHA256 -ErrorAction Stop).Hash -ne [string]$oldModRow.InstalledSha256){
                throw 'The parked Flat-mode VR DLL is not the unchanged Hub-owned file. No update was made; keep this file and review it before retrying.'
            }
        }
        $snapshot=Join-Path $work 'rollback';$records=Save-EDF6Snapshot -GameRoot $game -SnapshotRoot $snapshot;$changesStarted=$true
        $loaderStage=Join-Path $work 'loader-stage';[void][IO.Directory]::CreateDirectory($loaderStage);$loaderFiles=0
        if(-not $existingLoaderHash -or $existingLoaderHash -ne $publisherLoaderHash -or $ownedLoader){Copy-Item -LiteralPath $publisherLoader -Destination (Join-Path $loaderStage 'winmm.dll') -Force -ErrorAction Stop;$loaderFiles++}
        $sourceLoaderIni=Join-Path $payload 'ModLoader.ini';$gameLoaderIni=Join-Path $game 'ModLoader.ini'
        if((Test-Path -LiteralPath $sourceLoaderIni -PathType Leaf) -and -not(Test-Path -LiteralPath $gameLoaderIni -PathType Leaf)){Copy-Item -LiteralPath $sourceLoaderIni -Destination (Join-Path $loaderStage 'ModLoader.ini') -Force -ErrorAction Stop;$loaderFiles++}
        elseif((Test-Path -LiteralPath $gameLoaderIni -PathType Leaf) -and (Test-Path -LiteralPath $loaderManifest -PathType Leaf)){
            $ownedIniRow=@(Import-Csv -LiteralPath $loaderManifest -ErrorAction Stop | Where-Object {$_.RelativePath -ieq 'ModLoader.ini'})|Select-Object -First 1
            if($ownedIniRow){Copy-Item -LiteralPath $gameLoaderIni -Destination (Join-Path $loaderStage 'ModLoader.ini') -Force -ErrorAction Stop;$loaderFiles++}
        }
        if($loaderFiles -gt 0){[void](Install-OwnedModPayload -SourceRoot $loaderStage -GameRoot $game -Identity 'edf6vr_loader' -AdoptIdenticalExisting -KeepExistingRelativePaths @('ModLoader.ini'));Write-EDFOK 'Publisher EDFModLoader installed or updated with ownership backup.'}else{Write-EDFOK 'Existing byte-identical shared EDFModLoader preserved.'}
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $game -Identity $IDENTITY -SkipRelativePaths @('winmm.dll','ModLoader.ini','Mods\Plugins\EDF6VR.ini','Mods\Plugins\EDF6ClearLoot.ini') -AdoptIdenticalExisting)
        foreach($relative in @('Mods\Plugins\EDF6VR.ini','Mods\Plugins\EDF6ClearLoot.ini')){
            $target=Join-Path $game $relative
            if(Test-Path -LiteralPath $target -PathType Leaf){Write-EDFOK "Existing $relative preserved.";continue}
            $source=Join-Path $payload $relative
            if(Test-Path -LiteralPath $source -PathType Leaf){Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop;Write-EDFOK "Default $relative created."}
            elseif($relative -eq 'Mods\Plugins\EDF6VR.ini'){Write-EDFInfo 'EDF6VR.ini will be created by the mod on first game start; publisher defaults remain under EDF6VR.'}
            else{throw "The publisher package is missing its required default: $relative"}
        }
        if($wasFlat){$enabled=Join-Path $game 'Mods\Plugins\EDF6VR.dll';$disabled=$enabled+'.disabled';if(Test-Path -LiteralPath $disabled){Remove-Item -LiteralPath $disabled -Force};Move-Item -LiteralPath $enabled -Destination $disabled -Force;Write-EDFOK 'Previous Flat mode preserved.'}else{Write-EDFOK 'VR mode enabled by the publisher package.'}
        # Keep this explicitly typed and array-wrapped. When only one mode DLL
        # exists, an unwrapped pipeline becomes a scalar string; using += then
        # concatenates the next absolute paths into one impossible filename.
        [string[]]$watch = @(Get-EDF6RequiredRuntimePaths -GameRoot $game -FlatMode $wasFlat)
        foreach ($path in $watch) {
            $relative = $path.Substring($game.TrimEnd('\','/').Length).TrimStart('\','/')
            if (Test-Path -LiteralPath $path -PathType Leaf) { Write-EDFInfo "Post-copy check: $relative is present." }
            else { Write-EDFWarn "Post-copy check: $relative is missing." }
        }
        # Recovery must unpack the original publisher archive inside the game
        # folder the user just excluded. The closure also maps the publisher's
        # active DLL back to .disabled when the previous Flat mode is retained.
        $recover = { [void](Restore-EDF6FilesInsideGame -ArchivePath $archive -GameRoot $game -FlatMode $wasFlat) }.GetNewClosure()
        if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recover)){throw 'Required EDF6VR files are still missing after recovery.'}

        Write-EDFStep 4 4 'Verifying the Steam route and saved mode'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current);$changesStarted=$false
        Write-EDFOK "EDF6VR $($release.Tag) is installed and tracked."
        Write-Host '  Connect the selected OpenXR runtime, then use Start in VR from the Hub.' -ForegroundColor White
        Write-Host '  Use EDF6 VR setting.exe or the Hub Flat / VR switch to change mode.' -ForegroundColor Gray
        Write-Host '  The tutorial may need a normal gamepad with F11 used as a session toggle.' -ForegroundColor Gray
        Write-Host '';Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Setup complete.' -ForegroundColor Green;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '';Write-Host "  $QUIP" -ForegroundColor Magenta;Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{if($changesStarted -and $game -and $snapshot){try{Restore-EDF6Snapshot -GameRoot $game -SnapshotRoot $snapshot -Records $records;Write-EDFWarn 'The previous EDF6 VR state was restored.'}catch{Write-EDFWarn "Rollback needs review: $($_.Exception.Message)"}};Write-Host '';Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red;throw
    }finally{if($work -and(Test-Path $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_EDF6VR_LIBRARY_ONLY -ne '1'){Invoke-EDF6VRInstaller}
