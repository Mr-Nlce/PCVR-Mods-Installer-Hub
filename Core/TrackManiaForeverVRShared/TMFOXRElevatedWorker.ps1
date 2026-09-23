param([Parameter(Mandatory=$true)][string]$RequestFile)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$resultPath = ''
$copyAttempted = $false
$required = @()
try {
    if (-not (Test-Path -LiteralPath $RequestFile -PathType Leaf)) { throw 'The elevation request is missing.' }
    $request = Get-Content -LiteralPath $RequestFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $resultPath = [IO.Path]::GetFullPath([string]$request.ResultPath)
    $action = [string]$request.Action
    $edition = [string]$request.Edition
    if ($action -notin @('InstallDirect','UninstallDirect') -or $edition -notin @('Nations','United')) { throw 'The elevation request is not a supported TrackMania operation.' }

    $gameRoot = [IO.Path]::GetFullPath([string]$request.GameRoot)
    if (-not (Test-Path -LiteralPath (Join-Path $gameRoot 'TmForever.exe') -PathType Leaf)) { throw 'TmForever.exe is missing from the requested game folder.' }
    $identity = if ($edition -eq 'United') { 'tmfoxr_united_direct' } else { 'tmfoxr_nations_direct' }

    if ($action -eq 'UninstallDirect') {
        $removed = Uninstall-OwnedModPayload -GameRoot $gameRoot -Identity $identity
        $manifest = Join-Path $gameRoot ('.pcvrhub_' + $identity + '_ownership.csv')
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { Remove-Item -LiteralPath (Join-Path $gameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue }
        $result = [ordered]@{ Success=$true; Removed=$removed.Removed; Restored=$removed.Restored; Preserved=$removed.Preserved }
    } else {
        $sourceRoot = [IO.Path]::GetFullPath([string]$request.SourceRoot)
        $version = [string]$request.Version
        $launcher = if ($edition -eq 'United') { 'Start TrackMania United Forever VR.bat' } else { 'Start TrackMania Nations Forever VR.bat' }
        $id = if ($edition -eq 'United') { 'trackmania-united-forever' } else { 'trackmania-nations-forever' }
        $title = if ($edition -eq 'United') { 'TrackMania United Forever' } else { 'TrackMania Nations Forever' }
        $hubFolder = if ($edition -eq 'United') { 'TrackManiaUnitedForeverVR' } else { 'TrackManiaNationsForeverVR' }
        $requiredRelative = @('d3d9.dll','openxr_loader.dll','TMFOXR.defaults.ini',$launcher)
        foreach ($relative in $requiredRelative) {
            if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $relative) -PathType Leaf)) { throw "The staged direct package is missing $relative." }
        }
        $required = @($requiredRelative | ForEach-Object { Join-Path $gameRoot $_ })
        $copyAttempted = $true
        [void](Install-OwnedModPayload -SourceRoot $sourceRoot -GameRoot $gameRoot -Identity $identity -AdoptIdenticalExisting)
        Start-Sleep -Seconds 3
        $missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
        if ($missing.Count) {
            $result = [ordered]@{
                Success=$false
                FailureKind='MissingAfterCopy'
                Error='Required files are missing after the elevated copy check.'
                MissingPaths=@($missing)
            }
            [IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false))
            exit 2
        }
        $contract = New-PCVRInstallerContract -Id $id -GameName ($title + ' VR') -Acquisition GitHub -AntivirusNotice `
            -ReleasePageUrl 'https://github.com/jiink/TrackManiaForeverOpenXR/releases' -Routes @('Direct') `
            -RequiredInstalledFileGroups @($requiredRelative + ('.pcvrhub_' + $identity + '_ownership.csv'))
        $receipt = Join-Path (Join-Path ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))) $hubFolder) '.installed_path'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gameRoot -Version $version -InstalledPathReceiptPaths @($receipt) -Route 'Direct')
        $result = [ordered]@{ Success=$true; Removed=0; Restored=0; Preserved=0 }
    }
    [IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false))
    exit 0
} catch {
    if ($resultPath) {
        if ($copyAttempted -and $required.Count -gt 0) {
            $missingAfterCopy = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf -ErrorAction SilentlyContinue) })
            if ($missingAfterCopy.Count -gt 0) {
                try {
                    [IO.File]::WriteAllText($resultPath,([ordered]@{
                        Success=$false
                        FailureKind='MissingAfterCopy'
                        Error='Required files are missing during or after the elevated copy check.'
                        MissingPaths=@($missingAfterCopy)
                    } | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false))
                } catch {}
                exit 2
            }
        }
        try { [IO.File]::WriteAllText($resultPath,([ordered]@{Success=$false;Error=$_.Exception.Message} | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false)) } catch {}
    }
    exit 1
}
