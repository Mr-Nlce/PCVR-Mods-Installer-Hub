# Ghost Recon Wildlands VR - governed current/depot installer.
# Current route: newest GRW-XR prerelease against the normal game.
# Depot route: Steam build 24821571 plus GRW-XR v0.11.1, fully pinned.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Ghost Recon Wildlands VR Installer'
$APP_ID = '460930'
$GAME_EXE = 'GRW.exe'
$REPO = 'Firejumper93/GhostReconWildlandsVR'
$RELEASES_URL = "https://github.com/$REPO/releases"
$IDENTITY = 'grwxr'
$MOD_FILE = 'dxgi.dll'
$LOADER_FILE = 'openxr_loader.dll'
$REAL_PROXY = 'dxgi_real.dll'
$CFG_REL = 'GRWVR\grwxr.cfg'
$CFG_GUI = 'cfg_gui.exe'
$QUIP = 'Sync up, Ghosts - Bolivia in stereo.'

$PINNED_BUILD = '24821571'
$PINNED_MOD_TAG = 'v0.11.1'
$PINNED_MOD_NAME = 'GRW-XR-0.11.1.zip'
$PINNED_MOD_URL = 'https://github.com/Firejumper93/GhostReconWildlandsVR/releases/download/v0.11.1/GRW-XR-0.11.1.zip'
$PINNED_MOD_ARCHIVE_SHA256 = 'DABD5C4FBDE22947216ABCF71354C26217E5E7A912E399AFB126934AE8664911'
$CURRENT_FALLBACK_TAG = 'v0.11.2-test1'
$CURRENT_FALLBACK_NAME = 'GRW-XR-0.11.2-test1.zip'
$CURRENT_FALLBACK_URL = 'https://github.com/Firejumper93/GhostReconWildlandsVR/releases/download/v0.11.2-test1/GRW-XR-0.11.2-test1.zip'
$PINNED_GRW_SHA256 = '33D58D9763264D4F2734F2939E928AF74F167A57F6C88C4C7FDE39014C022F63'
$DEPOT_DEFAULT_PATH = 'C:\Games\Ghost Recon Wildlands VR 24821571'
$DEPOT_MARKER = '.pcvrhub_grw_depot_24821571'
$DEPOT_STACK_MARKER = '.pcvrhub_grw_depot_stack'
$DEPOT_STAGING_MARKER = '.pcvrhub_grw_depot_staging_24821571'
$DEPOT_ROWS = @(
    [pscustomobject]@{ DepotId='460932'; Manifest='4960655080727971619'; Proof='GRW.exe'; Label='Windows executable and core files' },
    [pscustomobject]@{ DepotId='460934'; Manifest='2282168770059932163'; Proof='DataPC.forge'; Label='base game data' },
    [pscustomobject]@{ DepotId='460935'; Manifest='8635509546796952093'; Proof='DataPC_GRN_WorldMap.forge'; Label='Bolivia world data' },
    [pscustomobject]@{ DepotId='460936'; Manifest='5451164306768136889'; Proof='DataPC_GRN_GhostRoom.forge'; Label='Ghost Room data' },
    [pscustomobject]@{ DepotId='460937'; Manifest='2767680188697771581'; Proof='videos\Loading.bk2'; Label='video data' },
    [pscustomobject]@{ DepotId='460938'; Manifest='3670877133173363108'; Proof='sounddata\pc\sounds_sfx.pck'; Label='sound data' },
    [pscustomobject]@{ DepotId='460939'; Manifest='4258098457727288719'; Proof='support\installscript.vdf'; Label='Steam support files' },
    [pscustomobject]@{ DepotId='1716751'; Manifest='6659642105086821873'; Proof='UbisoftConnectInstaller.exe'; Label='Ubisoft Connect bootstrap' }
)
$LANGUAGE_DEPOTS = @(
    [pscustomobject]@{ Code='E'; Name='English'; DepotId='527063'; Manifest='3912387248397514729'; Proof='support\Readme\English\Readme.txt'; Label='English language files' },
    [pscustomobject]@{ Code='G'; Name='German'; DepotId='527052'; Manifest='8311160010234034332'; Proof='support\Readme\German\Readme.txt'; Label='German language files' }
)

$currentContract = New-PCVRInstallerContract -Id 'ghost-recon-wildlands-vr' `
    -GameName 'Ghost Recon Wildlands VR' -Acquisition GitHub -AntivirusNotice `
    -ReleasePageUrl $RELEASES_URL -RequiredInstalledFileGroups @(
        'dxgi.dll|dxgi.dll.off','openxr_loader.dll','dxgi_real.dll','.pcvrhub_grwxr_ownership.csv'
    )
