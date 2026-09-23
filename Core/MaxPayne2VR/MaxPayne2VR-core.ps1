. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1');. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference='Stop';$Host.UI.RawUI.WindowTitle='Max Payne 2 VR Installer'
$repo='betotron/MaxPayne2VR-release';$fallbackVersion='v1.2';$fallbackName='MaxPayne2VR-v1.2.zip';$fallbackUrl='https://github.com/betotron/MaxPayne2VR-release/releases/download/v1.2/MaxPayne2VR-v1.2.zip'
function Write-Header {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Max Payne 2 VR Installer' -ForegroundColor Cyan
    Write-Host '  Installs: MaxPayne2VR by betotron' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function S($n,$t,$x){Write-Host '';Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan;Write-Host ''};function OK($x){Write-Host " [OK] $x" -ForegroundColor Green};function W($x){Write-Host " [!!] $x" -ForegroundColor Yellow};function P($x='Press Enter to continue...'){Write-Host '';Write-Host " >>> $x " -ForegroundColor Black -BackgroundColor Yellow;Read-Host|Out-Null}
Write-Header
Write-Host '  This beta adds stereo OpenXR, roomscale and motion controls.' -ForegroundColor White
Write-Host '  Virtual Desktop is the only runtime currently confirmed by' -ForegroundColor White
Write-Host '  the author. Start Virtual Desktop before launching the game.' -ForegroundColor White
Write-Host '';W 'WIP: expect rough edges.'
Write-Host '  The Hub keeps your original game files recoverable.' -ForegroundColor White
Show-AntivirusNotice -Compact
P 'Press Enter to start setup...'
Write-Header;S 1 4 'Locating Max Payne 2'
$game=Find-SteamGameFolder -AppId '12150' -SteamFolderNames @('Max Payne 2 The Fall of Max Payne','Max Payne 2') -ProbeExe 'MaxPayne2.exe' -GogNames @('Max Payne 2','Max Payne 2 The Fall of Max Payne') -HubGameId 'max-payne-2-vr'
if(-not$game){$game=Get-GameFolderInteractive -GameName 'Max Payne 2' -ProbeFile 'MaxPayne2.exe' -ManualUrl 'https://store.steampowered.com/app/12150/'}
if($game -in @('quit','skip',$null)){W 'No verified game folder was selected.';P 'Press Enter to exit';exit 1};OK "Found: $game"

S 2 4 'Resolving the current stable release'
$release=Resolve-GitHubReleaseAsset -Repo $repo -AssetPatterns @('(?i)^MaxPayne2VR-v.+\.zip$') -FallbackUrl $fallbackUrl -FallbackTag $fallbackVersion -FallbackAssetName $fallbackName
$version=[string]$release.Tag;$url=[string]$release.Url
if($release.Resolved){OK "Current stable release: $version"}else{W "GitHub did not provide the current asset; using the reviewed $fallbackVersion route."}
$tmp=Join-Path ([IO.Path]::GetTempPath()) ('MaxPayne2VR_'+[Guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $tmp -Force|Out-Null;$zip=Join-Path $tmp 'MaxPayne2VR.zip'
$got=Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "MaxPayne2VR $version" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
if(-not$got){W 'The required archive was not obtained.';P 'Press Enter to exit';exit 1}

S 3 4 'Installing with exact-file recovery'
$out=Join-Path $tmp 'out';if((Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $out -Label 'MaxPayne2VR' -AllowSkip $false) -notin @('ok','manual')){throw 'Extraction was not completed.'}
$modDir=Get-ChildItem -LiteralPath $out -Recurse -Directory|Where-Object{Test-Path -LiteralPath (Join-Path $_.FullName 'winmm.dll')}|Select-Object -First 1 -ExpandProperty FullName
if(-not$modDir){throw 'The archive does not contain the documented mod folder.'}
$liveProxy=Join-Path $game 'winmm.dll';$parkedProxy=Join-Path $game 'winmm.dll.pcvrhub_off'
if((Test-Path -LiteralPath $liveProxy) -and (Test-Path -LiteralPath $parkedProxy)){throw 'Both active and parked winmm.dll copies exist. Remove the duplicate before updating.'}
if((-not(Test-Path -LiteralPath $liveProxy)) -and (Test-Path -LiteralPath $parkedProxy)){Rename-Item -LiteralPath $parkedProxy -NewName 'winmm.dll' -ErrorAction Stop;OK 'Parked VR proxy restored before update.'}
$iniSource=Join-Path $modDir 'MaxPayne2VR.ini';$iniTarget=Join-Path $game 'MaxPayne2VR.ini'
if(-not(Test-Path -LiteralPath $iniTarget)){Merge-PathItemVerified -Source $iniSource -Destination $iniTarget -Label 'default VR configuration'|Out-Null}else{OK 'Existing MaxPayne2VR.ini preserved.'}
Install-OwnedModPayload -SourceRoot $modDir -GameRoot $game -Identity 'maxpayne2vr' -SkipRelativePaths @('MaxPayne2VR.ini')|Out-Null
OK 'Recovery manifest saved; any replaced originals are stored in .pcvrhub_maxpayne2vr_backup.'

S 4 4 'Verifying and saving recovery data'
$watch=@('winmm.dll','d3d8.dll')|ForEach-Object{Join-Path $game $_}
if(@($watch|Where-Object{-not(Test-Path -LiteralPath $_ -PathType Leaf)}).Count){throw 'MaxPayne2VR verification failed.'}
$survived=Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -ArchivePath $zip
if(-not$survived){throw 'Required MaxPayne2VR files did not survive the antivirus check.'}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$game,(New-Object Text.UTF8Encoding $false));[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),$version,(New-Object Text.UTF8Encoding $false));Save-InstalledStamp -GameDir $game -Version $version
OK "Installed release $version.";Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host '';Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Setup complete.' -ForegroundColor Green;Write-Host ('='*60) -ForegroundColor Magenta
Write-Host '';Write-Host '  Start Virtual Desktop first, then launch from the Hub or Steam.' -ForegroundColor White;Write-Host '  The first launch begins with a short flat wait and calibration.' -ForegroundColor White
Write-Host '';Write-Host '  Nothing was bulletproof. Not even the weather.' -ForegroundColor Magenta;Write-Host '';P 'Press Enter to exit'
