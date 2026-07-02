# -------------------------------------------------------
#  Installer-Safety helpers
#  Dot-source from any installer:
#      . "$PSScriptRoot\..\Modules\InstallerSafety.ps1"
#  to gain three high-level functions that replace
#  hard 'exit 1' aborts with safe interactive fallbacks.
#
#  All output is ASCII-only and English-only to match the
#  rest of the hub.
# -------------------------------------------------------

# ---- Manual Fallback prompt --------------------------------
#
# Use after every failed download / extract / dependency check
# where the installer would otherwise just give up. Opens an
# info URL in the user's browser, prints a manual instruction,
# then presents [R]etry / [S]kip / [Q]uit choices.
#
# Parameters:
#   -Action     Short description of what just failed
#               (e.g. ".NET 7 Desktop Runtime download")
#   -Url        Page the user can open to do it manually
#   -Instructions  Multi-line guidance for the user
#   -RetryCheck    Scriptblock returning $true if the user fixed
#                  the problem (e.g. { Test-DotNet7Desktop })
#                  - omit to make Retry just rerun the caller
#   -SkipMessage   What happens if user skips (warning text)
#   -AllowSkip     Default $true. Set $false for fatal cases
#                  where the user MUST fix it (still no abort,
#                  but the choices are only Retry/Quit).
#
# Returns one of: "retry" / "skip" / "quit"
# Never returns until the user has made a choice.
#
function global:Invoke-InstallerFallback {
    param(
        [Parameter(Mandatory=$true)][string]$Action,
        [string]$Url           = "",
        [string]$Instructions  = "",
        [scriptblock]$RetryCheck = $null,
        [string]$SkipMessage   = "",
        [bool]$AllowSkip       = $true,
        [string]$SourceFolder  = "",
        [string]$DestFolder    = "",
        # Short noun phrase describing WHAT the automated step was
        # trying to do (e.g. "the PeakVersionBypass ZIP", "BepInEx").
        # Used to generate a clear "What happened?" line. Falls back
        # to $Action when not given so old call sites keep working.
        [string]$Subject       = ""
    )
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Manual step needed: $Action" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow

    # "What happened?" explains the failure in plain language.
    # If the caller didn't give us a Subject we fall back to the
    # Action string so we always say SOMETHING here.
    $subjectText = if ($Subject) { $Subject } else { $Action }
    Write-Host ""
    Write-Host "  What happened?" -ForegroundColor White
    Write-Host "  Unfortunately, the automated download of $subjectText is currently not possible." -ForegroundColor Gray
    if ($Instructions) {
        Write-Host ""
        Write-Host "  Note:" -ForegroundColor White
        # We render Instructions across several lines instead of one
        # long string. Single-quoted segments (file names, full
        # paths) get a line of their own indented to the body's
        # column, because temp paths often exceed the console width
        # and the default console wrap would dump them ugly back to
        # column 0.
        $indent = "  "
        $maxWidth = 78
        try {
            $cw = $Host.UI.RawUI.WindowSize.Width - 2
            if ($cw -gt 40) { $maxWidth = $cw }
        } catch {}
        # Split on quoted segments without losing them
        $parts = [regex]::Split($Instructions, "('[^']*')")
        $line = $indent
        foreach ($p in $parts) {
            if (-not $p) { continue }
            if ($p.StartsWith("'") -and $p.EndsWith("'")) {
                # Quoted segment. Only lift it to its own line when
                # it's actually long enough to wrap on the current
                # console - short names like 'MotherVR.zip' read
                # better inline as part of the sentence.
                $isLong = ($p.Length -gt 40)
                if ($isLong) {
                    if ($line.Trim()) { Write-Host $line -ForegroundColor Gray }
                    Write-Host ($indent + "  " + $p) -ForegroundColor Cyan
                    $line = $indent
                } else {
                    if ($line.Length -eq $indent.Length) {
                        $line += $p
                    } elseif (($line.Length + 1 + $p.Length) -le $maxWidth) {
                        $line += " " + $p
                    } else {
                        Write-Host $line -ForegroundColor Gray
                        $line = $indent + $p
                    }
                }
            } else {
                # Normal prose - word-wrap into the current line
                $words = $p -split '\s+'
                foreach ($w in $words) {
                    if (-not $w) { continue }
                    if ($line.Length -eq $indent.Length) {
                        $line += $w
                    } elseif (($line.Length + 1 + $w.Length) -le $maxWidth) {
                        $line += " " + $w
                    } else {
                        Write-Host $line -ForegroundColor Gray
                        $line = $indent + $w
                    }
                }
            }
        }
        if ($line.Trim()) { Write-Host $line -ForegroundColor Gray }
    }

    # Pre-create destination folder if it doesn't exist yet so the
    # user has somewhere to drop the file.
    if ($DestFolder -and -not (Test-Path $DestFolder)) {
        try { New-Item -ItemType Directory -Path $DestFolder -Force -EA SilentlyContinue | Out-Null } catch { }
    }

    # Show numbered steps so the user knows exactly what to do.
    Write-Host ""
    Write-Host "  What to do:" -ForegroundColor White
    $stepNum = 1
    if ($Url) {
        Write-Host "    $stepNum. Download $subjectText manually (opening now in your browser):" -ForegroundColor Gray
        Write-Host "       $Url" -ForegroundColor Cyan
        try { Start-Process $Url -ErrorAction SilentlyContinue | Out-Null } catch { }
        $stepNum++
    }
    if ($DestFolder -and (Test-Path $DestFolder)) {
        Write-Host "    $stepNum. Put the file in this folder (should be opened now in Explorer):" -ForegroundColor Gray
        Write-Host "       $DestFolder" -ForegroundColor Cyan
        try { Start-Process explorer.exe "`"$DestFolder`"" -EA SilentlyContinue | Out-Null } catch { }
        $clipboardOk = $false
        try {
            Set-Clipboard -Value $DestFolder -ErrorAction Stop
            $clipboardOk = $true
        } catch { }
        if ($clipboardOk) {
            Write-Host "       (Path also copied to clipboard - if Explorer didn't open," -ForegroundColor DarkGray
            Write-Host "        press Win+E, then Ctrl+L, paste, Enter.)" -ForegroundColor DarkGray
        }
        $stepNum++
    }
    if ($SourceFolder) {
        Write-Host "       Source folder (in case you need to copy from here):" -ForegroundColor DarkGray
        Write-Host "       $SourceFolder" -ForegroundColor Cyan
    }
    Write-Host "    $stepNum. Come back here and choose [R]etry." -ForegroundColor Gray

    while ($true) {
        Write-Host ""
        Write-Host "  Choices:" -ForegroundColor White
        Write-Host "    [R]etry  -  I did the manual step, check again" -ForegroundColor Yellow
        if ($AllowSkip) {
            Write-Host "    [S]kip   -  Continue without this step (install may be incomplete)" -ForegroundColor Yellow
        }
        if ($SourceFolder -or $DestFolder) {
            Write-Host "    [O]pen   -  Reopen the folder in Explorer" -ForegroundColor Yellow
        }
        Write-Host "    [Q]uit   -  Stop the installer" -ForegroundColor Yellow
        $c = (Read-Host "  Your choice").Trim().ToLower()
        if ($c -eq "r") {
            if ($RetryCheck) {
                try {
                    if (& $RetryCheck) {
                        Write-Host "  [OK] Detected - continuing." -ForegroundColor Green
                        return "retry"
                    } else {
                        Write-Host "  [!!] Still not detected. Try again or skip." -ForegroundColor Yellow
                        continue
                    }
                } catch {
                    Write-Host "  [!!] Check threw: $($_.Exception.Message)" -ForegroundColor Yellow
                    continue
                }
            } else {
                return "retry"
            }
        }
        if ($c -eq "s" -and $AllowSkip) {
            if ($SkipMessage) {
                Write-Host "  [!!] $SkipMessage" -ForegroundColor Yellow
            }
            return "skip"
        }
        if ($c -eq "o") {
            if ($DestFolder -and (Test-Path $DestFolder)) {
                try { Start-Process explorer.exe "`"$DestFolder`"" -EA SilentlyContinue | Out-Null } catch { }
                try { Set-Clipboard -Value $DestFolder -EA SilentlyContinue } catch { }
                Write-Host "  Path re-copied to clipboard: $DestFolder" -ForegroundColor DarkGray
            }
            if ($SourceFolder -and (Test-Path $SourceFolder)) {
                try { Start-Process explorer.exe "`"$SourceFolder`"" -EA SilentlyContinue | Out-Null } catch { }
            }
            continue
        }
        if ($c -eq "q") {
            return "quit"
        }
        Write-Host "  Please answer R, S, or Q." -ForegroundColor Yellow
    }
}

# ---- Safe Download with multi-URL fallback -----------------
#
# Wraps Invoke-WebRequest. Tries every URL in order until one
# succeeds. If all fail, calls Invoke-InstallerFallback so the
# user gets a manual route instead of a hard abort.
#
# Parameters:
#   -Urls           Array of mirror URLs to try in order
#   -Destination    Full output path
#   -Label          Display name (e.g. ".NET 7 Desktop Runtime")
#   -ManualUrl      Page the user can open if all auto fail
#   -Instructions   Text for the manual fallback prompt
#   -SkipMessage    Warning if user skips
#
# Returns one of: $true (downloaded ok) / "skip" / "quit"
#
# ---- Streaming download with a live progress bar -----------
#
# A raw buffered stream copy that drives Write-Progress itself,
# throttled to ~4 updates/sec, so there is no Invoke-WebRequest-style
# slowdown AND the user sees "<x> MB of <y> MB (z%) - <rate> MB/s"
# plus a taskbar progress (in Windows Terminal). The throttled
# progress and the 128 KB buffered copy add no meaningful overhead -
# throughput is bound by the network, so the MB/s readout makes it
# obvious when a source (e.g. GitHub) is simply slow rather than the
# Hub. Returns $true on a non-empty file, else throws so the caller
# can fall back to the proven Invoke-WebRequest path.
function global:_Invoke-DownloadWithProgress {
    param([string]$Url, [string]$Destination, [string]$Label)
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
    $resp = $null; $inStream = $null; $outStream = $null
    try {
        $req = [System.Net.HttpWebRequest]::Create($Url)
        $req.UserAgent = "PCVR-Mods-Hub"
        $req.AllowAutoRedirect = $true
        $req.Timeout = 30000
        $req.ReadWriteTimeout = 120000
        $resp = $req.GetResponse()
        $total = [int64]$resp.ContentLength
        $totalMB = if ($total -gt 0) { [math]::Round($total / 1MB, 1) } else { 0 }
        $inStream  = $resp.GetResponseStream()
        $outStream = [System.IO.File]::Create($Destination)
        $buffer = New-Object byte[] 131072   # 128 KB
        $sofar  = [int64]0
        $read   = 0
        $startTick = [Environment]::TickCount
        $lastTick  = 0
        while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outStream.Write($buffer, 0, $read)
            $sofar += $read
            $now = [Environment]::TickCount
            if (($now - $lastTick) -ge 250) {
                $lastTick = $now
                $sofarMB = [math]::Round($sofar / 1MB, 1)
                $elapsed = [math]::Max(1, ($now - $startTick)) / 1000.0
                $rate    = [math]::Round(($sofar / 1MB) / $elapsed, 2)   # MB/s
                if ($total -gt 0) {
                    $pct = [int](($sofar * 100) / $total)
                    if ($pct -lt 0) { $pct = 0 } elseif ($pct -gt 100) { $pct = 100 }
                    Write-Progress -Id 1 -Activity "Downloading $Label" -Status "$sofarMB MB of $totalMB MB ($pct%) - $rate MB/s" -PercentComplete $pct
                } else {
                    Write-Progress -Id 1 -Activity "Downloading $Label" -Status "$sofarMB MB downloaded - $rate MB/s"
                }
            }
        }
        Write-Progress -Id 1 -Activity "Downloading $Label" -Completed
        try { $outStream.Close() } catch {}; $outStream = $null
        try { $inStream.Close() }  catch {}; $inStream  = $null
        try { $resp.Close() }      catch {}; $resp      = $null
        return ((Test-Path $Destination) -and ((Get-Item $Destination).Length -gt 0))
    } catch {
        try { Write-Progress -Id 1 -Activity "Downloading $Label" -Completed } catch {}
        throw
    } finally {
        if ($outStream) { try { $outStream.Close() } catch {} }
        if ($inStream)  { try { $inStream.Close() }  catch {} }
        if ($resp)      { try { $resp.Close() }      catch {} }
    }
}

function global:Invoke-SafeDownload {
    param(
        [Parameter(Mandatory=$true)][string[]]$Urls,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][string]$Label,
        [string]$ManualUrl    = "",
        [string]$Instructions = "",
        [string]$SkipMessage  = ""
    )
    # Auto-expand: for every GitHub URL also try a Web Archive mirror
    # of the file. Many "releases" assets are also archived there. This
    # gives us a no-cost auto-fallback when GitHub itself is down or
    # rate-limiting the user's IP.
    $expanded = New-Object System.Collections.Generic.List[string]
    foreach ($u in $Urls) {
        [void]$expanded.Add($u)
        if ($u -match '^https?://github\.com/' -or $u -match '^https?://[^/]+\.githubusercontent\.com/') {
            [void]$expanded.Add("https://web.archive.org/web/0/$u")
        }
    }

    foreach ($u in $expanded) {
        Write-Host "  [..] Downloading $Label" -ForegroundColor Gray
        Write-Host "       From: $u" -ForegroundColor DarkGray
        try {
            # Preferred: streaming copy with a live progress bar + rate.
            if (_Invoke-DownloadWithProgress -Url $u -Destination $Destination -Label $Label) {
                Write-Host "  [OK] Downloaded $Label" -ForegroundColor Green
                return $true
            }
            throw "empty or missing file"
        } catch {
            # Fall back to the proven silent Invoke-WebRequest for this
            # same URL before moving on to the next source. (IWR's own
            # progress is suppressed - it crawls in PS 5.1.)
            try {
                $old = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $u -OutFile $Destination -UseBasicParsing -ErrorAction Stop
                $ProgressPreference = $old
                if ((Test-Path $Destination) -and ((Get-Item $Destination).Length -gt 0)) {
                    Write-Host "  [OK] Downloaded $Label" -ForegroundColor Green
                    return $true
                }
            } catch {
                Write-Host "  [!!] Source failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    # All sources failed - hand off to interactive fallback.
    # Derive the destination FOLDER from the file path so the
    # fallback can auto-open Explorer there and the user can drop
    # the manually-downloaded ZIP straight in.
    $destFolderForFallback = ""
    try { $destFolderForFallback = Split-Path $Destination -Parent } catch { }
    $r = Invoke-InstallerFallback `
            -Action "$Label download" `
            -Subject $Label `
            -Url $ManualUrl `
            -Instructions $Instructions `
            -SkipMessage $SkipMessage `
            -DestFolder $destFolderForFallback
    return $r
}

# ---- Single-URL convenience wrapper ------------------------
#
# A drop-in for code that wants to keep its existing call site
# layout (one URL, try/catch) but get auto-mirror fallback for
# GitHub / common CDNs for free. Returns $true on success,
# "skip"/"quit" via interactive fallback on failure.
#
# Usage:
#   if (-not (Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip -Label "MyMod")) {
#       # user chose Skip or Quit - handle accordingly
#   }
#
function global:Invoke-DownloadOrFallback {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][string]$Label,
        [string]$ManualUrl    = "",
        [string]$Instructions = "",
        [string]$SkipMessage  = ""
    )
    if (-not $ManualUrl) { $ManualUrl = $Url }
    # We deliberately do NOT generate a default Instructions string
    # any more. The fallback prompt already prints "What happened?"
    # and "What to do" with the URL, destination folder and Retry
    # hint. A default Instructions line just duplicates that.
    if (-not $SkipMessage) {
        $SkipMessage = "Skipped - '$Label' was not downloaded; downstream steps may fail."
    }
    return (Invoke-SafeDownload -Urls @($Url) -Destination $Destination -Label $Label `
                -ManualUrl $ManualUrl -Instructions $Instructions -SkipMessage $SkipMessage)
}

# ---- Safe archive extraction --------------------------------
#
# Replaces raw Expand-Archive / 7z calls. Tries 7z.exe first if
# available (works for .zip, .7z, .rar), then PowerShell's
# Expand-Archive (zip only), then drops to interactive fallback
# that auto-opens the source folder in Explorer for manual
# extraction. Never aborts.
#
# Returns:
#   "ok"     - archive extracted successfully
#   "manual" - user extracted it themselves (Retry) - caller should
#              re-verify the expected output exists
#   "skip"   - user chose Skip - downstream steps will be incomplete
#   "quit"   - user chose Quit - caller should clean exit
#
function global:Expand-ArchiveOrFallback {
    param(
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [Parameter(Mandatory=$true)][string]$DestinationFolder,
        [string]$Label = "archive",
        [string]$SkipMessage = "",
        [bool]$AllowSkip = $true
    )
    if (-not (Test-Path $ArchivePath)) {
        Write-Host "  [!!] Archive not found at $ArchivePath" -ForegroundColor Yellow
        $r = Invoke-InstallerFallback `
                -Action "$Label extraction" `
                -Instructions "The archive '$ArchivePath' was not found. Place it there manually, then choose Retry. Or choose Skip to continue without it." `
                -SkipMessage $(if ($SkipMessage) { $SkipMessage } else { "Skipped - $Label was not extracted; downstream steps may fail (questionable result)." }) `
                -SourceFolder (Split-Path "$ArchivePath" -Parent) `
                -DestFolder $DestinationFolder `
                -AllowSkip $AllowSkip
        return $r
    }
    if (-not (Test-Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    }

    # Try 7z.exe first (handles .zip, .7z, .rar, .tar.gz, etc.)
    $sevenZip = $null
    foreach ($c in @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
    )) { if (Test-Path $c) { $sevenZip = $c; break } }
    if (-not $sevenZip) {
        try {
            $cmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue
            if ($cmd) { $sevenZip = $cmd.Source }
        } catch { }
    }
    if ($sevenZip) {
        Write-Host "  [..] Extracting $Label with 7-Zip..." -ForegroundColor Gray
        try {
            $p = Start-Process -FilePath $sevenZip `
                    -ArgumentList "x","-y","-bso0","-bsp0","`"$ArchivePath`"","-o`"$DestinationFolder`"" `
                    -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0) {
                Write-Host "  [OK] Extracted: $Label" -ForegroundColor Green
                return "ok"
            }
            Write-Host "  [!!] 7-Zip extract exited with code $($p.ExitCode)" -ForegroundColor Yellow
        } catch {
            Write-Host "  [!!] 7-Zip extract failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Fall back to PowerShell's Expand-Archive (zip only)
    if ($ArchivePath -match '\.zip$') {
        Write-Host "  [..] Extracting $Label with Expand-Archive..." -ForegroundColor Gray
        try {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationFolder -Force -ErrorAction Stop
            Write-Host "  [OK] Extracted: $Label" -ForegroundColor Green
            return "ok"
        } catch {
            Write-Host "  [!!] Expand-Archive failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Both auto-paths failed - hand off to user
    $r = Invoke-InstallerFallback `
            -Action "$Label extraction" `
            -Instructions "Both 7-Zip and Expand-Archive failed (or were unavailable) to extract '$ArchivePath'. Open it manually with your archive tool and extract its contents into '$DestinationFolder'. Then choose Retry." `
            -SkipMessage $(if ($SkipMessage) { $SkipMessage } else { "Skipped - $Label was not extracted; downstream steps may fail (questionable result)." }) `
            -SourceFolder (Split-Path "$ArchivePath" -Parent) `
            -DestFolder $DestinationFolder `
            -AllowSkip $AllowSkip
    return $r
}

# ---- 7-Zip detection + auto-install -----------------------
#
# Centralised 7-Zip resolver. Returns the path to a usable 7z.exe
# (either already installed or freshly downloaded), or $null if
# the user skipped / quit the fallback prompt.
#
# Behaviour:
#   1. Probe the standard install paths.
#   2. Probe PATH for 7z.exe.
#   3. If still missing, ASK the user (default Yes) to auto-download
#      and silently install 7-Zip from 7-zip.org. UAC prompt may
#      appear during install.
#   4. If the auto-install fails or the user declines, fall through
#      to Invoke-InstallerFallback with the manual download page
#      auto-opened in the browser.
#
# Replace every per-installer "check 7-Zip then exit if missing"
# block with a single call:
#
#   $sevenZip = Get-SevenZip
#   if (-not $sevenZip) { return }   # user chose Skip or Quit
#
function global:Get-SevenZip {
    param(
        [switch]$Required = $false   # if set, [S]kip is hidden
    )
    # Standard install probes
    $candidates = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe",
        "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    try {
        $found = Get-Command "7z.exe" -ErrorAction SilentlyContinue
        if ($found) { return $found.Source }
    } catch { }

    # Not found - offer to auto-install
    Write-Host ""
    Write-Host "  7-Zip is needed to extract this mod's archive (.7z or .zip)." -ForegroundColor Yellow
    Write-Host "  Download and install 7-Zip silently now? (~1.6 MB)" -ForegroundColor White
    Write-Host "    [Y]es (recommended)   [N]o, I'll handle it" -ForegroundColor Gray
    $ans = (Read-Host "  Your choice (Y/N)").Trim().ToLower()
    if ($ans -in @("y","yes","")) {
        # Multiple stable sources. Since v24.09 the official 7-zip.org
        # download links are 302-redirects to github.com/ip7z/7zip/releases.
        # Both URLs work today but the GitHub release URLs are more
        # resilient against future website restructures. Older 7-zip.org
        # version URLs are archived indefinitely on their /a/ path.
        $sevenZipSources = @(
            @{ Url = "https://github.com/ip7z/7zip/releases/download/24.09/7z2409-x64.exe";
               Label = "7-Zip 24.09 (GitHub mirror)" }
            @{ Url = "https://www.7-zip.org/a/7z2409-x64.exe";
               Label = "7-Zip 24.09 (7-zip.org)" }
        )
        $tmpInst = Join-Path $env:TEMP "7z-installer.exe"
        $ok = $false
        foreach ($src in $sevenZipSources) {
            Write-Host "  [..] Downloading $($src.Label)..." -ForegroundColor Gray
            Write-Host "       From: $($src.Url)" -ForegroundColor DarkGray
            try {
                $old = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $src.Url -OutFile $tmpInst -UseBasicParsing -ErrorAction Stop
                $ProgressPreference = $old
                if ((Test-Path $tmpInst) -and ((Get-Item $tmpInst).Length -gt 100000)) {
                    $ok = $true
                    break
                }
            } catch {
                Write-Host "  [!!] Source failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        if ($ok) {
            Write-Host "  [..] Running silent install (UAC prompt may appear)..." -ForegroundColor Gray
            try {
                Start-Process -FilePath $tmpInst -ArgumentList "/S" -Wait
                Remove-Item $tmpInst -Force -ErrorAction SilentlyContinue
                foreach ($c in $candidates) {
                    if (Test-Path $c) {
                        Write-Host "  [OK] 7-Zip installed at: $c" -ForegroundColor Green
                        return $c
                    }
                }
                Write-Host "  [!!] 7-Zip install ran but 7z.exe is still not detected." -ForegroundColor Yellow
            } catch {
                Write-Host "  [!!] 7-Zip installer threw: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    # Fall through to interactive fallback - user must handle manually
    $r = Invoke-InstallerFallback `
            -Action "7-Zip detection" `
            -Url "https://github.com/ip7z/7zip/releases" `
            -Instructions "Install 7-Zip from the page that just opened in your browser (it is free, MIT-license). The 'x64.exe' installer is what you want. After installing, choose Retry." `
            -SkipMessage "Skipped - the mod archive cannot be extracted (questionable result)." `
            -RetryCheck {
                foreach ($c in @("C:\Program Files\7-Zip\7z.exe","C:\Program Files (x86)\7-Zip\7z.exe","$env:LOCALAPPDATA\Programs\7-Zip\7z.exe")) {
                    if (Test-Path $c) { return $true }
                }
                try { if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) { return $true } } catch { }
                return $false
            } `
            -AllowSkip (-not $Required)
    if ([string]$r -eq "retry") {
        # Re-detect after user fixed it
        foreach ($c in $candidates) {
            if (Test-Path $c) { return $c }
        }
        try {
            $found = Get-Command "7z.exe" -ErrorAction SilentlyContinue
            if ($found) { return $found.Source }
        } catch { }
    }
    return $null
}

# ---- Safe path prompt --------------------------------------
#
# When the auto-detection for a game's install folder fails,
# instead of aborting, ask the user to paste a path.
#
# Parameters:
#   -GameName       For the prompt text
#   -ProbeFile      Optional path inside the folder to verify
#                   (e.g. "AnotherCrabsTreasure.exe")
#   -ManualUrl      Where to look up the correct path
#
# Returns:
#   - The validated path string, OR
#   - "quit"  if the user gave up
#   - "skip"  if no path could be verified after several tries
#
# ---- Canonical Steam/GOG/Epic game-folder finder ------------
#
# Authoritative, shared replacement for the per-installer Steam
# finders. Locates an installed game's folder the way Steam itself
# does - by AppId -> appmanifest installdir - so it does NOT depend
# on a guessed folder name or a specific exe being present (the Hub
# also detects by folder, not exe). Falls back to name-based lookup
# across Steam libraries, every GOG root, and every Epic root.
#
# Params:
#   -AppId             Steam AppId (enables the authoritative path)
#   -SteamFolderNames  steamapps\common folder name(s) to try by name
#   -Subdir            optional subfolder that holds the exe (e.g. "sr5")
#   -ProbeExe          optional exe to PREFER (never strictly required)
#   -GogNames          GOG folder name(s) (resolved vs every GOG root)
#   -EpicNames         Epic folder name(s) (resolved vs every Epic root)
#
# Returns: the folder that holds the game (or its Subdir), else $null.
#
function global:Find-SteamGameFolder {
    param(
        [string]$AppId = "",
        [string[]]$SteamFolderNames = @(),
        [string]$Subdir = "",
        [string]$ProbeExe = "",
        [string[]]$GogNames = @(),
        [string[]]$EpicNames = @()
    )

    # Steam roots: registry (HKLM InstallPath / HKCU SteamPath) PLUS
    # default install paths, so detection survives a failed registry read.
    $steamRoots = @()
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam")) {
        try { $rp = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($rp) { $steamRoots += $rp } } catch {}
    }
    try { $rp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Valve\Steam" -ErrorAction Stop).SteamPath; if ($rp) { $steamRoots += ($rp -replace '/','\') } } catch {}
    foreach ($d in @(
        "${env:ProgramFiles(x86)}\Steam", "${env:ProgramFiles}\Steam",
        "C:\Program Files (x86)\Steam", "C:\Program Files\Steam",
        "C:\Steam", "D:\Steam", "E:\Steam", "D:\SteamLibrary", "E:\SteamLibrary"
    )) { if ($d) { $steamRoots += $d } }

    $libs = @()
    foreach ($root in ($steamRoots | Select-Object -Unique)) {
        if (-not (Test-Path $root)) { continue }
        $libs += $root
        $vdf = Join-Path $root "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            try {
                foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                    $lp = $m.Groups[1].Value -replace '\\\\', '\'
                    if (Test-Path $lp) { $libs += $lp }
                }
            } catch {}
        }
    }
    $libs = $libs | Select-Object -Unique

    # PRIMARY: Steam appmanifest for this AppId -> real installdir.
    if ($AppId) {
        foreach ($lib in $libs) {
            $acf = Join-Path $lib "steamapps\appmanifest_$AppId.acf"
            if (Test-Path $acf) {
                try {
                    $mm = [regex]::Match((Get-Content $acf -Raw), '"installdir"\s+"([^"]+)"')
                    if ($mm.Success) {
                        $g = Join-Path $lib "steamapps\common\$($mm.Groups[1].Value)"
                        if ($Subdir) { $g = Join-Path $g $Subdir }
                        if (Test-Path $g) { return $g }
                    }
                } catch {}
            }
        }
    }

    # GOG: read each installed game's REAL path from the registry
    # (HKLM\SOFTWARE\GOG.com\Games\<id>\path). Authoritative location -
    # works no matter which drive/folder GOG installed to. We accept a
    # game whose folder name matches, or that contains the probe exe.
    if ($GogNames.Count) {
        foreach ($base in @("HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games","HKLM:\SOFTWARE\GOG.com\Games")) {
            if (-not (Test-Path $base)) { continue }
            foreach ($key in (Get-ChildItem -Path $base -ErrorAction SilentlyContinue)) {
                try {
                    $props = Get-ItemProperty -Path $key.PSPath -ErrorAction Stop
                    $gp = $props.path
                    if (-not $gp -or -not (Test-Path $gp)) { continue }
                    $leaf = Split-Path -Leaf $gp
                    $g = if ($Subdir) { Join-Path $gp $Subdir } else { $gp }
                    $isMatch = $false
                    foreach ($n in $GogNames) { if (($leaf -ieq $n) -or ($props.gameName -ieq $n)) { $isMatch = $true; break } }
                    if (-not $isMatch -and $ProbeExe -and (Test-Path (Join-Path $g $ProbeExe))) { $isMatch = $true }
                    if ($isMatch -and (Test-Path $g)) { return $g }
                } catch {}
            }
        }
    }

    # Epic: read each installed game's REAL path from the launcher
    # manifests (%ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item,
    # JSON with InstallLocation). Authoritative; match by folder name.
    if ($EpicNames.Count) {
        $mfDir = Join-Path $env:ProgramData "Epic\EpicGamesLauncher\Data\Manifests"
        if (Test-Path $mfDir) {
            foreach ($item in (Get-ChildItem -Path $mfDir -Filter *.item -ErrorAction SilentlyContinue)) {
                try {
                    $j = Get-Content $item.FullName -Raw | ConvertFrom-Json
                    $loc = $j.InstallLocation
                    if (-not $loc -or -not (Test-Path $loc)) { continue }
                    $leaf = Split-Path -Leaf $loc
                    $g = if ($Subdir) { Join-Path $loc $Subdir } else { $loc }
                    $isMatch = $false
                    foreach ($n in $EpicNames) { if (($leaf -ieq $n) -or ($j.MandatoryAppFolderName -ieq $n)) { $isMatch = $true; break } }
                    if (-not $isMatch -and $ProbeExe -and (Test-Path (Join-Path $g $ProbeExe))) { $isMatch = $true }
                    if ($isMatch -and (Test-Path $g)) { return $g }
                } catch {}
            }
        }
    }

    # SECONDARY: name-based candidates across Steam / GOG / Epic.
    $cands = @()
    foreach ($n in $SteamFolderNames) {
        foreach ($lib in $libs) {
            $c = Join-Path $lib "steamapps\common\$n"
            if ($Subdir) { $c = Join-Path $c $Subdir }
            $cands += $c
        }
    }
    if ($GogNames.Count) {
        foreach ($root in @(
            "C:\Program Files (x86)\GOG Galaxy\Games", "C:\Program Files\GOG Galaxy\Games",
            "${env:ProgramFiles(x86)}\GOG Galaxy\Games", "${env:ProgramFiles}\GOG Galaxy\Games",
            "C:\GOG Games", "D:\GOG Games", "E:\GOG Games",
            "D:\Program Files (x86)\GOG Galaxy\Games", "E:\Program Files (x86)\GOG Galaxy\Games"
        )) {
            if ($root) { foreach ($n in $GogNames) { $c = Join-Path $root $n; if ($Subdir) { $c = Join-Path $c $Subdir }; $cands += $c } }
        }
    }
    if ($EpicNames.Count) {
        foreach ($root in @(
            "${env:ProgramFiles}\Epic Games", "${env:ProgramFiles(x86)}\Epic Games",
            "C:\Program Files\Epic Games", "C:\Epic Games", "D:\Epic Games", "E:\Epic Games",
            "D:\Program Files\Epic Games", "E:\Program Files\Epic Games"
        )) {
            if ($root) { foreach ($n in $EpicNames) { $c = Join-Path $root $n; if ($Subdir) { $c = Join-Path $c $Subdir }; $cands += $c } }
        }
    }
    $cands = $cands | Select-Object -Unique

    # Prefer a folder that holds the exe, then accept a folder that exists.
    if ($ProbeExe) {
        foreach ($c in $cands) { if ($c -and (Test-Path $c) -and (Test-Path (Join-Path $c $ProbeExe))) { return $c } }
    }
    foreach ($c in $cands) { if ($c -and (Test-Path $c)) { return $c } }
    return $null
}

function global:Get-GameFolderInteractive {
    param(
        [Parameter(Mandatory=$true)][string]$GameName,
        [string]$ProbeFile = "",
        [string]$ManualUrl = ""
    )
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "  Couldn't auto-detect the install folder for:" -ForegroundColor Yellow
    Write-Host "    $GameName" -ForegroundColor White
    Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  You can paste the path manually (the folder where the" -ForegroundColor White
    Write-Host "  game's .exe lives). Examples:" -ForegroundColor White
    Write-Host "    C:\Program Files (x86)\Steam\steamapps\common\$GameName" -ForegroundColor DarkGray
    Write-Host "    D:\Games\$GameName" -ForegroundColor DarkGray
    if ($ManualUrl) {
        Write-Host ""
        Write-Host "  Help finding it:  $ManualUrl" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "  Or type [Q] to quit without changes, [S] to skip this step." -ForegroundColor Yellow

    for ($i = 1; $i -le 5; $i++) {
        Write-Host ""
        $p = (Read-Host "  Path (attempt $i/5)").Trim('"').Trim()
        if ($p -in @("q","Q","quit","exit")) { return "quit" }
        if ($p -in @("s","S","skip"))        { return "skip" }
        if (-not $p) {
            Write-Host "  Empty input - try again or [Q]uit." -ForegroundColor Yellow
            continue
        }
        if (-not (Test-Path $p)) {
            Write-Host "  Path does not exist - try again." -ForegroundColor Yellow
            continue
        }
        if ($ProbeFile) {
            $probe = Join-Path $p $ProbeFile
            if (-not (Test-Path $probe)) {
                Write-Host "  Path exists but doesn't contain $ProbeFile." -ForegroundColor Yellow
                Write-Host "  Is this really the install folder?" -ForegroundColor Yellow
                $ok = (Read-Host "  [Y]es accept anyway / [N]o try again").Trim().ToLower()
                if ($ok -ne "y") { continue }
            }
        }
        return $p
    }
    Write-Host "  Too many invalid attempts - skipping this step." -ForegroundColor Yellow
    return "skip"
}

# ---- Depot path resolver -----------------------------------
#
# When a depot installer auto-detects the depot folder Steam
# downloaded for us, great. When it doesn't (path moved, dl
# unfinished, user closed Steam too early), this gives a clear
# two-option menu:
#
#   1) Open Steam Console and re-run the download_depot command
#      (command is copied to clipboard; explicit paste steps
#      shown in case Steam can't open automatically, e.g. on a
#      virtual desktop or sandboxed shell).
#   2) Paste the depot path manually.
#
# Empty input at the menu, or three failed manual-path attempts,
# loops back to the menu. Pressing Enter at the top menu cleanly
# ends the installer.
#
# Returns: validated absolute path, or $null on quit.
#
function global:Resolve-DepotPath {
    param(
        [Parameter(Mandatory=$true)][string]$GameName,
        [Parameter(Mandatory=$true)][string]$DepotCommand,
        [string]$GameExe = "",
        [string[]]$ProbePaths = @(),
        # Optional - enables the automated DepotDownloader fallback.
        [string]$AppId = "",
        [string]$DepotId = "",
        [string]$Manifest = "",
        [string]$Branch = "",
        [string]$ParentDir = ""
    )

    $consoleFailCount = 0
    $ddAvailable = ($AppId -and $DepotId -and $Manifest)

    while ($true) {
        # Re-probe expected paths every loop iteration: the user
        # may have just finished the download via option 1.
        foreach ($probe in $ProbePaths) {
            if ($probe -and (Test-Path $probe)) {
                $probeOk = $true
                if ($GameExe) {
                    $probeOk = [bool](Test-Path (Join-Path $probe $GameExe))
                    if (-not $probeOk) {
                        $probeOk = [bool](Get-ChildItem -Path $probe -Recurse -Filter $GameExe -ErrorAction SilentlyContinue | Select-Object -First 1)
                    }
                }
                if ($probeOk) {
                    Write-Host "  [OK] Depot folder found: $probe" -ForegroundColor Green
                    return $probe
                }
            }
        }

        # After two failed Steam Console attempts, automatically try
        # the DepotDownloader fallback (if depot params were provided).
        if ($ddAvailable -and $consoleFailCount -ge 2) {
            Write-Host ""
            Write-Host "  Steam Console did not succeed twice - switching to" -ForegroundColor Yellow
            Write-Host "  the DepotDownloader fallback automatically." -ForegroundColor Yellow
            $ddResult = Invoke-DepotDownloaderFallback -GameName $GameName -AppId $AppId `
                -DepotId $DepotId -Manifest $Manifest -Branch $Branch -GameExe $GameExe -ParentDir $ParentDir
            if ($ddResult) { return $ddResult }
            # Reset so the user can keep trying the console route too.
            $consoleFailCount = 0
        }

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host "  Depot folder for $GameName not found." -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  How would you like to continue?" -ForegroundColor White
        Write-Host ""
        Write-Host "    [1] Open Steam Console and re-run the depot download" -ForegroundColor Yellow
        Write-Host "    [2] Enter the depot folder path manually" -ForegroundColor Yellow
        if ($ddAvailable) {
            Write-Host "    [3] Use the DepotDownloader fallback (logs into Steam)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "  Press Enter (without typing anything) to quit the installer." -ForegroundColor DarkGray

        $choice = (Read-Host "  Your choice").Trim()
        if (-not $choice) { return $null }
        if ($choice -eq "q" -or $choice -eq "Q") { return $null }

        if ($choice -eq "1") {
            $clipOk = $false
            try { Set-Clipboard -Value $DepotCommand -ErrorAction Stop; $clipOk = $true } catch {}

            Write-Host ""
            Write-Host "  Steam Console will open in your browser." -ForegroundColor White
            if ($clipOk) {
                Write-Host "  The download command has been copied to your clipboard:" -ForegroundColor Gray
            } else {
                Write-Host "  (Couldn't copy to clipboard - copy the command shown below.)" -ForegroundColor Gray
            }
            Write-Host "    $DepotCommand" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  If Steam Console doesn't open automatically:" -ForegroundColor Gray
            Write-Host "    1. Make sure the Steam client is running and you're logged in." -ForegroundColor Gray
            Write-Host "    2. Open this URL in any browser:  steam://nav/console" -ForegroundColor Gray
            Write-Host "       (or paste it into the Run dialog: Win+R, paste, Enter)" -ForegroundColor Gray
            Write-Host "    3. Click into the Steam Console input field." -ForegroundColor Gray
            Write-Host "    4. Paste with Ctrl+V and press Enter." -ForegroundColor Gray
            Write-Host "    5. Wait for 'Depot download complete' before continuing." -ForegroundColor Gray
            Write-Host ""
            try { Start-Process "steam://nav/console" -ErrorAction SilentlyContinue | Out-Null } catch {}

            Write-Host "  When the download is COMPLETE, press Enter." -ForegroundColor White
            Write-Host "  If there was a PROBLEM (download did not finish), type I and press Enter." -ForegroundColor White
            $done = (Read-Host "  [Enter] = done   /   [I] = problem").Trim()
            if ($done -eq "i" -or $done -eq "I") {
                $consoleFailCount++
                Write-Host "  [!!] Steam Console attempt marked as failed ($consoleFailCount)." -ForegroundColor Yellow
            }
            continue
        }

        if ($choice -eq "2") {
            $attempts = 0
            while ($attempts -lt 3) {
                $attempts++
                Write-Host ""
                Write-Host "  Paste the full depot folder path (the absolute folder" -ForegroundColor White
                Write-Host "  Steam printed when the download completed)." -ForegroundColor White
                Write-Host "  Press Enter on its own to go back to the menu." -ForegroundColor DarkGray
                $raw = (Read-Host "  Depot path").Trim().Trim('"')
                if (-not $raw) { break }
                if (-not (Test-Path $raw)) {
                    Write-Host "  [XX] Path not found: $raw" -ForegroundColor Red
                    continue
                }
                if ($GameExe) {
                    $probe = Join-Path $raw $GameExe
                    if (-not (Test-Path $probe)) {
                        Write-Host "  [!!] Path exists but '$GameExe' is not inside it." -ForegroundColor Yellow
                        $ok = (Read-Host "  Accept anyway? [Y/N]").Trim().ToLower()
                        if ($ok -ne "y") { continue }
                    }
                }
                Write-Host "  [OK] Depot folder set: $raw" -ForegroundColor Green
                return $raw
            }
            continue
        }

        if ($choice -eq "3" -and $ddAvailable) {
            $ddResult = Invoke-DepotDownloaderFallback -GameName $GameName -AppId $AppId `
                -DepotId $DepotId -Manifest $Manifest -Branch $Branch -GameExe $GameExe -ParentDir $ParentDir
            if ($ddResult) { return $ddResult }
            continue
        }

        Write-Host "  Please enter a valid option (or press Enter to quit)." -ForegroundColor Yellow
    }
}

# ============================================================
#  DepotDownloader fallback helpers
#  Used when the Steam Console download_depot route fails.
#  DepotDownloader is cached in Core/Assets/Tools so it only
#  downloads once and becomes a permanent, reusable fallback.
# ============================================================

# Known-good pinned version, used as a safe anchor if the
# "latest" lookup from GitHub fails for any reason.
$global:DD_FALLBACK_VERSION = "3.4.0"

function global:Get-DepotDownloader {
    # Returns the full path to a ready-to-use DepotDownloader.exe,
    # or $null if it could not be obtained. Caches the tool under
    # Core/Assets/Tools/DepotDownloader so later fallbacks reuse it.
    #
    # Order of operations:
    #   1. If a cached DepotDownloader.exe already exists -> use it.
    #   2. Otherwise query GitHub for the latest release; fall back
    #      to the pinned version if that lookup fails.
    #   3. Download + extract into the cache folder.
    #   4. Verify DepotDownloader.exe is present and return its path.

    # Stable cache dir INSIDE the hub, CONSTANT across Hub restarts.
    # $global:scriptDir is the Core folder, set by VRModHub.ps1 exactly
    # for cache helpers like this one. $PSScriptRoot is unreliable at
    # runtime inside a dot-sourced global function (it changed between
    # runs, which moved the cache and forced a re-download every restart).
    # Prefer $global:scriptDir, fall back to $PSScriptRoot\.. then TEMP.
    $cacheRoot = $null
    if ($global:scriptDir) {
        $cacheRoot = Join-Path ([string]$global:scriptDir) "Assets\Tools\DepotDownloader"
    } elseif ($PSScriptRoot) {
        $cacheRoot = Join-Path $PSScriptRoot "..\Assets\Tools\DepotDownloader"
    }
    if ($cacheRoot) {
        try { $cacheRoot = [System.IO.Path]::GetFullPath($cacheRoot) } catch {}
    }
    if (-not $cacheRoot) {
        $cacheRoot = Join-Path $env:TEMP "PCVRModsHub_DepotDownloader"
    }
    $cachedExe = Join-Path $cacheRoot "DepotDownloader.exe"

    # 1) Reuse a cached copy if present.
    if (Test-Path $cachedExe) {
        Write-Host "  [OK] Using cached DepotDownloader: $cachedExe" -ForegroundColor Green
        return $cachedExe
    }

    # Make sure the cache folder exists.
    try {
        if (-not (Test-Path $cacheRoot)) {
            New-Item -ItemType Directory -Path $cacheRoot -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        Write-Host "  [!!] Could not create the DepotDownloader cache folder: $_" -ForegroundColor Yellow
        # Fall back to a temp folder so the download can still proceed.
        $cacheRoot = Join-Path $env:TEMP "DepotDownloaderCache_$([System.IO.Path]::GetRandomFileName())"
        try { New-Item -ItemType Directory -Path $cacheRoot -Force -ErrorAction Stop | Out-Null }
        catch { Write-Fail "Could not create any folder for DepotDownloader: $_"; return $null }
        $cachedExe = Join-Path $cacheRoot "DepotDownloader.exe"
    }

    # 2) Determine the download URL: latest from GitHub, else pinned.
    $assetName = "DepotDownloader-windows-x64.zip"
    $ddUrl = $null
    $ddVersionLabel = "latest"
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/SteamRE/DepotDownloader/releases/latest" `
            -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -ErrorAction Stop
        $asset = $rel.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
        if ($asset -and $asset.browser_download_url) {
            $ddUrl = $asset.browser_download_url
            $ddVersionLabel = "$($rel.tag_name)"
        }
    } catch {
        Write-Host "  [!!] Could not query GitHub for the latest DepotDownloader - using pinned $global:DD_FALLBACK_VERSION." -ForegroundColor Yellow
    }
    if (-not $ddUrl) {
        $v = $global:DD_FALLBACK_VERSION
        $ddUrl = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_$v/$assetName"
        $ddVersionLabel = $v
    }

    # 3) Download + extract into the cache folder. Use a no-space
    #    temp zip path so no external tool ever sees a split arg.
    $tmpZip = Join-Path $cacheRoot "dd_download.zip"
    Write-Host "  Downloading DepotDownloader ($ddVersionLabel) ..." -ForegroundColor White
    try {
        Invoke-WebRequest -Uri $ddUrl -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "  [!!] Latest DepotDownloader download failed: $_" -ForegroundColor Yellow
        # Retry once with the pinned version if we were trying latest.
        if ($ddVersionLabel -ne $global:DD_FALLBACK_VERSION) {
            $v = $global:DD_FALLBACK_VERSION
            $ddUrl = "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_$v/$assetName"
            Write-Host "  Retrying with pinned DepotDownloader $v ..." -ForegroundColor White
            try { Invoke-WebRequest -Uri $ddUrl -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop }
            catch { Write-Fail "DepotDownloader could not be downloaded: $_"; return $null }
        } else {
            Write-Host "  [XX] DepotDownloader could not be downloaded: $_" -ForegroundColor Red
            return $null
        }
    }

    try {
        Expand-Archive -Path $tmpZip -DestinationPath $cacheRoot -Force -ErrorAction Stop
    } catch {
        Write-Host "  [XX] Could not extract DepotDownloader: $_" -ForegroundColor Red
        return $null
    }
    try { Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue } catch {}

    # 4) Verify.
    if (Test-Path $cachedExe) {
        Write-Host "  [OK] DepotDownloader ready (cached for future use): $cachedExe" -ForegroundColor Green
        return $cachedExe
    }
    Write-Host "  [XX] DepotDownloader.exe not found after extraction." -ForegroundColor Red
    return $null
}

function global:Invoke-DepotDownloaderFallback {
    # Automated DepotDownloader run, mirroring the Outward installer:
    #   - obtains a cached/fresh DepotDownloader.exe
    #   - asks for the Steam username (password/Guard go into DD's own window)
    #   - downloads into a NO-SPACE folder (avoids the arg-split bug)
    #   - verifies the game exe arrived; does near-folder recovery
    # Returns the folder containing the downloaded depot, or $null.
    param(
        [Parameter(Mandatory=$true)][string]$GameName,
        [Parameter(Mandatory=$true)][string]$AppId,
        [Parameter(Mandatory=$true)][string]$DepotId,
        [Parameter(Mandatory=$true)][string]$Manifest,
        [string]$Branch = "",
        [string]$GameExe = "",
        [string]$ParentDir = ""
    )

    $ddExe = Get-DepotDownloader
    if (-not $ddExe) {
        Write-Host "  [!!] DepotDownloader is not available - cannot use this fallback." -ForegroundColor Yellow
        return $null
    }

    Write-Host ""
    Write-Host "  DepotDownloader fallback for $GameName" -ForegroundColor Cyan
    Write-Host "  It logs into your Steam account just long enough to download," -ForegroundColor Gray
    Write-Host "  the same way the Steam client does. Password and Steam Guard" -ForegroundColor Gray
    Write-Host "  code go directly into DepotDownloader's own window." -ForegroundColor Gray
    Write-Host ""

    $steamUser = (Read-Host "  Steam username (the account that owns $GameName)").Trim()
    if (-not $steamUser) {
        Write-Host "  [!!] No username entered - skipping the DepotDownloader fallback." -ForegroundColor Yellow
        return $null
    }

    # No-space staging folder INSIDE the hub (rule: nothing outside
    # hub/game). The depot is moved into the game folder afterward.
    if (-not $ParentDir) {
        if ($global:scriptDir) { $ParentDir = Join-Path ([string]$global:scriptDir) "Assets\Tools" }
        else { $ParentDir = $env:TEMP }
    }
    try {
        if (-not (Test-Path $ParentDir)) { New-Item -ItemType Directory -Path $ParentDir -Force -ErrorAction Stop | Out-Null }
    } catch {
        Write-Host "  [!!] Could not use '$ParentDir' - falling back to TEMP." -ForegroundColor Yellow
        $ParentDir = $env:TEMP
    }
    $downloadPath = Join-Path $ParentDir "DepotDL_$AppId"
    if (Test-Path $downloadPath) {
        try { Remove-Item $downloadPath -Recurse -Force -ErrorAction Stop } catch {}
    }
    try { New-Item -ItemType Directory -Path $downloadPath -Force -ErrorAction Stop | Out-Null }
    catch { Write-Fail "Could not create the download folder: $_"; return $null }

    # Build args. -dir uses the no-space $downloadPath, passed as a
    # single -FilePath/-ArgumentList element (DD via Start-Process).
    $ddArgs = @("-app", $AppId, "-depot", $DepotId, "-manifest", $Manifest)
    if ($Branch) { $ddArgs += @("-branch", $Branch) }
    $ddArgs += @("-username", $steamUser, "-dir", $downloadPath)

    Write-Host ""
    Write-Host "  Starting DepotDownloader..." -ForegroundColor White
    Write-Host "  -> It will prompt for your password (and Steam Guard) in its own window." -ForegroundColor Gray
    Write-Host "  -> Failed chunks are retried automatically; let it finish." -ForegroundColor Gray
    Write-Host ""
    Pause-User "Press Enter to launch DepotDownloader..." | Out-Null

    try {
        $ddProc = Start-Process -FilePath $ddExe -ArgumentList $ddArgs -Wait -PassThru -ErrorAction Stop
    } catch {
        Write-Host "  [!!] Could not start DepotDownloader: $_" -ForegroundColor Yellow
        return $null
    }
    if ($ddProc.ExitCode -ne 0) {
        Write-Host "  [!!] DepotDownloader exited with code $($ddProc.ExitCode)." -ForegroundColor Yellow
        Write-Host "  Make sure you own $GameName, close Steam, and try again." -ForegroundColor Gray
    }

    # Verify + near-folder recovery (same idea as Outward).
    $found = $null
    if ($GameExe) {
        if (Test-Path (Join-Path $downloadPath $GameExe)) { $found = $downloadPath }
        if (-not $found) {
            # Scan immediate subfolders of the download folder.
            try {
                $sub = Get-ChildItem -Path $downloadPath -Directory -ErrorAction Stop | Where-Object { Test-Path (Join-Path $_.FullName $GameExe) } | Select-Object -First 1
                if ($sub) { $found = $sub.FullName }
            } catch {}
        }
        if (-not $found) {
            # Scan the parent dir for any sibling containing the exe.
            try {
                $sib = Get-ChildItem -Path $ParentDir -Directory -ErrorAction Stop | Where-Object { Test-Path (Join-Path $_.FullName $GameExe) } | Select-Object -First 1
                if ($sib) { $found = $sib.FullName }
            } catch {}
        }
    } else {
        # No exe to probe - accept the download folder if it has content.
        try { if ((Get-ChildItem -Path $downloadPath -Force -ErrorAction Stop | Measure-Object).Count -gt 0) { $found = $downloadPath } } catch {}
    }

    if ($found) {
        $found = [string]$found
        Write-Host "  [OK] DepotDownloader fallback succeeded: $found" -ForegroundColor Green
        return $found
    }
    Write-Host "  [!!] DepotDownloader finished but the expected files were not found." -ForegroundColor Yellow
    return $null
}
function global:Test-ViGEmBusInstalled {
    # Best-effort detection of the Nefarius ViGEmBus driver. Returns
    # $true if any reliable signal is found. We check several
    # independent sources because no single one is guaranteed across
    # Windows versions / install methods:
    #   1. Install folder under Program Files (created by the MSI/EXE)
    #   2. Uninstall registry entries ("ViGEm Bus Driver")
    #   3. PnP device ("Nefarius Virtual Gamepad Emulation Bus" /
    #      "Virtual Gamepad Emulation Bus")
    # Any positive hit is treated as installed. Detection failures are
    # swallowed so a probe can never crash an installer.
    try {
        # 1. Program Files install folder.
        foreach ($pf in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
            if ($pf) {
                $dir = Join-Path $pf "Nefarius Software Solutions\ViGEm Bus Driver"
                if (Test-Path $dir) { return $true }
            }
        }
    } catch {}
    try {
        # 2. Uninstall registry entries.
        $regRoots = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        foreach ($rr in $regRoots) {
            $hit = Get-ItemProperty -Path $rr -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -and $_.DisplayName -match "ViGEm" }
            if ($hit) { return $true }
        }
    } catch {}
    try {
        # 3. PnP device node.
        $dev = Get-PnpDevice -ErrorAction SilentlyContinue |
            Where-Object { $_.FriendlyName -and $_.FriendlyName -match "Virtual Gamepad Emulation Bus" }
        if ($dev) { return $true }
    } catch {}
    return $false
}

function Read-UpdateOrInstall {
    # Shared install/update picker for download-and-replace mods. If the mod
    # is already present, offer to update (re-pull the latest files) or do a
    # full reinstall. Returns "install" (nothing there yet), "update",
    # "reinstall", or "cancel".
    param([string]$GameFolder, [string]$ModFile)
    if (-not $ModFile -or -not $GameFolder) { return "install" }
    $probe = Join-Path $GameFolder $ModFile
    if (-not (Test-Path $probe)) { return "install" }
    Write-Host ""
    Write-Host "  An existing installation was detected." -ForegroundColor Cyan
    Write-Host "    [1] Update    - re-download the latest version and replace the mod files" -ForegroundColor White
    Write-Host "    [2] Reinstall - full clean install" -ForegroundColor White
    Write-Host "    [Q] Cancel" -ForegroundColor Gray
    $c = ""
    while ($c -notin @("1","2","q","Q")) { $c = (Read-Host "  Choice (1/2/Q)").Trim() }
    if ($c -match "^[Qq]$") { return "cancel" }
    if ($c -eq "1") { return "update" }
    return "reinstall"
}

function global:New-DesktopShortcut {
    param([string]$LnkPath, [string]$TargetPath, [string]$ShortcutName, [string]$WorkingDir, [string]$IconPath, [string]$Arguments, [string]$Description)
    try {
        if (-not $LnkPath) {
            $dsk = [Environment]::GetFolderPath('Desktop')
            $LnkPath = Join-Path $dsk ($ShortcutName + '.lnk')
        }
        $ws = New-Object -ComObject WScript.Shell
        $sc = $ws.CreateShortcut($LnkPath)
        $sc.TargetPath = $TargetPath
        if ($WorkingDir)  { $sc.WorkingDirectory = $WorkingDir }
        if ($IconPath)    { $sc.IconLocation = $IconPath }
        if ($Arguments)   { $sc.Arguments = $Arguments }
        if ($Description) { $sc.Description = $Description }
        $sc.Save()
        return $LnkPath
    } catch { return $null }
}
