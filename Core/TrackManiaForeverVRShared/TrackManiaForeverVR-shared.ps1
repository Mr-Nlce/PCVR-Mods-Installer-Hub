param([ValidateSet('Nations','United')][string]$Edition = 'Nations')

$ErrorActionPreference = 'Stop'
if (-not (Get-Command New-PCVRInstallerContract -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
}
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'TMFOXRElevatedOperations.ps1')

$script:TMFOXRRepo = 'jiink/TrackManiaForeverOpenXR'
$script:TMFOXRReleases = 'https://github.com/jiink/TrackManiaForeverOpenXR/releases'
$script:TMFOXRUsage = 'https://github.com/jiink/TrackManiaForeverOpenXR#usage'
$script:TMFOXRLoaderUrl = 'https://tomashu.pages.dev/modloader/modloader/TMLoader-latest.exe'
$script:TMFOXRUVMEPage = 'https://strangeplanet.fr/work/trackmania-uvme/'
$script:TMFOXRFallbackTag = 'v8'
$script:TMFOXRFallbackDirectName = 'TMFOXR-v8.zip'
$script:TMFOXRFallbackLoaderName = 'TMFOXR-v8-for-TMLoader.zip'
$script:TMFOXRFallbackDirectUrl = 'https://github.com/jiink/TrackManiaForeverOpenXR/releases/download/v8/TMFOXR-v8.zip'
$script:TMFOXRFallbackLoaderUrl = 'https://github.com/jiink/TrackManiaForeverOpenXR/releases/download/v8/TMFOXR-v8-for-TMLoader.zip'

function Get-TMFOXREditionConfig {
    param([ValidateSet('Nations','United')][string]$Name)
    if ($Name -eq 'United') {
        return [pscustomobject][ordered]@{
            Edition='United'; Id='trackmania-united-forever'; Title='TrackMania United Forever'; AppId='7200'
            SteamFolders=@('TrackMania United'); HubFolder='TrackManiaUnitedForeverVR'
            FallbackPaths=@('C:\Program Files (x86)\TmUnitedForever')
            DirectIdentity='tmfoxr_united_direct'; Launcher='Start TrackMania United Forever VR.bat'
            Quip='Seven environments, one headset, and no horizon wide enough for the next jump.'
        }
    }
    return [pscustomobject][ordered]@{
        Edition='Nations'; Id='trackmania-nations-forever'; Title='TrackMania Nations Forever'; AppId='11020'
        SteamFolders=@('TrackMania Nations Forever'); HubFolder='TrackManiaNationsForeverVR'
        FallbackPaths=@('C:\Program Files (x86)\TmNationsForever')
        DirectIdentity='tmfoxr_nations_direct'; Launcher='Start TrackMania Nations Forever VR.bat'
        Quip='The stadium has no walls in VR, but the next corner still does.'
    }
}

function Write-TMFOXRStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''
    Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan
    Write-Host ''
}
function Write-TMFOXROK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-TMFOXRInfo([string]$Text) { Write-Host "  [i] $Text" -ForegroundColor Gray }
function Write-TMFOXRWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Write-TMFOXRCompletionGuidance {
    param($Config)
    Write-Host '  Press [3] in a race for first-person view and [F10] for' -ForegroundColor White
    Write-Host '  TMFOXR settings. Cancel shadow computation after a few seconds' -ForegroundColor White
    Write-Host '  if it stalls; do not press cancel immediately.' -ForegroundColor White
    if ($Config.Edition -eq 'Nations') {
        Write-Host ''
        Write-Host '  Gamepad note: TMNF can leave gamepad axes unbound, including' -ForegroundColor Yellow
        Write-Host '  with Virtual Desktop Gamepad Mode. Main menu > Profile > Inputs:' -ForegroundColor Yellow
        Write-Host '  Acceleration (analog): Y Axis (Pad 1) - Left Stick up' -ForegroundColor Gray
        Write-Host '  Steering (analog):     X Axis (Pad 1) - Left Stick left' -ForegroundColor Gray
        Write-Host '  Camera 1: [A]   Camera 2: [B]   Camera 3: [Right Stick Click]' -ForegroundColor Gray
        Write-Host '  Camera 3 is first-person; the camera buttons can be reassigned.' -ForegroundColor Gray
    }
}

function Get-TMFOXRProductsRoot {
    $override = ('' + $env:PCVR_TMFOXR_PRODUCTS_ROOT).Trim()
    if ($override) { return [IO.Path]::GetFullPath($override) }
    return [IO.Path]::Combine([Environment]::GetFolderPath('LocalApplicationData'),'TMLoader','database','TmForever','products')
}

