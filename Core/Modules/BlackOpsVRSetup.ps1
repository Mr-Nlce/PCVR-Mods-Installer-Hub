. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')
$script:BO1Id='call-of-duty-black-ops-vr'
$script:BO1Title='Call of Duty: Black Ops VR'
$script:BO1Page='https://github.com/BigManLucaVR/BO1VR/releases'
$script:BO1Base=@('BlackOps.exe','main\iw_00.iwd')
$script:BO1Files=@('BO1VR.exe','d3d9.dll','openxr_loader.dll','BO1VR\manifest.json','BO1VR\data\controls.ini','BO1VR\data\bo1vr-poses.bin','BO1VR\data\bo1vr-weapons.bin','BO1VR\data\bo1vr-guns.bin','BO1VR\data\bo1vr-body.bin','BO1VR\data\dxvk\bo1vr-dxvk-d3d9.dll','BO1VR\data\dxvk\wineopenxr.dll')
function Get-BO1VRTest {
 if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_BO1_TEST){return $null}
 $path=[IO.Path]::GetFullPath($env:PCVR_BO1_TEST);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
 if(-not $path.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'Black Ops fixture input escaped Temp.'}
 $c=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json;$root=[IO.Path]::GetFullPath($c.Root).TrimEnd('\')+'\'
 if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_bo1_fixture'))){throw 'Missing isolated Black Ops fixture sentinel.'}
 foreach($name in @('Game','Local','Desktop','Receipt')){if(-not ([IO.Path]::GetFullPath([string]$c.$name)).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Black Ops fixture destination escaped its sentinel.'}}
 return $c
}
function Test-BO1VRBase([string]$Root){
 if(-not $Root){return $false};foreach($rel in $script:BO1Base){if(-not(Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)){return $false}};return $true
}
function Resolve-BO1VRGameInput([string]$InputPath){
 if(-not $InputPath){return $null};$path=$InputPath.Trim().Trim('"').Trim("'")
 if(Test-Path -LiteralPath $path -PathType Leaf){if([IO.Path]::GetFileName($path) -notin @('BlackOps.exe','BlackOpsMP.exe','BO1VR.exe')){return $null};$path=Split-Path -Parent $path}
 if(Test-BO1VRBase $path){return [IO.Path]::GetFullPath($path)};return $null
}
function Get-BO1VRGame($Test){
 if($Test){if(-not(Test-BO1VRBase $Test.Game)){throw 'Black Ops single-player base game is incomplete.'};return [string]$Test.Game}
 $saved=Get-PCVRRememberedGameFolder -GameId $script:BO1Id -StateNames @('user_located','installed_path','base_game_path') -ProbeFiles $script:BO1Base
 if(Test-BO1VRBase $saved){return $saved}
 try{$steam=Find-SteamGameFolder -AppId '42700' -SteamFolderNames @('Call of Duty Black Ops') -ProbeExe 'BlackOps.exe' -HubGameId $script:BO1Id;if(Test-BO1VRBase $steam){return $steam}}catch{}
 while($true){
  Write-Host '  Choose the Steam single-player game. Xbox and multiplayer-only installs are not supported.' -ForegroundColor Yellow
  $answer=Read-Host '  Drag BlackOps.exe here, or paste the Steam game folder (Q cancels)'
  if($answer -match '^(?i:q)$'){throw 'Game selection cancelled.'}
  $game=Resolve-BO1VRGameInput $answer
  if($game -and $game -notmatch '(?i)[\\/]XboxGames[\\/]'){
   if(-not(Save-HubRememberedGameFolder -GameId $script:BO1Id -Title $script:BO1Title -GameDir $game -ProbeFiles $script:BO1Base -UserSelected)){throw 'The selected game path could not be saved.'};return $game
  }
  Write-Host '  Choose the complete Steam single-player folder containing BlackOps.exe and main\iw_00.iwd.' -ForegroundColor Yellow
 }
}
function Get-BO1VRArchive([string]$Work,$Test){
 $archive=Join-Path $Work 'BO1VR.zip'
 if($Test){Copy-Item -LiteralPath $Test.Archive -Destination $archive -ErrorAction Stop;return @{Path=$archive;Tag=[string]$Test.Tag}}
 $manual=Get-PCVRRecoveryInput -PathType Leaf
 if($manual){
  do{$tag=(Read-Host '  Version shown on the official BO1VR release page').Trim()}until(Test-IsTrackableInstalledVersion $tag)
  Copy-Item -LiteralPath $manual -Destination $archive -ErrorAction Stop;[void](Set-PCVRRecoveryInput '');return @{Path=$archive;Tag=$tag}
 }
 $release=Resolve-GitHubReleaseAsset -Repo 'BigManLucaVR/BO1VR' -IncludePrerelease $true -AssetPatterns @('(?i)^BO1VR.*\.zip$') -SkipReleasesWithoutMatchingAsset
 if(-not $release.Resolved -or -not $release.Url -or -not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){throw 'The current BO1VR release could not be resolved. Recovery can open its official release page and accept the downloaded ZIP.'}
 [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label ('BO1VR '+$release.Tag) -ManualUrl $script:BO1Page -AllowSkip $false -PlainProgress)
 return @{Path=$archive;Tag=[string]$release.Tag}
}
function Get-BO1VRMissing([string]$Game,[string]$Phase){
 $missing=@();foreach($rel in $script:BO1Files){
  $path=Join-Path $Game $rel;$present=Test-Path -LiteralPath $path -PathType Leaf
  if($rel -eq 'd3d9.dll' -and -not $present){$present=Test-Path -LiteralPath ($path+'.pcvrhub_off') -PathType Leaf}
  Write-PCVRFileCheckResult -Path $path -Present $present -Phase $Phase -DisplayName $rel
  if(-not $present){$missing+=$path}
 };return $missing
}
function Invoke-BO1Publisher([string]$File,[string]$Directory,[string[]]$Arguments=@(),[switch]$Hidden){
 # Redirected progress/stderr is neutral output; only the actual exit decides.
 $start=@{FilePath=$File;WorkingDirectory=$Directory;Wait=$true;PassThru=$true;ErrorAction='Stop'}
 if($Arguments.Count){$start.ArgumentList=$Arguments}
 if($Hidden){$start.WindowStyle='Hidden'}
 $process=Start-Process @start
 if($null -eq $process -or $null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw ('BO1VR publisher program failed (exit '+$process.ExitCode+').')}
}
function Invoke-BO1VRSetup([string]$InstallerFolder){
 $ErrorActionPreference='Stop';$test=Get-BO1VRTest;$work=$null;$snapshot=$null;$changed=$false;$linkChanged=$false;$oldLink=$null;$linkPath=$null;$keepWork=$false
 try{
  Write-Host ('='*60) -ForegroundColor Magenta
  Write-Host '  Call of Duty: Black Ops VR - Installer' -ForegroundColor Cyan
  Write-Host '  Steam single player; Campaign and Zombies; OpenXR' -ForegroundColor Yellow
  Write-Host ('='*60) -ForegroundColor Magenta
  Write-Host '  Close Black Ops and BO1VR before installing or updating. Saves and settings are kept.'
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Black Ops...')
  $game=Get-BO1VRGame $test
  if($game -match '(?i)[\\/]XboxGames[\\/]'){throw 'BO1VR requires the Steam version. No Xbox files were changed.'}
  Write-Host ('  [OK] Game (Steam): '+$game) -ForegroundColor Green
  if(Get-Process -Name BlackOps,BlackOpsMP,BO1VR -ErrorAction SilentlyContinue){throw 'Close Black Ops and the BO1VR launcher, then Retry.'}
  if(-not(Test-InstallerTargetWritable $game)){throw 'The selected game folder is not writable.'}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest BO1VR release...')
  $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath());$a=Get-BO1VRArchive $work $test
  $stage=Join-Path $work 'payload';$safe=Test-ZipArchiveEntrySafety -ArchivePath $a.Path -DestinationFolder $stage
  if(-not $safe.Safe -or -not $safe.Inspectable){throw 'The publisher ZIP is unreadable or has unsafe paths.'}
  Write-Host '  Extracting and checking the complete publisher package; this may take a minute.' -ForegroundColor Gray
  if((Expand-ArchiveOrFallback -ArchivePath $a.Path -DestinationFolder $stage -Label 'BO1VR' -AllowSkip $false -QuietProgress) -ne 'ok'){throw 'The BO1VR ZIP could not be extracted.'}
  Write-Host '  [OK] Publisher ZIP extracted.' -ForegroundColor Green
  foreach($rel in $script:BO1Files){if(-not(Test-Path -LiteralPath (Join-Path $stage $rel) -PathType Leaf)){throw ('Publisher package lacks '+$rel)}}
  $manifest=Get-Content -LiteralPath (Join-Path $stage 'BO1VR\manifest.json') -Raw|ConvertFrom-Json
  if(-not $manifest.version){throw 'Publisher package does not report a component version.'}
  $parked=Test-Path -LiteralPath (Join-Path $game 'd3d9.dll.pcvrhub_off') -PathType Leaf
  if($parked -and (Test-Path -LiteralPath (Join-Path $game 'd3d9.dll'))){throw 'Both active and parked graphics proxies exist. Resolve the conflict before Retry; neither was overwritten.'}
  $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity 'bo1vr' -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths @('d3d9.dll.pcvrhub_off')
  $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$linkPath=Join-Path $desktop 'Call of Duty Black Ops VR.lnk'
  $shell=New-Object -ComObject WScript.Shell
  if(Test-Path -LiteralPath $linkPath){$oldLink=[IO.File]::ReadAllBytes($linkPath);$previous=$shell.CreateShortcut($linkPath);if($previous.TargetPath -ine (Join-Path $game 'BO1VR.exe')){throw 'A different desktop shortcut already uses this name. Rename it, then Retry; it has been kept.'}}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the full VR package and its desktop shortcut...')
  $changed=$true
  if($parked){Move-Item -LiteralPath (Join-Path $game 'd3d9.dll.pcvrhub_off') -Destination (Join-Path $game 'd3d9.dll') -ErrorAction Stop}
  [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'bo1vr' -KeepExistingRelativePaths @('BO1VR\data\controls.ini') -ProgressLabel 'Installing Black Ops VR')
  if($parked){Move-Item -LiteralPath (Join-Path $game 'd3d9.dll') -Destination (Join-Path $game 'd3d9.dll.pcvrhub_off') -ErrorAction Stop}
  $missing=@(Get-BO1VRMissing $game 'after-copy');if($test -and $test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game 'openxr_loader.dll') -Force}
  $missing=@(Get-BO1VRMissing $game 'after-mode-preservation')
  if($missing.Count){throw ('Required files are missing: '+($missing -join ', ')+'. Inspect the target path and installer log; a missing file alone does not establish an antivirus cause.')}
  $observed=@($script:BO1Files|ForEach-Object{if($_ -eq 'd3d9.dll' -and $parked){Join-Path $game 'd3d9.dll.pcvrhub_off'}else{Join-Path $game $_}})
  if(-not(Confirm-PlacedFilesSurvive -Paths $observed -GameDir $game -NoClear)){throw 'Required BO1VR files did not remain available. Review the file checks and Retry.'}
  if(@(Get-BO1VRMissing $game 'after-observation').Count){throw 'Required BO1VR files are missing after observation.'}
  $link=$shell.CreateShortcut($linkPath);$link.TargetPath=Join-Path $game 'BO1VR.exe';$link.WorkingDirectory=$game;$link.IconLocation=$link.TargetPath+',0';$link.Description='Black Ops VR - choose Launch game';$linkChanged=$true;$link.Save()
  if($test -and $test.Failure -eq 'commit'){throw 'Simulated commit failure.'}
  $proof=@($script:BO1Base)+@($script:BO1Files|ForEach-Object{if($_ -eq 'd3d9.dll'){'d3d9.dll|d3d9.dll.pcvrhub_off'}else{$_}})+@('.pcvrhub_bo1vr_ownership.csv')
  $contract=New-PCVRInstallerContract -Id $script:BO1Id -GameName $script:BO1Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:BO1Page -Routes @('Steam') -RequiredInstalledFileGroups $proof
  $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $a.Tag -Route Steam -InstalledPathReceiptPaths @($receipt))
  $changed=$false
  Write-Host ('  [OK] Black Ops VR '+$a.Tag+' is installed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub, then choose Launch game in the BO1VR launcher.' -ForegroundColor Yellow
  Write-Host '  Alternative: use the Call of Duty Black Ops VR desktop shortcut, then Launch game.'
  Write-Host '  On first launch the publisher prepares the mod. Wait for it to finish.' -ForegroundColor Yellow
  Write-Host '  Connect your headset and select its active OpenXR runtime first. SteamVR needs 2.17 or newer.'
  Write-Host '  Choose Campaign or Zombies in the game. Multiplayer is not supported.'
  Write-Host ''
  Write-Host '  The numbers, Mason! They were not your refresh rate.' -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  if($changed -and $snapshot){[void](Get-BO1VRMissing $game 'before-rollback');try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot;[void](Get-BO1VRMissing $game 'after-rollback')}catch{$keepWork=$true;Write-Host ('  Recovery copy retained: '+$work) -ForegroundColor Red}}
  if($linkChanged){if($oldLink){[IO.File]::WriteAllBytes($linkPath,$oldLink)}elseif(Test-Path -LiteralPath $linkPath){Remove-Item -LiteralPath $linkPath -Force}}
  throw
 }finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
