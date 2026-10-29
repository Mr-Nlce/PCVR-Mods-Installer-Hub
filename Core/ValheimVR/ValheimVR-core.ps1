$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
. (Join-Path $PSScriptRoot '..\Utils\GameDetection.ps1')
$oldLibrary=$env:PCVR_VALHEIM_LIBRARY_ONLY;$env:PCVR_VALHEIM_LIBRARY_ONLY='1'
. (Join-Path $PSScriptRoot 'Start-ValheimVR.ps1')
$env:PCVR_VALHEIM_LIBRARY_ONLY=$oldLibrary
$script:ValheimId='valheim-vr';$script:ValheimPage='https://github.com/brandonmousseau/vhvr-mod/releases'
$script:ValheimLoaderDlls=@('0Harmony.dll','0Harmony20.dll','BepInEx.Harmony.dll','BepInEx.Preloader.dll','BepInEx.dll','HarmonyXInterop.dll','Mono.Cecil.Mdb.dll','Mono.Cecil.Pdb.dll','Mono.Cecil.Rocks.dll','Mono.Cecil.dll','MonoMod.RuntimeDetour.dll','MonoMod.Utils.dll')
$script:ValheimRequired=@('valheim.exe','UnityPlayer.dll','Valheim_Data\Managed\assembly_valheim.dll',
 'winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll',
 'BepInEx\plugins\ValheimVRMod.dll','Valheim_Data\Managed\SteamVR.dll','Valheim_Data\Managed\Unity.XR.OpenVR.dll',
 'Valheim_Data\Plugins\x86_64\openvr_api.dll','Valheim_Data\Plugins\x86_64\XRSDKOpenVR.dll',
 'Valheim_Data\StreamingAssets\SteamVR\actions.json','Valheim_Data\UnitySubsystems\XRSDKOpenVR\UnitySubsystemsManifest.json',
 'PCVR-Valheim\Start-ValheimVR.ps1','PCVR-Valheim\StoreLaunch.ps1','.pcvrhub_valheimvr_ownership.csv')
