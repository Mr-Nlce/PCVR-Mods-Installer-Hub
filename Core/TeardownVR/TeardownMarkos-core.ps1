param([Alias('InstallerChoice')][ValidateSet('markos')][string]$Mod='markos')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TeardownVR-Modes.ps1')
function Get-TeardownMarkosGame {
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_MARKOS_GAME){
  $root=Assert-TeardownManagedPath $env:PCVR_TEARDOWN_MARKOS_GAME
  Assert-TeardownSwitchReady $root
  return $root
 }
 $root=Get-PCVRRememberedGameFolder -GameId 'teardown-vr' -StateNames @('base_game_path','user_located','installed_path') -ProbeFiles @('teardown.exe')
 if($root -and (Test-PCVRGameInstallProof -GameId 'teardown-vr' -Root $root)){return $root}
 foreach($name in @('.installed_path_markos','.installed_path')){
  $file=Join-Path $PSScriptRoot $name
  if([IO.File]::Exists($file)){
   $root=[IO.File]::ReadAllText($file).Trim()
   if($root -and (Test-PCVRGameInstallProof -GameId 'teardown-vr' -Root $root)){return $root}
  }
 }
 $root=Find-SteamGameFolder -AppId '1167630' -SteamFolderNames @('Teardown') -ProbeExe 'teardown.exe' -HubGameId 'teardown-vr'
 if($root -and (Test-PCVRGameInstallProof -GameId 'teardown-vr' -Root $root)){return $root}
 return Get-GameFolderInteractive -GameName 'Teardown' -ProbeFile 'teardown.exe' -ManualUrl 'https://store.steampowered.com/app/1167630/'
}
function Get-TeardownMarkosArchive([string]$Work){
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_MARKOS_ARCHIVE){return Assert-TeardownManagedPath $env:PCVR_TEARDOWN_MARKOS_ARCHIVE}
 $manual=Get-PCVRRecoveryInput -PathType Leaf
 if($manual){[void](Set-PCVRRecoveryInput '');return $manual}
 $r=Resolve-GitHubReleaseAsset -Repo 'markos12900-beep/teardown-vr-mod' -AssetPatterns @('(?i)^TeardownVR-Mod-v[0-9].*\.zip$') -SkipReleasesWithoutMatchingAsset
 if(-not $r.Resolved){throw 'The current Markos Windows ZIP could not be resolved. Use Retry or provide the publisher ZIP.'}
 $zip=Join-Path $Work 'publisher.zip'
 [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the Markos Teardown VR ZIP...')
 $ok=Invoke-SafeDownload -Urls @([string]$r.Url) -Destination $zip -Label ('Teardown VR '+$r.Tag) -ManualUrl ([string]$r.PageUrl) -AllowSkip $false
 if(-not $ok -or -not [IO.File]::Exists($zip)){throw 'The Markos publisher ZIP is unavailable.'}
 return $zip
}
function Invoke-TeardownMarkosInstaller {
 $work=$null;$snapshots=@();$changed=$false;$keepWork=$false
 try{
  Write-Host 'Teardown VR - markos12900-beep' -ForegroundColor Cyan
  Write-Host 'Experimental, single-player only. Current Steam Teardown and SteamVR/OpenXR are required.' -ForegroundColor Yellow
  Write-Host 'The new body, solid hands and legs are not headset-tested by the publisher.' -ForegroundColor Yellow
  Write-Host 'This installs a separate choice; Start in VR activates it. Existing saves, settings and the other VR mod remain.'
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate Teardown...')
  $game=Get-TeardownMarkosGame
  Assert-TeardownSwitchReady $game
  [void](Get-TeardownMarkosDocuments)
  $work=New-PCVRInstallerTempSession -BasePath (Get-TeardownTempBase $game)
  $archive=Get-TeardownMarkosArchive $work
  if(-not(Test-DownloadedPayload -Path $archive -IntendedPath 'publisher.zip')){throw 'Choose a readable publisher ZIP, not a download or login page.'}
  $extract=Join-Path $work 'expanded'
  $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $extract
  if(-not $safe.Inspectable -or -not $safe.Safe){throw 'The ZIP is unreadable or contains unsafe paths. No installation was changed.'}
  $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Markos Teardown VR' -AllowSkip $false
  if([string]$expanded -notin @('ok','manual','retry')){throw 'The publisher ZIP could not be extracted.'}
  $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'dxgi.dll'
  if(-not $payload){throw 'The publisher ZIP has no native Teardown runtime.'}
  foreach($rel in $script:TeardownMarkosFiles){if(-not [IO.File]::Exists((Join-Path $payload $rel))){throw ('Required publisher runtime file is missing: '+$rel)}}
  $version=Get-TeardownMarkosVersion $payload
  $stage=Join-Path $work 'stage';[void][IO.Directory]::CreateDirectory($stage)
  foreach($rel in $script:TeardownMarkosFiles){$to=Join-Path $stage $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $to));Copy-Item -LiteralPath (Join-Path $payload $rel) -Destination $to}
  $preview=Join-Path $payload 'TeardownVR\preview.jpg'
  if([IO.File]::Exists($preview)){Copy-Item -LiteralPath $preview -Destination (Join-Path $stage 'TeardownVR\preview.jpg')}
  Write-PCVRAtomicText -Path (Join-Path $stage '.pcvrhub_version') -Value $version
  $profile=Assert-TeardownManagedPath (Get-TeardownMarkosProfile $game)
  $wasActive=([IO.File]::Exists((Join-Path $game '.pcvrhub_teardown_active')) -and [IO.File]::ReadAllText((Join-Path $game '.pcvrhub_teardown_active')).Trim() -eq 'markos')
  $snapshots+=@{Root=$profile;Snapshot=(Save-PCVRPublisherZipSnapshot -GameRoot $profile -Stage $stage -Identity teardownmarkosprofile -SnapshotRoot (Join-Path $work 'snapshot-profile'))}
  # The publisher profile is installed first; if active, the same transaction
  # also covers the native game and Windows Documents roots before commit.
  $liveStages=@{Native=(Join-Path $work 'live-native');Lua=(Join-Path $work 'live-lua')}
  [void][IO.Directory]::CreateDirectory($liveStages.Native);[void][IO.Directory]::CreateDirectory($liveStages.Lua)
  Copy-Item -LiteralPath (Join-Path $stage 'dxgi.dll') -Destination (Join-Path $liveStages.Native 'dxgi.dll')
  foreach($f in Get-ChildItem -LiteralPath (Join-Path $stage 'TeardownVR') -File){Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $liveStages.Lua $f.Name)}
  [IO.File]::WriteAllText((Join-Path $liveStages.Lua '.pcvrhub_teardown_owner'),[IO.Path]::GetFullPath($game),[Text.UTF8Encoding]::new($false))
  if($wasActive){$snapshots+=New-TeardownSwitchSnapshot $game $work $liveStages}
  $required=@($script:TeardownMarkosFiles+@('.pcvrhub_version'))
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update the selected Teardown VR choice...')
  $changed=$true
  [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $profile -Identity teardownmarkosprofile)
  $initialMissing=@(Write-TeardownMarkosCheckpoint $profile $required 'immediately-after-copy')
  if($initialMissing.Count){throw 'Required files were not copied. Check the path, permissions and log. No antivirus cause has been established.'}
  if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_MARKOS_REMOVE_AFTER_COPY){
   $rel=[string]$env:PCVR_TEARDOWN_MARKOS_REMOVE_AFTER_COPY
   if($rel -notin $required){throw 'Invalid isolated Teardown missing-file case.'}
   Remove-Item -LiteralPath (Join-Path $profile $rel) -Force
  }
  Start-Sleep -Seconds 3
  $missing=@(Write-TeardownMarkosCheckpoint $profile $required 'after-observation')
  if($missing.Count){
   if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'Required files disappeared after copying. No antivirus cause has been established.'}
   $retry={ [void](Write-TeardownMarkosCheckpoint $profile $required 'before-retry');[void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $profile -Identity teardownmarkosprofile);[void](Write-TeardownMarkosCheckpoint $profile $required 'after-retry') }.GetNewClosure()
   if(-not(Confirm-PlacedFilesSurvive -Paths @($required|ForEach-Object{Join-Path $profile $_}) -GameDir $game -Recopy $retry -WaitSeconds 1)){throw 'The required Teardown files are still missing.'}
  }
  if(-not(Test-TeardownMarkosProfile $game)){throw 'The complete Markos Teardown profile could not be verified.'}
  if($wasActive){Set-TeardownVRMode -Game $game -Mod markos}
  $groups=@($required|ForEach-Object{'.pcvrhub_teardown_profiles\markos\'+$_})+@('.pcvrhub_teardown_profiles\markos\.pcvrhub_teardownmarkosprofile_ownership.csv')
  $contract=New-PCVRInstallerContract -Id 'teardown-vr' -GameName 'Teardown VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl 'https://github.com/markos12900-beep/teardown-vr-mod/releases' -Routes @('Steam') -RequiredInstalledFileGroups $groups
  $receipt=Join-Path $PSScriptRoot '.installed_path_markos'
  [void](Write-TeardownMarkosCheckpoint $profile $required 'before-commit')
  [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $version -Route Steam -VersionSlot Secondary -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @((Join-Path $game '.pcvrhub_version_b')) -InstalledVersionReceiptPaths @((Join-Path $PSScriptRoot '.installed_version_b')))
  $changed=$false
  Write-Host ('[OK] Teardown VR '+$version+' installed as a separate choice.') -ForegroundColor Green
  Write-Host '1. Use Start in VR in the Hub, then choose Markos.' -ForegroundColor Yellow
  Write-Host 'Start SteamVR first. In Teardown: Mods > Local files > Teardown VR Mod, enable it and load a level.'
  Write-Host 'Enable only one local or Workshop copy. Disable the old VR mod when using this choice.'
  Write-Host 'Set barrel distortion, motion blur and depth of field off; render scale 100%, head bob 0 and tool sway off.'
  Write-Host ''
  Write-Host 'The next wall is merely a suggestion.' -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
  $global:LASTEXITCODE=0
 }catch{
  $problem=$_.Exception.Message
  if($changed){
   try{if($profile){[void](Write-TeardownMarkosCheckpoint $profile $required 'before-rollback')};Restore-TeardownSwitchSnapshot $snapshots;if($profile){[void](Write-TeardownMarkosCheckpoint $profile $required 'after-rollback')}}catch{$keepWork=$true;throw ($problem+' '+$_.Exception.Message+' Recovery copy: '+$work)}
  }
  throw $problem
 }finally{if($work -and -not $keepWork){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_TEARDOWN_LIBRARY_ONLY -ne '1'){
 while($true){try{Invoke-TeardownMarkosInstaller;break}catch{
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  Write-Host $_.Exception.Message -ForegroundColor Red
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $_.Exception.Message -InstallerFolder $PSScriptRoot)
 }}
}
