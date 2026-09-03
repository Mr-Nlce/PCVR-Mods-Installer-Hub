# Nuclear Option / NOVR installer. The current NOVR release is a small
# plug-in payload, not the former all-in-one GUI installer. This installer
# supplies BepInEx 5, verifies both downloads and merges only NOVR folders.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')

$GAME_APPID = '2168680'
$GAME_EXE = 'NuclearOption.exe'
$NOVR_REPO = 'InfernoSuperNova/novr'
$NOVR_FALLBACK_TAG = '0.4.3'
$NOVR_FALLBACK_URL = 'https://github.com/InfernoSuperNova/novr/releases/download/0.4.3/NOVR.zip'
$NOVR_FALLBACK_SIZE = 1602498
$NOVR_FALLBACK_SHA = 'b324b22e8bb012f31116170793d0a152651a901563b6f5da6c8f19a60e97a343'
$BEPINEX_VERSION = '5.4.23.5'
$BEPINEX_URL = 'https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.5/BepInEx_win_x64_5.4.23.5.zip'
$BEPINEX_SIZE = 639118
$BEPINEX_SHA = '82f9878551030f54657792c0740d9d51a09500eeae1fba21106b0c441e6732c4'

function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "[$Number/$Total] $Text" -ForegroundColor Cyan; Write-Host '----------------------------------------' -ForegroundColor DarkGray }
function Write-OK   { param($Text) Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-Warn { param($Text) Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Stop-NOVRInstaller { param([int]$Code=0) Write-Host ''; Read-Host '  Press Enter to exit' | Out-Null; exit $Code }

function Test-NuclearOptionRoot {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf) -and
           (Test-Path -LiteralPath (Join-Path $Path 'NuclearOption_Data') -PathType Container)
}

function Get-NOVRRelease {
    $fallback = [pscustomobject]@{ Tag=$NOVR_FALLBACK_TAG; Url=$NOVR_FALLBACK_URL; Size=$NOVR_FALLBACK_SIZE; Sha256=$NOVR_FALLBACK_SHA }
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$NOVR_REPO/releases/latest" -Headers @{ 'User-Agent'='PCVR-Mods-Hub' } -TimeoutSec 15 -ErrorAction Stop
        $asset = @($release.assets | Where-Object { $_.name -eq 'NOVR.zip' }) | Select-Object -First 1
        if (-not $asset -or -not $asset.browser_download_url) { return $fallback }
        $digest = [string]$asset.digest
        $sha = if ($digest -match '^sha256:([0-9a-fA-F]{64})$') { $matches[1].ToLowerInvariant() } else { '' }
        return [pscustomobject]@{ Tag=[string]$release.tag_name; Url=[string]$asset.browser_download_url; Size=[long]$asset.size; Sha256=$sha }
    } catch { return $fallback }
}

function Test-DownloadedFile {
    param([string]$Path,[long]$ExpectedSize=0,[string]$ExpectedSha='')
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    if ($ExpectedSize -gt 0 -and (Get-Item -LiteralPath $Path).Length -ne $ExpectedSize) { return $false }
    if ($ExpectedSha) {
        $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
        if ($actual -ne $ExpectedSha) { return $false }
    }
    return $true
}

function Test-NOVRArchive {
    param([string]$ArchivePath,[string]$ExpectedSha='')
    if (-not (Test-DownloadedFile -Path $ArchivePath -ExpectedSha $ExpectedSha)) { return $false }
    # Wildcards between each path component make this independent of the
    # separator stored by the ZIP writer (author archive: '/', Windows test
    # fixture: '\'). All component names still have to occur in order.
    return (Test-ArchiveContains -ArchivePath $ArchivePath -Entry '*plugins*NOVR*NOVR.dll') -and
           (Test-ArchiveContains -ArchivePath $ArchivePath -Entry '*patchers*NOVR*NOVR.Patcher.dll') -and
           (Test-ArchiveContains -ArchivePath $ArchivePath -Entry '*patchers*NOVR*CopyToGame*Plugins*x64*openxr_loader.dll')
}

