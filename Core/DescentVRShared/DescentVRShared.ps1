$ErrorActionPreference = 'Stop'
$script:DescentRepo = 'GameOrDie007/Descent-1-and-2-VR'
$script:DescentPage = 'https://github.com/GameOrDie007/Descent-1-and-2-VR/releases'
$script:DescentCore = Split-Path -Parent $PSScriptRoot

function Get-DescentDefinition([string]$Key) {
    switch ($Key) {
        d1 { return @{ Key='d1'; Id='descent-vr'; Title='Descent VR'; Name='Descent'; SteamId='273570'; SteamFolder='Descent'; Gog='Descent'; Hog='descent.hog'; Companion='descent.pig'; Engine='d1x-redux.exe'; Launcher='Descent VR.cmd'; Flat='Descent (flat).cmd'; Shortcut='Descent VR.lnk'; Folder='DescentVR'; Quip='The tunnels have six directions. Good luck remembering which way is up.'; Fallbacks=@('C:\Program Files (x86)\Steam\steamapps\common\Descent','C:\Program Files (x86)\GOG Galaxy\Games\Descent','C:\GOG Games\Descent','C:\GAMES\DESCENT') } }
        d2 { return @{ Key='d2'; Id='descent-2-vr'; Title='Descent 2 VR'; Name='Descent 2'; SteamId='273580'; SteamFolder='Descent 2'; Gog='Descent 2'; Hog='descent2.hog'; Companion='descent2.ham'; Engine='d2x-redux.exe'; Launcher='Descent 2 VR.cmd'; Flat='Descent 2 (flat).cmd'; Shortcut='Descent 2 VR.lnk'; Folder='Descent2VR'; Quip='Guide-bot knows the way out. Whether it tells you is another matter.'; Fallbacks=@('C:\Program Files (x86)\Steam\steamapps\common\Descent 2','C:\Program Files (x86)\GOG Galaxy\Games\Descent 2','C:\GOG Games\Descent 2','C:\GAMES\DESCENT2') } }
        default { throw "Unknown Descent game: $Key" }
    }
}

function Assert-DescentTestPath([string]$Path,[string]$Marker='descent-fixture.txt') {
    $full=[IO.Path]::GetFullPath($Path)
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full $Marker) -PathType Leaf)) { throw 'Descent test input must be inside a marked temporary fixture.' }
    return $full
}

function Get-DescentBase([hashtable]$Definition,[string]$Root) {
    if(-not $Root -or -not(Test-Path -LiteralPath $Root -PathType Container)){return $null}
    $full=[IO.Path]::GetFullPath($Root)
    $candidates=@($full)+@(Get-ChildItem -LiteralPath $full -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
    foreach($data in $candidates){
        if((Test-Path -LiteralPath (Join-Path $data $Definition.Hog) -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $data $Definition.Companion) -PathType Leaf)){
            return [pscustomobject]@{ Root=$full; Data=$data }
        }
    }
    return $null
}

function Find-DescentBase([hashtable]$Definition) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_GAME){
        return Get-DescentBase $Definition (Assert-DescentTestPath $env:PCVR_DESCENT_TEST_GAME)
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $Definition.Id -StateNames @('base_game_path','user_located')
    $roots=New-Object 'System.Collections.Generic.List[string]'
    if($saved){$roots.Add($saved)}
    try { $steam=Find-SteamGameFolder -AppId $Definition.SteamId -SteamFolderNames @($Definition.SteamFolder) -GogNames @($Definition.Gog) -HubGameId $Definition.Id; if($steam){$roots.Add($steam)} } catch {}
    foreach($path in $Definition.Fallbacks){$roots.Add($path)}
    foreach($root in @($roots | Where-Object {$_} | Select-Object -Unique)){
        $found=Get-DescentBase $Definition $root
        if($found){return $found}
    }
    return $null
}

