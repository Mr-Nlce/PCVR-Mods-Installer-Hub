$ErrorActionPreference = 'Stop'
# The three Steam HL2VR titles share this game folder.
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')

$release = 'https://github.com/vittorioromeo/HL2VRU/releases'
$required = @('hlvr\bin\client.dll','hlvr\bin\server.dll','episodicvr\bin\client.dll','episodicvr\bin\server.dll','bin\d3d9.dll','hlvr\cfg\steamvr\actions.json')
$keep = @('hlvr\cfg\hlvr.cfg','episodicvr\cfg\episodicvr.cfg','ep2vr\cfg\ep2vr.cfg','episodicvr\cfg\modsettings.cfg')

function Test-HL2VRUArchive([string]$Path,[string]$Tool,[string[]]$RequiredFiles) {
    $ErrorActionPreference = 'Continue'
    $list = @(& $Tool l -slt -p- -- $Path 2>&1)
    if ($LASTEXITCODE -ne 0) { return $false }
    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $body = $false
    foreach ($line in $list) {
        if ($line -eq '----------') { $body = $true; continue }
        if (-not $body) { continue }
        if ($line -match '^(Symbolic Link|Hard Link|Alternate Stream) = .+' -or
            $line -match '^Attributes = .* lrwx' -or $line -eq 'Encrypted = +') { return $false }
        if ($line -notmatch '^Path = (.+)$') { continue }
        $name = $Matches[1].Replace('/','\')
        if ($name -notmatch '^(bin|hlvr|episodicvr|ep2vr)(\\|$)' -or
            $name -match '[:\x00-\x1F]|(^|\\)\.{1,2}(\\|$)|[. ](\\|$)|\\\\' -or
            -not $names.Add($name)) { return $false }
    }
    foreach ($file in $RequiredFiles) {
        if (-not $names.Contains($file)) { return $false }
    }
    return $true
}

Write-Host ''
Write-Host ' Half-Life 2: VR Mod - Unleashed by Vittorio Romeo' -ForegroundColor Magenta
Write-Host ' Adds dual-wielding, physical melee, jumping and weapon handling tweaks.'
Write-Host ' Install the original Half-Life 2: VR Mod in Steam first. Both episodes are optional.'
Write-Host ' If required files disappear after copying, the installer offers recovery guidance.'
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to continue...')

Write-Host '--- [1/4] Locate Half-Life 2: VR Mod ---' -ForegroundColor Cyan
while ($true) {
    $game = Find-SteamGameFolder -AppId '658920' -SteamFolderNames 'Half-Life 2 VR' -ProbeExe 'hl2vr.exe' -HubGameId 'half-life-2-vr'
    if ($game -and (Test-Path -LiteralPath (Join-Path $game 'hl2vr.exe') -PathType Leaf)) { break }
    $answer = Invoke-InstallerFallback -Action 'Locate Half-Life 2: VR Mod' -Url 'https://store.steampowered.com/app/658920' -AllowSkip:$false -Instructions 'Install the base Half-Life 2: VR Mod in Steam, let it finish and choose Retry.'
    if ($answer -ne 'retry') { throw 'The Half-Life 2 VR base game is required.' }
}
Write-Host " [OK] Found Half-Life 2 VR: $game" -ForegroundColor Green

Write-Host '--- [2/4] Check 7-Zip availability ---' -ForegroundColor Cyan
$sevenZip = Get-SevenZip -Required
if (-not $sevenZip) { throw 'A usable 7-Zip installation is required.' }

$work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
$keepWork = $false
try {
    Write-Host '--- [3/4] Download and check the Unleashed archive ---' -ForegroundColor Cyan
    $archive = Join-Path $work 'HL2VRU_0.0.7.7z'
    $checkArchive = (Get-Command Test-HL2VRUArchive).ScriptBlock
    $validate = { param($candidate) & $checkArchive $candidate $sevenZip $required }.GetNewClosure()
    $download = Invoke-SafeDownload -Urls "$release/download/v0.0.7/HL2VRU_0.0.7.7z" -Destination $archive -Label 'HL2VRU' -ManualUrl "$release/tag/v0.0.7" -FunctionalPayloadOnly -DisableGitHubAssetReresolution -Validator $validate -AllowSkip:$false -Instructions 'Download the Windows 7z asset from the release page and drag the archive here, or paste its full path.'
    if ($download -ne $true -and $download -ne 'retry') { throw 'The Unleashed download was cancelled.' }

    $stage = Join-Path $work 'stage'
    $null = [IO.Directory]::CreateDirectory($stage)
    $extractExit = & {
        $ErrorActionPreference = 'Continue'
        & $sevenZip x -y -p- -bso0 "-o$stage" -- $archive 2>&1 | ForEach-Object { Write-Host $_ }
        $LASTEXITCODE
    }
    if ($extractExit -ne 0) { throw "7-Zip extraction failed (exit $extractExit). No game files were changed." }
    foreach ($file in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $stage $file) -PathType Leaf)) { throw "The archive is missing a required Unleashed file: $file" }
    }

    Write-Host '--- [4/4] Install and verify Unleashed ---' -ForegroundColor Cyan
    Write-Host ' Close Half-Life 2 VR. Existing player settings stay in place. Replaced originals are backed up.'
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install Unleashed...')
    if (Get-Process -Name 'hl2vr' -ErrorAction SilentlyContinue) { throw 'Close Half-Life 2 VR before installing Unleashed.' }

    $snapshot = Save-PCVRPublisherZipSnapshot -GameRoot $game -Stage $stage -Identity hl2vru -SnapshotRoot (Join-Path $work 'rollback')
    $install = @{SourceRoot=$stage; GameRoot=$game; Identity='hl2vru'; KeepExistingRelativePaths=$keep; ProgressLabel='Installing Unleashed'}
    $targets = @($required | ForEach-Object { Join-Path $game $_ })
    try {
        [void](Install-OwnedModPayload @install)
        foreach ($path in $targets) {
            $present = [IO.File]::Exists($path)
            Write-PCVRFileCheckResult -Path $path -Present $present -Phase 'after-copy'
            if (-not $present) { throw "Required Unleashed file is missing after copying: $path" }
        }
        $recopy = { [void](Install-OwnedModPayload @install) }.GetNewClosure()
        $survived = Confirm-PlacedFilesSurvive -Paths $targets -GameDir $game -Recopy $recopy -NoClear
        foreach ($path in $targets) {
            $present = [IO.File]::Exists($path)
            Write-PCVRFileCheckResult -Path $path -Present $present -Phase 'after-observation'
            if (-not $present) { $survived = $false }
        }
        if (-not $survived) { throw 'Required Unleashed files are missing. Review the install log and try again.' }
        Write-PCVRAtomicText -Path (Join-Path $PSScriptRoot '.installed_path') -Value $game
    } catch {
        $problem = $_
        try { Restore-PCVRPublisherZipSnapshot -GameRoot $game -Snapshot $snapshot } catch {
            $keepWork = $true
            throw ("Unleashed installation failed: $problem. Rollback failed: $_. Recovery files: $work")
        }
        throw $problem
    }

    Write-Host ' [OK] HL2VRU Unleashed installed.' -ForegroundColor Green
    Write-Host ' Launch Half-Life 2: VR Mod or an installed episode from Steam.'
    Write-Host ' Look for UNLEASHED on the title screen and set up both controllers in SteamVR bindings.'
    Write-Host ''
    Write-Host ' Dual wield the crowbar. Two-fist the gravity gun. Unleashed.' -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to exit...')
} finally {
    if (-not $keepWork) { Remove-PCVRInstallerTempSession -Path $work }
}
