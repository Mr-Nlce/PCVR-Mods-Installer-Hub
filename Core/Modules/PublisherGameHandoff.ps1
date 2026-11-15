# Shared handoff for the Trilex and Gothic 3 VR publisher installers.
. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherVrState.ps1')
. (Join-Path $PSScriptRoot 'Gothic3GameCopy.ps1')

function Get-PublisherVrTarget {
    param($Game,[switch]$RequireCopy)
    if ($Game.Publisher -eq 'gothic') { return Select-Gothic3PublisherFolder $Game }
    $remembered = if ($Game.Publisher -eq 'singularity') { 'mod_b_path' } else { 'installed_path' }
    $saved = Get-PCVRRememberedGameFolder -GameId $Game.Id -StateNames @($remembered,'user_located') -ProbeFiles $Game.Base
    $store = Find-SteamGameFolder -AppId $Game.App -SteamFolderNames @($Game.SteamFolder) -ProbeExe $Game.Base[0] -HubGameId $Game.Id
    $handover = Get-PCVRRecoveryInput
    if ($handover -and [IO.Directory]::Exists($handover)) { $saved = $handover }
    $candidate = $saved
    if (-not $candidate -and -not $RequireCopy) { $candidate = $store }
    if ($Game.Publisher -eq 'wonderlands') {
        $library = if ($store) { Split-Path -Parent (Split-Path -Parent $store) }
        if (-not $library -or -not [IO.File]::Exists((Join-Path $library 'appmanifest_1286680.acf'))) {
            throw 'Install the Steam edition of Tiny Tina''s Wonderlands before running setup.'
        }
        $candidate = $store
    }
    while ($true) {
        if ($candidate -and [IO.File]::Exists($candidate)) {
            $candidate = Split-Path -Parent $candidate
            if ($Game.Publisher -eq 'singularity' -and (Split-Path -Leaf $candidate) -ieq 'Binaries') { $candidate = Split-Path -Parent $candidate }
        }
        if ($candidate -and [IO.Directory]::Exists($candidate)) {
            $candidate = (Get-Item -LiteralPath $candidate).FullName
            $missing = @($Game.Base | Where-Object { -not [IO.File]::Exists((Join-Path $candidate $_)) })
            $valid = -not $missing.Count
            # Find-SteamGameFolder can return a remembered copy first. Only
            # reject the actual Steam-library root, never the saved VR copy.
            $steamRoot = $candidate -match '(?i)[\\/]steamapps[\\/]common[\\/][^\\/]+[\\/]?$'
            if ($valid -and $RequireCopy -and $steamRoot) {
                Write-Host '  Choose a separate game copy outside the original Steam folder.' -ForegroundColor Yellow
                $valid = $false
            }
            if ($valid -and $Game.Publisher -eq 'singularity') {
                $conflicts = @('Binaries\d3d9.dll','Binaries\d3d9.dll.off','Binaries\dinput8.dll')
                $hasProxy = @($conflicts | Where-Object { [IO.File]::Exists((Join-Path $candidate $_)) }).Count
                if ($hasProxy -and -not (Get-PCVRTrilexReceipt $candidate 'singularity' $Game.HashProof)) {
                    Write-Host '  This folder already contains a graphics or input proxy. Choose a clean copy for Trilex.' -ForegroundColor Yellow
                    $valid = $false
                }
            }
            if ($valid) { return $candidate }
        }
        if ($Game.Publisher -eq 'wonderlands') { throw 'The Steam folder is incomplete. Verify the game in Steam and try again.' }
        $candidate = ('' + (Read-Host "  Paste the $($Game.Title) folder, or Q to cancel")).Trim().Trim('"').Trim("'")
        if (-not $candidate -or $candidate -ieq 'Q') { return }
    }
}

function Test-PublisherVrPe([string]$Path) {
    try {
        $stream = [IO.File]::OpenRead($Path)
        try {
            $reader = [IO.BinaryReader]::new($stream)
            if ($stream.Length -lt 128 -or $reader.ReadUInt16() -ne 0x5A4D) { return $false }
            $stream.Position = 60
            $stream.Position = $reader.ReadUInt32()
            return ($reader.ReadUInt32() -eq 0x4550)
        } finally { $stream.Dispose() }
    } catch { return $false }
}

