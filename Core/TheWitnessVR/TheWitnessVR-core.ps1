# The Witness VR - Discord-package installer.
# The release archive is acquired at run time and is never bundled with Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'The Witness VR Installer'
$APP_ID = '210970'
$GAME_EXE = 'witness64_d3d11.exe'
$MOD_NAME = 'Witness VR Mod'
$MOD_AUTHOR = 'Flat2VR community'
$IDENTITY = 'witnessvr'
$DISCORD_INVITE = 'https://discord.gg/uAeQkYBM4n'
$INFO_POST = 'https://discord.com/channels/747967102895390741/1532163496899248198'
$DOWNLOAD_POST = 'https://discord.com/channels/747967102895390741/1532163496899248198/1544400886166462474'
$PIN_VERSION = 'v1.0.0'
$PIN_NAME = 'TheWitnessVRMod-v1.0.0.zip'
$MOD_DLL_SHA = '68BBFB288E43F5C14FC4612929A3323C244EC9C90330A593408EFECF5C36FC9D'
$RUNTIME_NAME = 'libwinpthread-1.dll'
$RUNTIME_PACKAGE = 'mingw-w64-ucrt-x86_64-libwinpthread-14.0.0.r47.g0636d42e1-1-any.pkg.tar.zst'
$RUNTIME_INFO_URL = 'https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-libwinpthread'
$RUNTIME_URLS = @(
    'https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libwinpthread-14.0.0.r47.g0636d42e1-1-any.pkg.tar.zst',
    'https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libwinpthread-14.0.0.r47.g0636d42e1-1-any.pkg.tar.zst'
)
$QUIP = 'Every panel has an answer. The island never tells you twice.'

function Write-Header {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' The Witness VR - Installer' -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!!] $Text" -ForegroundColor Yellow }
function Wait-FreshEnter {
    param([string]$Text='Press Enter to continue...')

    Write-Host ''
    Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow

    # The Hub starts this script in a child runspace attached to a fresh
    # console. A plain Read-Host can consume Enter that was already waiting in
    # that console and therefore is not a dependable browser gate. Discard all
    # pending keys first, then accept only a newly submitted empty line.
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    while ($true) {
        $answer = '' + (Read-Host)
        if ([string]::IsNullOrWhiteSpace($answer)) { return }
        Write-Warn 'Press Enter by itself to continue.'
    }
}

function Open-WitnessBrowserPage {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Label
    )

    try {
        Start-Process -FilePath $Url -ErrorAction Stop | Out-Null
        Write-OK "$Label was opened in your default browser."
        return
    } catch {
        try {
            Start-Process -FilePath 'explorer.exe' -ArgumentList @($Url) -ErrorAction Stop | Out-Null
            Write-OK "$Label was handed to your default browser."
            return
        } catch {
            Write-Warn "$Label could not be opened automatically."
            Write-Host "      Open this exact address yourself: $Url" -ForegroundColor Cyan
        }
    }
}

function Pause-User { param([string]$Text='Press Enter to continue...') Wait-FreshEnter -Text $Text }
function Get-Sha([string]$Path) { if (Test-Path -LiteralPath $Path -PathType Leaf) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }; return '' }
function Test-GameRoot([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf)) }