function Invoke-BO1VRUninstall([string]$InstallerFolder,[switch]$HubConfirmed){
 $ErrorActionPreference='Stop';$test=Get-BO1VRTest;$game=Get-BO1VRGame $test
 if(Get-Process -Name BlackOps,BlackOpsMP,BO1VR -ErrorAction SilentlyContinue){throw 'Close Black Ops and BO1VR before removal.'}
 if(-not $HubConfirmed -and (Read-Host 'Remove Black Ops VR? Type REMOVE') -cne 'REMOVE'){return}
 # The publisher has its own backup of game settings and generated files.
 # Let it restore these before the Hub reverses its file ownership plan.
 if(-not $test){
  Write-Host '  In BO1VR, click the beta version at the bottom right, then Uninstall.' -ForegroundColor Yellow
  Write-Host '  Leave Also delete my settings unchecked to keep your settings. Finish removal, then close BO1VR.' -ForegroundColor Yellow
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open BO1VR for publisher removal...')
  $launcher=Join-Path $game 'BO1VR.exe';if(-not(Test-Path -LiteralPath $launcher)){throw 'BO1VR.exe is missing. Repair the publisher package first so its backups can be restored.'}
  Invoke-BO1Publisher -File $launcher -Directory $game
  if((Read-Host '  Did publisher Uninstall finish? Y/N').Trim() -notmatch '^(?i:y|yes)$'){throw 'Publisher removal was not confirmed. No Hub-owned files were removed.'}
 }
 [void](Uninstall-OwnedModPayload -GameRoot $game -Identity 'bo1vr' -ParkedAlternates @{'d3d9.dll'='d3d9.dll.pcvrhub_off'})
 $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$path=Join-Path $desktop 'Call of Duty Black Ops VR.lnk'
 if(Test-Path -LiteralPath $path){$link=(New-Object -ComObject WScript.Shell).CreateShortcut($path);if($link.TargetPath -ieq (Join-Path $game 'BO1VR.exe')){Remove-Item -LiteralPath $path -Force}}
 foreach($path in @((Join-Path $game '.pcvrhub_version'),$(if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}))){if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}}
 Write-Host '  [OK] Hub-owned BO1VR files removed; saves and edited or generated settings retained.' -ForegroundColor Green
}