function Get-DescentRuntime([hashtable]$Definition,[string]$GameRoot) {
    $roots=New-Object 'System.Collections.Generic.List[string]'
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_RUNTIME){$roots.Add((Assert-DescentTestPath $env:PCVR_DESCENT_TEST_RUNTIME))}
    if($GameRoot){$roots.Add((Join-Path $GameRoot 'VR'))}
    if($env:PCVR_HUB_TEST_MODE -ne '1'){$roots.Add((Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('Descent 1 and 2 VR\'+$Definition.Name)))}
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_RECEIPT){
        $testReceipt=[IO.Path]::GetFullPath($env:PCVR_DESCENT_TEST_RECEIPT)
        [void](Assert-DescentTestPath (Split-Path -Parent $testReceipt))
        $testReceipt
    }elseif($env:PCVR_HUB_TEST_MODE -eq '1'){''}else{Join-Path (Join-Path $script:DescentCore $Definition.Folder) '.installed_path'}
    if($receipt -and (Test-Path -LiteralPath $receipt -PathType Leaf)){try{$roots.Add((Get-Content -LiteralPath $receipt -Raw).Trim())}catch{}}
    foreach($root in @($roots | Where-Object {$_} | Select-Object -Unique)){
        if(-not(Test-Path -LiteralPath $root -PathType Container)){continue}
        $required=@("game\$($Definition.Engine)",'game\GameOrDieXR.dll','game\openxr_loader.dll',$Definition.Launcher,$Definition.Flat,'tools\setup.ps1','version.txt','install-manifest.txt')
        $missing=@($required | Where-Object { -not(Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf) })
        if($missing.Count){continue}
        $versionLine=(Get-Content -LiteralPath (Join-Path $root 'version.txt') -TotalCount 1 -ErrorAction SilentlyContinue)
        if($versionLine -notmatch '^Descent 1 & 2 VR (?<version>\d+(?:\.\d+){1,3}(?:[-.][0-9A-Za-z.]+)?)$'){continue}
        return [pscustomobject]@{Root=[IO.Path]::GetFullPath($root);Version=$Matches.version;Stamp=(Get-Item -LiteralPath (Join-Path $root 'version.txt')).LastWriteTimeUtc.Ticks}
    }
    return $null
}

function Get-DescentRelease {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_ARCHIVE){
        $archive=[IO.Path]::GetFullPath($env:PCVR_DESCENT_TEST_ARCHIVE)
        [void](Assert-DescentTestPath (Split-Path -Parent $archive))
        if(-not(Test-Path -LiteralPath $archive -PathType Leaf)){throw 'Descent test archive is missing.'}
        return [pscustomobject]@{Url=$archive;Version='1.0';Name=[IO.Path]::GetFileName($archive);Local=$true}
    }
    $asset=Resolve-GitHubReleaseAsset -Repo $script:DescentRepo -AssetPatterns @('(?i)^Descent-1-and-2-VR-\d+(?:\.\d+){1,3}(?:[-.][0-9A-Za-z.]+)?-PCVR\.zip$') -SkipReleasesWithoutMatchingAsset
    if(-not $asset.Url -or $asset.AssetName -notmatch '(?i)^Descent-1-and-2-VR-(?<version>\d+(?:\.\d+){1,3}(?:[-.][0-9A-Za-z.]+)?)-PCVR\.zip$'){throw 'No versioned Descent 1 and 2 VR release ZIP was found.'}
    return [pscustomobject]@{Url=[string]$asset.Url;Version=$Matches.version;Name=[string]$asset.AssetName;Local=$false}
}

function Get-DescentPayload([string]$Extracted,[hashtable]$Definition){
    $roots=@($Extracted)+@(Get-ChildItem -LiteralPath $Extracted -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
    foreach($root in $roots){
        $required=@('Setup.bat','Uninstall.bat','README.txt','LICENSE-GameOrDie.txt','files\setup.ps1','files\d1\d1x-redux.exe','files\d1\GameOrDieXR.dll','files\d1\openxr_loader.dll','files\d2\d2x-redux.exe','files\d2\GameOrDieXR.dll','files\d2\openxr_loader.dll')
        if(@($required|Where-Object{-not(Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf)}).Count -eq 0){return $root}
    }
    throw 'The archive is missing the complete publisher Setup or one of its game runtimes.'
}

function Invoke-DescentPublisher([string]$Payload,[string]$GameRoot,[string]$Work) {
    $publisher=Join-Path $Payload 'files\setup.ps1'
    $quote={param([string]$value) "'"+$value.Replace("'","''")+"'"}
    $command="& $(& $quote $publisher) -Quiet -Json -NoSteam -GamePath $(& $quote $GameRoot)"
    if($env:PCVR_HUB_TEST_MODE -eq '1'){$command+=' -NoShortcuts'}
    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $out=Join-Path $Work 'publisher-out.txt';$err=Join-Path $Work 'publisher-err.txt'
    $start=[Diagnostics.ProcessStartInfo]::new()
    $start.FileName='powershell.exe';$start.Arguments="-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
    $start.WorkingDirectory=$Payload;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $p=[Diagnostics.Process]::new();$p.StartInfo=$start
    if(-not $p.Start()){throw 'Publisher Setup could not start.'}
    $outStream=[IO.FileStream]::new($out,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
    $errStream=[IO.FileStream]::new($err,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
    $outTask=$p.StandardOutput.BaseStream.CopyToAsync($outStream)
    $errTask=$p.StandardError.BaseStream.CopyToAsync($errStream)
    try{
        while(-not $p.WaitForExit(3000)){Write-Host '  Publisher Setup is still working on the VR files...' -ForegroundColor Cyan}
        $p.WaitForExit();[void]$outTask.GetAwaiter().GetResult();[void]$errTask.GetAwaiter().GetResult()
        $exitCode=$p.ExitCode
    }finally{$outStream.Dispose();$errStream.Dispose();$p.Dispose()}
    if($null -eq $exitCode -or $exitCode -ne 0){
        $detail=if(Test-Path -LiteralPath $err){((Get-Content -LiteralPath $err -Tail 4 -ErrorAction SilentlyContinue) -join ' ')}else{''}
        throw "Publisher Setup failed (exit $exitCode). $detail"
    }
    return [string](Get-Content -LiteralPath $out -Raw -ErrorAction SilentlyContinue)
}

function Invoke-DescentInstaller([string]$Key){
    $d=Get-DescentDefinition $Key
    $contract=New-PCVRInstallerContract -Id $d.Id -GameName $d.Title -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:DescentPage -RequiredInstalledFileGroups @("game\$($d.Engine)",'game\GameOrDieXR.dll','game\openxr_loader.dll',$d.Launcher,$d.Flat,'tools\setup.ps1','version.txt','install-manifest.txt')
    $work=$null
    try{
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host "  $($d.Title) - Game Or Die OpenXR setup" -ForegroundColor Cyan
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Your original Descent game files are required (Steam, GOG or CD).' -ForegroundColor White
        Write-Host '  The publisher writes VR files beside the game, or in Documents' -ForegroundColor White
        Write-Host '  if the game folder is protected. Saves and settings remain yours.' -ForegroundColor White
        Write-Host '  A publisher desktop shortcut is created. Steam-library entries' -ForegroundColor White
        Write-Host '  are not added by this guided Hub route.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate the original game and check the release...')
        $base=Find-DescentBase $d
        while(-not $base){
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw "Original $($d.Name) data was not found."}
            Write-Host "  Select your $($d.Name) install folder containing $($d.Hog) and $($d.Companion)." -ForegroundColor Yellow
            $answer=(''+(Read-Host 'Game folder (Q = cancel)')).Trim().Trim('"')
            if($answer -ieq 'Q'){throw 'Setup cancelled before changing any game files.'}
            $base=Get-DescentBase $d $answer
            if(-not $base){Write-Host '  These original game data files were not found there.' -ForegroundColor Yellow}
        }
        Write-Host "  [OK] Original data: $($base.Data)" -ForegroundColor Green
        $before=Get-DescentRuntime $d $base.Root
        $manual=Get-PCVRRecoveryInput -PathType Leaf
        try{$release=Get-DescentRelease}catch{
            if(-not $manual){throw}
            $release=[pscustomobject]@{Url=$manual;Version='';Name=[IO.Path]::GetFileName($manual);Local=$true}
            Write-Host '  Online release lookup is unavailable; the selected publisher ZIP will be verified after setup.' -ForegroundColor Yellow
        }
        if($release.Version){Write-Host "  [OK] Publisher release: $($release.Version)" -ForegroundColor Green}
        Write-Host '  Download and setup may take a few minutes. Progress will stay visible.' -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download and prepare the publisher ZIP...')
        $choice=Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes 30000000L
        if(-not $choice.BasePath){throw 'No writable temporary location has enough free space.'}
        $work=New-PCVRInstallerTempSession -BasePath $choice.BasePath
        $zip=Join-Path $work $release.Name
        if($manual){Copy-Item -LiteralPath $manual -Destination $zip -Force -ErrorAction Stop}
        elseif($release.Local){Copy-Item -LiteralPath $release.Url -Destination $zip -Force -ErrorAction Stop}
        else{
            $ok=Invoke-SafeDownload -Urls @($release.Url) -Destination $zip -Label "Descent 1 and 2 VR $($release.Version)" -ManualUrl $script:DescentPage -AllowSkip:$false
            if(-not $ok){throw 'The publisher ZIP download did not complete.'}
        }
        if(-not(Test-DownloadedPayload -Path $zip -IntendedPath $release.Name)){throw 'The downloaded ZIP is not usable.'}
        $extract=Join-Path $work 'extracted'
        $status=Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $extract -Label 'Descent VR package' -AllowSkip:$false
        if([string]$status -notin @('ok','manual')){throw 'The publisher ZIP could not be extracted.'}
        $payload=Get-DescentPayload $extract $d
        Write-Host '  [OK] Both publisher runtimes and Setup are present.' -ForegroundColor Green
        Write-Host "  Setup now installs only $($d.Name), then verifies its own VR folder." -ForegroundColor White
        Write-Host '  This can take a little while. The publisher output is being captured.' -ForegroundColor Cyan
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run publisher Setup...')
        $publisherOutput=Invoke-DescentPublisher -Payload $payload -GameRoot $base.Root -Work $work
        Write-Host '  Publisher Setup returned; checking its installed files...' -ForegroundColor Cyan
        $after=Get-DescentRuntime $d $base.Root
        if(-not $after -or ($release.Version -and $after.Version -ne $release.Version)){throw 'Setup did not produce a complete runtime with the expected version. No success was recorded.'}
        if($before -and $before.Root -ieq $after.Root -and $before.Version -eq $after.Version -and $before.Stamp -eq $after.Stamp){throw 'Setup did not change the selected game. No new completion was recorded.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DESCENT_TEST_RECEIPT){
            $testReceipt=[IO.Path]::GetFullPath($env:PCVR_DESCENT_TEST_RECEIPT)
            [void](Assert-DescentTestPath (Split-Path -Parent $testReceipt))
            $testReceipt
        }else{Join-Path (Join-Path $script:DescentCore $d.Folder) '.installed_path'}
        Save-DescentOwnedHashes -Runtime $after.Root
        if($env:PCVR_HUB_TEST_MODE -ne '1'){
            if(-not(Save-HubRememberedGameFolder -GameId $d.Id -Title $d.Title -GameDir $base.Root -ProbeFiles @() -StateName 'base_game_path')){throw 'Original game path could not be saved for later scans.'}
        }
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $after.Root -Version $after.Version -Route Current -InstalledPathReceiptPaths @($receipt))
        Write-Host "  [OK] $($d.Title) $($after.Version): $($after.Root)" -ForegroundColor Green
        Write-Host "  Start in VR opens $($d.Launcher). Put on your headset first." -ForegroundColor White
        Write-Host ''
        Write-Host "  $($d.Quip)" -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }finally{if($work){try{Remove-PCVRInstallerTempSession -Path $work}catch{}}}
}

function Save-DescentOwnedHashes([string]$Runtime){
    $manifest=Join-Path $Runtime 'install-manifest.txt'
    $list=@(Get-Content -LiteralPath $manifest | Where-Object {$_ -and -not $_.StartsWith('#')})
    $hashes=[ordered]@{}
    foreach($rel in $list){
        $safe=Resolve-DescentOwnedFile -Runtime $Runtime -Relative $rel
        if(Test-Path -LiteralPath $safe -PathType Leaf){$hashes[$rel]=[string](Get-FileHash -LiteralPath $safe -Algorithm SHA256).Hash}
    }
    $json=$hashes|ConvertTo-Json -Depth 3
    Write-PCVRAtomicText -Path (Join-Path $Runtime '.pcvrhub_descent_owned.json') -Value $json
}

function Resolve-DescentOwnedFile([string]$Runtime,[string]$Relative){
    if(-not $Relative -or [IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)'){throw 'Publisher manifest has an unsafe path.'}
    $root=[IO.Path]::GetFullPath($Runtime).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    $full=[IO.Path]::GetFullPath((Join-Path $Runtime $Relative))
    if(-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Publisher manifest escapes the VR folder.'}
    return $full
}
