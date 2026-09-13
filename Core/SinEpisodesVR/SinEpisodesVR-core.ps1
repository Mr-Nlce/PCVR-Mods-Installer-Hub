. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'SiN Episodes: Emergence VR Installer'
$repo = 'RototRobot/Sin-Episodes-VR-Port'
$appId = '1300'
$pinnedTag = '1.0.0'
$pinnedUrl = 'https://github.com/RototRobot/Sin-Episodes-VR-Port/releases/download/1.0.0/SiN-VR-v1.0.0.zip'

function Write-SinHeader {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  SiN Episodes: Emergence' -ForegroundColor Cyan
    Write-Host '  Installs: SiN VR by RototRobot' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
}
function Write-SinStep([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-SinOk([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-SinInfo([string]$Text) { Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-SinWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Pause-Sin([string]$Text='Press Enter to continue...') { Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }
function Set-SinClipboardText([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    try {
        Set-Clipboard -Value $Text -ErrorAction Stop
        $readBack = [string](Get-Clipboard -Raw -ErrorAction Stop)
        if ($readBack.TrimEnd([char[]]"`r`n") -ceq $Text) { return $true }
    } catch {}
    try {
        $clip = Join-Path $env:SystemRoot 'System32\clip.exe'
        if (Test-Path -LiteralPath $clip -PathType Leaf) {
            $Text | & $clip
            Start-Sleep -Milliseconds 80
            $readBack = [string](Get-Clipboard -Raw -ErrorAction Stop)
            if ($readBack.TrimEnd([char[]]"`r`n") -ceq $Text) { return $true }
        }
    } catch {}
    return $false
}
function Test-SinSamePath([string]$Left,[string]$Right) {
    if (-not $Left -or -not $Right) { return $false }
    try {
        $a = [IO.Path]::GetFullPath($Left).TrimEnd([char[]]'\/')
        $b = [IO.Path]::GetFullPath($Right).TrimEnd([char[]]'\/')
        return $a.Equals($b,[StringComparison]::OrdinalIgnoreCase)
    } catch { return $false }
}
function Set-SinCfgValue {
    param([string]$Text,[string]$Name,[string]$Value)
    $line = "$Name = $Value"
    $pattern = '(?m)^\s*' + [regex]::Escape($Name) + '\s*=.*$'
    if ($Text -match $pattern) { return [regex]::Replace($Text,$pattern,$line) }
    return ($Text.TrimEnd() + "`r`n$line`r`n")
}
function Test-SinGpuTdrEvidence {
    param([string]$GameRoot)
    try {
        $crash = Join-Path $GameRoot 'sinvr_crash.log'
        $dxvk = Join-Path $GameRoot 'SinEpisodes_d3d9.log'
        if (-not (Test-Path -LiteralPath $crash -PathType Leaf) -or -not (Test-Path -LiteralPath $dxvk -PathType Leaf)) { return $false }
        return ([IO.File]::ReadAllText($crash) -match '=== RENDER STALL ===' -and
                [IO.File]::ReadAllText($dxvk) -match 'VK_ERROR_DEVICE_LOST')
    } catch { return $false }
}
function Test-SinOversizeFailureEvidence {
    param([string]$GameRoot)
    try {
        foreach ($name in @('sinvr.log','SinEpisodes_d3d9.log','SinEpisodes_laa_d3d9.log')) {
            $path = Join-Path $GameRoot $name
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
            $log = [IO.File]::ReadAllText($path)
            if ($log -match 'TextureUsesUnsupportedFormat|VK_ERROR_SURFACE_LOST_KHR') { return $true }
        }
    } catch {}
    return $false
}
function Get-SinRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers @{'User-Agent'='PCVR-Mods-Hub';'Accept'='application/vnd.github+json'} -TimeoutSec 15 -ErrorAction Stop
        $asset = @($release.assets | Where-Object { $_.name -match '(?i)^SiN-VR-.+\.zip$' } | Select-Object -First 1)[0]
        if (-not $asset -or -not $asset.browser_download_url) { throw 'The latest release has no SiN VR ZIP asset.' }
        return [pscustomobject]@{ Tag=[string]$release.tag_name; Url=[string]$asset.browser_download_url; Name=[string]$asset.name }
    } catch {
        Write-SinWarn "GitHub did not answer; using the last known $pinnedTag release URL."
        return [pscustomobject]@{ Tag=$pinnedTag; Url=$pinnedUrl; Name='SiN-VR-v1.0.0.zip' }
    }
}
function Copy-SinTree([string]$Source,[string]$Destination) {
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Missing package folder: $Source" }
    if (-not (Test-Path -LiteralPath $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force }
}

trap {
    Write-SinWarn ("Setup could not finish: " + $_.Exception.Message)
    Write-Host '  Nothing unverified is marked as installed. Run setup again to retry.' -ForegroundColor Gray
    Pause-Sin 'Press Enter to exit'
    exit 1
}

Write-SinHeader
Write-Host '  Native stereo, roomscale and full motion-controlled weapons.' -ForegroundColor White
Write-Host '  SteamVR and a Vulkan-capable GPU are required.' -ForegroundColor White
Write-Host '  Before setup, run the unmodded game once to the main menu,' -ForegroundColor Yellow
Write-Host '  then close it so the required configuration can be verified.' -ForegroundColor Yellow
Write-Host '  The author supports the Steam build; other legitimate copies' -ForegroundColor Yellow
Write-Host '  use a best-effort direct route and must work in flat mode first.' -ForegroundColor Yellow
Write-Host ''
Write-SinWarn 'Windows 11 Smart App Control can block this unsigned mod without an allow-once option.'
Show-AntivirusNotice -Compact
Pause-Sin 'Press Enter to start setup...'

Write-SinHeader
Write-SinStep 1 5 'Locating the game and its first-run configuration'
$game = Find-SteamGameFolder -AppId $appId -SteamFolderNames @('SiN Episodes Emergence') -ProbeExe 'SinEpisodes.exe' -HubGameId 'sin-episodes-emergence'
if (-not $game) { $game = Get-GameFolderInteractive -GameName 'SiN Episodes: Emergence' -ProbeFile 'SinEpisodes.exe' -ManualUrl 'https://store.steampowered.com/app/1300/' }
if ($game -in @('quit','skip',$null)) { throw 'No verified SiN Episodes folder was selected.' }
Write-SinOk "Found: $game"
$steamGame = Find-SteamGameFolder -AppId $appId -SteamFolderNames @('SiN Episodes Emergence') -ProbeExe 'SinEpisodes.exe' -HubGameId '__steam_probe_only__'
$isSteamInstall = Test-SinSamePath -Left $game -Right $steamGame
if ($isSteamInstall) { Write-SinOk 'Steam-managed game installation detected.' }
else { Write-SinWarn 'Non-Steam game folder detected. This route is best effort and is not confirmed by the mod author.' }
$stockConfig = Join-Path $game 'SE1\cfg\config.cfg'
if (-not (Test-Path -LiteralPath $stockConfig -PathType Leaf)) {
    Write-SinWarn 'The game has not created its configuration yet.'
    Write-Host $(if ($isSteamInstall) { '  SiN will open through Steam now. Let it reach the main menu,' } else { '  The unmodded game will open directly. Let it reach the main menu,' }) -ForegroundColor White
    Write-Host '  quit the game, then return here.' -ForegroundColor White
    Pause-Sin $(if ($isSteamInstall) { 'Press Enter to start SiN Episodes through Steam...' } else { 'Press Enter to start the unmodded game...' })
    if ($isSteamInstall) { try { Start-Process "steam://rungameid/$appId" } catch {} }
    else { try { Start-Process -FilePath (Join-Path $game 'SinEpisodes.exe') -WorkingDirectory $game } catch {} }
    Pause-Sin 'After closing the game, press Enter to continue...'
    if (-not (Test-Path -LiteralPath $stockConfig -PathType Leaf)) { throw 'The first-run config is still missing. Start the game once, close it, then rerun setup.' }
}
Write-SinOk 'The base-game configuration exists.'

Write-SinStep 2 5 'Choosing optional VR improvements'
Write-Host '  [1] Install GUI scaling for readable Load / Save screens (recommended)' -ForegroundColor White
Write-Host '  [2] Keep the original GUI size' -ForegroundColor Gray
$guiChoice = ''
while ($guiChoice -notin @('1','2')) { $guiChoice = (Read-Host '  Choice (1/2)').Trim() }
Write-Host ''
Write-Host '  [1] Enable gesture reload and disable automatic empty reload' -ForegroundColor White
Write-Host '  [2] Keep button reload and automatic empty reload (recommended)' -ForegroundColor Gray
$reloadChoice = ''
while ($reloadChoice -notin @('1','2')) { $reloadChoice = (Read-Host '  Choice (1/2)').Trim() }

Write-SinStep 3 5 'Downloading the current official release'
$release = Get-SinRelease
$temp = Join-Path ([IO.Path]::GetTempPath()) ('SinVR_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
$archive = Join-Path $temp $release.Name
$downloaded = Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "SiN VR $($release.Tag)" -ManualUrl "https://github.com/$repo/releases" -AllowSkip $false
if (-not $downloaded) { throw 'The official SiN VR archive was not obtained.' }
Write-SinOk "Official release $($release.Tag) ready."

Write-SinStep 4 5 'Installing with exact-file recovery'
$extract = Join-Path $temp 'extract'
$result = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'SiN VR archive' -AllowSkip $false
if ($result -notin @('ok','manual')) { throw 'Archive extraction was not completed.' }
$main = Get-ChildItem -LiteralPath $extract -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'sinvr.dll') } | Select-Object -First 1 -ExpandProperty FullName
if (-not $main) { throw 'The documented SiN VR main payload was not found.' }
$stage = Join-Path $temp 'stage'
Copy-SinTree -Source $main -Destination $stage
if ($guiChoice -eq '1') {
    $gui = Get-ChildItem -LiteralPath $extract -Directory -Recurse | Where-Object { $_.Name -eq 'Optional - GUI Scaling' } | Select-Object -First 1 -ExpandProperty FullName
    Copy-SinTree -Source $gui -Destination $stage
}
if ($reloadChoice -eq '1') {
    $reload = Get-ChildItem -LiteralPath $extract -Directory -Recurse | Where-Object { $_.Name -eq 'Optional - Arcade Reload files' } | Select-Object -First 1 -ExpandProperty FullName
    Copy-SinTree -Source $reload -Destination $stage
}
$hubLauncherName = 'Start SiN Episodes VR.bat'
$hubLauncherBody = @('@echo off','setlocal','cd /d "%~dp0"')
if ($isSteamInstall) { $hubLauncherBody += 'start "" "steam://rungameid/1300"' }
else { $hubLauncherBody += 'start "" "%~dp0sinvr_launcher.exe" --exe "%~dp0SinEpisodes.exe" -novid -windowed' }
[IO.File]::WriteAllLines((Join-Path $stage $hubLauncherName),$hubLauncherBody,[Text.Encoding]::ASCII)
$liveProxy = Join-Path $game 'dinput8.dll'
$parkedProxy = Join-Path $game 'dinput8.dll.pcvrhub_off'
if ((Test-Path -LiteralPath $liveProxy) -and (Test-Path -LiteralPath $parkedProxy)) { throw 'Both active and parked dinput8.dll files exist. Remove the duplicate before updating.' }
if ((-not (Test-Path -LiteralPath $liveProxy)) -and (Test-Path -LiteralPath $parkedProxy)) { Rename-Item -LiteralPath $parkedProxy -NewName 'dinput8.dll'; Write-SinOk 'Parked VR proxy restored before update.' }
Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'sinvr' | Out-Null
$cfg = Join-Path $game 'sinvr.cfg'
$cfgExisted = Test-Path -LiteralPath $cfg -PathType Leaf
$text = if ($cfgExisted) { [IO.File]::ReadAllText($cfg) } else { "# Created by PCVR Mods Hub; the mod fills unspecified settings with defaults.`r`n" }
$writeCfg = $false
$tdrDetected = Test-SinGpuTdrEvidence -GameRoot $game
$oversizeFailureDetected = Test-SinOversizeFailureEvidence -GameRoot $game
$hasOversizeSetting = ($text -match '(?m)^\s*vr_allow_oversize_window\s*=')
$needsRenderRecovery = ($tdrDetected -or $oversizeFailureDetected)
if (-not $cfgExisted -or $tdrDetected) {
    if ($needsRenderRecovery -and $cfgExisted) {
        $recoveryDir = Join-Path $game '.pcvrhub_sinvr_user_backup'
        $recoveryCfg = Join-Path $recoveryDir 'sinvr.cfg.before-gpu-recovery'
        if (-not (Test-Path -LiteralPath $recoveryCfg -PathType Leaf)) {
            New-Item -ItemType Directory -Path $recoveryDir -Force | Out-Null
            Copy-Item -LiteralPath $cfg -Destination $recoveryCfg -Force -ErrorAction Stop
        }
    }
    # These are the mod's documented performance levers.  Open-all portals and
    # sample-rate shading are expensive experimental choices; begin with them
    # off and at a conservative resolution rather than risking a GPU TDR.
    $text = Set-SinCfgValue -Text $text -Name 'engine_portals_open_all' -Value '0'
    $text = Set-SinCfgValue -Text $text -Name 'dxvk_sample_rate_shading' -Value '0'
    $text = Set-SinCfgValue -Text $text -Name 'vr_resolution_scale' -Value '0.75'
    $writeCfg = $true
}
if (-not $cfgExisted -or -not $hasOversizeSetting -or $needsRenderRecovery) {
    if ($needsRenderRecovery -and $cfgExisted) {
        $recoveryDir = Join-Path $game '.pcvrhub_sinvr_user_backup'
        $recoveryCfg = Join-Path $recoveryDir 'sinvr.cfg.before-gpu-recovery'
        if (-not (Test-Path -LiteralPath $recoveryCfg -PathType Leaf)) {
            New-Item -ItemType Directory -Path $recoveryDir -Force | Out-Null
            Copy-Item -LiteralPath $cfg -Destination $recoveryCfg -Force -ErrorAction Stop
        }
    }
    # The author's troubleshooting route recommends 0 when large headset-sized
    # windows fail.  Make it the safe first-run default; preserve an explicit 1
    # on a working existing setup and only repair it after matching log evidence.
    $text = Set-SinCfgValue -Text $text -Name 'vr_allow_oversize_window' -Value '0'
    $writeCfg = $true
}
if ($needsRenderRecovery) { Write-SinWarn 'A previous VR render/window failure was found. Conservative settings were applied; the prior config remains in .pcvrhub_sinvr_user_backup.' }
elseif (-not $cfgExisted) { Write-SinInfo 'Conservative first-launch rendering settings prepared.' }
elseif (-not $hasOversizeSetting) { Write-SinInfo 'Safe headset-window compatibility was added without changing your other VR settings.' }
if ($reloadChoice -eq '1') {
    $text = Set-SinCfgValue -Text $text -Name 'arcade_reload' -Value '1'
    $writeCfg = $true
}
if ($writeCfg) {
    [IO.File]::WriteAllText($cfg,$text,(New-Object Text.UTF8Encoding($false)))
}
$watch = @('sinvr.dll','sinvr_launcher.exe','dinput8.dll','d3d9.dll','openvr_api.dll',$hubLauncherName) | ForEach-Object { Join-Path $game $_ }
foreach ($required in $watch) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Installed-file verification failed: $(Split-Path -Leaf $required)" } }
$recoverSin = {
    Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity 'sinvr' | Out-Null
}.GetNewClosure()
if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recoverSin)) { throw 'One or more required SiN VR binaries did not survive the antivirus check.' }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$game,(New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version'),[string]$release.Tag,(New-Object Text.UTF8Encoding($false)))
Save-InstalledStamp -GameDir $game -Version ([string]$release.Tag)
Write-SinOk 'Main VR files and recoverable originals verified.'
if ($guiChoice -eq '1') { Write-SinOk 'GUI scaling installed.' }
if ($reloadChoice -eq '1') { Write-SinOk 'Gesture reload files and setting installed.' }

$launcher = Join-Path $game 'sinvr_launcher.exe'
if ($isSteamInstall) {
    Write-SinStep 5 5 'Setting the required Steam launch route'
    $launchOption = '"' + $launcher + '" %command% -novid -windowed'
    $clipboardReady = Set-SinClipboardText -Text $launchOption
    if ($clipboardReady) { Write-SinOk 'The exact launch option was copied and verified in the clipboard.' }
    else { Write-SinWarn 'The clipboard was unavailable. Copy the complete gray line below.' }
    Write-Host '  Launch option:' -ForegroundColor White
    Write-Host "  $launchOption" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Steam Properties opens next:' -ForegroundColor White
    Write-Host '    1. Clear the existing Launch Options field.' -ForegroundColor Gray
    Write-Host '    2. Paste with Ctrl+V, or copy the gray line above.' -ForegroundColor Gray
    Write-Host '    3. Close Properties and return here.' -ForegroundColor Gray
    Write-Host ''
    Write-SinWarn 'Do not add -w or -h; they override the headset resolution.'
    Pause-Sin 'Press Enter to open Steam Properties...'
    try { Start-Process "steam://gameproperties/$appId" } catch {}
    [void](Set-SinClipboardText -Text $launchOption)
    Pause-Sin 'After pasting and closing Properties, press Enter...'
} else {
    Write-SinStep 5 5 'Creating the DVD / standalone launch route'
    $directArguments = '--exe "' + (Join-Path $game 'SinEpisodes.exe') + '" -novid -windowed'
    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcut = $null
    if ($desktop) {
        $shortcut = New-DesktopShortcut -LnkPath (Join-Path $desktop 'SiN Episodes VR.lnk') -TargetPath $launcher -WorkingDir $game -IconPath (Join-Path $game 'SinEpisodes.exe') -Arguments $directArguments -Description 'Start SiN Episodes: Emergence in VR'
    }
    if ($shortcut) { Write-SinOk 'Desktop shortcut created: SiN Episodes VR' }
    else { Write-SinWarn 'A desktop shortcut could not be created; Start in VR in the Hub still works.' }
    Write-Host '  Direct launch command:' -ForegroundColor White
    Write-Host ('  "' + $launcher + '" ' + $directArguments) -ForegroundColor DarkGray
    Write-Host ''
    Write-SinInfo 'No Steam launch option is needed for this installation.'
}
Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host '  SiN VR installed.' -ForegroundColor Green
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host ''
if ($isSteamInstall) { Write-Host '  Start SteamVR, then use Start in VR in the Hub or Play in Steam.' -ForegroundColor White }
else { Write-Host '  Start SteamVR, then use Start in VR or the desktop shortcut.' -ForegroundColor White }
Write-Host '  If New Game returns to a silent menu, test New Game once in flat mode.' -ForegroundColor Yellow
Write-Host '  Flat works: the current VR build is crashing. Flat also fails: repair' -ForegroundColor Gray
Write-Host '  or replace the base-game copy before troubleshooting the VR mod.' -ForegroundColor Gray
Write-Host '  Make a save before entering either car; the current build can eject' -ForegroundColor Gray
Write-Host '  Blade and soft-lock those two sequences.' -ForegroundColor Gray
Write-Host ''
Write-Host '  Blade is back - Freeport never learned to stay quiet.' -ForegroundColor Magenta
Write-Host ''
Pause-Sin 'Press Enter to exit'
