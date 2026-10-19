$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$script:QuakeURepo='vittorioromeo/quakevr'
$script:QuakeUPage='https://github.com/vittorioromeo/quakevr/releases'
$script:QuakeURequired=@('ironwail.exe','ironwail.pak','openxr_loader.dll','quakevr\progs.dat','install.json','setup\QuakeVR-Setup.exe')
$script:QuakeUContract=New-PCVRInstallerContract -Id 'quake-vr-unleashed' -GameName 'Quake VR Unleashed' -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:QuakeUPage -Routes @('Unleashed') -RequiredInstalledFileGroups $script:QuakeURequired

function Get-QuakeUnleashedRelease($ReleaseData=$null) {
    if($null -eq $ReleaseData -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_QUAKEU_TEST_RELEASE_JSON){
        $ReleaseData=Get-Content -LiteralPath $env:PCVR_QUAKEU_TEST_RELEASE_JSON -Raw -ErrorAction Stop | ConvertFrom-Json
    }
    $options=@{Repo=$script:QuakeURepo;IncludePrerelease=$false;AssetPatterns=@('(?i)^QuakeVR-Setup\.exe$');SkipReleasesWithoutMatchingAsset=$true}
    if ($null -ne $ReleaseData) {$options.ReleaseData=$ReleaseData}
    $release=Resolve-GitHubReleaseAsset @options
    if (-not $release.Resolved -or -not $release.Url -or [string]$release.Tag -notmatch '^v?(?<version>1\.\d+\.\d+)$') {
        throw 'No current Quake VR Unleashed publisher Setup was found.'
    }
    return [pscustomobject]@{Version=$Matches.version;Tag=[string]$release.Tag;Url=[string]$release.Url;PageUrl=[string]$release.PageUrl}
}

function Get-QuakeUnleashedInstalled([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) {return $null}
    foreach($relative in $script:QuakeURequired) {
        if(-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)){return $null}
    }
    try {
        $manifest=Get-Content -LiteralPath (Join-Path $Root 'install.json') -Raw -ErrorAction Stop | ConvertFrom-Json
        if($manifest.product -cne 'Quake VR: Unleashed' -or [string]$manifest.version -notmatch '^(?<version>1\.\d+\.\d+)\b'){return $null}
        $version=$Matches.version
        $base=[string]$manifest.quakeDir
        $original=($base -and (Test-Path -LiteralPath (Join-Path $base 'id1\PAK0.PAK') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $base 'id1\PAK1.PAK') -PathType Leaf))
        $rerelease=($base -and (Test-Path -LiteralPath (Join-Path $base 'rerelease\id1\PAK0.PAK') -PathType Leaf))
        if(-not ($original -or $rerelease)){return $null}
        return [pscustomobject]@{Root=[IO.Path]::GetFullPath($Root);Version=$version;Base=[IO.Path]::GetFullPath($base);Stamp=(Get-Item -LiteralPath (Join-Path $Root 'install.json')).LastWriteTimeUtc.Ticks}
    } catch {return $null}
}

function Test-QuakeUnleashedPackage([string]$Path,[string]$Version) {
    if (-not $Path -or -not (Test-DownloadedPayload -Path $Path -IntendedPath 'QuakeVR.zip')) { return $false }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip=[IO.Compression.ZipFile]::OpenRead($Path)
        try {
            $entry=$zip.GetEntry('manifest.json')
            if (-not $entry) { return $false }
            $reader=New-Object IO.StreamReader($entry.Open())
            try { $manifest=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
            return ($manifest.product -ceq 'Quake VR' -and [string]$manifest.version -match ('^'+[regex]::Escape($Version)+'\b') -and
                $null -ne $zip.GetEntry('ironwail.exe') -and $null -ne $zip.GetEntry('quakevr/progs.dat'))
        } finally { $zip.Dispose() }
    } catch { return $false }
}

