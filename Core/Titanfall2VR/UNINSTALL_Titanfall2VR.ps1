param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-TFUninstall([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-TFOwnedRoot([string]$Path){return [bool]($Path -and(Test-Path -LiteralPath (Join-Path $Path 'Titanfall2.exe') -PathType Leaf) -and(Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_titanfall2vr_ownership.csv') -PathType Leaf))}
function Test-TFProcessInRoot([string]$Path){
    try{$root=[IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar}catch{return $true}
    foreach($process in @(Get-Process -Name Titanfall2,NorthstarLauncher -ErrorAction SilentlyContinue)){
        try{
            $processPath=[string]$process.Path
            if([string]::IsNullOrWhiteSpace($processPath)){$processPath=[string]$process.MainModule.FileName}
            if(-not [string]::IsNullOrWhiteSpace($processPath)){
                $full=[IO.Path]::GetFullPath($processPath)
                if($full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){return $true}
            }
        }catch{return $true}
    }
    return $false
}
if(-not(Test-TFOwnedRoot $GameRoot)){try{$saved=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim();if(Test-TFOwnedRoot $saved){$GameRoot=$saved}}catch{}}
if(-not(Test-TFOwnedRoot $GameRoot)){Write-Host '[X] No Hub-owned titanfall2vr installation was found. Nothing was guessed or deleted.' -ForegroundColor Red;Finish-TFUninstall 1}
if(Test-TFProcessInRoot $GameRoot){Write-Host '[X] Close Titanfall 2 and Northstar for this installation before removing the VR plugin.' -ForegroundColor Red;Finish-TFUninstall 1}
if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned titanfall2vr files from '$GameRoot'? Type REMOVE").Trim() -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-TFUninstall 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'titanfall2vr'
Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] Northstar remains installed and usable.' -ForegroundColor Gray
Write-Host '[KEEP] titanfall2vr.ini, saves and unrelated plugins remain.' -ForegroundColor Gray
if($result.Preserved -eq 0 -and -not(Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_titanfall2vr_ownership.csv') -PathType Leaf)){Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue;Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Force -ErrorAction SilentlyContinue}
Finish-TFUninstall 0