function Get-TMFOXRCoreRoot {
    $override = ('' + $env:PCVR_TMFOXR_CORE_ROOT).Trim()
    if ($override) { return [IO.Path]::GetFullPath($override) }
    return [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

function Test-TMFOXRGameRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'TmForever.exe') -PathType Leaf -ErrorAction SilentlyContinue))
}

function Find-TMFOXRGameRoot($Config) {
    $override = ('' + $env:PCVR_TMFOXR_GAME_ROOT).Trim()
    if (Test-TMFOXRGameRoot $override) { return (Get-Item -LiteralPath $override).FullName }
    $found = Find-SteamGameFolder -AppId $Config.AppId -SteamFolderNames $Config.SteamFolders -ProbeExe 'TmForever.exe' -HubGameId $Config.Id
    if (Test-TMFOXRGameRoot $found) { return (Get-Item -LiteralPath $found).FullName }
    foreach ($candidate in $Config.FallbackPaths) {
        if (Test-TMFOXRGameRoot $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    $picked = Get-GameFolderInteractive -GameName $Config.Title -ProbeFile 'TmForever.exe' -ManualUrl ("https://store.steampowered.com/app/" + $Config.AppId + '/')
    if ($picked -in @('quit','skip',$null) -or -not (Test-TMFOXRGameRoot $picked)) { return $null }
    return (Get-Item -LiteralPath $picked).FullName
}

function Select-TMFOXRInstallMode {
    param([scriptblock]$ReadInput = $null)
    Write-Host '  Choose how TMFOXR should be installed:' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host '  [1] Direct - fastest setup; files sit next to TmForever.exe' -ForegroundColor Yellow
    Write-Host '  [2] TMLoader - one-click enable/disable and much faster shadow baking' -ForegroundColor Yellow
    Write-Host '      Installs Tomashu''s loader first when it is not already present.' -ForegroundColor Gray
    while ($true) {
        $answer = if ($ReadInput) { & $ReadInput } else { Read-Host '  Choose 1, 2 or Q' }
        switch (('' + $answer).Trim().ToUpperInvariant()) {
            '1' { return 'Direct' }
            '2' { return 'TMLoader' }
            'Q' { return $null }
            default { Write-Host '  Enter 1, 2 or Q.' -ForegroundColor Yellow }
        }
    }
}

function Test-TMFOXRPortableExecutable([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    $stream = $null
    try {
        $stream = [IO.File]::OpenRead($Path)
        if ($stream.Length -lt 2) { return $false }
        return ($stream.ReadByte() -eq 0x4D -and $stream.ReadByte() -eq 0x5A)
    } catch { return $false }
    finally { if ($stream) { $stream.Dispose() } }
}

function Test-TMFOXRUnitedUVMEInstaller([string]$Path) {
    if (-not (Test-TMFOXRPortableExecutable $Path)) { return $false }
    $leaf = Split-Path -Leaf $Path
    if ($leaf -match '(?i)nations') { return $false }
    try {
        $info = (Get-Item -LiteralPath $Path -ErrorAction Stop).VersionInfo
        $identity = (([string]$info.ProductName) + ' ' + ([string]$info.FileDescription)).Trim()
        return ($identity -match '(?i)TmUnitedForever' -and $identity -match '(?i)UVME')
    } catch { return $false }
}

function Get-TMFOXRDownloadFolders {
    $folders = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    try {
        $known = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
        $redirected = [Environment]::ExpandEnvironmentVariables(('' + $known.'{374DE290-123F-4565-9164-39C4925E467B}'))
        if ($redirected) { [void]$folders.Add($redirected) }
    } catch {}
    $profile = [Environment]::GetFolderPath('UserProfile')
    if ($profile) { [void]$folders.Add((Join-Path $profile 'Downloads')) }
    if ($env:OneDrive) { [void]$folders.Add((Join-Path $env:OneDrive 'Downloads')) }
    return @($folders | Where-Object { $_ -and $seen.Add($_) -and (Test-Path -LiteralPath $_ -PathType Container -ErrorAction SilentlyContinue) })
}

function Get-TMFOXRUnitedUVMECandidates {
    param([string[]]$Folders = @())
    if (-not $Folders -or $Folders.Count -eq 0) { $Folders = @(Get-TMFOXRDownloadFolders) }
    $hits = [Collections.Generic.List[IO.FileInfo]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($folder in @($Folders)) {
        if (-not $folder -or -not (Test-Path -LiteralPath $folder -PathType Container -ErrorAction SilentlyContinue)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $folder -Filter '*.exe' -File -ErrorAction SilentlyContinue)) {
            if ($seen.Add($file.FullName) -and (Test-TMFOXRUnitedUVMEInstaller $file.FullName)) { [void]$hits.Add($file) }
        }
    }
    return @($hits | Sort-Object LastWriteTimeUtc -Descending)
}

function Read-TMFOXRUnitedUVMEInstaller {
    param([scriptblock]$ReadInput = $null,[scriptblock]$OpenUrl = $null,[string[]]$SearchFolders = @())
    while ($true) {
        $found = @(Get-TMFOXRUnitedUVMECandidates -Folders $SearchFolders)
        if ($found.Count -gt 0) {
            Write-Host ''
            Write-Host '  Matching TrackMania United Forever UVME installers:' -ForegroundColor Cyan
            for ($i = 0; $i -lt $found.Count; $i++) {
                Write-Host ("   [{0}] {1}" -f ($i + 1),$found[$i].Name) -ForegroundColor White
                Write-Host ("       {0:N1} MiB  {1}" -f ($found[$i].Length / 1MB),$found[$i].DirectoryName) -ForegroundColor DarkGray
            }
            $prompt = if ($found.Count -eq 1) { 'Press Enter to use [1], or B to go back' } else { "Press Enter to use [1], choose 1-$($found.Count), or B to go back" }
            $answer = if ($ReadInput) { & $ReadInput $prompt } else { Read-Host ('  ' + $prompt) }
            $choice = ('' + $answer).Trim()
            if ($choice -ieq 'B') { $found = @() }
            else {
                if (-not $choice) { $choice = '1' }
                $number = 0
                if ([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $found.Count) { return $found[$number - 1].FullName }
                Write-TMFOXRWarn 'Choose one of the shown numbers, or B.'
                continue
            }
        }

        Write-Host ''
        Write-Host '  Drag or paste the downloaded United UVME EXE path here.' -ForegroundColor Yellow
        Write-Host '  Or press Enter to search Downloads again.' -ForegroundColor Yellow
        Write-Host '  Type O to reopen the official page, or S to skip UVME.' -ForegroundColor Gray
        $raw = if ($ReadInput) { & $ReadInput 'EXE path / Enter / O / S' } else { Read-Host '  EXE path / Enter / O / S' }
        $value = ('' + $raw).Trim().Trim('"').Trim("'")
        if ($value -ieq 'S') { return $null }
        if ($value -ieq 'O') {
            if ($OpenUrl) { & $OpenUrl $script:TMFOXRUVMEPage | Out-Null }
            elseif ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -ne '1') { Start-Process $script:TMFOXRUVMEPage -ErrorAction Stop | Out-Null }
            continue
        }
        if (-not $value) { continue }
        if (Test-TMFOXRUnitedUVMEInstaller $value) { return (Get-Item -LiteralPath $value).FullName }
        Write-TMFOXRWarn 'That is not the United UVME installer. The 29 MiB Nations download is not compatible here.'
    }
}

function Invoke-TMFOXRUnitedUVMEOptional {
    param([scriptblock]$ReadInput = $null,[scriptblock]$OpenUrl = $null,[scriptblock]$RunInstaller = $null,[string[]]$SearchFolders = @())
    $overrideChoice = ('' + $env:PCVR_TMFOXR_INSTALL_UVME).Trim().ToUpperInvariant()
    $answer = if ($overrideChoice) { $overrideChoice } elseif ($ReadInput) { & $ReadInput 'Install optional UVME HD car interiors too? [Y/N]' } else { Read-Host '  Install optional UVME HD car interiors too? [Y/N]' }
    if ((('' + $answer).Trim().ToUpperInvariant()) -notin @('Y','YES')) { Write-TMFOXRInfo 'UVME skipped; TMFOXR remains fully installed.'; return $false }

    Write-Host ''
    Write-Host '  UVME can add HD car interiors and broader visual improvements.' -ForegroundColor White
    Write-Host '  Download the 465 MiB TrackMania United Forever version.' -ForegroundColor Yellow
    Write-Host '  The 29 MiB lighter download is for Nations Forever, not United.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the official UVME page...' -ReadInput $ReadInput)
    if ($OpenUrl) { & $OpenUrl $script:TMFOXRUVMEPage | Out-Null }
    elseif ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -ne '1') { Start-Process $script:TMFOXRUVMEPage -ErrorAction Stop | Out-Null }
    [void](Wait-PCVRExplicitEnter -Message 'When the 465 MiB United download has finished, press Enter. Running it may show a UAC request.' -ReadInput $ReadInput)

    $override = ('' + $env:PCVR_TMFOXR_UVME_INSTALLER).Trim()
    $installer = if ($override) {
        if (-not (Test-TMFOXRUnitedUVMEInstaller $override)) { Write-TMFOXRWarn 'The supplied UVME path is not the TrackMania United Forever installer.'; return $false }
        [IO.Path]::GetFullPath($override)
    } else { Read-TMFOXRUnitedUVMEInstaller -ReadInput $ReadInput -OpenUrl $OpenUrl -SearchFolders $SearchFolders }
    if (-not $installer) { Write-TMFOXRInfo 'UVME skipped; TMFOXR remains fully installed.'; return $false }

    Write-Host ''
    Write-Host '  The official UVME installer will now open.' -ForegroundColor White
    Write-Host '  Windows may request administrator permission before it starts.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the United UVME installer...' -ReadInput $ReadInput)
    try {
        if ($RunInstaller) { $exitCode = & $RunInstaller $installer }
        elseif ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -eq '1') { $exitCode = 0 }
        else { $exitCode = (Start-Process -FilePath $installer -Verb RunAs -Wait -PassThru -ErrorAction Stop).ExitCode }
        if ([int]$exitCode -ne 0) { Write-TMFOXRWarn "UVME closed with exit code $exitCode. TMFOXR itself is still installed."; return $false }
        Write-TMFOXROK 'UVME setup finished. Select an HD car in Profile for a modeled interior.'
        return $true
    } catch {
        Write-TMFOXRWarn ('UVME could not be started: ' + $_.Exception.Message)
        Write-TMFOXRInfo 'TMFOXR itself is still installed and ready.'
        return $false
    }
}