$depotContract = New-PCVRInstallerContract -Id 'ghost-recon-wildlands-vr' `
    -GameName 'Ghost Recon Wildlands VR' -Acquisition SteamDepot -PinnedDepot -AntivirusNotice `
    -ReleasePageUrl $RELEASES_URL -Routes @('Depot-24821571') -RequiredInstalledFileGroups @(
        'GRW.exe','dxgi.dll|dxgi.dll.off','openxr_loader.dll','dxgi_real.dll',
        '.pcvrhub_grwxr_ownership.csv',$DEPOT_MARKER,$DEPOT_STACK_MARKER,
        'steam_appid.txt','Start Ghost Recon Wildlands VR Depot.bat',
        'support\Readme\English\Readme.txt|support\Readme\German\Readme.txt'
    )

function Write-GRWStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-GRWOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-GRWInfo([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }
function Write-GRWWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Read-GRWChoice {
    param([string[]]$Allowed,[string]$Prompt)
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $choice=([string](Read-Host $Prompt)).Trim().ToUpperInvariant()
        if ($choice -in $Allowed) { return $choice }
        Write-GRWWarn "Choose $($Allowed -join ', ')."
    }
    throw 'No valid setup option was selected after 10 attempts.'
}

function Test-GRWRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function Get-GRWPEMachine([string]$Path) {
    try {
        $stream=[IO.File]::OpenRead($Path)
        try {
            $reader=New-Object IO.BinaryReader($stream)
            $stream.Position=0x3C; $offset=$reader.ReadInt32(); $stream.Position=$offset
            if ($reader.ReadUInt32() -ne 0x00004550) { return 0 }
            return [int]$reader.ReadUInt16()
        } finally { $stream.Dispose() }
    } catch { return 0 }
}

