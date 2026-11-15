. (Join-Path $PSScriptRoot 'PublisherGameHandoff.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')

$script:Mafia2Repo = 'josvitorkjr45/mafia2-vr-mod'
$script:Mafia2Asset = '(?i)^(?:mafia2modvr|m2vr|mafia[ ._-]*ii.*vr)[\w .()-]*\.zip$'
$script:Mafia2Base = @('pc\mafia2.exe','pc\sds\tables\tables.sds')
$script:Mafia2Files = @(
    'm2vr.asi','M2VR-Launcher.exe','mafia2.exe.bak','Uninstall-M2VR.exe',
    'd3d9.dll','dinput8.dll','jsoncpp.dll','m2vr.ini','dxvk.conf','openxr_loader.dll',
    'm2vr_openvr.dll','m2vr_openvr.json','m2vr_xrbridge.dll','m2vr_xrbridge.json','m2vr_xrhost.exe'
)

function Get-Mafia2Target {
    $candidate = Get-PCVRRecoveryInput -PathType Container
    if (-not $candidate) {
        $file = Get-PCVRRecoveryInput -PathType Leaf
        if ($file -and [IO.Path]::GetFileName($file) -ieq 'mafia2.exe') { $candidate = $file }
    }
    if (-not $candidate) {
        $candidate = Find-SteamGameFolder -AppId '50130' -SteamFolderNames @('Mafia II') -GogNames @('Mafia II','Mafia II (Classic)','Mafia II Classic') -ProbeExe $script:Mafia2Base[0] -HubGameId 'mafia-ii-classic-vr'
    }
    while ($true) {
        if ($candidate) {
            $root = Resolve-PCVRInstallerOriginalFolder -GameId 'mafia-ii-classic-vr' -Path $candidate -ProbeFiles $script:Mafia2Base
            if ($root) { return $root }
            Write-Host '  Choose the Mafia II Classic folder containing pc\mafia2.exe and the original game data.' -ForegroundColor Yellow
        }
        $candidate = ('' + (Read-Host '  Drop the Mafia II Classic folder or mafia2.exe, or enter Q to cancel')).Trim().Trim('"').Trim("'")
        if (-not $candidate -or $candidate -ieq 'Q') { return }
    }
}

function Get-Mafia2SetupVersion([string]$Path) {
    if (-not (Test-PublisherVrPe $Path)) { return }
    $info = (Get-Item -LiteralPath $Path).VersionInfo
    if ($info.ProductName -match '(?i)^Mafia II Classic VR' -and $info.FileDescription -match '(?i)\bInstaller\b' -and
        $info.ProductVersion -match '^v?(\d+\.\d+\.\d+)(?:\.0)?$') {
        return ('v' + $Matches[1])
    }
}

function Get-Mafia2PublisherSetup([string]$Asset,[string]$Work) {
    if ([IO.Path]::GetExtension($Asset) -ieq '.exe') {
        if (Get-Mafia2SetupVersion $Asset) { return $Asset }
        throw 'Choose the official Mafia II Classic VR installer or its complete release ZIP.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Asset)
    $setups = @()
    try {
        foreach ($entry in $zip.Entries) {
            [void](Assert-PCVROwnedRelativePath -Relative $entry.FullName.TrimEnd('\','/'))
        }
        foreach ($entry in $zip.Entries) {
            if ($entry.Name -notmatch '\.exe$') { continue }
            $probe = Join-Path $Work ('candidate-' + [guid]::NewGuid().ToString('N') + '.exe')
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$probe)
            if (Get-Mafia2SetupVersion $probe) { $setups += $probe }
        }
    } finally { $zip.Dispose() }
    if ($setups.Count -ne 1) { throw 'The archive must contain one usable Mafia II Classic VR publisher installer.' }
    return $setups[0]
}

function Get-Mafia2PublisherRegistration {
    foreach ($view in 'Registry32','Registry64') {
        $hive = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine',$view)
        try {
            $key = $hive.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Uninstall\M2VR_josvitorkjr45')
            if ($key) {
                try {
                    return @{ Path=$key.GetValue('InstallLocation'); Version=$key.GetValue('DisplayVersion') }
                } finally { $key.Dispose() }
            }
        } finally { $hive.Dispose() }
    }
}

function Test-Mafia2LargeAddressAware([string]$Path) {
    if (-not (Test-PublisherVrPe $Path)) { return $false }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $reader = [IO.BinaryReader]::new($stream)
        $stream.Position = 60
        $stream.Position = $reader.ReadUInt32() + 22
        return (($reader.ReadUInt16() -band 0x20) -ne 0)
    } finally { $stream.Dispose() }
}

function Invoke-Mafia2PublisherSetup([string]$Setup) {
    $process = Start-Process -FilePath $Setup -WorkingDirectory (Split-Path -Parent $Setup) -PassThru -Wait -ErrorAction Stop
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) {
        throw "Publisher setup closed with exit code $($process.ExitCode)."
    }
}

