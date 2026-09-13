param(
    [string]$GameRoot = '',
    [string]$StateRoot = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$APP_ID = '1300'
$GAME_ID = 'sin-episodes-emergence'
$GAME_EXE = 'SinEpisodes.exe'
$IDENTITY = 'sinvr'
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }

function Finish-SinUninstall([int]$Code) {
    if (-not $NoPause) {
        Write-Host ''
        Read-Host 'Press Enter to exit' | Out-Null
    }
    exit $Code
}

function Test-SinGameRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-PathLexical $Path $GAME_EXE) -PathType Leaf))
}

try {
    # An explicit test/repair path wins, followed by the legacy marker. Normal
    # store discovery then checks Steam and finally the checksum-verified
    # LocalAppData Locate/installed_path state. This last source is essential
    # for legitimate DVD/standalone copies after the user replaces the Hub.
    if (-not (Test-SinGameRoot $GameRoot)) {
        try {
            $recorded = ([IO.File]::ReadAllText((Join-Path $StateRoot '.installed_path'))).Trim()
            if (Test-SinGameRoot $recorded) { $GameRoot = $recorded }
        } catch {}
    }
    if (-not (Test-SinGameRoot $GameRoot)) {
        $GameRoot = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('SiN Episodes Emergence') `
            -ProbeExe $GAME_EXE -HubGameId $GAME_ID
    }
    if (-not (Test-SinGameRoot $GameRoot)) {
        Write-Host '[X] SiN Episodes: Emergence was not found. No files were changed.' -ForegroundColor Red
        Finish-SinUninstall 1
    }

    $manifest = Join-PathLexical $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        Write-Host '[X] No Hub ownership record was found. Nothing was guessed or deleted.' -ForegroundColor Red
        Write-Host '    Use the uninstall guide for a manual review.' -ForegroundColor Gray
        Finish-SinUninstall 1
    }
    if (-not $HubConfirmed) {
        $answer = ('' + (Read-Host "Remove SiN VR from '$GameRoot'? Type REMOVE")).Trim()
        if ($answer -cne 'REMOVE') {
            Write-Host 'Cancelled. Nothing changed.' -ForegroundColor Gray
            Finish-SinUninstall 0
        }
    }

    $hubLauncher = Join-PathLexical $GameRoot 'Start SiN Episodes VR.bat'
    $wasSteamRoute = $false
    if (Test-Path -LiteralPath $hubLauncher -PathType Leaf) {
        try { $wasSteamRoute = ([IO.File]::ReadAllText($hubLauncher) -match 'steam://rungameid/1300') } catch {}
    } elseif ([IO.Path]::GetFullPath($GameRoot) -match '(?i)[\\/]steamapps[\\/]common[\\/]') {
        $wasSteamRoute = $true
    }

    $result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY `
        -ParkedAlternates @{'dinput8.dll'='dinput8.dll.pcvrhub_off'}
    if (-not $result.Found) {
        Write-Host '[X] The ownership record disappeared before removal. No files were guessed.' -ForegroundColor Red
        Finish-SinUninstall 1
    }

    # These files are created by the Hub/mod at runtime and therefore may not
    # occur in the downloaded ownership manifest. Their names are unique to
    # this integration; configs, saves and unknown files remain untouched.
    foreach ($generated in @('SinEpisodes_laa.exe','SinEpisodes_laa_d3d9.log','dxvk.conf','dxvk.conf.superseded-by-launcher')) {
        Remove-Item -LiteralPath (Join-PathLexical $GameRoot $generated) -Force -ErrorAction SilentlyContinue
    }
    $stockConfig = Join-PathLexical $GameRoot 'SE1\cfg\config.cfg'
    if (Test-Path -LiteralPath $stockConfig -PathType Leaf) {
        $text = [IO.File]::ReadAllText($stockConfig)
        $restored = [regex]::Replace($text,'(?m)^(\s*crosshair\s+)"0"','$1"1"')
        if ($restored -ne $text) {
            [IO.File]::WriteAllText($stockConfig,$restored,(New-Object Text.UTF8Encoding($false)))
        }
    }
    foreach ($name in @('.pcvrhub_version','.pcvrhub.install.json')) {
        Remove-Item -LiteralPath (Join-PathLexical $GameRoot $name) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath (Join-Path $StateRoot '.installed_path') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $StateRoot '.installed_version') -Force -ErrorAction SilentlyContinue

    $desktop = [Environment]::GetFolderPath('Desktop')
    if ($desktop) {
        $shortcutPath = Join-Path $desktop 'SiN Episodes VR.lnk'
        $expectedShortcutTarget = Join-PathLexical $GameRoot 'sinvr_launcher.exe'
        if (Test-Path -LiteralPath $shortcutPath -PathType Leaf) {
            try {
                $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
                if ([IO.Path]::GetFullPath([string]$shortcut.TargetPath).Equals(
                    [IO.Path]::GetFullPath($expectedShortcutTarget),[StringComparison]::OrdinalIgnoreCase)) {
                    Remove-Item -LiteralPath $shortcutPath -Force
                }
            } catch {}
        }
    }

    Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host '[KEEP] sinvr.cfg and its calibration were retained.' -ForegroundColor Gray
    Write-Host '[KEEP] Saves and unrelated files were untouched.' -ForegroundColor Gray
    if ($wasSteamRoute) {
        Write-Host ''
        Write-Host 'Steam Properties can now be opened so you can clear the removed SiN launch option.' -ForegroundColor Yellow
        if (-not $NoPause) {
            Read-Host 'Press Enter to open Steam Properties' | Out-Null
            try { Start-Process "steam://gameproperties/$APP_ID" } catch {}
        }
    } else {
        Write-Host '[OK] No Steam launch option was used for this DVD / standalone installation.' -ForegroundColor Green
    }
    Finish-SinUninstall 0
} catch {
    Write-Host ''
    Write-Host '[X] SiN VR could not be removed safely.' -ForegroundColor Red
    Write-Host "    $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host '    No unverified file was deleted. You can retry or use the uninstall guide.' -ForegroundColor Gray
    Finish-SinUninstall 1
}
