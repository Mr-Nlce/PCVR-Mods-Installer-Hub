param(
    [ValidateSet('Overture','BlackPlague','Requiem')][string]$Game = 'BlackPlague',
    [ValidateSet('Install','Manage')][string]$Mode = 'Install'
)
$ErrorActionPreference = 'Stop'
if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT) {
    $global:HubPortableStateRootOverride=$env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT
    $global:HubLegacyPortableStateRootOverride=Join-Path $env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT 'legacy'
    $global:HubRuntimeRootOverride=Join-Path $env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT 'runtime'
}
# Overture can call this script in its existing PowerShell process. Load the
# safety module here as well so its script-scoped state root is initialized.
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$script:PenumbraRepo = 'rubocopter/penumbra_vr_framework'
$script:PenumbraPage = 'https://github.com/rubocopter/penumbra_vr_framework/releases'
$script:PenumbraExe = if ($Game -eq 'Requiem') { 'Requiem.exe' } else { 'Penumbra.exe' }
$script:PenumbraName = 'Penumbra: '+$(if ($Game -eq 'Overture') { 'Overture' } elseif ($Game -eq 'Requiem') { 'Requiem' } else { 'Black Plague' })+' VR'
$script:PenumbraId = 'penumbra-'+$(if ($Game -eq 'Overture') { 'overture' } elseif ($Game -eq 'Requiem') { 'requiem' } else { 'black-plague' })+'-vr'
$script:PenumbraProbe = if ($Game -eq 'Requiem') { 'PenumbraVR.Requiem.Probe.dll' } else { 'PenumbraVR.BlackPlague.Probe.dll' }
$script:PenumbraFolder = Join-Path (Split-Path -Parent $PSScriptRoot) $(if ($Game -eq 'Overture') { 'PenumbraVR' } elseif ($Game -eq 'Requiem') { 'PenumbraRequiemVR' } else { 'PenumbraBlackPlagueVR' })
$script:PenumbraRequired = @('redist\Penumbra.exe','redist\alut.dll','redist\OpenAL32.dll','redist\PenumbraVR_OpenALSoft.dll',
    'redist\PenumbraVR.BlackPlague.Probe.dll','redist\openvr_api.dll','redist\vr\actions.json',
    'redist\PenumbraVR.BlackPlague.install.json')
if ($Game -eq 'Requiem') { $script:PenumbraRequired += @('redist\Requiem.exe','redist\PenumbraVR.Requiem.Probe.dll') }
if ($Game -eq 'Overture') { $script:PenumbraRequired = @('redist\Penumbra.exe','redist\Penumbra_vr.exe','redist\openvr_api.dll','redist\vr\actions.json','.penumbravr\deploy-state.json') }
$script:PenumbraContract = New-PCVRInstallerContract -Id $script:PenumbraId -GameName $script:PenumbraName `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:PenumbraPage -Routes @('Current') `
    -RequiredInstalledFileGroups $script:PenumbraRequired

