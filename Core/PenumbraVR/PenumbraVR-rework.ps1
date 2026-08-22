# ============================================================
#  PENUMBRA VR REWORK - by rubocopter
# ============================================================
#  Loaded from PenumbraVR-core.ps1 when the user picks option 2.
#  Runs in the SAME session, so the console helpers, $RW_* values
#  and the shared InstallerSafety helpers are already in scope.
#
#  THIS ONE MERGES INTO THE STEAM COPY, unlike the older mod which
#  works on a copy under C:\Games. Its own installer backs up every
#  file it replaces under <game>\.penumbravr\backup and can put
#  them all back with -Restore. So we do NOT copy the game and we
#  do NOT unpack anything ourselves - we fetch the release, verify
#  it, and hand over to the author's Install-PenumbraVR.bat.
#
#  ALL RELEASES ARE PRERELEASES -> the release LIST is queried.
# ============================================================

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " $RW_NAME by $RW_AUTHOR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Per-finger hand animation from the SteamVR skeletal input." -ForegroundColor White
Write-Host "  Devices without it get a synthesized closing sequence:" -ForegroundColor Gray
Write-Host "  pinky and ring first, middle follows, index on the trigger." -ForegroundColor Gray
Write-Host ""
Write-Host "  EARLY ALPHA - only PS VR2 Sense is hardware-validated. " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Pause-User "Press Enter to begin..." | Out-Null

# ---- 1. Locate the Steam copy ---------------------------------
Write-Step 1 3 "Locating Penumbra: Overture (Steam)"
$rwGame = Find-SteamGameFolder -AppId $STEAM_APPID `
            -SteamFolderNames @("Penumbra Overture") `
            -ProbeExe "redist\Penumbra.exe" `
            -GogNames @("Penumbra Overture")
if (-not $rwGame) {
    $rwGame = Get-GameFolderInteractive -GameName "Penumbra Overture" -ProbeFile "redist\Penumbra.exe"
}
if (-not $rwGame -or -not (Test-Path -LiteralPath "$rwGame\redist\Penumbra.exe")) {
    Write-Fail "Could not find redist\Penumbra.exe - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $rwGame"

# The older mod lives somewhere else entirely, so both can be on disk
# at once - but say which one this run is touching, so nobody thinks
# the other has been replaced.
if (Test-Path -LiteralPath "$rwGame\.penumbravr") {
    Write-Info "This copy already carries the rework - it will be updated in place."
}

# ---- 2. Fetch the release -------------------------------------
Write-Step 2 3 "Downloading $RW_NAME"

$rwUrl = $null; $rwTag = ""; $rwAsset = ""; $rwSize = 0; $rwBody = ""
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$RW_REPO/releases" `
                -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    foreach ($r in @($rels)) {
        $a = @($r.assets) | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1
        if ($a) {
            $rwUrl = [string]$a.browser_download_url; $rwTag = [string]$r.tag_name
            $rwAsset = [string]$a.name; $rwSize = [long]$a.size; $rwBody = [string]$r.body
            break
        }
    }
} catch { Write-Warn "GitHub could not be reached - falling back to the releases page." }
if ($rwUrl) { Write-OK "Release: $rwTag  ($rwAsset)" } else { $rwUrl = $RW_RELEASES }

