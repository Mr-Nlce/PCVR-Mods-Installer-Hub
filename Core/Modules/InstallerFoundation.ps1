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
if (-not (Get-Command Test-IsTrackableInstalledVersion -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'InstallerSafety.ps1')
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
        [switch]$PinnedDepot
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

    return [pscustomobject][ordered]@{
        SchemaVersion = 1
        Id = $cleanId
        GameName = $cleanName
        Acquisition = $Acquisition
        RequiredInstalledFileGroups = $groups
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
        if ([string]::IsNullOrEmpty(('' + $answer))) { return $true }
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
        $Folders = @([IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'),'Downloads'))
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
        [string[]]$SearchFolders = @(),
        [scriptblock]$ReadInput = $null,
        [scriptblock]$OpenUrl = $null,
        [scriptblock]$FindCandidate = $null,
        [scriptblock]$ValidateCandidate = $null
    )

    if ($InviteUrl -notmatch '^https://discord\.(gg|com/invite)/') { throw 'The Discord invite URL is missing or has the wrong role.' }
    if ($DownloadPostUrl -notmatch '^https://discord\.com/channels/') { throw 'The Discord download-post URL is missing or has the wrong role.' }

    Write-Host "  $Label is $SourceDescription and requires a signed-in browser." -ForegroundColor White
    Write-Host "  The server invite opens first; the download post opens only after you return." -ForegroundColor Gray
    Open-PCVRPageAfterEnter -Message 'Press Enter to open the Discord invite.' -Url $InviteUrl -ReadInput $ReadInput -OpenUrl $OpenUrl
    Open-PCVRPageAfterEnter -Message 'After joining or confirming the server, press Enter to open the download post.' -Url $DownloadPostUrl -ReadInput $ReadInput -OpenUrl $OpenUrl
    [void](Wait-PCVRExplicitEnter -Message 'After the download has finished, press Enter to search your Downloads folder.' -ReadInput $ReadInput)

    $find = {
        if ($FindCandidate) { return (& $FindCandidate) }
        return (Find-PCVRDownloadedCandidate -Patterns $FilePatterns -Folders $SearchFolders)
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
    $candidate = & $find
    if ($candidate -and -not (& $accept $candidate)) { $candidate = $null }
    while (-not $candidate) {
        Write-Host ''
        Write-Host "  $Label was not found yet." -ForegroundColor Yellow
        Write-Host '  Drag the downloaded file onto this window and press Enter,' -ForegroundColor White
        Write-Host '  or type R to search again, O to reopen the post, Q to quit.' -ForegroundColor Gray
        $raw = if ($ReadInput) { & $ReadInput 'Downloaded file, R, O or Q' } else { Read-Host '  Downloaded file, R, O or Q' }
        $value = ('' + $raw).Trim().Trim('"').Trim("'")
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
                continue
            }
            'O' {
                if ($OpenUrl) { & $OpenUrl $DownloadPostUrl | Out-Null }
                else { Start-Process $DownloadPostUrl -ErrorAction Stop | Out-Null }
                continue
            }
            'Q' { return $null }
            default { Write-Host '  Enter a valid file path, R, O or Q.' -ForegroundColor Yellow }
        }
    }
    return $candidate
}

function global:Write-PCVRAtomicText {
    param([Parameter(Mandatory=$true)][string]$Path,[Parameter(Mandatory=$true)][AllowEmptyString()][string]$Value)
    $parent = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
    $temp = Join-Path $parent ('.pcvr-write-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($temp,$Value,(New-Object Text.UTF8Encoding $false))
        Move-Item -LiteralPath $temp -Destination $Path -Force -ErrorAction Stop
    } finally {
        if (Test-Path -LiteralPath $temp -PathType Leaf -ErrorAction SilentlyContinue) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
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
        [ValidateSet('Primary','Secondary')][string]$VersionSlot = 'Primary',
        [string]$Route = 'Current'
    )

    if (-not $Contract -or [int]$Contract.SchemaVersion -ne 1) { throw 'A generation-1 installer contract is required.' }
    if (-not (Test-Path -LiteralPath $GameDir -PathType Container)) { throw "Install target is missing: $GameDir" }
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { throw "Installed version is not trackable: $Version" }
    if (@($InstalledPathReceiptPaths | Where-Object { $_ }).Count -eq 0) { throw 'At least one installed-path receipt is required.' }

    $missing = @()
    $gameRoot = [IO.Path]::GetFullPath($GameDir).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $gamePrefix = $gameRoot + [IO.Path]::DirectorySeparatorChar
    foreach ($group in @($Contract.RequiredInstalledFileGroups)) {
        $alternatives = @((('' + $group) -split '\|') | ForEach-Object { $_.Trim().Replace('/',[IO.Path]::DirectorySeparatorChar).Replace('\',[IO.Path]::DirectorySeparatorChar) } | Where-Object { $_ })
        $present = $false
        foreach ($relative in $alternatives) {
            if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw "Installed evidence escapes the game folder: $relative" }
            $candidate = [IO.Path]::GetFullPath([IO.Path]::Combine($gameRoot,$relative))
            if (-not $candidate.StartsWith($gamePrefix,[StringComparison]::OrdinalIgnoreCase)) { throw "Installed evidence escapes the game folder: $relative" }
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $present = $true; break }
        }
        if (-not $present) { $missing += $group }
    }
    if ($missing.Count) { throw ('Installed payload is incomplete; missing evidence: ' + ($missing -join ', ')) }

    $stampName = if ($VersionSlot -eq 'Secondary') { '.pcvrhub_version_b' } else { '.pcvrhub_version' }
    $stampPath = [IO.Path]::Combine($gameRoot,$stampName)
    $additionalVersionPaths = @($AdditionalVersionReceiptPaths | Where-Object { $_ } | Select-Object -Unique)
    foreach ($versionReceipt in $additionalVersionPaths) {
        $resolvedVersionReceipt = [IO.Path]::GetFullPath($versionReceipt)
        if (-not $resolvedVersionReceipt.StartsWith($gamePrefix,[StringComparison]::OrdinalIgnoreCase)) {
            throw "Additional version receipt escapes the game folder: $versionReceipt"
        }
    }
    $writePaths = @($InstalledPathReceiptPaths | Where-Object { $_ } | Select-Object -Unique) + @($stampPath) + $additionalVersionPaths
    $before = @{}
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

        if ($statusPath) {
            $status = [ordered]@{
                outcome = 'success'
                completedAt = (Get-Date -Format o)
                evidence = @('payload','version','installed_path','route')
                versionWritten = ($VersionSlot -eq 'Primary')
                versionBWritten = ($VersionSlot -eq 'Secondary')
                installedPathWritten = $true
                installedPath = $gameRoot
                versionValue = $(if ($VersionSlot -eq 'Primary') { $Version.Trim() } else { '' })
                versionBValue = $(if ($VersionSlot -eq 'Secondary') { $Version.Trim() } else { '' })
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
