# Warhammer 40,000: Darktide VR - governed GitHub prerelease installer.
# Steam App 1361210; Darktide Mod Loader and DMF are shared dependencies;
# the VR package owns only mods\darktidevr. The publisher's mode tool owns
# executable/proxy/load-order recovery and is always run in a child process.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Warhammer 40K: Darktide VR Installer'
$APP_ID = '1361210'
$GAME_EXE = 'binaries\Darktide.exe'
$REPO = 'Brobert-in-aus/darktide-vr'
$RELEASES = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'v0.3.0-alpha.2'
$FALLBACK_NAME = 'darktidevr-0.3.0-alpha.2-4efdd3369405.zip'
$FALLBACK_URL = 'https://github.com/Brobert-in-aus/darktide-vr/releases/download/v0.3.0-alpha.2/darktidevr-0.3.0-alpha.2-4efdd3369405.zip'
$LOADER_REPO = 'Darktide-Mod-Framework/Darktide-Mod-Loader'
$DMF_COMMIT = 'fc08c1cb772f86248c7ae9e957543e801a0dbf64'
$DMF_URL = 'https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework/archive/fc08c1cb772f86248c7ae9e957543e801a0dbf64.zip'
$DARKTIDE_RECEIPT_ROOT=$PSScriptRoot
$IDENTITY = 'darktidevr'
$QUIP = 'The Emperor protects, but the hands still have to aim.'
$contract = New-PCVRInstallerContract -Id 'warhammer-40k-darktide-vr' `
    -GameName 'Warhammer 40K: Darktide VR' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @(
        'mods\darktidevr\bin\darktidevr_native_capture.dll',
        'mods\darktidevr\bin\darktidevr-xr-harness.exe',
        'mods\darktidevr\darktidevr-mode.ps1',
        'mods\dmf\dmf.mod','tools\dtkit-patch.exe','binaries\d3d12.dll',
        '.pcvrhub_darktidevr_ownership.csv'
    )
function Write-DarkStep([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-DarkOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-DarkInfo([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }
function Write-DarkWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Test-DarktideRoot([string]$Path) {
    if (-not (Test-PCVRGameInstallProof -GameId 'warhammer-40k-darktide-vr' -Root $Path)) { return $false }

    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'binaries\Darktide.exe') -PathType Leaf))
}
function Test-DarktideLoader([string]$GameRoot) {
    return [bool]((Test-Path -LiteralPath (Join-Path $GameRoot 'binaries\mod_loader') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $GameRoot 'tools\dtkit-patch.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $GameRoot 'mods\mod_load_order.txt') -PathType Leaf))
}
function Test-DarktideFramework([string]$GameRoot) {
    return [bool](Test-Path -LiteralPath (Join-Path $GameRoot 'mods\dmf\dmf.mod') -PathType Leaf)
}
function Find-DarktideVrPayload([string]$ExtractRoot) {
    $marker = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'darktidevr.mod' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'darktidevr' } | Select-Object -First 1
    if (-not $marker) { return $null }
    return (Split-Path -Parent (Split-Path -Parent $marker.DirectoryName))
}
function Find-DarktideLoaderPayload([string]$ExtractRoot) {
    $marker = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'mod_loader' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'binaries' } | Select-Object -First 1
    if (-not $marker) { return $null }
    return (Split-Path -Parent $marker.DirectoryName)
}
function Find-DarktideFrameworkPayload([string]$ExtractRoot) {
    $marker = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'dmf.mod' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'dmf' } | Select-Object -First 1
    if ($marker) { return $marker.DirectoryName }
    return $null
}

function Resolve-DarktideLoaderDownload {
    param($ReleaseData = $null)
    $page = "https://github.com/$LOADER_REPO/releases"
    try {
        $releases = $ReleaseData
        if ($null -eq $releases) {
            # This publisher posts full ZIPs as release-body attachments.
            # Read the public stable release itself; no API token is needed.
            $reply=Get-PCVRGitHubText -Uri ($page+'/latest')
            $tag=''
            if ($reply.FinalUrl -match '/releases/tag/([^/?#]+)') { $tag=[uri]::UnescapeDataString($Matches[1]) }
            elseif ($reply.Content -match '<meta\s+property="og:url"\s+content="[^" ]+/releases/tag/([^"/?#]+)"') { $tag=[Net.WebUtility]::HtmlDecode([uri]::UnescapeDataString($Matches[1])) }
            if (-not $tag) { throw 'The current Mod Loader release tag could not be read.' }
            $releases=@([pscustomobject]@{draft=$false;tag_name=$tag;published_at='';html_url=($page+'/tag/'+[uri]::EscapeDataString($tag));body=[string]$reply.Content})
        }
        $release = @($releases | Where-Object { $_ -and -not [bool]$_.draft } | Sort-Object published_at -Descending)[0]
        if ($release) {
            $body = [Net.WebUtility]::HtmlDecode([string]$release.body)
            $match = [regex]::Match($body,'https://github\.com/user-attachments/files/[^\s\)\]"'']+/Darktide-Mod-Loader\.zip','IgnoreCase')
            if ($match.Success) {
                return [pscustomobject]@{ Url=$match.Value; Tag=[string]$release.tag_name; PageUrl=[string]$release.html_url; Resolved=$true }
            }
        }
    } catch { throw ('The current Darktide Mod Loader could not be checked on its official release page. Use Retry or its full release ZIP. '+$_.Exception.Message) }
    throw 'The current Darktide Mod Loader release has no full installation ZIP. Use Retry or hand over its official full ZIP.'
}

function Get-DarktideVrRelease {
    return Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true -AssetPatterns @('(?i)^darktidevr[-_.].*\.zip$') `
        -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_NAME
}

