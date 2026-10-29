param([string]$GameDirectory='', [string]$RuntimeRoot='')
$ErrorActionPreference='Stop'
trap {
    if($env:PCVR_HUB_TEST_MODE -ne '1'){
        Add-Type -AssemblyName PresentationFramework
        [void][Windows.MessageBox]::Show(('Balatro VR could not start: '+$_.Exception.Message),'Balatro VR')
    }
    throw $_
}
if(-not $RuntimeRoot){
    if(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'Balatro in VR.exe')){$RuntimeRoot=$PSScriptRoot}
    else{$base=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HUB_TEST_LOCALAPPDATA){$env:PCVR_HUB_TEST_LOCALAPPDATA}else{$env:LOCALAPPDATA};$RuntimeRoot=Join-Path $base 'PCVR Mods Installer Hub\BalatroVR'}
}
if(-not $GameDirectory){$file=Join-Path $RuntimeRoot '.pcvrhub_balatro_game.txt';if(Test-Path -LiteralPath $file){$GameDirectory=[IO.File]::ReadAllText($file).Trim()}}
foreach($file in @((Join-Path $GameDirectory 'Balatro.exe'),(Join-Path $GameDirectory 'winmm.dll'),(Join-Path $RuntimeRoot 'Balatro in VR.exe'),(Join-Path $RuntimeRoot 'Balatro in VR.pck'))){if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw 'Balatro VR files are incomplete. Use Install / Update in the Hub or locate the complete game folder.'}}
$roaming=$env:APPDATA
if(-not(Test-Path -LiteralPath (Join-Path $roaming 'Balatro\Mods\BalatroVRBridge\BalatroVRBridge.lua'))){throw 'The Balatro VR bridge is missing from your Windows profile. Reinstall through the Hub.'}
$targets=@(@{File=(Join-Path $RuntimeRoot 'Balatro in VR.exe');WorkingDirectory=$RuntimeRoot},@{File='steam://rungameid/2379780';WorkingDirectory=$GameDirectory})
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BALATRO_LAUNCH_CAPTURE){
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    $capture=[IO.Path]::GetFullPath($env:PCVR_BALATRO_LAUNCH_CAPTURE)
    if(-not $capture.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped the isolated fixture.'}
    $targets|ConvertTo-Json|Set-Content -LiteralPath $capture -Encoding UTF8;return
}
try{
    if(-not(Get-Process -Name 'Balatro in VR' -ErrorAction SilentlyContinue)){[void](Start-Process -FilePath $targets[0].File -WorkingDirectory $targets[0].WorkingDirectory -ErrorAction Stop)}
    if(-not(Get-Process -Name 'Balatro' -ErrorAction SilentlyContinue)){[void](Start-Process -FilePath $targets[1].File -ErrorAction Stop)}
}catch{throw}
