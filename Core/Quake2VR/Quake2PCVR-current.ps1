$ErrorActionPreference = 'Stop'

# This route is also a supported standalone entry point.  Load every shared
# helper it calls here instead of relying on Quake2VR-core.ps1 to have placed
# the functions in the parent session first.
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$repo = 'GameOrDie007/Quake-II-PCVR'
$pinnedTag = 'v1.0'
$pinnedUrl = 'https://github.com/GameOrDie007/Quake-II-PCVR/releases/download/v1.0/quake2-vr-pc.zip'

function Write-Q2Header {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Quake 2 VR' -ForegroundColor Cyan
    Write-Host '  Installs: Quake II PCVR by GameOrDie007' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function Write-Q2Step([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-Q2Ok([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-Q2Info([string]$Text) { Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-Q2Warn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Pause-Q2([string]$Text='Press Enter to continue...') { Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }
function Get-Q2Release {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers @{'User-Agent'='PCVR-Mods-Hub';'Accept'='application/vnd.github+json'} -TimeoutSec 15 -ErrorAction Stop
        $asset = @($release.assets | Where-Object { $_.name -match '(?i)^quake2-vr-pc\.zip$' } | Select-Object -First 1)[0]
        if (-not $asset -or -not $asset.browser_download_url) { throw 'The latest release has no PCVR archive.' }
        return [pscustomobject]@{ Tag=[string]$release.tag_name; Url=[string]$asset.browser_download_url }
    } catch {
        Write-Q2Warn "GitHub did not answer; using the last known $pinnedTag release URL."
        return [pscustomobject]@{ Tag=$pinnedTag; Url=$pinnedUrl }
    }
}
function Test-Q2WritableRoot([string]$Root) {
    try {
        if (-not (Test-Path -LiteralPath $Root)) { New-Item -ItemType Directory -Path $Root -Force | Out-Null }
        $probe = Join-Path $Root ('.pcvr_write_' + [Guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText($probe,'ok'); Remove-Item -LiteralPath $probe -Force
        return $true
    } catch { return $false }
}

trap {
    Write-Q2Warn ("Setup could not finish: " + $_.Exception.Message)
    Write-Host '  No incomplete folder is marked VR Ready. Run setup again to retry.' -ForegroundColor Gray
    Pause-Q2 'Press Enter to exit'
    exit 1
}

Write-Q2Header
Write-Host '  The maintained OpenXR port supports VDXR, SteamVR and Oculus.' -ForegroundColor White
Write-Host '  It builds a separate portable copy and leaves the Steam game alone.' -ForegroundColor White
Show-AntivirusNotice -Compact
Pause-Q2 'Press Enter to start setup...'

Write-Q2Header
Write-Q2Step 1 4 'Locating your original Quake II data'
$source = Find-SteamGameFolder -AppId '2320' -SteamFolderNames @('Quake 2','Quake II') -ProbeExe 'baseq2\pak0.pak' -GogNames @('Quake II','Quake 2') -HubGameId 'quake-2-vr'
if (-not $source) { $source = Get-GameFolderInteractive -GameName 'Quake II' -ProbeFile 'baseq2\pak0.pak' -ManualUrl 'https://store.steampowered.com/app/2320/' }
if ($source -in @('quit','skip',$null)) { throw 'No folder containing baseq2\pak0.pak was selected.' }
Write-Q2Ok "Original game found: $source"

Write-Q2Step 2 4 'Choosing the portable PCVR folder'
$parent = $null
foreach ($root in @('C:\Games','D:\Games','E:\Games')) { if (Test-Q2WritableRoot $root) { $parent = $root; break } }
if (-not $parent) {
    Write-Q2Warn 'No standard Games folder is writable.'
    while (-not $parent) {
        $candidate = (Read-Host '  Enter a writable install root').Trim().Trim('"')
        if (Test-Q2WritableRoot $candidate) { $parent = $candidate } else { Write-Q2Warn "Not writable: $candidate" }
    }
}
$target = Join-Path $parent 'Quake II PCVR'
if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
Write-Q2Ok "PCVR folder: $target"

Write-Q2Step 3 4 'Downloading and preparing the current OpenXR port'
$release = Get-Q2Release
$temp = Join-Path ([IO.Path]::GetTempPath()) ('Quake2PCVR_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$archive = Join-Path $temp 'quake2-vr-pc.zip'
$got = Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Quake II PCVR $($release.Tag)" -ManualUrl "https://github.com/$repo/releases" -AllowSkip $false
if (-not $got) { throw 'The official Quake II PCVR archive was not obtained.' }
$extract = Join-Path $temp 'extract'
$expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Quake II PCVR archive' -AllowSkip $false
if ($expanded -notin @('ok','manual')) { throw 'Archive extraction was not completed.' }
$payload = Get-ChildItem -LiteralPath $extract -Directory -Recurse | Where-Object { (Test-Path -LiteralPath (Join-Path $_.FullName 'yquake2.exe')) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'tools\setup.ps1')) } | Select-Object -First 1 -ExpandProperty FullName
if (-not $payload) { throw 'The documented Quake II PCVR payload was not found.' }
Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity 'quake2pcvr' -AdoptIdenticalExisting | Out-Null
$runtimeWatch = @('yquake2.exe','libopenxr_loader.dll','SDL2.dll','ref_gl1.dll','baseq2\game.dll') | ForEach-Object { Join-Path $target $_ }
foreach ($required in $runtimeWatch) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Installed runtime verification failed: $(Split-Path -Leaf $required)" } }
$recoverQ2 = {
    Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity 'quake2pcvr' -AdoptIdenticalExisting | Out-Null
}.GetNewClosure()
if (-not (Confirm-PlacedFilesSurvive -Paths $runtimeWatch -GameDir $target -Recopy $recoverQ2)) { throw 'One or more required Quake II PCVR binaries did not survive the antivirus check.' }
Write-Q2Ok "Official port $($release.Tag) downloaded."

Write-Q2Step 4 4 'Copying owned game data and optional Team Beef assets'
Write-Q2Info 'The official setup copies Quake II, owned mission packs and music.'
Write-Q2Info "If missing, it also downloads Team Beef's optional HD assets once (about 169 MB)."
$setup = Join-Path $target 'tools\setup.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -InstallDir $target -Quake2Dir $source -Extras yes
if ($LASTEXITCODE -ne 0) { throw "The official Quake II data setup returned exit code $LASTEXITCODE." }
$launch = Join-Path $target 'Play Quake II VR.bat'
if (-not (Test-Path -LiteralPath $launch) -or -not (Test-Path -LiteralPath (Join-Path $target 'baseq2\pak0.pak'))) { throw 'Final Quake II PCVR verification failed.' }
[IO.File]::WriteAllText((Join-Path $target '.pcvrhub_ready'),[string]$release.Tag,(New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path_pcvr'),$target,(New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),[string]$release.Tag,(New-Object Text.UTF8Encoding($false)))
Save-InstalledStamp -GameDir $target -Version ([string]$release.Tag)
$desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Quake 2 OpenXR VR.lnk'
New-DesktopShortcut -LnkPath $desktop -TargetPath $launch -WorkingDir $target -IconPath "$(Join-Path $target 'yquake2.exe'),0" -Description 'Launch Quake II PCVR' | Out-Null
foreach ($expansion in @('The Reckoning','Ground Zero')) {
    $expLaunch = Join-Path $target "Play $expansion VR.bat"
    if (Test-Path -LiteralPath $expLaunch) {
        New-DesktopShortcut -LnkPath (Join-Path ([Environment]::GetFolderPath('Desktop')) "Quake 2 $expansion VR.lnk") -TargetPath $expLaunch -WorkingDir $target -IconPath "$(Join-Path $target 'yquake2.exe'),0" -Description "Launch Quake II: $expansion in VR" | Out-Null
    }
}
Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
Write-Q2Ok 'Base game and available extras verified.'

Write-Host ''
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host '  Quake II PCVR installed.' -ForegroundColor Green
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host ''
Write-Host '  Start your OpenXR runtime, then use the OpenXR button in the Hub.' -ForegroundColor White
Write-Host '  VR and PC options are available in the game menus.' -ForegroundColor Gray
Write-Host ''
Write-Host '  Storm Stroggos - the railgun does the talking.' -ForegroundColor Magenta
Write-Host ''
Pause-Q2 'Press Enter to exit'