function Test-WitnessArchive([string]$Path) {
    return (Test-ZipPayloadAnchors -Path $Path -MinimumMatches 2 -MinimumEntries 2 -MaximumEntries 200 `
        -AnchorPatterns @(
            '(^|\\)witness_vr_mod\\openvr_api_mod\.dll$',
            '(^|\\)witness_vr_mod\\config\.default\.ini$'
        ))
}

function Test-RecognizedArchive([string]$Path) {
    return (Test-DownloadedPayload -Path $Path -IntendedPath $PIN_NAME -Validator { param($Candidate) Test-WitnessArchive $Candidate })
}

function Get-WitnessDownloadFolders {
    $folders = New-Object System.Collections.Generic.List[string]

    # Honour a redirected Windows Downloads known folder first. This covers
    # OneDrive/profile redirection without guessing a fixed location.
    try {
        $shellFolders = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
        $redirected = '' + $shellFolders.'{374DE290-123F-4565-9164-39C4925E467B}'
        if ($redirected) {
            $redirected = [Environment]::ExpandEnvironmentVariables($redirected)
            if (Test-Path -LiteralPath $redirected -PathType Container) { $folders.Add($redirected) }
        }
    } catch {}

    $profile = [Environment]::GetFolderPath('UserProfile')
    if ($profile) {
        $standard = Join-Path $profile 'Downloads'
        if ((Test-Path -LiteralPath $standard -PathType Container) -and -not $folders.Contains($standard)) { $folders.Add($standard) }
    }
    if ($env:OneDrive) {
        $oneDriveDownloads = Join-Path $env:OneDrive 'Downloads'
        if ((Test-Path -LiteralPath $oneDriveDownloads -PathType Container) -and -not $folders.Contains($oneDriveDownloads)) { $folders.Add($oneDriveDownloads) }
    }
    return @($folders)
}

function Find-WitnessDownloadedArchive {
    $stem = [IO.Path]::GetFileNameWithoutExtension($PIN_NAME)
    $extension = [IO.Path]::GetExtension($PIN_NAME)
    $duplicatePattern = '^' + [regex]::Escape($stem) + ' \(\d+\)' + [regex]::Escape($extension) + '$'
    $candidates = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    foreach ($folder in @(Get-WitnessDownloadFolders)) {
        try {
            foreach ($file in @(Get-ChildItem -LiteralPath $folder -Filter '*.zip' -File -ErrorAction SilentlyContinue)) {
                if ($file.Name -eq $PIN_NAME -or $file.Name -match $duplicatePattern) { $candidates.Add($file) }
            }
        } catch {}
    }

    foreach ($candidate in @($candidates | Sort-Object LastWriteTime -Descending)) {
        if (Test-RecognizedArchive $candidate.FullName) { return $candidate.FullName }
    }
    return $null
}

function Copy-VerifiedWitnessArchive([string]$Source,[string]$Destination) {
    if (-not (Test-RecognizedArchive $Source)) { return $false }
    $parent = Split-Path -Parent ([IO.Path]::GetFullPath($Destination))
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $stage = Join-Path $parent ('.pcvr-witness-' + [Guid]::NewGuid().ToString('N') + '.zip')
    try {
        Copy-Item -LiteralPath $Source -Destination $stage -Force -ErrorAction Stop
        if (-not (Test-RecognizedArchive $stage)) { return $false }
        Move-Item -LiteralPath $stage -Destination $Destination -Force -ErrorAction Stop
        $stage = $null
        return $true
    } catch {
        Write-Warn "Could not copy the archive: $($_.Exception.Message)"
        return $false
    } finally {
        if ($stage -and (Test-Path -LiteralPath $stage -PathType Leaf)) { Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue }
    }
}

function Get-WitnessArchive([string]$Destination) {
    Write-Host " Download $PIN_NAME completely, then return to this installer." -ForegroundColor White
    Write-Host ' Press Enter to search your Downloads folders, or drag the' -ForegroundColor Gray
    Write-Host ' downloaded ZIP onto this window and then press Enter.' -ForegroundColor Gray
    $answer = ('' + (Read-Host ' ZIP path / Enter to search Downloads')).Trim()
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        if ($answer) {
            $candidate = $answer.Trim('"').Trim("'")
            if ((Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) -and
                (Copy-VerifiedWitnessArchive -Source $candidate -Destination $Destination)) {
                Write-OK 'The supplied archive contains the recognized Witness VR payload.'
                return $Destination
            }
            Write-Warn 'That file does not contain the recognized Witness VR payload.'
        } else {
            $found = Find-WitnessDownloadedArchive
            if ($found -and (Copy-VerifiedWitnessArchive -Source $found -Destination $Destination)) {
                Write-OK "Found usable archive: $found"
                return $Destination
            }
        }

        Write-Warn "A recognized Witness VR archive was not found in Downloads (attempt $attempt/10)."
        Write-Host "      Expected filename: $PIN_NAME" -ForegroundColor DarkGray
        Write-Host '      Press Enter to scan Downloads again.' -ForegroundColor Gray
        Write-Host '      Or drag the downloaded ZIP onto this window and press Enter.' -ForegroundColor Gray
        Write-Host '      Type O to reopen Discord, or Q to leave without changing the game.' -ForegroundColor Gray
        $answer = ('' + (Read-Host ' ZIP path / Enter / O / Q')).Trim()

        if ($answer.ToUpperInvariant() -eq 'O') {
            Open-WitnessBrowserPage -Url $DOWNLOAD_POST -Label 'The official Discord download post'
            $answer = ''
            continue
        }
        if ($answer.ToUpperInvariant() -eq 'Q') {
            Write-Warn 'Setup was left before any game file was changed.'
            return $null
        }
    }

    Write-Warn 'No usable archive was supplied after 10 attempts. Nothing was changed.'
    return $null
}

function Confirm-Executable([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'The Witness executable is missing.' }
    Write-OK 'The Witness executable was found.'
}

function global:Test-WitnessRuntimeDll([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $bytes = [IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -lt 1024 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $false }
        $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($peOffset -lt 0 -or ($peOffset + 6) -ge $bytes.Length) { return $false }
        if ([BitConverter]::ToUInt32($bytes, $peOffset) -ne 0x00004550) { return $false }
        if ([BitConverter]::ToUInt16($bytes, $peOffset + 4) -ne 0x8664) { return $false }
        $text = [Text.Encoding]::ASCII.GetString($bytes)
        foreach ($symbol in @('pthread_cond_broadcast','pthread_cond_wait','pthread_mutex_destroy','pthread_mutex_init','pthread_mutex_lock','pthread_mutex_unlock','pthread_once')) {
            if ($text.IndexOf($symbol, [StringComparison]::Ordinal) -lt 0) { return $false }
        }
        return $true
    } catch { return $false }
}

function Find-WitnessRuntimeDependency([string]$GameRoot) {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($GameRoot) { $candidates.Add((Join-Path $GameRoot $RUNTIME_NAME)) }
    if ($env:WINDIR) {
        foreach ($relative in @("System32\$RUNTIME_NAME",$RUNTIME_NAME)) {
            $candidates.Add((Join-Path $env:WINDIR $relative))
        }
    }
    foreach ($pathPart in @($env:PATH -split [IO.Path]::PathSeparator)) {
        if (-not [string]::IsNullOrWhiteSpace($pathPart)) {
            try { $candidates.Add((Join-Path $pathPart.Trim().Trim('"') $RUNTIME_NAME)) } catch {}
        }
    }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (Test-WitnessRuntimeDll $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    return $null
}

function Find-ExistingSevenZip {
    $candidates = @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe'
    )
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\7-Zip\7z.exe') }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
    }
    try {
        $command = Get-Command '7z.exe' -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    } catch {}
    return $null
}

function Expand-WitnessRuntimePackage([string]$Package,[string]$Destination) {
    if (-not (Test-Path -LiteralPath $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }
    $expected = Join-Path $Destination 'ucrt64\bin\libwinpthread-1.dll'
    $tar = Get-Command 'tar.exe' -ErrorAction SilentlyContinue
    if ($tar) {
        Write-Info 'Extracting the official MSYS2 runtime package with Windows tar...'
        try {
            & $tar.Source -xf $Package -C $Destination 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $expected -PathType Leaf)) { return $expected }
        } catch {}
    }

    $sevenZip = Find-ExistingSevenZip
    if ($sevenZip) {
        Write-Info 'Extracting the official MSYS2 runtime package with 7-Zip...'
        try {
            $outer = Join-Path $Destination 'outer'
            New-Item -ItemType Directory -Path $outer -Force | Out-Null
            $first = Start-Process -FilePath $sevenZip -ArgumentList 'x','-y','-bso0','-bsp0',"`"$Package`"","-o`"$outer`"" -Wait -PassThru -NoNewWindow
            $tarFile = @(Get-ChildItem -LiteralPath $outer -Filter '*.tar' -File -ErrorAction SilentlyContinue | Select-Object -First 1)[0]
            if ($first.ExitCode -eq 0 -and $tarFile) {
                $second = Start-Process -FilePath $sevenZip -ArgumentList 'x','-y','-bso0','-bsp0',"`"$($tarFile.FullName)`"","-o`"$Destination`"" -Wait -PassThru -NoNewWindow
                if ($second.ExitCode -eq 0 -and (Test-Path -LiteralPath $expected -PathType Leaf)) { return $expected }
            }
        } catch {}
    }
    return $null
}