function Get-DarktideLoaderRelease {
    param($ReleaseData=$null)
    return Resolve-DarktideLoaderDownload -ReleaseData $ReleaseData
}

function Test-DarktideWasActive([string]$GameRoot) {
    $loadOrder = Join-Path $GameRoot 'mods\mod_load_order.txt'
    $listed = $false
    try { $listed = [bool](Get-Content -LiteralPath $loadOrder -ErrorAction Stop | Where-Object { $_.Trim() -eq 'darktidevr' }) } catch {}
    return [bool]($listed -and (Test-Path -LiteralPath (Join-Path $GameRoot 'binaries\d3d12.dll') -PathType Leaf))
}
function Invoke-DarktideNativeTool {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList=@(),
        [Parameter(Mandatory=$true)][string]$FailureMessage,
        [switch]$IgnoreFailure,
        $OutputLines
    )
    $resolvedPath=$null
    if (Test-Path -LiteralPath $FilePath -PathType Leaf) {
        $resolvedPath=(Get-Item -LiteralPath $FilePath -ErrorAction Stop).FullName
    } else {
        $command=Get-Command $FilePath -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $resolvedPath=$command.Source }
    }
    if (-not $resolvedPath) {
        if ($IgnoreFailure) { return $false }
        throw "$FailureMessage (publisher tool was not found)."
    }

    $previousPreference=$ErrorActionPreference
    $nativeOutput=@(); $nativeExitCode=$null; $invocationFailure=$null
    try {
        # Windows PowerShell 5 turns native stderr into ErrorRecord objects. Some
        # Darktide publisher tools print successful status there, so only their
        # process exit code may decide whether the transaction failed.
        $ErrorActionPreference='Continue'
        $global:LASTEXITCODE=$null
        try {
            $nativeOutput=@(& $resolvedPath @ArgumentList 2>&1)
            $nativeExitCode=$global:LASTEXITCODE
        } catch {
            $invocationFailure=$_.Exception.Message
        }
    } finally {
        $ErrorActionPreference=$previousPreference
    }
    if ($OutputLines) { $OutputLines.Value=@($nativeOutput | ForEach-Object { [string]$_ }) }
    foreach ($entry in @($(if (-not $OutputLines) { $nativeOutput }))) {
        $line=[string]$entry
        if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Host ('  '+$line.TrimEnd()) -ForegroundColor Gray }
    }

    if ($invocationFailure -or $null -eq $nativeExitCode -or [int]$nativeExitCode -ne 0) {
        if ($IgnoreFailure) { return $false }
        if ($invocationFailure) { throw "$FailureMessage ($invocationFailure)" }
        if ($null -eq $nativeExitCode) { throw "$FailureMessage (publisher tool returned no exit code)." }
        throw "$FailureMessage (exit code $nativeExitCode)."
    }
    return $true
}
function global:Invoke-DarktideMode([string]$GameRoot,[ValidateSet('vr','flat','status')][string]$Mode,[string]$StateRoot='',[switch]$IgnoreFailure,[string]$SourceRoot='',$OutputLines) {
    # During an update, the installed mode tool can predate the current game
    # executable. Use the complete freshly extracted publisher toolset while
    # retaining the actual game and its existing recovery/settings location.
    $toolRoot=if ($SourceRoot) { $SourceRoot } else { $GameRoot }
    $scriptPath = Join-Path $toolRoot 'mods\darktidevr\darktidevr-mode.ps1'
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        if ($IgnoreFailure) { return $false }
        throw 'The DarktideVR mode script is missing.'
    }
    $oldLocalAppData=$env:LOCALAPPDATA
    try {
        if ($StateRoot) {
            if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) { [void][IO.Directory]::CreateDirectory($StateRoot) }
            $env:LOCALAPPDATA=(Get-Item -LiteralPath $StateRoot).FullName
        }
        return [bool](Invoke-DarktideNativeTool -FilePath 'powershell.exe' `
            -ArgumentList @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath,'-Mode',$Mode,'-GameRoot',$GameRoot) `
            -FailureMessage "The publisher's Darktide $Mode mode switch failed" -IgnoreFailure:$IgnoreFailure -OutputLines $OutputLines)
    } finally {
        $env:LOCALAPPDATA=$oldLocalAppData
    }
}
function Assert-DarktidePublisherBuild([string]$GameRoot,[string]$SourceRoot,[string]$StateRoot,[string]$Version) {
    $statusLines=@()
    $patchTool=Join-Path $SourceRoot 'mods\darktidevr\tools\set-skinner-assert-patch.ps1'
    $inspectionBackup=Join-Path $SourceRoot '.pcvr-inspection\unused.exe'
    [void](Invoke-DarktideNativeTool -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$patchTool,'-Action','Inspect','-GameExe',(Join-Path $GameRoot 'binaries\Darktide.exe'),'-Backup',$inspectionBackup) -FailureMessage 'The publisher could not inspect this Darktide executable' -OutputLines ([ref]$statusLines))
    $state=@($statusLines | Where-Object { $_ -match '^state=' } | Select-Object -First 1)
    if ($state.Count -ne 1 -or $state[0] -notmatch '^state=(original|patched)$') {
        throw "DarktideVR $Version does not support your installed game executable. Setup has not changed the game. Wait for a DarktideVR release that supports the current online game. Older game builds cannot sign in."
    }
    Write-DarkOK 'The publisher patcher supports this game executable.'
}

