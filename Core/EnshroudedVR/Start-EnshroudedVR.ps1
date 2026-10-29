param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
$previousLibraryMode=$env:PCVR_EVR_LIBRARY_ONLY
try {
    try {
        $env:PCVR_EVR_LIBRARY_ONLY='1'
        . (Join-Path $PSScriptRoot 'EnshroudedVR-core.ps1')
    } finally { $env:PCVR_EVR_LIBRARY_ONLY=$previousLibraryMode }
    foreach($relative in @('enshrouded.exe','dinput8.dll','Enshrouded VR setting.exe','EnshroudedVR\bin\evr_hooks.dll')){
        if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $relative) -PathType Leaf)){throw "Enshrouded VR is incomplete: $relative. Use Reinstall in the Hub."}
    }
    if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name enshrouded -ErrorAction SilentlyContinue)){throw 'Enshrouded is already running. Close it before changing VR settings.'}
    if(-not(Get-EVRFlatSettings $GameDirectory)){throw 'The one-time flat start is not complete. Use Reinstall in the Hub for the guided Steam first start, reach the main menu, then close the game.'}
    $settings=Join-Path $GameDirectory 'Enshrouded VR setting.exe'
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_EVR_TEST_LAUNCH_CAPTURE){
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
        if(-not([IO.Path]::GetFullPath($GameDirectory).StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase)) -or
            -not(Test-Path -LiteralPath (Join-Path $GameDirectory 'evr-fixture.txt'))){throw 'Launch capture requires an isolated game fixture.'}
        $events=@([pscustomobject]@{Action='Settings';Target=$settings;WorkingDirectory=$GameDirectory})
        if(-not(Test-EVRMode $GameDirectory)){throw 'VR is off. Choose motion VR or controller VR, then close the publisher settings.'}
        $events+=[pscustomobject]@{Action='Steam';Target='steam://rungameid/1203620';WorkingDirectory=''}
        $events|ConvertTo-Json|Set-Content -LiteralPath $env:PCVR_EVR_TEST_LAUNCH_CAPTURE -Encoding UTF8
        exit 0
    }
    $process=Start-Process -FilePath $settings -WorkingDirectory $GameDirectory -Wait -PassThru -ErrorAction Stop
    if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher settings did not finish successfully (exit $($process.ExitCode))."}
    # Its updater can replace/reopen the settings EXE. Wait for that window too.
    do {
        Start-Sleep -Milliseconds 500
        $active=@(Get-Process -Name 'Enshrouded VR setting' -ErrorAction SilentlyContinue|Where-Object {
            try{$_.Path -ieq $settings}catch{$false}
        })
    } while($active.Count)
    if(-not(Test-EVRMode $GameDirectory)){throw 'VR is off. Open the publisher settings again, choose motion VR or controller VR, then close it. The game was not started in flat.'}
    $manifestPath=Join-Path $GameDirectory 'EnshroudedVR\PACKAGE_MANIFEST.json'
    $manifest=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop
    if(-not(Test-EVRGameBuild -Game $GameDirectory -ExpectedHash ([string]$manifest.game_exe_sha256))){
        throw 'This VR mod does not match the installed game build. Update the mod in the publisher window, then use Start in VR again. The unsupported game was not started as VR.'
    }
    if(Get-Process -Name enshrouded -ErrorAction SilentlyContinue){throw 'Enshrouded was already started. Close it, then use Start in VR again.'}
    Start-Process -FilePath 'steam://rungameid/1203620' -ErrorAction Stop|Out-Null
} catch {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
    Add-Type -AssemblyName PresentationFramework
    [void][Windows.MessageBox]::Show($_.Exception.Message,'Enshrouded VR','OK','Warning')
    exit 1
}