function Install-NOVRPayload {
    param([Parameter(Mandatory=$true)][string]$ArchivePath,[Parameter(Mandatory=$true)][string]$GameRoot,[string]$Version='unknown',[string]$ExpectedSha='')
    if (-not (Test-NuclearOptionRoot $GameRoot)) { throw 'The selected folder is not a Nuclear Option installation.' }
    if (-not (Test-NOVRArchive -ArchivePath $ArchivePath -ExpectedSha $ExpectedSha)) { throw 'NOVR.zip failed its checksum or required-file check.' }
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('PCVRHub_NOVR_' + [Guid]::NewGuid().ToString('N'))
    $backup = Join-Path $stage '_previous'
    $targets = @(@{ Source='plugins\NOVR'; Target='BepInEx\plugins\NOVR' },@{ Source='patchers\NOVR'; Target='BepInEx\patchers\NOVR' })
    [void][IO.Directory]::CreateDirectory($stage)
    try {
        $extract = Join-Path $stage 'payload'; [void][IO.Directory]::CreateDirectory($extract)
        $result = Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $extract -Label 'NOVR archive' -AllowSkip $false
        if ($result -notin @('ok','manual','retry')) { throw 'NOVR archive extraction was not completed.' }
        foreach ($definition in $targets) { if (-not (Test-Path -LiteralPath (Join-Path $extract $definition.Source) -PathType Container)) { throw "NOVR payload is missing $($definition.Source)." } }
        [void][IO.Directory]::CreateDirectory($backup)
        $moved = New-Object System.Collections.Generic.List[object]
        try {
            foreach ($definition in $targets) {
                $dest = Join-Path $GameRoot $definition.Target; $parent = Split-Path -Parent $dest
                if (-not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
                if (Test-Path -LiteralPath $dest) {
                    $old = Join-Path $backup (($definition.Target -replace '[\\/:*?"<>|]','_'))
                    Move-Item -LiteralPath $dest -Destination $old -Force -ErrorAction Stop
                    [void]$moved.Add([pscustomobject]@{ Destination=$dest; Backup=$old })
                }
                Copy-Item -LiteralPath (Join-Path $extract $definition.Source) -Destination $parent -Recurse -Force -ErrorAction Stop
            }
            $plugin = Join-Path $GameRoot 'BepInEx\plugins\NOVR\NOVR.dll'; $patcher = Join-Path $GameRoot 'BepInEx\patchers\NOVR\NOVR.Patcher.dll'
            if (-not (Test-Path -LiteralPath $plugin -PathType Leaf) -or -not (Test-Path -LiteralPath $patcher -PathType Leaf)) { throw 'NOVR placement did not produce both runtime markers.' }
            [IO.File]::WriteAllText((Join-Path $GameRoot 'BepInEx\plugins\NOVR\version.txt'),([string]$Version).Trim(),(New-Object Text.UTF8Encoding $false))
        } catch {
            foreach ($definition in $targets) { $partial=Join-Path $GameRoot $definition.Target; if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Recurse -Force -ErrorAction SilentlyContinue } }
            foreach ($old in $moved) { if (Test-Path -LiteralPath $old.Backup) { [void][IO.Directory]::CreateDirectory((Split-Path -Parent $old.Destination)); Move-Item -LiteralPath $old.Backup -Destination $old.Destination -Force -ErrorAction SilentlyContinue } }
            throw
        }
    } finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue } }
}

