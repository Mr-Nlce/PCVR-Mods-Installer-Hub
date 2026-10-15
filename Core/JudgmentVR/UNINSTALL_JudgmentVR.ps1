param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
$env:PCVR_JUDGMENT_LIBRARY_ONLY='1'
. (Join-Path $PSScriptRoot 'JudgmentVR-core.ps1')
Remove-Item Env:PCVR_JUDGMENT_LIBRARY_ONLY -ErrorAction SilentlyContinue
function Finish-JudgmentRemove([int]$Code) {
    if (-not $NoPause) { Write-Host ''; [void](Read-Host 'Press Enter to close') }
    exit $Code
}
try {
    $root=Get-JudgmentRoot
    if (-not $root -or -not (Get-JudgmentInstalledVersion $root)) {
        Write-Host 'No verified Judgment VR installation was found.' -ForegroundColor Yellow
        Finish-JudgmentRemove 0
    }
    if (Get-Process -Name 'Judgment','startup' -ErrorAction SilentlyContinue) {
        throw 'Close Judgment before removing the VR mod.'
    }
    if (-not $HubConfirmed) {
        $choice=([string](Read-Host "Run the publisher uninstaller for '$root'? Type REMOVE")).Trim()
        if ($choice -cne 'REMOVE') { Finish-JudgmentRemove 0 }
    }
    $uninstaller=$null
    foreach ($hive in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')) {
        foreach ($entry in @(Get-ChildItem -Path $hive -ErrorAction SilentlyContinue)) {
            $value=Get-ItemProperty -LiteralPath $entry.PSPath -ErrorAction SilentlyContinue
            if ($value.DisplayName -notmatch '^Judgment VR mod\b') { continue }
            $raw=([string]$value.UninstallString).Trim()
            $match=[regex]::Match($raw,'^"(?<path>[^"]+\.exe)"|^(?<path>\S+\.exe)',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if (-not $match.Success) { continue }
            $candidate=[IO.Path]::GetFullPath($match.Groups['path'].Value)
            $registeredRoot=if($value.InstallLocation){[IO.Path]::GetFullPath([string]$value.InstallLocation)}else{$root}
            $registeredPrefix=$registeredRoot.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
            if (-not $candidate.StartsWith($registeredPrefix,[StringComparison]::OrdinalIgnoreCase) -or
                [IO.Path]::GetFileName($candidate) -notmatch '^unins[0-9]*\.exe$' -or
                -not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
            $uninstaller=$candidate; break
        }
        if ($uninstaller) { break }
    }
    if (-not $uninstaller) { throw 'The registered publisher uninstaller was not found in its installation folder.' }
    Write-Host "Publisher uninstaller: $uninstaller" -ForegroundColor Cyan
    Write-Host 'Windows may request administrator approval (UAC).' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the publisher uninstaller...')
    $process=Start-Process -FilePath $uninstaller -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher uninstaller ended with exit code $($process.ExitCode)." }
    if (Get-JudgmentInstalledVersion $root) { throw 'The publisher still reports Judgment VR installed; Hub state was kept.' }
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try { if ([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -ieq [IO.Path]::GetFullPath($root)) { Remove-Item -LiteralPath $receipt -Force } } catch {}
    }
    $versionMarker=Join-Path $root '.pcvrhub_version'
    if (Test-Path -LiteralPath $versionMarker -PathType Leaf) { Remove-Item -LiteralPath $versionMarker -Force }
    Write-Host 'Judgment VR was removed by its publisher uninstaller.' -ForegroundColor Green
    Finish-JudgmentRemove 0
} catch {
    Write-Host "Removal did not complete: $($_.Exception.Message)" -ForegroundColor Red
    Finish-JudgmentRemove 1
}