function Get-GRWSystemDxgi([int]$Machine) {
    $folders=@()
    if ($Machine -eq 0x8664) {
        $folders += $(if ([Environment]::Is64BitProcess) { Join-Path $env:WINDIR 'System32' } else { Join-Path $env:WINDIR 'Sysnative' })
    } else {
        $folders += $(if ([Environment]::Is64BitOperatingSystem) { Join-Path $env:WINDIR 'SysWOW64' } else { Join-Path $env:WINDIR 'System32' })
    }
    foreach ($folder in $folders) {
        $candidate=Join-Path $folder 'dxgi.dll'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

function Get-GRWRelease {
    param([ValidateSet('Current','Depot')][string]$InstallMode='Current')
    if ($InstallMode -eq 'Depot') {
        return [pscustomobject]@{ Tag=$PINNED_MOD_TAG; Url=$PINNED_MOD_URL; Name=$PINNED_MOD_NAME; PageUrl="$RELEASES_URL/tag/$PINNED_MOD_TAG"; Pinned=$true }
    }
    $release=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true `
        -AssetPatterns @('(?i)^GRW-XR-.*\.zip$') -FallbackUrl $CURRENT_FALLBACK_URL `
        -FallbackTag $CURRENT_FALLBACK_TAG -FallbackAssetName $CURRENT_FALLBACK_NAME
    return [pscustomobject]@{ Tag=[string]$release.Tag; Url=[string]$release.Url; Name=[string]$release.AssetName; PageUrl=[string]$release.PageUrl; Pinned=$false }
}

function Get-GRWDepotMarkerText {
    param([string]$LanguageDepotId='527063')
    $lines=@("AppId=$APP_ID","BuildId=$PINNED_BUILD","GRW.exe.SHA256=$PINNED_GRW_SHA256","GRW-XR=$PINNED_MOD_TAG")
    foreach ($row in $DEPOT_ROWS) { $lines += "Depot.$($row.DepotId)=$($row.Manifest)" }
    $language=@($LANGUAGE_DEPOTS | Where-Object DepotId -eq $LanguageDepotId) | Select-Object -First 1
    if (-not $language) { throw "Unsupported pinned language depot: $LanguageDepotId" }
    $lines += "LanguageDepot.$($language.DepotId)=$($language.Manifest)"
    return ($lines -join "`r`n")
}

function Test-GRWDepotMarker([string]$Path,[string]$MarkerName=$DEPOT_MARKER) {
    if (-not $Path) { return $false }
    $marker=Join-Path $Path $MarkerName
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { return $false }
    try {
        $text=[IO.File]::ReadAllText($marker)
        $language=@($LANGUAGE_DEPOTS | Where-Object { $text -match ('(?m)^LanguageDepot\.'+[regex]::Escape($_.DepotId)+'='+[regex]::Escape($_.Manifest)+'\s*$') }) | Select-Object -First 1
        if (-not $language) { return $false }
        foreach ($line in @((Get-GRWDepotMarkerText -LanguageDepotId $language.DepotId) -split '\r?\n')) {
            if ($text -notmatch ('(?m)^'+[regex]::Escape($line)+'\s*$')) { return $false }
        }
        return $true
    } catch { return $false }
}

function Test-GRWPinnedExecutable([string]$Path) {
    if (-not (Test-GRWRoot $Path)) { return $false }
    try { return ((Get-FileHash -LiteralPath (Join-Path $Path $GAME_EXE) -Algorithm SHA256).Hash -eq $PINNED_GRW_SHA256) }
    catch { return $false }
}

function Get-GRWDepotReceiptPath([string]$GameRoot,$Row) {
    return (Join-Path $GameRoot ('.pcvrhub_grw_depot_{0}_{1}' -f $Row.DepotId,$Row.Manifest))
}

function Test-GRWDepotReceipt([string]$GameRoot,$Row) {
    if (-not $GameRoot -or -not $Row) { return $false }
    $proof=Join-Path $GameRoot ([string]$Row.Proof)
    $receipt=Get-GRWDepotReceiptPath -GameRoot $GameRoot -Row $Row
    return [bool]((Test-Path -LiteralPath $proof -PathType Leaf) -and (Test-Path -LiteralPath $receipt -PathType Leaf))
}

function Write-GRWDepotReceipt([string]$GameRoot,$Row) {
    if (-not (Test-Path -LiteralPath (Join-Path $GameRoot ([string]$Row.Proof)) -PathType Leaf)) {
        throw "Cannot confirm depot $($Row.DepotId): $($Row.Proof) is missing."
    }
    [IO.File]::WriteAllText((Get-GRWDepotReceiptPath -GameRoot $GameRoot -Row $Row),
        ("AppId={0}`r`nDepotId={1}`r`nManifest={2}" -f $APP_ID,$Row.DepotId,$Row.Manifest),
        (New-Object Text.UTF8Encoding $false))
}

function Test-GRWSteamManifestStack([string]$GameRoot) {
    if (-not $GameRoot) { return $false }
    try {
        $common=Split-Path -Parent ([IO.Path]::GetFullPath($GameRoot))
        if ((Split-Path -Leaf $common) -ine 'common') { return $false }
        $steamApps=Split-Path -Parent $common
        $manifestPath=Join-Path $steamApps "appmanifest_$APP_ID.acf"
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { return $false }
        $text=[IO.File]::ReadAllText($manifestPath)
        if ($text -notmatch ('(?i)"buildid"\s*"'+[regex]::Escape($PINNED_BUILD)+'"')) { return $false }
        foreach ($row in $DEPOT_ROWS) {
            $pattern='(?is)"'+[regex]::Escape([string]$row.DepotId)+'"\s*\{[^{}]*"manifest"\s*"'+[regex]::Escape([string]$row.Manifest)+'"'
            if ($text -notmatch $pattern) { return $false }
        }
        foreach ($language in $LANGUAGE_DEPOTS) {
            $pattern='(?is)"'+[regex]::Escape([string]$language.DepotId)+'"\s*\{[^{}]*"manifest"\s*"'+[regex]::Escape([string]$language.Manifest)+'"'
            if ($text -match $pattern) { return $true }
        }
    } catch {}
    return $false
}

function Test-GRWPinnedRoot([string]$Path,[switch]$AllowStaging) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    foreach ($row in $DEPOT_ROWS) {
        if (-not (Test-GRWDepotReceipt -GameRoot $Path -Row $row)) { return $false }
    }
    if (-not @($LANGUAGE_DEPOTS | Where-Object { Test-GRWDepotReceipt -GameRoot $Path -Row $_ }).Count) { return $false }
    if (-not (Test-GRWPinnedExecutable $Path)) { return $false }
    if (Test-GRWDepotMarker -Path $Path) { return $true }
    if ($AllowStaging -and (Test-GRWDepotMarker -Path $Path -MarkerName $DEPOT_STAGING_MARKER)) { return $true }
    return $false
}

function Write-GRWDepotSupportFiles([string]$GameRoot,[string]$LanguageDepotId='') {
    if (-not (Test-GRWPinnedExecutable $GameRoot)) { throw 'The depot GRW.exe does not match pinned Steam build 24821571.' }
    foreach ($row in $DEPOT_ROWS) {
        if (-not (Test-GRWDepotReceipt -GameRoot $GameRoot -Row $row)) { throw "The merged depot lacks exact receipt for $($row.DepotId) / $($row.Manifest)." }
    }
    $language=$null
    if ($LanguageDepotId) { $language=@($LANGUAGE_DEPOTS | Where-Object DepotId -eq $LanguageDepotId) | Select-Object -First 1 }
    if (-not $language) { $language=@($LANGUAGE_DEPOTS | Where-Object { Test-GRWDepotReceipt -GameRoot $GameRoot -Row $_ }) | Select-Object -First 1 }
    if (-not $language -or -not (Test-GRWDepotReceipt -GameRoot $GameRoot -Row $language)) { throw 'The merged depot is missing its exact English or German language receipt.' }
    [IO.File]::WriteAllText((Join-Path $GameRoot 'steam_appid.txt'),$APP_ID,[Text.Encoding]::ASCII)
    $launcher=@'
@echo off
setlocal
set "SteamAppId=460930"
start "" "steam://open/main"
for /L %%I in (1,1,30) do (
  tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I "steam.exe" >NUL && goto steam_ready
  timeout /t 1 /nobreak >NUL
)
:steam_ready
start "Ghost Recon Wildlands VR 24821571" /D "%~dp0" "%~dp0GRW.exe" -uplay_steam_mode
endlocal
exit /b 0
'@
    [IO.File]::WriteAllText((Join-Path $GameRoot 'Start Ghost Recon Wildlands VR Depot.bat'),$launcher.TrimStart(),[Text.Encoding]::ASCII)
    if (-not (Test-GRWDepotMarker $GameRoot)) {
        [IO.File]::WriteAllText((Join-Path $GameRoot $DEPOT_MARKER),(Get-GRWDepotMarkerText -LanguageDepotId $language.DepotId),(New-Object Text.UTF8Encoding $false))
    }
    [IO.File]::WriteAllText((Join-Path $GameRoot $DEPOT_STACK_MARKER),("BuildId=$PINNED_BUILD`r`nGRW-XR=$PINNED_MOD_TAG"),(New-Object Text.UTF8Encoding $false))
}

function Get-ExistingGRWDepot {
    $candidates=@()
    $receipt=Join-Path $PSScriptRoot '.installed_path_depot'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try { $candidates += ([IO.File]::ReadAllText($receipt)).Trim() } catch {}
    }
    $candidates += $DEPOT_DEFAULT_PATH
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-GRWPinnedRoot $candidate) { return (Get-Item -LiteralPath $candidate).FullName }
    }
    return $null
}

