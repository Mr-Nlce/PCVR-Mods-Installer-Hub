param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-GloomUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}

function Test-GloomOwnedRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path 'GH.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_gloomhavenvr_ownership.csv') -PathType Leaf))
}

function Get-GloomUninstallCandidate([string]$Receipt,[string]$Route) {
    if (-not (Test-Path -LiteralPath $Receipt -PathType Leaf)) { return $null }
    try { $path=([IO.File]::ReadAllText($Receipt)).Trim() } catch { return $null }
    if (-not (Test-GloomOwnedRoot $path)) { return $null }
    return [pscustomobject]@{ Route=$Route; Path=$path; Receipt=$Receipt }
}

$selected=$null
if (Test-GloomOwnedRoot $GameRoot) {
    $route=if (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_gloomhaven_depot_20286313') -PathType Leaf) { 'Pinned build 20286313' } else { 'Current game' }
    $receipt=Join-Path $PSScriptRoot $(if ($route -like 'Pinned*') { '.installed_path_depot' } else { '.installed_path' })
    $selected=[pscustomobject]@{ Route=$route; Path=(Get-Item -LiteralPath $GameRoot).FullName; Receipt=$receipt }
} else {
    $candidates=@(
        Get-GloomUninstallCandidate -Receipt (Join-Path $PSScriptRoot '.installed_path') -Route 'Current game'
        Get-GloomUninstallCandidate -Receipt (Join-Path $PSScriptRoot '.installed_path_depot') -Route 'Pinned build 20286313'
    ) | Where-Object { $_ } | Group-Object Path | ForEach-Object { $_.Group[0] }

    if ($candidates.Count -eq 0) {
        Write-Host '  No Hub-owned GloomhavenVR installation was found.' -ForegroundColor Yellow
        Finish-GloomUninstall 0
    }
    if ($candidates.Count -gt 1) {
        Write-Host 'Choose the independent GloomhavenVR route to remove:' -ForegroundColor Yellow
        for ($i=0; $i -lt $candidates.Count; $i++) {
            Write-Host ("  [{0}] {1}: {2}" -f ($i+1),$candidates[$i].Route,$candidates[$i].Path) -ForegroundColor White
        }
        Write-Host '  [Q] Cancel' -ForegroundColor Gray
        while (-not $selected) {
            $choice=([string](Read-Host 'Your choice')).Trim().ToUpperInvariant()
            if ($choice -eq 'Q') { Finish-GloomUninstall 0 }
            $number=0
            if ([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $candidates.Count) {
                $selected=$candidates[$number-1]
            }
        }
    } else { $selected=$candidates[0] }
}

if (-not (Test-GloomOwnedRoot $selected.Path)) {
    Write-Host '[X] The selected folder no longer proves a Hub-owned GloomhavenVR installation.' -ForegroundColor Red
    Finish-GloomUninstall 1
}
if (Get-Process -Name 'GH' -ErrorAction SilentlyContinue) {
    Write-Host '[X] Close Gloomhaven before removing VR mode.' -ForegroundColor Red
    Finish-GloomUninstall 1
}
if (-not $HubConfirmed) {
    $confirm=([string](Read-Host "Remove Hub-owned GloomhavenVR files from '$($selected.Path)'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-GloomUninstall 0 }
}

$result=Uninstall-OwnedModPayload -GameRoot $selected.Path -Identity 'gloomhavenvr' `
    -ParkedAlternates @{ 'winhttp.dll'='winhttp.dll.pcvrhub_off' }
if (-not $result.Found) { throw 'The ownership manifest disappeared before removal.' }

# The mod itself creates this backup when it adjusts Unity rendering. Restore
# it only after all Hub-owned files were removed successfully; saves and normal
# game settings are never part of the ownership manifest.
if ($result.Preserved -eq 0) {
    $boot=Join-Path $selected.Path 'GH_Data\boot.config'
    $bootBackup=Join-Path $selected.Path 'GH_Data\boot.config.gloomhavenvr-backup'
    if (Test-Path -LiteralPath $bootBackup -PathType Leaf) {
        Copy-Item -LiteralPath $bootBackup -Destination $boot -Force
        Remove-Item -LiteralPath $bootBackup -Force
        Write-Host '  [OK] Restored the original GH_Data\boot.config.' -ForegroundColor Green
    }
    Remove-Item -LiteralPath (Join-Path $selected.Path '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $selected.Receipt -PathType Leaf) {
        try {
            $saved=([IO.File]::ReadAllText($selected.Receipt)).Trim()
            if ([IO.Path]::GetFullPath($saved) -eq [IO.Path]::GetFullPath($selected.Path)) {
                Remove-Item -LiteralPath $selected.Receipt -Force
            }
        } catch {}
    }
}

if ($result.Preserved -gt 0) {
    Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Gloomhaven, saves, settings and the dedicated depot game data remain.' -ForegroundColor Gray
Finish-GloomUninstall 0