$script:ValheimRequired+=@($script:ValheimLoaderDlls|Where-Object{('BepInEx\core\'+$_) -notin $script:ValheimRequired}|ForEach-Object{'BepInEx\core\'+$_})
$script:ValheimRequired+=@('Bhaptics.Tact.dll','final_ik.dll','NDesk.Options.dll','root_motion_demo_assets.dll','root_motion_shared.dll','Unity.XR.Management.dll','UnityEngine.SpatialTracking.dll','UnityEngine.XR.LegacyInputHelpers.dll','Valve.Newtonsoft.Json.dll'|ForEach-Object{'Valheim_Data\Managed\'+$_})
$script:ValheimContract=New-PCVRInstallerContract -Id $script:ValheimId -GameName 'Valheim VR' -Acquisition GitHub -Routes @('Steam','Xbox') -ReleasePageUrl $script:ValheimPage -AntivirusNotice -RequiredInstalledFileGroups $script:ValheimRequired
function Test-ValheimGame([string]$Root){
 if(-not $Root){return $false}
 foreach($rel in @('valheim.exe','UnityPlayer.dll','Valheim_Data\Managed\assembly_valheim.dll')){if(-not(Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)){return $false}}
 return $true
}
function Get-ValheimGame {
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VALHEIM_TEST_GAME){
  $root=[IO.Path]::GetFullPath($env:PCVR_VALHEIM_TEST_GAME)
  $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
  if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root '.pcvr_valheim_fixture'))){throw 'Valheim test paths must be isolated sentinel fixtures.'}
  if(-not(Test-ValheimGame $root)){throw 'The Valheim game fixture is incomplete.'};return $root
 }
 $saved=Get-PCVRRememberedGameFolder -GameId $script:ValheimId -StateNames @('user_located','installed_path') -ProbeFiles @('valheim.exe','UnityPlayer.dll','Valheim_Data\Managed\assembly_valheim.dll')
 if(Test-ValheimGame $saved){return $saved}
 $found=Find-GameInstall -GameName 'Valheim' -Steam @{AppID='892970';Folder='Valheim'} -Gamepass @{Folder='Valheim';PackageName='*Valheim*';ContentSubfolder=$true} -ExeName 'valheim.exe'
 if($found.Found -and (Test-ValheimGame $found.Path)){return $found.Path}
 while($true){
  $picked=Get-GameFolderInteractive -GameName 'Valheim (Steam or Xbox app)' -ProbeFile 'valheim.exe'
  if(Test-ValheimGame $picked){[void](Save-HubRememberedGameFolder -GameId $script:ValheimId -Title 'Valheim VR' -GameDir $picked -ProbeFiles @('valheim.exe','UnityPlayer.dll','Valheim_Data\Managed\assembly_valheim.dll') -UserSelected);return $picked}
  Write-Host '  Choose the folder containing the complete Valheim game.' -ForegroundColor Yellow
 }
}
function Test-ValheimZip([string]$Path,[switch]$Loader){
 try{
  Add-Type -AssemblyName System.IO.Compression.FileSystem;$z=[IO.Compression.ZipFile]::OpenRead($Path)
  try{
   $required=if($Loader){@('BepInExPack_Valheim/winhttp.dll','BepInExPack_Valheim/doorstop_config.ini','BepInExPack_Valheim/BepInEx/core/BepInEx.dll','BepInExPack_Valheim/BepInEx/core/BepInEx.Preloader.dll')}
   else{@('BepInEx/plugins/ValheimVRMod.dll','Valheim_Data/Managed/SteamVR.dll','Valheim_Data/Plugins/x86_64/openvr_api.dll','Valheim_Data/StreamingAssets/SteamVR/actions.json')}
   if($Loader){$required+=@($script:ValheimLoaderDlls|ForEach-Object{'BepInExPack_Valheim/BepInEx/core/'+$_})}
   foreach($name in $required){if(-not $z.GetEntry($name)){return $false}};return $true
  }finally{$z.Dispose()}
 }catch{return $false}
}
function Get-ValheimPackages([string]$Work){
 $loader=Join-Path $Work 'BepInEx.zip';$mod=Join-Path $Work 'vhvr.zip'
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VALHEIM_TEST_LOADER){
  Copy-Item -LiteralPath $env:PCVR_VALHEIM_TEST_LOADER -Destination $loader
  Copy-Item -LiteralPath $env:PCVR_VALHEIM_TEST_MOD -Destination $mod
  $version='v'+[string]$env:PCVR_VALHEIM_TEST_VERSION
 }else{
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the Valheim loader and current VHVR release...')
  $handover=Get-PCVRRecoveryInput
  $manualFiles=if($handover -and (Test-Path -LiteralPath $handover -PathType Container)){@(Get-ChildItem -LiteralPath $handover -File -Filter '*.zip'|Select-Object -ExpandProperty FullName)}elseif($handover){@($handover)}else{@()}
  $manualMod=@($manualFiles|Where-Object{Test-ValheimZip $_})
  $manualLoader=@($manualFiles|Where-Object{Test-ValheimZip $_ -Loader})
  if($manualMod.Count -gt 1 -or $manualLoader.Count -gt 1){throw 'The selected folder contains multiple matching Valheim packages. Hand over the specific VHVR ZIP, or a folder containing one VHVR ZIP and one loader ZIP.'}
  $downloadInfo=@{}
  if($manualMod.Count){
   Copy-Item -LiteralPath $manualMod[0] -Destination $mod -Force
   $downloadInfo.SourceKind='manual handover'
  }else{
   $release=Resolve-GitHubReleaseAsset -Repo 'brandonmousseau/vhvr-mod' -IncludePrerelease $false -AssetPatterns @('(?i)^(?!.*(?:source|symbols|debug|server|linux|macos))vhvr.*\.zip$') -SkipReleasesWithoutMatchingAsset $true
   if(-not $release.Resolved -or -not $release.Url -or -not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){throw 'The current VHVR release could not be resolved. Retry, or hand over the downloaded VHVR ZIP (or a folder containing both ZIPs) through recovery.'}
   $version=[string]$release.Tag
   [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $mod -Label 'Valheim VR' -ManualUrl $script:ValheimPage -AllowSkip:$false -FunctionalPayloadOnly -PlainProgress -DisableGitHubAssetReresolution -DownloadInfo $downloadInfo -Validator {param($p) Test-ValheimZip $p})
  }
  if($downloadInfo.SourceKind -match 'manual'){
   Write-Host '  The ZIP was supplied manually. Enter its release version from the download page.' -ForegroundColor White
   do{$version=(Read-Host '  VHVR release version, for example 0.11.2').Trim()}while(-not(Test-IsTrackableInstalledVersion $version))
  }
  if($manualLoader.Count){Copy-Item -LiteralPath $manualLoader[0] -Destination $loader -Force}
  else{[void](Invoke-SafeDownload -Urls @('https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2351/') -Destination $loader -Label 'BepInExPack Valheim 5.4.2351' -ManualUrl 'https://thunderstore.io/c/valheim/p/denikson/BepInExPack_Valheim/' -AllowSkip:$false -FunctionalPayloadOnly -PlainProgress -DisableGitHubAssetReresolution -Validator {param($p) Test-ValheimZip $p -Loader})}
 }
 if(-not(Test-ValheimZip $loader -Loader) -or -not(Test-ValheimZip $mod)){throw 'A downloaded archive lacks required Valheim runtime files.'}
 foreach($entry in @(@{Zip=$loader;Folder='loader'},@{Zip=$mod;Folder='mod'})){
  Write-Host ('  Preparing '+$entry.Folder+' files...') -ForegroundColor Gray
  if((Expand-ArchiveOrFallback -ArchivePath $entry.Zip -DestinationFolder (Join-Path $Work $entry.Folder) -Label $entry.Folder -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The required Valheim package could not be extracted.'}
 }
 $manifest=Get-Content -LiteralPath (Join-Path $Work 'loader\manifest.json') -Raw | ConvertFrom-Json
 if(@($manifest.dependencies).Count -gt 0){throw 'This loader declares additional dependencies. Use the supported BepInExPack Valheim package or Retry; no game files were changed.'}
 $stage=Join-Path $Work 'payload';[void][IO.Directory]::CreateDirectory($stage)
 foreach($source in @((Join-Path $Work 'loader\BepInExPack_Valheim'),(Join-Path $Work 'mod'))){foreach($item in Get-ChildItem -LiteralPath $source -Force){Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse -Force}}
 $launch=Join-Path $stage 'PCVR-Valheim';[void][IO.Directory]::CreateDirectory($launch)
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Start-ValheimVR.ps1') -Destination $launch
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\Modules\StoreLaunch.ps1') -Destination $launch
 [IO.File]::WriteAllText((Join-Path $stage '.pcvrhub_version'),$version)
 foreach($relative in @($script:ValheimRequired|Where-Object {$_ -notin @('valheim.exe','UnityPlayer.dll','Valheim_Data\Managed\assembly_valheim.dll','.pcvrhub_valheimvr_ownership.csv')})){
  $file=Join-Path $stage $relative
  if(-not(Test-Path -LiteralPath $file -PathType Leaf) -or (Get-Item -LiteralPath $file).Length -eq 0){throw ('The staged runtime lacks '+$relative+'. No game files were changed.')}
 }
 return [pscustomobject]@{Stage=$stage;Version=$version}
}
function global:Write-ValheimCheckpoint([string]$Game,[string]$Phase){
 $missing=@();foreach($rel in $script:ValheimRequired){$path=Join-Path $Game $rel;$present=Test-Path -LiteralPath $path -PathType Leaf;Write-PCVRFileCheckResult -Path $path -Present $present -Phase $Phase;if(-not $present){$missing+=@($rel)}};return @($missing)
}
function Get-ValheimShortcutPath {
 if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VALHEIM_TEST_GAME){return (Join-Path $env:PCVR_VALHEIM_TEST_GAME 'Desktop\Valheim VR.lnk')}
 return (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Valheim VR.lnk')
}
function Set-ValheimShortcut([string]$Game){
 $path=Get-ValheimShortcutPath;[void][IO.Directory]::CreateDirectory((Split-Path $path));$shell=New-Object -ComObject WScript.Shell
 if(Test-Path -LiteralPath $path){$old=$shell.CreateShortcut($path);if($old.Arguments -notlike '*PCVR-Valheim\Start-ValheimVR.ps1*'){throw 'An unrelated Valheim VR desktop shortcut exists. Rename it before Retry; it was not replaced.'}}
 $shortcut=$shell.CreateShortcut($path);$shortcut.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $shortcut.Arguments='-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $Game 'PCVR-Valheim\Start-ValheimVR.ps1')+'"'
 $shortcut.WorkingDirectory=$Game;$shortcut.IconLocation=(Join-Path $Game 'valheim.exe')+',0';$shortcut.Save()
}
function Invoke-ValheimInstaller {
 $work=$null;$snapshot=$null;$changed=$false;$game=$null;$shortcutPath=$null;$shortcutBytes=$null;$hadShortcut=$false
 try{
  Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Valheim VR - Steam / Xbox app' -ForegroundColor Cyan
  Write-Host '  SteamVR is required for the headset, including Xbox copies.' -ForegroundColor White
  Write-Host '  The Xbox game does not require a Steam game license.' -ForegroundColor White
  Show-AntivirusNotice -Compact
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to find Valheim...')
  $game=Get-ValheimGame
  if(Get-Process -Name valheim -ErrorAction SilentlyContinue){throw 'Close Valheim before installing or updating its VR mod.'}
  $plan=Get-ValheimLaunchPlan $game;Write-Host ('  [OK] '+$plan.Store+' Valheim found: '+$game) -ForegroundColor Green
  if(-not(Test-InstallerTargetWritable $game)){throw 'The Valheim game folder is not writable. Choose Retry after correcting its permissions.'}
  $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath());$package=Get-ValheimPackages $work
  $keep=@('doorstop_config.ini')+@(Get-ChildItem -LiteralPath (Join-Path $package.Stage 'BepInEx\config') -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {$_.FullName.Substring($package.Stage.Length+1)})
  $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $package.Stage -Identity 'valheimvr' -SnapshotRoot (Join-Path $work 'rollback')
  $shortcutPath=Get-ValheimShortcutPath;$hadShortcut=Test-Path -LiteralPath $shortcutPath -PathType Leaf;if($hadShortcut){$shortcutBytes=[IO.File]::ReadAllBytes($shortcutPath)}
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Valheim VR...');$changed=$true
  $copyState=@{Count=0}
  $copy={
   if($copyState.Count -gt 0){[void](Write-ValheimCheckpoint $game 'before-retry')}
   $copyState.Count++
   [void](Install-OwnedModPayload -SourceRoot $package.Stage -GameRoot $game -Identity 'valheimvr' -KeepExistingRelativePaths $keep -AdoptIdenticalExisting -ReplaceChangedOwnedRelativePaths @('.pcvrhub_version'))
   if($copyState.Count -gt 1){[void](Write-ValheimCheckpoint $game 'after-retry')}
  }.GetNewClosure()
  & $copy
  if(@(Write-ValheimCheckpoint $game 'immediately-after-copy').Count){throw 'Required files were not copied. Check the selected folder and write permissions, then Retry.'}
  if(-not(Confirm-PlacedFilesSurvive -Paths @($script:ValheimRequired|ForEach-Object{Join-Path $game $_}) -GameDir $game -Recopy $copy -NoClear)){throw 'Valheim runtime files are missing. Previous files will be restored.'}
  if(@(Write-ValheimCheckpoint $game 'after-observation').Count){throw 'Required Valheim files are missing after installation.'}
  Set-ValheimShortcut $game
  if(@(Write-ValheimCheckpoint $game 'before-commit').Count){throw 'Valheim files are incomplete; setup was not committed.'}
  $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_VALHEIM_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
  [void](Complete-PCVRInstallTransaction -Contract $script:ValheimContract -GameDir $game -Version $package.Version -InstalledPathReceiptPaths @($receipt) -Route $plan.Store)
  $changed=$false
  Write-Host ('  [OK] Valheim VR '+$package.Version+' installed.') -ForegroundColor Green
  Write-Host '  1. Use Start in VR in the Hub with SteamVR running.' -ForegroundColor White
  Write-Host '  Alternatively, use the Valheim VR desktop shortcut.' -ForegroundColor White
  Write-Host '  DirectX 11 is selected automatically. Do not choose Vulkan.' -ForegroundColor Yellow
  Write-Host '';Write-Host '  The trees still have the highest kill count.' -ForegroundColor Magenta
  [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
 }catch{
  if($changed -and $snapshot){
   [void](Write-ValheimCheckpoint $game 'before-rollback');Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot
   if($hadShortcut){[IO.File]::WriteAllBytes($shortcutPath,$shortcutBytes)}elseif($shortcutPath -and (Test-Path -LiteralPath $shortcutPath)){Remove-Item -LiteralPath $shortcutPath -Force}
   [void](Write-ValheimCheckpoint $game 'after-rollback')
  };throw
 }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_VALHEIM_SETUP_LIBRARY_ONLY -ne '1'){
 while($true){try{Invoke-ValheimInstaller;break}catch{
  $message='Valheim VR setup did not complete: '+$_.Exception.Message;Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot -RecoveryPageUrl $script:ValheimPage -GameId $script:ValheimId)
 }}
}
