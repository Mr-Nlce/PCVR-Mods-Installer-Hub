param([string]$GameRoot,[switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TeardownVR-Modes.ps1')
if(-not $GameRoot){$record=Join-Path $PSScriptRoot '.installed_path_markos';if([IO.File]::Exists($record)){$GameRoot=[IO.File]::ReadAllText($record).Trim()}}
if(-not $GameRoot){throw 'Select the Teardown game folder for this Markos installation.'}
$GameRoot=Assert-TeardownManagedPath $GameRoot
$profile=Assert-TeardownManagedPath (Get-TeardownMarkosProfile $GameRoot)
if(-not [IO.File]::Exists((Join-Path $profile '.pcvrhub_teardownmarkosprofile_ownership.csv'))){throw 'No Markos ownership record was found. No files were removed.'}
if(Get-Process -Name teardown -ErrorAction SilentlyContinue){throw 'Close Teardown before removing its VR mod.'}
if(-not $HubConfirmed){
 Write-Host 'Remove only unchanged Markos VR files and restore same-name originals. Teardown, saves, personal settings and the other VR mod remain.' -ForegroundColor Yellow
 [void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove this VR choice, or close this window to cancel...')
}
$work=New-PCVRInstallerTempSession -BasePath (Get-TeardownTempBase $GameRoot)
$keep=$false
try{
 $empty=Join-Path $work 'empty';[void][IO.Directory]::CreateDirectory($empty)
 $stages=@{Native=$empty;Lua=$empty}
 $snapshots=@(New-TeardownSwitchSnapshot $GameRoot $work $stages)
 $snapshots+=@{Root=$profile;Snapshot=(Save-PCVRPublisherZipSnapshot -GameRoot $profile -Stage $profile -Identity teardownmarkosprofile -SnapshotRoot (Join-Path $work 'snapshot-profile'))}
 $receipts=@(foreach($name in @('.installed_path_markos','.installed_version_b')){$file=Join-Path $PSScriptRoot $name;@{Path=$file;Bytes=$(if([IO.File]::Exists($file)){[IO.File]::ReadAllBytes($file)}else{$null})}})
 try{
  $native=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity teardownmarkosnative
  $docs=Get-TeardownMarkosDocuments
  if([IO.Directory]::Exists($docs)){$lua=Uninstall-OwnedModPayload -GameRoot $docs -Identity teardownmarkoslua}
  $stored=Uninstall-OwnedModPayload -GameRoot $profile -Identity teardownmarkosprofile
  foreach($p in @((Join-Path $GameRoot '.pcvrhub_version_b'),(Join-Path $PSScriptRoot '.installed_path_markos'),(Join-Path $PSScriptRoot '.installed_version_b'))){
   if([IO.File]::Exists($p)){Remove-Item -LiteralPath $p -Force}
  }
  $active=Join-Path $GameRoot '.pcvrhub_teardown_active'
  if([IO.File]::Exists($active) -and [IO.File]::ReadAllText($active).Trim() -eq 'markos'){
   if($native.Preserved -eq 0 -and (Test-TeardownLegacyProfile $GameRoot)){
    $sound=Join-Path $GameRoot 'dsound.dll';$parked=$sound+'.pcvrhub_teardown_legacy'
    if(-not [IO.File]::Exists($sound) -and [IO.File]::Exists($parked)){Move-Item -LiteralPath $parked -Destination $sound}
    Write-PCVRAtomicText -Path $active -Value 'legacy'
   }else{Remove-Item -LiteralPath $active -Force}
  }
 }catch{
  $problem=$_.Exception.Message
  try{Restore-TeardownSwitchSnapshot $snapshots;foreach($record in $receipts){if($null -ne $record.Bytes){[IO.File]::WriteAllBytes($record.Path,$record.Bytes)}elseif([IO.File]::Exists($record.Path)){Remove-Item -LiteralPath $record.Path -Force}}}catch{$keep=$true;throw ($problem+' '+$_.Exception.Message+' Recovery copy: '+$work)}
  throw $problem
 }
 # Clear only this mod slot. Do not touch legacy path/version A or game data.
 . (Join-Path $PSScriptRoot '..\Modules\HubState.ps1')
 $stateGame=@{Id='teardown-vr';Title='Teardown VR'}
 foreach($name in @('installed_version_b','mod_b_path')){Reset-PersistentGameStateValue -Game $stateGame -Name $name|Out-Null}
 Write-Host 'Markos VR removal finished. Teardown, legacy VR, personal INI files, saves and changed files were preserved.' -ForegroundColor Green
 if($native.Preserved -gt 0 -or $stored.Preserved -gt 0 -or ($lua -and $lua.Preserved -gt 0)){Write-Host 'Modified VR files remain for review; they were not deleted.' -ForegroundColor Yellow}
 if(-not $NoPause){[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close...')}
}finally{if(-not $keep){Remove-PCVRInstallerTempSession -Path $work}}