function Find-CompatibleGRWSource {
    $candidate=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Wildlands',"Tom Clancy's Ghost Recon Wildlands") -ProbeExe $GAME_EXE -HubGameId 'ghost-recon-wildlands-vr'
    if ((Test-GRWPinnedExecutable $candidate) -and (Test-GRWSteamManifestStack $candidate)) { return (Get-Item -LiteralPath $candidate).FullName }
    return $null
}

function Install-GRWPinnedDepot {
    $selectedLanguage=$null
    Write-GRWStep 1 5 "Preparing confirmed Steam build $PINNED_BUILD"
    $existing=Get-ExistingGRWDepot
    if ($existing) {
        Write-GRWDepotSupportFiles $existing
        Write-GRWOK "Using existing pinned copy: $existing"
        return $existing
    }

    Write-Host '  This creates a separate base-campaign copy of the last' -ForegroundColor White
    Write-Host '  build confirmed for GRW-XR v0.11.1. Paid DLC depots are not included.' -ForegroundColor White
    Write-Host '  Download route: about 62.3 GiB; installed size: about 77.3 GiB.' -ForegroundColor Gray
    Write-Host "  Default destination: $DEPOT_DEFAULT_PATH" -ForegroundColor Gray
    $entered=([string](Read-Host 'Press Enter for the default, or type a different full path')).Trim().Trim('"')
    $target=if ($entered) { $entered } else { $DEPOT_DEFAULT_PATH }
    if (-not (Test-InstallerTargetWritable -TargetPath $target)) { throw "The depot target is not writable: $target" }
    $normal=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Wildlands',"Tom Clancy's Ghost Recon Wildlands") -ProbeExe $GAME_EXE
    if ($normal -and ([IO.Path]::GetFullPath($target) -ieq [IO.Path]::GetFullPath($normal))) {
        throw 'The pinned depot cannot replace or merge into the normal Steam installation.'
    }
    if (Test-Path -LiteralPath $target -PathType Container) {
        if (-not (Test-GRWDepotMarker $target) -and -not (Test-GRWDepotMarker $target $DEPOT_STAGING_MARKER)) {
            throw 'The selected existing folder is not a Hub-created Wildlands depot. Choose an empty, new destination.'
        }
    }

    $compatible=Find-CompatibleGRWSource
    $useClone=$false
    if ($compatible -and -not (Test-Path -LiteralPath $target -PathType Container)) {
        Write-Host ''; Write-GRWOK "Steam still has exact compatible build $PINNED_BUILD."
        Write-Host '  [C] Clone those verified local files into the separate depot copy' -ForegroundColor Cyan
        Write-Host '  [D] Download the pinned depots through Steam Console instead' -ForegroundColor Cyan
        Write-Host '  [Q] Quit' -ForegroundColor Gray
        $sourceChoice=Read-GRWChoice -Allowed @('C','D','Q') -Prompt 'Choose source'
        if ($sourceChoice -eq 'Q') { throw 'Setup cancelled before creating the depot.' }
        $useClone=($sourceChoice -eq 'C')
    }
    if ($useClone) {
        Write-Host '  The compatible installation will now be copied. Steam keeps its' -ForegroundColor White
        Write-Host '  normal folder; only the new separate route is changed.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy the verified build...')
        [void](Copy-DirectoryTreeVerified -Source $compatible -Destination $target)
        $cloneLanguage=@($LANGUAGE_DEPOTS | Where-Object { Test-Path -LiteralPath (Join-Path $target $_.Proof) -PathType Leaf }) | Select-Object -First 1
        if (-not $cloneLanguage) { throw 'The verified local build has no supported English or German language proof.' }
        [IO.File]::WriteAllText((Join-Path $target $DEPOT_STAGING_MARKER),(Get-GRWDepotMarkerText -LanguageDepotId $cloneLanguage.DepotId),(New-Object Text.UTF8Encoding $false))
        foreach ($row in @($DEPOT_ROWS)+@($cloneLanguage)) { Write-GRWDepotReceipt -GameRoot $target -Row $row }
    } else {
        $steamRoot=Get-SteamPath
        $sources=@{}
        Write-Host '  [E] English base-campaign files' -ForegroundColor Cyan
        Write-Host '  [G] German language files in addition to the English base data' -ForegroundColor Cyan
        $languageChoice=Read-GRWChoice -Allowed @('E','G') -Prompt 'Choose depot language'
        $selectedLanguage=@($LANGUAGE_DEPOTS | Where-Object Code -eq $languageChoice) | Select-Object -First 1
        $selectedRows=@($DEPOT_ROWS)+@($selectedLanguage)
        foreach ($row in $selectedRows) {
            if ((Test-Path -LiteralPath $target -PathType Container) -and (Test-GRWDepotReceipt -GameRoot $target -Row $row)) { continue }
            # A Steam content folder does not encode its manifest identity in
            # its pathname. Never accept a previously left-behind depot merely
            # because one proof file exists: present and run the exact pinned
            # command first, then resolve the result of that explicit action.
            $command="download_depot $APP_ID $($row.DepotId) $($row.Manifest)"
            Write-Host ''; Write-Host "  Required $($row.Label) depot $($row.DepotId):" -ForegroundColor White
            Write-Host "  $command" -ForegroundColor DarkGray
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy this command and open Steam Console...')
            try { Set-Clipboard -Value $command -DeferManualFallback } catch {}
            foreach ($uri in @('steam://open/console','steam://nav/console')) { try { Start-Process $uri; Start-Sleep -Milliseconds 700 } catch {} }
            Show-PCVRClipboardManualFallback -Text $command
            Write-Host '  Paste with Ctrl+V in Steam Console and wait for the depot download.' -ForegroundColor White
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter here only after that exact depot has finished...')
            $source=Find-SteamDepotPath -AppId $APP_ID -DepotId $row.DepotId -GameExe $row.Proof -AdditionalSteamRoots @($steamRoot)
            if (-not $source) {
                $probes=@(Get-SteamDepotProbePaths -AppId $APP_ID -DepotId $row.DepotId -AdditionalSteamRoots @($steamRoot))
                $source=Resolve-DepotPath -GameName "Wildlands build $PINNED_BUILD, depot $($row.DepotId)" `
                    -DepotCommand $command -GameExe $row.Proof -ProbePaths $probes `
                    -AppId $APP_ID -DepotId $row.DepotId -Manifest $row.Manifest
            }
            if (-not $source -or -not (Test-Path -LiteralPath (Join-Path $source $row.Proof) -PathType Leaf)) { throw "Pinned depot $($row.DepotId) did not provide $($row.Proof)." }
            $sources[$row.DepotId]=$source
        }
        if (-not (Test-Path -LiteralPath $target -PathType Container)) {
            $main=[string]$sources['460932']; if (-not $main) { throw 'The executable depot is unavailable.' }
            [void](Merge-DirectoryTreeVerified -Source $main -Destination $target -RemoveSource -Label 'Wildlands executable depot')
            [IO.File]::WriteAllText((Join-Path $target $DEPOT_STAGING_MARKER),(Get-GRWDepotMarkerText -LanguageDepotId $selectedLanguage.DepotId),(New-Object Text.UTF8Encoding $false))
            Write-GRWDepotReceipt -GameRoot $target -Row (@($selectedRows | Where-Object DepotId -eq '460932') | Select-Object -First 1)
        }
        foreach ($row in $selectedRows) {
            if (Test-GRWDepotReceipt -GameRoot $target -Row $row) { continue }
            $source=[string]$sources[$row.DepotId]; if (-not $source) { throw "The $($row.Label) depot is unavailable for the merge." }
            [void](Merge-DirectoryTreeVerified -Source $source -Destination $target -RemoveSource -Label "Wildlands $($row.Label) depot")
            Write-GRWDepotReceipt -GameRoot $target -Row $row
        }
    }
    Write-GRWDepotSupportFiles $target $(if ($selectedLanguage) { $selectedLanguage.DepotId } else { '' })
    Remove-Item -LiteralPath (Join-Path $target $DEPOT_STAGING_MARKER) -Force -ErrorAction SilentlyContinue
    if (-not (Test-GRWPinnedRoot $target)) { throw 'The completed pinned Wildlands root failed its route check.' }
    Write-GRWOK "Steam build $PINNED_BUILD assembled at: $target"
    return (Get-Item -LiteralPath $target).FullName
}