function Get-WitnessRuntimeDependency([string]$GameRoot,[string]$WorkRoot) {
    $existing = Find-WitnessRuntimeDependency -GameRoot $GameRoot
    if ($existing) {
        Write-OK "Compatible runtime already present: $existing"
        return $existing
    }

    Write-Info "$RUNTIME_NAME is missing; downloading its official MSYS2 UCRT package."
    $packagePath = Join-Path $WorkRoot $RUNTIME_PACKAGE
    $download = Invoke-SafeDownload -Urls @($RUNTIME_URLS) `
        -Destination $packagePath -Label 'MSYS2 winpthreads runtime' -ManualUrl $RUNTIME_INFO_URL `
        -Instructions "Download '$RUNTIME_PACKAGE' from the official MSYS2 page and drag it into this window." `
        -SkipMessage 'The required runtime is mandatory for Witness VR.' -AllowSkip $false
    if ($download -ne $true -and [string]$download -ne 'retry') { throw 'The official MSYS2 runtime package was not supplied.' }

    $extractRoot = Join-Path $WorkRoot 'msys2-runtime'
    $runtime = Expand-WitnessRuntimePackage -Package $packagePath -Destination $extractRoot
    if ($runtime -and (Test-WitnessRuntimeDll $runtime)) {
        Write-OK 'Official MSYS2 x64 UCRT runtime downloaded and extracted.'
        return $runtime
    }

    $manualDll = Join-Path $WorkRoot $RUNTIME_NAME
    $validator = {
        param([string]$Candidate)
        Test-WitnessRuntimeDll $Candidate
    }.GetNewClosure()
    $retry = { & $validator $manualDll }.GetNewClosure()
    $fallback = Invoke-InstallerFallback -Action 'MSYS2 runtime extraction' -Url $RUNTIME_INFO_URL `
        -Instructions "Extract '$RUNTIME_NAME' from ucrt64\bin inside the official package, drag that DLL into this window, then choose Retry." `
        -DestFile $manualDll -FileValidator $validator -RetryCheck $retry -AllowSkip $false `
        -SkipMessage 'The required runtime is mandatory for Witness VR.'
    if ([string]$fallback -eq 'retry' -and (& $validator $manualDll)) { return $manualDll }
    throw 'A usable MSYS2 runtime DLL was not supplied.'
}