function Add-DarktideHubMeleePatch([string]$Payload, [string]$Version) {
    if ($Version.TrimStart('v','V') -ne '0.3.0-alpha.2') { return }
    $scriptFolder = 'mods\darktidevr\scripts\mods\darktidevr'
    $baseScripts = [ordered]@{
        'darktidevr.lua' = '37b216e05826fed93ae70f0c04f06119658bafbe7c427783531bf7aa48c4e9be'
        'darktidevr_data.lua' = '811977cfae8e2d72f6575e0d4ad5c57db8ae08e6124f321816ef028446146afd'
        'darktidevr_localization.lua' = 'cec3e4b875c4b64093634a17eb94aefd3b327d6a5e1e66c32b3455f87ddf7087'
    }
    # These replacements target specific upstream scripts. A mismatch skips
    # the optional patch and leaves the normal publisher install available.
    foreach ($name in $baseScripts.Keys) {
        $path = Join-Path (Join-Path $Payload $scriptFolder) $name
        if (-not [IO.File]::Exists($path) -or (Get-FileHash -LiteralPath $path).Hash -ne $baseScripts[$name]) {
            Write-DarkInfo 'The optional Hub melee patch does not match these publisher scripts.'
            return
        }
    }
    Write-Host '  Optional Hub patch: swing your controller to melee and touch to interact.' -ForegroundColor Cyan
    Write-Host '  The add-on includes a build-specific experimental crash workaround.'
    if ((Read-Host '  Install the optional melee patch? [y/N]') -notmatch '^\s*y(es)?\s*$') { return }

    $manifestPath = Join-Path $Payload 'mods\darktidevr\package-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $patchFiles = @($baseScripts.Keys) + @('darktidevr_melee_swing.lua')
    foreach ($name in $patchFiles) {
        $relative = Join-Path $scriptFolder $name
        $path = Join-Path $Payload $relative
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('MeleeSwingPatch\'+$name)) -Destination $path -Force
        $manifestRelative = $relative.Replace('\','/')
        $manifest.files = @($manifest.files | Where-Object path -ne $manifestRelative) + @(
            [pscustomobject]@{path=$manifestRelative; bytes=(Get-Item -LiteralPath $path).Length; sha256=(Get-FileHash -LiteralPath $path).Hash}
        )
    }
    $manifest.source_dirty = $true
    $manifest | Add-Member -NotePropertyName hub_addon -NotePropertyValue 'Optional Hub melee swing patch' -Force
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
    Write-DarkInfo 'The optional Hub melee patch is ready to install.'
    foreach ($name in $patchFiles) { Join-Path $scriptFolder $name }
}

function Save-DarktideSnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $records = @()
    foreach ($relative in @('mods\darktidevr','.pcvrhub_darktidevr_ownership.csv','.pcvrhub_darktidevr_backup','.pcvrhub_version')) {
        $source = Join-Path $GameRoot $relative
        $exists = Test-Path -LiteralPath $source
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists; IsDirectory=(Test-Path -LiteralPath $source -PathType Container) }
        if ($exists) { Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot ([IO.Path]::GetFileName($relative))) -Recurse -Force }
    }
    return $records
}
function Restore-DarktideSnapshot([string]$GameRoot,[string]$SnapshotRoot,$Records) {
    if (-not (Test-DarktideRoot $GameRoot)) { throw 'Rollback target is no longer a verified Darktide folder.' }
    foreach ($record in @($Records)) {
        $target = Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            $source = Join-Path $SnapshotRoot ([IO.Path]::GetFileName([string]$record.Relative))
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
        }
    }
}

