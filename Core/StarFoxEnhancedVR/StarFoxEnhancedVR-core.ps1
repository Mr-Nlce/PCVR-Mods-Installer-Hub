$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$Host.UI.RawUI.WindowTitle='Star Fox Enhanced PCVR Installer'
$script:Id='star-fox-enhanced-vr'
$script:Title='Star Fox Enhanced PCVR'
$script:Required=@('starfox_pcvr.exe','starfox_asset_builder.exe','BUILD-ASSETS.bat','LAUNCH-PCVR.bat','START-HERE.txt')
function Test-StarFoxPayload([string]$Root) {
    if(-not $Root){return $false}
    foreach($relative in $script:Required){if(-not(Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)){return $false}}
    return $true
}
function Resolve-StarFoxTarget([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
    if((Split-Path -Leaf $full) -cne 'Star Fox Enhanced PCVR'){$full=Join-Path $full 'Star Fox Enhanced PCVR'}
    $parent=Split-Path -Parent $full
    if(-not $parent -or $parent -eq [IO.Path]::GetPathRoot($full) -and $full -eq $parent){throw 'Choose a folder beneath a games directory.'}
    if($full -match '^[A-Za-z]:\\(?:Windows|Program Files(?: \(x86\))?)(?:\\|$)'){throw 'Choose a writable games folder.'}
    return $full
}
function Get-StarFoxFolder {
    $test=(''+$env:PCVR_STARFOX_TEST_TARGET).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){
        $full=Resolve-StarFoxTarget $test
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'The test target must stay inside the temporary directory.'}
        return $full
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:Id -StateNames @('installed_path','user_located') -ProbeFiles @('LAUNCH-PCVR.bat')
    if($saved -and (Test-Path -LiteralPath $saved -PathType Container)){return Resolve-StarFoxTarget $saved}
    Write-Host '  Choose a writable folder for this standalone PCVR port.' -ForegroundColor White
    Write-Host '  Its generated assets and saves stay there. Do not use Program Files.' -ForegroundColor Yellow
    while($true){
        $choice=(''+(Read-Host 'Folder (Enter = C:\Games\Star Fox Enhanced PCVR; Q = cancel)')).Trim().Trim('"')
        if($choice -in @('q','Q','quit')){return $null}
        if(-not $choice){$choice='C:\Games\Star Fox Enhanced PCVR'}
        try{return Resolve-StarFoxTarget $choice}catch{Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow}
    }
}
function Get-StarFoxRom {
    $test=(''+$env:PCVR_STARFOX_TEST_ROM).Trim()
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $test){if(Test-Path -LiteralPath $test -PathType Leaf){return [IO.Path]::GetFullPath($test)};throw 'The isolated ROM fixture is missing.'}
    Write-Host '  Select your own unmodified retail Star Fox / Starwing SNES ROM.' -ForegroundColor White
    Write-Host '  No ROM or Nintendo data is downloaded, retained by the Hub, or bundled.' -ForegroundColor Gray
    while($true){
        $choice=(''+(Read-Host 'ROM path, or Q to cancel')).Trim().Trim('"')
        if($choice -in @('q','Q','quit')){return $null}
        if($choice -and (Test-Path -LiteralPath $choice -PathType Leaf)){return [IO.Path]::GetFullPath($choice)}
        Write-Host '  File not found. Drag the ROM onto this window or paste its path.' -ForegroundColor Yellow
    }
}
function Invoke-StarFoxBuilder([string]$Builder,[string]$Rom,[string]$Bundle,[string]$Work) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_STARFOX_TEST_BUILDER){$Builder=$env:PCVR_STARFOX_TEST_BUILDER}
    $start=[Diagnostics.ProcessStartInfo]::new()
    $start.FileName=$Builder
    $start.Arguments=('"'+$Rom+'" "'+$Bundle+'"')
    $start.WorkingDirectory=Split-Path -Parent $Builder
    $start.UseShellExecute=$false
    $start.RedirectStandardOutput=$true
    $start.RedirectStandardError=$true
    $p=[Diagnostics.Process]::new();$p.StartInfo=$start
    try {
        if(-not $p.Start()){throw 'The asset builder did not start.'}
        $outTask=$p.StandardOutput.ReadToEndAsync();$errTask=$p.StandardError.ReadToEndAsync()
        $p.WaitForExit();$out=$outTask.Result;$err=$errTask.Result
        $exitCode=$p.ExitCode
    } finally { $p.Dispose() }
    if($out){Write-Host $out.TrimEnd()}
    if($err){Write-Host $err.TrimEnd() -ForegroundColor Yellow}
    if($exitCode -ne 0){throw "The asset builder failed (exit $exitCode). Check your own supported ROM and the log above."}
    if(-not(Test-Path -LiteralPath $Bundle -PathType Leaf) -or (Get-Item -LiteralPath $Bundle).Length -eq 0){throw 'The asset builder did not create Starfox-Assets.BIN.'}
}
function Invoke-StarFoxInstaller {
    $work=$null;$target=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ' Star Fox Enhanced PCVR - Installer' -ForegroundColor Cyan
        Write-Host ' OpenXR alpha | your own Star Fox / Starwing ROM required' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' The complete PCVR package includes the matching asset builder.' -ForegroundColor White
        Write-Host ' A fresh asset bundle is built from your ROM for every update.' -ForegroundColor White
        Write-Host ' Existing VR saves, settings and optional music are kept.' -ForegroundColor White
        Write-Host ' Close Star Fox Enhanced before installing.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to select your folder and ROM, then download the PCVR package...')
        $target=Get-StarFoxFolder;if(-not $target){return}
        $rom=Get-StarFoxRom;if(-not $rom){return}
        if(Get-Process -Name starfox_pcvr -ErrorAction SilentlyContinue){throw 'Close Star Fox Enhanced PCVR before setup.'}
        $local=(''+$env:PCVR_STARFOX_TEST_ARCHIVE).Trim()
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $local){$release=[pscustomobject]@{Tag='v0.0.8';Url=$local;PageUrl='https://github.com/kandowontu2/starfox-enhanced/releases';Local=$true}}
        else{
            $asset=Resolve-GitHubReleaseAsset -Repo 'kandowontu2/starfox-enhanced' -IncludePrerelease $true -AssetPatterns @('(?i)^StarFoxEnhanced-[0-9].*-windows-pcvr\.zip$') -FallbackUrl 'https://github.com/kandowontu2/starfox-enhanced/releases/download/v0.0.8.6/StarFoxEnhanced-0.0.8.6-windows-pcvr.zip' -FallbackTag 'v0.0.8.6' -FallbackAssetName 'StarFoxEnhanced-0.0.8.6-windows-pcvr.zip' -SkipReleasesWithoutMatchingAsset
            $release=[pscustomobject]@{Tag=[string]$asset.Tag;Url=[string]$asset.Url;PageUrl=[string]$asset.PageUrl;Local=$false}
        }
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_starfox_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'publisher.zip'
        Write-Host '';Write-Host '--- [1/3] Download and verify the PCVR release ---' -ForegroundColor Cyan
        if($release.Local){Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop}
        else{$got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "Star Fox Enhanced $($release.Tag) PCVR" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false;if(-not($got -eq $true -or [string]$got -in @('retry','manual'))){throw 'No PCVR release ZIP was downloaded.'}}
        $extract=Join-Path $work 'release';$result=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Star Fox Enhanced PCVR' -AllowSkip $false -QuietProgress
        if([string]$result -notin @('ok','manual','retry')){throw 'The PCVR ZIP could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'starfox_pcvr.exe'
        if(-not(Test-StarFoxPayload $payload)){throw 'The package lacks the player, matching builder or launcher.'}
        Write-Host '';Write-Host '--- [2/3] Install the matching player and create assets ---' -ForegroundColor Cyan
        if(Test-Path -LiteralPath $target -PathType Container){
            $item=Get-Item -LiteralPath $target -Force
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'A linked installation folder cannot be changed safely.'}
        }
        $snapshot=Join-Path $work 'rollback';[void][IO.Directory]::CreateDirectory($snapshot)
        $before=Test-Path -LiteralPath $target -PathType Container
        if($before){foreach($item in @(Get-ChildItem -LiteralPath $target -Force)){Copy-Item -LiteralPath $item.FullName -Destination $snapshot -Recurse -Force -ErrorAction Stop}}
        [void][IO.Directory]::CreateDirectory($target);$changed=$true
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity 'starfoxenhanced' -AdoptIdenticalExisting)
        $bundle=Join-Path $target 'Starfox-Assets.BIN'
        if(Test-Path -LiteralPath $bundle -PathType Leaf){Remove-Item -LiteralPath $bundle -Force -ErrorAction Stop}
        Invoke-StarFoxBuilder -Builder (Join-Path $target 'starfox_asset_builder.exe') -Rom $rom -Bundle $bundle -Work $work
        Write-Host '';Write-Host '--- [3/3] Verify and record this release ---' -ForegroundColor Cyan
        foreach($name in $script:Required){if(-not(Test-Path -LiteralPath (Join-Path $target $name) -PathType Leaf)){throw "Missing required player file: $name"}}
        $contract=New-PCVRInstallerContract -Id $script:Id -GameName $script:Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl ([string]$release.PageUrl) -RequiredInstalledFileGroups (@($script:Required)+@('Starfox-Assets.BIN','.pcvrhub_starfoxenhanced_ownership.csv'))
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $changed=$false
        Write-Host "  [OK] $($release.Tag) is installed with assets from your own ROM." -ForegroundColor Green
        Write-Host '  Hub Play opens LAUNCH-PCVR.bat. Connect OpenXR and your headset first.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Good luck, Fox. Slippy promised to stay out of the way this time.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $target -and $snapshot){
            try{
                $full=[IO.Path]::GetFullPath($target).TrimEnd([char[]]'\/')
                if((Split-Path -Leaf $full) -cne 'Star Fox Enhanced PCVR'){throw 'Rollback target is not the dedicated Star Fox Enhanced folder.'}
                if($full -and (Test-Path -LiteralPath $full -PathType Container)){Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop}
                if($before){[void][IO.Directory]::CreateDirectory($full);foreach($item in @(Get-ChildItem -LiteralPath $snapshot -Force)){Copy-Item -LiteralPath $item.FullName -Destination $full -Recurse -Force -ErrorAction Stop}}
                Write-Host '  [!!] The previous installation was restored.' -ForegroundColor Yellow
            }catch{Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow}
        }
        Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red;throw
    }finally{if($work -and (Test-Path -LiteralPath $work -PathType Container)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if($env:PCVR_STARFOX_LIBRARY_ONLY -ne '1'){Invoke-StarFoxInstaller}
