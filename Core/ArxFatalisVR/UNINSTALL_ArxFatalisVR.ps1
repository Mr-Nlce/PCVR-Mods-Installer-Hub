param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Get-ArxReceiptPath {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ARX_TEST_RECEIPT){
        $path=[IO.Path]::GetFullPath($env:PCVR_ARX_TEST_RECEIPT)
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not $path.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $path) 'arx-fixture.txt'))){throw 'Uninstall fixture is not isolated.'}
        return $path
    }
    return (Join-Path $PSScriptRoot '.installed_path')
}
function Finish-Arx([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-ArxOwned([string]$Path){return [bool]($Path -and
    (Test-Path -LiteralPath (Join-Path $Path 'arx.exe') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_arxvr_ownership.csv') -PathType Leaf))}
if(-not(Test-ArxOwned $GameRoot)){
    try{$candidate=([IO.File]::ReadAllText((Get-ArxReceiptPath))).Trim();if(Test-ArxOwned $candidate){$GameRoot=$candidate}}catch{}
}
if(-not(Test-ArxOwned $GameRoot)){Write-Host '  No Hub-owned Arx Libertatis VR installation was found.' -ForegroundColor Yellow;Finish-Arx 0}
if(Get-Process -Name 'arx' -ErrorAction SilentlyContinue){Write-Host '  Close Arx VR before removing it.' -ForegroundColor Red;Finish-Arx 1}
if(-not $HubConfirmed){$answer=([string](Read-Host "Remove Hub-owned Arx VR files from '$GameRoot'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-Arx 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'arxvr'
if(-not $result.Found){throw 'The Arx VR ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Get-ArxReceiptPath
    if(Test-Path -LiteralPath $receipt){try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}}
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed files." -ForegroundColor Green
Write-Host '  Your original Arx Fatalis game data and saved games remain.' -ForegroundColor Gray
Finish-Arx 0
