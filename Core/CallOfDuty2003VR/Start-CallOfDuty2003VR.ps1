param([string]$GameDirectory=$PSScriptRoot,[string]$RuntimeRoot,[ValidateSet('SP','UO')][string]$Game='SP')
$ErrorActionPreference='Stop'
try {
$base=if($Game -eq 'UO'){@('CoDUOSP.exe','uo\pakuo00.pk3')}else{@('CoDSP.exe','main\pak0.pk3')}
foreach($relative in @($base)+@('openxr_loader.dll','CoD-VR-Launcher.exe')){
    $path=Join-Path $GameDirectory $relative
    if(-not(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0){
        throw "Call of Duty VR is incomplete: $relative. Use Reinstall in the Hub."
    }
}
$active=Join-Path $GameDirectory 'opengl32.dll';$parked=$active+'.pcvrhub_off'
if(-not(Test-Path -LiteralPath $active) -and -not(Test-Path -LiteralPath $parked)){throw 'The VR graphics proxy is missing. Reinstall this VR mod.'}
if((Test-Path -LiteralPath $active) -and (Test-Path -LiteralPath $parked)){throw 'Both active and parked VR proxies exist. Resolve the conflict before starting.'}
$launcher=Join-Path $GameDirectory 'CoD-VR-Launcher.exe'
$capture=if($Game -eq 'UO' -and $env:PCVR_CODUO_TEST_LAUNCH_CAPTURE){$env:PCVR_CODUO_TEST_LAUNCH_CAPTURE}else{$env:PCVR_COD1_TEST_LAUNCH_CAPTURE}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $capture){
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
    if(-not ([IO.Path]::GetFullPath($GameDirectory)).StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not ([IO.Path]::GetFullPath($capture)).StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)){throw 'CoD launch capture escaped the isolated temporary fixture.'}
    [pscustomobject]@{File=$launcher;WorkingDirectory=$GameDirectory;Game=$Game} | ConvertTo-Json -Compress |
        Set-Content -LiteralPath $capture -Encoding UTF8
    exit 0
}
# The publisher reads this game selection at startup. The native INI API
# preserves unrelated settings and the file's Windows encoding semantics.
if(-not ('PCVRCoDLauncherPreferences' -as [type])){
 Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class PCVRCoDLauncherPreferences {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
 public static extern bool WritePrivateProfileString(string section, string key, string value, string file);
}
'@
}
if(-not $env:APPDATA){throw 'The publisher settings folder could not be resolved.'}
$settings=Join-Path $env:APPDATA 'CoD-VR\settings.ini';[void][IO.Directory]::CreateDirectory((Split-Path $settings))
if(-not [PCVRCoDLauncherPreferences]::WritePrivateProfileString('Launcher','Game',$Game,$settings)){throw 'The publisher game selection could not be saved. Close its launcher and retry.'}
$enable=Test-Path -LiteralPath $parked
if($enable){Move-Item -LiteralPath $parked -Destination $active -ErrorAction Stop}
try{Start-Process -FilePath $launcher -WorkingDirectory $GameDirectory -ErrorAction Stop | Out-Null}catch{if($enable){Move-Item -LiteralPath $active -Destination $parked -ErrorAction Stop};throw}

} catch {
 if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
 Add-Type -AssemblyName System.Windows.Forms
 [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Call of Duty VR - start failed')
 exit 1
}
