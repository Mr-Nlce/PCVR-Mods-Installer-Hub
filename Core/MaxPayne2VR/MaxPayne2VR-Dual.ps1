# Max Payne 2's two VR packages use the same d3d8.dll name. Keep both
# publishers' ownership records intact and activate exactly one loader set.
$script:MP2SlotFiles = @{
    A = @('d3d8.dll','dinput.dll','maxpayne2vr.asi','Max Payne 2 VR.exe')
    B = @('d3d8.dll','d3d9.dll','winmm.dll','dxvk.conf')
}

function Get-MP2ProfileRoot([string]$Game) { Join-Path $Game '.pcvrhub_maxpayne2_profiles' }
function Get-MP2ProfileFile([string]$Game,[string]$Slot,[string]$Name) {
    Join-Path (Join-Path (Get-MP2ProfileRoot $Game) $Slot) $Name
}
function Get-MP2ModeFile([string]$Game) { Join-Path $Game '.pcvrhub_maxpayne2_mode' }
function Get-MP2ActiveProofFile([string]$Game) { Join-Path $Game '.pcvrhub_maxpayne2_active.csv' }
function Test-MP2ActiveRuntimeProof {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot)
    $proof=Get-MP2ActiveProofFile $Game
    if(-not(Test-Path -LiteralPath $proof -PathType Leaf)) { return $false }
    try { $rows=@(Import-Csv -LiteralPath $proof -ErrorAction Stop) } catch { return $false }
    $required=@($script:MP2SlotFiles[$Slot])
    if($rows.Count -ne $required.Count) { return $false }
    foreach($name in $required) {
        $matching=@($rows | Where-Object { $_.Slot -eq $Slot -and $_.RelativePath -ieq $name })
        $path=Join-Path $Game $name
        if($matching.Count -ne 1 -or -not $matching[0].Sha256 -or -not(Test-Path -LiteralPath $path -PathType Leaf) -or
           (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$matching[0].Sha256) { return $false }
    }
    return $true
}
function Test-MP2KnownRuntimeFragment {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot,[string]$Name)
    if($Name -notin $script:MP2SlotFiles[$Slot]) { return $false }
    $path=Join-Path $Game $Name
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    $proof=Get-MP2ActiveProofFile $Game
    if(Test-Path -LiteralPath $proof -PathType Leaf) {
        foreach($row in @(Import-Csv -LiteralPath $proof -ErrorAction Stop)) {
            if($row.Slot -eq $Slot -and $row.RelativePath -ieq $Name -and $row.Sha256 -ieq $hash) { return $true }
        }
    }
    if($Slot -eq 'A') {
        $receipt=Get-MP2Receipt $Game
        $entry=if($receipt -and $receipt.status -eq 'installed'){$receipt.files.PSObject.Properties[$Name]}else{$null}
        if($entry -and $entry.Value.installed_sha256 -ieq $hash) { return $true }
    } else {
        $oldManifest=Join-Path $Game '.pcvrhub_maxpayne2vr_ownership.csv'
        if(Test-Path -LiteralPath $oldManifest -PathType Leaf) {
            foreach($row in @(Import-Csv -LiteralPath $oldManifest -ErrorAction Stop)) {
                if($row.RelativePath -ieq $Name -and $row.InstalledSha256 -ieq $hash) { return $true }
            }
        }
    }
    $identity=if($Slot -eq 'A'){'mp2evilruntime'}else{'mp2betotronruntime'}
    $stageManifest=Get-MP2ProfileFile $Game $Slot ".pcvrhub_${identity}_ownership.csv"
    if(Test-Path -LiteralPath $stageManifest -PathType Leaf) {
        foreach($row in @(Import-Csv -LiteralPath $stageManifest -ErrorAction Stop)) {
            if($row.RelativePath -ieq $Name -and $row.InstalledSha256 -ieq $hash) { return $true }
        }
    }
    return $false
}
function Write-MP2ActiveRuntimeProof {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot)
    $proof=Get-MP2ActiveProofFile $Game
    $rows=@($script:MP2SlotFiles[$Slot] | ForEach-Object {
        [pscustomobject]@{Slot=$Slot;RelativePath=$_;Sha256=(Get-FileHash -LiteralPath (Join-Path $Game $_) -Algorithm SHA256).Hash}
    })
    $tmp=$proof+'.new'
    $rows | Export-Csv -LiteralPath $tmp -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $proof -Force -ErrorAction Stop
}
function Get-MP2LaunchTarget {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot)
    if ($Game -match '(?i)[\\/]steamapps[\\/]common[\\/]') {
        return [pscustomobject]@{ Kind='Uri'; Target='steam://rungameid/12150'; WorkingDirectory='' }
    }
    $exe=if($Slot -eq 'A'){'Max Payne 2 VR.exe'}else{'maxpayne2.exe'}
    return [pscustomobject]@{ Kind='File'; Target=(Join-Path $Game $exe); WorkingDirectory=$Game }
}
function Assert-MP2GameClosed {
    if (Get-Process -Name maxpayne2,'Max Payne 2 VR' -ErrorAction SilentlyContinue) {
        throw 'Close Max Payne 2 and its VR launcher before installing, switching or removing a mod.'
    }
}
function Get-MP2Receipt([string]$Game) {
    $path=Join-Path $Game 'MP2VR-Install\receipt.json'
    if (-not(Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $raw=Get-Content -LiteralPath $path -Raw -ErrorAction Stop
        if ($raw -notmatch '^\s*\{') { return $null }
        # Lab and legacy folders may contain a plain-text probe named receipt.json.
        # Validate before invoking the cmdlet so a rejected probe does not emit
        # a caught terminating error into the Hub transcript.
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $document=[System.Text.Json.JsonDocument]::Parse($raw)
            $document.Dispose()
        }
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    } catch { return $null }
}
function Test-MP2LegacySlot {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot,[switch]$Parked)
    if (-not(Test-Path -LiteralPath (Join-Path $Game 'maxpayne2.exe') -PathType Leaf)) { return $false }
    $files=$script:MP2SlotFiles[$Slot]
    if ($Slot -eq 'A') {
        $receipt=Get-MP2Receipt $Game
        $stamp=Join-Path $Game '.pcvrhub_maxpayne2_evil_version'
        if (-not $receipt -or $receipt.status -ne 'installed' -or -not $receipt.version -or
            -not(Test-Path -LiteralPath $stamp -PathType Leaf) -or
            ((Get-Content -LiteralPath $stamp -Raw).Trim() -ne [string]$receipt.version) -or
            -not(Test-Path -LiteralPath (Join-Path $Game 'maxpayne2vr_assets.bin') -PathType Leaf) -or
            -not(Test-Path -LiteralPath (Join-Path $Game 'MP2VR_FirstPerson.mp2m') -PathType Leaf)) { return $false }
        foreach ($name in $files) {
            $path=if($Parked){Get-MP2ProfileFile $Game $Slot $name}else{Join-Path $Game $name}
            if (-not(Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
            $entry=$receipt.files.PSObject.Properties[$name]
            if (-not $entry -or -not $entry.Value.installed_sha256 -or
                (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$entry.Value.installed_sha256) { return $false }
        }
        return $true
    }
    $manifest=Join-Path $Game '.pcvrhub_maxpayne2vr_ownership.csv'
    $stamp=Join-Path $Game '.pcvrhub_maxpayne2_betotron_version'
    $legacy=Join-Path $Game '.pcvrhub_version'
    if (-not(Test-Path -LiteralPath $manifest -PathType Leaf) -or
        (-not(Test-Path -LiteralPath $stamp -PathType Leaf) -and -not(Test-Path -LiteralPath $legacy -PathType Leaf))) { return $false }
    try { $rows=@(Import-Csv -LiteralPath $manifest -ErrorAction Stop) } catch { return $false }
    foreach ($name in $files) {
        $row=@($rows | Where-Object { $_.RelativePath -ieq $name } | Select-Object -First 1)[0]
        $path=if($Parked){Get-MP2ProfileFile $Game $Slot $name}else{Join-Path $Game $name}
        if (-not $row -or -not $row.InstalledSha256 -or -not(Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$row.InstalledSha256) { return $false }
    }
    return $true
}
function Test-MP2V2Slot {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot,[switch]$Parked)
    if (-not(Test-Path -LiteralPath (Join-Path $Game 'maxpayne2.exe') -PathType Leaf)) { return $false }
    $profile=Join-Path (Get-MP2ProfileRoot $Game) $Slot
    $identity=if($Slot -eq 'A'){'mp2evilruntime'}else{'mp2betotronruntime'}
    $manifest=Join-Path $profile ".pcvrhub_${identity}_ownership.csv"
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)) { return $false }
    try { $rows=@(Import-Csv -LiteralPath $manifest -ErrorAction Stop) } catch { return $false }
    $stamp=if($Slot -eq 'A'){'.pcvrhub_maxpayne2_evil_version'}else{'.pcvrhub_maxpayne2_betotron_version'}
    $stampPath=Join-Path $Game $stamp
    $profileVersion=Join-Path $profile 'version.txt'
    if(-not(Test-Path -LiteralPath $stampPath -PathType Leaf) -or -not(Test-Path -LiteralPath $profileVersion -PathType Leaf) -or
        ((Get-Content -LiteralPath $stampPath -Raw).Trim() -ne (Get-Content -LiteralPath $profileVersion -Raw).Trim())) { return $false }
    if($Slot -eq 'A') {
        $contentManifest=Join-Path $Game '.pcvrhub_mp2evilcontent_ownership.csv'
        if(-not(Test-Path -LiteralPath $contentManifest -PathType Leaf) -or
            -not(Test-Path -LiteralPath (Join-Path $Game 'maxpayne2vr_assets.bin') -PathType Leaf) -or
            -not(Test-Path -LiteralPath (Join-Path $Game 'MP2VR_FirstPerson.mp2m') -PathType Leaf) -or
            -not(Test-Path -LiteralPath (Join-Path $Game 'maxpayne2vr_settings.ini') -PathType Leaf)) { return $false }
        try { $contentRows=@(Import-Csv -LiteralPath $contentManifest -ErrorAction Stop) } catch { return $false }
        if($contentRows.Count -lt 3) { return $false }
        foreach($contentRow in $contentRows) {
            $contentName=[string]$contentRow.RelativePath
            if(-not $contentName -or $contentName -match '[:\\/]' -or -not $contentRow.InstalledSha256) { return $false }
            $contentPath=Join-Path $Game $contentName
            if(-not(Test-Path -LiteralPath $contentPath -PathType Leaf) -or
                (Get-FileHash -LiteralPath $contentPath -Algorithm SHA256).Hash -ine [string]$contentRow.InstalledSha256) { return $false }
        }
    } elseif(-not(Test-Path -LiteralPath (Join-Path $Game 'MaxPayne2VR.ini') -PathType Leaf)) {
        return $false
    }
    foreach($name in $script:MP2SlotFiles[$Slot]) {
        $row=@($rows | Where-Object RelativePath -ieq $name | Select-Object -First 1)[0]
        $path=if($Parked){Join-Path $profile $name}else{Join-Path $Game $name}
        if(-not $row -or -not $row.InstalledSha256 -or -not(Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$row.InstalledSha256) { return $false }
    }
    return $true
}
function Test-MP2Slot {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot,[switch]$Parked)
    $profile=Join-Path (Get-MP2ProfileRoot $Game) $Slot
    $identity=if($Slot -eq 'A'){'mp2evilruntime'}else{'mp2betotronruntime'}
    if(Test-Path -LiteralPath (Join-Path $profile ".pcvrhub_${identity}_ownership.csv") -PathType Leaf) {
        if(Test-MP2V2Slot -Game $Game -Slot $Slot -Parked:$Parked) { return $true }
        if($Parked) { return $false }
        # An update may be staged while the previous release is still active.
        # Keep that known loader valid until the matching Hub Play action swaps it.
        return ((Test-MP2ActiveRuntimeProof -Game $Game -Slot $Slot) -or
                (Test-MP2LegacyRuntime -Game $Game -Slot $Slot))
    }
    return (Test-MP2LegacySlot -Game $Game -Slot $Slot -Parked:$Parked)
}
function Test-MP2LegacyRuntime {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot)
    if($Slot -eq 'A') {
        $receipt=Get-MP2Receipt $Game
        if(-not $receipt -or $receipt.status -ne 'installed') { return $false }
        foreach($name in $script:MP2SlotFiles.A) {
            $entry=$receipt.files.PSObject.Properties[$name]
            $path=Join-Path $Game $name
            if(-not $entry -or -not $entry.Value.installed_sha256 -or -not(Test-Path -LiteralPath $path -PathType Leaf) -or
                (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$entry.Value.installed_sha256) { return $false }
        }
        return $true
    }
    $manifest=Join-Path $Game '.pcvrhub_maxpayne2vr_ownership.csv'
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)) { return $false }
    try { $rows=@(Import-Csv -LiteralPath $manifest -ErrorAction Stop) } catch { return $false }
    foreach($name in $script:MP2SlotFiles.B) {
        $row=@($rows | Where-Object RelativePath -ieq $name | Select-Object -First 1)[0]
        $path=Join-Path $Game $name
        if(-not $row -or -not $row.InstalledSha256 -or -not(Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine [string]$row.InstalledSha256) { return $false }
    }
    return $true
}
function Get-MP2ActiveMode([string]$Game) {
    $file=Get-MP2ModeFile $Game
    if (Test-Path -LiteralPath $file -PathType Leaf) {
        $value=(Get-Content -LiteralPath $file -Raw).Trim()
        if ($value -eq 'None') { return 'None' }
        if ($value -in @('A','B')) {
            if (Test-MP2Slot -Game $Game -Slot $value) { return $value }
            throw "The saved Max Payne 2 mode ($value) is incomplete. Repair that mod before switching."
        }
        throw 'Unknown Max Payne 2 mode marker. No files were changed.'
    }
    $a=Test-MP2Slot -Game $Game -Slot A
    $b=Test-MP2Slot -Game $Game -Slot B
    if ($a -and $b) { throw 'Both Max Payne 2 loaders appear active. No files were changed.' }
    if ($a) { return 'A' }; if ($b) { return 'B' }
    return 'None'
}
function Resolve-MP2LaunchRoot {
    param([string[]]$Candidates,[ValidateSet('A','B')][string]$Slot)
    $seen=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($candidate in @($Candidates)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        try { $root=[IO.Path]::GetFullPath($candidate) } catch { continue }
        if (-not $seen.Add($root) -or
            -not(Test-Path -LiteralPath (Join-Path $root 'maxpayne2.exe') -PathType Leaf)) { continue }
        try {
            if ((Test-MP2Slot -Game $root -Slot $Slot -Parked) -or
                (Test-MP2Slot -Game $root -Slot $Slot)) { return $root }
        } catch { continue }
    }
    throw "The selected Max Payne 2 VR profile ($Slot) is incomplete in every known game folder. Repair it with Install / manage VR mods."
}
function Write-MP2Mode([string]$Game,[string]$Mode) {
    $path=Get-MP2ModeFile $Game
    $temp=$path+'.new'
    [IO.File]::WriteAllText($temp,$Mode,(New-Object Text.UTF8Encoding $false))
    Move-Item -LiteralPath $temp -Destination $path -Force -ErrorAction Stop
}
function Suspend-MP2Mode([string]$Game) {
    Assert-MP2GameClosed
    $active=Get-MP2ActiveMode $Game
    if ($active -eq 'None') { return 'None' }
    if (-not(Test-MP2Slot -Game $Game -Slot $active)) { throw "Max Payne 2 $active is incomplete." }
    $park=Join-Path (Get-MP2ProfileRoot $Game) $active
    [void](New-Item -ItemType Directory -Path $park -Force)
    foreach ($name in $script:MP2SlotFiles[$active]) {
        $source=Join-Path $Game $name;$target=Join-Path $park $name
        Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
        if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) { throw "Could not safely park $name." }
    }
    if (-not(Test-MP2Slot -Game $Game -Slot $active -Parked)) { throw 'Parked Max Payne 2 profile failed its ownership proof.' }
    try {
        foreach ($name in $script:MP2SlotFiles[$active]) { Remove-Item -LiteralPath (Join-Path $Game $name) -Force -ErrorAction Stop }
        Write-MP2Mode $Game 'None'
        return $active
    } catch {
        foreach ($name in $script:MP2SlotFiles[$active]) {
            $target=Join-Path $Game $name
            if (-not(Test-Path -LiteralPath $target -PathType Leaf)) { Copy-Item -LiteralPath (Get-MP2ProfileFile $Game $active $name) -Destination $target -ErrorAction Stop }
        }
        Write-MP2Mode $Game $active
        throw
    }
}
function Activate-MP2Mode {
    param([string]$Game,[ValidateSet('A','B')][string]$Slot)
    Assert-MP2GameClosed
    $incomplete=$false
    try { $active=Get-MP2ActiveMode $Game }
    catch {
        $modeFile=Get-MP2ModeFile $Game
        $saved=if(Test-Path -LiteralPath $modeFile -PathType Leaf){(Get-Content -LiteralPath $modeFile -Raw).Trim()}else{''}
        if($saved -notin @('A','B')) { throw }
        $active=$saved
        $incomplete=$true
    }
    $parked=Test-MP2Slot -Game $Game -Slot $Slot -Parked
    if (-not $incomplete -and $active -eq $Slot -and (($parked -and (Test-MP2V2Slot -Game $Game -Slot $Slot)) -or -not $parked)) {
        if($parked -and -not(Test-MP2ActiveRuntimeProof -Game $Game -Slot $Slot)) { Write-MP2ActiveRuntimeProof -Game $Game -Slot $Slot }
        return
    }
    if (-not $parked) { throw "The $Slot profile is incomplete; no files were changed." }
    $previous=$active
    if(-not $incomplete -and $active -ne 'None' -and -not(Test-MP2Slot -Game $Game -Slot $active -Parked)) {
        $priorProfile=Join-Path (Get-MP2ProfileRoot $Game) $active
        [void][IO.Directory]::CreateDirectory($priorProfile)
        foreach($name in $script:MP2SlotFiles[$active]) {
            $source=Join-Path $Game $name
            $target=Join-Path $priorProfile $name
            Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
            if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne
               (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) { throw "Could not safely park $name." }
        }
        if(-not(Test-MP2Slot -Game $Game -Slot $active -Parked)) { throw 'The previous Max Payne 2 profile could not be parked.' }
    }
    $all=@($script:MP2SlotFiles.A+$script:MP2SlotFiles.B|Select-Object -Unique)
    $activeNames=if($active -ne 'None'){@($script:MP2SlotFiles[$active])}else{@()}
    if($incomplete) {
        $activeNames=@($activeNames | Where-Object { Test-Path -LiteralPath (Join-Path $Game $_) -PathType Leaf })
        foreach($name in $activeNames) {
            if(-not(Test-MP2KnownRuntimeFragment -Game $Game -Slot $active -Name $name)) {
                throw "Incomplete saved Max Payne 2 mode $active contains an unknown $name. No files were changed."
            }
        }
    }
    foreach($name in $all) {
        $live=Join-Path $Game $name
        if((Test-Path -LiteralPath $live -PathType Leaf) -and $name -notin $activeNames) {
            throw "Unowned file blocks Max Payne 2 mode switch: $name"
        }
    }
    $snapshot=Join-Path (Get-MP2ProfileRoot $Game) ('Switch-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($snapshot)
    $activeProof=Get-MP2ActiveProofFile $Game
    if(Test-Path -LiteralPath $activeProof -PathType Leaf) {
        Copy-Item -LiteralPath $activeProof -Destination (Join-Path $snapshot 'active.csv') -ErrorAction Stop
    }
    foreach($name in $activeNames) {
        Copy-Item -LiteralPath (Join-Path $Game $name) -Destination (Join-Path $snapshot $name) -ErrorAction Stop
    }
    try {
        foreach($name in $activeNames) { Remove-Item -LiteralPath (Join-Path $Game $name) -Force -ErrorAction Stop }
        foreach ($name in $script:MP2SlotFiles[$Slot]) {
            Copy-Item -LiteralPath (Get-MP2ProfileFile $Game $Slot $name) -Destination (Join-Path $Game $name) -ErrorAction Stop
        }
        if (-not(Test-MP2Slot -Game $Game -Slot $Slot)) { throw 'The activated Max Payne 2 profile failed its ownership proof.' }
        Write-MP2ActiveRuntimeProof -Game $Game -Slot $Slot
        Write-MP2Mode $Game $Slot
    } catch {
        $failure=$_
        foreach ($name in $script:MP2SlotFiles[$Slot]) {
            $live=Join-Path $Game $name
            if (Test-Path -LiteralPath $live -PathType Leaf) { Remove-Item -LiteralPath $live -Force -ErrorAction SilentlyContinue }
        }
        if ($previous -ne 'None') {
            foreach ($name in $activeNames) {
                Copy-Item -LiteralPath (Join-Path $snapshot $name) -Destination (Join-Path $Game $name) -Force -ErrorAction Stop
            }
            Write-MP2Mode $Game $previous
        } else {
            Write-MP2Mode $Game 'None'
        }
        if(Test-Path -LiteralPath (Join-Path $snapshot 'active.csv') -PathType Leaf) {
            Copy-Item -LiteralPath (Join-Path $snapshot 'active.csv') -Destination $activeProof -Force -ErrorAction Stop
        } elseif(Test-Path -LiteralPath $activeProof -PathType Leaf) {
            Remove-Item -LiteralPath $activeProof -Force -ErrorAction Stop
        }
        throw $failure
    } finally {
        $root=[IO.Path]::GetFullPath((Get-MP2ProfileRoot $Game)).TrimEnd('\')+'\'
        if([IO.Path]::GetFullPath($snapshot).StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -and
           (Test-Path -LiteralPath $snapshot -PathType Container)) {
            Remove-Item -LiteralPath $snapshot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
function Save-MP2RestoredBaseFiles([string]$Game) {
    $base=Join-Path (Get-MP2ProfileRoot $Game) 'Base'
    [void](New-Item -ItemType Directory -Path $base -Force)
    foreach($name in @($script:MP2SlotFiles.A+$script:MP2SlotFiles.B|Select-Object -Unique)) {
        $live=Join-Path $Game $name
        if(-not(Test-Path -LiteralPath $live -PathType Leaf)){continue}
        $saved=Join-Path $base $name
        if(Test-Path -LiteralPath $saved -PathType Leaf){
            if((Get-FileHash -LiteralPath $saved -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash){
                throw "A different original $name is already preserved. No overwrite was made."
            }
        }else{
            Copy-Item -LiteralPath $live -Destination $saved -ErrorAction Stop
            if((Get-FileHash -LiteralPath $saved -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash){throw "Could not preserve original $name."}
        }
        Remove-Item -LiteralPath $live -Force -ErrorAction Stop
    }
}
function Restore-MP2BaseFiles([string]$Game) {
    $base=Join-Path (Get-MP2ProfileRoot $Game) 'Base'
    if(-not(Test-Path -LiteralPath $base -PathType Container)){return}
    foreach($file in @(Get-ChildItem -LiteralPath $base -File -ErrorAction Stop)){
        $live=Join-Path $Game $file.Name
        if(Test-Path -LiteralPath $live -PathType Leaf){
            if((Get-FileHash -LiteralPath $live -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash){
                throw "Original $($file.Name) cannot be restored over another file."
            }
        }else{Copy-Item -LiteralPath $file.FullName -Destination $live -ErrorAction Stop}
    }
    foreach($file in @(Get-ChildItem -LiteralPath $base -File -ErrorAction Stop)){
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
    }
    Remove-Item -LiteralPath $base -Force -ErrorAction SilentlyContinue
}