function Ensure-BepInEx5 {
    param([string]$GameRoot,[string]$ArchivePath='')
    $core=Join-Path $GameRoot 'BepInEx\core\BepInEx.dll'; $loader=Join-Path $GameRoot 'winhttp.dll'
    foreach ($parkedName in @('winhttp_bak.dll','winhttp.dll.pcvrhub_off')) { $parked=Join-Path $GameRoot $parkedName; if ((Test-Path -LiteralPath $core) -and -not (Test-Path -LiteralPath $loader) -and (Test-Path -LiteralPath $parked)) { Move-Item -LiteralPath $parked -Destination $loader -Force -ErrorAction Stop } }
    if (Test-Path -LiteralPath $core) {
        try { $major=[Reflection.AssemblyName]::GetAssemblyName($core).Version.Major; if ($major -ge 6) { throw 'BepInEx 6 is installed, but NOVR requires BepInEx 5. Remove or relocate that incompatible loader first.' } }
        catch { if ($_.Exception.Message -match '^BepInEx 6') { throw } }
    }
    if ((Test-Path -LiteralPath $core) -and (Test-Path -LiteralPath $loader)) { return }
    $downloaded=$false
    if (-not $ArchivePath) {
        $ArchivePath=Join-Path ([IO.Path]::GetTempPath()) ('BepInEx_5_4_23_5_' + [Guid]::NewGuid().ToString('N') + '.zip'); $downloaded=$true
        $got=Invoke-SafeDownload -Urls @($BEPINEX_URL) -Destination $ArchivePath -Label "BepInEx $BEPINEX_VERSION" -ManualUrl $BEPINEX_URL -Instructions "Download BepInEx_win_x64_$BEPINEX_VERSION.zip and give that file to the installer." -SkipMessage 'NOVR cannot run without BepInEx 5.'
        if (-not $got) { throw 'BepInEx download was not completed.' }
    }
    try {
        if (-not (Test-DownloadedFile -Path $ArchivePath -ExpectedSize $BEPINEX_SIZE -ExpectedSha $BEPINEX_SHA)) { throw 'BepInEx archive does not match the official 5.4.23.5 release.' }
        if (-not (Test-ArchiveContains -ArchivePath $ArchivePath -Entry 'BepInEx/core/BepInEx.dll') -or -not (Test-ArchiveContains -ArchivePath $ArchivePath -Entry 'winhttp.dll')) { throw 'BepInEx archive structure is incomplete.' }
        $stage=Join-Path ([IO.Path]::GetTempPath()) ('PCVRHub_BepInEx_' + [Guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($stage)
        try { $result=Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $stage -Label 'BepInEx 5 archive' -AllowSkip $false; if ($result -notin @('ok','manual','retry')) { throw 'BepInEx extraction was not completed.' }; foreach ($item in Get-ChildItem -LiteralPath $stage -Force) { Copy-Item -LiteralPath $item.FullName -Destination $GameRoot -Recurse -Force -ErrorAction Stop } }
        finally { if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue } }
        if (-not (Test-Path -LiteralPath $core) -or -not (Test-Path -LiteralPath $loader)) { throw 'BepInEx placement did not produce its loader and core.' }
    } finally { if ($downloaded -and (Test-Path -LiteralPath $ArchivePath)) { Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue } }
}

Clear-Host
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host ' Nuclear Option VR / NOVR Installer' -ForegroundColor Cyan
Write-Host ' Current GitHub release + compatible BepInEx' -ForegroundColor Gray
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host ''; Write-Host ' The current small NOVR.zip is the complete NOVR plug-in.' -ForegroundColor White; Write-Host ' Unlike the retired GUI installer, it does not include BepInEx;' -ForegroundColor White; Write-Host ' this Hub installer adds that required loader for you.' -ForegroundColor White
Show-AntivirusNotice
Read-Host '  Press Enter to start' | Out-Null

Write-Step 1 4 'Locating Nuclear Option'
$gamePath=Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @('Nuclear Option') -ProbeExe $GAME_EXE
while (-not (Test-NuclearOptionRoot $gamePath)) { Write-Warn "Nuclear Option was not found automatically. Paste the folder containing $GAME_EXE."; $gamePath=(Read-Host '  Game folder').Trim().Trim('"').Trim("'"); if (-not (Test-NuclearOptionRoot $gamePath)) { Write-Warn 'That is not the Nuclear Option game root.' } }
Write-OK "Found: $gamePath"
if (Get-Process -Name 'NuclearOption' -ErrorAction SilentlyContinue) { Write-Warn 'Close Nuclear Option before installing or updating NOVR.'; Stop-NOVRInstaller 1 }

try {
    Write-Step 2 4 'Checking BepInEx 5'; Ensure-BepInEx5 -GameRoot $gamePath; Write-OK 'Compatible BepInEx 5 loader is ready.'
    Write-Step 3 4 'Downloading and verifying NOVR'; $release=Get-NOVRRelease; $novrZip=Join-Path ([IO.Path]::GetTempPath()) ('NOVR_' + [Guid]::NewGuid().ToString('N') + '.zip')
    $got=Invoke-SafeDownload -Urls @($release.Url,$NOVR_FALLBACK_URL) -Destination $novrZip -Label "NOVR $($release.Tag)" -ManualUrl 'https://github.com/InfernoSuperNova/novr/releases/latest' -Instructions 'Download the release asset named NOVR.zip and give that file to the installer.' -SkipMessage 'NOVR cannot be installed without its release archive.'
    if (-not $got) { throw 'NOVR download was not completed.' }
    $expectedSize=if ($release.Sha256) { [long]$release.Size } elseif ($release.Tag -eq $NOVR_FALLBACK_TAG) { $NOVR_FALLBACK_SIZE } else { 0 }
    if (-not (Test-DownloadedFile -Path $novrZip -ExpectedSize $expectedSize -ExpectedSha $release.Sha256)) { throw 'The NOVR download does not match the official release metadata.' }
    Write-OK "Verified NOVR $($release.Tag)."
    Write-Step 4 4 'Installing NOVR'; Install-NOVRPayload -ArchivePath $novrZip -GameRoot $gamePath -Version $release.Tag -ExpectedSha $release.Sha256
    $required=@((Join-Path $gamePath 'BepInEx\plugins\NOVR\NOVR.dll'),(Join-Path $gamePath 'BepInEx\patchers\NOVR\NOVR.Patcher.dll')); $recopy={ Install-NOVRPayload -ArchivePath $novrZip -GameRoot $gamePath -Version $release.Tag -ExpectedSha $release.Sha256 }.GetNewClosure()
    if (-not (Confirm-PlacedFilesSurvive -Paths $required -GameDir $gamePath -Recopy $recopy)) { throw 'NOVR files did not survive the antivirus check.' }
    Save-InstalledStamp -GameDir $gamePath -HubDir $PSScriptRoot -Version $release.Tag
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$gamePath,(New-Object Text.UTF8Encoding $false))
    Write-OK 'NOVR is installed and will be detected as VR Ready.'
    Write-Host ''
    Write-Host '  Start Nuclear Option through the Hub or Steam.' -ForegroundColor White
    Write-Host '  The first game launch lets NOVR place its XR support files.' -ForegroundColor White
    Write-Host ''
    Write-Host '  Arm the payload, bank hard, and rule the contested skies.' -ForegroundColor Magenta
} catch { Write-Warn $_.Exception.Message; Stop-NOVRInstaller 1 }
finally { if ($novrZip -and (Test-Path -LiteralPath $novrZip)) { Remove-Item -LiteralPath $novrZip -Force -ErrorAction SilentlyContinue } }
Stop-NOVRInstaller 0