function Find-GRWCurrentRoot {
    $path=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Wildlands',"Tom Clancy's Ghost Recon Wildlands") -ProbeExe $GAME_EXE -HubGameId 'ghost-recon-wildlands-vr'
    if (-not (Test-GRWRoot $path)) {
        foreach ($candidate in @(
            'C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy''s Ghost Recon Wildlands',
            'C:\Program Files\Ubisoft\Ubisoft Game Launcher\games\Tom Clancy''s Ghost Recon Wildlands'
        )) { if (Test-GRWRoot $candidate) { $path=$candidate; break } }
    }
    if (-not (Test-GRWRoot $path)) {
        $path=Get-GameFolderInteractive -GameName "Tom Clancy's Ghost Recon Wildlands" -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/460930/'
    }
    if ($path -in @('quit','skip',$null) -or -not (Test-GRWRoot $path)) { return $null }
    return (Get-Item -LiteralPath $path).FullName
}

function Find-GRWPayload([string]$ExtractRoot) {
    $hit=Get-ChildItem -LiteralPath $ExtractRoot -Filter $MOD_FILE -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $hit) { return $null }
    $root=$hit.DirectoryName
    if (-not (Test-Path -LiteralPath (Join-Path $root $LOADER_FILE) -PathType Leaf)) { return $null }
    return $root
}