function Find-QuakeUnleashedInstalled {
    $roots=New-Object 'System.Collections.Generic.List[string]'
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_QUAKEU_TEST_ROOT) {
        $roots.Add([string]$env:PCVR_QUAKEU_TEST_ROOT)
    } else {
        foreach($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\QuakeVR','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\QuakeVR-Unleashed')) {
            try {$entry=Get-ItemProperty -LiteralPath $key -ErrorAction Stop;if($entry.InstallLocation){$roots.Add([string]$entry.InstallLocation)}}catch{}
        }
        try {
            $link=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Quake VR Unleashed.lnk'
            if(Test-Path -LiteralPath $link -PathType Leaf){
                $shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut($link)
                if([IO.Path]::GetFileName([string]$shortcut.TargetPath) -ieq 'ironwail.exe'){$roots.Add((Split-Path -Parent ([string]$shortcut.TargetPath)))}
            }
        }catch{}
        try{
            $receipt=Join-Path $PSScriptRoot '.installed_path_unleashed'
            if(Test-Path -LiteralPath $receipt -PathType Leaf){$roots.Add((Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop).Trim())}
        }catch{}
        $roots.Add((Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\QuakeVR'))
    }
    foreach($root in @($roots | Where-Object {$_} | Select-Object -Unique)){
        $installed=Get-QuakeUnleashedInstalled -Root $root
        if($installed){return $installed}
    }
    return $null
}

function Invoke-QuakeUnleashedInstaller {
    $work=$null
    try{
        Clear-Host
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Quake VR: Unleashed' -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Magenta
        Write-Host '  Requires your original Quake game and an OpenXR runtime.' -ForegroundColor White
        Write-Host '  Publisher Setup installs a separate copy and keeps saves and settings.' -ForegroundColor White
        Write-Host '  Optional HD textures need about 0.6 GB more space.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check the current Unleashed release...')
        $release=$null
        try {$release=Get-QuakeUnleashedRelease}
        catch {Write-Host '  GitHub could not confirm the current Setup. You can use an official Setup file from Downloads.' -ForegroundColor Yellow}
        if($release){Write-Host "  [OK] Publisher release $($release.Tag)." -ForegroundColor Green}
        $before=Find-QuakeUnleashedInstalled
        if($before){Write-Host "  Installed: $($before.Version) at $($before.Root)" -ForegroundColor Gray}
        $fixtureSetup=($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_QUAKEU_TEST_SETUP)
        $downloaded=if($fixtureSetup){[string]$env:PCVR_QUAKEU_TEST_SETUP}else{Find-PCVRDownloadedCandidate -Patterns @('QuakeVR-Setup.exe')}
        $useLocal=[bool]$fixtureSetup
        if($downloaded -and -not $fixtureSetup){
            $localVersion=([string](Get-Item -LiteralPath $downloaded).VersionInfo.FileVersion).Trim() -replace '\.0$',''
            if($localVersion -match '^1\.\d+\.\d+$' -and ($null -eq $release -or $localVersion -eq $release.Version) -and
                (Test-DownloadedPayload -Path $downloaded -IntendedPath 'QuakeVR-Setup.exe')){
                Write-Host "  Found official QuakeVR-Setup.exe $localVersion in Downloads:" -ForegroundColor White
                Write-Host "  $downloaded" -ForegroundColor Gray
                if(-not $release){Write-Host '  GitHub is unavailable, so the current version cannot be confirmed online.' -ForegroundColor Yellow}
                $useLocal=((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$')
                if($useLocal -and -not $release){$release=[pscustomobject]@{Version=$localVersion;Tag="v$localVersion";Url='';PageUrl=$script:QuakeUPage}}
            }
        }
        if(-not $release){
            Write-Host '  Download the current QuakeVR-Setup.exe from the official release page.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the release page...')
            Start-Process $script:QuakeUPage -ErrorAction Stop | Out-Null
            while(-not $useLocal){
                [void](Wait-PCVRExplicitEnter -Message 'After the download finishes, press Enter to check Downloads...')
                $downloaded=Find-PCVRDownloadedCandidate -Patterns @('QuakeVR-Setup.exe')
                if(-not $downloaded){
                    $raw=(Read-Host '  Drag QuakeVR-Setup.exe here, or press Enter to open the page again').Trim().Trim('"')
                    if($raw -and (Test-Path -LiteralPath $raw -PathType Leaf)){$downloaded=$raw}
                    else{Start-Process $script:QuakeUPage -ErrorAction Stop | Out-Null;continue}
                }
                $localVersion=([string](Get-Item -LiteralPath $downloaded).VersionInfo.FileVersion).Trim() -replace '\.0$',''
                if($localVersion -notmatch '^1\.\d+\.\d+$' -or -not (Test-DownloadedPayload -Path $downloaded -IntendedPath 'QuakeVR-Setup.exe')){
                    Write-Host '  This is not a usable Quake VR Unleashed Setup file.' -ForegroundColor Yellow
                    $downloaded=$null;continue
                }
                Write-Host "  Found QuakeVR-Setup.exe $localVersion at $downloaded" -ForegroundColor White
                Write-Host '  GitHub is unavailable, so the current version cannot be confirmed online.' -ForegroundColor Yellow
                $useLocal=((Read-Host '  Use this file? Y/N').Trim() -match '^(?i:y|yes)$')
                if($useLocal){$release=[pscustomobject]@{Version=$localVersion;Tag="v$localVersion";Url='';PageUrl=$script:QuakeUPage}}
            }
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to prepare the publisher Setup...')
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $setup=Join-Path $work 'QuakeVR-Setup.exe'
        if($useLocal){Copy-Item -LiteralPath $downloaded -Destination $setup -Force -ErrorAction Stop}
        else{
            $ok=Invoke-SafeDownload -Urls @($release.Url) -Destination $setup -Label "Quake VR Unleashed $($release.Version)" -ManualUrl $release.PageUrl -AllowSkip:$false
            if(-not $ok){throw 'The current publisher Setup is not ready.'}
        }
        if(-not (Test-DownloadedPayload -Path $setup -IntendedPath 'QuakeVR-Setup.exe')){throw 'The downloaded Setup is not a usable EXE.'}
        $setupVersion=if($fixtureSetup){$release.Version}else{([string](Get-Item -LiteralPath $setup).VersionInfo.FileVersion).Trim() -replace '\.0$',''}
        if($setupVersion -ne $release.Version){throw "Setup version $setupVersion does not match $($release.Version)."}
        $setupArgs=''
        $package=if($fixtureSetup){$null}else{Find-PCVRDownloadedCandidate -Patterns @('QuakeVR.zip')}
        if($package -and (Test-QuakeUnleashedPackage -Path $package -Version $release.Version)){
            Write-Host "  Found the publisher package in Downloads: $package" -ForegroundColor White
            if((Read-Host '  Use this package? Y/N').Trim() -match '^(?i:y|yes)$'){$setupArgs='--package "'+$package+'"'}
        }
        Write-Host '  Publisher Setup asks for its statement, game folder, destination' -ForegroundColor White
        Write-Host '  and optional HD textures. Keep the original game folder unchanged.' -ForegroundColor White
        Write-Host '  Windows may show SmartScreen; VC++ setup may request UAC.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open Quake VR Unleashed Setup...')
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_QUAKEU_TEST_PUBLISHER_OUTPUT){
            $source=[IO.Path]::GetFullPath($env:PCVR_QUAKEU_TEST_PUBLISHER_OUTPUT)
            $target=[IO.Path]::GetFullPath($env:PCVR_QUAKEU_TEST_ROOT)
            foreach($item in @(Get-ChildItem -LiteralPath $source -File -Recurse)){
                $rel=$item.FullName.Substring($source.TrimEnd([char[]]'\/').Length+1)
                $dest=Join-Path $target $rel
                [void][IO.Directory]::CreateDirectory((Split-Path -Parent $dest))
                Copy-Item -LiteralPath $item.FullName -Destination $dest -Force
            }
        }else{
            $start=@{FilePath=$setup;Wait=$true;PassThru=$true;ErrorAction='Stop'}
            if($setupArgs){$start.ArgumentList=$setupArgs}
            $process=Start-Process @start
            if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher Setup ended with exit code $($process.ExitCode)."}
        }
        $after=Find-QuakeUnleashedInstalled
        if(-not $after -and $env:PCVR_HUB_TEST_MODE -ne '1'){
            Write-Host '  The publisher Setup may have used a custom install folder.' -ForegroundColor Yellow
            $chosen=(Read-Host '  Drag the QuakeVR install folder here, or paste its full path').Trim().Trim('"')
            if($chosen){$after=Get-QuakeUnleashedInstalled -Root $chosen}
        }
        if(-not $after -or $after.Version -ne $release.Version){throw 'Publisher Setup ended without a complete matching Unleashed installation.'}
        if($before -and $before.Root -ieq $after.Root -and $before.Version -eq $after.Version -and $before.Stamp -eq $after.Stamp){throw 'Publisher Setup made no detectable change.'}
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_QUAKEU_TEST_RECEIPT){[IO.Path]::GetFullPath($env:PCVR_QUAKEU_TEST_RECEIPT)}else{Join-Path $PSScriptRoot '.installed_path_unleashed'}
        [void](Complete-PCVRInstallTransaction -Contract $script:QuakeUContract -GameDir $after.Root -Version $after.Version -Route Unleashed -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @((Join-Path $after.Root '.pcvrhub_version_c')))
        Write-Host "  [OK] Unleashed $($after.Version) is ready." -ForegroundColor Green
        Write-Host '  Use Start in VR in the Hub. The other Quake mods remain separate.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Step through the portal; the slipgate is open.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }finally{
        if($work){try{Remove-PCVRInstallerTempSession -Path $work}catch{}}
    }
}

if($env:PCVR_QUAKEU_LIBRARY_ONLY -ne '1'){
    while($true){
        try{Invoke-QuakeUnleashedInstaller;break}
        catch{
            $message="Quake VR Unleashed setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
