$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$script:ForsakenRepo = 'GameOrDie007/Forsaken-VR'
$script:ForsakenPage = 'https://github.com/GameOrDie007/Forsaken-VR/releases'
$script:ForsakenRequired = @('Forsaken VR.cmd','game\projectx.exe','game\libopenxr_loader.dll',
    'game\Data\levels\alpha\alpha.mxv','install-manifest.txt','tools\setup.ps1','version.txt')
$script:ForsakenContract = New-PCVRInstallerContract -Id 'forsaken-vr' -GameName 'Forsaken VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:ForsakenPage -Routes @('PCVR') `
    -RequiredInstalledFileGroups $script:ForsakenRequired

function Get-ForsakenRelease($ReleaseData=$null) {
    if ($null -eq $ReleaseData -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FORSAKEN_TEST_RELEASE_JSON) {
        $ReleaseData = Get-Content -LiteralPath $env:PCVR_FORSAKEN_TEST_RELEASE_JSON -Raw -ErrorAction Stop | ConvertFrom-Json
    }
    $options = @{Repo=$script:ForsakenRepo;IncludePrerelease=$false;
        AssetPatterns=@('(?i)^Forsaken-VR-[0-9]+(?:\.[0-9]+)+-PCVR\.zip$');SkipReleasesWithoutMatchingAsset=$true}
    if ($null -ne $ReleaseData) { $options.ReleaseData = $ReleaseData }
    $release = Resolve-GitHubReleaseAsset @options
    if (-not $release.Resolved -or -not $release.Url -or [string]$release.Tag -notmatch '^v?(?<version>[0-9]+(?:\.[0-9]+)+)$') {
        throw 'No current PC VR publisher release was found.'
    }
    return [pscustomobject]@{Version=$Matches.version;Url=[string]$release.Url;PageUrl=[string]$release.PageUrl}
}

function Get-ForsakenPackageVersion([string]$Archive) {
    if (-not (Test-DownloadedPayload -Path $Archive -IntendedPath 'Forsaken-VR-PCVR.zip')) { return $null }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
        try {
            $entries = @{}
            foreach ($item in $zip.Entries) { $entries[$item.FullName.Replace('\','/')] = $item }
            $setup = $entries['Forsaken-VR/files/setup.ps1']
            if (-not $setup -or -not $entries['Forsaken-VR/files/game/projectx.exe'] -or
                -not $entries['Forsaken-VR/Setup.bat']) { return $null }
            $reader = New-Object IO.StreamReader($setup.Open())
            try { $source = $reader.ReadToEnd() } finally { $reader.Dispose() }
            if ($source -match '(?m)^\$Version\s*=\s*''(?<version>[0-9]+(?:\.[0-9]+)+)''\s*$') { return $Matches.version }
        } finally { $zip.Dispose() }
    } catch { return $null }
    return $null
}

function Get-ForsakenInstalled([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    foreach ($relative in $script:ForsakenRequired) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $null }
    }
    $line = ([string](Get-Content -LiteralPath (Join-Path $Root 'version.txt') -TotalCount 1 -ErrorAction Stop)).Trim()
    if ($line -notmatch '^Forsaken VR (?<version>[0-9]+(?:\.[0-9]+)+)$') { return $null }
    return [pscustomobject]@{Root=[IO.Path]::GetFullPath($Root);Version=$Matches.version}
}

function Write-ForsakenOwnership([string]$Root) {
    $manifest = Join-Path $Root 'install-manifest.txt'
    $records = New-Object 'System.Collections.Generic.List[object]'
    foreach ($line in @(Get-Content -LiteralPath $manifest -ErrorAction Stop)) {
        $relative = ([string]$line).Trim()
        if (-not $relative -or $relative.StartsWith('#') -or $relative.StartsWith('dir:')) { continue }
        if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw 'Publisher manifest contains an unsafe path.' }
        $target = [IO.Path]::GetFullPath((Join-Path $Root $relative))
        if (-not $target.StartsWith(($Root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)) {
            throw 'Publisher manifest points outside the VR folder.'
        }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $records.Add([pscustomobject]@{Path=$relative;SHA256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash})
        }
    }
    if ($records.Count -lt 20) { throw 'Publisher manifest did not list the installed VR runtime.' }
    $probe = Join-Path $Root '.pcvrhub_forsaken_ownership.csv'
    $temp = "$probe.tmp"
    $records | Export-Csv -LiteralPath $temp -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Move-Item -LiteralPath $temp -Destination $probe -Force -ErrorAction Stop
    return $probe
}

