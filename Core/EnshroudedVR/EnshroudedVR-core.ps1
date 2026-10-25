$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')

$Host.UI.RawUI.WindowTitle='Enshrouded VR Installer'
$script:EVRId='enshrouded-vr'
$script:EVRRepo='momotori01/ENSHROUDED-VR-MOD'
$script:EVRPage='https://github.com/momotori01/ENSHROUDED-VR-MOD/releases'
$script:EVRIdentity='enshroudedvr'
$script:EVRRequired=@('enshrouded.exe','dinput8.dll','Enshrouded VR setting.exe',
    'EnshroudedVR\bin\evr_hooks.dll','EnshroudedVR\bin\openxr_loader.dll',
    'EnshroudedVR\version.txt','EnshroudedVR\EnshroudedVR.ini',
    '.pcvrhub_enshroudedvr_ownership.csv')
$script:EVRContract=New-PCVRInstallerContract -Id $script:EVRId -GameName 'Enshrouded VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:EVRPage -Routes @('Steam') `
    -RequiredInstalledFileGroups $script:EVRRequired

function Test-EVRGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'enshrouded.exe') -PathType Leaf))
}
function Test-EVRGameBuild([string]$Game,[string]$ExpectedHash) {
    if($ExpectedHash -notmatch '^[a-fA-F0-9]{64}$'){return $false}
    $exe=Join-Path $Game 'enshrouded.exe'
    if(-not(Test-Path -LiteralPath $exe -PathType Leaf)){return $false}
    return ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ieq $ExpectedHash)
}
function Get-EVRPublisherOwnedUpdates {
    param([string]$Game,[switch]$SyncOwnership)
    $ownership=Join-Path $Game '.pcvrhub_enshroudedvr_ownership.csv'
    $publisher=Join-Path $Game 'EnshroudedVR\PACKAGE_MANIFEST.json'
    if(-not(Test-Path -LiteralPath $ownership) -or -not(Test-Path -LiteralPath $publisher)){return}
    $metadata=Get-Content -LiteralPath $publisher -Raw -Encoding UTF8|ConvertFrom-Json
    $declared=@{}
    foreach($file in @($metadata.files)){
        $relative=Assert-PCVROwnedRelativePath -Relative ([string]$file.path)
        $declared[$relative]=[string]$file.sha256
    }
    $rows=@(Import-Csv -LiteralPath $ownership -ErrorAction Stop)
    $changed=@()
    foreach($row in $rows){
        $relative=Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)
        if(-not $declared.ContainsKey($relative) -or $declared[$relative] -notmatch '^[a-fA-F0-9]{64}$'){continue}
        $target=Join-OwnedRelativePath $Game $relative
        if(-not(Test-Path -LiteralPath $target -PathType Leaf)){continue}
        $actual=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        # Positive ownership evidence for a previously owned file after the
        # publisher's own updater. No download is accepted/rejected here.
        if($actual -ieq $declared[$relative] -and $actual -ine $row.InstalledSha256){
            $changed+=$relative
            $row.InstalledSha256=$actual
        }
    }
    if($SyncOwnership -and $changed.Count){
        $rows|Export-Csv -LiteralPath ($ownership+'.new') -NoTypeInformation -Encoding UTF8
        Move-Item -LiteralPath ($ownership+'.new') -Destination $ownership -Force
    }
    return $changed
}
function Get-EVRGame {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_EVR_TEST_GAME) {
        $root=[IO.Path]::GetFullPath($env:PCVR_EVR_TEST_GAME)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if (-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path $root 'evr-fixture.txt') -PathType Leaf) -or
            -not (Test-EVRGame $root)) { throw 'Enshrouded test game must be an isolated fixture.' }
        return $root
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:EVRId -StateNames @('installed_path','user_located') -ProbeFiles @('enshrouded.exe')
    if (Test-EVRGame $saved) { return [IO.Path]::GetFullPath($saved) }
    $steam=Find-SteamGameFolder -AppId '1203620' -SteamFolderNames @('Enshrouded') -ProbeExe 'enshrouded.exe' -HubGameId $script:EVRId
    if (Test-EVRGame $steam) { return [IO.Path]::GetFullPath($steam) }
    $default='C:\Program Files (x86)\Steam\steamapps\common\Enshrouded'
    if (Test-EVRGame $default) { return $default }
    $picked=Get-GameFolderInteractive -GameName 'Enshrouded (Steam)' -ProbeFile 'enshrouded.exe'
    if (Test-EVRGame $picked) {
        [void](Save-HubRememberedGameFolder -GameId $script:EVRId -Title 'Enshrouded VR' -GameDir $picked -ProbeFiles @('enshrouded.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose the Steam Enshrouded folder containing enshrouded.exe.'
}
function Get-EVRArchiveInfo([string]$Path) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try {
            $entries=@{}
            foreach($item in $zip.Entries){$entries[$item.FullName.Replace('\','/')]=$item}
            foreach($required in @('dinput8.dll','Enshrouded VR setting.exe',
                'EnshroudedVR/PACKAGE_MANIFEST.json','EnshroudedVR/version.txt',
                'EnshroudedVR/bin/evr_hooks.dll','EnshroudedVR/bin/openxr_loader.dll')) {
                if (-not $entries.ContainsKey($required)) { return $null }
            }
            $entry=$entries['EnshroudedVR/PACKAGE_MANIFEST.json']
            $reader=[IO.StreamReader]::new($entry.Open())
            try { $manifest=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
            if (-not (Test-IsTrackableInstalledVersion ([string]$manifest.version)) -or
                [string]$manifest.game_exe_sha256 -notmatch '^[a-fA-F0-9]{64}$') { return $null }
            return [pscustomobject]@{ Version=[string]$manifest.version; GameHash=[string]$manifest.game_exe_sha256 }
        } finally { $zip.Dispose() }
    } catch { return $null }
}
function Get-EVRArchive([string]$Destination) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_EVR_TEST_ARCHIVE) {
        Copy-Item -LiteralPath $env:PCVR_EVR_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop
        return (Get-EVRArchiveInfo $Destination)
    }
    $release=Resolve-GitHubReleaseAsset -Repo $script:EVRRepo -AssetPatterns @('(?i)^EnshroudedVR-[0-9]+(?:\.[0-9]+)+\.zip$') -SkipReleasesWithoutMatchingAsset
    if (-not $release.Resolved -or -not $release.Url) {
        throw 'The current Enshrouded VR release could not be resolved. Use recovery to open the official release page and hand over its ZIP.'
    }
    [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label 'Enshrouded VR ZIP' `
        -ManualUrl $script:EVRPage -AllowSkip:$false -Validator { param($p) [bool](Get-EVRArchiveInfo $p) })
    $info=Get-EVRArchiveInfo $Destination
    if (-not $info) { throw 'The Enshrouded VR archive lacks required publisher files.' }
    return $info
}
function Test-EVRMode([string]$Game) {
    $ini=Join-Path $Game 'EnshroudedVR\EnshroudedVR.ini'
    if (-not (Test-Path -LiteralPath $ini -PathType Leaf)) { return $false }
    $section=''
    foreach ($line in @(Get-Content -LiteralPath $ini -ErrorAction Stop)) {
        if ($line -match '^\s*\[([^]]+)\]') { $section=$Matches[1]; continue }
        if ($section -ieq 'Mode' -and $line -match '^\s*VR\s*=\s*1\s*(?:[;#].*)?$') { return $true }
    }
    return $false
}
function Get-EVRFlatSettings([string]$Game) {
    $savedGames=Join-Path $env:USERPROFILE 'Saved Games'
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        # Test games are validated against the isolated Temp sentinel in Get-EVRGame.
        $candidates=@((Join-Path $Game 'enshrouded_local.json'))
    }else{
        try{
            $value=(Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop).'{4C5C32FF-BB9D-43B0-B5B4-2D72E54EAAA4}'
            if($value){$savedGames=[Environment]::ExpandEnvironmentVariables($value)}
        }catch{}
        $candidates=@((Join-Path $savedGames 'keen games\Enshrouded\local_settings.json'),(Join-Path $Game 'enshrouded_local.json'))
    }
    foreach($path in $candidates){
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)){continue}
        try{
            $settings=Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop
            if($settings -and @($settings.PSObject.Properties).Count -gt 0){return $path}
        }catch{}
    }
    return $null
}
function Confirm-EVRFlatFirstStart([string]$Game) {
    if(Get-EVRFlatSettings $Game){Write-Host '  [OK] Existing game settings found; the one-time flat start is already covered.' -ForegroundColor Green;return}
    Write-Host ''
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  REQUIRED ONCE: START THE GAME IN FLAT FIRST' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host '  The game has not created readable graphics settings yet.' -ForegroundColor Yellow
    Write-Host '  Reach the main menu on your monitor, then close the game completely.' -ForegroundColor Cyan
    Write-Host '  FIRST START: let shaders compile (about 30-40 seconds in testing; slower PCs may take longer).' -ForegroundColor Yellow
    Write-Host '  A black/loading screen during that compilation does not mean Setup has frozen.' -ForegroundColor White
    Write-Host '  Do not start in VR yet. Setup will recheck the settings before installing.' -ForegroundColor White
    Write-Host ('='*60) -ForegroundColor Magenta
    if(Test-EVRMode $Game){
        Write-Host '  VR files are already installed. First choose Desktop (older versions: Normal) in the setting program.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher settings and select Desktop / Normal...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            [IO.File]::WriteAllText((Join-Path $Game 'EnshroudedVR\EnshroudedVR.ini'),"[Mode]`r`nVR=0`r`n")
        }else{
            $proc=Start-Process -FilePath (Join-Path $Game 'Enshrouded VR setting.exe') -WorkingDirectory $Game -Wait -PassThru -ErrorAction Stop
            if($null -eq $proc.ExitCode -or $proc.ExitCode -ne 0){throw 'Publisher settings did not finish successfully.'}
        }
        if(Test-EVRMode $Game){throw 'Desktop / Normal is not selected. Choose it in publisher settings, close the program, then Retry.'}
    }
    while($true){
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start Enshrouded in flat through Steam...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            if($env:PCVR_EVR_TEST_FLAT_CAPTURE){[IO.File]::AppendAllText($env:PCVR_EVR_TEST_FLAT_CAPTURE,"steam://rungameid/1203620`r`n")}
            if($env:PCVR_EVR_TEST_FLAT_FAIL -ne '1'){[IO.File]::WriteAllText((Join-Path $Game 'enshrouded_local.json'),'{"graphics":{"fixture":true}}')}
        }else{Start-Process -FilePath 'steam://rungameid/1203620' -ErrorAction Stop|Out-Null}
        [void](Wait-PCVRExplicitEnter -Message 'After reaching the flat main menu and closing Enshrouded, press Enter to check its settings...')
        if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name enshrouded -ErrorAction SilentlyContinue)){
            throw 'Enshrouded is still running. Close it completely, then Retry; no VR files were installed.'
        }
        if(Get-EVRFlatSettings $Game){Write-Host '  [OK] Game settings verified after the flat start.' -ForegroundColor Green;return}
        Write-Host '  Readable game settings are still missing. No VR installation was confirmed.' -ForegroundColor Yellow
        $answer=(''+(Read-Host '[F] Start flat again  [R] Recheck settings  [Q] Recovery')).Trim()
        if($answer -ieq 'R' -and (Get-EVRFlatSettings $Game)){return}
        if($answer -ine 'F'){throw 'The flat first start has not created readable game settings. Reach the main menu, exit normally, then Retry.'}
    }
}
function Enable-EVRMode([string]$Game) {
    Write-Host ''
    Write-Host '  REQUIRED: VR is OFF in a fresh publisher installation.' -ForegroundColor Yellow
    Write-Host '  In the publisher program choose motion VR (older versions: VR), then close it.' -ForegroundColor Cyan
    Write-Host '  controller VR FPS / TPS are alternatives for playing with an Xbox controller.' -ForegroundColor White
    Write-Host '  Keep Frame mode on Both eyes every frame; AFW is a publisher test mode.' -ForegroundColor Yellow
    Write-Host '  Keep the game closed while changing the mode.' -ForegroundColor White
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        if ($env:PCVR_EVR_TEST_SET_MODE -ne '1') { throw 'Fixture did not enable VR mode.' }
        [IO.File]::WriteAllText((Join-Path $Game 'EnshroudedVR\EnshroudedVR.ini'),"[Mode]`r`nVR=1`r`n")
    } else {
        for($attempt=1;$attempt -le 4 -and -not(Test-EVRMode $Game);$attempt++) {
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher VR setting program...')
            $process=Start-Process -FilePath (Join-Path $Game 'Enshrouded VR setting.exe') -WorkingDirectory $Game -Wait -PassThru -ErrorAction Stop
            if ($null -eq $process.ExitCode -or [int]$process.ExitCode -ne 0) { throw 'The publisher VR setting program did not finish successfully.' }
            if (-not(Test-EVRMode $Game)) { Write-Host '  VR is still off. Choose motion VR or controller VR in the publisher program.' -ForegroundColor Yellow }
        }
    }
    if (-not(Test-EVRMode $Game)) { throw 'VR mode is not enabled in EnshroudedVR.ini; no VR installation was confirmed.' }
}
function Invoke-EVRInstaller {
    $work=$null;$snapshot=$null;$changed=$false;$game=$null
    try {
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Enshrouded VR - Installer' -ForegroundColor Cyan
        Write-Host '  Steam; room-scale OpenXR motion controls' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Start the flat game once, then close it before installing.' -ForegroundColor White
        Write-Host '  This mod is tied to a specific Enshrouded game build.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Enshrouded...')
        $game=Get-EVRGame
        Write-Host "  Game: $game" -ForegroundColor Green
        if ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name enshrouded -ErrorAction SilentlyContinue)) { throw 'Close Enshrouded before installing or updating VR.' }
        if (-not(Test-InstallerTargetWritable $game)) { throw 'The Enshrouded folder is not writable.' }
        Confirm-EVRFlatFirstStart $game
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'EnshroudedVR.zip'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Enshrouded VR ZIP...')
        $info=Get-EVRArchive $archive
        if (-not $info) { throw 'The Enshrouded VR archive could not be validated.' }
        if ($env:PCVR_HUB_TEST_MODE -ne '1') {
            if (-not(Test-EVRGameBuild -Game $game -ExpectedHash $info.GameHash)) {
                $actual=(Get-FileHash -LiteralPath (Join-Path $game 'enshrouded.exe') -Algorithm SHA256).Hash
                throw "This VR package targets a different Enshrouded build. Update the game and mod together. Game SHA256: $actual; publisher target: $($info.GameHash)."
            }
        }
        $stage=Join-Path $work 'stage'
        if ((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Enshrouded VR' -AllowSkip:$false) -ne 'ok') {
            throw 'The publisher ZIP could not be extracted.'
        }
        foreach($name in @('dinput8.dll','Enshrouded VR setting.exe','EnshroudedVR\bin\evr_hooks.dll','EnshroudedVR\bin\openxr_loader.dll')) {
            if (-not(Test-Path -LiteralPath (Join-Path $stage $name) -PathType Leaf)) { throw "Publisher package lacks $name." }
        }
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity $script:EVRIdentity -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths @('EnshroudedVR\EnshroudedVR.ini')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Enshrouded VR...')
        $changed=$true
        $publisherUpdated=@(Get-EVRPublisherOwnedUpdates -Game $game)
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:EVRIdentity `
            -ReplaceChangedOwnedRelativePaths $publisherUpdated `
            -KeepExistingRelativePaths @('EnshroudedVR\EnshroudedVR.ini') -AdoptIdenticalExisting)
        if (-not(Test-EVRMode $game)) { Enable-EVRMode $game }
        $required=@('dinput8.dll','Enshrouded VR setting.exe','EnshroudedVR\bin\evr_hooks.dll',
            'EnshroudedVR\bin\openxr_loader.dll','.pcvrhub_enshroudedvr_ownership.csv') | ForEach-Object { Join-Path $game $_ }
        if (-not(Confirm-PlacedFilesSurvive -Paths $required -GameDir $game -NoClear)) { throw 'Required Enshrouded VR files did not survive installation.' }
        $receipt=if($env:PCVR_EVR_TEST_RECEIPT){$env:PCVR_EVR_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:EVRContract -GameDir $game -Version $info.Version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed=$false
        Write-Host "  [OK] Enshrouded VR $($info.Version) is installed and VR mode is on." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub. Check updates and choose a VR mode in the publisher window.' -ForegroundColor White
        Write-Host '     Close that window; the Hub then starts the game through Steam.' -ForegroundColor Cyan
        Write-Host '  Alternatively, launch Enshrouded from Steam.' -ForegroundColor White
        Write-Host '  The publisher setting program beside enshrouded.exe changes VR/flat mode.' -ForegroundColor White
        Write-Host '  VR startup first shows a flat panel; VR is loading appeared about 10 seconds later in testing.' -ForegroundColor Yellow
        Write-Host '  Wait for VR to finish loading before treating the initial panel as a failed start.' -ForegroundColor White
        Write-Host ''
        Write-Host '  The Shroud is easier to face when both hands are yours.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot; Write-Host '  [!!] Previous Enshrouded files were restored.' -ForegroundColor Yellow }
            catch { Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
        throw
    } finally { if($work){Remove-PCVRInstallerTempSession -Path $work} }
}
if ($env:PCVR_EVR_LIBRARY_ONLY -ne '1') {
    while($true) {
        try { Invoke-EVRInstaller; break }
        catch {
            $message="Enshrouded VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
