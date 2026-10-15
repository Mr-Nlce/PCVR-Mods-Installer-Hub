$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$REPO='kwstasg/Unreal-Revived'
$RELEASES="https://github.com/$REPO/releases"
$DEFAULT_TARGET='C:\Games\Unreal Revived'
$REQUIRED=@('System64\UnrealRevivedVR.exe','System64\openxr_loader.dll',
    'System64\D3D12Drv.dll','System64\ModernMenu.u','MAPS\Vortex2.unr','.unreal-revived.json')
$CONTRACT=New-PCVRInstallerContract -Id 'unreal-revived-vr' -GameName 'Unreal Revived VR' `
    -Acquisition GitHub -ReleasePageUrl $RELEASES -AntivirusNotice -Routes @('Standalone') `
    -RequiredInstalledFileGroups $REQUIRED

function Get-UnrealInstalledVersion([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    foreach ($relative in $REQUIRED) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $null }
    }
    try {
        $version=([string](Get-Item -LiteralPath (Join-Path $Root 'System64\UnrealRevivedVR.exe') -ErrorAction Stop).VersionInfo.ProductVersion).Trim()
        if ($version -match '^\d+(?:\.\d+){1,3}$') { return $version }
    } catch {}
    return $null
}

function Get-UnrealSetupVersion([string]$Path) {
    if (-not (Test-DownloadedPayload -Path $Path -IntendedPath 'UnrealRevived-Setup.exe')) { return $null }
    try {
        $version=([string](Get-Item -LiteralPath $Path -ErrorAction Stop).VersionInfo.ProductVersion).Trim()
        if ($version -match '^\d+(?:\.\d+){1,3}$') { return $version }
    } catch {}
    return $null
}

function Get-UnrealTarget([scriptblock]$ReadInput=$null) {
    $paths=New-Object 'System.Collections.Generic.List[string]'
    try {
        $saved=Get-PCVRRememberedGameFolder -GameId 'unreal-revived-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('System64\UnrealRevivedVR.exe')
        if ($saved) { $paths.Add($saved) }
    } catch {}
    try {
        $legacy=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if ($legacy) { $paths.Add($legacy) }
    } catch {}
    foreach ($path in @($DEFAULT_TARGET,'D:\Games\Unreal Revived','E:\Games\Unreal Revived')) { $paths.Add($path) }
    foreach ($path in @($paths | Select-Object -Unique)) {
        if (Get-UnrealInstalledVersion $path) { return (Get-Item -LiteralPath $path).FullName }
    }
    return $null
}

function Read-UnrealTarget([string]$ExpectedVersion,[scriptblock]$ReadInput=$null) {
    while ($true) {
        Write-Host "  Default destination: $DEFAULT_TARGET" -ForegroundColor Cyan
        $raw=if($ReadInput){& $ReadInput 'Destination'}else{Read-Host '  Enter = default; drag/paste another Unreal Revived folder; Q = cancel'}
        if($null -eq $raw){return $null}
        $value=(''+$raw).Trim().Trim('"').Trim("'")
        if ($value -ieq 'Q') { return $null }
        $path=if($value){$value}else{$DEFAULT_TARGET}
        $foundVersion=Get-UnrealInstalledVersion $path
        if ($foundVersion -and (-not $ExpectedVersion -or $foundVersion -eq $ExpectedVersion)) { return (Get-Item -LiteralPath $path).FullName }
        Write-Host "  Unreal Revived VR $ExpectedVersion was not found there." -ForegroundColor Yellow
        Write-Host '  Check the destination chosen in publisher Setup; do not select C:\Unreal.' -ForegroundColor Gray
    }
}

function Get-UnrealRelease([object]$ReleaseData=$null) {
    $args=@{ Repo=$REPO; AssetPatterns=@('(?i)^UnrealRevived-Setup-\d+(?:\.\d+){1,3}\.exe$'); SkipReleasesWithoutMatchingAsset=$true }
    if ($null -ne $ReleaseData) { $args.ReleaseData=$ReleaseData }
    $release=Resolve-GitHubReleaseAsset @args
    if (-not $release.Resolved) { return $null }
    $version=[regex]::Match([string]$release.AssetName,'(?i)^UnrealRevived-Setup-(\d+(?:\.\d+){1,3})\.exe$')
    if (-not $version.Success) { return $null }
    return [pscustomobject]@{ Url=$release.Url; Tag=$release.Tag; Version=$version.Groups[1].Value; Name=$release.AssetName }
}

