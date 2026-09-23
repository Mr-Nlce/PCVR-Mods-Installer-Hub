$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Get-GRWUninstallCandidate([string]$Receipt,[string]$Label) {
    if (-not (Test-Path -LiteralPath $Receipt -PathType Leaf)) { return $null }
    try { $path=([IO.File]::ReadAllText($Receipt)).Trim() } catch { return $null }
    if (-not $path -or -not (Test-Path -LiteralPath (Join-Path $path 'GRW.exe') -PathType Leaf)) { return $null }
    if (-not (Test-Path -LiteralPath (Join-Path $path '.pcvrhub_grwxr_ownership.csv') -PathType Leaf)) { return $null }
    return [pscustomobject]@{ Label=$Label; Path=$path; Receipt=$Receipt }
}

$candidates=@(
    Get-GRWUninstallCandidate -Receipt (Join-Path $PSScriptRoot '.installed_path') -Label 'Current game'
    Get-GRWUninstallCandidate -Receipt (Join-Path $PSScriptRoot '.installed_path_depot') -Label 'Pinned build 24821571'
) | Where-Object { $_ }

if ($candidates.Count -eq 0) {
    Write-Host '  No Hub-owned GRW-XR installation was found.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close...')
    exit 0
}

$selected=$candidates[0]
if ($candidates.Count -gt 1) {
    Write-Host '  Choose the independent GRW-XR route to remove:' -ForegroundColor White
    for ($i=0; $i -lt $candidates.Count; $i++) { Write-Host ("  [{0}] {1}: {2}" -f ($i+1),$candidates[$i].Label,$candidates[$i].Path) -ForegroundColor Cyan }
    do { $raw=([string](Read-Host 'Selection')).Trim() } while ($raw -notmatch '^\d+$' -or [int]$raw -lt 1 -or [int]$raw -gt $candidates.Count)
    $selected=$candidates[[int]$raw-1]
}

Write-Host "  Remove GRW-XR from: $($selected.Path)" -ForegroundColor White
Write-Host '  The base game, saves and the dedicated depot game data remain.' -ForegroundColor Gray
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove only the Hub-owned VR payload...')

$result=Uninstall-OwnedModPayload -GameRoot $selected.Path -Identity 'grwxr' -ParkedAlternates @{ 'dxgi.dll'='dxgi.dll.off' }
if (-not $result.Found) { throw 'The ownership manifest disappeared before removal.' }
if ($result.Preserved -gt 0) {
    Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow
} else {
    Remove-Item -LiteralPath (Join-Path $selected.Path '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $selected.Receipt -Force -ErrorAction SilentlyContinue
    if ($selected.Label -eq 'Current game') { Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_version') -Force -ErrorAction SilentlyContinue }
    else { Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_version_depot') -Force -ErrorAction SilentlyContinue }
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Flat Ghost Recon Wildlands remains installed.' -ForegroundColor Gray
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close...')
