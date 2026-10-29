. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')
$script:Avp2Modules=$PSScriptRoot
$script:Avp2Id='aliens-versus-predator-2-vr'
$script:Avp2Page='https://github.com/Bassquake/Aliens-Versus-Predator-2-VR/releases'
$script:Avp2BasePage='https://www.moddb.com/games/aliens-vs-predator-2/downloads/aliens-vs-predator-2-easy-installer'
$script:Avp2Required=@('DDraw.dll|DDraw.dll.pcvrhub_off','D3DImm.dll','d3d11.dll','openxr_loader.dll','xrres.exe','dgVoodoo.conf','avp2xr.ini','vrrez\cshell.dll','vrrez\cres.dll','vrrez\sres.dll','vrrez\Models\Weapons\Marine\mPulserifle_pv.ABC','PCVR-Launcher\Start-AvP2VR.ps1')
function Test-Avp2Base([string]$Root){
 if(-not $Root){return $false}
 foreach($f in @('AVP2.exe','lithtech.exe','AVP2.rez')){if(-not [IO.File]::Exists([IO.Path]::Combine($Root,$f))){return $false}};return $true
}
function Get-Avp2Test {
 if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_AVP2_TEST){return $null}
 $p=[IO.Path]::GetFullPath($env:PCVR_AVP2_TEST);$t=Get-Content -LiteralPath $p -Raw|ConvertFrom-Json
 $root=[IO.Path]::GetFullPath($t.Root).TrimEnd('\')+'\'
 if(-not $root.StartsWith([IO.Path]::GetTempPath(),[StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists((Join-Path $root '.avp2-fixture')) -or -not $p.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Invalid isolated AvP2 fixture.'}
 foreach($key in @('Game','Receipt','Desktop','Package')){if(-not ([IO.Path]::GetFullPath($t.$key)).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'AvP2 fixture escapes its sentinel.'}}
 return $t
}
function Invoke-Avp2Privileged {
 param([ValidateSet('install','restore','remove','commit')][string]$Action,[string]$Game,[string]$Stage='',$Snapshot=$null)
 if(Test-InstallerTargetWritable $Game){return Invoke-Avp2FileAction $Action $Game $Stage $Snapshot}
 Write-Host '  Administrator approval is needed to change VR files in this game folder.' -ForegroundColor Yellow
 Write-Host ('  Game folder: '+$Game) -ForegroundColor Cyan
 [void](Wait-PCVRExplicitEnter -Message 'Press Enter to request Windows administrator approval (UAC)...')
 $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
 try{
  $result=Join-Path $work 'result.json';$request=Join-Path $work 'request.json'
  @{Action=$Action;Game=$Game;Stage=$Stage;Snapshot=$Snapshot;Result=$result}|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $request -Encoding UTF8
  $entry=Join-Path $script:Avp2Modules '..\AliensPredator2VR\Files-AvP2VR.ps1'
  $p=Start-Process -FilePath (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "'+$entry+'" -Request "'+$request+'"') -Verb RunAs -WindowStyle Hidden -PassThru
  $processHandle=$p.Handle;$p.WaitForExit()
  if($p.ExitCode -ne 0 -or -not [IO.File]::Exists($result)){throw 'Administrator approval or the file operation did not complete. Retry is available.'}
  $r=Get-Content -LiteralPath $result -Raw|ConvertFrom-Json;if(-not $r.Success){throw $r.Message};return $r.Value
 }finally{Remove-PCVRInstallerTempSession -Path $work}
}
function Invoke-Avp2FileAction($Action,$Game,$Stage,$Snapshot){
 if(-not(Test-Avp2Base $Game)){throw 'The original game files are missing.'}
 switch($Action){
  'install'{
   $obsolete=Join-Path $Game 'vrrez\object.lto';$retained=Join-Path $Game '.pcvrhub_avp2vr_legacy\object.lto'
   if([IO.File]::Exists($obsolete)){
    if([IO.File]::Exists($retained)){if((Get-FileHash -LiteralPath $obsolete).Hash -ne (Get-FileHash -LiteralPath $retained).Hash){throw 'A previous object.lto backup differs from the current file. Keep both files and rename the current vrrez\object.lto before Retry.'};Remove-Item -LiteralPath $obsolete -Force}else{[void][IO.Directory]::CreateDirectory((Split-Path $retained -Parent));Move-Item -LiteralPath $obsolete -Destination $retained}
   }
   $on=Join-Path $Game 'DDraw.dll';$off=$on+'.pcvrhub_off';$flat=-not [IO.File]::Exists($on) -and [IO.File]::Exists($off)
   if($flat){Move-Item -LiteralPath $off -Destination $on}
   try{return Install-OwnedModPayload -SourceRoot $Stage -GameRoot $Game -Identity avp2vr -KeepExistingRelativePaths @('avp2xr.ini','dgVoodoo.conf')}finally{if($flat -and [IO.File]::Exists($on)){Move-Item -LiteralPath $on -Destination $off}}
  }
  'restore'{Restore-PCVRPublisherZipSnapshot -GameRoot $Game -Snapshot $Snapshot;return}
  'remove'{
   $r=Uninstall-OwnedModPayload -GameRoot $Game -Identity avp2vr -ParkedAlternates @{'DDraw.dll'='DDraw.dll.pcvrhub_off'}
   $obsolete=Join-Path $Game 'vrrez\object.lto';$retained=Join-Path $Game '.pcvrhub_avp2vr_legacy\object.lto'
   if([IO.File]::Exists($retained) -and -not [IO.File]::Exists($obsolete)){[void][IO.Directory]::CreateDirectory((Split-Path $obsolete -Parent));Move-Item -LiteralPath $retained -Destination $obsolete}
   if([IO.File]::Exists((Join-Path $Game '.pcvrhub_version'))){Remove-Item -LiteralPath (Join-Path $Game '.pcvrhub_version') -Force};return $r
  }
  'commit'{
   foreach($key in @('LOCALAPPDATA','APPDATA','USERPROFILE','PCVR_HUB_RUNTIME_ROOT','PCVR_HUB_USERDATA_ROOT','PCVR_HUB_STATE_ROOT','PCVR_HUB_TEST_LOCALAPPDATA','PCVR_HUB_TEST_MODE','PCVR_HUB_INSTALL_STATUS_PATH','PCVR_HUB_INSTALL_RUN_ID')){[Environment]::SetEnvironmentVariable($key,[string]$Snapshot.Environment.$key,'Process')}
   foreach($key in @('HubStateRootOverride','HubPortableStateRootOverride','HubLegacyPortableStateRootOverride','HubRuntimeRootOverride','HubLocalAppDataRootOverride')){if($Snapshot.Overrides.$key){Set-Variable -Name $key -Scope Global -Value ([string]$Snapshot.Overrides.$key)}}
   $contract=New-PCVRInstallerContract -Id $script:Avp2Id -GameName 'Aliens versus Predator 2 VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:Avp2Page -RequiredInstalledFileGroups @($script:Avp2Required+'.pcvrhub_avp2vr_ownership.csv')
   [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $Game -Version $Snapshot.Version -InstalledPathReceiptPaths @($Snapshot.Receipt))
  }
 }
}
function Get-Avp2Game($Test){
 if($Test){if(-not(Test-Avp2Base $Test.Game)){throw 'The original game fixture is incomplete.'};return [string]$Test.Game}
 $handoff=Get-PCVRRecoveryInput
 if($handoff){$candidate=if([IO.File]::Exists($handoff)){Split-Path $handoff -Parent}else{$handoff};if(Test-Avp2Base $candidate){[void](Set-PCVRRecoveryInput '');return $candidate}}
 $saved=Get-PCVRRememberedGameFolder -GameId $script:Avp2Id -StateNames @('user_located','base_game_path','installed_path') -ProbeFiles @('AVP2.exe','lithtech.exe','AVP2.rez')
 if(Test-Avp2Base $saved){return $saved}
 foreach($p in @('C:\Program Files (x86)\Fox\Aliens vs. Predator 2','C:\Program Files (x86)\Aliens vs. Predator 2')){if(Test-Avp2Base $p){return $p}}
 while($true){
  Write-Host '  Drop AVP2.exe or its game folder here.' -ForegroundColor White
  Write-Host '  Need the game? Enter D for the Easy Installer download and guided setup.' -ForegroundColor Cyan
  $p=(Read-Host '  Game EXE/folder, D = download, Q = cancel').Trim().Trim('"')
  if($p -ieq 'Q'){throw 'Installation cancelled; your previous files are kept.'}
  if($p -ieq 'D'){Install-Avp2Base;return Get-Avp2Game $Test}
  if([IO.File]::Exists($p) -and [IO.Path]::GetExtension($p) -ieq '.zip'){Install-Avp2Base -Archive $p;return Get-Avp2Game $Test}
  if([IO.File]::Exists($p)){$p=Split-Path $p -Parent}
  if(Test-Avp2Base $p){return [IO.Path]::GetFullPath($p)}
  Write-Host '  This folder needs AVP2.exe, lithtech.exe and AVP2.rez. Choose the complete game.' -ForegroundColor Yellow
 }
}
function Install-Avp2Base {
 param([string]$Archive='')
 if(-not $Archive){
  Write-Host '  On ModDB click Download Now for the Easy Installer ZIP (about 993 MB).' -ForegroundColor White
  Write-Host '  Keep the entire ZIP; setup extracts its resources together.' -ForegroundColor White
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the game download page...');Start-Process $script:Avp2BasePage|Out-Null
  [void](Wait-PCVRExplicitEnter -Message 'After the download has finished, press Enter to find it...')
  $archive=Find-PCVRDownloadedCandidate -Patterns @('AVP2*Easy*Installer*.zip')
 }
 if($archive -and $archive.FullName){$archive=$archive.FullName}
 while(-not $archive -or -not [IO.File]::Exists([string]$archive)){$archive=(Read-Host '  Drag/paste the downloaded Easy Installer ZIP, or Q to cancel').Trim().Trim('"');if($archive -ieq 'Q'){throw 'Game installation cancelled; no VR files were changed.'}}
 $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
 try{
  $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder (Join-Path $work 'base');if(-not $safe.Safe -or -not $safe.Inspectable){throw 'Choose a readable ZIP without unsafe paths.'}
  Write-Host '  Extracting the game installer and its resources; this can take several minutes.' -ForegroundColor Gray
  if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder (Join-Path $work 'base') -Label 'AvP2 Easy Installer' -AllowSkip $false -QuietProgress) -ne 'ok'){throw 'The game installer ZIP could not be extracted.'}
  $exe=@(Get-ChildItem -LiteralPath (Join-Path $work 'base') -Recurse -File|Where-Object Name -eq 'Aliens vs. Predator 2 Easy Installer.exe')
  if($exe.Count -ne 1){throw 'The ZIP needs Aliens vs. Predator 2 Easy Installer.exe and its resources.'}
  Write-Host '  In the Easy Installer:' -ForegroundColor Yellow
  Write-Host '  Aliens Vs Predators 2 installers > Alien Vs Predator 2 > Install AVP 2' -ForegroundColor Yellow
  Write-Host '  Then install the included 1.0.9.6 game update. Finish all setup windows.' -ForegroundColor Yellow
  Write-Host '  Both default folders and custom folders are supported; keep the path you choose.' -ForegroundColor Cyan
  Write-Host '  The game installer requires Windows administrator approval (UAC).' -ForegroundColor Yellow
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the Easy Installer (UAC)...')
  $p=Start-Process -FilePath $exe[0].FullName -WorkingDirectory $exe[0].DirectoryName -Verb RunAs -PassThru
  $processHandle=$p.Handle;$p.WaitForExit()
  if($p.ExitCode -ne 0){throw ('The Easy Installer exited with code '+$p.ExitCode+'. Retry or select your existing game.')}
  [void](Wait-PCVRExplicitEnter -Message 'When the game and 1.0.9.6 patch are fully installed and every setup window is closed, press Enter...')
 }finally{Remove-PCVRInstallerTempSession -Path $work}
}
function Test-Avp2Files([string]$Game,[string]$Phase){
 $missing=@();foreach($group in $script:Avp2Required){$found=$false;foreach($rel in ($group -split '\|')){if([IO.File]::Exists((Join-Path $Game $rel))){$found=$true;break}};Write-PCVRFileCheckResult -Path (Join-Path $Game $group) -Present $found -Phase $Phase -DisplayName $group;if(-not $found){$missing+=$group}};return $missing
}
function Set-Avp2Shortcut([string]$Game,[string]$Desktop,[switch]$Remove){
 $path=Join-Path $Desktop 'Aliens versus Predator 2 VR.lnk';$target=Join-Path $env:WINDIR 'System32\wscript.exe';$args='"'+(Join-Path $Game 'PCVR-Launcher\Start VR.vbs')+'"'
 $shell=New-Object -ComObject WScript.Shell;$link=$shell.CreateShortcut($path)
 if([IO.File]::Exists($path) -and ($link.TargetPath -ine $target -or $link.Arguments -cne $args)){if($Remove){return};throw 'An unrelated desktop shortcut has this name. Rename it before Retry; it was kept.'}
 if($Remove){if([IO.File]::Exists($path)){Remove-Item -LiteralPath $path -Force};return}
 [void][IO.Directory]::CreateDirectory($Desktop);$link.TargetPath=$target;$link.Arguments=$args;$link.WorkingDirectory=$Game;$link.IconLocation=(Join-Path $Game 'AVP2.exe')+',0';$link.Save()
 $check=$shell.CreateShortcut($path);if($check.TargetPath -ine $target -or $check.Arguments -cne $args -or $check.WorkingDirectory -ine $Game -or $check.IconLocation -ine ((Join-Path $Game 'AVP2.exe')+',0')){throw 'Desktop shortcut verification failed.'}
}
function Invoke-Avp2Setup([string]$Folder){
 $test=Get-Avp2Test;$work=$null;$snap=$null;$committed=$false;$changed=$false;$oldLink=$null;$linkChanged=$false
 Write-Host ('='*60) -ForegroundColor Cyan;Write-Host '  Aliens versus Predator 2 VR Installer' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Cyan
 Write-Host '  Original game plus patch 1.0.9.6 required. Setup can guide the free Easy Installer.' -ForegroundColor White
 Write-Host '  Start SteamVR and use Steam Link. Meta Link does not support this 32-bit game.' -ForegroundColor Yellow
 Write-Host '  Close the game before installing or updating. Your saves and edited settings are kept.' -ForegroundColor White
 Show-AntivirusNotice -Compact
 [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to find or install the game...')
 $game=Get-Avp2Game $test;Write-Host ('  Game folder: '+$game) -ForegroundColor Cyan
 if(-not $test -and (Get-Process -Name lithtech,AVP2 -ErrorAction SilentlyContinue)){throw 'Close AvP2 and its launcher, then Retry.'}
 if(-not $test){Write-Host '  Verify that the original game starts in flat and the 1.0.9.6 update is installed.' -ForegroundColor Yellow;[void](Wait-PCVRExplicitEnter -Message 'After the flat check and patch installation, press Enter to continue...')}
 try{
  $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
  if([IO.File]::Exists((Join-Path $game 'vrrez\object.lto'))){Write-Host '  An obsolete VR object.lto must be parked for this release. Its exact file is backed up and restored on removal.' -ForegroundColor Yellow}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current official VR package...')
  if($test){$archive=[string]$test.Package;$version=[string]$test.Version}else{
   $manual=Get-PCVRRecoveryInput -PathType Leaf
   if($manual){$archive=$manual;[void](Set-PCVRRecoveryInput '');do{$version=(Read-Host '  Version on the official release page for this VR ZIP').Trim()}until(Test-IsTrackableInstalledVersion $version)}else{
    $r=Resolve-GitHubReleaseAsset -Repo 'Bassquake/Aliens-Versus-Predator-2-VR' -IncludePrerelease $false -AssetPatterns @('(?i)^avp2vr[-_].+\.zip$') -SkipReleasesWithoutMatchingAsset $true
    if(-not $r.Resolved -or -not $r.Url){throw 'The official VR package could not be resolved. Retry or hand over its downloaded ZIP.'}
    $version=$r.Tag;$archive=Join-Path $work 'vr.zip';[void](Invoke-SafeDownload -Urls @($r.Url) -Destination $archive -Label 'AvP2 VR' -ManualUrl $script:Avp2Page -AllowSkip $false -PlainProgress -FunctionalPayloadOnly)
   }
  }
  if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The VR package version is not trackable.'}
  $stage=Join-Path $work 'stage';$extract=Join-Path $work 'extract'
  $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $extract;if(-not $safe.Safe -or -not $safe.Inspectable){throw 'Choose a readable VR ZIP without unsafe archive paths.'}
  if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'AvP2 VR' -AllowSkip $false -QuietProgress) -ne 'ok'){throw 'The VR ZIP could not be opened.'}
  $deploy=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'vrrez\cshell.dll';if(-not $deploy){throw 'The VR package has no complete deploy folder.'}
  [void][IO.Directory]::CreateDirectory($stage)
  foreach($i in Get-ChildItem -LiteralPath $deploy -Force){if($i.Name -notin @('Uninstall_avp2vr.bat','AVP2VR_(SteamVR_runtime).bat')){Copy-Item -LiteralPath $i.FullName -Destination $stage -Recurse -Force}}
  $launch=Join-Path $stage 'PCVR-Launcher';[void][IO.Directory]::CreateDirectory($launch);Copy-Item -LiteralPath (Join-Path $Folder 'Start-AvP2VR.ps1') -Destination $launch
  $vbs='CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""'+(Join-Path $game 'PCVR-Launcher\Start-AvP2VR.ps1')+'"" -GameDirectory ""'+$game+'""", 0, False'
  [IO.File]::WriteAllText((Join-Path $launch 'Start VR.vbs'),$vbs,[Text.Encoding]::Unicode)
  if(@(Test-Avp2Files $stage 'publisher-payload').Count){throw 'The publisher package is incomplete; no game files were changed.'}
  $snap=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity avp2vr -SnapshotRoot (Join-Path $work 'snapshot') -ExtraPaths @('DDraw.dll.pcvrhub_off','vrrez\object.lto','.pcvrhub_avp2vr_legacy\object.lto')
  $changed=$true;[void](Invoke-Avp2Privileged install $game $stage)
  $missing=@(Test-Avp2Files $game 'immediately-after-copy')
  if($test -and $test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game 'vrrez\cshell.dll') -Force}
  if(-not $test){Write-Host '  Checking that the copied files remain available; this takes a few seconds.' -ForegroundColor Gray;Start-Sleep -Seconds 3}
  $missing=@(Test-Avp2Files $game 'after-observation')
  if($missing.Count){
   if($test){throw 'Required VR files are missing; restoring the previous installation.'}
   Write-Host '  Required files are missing. A copy, permission, path or external-removal problem is possible.' -ForegroundColor Yellow
   $retry={ [void](Test-Avp2Files $game 'before-retry');[void](Invoke-Avp2Privileged install $game $stage);[void](Test-Avp2Files $game 'after-retry') }.GetNewClosure()
   if(-not(Confirm-PlacedFilesSurvive -Paths @($script:Avp2Required|ForEach-Object {Join-Path $game (($_ -split '\|')[0])}) -GameDir $game -WaitSeconds 0 -Recopy $retry -NoClear)){throw 'Installation was not completed. The previous files will be restored.'}
  }
  if(@(Test-Avp2Files $game 'before-commit').Count){throw 'The VR runtime is incomplete.'}
  $desktop=if($test){[string]$test.Desktop}else{[Environment]::GetFolderPath('DesktopDirectory')};$link=Join-Path $desktop 'Aliens versus Predator 2 VR.lnk';if([IO.File]::Exists($link)){$oldLink=[IO.File]::ReadAllBytes($link)}
  Set-Avp2Shortcut $game $desktop;$linkChanged=$true
  $receipt=if($test){$test.Receipt}else{Join-Path $Folder '.installed_path'}
  $environment=@{};foreach($key in @('LOCALAPPDATA','APPDATA','USERPROFILE','PCVR_HUB_RUNTIME_ROOT','PCVR_HUB_USERDATA_ROOT','PCVR_HUB_STATE_ROOT','PCVR_HUB_TEST_LOCALAPPDATA','PCVR_HUB_TEST_MODE','PCVR_HUB_INSTALL_STATUS_PATH','PCVR_HUB_INSTALL_RUN_ID')){$environment[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
  $overrides=@{};foreach($key in @('HubStateRootOverride','HubPortableStateRootOverride','HubLegacyPortableStateRootOverride','HubRuntimeRootOverride','HubLocalAppDataRootOverride')){$v=Get-Variable -Name $key -Scope Global -ErrorAction SilentlyContinue;if($v){$overrides[$key]=$v.Value}}
  [void](Invoke-Avp2Privileged commit $game '' ([pscustomobject]@{Version=$version;Receipt=$receipt;Environment=[pscustomobject]$environment;Overrides=[pscustomobject]$overrides}))
  $committed=$true
  [void](Save-HubRememberedGameFolder -GameId $script:Avp2Id -Title 'Aliens versus Predator 2 VR' -GameDir $game -StateName 'installed_path' -ProbeFiles @('AVP2.exe','lithtech.exe','AVP2.rez'))
  Write-Host ('  [OK] Aliens versus Predator 2 VR '+$version+' installed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
  Write-Host '  Start SteamVR first. Flat / VR restores ordinary flat launch when selected.' -ForegroundColor White
  Write-Host '  Game over, man! Try the other two campaigns.' -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  if($changed -and -not $committed -and $snap){[void](Test-Avp2Files $game 'before-rollback');[void](Invoke-Avp2Privileged restore $game '' $snap);[void](Test-Avp2Files $game 'after-rollback')}
  if($linkChanged -and -not $committed){if($oldLink){[IO.File]::WriteAllBytes($link,$oldLink)}elseif([IO.File]::Exists($link)){Remove-Item -LiteralPath $link -Force}};throw
 }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