function Remove-ExactKnownFile([string]$Path,[string]$Sha) {
    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and (Get-Sha $Path) -eq $Sha) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
    }
}

function Prepare-ExistingInstall([string]$GameRoot) {
    $manifest = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    $live = Join-Path $GameRoot 'openvr_api.dll'
    $parked = Join-Path $GameRoot 'openvr_api.dll.pcvrhub_off'
    $ownedOriginal = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup\openvr_api.dll"
    $manualOriginal = Join-Path $GameRoot 'openvr_api_real.dll'
    $payloadDll = Join-Path $GameRoot 'witness_vr_mod\openvr_api_mod.dll'
    $defaultIni = Join-Path $GameRoot 'witness_vr_mod\config.default.ini'
    $oldMarker = Join-Path $GameRoot 'witness_vr_mod\.installed'
    $wasFlat = $false

    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        if (-not (Test-Path -LiteralPath $live -PathType Leaf)) { throw 'The Hub-managed openvr_api.dll is missing. Use Steam Verify, then reinstall.' }
        if (Test-Path -LiteralPath $parked -PathType Leaf) {
            $row = @(Import-Csv -LiteralPath $manifest | Where-Object RelativePath -eq 'openvr_api.dll' | Select-Object -First 1)[0]
            if (-not $row -or (Get-Sha $parked) -ne [string]$row.InstalledSha256) { throw 'The parked VR proxy differs from the ownership record. Nothing was overwritten.' }
            if (-not (Test-Path -LiteralPath $ownedOriginal -PathType Leaf) -or (Get-Sha $live) -ne (Get-Sha $ownedOriginal)) { throw 'Flat mode is incomplete: the live DLL does not match the preserved original.' }
            Copy-Item -LiteralPath $parked -Destination $live -Force -ErrorAction Stop
            Remove-Item -LiteralPath $parked -Force -ErrorAction Stop
            $wasFlat = $true
            Write-Info 'Your Flat-mode choice was enabled temporarily for this update.'
        }
        return $wasFlat
    }

    $manualEvidence = (Test-Path -LiteralPath $manualOriginal -PathType Leaf) -or (Test-Path -LiteralPath $oldMarker -PathType Leaf)
    if (-not $manualEvidence) {
        if (-not (Test-Path -LiteralPath $live -PathType Leaf)) { throw 'The game original openvr_api.dll is missing. Use Steam Verify, then run setup again.' }
        if (Test-Path -LiteralPath $parked -PathType Leaf) { throw 'A parked proxy exists without a Hub ownership record. Restore or remove that installation first.' }
        return $false
    }

    if (-not (Test-Path -LiteralPath $manualOriginal -PathType Leaf)) { throw 'A manual Witness VR marker exists, but openvr_api_real.dll is missing. Use its original uninstaller or Steam Verify first.' }
    $liveHash = Get-Sha $live
    $parkedHash = Get-Sha $parked
    if ($liveHash -eq $MOD_DLL_SHA) {
        Copy-Item -LiteralPath $manualOriginal -Destination $live -Force -ErrorAction Stop
    } elseif ($parkedHash -eq $MOD_DLL_SHA -and $liveHash -eq (Get-Sha $manualOriginal)) {
        Remove-Item -LiteralPath $parked -Force -ErrorAction Stop
        $wasFlat = $true
    } else {
        throw 'An existing manual proxy could not be proven to be this verified release. Nothing was overwritten.'
    }

    Remove-ExactKnownFile -Path $payloadDll -Sha $MOD_DLL_SHA
    Remove-ExactKnownFile -Path $defaultIni -Sha 'C70F707057B367AC8BBC0996A81E5B079CE4A5274ECC29C3B7CB7DB3D5BC22A8'
    if (Test-Path -LiteralPath $oldMarker -PathType Leaf) {
        $markerText = ''
        try { $markerText = Get-Content -LiteralPath $oldMarker -Raw } catch {}
        if ($markerText -match '(?m)^version=1\.0\.0\s*$' -and $markerText -match [regex]::Escape($MOD_DLL_SHA)) {
            Remove-Item -LiteralPath $oldMarker -Force -ErrorAction Stop
        }
    }
    Write-OK 'Recognized manual v1.0.0 install and migrated it into Hub recovery tracking.'
    return $wasFlat
}

