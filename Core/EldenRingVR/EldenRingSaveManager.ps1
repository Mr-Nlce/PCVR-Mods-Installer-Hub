# =============================================================
# Elden Ring current/depot save manager
# =============================================================
# Elden Ring stores one save set per Steam account, outside either game
# installation.  A newer save cannot be opened by the pinned 1.16.2 build.
# These helpers keep the current and depot sets under distinct suffixes,
# make a verified safety copy before every real switch, and never overwrite
# a parked set.

$script:EldenSaveName          = "ER0000.sl2"
$script:EldenCurrentSuffix     = ".build-current"
$script:EldenDepotSuffix       = ".build-depot"
$script:EldenActiveBuildMarker = ".pcvrhub-active-build"
$script:EldenBackupFolder      = ".pcvrhub-save-backups"

function global:Get-EldenRingSaveSetFiles {
    param(
        [Parameter(Mandatory=$true)][string]$SaveDirectory,
        [string]$Suffix = ""
    )
    $result = @()
    # Parenthesize the expression after the comma. In Windows PowerShell 5.1,
    # @($name, $name + '.bak') otherwise binds the + outside the second
    # element and can emit the main filename twice.
    foreach ($base in @($script:EldenSaveName, ($script:EldenSaveName + ".bak"))) {
        $path = Join-Path $SaveDirectory ($base + $Suffix)
        if (Test-Path -LiteralPath $path -PathType Leaf) { $result += $path }
    }
    return @($result)
}

function global:Get-EldenRingSaveState {
    param([Parameter(Mandatory=$true)][string]$SaveDirectory)
    $marker = ""
    $markerPath = Join-Path $SaveDirectory $script:EldenActiveBuildMarker
    if (Test-Path -LiteralPath $markerPath -PathType Leaf) {
        try {
            $candidate = (Get-Content -LiteralPath $markerPath -Raw -ErrorAction Stop).Trim()
            if ($candidate -in @("Current","Depot")) { $marker = $candidate }
        } catch {}
    }
    return [pscustomobject]@{
        LiveFiles    = @(Get-EldenRingSaveSetFiles -SaveDirectory $SaveDirectory)
        CurrentFiles = @(Get-EldenRingSaveSetFiles -SaveDirectory $SaveDirectory -Suffix $script:EldenCurrentSuffix)
        DepotFiles   = @(Get-EldenRingSaveSetFiles -SaveDirectory $SaveDirectory -Suffix $script:EldenDepotSuffix)
        Marker       = $marker
        MarkerPath   = $markerPath
    }
}

function global:Get-EldenRingLegacySaveSets {
    param([Parameter(Mandatory=$true)][string]$SaveDirectory)
    $groups = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $SaveDirectory -File -ErrorAction SilentlyContinue)) {
        if ($file.Name -match '^ER0000\.sl2(?:\.bak)?(?<suffix>\.before-vr-.+)$') {
            $suffix = [string]$matches['suffix']
            if (-not $groups.ContainsKey($suffix)) { $groups[$suffix] = @() }
            $groups[$suffix] += $file.FullName
        }
    }
    return @($groups.Keys | Sort-Object -Descending | ForEach-Object {
        [pscustomobject]@{ Suffix=[string]$_; Files=@($groups[$_]) }
    })
}

function global:Move-EldenRingSaveOperations {
    param([Parameter(Mandatory=$true)][array]$Operations)
    if ($Operations.Count -eq 0) { return $true }

    $sources = @{}
    foreach ($op in $Operations) { $sources[[string]$op.Source] = $true }
    foreach ($op in $Operations) {
        if (-not (Test-Path -LiteralPath $op.Source -PathType Leaf)) {
            throw "The source save disappeared before the switch: $($op.Source)"
        }
        if ((Test-Path -LiteralPath $op.Destination) -and -not $sources.ContainsKey([string]$op.Destination)) {
            throw "A destination save already exists; refusing to overwrite it: $($op.Destination)"
        }
    }

    $moved = New-Object System.Collections.ArrayList
    try {
        foreach ($op in $Operations) {
            Move-Item -LiteralPath $op.Source -Destination $op.Destination -ErrorAction Stop
            [void]$moved.Add($op)
        }
        return $true
    } catch {
        for ($i = $moved.Count - 1; $i -ge 0; $i--) {
            $op = $moved[$i]
            try {
                if ((Test-Path -LiteralPath $op.Destination -PathType Leaf) -and -not (Test-Path -LiteralPath $op.Source)) {
                    Move-Item -LiteralPath $op.Destination -Destination $op.Source -ErrorAction Stop
                }
            } catch {}
        }
        throw
    }
}

