param([switch]$HubConfirmed,[switch]$NoPause)
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference = 'Stop'
$appId = '1465360'
$depotVersion = '1.886173'
$depotDefaultPath = 'C:\Games\SnowRunner VR'

function Add-SnowRemovalCandidate {
    param([System.Collections.ArrayList]$List,[string]$Label,[string]$Root,[string]$PathState,[string]$VersionState,[bool]$Depot)
    if (-not $Root) { return }
    $exe = Join-PathLexical $Root 'Sources\Bin\SnowRunner.exe'
    $manifest = Join-PathLexical $Root 'Sources\Bin\.pcvrhub_snowrunnervr_ownership.csv'
    if (-not (Test-LiteralPathSafe -Path $exe -PathType Leaf) -or -not (Test-LiteralPathSafe -Path $manifest -PathType Leaf)) { return }
    foreach ($known in $List) { if ([string]$known.Root -ieq [string]$Root) { return } }
    [void]$List.Add([pscustomobject]@{ Label=$Label; Root=$Root; PathState=$PathState; VersionState=$VersionState; Depot=$Depot })
}

function Read-SnowRemovalChoice {
    param([int]$Maximum)
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $choice = ([string](Read-Host "Choose 1-$Maximum, or Q to keep everything")).Trim().ToUpperInvariant()
        if ($choice -eq 'Q') { return 0 }
        $number = 0
        if ([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $Maximum) { return $number }
        Write-Host "Choose a number from 1 to $Maximum, or Q." -ForegroundColor Yellow
    }
    throw 'No valid uninstall choice was selected after 10 attempts.'
}

function Remove-SnowDepotShortcutIfOwned {
    param([string]$GameRoot)
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) { return }
    $shortcut = Join-Path $desktop "SnowRunner VR $depotVersion.lnk"
    if (-not (Test-Path -LiteralPath $shortcut -PathType Leaf)) { return }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $target = [string]$shell.CreateShortcut($shortcut).TargetPath
        $expected = Join-PathLexical $GameRoot 'Sources\Bin\SnowRunner.exe'
        if ($target -and ([IO.Path]::GetFullPath($target) -ieq [IO.Path]::GetFullPath($expected))) {
            Remove-Item -LiteralPath $shortcut -Force -ErrorAction Stop
        }
    } catch {}
}

$candidates = New-Object System.Collections.ArrayList
$current = Find-SteamGameFolder -AppId $appId -SteamFolderNames @('SnowRunner','Codename - SR') -ProbeExe 'Sources\Bin\SnowRunner.exe'
$currentPathState = Join-Path $PSScriptRoot '.installed_path'
if (Test-Path -LiteralPath $currentPathState -PathType Leaf) {
    try { $current = ([IO.File]::ReadAllText($currentPathState)).Trim() } catch {}
}
Add-SnowRemovalCandidate -List $candidates -Label 'Current Steam version' -Root $current -PathState '.installed_path' -VersionState '.installed_version' -Depot $false

$depotPaths = @($depotDefaultPath)
$depotPathState = Join-Path $PSScriptRoot '.installed_path_depot'
if (Test-Path -LiteralPath $depotPathState -PathType Leaf) {
    try { $depotPaths = @(([IO.File]::ReadAllText($depotPathState)).Trim()) + $depotPaths } catch {}
}
foreach ($depotPath in @($depotPaths | Where-Object { $_ } | Select-Object -Unique)) {
    Add-SnowRemovalCandidate -List $candidates -Label "Last confirmed $depotVersion copy" -Root $depotPath -PathState '.installed_path_depot' -VersionState '.installed_version_depot' -Depot $true
}

if ($candidates.Count -eq 0) { throw 'No Hub-owned SnowRunner VR installation was found. No unverified file was removed.' }
if (Get-Process -Name 'SnowRunner' -ErrorAction SilentlyContinue) { throw 'SnowRunner is still running. Close it before uninstalling.' }

if ($candidates.Count -eq 1) {
    $selected = $candidates[0]
    if (-not $HubConfirmed -and (Read-Host "Type REMOVE to uninstall SnowRunner VR from $($selected.Label)") -ne 'REMOVE') { exit 0 }
} else {
    Write-Host 'SnowRunner VR is installed in more than one independent game copy:' -ForegroundColor Cyan
    for ($i=0; $i -lt $candidates.Count; $i++) { Write-Host "  [$($i+1)] $($candidates[$i].Label) - $($candidates[$i].Root)" }
    $choice = Read-SnowRemovalChoice -Maximum $candidates.Count
    if ($choice -eq 0) { exit 0 }
    $selected = $candidates[$choice-1]
}

$bin = Join-PathLexical $selected.Root 'Sources\Bin'
$result = Uninstall-OwnedModPayload -GameRoot $bin -Identity 'snowrunnervr' -ParkedAlternates @{'dxgi.dll'='dxgi.dll.pcvrhub_off'}
if (-not $result.Found) { throw 'No Hub ownership record was found. No unverified file was removed.' }
if ($result.Preserved -eq 0) {
    foreach ($name in @('.pcvrhub_version','.pcvrhub.install.json')) { Remove-Item -LiteralPath (Join-PathLexical $selected.Root $name) -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot $selected.PathState) -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot $selected.VersionState) -Force -ErrorAction SilentlyContinue
    if ($selected.Depot) { Remove-SnowDepotShortcutIfOwned -GameRoot $selected.Root }
}
Write-Host "Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host 'Snowrunner_VR_config.txt, snowrunner_vr.log and steam_appid.txt were retained.' -ForegroundColor Gray
Write-Host 'The selected game copy, saves and unrelated mods were untouched.' -ForegroundColor Gray
if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
