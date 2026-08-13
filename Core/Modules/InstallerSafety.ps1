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
        # Full path where a dragged/pasted file should land so the
        # caller's RetryCheck finds it. When set, the prompt becomes a
        # simple drag-the-file-onto-the-window flow (no temp folder, no
        # rename) - the preferred UX for every download fallback.
        [string]$DestFile      = "",
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
    # Only download flows (Subject set by Invoke-SafeDownload) get the
    # download sentence; every other caller (extraction, detection,
    # setup, checks) gets a generic one - previously this always said
    # "automated download of X", which read broken for e.g.
    # "BepInEx archive extraction".
    $subjectText = if ($Subject) { $Subject } else { $Action }
    $dlNoun = $subjectText -replace '\s+download$', ''
    Write-Host ""
    Write-Host "  What happened?" -ForegroundColor White
    if ($Subject) {
        Write-Host "  Unfortunately, the automated download of $dlNoun is currently not possible." -ForegroundColor Gray
    } else {
        Write-Host "  Unfortunately, '$Action' could not be completed automatically." -ForegroundColor Gray
    }
    if ($Instructions -and -not $DestFile) {
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
        # A console URL is not clickable - the ONLY reliable way to get the
        # user onto the page is opening it for them. Gate it behind an
        # explicit Enter so the browser doesn't pop up while they are still
        # reading (and so they know where the window came from).
        Write-Host "    $stepNum. Press ENTER to open the download page in your browser," -ForegroundColor White
        Write-Host "       then download $dlNoun there manually." -ForegroundColor White
        Write-Host "       Page: $Url" -ForegroundColor DarkGray
        Read-Host "       (press Enter to open the page)" | Out-Null
        try { Start-Process $Url -ErrorAction SilentlyContinue | Out-Null } catch { }
        Write-Host "       Opened. If no browser window appeared, copy the URL above by hand." -ForegroundColor DarkGray
        $stepNum++
    }
    if ($DestFile) {
        Write-Host "    $stepNum. DRAG the downloaded file onto THIS window, then press Enter." -ForegroundColor White
        Write-Host "       (or paste its full path and press Enter - no renaming needed)" -ForegroundColor DarkGray
        $stepNum++
    } elseif ($DestFolder -and (Test-Path $DestFolder)) {
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
    if (-not $DestFile) { Write-Host "    $stepNum. Come back here and choose [R]etry." -ForegroundColor Gray }

    while ($true) {
        Write-Host ""
        Write-Host "  Choices:" -ForegroundColor White
        Write-Host "    [R]etry  -  I did the manual step, check again" -ForegroundColor Yellow
        if ($AllowSkip) {
            Write-Host "    [S]kip   -  Continue without this step (install may be incomplete)" -ForegroundColor Yellow
        }
        if ($SourceFolder -or $DestFolder -or $Url) {
            $oLabel = if ($Url -and ($SourceFolder -or $DestFolder)) { "Reopen the download page / folder" }
                      elseif ($Url) { "Reopen the download page" }
                      else { "Reopen the folder in Explorer" }
            Write-Host "    [O]pen   -  $oLabel" -ForegroundColor Yellow
        }
        Write-Host "    [Q]uit   -  Stop the installer" -ForegroundColor Yellow
        $__prompt = if ($DestFile) { "  Drop the file here (or type R/S/Q)" } else { "  Your choice" }
        $raw = (Read-Host $__prompt).Trim()
        if ($DestFile -and $raw) {
            $cand = $raw.Trim('"').Trim("'")
            if ((Test-Path -LiteralPath $cand -PathType Leaf -ErrorAction SilentlyContinue)) {
                try {
                    Copy-Item -LiteralPath $cand -Destination $DestFile -Force -ErrorAction Stop
                    Write-Host "  [OK] Got it - using that file." -ForegroundColor Green
                    if ($RetryCheck) {
                        try { if (& $RetryCheck) { return "retry" } } catch {}
                        Write-Host "  [!!] That file did not pass the check - try another." -ForegroundColor Yellow
                        continue
                    }
                    return "retry"
                } catch {
                    Write-Host "  [!!] Could not use that file: $($_.Exception.Message)" -ForegroundColor Yellow
                    continue
                }
            }
        }
        $c = $raw.ToLower()
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
            if ($Url) {
                try { Start-Process $Url -ErrorAction SilentlyContinue | Out-Null } catch { }
            }
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
        # Name exactly the options that are actually on offer.
        $validOpts = "R"
        if ($AllowSkip) { $validOpts += ", S" }
        if ($SourceFolder -or $DestFolder -or $Url) { $validOpts += ", O" }
        $validOpts += " or Q"
        Write-Host "  Please answer $validOpts." -ForegroundColor Yellow
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
    # Last-resort auto-fallback for pinned GitHub release assets: only when
    # EVERY direct source above failed (including the Web Archive mirror),
    # ask the GitHub API for the repo's releases and resolve a matching
    # asset live. Rescues the common case of a re-tagged/renamed release
    # where the pinned URL 404s but the mod is still right there. Matching
    # is deliberately conservative:
    #   1. exact same file name in any release (newest first)
    #   2. name with the same leading word AND same extension
    #   3. a release's SINGLE asset with that extension (unambiguous)
    # Anything ambiguous is skipped - then the interactive fallback below
    # takes over exactly as before. Strictly additive: on any API error we
    # fall through unchanged.
    foreach ($u in $Urls) {
        if ($u -notmatch '^https?://github\.com/([^/]+)/([^/]+)/releases/download/[^/]+/(.+)$') { continue }
        $ghOwner = $matches[1]; $ghRepo = $matches[2]
        $ghFile  = [System.Uri]::UnescapeDataString($matches[3])
        $ghExt   = [System.IO.Path]::GetExtension($ghFile)
        $ghPrefix = ""
        if ($ghFile -match '^([A-Za-z]{4,})') { $ghPrefix = $matches[1] }
        try {
            Write-Host "  [..] Trying the GitHub API to locate $Label (matching release asset)..." -ForegroundColor Gray
            $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$ghOwner/$ghRepo/releases" -Headers @{ "User-Agent" = "VRModHub" } -TimeoutSec 10 -ErrorAction Stop
            if ($rels -isnot [array]) { $rels = @($rels) }
            $asset = $null
            foreach ($rel in $rels) {
                $a = @($rel.assets | Where-Object { $_.name -eq $ghFile }) | Select-Object -First 1
                if ($a) { $asset = $a; break }
            }
            if (-not $asset -and $ghPrefix) {
                foreach ($rel in $rels) {
                    $a = @($rel.assets | Where-Object { $_.name -like "$ghPrefix*$ghExt" }) | Select-Object -First 1
                    if ($a) { $asset = $a; break }
                }
            }
            if (-not $asset -and $ghExt) {
                foreach ($rel in $rels) {
                    $cand = @($rel.assets | Where-Object { $_.name -like "*$ghExt" })
                    if ($cand.Count -eq 1) { $asset = $cand[0]; break }
                }
            }
            if ($asset -and $asset.browser_download_url -and (-not $expanded.Contains([string]$asset.browser_download_url))) {
                $au = [string]$asset.browser_download_url
                Write-Host "  [..] API resolved: $($asset.name) - downloading..." -ForegroundColor Gray
                Write-Host "       From: $au" -ForegroundColor DarkGray
                try {
                    if (_Invoke-DownloadWithProgress -Url $au -Destination $Destination -Label $Label) {
                        Write-Host "  [OK] Downloaded $Label (via GitHub API fallback)" -ForegroundColor Green
                        return $true
                    }
                    throw "empty or missing file"
                } catch {
                    try {
                        $old = $ProgressPreference
                        $ProgressPreference = 'SilentlyContinue'
                        Invoke-WebRequest -Uri $au -OutFile $Destination -UseBasicParsing -ErrorAction Stop
                        $ProgressPreference = $old
                        if ((Test-Path $Destination) -and ((Get-Item $Destination).Length -gt 0)) {
                            Write-Host "  [OK] Downloaded $Label (via GitHub API fallback)" -ForegroundColor Green
                            return $true
                        }
                    } catch {
                        Write-Host "  [!!] API-resolved source failed too: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
        } catch {
            Write-Host "  [!!] GitHub API fallback unavailable: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        break   # only the first GitHub URL needs resolving
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
            -DestFolder $destFolderForFallback `
            -DestFile $Destination
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

# ---- Wrapper-folder resilience (generic) ------------------
#
# Modders change their ZIP layout without warning: one release has the
# payload at the archive root, the next wraps everything in a top-level
# folder ("ModName-1.2.3\<payload>"). An installer that copies the
# extraction dir verbatim then lands the files one level too deep and the
# mod reads as "not installed" (real case: CyberpunkVRPort-0.0.9).
#
# Get-ExtractedPayloadRoot returns the folder that actually holds the mod
# payload, so merge-into-root installers copy from THERE. Detection order:
#
#   1. -RelModFile (STRONGEST - use whenever the installer knows the
#      relative path of its marker file, e.g. "bin\x64\dxgi.dll" or just
#      "winhttp.dll"): the file is searched RECURSIVELY in the whole
#      extracted tree and the payload root is derived from where it was
#      found (hit path minus the relative path). Immune to any number of
#      wrapper folders, renamed wrappers, or extra readme files.
#   2. -Markers (folder/file names the payload level is known to hold,
#      e.g. @("bin","red4ext")): walking down through single wrapper
#      folders (max depth 10), the first level containing any marker wins.
#   3. No markers hit: a level with real files is treated as the payload
#      root; a level that is exactly one folder and no files is a wrapper
#      and is stepped into.
#
# Falls back to the extraction dir itself, so flat archives behave
# exactly as before.
function global:Get-ExtractedPayloadRoot {
    param(
        [Parameter(Mandatory=$true)][string]$ExtractDir,
        [string[]]$Markers = @(),
        [string]$RelModFile = ""
    )
    if (-not $ExtractDir -or -not (Test-Path -LiteralPath $ExtractDir)) { return $ExtractDir }
    $root = (Resolve-Path -LiteralPath $ExtractDir).Path.TrimEnd('\')

    # 1. Find the known mod file anywhere in the tree; derive the root.
    if ($RelModFile) {
        $rel  = $RelModFile.Trim('\')
        $leaf = Split-Path $rel -Leaf
        try {
            $hits = @(Get-ChildItem -LiteralPath $root -Recurse -Filter $leaf -File -ErrorAction SilentlyContinue)
            foreach ($h in $hits) {
                $full = $h.FullName
                if ($full.ToLower().EndsWith(("\" + $rel).ToLower())) {
                    return $full.Substring(0, $full.Length - $rel.Length - 1)
                }
            }
        } catch {}
    }

    # 2./3. Walk down through single wrapper folders.
    $cur = $root
    for ($depth = 0; $depth -lt 10; $depth++) {
        foreach ($m in $Markers) {
            if ($m -and (Test-Path -LiteralPath (Join-Path $cur $m))) { return $cur }
        }
        $entries = @(Get-ChildItem -LiteralPath $cur -Force -ErrorAction SilentlyContinue)
        $dirs  = @($entries | Where-Object { $_.PSIsContainer })
        $files = @($entries | Where-Object { -not $_.PSIsContainer })
        if ($files.Count -gt 0) { return $cur }
        if ($dirs.Count -eq 1) { $cur = $dirs[0].FullName; continue }
        break
    }
    return $cur
}

# ---- Safe extract-to-target (payload-verified) ------------
#
# One-call replacement for "Expand-ArchiveOrFallback straight into the
# game folder" used by auto-update installers (they pull releases/LATEST,
# so the modder can change the ZIP layout any day). It:
#   1. extracts to a private temp folder,
#   2. resolves the real payload root (Get-ExtractedPayloadRoot, using
#      the known mod file's relative path and/or markers),
#   3. merge-copies that root into -TargetDir (overwriting, creating
#      folders as needed),
#   4. VERIFIES the mod file actually arrived at the target, and warns
#      if it did not,
#   5. cleans up the temp folder.
# Returns the underlying extraction status string ("ok"/"manual"/"skip"/
# "quit"/"fail") so callers keep their existing flow; on successful copy
# with failed verification it still returns the status but prints a
# clear warning so the user is never silently left broken.
function global:Expand-ArchiveToTarget {
    param(
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [Parameter(Mandatory=$true)][string]$TargetDir,
        [string]$RelModFile = "",
        [string[]]$Markers = @(),
        [string]$Label = "archive",
        [string]$SkipMessage = "",
        [bool]$AllowSkip = $true
    )
    $tmpEx = Join-Path ([System.IO.Path]::GetTempPath()) ("hubex_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpEx -Force | Out-Null
    try {
        $st = Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $tmpEx -Label $Label `
                -SkipMessage $SkipMessage -AllowSkip $AllowSkip
        if ([string]$st -ne "ok" -and [string]$st -ne "manual") { return $st }
        $src = Get-ExtractedPayloadRoot -ExtractDir $tmpEx -RelModFile $RelModFile -Markers $Markers
        $base = (Resolve-Path -LiteralPath $src).Path.TrimEnd('\')
        Get-ChildItem -Path $base -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $rel = $_.FullName.Substring($base.Length).TrimStart('\')
            $tgt = Join-Path $TargetDir $rel
            $td  = Split-Path $tgt -Parent
            if ($td -and -not (Test-Path -LiteralPath $td)) { New-Item -ItemType Directory -Path $td -Force | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $tgt -Force
        }
        if ($RelModFile) {
            if (Test-Path -LiteralPath (Join-Path $TargetDir $RelModFile)) {
                Write-Host "  [OK] $Label delivered ($RelModFile verified in target)." -ForegroundColor Green
            } else {
                Write-Host "  [WARN] $Label copied, but '$RelModFile' was NOT found in the target folder - the mod package layout may have changed. Please report this." -ForegroundColor Yellow
            }
        }
        return $st
    } finally {
        try { Remove-Item -LiteralPath $tmpEx -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}


# ---- ARCHIVE SAFETY: look inside BEFORE unpacking ---------
#
# Hard rule in this project: no installer ever extracts an archive and
# HOPES the layout is what it was last month. Modders re-wrap their
# packages without warning (GAMMA's update .7z suddenly carried a
# wrapper folder named after the archive), and a blind extract then
# drops the payload NEXT TO the install instead of into it.
#
# Get-ArchiveTopLevel lists an archive WITHOUT extracting it, so the
# caller can see the real layout first. Returns:
#   Ok       $true when the listing worked
#   Entries  every path inside the archive (relative, backslashes)
#   Roots    the distinct top-level names
#   Method   "7z" or "zip"
# On failure Ok is $false and the caller must treat the layout as
# unknown - never as "probably fine".
function global:Get-ArchiveTopLevel {
    param(
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [string]$SevenZip = ""
    )
    $res = [pscustomobject]@{ Ok = $false; Entries = @(); Roots = @(); Method = "" }
    if (-not (Test-Path -LiteralPath $ArchivePath)) { return $res }

    $entries = New-Object System.Collections.Generic.List[string]

    # .zip can be read by .NET without any external tool.
    if ($ArchivePath -match '(?i)\.zip$') {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $za = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
            try { foreach ($e in $za.Entries) { $entries.Add(($e.FullName -replace '/','\')) } }
            finally { $za.Dispose() }
            $res.Method = "zip"
        } catch { $entries.Clear() }
    }

    # Everything else (and .zip if the managed read failed) via 7-Zip's
    # technical listing, which prints one "Path = ..." line per entry
    # and survives spaces and umlauts in names.
    if ($entries.Count -eq 0) {
        $sz = $SevenZip
        if (-not $sz -and (Get-Command Get-SevenZip -ErrorAction SilentlyContinue)) { $sz = Get-SevenZip }
        if ($sz -and (Test-Path -LiteralPath $sz)) {
            $out = Join-Path ([System.IO.Path]::GetTempPath()) ("hublist_" + [Guid]::NewGuid().ToString("N") + ".txt")
            try {
                $p = Start-Process -FilePath $sz -ArgumentList @("l","-slt","-ba","-y","`"$ArchivePath`"") `
                        -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out
                if ($p.ExitCode -eq 0 -and (Test-Path -LiteralPath $out)) {
                    foreach ($line in (Get-Content -LiteralPath $out -ErrorAction SilentlyContinue)) {
                        if ($line -like "Path = *") { $entries.Add(($line.Substring(7).Trim() -replace '/','\')) }
                    }
                    $res.Method = "7z"
                }
            } catch { }
            finally { try { Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue } catch {} }
        }
    }

    if ($entries.Count -eq 0) { return $res }
    $res.Entries = @($entries)
    $res.Roots   = @($entries | ForEach-Object { ($_ -split '\\')[0] } | Where-Object { $_ } | Sort-Object -Unique)
    $res.Ok      = $true
    return $res
}

# ---- ARCHIVE SAFETY: put the payload where it belongs -----
#
# For archives too large to extract twice (GAMMA's full build is 110 GB,
# so extract-to-temp-then-copy is not an option): extract into the
# PARENT folder as before, then call this. It locates the folder that
# really holds $Marker and, if that is not the target, MOVES the payload
# into place (a move on the same volume is instant) and removes the
# empty wrapper.
#
# Returns an object: Ok, PayloadRoot, Moved (file count), Merged (bool),
# AlreadyInPlace (bool), Message. Ok=$false means the marker was not
# found anywhere - the caller must FAIL, never assume success.
function global:Move-PayloadIntoPlace {
    param(
        [Parameter(Mandatory=$true)][string]$SearchRoot,
        [Parameter(Mandatory=$true)][string]$TargetDir,
        [Parameter(Mandatory=$true)][string]$Marker,
        [int]$MaxDepth = 4
    )
    $r = [pscustomobject]@{ Ok=$false; PayloadRoot=""; Moved=0; Merged=$false; AlreadyInPlace=$false; Message="" }
    if (-not (Test-Path -LiteralPath $SearchRoot)) { $r.Message = "search root missing: $SearchRoot"; return $r }

    $leaf = Split-Path $Marker -Leaf
    $hits = @()
    try {
        $hits = @(Get-ChildItem -LiteralPath $SearchRoot -Recurse -Depth $MaxDepth -Filter $leaf -File -ErrorAction SilentlyContinue)
    } catch {}
    if ($hits.Count -eq 0) { $r.Message = "'$leaf' not found under $SearchRoot"; return $r }

    # Prefer a hit OUTSIDE the target. A copy already sitting in the
    # target is usually the OLD install - treating that as "the payload"
    # is exactly the false success this function exists to prevent.
    # Only when there is no other candidate is the target itself the
    # payload (the normal case for a full build that unpacked correctly).
    $tgt   = $TargetDir.TrimEnd('\')
    $outer = @($hits | Where-Object { (Split-Path $_.FullName -Parent).TrimEnd('\') -ine $tgt })
    if ($outer.Count -gt 0) {
        $best = $outer | Sort-Object { ($_.FullName -split '\\').Count } | Select-Object -First 1
    } else {
        $best = $hits | Sort-Object { ($_.FullName -split '\\').Count } | Select-Object -First 1
    }
    $payload = (Split-Path $best.FullName -Parent).TrimEnd('\')
    $r.PayloadRoot = $payload

    if ($payload -ieq $tgt) { $r.Ok = $true; $r.AlreadyInPlace = $true; $r.Message = "payload already at target"; return $r }

    # Merge-move every file from the payload root into the target.
    $moved = 0
    try {
        $files = @(Get-ChildItem -LiteralPath $payload -Recurse -File -Force -ErrorAction SilentlyContinue)
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($payload.Length).TrimStart('\')
            $dst = Join-Path $TargetDir $rel
            $dd  = Split-Path $dst -Parent
            if ($dd -and -not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
            Move-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop
            $moved++
        }
    } catch {
        $r.Moved = $moved; $r.Message = "move failed after $moved file(s): $($_.Exception.Message)"; return $r
    }
    $r.Moved  = $moved
    $r.Merged = $true
    $r.Ok     = ($moved -gt 0)
    if (-not $r.Ok) { $r.Message = "payload root held no files"; return $r }

    # Drop the now-empty wrapper folder (only what we emptied ourselves).
    try {
        $wrapper = $payload
        while ($wrapper -and ($wrapper.TrimEnd('\') -ne $SearchRoot.TrimEnd('\')) -and (Test-Path -LiteralPath $wrapper)) {
            $left = @(Get-ChildItem -LiteralPath $wrapper -Force -Recurse -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer })
            if ($left.Count -gt 0) { break }
            $up = Split-Path $wrapper -Parent
            Remove-Item -LiteralPath $wrapper -Recurse -Force -ErrorAction SilentlyContinue
            $wrapper = $up
        }
    } catch {}
    $r.Message = "moved $moved file(s) from '$payload' into '$TargetDir'"
    return $r
}

# ---- Post-copy delivery verification ----------------------
#
# For installers that already have their own extract+copy logic (Martin's
# rule: don't rewrite working logic). Call this AFTER the existing copy:
# if the expected file is at the target, it does nothing and returns
# $true. Only when the file is MISSING does it resolve the real payload
# root inside the extraction dir and merge-copy from there, then verify
# again. Existing behavior is untouched in the good case; the safety net
# only engages when a layout change actually broke the install.
function global:Assert-PayloadDelivered {
    param(
        [Parameter(Mandatory=$true)][string]$ExtractDir,
        [Parameter(Mandatory=$true)][string]$TargetDir,
        [Parameter(Mandatory=$true)][string]$RelModFile,
        [string[]]$Markers = @(),
        [string]$Label = "mod"
    )
    try {
        if (Test-Path -LiteralPath (Join-Path $TargetDir $RelModFile)) { return $true }
        if (-not (Test-Path -LiteralPath $ExtractDir)) { return $false }
        Write-Host "  [WARN] $Label`: expected file '$RelModFile' not found in target after copy - the package layout likely changed. Engaging safety re-copy..." -ForegroundColor Yellow
        $src = Get-ExtractedPayloadRoot -ExtractDir $ExtractDir -RelModFile $RelModFile -Markers $Markers
        if (-not (Test-Path -LiteralPath (Join-Path $src $RelModFile))) {
            Write-Host "  [WARN] $Label`: '$RelModFile' not found anywhere in the extracted package either. Please report this." -ForegroundColor Yellow
            return $false
        }
        $base = (Resolve-Path -LiteralPath $src).Path.TrimEnd('\')
        Get-ChildItem -Path $base -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $rel = $_.FullName.Substring($base.Length).TrimStart('\')
            $tgt = Join-Path $TargetDir $rel
            $td  = Split-Path $tgt -Parent
            if ($td -and -not (Test-Path -LiteralPath $td)) { New-Item -ItemType Directory -Path $td -Force | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $tgt -Force
        }
        if (Test-Path -LiteralPath (Join-Path $TargetDir $RelModFile)) {
            Write-Host "  [OK] $Label`: safety re-copy delivered '$RelModFile'." -ForegroundColor Green
            return $true
        }
        Write-Host "  [WARN] $Label`: safety re-copy still could not deliver '$RelModFile'. Please report this." -ForegroundColor Yellow
        return $false
    } catch { return $false }
}

# ---- Update notice for re-runs ----------------------------
#
# Auto-update installers double as updaters: re-running one simply pulls
# the newest release over the existing install. Make that explicit: call
# this right after the game folder is known; if the mod file is already
# there, tell the user this run will UPDATE the mod (no extra prompt -
# the installers' own gates stay as they are).
function global:Show-UpdateNoticeIfInstalled {
    param(
        [string]$TargetDir,
        [string]$RelModFile,
        [string]$Label = "VR mod"
    )
    try {
        if (-not $TargetDir -or -not $RelModFile) { return $false }
        if (Test-Path -LiteralPath (Join-Path $TargetDir $RelModFile)) {
            Write-Host ""
            Write-Host "  [UPDATE] $Label is already installed - this run will update it to the latest version." -ForegroundColor Cyan
            Write-Host ""
            return $true
        }
    } catch {}
    return $false
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

# ---- Standard extraction with progress ---------------------
#
# Extract an archive with 7-Zip showing 7-Zip's NATIVE progress
# (accurate %), while redirecting 7z's noisy per-file stdout to a temp
# file so only a clean "Extracting <label>... NN%  MM:SS elapsed" line
# reaches the console. THIS is the standard way to extract in installers,
# especially for large packs. Pass a $SevenZip from Get-SevenZip.
# Returns $true on success (7z exit 0), $false otherwise.
#
#   $sevenZip = Get-SevenZip
#   if (-not $sevenZip) { return }
#   if (-not (Expand-7zWithProgress -SevenZip $sevenZip -Archive $zip -Dest $out -Label "HD textures")) { ... }
#
function global:Expand-7zWithProgress {
    param(
        [Parameter(Mandatory=$true)][string]$SevenZip,
        [Parameter(Mandatory=$true)][string]$Archive,
        [Parameter(Mandatory=$true)][string]$Dest,
        [string]$Label = "archive"
    )
    if (-not (Test-Path -LiteralPath $Dest)) {
        try { New-Item -ItemType Directory -Path $Dest -Force | Out-Null } catch {}
    }
    $progFile = Join-Path ([System.IO.Path]::GetTempPath()) ("7zp_" + [Guid]::NewGuid().ToString("N") + ".log")
    try {
        $proc = Start-Process -FilePath $SevenZip `
            -ArgumentList "x","-y","-bso0","-bsp1","`"$Archive`"","-o`"$Dest`"" `
            -PassThru -NoNewWindow -RedirectStandardOutput $progFile
    } catch {
        Write-Host "  [X] Could not start 7-Zip: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pct = 0
    while (-not $proc.HasExited) {
        Start-Sleep -Milliseconds 500
        try {
            $fs = [System.IO.File]::Open($progFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $sr = New-Object System.IO.StreamReader($fs)
            $txt = $sr.ReadToEnd()
            $sr.Close(); $fs.Close()
            $mm = [regex]::Matches($txt, '(\d+)%')
            if ($mm.Count -gt 0) { $pct = [int]$mm[$mm.Count - 1].Groups[1].Value }
        } catch { }
        $el = $sw.Elapsed.ToString('mm\:ss')
        Write-Host ("`r  Extracting $Label... {0,3}%   {1} elapsed        " -f $pct, $el) -NoNewline -ForegroundColor Gray
    }
    # Start-Process -PassThru with a redirected stream can leave ExitCode
    # null even after the process has exited. Force it via WaitForExit,
    # then fall back to verifying the destination actually received files -
    # so a null code doesn't get mis-reported as a failure.
    try { $proc.WaitForExit() } catch {}
    $exitCode = $null
    try { $exitCode = $proc.ExitCode } catch { $exitCode = $null }
    Remove-Item $progFile -Force -ErrorAction SilentlyContinue
    $destHasFiles = $false
    try { $destHasFiles = (@(Get-ChildItem -LiteralPath $Dest -Recurse -File -ErrorAction SilentlyContinue)).Count -gt 0 } catch {}
    if (($exitCode -eq 0) -or (($null -eq $exitCode) -and $destHasFiles)) {
        Write-Host ("`r  Extracting $Label... 100%   done                        ") -ForegroundColor Gray
        return $true
    }
    $shown = if ($null -eq $exitCode) { "unknown" } else { $exitCode }
    Write-Host ("`r  Extraction of $Label failed (7-Zip exit $shown).                 ") -ForegroundColor Red
    return $false
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
            Write-Host "    2. Open one of these in any browser:  steam://open/console" -ForegroundColor Gray
            Write-Host "       or  steam://nav/console  - only one works per Steam version." -ForegroundColor Gray
            Write-Host "       (or paste it into the Run dialog: Win+R, paste, Enter)" -ForegroundColor Gray
            Write-Host "    3. Click into the Steam Console input field." -ForegroundColor Gray
            Write-Host "    4. Paste with Ctrl+V and press Enter." -ForegroundColor Gray
            Write-Host "    5. Wait for 'Depot download complete' before continuing." -ForegroundColor Gray
            Write-Host ""
            # Beide Protokoll-Adressen: je nach Steam-Version zieht nur eine.
            foreach ($cu in @("steam://open/console", "steam://nav/console")) {
                try { Start-Process $cu -ErrorAction SilentlyContinue | Out-Null; Start-Sleep -Milliseconds 900 } catch {}
            }

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
    # Shared install/update picker for download-and-replace mods.  A clean
    # reinstall is exposed only when the caller explicitly declares support;
    # most installers merge the same payload for both old choices, so showing
    # two choices was misleading. Returns "install" (truly empty target),
    # "update", "reinstall", or "cancel".
    param(
        [string]$GameFolder,
        [string]$ModFile,
        [switch]$AllowCleanReinstall
    )
    if (-not $ModFile -or -not $GameFolder) { return "install" }
    $probe = Join-Path $GameFolder $ModFile
    $modPresent = Test-Path -LiteralPath $probe
    $folderHasContent = $false
    if (Test-Path -LiteralPath $GameFolder -PathType Container) {
        try { $folderHasContent = (@(Get-ChildItem -LiteralPath $GameFolder -Force -ErrorAction Stop).Count -gt 0) } catch {}
    }
    if (-not $modPresent -and -not $folderHasContent) { return "install" }
    Write-Host ""
    if ($modPresent) {
        Write-Host "  An existing installation was detected." -ForegroundColor Cyan
    } else {
        Write-Host "  Existing files were found, but '$ModFile' is missing." -ForegroundColor Yellow
        Write-Host "  Repair mode will merge a fresh release without deleting unrelated files." -ForegroundColor Gray
    }
    Write-Host "    [1] Update / repair - merge the latest release files safely" -ForegroundColor White
    if ($AllowCleanReinstall) {
        Write-Host "    [2] Reinstall       - rebuild app/mod files; personal data is preserved" -ForegroundColor White
    }
    Write-Host "    [Q] Cancel" -ForegroundColor Gray
    $valid = if ($AllowCleanReinstall) { @("1","2","q","Q") } else { @("1","q","Q") }
    $prompt = if ($AllowCleanReinstall) { "  Choice (1/2/Q)" } else { "  Choice (1/Q)" }
    $c = ""
    while ($c -notin $valid) { $c = (Read-Host $prompt).Trim() }
    if ($c -match "^[Qq]$") { return "cancel" }
    if ($c -eq "1") { return "update" }
    return "reinstall"
}

# ============================================================
#  Durable user-data protection for replace-style installers
# ============================================================
# Installers that rebuild a standalone game's whole directory must never put
# saves/ROMs/settings in their ordinary extraction temp: their error handling
# routinely clears that temp before exiting.  These helpers move selected paths
# to a separately named backup beside the installation, merge them back with
# per-file verification, and delete the backup only after a complete restore.
function global:Copy-DirectoryTreeVerified {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [string[]]$KeepExistingRelativePaths = @()
    )
    $sourceRoot = [System.IO.Path]::GetFullPath($Source).TrimEnd('\')
    $keepPaths = @($KeepExistingRelativePaths | ForEach-Object {
        if ($_ -and $_.Trim()) { $_.Trim().Replace('/', '\').Trim('\') }
    } | Where-Object { $_ })
    if (-not (Test-Path -LiteralPath $sourceRoot)) { return }
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force -ErrorAction Stop | Out-Null
    }
    Get-ChildItem -LiteralPath $sourceRoot -Directory -Recurse -Force -ErrorAction Stop | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
        New-Item -ItemType Directory -Path (Join-Path $Destination $relative) -Force -ErrorAction Stop | Out-Null
    }
    Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force -ErrorAction Stop | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
        $target = Join-Path $Destination $relative
        $parent = Split-Path $target -Parent
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        $keepExisting = $false
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            foreach ($keepPath in $keepPaths) {
                if ($relative.Equals($keepPath, [StringComparison]::OrdinalIgnoreCase) -or
                    $relative.StartsWith($keepPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
                    $keepExisting = $true
                    break
                }
            }
        }
        if (-not $keepExisting) {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force -ErrorAction Stop
            $copied = Get-Item -LiteralPath $target -Force -ErrorAction Stop
            if ($copied.Length -ne $_.Length) { throw "Verification failed after copying '$relative'." }
        }
    }
}

# Merge a complete extracted/depot directory into an installation without ever
# deleting the destination.  When the destination already exists, every source
# file is copied and size-verified; unrelated destination files remain.  A
# disposable source directory is removed only after that verified copy.  When
# no destination exists yet, a same-volume move keeps large depot installs fast.
function global:Merge-DirectoryTreeVerified {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [switch]$RemoveSource,
        [string]$Label = "payload",
        [string[]]$KeepExistingRelativePaths = @()
    )
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "$Label source directory is missing: $Source"
    }
    $sourceRoot = [System.IO.Path]::GetFullPath($Source).TrimEnd('\')
    $targetRoot = [System.IO.Path]::GetFullPath($Destination).TrimEnd('\')
    if ($sourceRoot -ieq $targetRoot) {
        Write-Host "  [OK] $Label is already at the selected destination." -ForegroundColor Green
        return "already"
    }
    if (Test-Path -LiteralPath $targetRoot -PathType Leaf) {
        throw "$Label destination is a file, not a directory: $targetRoot"
    }
    if (Test-Path -LiteralPath $targetRoot -PathType Container) {
        Copy-DirectoryTreeVerified -Source $sourceRoot -Destination $targetRoot -KeepExistingRelativePaths $KeepExistingRelativePaths
        if ($RemoveSource) {
            try { Remove-Item -LiteralPath $sourceRoot -Recurse -Force -ErrorAction Stop }
            catch { Write-Host "  [!!] $Label was installed, but the disposable source could not be removed: $sourceRoot" -ForegroundColor Yellow }
        }
        Write-Host "  [OK] $Label merged into the existing installation; additional files were preserved." -ForegroundColor Green
        return "merged"
    }
    $parent = Split-Path $targetRoot -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    if ($RemoveSource) {
        Move-Item -LiteralPath $sourceRoot -Destination $targetRoot -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $targetRoot -PathType Container)) {
            throw "$Label move did not create the destination: $targetRoot"
        }
        Write-Host "  [OK] $Label moved into place." -ForegroundColor Green
        return "moved"
    }
    Copy-DirectoryTreeVerified -Source $sourceRoot -Destination $targetRoot -KeepExistingRelativePaths $KeepExistingRelativePaths
    Write-Host "  [OK] $Label copied into place and verified." -ForegroundColor Green
    return "copied"
}

# Merge one payload item whose destination path is already fully resolved.
# Directories use the tree merge above; files are overwritten and size-checked.
function global:Merge-PathItemVerified {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [string]$Label = "payload item",
        [string[]]$KeepExistingRelativePaths = @()
    )
    if (Test-Path -LiteralPath $Source -PathType Container) {
        return Merge-DirectoryTreeVerified -Source $Source -Destination $Destination -Label $Label `
            -KeepExistingRelativePaths $KeepExistingRelativePaths
    }
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "$Label source item is missing: $Source"
    }
    if (Test-Path -LiteralPath $Destination -PathType Container) {
        throw "$Label destination is a directory, but the source is a file: $Destination"
    }
    $leaf = Split-Path $Source -Leaf
    $keepFile = $false
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        foreach ($keepPath in @($KeepExistingRelativePaths)) {
            if ($keepPath -and $leaf.Equals($keepPath.Trim().Replace('/', '\').Trim('\'), [StringComparison]::OrdinalIgnoreCase)) {
                $keepFile = $true
                break
            }
        }
    }
    if ($keepFile) { return "preserved" }
    $parent = Split-Path $Destination -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
    $sourceItem = Get-Item -LiteralPath $Source -Force -ErrorAction Stop
    $targetItem = Get-Item -LiteralPath $Destination -Force -ErrorAction Stop
    if ($sourceItem.Length -ne $targetItem.Length) { throw "Verification failed after copying '$leaf'." }
    return "copied"
}

function global:Restore-InstallUserData {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$BackupRoot,
        [string]$Label = "game"
    )
    if (-not (Test-Path -LiteralPath $BackupRoot)) { return $true }
    try {
        if (-not (Test-Path -LiteralPath $GameRoot)) {
            New-Item -ItemType Directory -Path $GameRoot -Force -ErrorAction Stop | Out-Null
        }
        Copy-DirectoryTreeVerified -Source $BackupRoot -Destination $GameRoot
        Remove-Item -LiteralPath $BackupRoot -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] Preserved $Label user data restored and verified." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [XX] Could not fully restore preserved $Label user data: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [!!] The safety backup has NOT been deleted: $BackupRoot" -ForegroundColor Yellow
        return $false
    }
}

function global:Protect-InstallUserData {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$BackupRoot,
        [Parameter(Mandatory=$true)][string[]]$RelativePaths,
        [string]$Label = "game"
    )
    # A leftover backup means an earlier run was interrupted.  Recover it before
    # capturing current state; overwriting it would recreate the data-loss bug.
    if (Test-Path -LiteralPath $BackupRoot) {
        Write-Host "  [!!] Recovering $Label user data from an interrupted update first." -ForegroundColor Yellow
        if (-not (Restore-InstallUserData -GameRoot $GameRoot -BackupRoot $BackupRoot -Label $Label)) { return $false }
    }
    try {
        foreach ($relative in $RelativePaths) {
            if ([string]::IsNullOrWhiteSpace($relative)) { continue }
            $source = Join-Path $GameRoot $relative
            if (-not (Test-Path -LiteralPath $source)) { continue }
            $destination = Join-Path $BackupRoot $relative
            $parent = Split-Path $destination -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
            }
            Move-Item -LiteralPath $source -Destination $destination -Force -ErrorAction Stop
            Write-Host "  [OK] Secured user data: $relative" -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Host "  [XX] Could not safely preserve $Label user data: $($_.Exception.Message)" -ForegroundColor Red
        if (Test-Path -LiteralPath $BackupRoot) {
            $null = Restore-InstallUserData -GameRoot $GameRoot -BackupRoot $BackupRoot -Label $Label
        }
        return $false
    }
}

# ============================================================
#  Write-ModStamp - record WHICH build got installed, next to the mod
# ============================================================
# One marker name for every game, written into the GAME folder. The Hub
# also keeps a copy under Core\<Game>\.installed_version, but that copy
# dies whenever somebody replaces the Hub folder by hand - and a missing
# marker makes the next scan seed the CURRENT version, which quietly
# declares an outdated mod up to date. The in-game file cannot be lost
# that way, so it is the ground truth and the Hub copy is the cache.
#
# Installers call this right after they have proof the mod landed. Pass
# the version you actually installed - a GitHub tag, a Thunderstore
# version, a Nexus file version. Anything the catalog compares against
# has to match this string, so use the same shape.
# $Second is for entries that track two mods in one tile.
# ---------------------------------------------------------------
#  Test-ThunderstoreDependencies - fehlende Abhaengigkeiten finden
# ---------------------------------------------------------------
# WARUM ES DAS GIBT: unsere Thunderstore-Installer tragen feste Listen
# von Paketen. Die stammen aus der manifest.json der Hauptmod oder aus
# Handarbeit - und beides kennt nur die DIREKTEN Abhaengigkeiten, nicht
# das, was diese wiederum brauchen. Bei PEAK ist genau das aufgefallen:
# PEAKLib_Core verlangt MonoDetour_BepInEx_5 und SoftDependencyFix, und
# beide wurden nie mitinstalliert.
#
# DIESE FUNKTION AENDERT NICHTS. Sie liest die Abhaengigkeiten der
# angegebenen Pakete von Thunderstore und gibt zurueck, was in der
# Liste fehlt. Der Aufrufer entscheidet, was er damit tut.
#
# EINGABE: Adressen der Form
#   https://thunderstore.io/package/download/<Autor>/<Name>/<Version>/
# Daraus werden Autor und Name gelesen - die Installer haben solche
# Listen ohnehin, es braucht keine Umbauten an ihren Datenstrukturen.
function global:Test-ThunderstoreDependencies {
    param(
        [Parameter(Mandatory=$true)][string[]]$PackageUrls,
        [int]$TimeoutSec = 10
    )
    $have = @{}
    $todo = @()
    foreach ($u in $PackageUrls) {
        $m = [regex]::Match([string]$u, 'thunderstore\.io/package/download/([^/]+)/([^/]+)/')
        if (-not $m.Success) { continue }
        $key = ($m.Groups[1].Value + "-" + $m.Groups[2].Value)
        $have[$key.ToLowerInvariant()] = $true
        $todo += @{ Author = $m.Groups[1].Value; Name = $m.Groups[2].Value }
    }
    # Modloader nie melden - der steht in jeder Liste ohnehin ganz oben
    # und wird von den Installern gesondert behandelt.
    foreach ($b in @("bepinex-bepinexpack","bepinex-bepinexpack_peak","denikson-bepinexpack_valheim")) { $have[$b] = $true }

    $missing = @()
    $seenMissing = @{}
    foreach ($p in $todo) {
        $info = $null
        try {
            $info = (Invoke-WebRequest -Uri "https://thunderstore.io/api/experimental/package/$($p.Author)/$($p.Name)/" `
                        -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop).Content | ConvertFrom-Json
        } catch { continue }
        if (-not $info -or -not $info.latest -or -not $info.latest.dependencies) { continue }
        foreach ($dep in @($info.latest.dependencies)) {
            if (-not $dep) { continue }
            # "Namespace-Name-Version" von HINTEN trennen: der Name darf
            # selbst Bindestriche enthalten, die Version nicht.
            $parts = [string]$dep -split '-'
            if ($parts.Count -lt 3) { continue }
            $ver  = $parts[-1]
            $ns   = $parts[0]
            $name = ($parts[1..($parts.Count-2)]) -join '-'
            $key  = "$ns-$name"
            if ($have.ContainsKey($key.ToLowerInvariant())) { continue }
            if ($seenMissing.ContainsKey($key.ToLowerInvariant())) { continue }
            $seenMissing[$key.ToLowerInvariant()] = $true
            $missing += @{
                Author = $ns; Name = $name; Version = $ver
                RequiredBy = $p.Name
                Url = "https://thunderstore.io/package/download/$ns/$name/$ver/"
            }
        }
    }
    # KOMMA VOR DER RUECKGABE, das ist kein Tippfehler: PowerShell packt
    # ein Array mit GENAU EINEM Element beim Zurueckgeben aus. Der
    # Aufrufer bekaeme dann die Hashtabelle selbst - und .Count waere die
    # Zahl ihrer SCHLUESSEL statt 1. Genau darauf bin ich beim Testen
    # hereingefallen. Das Komma erzwingt ein Array.
    return ,$missing
}

# Das Ergebnis in einer einheitlichen Form ausgeben. Bewusst als
# WARNUNG und nicht als Abbruch: fehlt etwas, laeuft die Mod oft
# trotzdem - nur eben nicht vollstaendig.
function global:Show-ThunderstoreDependencyWarning {
    param([array]$Missing)
    if (-not $Missing -or $Missing.Count -eq 0) { return }
    Write-Host ""
    Write-Host " [!] Thunderstore lists $($Missing.Count) required package(s) that this" -ForegroundColor Yellow
    Write-Host "     installer does not install:" -ForegroundColor Yellow
    foreach ($m in $Missing) {
        Write-Host ("       {0}-{1} {2}   (required by {3})" -f $m.Author, $m.Name, $m.Version, $m.RequiredBy) -ForegroundColor Yellow
    }
    Write-Host "     The mod may still start, but parts of it can fail." -ForegroundColor Gray
    Write-Host "     Please report this so the entry can be completed." -ForegroundColor Gray
    Write-Host ""
}

function global:Write-ModStamp {
    param(
        [string]$GameDir,
        [string]$Version,
        [switch]$Second
    )
    if ([string]::IsNullOrWhiteSpace($GameDir)) { return $false }
    if ([string]::IsNullOrWhiteSpace($Version)) { return $false }
    if (-not (Test-Path -LiteralPath $GameDir)) { return $false }
    # Same literal as Get-GameStampPath in VRModHub.ps1 - installers run in
    # their own process and never load that file, so the name is repeated
    # here on purpose. Change one, change the other.
    $name = ".pcvrhub_version"
    if ($Second) { $name = "$name" + "_b" }
    try {
        [System.IO.File]::WriteAllText(
            (Join-Path $GameDir $name), $Version.Trim(),
            (New-Object System.Text.UTF8Encoding $false)
        )
        return $true
    } catch { return $false }
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

# ---- Pre-download scan --------------------------------------
#
# Many mods live behind a page we cannot download from directly (Nexus
# logins, ModDB gates, Patreon). The old pattern was: open the page, THEN
# look in Downloads. That sends people to a browser they may not need -
# the file is very often already sitting there from an earlier attempt or
# a run that was cancelled halfway.
#
# So: call this BEFORE opening the page. If it returns a path, skip the
# browser step entirely. If it returns $null, carry on as before.
#
#   $pre = Find-PredownloadedFile -Patterns @("*LUNACID*VR*.zip","*LUNACID*.zip") -Label "the Lunacid VR mod"
#   if (-not $pre) { Pause-User "Press Enter to open..."; Start-Process $url }
#
# Patterns are tried IN ORDER, so put the most specific one first; within
# one pattern the newest file wins. Also looks in the Hub folder itself,
# since browsers configured to "always ask" often land next to the Hub.
# The user always confirms - a wrong guess must never be silently used.
function global:Find-PredownloadedFile {
    param(
        [Parameter(Mandatory=$true)][string[]]$Patterns,
        [string]$Label = "the download",
        [string[]]$ExtraFolders = @(),
        [int]$MaxAgeDays = 0,         # 0 = no age limit
        # Set this on the SECOND pass, after the download page has already
        # been opened. There is no download left to skip at that point, and
        # saying so would suggest this is some additional, separate file.
        [switch]$PageAlreadyOpen
    )
    $folders = New-Object System.Collections.ArrayList
    foreach ($f in @(
        (Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"),
        ([Environment]::GetFolderPath("Desktop"))
    ) + $ExtraFolders) {
        if ($f -and (Test-Path -LiteralPath $f)) { [void]$folders.Add([string]$f) }
    }
    if ($folders.Count -eq 0) { return $null }

    $hit = $null
    foreach ($pat in $Patterns) {
        foreach ($dir in $folders) {
            $found = $null
            try {
                $found = Get-ChildItem -LiteralPath $dir -Filter $pat -File -ErrorAction SilentlyContinue |
                         Where-Object {
                             # Browsers write a .crdownload / .part next to the
                             # real name while still downloading - never offer
                             # a file that is still being written.
                             ($_.Extension -notmatch '(?i)\.(crdownload|part|tmp|opdownload)$') -and
                             (($MaxAgeDays -le 0) -or ($_.LastWriteTime -gt (Get-Date).AddDays(-$MaxAgeDays)))
                         } |
                         Sort-Object LastWriteTime -Descending | Select-Object -First 1
            } catch { $found = $null }
            if ($found) { $hit = $found; break }
        }
        if ($hit) { break }
    }
    if (-not $hit) { return $null }

    $sizeTxt = if ($hit.Length -ge 1GB) { "{0:N2} GB" -f ($hit.Length / 1GB) } else { "{0:N1} MB" -f ($hit.Length / 1MB) }
    Write-Host ""
    Write-Host "  Found what looks like $Label already on disk:" -ForegroundColor Cyan
    Write-Host "    $($hit.Name)" -ForegroundColor White
    Write-Host "    $sizeTxt   $($hit.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
    Write-Host "    in $($hit.DirectoryName)" -ForegroundColor DarkGray
    Write-Host ""
    $question = if ($PageAlreadyOpen) { "  Use this file? [Y/N]" } else { "  Use this file and skip the download? [Y/N]" }
    $ans = (Read-Host $question).Trim().ToUpper()
    if ($ans -in @("Y","YES","")) {
        Write-Host "  [OK] Using: $($hit.FullName)" -ForegroundColor Green
        return [string]$hit.FullName
    }
    if ($PageAlreadyOpen) {
        Write-Host "  [..] Ignoring it - you can point at another file instead." -ForegroundColor Gray
    } else {
        Write-Host "  [..] Ignoring it - opening the download page instead." -ForegroundColor Gray
    }
    return $null
}
