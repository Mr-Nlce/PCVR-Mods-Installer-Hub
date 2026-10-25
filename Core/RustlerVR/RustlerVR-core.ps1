$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Rustler VR Installer'
$script:RustlerId = 'rustler-vr'
$script:RustlerRepo = 'King-EJ/Rustler-VR'
$script:RustlerPage = 'https://github.com/King-EJ/Rustler-VR/releases'
$script:RustlerDirect = 'https://github.com/King-EJ/Rustler-VR/releases/download/Rustler_VR/RustlerVR.zip'
$script:RustlerIdentity = 'rustlervr'
$script:RustlerManifest = '.pcvrhub_rustlervr_ownership.csv'
$script:RustlerContract = New-PCVRInstallerContract -Id $script:RustlerId -GameName 'Rustler VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:RustlerPage -Routes @('Steam','Epic','GOG') `
    -RequiredInstalledFileGroups @('Rustler.exe','UnityPlayer.dll','winhttp.dll','BepInEx\core\BepInEx.dll', `
        'BepInEx\plugins\RusVR\RusVR.dll','BepInEx\plugins\RusVR\OpenXR.dll',$script:RustlerManifest)

function Test-RustlerGame([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Rustler.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'UnityPlayer.dll') -PathType Leaf))
}
function Get-RustlerGame {
    if ($env:PCVR_RUSTLER_TEST_GAME) {
        $root = [IO.Path]::GetFullPath($env:PCVR_RUSTLER_TEST_GAME)
        if (-not $root.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath (Join-Path $root 'rustler-fixture.txt') -PathType Leaf) -or
            -not (Test-RustlerGame $root)) { throw 'Rustler test game must be an isolated complete fixture.' }
        return $root
    }
    $paths = @()
    $saved = Get-PCVRRememberedGameFolder -GameId $script:RustlerId -StateNames @('installed_path','user_located') -ProbeFiles @('Rustler.exe','UnityPlayer.dll')
    if ($saved) { $paths += $saved }
    try { $steam = Find-SteamGameFolder -AppId '844260' -SteamFolderNames @('Rustler') -ProbeExe 'Rustler.exe' -HubGameId $script:RustlerId; if ($steam) { $paths += $steam } } catch { }
    $paths += @('C:\Program Files (x86)\Steam\steamapps\common\Rustler','C:\Program Files\Epic Games\Rustler',
        'C:\Program Files (x86)\GOG Galaxy\Games\Rustler (Grand Theft Horse)','C:\GOG Games\Rustler (Grand Theft Horse)')
    foreach ($path in @($paths | Select-Object -Unique)) { if (Test-RustlerGame $path) { return [IO.Path]::GetFullPath($path) } }
    $picked = Get-GameFolderInteractive -GameName 'Rustler' -ProbeFile 'Rustler.exe' -ManualUrl 'https://store.steampowered.com/app/844260/'
    if (Test-RustlerGame $picked) {
        [void](Save-HubRememberedGameFolder -GameId $script:RustlerId -Title 'Rustler VR' -GameDir $picked -ProbeFiles @('Rustler.exe','UnityPlayer.dll') -UserSelected)
        return [IO.Path]::GetFullPath($picked)
    }
    throw 'Choose a complete Rustler folder containing Rustler.exe and UnityPlayer.dll.'
}
function Get-RustlerPackageVersion([string]$Archive) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
        try {
            foreach ($required in @('winhttp.dll','BepInEx/core/BepInEx.dll','BepInEx/plugins/RusVR/RusVR.dll',
                'BepInEx/plugins/RusVR/OpenXR.dll','BepInEx/config/rustler.vr.cfg')) {
                if (-not @($zip.Entries | Where-Object { $_.FullName -ceq $required }).Count) { return '' }
            }
            $cfg = @($zip.Entries | Where-Object { $_.FullName -ceq 'BepInEx/config/rustler.vr.cfg' }) | Select-Object -First 1
            $reader = [IO.StreamReader]::new($cfg.Open())
            try { $first = $reader.ReadLine() } finally { $reader.Dispose() }
            if ($first -match '^## Settings file was created by plugin Rustler VR v(\d+(?:\.\d+){2})$') { return 'v' + $Matches[1] }
            return ''
        } finally { $zip.Dispose() }
    } catch { return '' }
}
function Get-RustlerArchive([string]$Destination) {
    if ($env:PCVR_RUSTLER_TEST_ARCHIVE) {
        Copy-Item -LiteralPath $env:PCVR_RUSTLER_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop
        $testVersion = Get-RustlerPackageVersion $Destination
        if (-not $testVersion) { throw 'The Rustler VR test ZIP is incomplete.' }
        return $testVersion
    }
    $url = $script:RustlerDirect
    try {
        $release = Resolve-GitHubReleaseAsset -Repo $script:RustlerRepo -AssetPatterns @('(?i)^RustlerVR\.zip$') -SkipReleasesWithoutMatchingAsset
        if ($release -and $release.Resolved -and $release.Url) { $url = [string]$release.Url }
    } catch { Write-Host '  GitHub release lookup is unavailable; trying the official direct ZIP.' -ForegroundColor Yellow }
    [void](Invoke-SafeDownload -Urls @($url) -Destination $Destination -Label 'Rustler VR ZIP' `
        -ManualUrl $script:RustlerPage -AllowSkip:$false `
        -Validator { param($path) [bool](Get-RustlerPackageVersion $path) })
    $version = Get-RustlerPackageVersion $Destination
    if (-not $version) { throw 'The downloaded file is not a complete Rustler VR ZIP.' }
    return $version
}
function Save-RustlerSnapshot([string]$Game,[string]$Folder,[string]$Stage) {
    [void][IO.Directory]::CreateDirectory($Folder)
    $all = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -File -Recurse)) {
        [void]$all.Add($file.FullName.Substring($Stage.TrimEnd([char[]]'\/').Length + 1))
    }
    $manifest = Join-Path $Game $script:RustlerManifest
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest)) { [void]$all.Add((Assert-PCVROwnedRelativePath $row.RelativePath)) }
    }
    [void]$all.Add($script:RustlerManifest)
    [void]$all.Add('.pcvrhub_version')
    $rows = @()
    foreach ($relative in $all) {
        $target = Join-OwnedRelativePath $Game $relative
        $key = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $exists = Test-Path -LiteralPath $target -PathType Leaf
        $rows += [pscustomobject]@{Relative=$relative;Key=$key;Exists=$exists}
        if ($exists) { Copy-Item -LiteralPath $target -Destination (Join-Path $Folder $key) -Force -ErrorAction Stop }
    }
    $backup = Join-Path $Game '.pcvrhub_rustlervr_backup'
    $hasBackup = Test-Path -LiteralPath $backup -PathType Container
    if ($hasBackup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $Folder 'backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{Rows=$rows;Folder=$Folder;HasBackup=$hasBackup}
}
function Restore-RustlerSnapshot([string]$Game,$Snapshot) {
    foreach ($row in $Snapshot.Rows) {
        $target = Join-OwnedRelativePath $Game $row.Relative
        if ($row.Exists) {
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath (Join-Path $Snapshot.Folder $row.Key) -Destination $target -Force
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
    }
    $backup = Join-Path $Game '.pcvrhub_rustlervr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force }
    if ($Snapshot.HasBackup) { Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'backup') -Destination $backup -Recurse -Force }
}
function Invoke-RustlerInstaller {
    $work = $null; $snapshot = $null; $changed = $false; $game = $null
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Rustler VR - Installer' -ForegroundColor Cyan
        Write-Host '  Motion controls; test build' -ForegroundColor Yellow
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  The mod includes BepInEx 5 and an OpenXR plugin.' -ForegroundColor White
        Write-Host '  Existing files with the same names are backed up; saves stay untouched.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Rustler...')
        $game = Get-RustlerGame
        Write-Host "  Game: $game" -ForegroundColor Green
        if (Get-Process -Name Rustler -ErrorAction SilentlyContinue) { throw 'Close Rustler before installing or updating VR.' }
        if (-not (Test-InstallerTargetWritable $game)) { throw 'The Rustler folder is not writable.' }
        $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive = Join-Path $work 'RustlerVR.zip'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the current Rustler VR ZIP...')
        $version = Get-RustlerArchive $archive
        $stage = Join-Path $work 'stage'
        if ((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'Rustler VR' -AllowSkip:$false) -ne 'ok') {
            throw 'The Rustler VR ZIP could not be extracted.'
        }
        foreach ($required in @('winhttp.dll','BepInEx\core\BepInEx.dll','BepInEx\plugins\RusVR\RusVR.dll','BepInEx\plugins\RusVR\OpenXR.dll')) {
            if (-not (Test-Path -LiteralPath (Join-Path $stage $required) -PathType Leaf)) { throw "Publisher package lacks $required." }
        }
        $snapshot = Save-RustlerSnapshot -Game $game -Folder (Join-Path $work 'rollback') -Stage $stage
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update Rustler VR...')
        $changed = $true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $script:RustlerIdentity `
            -KeepExistingRelativePaths @('BepInEx\config\rustler.vr.cfg','BepInEx\config\BepInEx.cfg') -AdoptIdenticalExisting)
        $paths = @('winhttp.dll','BepInEx\core\BepInEx.dll','BepInEx\plugins\RusVR\RusVR.dll','BepInEx\plugins\RusVR\OpenXR.dll',$script:RustlerManifest) |
            ForEach-Object { Join-Path $game $_ }
        if (-not (Confirm-PlacedFilesSurvive -Paths $paths -GameDir $game -NoClear)) { throw 'Required Rustler VR files did not survive installation.' }
        $receipt = if ($env:PCVR_RUSTLER_TEST_RECEIPT) { $env:PCVR_RUSTLER_TEST_RECEIPT } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:RustlerContract -GameDir $game -Version $version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed = $false
        Write-Host "  [OK] Rustler VR $version is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub with the headset and OpenXR runtime ready.' -ForegroundColor White
        Write-Host '  If the game shows a brown void with music, press Esc.' -ForegroundColor Yellow
        Write-Host '  For low performance, lower VR menu > Picture > View distance.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Grand Theft Horse: please return the stolen mount by sundown.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-RustlerSnapshot -Game $game -Snapshot $snapshot; Write-Host '  [!!] Previous Rustler files were restored.' -ForegroundColor Yellow }
            catch { Write-Host "  [!!] Rollback needs review: $($_.Exception.Message)" -ForegroundColor Yellow }
        }
        throw
    } finally { if ($work) { Remove-PCVRInstallerTempSession -Path $work } }
}
if ($env:PCVR_RUSTLER_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-RustlerInstaller; break }
        catch {
            $message = "Rustler VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