function Get-PublisherVrApp {
    param([string]$Work,[string]$Repo,[string]$Pattern,[switch]$Trilex)
    $page = "https://github.com/$Repo/releases"
    $manual = Get-PCVRRecoveryInput
    $ext = if ($Trilex) { '.zip' } else { '.exe' }
    if ($manual -and [IO.File]::Exists($manual) -and [IO.Path]::GetExtension($manual) -ieq $ext) {
        $asset = $manual
    } else {
        Write-Host '  Checking GitHub for the current Windows setup. Downloading may take a few minutes.'
        $release = Resolve-GitHubReleaseAsset -Repo $Repo -AssetPatterns @($Pattern) -SkipReleasesWithoutMatchingAsset
        if (-not $release.Url) { throw "The current publisher setup could not be resolved. $page" }
        $asset = Join-Path $Work ("publisher" + $ext)
        $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $asset -Label 'Publisher setup' -ManualUrl $page -AllowSkip:$false -PlainProgress -FunctionalPayloadOnly -DisableGitHubAssetReresolution
        if (-not $ok) { throw 'Publisher setup download did not complete.' }
    }
    if ($Trilex) {
        $layout = Get-ArchiveTopLevel -ArchivePath $asset
        if (-not $layout.Ok) { throw 'Choose a readable Trilex ZIP.' }
        foreach ($entry in $layout.Entries) {
            [void](Assert-PCVROwnedRelativePath -Relative ([string]$entry).TrimEnd('\','/'))
        }
        $expanded = Join-Path $Work 'Trilex'
        $unpacked = Expand-ArchiveOrFallback -ArchivePath $asset -DestinationFolder $expanded -Label 'Trilex Mod Installer' -AllowSkip $false -QuietProgress
        if ($unpacked -notin @('ok','manual','retry')) { throw 'Could not extract the Trilex ZIP.' }
        $apps = @(Get-ChildItem -LiteralPath $expanded -Filter 'TrilexModInstaller.exe' -File -Recurse)
        if ($apps.Count -ne 1 -or -not [IO.File]::Exists((Join-Path $apps[0].DirectoryName 'catalog.signed.json'))) {
            throw 'The ZIP needs the publisher app and its accompanying catalog.'
        }
        $asset = $apps[0].FullName
    }
    if (-not (Test-PublisherVrPe $asset)) { throw 'The downloaded setup is not a usable Windows executable.' }
    return $asset
}

function Invoke-PublisherVrApp {
    param([string]$App,[string]$Root,[switch]$Trilex)
    $options = @{FilePath=$App;WorkingDirectory=(Split-Path -Parent $App);Wait=$true;PassThru=$true;ErrorAction='Stop'}
    if (-not $Trilex) { $options.ArgumentList = @('/DIR="' + $Root.TrimEnd('\','/') + '"','/NORESTART') }
    $process = Start-Process @options
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher setup exited with code $($process.ExitCode). No Hub success was recorded." }
}

function Invoke-PublisherGameHandoff {
    param($Game,[string]$InstallerFolder)
    $trilex = $Game.Publisher -ne 'gothic'
    $repo = if ($trilex) { 'trilex07/TrilexModInstaller' } else { 'PeCOS2k5/Gothic3VR-Releases' }
    $pattern = if ($trilex) { '(?i)^Trilex-Mod-Installer-[\w.-]+-win-x64\.zip$' } else { '(?i)^Gothic3VR-[\w.-]+-Setup\.exe$' }
    $page = "https://github.com/$repo/releases"
    $route = if ($Game.Publisher -eq 'singularity') { 'ModB' } else { 'Current' }
    $slot = if ($route -eq 'ModB') { 'Secondary' } else { 'Primary' }
    $marker = if ($slot -eq 'Secondary') { '.installed_path_trilex' } else { '.installed_path' }
    $versionMarker = if ($slot -eq 'Secondary') { '.installed_version_b' } else { '.installed_version' }
    $required = @($Game.Base) + @($Game.Proof)
    $contract = New-PCVRInstallerContract -Id $Game.Id -GameName $Game.Title -Acquisition GitHub -RequiredInstalledFileGroups $required -Routes @($route) -ReleasePageUrl $page -AntivirusNotice

    while ($true) {
        $work = $null
        try {
            Write-Host ""; Write-Host "  $($Game.Title) - VR setup" -ForegroundColor Cyan
            Write-Host "  $($Game.Notes)"
            if ($trilex) {
                Write-Host '  Trilex manages its own backups, repair and uninstall. It can also update other games you select.'
                Write-Host '  [1] Only this game    [2] All compatible games you select in Trilex    [Q] Cancel'
            }
            Show-AntivirusNotice -Compact
            if ($trilex) {
                do {
                    $scope = Read-Host '  Scope [1]'
                    if ($null -eq $scope) { return }
                    $choice = $scope.Trim()
                } until ($choice -in @('','1','2','Q'))
                if ($choice -eq 'Q') { return }
            } else {
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to select the game folder...')
            }
            Write-Host '--- [1/4] Finding the base game ---' -ForegroundColor Cyan
            $root = Get-PublisherVrTarget -Game $Game -RequireCopy:($Game.Publisher -in @('gothic','singularity'))
            if (-not $root) { return }
            if (Get-Process -Name $Game.Processes -ErrorAction SilentlyContinue) { throw 'Close the game, its VR launcher and its publisher setup before continuing.' }
            Write-Host "  [OK] $root" -ForegroundColor Green
            $before = if ($trilex) { Get-PCVRTrilexReceipt $root $Game.Publisher $Game.HashProof }
            Write-Host '--- [2/4] Getting the publisher installer ---' -ForegroundColor Cyan
            Write-Host "  Source: $page"
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download or use the selected setup file...')
            $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr-publisher-vr-' + [guid]::NewGuid().ToString('N'))
            [void][IO.Directory]::CreateDirectory($work)
            $app = Get-PublisherVrApp -Work $work -Repo $repo -Pattern $pattern -Trilex:$trilex

            Write-Host '--- [3/4] Installing with the publisher setup ---' -ForegroundColor Cyan
            if ($trilex) {
                if ($choice -eq '2') {
                    Write-Host '  In Trilex, select the compatible games you want to install or update.'
                    Write-Host '  Only the originating game is confirmed by this Hub setup. Scan to discover the other games afterward.'
                } else {
                    Write-Host "  In Trilex, select only $($Game.Title). Leave the other games unchecked."
                }
                Write-Host "  Select this exact folder for $($Game.Title), click Install selected and close Trilex when it finishes."
                Write-Host "  $root"
            } else {
                Write-Host "  Confirm this separate Gothic 3 folder in Setup: $root"
                Write-Host '  Accept the required patches if prompted.'
                Write-Host '  The Community Patch alone is about 1.6 GB. Setup shows progress while the patches are applied.'
            }
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher setup...')
            Invoke-PublisherVrApp -App $app -Root $root -Trilex:$trilex

            Write-Host '--- [4/4] Verifying the installed VR files ---' -ForegroundColor Cyan
            if ($trilex) {
                $installed = Get-PCVRTrilexReceipt $root $Game.Publisher $Game.HashProof
                if (-not $installed) { throw 'No complete Trilex installation was found in the selected game folder.' }
                if ($before -and $installed.transactionId -eq $before.transactionId) {
                    throw 'Trilex closed without completing a new install or repair for this game.'
                }
                $version = $installed.version
            } else {
                $version = Get-PCVRGothic3Version $root
                if (-not $version) { throw 'Gothic 3 VR Setup did not report an installed version for the selected folder.' }
            }
            $missing = @($required | Where-Object { -not [IO.File]::Exists((Join-Path $root $_)) })
            if ($missing.Count) {
                throw ('Required files are missing in the chosen folder: ' + ($missing -join ', ') + '. Check the folder, write permissions and publisher log.')
            }
            $paths = @($required | ForEach-Object { Join-Path $root $_ })
            foreach ($file in $paths) { Write-Verbose "After publisher setup: $file exists" -Verbose }
            $runPublisher = ${function:Invoke-PublisherVrApp}
            $recopy = { & $runPublisher -App $app -Root $root -Trilex:$trilex }.GetNewClosure()
            $survived = Confirm-PlacedFilesSurvive -GameDir $root -Paths $paths -Recopy $recopy
            if (-not $survived) { throw 'Required files could not be verified after setup. Review recovery options and run the publisher installer again.' }
            if ($trilex) {
                $installed = Get-PCVRTrilexReceipt $root $Game.Publisher $Game.HashProof
                if (-not $installed) { throw 'The installed Trilex runtime no longer matches its publisher receipt.' }
                $version = $installed.version
            } else { $version = Get-PCVRGothic3Version $root }
            [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $version -Route $route -VersionSlot $slot -InstalledPathReceiptPaths @((Join-Path $InstallerFolder $marker)) -InstalledVersionReceiptPaths @((Join-Path $InstallerFolder $versionMarker)))
            if ($slot -eq 'Secondary') {
                [void](Save-HubRememberedGameFolder -GameId $Game.Id -Title $Game.Title -GameDir $root -StateName 'mod_b_path' -ProbeFiles $Game.Base)
            }
            Write-Host '  1. Use Start in VR in the Hub.'
            Write-Host "  $($Game.Done)"
            Write-Host ''; Write-Host "  $($Game.Quip)" -ForegroundColor Magenta
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
            return
        } catch {
            $recovery = Invoke-PCVRUniversalRecovery -FailureMessage $_.Exception.Message -InstallerFolder $InstallerFolder -RecoveryPageUrl $page -GameId $Game.Id
            if ($recovery.Action -ne 'retry') { throw }
        } finally {
            if ($work -and [IO.Directory]::Exists($work)) {
                # The unique temp tree belongs only to this completed run.
                $safe = [IO.Path]::GetFullPath($work)
                $prefix = Join-Path ([IO.Path]::GetTempPath()) 'pcvr-publisher-vr-'
                if ($safe.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
                    Remove-Item -LiteralPath $safe -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
