$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$Host.UI.RawUI.WindowTitle='Mario Kart Wii VR Installer'
$script:WiiId='mario-kart-wii-vr'
$script:WiiPage='https://github.com/iChris4/WheelWizard_VR/releases'

function Test-WiiVRInstall([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
    foreach ($relative in @('install-state.json','WiiCompiled-Setup.exe','Base\WiiCompiled.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { return $false }
    }
    try {
        $state=Get-Content -LiteralPath (Join-Path $Root 'install-state.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $same=[IO.Path]::GetFullPath([string]$state.installDir).TrimEnd([char[]]'\/').Equals([IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/'),[StringComparison]::OrdinalIgnoreCase)
        return ($state.productId -ceq 'wiicompiled-openxr-vr' -and [int]$state.schemaVersion -eq 1 -and [string]$state.setupVersion -match '^\d+\.\d+\.\d+' -and $same)
    } catch { return $false }
}
function Get-WiiVRInstall {
    $fixture=(''+$env:PCVR_WII_TEST_INSTALL).Trim()
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture) {
        $full=[IO.Path]::GetFullPath($fixture)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath (Join-Path $full 'wii-fixture.txt'))) { throw 'Wii fixture must stay under the temporary directory.' }
        return $full
    }
    $saved=Get-PCVRRememberedGameFolder -GameId $script:WiiId -StateNames @('installed_path','user_located') -ProbeFiles @('install-state.json')
    if (Test-WiiVRInstall $saved) { return (Get-Item -LiteralPath $saved).FullName }
    $dataRoot=$null
    try { $dataRoot=(Get-ItemProperty -Path 'HKCU:\Software\WheelWizardVR' -Name AppDataLocation -ErrorAction Stop).AppDataLocation } catch {}
    if (-not $dataRoot) { $dataRoot=Join-Path $env:APPDATA 'CT-MKWII' }
    $candidate=Join-Path $dataRoot 'RecompVR\Install'
    if (Test-WiiVRInstall $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    Write-Host '  WheelWizard VR can use a custom data folder.' -ForegroundColor White
    Write-Host '  Drag its RecompVR\Install folder here, or enter Q to cancel.' -ForegroundColor White
    while ($true) {
        $raw=(''+(Read-Host 'RecompVR Install folder or Q')).Trim().Trim('"').Trim("'")
        if ($raw -ieq 'Q') { return $null }
        if (Test-WiiVRInstall $raw) { return (Get-Item -LiteralPath $raw).FullName }
        Write-Host '  No complete OpenXR VR build found there. Check WheelWizard Home > Install.' -ForegroundColor Yellow
    }
}
function Get-WiiLauncher {
    $fixture=(''+$env:PCVR_WII_TEST_LAUNCHER).Trim()
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $fixture) {
        if (-not (Test-Path -LiteralPath $fixture -PathType Leaf)) { throw 'WheelWizard fixture is missing.' }
        return [pscustomobject]@{Url=$fixture;PageUrl=$script:WiiPage;Local=$true}
    }
    $asset=Resolve-GitHubReleaseAsset -Repo 'iChris4/WheelWizard_VR' -IncludePrerelease $false -AssetPatterns @('(?i)^WheelWizardVRWindows\.exe$') -FallbackUrl 'https://github.com/iChris4/WheelWizard_VR/releases/download/2.5.10/WheelWizardVRWindows.exe' -FallbackTag '2.5.10' -FallbackAssetName 'WheelWizardVRWindows.exe' -SkipReleasesWithoutMatchingAsset
    if (-not $asset.Url) { throw 'No official WheelWizard VR Windows launcher could be resolved.' }
    return [pscustomobject]@{Url=[string]$asset.Url;PageUrl=[string]$asset.PageUrl;Local=$false}
}
function Assert-WiiWindowsExe([string]$Path) {
    $f=[IO.File]::OpenRead($Path)
    try { if ($f.Length -lt 1024 -or $f.ReadByte() -ne 77 -or $f.ReadByte() -ne 90) { throw 'The WheelWizard download is not a usable Windows EXE.' } }
    finally { $f.Dispose() }
}
function Invoke-WiiProductCheck([string]$Executable,[string[]]$Arguments,[string]$Work) {
    $out=Join-Path $Work 'products-out.txt'
    $err=Join-Path $Work 'products-err.txt'
    $process=Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $out -RedirectStandardError $err -ErrorAction Stop
    # Windows PowerShell returns $null for an empty file even with -Raw.
    # Both streams may legitimately be empty when the publisher exits 0.
    [string]$stdout=if(Test-Path -LiteralPath $out){Get-Content -LiteralPath $out -Raw}else{''}
    [string]$stderr=if(Test-Path -LiteralPath $err){Get-Content -LiteralPath $err -Raw}else{''}
    if(-not [string]::IsNullOrWhiteSpace($stdout)){Write-Host ([string]$stdout).TrimEnd()}
    if(-not [string]::IsNullOrWhiteSpace($stderr)){Write-Host ([string]$stderr).TrimEnd() -ForegroundColor Yellow}
    if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw 'WiiCompiled product check says the VR build needs installation or repair in WheelWizard.'}
}
function Set-WiiBaseShortcutIcon([string]$Install,[string]$DesktopFolder) {
    $sourceIcon=Join-Path $PSScriptRoot 'MarioKartWiiVR.ico'
    $icon=Join-Path $Install 'MarioKartWiiVR.ico'
    $setup=Join-Path $Install 'WiiCompiled-Setup.exe'
    if(-not(Test-Path -LiteralPath $sourceIcon -PathType Leaf) -or -not(Test-Path -LiteralPath $setup -PathType Leaf)){return $false}
    $folders=if($DesktopFolder){@($DesktopFolder)}else{@([Environment]::GetFolderPath('DesktopDirectory'),[Environment]::GetFolderPath('CommonDesktopDirectory'))}
    $link=$null
    foreach($folder in $folders){
        if($folder -and (Test-Path -LiteralPath $folder -PathType Container)){
            $candidate=Join-Path $folder 'WiiCompiled OpenXR VR (base) (beta).lnk'
            if(Test-Path -LiteralPath $candidate -PathType Leaf){$link=$candidate;break}
        }
    }
    if(-not $link){return $false}
    $shell=New-Object -ComObject WScript.Shell
    $shortcut=$shell.CreateShortcut($link)
    if(-not [string]::Equals(([IO.Path]::GetFullPath($shortcut.TargetPath)),([IO.Path]::GetFullPath($setup)),[StringComparison]::OrdinalIgnoreCase) -or
       ($shortcut.Arguments.Trim() -ne '--launch-base')){return $false}
    # Match the Hexen/Strife shortcut pattern: keep its icon beside the
    # launcher so moving or updating the Hub does not break the shortcut.
    # A pre-existing custom icon is user-owned and stays untouched.
    if(-not(Test-Path -LiteralPath $icon -PathType Leaf)){Copy-Item -LiteralPath $sourceIcon -Destination $icon -ErrorAction Stop}
    $shortcut.IconLocation="$icon,0"
    $shortcut.Save()
    $verified=$shell.CreateShortcut($link)
    return [bool]($verified.IconLocation -like "$icon*")
}
function Invoke-WiiVRInstaller {
    $work=$null
    try {
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Mario Kart Wii VR - Installer' -ForegroundColor Cyan
        Write-Host '  WiiCompiled OpenXR VR via WheelWizard VR' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Bring your own clean, unmodified PAL RMCP01 Mario Kart Wii' -ForegroundColor White
        Write-Host '  disc image. No ROM, game data or BIOS is supplied.' -ForegroundColor White
        Write-Host '  WheelWizard VR imports and compiles it locally (about 20 GB' -ForegroundColor White
        Write-Host '  free space during installation). Close the game first.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to get the official WheelWizard VR launcher...')
        $release=Get-WiiLauncher
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-wii-'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $staged=Join-Path $work 'WheelWizardVRWindows.exe'
        if ($release.Local) { Copy-Item -LiteralPath $release.Url -Destination $staged -Force -ErrorAction Stop }
        else {
            $ok=Invoke-SafeDownload -Urls @($release.Url) -Destination $staged -Label 'WheelWizard VR' -ManualUrl $release.PageUrl -AllowSkip:$false
            if (-not $ok) { throw 'WheelWizard VR could not be downloaded.' }
        }
        Assert-WiiWindowsExe $staged
        $toolDir=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\Tools'
        [void][IO.Directory]::CreateDirectory($toolDir)
        $launcher=Join-Path $toolDir 'WheelWizardVRWindows.exe'
        Copy-Item -LiteralPath $staged -Destination $launcher -Force -ErrorAction Stop
        Write-Host '  In WheelWizard: Settings > select your PAL RMCP01 image.' -ForegroundColor White
        Write-Host '  Settings > Other > enable WiiCompiled OpenXR VR (beta).' -ForegroundColor White
        Write-Host '  Home > Install builds Base and Retro Rewind. Wait for completion.' -ForegroundColor White
        Write-Host '  The local build can take several minutes; follow WheelWizard progress.' -ForegroundColor Cyan
        Write-Host '  Home > Play chooses which one to start.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open WheelWizard VR...')
        if ($env:PCVR_HUB_TEST_MODE -ne '1') {
            $process=Start-Process -FilePath $launcher -PassThru -Wait -ErrorAction Stop
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "WheelWizard VR exited with code $($process.ExitCode)." }
        }
        [void](Wait-PCVRExplicitEnter -Message 'After WheelWizard finishes the VR build, press Enter to verify it...')
        $install=Get-WiiVRInstall
        if (-not (Test-WiiVRInstall $install)) { throw 'No complete WiiCompiled OpenXR VR build was found.' }
        $state=Get-Content -LiteralPath (Join-Path $install 'install-state.json') -Raw | ConvertFrom-Json
        if ($env:PCVR_HUB_TEST_MODE -ne '1') {
            # This Setup lives inside the verified Install folder and resolves
            # that product itself. Its --install-dir parser misreads an explicitly
            # quoted path as a different directory when launched via Start-Process.
            Invoke-WiiProductCheck -Executable (Join-Path $install 'WiiCompiled-Setup.exe') -Arguments @('--check-products') -Work $work
        }
        $contract=New-PCVRInstallerContract -Id $script:WiiId -GameName 'Mario Kart Wii VR' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl 'https://github.com/iChris4/Wiicompiled_VR/releases' -RequiredInstalledFileGroups @('install-state.json','WiiCompiled-Setup.exe','Base\WiiCompiled.exe')
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $install -Version ([string]$state.setupVersion) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route OpenXR)
        $desktop=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_WII_TEST_DESKTOP}else{''}
        try {
            if(Set-WiiBaseShortcutIcon -Install $install -DesktopFolder $desktop){Write-Host '  [OK] Added the Mario Kart Wii VR icon to the Base desktop shortcut.' -ForegroundColor Green}
            else{Write-Host '  WheelWizard Base desktop shortcut was not found or did not match; its icon was left unchanged.' -ForegroundColor Yellow}
        } catch { Write-Host '  The VR build is ready, but its desktop shortcut icon could not be updated.' -ForegroundColor Yellow }
        Write-Host "  [OK] WiiCompiled OpenXR VR $($state.setupVersion) is installed." -ForegroundColor Green
        Write-Host '  Hub Play starts the publisher Base launcher; WheelWizard' -ForegroundColor White
        Write-Host '  remains available for Retro Rewind, repair and updates.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Blue shells are still a problem at 90 frames per second.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        $message="Mario Kart Wii VR setup did not complete: $($_.Exception.Message)"
        Write-Host "  $message" -ForegroundColor Red
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
    } finally { if ($work -and (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
}
if ($env:PCVR_WII_LIBRARY_ONLY -ne '1') { Invoke-WiiVRInstaller }