function Find-TMFOXRDirectPayload([string]$Root) {
    foreach ($candidate in @((Get-Item -LiteralPath $Root -ErrorAction SilentlyContinue)) + @(Get-ChildItem -LiteralPath $Root -Directory -Recurse -ErrorAction SilentlyContinue)) {
        if ((Test-Path -LiteralPath (Join-Path $candidate.FullName 'd3d9.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'openxr_loader.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'TMFOXR.defaults.ini') -PathType Leaf)) { return $candidate.FullName }
    }
    return $null
}

function Find-TMFOXRLoaderPayload([string]$Root) {
    $description = Get-ChildItem -LiteralPath $Root -Filter 'description.yaml' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'TMFOXR' } | Select-Object -First 1
    if (-not $description) { return $null }
    $product = $description.Directory.FullName
    $runtime = Get-ChildItem -LiteralPath $product -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName 'TMFOXR.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'openxr_loader.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'TMFOXR.defaults.ini') -PathType Leaf)
        } | Select-Object -First 1
    if (-not $runtime) { return $null }
    $sourceRoot = Split-Path -Parent $product
    $runtimeRelative = $runtime.FullName.Substring($sourceRoot.TrimEnd('\','/').Length + 1)
    return [pscustomobject]@{ SourceRoot=$sourceRoot; ProductRoot=$product; RuntimeRoot=$runtime.FullName; RuntimeRelative=$runtimeRelative }
}

function Find-TMLoaderExe {
    $override = ('' + $env:PCVR_TMLOADER_EXE).Trim()
    if ($override -and (Test-Path -LiteralPath $override -PathType Leaf)) { return [IO.Path]::GetFullPath($override) }
    $local = [Environment]::GetFolderPath('LocalApplicationData')
    $candidates = @(
        (Join-Path $local 'TMLoader\TMLoader.exe'),
        (Join-Path $local 'Programs\TMLoader\TMLoader.exe')
    )
    foreach ($candidate in $candidates) { if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate } }
    $root = Join-Path $local 'TMLoader'
    if (Test-Path -LiteralPath $root -PathType Container) {
        $hit = Get-ChildItem -LiteralPath $root -Filter 'TMLoader*.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Get-TMFOXRAssetPattern {
    param([ValidateSet('Direct','TMLoader')][string]$Mode)
    if ($Mode -eq 'Direct') { return '(?i)^TMFOXR-v(?!.*-for-TMLoader\.zip$)[0-9][A-Za-z0-9._-]*\.zip$' }
    return '(?i)^TMFOXR-v[0-9][A-Za-z0-9._-]*-for-TMLoader\.zip$'
}

function Get-TMFOXRReleaseArchive {
    param([ValidateSet('Direct','TMLoader')][string]$Mode,[string]$WorkRoot)
    $override = if ($Mode -eq 'Direct') { ('' + $env:PCVR_TMFOXR_DIRECT_ARCHIVE).Trim() } else { ('' + $env:PCVR_TMFOXR_LOADER_ARCHIVE).Trim() }
    if ($override) {
        if (-not (Test-Path -LiteralPath $override -PathType Leaf)) { throw "The test/source archive is missing: $override" }
        return [pscustomobject]@{ Archive=[IO.Path]::GetFullPath($override); Tag=$script:TMFOXRFallbackTag; AssetName=(Split-Path -Leaf $override); PageUrl=$script:TMFOXRReleases }
    }
    $pattern = Get-TMFOXRAssetPattern -Mode $Mode
    $fallbackName = if ($Mode -eq 'Direct') { $script:TMFOXRFallbackDirectName } else { $script:TMFOXRFallbackLoaderName }
    $fallbackUrl = if ($Mode -eq 'Direct') { $script:TMFOXRFallbackDirectUrl } else { $script:TMFOXRFallbackLoaderUrl }
    $release = Resolve-GitHubReleaseAsset -Repo $script:TMFOXRRepo -IncludePrerelease $false -AssetPatterns @($pattern) `
        -FallbackUrl $fallbackUrl -FallbackTag $script:TMFOXRFallbackTag -FallbackAssetName $fallbackName
    $archive = Join-Path $WorkRoot $fallbackName
    Write-TMFOXRInfo "Downloading $($release.AssetName) from the publisher release."
    $downloaded = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label ([string]$release.AssetName) `
        -ManualUrl ([string]$release.PageUrl) -AllowSkip $false -QuietProgress
    if (-not ($downloaded -eq $true -or [string]$downloaded -in @('manual','retry'))) { throw 'The required TMFOXR release asset was not downloaded.' }
    return [pscustomobject]@{ Archive=$archive; Tag=[string]$release.Tag; AssetName=[string]$release.AssetName; PageUrl=[string]$release.PageUrl }
}

function Ensure-TMLoader {
    param([string]$WorkRoot)
    $loader = Find-TMLoaderExe
    if ($loader) { Write-TMFOXROK "TMLoader found: $loader"; return $loader }
    $installerOverride = ('' + $env:PCVR_TMLOADER_INSTALLER).Trim()
    $installer = if ($installerOverride) { [IO.Path]::GetFullPath($installerOverride) } else { Join-Path $WorkRoot 'TMLoader-latest.exe' }
    if (-not $installerOverride) {
        Write-TMFOXRInfo 'Downloading the current TMLoader installer from Tomashu.'
        $exeValidator = { param([string]$Candidate) Test-TMFOXRPortableExecutable $Candidate }
        $downloaded = Invoke-SafeDownload -Urls @($script:TMFOXRLoaderUrl) -Destination $installer -Label 'TMLoader installer' `
            -ManualUrl 'https://tomashu.pages.dev/modloader/' -AllowSkip $false -Validator $exeValidator -QuietProgress
        if (-not ($downloaded -eq $true -or [string]$downloaded -in @('manual','retry'))) { throw 'TMLoader was not downloaded.' }
    } elseif (-not (Test-TMFOXRPortableExecutable $installer)) { throw 'The selected TMLoader installer is not a usable Windows executable.' }
    Write-Host ''
    Write-Host '  TMLoader is an unsigned third-party application.' -ForegroundColor Yellow
    Write-Host '  Install it outside the TrackMania game folder. Windows may ask for' -ForegroundColor White
    Write-Host '  confirmation when its protocol integration is registered.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the TMLoader installer...')
    if ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -ne '1') {
        $process = Start-Process -FilePath $installer -PassThru -Wait -ErrorAction Stop
        if ($process.ExitCode -ne 0) { throw "TMLoader setup closed with exit code $($process.ExitCode)." }
    }
    $loader = Find-TMLoaderExe
    if (-not $loader) { throw 'TMLoader setup finished, but TMLoader.exe could not be found. Install it in its normal per-user location and retry.' }
    Write-TMFOXROK "TMLoader installed: $loader"
    return $loader
}

function New-TMFOXRDirectStage {
    param([string]$Payload,[string]$Stage,[string]$Launcher)
    [void][IO.Directory]::CreateDirectory($Stage)
    foreach ($name in @('d3d9.dll','openxr_loader.dll','TMFOXR.defaults.ini')) { Copy-Item -LiteralPath (Join-Path $Payload $name) -Destination (Join-Path $Stage $name) -Force }
    $batch = "@echo off`r`nstart `"`" `"%~dp0TmForever.exe`"`r`n"
    Write-PCVRAtomicText -Path (Join-Path $Stage $Launcher) -Value $batch
}

function New-TMFOXRLoaderStage {
    param([string]$PayloadRoot,[string]$Stage,[string]$LoaderExe)
    [void][IO.Directory]::CreateDirectory($Stage)
    Copy-Item -LiteralPath (Join-Path $PayloadRoot 'TMFOXR') -Destination (Join-Path $Stage 'TMFOXR') -Recurse -Force
    $batch = "@echo off`r`npowershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Start TMLoader.ps1`"`r`n"
    foreach ($launcher in @('Start TrackMania Nations Forever VR.bat','Start TrackMania United Forever VR.bat')) {
        Write-PCVRAtomicText -Path (Join-Path $Stage $launcher) -Value $batch
    }
    $loaderScript = @'
$pathFile = Join-Path $PSScriptRoot '.pcvrhub_tmloader_path'
$loader = if (Test-Path -LiteralPath $pathFile -PathType Leaf) { (Get-Content -LiteralPath $pathFile -Raw).Trim() } else { '' }
if (-not $loader -or -not (Test-Path -LiteralPath $loader -PathType Leaf)) {
    $local = [Environment]::GetFolderPath('LocalApplicationData')
    foreach ($candidate in @((Join-Path $local 'TMLoader\TMLoader.exe'),(Join-Path $local 'Programs\TMLoader\TMLoader.exe'))) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $loader = $candidate; break }
    }
}
if ($loader -and (Test-Path -LiteralPath $loader -PathType Leaf)) { Start-Process -FilePath $loader; exit 0 }
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('TMLoader.exe was moved or removed. Run the TrackMania VR installer again to reconnect it.','TMLoader not found','OK','Warning') | Out-Null
exit 1
'@
    Write-PCVRAtomicText -Path (Join-Path $Stage 'Start TMLoader.ps1') -Value $loaderScript
    Write-PCVRAtomicText -Path (Join-Path $Stage '.pcvrhub_tmloader_path') -Value $LoaderExe
}