if ($env:PCVR_UNREAL_REVIVED_LIBRARY_ONLY -eq '1') { return }

while ($true) {
try {
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Unreal Revived VR Installer' -ForegroundColor Cyan
    Write-Host '  Native OpenXR conversion by Kwstasg' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  Setup copies original Unreal Gold data into a separate folder.' -ForegroundColor White
    Write-Host '  If you need the source game, publisher Setup links to the' -ForegroundColor White
    Write-Host '  official free OldUnreal full-game installer (usually C:\Unreal).' -ForegroundColor White
    Write-Host '  Unreal Revived normally installs to C:\Games\Unreal Revived.' -ForegroundColor White
    Write-Host '  Windows may ask for administrator approval when Setup runs.' -ForegroundColor Gray
    Write-Host '  If a required file disappears, check the installer log and path.' -ForegroundColor Gray
    Write-Host '  If antivirus reported a matching detection, review its history' -ForegroundColor Gray
    Write-Host '  and use its allow/exclusion guidance before retrying.' -ForegroundColor Gray
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to choose the Setup source.')

    Write-Host '  [1/4] Check the existing VR installation' -ForegroundColor Cyan
    Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
    $beforeRoot=Get-UnrealTarget
    $beforeVersion=if($beforeRoot){Get-UnrealInstalledVersion $beforeRoot}else{$null}
    if ($beforeVersion) { Write-Host "  Installed: $beforeVersion at $beforeRoot" -ForegroundColor Green }
    Write-Host '  [1] Download the latest public GitHub Setup' -ForegroundColor White
    Write-Host '  [2] Select a Setup EXE yourself (including a newer local build)' -ForegroundColor White
    Write-Host '  [Q] Cancel' -ForegroundColor Gray
    $recoverySetup=Get-PCVRRecoveryInput -PathType Leaf
    if ($recoverySetup -and (Get-UnrealSetupVersion $recoverySetup)) {
        Write-Host "  Recovery Setup selected: $recoverySetup" -ForegroundColor Cyan
        $choice='2'
    } else {
        $choice=(Read-Host '  Choice').Trim().ToUpperInvariant()
    }
    if ($choice -eq 'Q') { exit 0 }
    if ($choice -notin @('1','2')) { throw 'Choose 1, 2 or Q.' }

    $setupPath=$null
    $selectedVersion=$null
    if ($choice -eq '1') {
        Write-Host '  [2/4] Resolve the stable publisher Setup' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $release=Get-UnrealRelease
        if (-not $release) {
            Write-Host '  GitHub could not resolve an installable release right now.' -ForegroundColor Yellow
            Write-Host '  You can open the releases page and select a downloaded EXE.' -ForegroundColor White
            Open-PCVRPageAfterEnter -Message 'Press Enter to open the GitHub releases page.' -Url $RELEASES
            $choice='2'
        } else {
            $selectedVersion=$release.Version
            Write-Host "  Public release: $selectedVersion ($($release.Name))" -ForegroundColor Cyan
            if ($beforeVersion -and ([version]$selectedVersion -lt [version]$beforeVersion)) {
                Write-Host "  Your installed $beforeVersion is newer. GitHub $selectedVersion will not replace it." -ForegroundColor Yellow
                Write-Host '  Choose the newer local Setup EXE if you want to reinstall that build.' -ForegroundColor White
                $choice='2'
            } elseif ($beforeVersion -eq $selectedVersion) {
                Write-Host '  This version is already installed. No reinstall is needed.' -ForegroundColor Green
                exit 0
            } else {
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the selected GitHub Setup.')
                $setupPath=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-unreal-' + [Guid]::NewGuid().ToString('N') + '.exe')
                $ok=Invoke-SafeDownload -Urls @($release.Url) -Destination $setupPath -Label "Unreal Revived $selectedVersion Setup" -ManualUrl $RELEASES -AllowSkip:$false
                if (-not $ok -or (Get-UnrealSetupVersion $setupPath) -ne $selectedVersion) {
                    throw 'No usable publisher Setup was downloaded. Select a local EXE and retry.'
                }
            }
        }
    }
    if ($choice -eq '2') {
        Write-Host '  [2/4] Select the publisher Setup EXE' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        while ($true) {
            $raw=if ($recoverySetup) { $selected=$recoverySetup; $recoverySetup=$null; $selected }
                 else { (Read-Host '  Drag/paste the Setup EXE path; Q = cancel').Trim().Trim('"').Trim("'") }
            if ($raw -ieq 'Q') { exit 0 }
            $selectedVersion=Get-UnrealSetupVersion $raw
            if ($selectedVersion) { $setupPath=(Get-Item -LiteralPath $raw).FullName; break }
            Write-Host '  The selected path is not a readable, versioned Setup EXE.' -ForegroundColor Yellow
        }
    }
    if ($beforeVersion -and ([version]$selectedVersion -lt [version]$beforeVersion)) {
        throw "Setup $selectedVersion is older than installed $beforeVersion. Downgrade was stopped."
    }

    Write-Host ''
    Write-Host '  [3/4] Run publisher Setup' -ForegroundColor Cyan
    Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
    Write-Host "  Selected Setup version: $selectedVersion" -ForegroundColor Cyan
    Write-Host '  Publisher Setup handles installation and any existing copy itself.' -ForegroundColor White
    Write-Host '  It may offer uninstall/reinstall. Keep saves and back up settings' -ForegroundColor White
    Write-Host '  when prompted; settings are not restored automatically.' -ForegroundColor White
    Write-Host '  Select the original Unreal Gold source or Install via OldUnreal.' -ForegroundColor White
    Write-Host '  Choose a separate Unreal Revived destination, then finish Setup.' -ForegroundColor White
    Write-Host '  The Hub checks the actual VR executable, OpenXR loader, renderer,' -ForegroundColor White
    Write-Host '  menus, map and publisher metadata after Setup closes.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to launch publisher Setup.')
    $beforeMetadataTime=$null
    if ($beforeRoot) {
        try { $beforeMetadataTime=(Get-Item -LiteralPath (Join-Path $beforeRoot '.unreal-revived.json')).LastWriteTimeUtc.Ticks } catch {}
    }
    $process=Start-Process -FilePath $setupPath -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher Setup ended with exit code $($process.ExitCode)." }
    $target=Get-UnrealTarget
    if ($target -and (Get-UnrealInstalledVersion $target) -ne $selectedVersion) { $target=$null }
    if (-not $target) { $target=Read-UnrealTarget -ExpectedVersion $selectedVersion }
    if (-not $target) { throw 'No verified Unreal Revived installation was selected.' }
    $actualVersion=Get-UnrealInstalledVersion $target
    if (-not $actualVersion) { throw 'Publisher Setup closed without the required VR files.' }
    if ($actualVersion -ne $selectedVersion) { throw "Installed build $actualVersion does not match selected Setup $selectedVersion." }
    if ($beforeRoot -and $target -ieq $beforeRoot -and $beforeVersion -eq $actualVersion -and $beforeMetadataTime) {
        $afterMetadataTime=(Get-Item -LiteralPath (Join-Path $target '.unreal-revived.json')).LastWriteTimeUtc.Ticks
        if ($afterMetadataTime -eq $beforeMetadataTime) { throw 'Setup left the previous installation unchanged; no new success receipt was written.' }
    }
    [void](Complete-PCVRInstallTransaction -Contract $CONTRACT -GameDir $target -Version $actualVersion `
        -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Standalone)
    Write-Host '  [4/4] Finish and start in VR' -ForegroundColor Cyan
    Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
    Write-Host '  Start in VR in the Hub opens System64\UnrealRevivedVR.exe.' -ForegroundColor Green
    Write-Host '  Press [Esc] -> Options -> Preferences -> VR to set player height' -ForegroundColor Cyan
    Write-Host '  and choose motion-controller aiming.' -ForegroundColor Cyan
    Write-Host '  OpenXR runtime and headset behaviour still depend on your PC.' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Welcome to Na Pali. The Skaarj look bigger from here.' -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    exit 0
} catch {
    $message="Unreal Revived setup did not complete: $($_.Exception.Message)"
    Write-Host "  $message" -ForegroundColor Red
    [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
}
}