function Confirm-Mafia2PublisherLaunch([string]$Pc,[switch]$Retry) {
    Set-Clipboard -Value $Pc -DeferManualFallback
    if ($global:PCVRLastClipboardWriteSucceeded) {
        Write-Host '  The folder path is on your clipboard.'
    } else {
        Show-PCVRClipboardManualFallback -Text $Pc
    }
    Write-Host "  Folder containing mafia2.exe: $Pc" -ForegroundColor Cyan
    Write-Host '  Publisher setup requires administrator permission. Approve the Windows UAC prompt.'
    Write-Host '  In the empty game-folder field, press Ctrl+V or right-click and choose Paste.'
    $message = if ($Retry) { 'Press Enter to reopen the publisher setup...' } else { 'Press Enter to open the publisher setup...' }
    [void](Wait-PCVRExplicitEnter -Message $message)
}

function Confirm-Mafia2PublisherSetup([string]$Pc,[string]$Version,[datetime]$Before,[string]$Checkpoint) {
    $registration = Get-Mafia2PublisherRegistration
    $uninstaller = Join-Path $Pc 'Uninstall-M2VR.exe'
    if ($Checkpoint -eq 'after setup' -and [IO.File]::GetLastWriteTimeUtc($uninstaller) -le $Before) {
        throw 'Publisher setup did not complete a new installation in the selected folder.'
    }
    $registeredVersion = if ($registration.Version -match '^v?(\d+\.\d+\.\d+)(?:\.0)?$') { 'v' + $Matches[1] }
    if (-not $registration.Path -or [IO.Path]::GetFullPath($registration.Path).TrimEnd('\','/') -ine $Pc -or
        $registeredVersion -ne $Version) {
        throw 'Publisher setup did not register the selected game folder and mod version.'
    }
    $missing = foreach ($name in $script:Mafia2Files) {
        $path = Join-Path $Pc $name
        $present = [IO.File]::Exists($path) -and ([IO.FileInfo]::new($path)).Length -gt 0
        Write-Verbose ("Mafia II {0}: {1} present={2}" -f $Checkpoint,$name,$present) -Verbose
        if (-not $present) { $name }
    }
    if ($missing) { throw ('Required files are missing: ' + ($missing -join ', ') + '. Check the selected folder, permissions and installer log.') }
    if (-not (Test-Mafia2LargeAddressAware (Join-Path $Pc 'mafia2.exe'))) {
        throw 'The installed Mafia II executable is missing the required 4 GB flag. Check the patch result in the publisher setup.'
    }
}

function Invoke-Mafia2VrSetup([string]$InstallerFolder) {
    $page = "https://github.com/$script:Mafia2Repo/releases"
    $proof = @($script:Mafia2Files | ForEach-Object { "pc\$_" })
    $contract = New-PCVRInstallerContract -Id 'mafia-ii-classic-vr' -GameName 'Mafia II (Classic)' -Acquisition GitHub -RequiredInstalledFileGroups ($script:Mafia2Base + $proof) -Routes @('Current') -ReleasePageUrl $page -AntivirusNotice
    Write-Host '  Mafia II (Classic) 1.0.0.1 with motion controls'
    Write-Host '  Start the original game once, then close it. The publisher setup patches mafia2.exe and keeps an original backup.'
    Write-Host '  Use the publisher uninstaller in Windows Installed apps to restore the original executable.'
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to locate Mafia II Classic...')

    while ($true) {
        $work = $null
        $snapshot = $null
        $keepWork = $false
        try {
            Write-Host '--- [1/4] Finding Mafia II Classic ---' -ForegroundColor Cyan
            $root = Get-Mafia2Target
            if (-not $root) { return }
            $pc = Join-Path $root 'pc'
            if (Get-Process -Name 'mafia2','M2VR-Launcher','m2vr_xrhost' -ErrorAction SilentlyContinue) {
                throw 'Close Mafia II and its VR launcher before continuing.'
            }
            $original = Join-Path $pc 'mafia2.exe'
            if ([IO.File]::Exists("$original.bak")) { $original = "$original.bak" }
            $originalVersion = (Get-Item -LiteralPath $original).VersionInfo
            if ($originalVersion.FileVersion -notmatch '^1[.,]\s*0[.,]\s*0[.,]\s*1(?:\D|$)' -and
                $originalVersion.ProductVersion -notmatch '^1[.,]\s*0[.,]\s*0[.,]\s*1(?:\D|$)') {
                throw 'The selected folder does not contain a supported Mafia II Classic 1.0.0.1 executable.'
            }
            if (-not (Test-InstallerTargetWritable (Join-Path $root '.pcvrhub_version')) -or
                -not (Test-InstallerTargetWritable (Join-Path $pc 'm2vr.ini'))) {
                throw 'The Hub cannot write to this game folder. Choose a writable installation of Mafia II Classic.'
            }
            $prior = Get-Mafia2PublisherRegistration
            if ($prior.Path -and [IO.Path]::GetFullPath($prior.Path).TrimEnd('\','/') -ine $pc) {
                throw 'The publisher installer manages one folder at a time. Remove its VR mod from the other game copy in Windows Installed apps first.'
            }
            if (-not $prior.Path -and (@($script:Mafia2Files | Where-Object { [IO.File]::Exists((Join-Path $pc $_)) }).Count -gt 0)) {
                throw 'This folder already contains a graphics/input wrapper, a manual M2VR install or an earlier backup. Use a clean copy or remove the existing mod first.'
            }
            Write-Host "  [OK] $root" -ForegroundColor Green
            Write-Host '--- [2/4] Downloading the Windows release ---' -ForegroundColor Cyan
            Write-Host "  Source: $page"
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download or check the file you supplied...')
            $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr-mafia2-' + [guid]::NewGuid().ToString('N'))
            [void][IO.Directory]::CreateDirectory($work)
            $asset = Get-PCVRRecoveryInput -PathType Leaf
            if (-not $asset -or [IO.Path]::GetFileName($asset) -ieq 'mafia2.exe' -or [IO.Path]::GetExtension($asset) -notin @('.zip','.exe')) {
                Write-Host '  Checking GitHub and downloading the package. Progress appears while it downloads.'
                $release = Resolve-GitHubReleaseAsset -Repo $script:Mafia2Repo -AssetPatterns @($script:Mafia2Asset) -SkipReleasesWithoutMatchingAsset
                if (-not $release.Url) { throw 'No usable Windows release was found. Download the publisher ZIP and drop it into recovery.' }
                $asset = Join-Path $work 'release.zip'
                if (-not (Invoke-SafeDownload -Urls @($release.Url) -Destination $asset -Label 'Mafia II Classic VR' -ManualUrl $page -AllowSkip:$false -PlainProgress -FunctionalPayloadOnly -DisableGitHubAssetReresolution)) {
                    throw 'Download did not complete. Retry or supply the publisher ZIP.'
                }
            }
            $setup = Get-Mafia2PublisherSetup $asset $work
            $version = Get-Mafia2SetupVersion $setup
            Write-Host '--- [3/4] Installing with the publisher setup ---' -ForegroundColor Cyan
            Confirm-Mafia2PublisherLaunch $pc
            Write-Host '  Saving the files that publisher setup may change.'
            $empty = Join-Path $work 'snapshot-input'
            [void][IO.Directory]::CreateDirectory($empty)
            $snapshot = Save-PCVRPublisherZipSnapshot -GameRoot $root -Stage $empty -Identity 'mafia2vr' -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths ($proof + @('pc\mafia2.exe','pc\m2vr.ini.padrao-do-lancador','pc\m2vr_ini.padrao-do-lancador','pc\videoconfig.cfg.m2vr-original'))
            $ini = Join-Path $pc 'm2vr.ini'
            if ([IO.File]::Exists($ini)) {
                $savedIni = "$ini.before-$((Get-Date).ToString('yyyyMMdd-HHmmssfff'))"
                [IO.File]::Copy($ini,$savedIni)
                Write-Host "  Your previous VR settings were saved to $savedIni"
            }
            $uninstaller = Join-Path $pc 'Uninstall-M2VR.exe'
            $before = [IO.File]::GetLastWriteTimeUtc($uninstaller)
            Invoke-Mafia2PublisherSetup $setup
            Write-Host '--- [4/4] Verifying the VR installation ---' -ForegroundColor Cyan
            Confirm-Mafia2PublisherSetup $pc $version $before 'after setup'
            $paths = @($proof | ForEach-Object { Join-Path $root $_ })
            $runPublisher = ${function:Invoke-Mafia2PublisherSetup}
            $checkPublisher = ${function:Confirm-Mafia2PublisherSetup}
            $getSetup = ${function:Get-Mafia2PublisherSetup}
            $confirmLaunch = ${function:Confirm-Mafia2PublisherLaunch}
            $retry = {
                & $confirmLaunch -Pc $pc -Retry
                $restage = Join-Path $root ('_pcvrhub_restage_mafia2_' + [guid]::NewGuid().ToString('N'))
                [void][IO.Directory]::CreateDirectory($restage)
                try {
                    $restagedAsset = Join-Path $restage ('release' + [IO.Path]::GetExtension($asset))
                    [IO.File]::Copy($asset,$restagedAsset)
                    $restagedSetup = & $getSetup $restagedAsset $restage
                    & $runPublisher $restagedSetup
                    & $checkPublisher $pc $version $before 'after retry'
                } finally {
                    if ([IO.Path]::GetFullPath($restage).StartsWith((Join-Path $root '_pcvrhub_restage_mafia2_'),[StringComparison]::OrdinalIgnoreCase)) {
                        Remove-Item -LiteralPath $restage -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }.GetNewClosure()
            if (-not (Confirm-PlacedFilesSurvive -GameDir $root -Paths $paths -Recopy $retry)) {
                throw 'Required VR files did not survive verification. No Hub success was recorded.'
            }
            Confirm-Mafia2PublisherSetup $pc $version $before 'after observation'
            [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $version -Route Current -InstalledPathReceiptPaths @((Join-Path $InstallerFolder '.installed_path')) -InstalledVersionReceiptPaths @((Join-Path $InstallerFolder '.installed_version')))
            $snapshot = $null
            Write-Host "  [OK] Mafia II Classic VR $version is installed. Start in VR opens M2VR Launcher." -ForegroundColor Green
            Write-Host ''
            Write-Host '  The view from the wheel in Empire Bay is something else.' -ForegroundColor Magenta
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
            return
        } catch {
            $failure = $_
            if ($snapshot) {
                try {
                    Write-Verbose "Mafia II: restoring files in $root after setup failed." -Verbose
                    Restore-PCVRPublisherZipSnapshot -GameRoot $root -Snapshot $snapshot
                    Write-Verbose 'Mafia II: game-folder rollback completed.' -Verbose
                } catch {
                    $keepWork = $true
                    Write-Host "  The game-folder recovery copy was retained at $($snapshot.Root)." -ForegroundColor Yellow
                }
            }
            $recovery = Invoke-PCVRUniversalRecovery -FailureMessage $failure.Exception.Message -InstallerFolder $InstallerFolder -RecoveryPageUrl $page -GameId 'mafia-ii-classic-vr'
            if ($recovery.Action -ne 'retry') { throw }
        } finally {
            if (-not $keepWork -and $work -and [IO.Directory]::Exists($work)) {
                $prefix = Join-Path ([IO.Path]::GetTempPath()) 'pcvr-mafia2-'
                if ([IO.Path]::GetFullPath($work).StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
                    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