function Test-PenumbraBase([string]$Root) {
    if (-not $Root) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Root 'redist\Penumbra.exe') -PathType Leaf)) { return $false }
    if ($script:PenumbraExe -eq 'Requiem.exe' -and -not (Test-Path -LiteralPath (Join-Path $Root 'redist\Requiem.exe') -PathType Leaf)) { return $false }
    return $true
}
function Get-PenumbraGameFolder {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_GAME) {
        if (-not (Test-PenumbraBase $env:PCVR_PENUMBRA_TEST_GAME)) { throw 'The isolated Penumbra game fixture is incomplete.' }
        return [IO.Path]::GetFullPath($env:PCVR_PENUMBRA_TEST_GAME)
    }
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($id in @($script:PenumbraId,'penumbra-black-plague-vr')) {
        if ($Game -eq 'Overture' -and $id -ne $script:PenumbraId) { continue }
        try { $saved=Get-PCVRRememberedGameFolder -GameId $id -StateNames @('installed_path','user_located') -ProbeFiles @('redist\Penumbra.exe'); if ($saved) { $paths.Add($saved) } } catch {}
    }
    try { $steam=Find-SteamGameFolder -AppId $(if ($Game -eq 'Overture') { '22180' } else { '22120' }) -SteamFolderNames @($(if ($Game -eq 'Overture') { 'Penumbra Overture' } else { 'Penumbra Black Plague' })) -ProbeExe 'redist\Penumbra.exe' -HubGameId $script:PenumbraId; if ($steam) { $paths.Add($steam) } } catch {}
    if ($Game -eq 'Overture') {
        foreach ($p in @('C:\Program Files (x86)\Steam\steamapps\common\Penumbra Overture','C:\Program Files (x86)\GOG Galaxy\Games\Penumbra Overture','C:\GOG Games\Penumbra Overture')) { $paths.Add($p) }
    } else {
    foreach ($p in @(
        'C:\Program Files (x86)\Steam\steamapps\common\Penumbra Black Plague',
        'C:\Program Files (x86)\GOG Galaxy\Games\Penumbra - Black Plague',
        'C:\GOG Games\Penumbra - Black Plague',
        'C:\Program Files (x86)\Paradox Interactive\Penumbra Black Plague',
        'C:\Program Files (x86)\Paradox Interactive\Penumbra Collection\Black Plague')) { $paths.Add($p) }
    }
    foreach ($p in @($paths | Where-Object { $_ } | Select-Object -Unique)) { if (Test-PenumbraBase $p) { return [IO.Path]::GetFullPath($p) } }
    $picked=Get-GameFolderInteractive -GameName $script:PenumbraName -ProbeFile ('redist\'+$script:PenumbraExe) -ManualUrl $script:PenumbraPage
    if (Test-PenumbraBase $picked) { return [IO.Path]::GetFullPath($picked) }
    throw ('Choose the '+$(if ($Game -eq 'Overture') { 'Overture' } else { 'Black Plague' })+' folder containing redist\Penumbra.exe'+$(if ($Game -eq 'Requiem') { ' and redist\Requiem.exe' } else { '' })+'.')
}
function Get-PenumbraRelease {
    $pattern='(?i)^PenumbraVR-Setup-(\d+(?:\.\d+){2})\.exe$'
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_SETUP) {
        $name=[IO.Path]::GetFileName($env:PCVR_PENUMBRA_TEST_SETUP)
        if ($name -notmatch $pattern) { throw 'The publisher Setup filename is not a Penumbra VR release.' }
        return [pscustomobject]@{ Version=$Matches[1]; Tag=('v'+$Matches[1]); Name=$name; Url=$env:PCVR_PENUMBRA_TEST_SETUP; Local=$true }
    }
    $r=Resolve-GitHubReleaseAsset -Repo $script:PenumbraRepo -IncludePrerelease $true -AssetPatterns @($pattern) -SkipReleasesWithoutMatchingAsset
    if (-not $r.Resolved -or [string]$r.AssetName -notmatch $pattern) { throw 'No current Penumbra VR publisher Setup was found.' }
    $assetVersion=$Matches[1]
    if (([string]$r.Tag -replace '^v','') -ne $assetVersion) { throw 'Publisher Setup asset version does not match the release tag.' }
    return [pscustomobject]@{ Version=$assetVersion; Tag=[string]$r.Tag; Name=[string]$r.AssetName; Url=[string]$r.Url; Local=$false }
}
function Test-PenumbraInstalled([string]$Root) {
    if (-not (Test-PenumbraBase $Root)) { return $false }
    foreach ($name in $script:PenumbraRequired) { if (-not (Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)) { return $false } }
    try {
        $state=Get-Content -LiteralPath (Join-Path $Root $(if ($Game -eq 'Overture') { '.penumbravr\deploy-state.json' } else { 'redist\PenumbraVR.BlackPlague.install.json' })) -Raw | ConvertFrom-Json
        if ($Game -eq 'Overture') { return [bool]($state.FrameworkVersion -and @($state.Components) -contains 'overture') }
        if (-not $state.frameworkVersion -or @($state.components) -notcontains 'black_plague') { return $false }
        if ($script:PenumbraExe -eq 'Requiem.exe' -and @($state.components) -notcontains 'requiem') { return $false }
        return $true
    } catch { return $false }
}
function Get-PenumbraLegacyOvertureState([string]$Root) {
    $statePath=Join-Path $Root '.penumbravr\deploy-state.json'
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) { return $null }
    $state=Get-Content -LiteralPath $statePath -Raw -ErrorAction Stop | ConvertFrom-Json
    # The old publisher deployment has Version=1 and a file/backup manifest;
    # it does not contain FrameworkVersion. That is the exact failing case.
    if ($state.FrameworkVersion) { return $null }
    if ([int]$state.Version -ne 1 -or @($state.Files).Count -eq 0) {
        throw 'The existing Overture deployment state is unfamiliar. Keep its files and use publisher support before updating.'
    }
    $redist=[IO.Path]::GetFullPath((Join-Path $Root 'redist')).TrimEnd('\')
    if (-not [string]::Equals(([IO.Path]::GetFullPath([string]$state.RedistRoot)).TrimEnd('\'),$redist,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'The old Overture deployment state belongs to another game folder.'
    }
    return $state
}
function Restore-PenumbraLegacyOverture([string]$Root,$State) {
    $redist=[IO.Path]::GetFullPath((Join-Path $Root 'redist')).TrimEnd('\')
    $backupRoot=Join-Path $Root '.penumbravr\backup'
    $restoreScript=Join-Path $redist 'Install-PenumbraVR.ps1'
    $scriptEntry=$null
    foreach ($entry in @($State.Files)) {
        $relative=([string]$entry.Path).Replace('/','\')
        if (-not $relative -or [IO.Path]::IsPathRooted($relative)) { throw 'Old Overture state contains an unsafe file path.' }
        $target=[IO.Path]::GetFullPath((Join-Path $redist $relative))
        if (-not $target.StartsWith(($redist+'\'),[StringComparison]::OrdinalIgnoreCase)) { throw 'Old Overture state contains a path outside redist.' }
        if ($relative -ieq 'Install-PenumbraVR.ps1') { $scriptEntry=$entry }
        $currentHash=if (Test-Path -LiteralPath $target -PathType Leaf) { (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() } else { '' }
        $deployed=([string]$entry.DeployedHash).ToLowerInvariant()
        $original=([string]$entry.OriginalHash).ToLowerInvariant()
        if ($currentHash -and $currentHash -ne $deployed -and $currentHash -ne $original) {
            throw "Old Overture file was changed outside the installer: $relative. No files were removed."
        }
        if ([bool]$entry.HadOriginal) {
            $backup=[IO.Path]::GetFullPath((Join-Path $backupRoot $relative))
            $backupBase=[IO.Path]::GetFullPath($backupRoot).TrimEnd('\')+'\'
            if (-not $backup.StartsWith($backupBase,[StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath $backup -PathType Leaf) -or
                (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $original) {
                throw "Original backup is missing or changed: $relative. No files were removed."
            }
        }
    }
    if (-not $scriptEntry -or -not (Test-Path -LiteralPath $restoreScript -PathType Leaf) -or
        (Get-FileHash -LiteralPath $restoreScript -Algorithm SHA256).Hash.ToLowerInvariant() -ne ([string]$scriptEntry.DeployedHash).ToLowerInvariant()) {
        throw 'The original Overture restore script is missing or changed. No files were removed.'
    }
    $recoveryBase=if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HUB_TEST_LOCALAPPDATA) { $env:PCVR_HUB_TEST_LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
    $recovery=Join-Path $recoveryBase ('PCVR Mods Installer Hub\Backups\PenumbraOverture-'+[Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($recovery)
    Copy-Item -LiteralPath (Join-Path $Root '.penumbravr') -Destination (Join-Path $recovery '.penumbravr') -Recurse -Force -ErrorAction Stop
    Write-Host "  [OK] Original Overture restore data saved: $recovery" -ForegroundColor Green
    Write-Host '  Restoring the original game files; this may take several seconds.' -ForegroundColor Yellow
    & $restoreScript -InstallRoot $Root -Restore
    if (Test-Path -LiteralPath (Join-Path $Root '.penumbravr\deploy-state.json') -PathType Leaf) {
        throw 'The old Overture restore did not finish. The recovery copy remains available.'
    }
}
function Get-PenumbraSetup {
    $release=Get-PenumbraRelease
    $setup=''
    if ($release.Local) { $setup=$release.Url }
    else {
        $downloads=Get-PCVRDownloadsFolder
        $cached=Join-Path $downloads $release.Name
        if (Test-Path -LiteralPath $cached -PathType Leaf) {
            Write-Host "  Found in your registered Downloads folder: $cached" -ForegroundColor Cyan
            $use=(''+(Read-Host '  Use this Setup? [Y/N]')).Trim().ToUpperInvariant()
            if ($use -in @('Y','YES')) { $setup=$cached }
        }
        if (-not $setup) {
            $choice=Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath $downloads -MinimumFreeBytes 1000000000L
            if (-not $choice.BasePath) { throw 'Choose a drive with at least 1 GB free for publisher Setup.' }
            $script:PenumbraWork=New-PCVRInstallerTempSession -BasePath $choice.BasePath
            $setup=Join-Path $script:PenumbraWork $release.Name
            $result=Invoke-SafeDownload -Urls @($release.Url) -Destination $setup -Label ('Penumbra VR '+$release.Version+' Setup') -ExpectedReleaseTag $release.Tag -ManualUrl $script:PenumbraPage -AllowSkip $false
            if ($result -ne $true -and [string]$result -notin @('manual','retry')) { throw 'Publisher Setup download did not complete.' }
        }
    }
    if (-not (Test-DownloadedPayload -Path $setup -IntendedPath $release.Name)) { throw 'The downloaded publisher Setup EXE is unusable.' }
    return [pscustomobject]@{ Path=$setup; Version=$release.Version }
}
function Clear-PenumbraRemovedComponentReceipts([string]$Root) {
    if ($Game -eq 'Overture') {
        if (-not (Test-Path -LiteralPath (Join-Path $Root '.penumbravr\deploy-state.json') -PathType Leaf)) {
            $receipt=if ($env:PCVR_HUB_TEST_MODE -eq '1') { $env:PCVR_PENUMBRA_TEST_RECEIPT } else { Join-Path $script:PenumbraFolder '.installed_path' }
            if ($receipt -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
                $recorded=(''+(Get-Content -LiteralPath $receipt -Raw -ErrorAction SilentlyContinue)).Trim()
                if ($recorded -and $recorded -ieq $Root) { Remove-Item -LiteralPath $receipt -Force }
            }
            if ($env:PCVR_HUB_TEST_MODE -ne '1') {
                $versionReceipt=Join-Path $script:PenumbraFolder '.installed_version_b'
                if (Test-Path -LiteralPath $versionReceipt -PathType Leaf) { Remove-Item -LiteralPath $versionReceipt -Force }
            }
            $gameVersion=Join-Path $Root '.pcvrhub_version_b'
            if (Test-Path -LiteralPath $gameVersion -PathType Leaf) { Remove-Item -LiteralPath $gameVersion -Force }
            if (Get-Command Reset-PersistentGameStateValue -ErrorAction SilentlyContinue) {
                $tile=[pscustomobject]@{Id=$script:PenumbraId;Title=$script:PenumbraName}
                Reset-PersistentGameStateValue -Game $tile -Name 'installed_version_b'
            }
        }
        return
    }
    $bpPresent=Test-Path -LiteralPath (Join-Path $Root 'redist\PenumbraVR.BlackPlague.Probe.dll') -PathType Leaf
    $reqPresent=Test-Path -LiteralPath (Join-Path $Root 'redist\PenumbraVR.Requiem.Probe.dll') -PathType Leaf
    $bpReceipts=if ($env:PCVR_HUB_TEST_MODE -eq '1') { @($env:PCVR_PENUMBRA_TEST_RECEIPT_BLACKPLAGUE) } else {
        @('.installed_path','.installed_version','.installed_version_b' | ForEach-Object { Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'PenumbraBlackPlagueVR') $_ })
    }
    $reqReceipts=if ($env:PCVR_HUB_TEST_MODE -eq '1') { @($env:PCVR_PENUMBRA_TEST_RECEIPT_REQUIEM) } else {
        @('.installed_path','.installed_version','.installed_version_b' | ForEach-Object { Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'PenumbraRequiemVR') $_ })
    }
    if (-not $bpPresent) {
        foreach ($path in $bpReceipts) {
            if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
        }
    }
    if (-not $reqPresent) {
        foreach ($path in $reqReceipts) {
            if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
        }
    }
    if (-not $bpPresent -and -not $reqPresent) {
        $sharedVersion=Join-Path $Root '.pcvrhub_version'
        if (Test-Path -LiteralPath $sharedVersion -PathType Leaf) { Remove-Item -LiteralPath $sharedVersion -Force }
    }
}
function Invoke-PenumbraFramework {
    $script:PenumbraWork=''
    try {
        Clear-Host
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ('  '+$script:PenumbraName+' - Installer') -ForegroundColor Cyan
        Write-Host '  Penumbra VR Framework by rubocopter' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        if ($Mode -eq 'Install') {
            Write-Host '  The original Windows PC game is required.' -ForegroundColor White
            if ($Game -eq 'Requiem') { Write-Host '  Requiem also requires Black Plague in the same game folder.' -ForegroundColor Yellow }
            if ($Game -ne 'Overture') {
                Write-Host '  Have an old Penumbra: Overture VR install made with the Hub?' -ForegroundColor Yellow
                Write-Host '  Update it from the Overture game tile before this Setup.' -ForegroundColor Yellow
                Write-Host '  Do not use Repair on the old Overture v0.x files.' -ForegroundColor Yellow
            }
            Write-Host '  Publisher Setup installs, updates and repairs the VR files.' -ForegroundColor White
            Write-Host '  It retains existing settings and backs up changed originals.' -ForegroundColor White
        } else {
            Write-Host '  Publisher Setup manages removal and repair.' -ForegroundColor White
            Write-Host '  Select the desired game component in Setup; Black Plague and Requiem share a folder.' -ForegroundColor Yellow
        }
        Write-Host '  Windows may request administrator approval for a protected game folder.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate the game...')
        $root=Get-PenumbraGameFolder
        if (Get-Process -Name 'Penumbra','Requiem' -ErrorAction SilentlyContinue) { throw 'Close Penumbra before opening publisher Setup.' }
        Write-Host "  Game: $root" -ForegroundColor Green
        Write-Host '  Checking and downloading the current publisher Setup may take some time.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download publisher Setup...')
        $release=Get-PenumbraSetup
        $legacyOverture=$false
        $priorVersion=''
        if ($Game -eq 'Overture' -and $Mode -eq 'Install') {
            $oldStatePath=Join-Path $root '.penumbravr\deploy-state.json'
            if (Test-Path -LiteralPath $oldStatePath -PathType Leaf) {
                try {
                    $oldState=Get-Content -LiteralPath $oldStatePath -Raw | ConvertFrom-Json
                    $priorVersion=([string]$oldState.FrameworkVersion).Trim() -replace '^v',''
                    if (-not $priorVersion -and (Get-PenumbraLegacyOvertureState $root)) { $priorVersion='0.1.0'; $legacyOverture=$true }
                    elseif ($priorVersion -match '^0\.') { $legacyOverture=$true }
                } catch { throw 'The earlier Overture deployment state is unreadable. Review its backup before continuing.' }
            }
            if ($priorVersion) {
                if ([Version]$priorVersion -lt [Version]$release.Version) {
                    Write-Host "  Update available: $priorVersion -> $($release.Version)" -ForegroundColor Green
                } elseif ([Version]$priorVersion -eq [Version]$release.Version) {
                    Write-Host "  Penumbra VR Framework $priorVersion is already current." -ForegroundColor Green
                } else {
                    throw "Installed Framework $priorVersion is newer than Setup $($release.Version). Keep the installed version."
                }
            } else {
                Write-Host "  Current Framework Setup: $($release.Version)." -ForegroundColor Green
            }
        }
        if ($legacyOverture) {
            Write-Host '  Earlier Overture VR v0.x is installed. The Hub will verify' -ForegroundColor Yellow
            Write-Host '  its file manifest and restore the original game files first.' -ForegroundColor Yellow
            Write-Host '  Publisher Setup can then perform a fresh installation.' -ForegroundColor White
        } else {
            Write-Host ('  In Setup, select '+$(if ($Game -eq 'Overture') { 'Overture' } else { 'Black Plague or Requiem' })+' and finish Install, Update or Remove.') -ForegroundColor White
        }
        if ($Game -eq 'Requiem') { Write-Host '  Requiem needs Black Plague selected as well.' -ForegroundColor Yellow }
        Write-Host '  Setup may take several minutes while it checks and backs up files.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message $(if ($legacyOverture) { 'Press Enter to restore old Overture files...' } else { 'Press Enter to open publisher Setup...' }))
        if ($legacyOverture) {
            if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_LEGACY_RESTORE -in @('1','state-only')) {
                Remove-Item -LiteralPath (Join-Path $root '.penumbravr\deploy-state.json') -Force
                if ($env:PCVR_PENUMBRA_TEST_LEGACY_RESTORE -eq '1') {
                    foreach ($name in @('redist\Penumbra_vr.exe','redist\openvr_api.dll','redist\vr\actions.json')) {
                        $oldFile=Join-Path $root $name
                        if (Test-Path -LiteralPath $oldFile -PathType Leaf) { Remove-Item -LiteralPath $oldFile -Force }
                    }
                }
            } else {
                $oldState=Get-PenumbraLegacyOvertureState $root
                if (-not $oldState) { throw 'The old Overture deployment has no safe restore manifest.' }
                Restore-PenumbraLegacyOverture -Root $root -State $oldState
            }
            if (Test-Path -LiteralPath (Join-Path $root '.penumbravr\deploy-state.json') -PathType Leaf) {
                throw 'The earlier Overture VR files are still managed. In Setup > Maintenance, finish Uninstall for Overture before installing the new framework.'
            }
            $remainingOld=@(@('redist\Penumbra_vr.exe','redist\openvr_api.dll','redist\vr\actions.json') | Where-Object {
                Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf
            })
            if ($remainingOld.Count -gt 0) {
                throw ('Old Overture VR files remain after publisher removal: '+($remainingOld -join ', ')+'. Finish the publisher Restore before the new installation.')
            }
            Write-Host '  [OK] Earlier Overture VR was removed; original game files remain.' -ForegroundColor Green
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup and install Overture VR...')
        }
        if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_OUTPUT) {
            if ($Mode -eq 'Manage' -and $env:PCVR_PENUMBRA_TEST_MANAGE_REMOVE -eq '1') {
                if ($Game -eq 'Overture') {
                    foreach ($name in @('redist\Penumbra_vr.exe','redist\openvr_api.dll','.penumbravr\deploy-state.json')) {
                        $path=Join-Path $root $name
                        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
                    }
                } elseif ($Game -eq 'BlackPlague') {
                    foreach ($name in @('PenumbraVR.BlackPlague.Probe.dll','PenumbraVR.Requiem.Probe.dll','PenumbraVR.BlackPlague.install.json')) {
                        $path=Join-Path $root ('redist\'+$name)
                        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
                    }
                } else {
                    $path=Join-Path $root 'redist\PenumbraVR.Requiem.Probe.dll'
                    if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
                    $statePath=Join-Path $root 'redist\PenumbraVR.BlackPlague.install.json'
                    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
                        $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
                        $state.components=@($state.components | Where-Object { $_ -ne 'requiem' })
                        [IO.File]::WriteAllText($statePath,($state|ConvertTo-Json -Depth 6))
                    }
                }
            } else {
                $source=$env:PCVR_PENUMBRA_TEST_OUTPUT
                foreach ($item in @(Get-ChildItem -LiteralPath $source -Force)) { Copy-Item -LiteralPath $item.FullName -Destination $root -Recurse -Force }
            }
        } else {
            $process=Start-Process -FilePath $release.Path -Wait -PassThru -ErrorAction Stop
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher Setup ended with exit code $($process.ExitCode)." }
        }
        if ($Mode -eq 'Manage') {
            Clear-PenumbraRemovedComponentReceipts $root
            Write-Host '  [OK] Publisher maintenance closed. Scan games again to refresh the Hub.' -ForegroundColor Green
        } else {
            if (-not (Test-PenumbraInstalled $root)) { throw ('Publisher Setup did not finish '+$script:PenumbraName+'. Reopen it and select this game, then retry.') }
            $installedState=Get-Content -LiteralPath (Join-Path $root $(if ($Game -eq 'Overture') { '.penumbravr\deploy-state.json' } else { 'redist\PenumbraVR.BlackPlague.install.json' })) -Raw | ConvertFrom-Json
            $installedVersion=([string]$installedState.frameworkVersion).Trim() -replace '^v',''
            if ($installedVersion -ne $release.Version) {
                throw "Publisher Setup still reports version $installedVersion, not the selected release $($release.Version). Finish Update or Repair in Setup, then retry."
            }
            $receipt=if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_RECEIPT) { $env:PCVR_PENUMBRA_TEST_RECEIPT } else { Join-Path $script:PenumbraFolder '.installed_path' }
            [void](Save-HubRememberedGameFolder -GameId $script:PenumbraId -Title $script:PenumbraName -GameDir $root -ProbeFiles @('redist\'+$script:PenumbraExe))
            [void](Complete-PCVRInstallTransaction -Contract $script:PenumbraContract -GameDir $root -Version $release.Version -Route 'Current' -VersionSlot $(if ($Game -eq 'Overture') { 'Secondary' } else { 'Primary' }) -InstalledPathReceiptPaths @($receipt))
            Write-Host ('  [OK] '+$script:PenumbraName+' '+$release.Version+' is ready.') -ForegroundColor Green
            Write-Host '  Start in VR launches the game through Steam for Steam copies.' -ForegroundColor Yellow
        }
        Write-Host ''
        Write-Host $(if ($Game -eq 'Requiem') { '  The puzzles continue where Black Plague left you.' } else { '  The dark has more to reveal.' }) -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } finally {
        if ($script:PenumbraWork) { try { Remove-PCVRInstallerTempSession -Path $script:PenumbraWork } catch {} }
    }
}
if ($env:PCVR_PENUMBRA_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-PenumbraFramework; break }
        catch {
            $message=$script:PenumbraName+' setup did not complete: '+$_.Exception.Message
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $script:PenumbraFolder)
        }
    }
}
