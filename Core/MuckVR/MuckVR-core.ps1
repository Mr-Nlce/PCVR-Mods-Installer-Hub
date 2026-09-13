. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference='Stop'; $Host.UI.RawUI.WindowTitle='Muck VR Installer'
function Write-Header {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Muck VR Installer' -ForegroundColor Cyan
    Write-Host '  Installs: MuckVR by Elektroney' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function S($n,$t,$x){Write-Host '';Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan;Write-Host ''}; function OK($x){Write-Host " [OK] $x" -ForegroundColor Green}; function W($x){Write-Host " [!!] $x" -ForegroundColor Yellow}; function P($x='Press Enter to continue...'){Write-Host '';Write-Host " >>> $x " -ForegroundColor Black -BackgroundColor Yellow;Read-Host|Out-Null}
function Get-TS($a,$n){try{Invoke-RestMethod -Uri "https://thunderstore.io/api/experimental/package/$a/$n/" -TimeoutSec 12 -ErrorAction Stop}catch{$null}}
function Get-DeclaredDependencyVersion($packageInfo,$dependencyName,$fallback){if($packageInfo -and $packageInfo.latest){$prefix=$dependencyName+'-';$declared=@($packageInfo.latest.dependencies|Where-Object{([string]$_).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)}|Select-Object -First 1);if($declared.Count){return ([string]$declared[0]).Substring($prefix.Length)}};return $fallback}
function Stamp($root,$v){$d=Join-Path $root 'BepInEx\.ts_versions';New-Item -ItemType Directory -Path $d -Force|Out-Null;foreach($n in @('Elektroney-MuckVR','MuckVR')){[IO.File]::WriteAllText((Join-Path $d $n),$v,(New-Object Text.UTF8Encoding $false))};[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$root,(New-Object Text.UTF8Encoding $false));[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),$v,(New-Object Text.UTF8Encoding $false));Save-InstalledStamp -GameDir $root -Version $v}

Write-Header
Write-Host '  MuckVR is a WIP VR build intended for gamepad play.' -ForegroundColor White
Write-Host '  Virtual Desktop Gamepad Mode can have input problems.' -ForegroundColor Yellow
Write-Host '  If it does not respond, use keyboard and mouse instead.' -ForegroundColor White
Write-Host '  Expect unfinished body IK and incorrect held-item offsets.' -ForegroundColor Yellow
Write-Host '  Its base-game data replacement is backed up before installation.' -ForegroundColor White
$mod=Get-TS 'Elektroney' 'MuckVR'
if($mod -and $mod.is_deprecated){W 'Thunderstore currently marks MuckVR as DEPRECATED. A game update may have broken this build.'}
$mv=if($mod){[string]$mod.latest.version_number}else{'1.0.0'};$mu=if($mod){[string]$mod.latest.download_url}else{'https://thunderstore.io/package/download/Elektroney/MuckVR/1.0.0/'}
$bv=Get-DeclaredDependencyVersion $mod 'BepInEx-BepInExPack_Muck' '5.4.1101';$bu="https://thunderstore.io/package/download/BepInEx/BepInExPack_Muck/$bv/"
try{Show-ThunderstoreDependencyWarning -Missing @(Test-ThunderstoreDependencies -PackageUrls @($mu,$bu))}catch{}
P 'Press Enter to start setup...'
Write-Header;S 1 4 'Locating Muck'
$game=Find-SteamGameFolder -AppId '1625450' -SteamFolderNames @('Muck') -ProbeExe 'Muck.exe'
if(-not $game){$game=Get-GameFolderInteractive -GameName 'Muck' -ProbeFile 'Muck.exe' -ManualUrl 'https://store.steampowered.com/app/1625450/'}
if($game -in @('quit','skip',$null)){W 'No verified game folder was selected.';P 'Press Enter to exit';exit 1};OK "Found: $game"

S 2 4 'Downloading current packages'
$tmp=Join-Path ([IO.Path]::GetTempPath()) ('MuckVR_'+[Guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $tmp -Force|Out-Null
$bz=Join-Path $tmp 'BepInEx.zip';$mz=Join-Path $tmp 'MuckVR.zip'
$gb=Invoke-SafeDownload -Urls @($bu) -Destination $bz -Label 'BepInExPack Muck' -ManualUrl 'https://thunderstore.io/c/muck/p/BepInEx/BepInExPack_Muck/' -AllowSkip $false
$gm=Invoke-SafeDownload -Urls @($mu) -Destination $mz -Label 'MuckVR' -ManualUrl 'https://thunderstore.io/c/muck/p/Elektroney/MuckVR/' -AllowSkip $false
if(-not $gb -or -not $gm){W 'Required package missing.';P 'Press Enter to exit';exit 1}

S 3 4 'Installing with original-file recovery'
$bo=Join-Path $tmp 'bep';$mo=Join-Path $tmp 'mod'
if((Expand-ArchiveOrFallback -ArchivePath $bz -DestinationFolder $bo -Label 'BepInExPack Muck' -AllowSkip $false) -notin @('ok','manual')){throw 'BepInEx extraction failed.'}
if((Expand-ArchiveOrFallback -ArchivePath $mz -DestinationFolder $mo -Label 'MuckVR' -AllowSkip $false) -notin @('ok','manual')){throw 'MuckVR extraction failed.'}
$br=Get-ChildItem -LiteralPath $bo -Directory|Where-Object{Test-Path -LiteralPath (Join-Path $_.FullName 'BepInEx\core\BepInEx.dll')}|Select-Object -First 1 -ExpandProperty FullName
if(-not $br){throw 'The BepInEx package layout was not recognized.'}
Merge-DirectoryTreeVerified -Source $br -Destination $game -Label 'shared BepInEx' -KeepExistingRelativePaths @('BepInEx\config\BepInEx.cfg')|Out-Null
Install-OwnedModPayload -SourceRoot $mo -GameRoot $game -Identity 'muckvr' -IncludeRelativePrefixes @('BepInEx','Muck_Data')|Out-Null

S 4 4 'Verifying and saving recovery data'
if(-not(Test-Path -LiteralPath (Join-Path $game 'BepInEx\plugins\MuckVR.dll')) -or -not(Test-Path -LiteralPath (Join-Path $game 'Muck_Data\globalgamemanagers'))){throw 'MuckVR verification failed.'}
Stamp $game $mv;OK "MuckVR $mv is ready.";Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host '';Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Setup complete.' -ForegroundColor Green;Write-Host ('='*60) -ForegroundColor Magenta
Write-Host '';Write-Host '  Start SteamVR, then launch from the Hub or Steam.' -ForegroundColor White
Write-Host '  Use a gamepad, or keyboard and mouse if Gamepad Mode fails.' -ForegroundColor White
Write-Host '  This is an alpha: body IK and item offsets are not final.' -ForegroundColor Yellow
Write-Host '';Write-Host '  Punch a tree, eat a mushroom, blame Dani.' -ForegroundColor Magenta;Write-Host '';P 'Press Enter to exit'
