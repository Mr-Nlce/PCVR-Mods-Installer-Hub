# ------------------------------------------------------------
# PCVR Hub installer foundation (contract generation 1)
# ------------------------------------------------------------
# New installers use this module instead of inventing their own interaction
# and completion semantics.  It deliberately builds on InstallerSafety.ps1:
# transport/extraction helpers stay there; this file owns the points that have
# repeatedly failed in integration: explicit read barriers, the exact Discord
# sequence, and a completion receipt that is written only after installed
# payload evidence exists.
# ------------------------------------------------------------

$script:PCVRInstallerFoundationRoot = $PSScriptRoot
. (Join-Path $PSScriptRoot 'InstallerTestReport.ps1')

if (-not (Get-Command Invoke-PCVRUniversalRecovery -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'InstallerRecovery.ps1')
}
if (-not (Get-Command Expand-ArchiveOrFallback -ErrorAction SilentlyContinue) -or
    -not (Get-Command Invoke-SafeDownload -ErrorAction SilentlyContinue) -or
    -not (Get-Command Confirm-PlacedFilesSurvive -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'InstallerSafety.ps1')
}

function global:Write-PCVRFileCheckResult {
    param([string]$Path,[bool]$Present,[string]$Phase,[string]$DisplayName='')
    # The wrapper records this information stream without displaying it.
    $detail=('File check ['+$Phase+']: '+$Path+' = '+$Present)
    Write-Information -MessageData $detail -Tags 'PCVRFileCheck' -InformationAction SilentlyContinue
    if (-not (Get-Variable PCVRInstallerFileCheckDiagnostics -Scope Global -ErrorAction SilentlyContinue)) {
        $global:PCVRInstallerFileCheckDiagnostics=[Collections.Generic.List[string]]::new()
    }
    [void]$global:PCVRInstallerFileCheckDiagnostics.Add($detail)
    if (-not $DisplayName) { $DisplayName=[IO.Path]::GetFileName($Path) }
    if (-not (Get-Variable PCVRInstallerVerifiedFilesShown -Scope Global -ErrorAction SilentlyContinue)) {
        $global:PCVRInstallerVerifiedFilesShown=@{}
    }
    if ($Phase -match 'rollback|before-retry') { return }
    if (-not $Present) {
        $missingKey='missing:'+$Path
        if (-not $global:PCVRInstallerVerifiedFilesShown.ContainsKey($missingKey)) {
            $headingKey='missing-heading:'+$Phase
            if (-not $global:PCVRInstallerVerifiedFilesShown.ContainsKey($headingKey)) {
                Write-Host '  [!!] Required VR files are missing:' -ForegroundColor Yellow
                $global:PCVRInstallerVerifiedFilesShown[$headingKey]=$true
            }
            $name=if($DisplayName -match '(^|[\\/])\.'){ 'Installation record' }else{ $DisplayName }
            Write-Host ('       '+$name+' - missing.') -ForegroundColor Yellow
            $global:PCVRInstallerVerifiedFilesShown[$missingKey]=$true
        }
        return
    }
    if ($DisplayName -match '(^|[\\/])\.') { return }
    if (-not $global:PCVRInstallerVerifiedFilesShown.ContainsKey($Path)) {
        Write-Host ('  [OK] '+$DisplayName+' - verified.') -ForegroundColor Green
        $global:PCVRInstallerVerifiedFilesShown[$Path]=$true
    }
}