function Install-TMFOXRDirect {
    param($Config,[string]$GameRoot,[string]$Payload,[string]$Version)
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_tmfoxr_direct_stage_' + [Guid]::NewGuid().ToString('N'))
    try {
        New-TMFOXRDirectStage -Payload $Payload -Stage $stage -Launcher $Config.Launcher
        if (-not (Test-InstallerTargetWritable -TargetPath (Join-Path $GameRoot 'd3d9.dll'))) {
            Write-Host ''
            Write-Host '  The game folder needs administrator rights for this copy.' -ForegroundColor Yellow
            Write-Host '  Windows will show one UAC request; no other folder is changed.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to request the required administrator rights...')
            $elevated = Invoke-TMFOXRElevatedOwnedOperation -Action InstallDirect -Edition $Config.Edition -GameRoot $GameRoot -SourceRoot $stage -Version $Version
            if (-not [bool]$elevated.Success) {
                $required = @('d3d9.dll','openxr_loader.dll','TMFOXR.defaults.ini',$Config.Launcher) | ForEach-Object { Join-Path $GameRoot $_ }
                $recopy = {
                    $retry = Invoke-TMFOXRElevatedOwnedOperation -Action InstallDirect -Edition $Config.Edition -GameRoot $GameRoot -SourceRoot $stage -Version $Version
                    if (-not [bool]$retry.Success) { throw ([string]$retry.Error) }
                }.GetNewClosure()
                if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $GameRoot -Recopy $recopy -WaitSeconds 0)) { throw 'Required direct TMFOXR files are still missing after recovery.' }
            }
            Write-TMFOXROK 'Direct TMFOXR files survived the post-copy check and were committed.'
            return
        }
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $GameRoot -Identity $Config.DirectIdentity -AdoptIdenticalExisting)
        $required = @('d3d9.dll','openxr_loader.dll','TMFOXR.defaults.ini',$Config.Launcher) | ForEach-Object { Join-Path $GameRoot $_ }
        $recopy = { [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $GameRoot -Identity $Config.DirectIdentity -AdoptIdenticalExisting) }.GetNewClosure()
        $survivalWait = if ((('' + $env:PCVR_TMFOXR_TEST_FAST).Trim()) -eq '1') { 0 } else { 3 }
        if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $GameRoot -Recopy $recopy -WaitSeconds $survivalWait)) { throw 'Required direct TMFOXR files are still missing after recovery.' }
        $contract = New-PCVRInstallerContract -Id $Config.Id -GameName ($Config.Title + ' VR') -Acquisition GitHub -AntivirusNotice `
            -ReleasePageUrl $script:TMFOXRReleases -Routes @('Direct') `
            -RequiredInstalledFileGroups @('d3d9.dll','openxr_loader.dll','TMFOXR.defaults.ini',$Config.Launcher,(".pcvrhub_" + $Config.DirectIdentity + '_ownership.csv'))
        $receipt = Join-Path (Join-Path (Get-TMFOXRCoreRoot) $Config.HubFolder) '.installed_path'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version -InstalledPathReceiptPaths @($receipt) -Route 'Direct')
    } finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Install-TMFOXRLoader {
    param($Config,[string]$ProductsRoot,$LoaderPayload,[string]$LoaderExe,[string]$Version)
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_tmfoxr_loader_stage_' + [Guid]::NewGuid().ToString('N'))
    try {
        New-TMFOXRLoaderStage -PayloadRoot $LoaderPayload.SourceRoot -Stage $stage -LoaderExe $LoaderExe
        [void][IO.Directory]::CreateDirectory($ProductsRoot)
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $ProductsRoot -Identity 'tmfoxr_loader' -AdoptIdenticalExisting)
        $runtimeRelative = [string]$LoaderPayload.RuntimeRelative
        $requiredRelative = @(
            'TMFOXR\description.yaml',
            (Join-Path $runtimeRelative 'TMFOXR.dll'),
            (Join-Path $runtimeRelative 'openxr_loader.dll'),
            (Join-Path $runtimeRelative 'TMFOXR.defaults.ini'),
            'Start TrackMania Nations Forever VR.bat',
            'Start TrackMania United Forever VR.bat',
            'Start TMLoader.ps1',
            '.pcvrhub_tmloader_path'
        )
        $required = @($requiredRelative | ForEach-Object { Join-Path $ProductsRoot $_ })
        $recopy = { [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $ProductsRoot -Identity 'tmfoxr_loader' -AdoptIdenticalExisting) }.GetNewClosure()
        $survivalWait = if ((('' + $env:PCVR_TMFOXR_TEST_FAST).Trim()) -eq '1') { 0 } else { 3 }
        if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $ProductsRoot -Recopy $recopy -WaitSeconds $survivalWait)) { throw 'Required TMLoader TMFOXR files are still missing after recovery.' }
        $contract = New-PCVRInstallerContract -Id $Config.Id -GameName ($Config.Title + ' VR') -Acquisition GitHub -AntivirusNotice `
            -ReleasePageUrl $script:TMFOXRReleases -Routes @('TMLoader') `
            -RequiredInstalledFileGroups @($requiredRelative + '.pcvrhub_tmfoxr_loader_ownership.csv')
        $coreRoot = Get-TMFOXRCoreRoot
        $receipts = @(
            (Join-Path (Join-Path $coreRoot 'TrackManiaNationsForeverVR') '.installed_path'),
            (Join-Path (Join-Path $coreRoot 'TrackManiaUnitedForeverVR') '.installed_path')
        )
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $ProductsRoot -Version $Version -InstalledPathReceiptPaths $receipts -Route 'TMLoader')
    } finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Invoke-TMFOXRInstaller {
    param([ValidateSet('Nations','United')][string]$EditionName)
    $config = Get-TMFOXREditionConfig $EditionName
    $Host.UI.RawUI.WindowTitle = $config.Title + ' VR Installer'
    $work = $null
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ("  " + $config.Title + ' VR - Installer') -ForegroundColor Cyan
        Write-Host '  Installs: TrackMania Forever OpenXR by jiink' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Native OpenXR stereo with headset tracking for the Forever engine.' -ForegroundColor White
        Write-Host '  Keyboard and gamepad remain the driving controls.' -ForegroundColor White
        Write-Host '  Direct setup is quickest. TMLoader adds one-click mod switching' -ForegroundColor White
        Write-Host '  and CoreMod makes the game''s very slow shadow baking much faster.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start setup...')
        $totalSteps = if ($config.Edition -eq 'United') { 6 } else { 5 }

        Write-TMFOXRStep 1 $totalSteps ("Locating " + $config.Title)
        $gameRoot = Find-TMFOXRGameRoot $config
        if (-not $gameRoot) { throw 'Setup cancelled before any game or mod file was changed.' }
        if (Get-Process -Name @('TmForever','TmForeverLauncher','TMLoader') -ErrorAction SilentlyContinue) { throw 'Close TrackMania and TMLoader completely, then run setup again.' }
        Write-TMFOXROK "Found: $gameRoot"

        Write-TMFOXRStep 2 $totalSteps 'Choosing the install route'
        $modeOverride = ('' + $env:PCVR_TMFOXR_INSTALL_MODE).Trim()
        $mode = if ($modeOverride -in @('Direct','TMLoader')) { $modeOverride } else { Select-TMFOXRInstallMode }
        if (-not $mode) { throw 'Setup cancelled before any game or mod file was changed.' }
        Write-TMFOXROK "$mode route selected."

        Write-TMFOXRStep 3 $totalSteps 'Getting the matching current release asset'
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_tmfoxr_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $source = Get-TMFOXRReleaseArchive -Mode $mode -WorkRoot $work
        $extract = Join-Path $work 'release'
        Write-TMFOXRInfo "Extracting $($source.AssetName)."
        $expanded = Expand-ArchiveOrFallback -ArchivePath $source.Archive -DestinationFolder $extract -Label $source.AssetName -AllowSkip $false -QuietProgress
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The TMFOXR release archive was not extracted.' }

        if ($mode -eq 'Direct') {
            $payload = Find-TMFOXRDirectPayload $extract
            if (-not $payload) { throw 'The direct release asset does not contain d3d9.dll, openxr_loader.dll and TMFOXR.defaults.ini together.' }
            Write-TMFOXROK 'Direct TMFOXR payload verified.'
            Write-TMFOXRStep 4 $totalSteps 'Installing recoverably next to TmForever.exe'
            Install-TMFOXRDirect -Config $config -GameRoot $gameRoot -Payload $payload -Version ([string]$source.Tag)
        } else {
            $loaderPayload = Find-TMFOXRLoaderPayload $extract
            if (-not $loaderPayload) { throw 'The TMLoader release asset has no complete TMFOXR product and runtime folder.' }
            Write-TMFOXROK 'TMLoader-specific TMFOXR payload verified.'
            $loaderExe = Ensure-TMLoader -WorkRoot $work
            Write-Host ''
            Write-Host '  Before TMFOXR is added, TMLoader must initialize this game once.' -ForegroundColor White
            Write-Host '  Open TMLoader, select this TrackMania installation, launch the game' -ForegroundColor White
            Write-Host '  once, then close both the game and TMLoader and return here.' -ForegroundColor White
            Write-Host '  If detection needs help: finish any game update, launch through Steam,' -ForegroundColor Gray
            Write-Host '  then check the desktop for TMLoader. Offline Play is below the login fields.' -ForegroundColor Gray
            Write-Host '  The game page has the full first-run troubleshooting sequence.' -ForegroundColor Gray
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open TMLoader for its first game launch...')
            if ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -ne '1') { Start-Process -FilePath $loaderExe -ErrorAction Stop | Out-Null }
            [void](Wait-PCVRExplicitEnter -Message 'After that first launch and after closing TMLoader, press Enter to install TMFOXR...')
            if (Get-Process -Name @('TmForever','TMLoader') -ErrorAction SilentlyContinue) { throw 'TrackMania or TMLoader is still running. Close both and retry setup.' }
            Write-TMFOXRStep 4 $totalSteps 'Installing the TMLoader product recoverably'
            Install-TMFOXRLoader -Config $config -ProductsRoot (Get-TMFOXRProductsRoot) -LoaderPayload $loaderPayload -LoaderExe $loaderExe -Version ([string]$source.Tag)
            Write-Host ''
            Write-Host '  TMFOXR is now in TMLoader''s product database.' -ForegroundColor White
            Write-Host '  Enable TMFOXR for the game. Keep CoreMod enabled too: it is the' -ForegroundColor White
            Write-Host '  declared loader dependency and accelerates shadow computation.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open TMLoader and enable TMFOXR...')
            if ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -ne '1') { Start-Process -FilePath $loaderExe -ErrorAction Stop | Out-Null }
            [void](Wait-PCVRExplicitEnter -Message 'After enabling TMFOXR, close TMLoader and press Enter to continue...')
        }

        Write-TMFOXRStep 5 $totalSteps 'Applying the required TrackMania display settings'
        Write-Host '  Fullscreen: OFF' -ForegroundColor Yellow
        Write-Host '  Advanced > Antialiasing: None' -ForegroundColor Yellow
        Write-Host '  The complete game window must fit inside the monitor''s usable area.' -ForegroundColor Yellow
        Write-Host '  Virtual Desktop: use VDXR. SteamVR: select SteamVR as OpenXR runtime.' -ForegroundColor White
        Write-Host '  TMFOXR v8 currently crashes with Meta Horizon Link; use Steam Link' -ForegroundColor White
        Write-Host '  or Virtual Desktop instead. Unsupported 32-bit OpenXR layers can conflict.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open TrackMania settings...')
        if ((('' + $env:PCVR_TMFOXR_SKIP_EXTERNAL).Trim()) -ne '1') {
            $settingsExe = Join-Path $gameRoot 'TmForeverLauncher.exe'
            if (Test-Path -LiteralPath $settingsExe -PathType Leaf) { Start-Process -FilePath $settingsExe -WorkingDirectory $gameRoot -ErrorAction Stop | Out-Null }
            else { Start-Process -FilePath $gameRoot -ErrorAction Stop | Out-Null }
        }
        $settingsDoneMessage = if ($config.Edition -eq 'United') {
            'After saving the display settings and closing the launcher, press Enter to continue to the optional UVME step...'
        } else {
            'After saving the display settings and closing the launcher, press Enter to finish...'
        }
        [void](Wait-PCVRExplicitEnter -Message $settingsDoneMessage)

        if ($config.Edition -eq 'United') {
            Write-TMFOXRStep 6 $totalSteps 'Optional: UVME HD car interiors and visual extension'
            [void](Invoke-TMFOXRUnitedUVMEOptional)
        }

        Write-Host ''
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Setup complete.' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-TMFOXRCompletionGuidance -Config $config
        Write-Host ''
        Write-Host ("  " + $config.Quip) -ForegroundColor Magenta
        Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        Write-Host ''
        Write-Host ("  [XX] " + $_.Exception.Message) -ForegroundColor Red
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_TMFOXR_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-TMFOXRInstaller -EditionName $Edition }
