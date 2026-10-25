$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Brutal Legend VR Installer'
$script:BlvrId = 'brutal-legend-vr'
$script:BlvrPage = 'https://github.com/nikamigaming-create/BrutalLegendVR/releases'
$script:BlvrRepo = 'nikamigaming-create/BrutalLegendVR'
$script:BlvrReviewedDirect = 'https://github.com/nikamigaming-create/BrutalLegendVR/releases/download/v0.1.0-preview.6/BrutalLegendVR-0.1.0-preview.6-windows.zip'
$script:BlvrExpectedExeSha = '872DC676E8FD77AD3351DD9DFCC99E89353AAE0ED9857272A65FD47F298FB0B1'
$script:BlvrContract = New-PCVRInstallerContract -Id $script:BlvrId -GameName 'Brutal Legend VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $script:BlvrPage -Routes @('Steam') `
    -RequiredInstalledFileGroups @('Play VR.cmd','Setup VR.cmd','BrutalLegendVR.ico','bin\d3d9.dll','tools\blvr_xr_host.exe',
        'settings.json','artifacts\eddie-rig\eddie.rigcache','.pcvrhub_brutallegendvr_ownership.csv')

function Get-BlvrRuntimeRoot {
    if ($env:PCVR_BLVR_TEST_ROOT) {
        $root = [IO.Path]::GetFullPath($env:PCVR_BLVR_TEST_ROOT)
        if (-not $root.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path $root 'blvr-fixture.txt') -PathType Leaf)) {
            throw 'Brutal Legend test runtime must be an isolated temporary fixture.'
        }
        return $root
    }
    return (Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\BrutalLegendVR')
}
function Get-BlvrSteamGame {
    if ($env:PCVR_BLVR_TEST_GAME) {
        $root = [IO.Path]::GetFullPath($env:PCVR_BLVR_TEST_GAME)
        if (-not $root.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path $root 'blvr-fixture.txt') -PathType Leaf)) {
            throw 'Brutal Legend test game must be an isolated temporary fixture.'
        }
        return $root
    }
    $saved = Get-PCVRRememberedGameFolder -GameId $script:BlvrId -StateNames @('base_game_path','user_located') -ProbeFiles @('BrutalLegend.exe')
    $paths = @($saved)
    try { $paths += Find-SteamGameFolder -AppId '225260' -SteamFolderNames @('BrutalLegend','Brutal Legend') -ProbeExe 'BrutalLegend.exe' -HubGameId $script:BlvrId } catch { }
    $paths += 'C:\Program Files (x86)\Steam\steamapps\common\BrutalLegend'
    foreach ($path in @($paths | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path -LiteralPath (Join-Path $path 'BrutalLegend.exe') -PathType Leaf) { return [IO.Path]::GetFullPath($path) }
    }
    $picked = Get-GameFolderInteractive -GameName 'Brutal Legend (Steam)' -ProbeFile 'BrutalLegend.exe' `
        -ManualUrl 'https://store.steampowered.com/app/225260/'
    if ($picked -and (Test-Path -LiteralPath (Join-Path $picked 'BrutalLegend.exe') -PathType Leaf)) {
        [void](Save-HubRememberedGameFolder -GameId $script:BlvrId -Title 'Brutal Legend VR' -GameDir $picked -ProbeFiles @('BrutalLegend.exe') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose the Steam Brutal Legend folder containing BrutalLegend.exe.'
}
function Get-BlvrPackageInfo([string]$Archive) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $setup = @($zip.Entries | Where-Object { $_.FullName -match '^BrutalLegendVR-(?<version>\d+\.\d+\.\d+(?:-(?:preview|alpha|beta|rc)\.\d+)?)/Setup VR\.cmd$' }) | Select-Object -First 1
        if (-not $setup) { return $null }
        $root = $setup.FullName.Substring(0,$setup.FullName.Length - 'Setup VR.cmd'.Length)
        foreach ($required in @('Play VR.cmd','bin/d3d9.dll','bin/openxr_loader.dll','tools/blvr_setup.exe','tools/blvr_xr_host.exe','scripts/uninstall.ps1')) {
            if (-not @($zip.Entries | Where-Object { $_.FullName -eq ($root + $required) }).Count) { return $null }
        }
        return [pscustomobject]@{Version=[regex]::Match($root,'BrutalLegendVR-(\d+\.\d+\.\d+(?:-(?:preview|alpha|beta|rc)\.\d+)?)').Groups[1].Value;Folder=$root.TrimEnd('/')}
    } finally { $zip.Dispose() }
}
function Get-BlvrRelease {
    if ($env:PCVR_BLVR_TEST_ARCHIVE) {
        $info = Get-BlvrPackageInfo $env:PCVR_BLVR_TEST_ARCHIVE
        if (-not $info) { throw 'The Brutal Legend test ZIP is incomplete.' }
        return [pscustomobject]@{Version=$info.Version;Url=$env:PCVR_BLVR_TEST_ARCHIVE;Local=$true;Page=$script:BlvrPage}
    }
    try { $release = Resolve-GitHubReleaseAsset -Repo $script:BlvrRepo -IncludePrerelease $true `
        -AssetPatterns @('(?i)^BrutalLegendVR-\d+\.\d+\.\d+(?:-(?:preview|alpha|beta|rc)\.\d+)?-windows\.zip$') -SkipReleasesWithoutMatchingAsset } catch { $release = $null }
    if ($release -and $release.Resolved -and $release.Tag -match '^v?(\d+\.\d+\.\d+(?:-(?:preview|alpha|beta|rc)\.\d+)?)$') {
        return [pscustomobject]@{Version=$Matches[1];Url=[string]$release.Url;Local=$false;Page=[string]$release.PageUrl}
    }
    Write-Host '  [!!] GitHub could not confirm the current Brutal Legend VR preview.' -ForegroundColor Yellow
    return [pscustomobject]@{Version='';Url='';Local=$false;Page=$script:BlvrPage}
}
function Get-BlvrArchive($Release,[string]$Destination) {
    if ($Release.Local) { Copy-Item -LiteralPath $Release.Url -Destination $Destination -Force; return }
    if ($Release.Url) {
        [void](Invoke-SafeDownload -Urls @($Release.Url) -Destination $Destination -Label "Brutal Legend VR $($Release.Version)" `
            -ManualUrl $Release.Page -AllowSkip:$false)
    } else {
        $candidate = Find-PCVRDownloadedCandidate -Patterns @('BrutalLegendVR-*-windows.zip')
        if ($candidate -and (Get-BlvrPackageInfo $candidate)) {
            Write-Host "  Found in Downloads: $candidate" -ForegroundColor Cyan
            if ((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$') { Copy-Item -LiteralPath $candidate -Destination $Destination -Force; return }
        }
        Write-Host '  Trying the last reviewed publisher ZIP; the current release could not be checked.' -ForegroundColor Yellow
        [void](Invoke-SafeDownload -Urls @($script:BlvrReviewedDirect) -Destination $Destination -Label 'Brutal Legend VR publisher ZIP' `
            -ManualUrl $Release.Page -AllowSkip:$false)
    }
}
function Test-BlvrPrepared([string]$Game,[string]$Runtime) {
    if (-not (Test-Path -LiteralPath (Join-Path $Game 'BrutalLegend.exe') -PathType Leaf)) { return $false }
    foreach ($file in @('Play VR.cmd','tools\blvr_xr_host.exe','tools\blvr_setup.exe',
        'settings.json','artifacts\eddie-rig\eddie.rigcache')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Runtime $file) -PathType Leaf)) { return $false }
    }
    try {
        $settings = Get-Content -LiteralPath (Join-Path $Runtime 'settings.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $settings.game_dir -or
            [IO.Path]::GetFullPath([string]$settings.game_dir).TrimEnd([char[]]'\/') -ine
            [IO.Path]::GetFullPath($Game).TrimEnd([char[]]'\/')) { return $false }
    } catch { return $false }
    if ($env:PCVR_BLVR_TEST_GAME) { return $true }
    try {
        $check = Start-Process -FilePath (Join-Path $Runtime 'tools\blvr_setup.exe') -ArgumentList '--check-assets' `
            -WorkingDirectory $Runtime -WindowStyle Hidden -PassThru -Wait -ErrorAction Stop
        return ($null -ne $check.ExitCode -and $check.ExitCode -eq 0)
    } catch { return $false }
}
function Get-BlvrDesktopPath {
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        $desktop = [string]$env:PCVR_BLVR_TEST_DESKTOP
        $full = if ($desktop) { [IO.Path]::GetFullPath($desktop) } else { '' }
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)) { throw 'Brutal Legend test desktop must be isolated under the temporary directory.' }
    } else { $full = [Environment]::GetFolderPath('DesktopDirectory') }
    if (-not $full) { throw 'The Desktop folder could not be found.' }
    [void][IO.Directory]::CreateDirectory($full)
    return (Join-Path $full 'Brutal Legend VR.lnk')
}
function Set-BlvrDesktopShortcut([string]$Runtime,[string]$Game) {
    $target = Join-Path $Runtime 'Play VR.cmd'
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw 'The publisher Play VR launcher is missing.' }
    $path = Get-BlvrDesktopPath
    $marker = Join-Path $Runtime '.pcvrhub_blvr_desktop_shortcut.json'
    $shell = New-Object -ComObject WScript.Shell
    $created = $false
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $old = $shell.CreateShortcut($path)
        if ([string]$old.TargetPath -ine $target -or [string]$old.WorkingDirectory -ine $Runtime) {
            throw 'Brutal Legend VR desktop shortcut belongs to another target. Rename it, then retry.'
        }
    } else {
        $link = $shell.CreateShortcut($path)
        $link.TargetPath = $target
        $link.WorkingDirectory = $Runtime
        $link.IconLocation = (Join-Path $Runtime 'BrutalLegendVR.ico') + ',0'
        $link.Description = 'Start Brutal Legend with the publisher VR launcher'
        $link.Save()
        $created = $true
    }
    $check = $shell.CreateShortcut($path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
        [string]$check.TargetPath -ine $target -or [string]$check.WorkingDirectory -ine $Runtime -or
        [string]$check.IconLocation -ine ((Join-Path $Runtime 'BrutalLegendVR.ico') + ',0')) {
        throw 'The VR desktop shortcut was not saved with the correct launcher.'
    }
    if ($created) {
        [pscustomobject]@{Path=$path;Hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash} |
            ConvertTo-Json -Compress | Set-Content -LiteralPath $marker -Encoding UTF8
    }
    return [pscustomobject]@{Path=$path;Created=$created}
}
function Save-BlvrRuntimeSnapshot([string]$Runtime,[string]$Source,[string]$Folder) {
    [void][IO.Directory]::CreateDirectory($Folder)
    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $sourceBase = [IO.Path]::GetFullPath($Source).TrimEnd([char[]]'\/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Source -File -Recurse)) {
        [void]$names.Add((Assert-PCVROwnedRelativePath $file.FullName.Substring($sourceBase.Length + 1)))
    }
    $manifestName = '.pcvrhub_brutallegendvr_ownership.csv'
    $manifest = Join-Path $Runtime $manifestName
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest)) {
            [void]$names.Add((Assert-PCVROwnedRelativePath ([string]$row.RelativePath)))
        }
    }
    [void]$names.Add($manifestName)
    [void]$names.Add('.pcvrhub_version')
    [void]$names.Add('.pcvrhub_blvr_desktop_shortcut.json')
    $rows = @(); $index = 0
    foreach ($relative in $names) {
        $index++
        $target = Join-OwnedRelativePath $Runtime $relative
        $exists = Test-Path -LiteralPath $target -PathType Leaf
        $key = ('{0:D5}.bak' -f $index)
        $rows += [pscustomobject]@{Relative=$relative;Key=$key;Exists=$exists}
        if ($exists) { Copy-Item -LiteralPath $target -Destination (Join-Path $Folder $key) -Force -ErrorAction Stop }
    }
    $backup = Join-Path $Runtime '.pcvrhub_brutallegendvr_backup'
    $hadBackup = Test-Path -LiteralPath $backup -PathType Container
    if ($hadBackup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $Folder 'original-backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{Rows=$rows;Folder=$Folder;HadBackup=$hadBackup}
}
function Restore-BlvrRuntimeSnapshot([string]$Runtime,$Snapshot) {
    foreach ($row in $Snapshot.Rows) {
        $target = Join-OwnedRelativePath $Runtime $row.Relative
        if ($row.Exists) {
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $target -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $Runtime '.pcvrhub_brutallegendvr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    if ($Snapshot.HadBackup) { Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'original-backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}
function Invoke-BlvrInstaller {
    $work = $null; $snapshot = $null; $changed = $false; $runtime = $null; $shortcut = $null
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Brutal Legend VR - Installer' -ForegroundColor Cyan
    Write-Host '  Steam version only; experimental preview' -ForegroundColor Yellow
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  The publisher checks the exact Steam game build and prepares your own game assets.' -ForegroundColor White
    Write-Host '  The complete portable VR runtime stays outside the game folder.' -ForegroundColor White
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Brutal Legend...')
    $game = Get-BlvrSteamGame
    Write-Host "  Game: $game" -ForegroundColor Green
    $exe = Join-Path $game 'BrutalLegend.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'BrutalLegend.exe is missing.' }
    if (-not $env:PCVR_BLVR_TEST_GAME -and (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne $script:BlvrExpectedExeSha) {
        throw 'The publisher does not support this Steam game build. No files were changed.'
    }
    if (Get-Process -Name BrutalLegend -ErrorAction SilentlyContinue) { throw 'Close Brutal Legend before VR setup.' }
    try {
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive = Join-Path $work 'BrutalLegendVR.zip'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the current Brutal Legend VR package...')
        $release = Get-BlvrRelease
        Get-BlvrArchive -Release $release -Destination $archive
        $info = Get-BlvrPackageInfo $archive
        if (-not $info) { throw 'The selected publisher ZIP lacks the required VR runtime files.' }
        $expanded = Join-Path $work 'expanded'
        if ((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $expanded -Label 'Brutal Legend VR' -AllowSkip:$false) -ne 'ok') {
            throw 'The Brutal Legend VR ZIP could not be extracted.'
        }
        $source = Join-Path $expanded $info.Folder
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'BrutalLegendVR.ico') -Destination (Join-Path $source 'BrutalLegendVR.ico') -Force -ErrorAction Stop
        $runtime = Get-BlvrRuntimeRoot
        [void][IO.Directory]::CreateDirectory($runtime)
        if (-not (Test-InstallerTargetWritable $runtime)) { throw 'The VR runtime folder is not writable.' }
        Write-Host '  Preparing a recovery copy of existing runtime files; this can take a minute.' -ForegroundColor Gray
        $snapshot = Save-BlvrRuntimeSnapshot -Runtime $runtime -Source $source -Folder (Join-Path $work 'rollback')
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install the complete VR runtime...')
        $changed = $true
        [void](Install-OwnedModPayload -SourceRoot $source -GameRoot $runtime -Identity 'brutallegendvr' `
            -KeepExistingRelativePaths @('controls.ini','settings.json') -AdoptIdenticalExisting -ProgressLabel 'Preparing Brutal Legend VR')
        $setup = Join-Path $runtime 'tools\blvr_setup.exe'
        $attempt = 0
        while ($true) {
            Write-Host ''
            Write-Host ('=' * 60) -ForegroundColor Magenta
            Write-Host '  REQUIRED PUBLISHER STEP - VR WILL NOT WORK WITHOUT THIS' -ForegroundColor Yellow
            Write-Host "  1. Select BrutalLegend.exe in publisher Setup: $exe" -ForegroundColor Cyan
            Write-Host '  2. Click PREPARE / REPAIR GAME and wait for completion.' -ForegroundColor Green
            Write-Host '  3. Only then close publisher Setup and return here.' -ForegroundColor Cyan
            Write-Host ('=' * 60) -ForegroundColor Magenta
            Write-Host ''
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
            $attempt++
            $setupExit = 0
            if ($env:PCVR_BLVR_TEST_GAME) {
                $prepareAt = if ($env:PCVR_BLVR_TEST_PREPARE -eq '2') { 2 } elseif ($env:PCVR_BLVR_TEST_PREPARE -eq '1') { 1 } else { [int]::MaxValue }
                if ($attempt -ge $prepareAt) {
                    $settings = @{game_dir=$game} | ConvertTo-Json -Compress
                    [IO.File]::WriteAllText((Join-Path $runtime 'settings.json'),$settings)
                    $rig = Join-Path $runtime 'artifacts\eddie-rig\eddie.rigcache'
                    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $rig))
                    [IO.File]::WriteAllText($rig,'fixture')
                }
            } else {
                try {
                    $process = Start-Process -FilePath $setup -WorkingDirectory $runtime -PassThru -Wait -ErrorAction Stop
                    $setupExit = $process.ExitCode
                } catch { $setupExit = -1 }
            }
            if ($null -ne $setupExit -and $setupExit -eq 0) {
                Write-Host '  Checking the prepared publisher assets; this can take a few seconds.' -ForegroundColor Gray
                if (Test-BlvrPrepared -Game $game -Runtime $runtime) { break }
            }
            Write-Host '  The model preparation is not complete for the game shown above.' -ForegroundColor Yellow
            Write-Host '  Publisher Setup can be opened again without downloading the ZIP again.' -ForegroundColor White
            if ($env:PCVR_BLVR_TEST_GAME -and $env:PCVR_BLVR_TEST_PREPARE -ne '2') {
                throw 'Publisher asset preparation is incomplete.'
            }
            if ((Read-Host '  Press Enter to reopen publisher Setup, or Q to return to recovery').Trim() -ieq 'Q') {
                throw 'Publisher preparation is incomplete. The previous runtime was restored.'
            }
        }
        $shortcut = Set-BlvrDesktopShortcut -Runtime $runtime -Game $game
        $receipt = if ($env:PCVR_BLVR_TEST_RECEIPT) { $env:PCVR_BLVR_TEST_RECEIPT } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:BlvrContract -GameDir $runtime `
            -Version $info.Version -InstalledPathReceiptPaths @($receipt) -Route Steam)
        [void](Save-HubRememberedGameFolder -GameId $script:BlvrId -Title 'Brutal Legend VR' -GameDir $game -ProbeFiles @('BrutalLegend.exe') -StateName 'base_game_path')
        $changed = $false
        Write-Host "  [OK] Brutal Legend VR $($info.Version) is ready." -ForegroundColor Green
        Write-Host "  VR publisher folder: $runtime" -ForegroundColor Cyan
        Write-Host "  Desktop shortcut: $($shortcut.Path)" -ForegroundColor Cyan
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor White
        Write-Host '  Alternative: use the Brutal Legend VR desktop shortcut.' -ForegroundColor White
        Write-Host '  If Windows reports an error only on first VR launch, close it and try Start in VR once more.' -ForegroundColor Yellow
        Write-Host '  If it repeats, use the publisher Check installation and read the VR logs.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Eddie Riggs called. The roadies are now an army.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($shortcut -and $shortcut.Created -and (Test-Path -LiteralPath $shortcut.Path -PathType Leaf)) {
            try { Remove-Item -LiteralPath $shortcut.Path -Force -ErrorAction Stop } catch { }
        }
        if ($changed -and $snapshot -and $runtime) {
            try { Restore-BlvrRuntimeSnapshot -Runtime $runtime -Snapshot $snapshot; Write-Host '  [!!] Previous VR runtime files were restored.' -ForegroundColor Yellow }
            catch { Write-Host "  [!!] Runtime rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
        throw
    } finally {
        if ($work) { Remove-PCVRInstallerTempSession -Path $work }
    }
}

if ($env:PCVR_BLVR_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-BlvrInstaller; break }
        catch {
            $message = "Brutal Legend VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