function New-GRWNormalizedPayload([string]$SourceRoot,[string]$GameRoot,[string]$WorkRoot) {
    $payload=Join-Path $WorkRoot 'payload'; [void][IO.Directory]::CreateDirectory($payload)
    Copy-Item -LiteralPath (Join-Path $SourceRoot $MOD_FILE) -Destination (Join-Path $payload $MOD_FILE) -Force
    Copy-Item -LiteralPath (Join-Path $SourceRoot $LOADER_FILE) -Destination (Join-Path $payload $LOADER_FILE) -Force
    $machine=Get-GRWPEMachine (Join-Path $GameRoot $GAME_EXE)
    $systemDxgi=Get-GRWSystemDxgi $machine
    if (-not $systemDxgi) { throw 'A same-architecture Windows dxgi.dll could not be found for dxgi_real.dll.' }
    Copy-Item -LiteralPath $systemDxgi -Destination (Join-Path $payload $REAL_PROXY) -Force
    if ($machine -ne 0 -and (Get-GRWPEMachine (Join-Path $payload $REAL_PROXY)) -ne $machine) { throw 'The Windows dxgi.dll architecture does not match GRW.exe.' }
    $gui=Get-ChildItem -LiteralPath $SourceRoot -Filter $CFG_GUI -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gui) { Copy-Item -LiteralPath $gui.FullName -Destination (Join-Path $payload $CFG_GUI) -Force }
    $cfg=Get-ChildItem -LiteralPath $SourceRoot -Filter 'grwxr.cfg' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cfg) {
        $cfgTarget=Join-Path $payload $CFG_REL; [void][IO.Directory]::CreateDirectory((Split-Path -Parent $cfgTarget))
        Copy-Item -LiteralPath $cfg.FullName -Destination $cfgTarget -Force
    }
    return $payload
}

function Save-GRWSnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $relatives=@('dxgi.dll','dxgi.dll.off','openxr_loader.dll','dxgi_real.dll','cfg_gui.exe','GRWVR\grwxr.cfg','.pcvrhub_grwxr_ownership.csv','.pcvrhub_grwxr_backup','.pcvrhub_version')
    $records=@()
    foreach ($relative in $relatives) {
        $source=Join-Path $GameRoot $relative; $exists=Test-Path -LiteralPath $source
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists; Directory=(Test-Path -LiteralPath $source -PathType Container) }
        if ($exists) {
            $copy=Join-Path $SnapshotRoot ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_'))
            Copy-Item -LiteralPath $source -Destination $copy -Recurse -Force
        }
    }
    return $records
}

