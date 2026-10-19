param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
function Finish-ForsakenRemoval([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
try {
    $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FORSAKEN_TEST_RECEIPT) {
        [IO.Path]::GetFullPath($env:PCVR_FORSAKEN_TEST_RECEIPT)
    } else { Join-Path $PSScriptRoot '.installed_path' }
    if (-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
        $GameRoot = ([string](Get-Content -LiteralPath $receipt -Raw)).Trim().Trim('"')
    }
    if (-not $GameRoot -or -not (Test-Path -LiteralPath $GameRoot -PathType Container)) {
        Write-Host '  No recorded Forsaken VR installation was found.' -ForegroundColor Yellow
        Finish-ForsakenRemoval 0
    }
    $GameRoot = [IO.Path]::GetFullPath($GameRoot)
    $probe = Join-Path $GameRoot '.pcvrhub_forsaken_ownership.csv'
    if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) {
        throw 'The Hub ownership record is missing. Nothing was removed.'
    }
    if (Get-Process -Name projectx -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($GameRoot,[StringComparison]::OrdinalIgnoreCase) }) {
        throw 'Close Forsaken VR before removing the Hub installation.'
    }
    Write-Host '  The Hub removes only unchanged runtime files in its ownership record.' -ForegroundColor White
    Write-Host '  Game data, saves, settings, Remastered and changed files remain.' -ForegroundColor White
    if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned Forsaken VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
        Finish-ForsakenRemoval 0
    }
    $rows = @(Import-Csv -LiteralPath $probe -ErrorAction Stop)
    if ($rows.Count -lt 20) { throw 'The ownership record is incomplete. Nothing was removed.' }
    $rootPrefix = $GameRoot.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    $targets = New-Object 'System.Collections.Generic.List[object]'
    foreach ($row in $rows) {
        $relative = [string]$row.Path
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') {
            throw 'The ownership record contains an unsafe path. Nothing was removed.'
        }
        $target = [IO.Path]::GetFullPath((Join-Path $GameRoot $relative))
        if (-not $target.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase)) {
            throw 'The ownership record points outside the VR folder. Nothing was removed.'
        }
        $targets.Add([pscustomobject]@{Path=$target;Hash=[string]$row.SHA256})
    }
    $removed = 0; $retained = 0
    foreach ($entry in $targets) {
        if (-not (Test-Path -LiteralPath $entry.Path -PathType Leaf)) { continue }
        $actual = (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash
        if ($actual -ine $entry.Hash) { $retained++; continue }
        Remove-Item -LiteralPath $entry.Path -Force -ErrorAction Stop
        $removed++
    }
    # Keep proof if a required launcher or executable could not be removed.
    foreach ($required in @('Forsaken VR.cmd','game\projectx.exe','game\libopenxr_loader.dll')) {
        if (Test-Path -LiteralPath (Join-Path $GameRoot $required) -PathType Leaf) {
            throw 'A VR runtime file remains (possibly modified). Review it before clearing Hub state.'
        }
    }
    foreach ($marker in @($probe,(Join-Path $GameRoot '.pcvrhub_version'))) {
        if (Test-Path -LiteralPath $marker -PathType Leaf) { Remove-Item -LiteralPath $marker -Force }
    }
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        $saved = ([string](Get-Content -LiteralPath $receipt -Raw)).Trim().Trim('"')
        if ($saved -ieq $GameRoot) { Remove-Item -LiteralPath $receipt -Force }
    }
    $desktop = if ($env:PCVR_HUB_TEST_MODE -eq '1') { [string]$env:PCVR_FORSAKEN_TEST_DESKTOP } else { [Environment]::GetFolderPath('DesktopDirectory') }
    if ($desktop) {
        $shortcut = Join-Path $desktop 'Forsaken VR.lnk'
        if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
            $shell = New-Object -ComObject WScript.Shell
            $link = $shell.CreateShortcut($shortcut)
            if ([string]$link.TargetPath -ieq (Join-Path $GameRoot 'game\projectx.exe') -and
                [string]$link.IconLocation -ieq ((Join-Path $PSScriptRoot 'ForsakenVR.ico') + ',0')) {
                Remove-Item -LiteralPath $shortcut -Force -ErrorAction Stop
            }
        }
    }
    Write-Host "  [OK] Removed $removed unchanged Hub-owned files; retained $retained changed files." -ForegroundColor Green
    Write-Host '  Game data, saves and settings remain in the VR folder.' -ForegroundColor Gray
    Finish-ForsakenRemoval 0
} catch {
    Write-Host "  Forsaken VR removal did not complete: $($_.Exception.Message)" -ForegroundColor Red
    Finish-ForsakenRemoval 1
}
