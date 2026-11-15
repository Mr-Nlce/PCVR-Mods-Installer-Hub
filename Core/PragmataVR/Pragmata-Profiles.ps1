. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
$script:PragmataCodeRoot=$PSScriptRoot
function Get-PragmataStore([string]$Game,[string]$Mod){Join-Path $Game ('_vrmods\pragmata\'+$Mod)}
function Get-PragmataHudNames {
 @('zz_pragmata_transform_probe.lua','zzzz_pragmata_capture_screen_test.lua','zzzzz_pragmata_cinematic_probe.lua','zzzzz_pragmata_label_probe.lua','zzzzz_pragmata_priority_ui_probe.lua','zzzzzz_pragmata_door_hack_inspect.lua','zzzzzzzz_pragmata_hud_orange_test.lua','hud_controls.lua','zz_pragmatavr_hide_ghost.lua','zz_pragmatavr_hud2_to_hud1.lua','zz_pragmatavr_gui_probe.lua')
}
function Assert-PragmataClosed {
 if(Get-Process -Name PRAGMATA -ErrorAction SilentlyContinue){throw 'Close PRAGMATA before installing, switching or removing VR.'}
}
function Test-PragmataProfile([string]$Game,[string]$Mod){
 $root=Get-PragmataStore $Game $Mod
 foreach($name in @('dinput8.dll','openxr_loader.dll')){if(-not[IO.File]::Exists((Join-Path $root $name))){return $false}}
 if($Mod -eq 'modern' -and -not[IO.File]::Exists((Join-Path $root 'PDAFWPlugin.dll'))){return $false};return $true
}
function Import-PragmataLegacy([string]$Game){
 if((Test-PragmataProfile $Game 'legacy') -or [IO.File]::Exists((Join-Path $Game 'PragmataVR_README.txt'))){return}
 foreach($n in @('dinput8.dll','openxr_loader.dll')){if(-not[IO.File]::Exists((Join-Path $Game $n))){return}}
 $store=Get-PragmataStore $Game 'legacy';[void][IO.Directory]::CreateDirectory($store)
 foreach($n in @('dinput8.dll','openxr_loader.dll','PDAFWPlugin.dll','reframework_revision.txt')){if([IO.File]::Exists((Join-Path $Game $n))){Copy-Item -LiteralPath (Join-Path $Game $n) -Destination (Join-Path $store $n)}}
 if([IO.File]::Exists((Join-Path $Game '.pcvrhub_version'))){Copy-Item -LiteralPath (Join-Path $Game '.pcvrhub_version') -Destination (Join-Path $store '.pcvrhub_version')}
}
function Set-PragmataLaunchers([string]$Stage){
 $target=Join-Path $Stage '_vrmods\pragmata\launch';[void][IO.Directory]::CreateDirectory($target)
 Copy-Item -LiteralPath (Join-Path $script:PragmataCodeRoot 'Pragmata-Profiles.ps1') -Destination (Join-Path $target 'Pragmata-Profiles.ps1')
 # The installed runtime is self-contained; it never refers to a disposable Hub folder.
 foreach($name in @('OwnedModFiles.ps1','PublisherZipTransaction.ps1')){Copy-Item -LiteralPath (Join-Path $script:PragmataCodeRoot ('..\Modules\'+$name)) -Destination (Join-Path $target $name)}
 $code=[IO.File]::ReadAllText((Join-Path $target 'Pragmata-Profiles.ps1'))
 $code=$code.Replace(". (Join-Path `$PSScriptRoot '..\Modules\PublisherVRSetup.ps1')", ". (Join-Path `$PSScriptRoot 'OwnedModFiles.ps1')`r`n. (Join-Path `$PSScriptRoot 'PublisherZipTransaction.ps1')")
 [IO.File]::WriteAllText((Join-Path $target 'Pragmata-Profiles.ps1'),$code,[Text.UTF8Encoding]::new($false))
 foreach($mod in @('modern','legacy')){
  $script="`$ErrorActionPreference='Stop'`r`n. (Join-Path `$PSScriptRoot 'Pragmata-Profiles.ps1')`r`ntry { Invoke-PragmataPlay -Game ([IO.Path]::GetFullPath((Join-Path `$PSScriptRoot '..\..\..'))) -Mod '$mod' } catch { if(`$env:PCVR_HUB_TEST_MODE -eq '1'){throw};Add-Type -AssemblyName System.Windows.Forms;[void][Windows.Forms.MessageBox]::Show(`$_.Exception.Message,'Pragmata VR') }"
  [IO.File]::WriteAllText((Join-Path $target ($mod+'.ps1')),$script,[Text.UTF8Encoding]::new($false))
  $vbs="Set f=CreateObject(""Scripting.FileSystemObject"")`r`nSet s=CreateObject(""WScript.Shell"")`r`ns.Run ""powershell.exe -NoProfile -ExecutionPolicy Bypass -File "" & Chr(34) & f.BuildPath(f.GetParentFolderName(WScript.ScriptFullName), ""$mod.ps1"") & Chr(34), 0, False`r`n"
  [IO.File]::WriteAllText((Join-Path $target ($mod+'.vbs')),$vbs,[Text.UTF8Encoding]::new($false))
 }
}
function Invoke-PragmataPlay([string]$Game,[ValidateSet('modern','legacy')][string]$Mod){
 Assert-PragmataClosed
 if(-not[IO.File]::Exists((Join-Path $Game 'PRAGMATA.exe')) -or -not[IO.File]::Exists((Join-Path $Game 're_chunk_000.pak'))){throw 'Locate the complete PRAGMATA game folder.'}
 if(-not(Test-PragmataProfile $Game $Mod)){
  $liveHud=[IO.File]::Exists((Join-Path $Game 'PragmataVR_README.txt'));$files=@('dinput8.dll','openxr_loader.dll')
  if($Mod -eq 'modern'){$files+=@('PragmataVR_README.txt','PDAFWPlugin.dll')}
  if(($Mod -eq 'modern' -or -not$liveHud) -and @($files|Where-Object{-not[IO.File]::Exists((Join-Path $Game $_))}).Count -eq 0){Start-PragmataSteam $Mod;return}
  throw ('The '+$Mod+' VR package is incomplete. Run its installer to repair it.')
 }
 $store=Get-PragmataStore $Game $Mod
 $tempBase=[IO.Path]::GetTempPath()
 if($env:PCVR_HUB_TEST_MODE -eq '1'){
  $ancestor=[IO.DirectoryInfo]::new([IO.Path]::GetFullPath($Game));$fixtureRoot=''
  while($ancestor){if([IO.File]::Exists((Join-Path $ancestor.FullName '.pcvrhub_publisher_fixture'))){$fixtureRoot=$ancestor.FullName;break};$ancestor=$ancestor.Parent}
  if(-not$fixtureRoot -or -not$fixtureRoot.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){throw 'The test switch must stay inside its marked Temp fixture.'};$tempBase=$fixtureRoot
 }
 $temp=Join-Path $tempBase ('PCVRPragmataSwitch_'+[guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($temp)
 $stage=Join-Path $temp 'stage';[void][IO.Directory]::CreateDirectory($stage)
 $owned=Join-Path $Game ('.pcvrhub_pragmata'+$Mod+'_ownership.csv');$ownedPaths=$null
 if([IO.File]::Exists($owned)){$ownedPaths=@(Import-Csv -LiteralPath $owned|ForEach-Object{[string]$_.RelativePath})}
 foreach($f in Get-ChildItem -LiteralPath $store -File -Recurse -Force){
   $rel=$f.FullName.Substring($store.Length+1);if($rel -match '^\.pcvrhub'){continue}
   if($null -ne $ownedPaths -and $ownedPaths -notcontains ('_vrmods\pragmata\'+$Mod+'\'+$rel)){continue}
   $to=Join-OwnedRelativePath $stage $rel;[void][IO.Directory]::CreateDirectory((Split-Path $to -Parent));Copy-Item -LiteralPath $f.FullName -Destination $to
 }
 $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $Game -Stage $stage -Identity 'pragmataactive' -SnapshotRoot (Join-Path $temp 'rollback') -ExtraPaths @('_vrmods\pragmata\active.txt','PDAFWPlugin.dll','PDAFWPlugin.dll.pcvrhub_off')
 $moved=@();$restored=@();$success=$false;$rollbackDone=$false
 try{
  if([IO.File]::Exists((Join-Path $Game '.pcvrhub_pragmataactive_ownership.csv'))){[void](Uninstall-OwnedModPayload -GameRoot $Game -Identity 'pragmataactive')}
  # An imported old AFW plugin belongs with its old framework, not a new
  # general nightly DLL. Park the known optional plugin reversibly when the
  # selected publisher package does not contain it.
  $plugin=Join-Path $Game 'PDAFWPlugin.dll';$pluginOff=$plugin+'.pcvrhub_off'
  if(-not[IO.File]::Exists((Join-Path $stage 'PDAFWPlugin.dll')) -and [IO.File]::Exists($plugin)){
   if([IO.File]::Exists($pluginOff)){if((Get-FileHash -LiteralPath $plugin).Hash -ne (Get-FileHash -LiteralPath $pluginOff).Hash){throw 'A different AFW plugin backup already exists. Keep both files and resolve that conflict before switching.'};Remove-Item -LiteralPath $plugin -Force}
   else{Move-Item -LiteralPath $plugin -Destination $pluginOff}
  }
  [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $Game -Identity 'pragmataactive')
  $autorun=Join-Path $Game 'reframework\autorun';$away=Join-Path $autorun 'pragmatavr_disabled'
  foreach($name in Get-PragmataHudNames){$live=Join-Path $autorun $name;$park=Join-Path $away $name
   if($Mod -eq 'modern' -and [IO.File]::Exists($live)){if([IO.File]::Exists($park)){throw ('A saved HUD script already exists: '+$park)};[void][IO.Directory]::CreateDirectory($away);Move-Item -LiteralPath $live -Destination $park;$moved+=@($name)}
   elseif($Mod -eq 'legacy' -and [IO.File]::Exists($park)){if([IO.File]::Exists($live)){throw ('A different HUD script already exists: '+$live)};Move-Item -LiteralPath $park -Destination $live;$restored+=@($name)}
  }
  [IO.File]::WriteAllText((Join-Path $Game '_vrmods\pragmata\active.txt'),$Mod)
  $success=$true
 }catch{
  foreach($name in $moved){Move-Item -LiteralPath (Join-Path $away $name) -Destination (Join-Path $autorun $name)}
  foreach($name in $restored){Move-Item -LiteralPath (Join-Path $autorun $name) -Destination (Join-Path $away $name)}
  try{Restore-PCVRPublisherZipSnapshot -GameRoot $Game -Snapshot $snapshot;$rollbackDone=$true}catch{Write-Host ('Recovery copy: '+$temp) -ForegroundColor Yellow;throw};throw
 }finally{if($success -or $rollbackDone){Remove-Item -LiteralPath $temp -Recurse -Force}}
 Start-PragmataSteam $Mod
}
function Start-PragmataSteam([string]$Mod){
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PRAGMATA_LAUNCH_CAPTURE){
  $capture=[IO.Path]::GetFullPath($env:PCVR_PRAGMATA_LAUNCH_CAPTURE);if(-not $capture.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped Temp.'};@{File='steam://rungameid/3357650';Mod=$Mod}|ConvertTo-Json|Set-Content -LiteralPath $capture;return
 }
 Start-Process 'steam://rungameid/3357650' -ErrorAction Stop
}