function global:New-PCVRInstallerContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$GameName,
        [Parameter(Mandatory=$true)][ValidateSet('GitHub','Thunderstore','Discord','Nexus','Bundled','External','SteamDepot')][string]$Acquisition,
        [Parameter(Mandatory=$true)][string[]]$RequiredInstalledFileGroups,
        [string[]]$Routes = @('Current'),
        [string]$DiscordInviteUrl = '',
        [string]$DiscordDownloadUrl = '',
        [string]$ReleasePageUrl = '',
        [switch]$AntivirusNotice,
        [switch]$PinnedDepot,
        [string[]]$RequiredExternalFileGroups = @()
    )

    $cleanId = $Id.Trim()
    $cleanName = $GameName.Trim()
    $groups = @($RequiredInstalledFileGroups | ForEach-Object { ('' + $_).Trim() } | Where-Object { $_ })
    $routeList = @($Routes | ForEach-Object { ('' + $_).Trim() } | Where-Object { $_ } | Select-Object -Unique)
    if ($cleanId -notmatch '^[a-z0-9][a-z0-9._-]*$') { throw "Installer contract Id is not stable: $Id" }
    if (-not $cleanName) { throw 'Installer contract requires a game name.' }
    if ($groups.Count -eq 0) { throw 'Installer contract requires installed payload evidence.' }
    if ($routeList.Count -eq 0) { throw 'Installer contract requires at least one route.' }
    if ($Acquisition -eq 'Discord') {
        if ($DiscordInviteUrl -notmatch '^https://discord\.(gg|com/invite)/' -or $DiscordDownloadUrl -notmatch '^https://discord\.com/channels/') {
            throw 'Discord contracts require a server invite and a channels download URL.'
        }
    }
    if ($Acquisition -eq 'GitHub' -and (-not $AntivirusNotice)) {
        throw 'New GitHub installers require the compact antivirus notice.'
    }
    if ($Acquisition -eq 'SteamDepot' -and (-not $PinnedDepot)) {
        throw 'Depot contracts must explicitly declare a pinned game/mod/dependency route.'
    }
    foreach ($group in $groups) {
        foreach ($relative in @(($group -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') {
                throw "Installed payload evidence must stay relative to the game folder: $relative"
            }
        }
    }

    $externalGroups=@($RequiredExternalFileGroups|Where-Object {$_})
    foreach($group in $externalGroups){foreach($path in @($group -split '\|')){
        if(-not [IO.Path]::IsPathRooted($path) -or $path -notmatch '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]|/)' -or $path -match '(^|[\\/])\.\.([\\/]|$)'){
            throw 'External installed evidence must name an explicit absolute path.'
        }
    }}
    return [pscustomobject][ordered]@{
        SchemaVersion = 1
        Id = $cleanId
        GameName = $cleanName
        Acquisition = $Acquisition
        RequiredInstalledFileGroups = $groups
        RequiredExternalFileGroups = $externalGroups
        Routes = $routeList
        DiscordInviteUrl = $DiscordInviteUrl.Trim()
        DiscordDownloadUrl = $DiscordDownloadUrl.Trim()
        ReleasePageUrl = $ReleasePageUrl.Trim()
        AntivirusNotice = [bool]$AntivirusNotice
        PinnedDepot = [bool]$PinnedDepot
    }
}

function global:Wait-PCVRExplicitEnter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        # Test seam: receives the prompt and returns one line. Production
        # callers leave this empty and use Read-Host.
        [scriptblock]$ReadInput = $null,
        [switch]$DoNotFlushInput
    )

    if (-not $DoNotFlushInput -and -not $ReadInput) {
        try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    }
    while ($true) {
        Write-Host ''
        Write-Host (">>> " + $Message) -ForegroundColor Black -BackgroundColor Yellow
        $answer = if ($ReadInput) { & $ReadInput $Message } else { Read-Host }
        if ($null -eq $answer) { throw [IO.EndOfStreamException]::new('Input ended before Enter was confirmed.') }
        if ([string]::IsNullOrEmpty([string]$answer)) { return $true }
        Write-Host '  Press Enter without typing anything to continue.' -ForegroundColor Yellow
    }
}

function global:Open-PCVRPageAfterEnter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][string]$Url,
        [scriptblock]$ReadInput = $null,
        [scriptblock]$OpenUrl = $null
    )
    [void](Wait-PCVRExplicitEnter -Message $Message -ReadInput $ReadInput)
    if ($OpenUrl) { & $OpenUrl $Url | Out-Null }
    else { Start-Process $Url -ErrorAction Stop | Out-Null }
}

