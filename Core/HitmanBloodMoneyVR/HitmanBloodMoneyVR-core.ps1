$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='Hitman: Blood Money VR Installer'
$script:HBMId='hitman-blood-money-vr'
$script:HBMRepo='andreystashev/hitman-blood-money-vr-showcase'
$script:HBMPage='https://github.com/andreystashev/hitman-blood-money-vr-showcase/releases'
$script:HBMRequired=@('BloodMoneyVR.exe','vr.ini','Collect-Diagnostics.cmd','unins000.exe')
$script:HBMContract=New-PCVRInstallerContract -Id $script:HBMId -GameName 'Hitman: Blood Money VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:HBMPage -Routes @('Current') `
    -RequiredInstalledFileGroups $script:HBMRequired

function Test-HBMGame([string]$Root){
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root 'HitmanBloodMoney.exe') -PathType Leaf)){return $false}
    if($env:PCVR_HUB_TEST_MODE -eq '1'){return (Test-Path -LiteralPath (Join-Path $Root 'hbm-fixture.txt') -PathType Leaf)}
    return ((Get-Item -LiteralPath (Join-Path $Root 'HitmanBloodMoney.exe')).Length -gt 500KB)
}
function Get-HBMGame {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HBM_TEST_GAME){
        $root=[IO.Path]::GetFullPath($env:PCVR_HBM_TEST_GAME)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-HBMGame $root)){
            throw 'Hitman test game must be an isolated fixture.'
        }
        return $root
    }
    $paths=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:HBMId -StateNames @('base_game_path','user_located') -ProbeFiles @('HitmanBloodMoney.exe')
    if($saved){$paths+=$saved}
    try{$steam=Find-SteamGameFolder -AppId '6860' -SteamFolderNames @('Hitman Blood Money') -ProbeExe 'HitmanBloodMoney.exe' -HubGameId $script:HBMId;if($steam){$paths+=$steam}}catch{}
    $paths+=@('C:\Program Files (x86)\Steam\steamapps\common\Hitman Blood Money',
        'C:\Program Files (x86)\GOG Galaxy\Games\Hitman Blood Money','C:\GOG Games\Hitman Blood Money',
        'C:\Program Files (x86)\Eidos\Hitman Blood Money')
    foreach($path in @($paths|Select-Object -Unique)){if(Test-HBMGame $path){return [IO.Path]::GetFullPath($path)}}
    $picked=Get-GameFolderInteractive -GameName 'Hitman: Blood Money' -ProbeFile 'HitmanBloodMoney.exe'
    if(Test-HBMGame $picked){
        [void](Save-HubRememberedGameFolder -GameId $script:HBMId -Title 'Hitman: Blood Money VR' -GameDir $picked -ProbeFiles @('HitmanBloodMoney.exe') -StateName 'base_game_path' -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose a complete original PC Hitman: Blood Money installation.'
}
function Get-HBMRuntimeDefault {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HBM_TEST_RUNTIME){return [IO.Path]::GetFullPath($env:PCVR_HBM_TEST_RUNTIME)}
    $publisherDefault=Join-Path $env:LOCALAPPDATA 'BloodMoneyVR'
    $previousHubFolder=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\BloodMoneyVR'
    if(Test-HBMRuntime $publisherDefault){return $publisherDefault}
    if(Test-HBMRuntime $previousHubFolder){return $previousHubFolder}
    return $publisherDefault
}
function Test-HBMRuntime([string]$Root){
    if(-not $Root){return $false}
    foreach($name in $script:HBMRequired){if(-not(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)){return $false}}
    return $true
}
function Get-HBMArchiveInfo([string]$Path){
    try{
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try{
            $releaseEntry=$zip.GetEntry('release.json')
            if(-not $releaseEntry -or -not $zip.GetEntry('README-EN.txt')){return $null}
            $reader=[IO.StreamReader]::new($releaseEntry.Open())
            try{$release=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
            $version=[string]$release.version
            $setup=[string]$release.installer
            if(-not(Test-IsTrackableInstalledVersion $version) -or $setup -notmatch '^BloodMoneyVR-[0-9]+(?:\.[0-9]+)+-Setup\.exe$' -or
                -not $zip.GetEntry($setup)){return $null}
            return [pscustomobject]@{Version=$version;SetupName=$setup}
        }finally{$zip.Dispose()}
    }catch{return $null}
}
function Get-HBMArchive([string]$Destination){
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HBM_TEST_ARCHIVE){
        Copy-Item -LiteralPath $env:PCVR_HBM_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop
        return (Get-HBMArchiveInfo $Destination)
    }
    $release=Resolve-GitHubReleaseAsset -Repo $script:HBMRepo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^BloodMoneyVR-[0-9]+(?:\.[0-9]+)+-alpha\.zip$') -SkipReleasesWithoutMatchingAsset $true
    if(-not $release.Resolved -or -not $release.Url){
        throw 'The current Blood Money VR alpha could not be resolved. Use recovery to open the official release and hand over its ZIP.'
    }
    [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label 'Blood Money VR publisher ZIP' `
        -ManualUrl $script:HBMPage -AllowSkip:$false -Validator {param($p) [bool](Get-HBMArchiveInfo $p)})
    return (Get-HBMArchiveInfo $Destination)
}
function Get-HBMRuntimeAfterSetup([string]$Default){
    if(Test-HBMRuntime $Default){return [IO.Path]::GetFullPath($Default)}
    if($env:PCVR_HUB_TEST_MODE -eq '1'){return $null}
    Write-Host "  Publisher Setup did not leave a complete VR runtime in: $Default" -ForegroundColor Yellow
    return $null
}
function Get-HBMShortcutPath {
    $desktop=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HBM_TEST_DESKTOP){$env:PCVR_HBM_TEST_DESKTOP}else{[Environment]::GetFolderPath('Desktop')}
    return (Join-Path $desktop 'Hitman Blood Money VR.lnk')
}
function New-HBMShortcut([string]$Runtime){
    $path=Get-HBMShortcutPath
    $shell=New-Object -ComObject WScript.Shell
    $target=Join-Path $Runtime 'BloodMoneyVR.exe'
    $icon=Join-Path $Runtime 'HitmanBloodMoneyVR.ico'
    $sourceIcon=Join-Path $PSScriptRoot 'HitmanBloodMoneyVR.ico'
    $marker=Join-Path $Runtime '.pcvrhub_hbm_shortcut.json'
    $owned=$null
    if(Test-Path -LiteralPath $marker -PathType Leaf){$owned=Get-Content -LiteralPath $marker -Raw -Encoding UTF8|ConvertFrom-Json}
    $created=-not(Test-Path -LiteralPath $path -PathType Leaf)
    if(Test-Path -LiteralPath $path -PathType Leaf){
        $old=$shell.CreateShortcut($path)
        if($old.TargetPath -ine $target -or $old.Arguments){throw 'An unrelated Hitman Blood Money VR desktop shortcut already exists.'}
    }
    $sourceHash=(Get-FileHash -LiteralPath $sourceIcon -Algorithm SHA256).Hash
    if(Test-Path -LiteralPath $icon -PathType Leaf){
        $currentHash=(Get-FileHash -LiteralPath $icon -Algorithm SHA256).Hash
        if($currentHash -ne $sourceHash -and (-not $owned -or $owned.IconHash -ne $currentHash)){
            throw 'An unrelated or edited HitmanBloodMoneyVR.ico already exists; it was preserved.'
        }
    }
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
    Copy-Item -LiteralPath $sourceIcon -Destination $icon -Force -ErrorAction Stop
    $link=$shell.CreateShortcut($path)
    $link.TargetPath=$target;$link.WorkingDirectory=$Runtime;$link.Description='Hitman: Blood Money VR'
    $link.IconLocation=$icon+',0';$link.Save()
    $check=$shell.CreateShortcut($path)
    if($check.TargetPath -ine $target -or $check.WorkingDirectory -ine $Runtime -or $check.IconLocation -ine ($icon+',0')){
        throw 'The Hitman VR shortcut target, working directory or icon was not saved correctly.'
    }
    [pscustomobject]@{Path=$path;Target=$target;Hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;IconPath=$icon;IconHash=$sourceHash}|
        ConvertTo-Json | Set-Content -LiteralPath $marker -Encoding UTF8
    # Migrate only the old Hub shortcut pointing at this exact publisher runtime.
    $legacy=Join-Path (Split-Path -Parent $path) 'Blood Money VR (Hub).lnk'
    if(Test-Path -LiteralPath $legacy -PathType Leaf){
        $old=$shell.CreateShortcut($legacy)
        if($old.TargetPath -ieq $target -and -not $old.Arguments){Remove-Item -LiteralPath $legacy -Force;$created=$false}
    }
    return $created
}
function Invoke-HBMInstaller {
    $work=$null;$createdShortcut=$false;$runtime=$null
    try{
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Hitman: Blood Money VR - Installer' -ForegroundColor Cyan
        Write-Host '  Publisher alpha; dedicated VR launcher and runtime' -ForegroundColor Yellow
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Start the unmodded PC game once, then close it.' -ForegroundColor White
        Write-Host '  Publisher Setup validates the exact game EXE and installs VR outside the game.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Hitman: Blood Money...')
        $game=Get-HBMGame
        Write-Host "  Game: $game" -ForegroundColor Green
        if(Get-Process -Name 'HitmanBloodMoney','BloodMoneyVR' -ErrorAction SilentlyContinue){throw 'Close the game and VR launcher before installing.'}
        $runtimeDefault=Get-HBMRuntimeDefault
        if([IO.Path]::GetFullPath($game).TrimEnd('\') -ieq [IO.Path]::GetFullPath($runtimeDefault).TrimEnd('\')){
            throw 'The VR runtime must be in a folder separate from the game.'
        }
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'BloodMoneyVR.zip'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Blood Money VR alpha...')
        $info=Get-HBMArchive $archive
        if(-not $info){throw 'The publisher ZIP is missing release metadata or Setup.'}
        $stage=Join-Path $work 'publisher'
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Blood Money VR' -AllowSkip:$false) -ne 'ok'){
            throw 'The publisher ZIP could not be extracted.'
        }
        $setup=Join-Path $stage $info.SetupName
        if(-not(Test-Path -LiteralPath $setup -PathType Leaf)){throw 'Publisher Setup is missing after extraction.'}
        $attempt=0
        while($true){
            Write-Host ''
            Write-Host ('='*60) -ForegroundColor Magenta
            Write-Host '  REQUIRED PUBLISHER SETUP' -ForegroundColor Yellow
            Write-Host "  1. Select HitmanBloodMoney.exe in: $game" -ForegroundColor Cyan
            if($runtimeDefault -ieq (Join-Path $env:LOCALAPPDATA 'BloodMoneyVR')){
                Write-Host "  2. Keep the publisher's default VR folder unchanged: $runtimeDefault" -ForegroundColor Green
            }else{
                Write-Host "  2. Update the existing VR folder in place: $runtimeDefault" -ForegroundColor Green
            }
            Write-Host '  3. Finish the full Setup, then return here.' -ForegroundColor Cyan
            Write-Host ('='*60) -ForegroundColor Magenta
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
            $attempt++
            if($env:PCVR_HUB_TEST_MODE -eq '1'){
                if($env:PCVR_HBM_TEST_PREPARE -eq '1'){
                    [void][IO.Directory]::CreateDirectory($runtimeDefault)
                    foreach($name in $script:HBMRequired){[IO.File]::WriteAllText((Join-Path $runtimeDefault $name),'fixture')}
                }
                $exitCode=0
            }else{
                $process=Start-Process -FilePath $setup -WorkingDirectory $stage -Wait -PassThru -ErrorAction Stop
                $exitCode=$process.ExitCode
            }
            if($null -eq $exitCode -or [int]$exitCode -ne 0){throw "Publisher Setup did not finish successfully (exit $exitCode)."}
            $runtime=Get-HBMRuntimeAfterSetup $runtimeDefault
            if($runtime){break}
            Write-Host '  Publisher Setup did not leave a complete VR runtime. It can be reopened here.' -ForegroundColor Yellow
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw 'Publisher runtime is incomplete.'}
            if((''+(Read-Host '  Press Enter to reopen Setup or Q for recovery')).Trim() -ieq 'Q'){
                throw 'Publisher runtime is incomplete; no Hub success was recorded.'
            }
        }
        $createdShortcut=New-HBMShortcut $runtime
        $receipt=if($env:PCVR_HBM_TEST_RECEIPT){$env:PCVR_HBM_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:HBMContract -GameDir $runtime -Version $info.Version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        [void](Save-HubRememberedGameFolder -GameId $script:HBMId -Title 'Hitman: Blood Money VR' -GameDir $game -ProbeFiles @('HitmanBloodMoney.exe') -StateName 'base_game_path')
        Write-Host "  [OK] Blood Money VR $($info.Version) publisher runtime verified." -ForegroundColor Green
        Write-Host "  VR publisher folder: $runtime" -ForegroundColor Cyan
        Write-Host "  Desktop shortcut: $(Get-HBMShortcutPath)" -ForegroundColor Cyan
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor White
        Write-Host '  Alternatively, use the Hitman: Blood Money VR desktop shortcut.' -ForegroundColor White
        Write-Host ''
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  IMPORTANT VR IMAGE SETTINGS' -ForegroundColor Yellow
        Write-Host '  In the game options, increase the resolution and enable anti-aliasing.' -ForegroundColor Cyan
        Write-Host '  This has helped avoid a jittering image in VR during playtests.' -ForegroundColor White
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Agent 47, your next disguise has a headset.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($createdShortcut -and (Test-Path -LiteralPath (Get-HBMShortcutPath) -PathType Leaf)){
            Remove-Item -LiteralPath (Get-HBMShortcutPath) -Force -ErrorAction SilentlyContinue
        }
        throw
    }finally{if($work){Remove-PCVRInstallerTempSession -Path $work}}
}
if($env:PCVR_HBM_LIBRARY_ONLY -ne '1'){
    while($true){
        try{Invoke-HBMInstaller;break}
        catch{
            $message="Blood Money VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
