param([switch]$HubConfirmed)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$runtime = if ($env:PCVR_BLVR_TEST_ROOT) { [IO.Path]::GetFullPath($env:PCVR_BLVR_TEST_ROOT) } else {
    Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\BrutalLegendVR'
}
$manifest = Join-Path $runtime '.pcvrhub_brutallegendvr_ownership.csv'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'No Hub-owned Brutal Legend VR runtime was found.' }
$shortcutMarker = Join-Path $runtime '.pcvrhub_blvr_desktop_shortcut.json'
$ownedShortcut = $null
if (Test-Path -LiteralPath $shortcutMarker -PathType Leaf) {
    $ownedShortcut = Get-Content -LiteralPath $shortcutMarker -Raw -Encoding UTF8 | ConvertFrom-Json
}
$game = if ($env:PCVR_BLVR_TEST_GAME) { [IO.Path]::GetFullPath($env:PCVR_BLVR_TEST_GAME) } else {
    Get-PCVRRememberedGameFolder -GameId 'brutal-legend-vr' -StateNames @('base_game_path','user_located') -ProbeFiles @('BrutalLegend.exe')
}
if (-not $game) { $game = Find-SteamGameFolder -AppId '225260' -SteamFolderNames @('BrutalLegend','Brutal Legend') -ProbeExe 'BrutalLegend.exe' -HubGameId 'brutal-legend-vr' }
if (-not $game -or -not (Test-Path -LiteralPath (Join-Path $game 'BrutalLegend.exe') -PathType Leaf)) {
    throw 'Locate the original Steam Brutal Legend game before removing VR mode.'
}
if (Get-Process -Name BrutalLegend -ErrorAction SilentlyContinue) { throw 'Close Brutal Legend before removing VR mode.' }
if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned Brutal Legend VR from '$game'? Type REMOVE") -cne 'REMOVE') { exit 0 }
$publisherUninstall = Join-Path $runtime 'scripts\uninstall.ps1'
if (-not (Test-Path -LiteralPath $publisherUninstall -PathType Leaf)) { throw 'Publisher uninstall script is missing; no files were removed.' }
if ($env:PCVR_HUB_TEST_MODE -ne '1') {
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to restore the original game files with publisher Uninstall...')
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$publisherUninstall+'"'),'-GameDir',('"'+$game+'"')) -WorkingDirectory $runtime -Wait -PassThru -ErrorAction Stop
    if ($null -eq $p.ExitCode -or $p.ExitCode -ne 0) { throw 'Publisher uninstall failed. The Hub runtime and state remain available for recovery.' }
} else {
    foreach ($name in @('d3d9.dll','openxr_loader.dll','blvr-install.json')) {
        $p = Join-Path $game $name
        if (Test-Path -LiteralPath $p -PathType Leaf) { Remove-Item -LiteralPath $p -Force }
    }
}
if (Test-Path -LiteralPath (Join-Path $game 'blvr-install.json') -PathType Leaf) {
    throw 'Publisher ownership is still present in the game. Runtime was retained for recovery.'
}
$result = Uninstall-OwnedModPayload -GameRoot $runtime -Identity 'brutallegendvr'
if ($ownedShortcut) {
    $desktop = if ($env:PCVR_HUB_TEST_MODE -eq '1') { [string]$env:PCVR_BLVR_TEST_DESKTOP } else { [Environment]::GetFolderPath('DesktopDirectory') }
    if ($desktop) {
        $expected = Join-Path $desktop 'Brutal Legend VR.lnk'
        if ([string]$ownedShortcut.Path -ieq $expected -and (Test-Path -LiteralPath $expected -PathType Leaf) -and
            (Get-FileHash -LiteralPath $expected -Algorithm SHA256).Hash -eq [string]$ownedShortcut.Hash) {
            $link = (New-Object -ComObject WScript.Shell).CreateShortcut($expected)
            if ([string]$link.TargetPath -ieq (Join-Path $runtime 'Play VR.cmd')) {
                Remove-Item -LiteralPath $expected -Force -ErrorAction Stop
            }
        }
    }
    Remove-Item -LiteralPath $shortcutMarker -Force -ErrorAction Stop
}
if ($result.Preserved -gt 0) {
    Write-Host '  Some locally changed runtime files were preserved for review.' -ForegroundColor Yellow
} else {
    foreach ($name in @('.pcvrhub_version','.installed_path')) {
        $path = if ($name -eq '.installed_path') { Join-Path $PSScriptRoot $name } else { Join-Path $runtime $name }
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
    }
}
Write-Host '  [OK] The publisher restored game files; Hub-owned VR runtime files were removed.' -ForegroundColor Green
Write-Host '  Game saves, imported model, settings and changed files stay in place.' -ForegroundColor Gray