function Restore-FlatChoice([string]$GameRoot,[bool]$WasFlat) {
    if (-not $WasFlat) { return }
    $live = Join-Path $GameRoot 'openvr_api.dll'
    $parked = Join-Path $GameRoot 'openvr_api.dll.pcvrhub_off'
    $original = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup\openvr_api.dll"
    if (-not (Test-Path -LiteralPath $live -PathType Leaf) -or -not (Test-Path -LiteralPath $original -PathType Leaf)) { throw 'Cannot restore the previous Flat-mode state because a required DLL is missing.' }
    if (Test-Path -LiteralPath $parked) { throw 'Cannot restore Flat mode because both active and parked VR proxy files exist.' }
    Copy-Item -LiteralPath $live -Destination $parked -Force -ErrorAction Stop
    Copy-Item -LiteralPath $original -Destination $live -Force -ErrorAction Stop
}

function Write-SuccessState([string]$GameRoot) {
    $encoding = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$GameRoot,$encoding)
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),$PIN_VERSION,$encoding)
    Save-InstalledStamp -GameDir $GameRoot -Version $PIN_VERSION -HubDir $PSScriptRoot
}

$work = $null
$gamePath = $null
$restoreFlat = $false
try {
    Write-Header
    Write-Host ' This setup extends The Witness native -vr mode with smooth' -ForegroundColor White
    Write-Host ' locomotion, snap turning and natural puzzle interaction.' -ForegroundColor White
    Write-Host ' Steam 64-bit DirectX 11 is supported; Epic remains untested.' -ForegroundColor Yellow
    Write-Host ' A Flat2VR Discord account is required to get the package.' -ForegroundColor Gray
    Write-Host ' Nothing opens automatically: every browser action has its own' -ForegroundColor Gray
    Write-Host ' fresh Enter confirmation.' -ForegroundColor Gray
    Show-AntivirusNotice

    Write-Step 1 5 'Joining the Flat2VR Discord'
    Write-Host ' Join the server in your signed-in browser, then return here.' -ForegroundColor White
    Write-Host " Invite: $DISCORD_INVITE" -ForegroundColor DarkGray
    Wait-FreshEnter 'Press Enter to open the Flat2VR Discord invite.'
    Open-WitnessBrowserPage -Url $DISCORD_INVITE -Label 'The Flat2VR Discord invite'

    Write-Step 2 5 'Downloading the Discord release'
    Write-Host ' The mod archive is a Discord attachment and cannot be fetched' -ForegroundColor White
    Write-Host ' automatically. The installer will open only this exact post.' -ForegroundColor White
    Write-Host " Download post: $DOWNLOAD_POST" -ForegroundColor DarkGray
    Wait-FreshEnter 'After joining, press Enter to open the download post.'
    Open-WitnessBrowserPage -Url $DOWNLOAD_POST -Label 'The official Discord download post'

    $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_witness_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $archive = Get-WitnessArchive -Destination (Join-Path $work $PIN_NAME)
    if (-not $archive) { throw 'A usable Witness VR archive was not supplied.' }
    Write-OK "$PIN_NAME passed the safe archive and payload checks."

    Write-Step 3 5 'Locating The Witness'
    $gamePath = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('The Witness') -ProbeExe $GAME_EXE -EpicNames @('TheWitness','The Witness')
    if (-not (Test-GameRoot $gamePath)) {
        $picked = Get-GameFolderInteractive -GameName 'The Witness' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/210970/'
        if ($picked -in @('quit','skip',$null) -or -not (Test-GameRoot $picked)) { throw 'Setup cancelled before any game file was changed.' }
        $gamePath = (Get-Item -LiteralPath $picked).FullName
    }
    if (@(Get-Process -Name 'witness64_d3d11' -ErrorAction SilentlyContinue).Count) { throw 'The Witness is running. Close it completely and run setup again.' }
    Write-OK "Found: $gamePath"
    Confirm-Executable (Join-Path $gamePath $GAME_EXE)

    Write-Step 4 5 'Installing with recovery data'
    $extract = Join-Path $work 'extracted'
    $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Witness VR archive' -AllowSkip $false
    if ([string]$expanded -notin @('ok','manual','retry') -or -not (Test-WitnessArchive $archive)) { throw 'The Witness VR archive was not extracted safely.' }
    $sourceMod = Join-Path $extract 'witness_vr_mod'
    $sourceDll = Join-Path $sourceMod 'openvr_api_mod.dll'
    $sourceDefault = Join-Path $sourceMod 'config.default.ini'
    if (-not (Test-DownloadedPayload -Path $sourceDll -IntendedPath 'openvr_api_mod.dll') -or (Get-Item -LiteralPath $sourceDll).Length -lt 65536) {
        throw 'The extracted VR DLL is not a recognizable Windows mod binary.'
    }

    # The Discord release imports this DLL but omits it. Reuse a compatible
    # x64 copy when one is already resolvable; otherwise fetch the pinned
    # UCRT build directly from MSYS2 and verify both package and DLL before
    # any existing game file is prepared or replaced.
    $runtimeDependency = Get-WitnessRuntimeDependency -GameRoot $gamePath -WorkRoot $work

    # The proxy imports the game's original OpenVR loader under this exact
    # runtime name.  Prepare the previous install first so $liveOriginal is
    # guaranteed to be the real game DLL (or its Hub-owned backup), never the
    # mod proxy.  The alias itself is then owned by the manifest and can be
    # removed safely during uninstall.
    $restoreFlat = Prepare-ExistingInstall -GameRoot $gamePath
    $liveOriginal = Join-Path $gamePath ".pcvrhub_${IDENTITY}_backup\openvr_api.dll"
    if (-not (Test-Path -LiteralPath $liveOriginal -PathType Leaf)) {
        $liveOriginal = Join-Path $gamePath 'openvr_api.dll'
    }
    if (-not (Test-Path -LiteralPath $liveOriginal -PathType Leaf) -or (Get-Sha $liveOriginal) -eq (Get-Sha $sourceDll)) {
        throw 'The original game openvr_api.dll could not be proven before installing its required runtime alias.'
    }

    $payload = Join-Path $work 'payload'
    $payloadMod = Join-Path $payload 'witness_vr_mod'
    New-Item -ItemType Directory -Path $payloadMod -Force | Out-Null
    Copy-Item -LiteralPath $sourceDll -Destination (Join-Path $payload 'openvr_api.dll') -Force -ErrorAction Stop
    Copy-Item -LiteralPath $liveOriginal -Destination (Join-Path $payload 'openvr_api_real.dll') -Force -ErrorAction Stop
    Copy-Item -LiteralPath $sourceDll -Destination (Join-Path $payloadMod 'openvr_api_mod.dll') -Force -ErrorAction Stop
    Copy-Item -LiteralPath $sourceDefault -Destination (Join-Path $payloadMod 'config.default.ini') -Force -ErrorAction Stop
    $runtimePayload = Join-Path $payload $RUNTIME_NAME
    Copy-Item -LiteralPath $runtimeDependency -Destination $runtimePayload -Force -ErrorAction Stop
    if (-not (Test-WitnessRuntimeDll $runtimePayload)) { throw 'The staged winpthreads runtime failed compatibility validation.' }

    $configDir = Join-Path $gamePath 'witness_vr_mod'
    $configPath = Join-Path $configDir 'config.ini'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Copy-Item -LiteralPath $sourceDefault -Destination $configPath -Force -ErrorAction Stop
        Write-OK 'Created witness_vr_mod\config.ini.'
    } else { Write-OK 'Existing witness_vr_mod\config.ini preserved.' }
    Install-OwnedModPayload -SourceRoot $payload -GameRoot $gamePath -Identity $IDENTITY | Out-Null

    Write-Step 5 5 'Verifying files and saving recovery data'
    $watch = @(
        (Join-Path $gamePath 'openvr_api.dll'),
        (Join-Path $gamePath 'openvr_api_real.dll'),
        (Join-Path $gamePath 'witness_vr_mod\openvr_api_mod.dll'),
        (Join-Path $gamePath 'witness_vr_mod\config.default.ini'),
        (Join-Path $gamePath $RUNTIME_NAME),
        (Join-Path $gamePath ".pcvrhub_${IDENTITY}_ownership.csv"),
        (Join-Path $gamePath ".pcvrhub_${IDENTITY}_backup\openvr_api.dll")
    )
    foreach ($path in $watch) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Installation verification failed: $(Split-Path -Leaf $path) is missing." } }
    $recopy = {
        $recovery = Join-Path $gamePath ('.pcvrhub_witnessvr_recovery_' + [Guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $recovery -Force | Out-Null
            $insideZip = Join-Path $recovery $PIN_NAME
            Copy-Item -LiteralPath $archive -Destination $insideZip -Force -ErrorAction Stop
            $insideOut = Join-Path $recovery 'files'
            [IO.Compression.ZipFile]::ExtractToDirectory($insideZip,$insideOut)
            $insideDll = Join-Path $insideOut 'witness_vr_mod\openvr_api_mod.dll'
            Copy-Item -LiteralPath $insideDll -Destination (Join-Path $gamePath 'openvr_api.dll') -Force -ErrorAction Stop
            Copy-Item -LiteralPath (Join-Path $payload 'openvr_api_real.dll') -Destination (Join-Path $gamePath 'openvr_api_real.dll') -Force -ErrorAction Stop
            Copy-Item -LiteralPath $insideDll -Destination (Join-Path $gamePath 'witness_vr_mod\openvr_api_mod.dll') -Force -ErrorAction Stop
            Copy-Item -LiteralPath (Join-Path $insideOut 'witness_vr_mod\config.default.ini') -Destination (Join-Path $gamePath 'witness_vr_mod\config.default.ini') -Force -ErrorAction Stop
            Copy-Item -LiteralPath $runtimePayload -Destination (Join-Path $gamePath $RUNTIME_NAME) -Force -ErrorAction Stop
        } finally {
            if (Test-Path -LiteralPath $recovery) { Remove-Item -LiteralPath $recovery -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }.GetNewClosure()
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch[0..4] -GameDir $gamePath -Recopy $recopy)) { throw 'One or more required VR files did not survive the antivirus check.' }

    if ($restoreFlat) {
        Restore-FlatChoice -GameRoot $gamePath -WasFlat $true
        $restoreFlat = $false
        Write-Info 'Your previous Flat-mode choice was preserved.'
    }
    Write-SuccessState -GameRoot $gamePath
    Write-OK "$MOD_NAME $PIN_VERSION is installed and will be detected as VR Ready."

    Write-Host ''
    Write-Host ' STARTING THE GAME' -ForegroundColor Cyan
    Write-Host ' Start SteamVR, then use Start in VR in the Hub. The Hub' -ForegroundColor White
    Write-Host ' passes -vr automatically. Steam users can alternatively add' -ForegroundColor Gray
    Write-Host ' -vr to Steam launch options and launch there.' -ForegroundColor Gray
    Write-Host ' Epic has not been tested; Locate game can assign its EXE.' -ForegroundColor Gray
    Write-Host ''
    Write-Host ' Tune resolution, turning and subtitles in:' -ForegroundColor White
    Write-Host ' witness_vr_mod\config.ini' -ForegroundColor Cyan
    Write-Host ''
    Write-Host " $QUIP" -ForegroundColor Magenta
} catch {
    Write-Host ''
    Write-Host " [X] $($_.Exception.Message)" -ForegroundColor Red
    throw
} finally {
    if ($restoreFlat -and $gamePath) {
        try { Restore-FlatChoice -GameRoot $gamePath -WasFlat $true } catch { Write-Warn 'Setup could not restore the previous Flat-mode state. Use the Hub switch after reviewing the two proxy files.' }
    }
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Pause-User 'Press Enter to exit...'
