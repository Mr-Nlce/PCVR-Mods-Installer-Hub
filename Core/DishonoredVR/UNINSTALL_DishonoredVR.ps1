param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')

$manifestName='.pcvrhub-dishonored-install.tsv'
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

$manifest=Join-PathLexical $GameRoot $manifestName
$remaining=New-Object Collections.Generic.List[string]
$removed=0;$restored=0;$preserved=0
foreach ($line in @(Get-Content -LiteralPath $manifest -ErrorAction Stop)) {
    $parts=@($line -split "`t",3)
    if ($parts.Count -lt 3 -or $parts[0] -notin @('restore','remove') -or -not (Test-DishonoredSafeRelative $parts[1]) -or $parts[2] -notmatch '^[A-Fa-f0-9]{64}$') {
        $remaining.Add($line);$preserved++;continue
    }
    $mode=[string]$parts[0];$relative=[string]$parts[1];$installedSha=([string]$parts[2]).ToUpperInvariant()
    $live=Join-PathLexical $GameRoot $relative
    $target=$live
    if ($relative -ieq 'Binaries\Win32\d3d9.dll' -and -not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $parked=Join-PathLexical $GameRoot 'Binaries\Win32\d3d9.dll.flat'
        if (Test-Path -LiteralPath $parked -PathType Leaf) { $target=$parked }
    }
    $backup="$live.hubbak"
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        if ($mode -eq 'restore' -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $live));Copy-Item -LiteralPath $backup -Destination $live -Force -ErrorAction Stop;Remove-Item -LiteralPath $backup -Force -ErrorAction Stop;$restored++
        }
        continue
    }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $installedSha) { $remaining.Add($line);$preserved++;continue }
    if ($mode -eq 'restore') {
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { $remaining.Add($line);$preserved++;continue }
        if ($target -ne $live) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
        Copy-Item -LiteralPath $backup -Destination $live -Force -ErrorAction Stop;Remove-Item -LiteralPath $backup -Force -ErrorAction Stop;$restored++
    } else { Remove-Item -LiteralPath $target -Force -ErrorAction Stop;$removed++ }
}
if ($remaining.Count) { Set-Content -LiteralPath $manifest -Value $remaining.ToArray() -Encoding UTF8 -Force }
else {
    Remove-Item -LiteralPath $manifest -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-PathLexical $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path';if(Test-Path -LiteralPath $receipt -PathType Leaf){try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim().Trim('"')) -eq [IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}}
}
if ($preserved) { Write-Host "  [!!] $preserved legacy, changed or unverified file(s) were preserved for safety." -ForegroundColor Yellow }
Write-Host "  [OK] Removed $removed, restored $restored, preserved $preserved." -ForegroundColor Green
Write-Host '  Saves, DishonoredEngine.ini, settings and unrelated mods remain in place.' -ForegroundColor Gray
Finish-DishonoredRemoval 0
