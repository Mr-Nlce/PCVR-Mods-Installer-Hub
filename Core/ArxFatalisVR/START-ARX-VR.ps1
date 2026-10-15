$ErrorActionPreference='Stop'
try {
    $root=$PSScriptRoot
    $exe=Join-Path $root 'arx.exe'
    $pathFile=Join-Path $root 'launcher-game-path.txt'
    if(-not(Test-Path -LiteralPath $exe -PathType Leaf) -or -not(Test-Path -LiteralPath (Join-Path $root 'openxr_loader.dll') -PathType Leaf)) {throw 'Arx Libertatis VR is incomplete. Run its Hub installer again.'}
    if(-not(Test-Path -LiteralPath $pathFile -PathType Leaf)){throw 'The saved Arx Fatalis game path is missing. Run its Hub installer again.'}
    $base=([IO.File]::ReadAllText($pathFile)).Trim()
    foreach($name in @('data.pak','data2.pak','loc.pak','sfx.pak','speech.pak')){
        if(-not(Test-Path -LiteralPath (Join-Path $base $name) -PathType Leaf)){throw "Arx Fatalis game data is missing: $name. Run its Hub installer again."}
    }
    Push-Location -LiteralPath $root
    try { & $exe "--data-dir=$base"; if($LASTEXITCODE -ne 0){throw "Arx Libertatis VR exited with code $LASTEXITCODE."} }
    finally { Pop-Location }
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
