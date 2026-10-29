param([Alias('InstallerChoice')][ValidateSet('','bordplate','gamepad','both')][string]$Mod='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
. (Join-Path $PSScriptRoot '..\Modules\GTA4VRProfiles.ps1')
function Invoke-GTA4Install {
param([string]$Mod)
$Host.UI.RawUI.WindowTitle='GTA IV VR Installer'
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host '  GTA IV VR Installer - two separate mod profiles' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host '  [1] bordplate - Motion Controls (RECOMMENDED)' -ForegroundColor Green
Write-Host '      SteamVR as OpenXR runtime. Tested by the author with Vive Wands.'
Write-Host '      Other controllers are untested and may need bindings or code changes.' -ForegroundColor Gray
Write-Host '  [2] gtaiv-dxvk-vr - Gamepad' -ForegroundColor White
Write-Host '      SteamVR, head tracking and stereo; no tracked hands.' -ForegroundColor Gray
Write-Host '  [3] Both - choose the matching Start in VR button in the Hub.'
Write-Host '  Installing another profile keeps your currently active mod.'
Write-Host '  Mod downloads and verified backups can take several minutes.' -ForegroundColor Gray
Show-AntivirusNotice -Compact
if(-not $Mod){do{$pick=(''+(Read-Host 'Choose 1, 2 or 3 (Enter = 1)')).Trim()}while($pick -notin @('','1','2','3'));$Mod=switch($pick){'2'{'gamepad'};'3'{'both'};default{'bordplate'}}}
$test=$null
if($env:PCVR_HUB_TEST_MODE -eq '1'){
 if(-not $env:PCVR_GTA4_TEST_CONFIG){throw 'An isolated GTA IV test config is required.'}
 $test=Get-Content -LiteralPath $env:PCVR_GTA4_TEST_CONFIG -Raw|ConvertFrom-Json
 $boundary=[IO.Path]::GetFullPath($test.Root).TrimEnd('\')+'\'
 if(-not(Test-Path -LiteralPath (Join-Path $test.Root '.fixture'))){throw 'Missing GTA IV test sentinel.'}
 foreach($path in @($test.Game,$test.Desktop,$test.Receipt,$env:PCVR_HUB_TEST_LOCALAPPDATA,$env:PCVR_HUB_RUNTIME_ROOT,$env:PCVR_HUB_USERDATA_ROOT)){
  if(-not $path -or -not [IO.Path]::GetFullPath($path).StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'GTA IV fixture path escaped its sentinel root.'}
 }
}
$game=& {
 $found=$null;$handover=Get-PCVRRecoveryInput
 if($handover){try{$found=Get-GTA4Root $handover}catch{}}
 if(-not $found){$found=Get-PCVRRememberedGameFolder -GameId 'gta-iv-vr' -StateNames @('user_located','installed_path') -ProbeFiles @('GTAIV.exe')}
 if(-not $found -and $test){throw 'The isolated remembered game path was not found.'}
 if(-not $found){$found=Find-SteamGameFolder -AppId '12210' -SteamFolderNames @('Grand Theft Auto IV') -ProbeExe 'GTAIV\GTAIV.exe' -HubGameId 'gta-iv-vr'}
 if(-not $found){foreach($candidate in @('C:\Program Files\Rockstar Games\Grand Theft Auto IV','C:\Program Files (x86)\Rockstar Games\Grand Theft Auto IV')){try{$found=Get-GTA4Root $candidate;break}catch{}}}
 while(-not $found){$raw=Read-Host 'Drop GTAIV.exe or paste its game folder';try{$found=Get-GTA4Root (ConvertTo-PCVRCanonicalUserPath $raw)}catch{Write-Host $_.Exception.Message -ForegroundColor Yellow}}
 Get-GTA4Root $found
}
if($test -and -not $game.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'The detected GTA IV game escaped its fixture.'}
if(-not [IO.File]::Exists((Join-Path $game 'pc\models\cdimages\vehicles.img'))){throw 'The selected folder lacks the original GTA IV game data. Choose the complete game installation, then Retry.'}
if(Get-Process -Name GTAIV,PlayGTAIV,LaunchGTAIV -ErrorAction SilentlyContinue){throw 'Close GTA IV and its launcher, then Retry.'}
if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is protected. Run the Hub as administrator for this folder, or choose a writable game installation, then Retry.'}
if(Test-Path -LiteralPath (Join-Path $game 'FirstPerson.asi')){throw 'FirstPerson.asi conflicts with both VR mods. Back it up and rename it to FirstPerson.asi.off, then Retry.'}
Write-Host ('  [OK] Game found: '+$game) -ForegroundColor Green
Write-Host '  Close the game before installing or switching. Both mods include their own FusionFix.'
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to download and prepare the selected VR mod...')
$work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
try{
$selected=if($Mod -eq 'both'){@('bordplate','gamepad')}else{@($Mod)}
foreach($choice in $selected){
 $p=Get-GTA4Profile $choice
 $script:GTA4RecoveryPage='https://github.com/'+$p.Repo+'/releases'
 Write-Host ('  Preparing '+$p.Name+'...') -ForegroundColor Cyan
 $release=if($test){$test.Packages.$choice}else{Resolve-GitHubReleaseAsset -Repo $p.Repo -AssetPatterns @($p.Pattern) -IncludePrerelease $p.Prerelease}
 if(-not $release.Resolved){throw ('The current '+$p.Name+' download could not be resolved. Retry or use the official release archive.')}
 $zip=Join-Path $work ($choice+'.zip')
 if($test){Copy-Item -LiteralPath $release.LocalFile -Destination $zip}else{[void](Invoke-SafeDownload -Urls @($release.Url) -Destination $zip -Label $p.Name -ManualUrl $release.PageUrl -AllowSkip $false -FunctionalPayloadOnly -PlainProgress -DisableGitHubAssetReresolution)}
 $ex=Join-Path $work ($choice+'-extract');[void][IO.Directory]::CreateDirectory($ex)
 $safety=Test-ZipArchiveEntrySafety -ArchivePath $zip -DestinationFolder $ex
 if(-not $safety.Inspectable -or -not $safety.Safe){throw 'The publisher ZIP is unreadable or contains unsafe paths.'}
 Write-Host ('  Extracting '+$p.Name+'...') -ForegroundColor Gray
 if((Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ex -Label $p.Name -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The complete publisher ZIP could not be extracted.'}
 $stage=if($choice -eq 'gamepad'){Join-Path $ex 'drop-into-GTAIV'}else{$ex}
 Assert-GTA4Tree $stage
 Assert-GTA4Payload $stage $choice
 [void](Wait-PCVRExplicitEnter -Message ('Press Enter to install '+$p.Name+'; existing files and settings are backed up...'))
 $launch=Join-Path $game '_vrmods\VRLaunch'
 $extra=@('_vrmods\active.json','_vrmods\mode.ini','UNINSTALL_GTA4VR.bat','.pcvrhub_version_b')+@('OwnedModFiles.ps1','PublisherZipTransaction.ps1','GTA4VRProfiles.ps1','Start-GTA4VR.ps1','UNINSTALL_GTA4VR.ps1','Start GTA4 bordplate.vbs','Start GTA4 gamepad.vbs'|ForEach-Object {'_vrmods\VRLaunch\'+$_})
 $gameSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity gta4active -SnapshotRoot (Join-Path $work ($choice+'-game-rollback')) -ExtraPaths $extra
 $store=Join-Path $game ('_vrmods\'+$choice);[void][IO.Directory]::CreateDirectory($store)
 $storeSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $store -Stage $stage -Identity ('gta4store_'+$choice) -SnapshotRoot (Join-Path $work ($choice+'-store-rollback')) -ExtraPaths @('.profile.json')
 $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')}
 $shortcutPath=Join-Path $desktop ('GTA IV VR ('+$choice+').lnk');$oldShortcut=if([IO.File]::Exists($shortcutPath)){[IO.File]::ReadAllBytes($shortcutPath)}else{$null}
 $controlStage=Join-Path $work ($choice+'-controllers');$controlLaunch=Join-Path $controlStage '_vrmods\VRLaunch';[void][IO.Directory]::CreateDirectory($controlLaunch)
 $controlSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $controlStage -Identity gta4controllers -SnapshotRoot (Join-Path $work ($choice+'-controllers-rollback')) -ExtraPaths $extra
 try{
 Install-GTA4Profile -Game $game -Stage $stage -Mod $choice -Version $release.Tag
 $launch=Join-Path $game '_vrmods\VRLaunch';[void][IO.Directory]::CreateDirectory($launch)
 foreach($file in @('OwnedModFiles.ps1','PublisherZipTransaction.ps1','GTA4VRProfiles.ps1')){Copy-GTA4Verified (Join-Path $PSScriptRoot ('..\Modules\'+$file)) (Join-Path $controlLaunch $file)}
 foreach($file in @('Start-GTA4VR.ps1','UNINSTALL_GTA4VR.ps1')){Copy-GTA4Verified (Join-Path $PSScriptRoot $file) (Join-Path $controlLaunch $file)}
 foreach($route in @('bordplate','gamepad')){
  $vbs='Set sh=CreateObject("WScript.Shell")'+"`r`n"+'sh.Run "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""'+(Join-Path $launch 'Start-GTA4VR.ps1')+'"" -Mod '+$route+'", 0, False'
  [IO.File]::WriteAllText((Join-Path $controlLaunch ('Start GTA4 '+$route+'.vbs')),$vbs)
 }
 $mode=Join-Path $controlStage '_vrmods\mode.ini';if(-not [IO.File]::Exists($mode)){[IO.File]::WriteAllText($mode,"[Hub]`r`nMode=VR`r`n")}
 [IO.File]::WriteAllText((Join-Path $controlStage 'UNINSTALL_GTA4VR.bat'),'@echo off'+"`r`n"+'powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0_vrmods\VRLaunch\UNINSTALL_GTA4VR.ps1" %*')
 [void](Install-OwnedModPayload -SourceRoot $controlStage -GameRoot $game -Identity gta4controllers -KeepExistingRelativePaths @('_vrmods\mode.ini'))
 $desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')}
 [void][IO.Directory]::CreateDirectory($desktop)
 $shortcutPath=Join-Path $desktop ('GTA IV VR ('+$choice+').lnk');$shell=New-Object -ComObject WScript.Shell
 $shortcut=$shell.CreateShortcut($shortcutPath);$target=Join-Path $env:WINDIR 'System32\wscript.exe'
 if(Test-Path -LiteralPath $shortcutPath){if($shortcut.TargetPath -ine $target -or $shortcut.Arguments -notlike ('*'+$launch+'*')){throw 'An unrelated shortcut has the same name. Rename it, then Retry.'}}
 $shortcut.TargetPath=$target;$shortcut.Arguments='"'+(Join-Path $launch ('Start GTA4 '+$choice+'.vbs'))+'"';$shortcut.WorkingDirectory=$game;$shortcut.IconLocation=(Join-Path $game 'GTAIV.exe')+',0';$shortcut.Save()
 $ship=@(Get-ChildItem -LiteralPath $stage -Recurse -File|ForEach-Object {$_.FullName.Substring($stage.TrimEnd('\').Length+1)})
 $proof=@('GTAIV.exe','pc\models\cdimages\vehicles.img')+@($ship|ForEach-Object {'_vrmods\'+$choice+'\'+$_})+@(('_vrmods\'+$choice+'\.profile.json'),('_vrmods\VRLaunch\Start GTA4 '+$choice+'.vbs'),'_vrmods\VRLaunch\Start-GTA4VR.ps1')
 foreach($rel in $proof){if(-not(Test-Path -LiteralPath (Join-Path $game $rel) -PathType Leaf)){throw ('Required GTA IV file is missing: '+$rel)}}
 if($test -and $test.Failure -eq 'copy'){Remove-Item -LiteralPath (Join-Path $store $p.Required[0]) -Force}
 $requiredPaths=@($ship|ForEach-Object {Join-Path $store $_})
 foreach($file in $requiredPaths){Write-Information -MessageData ('File check [immediately-after-copy]: '+$file+' = '+[IO.File]::Exists($file)) -InformationAction SilentlyContinue}
 if(@($requiredPaths|Where-Object {-not [IO.File]::Exists($_)}).Count){throw 'Required mod files are missing. Check the target path, write permissions and installer log.'}
 if(-not(Confirm-PlacedFilesSurvive -Paths $requiredPaths -GameDir $game -NoClear)){throw 'Required GTA IV mod files did not remain available.'}
 foreach($file in $requiredPaths){Write-Information -MessageData ('File check [after-observation]: '+$file+' = '+[IO.File]::Exists($file)) -InformationAction SilentlyContinue}
 Write-Host ('  [OK] '+$ship.Count+' publisher files verified.') -ForegroundColor Green
 $contract=New-PCVRInstallerContract -Id 'gta-iv-vr' -GameName 'GTA IV VR' -Acquisition GitHub -Routes @('bordplate','gamepad') -RequiredInstalledFileGroups $proof -AntivirusNotice -ReleasePageUrl ('https://github.com/'+$p.Repo+'/releases')
 $receipt=if($test){$test.Receipt}else{Join-Path $PSScriptRoot '.installed_path'}
 [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $release.Tag -Route $choice -VersionSlot $(if($choice -eq 'gamepad'){'Secondary'}else{'Primary'}) -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @((Join-Path $game $p.VersionFile),(Join-Path $store '.pcvrhub_version')))
 Write-Host ('  [OK] '+$p.Name+' '+$release.Tag+' installed.') -ForegroundColor Green
 }catch{
  Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $controlSnapshot
  Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $gameSnapshot
  Restore-PCVRPublisherZipSnapshot -GameRoot $store -Snapshot $storeSnapshot
  if($null -ne $oldShortcut){[IO.File]::WriteAllBytes($shortcutPath,$oldShortcut)}elseif([IO.File]::Exists($shortcutPath)){Remove-Item -LiteralPath $shortcutPath -Force}
  throw
 }
}
}finally{Remove-PCVRInstallerTempSession -Path $work}
Write-Host '  1. Use Start in VR in the Hub for the mod you want.' -ForegroundColor Yellow
Write-Host '  Start SteamVR first. For bordplate, make SteamVR the active OpenXR runtime.'
Write-Host '  Alternative: use the matching GTA IV VR desktop shortcut.'
Write-Host '  Only Vive Wands are author-tested; other controllers may need bindings or code changes.'
Write-Host '  Keep a keyboard/gamepad for minigames and mission workarounds. DLC campaigns are untested.'
Write-Host '  Roman has another bowling invitation.' -ForegroundColor Magenta
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
}
while($true){
 try{Invoke-GTA4Install -Mod $Mod;break}
 catch{
  $message='GTA IV VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'gta-iv-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $(if($script:GTA4RecoveryPage){$script:GTA4RecoveryPage}else{'https://github.com/bordplate/GTA4VR/releases'}))
 }
}
