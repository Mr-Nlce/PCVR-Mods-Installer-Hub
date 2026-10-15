$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Blade of Darkness VR Installer'
$script:BladeId = 'blade-of-darkness-vr'
$script:BladeIdentity = 'bladevr'
$script:BladeRepo = 'Efraim2704/BladeOfDarknessVR'
$script:BladeReleases = "https://github.com/$script:BladeRepo/releases"
$script:BladeFallback = 'https://github.com/Efraim2704/BladeOfDarknessVR/releases/download/v1.6/BladeVR-v1.6.zip'
$script:BladeFiles = @('dxgi.dll','BladeVR.dll','openvr_api.dll')
$script:BladeProof = @($script:BladeFiles | ForEach-Object { 'bin\bin\' + $_ })
$script:BladeContract = New-PCVRInstallerContract -Id $script:BladeId -GameName 'Blade of Darkness VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:BladeReleases `
    -RequiredInstalledFileGroups @($script:BladeProof + '.pcvrhub_bladevr_ownership.csv')

function Test-BladeGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'bin\bin\Blade.exe') -PathType Leaf))
}
function Get-BladeGameRoot {
    $test = ('' + $env:PCVR_BLADE_TEST_GAME).Trim()
    if ($test) {
        if (Test-BladeGame $test) { return (Get-Item -LiteralPath $test).FullName }
        throw 'The selected Blade test game folder has no bin\bin\Blade.exe.'
    }
    $found = Find-SteamGameFolder -AppId '1710170' -SteamFolderNames @('Blade of Darkness') `
        -ProbeExe 'bin\bin\Blade.exe' -HubGameId $script:BladeId
    if (Test-BladeGame $found) { return (Get-Item -LiteralPath $found).FullName }
    $manual = Get-GameFolderInteractive -GameName 'Blade of Darkness (2021 Steam remaster)' `
        -ProbeFile 'bin\bin\Blade.exe' -ManualUrl $script:BladeReleases
    if ($manual -and $manual -notin @('quit','skip') -and (Test-BladeGame $manual)) {
        return (Get-Item -LiteralPath $manual).FullName
    }
    return $null
}
function Get-BladeRelease {
    $test = ('' + $env:PCVR_BLADE_TEST_ARCHIVE).Trim()
    if ($test) {
        return [pscustomobject]@{ Tag='v1.6'; Url=$test; Name='BladeVR-v1.6.zip'; PageUrl='https://github.com/Efraim2704/BladeOfDarknessVR/releases/tag/v1.6'; IsLocal=$true }
    }
    $r = Resolve-GitHubReleaseAsset -Repo $script:BladeRepo -IncludePrerelease $false `
        -AssetPatterns @('(?i)^BladeVR-v[0-9].*\.zip$') -FallbackUrl $script:BladeFallback `
        -FallbackTag 'v1.6' -FallbackAssetName 'BladeVR-v1.6.zip' -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{ Tag=[string]$r.Tag; Url=[string]$r.Url; Name=[string]$r.AssetName; PageUrl=[string]$r.PageUrl; IsLocal=$false }
}
function New-BladeStage([string]$Archive,[string]$Work) {
    $outer = Join-Path $Work 'publisher'
    $result = Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'BladeVR publisher ZIP' -AllowSkip $false -QuietProgress
    if ([string]$result -notin @('ok','manual','retry')) { throw 'The BladeVR ZIP could not be opened.' }
    $payload = Get-ExtractedPayloadRoot -ExtractDir $outer -RelModFile 'BladeVR.dll'
    if (-not $payload) { throw 'The publisher ZIP has no BladeVR.dll.' }
    foreach ($name in $script:BladeFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $payload $name) -PathType Leaf)) { throw "Publisher ZIP is missing $name" }
    }
    $stage = Join-Path $Work 'stage\bin\bin'
    [void][IO.Directory]::CreateDirectory($stage)
    foreach ($name in $script:BladeFiles) { Copy-Item -LiteralPath (Join-Path $payload $name) -Destination (Join-Path $stage $name) -Force -ErrorAction Stop }
    return (Join-Path $Work 'stage')
}
function Save-BladeSnapshot([string]$Game,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)) { $paths.Add($file.FullName.Substring($Stage.Length+1)) }
    $manifest = Join-Path $Game '.pcvrhub_bladevr_ownership.csv'
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)) {
            if ($row.RelativePath) { $paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath))) }
        }
    }
    foreach ($name in @('.pcvrhub_bladevr_ownership.csv','.pcvrhub_bladevr_ownership.csv.new','.pcvrhub_version')) { $paths.Add($name) }
    $records = @()
    foreach ($rel in @($paths | Select-Object -Unique)) {
        $source = Join-OwnedRelativePath -Root $Game -Relative $rel
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$rel; Exists=$exists }
        if ($exists) {
            $copy = Join-OwnedRelativePath -Root (Join-Path $SnapshotRoot 'files') -Relative $rel
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $Game '.pcvrhub_bladevr_backup'
    $hadBackup = Test-Path -LiteralPath $backup -PathType Container
    if ($hadBackup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{ Root=$SnapshotRoot; Records=$records; HadBackup=$hadBackup }
}
function Restore-BladeSnapshot([string]$Game,$Snapshot) {
    foreach ($row in @($Snapshot.Records)) {
        $target = Join-OwnedRelativePath -Root $Game -Relative ([string]$row.Relative)
        if ($row.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$row.Relative)) -Destination $target -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $Game '.pcvrhub_bladevr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    if ($Snapshot.HadBackup) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}
function Invoke-BladeInstaller {
    $work=$null; $game=$null; $snapshot=$null; $changed=$false; $keepWork=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Blade of Darkness VR - Installer' -ForegroundColor Cyan
        Write-Host '  Steam 2021 DirectX 11 remaster; SteamVR / OpenVR' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  This mod needs the 2021 Steam remaster, not the original 2001 build.' -ForegroundColor White
        Write-Host '  Keep SteamVR ready. Gamepad or keyboard controls normal play.' -ForegroundColor White
        Write-Host '  Motion controllers manipulate only the optional diorama.' -ForegroundColor White
        Write-Host '  Existing DLLs with the same names are backed up; saves stay in place.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Blade of Darkness...')

        Write-Host ''; Write-Host '--- [1/5] Locate and check the 2021 game ---' -ForegroundColor Cyan
        $game = Get-BladeGameRoot
        if (-not $game) { throw 'Setup stopped before changing the game folder.' }
        if (Get-Process -Name 'Blade' -ErrorAction SilentlyContinue) { throw 'Blade of Darkness is running. Close it before installing or updating.' }
        if (-not (Test-InstallerTargetWritable -TargetPath (Join-Path $game 'bin\bin'))) { throw 'The Blade bin\bin folder is not writable.' }
        Write-Host "  [OK] Game EXE found: $game" -ForegroundColor Green

        Write-Host ''; Write-Host '--- [2/5] Get and inspect the official BladeVR release ---' -ForegroundColor Cyan
        Write-Host '  The next step checks the stable GitHub releases and downloads a ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download BladeVR...')
        $release = Get-BladeRelease
        if (-not (Test-IsTrackableInstalledVersion $release.Tag)) { throw 'GitHub supplied no trackable BladeVR version.' }
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_blade_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive = Join-Path $work 'BladeVR.zip'
        if ($release.IsLocal) { Copy-Item -LiteralPath $release.Url -Destination $archive -Force -ErrorAction Stop }
        else { [void](Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "BladeVR $($release.Tag)" -ManualUrl $release.PageUrl -AllowSkip $false) }
        $stage = New-BladeStage -Archive $archive -Work $work
        $publisherReadme = Get-ChildItem -LiteralPath (Join-Path $work 'publisher') -Filter 'README.txt' -File -Recurse -ErrorAction Stop | Select-Object -First 1
        if (-not $publisherReadme) { throw 'The BladeVR package has no publisher version evidence. No game files were changed.' }
        $publisherTag = [regex]::Match(([string](Get-Content -LiteralPath $publisherReadme.FullName -TotalCount 1 -ErrorAction Stop)),'(?i)^BladeVR\s+(v\d+(?:\.\d+){1,3})').Groups[1].Value
        if (-not $publisherTag -or $publisherTag -ne [string]$release.Tag) { throw "BladeVR package version $publisherTag does not match selected release $($release.Tag). No game files were changed." }
        Write-Host "  [OK] Three required DLLs staged for $($release.Tag)." -ForegroundColor Green

        Write-Host ''; Write-Host '--- [3/5] Prepare recoverable file ownership ---' -ForegroundColor Cyan
        $snapshot = Save-BladeSnapshot -Game $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback')
        Write-Host '  [OK] Existing collisions and previous ownership protected.' -ForegroundColor Green

        Write-Host ''; Write-Host '--- [4/5] Install and verify the VR runtime ---' -ForegroundColor Cyan
        $changed = $true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:BladeIdentity -AdoptIdenticalExisting)
        $watch = @($script:BladeProof | ForEach-Object { Join-Path $game $_ }) + @(Join-Path $game '.pcvrhub_bladevr_ownership.csv')
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)) { throw 'Required BladeVR DLLs are missing after installation.' }
        $receipt = ('' + $env:PCVR_BLADE_TEST_RECEIPT).Trim()
        if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:BladeContract -GameDir $game -Version $publisherTag `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed = $false

        Write-Host ''; Write-Host '--- [5/5] Setup complete ---' -ForegroundColor Cyan
        Write-Host "  [OK] BladeVR $($release.Tag) is installed." -ForegroundColor Green
        Write-Host '  Start SteamVR, then launch Blade of Darkness from Steam.' -ForegroundColor White
        Write-Host ''
        Write-Host '  ========================================================' -ForegroundColor Yellow
        Write-Host '  IMPORTANT: TURN OFF ANTI-ALIASING / EDGE SMOOTHING' -ForegroundColor Yellow
        Write-Host '  in the game graphics options BEFORE starting in VR.' -ForegroundColor Yellow
        Write-Host '  Otherwise VR shows only a small flat 2D window.' -ForegroundColor Yellow
        Write-Host '  ========================================================' -ForegroundColor Yellow
        Write-Host '  [F5] toggles the diorama; [Home] recentres your view.' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  The sword was sharp enough before it gained a second viewpoint.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-BladeSnapshot -Game $game -Snapshot $snapshot; Write-Host '  [!!] Previous BladeVR files were restored.' -ForegroundColor Yellow }
            catch { $keepWork=$true; Write-Host "  [!!] Rollback needs review; backup kept at $work. $($_.Exception.Message)" -ForegroundColor Red }
        }
        throw
    } finally {
        if ($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
if ((('' + $env:PCVR_BLADE_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-BladeInstaller }
