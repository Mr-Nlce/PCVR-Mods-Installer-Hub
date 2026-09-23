$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle='Kingdom Come: Deliverance VR Installer'
$APP_ID='379430';$GAME_EXE='Bin\Win64\KingdomCome.exe';$REPO='farmerarmor/KCD1VR';$IDENTITY='kcd1vr'
$FALLBACK_TAG='v0.1.67';$FALLBACK_ASSET='KCD1VR-0.1.67.zip';$FALLBACK_URL='https://github.com/farmerarmor/KCD1VR/releases/download/v0.1.67/KCD1VR-0.1.67.zip';$LAUNCH='+exec KCD1VR.cfg +exec KCD1VR-dlss.cfg'
$BEGIN='-- BEGIN KCD1VR MANAGED SETTINGS';$END='-- END KCD1VR MANAGED SETTINGS'
$REQUIRED=@('Bin\Win64\dinput8.dll','Bin\Win64\nvngx_dlss.dll','Bin\Win64\KCD1VR.ini','Bin\Win64\KCD1VRResolution.exe','KCD1VR.cfg','KCD1VR-dlss.cfg')
$contract=New-PCVRInstallerContract -Id 'kingdom-come-deliverance-vr' -GameName 'Kingdom Come: Deliverance VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl "https://github.com/$REPO/releases" -RequiredInstalledFileGroups @($REQUIRED+@(".pcvrhub_${IDENTITY}_ownership.csv"))