function global:Find-PCVRDownloadedCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string[]]$Patterns,
        [string[]]$Folders = @()
    )
    if (-not $Folders -or $Folders.Count -eq 0) {
        $Folders = @((Get-PCVRDownloadsFolder))
    }
    $recoveryFile = Get-PCVRRecoveryInput -PathType Leaf
    if ($recoveryFile) {
        foreach ($pattern in @($Patterns | Where-Object { $_ })) {
            if ([IO.Path]::GetFileName($recoveryFile) -like $pattern) { return $recoveryFile }
        }
    }
    foreach ($pattern in @($Patterns | Where-Object { $_ })) {
        foreach ($folder in @($Folders | Where-Object { $_ } | Select-Object -Unique)) {
            if (-not (Test-Path -LiteralPath $folder -PathType Container -ErrorAction SilentlyContinue)) { continue }
            $candidate = Get-ChildItem -LiteralPath $folder -Filter $pattern -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -notmatch '(?i)^\.(crdownload|part|tmp|opdownload)$' } |
                Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
            if ($candidate) { return $candidate.FullName }
        }
    }
    return $null
}

function global:Invoke-PCVRDiscordDownloadFlow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Label,
        [Parameter(Mandatory=$true)][string]$InviteUrl,
        [Parameter(Mandatory=$true)][string]$DownloadPostUrl,
        [Parameter(Mandatory=$true)][string[]]$FilePatterns,
        [string]$SourceDescription = 'a Discord attachment',
        [string]$DownloadChannelInstructions = '',
        [switch]$ConfirmFoundArchive,
        [switch]$AcceptArchiveAtSearchPrompt,
        [string[]]$SearchFolders = @(),
        [scriptblock]$ReadInput = $null,
        [scriptblock]$OpenUrl = $null,
        [scriptblock]$FindCandidate = $null,
        [scriptblock]$ValidateCandidate = $null
    )

    if ($InviteUrl -notmatch '^https://discord\.(gg|com/invite)/') { throw 'The Discord invite URL is missing or has the wrong role.' }
    if ($DownloadPostUrl -notmatch '^https://discord\.com/channels/') { throw 'The Discord download-post URL is missing or has the wrong role.' }

    Write-Host "  $Label is $SourceDescription and requires a signed-in browser." -ForegroundColor White
    $destination = if ($DownloadChannelInstructions) { 'download channel' } else { 'download post' }
    Write-Host "  The server invite opens first. The $destination opens only after you return." -ForegroundColor Gray
    Open-PCVRPageAfterEnter -Message 'Press Enter to open the Discord invite.' -Url $InviteUrl -ReadInput $ReadInput -OpenUrl $OpenUrl
    Open-PCVRPageAfterEnter -Message "After joining or confirming the server, press Enter to open the $destination." -Url $DownloadPostUrl -ReadInput $ReadInput -OpenUrl $OpenUrl
    if ($DownloadChannelInstructions) { Write-Host "  $DownloadChannelInstructions" }
    if ($AcceptArchiveAtSearchPrompt) {
        if (-not $ReadInput) { try { $Host.UI.RawUI.FlushInputBuffer() } catch {} }
        Write-Host '  After the download finishes, return here and drop the complete archive or press Enter to search Downloads.'
    } else {
        [void](Wait-PCVRExplicitEnter -Message 'After the download has finished, press Enter to search your Downloads folder.' -ReadInput $ReadInput)
    }

    $find = {
        try {
            $found = if ($FindCandidate) { & $FindCandidate }
                else { Find-PCVRDownloadedCandidate -Patterns $FilePatterns -Folders $SearchFolders }
        } catch {
            # Automatic discovery is a convenience, never a terminal gate.
            # A broken custom finder must still lead to the standard manual
            # path / drag-and-drop recovery screen.
            Write-Host ("  Automatic Downloads search failed: " + $_.Exception.Message) -ForegroundColor Yellow
            return $null
        }
        if ($found -and $ConfirmFoundArchive) {
            Write-Host "  Found: $found" -ForegroundColor Cyan
            $prompt = 'Use this archive? Enter Y to confirm or N to choose another file'
            $answer = if ($ReadInput) { & $ReadInput $prompt } else { Read-Host "  $prompt" }
            if ($null -eq $answer) { throw [IO.EndOfStreamException]::new('Input ended before the archive was confirmed.') }
            if (('' + $answer).Trim() -ine 'Y') { return $null }
        }
        return $found
    }
    $accept = {
        param([string]$Path)
        if (-not $Path) { return $false }
        if (-not $ValidateCandidate) { return $true }
        try { return [bool](& $ValidateCandidate $Path) }
        catch {
            Write-Host ("  The selected file could not be verified: " + $_.Exception.Message) -ForegroundColor Yellow
            return $false
        }
    }
    $firstArchivePrompt = [bool]$AcceptArchiveAtSearchPrompt
    $candidate = if (-not $firstArchivePrompt) { & $find }
    if ($candidate -and -not (& $accept $candidate)) { $candidate = $null }
    while (-not $candidate) {
        if ($AcceptArchiveAtSearchPrompt) {
            $prompt = if ($firstArchivePrompt) { 'Drop the downloaded archive or press Enter to search Downloads' }
                else { 'Drop the downloaded archive, R to search again, O to reopen, Q to cancel' }
        } else {
            Write-Host ''
            Write-Host "  $Label was not found yet." -ForegroundColor Yellow
            Write-Host '  Drag the downloaded file onto this window and press Enter,' -ForegroundColor White
            Write-Host "  or type R to search again, O to reopen the $destination." -ForegroundColor Gray
            $prompt = 'Downloaded file, R or O'
        }
        $raw = if ($ReadInput) { & $ReadInput $prompt } else { Read-Host "  $prompt" }
        if ($null -eq $raw) { throw [IO.EndOfStreamException]::new('Input ended before a Discord package was selected.') }
        $value = ('' + $raw).Trim().Trim('"').Trim("'").Trim()
        if ($firstArchivePrompt -and -not $value) { $value = 'R' }
        $firstArchivePrompt = $false
        if ($AcceptArchiveAtSearchPrompt -and $value -ieq 'Q') { throw "$Label download cancelled." }
        if ($value -and (Test-Path -LiteralPath $value -PathType Leaf -ErrorAction SilentlyContinue)) {
            $provided = (Get-Item -LiteralPath $value).FullName
            if (& $accept $provided) { return $provided }
            Write-Host '  That file is not yet a readable, usable package. Finish the download or choose another file.' -ForegroundColor Yellow
            continue
        }
        switch ($value.ToUpperInvariant()) {
            'R' {
                $candidate = & $find
                if ($candidate -and -not (& $accept $candidate)) { $candidate = $null }
                if (-not $candidate -and $AcceptArchiveAtSearchPrompt) {
                    Write-Host "  Downloads did not contain a selected, verified archive for $Label." -ForegroundColor Yellow
                }
                continue
            }
            'O' {
                if ($OpenUrl) { & $OpenUrl $DownloadPostUrl | Out-Null }
                else { Start-Process $DownloadPostUrl -ErrorAction Stop | Out-Null }
                continue
            }
            default { Write-Host '  Enter a valid file path, R or O.' -ForegroundColor Yellow }
        }
    }
    return $candidate
}

