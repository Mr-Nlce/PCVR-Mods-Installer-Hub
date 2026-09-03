param([string]$GameRoot='',[string]$StateRoot='',[switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }
function Stop-NOVRUninstall { param([int]$Code=0) if (-not $NoPause) { Write-Host ''; Read-Host '  Press Enter to exit' | Out-Null }; exit $Code }
function Test-NOVRGameRoot([string]$Path) { if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }; return (Test-Path -LiteralPath (Join-Path $Path 'NuclearOption.exe') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $Path 'BepInEx\plugins\NOVR\NOVR.dll') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $Path 'BepInEx\patchers\NOVR\NOVR.Patcher.dll') -PathType Leaf) }
function Resolve-NOVRGameRoot([string]$Preferred,[string]$MarkerRoot) { if (Test-NOVRGameRoot $Preferred) { return [IO.Path]::GetFullPath($Preferred) }; try { $record=(Get-Content -LiteralPath (Join-Path $MarkerRoot '.installed_path') -Raw -ErrorAction Stop).Trim(); if (Test-NOVRGameRoot $record) { return [IO.Path]::GetFullPath($record) } } catch {}; try { $found=Find-SteamGameFolder -AppId '2168680' -SteamFolderNames @('Nuclear Option') -ProbeExe 'NuclearOption.exe'; if (Test-NOVRGameRoot $found) { return [IO.Path]::GetFullPath($found) } } catch {}; return $null }
$GameRoot=Resolve-NOVRGameRoot -Preferred $GameRoot -MarkerRoot $StateRoot
if (-not $GameRoot) { Write-Host '  [!!] Nuclear Option / NOVR was not found. Nothing was changed.' -ForegroundColor Yellow; Stop-NOVRUninstall 1 }
if (Get-Process -Name 'NuclearOption' -ErrorAction SilentlyContinue) { Write-Host '  [!!] Close Nuclear Option before uninstalling NOVR.' -ForegroundColor Yellow; Stop-NOVRUninstall 1 }
$pluginDir=Join-Path $GameRoot 'BepInEx\plugins\NOVR'; $patcherDir=Join-Path $GameRoot 'BepInEx\patchers\NOVR'
if (-not (Test-Path -LiteralPath $pluginDir) -and -not (Test-Path -LiteralPath $patcherDir)) { Write-Host '  [..] NOVR is not installed. Nothing was changed.' -ForegroundColor Gray; Stop-NOVRUninstall 0 }
if (-not $HubConfirmed) { $answer=(Read-Host '  Type yes to remove NOVR (shared BepInEx is kept)').Trim(); if ($answer -ne 'yes') { Stop-NOVRUninstall 0 } }
Write-Host '============================================================' -ForegroundColor Magenta; Write-Host ' Nuclear Option VR - remove NOVR' -ForegroundColor Cyan; Write-Host '============================================================' -ForegroundColor Magenta; Write-Host "  Game: $GameRoot" -ForegroundColor Gray
foreach ($owned in @($pluginDir,$patcherDir)) { if (Test-Path -LiteralPath $owned) { Remove-Item -LiteralPath $owned -Recurse -Force -ErrorAction Stop } }
$otherPlugins=@(); foreach ($part in @('plugins','patchers')) { $root=Join-Path $GameRoot "BepInEx\$part"; if (Test-Path -LiteralPath $root) { $otherPlugins+=@(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.dll' -ErrorAction SilentlyContinue) } }
if ($otherPlugins.Count -eq 0) { $loader=Join-Path $GameRoot 'winhttp.dll'; $parked=Join-Path $GameRoot 'winhttp_bak.dll'; if ((Test-Path -LiteralPath $loader) -and -not (Test-Path -LiteralPath $parked)) { Rename-Item -LiteralPath $loader -NewName 'winhttp_bak.dll' -Force -ErrorAction Stop } }
foreach ($marker in @('.installed_path','.installed_version')) { $path=Join-Path $StateRoot $marker; if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue } }
$gameVersion=Join-Path $GameRoot '.pcvrhub_version'; if (Test-Path -LiteralPath $gameVersion -PathType Leaf) { Remove-Item -LiteralPath $gameVersion -Force -ErrorAction SilentlyContinue }
Write-Host '  [OK] NOVR plugin and patcher removed.' -ForegroundColor Green; Write-Host '  [..] Shared BepInEx, settings, saves and unrelated mods were preserved.' -ForegroundColor Gray; Write-Host '  [..] First-launch XR support files were retained conservatively; they are inert without NOVR.' -ForegroundColor Gray
Stop-NOVRUninstall 0