function global:Invoke-DarktideVRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $snapshotRecords=$null; $changesStarted=$false; $wasActive=$false
    $stateRoot=''
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Warhammer 40K: Darktide VR - Installer' -ForegroundColor Cyan
        Write-Host '  Installs: DarktideVR by Brobert-in-aus' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Native OpenXR VR with roomscale tracking,' -ForegroundColor White
        Write-Host '  tracked hands, hand-aimed weapons and controller menus.' -ForegroundColor White
        Write-Host '  Darktide Mod Loader and DMF are required; setup adds' -ForegroundColor Yellow
        Write-Host '  missing framework pieces and enables VR mode.' -ForegroundColor Yellow
        Write-Host '  A Darktide update can disable the loader or temporarily' -ForegroundColor Yellow
        Write-Host '  become unsupported until DarktideVR is updated.' -ForegroundColor Yellow
        Write-Host '  Setup patches the game executable with the publisher tool;' -ForegroundColor Gray
        Write-Host '  its pristine recovery copy and separate flat/VR settings remain.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  Installs the newest DarktideVR release for your current online game.' -ForegroundColor White
        Write-Host '  An internet connection and a supported current game build are required.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        Write-DarkStep 1 5 'Locating Warhammer 40,000: Darktide'
        $game = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Warhammer 40,000 DARKTIDE') -ProbeExe $GAME_EXE -HubGameId 'warhammer-40k-darktide-vr'
        if (-not (Test-DarktideRoot $game)) {
            foreach ($candidate in @('C:\XboxGames\Warhammer 40,000- Darktide\Content')) {
                if (Test-DarktideRoot $candidate) { $game=$candidate; break }
            }
        }
        if (-not (Test-DarktideRoot $game)) {
            $game = Get-GameFolderInteractive -GameName 'Warhammer 40,000 DARKTIDE' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/1361210/'
        }
        if ($game -in @('quit','skip',$null) -or -not (Test-DarktideRoot $game)) { throw 'Setup cancelled before any game file was changed.' }
        $game=(Get-Item -LiteralPath $game).FullName
        if (Get-Process -Name Darktide -ErrorAction SilentlyContinue) { throw 'Darktide is running. Close it completely and run setup again.' }
        Write-DarkOK "Found: $game"

        Write-DarkStep 2 5 'Getting the newest DarktideVR release, including prereleases'
        $release = Get-DarktideVrRelease
        Write-DarkInfo "Release: $($release.Tag)"
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_darktidevr_'+[Guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'darktidevr.zip'
        $got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "DarktideVR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The DarktideVR release was not downloaded.' }
        $extract=Join-Path $work 'vr'; $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'DarktideVR release' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The DarktideVR archive could not be extracted.' }
        $vrPayload=Find-DarktideVrPayload $extract
        if (-not $vrPayload -or -not (Test-Path -LiteralPath (Join-Path $vrPayload 'mods\darktidevr\bin\darktidevr_native_capture.dll') -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $vrPayload 'mods\darktidevr\bin\darktidevr-xr-harness.exe') -PathType Leaf)) {
            throw 'The current release has no usable DarktideVR runtime payload.'
        }

        Assert-DarktidePublisherBuild -GameRoot $game -SourceRoot $vrPayload -StateRoot $stateRoot -Version ([string]$release.Tag)
        $meleePatchFiles = @(Add-DarktideHubMeleePatch -Payload $vrPayload -Version ([string]$release.Tag))
        Write-DarkStep 3 5 'Ensuring the shared Darktide loader and framework'
        if (-not (Test-DarktideLoader $game)) {
            $loader=Get-DarktideLoaderRelease; Write-DarkInfo "Darktide Mod Loader: $($loader.Tag)"
            $loaderArchive=Join-Path $work 'loader.zip'
            $gotLoader=Invoke-SafeDownload -Urls @([string]$loader.Url) -Destination $loaderArchive -Label "Darktide Mod Loader $($loader.Tag)" -ManualUrl ([string]$loader.PageUrl) -AllowSkip $false
            if (-not ($gotLoader -eq $true -or [string]$gotLoader -in @('retry','manual'))) { throw 'The Darktide Mod Loader was not downloaded.' }
            $loaderExtract=Join-Path $work 'loader'; $x=Expand-ArchiveOrFallback -ArchivePath $loaderArchive -DestinationFolder $loaderExtract -Label 'Darktide Mod Loader' -AllowSkip $false
            if ([string]$x -notin @('ok','manual','retry')) { throw 'The Darktide Mod Loader archive could not be extracted.' }
            $loaderPayload=Find-DarktideLoaderPayload $loaderExtract
            if (-not $loaderPayload) { throw 'The current loader package has no binaries\mod_loader runtime.' }
            [void](Install-OwnedModPayload -SourceRoot $loaderPayload -GameRoot $game -Identity 'darktidevr_loader' -KeepExistingRelativePaths @('mods\mod_load_order.txt'))
            Write-DarkOK 'Missing Darktide Mod Loader files installed; existing load order preserved.'
        } else { Write-DarkOK 'Existing functional Darktide Mod Loader preserved.' }
        if (-not (Test-DarktideFramework $game)) {
            $dmfArchive=Join-Path $work 'dmf.zip'; $gotDmf=Invoke-SafeDownload -Urls @($DMF_URL) -Destination $dmfArchive -Label 'Darktide Mod Framework' -ManualUrl 'https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework' -AllowSkip $false
            if (-not ($gotDmf -eq $true -or [string]$gotDmf -in @('retry','manual'))) { throw 'Darktide Mod Framework was not downloaded.' }
            $dmfExtract=Join-Path $work 'dmf'; $x=Expand-ArchiveOrFallback -ArchivePath $dmfArchive -DestinationFolder $dmfExtract -Label 'Darktide Mod Framework' -AllowSkip $false
            if ([string]$x -notin @('ok','manual','retry')) { throw 'Darktide Mod Framework could not be extracted.' }
            $dmfPayload=Find-DarktideFrameworkPayload $dmfExtract
            if (-not $dmfPayload) { throw 'The framework package has no dmf\dmf.mod payload.' }
            $dmfStage=Join-Path $work 'dmf-stage\mods\dmf'; [void][IO.Directory]::CreateDirectory($dmfStage); Copy-DirectoryTreeVerified -Source $dmfPayload -Destination $dmfStage
            [void](Install-OwnedModPayload -SourceRoot (Join-Path $work 'dmf-stage') -GameRoot $game -Identity 'darktidevr_dmf')
            Write-DarkOK 'Darktide Mod Framework installed.'
        } else { Write-DarkOK 'Existing Darktide Mod Framework preserved.' }
        if (-not (Test-DarktideLoader $game) -or -not (Test-DarktideFramework $game)) { throw 'Shared Darktide dependencies are incomplete after setup.' }

        Write-DarkStep 4 5 'Installing the VR runtime and activating VR mode'
        Write-Host '  The publisher patchers now enable mod loading and Darktide VR.' -ForegroundColor White
        Write-Host '  Darktide must stay closed. Windows may request permission because' -ForegroundColor Yellow
        Write-Host '  the game folder and executable are being changed recoverably.' -ForegroundColor Yellow
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the two required publisher patchers...')
        $wasActive=Test-DarktideWasActive $game
        $snapshot=Join-Path $work 'rollback'; $snapshotRecords=Save-DarktideSnapshot -GameRoot $game -SnapshotRoot $snapshot
        $changesStarted=$true
        if ($wasActive) { [void](Invoke-DarktideMode -GameRoot $game -Mode flat -StateRoot $stateRoot -SourceRoot $vrPayload) }
        [void](Install-OwnedModPayload -SourceRoot $vrPayload -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting)
        $patcher=Join-Path $game 'tools\dtkit-patch.exe'
        [void](Invoke-DarktideNativeTool -FilePath $patcher -ArgumentList @('--patch',(Join-Path $game 'bundle')) `
            -FailureMessage 'The Darktide Mod Loader bundle patch failed')
        [void](Invoke-DarktideMode -GameRoot $game -Mode vr -StateRoot $stateRoot)
        $watch=(@('mods\darktidevr\bin\darktidevr_native_capture.dll','mods\darktidevr\bin\darktidevr-xr-harness.exe','binaries\d3d12.dll') + $meleePatchFiles) | ForEach-Object { Join-Path $game $_ }
        $recopy={ [void](Install-OwnedModPayload -SourceRoot $vrPayload -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting); [void](Invoke-DarktideMode -GameRoot $game -Mode vr -StateRoot $stateRoot) }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recopy)) { throw 'Required DarktideVR runtime files did not survive antivirus recovery.' }

        Write-DarkStep 5 5 'Verifying the tracked store launch route'
        $receipt=Join-Path $DARKTIDE_RECEIPT_ROOT '.installed_path'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version ([string]$release.Tag) -InstalledPathReceiptPaths @($receipt) -Route 'Current')
        $changesStarted=$false
        Write-DarkOK "DarktideVR $($release.Tag) is active and tracked."
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor White
            Write-Host '  For Steam, the Hub opens Steam; press Play in the Fatshark launcher.' -ForegroundColor White
        Write-Host '  Calibrate the two-pose body height when prompted; mod options contain' -ForegroundColor Gray
        Write-Host '  turning, HUD, aim-pitch and experimental keyboard/mouse settings.' -ForegroundColor Gray
        Write-Host ''
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host '  Setup complete.' -ForegroundColor Green; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot) {
            try {
                [void](Invoke-DarktideMode -GameRoot $game -Mode flat -StateRoot $stateRoot -IgnoreFailure)
                [void](Uninstall-OwnedModPayload -GameRoot $game -Identity $IDENTITY)
                Restore-DarktideSnapshot -GameRoot $game -SnapshotRoot $snapshot -Records $snapshotRecords
                $modeRestored=if ($wasActive) { Invoke-DarktideMode -GameRoot $game -Mode vr -StateRoot $stateRoot -IgnoreFailure } else { $true }
                if ($modeRestored) { Write-DarkWarn 'The prior DarktideVR package and mode were restored.' }
                else { Write-DarkWarn 'The prior DarktideVR files were restored. Its old mode tool cannot enable this game build; VR mode was not confirmed.' }
            } catch { Write-DarkWarn "Rollback needs review: $($_.Exception.Message)" }
        }
        Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red; throw
    } finally { if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($env:PCVR_DARKTIDEVR_LIBRARY_ONLY -ne '1') { Invoke-DarktideVRInstaller }
