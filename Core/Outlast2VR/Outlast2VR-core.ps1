$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$REPO = 'StrikeZoneVR-hub/Outlast2VR'
$RELEASES = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'v0.1.1'
$FALLBACK_ASSET = 'Outlast2VR-Beta1.1-RC1-Windows-x64.zip'
$FALLBACK_URL = "$RELEASES/download/$FALLBACK_TAG/$FALLBACK_ASSET"
$IDENTITY = 'outlast2vr'
$PAYLOAD = @('dinput8.dll','openxr_loader.dll','Outlast2VR.exe','Outlast2VR_intro.mp3',
    'outlast2_vr_p32.ini','outlast2_vr_p35.ini','outlast2_vr_p37.ini')
$REQUIRED = @($PAYLOAD | ForEach-Object { 'Binaries\Win64\' + $_ }) + @('.pcvrhub_outlast2vr_ownership.csv')
$CONTRACT = New-PCVRInstallerContract -Id 'outlast-2-vr' -GameName 'Outlast 2 VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups $REQUIRED

function Test-Outlast2Game([string]$Path) {
    if (-not $Path) { return $false }
    $exe = Join-Path $Path 'Binaries\Win64\Outlast2.exe'
    return [bool]((Test-Path -LiteralPath $exe -PathType Leaf) -and ((Get-Item -LiteralPath $exe).Length -gt 20MB))
}
function Test-Outlast2FlatFirstRun([string]$DocumentsPath = [Environment]::GetFolderPath('MyDocuments')) {
    if (-not $DocumentsPath) { return $false }
    $config = Join-Path $DocumentsPath 'My Games\Outlast2\OLGame\Config'
    foreach ($name in @('OLGame.ini','OLEngine.ini')) {
        $path = Join-Path $config $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
        if ((Get-Item -LiteralPath $path).Length -lt 128) { return $false }
    }
    return $true
}
function Get-Outlast2GameRoot([scriptblock]$ReadInput=$null) {
    $candidates = [Collections.Generic.List[string]]::new()
    try { $saved = ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"'); if ($saved) { $candidates.Add($saved) } } catch {}
    try { $saved = Get-PCVRRememberedGameFolder -GameId 'outlast-2-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('Binaries\Win64\Outlast2.exe'); if ($saved) { $candidates.Add($saved) } } catch {}
    try { $found = Find-SteamGameFolder -AppId '414700' -SteamFolderNames @('Outlast 2') -ProbeExe 'Binaries\Win64\Outlast2.exe' -HubGameId 'outlast-2-vr'; if ($found) { $candidates.Add($found) } } catch {}
    $candidates.Add('C:\Program Files (x86)\Steam\steamapps\common\Outlast 2')
    foreach ($path in @($candidates | Select-Object -Unique)) { if (Test-Outlast2Game $path) { return (Get-Item -LiteralPath $path).FullName } }
    Write-Host '  Select the Steam Outlast 2 game folder (with Binaries\Win64\Outlast2.exe).' -ForegroundColor Yellow
    while ($true) {
        $raw = if ($ReadInput) { & $ReadInput } else { Read-Host 'Game folder (drag/paste path, Q to cancel)' }
        $path = ('' + $raw).Trim().Trim('"').Trim("'")
        if ($path -ieq 'Q') { return $null }
        if (Test-Outlast2Game $path) { return (Get-Item -LiteralPath $path).FullName }
        Write-Host '  This is not a complete Outlast 2 game folder.' -ForegroundColor Yellow
    }
}
function Get-Outlast2Release {
    $r = Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^Outlast2VR-.*-Windows-x64\.zip$') `
        -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -FallbackUrl $FALLBACK_URL `
        -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET
    if (-not (Test-IsTrackableInstalledVersion ([string]$r.Tag))) { throw 'GitHub did not return a trackable Outlast 2 VR release.' }
    return $r
}
function New-Outlast2Stage([string]$Archive,[string]$Work) {
    $outer = Join-Path $Work 'publisher'
    $result = Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'Outlast 2 VR publisher ZIP' -AllowSkip $false -QuietProgress
    if ([string]$result -notin @('ok','manual','retry')) { throw 'The publisher ZIP could not be opened.' }
    foreach ($name in $PAYLOAD) { if (-not (Test-Path -LiteralPath (Join-Path $outer $name) -PathType Leaf)) { throw "Publisher ZIP is missing $name" } }
    $stage = Join-Path $Work 'stage'; $target = Join-Path $stage 'Binaries\Win64'
    [void][IO.Directory]::CreateDirectory($target)
    foreach ($file in @(Get-ChildItem -LiteralPath $outer -Recurse -File)) {
        $relative = $file.FullName.Substring($outer.Length+1)
        $destination = Join-Path $target $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }
    return $stage
}
function Save-Outlast2Snapshot([string]$Game,[string]$Stage,[string]$Destination) {
    [void][IO.Directory]::CreateDirectory($Destination)
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)) { $paths.Add($file.FullName.Substring($Stage.Length+1)) }
    $manifest = Join-Path $Game '.pcvrhub_outlast2vr_ownership.csv'
    if (Test-Path -LiteralPath $manifest) { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath))) } } }
    foreach ($name in @('.pcvrhub_outlast2vr_ownership.csv','.pcvrhub_version')) { $paths.Add($name) }
    $records = @()
    foreach ($rel in @($paths | Select-Object -Unique)) {
        $source = Join-Path $Game $rel; $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$rel; Exists=$exists }
        if ($exists) { $copy = Join-Path (Join-Path $Destination 'files') $rel; [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy)); Copy-Item -LiteralPath $source -Destination $copy -Force }
    }
    $backup = Join-Path $Game '.pcvrhub_outlast2vr_backup'; $hasBackup = Test-Path -LiteralPath $backup -PathType Container
    if ($hasBackup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $Destination 'ownership-backup') -Recurse -Force }
    return [pscustomobject]@{ Records=$records; HasBackup=$hasBackup; Folder=$Destination }
}
function Restore-Outlast2Snapshot([string]$Game,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $path = Join-Path $Game ([string]$record.Relative)
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
        if ($record.Exists) { [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path)); Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.Folder 'files') ([string]$record.Relative)) -Destination $path -Force }
    }
    $backup = Join-Path $Game '.pcvrhub_outlast2vr_backup'
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    if ($Snapshot.HasBackup) { Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'ownership-backup') -Destination $backup -Recurse -Force }
}
function global:Invoke-Outlast2VRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $changed=$false
    try {
        Clear-Host; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Outlast 2 VR Installer' -ForegroundColor Cyan
        Write-Host '  Public beta by StrikeZoneVR' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  Steam Outlast 2 is required. Launch it flat once, reach the' -ForegroundColor Yellow
        Write-Host '  main menu, then close it BEFORE adding the VR mod.' -ForegroundColor Yellow
        Write-Host '  This creates the game configuration required by the mod.' -ForegroundColor Yellow
        Write-Host '  Default compatibility mode displays the same image in both eyes.' -ForegroundColor Yellow
        Write-Host '  Experimental depth stereo costs substantially more GPU performance.' -ForegroundColor Yellow
        Write-Host '  Quest 3 with Virtual Desktop / VDXR is the publisher-tested setup.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to continue...')
        Write-Host '  [1/4] Find your Steam Outlast 2 installation' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $game = Get-Outlast2GameRoot; if (-not $game) { return }
        if (Get-Process -Name 'Outlast2','Outlast2VR' -ErrorAction SilentlyContinue) { throw 'Close Outlast 2 and its VR launcher before installing.' }
        if (-not (Test-Outlast2FlatFirstRun)) {
            Write-Host '  Required flat-game configuration was not found.' -ForegroundColor Yellow
            Write-Host '  Start Outlast 2 from Steam WITHOUT the VR mod, reach the main' -ForegroundColor White
            Write-Host '  menu, close the game, then return here.' -ForegroundColor White
            if (Test-Path -LiteralPath (Join-Path $game 'Binaries\Win64\Outlast2VR.exe') -PathType Leaf) {
                Write-Host '  The VR mod is already present. Use Uninstall now on the game' -ForegroundColor Yellow
                Write-Host '  page before the flat start, then return to this setup.' -ForegroundColor Yellow
            }
            Write-Host '  [Enter] Check again    [Q] Cancel setup' -ForegroundColor White
            while (-not (Test-Outlast2FlatFirstRun)) {
                $rawChoice = Read-Host 'Flat first-run check'
                if ($null -eq $rawChoice) { return }
                $choice = ('' + $rawChoice).Trim()
                if ($choice -ieq 'Q') { return }
                if (Get-Process -Name 'Outlast2','Outlast2VR' -ErrorAction SilentlyContinue) {
                    Write-Host '  Close the game completely before continuing.' -ForegroundColor Yellow
                    continue
                }
                if (-not (Test-Outlast2FlatFirstRun)) {
                    Write-Host '  OLGame.ini and OLEngine.ini are still missing from Documents\My Games\Outlast2\OLGame\Config.' -ForegroundColor Yellow
                    Write-Host '  Run the flat game to its main menu, then check again or press Q.' -ForegroundColor White
                }
            }
        }
        Write-Host '  [OK] Flat-game configuration found.' -ForegroundColor Green
        if (-not (Test-InstallerTargetWritable -TargetPath $game)) { throw 'The Outlast 2 folder is not writable.' }
        $exeVersion = (Get-Item -LiteralPath (Join-Path $game 'Binaries\Win64\Outlast2.exe')).VersionInfo.FileVersion
        if ($exeVersion -and $exeVersion -ne '1.0.8767.0') { Write-Host "  Game build $exeVersion is unverified by the publisher; VR hooks may refuse it." -ForegroundColor Yellow }
        Write-Host '  [2/4] Download and inspect the publisher release' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        Write-Host '  The next step checks the official GitHub beta and downloads its ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download Outlast 2 VR...')
        $release = Get-Outlast2Release
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_outlast2_'+[Guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($work)
        $archive = Join-Path $work 'Outlast2VR.zip'
        $download = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "Outlast 2 VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if ($download -ne $true -and [string]$download -notin @('retry','manual')) { throw 'Outlast 2 VR download was not completed.' }
        $stage = New-Outlast2Stage -Archive $archive -Work $work
        Write-Host '  [3/4] Install VR files and preserve your settings' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $snapshot = Save-Outlast2Snapshot -Game $game -Stage $stage -Destination (Join-Path $work 'rollback'); $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting `
            -KeepExistingRelativePaths @('Binaries\Win64\outlast2_vr_p32.ini','Binaries\Win64\outlast2_vr_p35.ini','Binaries\Win64\outlast2_vr_p37.ini') `
            -ProgressLabel 'Installing Outlast 2 VR files')
        foreach ($name in $REQUIRED) { if (-not (Test-Path -LiteralPath (Join-Path $game $name) -PathType Leaf)) { throw "Installed Outlast 2 VR file is missing: $name" } }
        if (-not (Confirm-PlacedFilesSurvive -Paths @($REQUIRED | ForEach-Object { Join-Path $game $_ }) -GameDir $game -NoClear)) { throw 'Required Outlast 2 VR files did not survive installation.' }
        [void](Complete-PCVRInstallTransaction -Contract $CONTRACT -GameDir $game -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $changed=$false
        Write-Host '  [4/4] Finish and choose PLAY VR' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        Write-Host "  [OK] Outlast 2 VR $($release.Tag) installed." -ForegroundColor Green
        Write-Host '  Start in VR opens Outlast2VR.exe; choose PLAY VR in its window.' -ForegroundColor White
        Write-Host '  Game launch, headset image and controls require your own test.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  The camera sees the terror. The headset puts you inside it.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $game -and $snapshot) { try { Restore-Outlast2Snapshot -Game $game -Snapshot $snapshot; Write-Host '  Previous files restored.' -ForegroundColor Yellow } catch { Write-Host ('  Rollback needs attention: '+$_.Exception.Message) -ForegroundColor Red } }
        throw
    } finally { if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
}
if (((''+$env:PCVR_OUTLAST2_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-Outlast2VRInstaller }