$rwTmp = Join-Path $env:TEMP ("penumbrarw_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $rwTmp -Force | Out-Null
$rwZip = Join-Path $rwTmp "PenumbraVRRework.zip"

# Name AND size must match this release - otherwise an older download
# would install itself without a word.
$rwHave = Find-PredownloadedFile -Patterns @("PenumbraVR-v*.zip") -Label "the Penumbra VR rework" `
              -ExpectedName $rwAsset -ExpectedSize $rwSize
if ($rwHave -and (Test-Path -LiteralPath $rwHave)) {
    $rwZip = $rwHave
    Write-Info "Using the copy you already downloaded."
} else {
    Invoke-SafeDownload -Urls @($rwUrl) -Destination $rwZip -Label "$RW_NAME $rwTag" `
        -ManualUrl $RW_RELEASES `
        -Instructions "Download the PenumbraVR zip from the releases page, save it as '$rwZip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $rwZip)) {
    Write-Fail "No package - the game was not touched."
    try { Remove-Item -LiteralPath $rwTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# Checksum from the release note, if the author put one there.
if ($rwBody -and $rwAsset) {
    $sum = Confirm-ReleaseChecksum -FilePath $rwZip -AssetName $rwAsset -ReleaseBody $rwBody
    if ([string]$sum -eq "mismatch") {
        Write-Fail "The download does not match the checksum in the release note - stopping."
        try { Remove-Item -LiteralPath $rwTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        exit 1
    }
}

$rwUnp = Join-Path $rwTmp "x"
$st = Expand-ArchiveOrFallback -ArchivePath $rwZip -DestinationFolder $rwUnp -Label "$RW_NAME"
if ([string]$st -ne "ok" -and [string]$st -ne "manual") {
    Write-Fail "The package could not be unpacked."
    try { Remove-Item -LiteralPath $rwTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive may or may not carry a wrapper folder, so the root is
# RESOLVED through a file that must be there rather than assumed.
$rwRoot = $rwUnp
$found = Get-ChildItem -LiteralPath $rwUnp -Recurse -Filter $RW_SETUP -ErrorAction SilentlyContinue | Select-Object -First 1
if ($found) { $rwRoot = $found.DirectoryName }
$missing = @()
foreach ($f in $RW_MUST_HAVE) {
    if (-not (Test-Path -LiteralPath (Join-Path $rwRoot $f))) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Fail ("The package is incomplete: " + ($missing -join ", "))
    try { Remove-Item -LiteralPath $rwTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Package verified."

# ---- 3. Hand over to the author's installer -------------------
Write-Step 3 3 "Running the author's installer"
Write-Host ""
Write-Host "  His installer merges the mod into your Steam copy and backs" -ForegroundColor White
Write-Host "  up every file it replaces first." -ForegroundColor White
Write-Host ""
Write-Host "  Your game folder is:" -ForegroundColor White
Write-Host "    $rwGame" -ForegroundColor Cyan
try { Set-Clipboard -Value $rwGame; Write-Host "  (copied to your clipboard)" -ForegroundColor DarkGray } catch {}
Write-Host ""
Pause-User "Press Enter to start it..." | Out-Null

try {
    $proc = Start-Process -FilePath (Join-Path $rwRoot $RW_SETUP) -WorkingDirectory $rwRoot -PassThru -Wait -ErrorAction Stop
    Write-Info "Installer closed (exit code $($proc.ExitCode))."
} catch {
    Write-Fail "Could not start it: $($_.Exception.Message)"
}

# Verify by the RESULT on disk, not by the exit code.
Write-Host ""
$proofExe = "$rwGame\redist\Penumbra_vr.exe"
# The state file the author's installer writes - name read from his
# own script, not guessed: he calls it deploy-state.json.
$proofState = "$rwGame\.penumbravr\deploy-state.json"
if ((Test-Path -LiteralPath $proofExe) -and (Test-Path -LiteralPath $proofState)) {
    Write-OK "Installed and verified: $rwGame"
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $rwGame -Encoding UTF8 -Force } catch {}
    if ($rwTag) { try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $rwTag -Encoding UTF8 -Force } catch {} }
} else {
    Write-Warn "The mod is not in place yet - the installer may have been cancelled."
}
try { Remove-Item -LiteralPath $rwTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-Host "  START STEAMVR FIRST, then launch the game through Steam. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "  Hands: on PS VR2 Sense, Index and Touch every finger follows" -ForegroundColor Gray
Write-Host "  its own curl. Ring and middle share one mesh tube, so their" -ForegroundColor Gray
Write-Host "  tips cannot spread apart, and the thumb stays at its bind" -ForegroundColor Gray
Write-Host "  pose - both are limits of the source model, not faults." -ForegroundColor Gray
Write-Host ""
Write-Host "  Vive wands and the WMR fallback have no per-finger input;" -ForegroundColor Gray
Write-Host "  they get the synthesized closing sequence." -ForegroundColor Gray
Write-Host ""
Write-Host "  The full control map is on this game's page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> The dog is still down there. Now it can see your hands." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