function Restore-GRWSnapshot([string]$GameRoot,[string]$SnapshotRoot,$Records) {
    if (-not (Test-GRWRoot $GameRoot)) { throw 'Rollback target is no longer a verified Wildlands folder.' }
    foreach ($record in @($Records)) {
        $target=Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            $copy=Join-Path $SnapshotRoot ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$record.Relative)).Replace('/','_'))
            $parent=Split-Path -Parent $target; if (-not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath $copy -Destination $target -Recurse -Force
        }
    }
}

function global:Invoke-GhostReconWildlandsVRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $snapshotRecords=$null; $changesStarted=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Ghost Recon Wildlands VR - Installer' -ForegroundColor Cyan
        Write-Host '  Installs: GRW-XR by Firejumper93' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Native OpenXR stereo, head tracking, first person and tracked' -ForegroundColor White
        Write-Host '  weapon aiming. Touch buttons emulate the normal gamepad.' -ForegroundColor White
        Write-Host '  Solo campaign or private co-op only; avoid public matchmaking.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  [1] Current game and newest GRW-XR prerelease' -ForegroundColor Cyan
        Write-Host '      Uses the normal Steam/Ubisoft installation.' -ForegroundColor Gray
        Write-Host '      The September 15 game update is not supported by v0.11.1.' -ForegroundColor Yellow
        Write-Host "  [2] Confirmed Steam build $PINNED_BUILD with GRW-XR $PINNED_MOD_TAG" -ForegroundColor Cyan
        Write-Host "      Separate $DEPOT_DEFAULT_PATH copy; normal Steam files stay untouched." -ForegroundColor Gray
        Write-Host '      English or German base campaign; paid DLC depots are not included.' -ForegroundColor Gray
        Write-Host '  [Q] Quit' -ForegroundColor Gray
        Write-Host ''
        $choice=Read-GRWChoice -Allowed @('1','2','Q') -Prompt 'Select setup option'
        if ($choice -eq 'Q') {
            Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
            return
        }
        $installMode=if ($choice -eq '2') { 'Depot' } else { 'Current' }
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        if ($installMode -eq 'Depot') { $game=Install-GRWPinnedDepot }
        else { Write-GRWStep 1 5 'Locating Ghost Recon Wildlands'; $game=Find-GRWCurrentRoot }
        if (-not (Test-GRWRoot $game)) { throw 'Setup cancelled before any game file was changed.' }
        if (Get-Process -Name 'GRW' -ErrorAction SilentlyContinue) { throw 'Ghost Recon Wildlands is running. Close it completely and run setup again.' }
        Write-GRWOK "Found: $game"

        Write-GRWStep 2 5 $(if ($installMode -eq 'Depot') { "Getting pinned GRW-XR $PINNED_MOD_TAG" } else { 'Getting the newest GRW-XR release, including prereleases' })
        $release=Get-GRWRelease $installMode
        Write-GRWInfo "Release: $($release.Tag)"
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_grwxr_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'grwxr.zip'
        $got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "GRW-XR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The GRW-XR release was not downloaded.' }
        if ($installMode -eq 'Depot') {
            # Historical digest is positive provenance only. A mismatch never
            # blocks a readable publisher archive or changes the install path.
            try {
                if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -eq $PINNED_MOD_ARCHIVE_SHA256) {
                    Write-GRWInfo 'Pinned publisher archive matches the inspected v0.11.1 digest.'
                }
            } catch {}
        }
        $extract=Join-Path $work 'extract'
        $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'GRW-XR release' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The GRW-XR archive could not be extracted.' }
        $source=Find-GRWPayload $extract
        if (-not $source) { throw 'The release is missing dxgi.dll or openxr_loader.dll.' }

        Write-GRWStep 3 5 'Preparing a recoverable file transaction'
        $normalized=New-GRWNormalizedPayload -SourceRoot $source -GameRoot $game -WorkRoot $work
        $snapshot=Join-Path $work 'snapshot'
        $snapshotRecords=Save-GRWSnapshot $game $snapshot
        $wasFlat=(Test-Path -LiteralPath (Join-Path $game 'dxgi.dll.off') -PathType Leaf) -and -not (Test-Path -LiteralPath (Join-Path $game 'dxgi.dll') -PathType Leaf)
        if ($wasFlat) { Move-Item -LiteralPath (Join-Path $game 'dxgi.dll.off') -Destination (Join-Path $game 'dxgi.dll') -Force }

        Write-GRWStep 4 5 'Installing and verifying GRW-XR'
        $changesStarted=$true
        [void](Install-OwnedModPayload -SourceRoot $normalized -GameRoot $game -Identity $IDENTITY `
            -KeepExistingRelativePaths @($CFG_REL) `
            -ReplaceChangedOwnedRelativePaths @('dxgi.dll','openxr_loader.dll','dxgi_real.dll',$CFG_GUI))
        if ($wasFlat -and (Test-Path -LiteralPath (Join-Path $game 'dxgi.dll') -PathType Leaf)) {
            Move-Item -LiteralPath (Join-Path $game 'dxgi.dll') -Destination (Join-Path $game 'dxgi.dll.off') -Force
        }
        foreach ($required in @('openxr_loader.dll','dxgi_real.dll','.pcvrhub_grwxr_ownership.csv')) {
            if (-not (Test-Path -LiteralPath (Join-Path $game $required) -PathType Leaf)) { throw "Required installed file is missing: $required" }
        }
        if (-not ((Test-Path -LiteralPath (Join-Path $game 'dxgi.dll') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $game 'dxgi.dll.off') -PathType Leaf))) {
            throw 'The GRW-XR proxy is missing after installation.'
        }
        Write-GRWOK 'Mod payload and Windows forwarding proxy verified.'

        Write-GRWStep 5 5 'Committing route state and launch files'
        if ($installMode -eq 'Depot') { Write-GRWDepotSupportFiles $game }
        $receipt=Join-Path $PSScriptRoot $(if ($installMode -eq 'Depot') { '.installed_path_depot' } else { '.installed_path' })
        $versionReceipt=Join-Path $PSScriptRoot $(if ($installMode -eq 'Depot') { '.installed_version_depot' } else { '.installed_version' })
        $contract=if ($installMode -eq 'Depot') { $depotContract } else { $currentContract }
        $route=if ($installMode -eq 'Depot') { 'Depot-24821571' } else { 'Current' }
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version ([string]$release.Tag) `
            -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @($versionReceipt) -Route $route)
        $changesStarted=$false

        if ($installMode -eq 'Depot') {
            try {
                $start=Join-Path $game 'Start Ghost Recon Wildlands VR Depot.bat'
                [void](New-DesktopShortcut -ShortcutName 'Ghost Recon Wildlands VR 24821571' -TargetPath $start `
                    -WorkingDir $game -IconPath ((Join-Path $game $GAME_EXE)+',0') `
                    -Description 'Launch pinned Ghost Recon Wildlands VR build 24821571')
                Write-GRWOK 'Desktop shortcut created for the pinned depot route.'
            } catch { Write-GRWWarn 'The depot is complete, but its optional desktop shortcut could not be created.' }
        } else {
            $isSteam=($game -match '(?i)steamapps\\common|\\Steam\\')
            if ($isSteam) { Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.launch_exe') -Force -ErrorAction SilentlyContinue }
            else { [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.launch_exe'),(Join-Path $game $GAME_EXE),(New-Object Text.UTF8Encoding $false)) }
        }

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Ghost Recon Wildlands VR is ready' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        if ($installMode -eq 'Depot') {
            Write-Host "  Route: Steam build $PINNED_BUILD with GRW-XR $PINNED_MOD_TAG" -ForegroundColor White
            Write-Host '  Start it with the new depot shortcut or its Start .bat.' -ForegroundColor White
            Write-Host '  Steam and Ubisoft Connect must both be running and signed in.' -ForegroundColor Yellow
            Write-Host '  This historical client may stop working if Ubisoft changes its backend.' -ForegroundColor Yellow
        } else {
            Write-Host '  Start the normal Steam copy through Steam. For Ubisoft Connect,' -ForegroundColor White
            Write-Host '  use the normal library entry. Put the headset on before launch.' -ForegroundColor White
            Write-Host '  If the September 15 executable is still unsupported, use option 2.' -ForegroundColor Yellow
        }
        Write-Host '  Solo campaign or private co-op only; never use public matchmaking.' -ForegroundColor Yellow
        Write-Host '  Press Home to recenter. The Flat / VR switch parks only dxgi.dll.' -ForegroundColor Gray
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot -and $snapshotRecords) {
            try {
                Restore-GRWSnapshot -GameRoot $game -SnapshotRoot $snapshot -Records $snapshotRecords
                Write-GRWWarn 'The previous GRW-XR file state was restored.'
            } catch { Write-GRWWarn "Rollback also failed: $($_.Exception.Message)" }
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($env:PCVR_HUB_IMPORT_ONLY -ne '1') { Invoke-GhostReconWildlandsVRInstaller }