function global:Write-PCVRAtomicText {
    param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][AllowEmptyString()][string]$Value)
    $Path = [IO.Path]::GetFullPath($Path)
    if ([IO.Directory]::Exists($Path)) { throw "The receipt target is a directory, not a file: $Path" }
    $parent = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
    $temp = Join-Path $parent ('.pcvr-write-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    $swap = $temp + '.previous'
    try {
        [IO.File]::WriteAllText($temp,$Value,(New-Object Text.UTF8Encoding $false))
        # File APIs never reinterpret an existing destination directory as a
        # container. Replace/Move also keep publication on the same volume.
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temp,$Path,$swap,$true) }
        else { [IO.File]::Move($temp,$Path) }
    } finally {
        if (Test-Path -LiteralPath $temp -PathType Leaf -ErrorAction SilentlyContinue) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $swap -PathType Leaf -ErrorAction SilentlyContinue) { Remove-Item -LiteralPath $swap -Force -ErrorAction SilentlyContinue }
    }
}

function global:Complete-PCVRInstallTransaction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Contract,
        [Parameter(Mandatory=$true)][string]$GameDir,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string[]]$InstalledPathReceiptPaths,
        [string[]]$AdditionalVersionReceiptPaths = @(),
        [ValidateSet('Primary','Secondary','Tertiary')][string]$VersionSlot = 'Primary',
        [string]$Route = 'Current',
        [string[]]$InstalledVersionReceiptPaths = @()
    )

    if (-not $Contract -or [int]$Contract.SchemaVersion -ne 1) { throw 'A generation-1 installer contract is required.' }
    if (-not (Test-Path -LiteralPath $GameDir -PathType Container)) { throw "Install target is missing: $GameDir" }
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { throw "Installed version is not trackable: $Version" }
    if (@($InstalledPathReceiptPaths | Where-Object { $_ }).Count -eq 0) { throw 'At least one installed-path receipt is required.' }

    $missing = @()
    $gameRoot = [IO.Path]::GetFullPath($GameDir).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $gamePrefix = $gameRoot + [IO.Path]::DirectorySeparatorChar
    foreach ($group in @($Contract.RequiredInstalledFileGroups)) {
        $alternatives = @((('' + $group) -split '\|') | ForEach-Object { $_.Trim().Replace('\','/').Replace('/',[IO.Path]::DirectorySeparatorChar).Replace('\',[IO.Path]::DirectorySeparatorChar) } | Where-Object { $_ })
        $present = $false
        foreach ($relative in $alternatives) {
            if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw "Installed evidence escapes the game folder: $relative" }
            $candidate = [IO.Path]::GetFullPath([IO.Path]::Combine($gameRoot,$relative))
            if (-not $candidate.StartsWith($gamePrefix,[StringComparison]::OrdinalIgnoreCase)) { throw "Installed evidence escapes the game folder: $relative" }
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $present = $true; break }
        }
        if (-not $present) { $missing += $group }
    }
    $externalProofs=if($Contract -is [Collections.IDictionary]){$Contract['RequiredExternalFileGroups']}elseif($Contract.PSObject.Properties['RequiredExternalFileGroups']){$Contract.RequiredExternalFileGroups}else{@()}
    foreach($group in @($externalProofs|Where-Object {$_})){
        $present=$false
        foreach($path in @($group -split '\|')){
            if(-not [IO.Path]::IsPathRooted($path) -or $path -notmatch '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]|/)' -or $path -match '(^|[\\/])\.\.([\\/]|$)'){throw 'External installed evidence must name an explicit absolute path.'}
            if([IO.File]::Exists($path)){$present=$true;break}
        }
        if(-not $present){$missing+=$group}
    }
    if ($missing.Count) { throw ('Installed payload is incomplete; missing evidence: ' + ($missing -join ', ')) }

    $stampName = if ($VersionSlot -eq 'Tertiary') { '.pcvrhub_version_c' } elseif ($VersionSlot -eq 'Secondary') { '.pcvrhub_version_b' } else { '.pcvrhub_version' }
    $stampPath = [IO.Path]::Combine($gameRoot,$stampName)
    $additionalVersionPaths = @($AdditionalVersionReceiptPaths | Where-Object { $_ } | Select-Object -Unique)
    foreach ($versionReceipt in $additionalVersionPaths) {
        $resolvedVersionReceipt = [IO.Path]::GetFullPath($versionReceipt)
        if (-not $resolvedVersionReceipt.StartsWith($gamePrefix,[StringComparison]::OrdinalIgnoreCase)) {
            throw "Additional version receipt escapes the game folder: $versionReceipt"
        }
    }
    $receiptFolders = @($InstalledPathReceiptPaths | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($_)) } | Select-Object -Unique)
    $portableVersionPaths = @($InstalledVersionReceiptPaths | Where-Object { $_ } | Select-Object -Unique)
    foreach ($versionReceipt in $portableVersionPaths) {
        $resolved = [IO.Path]::GetFullPath($versionReceipt)
        if ($receiptFolders -notcontains [IO.Path]::GetDirectoryName($resolved)) {
            throw 'Installed version receipt escapes the declared installer receipt folder.'
        }
    }
    $writePaths = @($InstalledPathReceiptPaths | Where-Object { $_ } | Select-Object -Unique) + @($stampPath) + $additionalVersionPaths + $portableVersionPaths
    $before = @{}
    foreach ($path in $writePaths) {
        if ([IO.Directory]::Exists([IO.Path]::GetFullPath($path))) { throw "The receipt target is a directory, not a file: $path" }
    }
    foreach ($path in $writePaths) {
        $before[$path] = if (Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue) {
            [pscustomobject]@{ Exists=$true; Bytes=[IO.File]::ReadAllBytes($path) }
        } else { [pscustomobject]@{ Exists=$false; Bytes=$null } }
    }

    $statusPath = ('' + $env:PCVR_HUB_INSTALL_STATUS_PATH).Trim()
    if ($statusPath) {
        $statusLeaf = [IO.Path]::GetFileName($statusPath)
        $statusParent = Split-Path -Parent $statusPath
        if ($statusLeaf -notlike 'install_*.json' -or (Split-Path -Leaf $statusParent) -ne 'Transactions') {
            throw 'Installer transaction status path is outside the expected Transactions folder.'
        }
    }

    try {
        foreach ($receipt in @($InstalledPathReceiptPaths | Where-Object { $_ } | Select-Object -Unique)) {
            Write-PCVRAtomicText -Path $receipt -Value ([IO.Path]::GetFullPath($GameDir))
        }
        Write-PCVRAtomicText -Path $stampPath -Value $Version.Trim()
        foreach ($versionReceipt in $additionalVersionPaths) {
            Write-PCVRAtomicText -Path $versionReceipt -Value $Version.Trim()
        }
        foreach ($versionReceipt in $portableVersionPaths) {
            Write-PCVRAtomicText -Path $versionReceipt -Value $Version.Trim()
        }

        if ($statusPath) {
            $status = [ordered]@{
                outcome = 'success'
                completedAt = (Get-Date -Format o)
                evidence = @('payload','version','installed_path','route')
                versionWritten = ($VersionSlot -eq 'Primary')
                versionBWritten = ($VersionSlot -eq 'Secondary')
                versionCWritten = ($VersionSlot -eq 'Tertiary')
                installedPathWritten = $true
                installedPath = $gameRoot
                versionValue = $(if ($VersionSlot -eq 'Primary') { $Version.Trim() } else { '' })
                versionBValue = $(if ($VersionSlot -eq 'Secondary') { $Version.Trim() } else { '' })
                versionCValue = $(if ($VersionSlot -eq 'Tertiary') { $Version.Trim() } else { '' })
                route = $Route
                contractId = [string]$Contract.Id
                runId = ('' + $env:PCVR_HUB_INSTALL_RUN_ID)
            }
            Write-PCVRAtomicText -Path $statusPath -Value ($status | ConvertTo-Json -Compress)
        }
        Write-Host "  [OK] $($Contract.GameName) $Route installation verified and committed." -ForegroundColor Green
        return $true
    } catch {
        foreach ($path in $writePaths) {
            try {
                if ($before[$path].Exists) { [IO.File]::WriteAllBytes($path,[byte[]]$before[$path].Bytes) }
                elseif (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
            } catch {}
        }
        throw
    }
}
