. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference='Stop'
$Host.UI.RawUI.WindowTitle='How to Fish XR Installer'

function Write-Header {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  How to Fish XR Installer' -ForegroundColor Cyan
    Write-Host '  Installs: HowToFishXR by J_axon' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function S($n,$t,$x){ Write-Host ''; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host '' }
function OK($x){ Write-Host " [OK] $x" -ForegroundColor Green }
function I($x){ Write-Host " [..] $x" -ForegroundColor Gray }
function W($x){ Write-Host " [!!] $x" -ForegroundColor Yellow }
function P($x='Press Enter to continue...'){ Write-Host ''; Write-Host " >>> $x " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }
function Get-TS($author,$name){ try { Invoke-RestMethod -Uri "https://thunderstore.io/api/experimental/package/$author/$name/" -TimeoutSec 12 -ErrorAction Stop } catch { $null } }
function Get-DeclaredDependencyVersion($packageInfo,$dependencyName,$fallback){
    if($packageInfo -and $packageInfo.latest){
        $prefix=$dependencyName+'-'
        $declared=@($packageInfo.latest.dependencies | Where-Object { ([string]$_).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)
        if($declared.Count){ return ([string]$declared[0]).Substring($prefix.Length) }
    }
    return $fallback
}
function Record-Version($root,$version){ $d=Join-Path $root 'BepInEx\.ts_versions'; New-Item -ItemType Directory -Path $d -Force | Out-Null; foreach($n in @('J_axon-HowToFishXR','HowToFishXR')){ [IO.File]::WriteAllText((Join-Path $d $n),$version,(New-Object Text.UTF8Encoding $false)) }; [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$root,(New-Object Text.UTF8Encoding $false)); [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),$version,(New-Object Text.UTF8Encoding $false)); Save-InstalledStamp -GameDir $root -Version $version }

Write-Header
Write-Host '  Full room-scale fishing, tracked tools, weapons and hands.' -ForegroundColor White
Write-Host '  The installer gets the current Thunderstore mod and its exact' -ForegroundColor White
Write-Host '  BepInEx 5 dependency. Flat and VR players can share a lobby.' -ForegroundColor White
Write-Host ''
$modInfo=Get-TS 'J_axon' 'HowToFishXR'
if($modInfo -and $modInfo.is_deprecated){ W 'Thunderstore currently marks HowToFishXR as DEPRECATED. Installation remains available, but a game update may have broken it.' }
$modVersion=if($modInfo){[string]$modInfo.latest.version_number}else{'1.3.0'}
$modUrl=if($modInfo){[string]$modInfo.latest.download_url}else{'https://thunderstore.io/package/download/J_axon/HowToFishXR/1.3.0/'}
$bepVersion=Get-DeclaredDependencyVersion $modInfo 'BepInEx-BepInExPack' '5.4.2305'
$bepUrl="https://thunderstore.io/package/download/BepInEx/BepInExPack/$bepVersion/"
try { Show-ThunderstoreDependencyWarning -Missing @(Test-ThunderstoreDependencies -PackageUrls @($modUrl,$bepUrl)) } catch {}
P 'Press Enter to start setup...'

Write-Header; S 1 4 'Locating How to Fish'
$game=Find-SteamGameFolder -AppId '4001890' -SteamFolderNames @('How to Fish') -Subdir 'How to Fish' -ProbeExe 'How to Fish.exe'
if(-not $game){ $game=Get-GameFolderInteractive -GameName 'How to Fish' -ProbeFile 'How to Fish.exe' -ManualUrl 'https://store.steampowered.com/app/4001890/' }
if($game -in @('quit','skip',$null)){ W 'No verified game folder was selected.'; P 'Press Enter to exit'; exit 1 }
OK "Found: $game"

S 2 4 'Downloading current packages'
$tmp=Join-Path ([IO.Path]::GetTempPath()) ('HowToFishXR_'+[Guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$bepZip=Join-Path $tmp 'BepInEx.zip'; $modZip=Join-Path $tmp 'HowToFishXR.zip'
$gotBep=Invoke-SafeDownload -Urls @($bepUrl) -Destination $bepZip -Label 'BepInEx 5' -ManualUrl 'https://thunderstore.io/c/how-to-fish/p/BepInEx/BepInExPack/' -AllowSkip $false
$gotMod=Invoke-SafeDownload -Urls @($modUrl) -Destination $modZip -Label 'HowToFishXR' -ManualUrl 'https://thunderstore.io/c/how-to-fish/p/J_axon/HowToFishXR/' -AllowSkip $false
if(-not $gotBep -or -not $gotMod){ W 'Required package missing.'; P 'Press Enter to exit'; exit 1 }

S 3 4 'Installing BepInEx and HowToFishXR'
$bepOut=Join-Path $tmp 'bep'; $modOut=Join-Path $tmp 'mod'
if((Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $bepOut -Label 'BepInEx 5' -AllowSkip $false) -notin @('ok','manual')){ throw 'BepInEx extraction was not completed.' }
if((Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $modOut -Label 'HowToFishXR' -AllowSkip $false) -notin @('ok','manual')){ throw 'HowToFishXR extraction was not completed.' }
$bepRoot=Get-ChildItem -LiteralPath $bepOut -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'BepInEx\core\BepInEx.dll') } | Select-Object -First 1 -ExpandProperty FullName
if(-not $bepRoot){throw 'The BepInEx package layout was not recognized.'}
Merge-DirectoryTreeVerified -Source $bepRoot -Destination $game -Label 'shared BepInEx 5' -KeepExistingRelativePaths @('BepInEx\config\BepInEx.cfg') | Out-Null
Install-OwnedModPayload -SourceRoot $modOut -GameRoot $game -Identity 'howtofishxr' -IncludeRelativePrefixes @('BepInEx') | Out-Null

S 4 4 'Verifying and saving recovery data'
$marker=Join-Path $game 'BepInEx\plugins\HowToFishXR\HowToFishVR.dll'; $patcher=Join-Path $game 'BepInEx\patchers\HowToFishXR\HowToFishVR.Preload.dll'
if(-not(Test-Path -LiteralPath $marker) -or -not(Test-Path -LiteralPath $patcher)){throw 'HowToFishXR verification failed.'}
Record-Version $game $modVersion; OK "HowToFishXR $modVersion is ready."
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ''; Write-Host ('='*60) -ForegroundColor Magenta; Write-Host '  Setup complete.' -ForegroundColor Green; Write-Host ('='*60) -ForegroundColor Magenta
Write-Host ''; Write-Host '  Start from the Hub or Steam. Use the Hub Flat / VR switch' -ForegroundColor White; Write-Host '  whenever you want the mod loaded without entering VR.' -ForegroundColor White
Write-Host ''; Write-Host '  The fish were not expecting hands.' -ForegroundColor Magenta; Write-Host ''; P 'Press Enter to exit'