function Write-KCDStep([int]$n,[string]$t){Write-Host '';Write-Host "--- [$n/6] $t ---" -ForegroundColor Cyan;Write-Host ''}
function Test-KCDRoot([string]$p){[bool]($p -and (Test-Path (Join-Path $p $GAME_EXE) -PathType Leaf) -and (Test-Path (Join-Path $p 'Data') -PathType Container))}
function Test-KCDPayload([string]$p){[bool]($p -and (Test-Path (Join-Path $p 'dist\dinput8.dll') -PathType Leaf) -and (Test-Path (Join-Path $p 'dist\KCD1VR.ini') -PathType Leaf) -and (Test-Path (Join-Path $p 'dist\KCD1VRResolution.exe') -PathType Leaf) -and (Get-ChildItem (Join-Path $p 'dist') -Filter 'KCD1VR*.cfg' -File -ErrorAction SilentlyContinue))}
function Get-KCDRoot {$p=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('KingdomComeDeliverance') -ProbeExe $GAME_EXE -HubGameId 'kingdom-come-deliverance-vr';if(Test-KCDRoot $p){return (Get-Item $p).FullName};foreach($f in @('C:\Program Files (x86)\Steam\steamapps\common\KingdomComeDeliverance','C:\Program Files\Steam\steamapps\common\KingdomComeDeliverance')){if(Test-KCDRoot $f){return (Get-Item $f).FullName}};$p=Get-GameFolderInteractive -GameName 'Kingdom Come: Deliverance' -ProbeFile $GAME_EXE -ManualUrl 'https://github.com/farmerarmor/KCD1VR#installation';if($p -and $p -notin @('quit','skip') -and (Test-KCDRoot $p)){return (Get-Item $p).FullName};return $null}
function Get-KCDRelease {$r=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -AssetPatterns @('(?i)^KCD1VR-.*\.zip$') -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET -SkipReleasesWithoutMatchingAsset;[pscustomobject]@{Tag=[string]$r.Tag;Url=[string]$r.Url;Name=[string]$r.AssetName;PageUrl=[string]$r.PageUrl}}
function Remove-KCDManagedBlockText([string]$text){if($null -eq $text){return ''};$pattern='(?ms)^\s*'+[regex]::Escape($BEGIN)+'.*?'+[regex]::Escape($END)+'\s*(?:\r?\n)?';return ([regex]::Replace($text,$pattern,'')).TrimEnd()}
function Set-KCDManagedBlock([string]$path,[int]$width,[int]$height){$old=if(Test-Path $path){[IO.File]::ReadAllText($path)}else{''};$base=Remove-KCDManagedBlockText $old;$block=@($BEGIN,'r_StereoDevice = 1','sys_vr_support = 0','r_StereoMode = 1','r_StereoOutput = 4','r_StereoEyeDist = 0.064','r_StereoFlipEyes = 0',"r_Width = $width","r_Height = $height",'r_Fullscreen = 0','r_VSync = 0',$END) -join "`r`n";$new=if($base){$base+"`r`n`r`n"+$block+"`r`n"}else{$block+"`r`n"};[IO.File]::WriteAllText($path,$new,[Text.UTF8Encoding]::new($false))}
function Get-KCDOptions {
    $scale=1.0;$quality='Quality';$preset='Default';Write-Host '  Press Enter to accept each recommended value.' -ForegroundColor Gray;$v=([string](Read-Host 'Display scale [1.0]')).Trim();if($v){$parsed=0.0;if(-not[double]::TryParse($v,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$parsed) -or $parsed -lt .25 -or $parsed -gt 3){throw 'Display scale must be between 0.25 and 3.0.'};$scale=$parsed};$v=([string](Read-Host 'DLSS mode: Quality, Balanced, Performance, UltraPerformance, DLAA [Quality]')).Trim();if($v){$quality=$v};if($quality -notin @('UltraPerformance','Performance','Balanced','Quality','DLAA')){throw 'Choose Quality, Balanced, Performance, UltraPerformance or DLAA.'};$v=([string](Read-Host 'DLSS render preset: Default, J, K, L or M [Default]')).Trim();if($v){$preset=$v};if($preset -notin @('Default','J','K','L','M')){throw 'Choose Default, J, K, L or M.'};[pscustomobject]@{Scale=$scale;Quality=$quality;Preset=$preset}
}
function Read-KCDResolutionFallback([double]$scale){
    $presets=@(
        [pscustomobject]@{Name='Meta Quest 3';Width=2064;Height=2208},
        [pscustomobject]@{Name='Meta Quest 2 / Quest 3S';Width=1832;Height=1920},
        [pscustomobject]@{Name='Valve Index';Width=1440;Height=1600},
        [pscustomobject]@{Name='HTC Vive';Width=1080;Height=1200},
        [pscustomobject]@{Name='HTC Vive Pro / Pro Eye';Width=1440;Height=1600},
        [pscustomobject]@{Name='HTC Vive Pro 2';Width=2448;Height=2448},
        [pscustomobject]@{Name='HP Reverb G2';Width=2160;Height=2160},
        [pscustomobject]@{Name='Pico 4';Width=2160;Height=2160},
        [pscustomobject]@{Name='PlayStation VR2 on PC';Width=2000;Height=2040},
        [pscustomobject]@{Name='Pimax Crystal';Width=2880;Height=2880}
    )
    Write-Host ''
    Write-Host '  Choose a common per-eye headset preset:' -ForegroundColor White
    for($i=0;$i -lt $presets.Count;$i++){
        $preset=$presets[$i]
        Write-Host ("  [{0,2}] {1,-29} {2} x {3}" -f ($i+1),$preset.Name,$preset.Width,$preset.Height) -ForegroundColor Cyan
    }
    Write-Host '  [M] Enter an exact per-eye output size manually' -ForegroundColor Cyan
    Write-Host '  [R] Retry the publisher OpenXR probe' -ForegroundColor Cyan
    while($true){
        $choice=([string](Read-Host 'Choice')).Trim().ToUpperInvariant()
        if($choice -eq 'R'){return [pscustomobject]@{Action='Retry'}}
        if($choice -eq 'M'){
            $w=0;$h=0
            [void][int]::TryParse((Read-Host 'Exact per-eye output width'),[ref]$w)
            [void][int]::TryParse((Read-Host 'Exact per-eye output height'),[ref]$h)
            if($w -ge 640 -and $h -ge 480){return [pscustomobject]@{Action='Use';Width=$w;Height=$h;Source='manual exact size'}}
            Write-Host '  Enter numeric per-eye values of at least 640 x 480.' -ForegroundColor Yellow
            continue
        }
        $number=0
        if([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $presets.Count){
            $selected=$presets[$number-1]
            return [pscustomobject]@{
                Action='Use'
                Width=[int][math]::Round($selected.Width*$scale)
                Height=[int][math]::Round($selected.Height*$scale)
                Source=("{0} preset" -f $selected.Name)
            }
        }
        Write-Host '  Choose 1-10, M or R.' -ForegroundColor Yellow
    }
}
function Invoke-KCDResolution([string]$tool,[double]$scale,[string]$work){
    if($env:PCVR_KCD_TEST_RESOLUTION -match '^(\d+)x(\d+)$'){return [pscustomobject]@{Width=[int]$matches[1];Height=[int]$matches[2]}}
    $out=Join-Path $work 'resolution.out';$err=Join-Path $work 'resolution.err'
    while($true){
        Remove-Item -LiteralPath $out,$err -Force -ErrorAction SilentlyContinue
        $p=Start-Process -FilePath $tool -ArgumentList @('--scale',$scale.ToString([Globalization.CultureInfo]::InvariantCulture)) -NoNewWindow -PassThru -Wait -RedirectStandardOutput $out -RedirectStandardError $err
        if($p.ExitCode -eq 0 -and (Test-Path -LiteralPath $out -PathType Leaf)){
            $raw=[IO.File]::ReadAllText($out)
            try{$j=$raw|ConvertFrom-Json;if([int]$j.width -gt 0 -and [int]$j.height -gt 0){return [pscustomobject]@{Width=[int]$j.width;Height=[int]$j.height}}}catch{}
        }
        $probeError=if(Test-Path -LiteralPath $err -PathType Leaf){[IO.File]::ReadAllText($err)}else{''}
        Write-Host ''
        if($probeError -match 'OpenXR runtime initialization failed\s*\(-4\)|XR_ERROR_API_VERSION_UNSUPPORTED'){
            Write-Host '  The publisher resolution tool is incompatible with the active' -ForegroundColor Yellow
            Write-Host '  OpenXR runtime (API version unsupported).' -ForegroundColor Yellow
        }else{
            Write-Host '  The publisher OpenXR tool could not read a headset resolution.' -ForegroundColor Yellow
        }
        Write-Host '  Automatic detection is optional. Choose your headset below or' -ForegroundColor White
        Write-Host '  enter an exact per-eye size. Presets use native panel resolution;' -ForegroundColor Gray
        Write-Host '  an exact runtime value remains preferable when you know it.' -ForegroundColor Gray
        $fallback=Read-KCDResolutionFallback -Scale $scale
        if($fallback.Action -eq 'Retry'){continue}
        Write-Host ("  [OK] Using {0}: {1} x {2} per eye" -f $fallback.Source,$fallback.Width,$fallback.Height) -ForegroundColor Green
        return [pscustomobject]@{Width=[int]$fallback.Width;Height=[int]$fallback.Height}
    }
}
function New-KCDStage([string]$payload,[string]$stage,$options,$resolution,$render){
    if(-not(Test-KCDPayload $payload)){throw 'The publisher archive does not contain the functional KCD1VR runtime and configuration set.'};$dist=Join-Path $payload 'dist';$bin=Join-Path $stage 'Bin\Win64';[void][IO.Directory]::CreateDirectory($bin)
    foreach($n in @('dinput8.dll','nvngx_dlss.dll','LICENSE-NVIDIA.txt','KCD1VR.ini','KCD1VRResolution.exe')){if(Test-Path (Join-Path $dist $n)){Copy-Item (Join-Path $dist $n) (Join-Path $bin $n) -Force}};Get-ChildItem $dist -Filter 'KCD1VR*.cfg' -File|Copy-Item -Destination $stage -Force
    $qualityCode=@{UltraPerformance=3;Performance=0;Balanced=1;Quality=2;DLAA=5}[$options.Quality];$ini=Join-Path $bin 'KCD1VR.ini';$txt=[IO.File]::ReadAllText($ini);$txt=[regex]::Replace($txt,'(?m)^\s*DLSSQuality\s*=.*$',"DLSSQuality=$qualityCode");$txt=[regex]::Replace($txt,'(?m)^\s*DLSSRenderPreset\s*=.*$',"DLSSRenderPreset=$($options.Preset)");$txt=[regex]::Replace($txt,'(?m)^\s*DLSSOutputWidth\s*=.*$',"DLSSOutputWidth=$($resolution.Width)");$txt=[regex]::Replace($txt,'(?m)^\s*DLSSOutputHeight\s*=.*$',"DLSSOutputHeight=$($resolution.Height)");[IO.File]::WriteAllText($ini,$txt,[Text.UTF8Encoding]::new($false))
    $cfg=Join-Path $stage 'KCD1VR.cfg';$t=[IO.File]::ReadAllText($cfg);$t=[regex]::Replace($t,'(?m)^\s*r_Width\s*=.*$',"r_Width = $($render.Width)");$t=[regex]::Replace($t,'(?m)^\s*r_Height\s*=.*$',"r_Height = $($render.Height)");[IO.File]::WriteAllText($cfg,$t,[Text.UTF8Encoding]::new($false));return $stage
}
function Save-KCDSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot){
    $snapshotIdentity='kcd1vr';[void][IO.Directory]::CreateDirectory($SnapshotRoot);$paths=[Collections.Generic.List[string]]::new();$base=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/');foreach($file in @(Get-ChildItem -LiteralPath $Stage -File -Recurse -ErrorAction Stop)){$paths.Add($file.FullName.Substring($base.Length+1).Replace('/','\'))};$manifest=Join-Path $GameRoot ".pcvrhub_${snapshotIdentity}_ownership.csv";if(Test-Path -LiteralPath $manifest -PathType Leaf){try{foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$paths.Add([string]$row.RelativePath)}}}catch{}};foreach($extra in @(".pcvrhub_${snapshotIdentity}_ownership.csv",".pcvrhub_${snapshotIdentity}_ownership.csv.new",'.pcvrhub_version','user.cfg')){$paths.Add($extra)}
    $records=@();foreach($relative in @($paths|Select-Object -Unique)){$source=Join-Path $GameRoot $relative;$exists=Test-Path -LiteralPath $source -PathType Leaf;$key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_');$records+=[pscustomobject]@{Relative=$relative;Exists=$exists;Key=$key};if($exists){Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot $key) -Force -ErrorAction Stop}};$backup=Join-Path $GameRoot ".pcvrhub_${snapshotIdentity}_backup";$backupExists=Test-Path -LiteralPath $backup -PathType Container;if($backupExists){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force -ErrorAction Stop};[pscustomobject]@{Records=$records;BackupExists=$backupExists;Root=$SnapshotRoot}
}
function Restore-KCDSnapshot([string]$GameRoot,$Snapshot){foreach($record in @($Snapshot.Records)){$target=Join-Path $GameRoot ([string]$record.Relative);if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue};if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path $Snapshot.Root ([string]$record.Key)) -Destination $target -Force -ErrorAction Stop}};$backup=Join-Path $GameRoot '.pcvrhub_kcd1vr_backup';if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue};if($Snapshot.BackupExists){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force -ErrorAction Stop}}
function global:Invoke-KCD1VRInstaller {
    $work=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host '  Kingdom Come: Deliverance VR - Installer' -ForegroundColor Cyan;Write-Host '  Experimental stereo OpenXR, gamepad or keyboard/mouse' -ForegroundColor Gray;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Supports only Kingdom Come: Deliverance 1.9.7 on Steam.' -ForegroundColor Yellow;Write-Host '  Virtual Desktop/VDXR is not supported by the current release.' -ForegroundColor Yellow;Write-Host '  The modder plans to fix VDXR in the next mod release.' -ForegroundColor Yellow;Write-Host '  Use Meta Quest Link/Air Link with Oculus OpenXR. Motion controls are absent.' -ForegroundColor Yellow;Show-AntivirusNotice -Compact;[void](Wait-PCVRExplicitEnter -Message 'After reading these WIP limitations, press Enter to proceed...')
        Write-KCDStep 1 'Locating Kingdom Come: Deliverance';$game=Get-KCDRoot;if(-not $game){throw 'Setup was stopped before the game was changed.'};if(Get-Process -Name 'KingdomCome' -ErrorAction SilentlyContinue){throw 'Kingdom Come: Deliverance is running. Close it and retry.'};if(-not(Test-InstallerTargetWritable $game)){throw 'The game folder is not writable.'};Write-Host "  [OK] Found: $game" -ForegroundColor Green
        Write-KCDStep 2 'Getting the newest prerelease';$rel=Get-KCDRelease;if(-not(Test-IsTrackableInstalledVersion $rel.Tag)){throw 'GitHub supplied no trackable KCD1VR version.'};$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_kcd1_'+[guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work);$zip=Join-Path $work 'kcd1vr.zip';[void](Invoke-SafeDownload -Urls @($rel.Url) -Destination $zip -Label "KCD1VR $($rel.Tag)" -ManualUrl $rel.PageUrl -AllowSkip $false);$ext=Join-Path $work 'extract';[void](Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ext -Label 'KCD1VR release' -AllowSkip $false -QuietProgress);$payload=if(Test-KCDPayload $ext){$ext}else{Get-ChildItem $ext -Directory -Recurse|Where-Object{Test-KCDPayload $_.FullName}|Select-Object -First 1 -ExpandProperty FullName};if(-not $payload){throw 'The extracted release lacks the functional KCD1VR package.'};Write-Host "  [OK] Functional publisher package $($rel.Tag) verified." -ForegroundColor Green
        Write-KCDStep 3 'Choosing display and DLSS settings';$options=Get-KCDOptions;$resolution=Invoke-KCDResolution (Join-Path $payload 'dist\KCD1VRResolution.exe') $options.Scale $work;$ratio=@{UltraPerformance=(1.0/3.0);Performance=.5;Balanced=.58;Quality=(2.0/3.0);DLAA=1.0}[$options.Quality];$render=[pscustomobject]@{Width=[int][math]::Round($resolution.Width*$ratio);Height=[int][math]::Round($resolution.Height*$ratio)};Write-Host "  [OK] Output: $($resolution.Width) x $($resolution.Height); render: $($render.Width) x $($render.Height)" -ForegroundColor Green;$stage=New-KCDStage $payload (Join-Path $work 'stage') $options $resolution $render
        Write-KCDStep 4 'Installing a recoverable runtime transaction';$userCfg=Join-Path $game 'user.cfg';$snapshot=Save-KCDSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback');$changed=$true;[void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -KeepExistingRelativePaths @('Bin\Win64\KCD1VR.ini') -AdoptIdenticalExisting);Set-KCDManagedBlock $userCfg $render.Width $render.Height;$watch=@($REQUIRED|ForEach-Object{Join-Path $game $_})+@(Join-Path $game ".pcvrhub_${IDENTITY}_ownership.csv");if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)){throw 'Required KCD1VR files are missing after installation.'}
        Write-KCDStep 5 'Setting the required Steam launch parameters';Write-Host '  The command is copied to the clipboard and also printed below.' -ForegroundColor Gray;Write-Host '  Paste it into Steam Launch Options with Ctrl+V.' -ForegroundColor Yellow;Set-Clipboard -Value $LAUNCH -DeferManualFallback -ErrorAction SilentlyContinue;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to open Steam game properties...');Start-Process "steam://gameproperties/$APP_ID";Show-PCVRClipboardManualFallback -Text $LAUNCH;[void](Wait-PCVRExplicitEnter -Message 'Press Enter once you have pasted the launch parameters and closed Steam properties...')
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $rel.Tag -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route 'Current');$changed=$false
        Write-KCDStep 6 'Setup complete';Write-Host '  [OK] KCD1VR is installed, configured, versioned and recoverable.' -ForegroundColor Green;Write-Host '  Connect through Meta Quest Link/Air Link, then use Start in VR.' -ForegroundColor White;Write-Host '  Start in VR opens the game through Steam, which applies the launch options you saved.' -ForegroundColor White;Write-Host '  Virtual Desktop/VDXR is not supported by this release.' -ForegroundColor Yellow;Write-Host '';Write-Host '  Henry has come to see us, now at historically inconvenient scale.' -ForegroundColor Magenta;Write-Host '';[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{if($changed -and $game -and $snapshot){try{Restore-KCDSnapshot -GameRoot $game -Snapshot $snapshot;Write-Host '  [!!] The previous Kingdom Come VR state was restored.' -ForegroundColor Yellow}catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}};throw}finally{if($work -and (Test-Path $work)){Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_KCD1VR_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-KCD1VRInstaller}
