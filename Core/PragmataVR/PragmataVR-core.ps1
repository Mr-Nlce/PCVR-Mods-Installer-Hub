param([ValidateSet('','modern','legacy')][string]$Mod='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'Pragmata-Profiles.ps1')
function Invoke-PragmataSetup {
 $test=Get-PublisherVRTestContext;$work=$null;$changed=$false;$keepWork=$false
 try{
  Write-Host ('='*60) -ForegroundColor Cyan;Write-Host '  PRAGMATA VR Installer' -ForegroundColor Cyan;Write-Host ('='*60) -ForegroundColor Cyan
  Write-Host '  [1] Pragmata VR by scubasteve - rebuilt VR HUD, Native / AFW, gamepad'
  Write-Host '  [2] Legacy REFramework by praydog - original general VR support'
  Write-Host '  Setup prepares your chosen mod. Use its Hub Play button to activate it.'
  Write-Host '  Close PRAGMATA. Your saves, per-headset settings and other scripts are kept.'
  Show-AntivirusNotice -Compact
  $selected=$Mod;if(-not $selected -and $env:PCVR_HUB_INSTALLER_CHOICE -in @('modern','legacy')){$selected=$env:PCVR_HUB_INSTALLER_CHOICE};if(-not $selected){do{$choice=(Read-Host '  Choose 1 or 2 (Enter = 1)').Trim()}while($choice -notin @('','1','2'));$selected=if($choice -eq '2'){'legacy'}else{'modern'}}
  [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate PRAGMATA...')
  $p=@{Id='pragmata-vr';GameFolder='PRAGMATA';Exe='PRAGMATA.exe';App='3357650';Key='Pragmata'}
  . (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
  $game=Get-OctoberNativeGame $p $test;Assert-PragmataClosed
  Write-Host ('  Game folder: '+$game) -ForegroundColor Cyan
  if(-not(Test-InstallerTargetWritable $game)){throw 'The game folder is not writable.'}
  if($selected -eq 'modern'){
   Write-Host '  Requires Steam game 1.3.0.0. Use Windowed display mode; start OpenXR before playing.' -ForegroundColor Yellow
   $v=[Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $game 'PRAGMATA.exe')).FileVersion
   if($v -and $v -notmatch '^1\.3\.0\.0(?:\D|$)'){throw ('This Pragmata VR release targets game 1.3.0.0; your EXE reports '+$v+'. Update the game in Steam first.')}
   Write-Host '  Old community HUD scripts are backed up when this mod is activated; Legacy restores them.'
  }
  $work=New-PCVRInstallerTempSession -BasePath $(if($test){$test.Root}else{[IO.Path]::GetTempPath()})
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download your selected VR package...')
  $stage=Join-Path $work 'stage';$storeStage=Join-Path $stage ('_vrmods\pragmata\'+$selected);[void][IO.Directory]::CreateDirectory($storeStage)
  if($selected -eq 'modern'){
   $repo='scubasteve2365/Pragmata-VR';$manual=if(-not $test){Get-PCVRRecoveryInput -PathType Leaf}else{''}
   if($test){$a=@{Path=$test.Archives.Main.Path;Tag=$test.Archives.Main.Tag}}
   elseif($manual -and [IO.Path]::GetExtension($manual) -ieq '.zip'){$a=@{Path=$manual;Tag=''};[void](Set-PCVRRecoveryInput '')}
   else{$r=Resolve-GitHubReleaseAsset -Repo $repo -IncludePrerelease $true -AssetPatterns @('(?i)^PragmataVR_.*\.zip$') -SkipReleasesWithoutMatchingAsset;if(-not $r.Resolved){throw 'The official Pragmata VR release could not be found. Retry or hand over its ZIP.'};$zip=Join-Path $work 'modern.zip';[void](Invoke-SafeDownload -Urls @($r.Url) -Destination $zip -Label 'Pragmata VR' -ManualUrl ('https://github.com/'+$repo+'/releases') -AllowSkip $false -PlainProgress -FunctionalPayloadOnly);$a=@{Path=$zip;Tag=$r.Tag}}
   $out=Expand-PublisherVRArchive $a (Join-Path $work 'modern');$payload=Find-PublisherVRPayload $out 'PragmataVR_README.txt';Get-ChildItem -LiteralPath $payload -Force|Copy-Item -Destination $storeStage -Recurse -Force
   $version=[string]$a.Tag
   if(-not $version){$version=Read-Host '  Version from the official release page (the bundled README can describe an older release)'}
   $required=@('dinput8.dll','openxr_loader.dll','PDAFWPlugin.dll','PragmataVR_README.txt');$slot='Secondary'
  }else{
   $repo='praydog/REFramework-nightly'
   $a=Get-PublisherVRArchive -Repo $repo -Patterns @('(?i)^REFramework\.zip$') -Label 'REFramework' -Work $work -Test $test -TestKey Main -FunctionalProbe 'dinput8.dll' -PlainProgress
   $b=Get-PublisherVRArchive -Repo $repo -Patterns @('(?i)^VR\.zip$') -Label 'REFramework VR support' -Work $work -Test $test -TestKey VR -FunctionalProbe 'openxr_loader.dll' -PlainProgress
   # Both components must come from the same live release; no mixed nightly payload.
   if($a.Tag -and $b.Tag -and $a.Tag -ne $b.Tag){throw 'The nightly changed during download. Retry both files together.'}
   foreach($component in @($a,$b)){$out=Expand-PublisherVRArchive $component (Join-Path $work ([guid]::NewGuid().ToString('N')));$probe=if($component -eq $a){'dinput8.dll'}else{'openxr_loader.dll'};$payload=Find-PublisherVRPayload $out $probe;Get-ChildItem -LiteralPath $payload -Force|Copy-Item -Destination $storeStage -Recurse -Force}
   $version=[string]$a.Tag;if(-not $version){$version=Read-Host '  Full nightly tag from the official release page'}
   $required=@('dinput8.dll','openxr_loader.dll');$slot='Primary'
  }
  if(-not(Test-IsTrackableInstalledVersion $version)){throw 'The publisher package has no trackable version.'}
  foreach($rel in $required){if(-not[IO.File]::Exists((Join-Path $storeStage $rel))){throw ('The selected VR ZIP is missing '+$rel)}}
  $linksStage=Join-Path $work 'links';Set-PragmataLaunchers $linksStage
  $prefix='_vrmods\pragmata\'+$selected+'\';$groups=@($required|ForEach-Object{$prefix+$_})+@('_vrmods\pragmata\launch\modern.vbs','_vrmods\pragmata\launch\legacy.vbs','_vrmods\pragmata\launch\Pragmata-Profiles.ps1','_vrmods\pragmata\launch\OwnedModFiles.ps1','_vrmods\pragmata\launch\PublisherZipTransaction.ps1')
  $identity='pragmata'+$selected
  $installGroups=@((New-PublisherVRGroup $game $stage $identity @($required|ForEach-Object{$prefix+$_})),(New-PublisherVRGroup $game $linksStage 'pragmatalinks' @($groups|Where-Object{$_ -like '*\launch\*'})))
  $contract=New-PCVRInstallerContract -Id 'pragmata-vr' -GameName 'Pragmata VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$repo+'/releases') -RequiredInstalledFileGroups @($installGroups|ForEach-Object{$_.Required}) -Routes @('modern','legacy')
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to prepare this VR mod and keep the currently active mod...')
  Write-Host '  Backing up and preparing the selected VR mod. This may take a minute.' -ForegroundColor Cyan
  Import-PragmataLegacy $game
  foreach($g in $installGroups){$g.Snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $g.Stage -Identity $g.Identity -SnapshotRoot (Join-Path $work ('rollback-'+$g.Identity)) -ExtraPaths @('.pcvrhub_version_b',($prefix+'.pcvrhub_version'))}
  $changed=$true
  foreach($g in $installGroups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $game -Identity $g.Identity)}
  if($test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $game $groups[0]) -Force}
  if(@(Write-PublisherVRCheckpoint $installGroups 'immediately-after-copy').Count){throw 'Required VR files were not copied. Check the folder, permissions and log.'}
  Write-Host '  Checking the prepared VR files; this takes a few seconds.';Start-Sleep -Seconds 3
  if($test.Failure -eq 'vanish'){Remove-Item -LiteralPath (Join-Path $game $groups[0]) -Force}
  if(@(Write-PublisherVRCheckpoint $installGroups 'after-observation').Count){$read=if($test){{'Q'}}else{$null};$recopy={ [void](Write-PublisherVRCheckpoint $installGroups 'before-retry');foreach($g in $installGroups){[void](Install-OwnedModPayload -SourceRoot $g.Stage -GameRoot $game -Identity $g.Identity)};[void](Write-PublisherVRCheckpoint $installGroups 'after-retry') }.GetNewClosure();if(-not(Confirm-PlacedFilesSurvive -Paths @($groups|ForEach-Object{Join-Path $game $_}) -GameDir $game -WaitSeconds 0 -ReadInput $read -Recopy $recopy -NoClear)){throw 'Prepared files disappeared. The previous mod is being restored.'}}
  if(@(Write-PublisherVRCheckpoint $installGroups 'before-commit').Count){throw 'The prepared profile is incomplete.'}
  if($test.Failure -eq 'commit'){throw 'Isolated commit failure.'}
  $receipt=if($test){$test.Receipt}else{Join-Path $PSScriptRoot '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -VersionSlot $slot -AdditionalVersionReceiptPaths @((Join-Path $game ($prefix+'.pcvrhub_version'))) -InstalledPathReceiptPaths @($receipt) -Route $selected)
  $changed=$false
  Write-Host ('  [OK] '+$selected+' '+$version+' prepared.') -ForegroundColor Green;Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor Green
  Write-Host '  Choose the matching mod button. OpenXR must be running; play in Windowed mode.'
  Write-Host '  Modern: click both sticks or F1 for the VR HUD and Native / AFW options.'
  Write-Host ''
  Write-Host '  Hack the moon. Hold her hand. Step into the unknown.' -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{$failure=$_;if($changed){[void](Write-PublisherVRCheckpoint $installGroups 'before-rollback');try{for($i=$installGroups.Count-1;$i -ge 0;$i--){Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $installGroups[$i].Snapshot};[void](Write-PublisherVRCheckpoint $installGroups 'after-rollback')}catch{$keepWork=$true;Write-Host ('  Recovery files: '+$work)}};throw $failure}
 finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession $work}}
}
while($true){try{Invoke-PragmataSetup;break}catch{$message='Pragmata VR setup did not complete: '+$_.Exception.Message;Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'pragmata-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/scubasteve2365/Pragmata-VR/releases')}}
