param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'DeusExHRVRElevatedOperations.ps1')
. (Join-Path $PSScriptRoot 'DeusExHRVRElevatedWorker.ps1')

function Finish-DeusExUninstall([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-DeusExOwnedRoot([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'DXHRDC.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Root '.pcvrhub_deusexhrvr_ownership.csv') -PathType Leaf))
}

if (-not (Test-DeusExOwnedRoot $GameRoot)) {
    foreach ($candidate in @(
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim() } catch { $null }),
        $(try { Find-SteamGameFolder -AppId '238010' -SteamFolderNames @("Deus Ex Human Revolution Director's Cut") -ProbeExe 'DXHRDC.exe' -HubGameId 'deus-ex-human-revolution-directors-cut-vr' } catch { $null })
    ) | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-DeusExOwnedRoot $candidate) { $GameRoot=(Get-Item -LiteralPath $candidate).FullName; break }
    }
}
if (-not (Test-DeusExOwnedRoot $GameRoot)) { Write-Host '  No Hub-owned DeusExHRVR installation was found.' -ForegroundColor Yellow; Finish-DeusExUninstall 0 }
if (Get-Process -Name 'DXHRDC','DeusExHRVRHost' -ErrorAction SilentlyContinue) { Write-Host '[X] Close Deus Ex and its VR host before removing the mod.' -ForegroundColor Red; Finish-DeusExUninstall 1 }
if (-not $HubConfirmed) {
    $confirm=(''+(Read-Host "Remove Hub-owned DeusExHRVR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-DeusExUninstall 0 }
}

if (Test-InstallerTargetWritable -TargetPath $GameRoot) {
    $result=Uninstall-DeusExVrOwnedPayload -GameRoot $GameRoot
} else {
    Write-Host '  Restoring the game files and graphics settings needs administrator rights.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to request administrator rights and continue...')
    $result=Invoke-DeusExHRVRElevatedOperation -Action Uninstall -GameRoot $GameRoot
}
$preserved=[int]$result.Preserved
if ($preserved -eq 0) {
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try { if ([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force } } catch {}
    }
}
if ($preserved -gt 0) { Write-Host "  [!!] $preserved changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow }
Write-Host "  [OK] Removed $([int]$result.Removed), restored $([int]$result.Restored), preserved $preserved." -ForegroundColor Green
Write-Host '  DeusExHRVR.ini, saves, logs, captures and unrelated mods remain in place.' -ForegroundColor Gray
Finish-DeusExUninstall 0
