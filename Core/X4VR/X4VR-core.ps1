$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$script:X4Repo = 'ToffelsKater/X4_VR'
$script:X4Page = 'https://github.com/ToffelsKater/X4_VR/releases'
$script:X4FallbackTag = 'v0.4.0'
$script:X4FallbackName = 'X4_VR-v0.4.0.zip'
$script:X4Required = @('X4.exe','X4_VR\X4VRLauncher.exe',
    'X4_VR\build\Release\FreeTrackClient64.dll',
    'X4_VR\build\Release\x4vr_observe.dll',
    'X4_VR\build\Release\openvr_api.dll',
    'X4_VR\version.txt','.pcvrhub_x4vr_ownership.csv')
$script:X4Contract = New-PCVRInstallerContract -Id 'x4-foundations-vr' -GameName 'X4: Foundations VR' `
    -Acquisition GitHub -ReleasePageUrl $script:X4Page -AntivirusNotice `
    -RequiredInstalledFileGroups $script:X4Required

function Test-X4BaseGame([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'X4.exe') -PathType Leaf))
}
function Get-X4GameRoot {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_X4_TEST_GAME_ROOT){
        $candidate=[IO.Path]::GetFullPath($env:PCVR_X4_TEST_GAME_ROOT)
        if(-not(Test-Path -LiteralPath (Join-Path $candidate 'x4-fixture.txt') -PathType Leaf)){throw 'X4 test target is missing its isolation marker.'}
        if(-not(Test-X4BaseGame $candidate)){throw 'X4 test target is missing X4.exe.'}
        return $candidate
    }
    $candidates = [Collections.Generic.List[string]]::new()
    try { $p = Get-PCVRRememberedGameFolder -GameId 'x4-foundations-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('X4.exe'); if($p){$candidates.Add($p)} } catch {}
    try { $p = Find-SteamGameFolder -AppId '392160' -SteamFolderNames @('X4 Foundations') -ProbeExe 'X4.exe' -HubGameId 'x4-foundations-vr'; if($p){$candidates.Add($p)} } catch {}
    $candidates.Add('C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations')
    foreach($path in @($candidates|Select-Object -Unique)){ if(Test-X4BaseGame $path){return (Get-Item -LiteralPath $path).FullName} }
    while($true){
        $raw = Read-Host 'X4 game folder with X4.exe (drag/paste path, Q to cancel)'
        if($null -eq $raw){return $null}
        $path = (''+$raw).Trim().Trim('"').Trim("'")
        if($path -ieq 'Q'){return $null}
        if(Test-X4BaseGame $path){return (Get-Item -LiteralPath $path).FullName}
        Write-Host '  That folder has no X4.exe.' -ForegroundColor Yellow
    }
}
function Get-X4Release {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_X4_TEST_ARCHIVE){
        $testTag=if($env:PCVR_X4_TEST_RELEASE_TAG){$env:PCVR_X4_TEST_RELEASE_TAG}else{'v0.4.0'}
        if(-not(Test-IsTrackableInstalledVersion $testTag)){throw 'The X4 test release tag is invalid.'}
        return [pscustomobject]@{Tag=$testTag;Url=$env:PCVR_X4_TEST_ARCHIVE;PageUrl=$script:X4Page}
    }
    $release = Resolve-GitHubReleaseAsset -Repo $script:X4Repo -AssetPatterns @('(?i)^X4_VR[-_]v?[0-9].*\.zip$') `
        -SkipReleasesWithoutMatchingAsset -FallbackTag $script:X4FallbackTag `
        -FallbackAssetName $script:X4FallbackName `
        -FallbackUrl "$script:X4Page/download/$script:X4FallbackTag/$script:X4FallbackName"
    if(-not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){throw 'GitHub returned no trackable X4 VR release.'}
    return $release
}
function New-X4Stage([string]$Archive,[string]$Work) {
    $stage = Join-Path $Work 'stage'
    $expanded = Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $stage -Label 'X4 VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$expanded -notin @('ok','manual','retry')){throw 'The X4 VR ZIP could not be opened.'}
    foreach($relative in @('X4_VR\X4VRLauncher.exe','X4_VR\build\Release\FreeTrackClient64.dll',
            'X4_VR\build\Release\x4vr_observe.dll','X4_VR\build\Release\openvr_api.dll','X4_VR\version.txt')){
        if(-not(Test-Path -LiteralPath (Join-Path $stage $relative) -PathType Leaf)){throw "X4 VR archive is missing $relative"}
    }
    $rootFiles = @(Get-ChildItem -LiteralPath $stage -File -Force -ErrorAction Stop)
    if($rootFiles.Count -gt 0){throw 'The X4 VR archive has unexpected files outside X4_VR.'}
    return $stage
}
function Assert-X4StageVersion([string]$Stage,[string]$ReleaseTag) {
    $versionFile=Join-Path $Stage 'X4_VR\version.txt'
    $version=([IO.File]::ReadAllText($versionFile)).Trim()
    if($version.Length -gt 80 -or -not(Test-IsTrackableInstalledVersion $version) -or
        -not [string]::Equals($version,$ReleaseTag,[StringComparison]::OrdinalIgnoreCase)){
        throw "The X4 VR package version does not match the selected release ($ReleaseTag). No game files were changed."
    }
    return $version
}
function Save-X4Snapshot([string]$Game,[string]$Stage,[string]$Backup) {
    [void][IO.Directory]::CreateDirectory($Backup)
    $paths = [Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$paths.Add($file.FullName.Substring($Stage.Length+1))}
    $manifest = Join-Path $Game '.pcvrhub_x4vr_ownership.csv'
    if(Test-Path -LiteralPath $manifest){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}}}
    foreach($name in @('.pcvrhub_x4vr_ownership.csv','.pcvrhub_version')){$paths.Add($name)}
    $records = @()
    foreach($relative in @($paths|Select-Object -Unique)){
        $source = Join-OwnedRelativePath -Root $Game -Relative $relative
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-OwnedRelativePath -Root (Join-Path $Backup 'files') -Relative $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop}
    }
    $ownedBackup=Join-Path $Game '.pcvrhub_x4vr_backup'
    $hadOwnedBackup=Test-Path -LiteralPath $ownedBackup -PathType Container
    if($hadOwnedBackup){Copy-Item -LiteralPath $ownedBackup -Destination (Join-Path $Backup 'ownership-backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Records=$records;HadOwnedBackup=$hadOwnedBackup;Root=$Backup}
}
function Restore-X4Snapshot([string]$Game,$Snapshot) {
    foreach($record in @($Snapshot.Records)){
        $target=Join-OwnedRelativePath -Root $Game -Relative ([string]$record.Relative)
        if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
        if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$record.Relative)) -Destination $target -Force -ErrorAction Stop}
    }
    $ownedBackup=Join-Path $Game '.pcvrhub_x4vr_backup'
    if(Test-Path -LiteralPath $ownedBackup){Remove-Item -LiteralPath $ownedBackup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadOwnedBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $ownedBackup -Recurse -Force -ErrorAction Stop}
}
function Write-X4ProofCheckpoint([string]$Label,[string]$Root) {
    foreach($relative in $script:X4Required){
        Write-Host ("  [{0}] {1}: {2}" -f $Label,$relative,[bool](Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) -ForegroundColor DarkGray
    }
}
function global:Invoke-X4VRInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try {
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  X4: Foundations VR Installer' -ForegroundColor Cyan
        Write-Host '  X4 VR by ToffelsKater | cockpit and head tracking' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Requires Steam X4 9.00 or 8.00 and SteamVR (default).' -ForegroundColor Yellow
        Write-Host '  The launcher also offers experimental OpenXR.' -ForegroundColor Yellow
        Write-Host '  Quest users: Virtual Desktop is recommended; Steam Link may jitter.' -ForegroundColor White
        Write-Host '  Setup installs only into the X4_VR folder beside X4.exe.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate X4...')
        Write-Host '';Write-Host '--- [1/3] Finding X4 ---' -ForegroundColor Cyan
        $game=Get-X4GameRoot;if(-not $game){return}
        if(Get-Process -Name X4,X4VRLauncher -ErrorAction SilentlyContinue){throw 'Close X4 and the X4 VR launcher before setup.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The X4 game folder is not writable.'}
        Write-Host "  [OK] $game" -ForegroundColor Green
        Write-Host '';Write-Host '--- [2/3] Getting the publisher ZIP ---' -ForegroundColor Cyan
        Write-Host "  Source: $script:X4Page" -ForegroundColor Gray
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download X4 VR...')
        $release=Get-X4Release
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_x4vr_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'X4_VR.zip'
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_X4_TEST_ARCHIVE){
            Copy-Item -LiteralPath ([IO.Path]::GetFullPath($env:PCVR_X4_TEST_ARCHIVE)) -Destination $archive -ErrorAction Stop
        } else {
            $download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "X4 VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
            if($download -ne $true -and [string]$download -notin @('manual','retry')){throw 'X4 VR download did not complete.'}
        }
        $stage=New-X4Stage -Archive $archive -Work $work
        $packageVersion=Assert-X4StageVersion -Stage $stage -ReleaseTag ([string]$release.Tag)
        Write-Host '';Write-Host '--- [3/3] Installing the isolated X4_VR folder ---' -ForegroundColor Cyan
        Write-X4ProofCheckpoint -Label before-copy -Root $game
        $snapshot=Save-X4Snapshot -Game $game -Stage $stage -Backup (Join-Path $work 'rollback')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'x4vr' `
            -KeepExistingRelativePaths @('X4_VR\config\stereo.txt','X4_VR\config\profiles\Default.txt','X4_VR\config\profiles\Pair 90 Hz (experimental).txt') `
            -ProgressLabel 'Installing X4 VR files')
        Write-X4ProofCheckpoint -Label after-copy -Root $game
        foreach($relative in $script:X4Required){if(-not(Test-Path -LiteralPath (Join-Path $game $relative) -PathType Leaf)){throw "Installed X4 VR file is missing: $relative"}}
        if(-not(Confirm-PlacedFilesSurvive -Paths @($script:X4Required|ForEach-Object{Join-Path $game $_}) -GameDir $game -NoClear)){throw 'Required X4 VR files did not survive installation.'}
        Write-X4ProofCheckpoint -Label after-observation -Root $game
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_X4_TEST_GAME_ROOT){Join-Path $game '.pcvrhub_test_installed_path'}else{Join-Path $PSScriptRoot '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $script:X4Contract -GameDir $game -Version $packageVersion -InstalledPathReceiptPaths @($receipt))
        $changed=$false
        Write-Host '  Start in VR opens X4VRLauncher.exe. Set the X4 options in the README.' -ForegroundColor White
        Write-Host '  The launcher changes the FreeTrack registry path only when started.' -ForegroundColor Gray
        Write-Host '';Write-Host '  Profitssss are better when you can see the whole sector.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if($changed -and $game -and $snapshot){
            Write-X4ProofCheckpoint -Label before-rollback -Root $game
            try{Restore-X4Snapshot -Game $game -Snapshot $snapshot;Write-X4ProofCheckpoint -Label after-rollback -Root $game;Write-Host '  Previous files restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host ('  Rollback needs attention: '+$_.Exception.Message) -ForegroundColor Red}
        }
        throw
    } finally {
        if($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)){
            $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
            $full=[IO.Path]::GetFullPath($work)
            if($full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $full -Leaf) -like 'pcvr_x4vr_*'){
                Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
if($env:PCVR_X4VR_LIBRARY_ONLY -ne '1'){Invoke-X4VRInstaller}
