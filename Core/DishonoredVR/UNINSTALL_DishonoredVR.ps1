param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot 'DishonoredMigration.ps1')

$manifestName='.pcvrhub-dishonored-install.tsv'
function Test-DishonoredLegacyRecord([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-PathLexical $Root $manifestName) -PathType Leaf))
}
function Test-DishonoredPublisherRecord([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-PathLexical $Root 'Binaries\Win32\Dishonored.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-PathLexical $Root 'Binaries\Win32\dishonored_vr_install.json') -PathType Leaf))
}
if (-not $GameRoot) {
    try { $GameRoot=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"') } catch {}
}
if (-not (Test-DishonoredPublisherRecord $GameRoot) -and -not (Test-DishonoredLegacyRecord $GameRoot)) {
    try { $steamRoot=Find-SteamGameFolder -AppId '205100' -SteamFolderNames @('Dishonored') -ProbeExe 'Binaries\Win32\Dishonored.exe' } catch { $steamRoot=$null }
    if (Test-DishonoredPublisherRecord $steamRoot) { $GameRoot=$steamRoot }
}
if (-not (Test-DishonoredPublisherRecord $GameRoot) -and -not (Test-DishonoredLegacyRecord $GameRoot)) {
    try { $gogRoot=Find-SteamGameFolder -GogNames @('Dishonored') -ProbeExe 'Binaries\Win32\Dishonored.exe' -HubGameId 'dishonored-vr' } catch { $gogRoot=$null }
    if (Test-DishonoredPublisherRecord $gogRoot) { $GameRoot=$gogRoot }
}
if ((Test-DishonoredPublisherRecord $GameRoot) -and -not (Test-Path -LiteralPath (Join-PathLexical $GameRoot $manifestName) -PathType Leaf)) {
    & (Join-Path $PSScriptRoot 'DishonoredVR-core.ps1') -Manage
    exit $LASTEXITCODE
}
function Finish-DishonoredRemoval([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-DishonoredOwnedRoot([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-PathLexical $Root 'Binaries\Win32\Dishonored.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-PathLexical $Root $manifestName) -PathType Leaf))
}
function Test-DishonoredSafeRelative([string]$Relative) {
    return [bool]($Relative -and -not [IO.Path]::IsPathRooted($Relative) -and $Relative -notmatch '(^|[\\/])\.\.([\\/]|$)' -and $Relative -notmatch '^[A-Za-z]:')
}

if (-not (Test-DishonoredOwnedRoot $GameRoot)) {
    foreach ($candidate in @(
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"') } catch { $null }),
        $(try { Find-SteamGameFolder -AppId '205100' -SteamFolderNames @('Dishonored') -ProbeExe 'Binaries\Win32\Dishonored.exe' } catch { $null })
    ) | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-DishonoredOwnedRoot $candidate) { $GameRoot=(Get-Item -LiteralPath $candidate).FullName; break }
    }
}
if (-not (Test-DishonoredOwnedRoot $GameRoot)) { Write-Host '  No Hub-owned Dishonored VR installation was found.' -ForegroundColor Yellow; Finish-DishonoredRemoval 0 }
if (Get-Process -Name 'Dishonored' -ErrorAction SilentlyContinue) { Write-Host '[X] Close Dishonored before removing the VR files.' -ForegroundColor Red; Finish-DishonoredRemoval 1 }
if (-not $HubConfirmed) {
    $confirm=(''+(Read-Host "Remove unchanged Hub-owned Dishonored VR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-DishonoredRemoval 0 }
}

try {
    $result=Invoke-DishonoredLegacyMigration -GameRoot $GameRoot
    Remove-Item -LiteralPath (Join-PathLexical $PSScriptRoot '.installed_version') -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Removed $($result.Removed) old mod file(s) and restored $($result.Restored) original game file(s)." -ForegroundColor Green
    if ($result.BackupFolder) {
        Write-Host "  [i] $($result.Preserved) changed old mod file(s) were saved in $($result.BackupFolder)." -ForegroundColor Yellow
    }
    Write-Host '  Saves, settings and unrelated files remain in place.' -ForegroundColor Gray
    Finish-DishonoredRemoval 0
} catch {
    Write-Host "  [X] Old mod removal did not complete: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host '  The ownership record remains for a safe retry.' -ForegroundColor Yellow
    Finish-DishonoredRemoval 1
}