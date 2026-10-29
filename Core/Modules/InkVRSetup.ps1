. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')
$script:InkBase=@('Bendy and the Ink Machine.exe','UnityPlayer.dll','GameAssembly.dll','Bendy and the Ink Machine_Data\il2cpp_data\Metadata\global-metadata.dat')
$script:InkProvider=@('Bendy and the Ink Machine_Data\Plugins\x86_64\UnityOpenXR.dll','Bendy and the Ink Machine_Data\Plugins\x86_64\openxr_loader.dll','Bendy and the Ink Machine_Data\UnitySubsystems\UnityOpenXR\UnitySubsystemsManifest.json')
$script:InkFiles=@('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.Unity.IL2CPP.dll','BepInEx\plugins\InkVR\InkVR.dll','InkVR\InkVR Launcher.exe','InkVR\InkVR-Payload\BepInEx\plugins\InkVR\InkVR.dll')+$script:InkProvider
function Get-InkVRTest {
 if($env:PCVR_HUB_TEST_MODE -ne '1' -or -not $env:PCVR_INKVR_TEST){return $null}
 $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\';$path=[IO.Path]::GetFullPath($env:PCVR_INKVR_TEST)
 if(-not $path.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase)){throw 'InkVR test input escaped Temp.'}
 $c=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json;$root=[IO.Path]::GetFullPath($c.Root).TrimEnd('\')+'\'
 if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_inkvr_fixture'))){throw 'Missing isolated InkVR fixture sentinel.'}
 foreach($key in @('Game','Desktop','Receipt')){if(-not ([IO.Path]::GetFullPath([string]$c.$key)).StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'InkVR fixture destination escaped its sentinel.'}}
 return $c
}
function Test-InkVRBase([string]$Root){
 if(-not $Root){return $false};foreach($rel in $script:InkBase){if(-not(Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)){return $false}};return $true
}
function Get-InkVRGame($Test){
 if($Test){if(-not(Test-InkVRBase $Test.Game)){throw 'The isolated Current game is incomplete.'};return [string]$Test.Game}
 $handoff=Get-PCVRRecoveryInput
 if($handoff){
  $selected=$handoff;if(Test-Path -LiteralPath $selected -PathType Leaf){
   switch([IO.Path]::GetFileName($selected)){
    'Bendy and the Ink Machine.exe' {$selected=Split-Path -Parent $selected}
    'InkVR Launcher.exe' {$selected=Split-Path -Parent (Split-Path -Parent $selected)}
    default {$selected=$null}
   }
  }
  if(Test-InkVRBase $selected){
   if(-not(Save-HubRememberedGameFolder -GameId 'bendy-vr' -Title 'Bendy VR' -GameDir $selected -ProbeFiles $script:InkBase -UserSelected)){throw 'The selected recovery game folder could not be saved.'}
   [void](Set-PCVRRecoveryInput '');return $selected
  }
 }
 $saved=Get-PCVRRememberedGameFolder -GameId 'bendy-vr' -StateNames @('installed_path_current','user_located','base_game_path','installed_path') -ProbeFiles $script:InkBase
 if(Test-InkVRBase $saved){return $saved}
 # Both Current and the old Mono depot have the same EXE. Give the shared
 # remembered-location filter a Current-only probe, then validate all base
 # files before accepting its result. A saved depot must not hide Steam.
 try{$steam=Find-SteamGameFolder -AppId '622650' -SteamFolderNames @('Bendy and the Ink Machine') -ProbeExe 'Bendy and the Ink Machine_Data\il2cpp_data\Metadata\global-metadata.dat' -HubGameId 'bendy-vr';if(Test-InkVRBase $steam){return $steam}}catch{Write-Host ('  Automatic Steam search could not finish: '+$_.Exception.Message) -ForegroundColor DarkGray}
 while($true){
  Write-Host '  InkVR requires the current Steam game, not the older Team Beef depot.' -ForegroundColor Yellow
  $answer=(Read-Host '  Drag the current game EXE here, paste its folder, or Q to cancel').Trim().Trim('"').Trim("'")
  if($answer -match '^(?i:q)$'){throw 'Current game selection cancelled.'}
  if(Test-Path -LiteralPath $answer -PathType Leaf){if([IO.Path]::GetFileName($answer) -ine 'Bendy and the Ink Machine.exe'){continue};$answer=Split-Path -Parent $answer}
  if(Test-InkVRBase $answer){
   if(-not(Save-HubRememberedGameFolder -GameId 'bendy-vr' -Title 'Bendy VR' -GameDir $answer -ProbeFiles $script:InkBase -UserSelected)){throw 'The game location could not be saved.'};return [IO.Path]::GetFullPath($answer)
  }
  Write-Host '  Choose the current Steam IL2CPP game. The old Mono build cannot load InkVR.' -ForegroundColor Yellow
 }
}
function Protect-InkVRDepotLocation([string]$InstallerFolder,$Test) {
 # Older Team Beef installs wrote only .installed_path, including custom roots.
 # Preserve a complete Mono runtime before Current replaces that generic value.
 $receipt=if($Test){[string]$Test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
 $proof=@('Bendy and the Ink Machine.exe','UnityPlayer.dll','Bendy and the Ink Machine_Data\Managed\Assembly-CSharp.dll','winhttp.dll','doorstop_config.ini','Bendy and the Ink Machine_Data\Plugins\openvr_api.dll','BendyVRInstall\BendyVRInstall\Mod\BepInEx\core\BepInEx.Preloader.dll','BendyVRInstall\BendyVRInstall\Mod\BepInEx\plugins\BendyVR_5.dll')
 $candidates=@()
 if(Test-Path -LiteralPath $receipt -PathType Leaf){$candidates+=[IO.File]::ReadAllText($receipt).Trim()}
 $candidates+=Get-PCVRRememberedGameFolder -GameId 'bendy-vr' -StateNames @('installed_path_depot','installed_path') -ProbeFiles $proof
 foreach($candidate in @($candidates|Where-Object{$_}|Select-Object -Unique)){
  if(-not(Test-Path -LiteralPath $candidate -PathType Container) -or (Test-Path -LiteralPath (Join-Path $candidate 'GameAssembly.dll'))){continue}
  $complete=$true;foreach($file in $proof){if(-not(Test-Path -LiteralPath (Join-Path $candidate $file) -PathType Leaf)){$complete=$false;break}}
  if(-not $complete){continue}
  $full=[IO.Path]::GetFullPath($candidate).TrimEnd('\')
  if(-not(Save-HubRememberedGameFolder -GameId 'bendy-vr' -Title 'Bendy VR' -GameDir $full -ProbeFiles $proof -StateName 'installed_path_depot')){throw 'The existing Team Beef depot location could not be preserved. No game files were changed.'}
  Write-PCVRAtomicText -Path (Join-Path (Split-Path $receipt) '.installed_path_depot') -Value $full
  Write-Host ('  [OK] Existing Team Beef depot kept: '+$full) -ForegroundColor Green
  return
 }
}
function Expand-InkOpenXRPackage([string]$Archive,[string]$Stage){
 # Read the official gzip/tar format directly. Only the three functional runtime
 # members are copied; no archive path, link or executable extraction is trusted.
 $wanted=@{'package/Runtime/windows/x64/UnityOpenXR.dll'=$script:InkProvider[0];'package/RuntimeLoaders/windows/x64/openxr_loader.dll'=$script:InkProvider[1];'package/Runtime/UnitySubsystemsManifest.json'=$script:InkProvider[2]}
 $input=[IO.File]::OpenRead($Archive);$gzip=[IO.Compression.GZipStream]::new($input,[IO.Compression.CompressionMode]::Decompress);$tar=[IO.MemoryStream]::new()
 try{$gzip.CopyTo($tar);$bytes=$tar.ToArray()}finally{$gzip.Dispose();$input.Dispose();$tar.Dispose()}
 $offset=0;$copied=@{}
 while($offset+512 -le $bytes.Length -and $bytes[$offset] -ne 0){
  $name=[Text.Encoding]::UTF8.GetString($bytes,$offset,100).Split([char]0)[0];$prefix=[Text.Encoding]::UTF8.GetString($bytes,$offset+345,155).Split([char]0)[0]
  if($prefix){$name=$prefix+'/'+$name};$name=$name.Replace('\','/')
  if($name -match '(^/|^[a-zA-Z]:|(^|/)\.\.(/|$))'){throw 'Unsafe Unity package path.'}
  $sizeText=[Text.Encoding]::ASCII.GetString($bytes,$offset+124,12).Trim([char[]]@([char]0,[char]32));$length=[Convert]::ToInt64($sizeText,8);$data=$offset+512
  if($length -lt 0 -or $data+$length -gt $bytes.Length){throw 'Incomplete Unity OpenXR package.'}
  if($wanted.ContainsKey($name)){
   if($bytes[$offset+156] -notin @(0,48) -or $copied.ContainsKey($name)){throw 'Invalid or duplicate Unity runtime member.'}
   $target=Join-Path $Stage $wanted[$name];[void][IO.Directory]::CreateDirectory((Split-Path $target));$file=[IO.File]::Create($target)
   try{$file.Write($bytes,$data,[int]$length)}finally{$file.Dispose()};$copied[$name]=$true
  }
  $offset=$data+[int64]([Math]::Ceiling($length/512.0)*512)
 }
 foreach($name in $wanted.Keys){if(-not $copied.ContainsKey($name)){throw ('Unity package lacks '+$name)}}
}
function Get-InkVRMissing([string]$Game,[string]$Phase){
 $missing=@();foreach($rel in $script:InkFiles){$p=Join-Path $Game $rel;$exists=Test-Path -LiteralPath $p -PathType Leaf;Write-PCVRFileCheckResult -Path $p -Present $exists -Phase $Phase -DisplayName $rel;if(-not $exists){$missing+=$p}};return $missing
}
function Invoke-InkVRSetup([string]$InstallerFolder){
 $ErrorActionPreference='Stop';$test=Get-InkVRTest;$work=$null;$snapshot=$null;$changed=$false;$linkChanged=$false;$oldLink=$null;$keepWork=$false
 try{
  Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Bendy - InkVR for the current Steam game' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Magenta
  Write-Host '  Close Bendy and InkVR Launcher. Your separate Team Beef depot is kept.'
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate current Bendy...')
  $game=Get-InkVRGame $test;Write-Host ('  [OK] Game (Steam): '+$game) -ForegroundColor Green
  if(Get-Process -Name 'Bendy and the Ink Machine','InkVR Launcher' -ErrorAction SilentlyContinue){throw 'Close the game and InkVR launcher, then Retry.'}
  if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The current game folder is not writable.'}
  Protect-InkVRDepotLocation -InstallerFolder $InstallerFolder -Test $test
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the latest InkVR release and Unity OpenXR...')
  $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath());$zip=Join-Path $work 'InkVR.zip';$unity=Join-Path $work 'UnityOpenXR.tgz'
  if($test){Copy-Item -LiteralPath $test.Archive -Destination $zip;Copy-Item -LiteralPath $test.Unity -Destination $unity;$tag=[string]$test.Tag}
  else{
   $manual=Get-PCVRRecoveryInput -PathType Leaf
   if($manual){do{$tag=(Read-Host '  InkVR version shown on its official release page').Trim()}until(Test-IsTrackableInstalledVersion $tag);Copy-Item -LiteralPath $manual -Destination $zip;[void](Set-PCVRRecoveryInput '')}
   else{$r=Resolve-GitHubReleaseAsset -Repo 'StrikeZoneVR-hub/InkVR' -IncludePrerelease $false -AssetPatterns @('(?i)^(?!.*(?:source|symbols|debug))InkVR(?:[-._ ].*)?\.zip$') -SkipReleasesWithoutMatchingAsset;if(-not $r.Resolved -or -not $r.Url -or -not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){throw 'The current InkVR release could not be resolved. Recovery can open the release page and accept its ZIP.'};$tag=[string]$r.Tag;[void](Invoke-SafeDownload -Urls @($r.Url) -Destination $zip -Label ('InkVR '+$tag) -ManualUrl 'https://github.com/StrikeZoneVR-hub/InkVR/releases' -AllowSkip $false -PlainProgress)}
  }
  $unpacked=Join-Path $work 'unpacked';$safe=Test-ZipArchiveEntrySafety -ArchivePath $zip -DestinationFolder $unpacked
  if(-not $safe.Safe -or -not $safe.Inspectable){throw 'The InkVR ZIP is unreadable or contains unsafe paths.'}
  Write-Host '  Extracting the full publisher package; this may take a minute.' -ForegroundColor Gray
  if((Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $unpacked -Label 'InkVR' -AllowSkip $false -QuietProgress) -ne 'ok'){throw 'InkVR could not be extracted.'}
  $launchers=@(Get-ChildItem -LiteralPath $unpacked -Filter 'InkVR Launcher.exe' -File -Recurse);if($launchers.Count -ne 1){throw 'The package must contain one InkVR Launcher with its payload.'}
  $package=Split-Path $launchers[0].FullName;$payload=Join-Path $package 'InkVR-Payload';$stage=Join-Path $work 'stage'
  if(-not(Test-Path -LiteralPath (Join-Path $payload 'BepInEx\plugins\InkVR\InkVR.dll'))){throw 'The publisher InkVR payload is missing.'}
  [void][IO.Directory]::CreateDirectory($stage);Copy-Item -LiteralPath $package -Destination (Join-Path $stage 'InkVR') -Recurse -Force
  Get-ChildItem -LiteralPath $payload -Force|ForEach-Object{Copy-Item -LiteralPath $_.FullName -Destination $stage -Recurse -Force}
  # Read this release's dependency URL from its shipped launcher, rather than
  # silently freezing a future release to the dependency reviewed today.
  $assemblyBytes=[IO.File]::ReadAllBytes($launchers[0].FullName)
  $assemblyText=[Text.Encoding]::Unicode.GetString($assemblyBytes)+[Text.Encoding]::Unicode.GetString($assemblyBytes,1,$assemblyBytes.Length-1)
  $urls=@([regex]::Matches($assemblyText,'https://download\.packages\.unity\.com/com\.unity\.xr\.openxr/-/com\.unity\.xr\.openxr-[0-9.]+\.tgz')|ForEach-Object{$_.Value}|Select-Object -Unique)
  if($urls.Count -ne 1){throw 'This InkVR launcher does not expose one supported Unity OpenXR package URL. No game files were changed.'}
  if(-not $test){[void](Invoke-SafeDownload -Urls @($urls[0]) -Destination $unity -Label 'Unity OpenXR runtime' -ManualUrl $urls[0] -AllowSkip $false -PlainProgress)}
  Expand-InkOpenXRPackage $unity $stage
  foreach($rel in $script:InkFiles){if(-not(Test-Path -LiteralPath (Join-Path $stage $rel) -PathType Leaf)){throw ('The complete package lacks '+$rel)}}
  $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity inkvr -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths @('.pcvrhub_inkvr_version')
  $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$linkPath=Join-Path $desktop 'Bendy InkVR.lnk';$shell=New-Object -ComObject WScript.Shell
  if(Test-Path -LiteralPath $linkPath){$oldLink=[IO.File]::ReadAllBytes($linkPath);if($shell.CreateShortcut($linkPath).TargetPath -ine (Join-Path $game 'InkVR\InkVR Launcher.exe')){throw 'An unrelated desktop shortcut already uses Bendy InkVR. Rename it before Retry.'}}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install InkVR and create its desktop shortcut...')
  $changed=$true
  [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity inkvr -KeepExistingRelativePaths @('BepInEx\config','InkVR\InkVR-Payload\BepInEx\config') -ProgressLabel 'Installing InkVR')
  $missing=@(Get-InkVRMissing $game 'after-copy')
  if($test -and $test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game $script:InkProvider[0]) -Force}
  $missing=@(Get-InkVRMissing $game 'after-mode-preservation');if($missing.Count){throw 'Required InkVR files are missing. Check the target path, copy permissions and installer log; missing files alone do not establish an antivirus cause.'}
  if(-not(Confirm-PlacedFilesSurvive -Paths @($script:InkFiles|ForEach-Object{Join-Path $game $_}) -GameDir $game -NoClear)){throw 'Required InkVR files did not remain available.'}
  if(@(Get-InkVRMissing $game 'after-observation').Count){throw 'Required InkVR files are missing after observation.'}
  $lnk=$shell.CreateShortcut($linkPath);$lnk.TargetPath=Join-Path $game 'InkVR\InkVR Launcher.exe';$lnk.Arguments='--play vr';$lnk.WorkingDirectory=Split-Path $lnk.TargetPath;$lnk.IconLocation=$lnk.TargetPath+',0';$lnk.Description='Bendy and the Ink Machine - InkVR';$linkChanged=$true;$lnk.Save()
  if($test -and $test.Failure -eq 'commit'){throw 'Simulated InkVR commit failure.'}
  $contract=New-PCVRInstallerContract -Id 'bendy-vr' -GameName 'Bendy VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl 'https://github.com/StrikeZoneVR-hub/InkVR/releases' -Routes @('Current') -RequiredInstalledFileGroups (@($script:InkBase)+@($script:InkFiles)+@('.pcvrhub_inkvr_ownership.csv'))
  $receipt=if($test){$test.Receipt}else{Join-Path $InstallerFolder '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $tag -Route Current -InstalledPathReceiptPaths @($receipt,(Join-Path (Split-Path $receipt) '.installed_path_current')) -AdditionalVersionReceiptPaths @((Join-Path $game '.pcvrhub_inkvr_version')))
  $changed=$false
  Write-Host ('  [OK] InkVR '+$tag+' is installed. The Team Beef depot was not changed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub. Alternative: the Bendy InkVR desktop shortcut.' -ForegroundColor Yellow
  Write-Host '  Connect your headset and start its OpenXR runtime first. Keep Steam running.'
  Write-Host '  For flat play or troubleshooting, open InkVR Launcher and choose PLAY WITHOUT VR or VR CHECK.'
  Write-Host '';Write-Host '  Dreams come to life. So does the ink.' -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  if($changed -and $snapshot){[void](Get-InkVRMissing $game 'before-rollback');try{Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot;[void](Get-InkVRMissing $game 'after-rollback')}catch{$keepWork=$true;Write-Host ('  Recovery copy retained: '+$work) -ForegroundColor Red}}
  if($changed -and $linkChanged){if($null -ne $oldLink){[IO.File]::WriteAllBytes($linkPath,$oldLink)}elseif(Test-Path -LiteralPath $linkPath){Remove-Item -LiteralPath $linkPath -Force}}
  throw
 }finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