function Set-ForsakenDesktopShortcut([string]$Root) {
    $target = Join-Path $Root 'game\projectx.exe'
    $icon = Join-Path $PSScriptRoot 'ForsakenVR.ico'
    if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or -not (Test-Path -LiteralPath $icon -PathType Leaf)) {
        throw 'Forsaken VR shortcut target or icon is missing.'
    }
    $desktop = if ($env:PCVR_HUB_TEST_MODE -eq '1') { [string]$env:PCVR_FORSAKEN_TEST_DESKTOP } else {
        [Environment]::GetFolderPath('DesktopDirectory')
    }
    if (-not $desktop) { throw 'The desktop shortcut location could not be found.' }
    [void][IO.Directory]::CreateDirectory($desktop)
    $path = Join-Path $desktop 'Forsaken VR.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($path)
    $link.TargetPath = $target
    $link.Arguments = '-window -vr -vrres 100 -log'
    $link.WorkingDirectory = Split-Path -Parent $target
    $link.IconLocation = "$icon,0"
    $link.Description = 'Start Forsaken VR'
    $link.Save()
    $check = $shell.CreateShortcut($path)
    if ([string]$check.TargetPath -ne $target -or [string]$check.IconLocation -ne "$icon,0") {
        throw 'The Forsaken VR desktop shortcut could not be verified.'
    }
    return $path
}

function Invoke-ForsakenPublisher([string]$Setup,[string]$Work) {
    $args = '-NoProfile -ExecutionPolicy Bypass -File "' + $Setup + '" -Quiet -Json -NoSteam'
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        $args += ' -NoShortcuts -NoDownload -NoSearch'
        foreach ($pair in @(@('DataPath','PCVR_FORSAKEN_TEST_DATA'),@('DocumentsRoot','PCVR_FORSAKEN_TEST_DOCUMENTS'),
            @('UserRoot','PCVR_FORSAKEN_TEST_USER'),@('GamePath','PCVR_FORSAKEN_TEST_GAME'))) {
            $value = [Environment]::GetEnvironmentVariable($pair[1])
            if ($value) { $args += ' -' + $pair[0] + ' "' + ([IO.Path]::GetFullPath($value)) + '"' }
        }
    }
    Write-Host '  [..] Publisher Setup is installing Forsaken VR and game data. This may take several minutes.' -ForegroundColor Cyan
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = 'powershell.exe'
    $info.Arguments = $args
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.CreateNoWindow = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    if (-not $process.Start()) { throw 'Publisher Setup could not start.' }
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $frames = @('|','/','-','\')
    $frame = 0
    while (-not $process.WaitForExit(1000)) {
        Write-Host -NoNewline ("`r  [" + $frames[$frame++ % 4] + '] Publisher Setup is working...') -ForegroundColor Cyan
    }
    $process.WaitForExit()
    Write-Host "`r  [..] Publisher Setup finished; checking its result.                 " -ForegroundColor Cyan
    $output = [string]$stdout.Result
    $errorOutput = [string]$stderr.Result
    $result = $null
    try { $result = $output | ConvertFrom-Json -ErrorAction Stop } catch {}
    if ($process.ExitCode -ne 0 -or -not $result -or [string]$result.result -ne 'installed' -or
        -not [bool]$result.game.dataReady) {
        $detail = if ($result -and $result.error) { [string]$result.error } elseif ($errorOutput) { $errorOutput.Trim() } else { 'See the publisher setup log.' }
        throw "Publisher Setup did not complete (exit $($process.ExitCode)): $detail"
    }
    return $result
}

