. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
. (Join-Path $PSScriptRoot '..\Modules\TeardownProof.ps1')
$script:TeardownMarkosFiles=@('dxgi.dll','TeardownVR\main.lua','TeardownVR\info.txt','TeardownVR\hands_glove.vox','TeardownVR\hands_skin.vox','TeardownVR\hands_blocky.vox')
function Assert-TeardownManagedPath([string]$Path){
 $full=[IO.Path]::GetFullPath($Path).TrimEnd('\','/')
 if($full -eq [IO.Path]::GetPathRoot($full).TrimEnd('\','/')){throw 'A drive root is not a Teardown target.'}
 if($env:PCVR_HUB_TEST_MODE -eq '1'){
  $boundary=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+'\'
  if(-not $full.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'Teardown test target escaped the temporary fixture.'}
  $parent=$full;$sentinel=$false
  while($parent -and $parent.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){
   if([IO.File]::Exists((Join-Path $parent '.pcvr-teardown-fixture')) -or [IO.File]::Exists((Join-Path $parent '.sentinel')) -or [IO.File]::Exists((Join-Path $parent '.pcvr-rust-fixture'))){$sentinel=$true;break}
   $parent=[IO.Path]::GetDirectoryName($parent)
  }
  if(-not $sentinel){throw 'The isolated Teardown sentinel is missing.'}
 }
 $ancestor=$full
 while($ancestor){
  if([IO.File]::Exists($ancestor) -or [IO.Directory]::Exists($ancestor)){
   if([IO.File]::GetAttributes($ancestor) -band [IO.FileAttributes]::ReparsePoint){throw 'Linked Teardown paths need manual handling.'}
  }
  $ancestor=[IO.Path]::GetDirectoryName($ancestor)
 }
 return $full
}
function Get-TeardownMarkosProfile([string]$Game){Join-Path $Game '.pcvrhub_teardown_profiles\markos'}
function Get-TeardownTempBase([string]$Game){
 if($env:PCVR_HUB_TEST_MODE -eq '1'){
  [void](Assert-TeardownManagedPath $Game)
  $parent=[IO.Path]::GetFullPath($Game)
  while($parent){if([IO.File]::Exists((Join-Path $parent '.pcvr-teardown-fixture')) -or [IO.File]::Exists((Join-Path $parent '.sentinel')) -or [IO.File]::Exists((Join-Path $parent '.pcvr-rust-fixture'))){return $parent};$parent=[IO.Path]::GetDirectoryName($parent)}
  throw 'The isolated Teardown temp boundary is unavailable.'
 }
 return [IO.Path]::GetTempPath()
}
function Get-TeardownMarkosDocuments {
 $docs=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEARDOWN_MARKOS_DOCUMENTS){$env:PCVR_TEARDOWN_MARKOS_DOCUMENTS}else{[Environment]::GetFolderPath('MyDocuments')}
 if(-not $docs){throw 'The Windows Documents folder is unavailable. No Teardown files were changed.'}
 return Assert-TeardownManagedPath (Join-Path $docs 'Teardown\mods\TeardownVR')
}
function Get-TeardownMarkosVersion([string]$Payload){
 $version=Get-PCVRTeardownMarkosVersion -Root $Payload
 if(-not $version){throw 'The native Teardown runtime is missing, unusable or has no trackable publisher version.'}
 return $version
}
function Test-TeardownMarkosProfile([string]$Game){
 $profile=Get-TeardownMarkosProfile $Game
 foreach($rel in $script:TeardownMarkosFiles+@('.pcvrhub_version')){
  $file=Join-Path $profile $rel
  if(-not [IO.File]::Exists($file) -or (Get-Item -LiteralPath $file).Length -eq 0){return $false}
  [void](Assert-TeardownManagedPath $file)
 }
 return Test-PCVRTeardownProfile -GameRoot $Game -Slot B
}
function Get-TeardownLegacyProxy([string]$Game){
 foreach($rel in @('dsound.dll','dsound.dll.pcvrhub_teardown_legacy')){
  $p=Join-Path $Game $rel
  if([IO.File]::Exists($p)){
   try{if([Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($p)).Contains('TDVR1')){return $p}}catch{}
  }
 }
 return $null
}
function Test-TeardownLegacyProfile([string]$Game){
 return Test-PCVRTeardownProfile -GameRoot $Game -Slot A
}
function Assert-TeardownSwitchReady([string]$Game){
 [void](Assert-TeardownManagedPath $Game)
 if(-not(Test-PCVRGameInstallProof -GameId 'teardown-vr' -Root $Game)){throw 'A complete original Teardown game is required.'}
 if(Get-Process -Name teardown -ErrorAction SilentlyContinue){throw 'Close Teardown before installing or switching VR mods.'}
 if(-not(Test-InstallerTargetWritable -TargetPath $Game)){throw 'The Teardown game folder is not writable.'}
}
function New-TeardownMarkosStages([string]$Game,[string]$Work){
 $profile=Get-TeardownMarkosProfile $Game
 $native=Join-Path $Work 'native';$lua=Join-Path $Work 'lua'
 [void][IO.Directory]::CreateDirectory($native);[void][IO.Directory]::CreateDirectory($lua)
 Copy-Item -LiteralPath (Join-Path $profile 'dxgi.dll') -Destination (Join-Path $native 'dxgi.dll') -Force
 foreach($file in Get-ChildItem -LiteralPath (Join-Path $profile 'TeardownVR') -File){Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $lua $file.Name) -Force}
 [IO.File]::WriteAllText((Join-Path $lua '.pcvrhub_teardown_owner'),[IO.Path]::GetFullPath($Game),[Text.UTF8Encoding]::new($false))
 return @{Native=$native;Lua=$lua}
}
function New-TeardownSwitchSnapshot([string]$Game,[string]$Work,$Stages){
 $docs=Get-TeardownMarkosDocuments
 $owner=Join-Path $docs '.pcvrhub_teardown_owner'
 if([IO.File]::Exists($owner) -and -not [IO.File]::ReadAllText($owner).Trim().Equals([IO.Path]::GetFullPath($Game),[StringComparison]::OrdinalIgnoreCase)){
  throw 'The local Teardown Lua mod belongs to another game installation. Its files were not changed.'
 }
 foreach($item in @(@{Root=$Game;Stage=$Stages.Native;Identity='teardownmarkosnative'},@{Root=$docs;Stage=$Stages.Lua;Identity='teardownmarkoslua'})){
  [void](Assert-TeardownManagedPath $item.Root)
  $manifest=Join-Path $item.Root ('.pcvrhub_'+$item.Identity+'_ownership.csv')
  if([IO.File]::Exists($manifest)){foreach($row in Import-Csv -LiteralPath $manifest){[void](Assert-TeardownManagedPath (Join-OwnedRelativePath -Root $item.Root -Relative $row.RelativePath))}}
  foreach($file in Get-ChildItem -LiteralPath $item.Stage -File -Recurse){$relative=$file.FullName.Substring($item.Stage.Length+1);[void](Assert-TeardownManagedPath (Join-OwnedRelativePath -Root $item.Root -Relative $relative))}
  $backup=Join-Path $item.Root ('.pcvrhub_'+$item.Identity+'_backup')
  [void](Assert-TeardownManagedPath $backup)
  if([IO.Directory]::Exists($backup)){foreach($file in Get-ChildItem -LiteralPath $backup -Recurse -Force){if($file.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked Teardown backup files need manual handling.'}}}
 }
 return @(
  @{Root=$Game;Snapshot=(Save-PCVRPublisherZipSnapshot -GameRoot $Game -Stage $Stages.Native -Identity teardownmarkosnative -SnapshotRoot (Join-Path $Work 'snapshot-native') -ExtraPaths @('dsound.dll','dsound.dll.pcvrhub_teardown_legacy','.pcvrhub_teardown_active','.pcvrhub_version_b'))},
  @{Root=$docs;Snapshot=(Save-PCVRPublisherZipSnapshot -GameRoot $docs -Stage $Stages.Lua -Identity teardownmarkoslua -SnapshotRoot (Join-Path $Work 'snapshot-lua'))}
 )
}
function Restore-TeardownSwitchSnapshot($Snapshots){
 $errors=@()
 for($i=$Snapshots.Count-1;$i -ge 0;$i--){try{Restore-PCVRPublisherZipSnapshot -GameRoot $Snapshots[$i].Root -Snapshot $Snapshots[$i].Snapshot}catch{$errors+=$_.Exception.Message}}
 if($errors.Count){throw ('Teardown rollback needs attention: '+($errors -join '; '))}
}
function Write-TeardownMarkosCheckpoint([string]$Root,[string[]]$Files,[string]$Phase){
 $missing=@()
 foreach($rel in $Files){$p=Join-Path $Root $rel;$exists=[IO.File]::Exists($p);Write-PCVRFileCheckResult -Path $p -Present $exists -Phase $Phase -DisplayName $rel;if(-not $exists){$missing+=$p}}
 return $missing
}
function Set-TeardownVRMode {
 param([string]$Game,[ValidateSet('legacy','markos')][string]$Mod)
 Assert-TeardownSwitchReady $Game
 if($Mod -eq 'markos' -and -not(Test-TeardownMarkosProfile $Game)){throw 'The Markos Teardown profile is incomplete. Install or repair this choice first.'}
 if($Mod -eq 'legacy' -and -not(Test-TeardownLegacyProfile $Game)){throw 'The legacy Teardown profile is incomplete. Install or repair this choice first.'}
 # An ordinary old installation needs no Documents access or profile migration.
 # Only a retained Markos deployment owns native/Lua files that need switching.
 if($Mod -eq 'legacy' -and -not [IO.File]::Exists((Join-Path $Game '.pcvrhub_teardownmarkosnative_ownership.csv')) -and
    (Get-TeardownLegacyProxy $Game) -eq (Join-Path $Game 'dsound.dll')){
  if(Get-PCVRTeardownMarkosVersion -Root $Game){throw 'An unmanaged Markos dxgi.dll needs manual review. It was not removed.'}
  Write-PCVRAtomicText -Path (Join-Path $Game '.pcvrhub_teardown_active') -Value 'legacy'
  return
 }
 $work=New-PCVRInstallerTempSession -BasePath (Get-TeardownTempBase $Game)
 $keep=$false
 try{
  $stages=if(Test-TeardownMarkosProfile $Game){New-TeardownMarkosStages $Game $work}else{
   $empty=Join-Path $work 'empty';[void][IO.Directory]::CreateDirectory($empty);@{Native=$empty;Lua=$empty}
  }
  $snapshots=New-TeardownSwitchSnapshot $Game $work $stages
  try{
   if($Mod -eq 'markos'){
    $sound=Join-Path $Game 'dsound.dll';$parked=$sound+'.pcvrhub_teardown_legacy'
    if([IO.File]::Exists($sound)){
     if((Get-TeardownLegacyProxy $Game) -ne $sound){throw 'An unrelated dsound.dll needs manual review before switching. It was not removed.'}
     if([IO.File]::Exists($parked) -and (Get-FileHash -LiteralPath $sound).Hash -ne (Get-FileHash -LiteralPath $parked).Hash){throw 'A different parked legacy proxy already exists. No proxy was overwritten.'}
     Move-Item -LiteralPath $sound -Destination $parked -Force
    }
    [void](Install-OwnedModPayload -SourceRoot $stages.Native -GameRoot $Game -Identity teardownmarkosnative)
    $docs=Get-TeardownMarkosDocuments;[void][IO.Directory]::CreateDirectory($docs)
    [void](Install-OwnedModPayload -SourceRoot $stages.Lua -GameRoot $docs -Identity teardownmarkoslua)
    $missing=@(Write-TeardownMarkosCheckpoint $Game @('dxgi.dll') 'after-mode-switch')+@(Write-TeardownMarkosCheckpoint $docs @('main.lua','info.txt','hands_glove.vox','hands_skin.vox','hands_blocky.vox') 'after-mode-switch')
    if($missing.Count){throw 'Required Teardown runtime files are missing after switching. Check the paths, permissions and log; no antivirus cause has been established.'}
   }else{
    if([IO.File]::Exists((Join-Path $Game 'dxgi.dll')) -and -not [IO.File]::Exists((Join-Path $Game '.pcvrhub_teardownmarkosnative_ownership.csv'))){
     $markosProxy=$false;try{$markosProxy=[bool](Get-TeardownMarkosVersion $Game)}catch{}
     if($markosProxy){throw 'An unmanaged Markos dxgi.dll needs manual review. It was not removed.'}
    }
    $result=Uninstall-OwnedModPayload -GameRoot $Game -Identity teardownmarkosnative
    if($result.Preserved -gt 0){throw 'The active Markos proxy was modified. It was preserved; review it before changing VR mods.'}
    $docs=Get-TeardownMarkosDocuments
    if([IO.Directory]::Exists($docs)){[void](Uninstall-OwnedModPayload -GameRoot $docs -Identity teardownmarkoslua)}
    $sound=Join-Path $Game 'dsound.dll';$parked=$sound+'.pcvrhub_teardown_legacy'
    if([IO.File]::Exists($parked)){
     if([IO.File]::Exists($sound)){throw 'An existing dsound.dll prevents restoring the legacy proxy. No file was overwritten.'}
     Move-Item -LiteralPath $parked -Destination $sound
    }
    if(-not(Test-TeardownLegacyProfile $Game)){throw 'The legacy Teardown runtime could not be restored.'}
   }
   Write-PCVRAtomicText -Path (Join-Path $Game '.pcvrhub_teardown_active') -Value $Mod
  }catch{
   $problem=$_.Exception.Message
   try{Restore-TeardownSwitchSnapshot $snapshots}catch{$keep=$true;throw ($problem+' '+$_.Exception.Message+' Recovery: '+$work)}
   throw $problem
  }
 }finally{if(-not $keep){Remove-PCVRInstallerTempSession -Path $work}}
}
