# Native PrimedGun uses its own engine and user-data format. Never install it
# over the former Dolphin-based PrimedGun installation.
. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'PublisherVRSetup.ps1')
$script:MetroidNativeModules=$PSScriptRoot
function Get-MetroidNativeSource {
    return @{Repo='iChris4/MetroidPrimePortVR';IncludePrerelease=$true;Patterns=@('(?i)^PrimedGun[-._](?!.*(?:symbols|source|sdk|debug))v?[0-9].*Windows[-._]x64\.zip$');Page='https://github.com/iChris4/MetroidPrimePortVR/releases'}
}
function Get-PrimedGunReleaseTagFromSource {
    param([string]$Source)
    if($Source -match '(?i)/releases/download/([^/]+)/'){return [uri]::UnescapeDataString($matches[1])}
    $leaf=[IO.Path]::GetFileName($Source)
    if($leaf -match '(?i)^PrimedGun[-._](v?[0-9][0-9A-Za-z._-]*?)(?:-Windows-x64)?\.zip$'){return $matches[1]}
    return $null
}
function Resolve-MetroidNativeRelease($ReleaseData=$null) {
    $source=Get-MetroidNativeSource
    return Resolve-GitHubReleaseAsset -Repo $source.Repo -IncludePrerelease $source.IncludePrerelease -AssetPatterns $source.Patterns -SkipReleasesWithoutMatchingAsset -ReleaseData $ReleaseData
}
function Get-MetroidNativeTest {
    if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_METROID_NATIVE_TEST){return $null}
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    $inputPath=[IO.Path]::GetFullPath($env:PCVR_METROID_NATIVE_TEST)
    if(-not $inputPath.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'Metroid test input escaped Temp.'}
    $test=Get-Content -LiteralPath $inputPath -Raw | ConvertFrom-Json
    $root=[IO.Path]::GetFullPath($test.Root).TrimEnd('\')+'\'
    if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_metroid_fixture'))){throw 'Missing isolated Metroid fixture sentinel.'}
    foreach($key in @('Game','Desktop','Receipt','Archive')){if(-not ([IO.Path]::GetFullPath([string]$test.$key)).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw ('Metroid fixture path escaped: '+$key)}}
    return $test
}
function Test-MetroidNativeRoot([string]$Root) {
    return ($Root -and (Test-LiteralPathSafe -Path (Join-PathLexical $Root 'metroid_prime_port.exe') -PathType Leaf) -and (Test-LiteralPathSafe -Path (Join-PathLexical $Root 'PrimedGun.exe') -PathType Leaf))
}
function Get-MetroidLegacySource {
    return @{Repo='Nobbie248/PrimedGun';Tag='v1.1.7-windows';Url='https://github.com/Nobbie248/PrimedGun/releases/download/v1.1.7-windows/PrimedGun.v1.1.7.zip';Page='https://github.com/Nobbie248/PrimedGun/releases/tag/v1.1.7-windows'}
}
function Get-MetroidVariantProof([string]$Variant){
    if($Variant -eq 'Legacy'){return @('PrimedGun.exe','Qt6Core.dll','Qt6Gui.dll','Qt6Widgets.dll','QtPlugins\platforms\qwindows.dll','Sys\GC\dsp_rom.bin')}
    return @('PrimedGun.exe','metroid_prime_port.exe','Qt6Core.dll','Qt6Gui.dll','Qt6Widgets.dll','platforms\qwindows.dll','webgpu_dawn.dll','dxcompiler.dll','dxil.dll')
}
function Test-MetroidVariantRoot([string]$Root,[string]$Variant){
    if(-not $Root){return $false}
    foreach($file in @(Get-MetroidVariantProof $Variant)){if(-not(Test-LiteralPathSafe -Path (Join-PathLexical $Root $file) -PathType Leaf)){return $false}}
    return $true
}
function Find-MetroidVariantRoot([string]$Variant,[string]$InstallerFolder,$Test){
    $slot=if($Variant -eq 'Native'){'mod_a_path'}else{'mod_b_path'}
    $roots=@(Get-PCVRRememberedGameFolder -GameId 'metroid-prime-vr' -StateNames @($slot,'installed_path','user_located') -ProbeFiles (Get-MetroidVariantProof $Variant))
    if($Test){
        if($Test.OtherGame){$other=[IO.Path]::GetFullPath([string]$Test.OtherGame);$prefix=[IO.Path]::GetFullPath($Test.Root).TrimEnd('\')+'\';if(-not $other.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Other Metroid route escaped the isolated fixture.'};$roots+=$other}
    }else{
        $receipt=Join-Path $InstallerFolder '.installed_path'
        if(Test-Path -LiteralPath $receipt){$roots+=([IO.File]::ReadAllText($receipt).Trim())}
        $leaf=if($Variant -eq 'Native'){'Metroid Prime VR 2'}else{'Metroid Prime VR'}
        foreach($drive in @('C:','D:','E:')){$roots+=Join-PathLexical ($drive+'\Games') $leaf}
    }
    foreach($root in $roots|Where-Object {$_}|Select-Object -Unique){if(Test-MetroidVariantRoot $root $Variant){return [string]$root}}
    return $null
}
function Find-MetroidVariantRepairRoot([string]$Variant){
    # A remembered location can still be repaired when a required DLL is
    # missing. This is path evidence only, never a VR Ready assertion.
    $slot=if($Variant -eq 'Native'){'mod_a_path'}else{'mod_b_path'};$identity=if($Variant -eq 'Native'){'primedgunnative'}else{'primedgunlegacy'}
    $root=Get-PCVRRememberedGameFolder -GameId 'metroid-prime-vr' -StateNames @($slot,'installed_path','user_located') -ProbeFiles @(('.pcvrhub_'+$identity+'_ownership.csv'))
    if($root){return $root}
    $probes=if($Variant -eq 'Native'){@('PrimedGun.exe','metroid_prime_port.exe')}else{@('PrimedGun.exe','Sys\GC\dsp_rom.bin')}
    return Get-PCVRRememberedGameFolder -GameId 'metroid-prime-vr' -StateNames @($slot,'installed_path','user_located') -ProbeFiles $probes
}
function Restore-MetroidVariantIndex($Before){
    if(-not $Before){return}
    . (Join-Path $script:MetroidNativeModules 'HubState.ps1')
    $game=@{Id='metroid-prime-vr';Title='Metroid Prime VR'}
    foreach($name in @('mod_a_path','mod_b_path')){if($Before[$name]){Write-PersistentGameStateValue -Game $game -Name $name -Value ([string]$Before[$name])}else{Reset-PersistentGameStateValue -Game $game -Name $name}}
}
function Save-MetroidVariantIndex([string]$Variant,[string]$Root,[string]$InstallerFolder,$Test){
    . (Join-Path $script:MetroidNativeModules 'HubState.ps1')
    $game=@{Id='metroid-prime-vr';Title='Metroid Prime VR'}
    $before=@{mod_a_path=(Read-PersistentGameStateValue -Game $game -Name 'mod_a_path');mod_b_path=(Read-PersistentGameStateValue -Game $game -Name 'mod_b_path')}
    $otherVariant=if($Variant -eq 'Native'){'Legacy'}else{'Native'}
    $other=Find-MetroidVariantRoot $otherVariant $InstallerFolder $Test
    try{
        $slot=if($Variant -eq 'Native'){'mod_a_path'}else{'mod_b_path'}
        if(-not(Save-HubRememberedGameFolder -GameId $game.Id -Title $game.Title -GameDir $Root -ProbeFiles (Get-MetroidVariantProof $Variant) -StateName $slot)){throw 'The selected Metroid variant path could not be saved.'}
        if($other){$otherSlot=if($Variant -eq 'Native'){'mod_b_path'}else{'mod_a_path'};if(-not(Save-HubRememberedGameFolder -GameId $game.Id -Title $game.Title -GameDir $other -ProbeFiles (Get-MetroidVariantProof $otherVariant) -StateName $otherSlot)){throw 'The other Metroid installation could not be retained in Hub state.'}}
        return $before
    }catch{Restore-MetroidVariantIndex $before;throw}
}
function Get-MetroidNativeDestination($Test) {
    if($Test){return [string]$Test.Game}
    $saved=Find-MetroidVariantRoot 'Native' (Join-Path $script:MetroidNativeModules '..\MetroidPrimeVR') $Test
    if(-not $saved){$saved=Find-MetroidVariantRepairRoot 'Native'}
    if($saved){if(Test-Path -LiteralPath (Join-Path $saved 'Sys\GC\dsp_rom.bin')){throw 'The saved Native folder also contains Legacy engine files. Choose a separate clean native folder.'};return $saved}
    Write-Host '  Native PrimedGun 2.0 installs separately from the old Dolphin build.' -ForegroundColor Yellow
    Write-Host '  Your old ROMs, saves, settings and complete legacy installation remain untouched.' -ForegroundColor White
    Write-Host '  Default: C:\Games\Metroid Prime VR 2. Choose a full destination folder, not its parent.' -ForegroundColor Cyan
    $picked=(Read-Host '  Destination (Enter = default)').Trim().Trim('"')
    if(-not $picked){$picked='C:\Games\Metroid Prime VR 2'}
    $picked=[IO.Path]::GetFullPath($picked)
    if(Test-Path -LiteralPath (Join-Path $picked 'Dolphin.exe')){throw 'Choose a separate empty folder for native PrimedGun, not a Dolphin installation.'}
    if((Test-Path -LiteralPath (Join-Path $picked 'PrimedGun.exe')) -and -not(Test-MetroidNativeRoot $picked)){throw 'This is the legacy PrimedGun folder. Choose a separate folder for version 2.'}
    return $picked
}
function Confirm-MetroidNativePlacement([string]$Game,[string]$Stage,$Test,[string]$Variant='Native') {
    $identity=if($Variant -eq 'Legacy'){'primedgunlegacy'}else{'primedgunnative'}
    while(@(Test-MetroidVariantFiles $Game 'before-retry' $Variant).Count){
        Write-Host '  Required files are missing. Check the target folder, permissions and installer log.' -ForegroundColor Yellow
        Write-Host '  This alone does not identify the cause. Check protection history if antivirus is suspected.' -ForegroundColor White
        Write-Host '  [R] Copy the runtime again  [F] Open installation folder  [D] Open Defender exclusions  [Q] Cancel and restore' -ForegroundColor White
        $answer=if($Test){if($Test.Recover -eq 'retry'){'R'}else{'Q'}}else{(Read-Host '  Choose R, F, D or Q').Trim().ToUpperInvariant()}
        switch($answer){
            'R'{[void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $Game -Identity $identity -ProgressLabel 'Retrying runtime placement');if(-not $Test){Start-Sleep -Seconds 3};[void](Test-MetroidVariantFiles $Game 'after-retry' $Variant);if($Test){$Test.Recover=''}}
            'F'{[void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the installation folder...');Start-Process explorer.exe -ArgumentList @('"'+$Game+'"')}
            'D'{Write-Host '  Review the issue before adding any exclusion. The Hub does not add one.' -ForegroundColor Yellow;[void](Open-PCVRPageAfterEnter -Url 'windowsdefender://exclusions' -Message 'Press Enter to open Windows Defender exclusions...')}
            'Q'{return $false}
        }
    }
    return $true
}
function Get-MetroidNativeArchive([string]$Work,$Test) {
    $source=Get-MetroidNativeSource;$dest=Join-Path $Work 'PrimedGun.zip'
    if($Test){Copy-Item -LiteralPath $Test.Archive -Destination $dest;return @{Path=$dest;Tag=[string]$Test.Tag}}
    $handoff=Get-PCVRRecoveryInput -PathType Leaf
    if(-not $handoff){
        Write-Host '  Checking stable releases AND prereleases; this may take a few seconds.' -ForegroundColor Cyan
        $release=Resolve-MetroidNativeRelease
        if($release.Resolved -and $release.Url){
            Write-Host ('  [OK] Current Windows release: '+$release.Tag) -ForegroundColor Green
            $downloadInfo=@{}
            [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $dest -Label ('PrimedGun '+$release.Tag+' Windows x64') -ManualUrl $source.Page -AllowSkip $false -PlainProgress -DownloadInfo $downloadInfo)
            $version=if($downloadInfo.SourcePath){Get-PrimedGunReleaseTagFromSource ([string]$downloadInfo.SourcePath)}else{Get-PrimedGunReleaseTagFromSource ([string]$downloadInfo.Url)}
            if(-not(Test-IsTrackableInstalledVersion $version)){$version=(Read-Host '  Enter the version shown for the file you downloaded on its official release page').Trim()}
            if(-not(Test-IsTrackableInstalledVersion $version)){throw 'A trackable delivered version is required. No installation files were changed.'}
            return @{Path=$dest;Tag=$version}
        }
        Write-Host '  The current Windows release could not be resolved. No legacy version will be substituted.' -ForegroundColor Yellow
        [void](Open-PCVRPageAfterEnter -Url $source.Page -Message 'Press Enter to open the current PrimedGun releases...')
    }
    while($true){
        if(-not $handoff){
            [void](Wait-PCVRExplicitEnter -Message 'After downloading the Windows x64 ZIP, press Enter...')
            $handoff=(Read-Host '  Drop/paste the downloaded ZIP, or Enter to reopen releases').Trim().Trim('"')
        }
        if($handoff -and (Test-Path -LiteralPath $handoff -PathType Leaf)){
            $tag=Get-PrimedGunReleaseTagFromSource $handoff
            if(-not(Test-IsTrackableInstalledVersion $tag)){$tag=(Read-Host '  Version shown on the official release page').Trim()}
            if(Test-IsTrackableInstalledVersion $tag){Copy-Item -LiteralPath $handoff -Destination $dest;[void](Set-PCVRRecoveryInput '');return @{Path=$dest;Tag=$tag}}
        }
        $handoff='';[void](Open-PCVRPageAfterEnter -Url $source.Page -Message 'Press Enter to reopen current releases...')
    }
}
function Test-MetroidNativeFiles([string]$Root,[string]$Checkpoint) {
    return @(Test-MetroidVariantFiles $Root $Checkpoint 'Native')
}
function Test-MetroidVariantFiles([string]$Root,[string]$Checkpoint,[string]$Variant) {
    $missing=@()
    foreach($file in @(Get-MetroidVariantProof $Variant)){
        $exists=Test-Path -LiteralPath (Join-Path $Root $file) -PathType Leaf
        Write-PCVRFileCheckResult -Path (Join-Path $Root $file) -Present $exists -Phase $Checkpoint -DisplayName $file
        if(-not $exists){$missing+=$file}
    }
    return $missing
}
function Invoke-MetroidNativeSetup([string]$InstallerFolder) {
    $ErrorActionPreference='Stop';$test=Get-MetroidNativeTest;$source=Get-MetroidNativeSource
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '  Metroid Prime VR - PrimedGun 2.0 (native OpenXR)' -ForegroundColor Cyan
    Write-Host '  Auto-update includes Windows prereleases. No game disc image is included.' -ForegroundColor White
    Write-Host '  Bring your own supported Metroid Prime disc image. USA revisions 0-2; PAL is experimental.' -ForegroundColor Yellow
    Show-AntivirusNotice -Compact
    Write-Host '  Keep your old installation: transfer normal saves through the new launcher.' -ForegroundColor Yellow
    Write-Host '  Dolphin save states cannot transfer. Save normally in the old game first.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to choose the installation folder...')
    $game=Get-MetroidNativeDestination $test
    if(Get-Process -Name 'PrimedGun','metroid_prime_port' -ErrorAction SilentlyContinue){throw 'Close PrimedGun and the game before installation or update.'}
    Write-Host ('  Game: '+$game) -ForegroundColor Cyan
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Windows release, including prereleases...')
    $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath());$snapshot=$null;$changed=$false;$shortcutChanged=$false;$keepWork=$false;$indexBefore=$null;$legacyLinkChanged=$false;$legacyLinkBefore=$null
    $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')}
    $link=Join-Path $desktop 'Metroid Prime VR.lnk';$oldLink=if(Test-Path -LiteralPath $link){[IO.File]::ReadAllBytes($link)}else{$null}
    try{
        $archive=Get-MetroidNativeArchive $work $test
        $expanded=Expand-PublisherVRArchive $archive (Join-Path $work 'expanded')
        $payload=Find-PublisherVRPayload $expanded 'metroid_prime_port.exe'
        if(@(Test-MetroidNativeFiles $payload 'package').Count){throw 'The package is missing required native Windows runtime files. Choose the Windows x64 ZIP.'}
        if(-not(Test-IsTrackableInstalledVersion $archive.Tag)){throw 'The delivered archive has no trackable publisher version.'}
        # Runtime ZIPs must never take ownership of saves/configs, even if a
        # future release starts bundling default user files.
        $stage=Join-Path $work 'runtime';[void][IO.Directory]::CreateDirectory($stage)
        foreach($item in Get-ChildItem -LiteralPath $payload -Force){if($item.Name -notin @('user','ROM','portable.txt') -and $item.Name -notlike '.pcvrhub*'){Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse -Force}}
        [void][IO.Directory]::CreateDirectory($game)
        $probe=Join-Path $game ('.pcvrhub_write_'+[guid]::NewGuid().ToString('N'));[IO.File]::WriteAllText($probe,'probe');Remove-Item -LiteralPath $probe
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity 'primedgunnative' -SnapshotRoot (Join-Path $work 'rollback')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the complete native Windows runtime...')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'primedgunnative' -ProgressLabel 'Installing PrimedGun native runtime')
        $missing=@(Test-MetroidNativeFiles $game 'after-copy')
        if(-not $test){Start-Sleep -Seconds 3}
        $later=@(Test-MetroidNativeFiles $game 'after-observation')
        if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game 'Qt6Core.dll');$later=@(Test-MetroidNativeFiles $game 'simulated-copy-failure')}
        if($later.Count -and -not(Confirm-MetroidNativePlacement $game $stage $test)){throw 'Required runtime files are missing. Setup was cancelled; earlier files will be restored.'}
        if($oldLink){
            $existing=(New-Object -ComObject WScript.Shell).CreateShortcut($link)
            if([IO.Path]::GetFileName($existing.TargetPath) -ine 'PrimedGun.exe'){throw 'An unrelated shortcut already uses this name; it was not changed.'}
        }
        $shortcutChanged=$true
        [void](New-DesktopShortcut -LnkPath $link -TargetPath (Join-Path $game 'PrimedGun.exe') -WorkingDir $game -IconPath (Join-Path $game 'PrimedGun.exe'))
        $legacy=Find-MetroidVariantRoot 'Legacy' $InstallerFolder $test
        if($legacy){
            $legacyLink=Join-Path $desktop 'Metroid Prime VR - Legacy.lnk'
            if(Test-Path -LiteralPath $legacyLink){$legacyLinkBefore=[IO.File]::ReadAllBytes($legacyLink);$old=(New-Object -ComObject WScript.Shell).CreateShortcut($legacyLink);if($old.TargetPath -ine (Join-Path $legacy 'PrimedGun.exe')){throw 'An unrelated Legacy shortcut already uses that name; it was not changed.'}}
            $legacyLinkChanged=$true;[void](New-DesktopShortcut -LnkPath $legacyLink -TargetPath (Join-Path $legacy 'PrimedGun.exe') -WorkingDir $legacy -IconPath (Join-Path $legacy 'PrimedGun.exe'))
        }
        if($test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
        if(@(Test-MetroidNativeFiles $game 'before-commit').Count){throw 'Native runtime evidence is incomplete.'}
        $contract=New-PCVRInstallerContract -Id 'metroid-prime-vr' -GameName 'Metroid Prime VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $source.Page -Routes @('Native') -RequiredInstalledFileGroups (@(Get-MetroidVariantProof 'Native')+@('.pcvrhub_primedgunnative_ownership.csv'))
        $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
        $indexBefore=Save-MetroidVariantIndex 'Native' $game $InstallerFolder $test
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $archive.Tag -InstalledPathReceiptPaths @($receipt) -Route Native)
        $changed=$false;$shortcutChanged=$false;$indexBefore=$null;$legacyLinkChanged=$false
        Write-Host '';Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
        Write-Host '  Alternative: Metroid Prime VR desktop shortcut.' -ForegroundColor White
        Write-Host '  In the launcher: Select Game -> choose your own disc image.' -ForegroundColor Yellow
        Write-Host '  Start your OpenXR runtime; in Port Config enable VR, then choose Play.' -ForegroundColor Yellow
        Write-Host '  To bring over old saves: Transfer PrimedGun Memory Card / Settings -> choose the old installation or User folder.' -ForegroundColor Yellow
        Write-Host '  Flat play: disable VR in Port Config. Save Settings remembers your choice.' -ForegroundColor White
        Write-Host '';Write-Host '  Scan the unknown, lock on, and let the arm cannon do the talking.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $errorRecord=$_
        if($indexBefore){Restore-MetroidVariantIndex $indexBefore}
        if($changed -and $snapshot){[void](Test-MetroidNativeFiles $game 'before-rollback');try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot;[void](Test-MetroidNativeFiles $game 'after-rollback')}catch{$keepWork=$true;Write-Host ('  Recovery copy retained at '+$work) -ForegroundColor Red}}
        if($shortcutChanged){if($oldLink){[IO.File]::WriteAllBytes($link,$oldLink)}elseif(Test-Path -LiteralPath $link){Remove-Item -LiteralPath $link -Force}}
        if($legacyLinkChanged){if($legacyLinkBefore){[IO.File]::WriteAllBytes($legacyLink,$legacyLinkBefore)}elseif(Test-Path -LiteralPath $legacyLink){Remove-Item -LiteralPath $legacyLink -Force}}
        throw $errorRecord
    }finally{if(-not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-MetroidLegacySetup([string]$InstallerFolder){
    $ErrorActionPreference='Stop';$test=Get-MetroidNativeTest;$source=Get-MetroidLegacySource
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '  Metroid Prime VR - LEGACY Dolphin-based PrimedGun 1.1.7' -ForegroundColor Cyan
    Write-Host '  Requires a powerful PC for Dolphin-based VR.' -ForegroundColor Yellow
    Write-Host '  This is the separate fixed legacy download, not the recommended native 2.0 route.' -ForegroundColor Yellow
    Write-Host '  Your own Metroid Prime USA NTSC 1.0 revision 0 disc image is required. No game is included.' -ForegroundColor Yellow
    Write-Host '  Use SteamVR for this legacy build. Native installations and all user data are kept separate.' -ForegroundColor White
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate or choose the Legacy installation...')
    $game=if($test){[string]$test.Game}else{Find-MetroidVariantRoot 'Legacy' $InstallerFolder $test}
    if(-not $game -and -not $test){$game=Find-MetroidVariantRepairRoot 'Legacy'}
    if(-not $game){Write-Host '  Default Legacy folder: C:\Games\Metroid Prime VR' -ForegroundColor Cyan;$picked=(Read-Host '  Full destination folder (Enter = default)').Trim().Trim('"');if(-not $picked){$picked='C:\Games\Metroid Prime VR'};$game=[IO.Path]::GetFullPath($picked)}
    if(Test-Path -LiteralPath (Join-Path $game 'metroid_prime_port.exe')){throw 'This is a native installation. Choose a separate folder for Legacy.'}
    if(Get-Process -Name PrimedGun,Dolphin -ErrorAction SilentlyContinue){throw 'Close PrimedGun and Dolphin before installing Legacy.'}
    Write-Host ('  Legacy game: '+$game) -ForegroundColor Cyan
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the separate Legacy Windows build...')
    $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath());$snapshot=$null;$changed=$false;$indexBefore=$null;$linkChanged=$false;$keepWork=$false
    $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$link=Join-Path $desktop 'Metroid Prime VR - Legacy.lnk';$oldLink=if(Test-Path -LiteralPath $link){[IO.File]::ReadAllBytes($link)}else{$null}
    try{
        $zip=Join-Path $work 'PrimedGunLegacy.zip';$version=$source.Tag
        if($test){Copy-Item -LiteralPath $test.Archive -Destination $zip;$version=[string]$test.Tag}
        else{
            $handoff=Get-PCVRRecoveryInput -PathType Leaf
            if($handoff){Copy-Item -LiteralPath $handoff -Destination $zip;$version=Get-PrimedGunReleaseTagFromSource $handoff;[void](Set-PCVRRecoveryInput '')}
            else{$info=@{};[void](Invoke-SafeDownload -Urls @($source.Url) -Destination $zip -Label 'PrimedGun Legacy 1.1.7 Windows' -ManualUrl $source.Page -AllowSkip $false -PlainProgress -DownloadInfo $info);$version=if($info.SourcePath){Get-PrimedGunReleaseTagFromSource ([string]$info.SourcePath)}else{Get-PrimedGunReleaseTagFromSource ([string]$info.Url)}}
            if(-not(Test-IsTrackableInstalledVersion $version)){$version=(Read-Host '  Version shown for this Legacy file on its official release page').Trim()}
        }
        if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The delivered Legacy version could not be recorded. No installation files were changed.'}
        $expanded=Expand-PublisherVRArchive @{Path=$zip} (Join-Path $work 'expanded');$payload=Find-PublisherVRPayload $expanded 'PrimedGun.exe'
        if(-not(Test-MetroidVariantRoot $payload 'Legacy') -or (Test-Path -LiteralPath (Join-Path $payload 'metroid_prime_port.exe'))){throw 'This is not a complete Dolphin-based Legacy Windows package. Native and Legacy files cannot be mixed.'}
        $stage=Join-Path $work 'runtime';$seed=Join-Path $work 'user-seed';[void][IO.Directory]::CreateDirectory($stage);[void][IO.Directory]::CreateDirectory($seed)
        foreach($item in Get-ChildItem -LiteralPath $payload -Force){if($item.Name -notin @('User','ROM') -and $item.Name -notlike '.pcvrhub*'){Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse -Force}}
        $previousVersionPath=Join-Path $game '.pcvrhub_legacy_previous_version.txt'
        if(Test-Path -LiteralPath $previousVersionPath){Copy-Item -LiteralPath $previousVersionPath -Destination (Join-Path $stage '.pcvrhub_legacy_previous_version.txt')}
        elseif((Test-MetroidVariantRoot $game 'Legacy') -and -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_primedgunlegacy_ownership.csv'))){$oldVersion=if(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_version')){[IO.File]::ReadAllText((Join-Path $game '.pcvrhub_version')).Trim()}else{'unknown'};[IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_legacy_previous_version.txt'),$oldVersion)}
        [IO.File]::WriteAllText((Join-Path $stage 'portable.txt'),'')
        # Seed only absent publisher User defaults. Once created, they are user
        # data, deliberately outside runtime removal/update ownership.
        $userSource=Join-Path $payload 'User'
        if(Test-Path -LiteralPath $userSource){$base=$payload.TrimEnd('\');foreach($file in Get-ChildItem -LiteralPath $userSource -File -Recurse){$rel=$file.FullName.Substring($base.Length+1);if(-not(Test-Path -LiteralPath (Join-Path $game $rel))){$target=Join-Path $seed $rel;[void][IO.Directory]::CreateDirectory((Split-Path $target -Parent));Copy-Item -LiteralPath $file.FullName -Destination $target}}}
        $ini=Join-Path $game 'User\Config\Dolphin.ini'
        if(-not(Test-Path -LiteralPath $ini)){$target=Join-Path $seed 'User\Config\Dolphin.ini';[void][IO.Directory]::CreateDirectory((Split-Path $target -Parent));[IO.File]::WriteAllText($target,("[General]`r`nISOPaths = 1`r`nRecursiveISOPaths = True`r`nISOPath0 = "+(Join-Path $game 'ROM')+"`r`n"))}
        $plan=Join-Path $work 'snapshot-plan';Copy-Item -LiteralPath $stage -Destination $plan -Recurse
        foreach($item in Get-ChildItem -LiteralPath $seed -Force){Copy-Item -LiteralPath $item.FullName -Destination $plan -Recurse -Force}
        [void][IO.Directory]::CreateDirectory($game)
        $probe=Join-Path $game ('.pcvrhub_write_'+[guid]::NewGuid().ToString('N'));[IO.File]::WriteAllText($probe,'probe');Remove-Item -LiteralPath $probe
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $plan -Identity 'primedgunlegacy' -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths @('.pcvrhub_version_b')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or repair Legacy only...')
        $changed=$true;[void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'primedgunlegacy' -ProgressLabel 'Installing Legacy runtime')
        $seedBase=$seed.TrimEnd('\');foreach($file in Get-ChildItem -LiteralPath $seed -Recurse -File){$rel=$file.FullName.Substring($seedBase.Length+1);$target=Join-Path $game $rel;if(-not(Test-Path -LiteralPath $target)){[void][IO.Directory]::CreateDirectory((Split-Path $target -Parent));Copy-Item -LiteralPath $file.FullName -Destination $target}}
        [void][IO.Directory]::CreateDirectory((Join-Path $game 'ROM'))
        [void](Test-MetroidVariantFiles $game 'after-copy' 'Legacy');if(-not $test){Start-Sleep -Seconds 3}
        if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game 'Qt6Core.dll')}
        if(@(Test-MetroidVariantFiles $game 'after-observation' 'Legacy').Count -and -not(Confirm-MetroidNativePlacement $game $stage $test 'Legacy')){throw 'Required Legacy files are missing. Earlier files will be restored.'}
        if($oldLink){$old=(New-Object -ComObject WScript.Shell).CreateShortcut($link);if($old.TargetPath -ine (Join-Path $game 'PrimedGun.exe')){throw 'An unrelated Legacy shortcut already uses this name; it was not changed.'}}
        $linkChanged=$true;[void](New-DesktopShortcut -LnkPath $link -TargetPath (Join-Path $game 'PrimedGun.exe') -WorkingDir $game -IconPath (Join-Path $game 'PrimedGun.exe'))
        if($test.Failure -eq 'commit'){throw 'Isolated Legacy commit failure.'}
        if(@(Test-MetroidVariantFiles $game 'before-commit' 'Legacy').Count){throw 'Legacy runtime evidence is incomplete.'}
        $indexBefore=Save-MetroidVariantIndex 'Legacy' $game $InstallerFolder $test
        $contract=New-PCVRInstallerContract -Id 'metroid-prime-vr' -GameName 'Metroid Prime VR Legacy' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $source.Page -Routes @('Legacy') -RequiredInstalledFileGroups (@(Get-MetroidVariantProof 'Legacy')+@('portable.txt','.pcvrhub_primedgunlegacy_ownership.csv'))
        $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -VersionSlot Secondary -AdditionalVersionReceiptPaths @((Join-Path $game '.pcvrhub_version')) -InstalledPathReceiptPaths @($receipt) -Route Legacy)
        $changed=$false;$indexBefore=$null;$linkChanged=$false
        Write-Host '';Write-Host '  1. Use Start in VR in the Hub and choose Legacy.' -ForegroundColor Green
        Write-Host '  Alternative: Metroid Prime VR - Legacy desktop shortcut. Start SteamVR first.' -ForegroundColor White
        Write-Host '  Put your own NTSC 1.0 revision 0 disc image in the ROM folder, or use Select Game in PrimedGun.' -ForegroundColor Yellow
        Write-Host '  The recommended Native variant remains separate and unchanged.' -ForegroundColor White
        Write-Host '';Write-Host '  Scan the unknown, lock on, and let the arm cannon do the talking.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $errorRecord=$_;if($indexBefore){Restore-MetroidVariantIndex $indexBefore}
        if($changed -and $snapshot){[void](Test-MetroidVariantFiles $game 'before-rollback' 'Legacy');try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot;[void](Test-MetroidVariantFiles $game 'after-rollback' 'Legacy')}catch{$keepWork=$true;Write-Host ('  Recovery copy retained at '+$work) -ForegroundColor Red}}
        if($linkChanged){if($oldLink){[IO.File]::WriteAllBytes($link,$oldLink)}elseif(Test-Path -LiteralPath $link){Remove-Item -LiteralPath $link -Force}}
        throw $errorRecord
    }finally{if(-not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-MetroidNativeUninstall([string]$InstallerFolder,[switch]$HubConfirmed,[ValidateSet('Native','Legacy')][string]$Variant='Native') {
    $ErrorActionPreference='Stop';$test=Get-MetroidNativeTest
    $identity=if($Variant -eq 'Legacy'){'primedgunlegacy'}else{'primedgunnative'}
    $game=if($test){[string]$test.Game}else{Find-MetroidVariantRoot $Variant $InstallerFolder $test}
    if(-not $game -and -not $test){$game=Find-MetroidVariantRepairRoot $Variant}
    if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game ('.pcvrhub_'+$identity+'_ownership.csv')))){throw 'No owned installation of this variant was found. The other installation was not changed.'}
    if(Get-Process -Name 'PrimedGun','metroid_prime_port' -ErrorAction SilentlyContinue){throw 'Close PrimedGun and the game before removal.'}
    if(-not $HubConfirmed -and (Read-Host ('Remove '+$Variant+' PrimedGun? Saves and disc images stay. Type REMOVE')) -cne 'REMOVE'){return}
    $priorVersionPath=Join-Path $game '.pcvrhub_legacy_previous_version.txt';$priorVersion=if($Variant -eq 'Legacy' -and (Test-Path -LiteralPath $priorVersionPath)){[IO.File]::ReadAllText($priorVersionPath).Trim()}else{''}
    [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $identity)
    if($Variant -eq 'Legacy' -and (Test-MetroidVariantRoot $game 'Legacy')){
        if(Test-IsTrackableInstalledVersion $priorVersion){Write-PCVRAtomicText -Path (Join-Path $game '.pcvrhub_version') -Value $priorVersion;Write-PCVRAtomicText -Path (Join-Path $game '.pcvrhub_version_b') -Value $priorVersion}
        else{foreach($name in @('.pcvrhub_version','.pcvrhub_version_b')){if(Test-Path -LiteralPath (Join-Path $game $name)){Remove-Item -LiteralPath (Join-Path $game $name)}}}
        [void](Save-HubRememberedGameFolder -GameId 'metroid-prime-vr' -Title 'Metroid Prime VR' -GameDir $game -StateName 'mod_b_path' -ProbeFiles (Get-MetroidVariantProof 'Legacy'))
        Write-Host '  [OK] The earlier Legacy runtime was restored. Its shortcut, saves and the Native installation remain.' -ForegroundColor Green
        return
    }
    $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$link=Join-Path $desktop $(if($Variant -eq 'Legacy'){'Metroid Prime VR - Legacy.lnk'}else{'Metroid Prime VR.lnk'})
    if(Test-Path -LiteralPath $link){$shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut($link);if($shortcut.TargetPath -ieq (Join-Path $game 'PrimedGun.exe')){Remove-Item -LiteralPath $link -Force}}
    $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
    foreach($path in @((Join-Path $game '.pcvrhub_version'),$(if($Variant -eq 'Legacy'){Join-Path $game '.pcvrhub_version_b'}))|Where-Object {$_}){if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Force}}
    if((Test-Path -LiteralPath $receipt) -and [IO.File]::ReadAllText($receipt).Trim() -ieq $game){Remove-Item -LiteralPath $receipt -Force}
    . (Join-Path $script:MetroidNativeModules 'HubState.ps1');Reset-PersistentGameStateValue -Game @{Id='metroid-prime-vr';Title='Metroid Prime VR'} -Name $(if($Variant -eq 'Legacy'){'mod_b_path'}else{'mod_a_path'})
    Write-Host '  [OK] Selected runtime removed. User data, disc images and the other installation remain.' -ForegroundColor Green
}