function Invoke-ForsakenInstaller {
    $work = $null
    try {
        Clear-Host
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Forsaken VR - Installer' -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  No purchased game is required. Publisher Setup downloads the' -ForegroundColor White
        Write-Host '  ForsakenX game data. Forsaken Remastered is optional for its' -ForegroundColor White
        Write-Host '  soundtrack and intro film.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check the current PC VR release...')

        $rememberedVrRoot = Get-PCVRRememberedGameFolder -GameId 'forsaken-vr' `
            -StateNames @('installed_path','user_located') -ProbeFiles @('Forsaken VR.cmd','game\projectx.exe')
        if ($rememberedVrRoot) {
            Write-Host "  Previous Forsaken VR location: $rememberedVrRoot" -ForegroundColor Gray
        }

        $release = $null
        try { $release = Get-ForsakenRelease }
        catch { Write-Host '  GitHub could not confirm the current release. An official ZIP can be used from Downloads.' -ForegroundColor Yellow }
        $testArchive = if ($env:PCVR_HUB_TEST_MODE -eq '1') { [string]$env:PCVR_FORSAKEN_TEST_ARCHIVE } else { '' }
        $local = if ($testArchive) { $testArchive } else { Find-PCVRDownloadedCandidate -Patterns @('Forsaken-VR-*-PCVR.zip') }
        $useLocal = [bool]$testArchive
        if ($local -and -not $testArchive) {
            $localVersion = Get-ForsakenPackageVersion $local
            if ($localVersion -and (-not $release -or $localVersion -eq $release.Version)) {
                Write-Host "  Found Forsaken VR PCVR v$localVersion in Downloads:" -ForegroundColor White
                Write-Host "  $local" -ForegroundColor Gray
                $useLocal = ((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$')
                if ($useLocal -and -not $release) { $release = [pscustomobject]@{Version=$localVersion;Url='';PageUrl=$script:ForsakenPage} }
            }
        }
        if (-not $release -and -not $useLocal) {
            Write-Host '  Download the current Forsaken VR PCVR ZIP from the publisher release page.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the release page...')
            Start-Process $script:ForsakenPage -ErrorAction Stop | Out-Null
            while (-not $useLocal) {
                [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
                $local = Find-PCVRDownloadedCandidate -Patterns @('Forsaken-VR-*-PCVR.zip')
                if (-not $local) {
                    $path = (Read-Host '  Drag the PCVR ZIP here, or press Enter to open the page again').Trim().Trim('"')
                    if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) { $local = $path }
                    else { Start-Process $script:ForsakenPage -ErrorAction Stop | Out-Null; continue }
                }
                $localVersion = Get-ForsakenPackageVersion $local
                if (-not $localVersion) { Write-Host '  This is not a usable Forsaken VR PCVR ZIP.' -ForegroundColor Yellow; continue }
                Write-Host "  Found Forsaken VR PCVR v${localVersion}: $local" -ForegroundColor White
                Write-Host '  The online version could not be confirmed.' -ForegroundColor Yellow
                $useLocal = ((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$')
                if ($useLocal) { $release = [pscustomobject]@{Version=$localVersion;Url='';PageUrl=$script:ForsakenPage} }
            }
        }
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive = Join-Path $work 'Forsaken-VR-PCVR.zip'
        if ($useLocal) { Copy-Item -LiteralPath $local -Destination $archive -Force -ErrorAction Stop }
        else {
            $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Forsaken VR $($release.Version)" `
                -ManualUrl $release.PageUrl -AllowSkip:$false
            if (-not $ok) { throw 'The current publisher ZIP is not ready.' }
        }
        $packageVersion = Get-ForsakenPackageVersion $archive
        if (-not $packageVersion -or $packageVersion -ne $release.Version) {
            throw 'The PCVR ZIP does not match the selected publisher release.'
        }
        $expanded = Join-Path $work 'expanded'
        if ((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $expanded -Label 'Forsaken VR' -AllowSkip:$false) -ne 'ok') {
            throw 'The Forsaken VR ZIP could not be extracted.'
        }
        $setup = Join-Path $expanded 'Forsaken-VR\files\setup.ps1'
        if (-not (Test-Path -LiteralPath $setup -PathType Leaf)) { throw 'Publisher Setup is missing from the ZIP.' }
        Write-Host '  Publisher Setup may install in the Remaster VR subfolder or your Documents/Games folder.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Forsaken VR...')
        $result = Invoke-ForsakenPublisher -Setup $setup -Work $work
        $installed = Get-ForsakenInstalled ([string]$result.vrFolder)
        if (-not $installed -or $installed.Version -ne $release.Version) { throw 'Publisher Setup ended without a complete matching VR installation.' }
        [void](Write-ForsakenOwnership -Root $installed.Root)
        $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FORSAKEN_TEST_RECEIPT) {
            [IO.Path]::GetFullPath($env:PCVR_FORSAKEN_TEST_RECEIPT)
        } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:ForsakenContract -GameDir $installed.Root `
            -Version $installed.Version -Route PCVR -InstalledPathReceiptPaths @($receipt) `
            -AdditionalVersionReceiptPaths @((Join-Path $installed.Root '.pcvrhub_version')))
        $shortcut = $null
        try {
            $shortcut = Set-ForsakenDesktopShortcut -Root $installed.Root
            Write-Host "  [OK] Desktop shortcut: $shortcut" -ForegroundColor Green
        } catch {
            Write-Host "  [!!] Desktop shortcut needs repair: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Write-Host "  [OK] Forsaken VR $($installed.Version) is ready." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor White
        if ($shortcut) { Write-Host '  Alternative: use the Forsaken VR desktop shortcut.' -ForegroundColor White }
        Write-Host ''
        Write-Host '  The tunnels are open. Keep your thrusters ready.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {
        if ($work) { try { Remove-PCVRInstallerTempSession -Path $work } catch {} }
    }
}

if ($env:PCVR_FORSAKEN_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-ForsakenInstaller; break }
        catch {
            $message = "Forsaken VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
