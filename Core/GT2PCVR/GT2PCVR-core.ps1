$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='Gran Turismo 2 PCVR Installer'
$script:GT2Id='gran-turismo-2-pcvr'
$script:GT2Repo='dubrovskiy-yevhen-stakelogic/gt-2-pc'
$script:GT2Page='https://github.com/dubrovskiy-yevhen-stakelogic/gt-2-pc/releases/tag/v0.9.0'
$script:GT2Version='v0.9.0'
$script:GT2Required=@('gt2game.exe','openxr_loader.dll','PLAY-PCVR.bat','PLAY-PCVR-META.bat','PLAY-PCVR-STEAMVR.bat','PLAY-PCVR-VD.bat')
function Test-GT2Runtime([string]$Root) {
    if(-not $Root -or -not(Test-Path -LiteralPath $Root -PathType Container)){return $false}
    foreach($relative in $script:GT2Required){if(-not(Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)){return $false}}
    foreach($mode in @('arcade','simulation')){
        if(Test-Path -LiteralPath (Join-Path $Root "$mode\disc.raw2352") -PathType Leaf){return $true}
    }
    return $false
}
function Set-GT2DesktopShortcut([string]$Target) {
    $desktop=if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $fixture=(''+$env:PCVR_GT2_TEST_DESKTOP).Trim()
        $full=if($fixture){[IO.Path]::GetFullPath($fixture)}else{''}
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full -or -not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'GT2 test desktop must be isolated under the temporary directory.'}
        $full
    }else{[Environment]::GetFolderPath('Desktop')}
    if(-not $desktop){throw 'The Desktop folder could not be found.'}
    [void][IO.Directory]::CreateDirectory($desktop)
    $launcher=Join-Path $Target 'PLAY-PCVR.bat'
    if(-not(Test-Path -LiteralPath $launcher -PathType Leaf)){throw 'The publisher PCVR launcher is missing.'}
    $icon=Join-Path $Target 'GranTurismo2VR.ico'
    if(-not(Test-Path -LiteralPath $icon -PathType Leaf)){
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'GranTurismo2VR.ico') -Destination $icon -ErrorAction Stop
    }
    $link=Join-Path $desktop 'Gran Turismo 2 PCVR.lnk'
    $shell=New-Object -ComObject WScript.Shell
    if(Test-Path -LiteralPath $link -PathType Leaf){
        $old=$shell.CreateShortcut($link)
        if(-not ([IO.Path]::GetFullPath($old.TargetPath)).Equals([IO.Path]::GetFullPath($launcher),[StringComparison]::OrdinalIgnoreCase)){
            return $false
        }
    }
    $created=New-DesktopShortcut -LnkPath $link -TargetPath $launcher -WorkingDir $Target -IconPath $icon -Description 'Launch Gran Turismo 2 in OpenXR VR'
    if(-not $created){throw 'The PCVR desktop shortcut could not be saved.'}
    $verify=$shell.CreateShortcut($link)
    if(-not ([IO.Path]::GetFullPath($verify.TargetPath)).Equals([IO.Path]::GetFullPath($launcher),[StringComparison]::OrdinalIgnoreCase) -or
       -not ([IO.Path]::GetFullPath($verify.WorkingDirectory)).Equals([IO.Path]::GetFullPath($Target),[StringComparison]::OrdinalIgnoreCase) -or
       -not $verify.IconLocation.StartsWith($icon,[StringComparison]::OrdinalIgnoreCase)){
        throw 'The PCVR desktop shortcut points at an unexpected target.'
    }
    return $true
}
function Get-GT2Target {
    $fixture=(''+$env:PCVR_GT2_TEST_TARGET).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){
        $full=[IO.Path]::GetFullPath($fixture)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'gt2-fixture.txt'))){throw 'GT2 test target must be isolated under the temporary directory.'}
        return $full
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GT2Id -StateNames @('installed_path','user_located') -ProbeFiles @('PLAY-PCVR.bat')
    if(Test-GT2Runtime $saved){return (Get-Item -LiteralPath $saved).FullName}
    $default=Join-Path $env:LOCALAPPDATA 'GT2-VR\runtime'
    if(Test-GT2Runtime $default){return (Get-Item -LiteralPath $default).FullName}
    return $default
}
function Get-GT2DiscImages {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GT2_TEST_DISC){
        if(-not(Test-Path -LiteralPath $env:PCVR_GT2_TEST_DISC -PathType Leaf)){throw 'The selected disc image is missing.'}
        return @([IO.Path]::GetFullPath($env:PCVR_GT2_TEST_DISC))
    }
    Write-Host '  Provide your own supported complete 2352-byte-sector GT2 disc image.' -ForegroundColor White
    Write-Host '  Arcade, Simulation, or both are supported. No game data or BIOS is downloaded.' -ForegroundColor Gray
    $images=New-Object 'System.Collections.Generic.List[string]'
    while($images.Count -lt 2){
        $prompt=if($images.Count -eq 0){'First disc path (BIN/CUE/ZIP/7Z; Q = cancel)'}else{'Second disc path (Enter = only one disc; Q = cancel)'}
        $raw=(''+(Read-Host $prompt)).Trim().Trim('"').Trim("'")
        if($raw -ieq 'Q'){return @()}
        if(-not $raw -and $images.Count -gt 0){break}
        if(-not $raw -or -not(Test-Path -LiteralPath $raw -PathType Leaf)){Write-Host '  File not found. Drag/paste a disc image path.' -ForegroundColor Yellow;continue}
        $full=[IO.Path]::GetFullPath($raw)
        if([IO.Path]::GetExtension($full).ToLowerInvariant() -notin @('.bin','.cue','.zip','.7z')){Write-Host '  Select BIN/CUE or a supported disc archive.' -ForegroundColor Yellow;continue}
        if($images.Contains($full)){Write-Host '  That disc is already selected.' -ForegroundColor Yellow;continue}
        $images.Add($full)
    }
    return @($images.ToArray())
}
function Get-GT2Release {
    $fixture=(''+$env:PCVR_GT2_TEST_ARCHIVE).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture){if(-not(Test-Path -LiteralPath $fixture -PathType Leaf)){throw 'The GT2 package fixture is missing.'};return [pscustomobject]@{Url=$fixture;Local=$true}}
    $asset=Resolve-GitHubReleaseAsset -Repo $script:GT2Repo -AssetPatterns @('(?i)^GT2-0\.9\.0\.zip$') `
        -FallbackUrl 'https://github.com/dubrovskiy-yevhen-stakelogic/gt-2-pc/releases/download/v0.9.0/GT2-0.9.0.zip' `
        -FallbackTag $script:GT2Version -FallbackAssetName 'GT2-0.9.0.zip' -SkipReleasesWithoutMatchingAsset
    if(-not $asset.Url){throw 'The pinned Windows PCVR release could not be resolved.'}
    return [pscustomobject]@{Url=[string]$asset.Url;Local=$false}
}
function Test-GT2Payload([string]$Root){
    foreach($relative in @('INSTALL-PCVR.bat','native\INSTALL-PCVR.bat','native\scripts\install-player.ps1','native\release-manifest.json','native\tools\gt2game.exe','native\tools\gt2install.exe','native\tools\gt2checks.exe','native\tools\openxr_loader.dll')){
        if(-not(Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)){return $false}
    }
    return $true
}
function Get-GT2PublisherDiagnostics([string]$Path){
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){return @()}
    $raw=[string](Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
    if(-not $raw){return @()}
    $plain=@($raw -split '\r?\n' | Where-Object { $_ -and $_ -notmatch '^\s*(?:#<\s*CLIXML|<\??xml|<Objs\b|<Obj\b|</Objs>)' })
    $serialized=@([regex]::Matches($raw,'<ToString>(.*?)</ToString>','Singleline') | ForEach-Object {
        [System.Net.WebUtility]::HtmlDecode($_.Groups[1].Value)
    })
    return @($plain + $serialized | Where-Object { $_ -and $_.Trim() } | Select-Object -Unique | Select-Object -Last 8)
}
function Invoke-GT2Publisher([string]$Payload,[string]$Target,[string[]]$Discs,[string]$Work){
    $mock=(''+$env:PCVR_GT2_TEST_PUBLISHER_OUTPUT).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $mock){
        $full=[IO.Path]::GetFullPath($mock);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'gt2-publisher-fixture.txt'))){throw 'Publisher fixture is invalid.'}
        [void][IO.Directory]::CreateDirectory($Target)
        foreach($item in @(Get-ChildItem -LiteralPath $full -Force)){if($item.Name -ne 'gt2-publisher-fixture.txt'){Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $Target $item.Name) -Recurse -Force -ErrorAction Stop}}
        return
    }
    $script=Join-Path $Payload 'native\scripts\install-player.ps1'
    $out=Join-Path $Work 'publisher-out.txt';$err=Join-Path $Work 'publisher-err.txt'
    $quote={param([string]$Value) "'"+$Value.Replace("'","''")+"'"}
    $discLiterals=@($Discs|ForEach-Object { & $quote $_ }) -join ','
    $command="`$ProgressPreference='SilentlyContinue'; & $(& $quote $script) -Target PCVR -InstallDir $(& $quote $Target) -NoBios -DiscImage @($discLiterals)"
    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $start=[Diagnostics.ProcessStartInfo]::new()
    $start.FileName='powershell.exe';$start.Arguments="-NoLogo -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
    $start.WorkingDirectory=$Payload;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $p=[Diagnostics.Process]::new();$p.StartInfo=$start
    if(-not $p.Start()){throw 'The publisher PCVR installer could not be started.'}
    $outStream=[IO.FileStream]::new($out,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite,1)
    $errStream=[IO.FileStream]::new($err,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite,1)
    $outTask=$p.StandardOutput.BaseStream.CopyToAsync($outStream)
    $errTask=$p.StandardError.BaseStream.CopyToAsync($errStream)
    Write-Host '  Publisher installer is running. Disc extraction and HD media preparation can take a while.' -ForegroundColor Cyan
    $lastStatus='';$lastStage='';$lastNotice=[DateTime]::MinValue
    try{
        while(-not $p.WaitForExit(3000)){
            $stage=if(Test-Path -LiteralPath $out){[string](Get-Content -LiteralPath $out -Tail 1 -ErrorAction SilentlyContinue)}else{''}
            if($stage -match '^(?:Ready:|PC game ready:)'){$stage=''}
            $status=if(Test-Path -LiteralPath $err){[string](Get-Content -LiteralPath $err -Tail 1 -ErrorAction SilentlyContinue)}else{''}
            if($status -match '(?i)(#<\s*CLIXML|<Objs\b|<Obj\b|</Objs>)'){$status=''}
            if($stage -and $stage -ne $lastStage){Write-Host "  $stage" -ForegroundColor White;$lastStage=$stage}
            if(([DateTime]::UtcNow-$lastNotice).TotalSeconds -ge 15){
                if($status -match '^\s*\d+(?:[.,]\d+)?%\s*$'){
                    Write-Host "  Publisher progress: $($status.Trim())" -ForegroundColor Cyan
                }elseif($status -and $status -ne $lastStatus){
                    Write-Host "  Publisher: $status" -ForegroundColor Yellow
                }else{Write-Host '  Publisher is still working on the selected disc data...' -ForegroundColor Cyan}
                $lastStatus=$status;$lastNotice=[DateTime]::UtcNow
            }
        }
        $p.WaitForExit()
        [void]$outTask.GetAwaiter().GetResult()
        [void]$errTask.GetAwaiter().GetResult()
        $outStream.Flush();$errStream.Flush()
        $exitCode=$p.ExitCode
    }finally{
        $outStream.Dispose();$errStream.Dispose();$p.Dispose()
    }
    if($null -eq $exitCode -or $exitCode -ne 0){
        $diagnostics=@(Get-GT2PublisherDiagnostics $err)
        if($diagnostics.Count){Write-Host ($diagnostics -join [Environment]::NewLine) -ForegroundColor Yellow}
    }else{Write-Host '  Publisher build finished. Verifying the PCVR runtime and disc data...' -ForegroundColor Cyan}
    if($null -eq $exitCode -or $exitCode -ne 0){throw "The publisher PCVR installer failed (exit $exitCode). Existing data remains in its own backup/staging folders."}
}
function Invoke-GT2Installer {
    $work=$null
    try{
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Gran Turismo 2 PCVR - Installer' -ForegroundColor Cyan
        Write-Host '  Native OpenXR port | own Arcade/Simulation discs required' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  This route is pinned to the last verified Windows PCVR' -ForegroundColor White
        Write-Host '  release v0.9.0. The complete native PCVR installer is included.' -ForegroundColor White
        Write-Host '  Publisher tools build game data from your own supported disc' -ForegroundColor White
        Write-Host '  image; saves and existing data are preserved on update.' -ForegroundColor White
        Write-Host '  No disc image, game data or BIOS is bundled with the Hub.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to select your disc image and installation folder...')
        $discs=@(Get-GT2DiscImages);if($discs.Count -eq 0){return}
        $target=Get-GT2Target
        if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name gt2game -ErrorAction SilentlyContinue)){throw 'Close GT2 PCVR before setup.'}
        Write-Host "  Target: $target" -ForegroundColor Cyan
        Write-Host '  The publisher package verifies and prepares disc data before' -ForegroundColor White
        Write-Host '  publishing a new runtime; its own backups retain old data.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the pinned publisher package...')
        $release=Get-GT2Release;$work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-gt2-'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work);$zip=Join-Path $work 'publisher.zip'
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $zip -Force -ErrorAction Stop}
        else{$ok=Invoke-SafeDownload -Urls @($release.Url) -Destination $zip -Label 'Gran Turismo 2 PCVR v0.9.0' -ManualUrl $script:GT2Page -AllowSkip:$false;if(-not $ok){throw 'The pinned PCVR package could not be downloaded.'}}
        Write-Host '  Extracting the publisher package. This may take several seconds.' -ForegroundColor Cyan
        $extract=Join-Path $work 'release';$result=Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $extract -Label 'GT2 PCVR package' -AllowSkip:$false -QuietProgress
        if([string]$result -notin @('ok','manual','retry')){throw 'The GT2 PCVR package could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'INSTALL-PCVR.bat'
        if(-not(Test-GT2Payload $payload)){throw 'The package lacks its Windows PCVR installer or native tools.'}
        Write-Host '  The publisher PCVR installer will verify the package and' -ForegroundColor White
        Write-Host '  selected discs, prepare the runtime and report any problem.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the publisher PCVR installer...')
        Invoke-GT2Publisher -Payload $payload -Target $target -Discs $discs -Work $work
        if(-not(Test-GT2Runtime $target)){throw 'Publisher installation ended without PCVR launchers, OpenXR loader or prepared disc data.'}
        $groups=@($script:GT2Required)+@('arcade\disc.raw2352|simulation\disc.raw2352')
        $contract=New-PCVRInstallerContract -Id $script:GT2Id -GameName 'Gran Turismo 2 PCVR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:GT2Page -RequiredInstalledFileGroups $groups
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version $script:GT2Version -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route PCVR)
        Write-Host '  [OK] Gran Turismo 2 PCVR v0.9.0 is installed.' -ForegroundColor Green
        try {
            if(Set-GT2DesktopShortcut $target){Write-Host '  [OK] Desktop shortcut starts PLAY-PCVR.bat.' -ForegroundColor Green}
            else{Write-Host '  A different desktop shortcut has the same name; it was left unchanged.' -ForegroundColor Yellow}
        } catch {Write-Host '  The PCVR runtime is ready, but its desktop shortcut could not be created.' -ForegroundColor Yellow}
        Write-Host '  Hub Play opens PLAY-PCVR.bat; runtime-specific launchers are' -ForegroundColor White
        Write-Host '  available beside it for Meta, SteamVR and Virtual Desktop.' -ForegroundColor White
        Write-Host ''
        Write-Host '  There are no shortcuts to the podium, only apexes.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $message="GT2 PCVR setup did not complete: $($_.Exception.Message)";Write-Host "  $message" -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    }finally{if($work -and (Test-Path -LiteralPath $work -PathType Container)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_GT2_LIBRARY_ONLY -ne '1'){Invoke-GT2Installer}
