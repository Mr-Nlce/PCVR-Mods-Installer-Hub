param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
$env:PCVR_D2R_LIBRARY_ONLY='1'
. (Join-Path $PSScriptRoot 'Diablo2ResurrectedVR-core.ps1')
Remove-Item Env:PCVR_D2R_LIBRARY_ONLY -ErrorAction SilentlyContinue
function Finish-D2RRemove([int]$Code){if(-not $NoPause){Write-Host '';[void](Read-Host 'Press Enter to close')};exit $Code}
try{
    $root=Get-D2RGameRoot
    if(-not $root -or -not(Test-D2RVRInstalled $root)){Write-Host 'No verified D2R VR installation was found.' -ForegroundColor Yellow;Finish-D2RRemove 0}
    if(Get-Process -Name 'D2R','D2RLoader' -ErrorAction SilentlyContinue){throw 'Close Diablo II Resurrected before removing D2R VR.'}
    if(-not $HubConfirmed){$choice=([string](Read-Host "Run publisher uninstall for '$root'? Type REMOVE")).Trim();if($choice -cne 'REMOVE'){Finish-D2RRemove 0}}
    $uninstaller=$null
    $hives=@('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
    foreach($hive in $hives){
        foreach($entry in @(Get-ChildItem -Path $hive -ErrorAction SilentlyContinue)){
            if($entry.PSChildName -notmatch '^\{8C1F3A52-6D0B-4E47-9B7E-2D5A0C9E4F31\}_is1$'){continue}
            $value=Get-ItemProperty -LiteralPath $entry.PSPath -ErrorAction SilentlyContinue
            if($value.DisplayName -notmatch '^D2R VR\b'){continue}
            $raw=([string]$value.UninstallString).Trim()
            $match=[regex]::Match($raw,'^"(?<path>[^\"]+\.exe)"|^(?<path>\S+\.exe)',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if(-not $match.Success){continue}
            $candidate=[IO.Path]::GetFullPath($match.Groups['path'].Value)
            $prefix=[IO.Path]::GetFullPath($root).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
            if(-not $candidate.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($candidate) -notmatch '^unins[0-9]*\.exe$' -or -not(Test-Path -LiteralPath $candidate -PathType Leaf)){continue}
            $uninstaller=$candidate;break
        }
        if($uninstaller){break}
    }
    if(-not $uninstaller){throw 'The registered D2R VR publisher uninstaller was not found inside this game folder.'}
    Write-Host "Publisher uninstaller: $uninstaller" -ForegroundColor Cyan
    Write-Host 'Windows may request administrator approval (UAC).' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher uninstaller...')
    $process=Start-Process -FilePath $uninstaller -Wait -PassThru -ErrorAction Stop
    if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher uninstaller ended with exit code $($process.ExitCode)."}
    if(Test-D2RVRInstalled $root){throw 'D2R VR still has all required files; Hub state was kept.'}
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -ieq [IO.Path]::GetFullPath($root)){Remove-Item -LiteralPath $receipt -Force}}catch{}}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Write-Host 'D2R VR was removed; game files and shared BodyWalk settings remain.' -ForegroundColor Green
    Finish-D2RRemove 0
}catch{Write-Host "Removal did not complete: $($_.Exception.Message)" -ForegroundColor Red;Finish-D2RRemove 1}