function global:Import-EldenRingLegacyCurrentSave {
    param(
        [Parameter(Mandatory=$true)][string]$SaveDirectory,
        [switch]$NoPrompt,
        [string]$SelectedLegacySuffix = ""
    )
    $state = Get-EldenRingSaveState -SaveDirectory $SaveDirectory
    if ($state.CurrentFiles.Count -gt 0) { return $true }
    $legacy = @(Get-EldenRingLegacySaveSets -SaveDirectory $SaveDirectory)
    if ($legacy.Count -eq 0) { return $true }

    $selected = $null
    if ($SelectedLegacySuffix) {
        $selected = $legacy | Where-Object { $_.Suffix -eq $SelectedLegacySuffix } | Select-Object -First 1
        if (-not $selected) { return $false }
    } elseif ($legacy.Count -eq 1) {
        $selected = $legacy[0]
    } elseif ($NoPrompt) {
        Write-Host "  [XX] Several legacy .before-vr save sets exist; none was selected automatically." -ForegroundColor Red
        return $false
    } else {
        Write-Host ""; Write-Host "  Several older Hub save backups were found:" -ForegroundColor White
        for ($i=0; $i -lt $legacy.Count; $i++) {
            Write-Host "   [$($i+1)] $($legacy[$i].Suffix) ($($legacy[$i].Files.Count) file(s))" -ForegroundColor Gray
        }
        $pick = ""
        for ($try=1; $try -le 20; $try++) {
            $pick = ("" + (Read-Host "  Which one is the current-build save? [1-$($legacy.Count), c=cancel]")).Trim().ToLower()
            if ($pick -eq "c") { return $false }
            if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $legacy.Count) { break }
        }
        if ($pick -notmatch '^\d+$' -or [int]$pick -lt 1 -or [int]$pick -gt $legacy.Count) { return $false }
        $selected = $legacy[[int]$pick - 1]
    }

    $ops = @()
    foreach ($source in $selected.Files) {
        $leaf = Split-Path -Leaf $source
        $base = $leaf.Substring(0, $leaf.Length - $selected.Suffix.Length)
        $ops += [pscustomobject]@{
            Source=$source
            Destination=(Join-Path $SaveDirectory ($base + $script:EldenCurrentSuffix))
        }
    }
    try {
        [void](Move-EldenRingSaveOperations -Operations $ops)
        Write-Host "  [OK] Imported the older $($selected.Suffix) save as the protected current-build set." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [XX] The older save could not be imported safely: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function global:Backup-EldenRingLiveSaveVerified {
    param(
        [Parameter(Mandatory=$true)][string]$SaveDirectory,
        [Parameter(Mandatory=$true)][ValidateSet("Current","Depot")][string]$Build
    )
    $live = @(Get-EldenRingSaveSetFiles -SaveDirectory $SaveDirectory)
    if ($live.Count -eq 0) { return $null }

    $backupRoot = Join-Path $SaveDirectory $script:EldenBackupFolder
    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss-fff")
    $backup = Join-Path $backupRoot ($stamp + "-" + $Build.ToLowerInvariant() + "-" + [Guid]::NewGuid().ToString("N").Substring(0,6))
    New-Item -ItemType Directory -Path $backup -Force -ErrorAction Stop | Out-Null
    foreach ($source in $live) {
        $destination = Join-Path $backup (Split-Path -Leaf $source)
        Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
        $sourceInfo = Get-Item -LiteralPath $source -ErrorAction Stop
        $destInfo = Get-Item -LiteralPath $destination -ErrorAction Stop
        if ($sourceInfo.Length -ne $destInfo.Length -or
            (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) {
            throw "The verified safety copy does not match $source"
        }
    }
    return $backup
}

function global:Resolve-EldenRingActiveSaveBuild {
    param(
        [Parameter(Mandatory=$true)]$State,
        [ValidateSet("","Current","Depot")][string]$AssumeLiveBuild = ""
    )
    # A single parked set is stronger evidence than the marker. This also
    # recovers cleanly if the process stopped after the moves but before the
    # small marker file could be updated.
    if ($State.CurrentFiles.Count -gt 0 -and $State.DepotFiles.Count -eq 0) { return "Depot" }
    if ($State.DepotFiles.Count -gt 0 -and $State.CurrentFiles.Count -eq 0) { return "Current" }
    if ($State.Marker -in @("Current","Depot")) { return [string]$State.Marker }
    if ($State.LiveFiles.Count -gt 0 -and $AssumeLiveBuild) { return $AssumeLiveBuild }
    if ($State.LiveFiles.Count -eq 0 -and $State.CurrentFiles.Count -eq 0 -and $State.DepotFiles.Count -eq 0) { return "" }
    return "Unknown"
}

function global:Invoke-EldenRingSaveSwitch {
    param(
        [Parameter(Mandatory=$true)][string]$SaveDirectory,
        [Parameter(Mandatory=$true)][ValidateSet("Current","Depot")][string]$TargetBuild,
        [ValidateSet("","Current","Depot")][string]$AssumeLiveBuild = "",
        [string]$LegacyCurrentSuffix = "",
        [switch]$NoPrompt,
        [switch]$RequireConfirmation
    )
    if (-not (Test-Path -LiteralPath $SaveDirectory -PathType Container)) {
        return [pscustomobject]@{ Success=$false; Changed=$false; Reason="Save folder does not exist"; Backup=$null }
    }
    if (-not (Import-EldenRingLegacyCurrentSave -SaveDirectory $SaveDirectory -NoPrompt:$NoPrompt -SelectedLegacySuffix $LegacyCurrentSuffix)) {
        return [pscustomobject]@{ Success=$false; Changed=$false; Reason="Legacy save selection is unresolved"; Backup=$null }
    }

    $state = Get-EldenRingSaveState -SaveDirectory $SaveDirectory
    $active = Resolve-EldenRingActiveSaveBuild -State $state -AssumeLiveBuild $AssumeLiveBuild
    if ($active -eq "Unknown" -and -not $NoPrompt -and $state.LiveFiles.Count -gt 0) {
        Write-Host ""; Write-Host "  Which build wrote the live ER0000.sl2?" -ForegroundColor White
        Write-Host "   [1] Current Steam build" -ForegroundColor Cyan
        Write-Host "   [2] Pinned 1.16.2 depot build" -ForegroundColor Cyan
        $pick = ("" + (Read-Host "  Enter 1 or 2")).Trim()
        if ($pick -eq "1") { $active = "Current" }
        elseif ($pick -eq "2") { $active = "Depot" }
    }
    if ($active -eq "Unknown") {
        return [pscustomobject]@{ Success=$false; Changed=$false; Reason="The active save build is ambiguous"; Backup=$null }
    }
    if (-not $active) {
        try { Set-Content -LiteralPath $state.MarkerPath -Value $TargetBuild -Encoding ASCII -NoNewline -Force -ErrorAction Stop }
        catch { return [pscustomobject]@{ Success=$false; Changed=$false; Reason=$_.Exception.Message; Backup=$null } }
        return [pscustomobject]@{ Success=$true; Changed=$false; Reason="No save exists yet; target recorded"; Backup=$null }
    }
    if ($active -eq $TargetBuild) {
        try { Set-Content -LiteralPath $state.MarkerPath -Value $TargetBuild -Encoding ASCII -NoNewline -Force -ErrorAction Stop } catch {}
        return [pscustomobject]@{ Success=$true; Changed=$false; Reason="$TargetBuild is already active"; Backup=$null }
    }

    if ($RequireConfirmation -and -not $NoPrompt) {
        Write-Host ""; Write-Host "  YOUR SAVE HAS TO MOVE ASIDE " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host ""
        Write-Host "  The live $active-build save will be parked, and the $TargetBuild" -ForegroundColor White
        Write-Host "  set will become active. A verified dated backup is made first." -ForegroundColor White
        $answer = ("" + (Read-Host "  Continue? [y/n]")).Trim().ToLower()
        if ($answer -notin @("y","yes")) {
            return [pscustomobject]@{ Success=$false; Changed=$false; Reason="Cancelled"; Backup=$null }
        }
    }

    $activeSuffix = if ($active -eq "Current") { $script:EldenCurrentSuffix } else { $script:EldenDepotSuffix }
    $targetSuffix = if ($TargetBuild -eq "Current") { $script:EldenCurrentSuffix } else { $script:EldenDepotSuffix }
    $operations = @()
    foreach ($source in $state.LiveFiles) {
        $operations += [pscustomobject]@{ Source=$source; Destination=($source + $activeSuffix) }
    }
    foreach ($source in @(Get-EldenRingSaveSetFiles -SaveDirectory $SaveDirectory -Suffix $targetSuffix)) {
        $operations += [pscustomobject]@{ Source=$source; Destination=$source.Substring(0, $source.Length - $targetSuffix.Length) }
    }

    $backup = $null
    try {
        $backup = Backup-EldenRingLiveSaveVerified -SaveDirectory $SaveDirectory -Build $active
        [void](Move-EldenRingSaveOperations -Operations $operations)
    } catch {
        return [pscustomobject]@{ Success=$false; Changed=$false; Reason=$_.Exception.Message; Backup=$backup }
    }
    try {
        Set-Content -LiteralPath $state.MarkerPath -Value $TargetBuild -Encoding ASCII -NoNewline -Force -ErrorAction Stop
        $reason = "$TargetBuild is now active"
    } catch {
        # The folder layout itself still identifies the active side whenever
        # only one parked set exists. A marker write failure must not claim
        # the already completed, verified save moves failed.
        $reason = "$TargetBuild is now active; the advisory marker could not be updated"
    }
    return [pscustomobject]@{ Success=$true; Changed=$true; Reason=$reason; Backup=$backup }
}

function global:Get-EldenRingSaveAccountDirectories {
    param([Parameter(Mandatory=$true)][string]$SaveRoot)
    if (-not (Test-Path -LiteralPath $SaveRoot -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $SaveRoot -Directory -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -match '^\d+$' } | Sort-Object Name)
}

function global:Select-EldenRingSaveAccountDirectory {
    param(
        [Parameter(Mandatory=$true)][string]$SaveRoot,
        [switch]$NoPrompt
    )
    $accounts = @(Get-EldenRingSaveAccountDirectories -SaveRoot $SaveRoot)
    if ($accounts.Count -eq 0) { return $null }
    if ($accounts.Count -eq 1) { return $accounts[0].FullName }
    if ($NoPrompt) { return $null }
    Write-Host ""; Write-Host "  More than one Elden Ring Steam account was found:" -ForegroundColor White
    for ($i=0; $i -lt $accounts.Count; $i++) { Write-Host "   [$($i+1)] $($accounts[$i].Name)" -ForegroundColor Gray }
    $pick = ""
    for ($try=1; $try -le 20; $try++) {
        $pick = ("" + (Read-Host "  Which account? [1-$($accounts.Count)]")).Trim()
        if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $accounts.Count) { break }
    }
    if ($pick -notmatch '^\d+$' -or [int]$pick -lt 1 -or [int]$pick -gt $accounts.Count) { return $null }
    return $accounts[[int]$pick - 1].FullName
}
