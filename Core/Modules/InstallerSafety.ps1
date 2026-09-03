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
        [string]$SkipMessage  = "",
        [hashtable]$DownloadInfo
    )
    if ($null -ne $DownloadInfo) { $DownloadInfo.Clear() }
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
                if ($null -ne $DownloadInfo) { $DownloadInfo.Url = $u }
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
                    if ($null -ne $DownloadInfo) { $DownloadInfo.Url = $u }
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
                        if ($null -ne $DownloadInfo) { $DownloadInfo.Url = $au }
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
                            if ($null -ne $DownloadInfo) { $DownloadInfo.Url = $au }
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

    # Fall back to .NET instead of Expand-Archive.
    #
    # !!! WHY NOT Expand-Archive (found 2026-08-20 in a real run):
    # the cmdlet decides by FILE EXTENSION, not by content. A file
    # with clean zip content under a different name is rejected with
    # "'.bin' is not a supported archive file format". On top of
    # that, the old condition -match '\.zip$' never let such files
    # reach this point at all - the user ended up doing it by hand
    # for no reason.
    # CAREFUL WHEN TESTING: PowerShell 7 accepts the .bin without
    # complaint, WINDOWS POWERSHELL 5.1 DOES NOT - and 5.1 is what
    # runs our installers (powershell.exe). So this is NOT
    # reproducible in a Linux container.
    # ZipFile::ExtractToDirectory looks inside the file and is
    # therefore independent of the name.
    Write-Host "  [..] Extracting $Label ..." -ForegroundColor Gray
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        if (-not (Test-Path -LiteralPath $DestinationFolder)) {
            New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
        }
        # The overwrite overload only exists from .NET 4.7.2 / PS 7 -
        # hence entry by entry, so a second run does not fail on an
        # already existing file.
        $zf = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
        try {
            foreach ($en in $zf.Entries) {
                $dest = Join-Path $DestinationFolder $en.FullName
                if ([string]::IsNullOrEmpty($en.Name)) {
                    if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
                    continue
                }
                $parent = Split-Path -Parent $dest
                if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($en, $dest, $true)
            }
        } finally { $zf.Dispose() }
        Write-Host "  [OK] Extracted: $Label" -ForegroundColor Green
        return "ok"
    } catch {
        Write-Host "  [!!] Extraction failed: $($_.Exception.Message)" -ForegroundColor Yellow
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
        [string]$Label = "archive",
        [string]$Password = ""
    )
    if (-not (Test-Path -LiteralPath $Dest)) {
        try { New-Item -ItemType Directory -Path $Dest -Force | Out-Null } catch {}
    }
    $progFile = Join-Path ([System.IO.Path]::GetTempPath()) ("7zp_" + [Guid]::NewGuid().ToString("N") + ".log")
    try {
        $extractArgs = @("x","-y","-bso0","-bsp1")
        if ($Password) { $extractArgs += "-p$Password" }
        $extractArgs += @("`"$Archive`"","-o`"$Dest`"")
        $proc = Start-Process -FilePath $SevenZip `
            -ArgumentList $extractArgs `
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
# ---- Provider-free local path construction -----------------
#
# Join-Path asks the PowerShell provider to resolve the drive. That is
# useful for registry paths, but dangerous for filesystem CANDIDATES:
# with ErrorActionPreference=Stop, merely constructing D:\Steam\... on a
# PC without a D: drive terminates the complete installer. Depot probes
# must be strings until Test-Path decides whether they exist.
#
# Do not use IO.Path.Combine here either. It applies the TEST HOST's path
# grammar. On Linux that turns a Windows candidate into D:\Steam/foo; on
# Windows it treats a POSIX test fixture differently. These helpers keep
# the grammar of the supplied base path and perform no filesystem access.
function global:Test-WindowsStylePathLexical {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    return ($Path -match '^[A-Za-z]:(?:[\\/]|$)' -or
            $Path -match '^[\\/]{2}[^\\/]' -or
            (-not $Path.StartsWith('/') -and $Path.Contains('\')))
}

function global:Test-NativeFileSystemPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $windowsHost = ([System.IO.Path]::DirectorySeparatorChar -eq '\')
    if (-not $windowsHost -and (Test-WindowsStylePathLexical $Path)) { return $false }
    return $true
}

function global:Join-PathLexical {
    param(
        [Parameter(Mandatory=$true)][string]$BasePath,
        [Parameter(Mandatory=$true)][string]$ChildPath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) { return $null }
    if ([string]::IsNullOrWhiteSpace($ChildPath)) { return $BasePath }

    $windowsStyle = Test-WindowsStylePathLexical $BasePath
    if (-not $windowsStyle -and -not $BasePath.StartsWith('/') -and -not $BasePath.Contains('/')) {
        $windowsStyle = ([System.IO.Path]::DirectorySeparatorChar -eq '\')
    }
    $separator = if ($windowsStyle) { '\' } else { '/' }
    $base = if ($windowsStyle) { $BasePath.Replace('/', '\') } else { $BasePath.Replace('\', '/') }
    $child = if ($windowsStyle) { $ChildPath.Replace('/', '\') } else { $ChildPath.Replace('\', '/') }
    $child = $child.TrimStart([char[]]"\/")

    # Preserve filesystem roots. Trimming C:\ to C: would create a
    # drive-relative path; trimming / would lose the POSIX root entirely.
    $base = $base.TrimEnd([char[]]"\/")
    if ($windowsStyle -and $base -match '^[A-Za-z]:$') { return ($base + '\' + $child) }
    if (-not $windowsStyle -and [string]::IsNullOrEmpty($base) -and $BasePath.StartsWith('/')) {
        return ('/' + $child)
    }
    if ([string]::IsNullOrEmpty($base)) { return $child }
    return ($base + $separator + $child)
}

function global:Get-PathLeafLexical {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $trimmed = $Path.TrimEnd([char[]]"\/")
    if (-not $trimmed) { return '' }
    $parts = @($trimmed -split '[\\/]')
    return [string]$parts[-1]
}

function global:Get-PathParentLexical {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    $windowsStyle = Test-WindowsStylePathLexical $Path
    $separator = if ($windowsStyle) { '\' } else { '/' }
    $normalized = if ($windowsStyle) { $Path.Replace('/', '\') } else { $Path.Replace('\', '/') }
    $trimmed = $normalized.TrimEnd([char[]]"\/")
    if ($windowsStyle -and $trimmed -match '^[A-Za-z]:$') { return '' }
    if (-not $windowsStyle -and -not $trimmed -and $normalized.StartsWith('/')) { return '' }
    $index = $trimmed.LastIndexOf($separator)
    if ($index -lt 0) { return '' }
    if ($windowsStyle -and $index -eq 2 -and $trimmed[1] -eq ':') { return $trimmed.Substring(0, 3) }
    if (-not $windowsStyle -and $index -eq 0) { return '/' }
    return $trimmed.Substring(0, $index)
}

function global:Test-LiteralPathSafe {
    param(
        [string]$Path,
        [ValidateSet('Any','Container','Leaf')][string]$PathType = 'Any'
    )
    if (-not (Test-NativeFileSystemPath $Path)) { return $false }
    try {
        if ($PathType -eq 'Container') {
            return [bool](Test-Path -LiteralPath $Path -PathType Container -ErrorAction SilentlyContinue)
        }
        if ($PathType -eq 'Leaf') {
            return [bool](Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)
        }
        return [bool](Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue)
    } catch { return $false }
}

# Validate a user-selected depot destination before a multi-gigabyte
# download is moved or copied. This is shared by every pinned-build
# installer so an absent drive, a foreign path grammar or a read-only
# parent always becomes a normal $false result, never a provider error.
function global:Test-InstallerTargetWritable {
    param([string]$TargetPath)
    if (-not (Test-NativeFileSystemPath $TargetPath)) { return $false }
    $parent = Get-PathParentLexical $TargetPath
    if (-not $parent) { return $false }
    $probe = Join-PathLexical $parent ('.pcvrhub_write_probe_' + [Guid]::NewGuid().ToString('N'))
    try {
        if (-not (Test-LiteralPathSafe -Path $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        Set-Content -LiteralPath $probe -Value 'ok' -Encoding ASCII -NoNewline -ErrorAction Stop
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        try { Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue } catch {}
        return $false
    }
}

# Return every plausible Steam Console depot location without resolving
# any drive. Registry entries and libraryfolders.vdf are authoritative;
# conventional roots are harmless fallbacks because they remain lexical
# strings. A stale VDF entry for a removed drive is therefore safe too.
function global:Get-SteamDepotProbePaths {
    param(
        [Parameter(Mandatory=$true)][string]$AppId,
        [Parameter(Mandatory=$true)][string]$DepotId,
        [string[]]$AdditionalSteamRoots = @()
    )

    $roots = @($AdditionalSteamRoots)
    $windowsHost = ([System.IO.Path]::DirectorySeparatorChar -eq '\')
    if ($windowsHost) {
        foreach ($reg in @(
            "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
            "HKLM:\SOFTWARE\Valve\Steam",
            "HKCU:\SOFTWARE\Valve\Steam"
        )) {
            try {
                $props = Get-ItemProperty -Path $reg -ErrorAction Stop
                foreach ($value in @($props.InstallPath, $props.SteamPath)) {
                    if ($value) { $roots += ([string]$value -replace '/','\') }
                }
            } catch {}
        }
        foreach ($fallback in @(
            "${env:ProgramFiles(x86)}\Steam", "${env:ProgramFiles}\Steam",
            "C:\Program Files (x86)\Steam", "C:\Program Files\Steam", "C:\Steam",
            "D:\Steam", "E:\Steam", "D:\SteamLibrary", "E:\SteamLibrary"
        )) {
            if ($fallback) { $roots += $fallback }
        }
    } else {
        $profile = [Environment]::GetFolderPath('UserProfile')
        if ($env:XDG_DATA_HOME) { $roots += (Join-PathLexical $env:XDG_DATA_HOME 'Steam') }
        if ($profile) {
            $roots += (Join-PathLexical $profile '.steam/steam')
            $roots += (Join-PathLexical $profile '.local/share/Steam')
            if ($PSVersionTable.OS -match 'Darwin') {
                $roots += (Join-PathLexical $profile 'Library/Application Support/Steam')
            }
        }
    }

    # Parse every reachable library list. Entries inside the VDF are not
    # required to exist: keeping a stale entry as a safe Test-Path probe
    # is preferable to ever resolving it with Join-Path.
    foreach ($root in @($roots | Where-Object { $_ } | Select-Object -Unique)) {
        $vdf = Join-PathLexical $root "steamapps\libraryfolders.vdf"
        if (-not (Test-LiteralPathSafe -Path $vdf -PathType Leaf)) { continue }
        try {
            foreach ($m in [regex]::Matches(
                (Get-Content -LiteralPath $vdf -Raw -ErrorAction Stop),
                '"path"\s+"([^"]+)"'
            )) {
                $library = $m.Groups[1].Value -replace '\\\\','\'
                if ($library) { $roots += $library }
            }
        } catch {}
    }

    $relative = "steamapps\content\app_$AppId\depot_$DepotId"
    return @($roots | Where-Object { $_ } | Select-Object -Unique | ForEach-Object {
        Join-PathLexical ([string]$_) $relative
    } | Select-Object -Unique)
}

# Find a completed depot among all safe candidates. GameExe may be a
# nested relative path. No provider-backed join occurs before existence
# checks, so missing drives and stale Steam libraries cannot terminate.
function global:Find-SteamDepotPath {
    param(
        [Parameter(Mandatory=$true)][string]$AppId,
        [Parameter(Mandatory=$true)][string]$DepotId,
        [string]$GameExe = "",
        [string[]]$AdditionalSteamRoots = @()
    )

    foreach ($candidate in (Get-SteamDepotProbePaths -AppId $AppId -DepotId $DepotId -AdditionalSteamRoots $AdditionalSteamRoots)) {
        if (-not (Test-LiteralPathSafe -Path $candidate -PathType Container)) { continue }
        if (-not $GameExe) { return $candidate }
        $expected = Join-PathLexical $candidate $GameExe
        if (Test-LiteralPathSafe -Path $expected -PathType Leaf) { return $candidate }
        try {
            $leaf = Get-PathLeafLexical $GameExe
            $found = Get-ChildItem -LiteralPath $candidate -Recurse -File -Filter $leaf -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { return $candidate }
        } catch {}
    }
    return $null
}

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

    # Steam roots: Windows registry/defaults or the native Linux/macOS
    # locations. Keeping this branch host-native lets the same detection
    # logic be executed by the portable regression suite.
    $steamRoots = @()
    $windowsHost = ([System.IO.Path]::DirectorySeparatorChar -eq '\')
    if ($windowsHost) {
        foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam")) {
            try { $rp = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($rp) { $steamRoots += $rp } } catch {}
        }
        try { $rp = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Valve\Steam" -ErrorAction Stop).SteamPath; if ($rp) { $steamRoots += ($rp -replace '/','\') } } catch {}
        foreach ($d in @(
            "${env:ProgramFiles(x86)}\Steam", "${env:ProgramFiles}\Steam",
            "C:\Program Files (x86)\Steam", "C:\Program Files\Steam",
            "C:\Steam", "D:\Steam", "E:\Steam", "D:\SteamLibrary", "E:\SteamLibrary"
        )) { if ($d) { $steamRoots += $d } }
    } else {
        $profile = [Environment]::GetFolderPath('UserProfile')
        if ($env:XDG_DATA_HOME) { $steamRoots += (Join-PathLexical $env:XDG_DATA_HOME 'Steam') }
        if ($profile) {
            $steamRoots += (Join-PathLexical $profile '.steam/steam')
            $steamRoots += (Join-PathLexical $profile '.local/share/Steam')
            if ($PSVersionTable.OS -match 'Darwin') {
                $steamRoots += (Join-PathLexical $profile 'Library/Application Support/Steam')
            }
        }
    }

    $libs = @()
    foreach ($root in ($steamRoots | Select-Object -Unique)) {
        if (-not (Test-LiteralPathSafe -Path $root -PathType Container)) { continue }
        $libs += $root
        $vdf = Join-PathLexical $root "steamapps\libraryfolders.vdf"
        if (Test-LiteralPathSafe -Path $vdf -PathType Leaf) {
            try {
                foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                    $lp = $m.Groups[1].Value -replace '\\\\', '\'
                    if (Test-LiteralPathSafe -Path $lp -PathType Container) { $libs += $lp }
                }
            } catch {}
        }
    }
    $libs = $libs | Select-Object -Unique

    # PRIMARY: Steam appmanifest for this AppId -> real installdir.
    if ($AppId) {
        foreach ($lib in $libs) {
            $acf = Join-PathLexical $lib "steamapps\appmanifest_$AppId.acf"
            if (Test-LiteralPathSafe -Path $acf -PathType Leaf) {
                try {
                    $mm = [regex]::Match((Get-Content $acf -Raw), '"installdir"\s+"([^"]+)"')
                    if ($mm.Success) {
                        $g = Join-PathLexical $lib "steamapps\common\$($mm.Groups[1].Value)"
                        if ($Subdir) { $g = Join-PathLexical $g $Subdir }
                        if (Test-LiteralPathSafe -Path $g -PathType Container) { return $g }
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
            if (-not (Test-LiteralPathSafe -Path $base)) { continue }
            foreach ($key in (Get-ChildItem -Path $base -ErrorAction SilentlyContinue)) {
                try {
                    $props = Get-ItemProperty -Path $key.PSPath -ErrorAction Stop
                    $gp = $props.path
                    if (-not $gp -or -not (Test-LiteralPathSafe -Path $gp -PathType Container)) { continue }
                    $leaf = Split-Path -Leaf $gp
                    $g = if ($Subdir) { Join-PathLexical $gp $Subdir } else { $gp }
                    $isMatch = $false
                    foreach ($n in $GogNames) { if (($leaf -ieq $n) -or ($props.gameName -ieq $n)) { $isMatch = $true; break } }
                    if (-not $isMatch -and $ProbeExe -and (Test-LiteralPathSafe -Path (Join-PathLexical $g $ProbeExe) -PathType Leaf)) { $isMatch = $true }
                    if ($isMatch -and (Test-LiteralPathSafe -Path $g -PathType Container)) { return $g }
                } catch {}
            }
        }
    }

    # Epic: read each installed game's REAL path from the launcher
    # manifests (%ProgramData%\Epic\EpicGamesLauncher\Data\Manifests\*.item,
    # JSON with InstallLocation). Authoritative; match by folder name.
    if ($EpicNames.Count) {
        $mfDir = Join-PathLexical $env:ProgramData "Epic\EpicGamesLauncher\Data\Manifests"
        if (Test-LiteralPathSafe -Path $mfDir -PathType Container) {
            foreach ($item in (Get-ChildItem -Path $mfDir -Filter *.item -ErrorAction SilentlyContinue)) {
                try {
                    $j = Get-Content $item.FullName -Raw | ConvertFrom-Json
                    $loc = $j.InstallLocation
                    if (-not $loc -or -not (Test-LiteralPathSafe -Path $loc -PathType Container)) { continue }
                    $leaf = Split-Path -Leaf $loc
                    $g = if ($Subdir) { Join-PathLexical $loc $Subdir } else { $loc }
                    $isMatch = $false
                    foreach ($n in $EpicNames) { if (($leaf -ieq $n) -or ($j.MandatoryAppFolderName -ieq $n)) { $isMatch = $true; break } }
                    if (-not $isMatch -and $ProbeExe -and (Test-LiteralPathSafe -Path (Join-PathLexical $g $ProbeExe) -PathType Leaf)) { $isMatch = $true }
                    if ($isMatch -and (Test-LiteralPathSafe -Path $g -PathType Container)) { return $g }
                } catch {}
            }
        }
    }

    # SECONDARY: name-based candidates across Steam / GOG / Epic.
    $cands = @()
    foreach ($n in $SteamFolderNames) {
        foreach ($lib in $libs) {
            $c = Join-PathLexical $lib "steamapps\common\$n"
            if ($Subdir) { $c = Join-PathLexical $c $Subdir }
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
            if ($root) { foreach ($n in $GogNames) { $c = Join-PathLexical $root $n; if ($Subdir) { $c = Join-PathLexical $c $Subdir }; $cands += $c } }
        }
    }
    if ($EpicNames.Count) {
        foreach ($root in @(
            "${env:ProgramFiles}\Epic Games", "${env:ProgramFiles(x86)}\Epic Games",
            "C:\Program Files\Epic Games", "C:\Epic Games", "D:\Epic Games", "E:\Epic Games",
            "D:\Program Files\Epic Games", "E:\Program Files\Epic Games"
        )) {
            if ($root) { foreach ($n in $EpicNames) { $c = Join-PathLexical $root $n; if ($Subdir) { $c = Join-PathLexical $c $Subdir }; $cands += $c } }
        }
    }
    $cands = $cands | Select-Object -Unique

    # Prefer a folder that holds the exe, then accept a folder that exists.
    if ($ProbeExe) {
        foreach ($c in $cands) { if ($c -and (Test-LiteralPathSafe -Path $c -PathType Container) -and (Test-LiteralPathSafe -Path (Join-PathLexical $c $ProbeExe) -PathType Leaf)) { return $c } }
    }
    foreach ($c in $cands) { if ($c -and (Test-LiteralPathSafe -Path $c -PathType Container)) { return $c } }
    return $null
}

# ---- Point at the game executable yourself -----------------
#
# The last resort when a game ships several files with the same
# name, or when the exe is somewhere we do not expect. Added
# 2026-08-20 after Ghostwire: Tokyo, where a launcher stub in the
# game root shares its name with the real 98 MB executable in
# Snowfall\Binaries\Win64 - the mod went next to the stub and
# RealConfig refused the folder.
#
# The automatic tie-breakers come first and are usually right.
# This exists for the case where they are not, and it asks before
# doing anything: the user confirms, Explorer opens at the game
# folder, and they drag the exe into this window. A dragged file
# arrives as its full path in quotes, which is exactly what
# Read-Host returns - no dialog needed, and it works over remote
# desktop where a file picker often does not.
#
# Returns the FULL PATH of the exe, or $null if the user declines
# or gives up. The caller decides what to do with it - normally
# Split-Path -Parent to get the folder the mod belongs in.
function global:Get-GameExeByDrop {
    param(
        [Parameter(Mandatory=$true)][string]$GameFolder,
        [string]$ExeName = "",
        [string]$GameName = "the game"
    )

    if (-not (Test-Path -LiteralPath $GameFolder)) { return $null }

    Write-Host ""
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "   Point at the game executable yourself?" -ForegroundColor Yellow
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  The mod has to sit in the SAME folder as the executable" -ForegroundColor White
    Write-Host "  that actually starts $GameName. If that is not where it" -ForegroundColor White
    Write-Host "  landed, you can point at the right file directly." -ForegroundColor White
    Write-Host ""
    Write-Host "  Explorer opens at the game folder. Find the executable -" -ForegroundColor Gray
    if ($ExeName) {
        Write-Host "  it is called $ExeName, and it is often inside a" -ForegroundColor Gray
        Write-Host "  subfolder such as Binaries\Win64 - then DRAG IT INTO" -ForegroundColor Gray
    } else {
        Write-Host "  it is often inside a subfolder such as Binaries\Win64 -" -ForegroundColor Gray
        Write-Host "  then DRAG IT INTO" -ForegroundColor Gray
    }
    Write-Host "  THIS WINDOW and press Enter." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Tip: if two files share the name, the real one is by far" -ForegroundColor DarkGray
    Write-Host "  the larger - the small one is only a launcher." -ForegroundColor DarkGray
    Write-Host ""

    # Counted, and ("" + ...) catches $null: with no console Read-Host
    # returns $null and .Trim() on it would throw (hub-wide rule).
    $answer = ""
    for ($i = 1; $i -le 20; $i++) {
        $answer = ("" + (Read-Host "  Do that now? [Y/N]")).Trim().ToLower()
        if ($answer -in @("y","yes","j","n","no")) { break }
        Write-Host "  Please answer Y or N." -ForegroundColor Yellow
    }
    if ($answer -notin @("y","yes","j")) {
        Write-Host "  Left as it is." -ForegroundColor Gray
        return $null
    }

    try { Start-Process "explorer.exe" -ArgumentList "`"$GameFolder`"" } catch {
        Write-Host "  Could not open Explorer. The folder is:" -ForegroundColor Yellow
        Write-Host "    $GameFolder" -ForegroundColor White
    }

    for ($i = 1; $i -le 5; $i++) {
        Write-Host ""
        # Dropped paths arrive wrapped in quotes - strip those, plus any
        # stray whitespace Explorer adds after the drop.
        $raw = ("" + (Read-Host "  Drop the .exe here (attempt $i/5, or press Enter to cancel)")).Trim().Trim('"').Trim()
        if (-not $raw) {
            Write-Host "  Cancelled - nothing was changed." -ForegroundColor Gray
            return $null
        }
        if (-not (Test-Path -LiteralPath $raw)) {
            Write-Host "  That path does not exist - try again." -ForegroundColor Yellow
            continue
        }
        $item = Get-Item -LiteralPath $raw -ErrorAction SilentlyContinue
        if (-not $item -or $item.PSIsContainer) {
            Write-Host "  That is a folder, not a file - drop the .exe itself." -ForegroundColor Yellow
            continue
        }
        if ($item.Extension -ne ".exe") {
            Write-Host "  That is not an .exe - drop the game executable." -ForegroundColor Yellow
            continue
        }
        # A name mismatch is a warning, not a refusal: the user may know
        # better than our catalog does, and some stores rename the exe.
        if ($ExeName -and $item.Name -ne $ExeName) {
            Write-Host "  Note: expected $ExeName but got $($item.Name)." -ForegroundColor Yellow
            $ok = ("" + (Read-Host "  Use it anyway? [Y/N]")).Trim().ToLower()
            if ($ok -notin @("y","yes","j")) { continue }
        }
        Write-Host "  [OK] Using: $($item.FullName)" -ForegroundColor Green
        Write-Host "       ($([math]::Round($item.Length / 1MB, 1)) MB)" -ForegroundColor DarkGray
        return $item.FullName
    }

    Write-Host "  Too many attempts - leaving it as it is." -ForegroundColor Yellow
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
            if ($probe -and (Test-LiteralPathSafe -Path $probe -PathType Container)) {
                $probeOk = $true
                if ($GameExe) {
                    $probeOk = Test-LiteralPathSafe -Path (Join-PathLexical $probe $GameExe) -PathType Leaf
                    if (-not $probeOk) {
                        $leaf = Get-PathLeafLexical $GameExe
                        $probeOk = [bool](Get-ChildItem -LiteralPath $probe -Recurse -File -Filter $leaf -ErrorAction SilentlyContinue | Select-Object -First 1)
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
            # Both protocol addresses: depending on the Steam build only one works.
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
                if (-not (Test-LiteralPathSafe -Path $raw -PathType Container)) {
                    Write-Host "  [XX] Path not found: $raw" -ForegroundColor Red
                    continue
                }
                if ($GameExe) {
                    $probe = Join-PathLexical $raw $GameExe
                    if (-not (Test-LiteralPathSafe -Path $probe -PathType Leaf)) {
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
#  Installed-version validation + durable stamp writer
# ============================================================
# Download fallbacks sometimes use labels such as "latest" or "cached"
# while the real release tag is unknown. Those labels must never become an
# installed version: the Hub cannot order them against a later numeric tag,
# and the game-side copy would mask a valid durable backup. Keep this rule
# in sync with VRModHub.ps1 (installers run in another process).
function global:Test-IsTrackableInstalledVersion {
    param($Version)
    if ($null -eq $Version) { return $false }
    if ($Version -isnot [string] -and $Version -isnot [ValueType] -and $Version -isnot [version]) { return $false }
    $versionText = ([string]$Version).Trim()
    if ([string]::IsNullOrWhiteSpace($versionText)) { return $false }
    return ($versionText -match '\d')
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
#  Test-ThunderstoreDependencies - find missing dependencies
# ---------------------------------------------------------------
# WHY THIS EXISTS: our Thunderstore installers carry fixed lists
# of packages. Those come from the main mod's manifest.json or from
# hand-written lists - and both only know the DIRECT dependencies, not
# what those in turn require. PEAK is exactly where this showed up:
# PEAKLib_Core requires MonoDetour_BepInEx_5 and SoftDependencyFix, and
# neither was ever installed along with it.
#
# THIS FUNCTION CHANGES NOTHING. It reads the dependencies of the given
# packages from Thunderstore and returns what is missing from the list.
# The caller decides what to do with that.
#
# INPUT: addresses of the form
#   https://thunderstore.io/package/download/<author>/<name>/<version>/
# Author and name are read from those - the installers have such lists
# anyway, so no rework of their data structures is needed.
# ---------------------------------------------------------------
#  Test-IsPayloadRelease / Select-PayloadAsset
# ---------------------------------------------------------------
# WHY THIS EXISTS: on 2026-08-13 RaYRoD-TV uploaded a release
# "hub-patch-2" to ALL of his VR ports containing SOURCE ONLY -
# BanjoKazooie-VR, MarioKart64-VR, RingRacers-VR, sm64coopdx-vr,
# SRB2-VR and StarFox64-VR. Counted on the Banjo example: 87 files,
# 324 KB, NO executable. The real package of the same series has 16
# files and 5.5 MB.
#
# An installer taking "the newest release carrying a .zip" would have
# unpacked the source - the asset carries the same project name
# (BanjoKazooie-VR-2-source.zip contains "banjo").
#
# THREE SIGNALS, all three needed because each alone is too weak:
#   1. the release tag or title looks like source
#   2. "source" (or patch/sdk/symbols/debug) in the FILE NAME
#   3. SIZE: the source packages always come in well under the real
#      ones. That also catches a future asset under a different name.
# ---------------------------------------------------------------
#  Install-MultiverseVRHub - RaYRoD-TV's own hub as a SECOND route
# ---------------------------------------------------------------
# WHAT THIS IS ABOUT: RaYRoD-TV now ships his VR ports through a small
# hub of his own (MultiverseVRHub.exe, a single file). Per his own
# announcement, future builds appear there - possibly first, possibly
# exclusively.
#
# THE PROBLEM WITH HIS HUB, and why this is the SECOND option: it
# installs the games itself, to a place WE do not know. We would know
# neither whether a game is installed nor where its exe is - "Start in
# VR" would have nothing to launch.
#
# THE SIMPLEST ANSWER: WE decide the location. The user is offered a
# path (C:\Games\Multiverse VR Hub), may change it, and from then on
# EXACTLY THAT exe is what "Start in VR" opens. We claim nothing about
# the games inside it - we only bring the user back to the place they
# launched them from.
#
# Returns: the full path of the exe, or $null.
# ============================================================
#  Confirm-ReleaseChecksum
# ------------------------------------------------------------
#  Recomputes the SHA-256 of a freshly downloaded file and holds it
#  against the value the author writes INTO THE RELEASE NOTE.
#
#  WHY FROM THE NOTE AND NOT HARD-CODED: a built-in checksum matches
#  exactly ONE build and fails on the next release - the user then sees
#  a warning although everything is fine, and learns to click it away.
#  Read from the note, the check keeps working on EVERY future build,
#  as long as the author keeps publishing it.
#
#  RETURNS (always a string, never $null):
#    "match"    - value found and equal. Carry on.
#    "mismatch" - value found and DIFFERENT. The caller MUST abort and
#                 must not run the file.
#    "none"     - no value in the note (or the file was unreadable).
#                 Not an error - there was simply nothing to compare,
#                 and the caller carries on.
#
#  The pattern is deliberately generous: file name, then 64 hex digits
#  somewhere in the next 200 characters. That covers colons, bullets,
#  code blocks and tables - every shape that occurs in release notes.
#  Case does not matter.
# ============================================================
function global:Confirm-ReleaseChecksum {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string]$AssetName,
        [string]$ReleaseBody = "",
        [string]$ReportTo    = "the author"
    )
    if (-not (Test-Path -LiteralPath $FilePath)) { return "none" }

    $expect = $null
    if ($ReleaseBody) {
        try {
            # [\s\S] instead of (?s): same effect (newlines are
            # included), but without an inline option switch - that is
            # unambiguous in every regex engine.
            $m = [regex]::Match($ReleaseBody, [regex]::Escape($AssetName) + '[\s\S]{0,200}?([0-9a-fA-F]{64})')
            if ($m.Success) { $expect = $m.Groups[1].Value.ToLower() }
        } catch { }
    }

    $got = $null
    try { $got = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch { }
    if (-not $got) { return "none" }

    $sizeB = 0
    try { $sizeB = (Get-Item -LiteralPath $FilePath).Length } catch { }

    Write-Host ""
    Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " CHECKING WHAT YOU GOT" -ForegroundColor Cyan
    Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ("   File   : {0}  ({1:N0} bytes)" -f $AssetName, $sizeB) -ForegroundColor White
    Write-Host "   SHA-256: $got" -ForegroundColor Gray

    if (-not $expect) {
        Write-Host ""
        Write-Host "   No checksum in the release note this time, so there was" -ForegroundColor Gray
        Write-Host "   nothing to compare against. You can compare it yourself" -ForegroundColor Gray
        Write-Host "   on the release page if you want to be sure." -ForegroundColor Gray
        Write-Host ""
        return "none"
    }

    Write-Host "   Author's: $expect" -ForegroundColor Gray
    Write-Host ""
    if ($got -eq $expect) {
        Write-Host "   CHECKSUM MATCHES THE AUTHOR'S RELEASE NOTE. " -ForegroundColor Black -BackgroundColor Green
        Write-Host "   The file is exactly what was published." -ForegroundColor White
        Write-Host ""
        return "match"
    }
    Write-Host "   CHECKSUM DOES NOT MATCH. " -ForegroundColor White -BackgroundColor Red
    Write-Host "   Do NOT run this file. Delete it and try again - and if it" -ForegroundColor Yellow
    Write-Host "   keeps failing, report it to $ReportTo before running it." -ForegroundColor Yellow
    Write-Host "   Expected: $expect" -ForegroundColor White
    Write-Host "   Got     : $got" -ForegroundColor White
    Write-Host ""
    return "mismatch"
}

function global:Install-MultiverseVRHub {
    param(
        [string]$DefaultDir = "C:\Games\Multiverse VR Hub",
        [switch]$Quiet
    )
    $repo    = "RaYRoD-TV/MVRH"
    $exeName = "MultiverseVRHub.exe"
    $pinned  = "https://github.com/$repo/releases/latest/download/$exeName"

    if (-not $Quiet) {
        Write-Host ""
        Write-Host "  Where should the Multiverse VR Hub live?" -ForegroundColor White
        Write-Host "  It is ONE file - it can sit anywhere, and it installs the" -ForegroundColor Gray
        Write-Host "  games itself from there." -ForegroundColor Gray
        Write-Host ""
        Write-Host "    Default: $DefaultDir" -ForegroundColor Cyan
        Write-Host ""
    }
    $dir = ""
    try { $dir = (Read-Host "  Folder (Enter for the default)").Trim().Trim('"') } catch {}
    if (-not $dir) { $dir = $DefaultDir }

    try { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
    catch {
        Write-Warn "Could not create $dir - $($_.Exception.Message)"
        return $null
    }

    # Resolve the newest build. The asset is an EXE, not a .zip -
    # Select-PayloadAsset only looks for .zip, so it does not fit here.
    $url = $pinned; $tag = "latest"; $expectHash = $null
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
        foreach ($a in @($rel.assets)) {
            if ($a.name -ieq $exeName) { $url = [string]$a.browser_download_url; $tag = [string]$rel.tag_name; break }
        }
        # RaYRoD-TV puts the SHA-256 of his files into EVERY release
        # note, in the shape "<file>, <size> bytes" followed by the hex
        # value. It is read out here and recomputed below - so the user
        # never has to reach for certutil.
        $body = [string]$rel.body
        $m = [regex]::Match($body, [regex]::Escape($exeName) + '(?s).{0,120}?([0-9a-fA-F]{64})')
        if ($m.Success) { $expectHash = $m.Groups[1].Value.ToLower() }
    } catch { }

    $dest = Join-Path $dir $exeName
    Invoke-SafeDownload -Urls @($url, $pinned) -Destination $dest -Label "Multiverse VR Hub $tag" `
        -ManualUrl "https://github.com/$repo/releases/latest" `
        -Instructions "Download $exeName from the releases page and save it as '$dest', then choose Retry."

    if (Test-Path -LiteralPath $dest) {
        # RECOMPUTE THE CHECKSUM. The author publishes it with every
        # build and tells people to run certutil - we take that off the
        # user's hands and show the result prominently.
        $gotHash = $null
        try { $gotHash = (Get-FileHash -LiteralPath $dest -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch { }
        $sizeB = 0
        try { $sizeB = (Get-Item -LiteralPath $dest).Length } catch { }
        Write-Host ""
        Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " CHECKING WHAT YOU GOT" -ForegroundColor Cyan
        Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ("   File   : {0}  ({1:N0} bytes)" -f $exeName, $sizeB) -ForegroundColor White
        if ($gotHash) { Write-Host "   SHA-256: $gotHash" -ForegroundColor Gray }
        if ($expectHash -and $gotHash) {
            Write-Host "   Author's: $expectHash" -ForegroundColor Gray
            Write-Host ""
            if ($gotHash -eq $expectHash) {
                Write-Host "   CHECKSUM MATCHES THE AUTHOR'S RELEASE NOTE. " -ForegroundColor Black -BackgroundColor Green
                Write-Host "   The file is exactly what he published." -ForegroundColor White
            } else {
                Write-Host "   CHECKSUM DOES NOT MATCH. " -ForegroundColor White -BackgroundColor Red
                Write-Host "   Do NOT run this file. Delete it and try again - and if it" -ForegroundColor Yellow
                Write-Host "   keeps failing, report it to RaYRoD-TV before running it." -ForegroundColor Yellow
                Write-Host "   Expected: $expectHash" -ForegroundColor White
                Write-Host "   Got     : $gotHash" -ForegroundColor White
                Write-Host ""
                return $null
            }
        } elseif ($gotHash) {
            Write-Host ""
            Write-Host "   No checksum in the release note this time, so there was" -ForegroundColor Gray
            Write-Host "   nothing to compare against. Compare it yourself on the" -ForegroundColor Gray
            Write-Host "   release page if you want to be sure." -ForegroundColor Gray
        }
        Write-Host ""
        Write-OK "Multiverse VR Hub $tag is at: $dest"
        return $dest
    }
    Write-Warn "$exeName is not there - nothing was installed."
    return $null
}

function global:Test-IsPayloadRelease {
    param($Release)
    if (-not $Release) { return $false }
    $txt = "$([string]$Release.tag_name) $([string]$Release.name)"
    if ($txt -match '(?i)source|hub-patch|sdk|symbols|debug-build') { return $false }
    return $true
}

function global:Select-PayloadAsset {
    param(
        $Assets,
        # Platform marker the asset MUST carry.
        [string]$PlatformPattern = '(?i)(win64|win32|windows|x64)',
        # !!! 2026-08-20: LOWERED FROM 1 MB TO 150 KB !!!
        # The old limit came from a SINGLE case - RaYRoD-TV's repos
        # put source archives next to the package, and 1 MB separated
        # the two cleanly. Those repos carry no releases at all any
        # more, so the reason is gone - but the limit stayed and threw
        # away small, perfectly valid mods (Singularity VR: 833 KB,
        # whose installer had to hunt for its asset by hand).
        # 150 KB still catches what is never a package here: checksum
        # and signature files, notes, empty archives.
        # Source archives are already excluded by NAME
        # (source|patch|sdk|symbols|debug), not by size.
        [int]$MinBytes = 153600
    )
    $zips = @($Assets | Where-Object { $_.name -match '(?i)\.zip$' })
    if ($zips.Count -eq 0) { return $null }

    $clean = @($zips | Where-Object {
        ($_.name -notmatch '(?i)source|patch|sdk|symbols|debug') -and
        ((-not $_.size) -or ([int64]$_.size -ge $MinBytes))
    })
    if ($clean.Count -eq 0) { return $null }

    # Prefer the asset carrying a platform marker, otherwise the
    # largest one - the playable package is always the biggest.
    $pick = $clean | Where-Object { $_.name -match $PlatformPattern } | Select-Object -First 1
    if (-not $pick) { $pick = $clean | Sort-Object { [int64]$_.size } -Descending | Select-Object -First 1 }
    return $pick
}

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
    # Never report the mod loader - it is at the top of every list
    # anyway and the installers handle it separately.
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
            # Split "namespace-name-version" from the END: the name may
            # itself may contain hyphens, the version may not.
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
    # THE COMMA BEFORE THE RETURN IS NOT A TYPO: PowerShell unwraps an
    # array holding EXACTLY ONE element when returning it. The caller
    # would then get the hashtable itself - and .Count would be the
    # number of its KEYS instead of 1. That is exactly what caught me
    # during testing. The comma forces an array.
    return ,$missing
}

# Report the result in one consistent shape. Deliberately a WARNING
# and not an abort: if something is missing the mod often still runs -
# just not completely.
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
        $Version,
        [switch]$Second
    )
    if ([string]::IsNullOrWhiteSpace($GameDir)) { return $false }
    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { return $false }
    if (-not (Test-Path -LiteralPath $GameDir)) { return $false }
    # Same literal as Get-GameStampPath in VRModHub.ps1 - installers run in
    # their own process and never load that file, so the name is repeated
    # here on purpose. Change one, change the other.
    $name = ".pcvrhub_version"
    if ($Second) { $name = "$name" + "_b" }
    try {
        [System.IO.File]::WriteAllText(
            ([IO.Path]::Combine($GameDir, $name)), ([string]$Version).Trim(),
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
# ---------------------------------------------------------------
#  Find-PredownloadedFile
# ---------------------------------------------------------------
#  !!! 2026-08-20 - THIS FUNCTION WAS TOO TRUSTING !!!
#  It offered any file whose NAME roughly matched. An old
#  "SomeMod-1.2.zip" sitting in the downloads folder therefore
#  looked just as good as the current release - the user confirmed,
#  and the installer put an outdated mod in place. From the outside
#  that looked like a broken update; in truth it was never the
#  current package.
#
#  FROM NOW ON THE CALLER MUST SAY WHAT IT EXPECTS:
#    -ExpectedName   exact file name of the current release
#    -ExpectedSize   size in bytes (from the release data)
#    -ExpectedSha256 checksum, when the author publishes one
#  If any of those does not match, the file is NOT offered - what
#  was found and why it is unsuitable is stated, and the download
#  proceeds normally.
#
#  WITH NO EXPECTATION AT ALL THERE IS NO SUGGESTION ANY MORE.
#  Anyone who still wants the reuse must pass -AllowUnverified and
#  then gets a clear warning. That is deliberate: better one
#  download too many than a wrong build in the game folder.
# ---------------------------------------------------------------
function global:Find-PredownloadedFile {
    param(
        [Parameter(Mandatory=$true)][string[]]$Patterns,
        [string]$Label = "the download",
        [string[]]$ExtraFolders = @(),
        [int]$MaxAgeDays = 0,         # 0 = no age limit
        [string]$ExpectedName = "",
        [long]$ExpectedSize = 0,
        # !!! THINK TWICE BEFORE SETTING THIS, AND CURRENTLY NOBODY DOES.
        # Slack in percent around $ExpectedSize. It sounds harmless and
        # is not: five percent of a 150 MB archive is a 15 MB window, and
        # anyone who has updated a mod a few times has an OLDER build of
        # it sitting in Downloads - very likely inside that window. The
        # file would then be offered as if it were the current release.
        #
        # A missed match costs one drag-and-drop. A wrong archive
        # accepted costs a working install. Leave it at 0 unless the
        # size genuinely cannot be known, and even then prefer no
        # search at all over a loose one.
        [int]$SizeTolerancePercent = 0,
        [string]$ExpectedSha256 = "",
        [switch]$AllowUnverified,
        # Set this on the SECOND pass, after the download page has already
        # been opened. There is no download left to skip at that point, and
        # saying so would suggest this is some additional, separate file.
        [switch]$PageAlreadyOpen
    )

    # No expectation and no explicit opt-in -> do not even search.
    # Silently, so nobody thinks they did something wrong.
    if ((-not $ExpectedName) -and ($ExpectedSize -le 0) -and (-not $ExpectedSha256) -and (-not $AllowUnverified)) {
        return $null
    }

    # When an exact name is known, ONLY that counts. The loose
    # patterns are meaningless then - they were the problem.
    if ($ExpectedName) { $Patterns = @($ExpectedName) }
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

    # ---- Cross-check: is this really the current release? --------
    $reject = $null
    if ($ExpectedName -and ($hit.Name -ne $ExpectedName)) {
        $reject = "the file is called '$($hit.Name)', expected '$ExpectedName'"
    }
    if ((-not $reject) -and ($ExpectedSize -gt 0)) {
        $slack = if ($SizeTolerancePercent -gt 0) { [long][Math]::Ceiling($ExpectedSize * ($SizeTolerancePercent / 100.0)) } else { 0 }
        $delta = [Math]::Abs($hit.Length - $ExpectedSize)
        if ($delta -gt $slack) {
            $reject = if ($slack -gt 0) { "it is $($hit.Length) bytes, expected about $ExpectedSize" }
                      else { "it is $($hit.Length) bytes, expected $ExpectedSize" }
        }
    }
    if ((-not $reject) -and $ExpectedSha256) {
        $got = $null
        try { $got = (Get-FileHash -LiteralPath $hit.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch {}
        if ($got -ne $ExpectedSha256.ToLower()) { $reject = "its checksum does not match the published one" }
    }
    if ($reject) {
        Write-Host ""
        Write-Host "  There is a file in your downloads that looks like $Label," -ForegroundColor Gray
        Write-Host "  but it is NOT the current release - $reject." -ForegroundColor Gray
        Write-Host "    $($hit.Name)" -ForegroundColor DarkGray
        Write-Host "  Downloading the correct one instead." -ForegroundColor Gray
        return $null
    }

    $sizeTxt = if ($hit.Length -ge 1GB) { "{0:N2} GB" -f ($hit.Length / 1GB) } else { "{0:N1} MB" -f ($hit.Length / 1MB) }
    Write-Host ""
    Write-Host "  Found what looks like $Label already on disk:" -ForegroundColor Cyan
    Write-Host "    $($hit.Name)" -ForegroundColor White
    Write-Host "    $sizeTxt   $($hit.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor DarkGray
    Write-Host "    in $($hit.DirectoryName)" -ForegroundColor DarkGray
    Write-Host ""
    if ($AllowUnverified -and (-not $ExpectedName) -and ($ExpectedSize -le 0) -and (-not $ExpectedSha256)) {
        Write-Host "  [!] This could not be checked against the current release -" -ForegroundColor Yellow
        Write-Host "      only the name looks right. If the mod misbehaves later," -ForegroundColor Yellow
        Write-Host "      answer N here and let it download fresh." -ForegroundColor Yellow
        Write-Host ""
    }
    $question = if ($PageAlreadyOpen) { "  Use this file? [Y/N]" } else { "  Use this file and skip the download? [Y/N]" }
    # ("" + ...) catches a closed input - Read-Host then returns
    # $null and .Trim() on it would throw.
    $ans = ("" + (Read-Host $question)).Trim().ToUpper()
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

# ---------------------------------------------------------------
#  Save-InstalledStamp
# ---------------------------------------------------------------
#  Writes the installed version to BOTH places the Hub looks at:
#    <Core>\<Installer>\.installed_version   - convenient, but it is
#         INSIDE THE HUB FOLDER and therefore GONE the moment the user
#         drops in a new Hub build.
#    <GameDir>\.pcvrhub_version              - lives with the game and
#         survives a Hub update. Read-InstalledVersion prefers it.
#
#  !!! WHY THIS EXISTS (2026-08-20): 29 installers wrote only the Hub
#  copy. After every Hub update those markers were gone, the next scan
#  found none, and the seeding branch then recorded THE CURRENT ONLINE
#  TAG as "installed" - which silently swallowed a pending update. That
#  is why an Update badge could be there one day and gone after
#  installing a new Hub, without anything having been updated.
function global:Save-InstalledStamp {
    # $GameDir takes ONE folder or SEVERAL. Several matter for the mods
    # that do not live in the game folder: Red Faction installs into its
    # own "Alpine Faction VR" directory, World at War into a program
    # folder of its own. The scan reads the stamp from wherever it
    # resolved the mod, and guessing wrong means no stamp at all - so
    # both candidates get one. A stamp in a folder nobody reads is a
    # harmless dotfile; a missing one brings back the swallowed update.
    param($GameDir, $Version, [string]$HubDir)

    if (-not (Test-IsTrackableInstalledVersion -Version $Version)) { return }
    $val = ([string]$Version).Trim()
    $enc = New-Object System.Text.UTF8Encoding $false

    $targets = @()
    foreach ($d in @($GameDir)) {
        if ([string]::IsNullOrWhiteSpace($d)) { continue }
        # Provider-independent: does not require a dead drive letter to be
        # mounted, and uses the host separator so the regression suite also
        # works outside Windows.
        $t = [IO.Path]::Combine(([string]$d), ".pcvrhub_version")
        if ($targets -notcontains $t) { $targets += $t }
    }
    if (-not [string]::IsNullOrWhiteSpace($HubDir)) {
        $targets += [IO.Path]::Combine($HubDir, ".installed_version")
    }
    foreach ($t in $targets) {
        try { [System.IO.File]::WriteAllText($t, $val, $enc) } catch {}
    }
}

# ---------------------------------------------------------------
#  Expand-NestedArchive
# ---------------------------------------------------------------
#  Some publishers ship ONE download that only contains further
#  zips. Mass Effect is the case that forced this (2026-08-20):
#  MELE-VR.zip holds MELE1VR.zip, MELE2VR.zip and MELE3VR.zip -
#  one per game - so an installer that unpacks the outer file and
#  looks for its own payload finds three archives and nothing else.
#
#  Given the already-extracted folder and a file that must exist in
#  the payload, this returns the folder that really holds it:
#    - payload directly in the folder    -> that folder
#    - inside a wrapper folder           -> the wrapper
#    - inside one of several inner archives -> unpacks the RIGHT one
#  Returns $null when no inner archive carries the marker, so the
#  caller can fail with a clear message instead of copying nothing.
function global:Expand-NestedArchive {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$Marker,
        [string]$Label = "the package"
    )

    if (-not (Test-Path -LiteralPath $Root)) { return $null }

    # 1. Already there.
    if (Test-Path -LiteralPath "$($Root.TrimEnd('\'))\$Marker") { return $Root }

    # 2. A wrapper folder somewhere below.
    $hit = Get-ChildItem -LiteralPath $Root -Recurse -Filter (Split-Path $Marker -Leaf) -ErrorAction SilentlyContinue |
           Select-Object -First 1
    if ($hit) { return $hit.DirectoryName }

    # 3. Inner archives. Unpack each into its own folder and keep the
    #    one that carries the marker - never the first one blindly,
    #    because the sibling zips belong to the OTHER games.
    # Try the archive whose NAME already looks like the marker first, so
    # the common case unpacks ONE inner zip instead of all of them. The
    # loop still falls through to the rest, so a misleading name costs
    # nothing - it just is not tried first.
    $stem = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $Marker -Leaf))
    $archives = @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
              Where-Object { [IO.Path]::GetExtension($_.Name).ToLower() -in @('.zip','.7z','.rar') } |
              Sort-Object @{ Expression = {
                  $n = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                  # 0 sorts first: exact-ish name match on either side.
                  if (($n -replace '[^a-zA-Z0-9]','') -like "*$($stem -replace '[^a-zA-Z0-9]','')*") { 0 } else { 1 }
              } }, Name)
    foreach ($archive in $archives) {
        $sub = Join-Path $Root ("_inner_" + [System.IO.Path]::GetFileNameWithoutExtension($archive.Name))
        try {
            New-Item -ItemType Directory -Path $sub -Force -ErrorAction Stop | Out-Null
            $r = Expand-ArchiveOrFallback -ArchivePath $archive.FullName -DestinationFolder $sub -Label "$Label ($($archive.Name))"
            if ([string]$r -ne "ok" -and [string]$r -ne "manual") { continue }
        } catch { continue }

        if (Test-Path -LiteralPath "$($sub.TrimEnd('\'))\$Marker") { return $sub }
        $deep = Get-ChildItem -LiteralPath $sub -Recurse -Filter (Split-Path $Marker -Leaf) -ErrorAction SilentlyContinue |
                Select-Object -First 1
        if ($deep) { return $deep.DirectoryName }
    }
    return $null
}

# ---------------------------------------------------------------
#  Test-ArchiveContains
# ---------------------------------------------------------------
#  Looks INSIDE a zip and says whether it carries an entry whose
#  name matches - without extracting anything.
#
#  !!! WHY THIS EXISTS (2026-08-20): a filename is not proof. The
#  Mass Effect installer offered MELE2-VR.zip while installing
#  ME3, because its search pattern still matched the sibling
#  game's download sitting in the same Downloads folder. Accepting
#  it would have copied one game's mod into another game's folder.
#  A name can be wrong, renamed by a browser, or belong to a
#  neighbouring product; what is INSIDE cannot.
#
#  Pass -Entry as a wildcard ("MELE3VR.zip", "*MELE3-VR.bat").
#  Returns $true only when the archive really holds it.
function global:Test-ArchiveContains {
    param(
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [Parameter(Mandatory=$true)][string]$Entry
    )

    if (-not (Test-Path -LiteralPath $ArchivePath)) { return $false }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $za = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
        try {
            foreach ($e in $za.Entries) {
                # Match the bare name as well as the full path, so an
                # entry inside a wrapper folder still counts.
                if (($e.Name -like $Entry) -or ($e.FullName -like $Entry) -or ($e.FullName -like "*/$Entry")) {
                    return $true
                }
            }
        } finally { $za.Dispose() }
    } catch {
        # Not a readable zip - treat as "cannot confirm", never as yes.
        return $false
    }
    return $false
}

# ---------------------------------------------------------------
#  Antivirus: the warning up front, and the explanation afterwards
# ---------------------------------------------------------------
# WHY THIS EXISTS. A VR mod hooks into a running game, and the file that
# does it is almost never signed. That is the same shape as an injector,
# so a handful of scanners flag some of these mods. It is a false
# positive in practice - but WE CANNOT PROMISE THAT, and this text must
# never say "safe". It says what the mod does and why a scanner reacts.
#
# The second half matters more than the first: when a scanner removes a
# file mid-install, the mod simply does not work and nothing explains
# why. Show-AntivirusFileLoss turns that silence into an answer.

# ONE WORDING, TWO SHAPES. Some installers open with a full-screen
# intro box that is already crowded - there the notice has to fit INSIDE
# the box rather than add five lines under it. So the text lives here
# once and can be fetched as lines; Show-AntivirusNotice just prints
# them. Short form for a box, long form for open screen.
function global:Get-AntivirusNoticeLines {
    param([switch]$Short)
    if ($Short) {
        # 56 characters is what Write-Box pads to - keep inside that.
        return @(
            "Some VR mods inject into the game or use unsigned",
            "executables, so a few antivirus tools flag them -",
            "usually a false positive. If a file disappears during",
            "this install, the installer says so and shows you how",
            "to add a folder exclusion."
        )
    }
    return @(
        "Some VR mods inject into the game and/or are built on unsigned",
        "executables, so a few antivirus tools may flag them - usually as",
        "a false positive. After placing the mod, this installer waits",
        "three seconds and checks it again. If files disappear, it shows",
        "the active antivirus and the folder-exclusion steps."
    )
}

function global:Show-AntivirusNotice {
    # !!! DARKGRAY THROUGHOUT, HEADING INCLUDED. This concerns a minority
    # of readers, and in white-on-grey it competed with the things
    # everyone has to read - on a long intro page it was one more block
    # that looked like all the others. Quiet, present, skippable.
    Write-Host ""
    Write-Host "  A note on antivirus software" -ForegroundColor DarkGray
    foreach ($l in (Get-AntivirusNoticeLines)) { Write-Host "  $l" -ForegroundColor DarkGray }
    Write-Host ""
}

# SecurityCenter2 retains disabled and passive products as well as the
# product that is protecting the machine right now. The 0x1000 bit in
# productState is the real-time-enabled flag; without this filter the first
# registered entry can easily be dormant Defender instead of the third-party
# scanner that actually removed the file.
function global:Test-AntivirusProductActive {
    param($ProductState)
    if ($null -eq $ProductState) { return $false }
    try {
        $state = [int64]$ProductState
        return (($state -band 0x1000) -eq 0x1000)
    } catch { return $false }
}

function global:Get-ActiveAntivirusNames {
    $products = @()
    try {
        $products = @(Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction Stop)
    } catch {}

    # SecurityCenter2 can be access-restricted by policy. Windows mirrors the
    # same provider records under this read-only registry key, including the
    # same product-state value, so detection still works without elevation.
    if ($products.Count -eq 0) {
        try {
            $products = @(Get-ChildItem -LiteralPath "HKLM:\SOFTWARE\Microsoft\Security Center\Provider\Av" -ErrorAction Stop |
                ForEach-Object {
                    $p = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop
                    [pscustomobject]@{ displayName=$p.DisplayName; productState=$p.State }
                })
        } catch {}
    }

    $active = @($products | Where-Object { $_.displayName -and (Test-AntivirusProductActive -ProductState $_.productState) })
    if ($active.Count -gt 0) {

        # If two engines really are active, show both. Put third-party tools
        # before Microsoft Defender so their instructions are not hidden by a
        # passive-looking Defender entry on unusual Security Center builds.
        return @($active |
            Sort-Object @{ Expression = { if ($_.displayName -match '(?i)windows defender|microsoft defender') { 1 } else { 0 } } }, displayName |
            Select-Object -ExpandProperty displayName -Unique)
    }
    return @()
}

function global:Get-ActiveAntivirusName {
    $names = @(Get-ActiveAntivirusNames)
    if ($names.Count -gt 0) { return ($names -join ', ') }
    return $null
}

# Call this when a file that WAS written is no longer there.
function global:Show-AntivirusFileLoss {
    param([string]$What, [string]$GameDir)
    Write-Host ""
    Write-Host "  A FILE WAS INSTALLED AND IS NOW GONE. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "  Missing: $What" -ForegroundColor White
    $av = Get-ActiveAntivirusName
    if ($av) {
        Write-Host "  Your antivirus ($av) most likely quarantined it." -ForegroundColor White
    } else {
        Write-Host "  An antivirus tool most likely quarantined it." -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  What to do:" -ForegroundColor White
    Write-Host "   1. Open your antivirus and restore the file from quarantine," -ForegroundColor Gray
    Write-Host "      or add an EXCLUSION for this folder:" -ForegroundColor Gray
    if ($GameDir) { Write-Host "        $GameDir" -ForegroundColor DarkGray }
    Write-Host "   2. Then run this installer again. With the folder excluded" -ForegroundColor Gray
    Write-Host "      the files are written straight into protected ground." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Alternatively, if you don't want to do that, you can simply leave" -ForegroundColor DarkGray
    Write-Host "  it here. Nothing further will be changed." -ForegroundColor DarkGray
    Write-Host ""
    # NOT AUTOMATED ON PURPOSE. Adding an exclusion from a script is
    # exactly what malware does to clear its own path, and doing it would
    # get the Hub flagged far harder than any mod. We open the page at
    # most; the user decides.
    if ($av -and ($av -match '(?i)windows defender|microsoft defender') -and ($av -notmatch '(?i)bitdefender')) {
        Write-Host "   Defender: Settings > Privacy & security > Windows Security >" -ForegroundColor DarkGray
        Write-Host "   Virus & threat protection > Manage settings > Exclusions" -ForegroundColor DarkGray
        Write-Host ""
    }
}

# ---------------------------------------------------------------
#  Did the files we just wrote survive?
# ---------------------------------------------------------------
# A scanner does not always strike while the file is being written. It
# often sweeps a moment later, and the file is gone AFTER the installer
# has already reported success. So the check waits, looks again, and if
# something vanished it walks the user through an exclusion and copies
# the files a second time.
#
# WHERE THE EXCLUSION IS SET, per product. Only the menu path - the Hub
# never sets an exclusion itself. Doing that from a script is what
# malware does to clear its own way, and it would get the Hub flagged
# far harder than any mod ever could.
$global:AV_EXCLUSION_PATHS = @{
    'defender'    = 'Windows Security > Virus & threat protection > Manage settings > Add or remove exclusions > Add an exclusion > Folder (the installer can open this for you)'
    'bitdefender' = 'Bitdefender > Protection > Antivirus > Open > Settings > Manage Exceptions > + Add an Exception > choose the folder > enable Antivirus > Save'
    'kaspersky'   = 'Kaspersky > Settings (gear) > Security settings > Threats and exclusions > Manage exclusions > Add > choose the folder'
    'avast'       = 'Avast > Menu > Settings > General > Exceptions > Add exception > File / Folder > choose the folder > Add'
    'avg'         = 'AVG > Menu > Settings > General > Exceptions > Add exception > File / Folder > choose the folder > Add'
    'norton'      = 'Norton > Security > Advanced Security > Computer > Antivirus > Exclusions > Add > choose the folder'
    'eset'        = 'ESET > press F5 (Advanced setup) > Scan > Performance Exclusions > Edit > Add > choose the folder > OK'
    'mcafee'      = 'McAfee > My Protection > Real-Time Scanning > Excluded files. If your edition offers Add folder, choose this folder; otherwise restore and exclude each reported file (some McAfee consumer editions have no real-time folder exclusion)'
    'malwarebytes'= 'Malwarebytes > Detection History > Allow list > Add item > select Folder > choose the folder > Save'
}

function global:Get-AvExclusionPath {
    param([string]$Name)
    if (-not $Name) { return $null }
    $n = $Name.ToLower()
    # !!! BITDEFENDER BEFORE DEFENDER. "bitdefender" contains "defender",
    # so testing defender first handed every Bitdefender user Microsoft's
    # menu path - a wrong instruction is worse than none.
    foreach ($k in @('bitdefender','malwarebytes','kaspersky','avast','avg','norton','eset','mcafee','defender')) {
        if ($n -match $k) { return $global:AV_EXCLUSION_PATHS[$k] }
    }
    return $null
}

# Put the files back FROM INSIDE the game folder. Generic, so that no
# installer has to hand-roll it: the archive is copied onto excluded
# ground, unpacked THERE, and each missing file is fetched out of it by
# name. ZIP, 7z and RAR all use the Hub's normal extractor. A package that
# contains a second archive (BF42++ does) is opened one level further as
# needed. The staging folder is removed afterwards either way.
function global:Restore-FromArchiveInGameFolder {
    param([string]$ArchivePath, [string]$GameDir, [string[]]$Paths)
    if (-not $GameDir) {
        Write-Warn "No exclusion folder was supplied, so the files cannot be restored safely."
        return $false
    }
    if (-not $ArchivePath -or -not (Test-Path -LiteralPath $ArchivePath)) {
        Write-Warn "The downloaded archive is gone as well - run the installer again once the exclusion is set."
        return $false
    }
    $stage = Join-Path $GameDir "_pcvrhub_restage"
    $restored = $false
    try {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
        $sourceDir = Join-Path $stage "source"
        $contentDir = Join-Path $stage "content"
        New-Item -ItemType Directory -Path $sourceDir,$contentDir -Force | Out-Null

        # The archive itself is now on excluded ground BEFORE it is opened.
        # Preserve its extension so 7-Zip can identify .7z/.rar immediately;
        # the central extractor also inspects ZIP content when the name has no
        # useful extension.
        $localArchive = Join-Path $sourceDir ("package" + [IO.Path]::GetExtension($ArchivePath))
        Copy-Item -LiteralPath $ArchivePath -Destination $localArchive -Force -ErrorAction Stop
        $unpack = Expand-ArchiveOrFallback -ArchivePath $localArchive -DestinationFolder $contentDir `
                    -Label "antivirus recovery package" -AllowSkip $false
        if ([string]$unpack -ne "ok" -and [string]$unpack -ne "manual") {
            Write-Warn "The package could not be unpacked inside the excluded folder."
            return $false
        }

        # If a watched file is not in the outer package, open the matching
        # inner archive. This is intentionally marker-driven: sibling archives
        # for other games must never be unpacked blindly.
        foreach ($want in $Paths) {
            if (Test-Path -LiteralPath $want) { continue }
            $leaf = Split-Path -Leaf $want
            $hit = Get-ChildItem -LiteralPath $contentDir -Filter $leaf -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $hit) {
                [void](Expand-NestedArchive -Root $contentDir -Marker $leaf -Label "antivirus recovery package")
            }
        }

        foreach ($want in $Paths) {
            if (Test-Path -LiteralPath $want) { continue }
            $leaf = Split-Path -Leaf $want
            $hit  = Get-ChildItem -LiteralPath $contentDir -Filter $leaf -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $hit) { continue }
            $dir = Split-Path -Parent $want
            if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Copy-Item -LiteralPath $hit.FullName -Destination $want -Force -ErrorAction Stop
        }
        $restored = (@($Paths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0)
    } catch {
        Write-Warn "Could not put the files back: $($_.Exception.Message)"
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    }
    return $restored
}

function global:Confirm-PlacedFilesSurvive {
    param(
        [string[]]$Paths,          # files that must still be there
        [string]$GameDir,          # what the user should exclude
        [scriptblock]$Recopy,      # optional: installer-specific recovery
        [string]$ArchivePath,      # or just the archive - handled generically
        [int]$WaitSeconds = 3
    )
    if (-not $Paths -or $Paths.Count -eq 0) { return $true }
    Start-Sleep -Seconds $WaitSeconds
    $gone = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($gone.Count -eq 0) { return $true }

    Write-Host ""
    Write-Host "  FILES THAT WERE JUST PLACED HAVE DISAPPEARED. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    foreach ($g in ($gone | Select-Object -First 6)) { Write-Host "    $g" -ForegroundColor DarkGray }
    if ($gone.Count -gt 6) { Write-Host "    ... and $($gone.Count - 6) more" -ForegroundColor DarkGray }
    Write-Host ""
    $avNames = @(Get-ActiveAntivirusNames)
    $av = if ($avNames.Count -gt 0) { $avNames -join ', ' } else { $null }
    if ($av) { Write-Host "  The cause is most likely your antivirus. You are running: $av" -ForegroundColor White }
    else      { Write-Host "  The cause is most likely an antivirus tool on this machine." -ForegroundColor White }
    Write-Host "  It flagged one of the mod's files - almost always a false positive." -ForegroundColor Gray
    Write-Host ""

    $guidance = @()
    foreach ($avName in $avNames) {
        $howTo = Get-AvExclusionPath -Name $avName
        if ($howTo) { $guidance += [pscustomobject]@{ Name=$avName; Path=$howTo } }
    }
    if ($guidance.Count -gt 0) {
        Write-Host "  Where to add the exclusion:" -ForegroundColor White
        foreach ($guide in $guidance) {
            Write-Host "    $($guide.Name): $($guide.Path)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Add a FOLDER exclusion in your antivirus for the path below." -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  The folder to exclude:" -ForegroundColor White
    Write-Host "    $GameDir" -ForegroundColor Cyan
    $copied = $false
    try { Set-Clipboard -Value $GameDir -ErrorAction Stop; $copied = $true } catch {}
    if ($copied) { Write-Host "    (already on your clipboard - just paste it)" -ForegroundColor DarkGray }
    Write-Host ""

    # Same trap here: only MICROSOFT's Defender has that settings page.
    # THE WAY OUT IS NAMED, IN GREY. Adding an exclusion is a real
    # security decision and it is not ours to push. Whoever would rather
    # not do it must be able to see that stopping here is a normal
    # choice, not a failure - so it is said plainly, and said quietly.
    Write-Host "  Alternatively, if you don't want to do that, you can close the" -ForegroundColor DarkGray
    Write-Host "  installer at this point. Nothing further will be changed." -ForegroundColor DarkGray
    Write-Host ""

    $microsoftDefenderActive = (@($avNames | Where-Object { $_ -match '(?i)windows defender|microsoft defender' }).Count -gt 0)
    if ($microsoftDefenderActive) {
        # windowsdefender://exclusions lands on the exclusion list ITSELF,
        # not on the Windows Security overview - five clicks saved. Only
        # Microsoft's Defender has such a handler; the third-party tools
        # below have no equivalent, so for those we can only say where to
        # look.
        Pause-User "Press Enter to open the exclusion list, then add the folder..."
        try { Start-Process "windowsdefender://exclusions" } catch {
            try { Start-Process "ms-settings:windowsdefender" } catch {}
        }
    } else {
        Pause-User "Press Enter once you have opened your antivirus..."
    }

    Pause-User "Press Enter when the exclusion is set - the files are then copied again..."
    $restoreAttempted = $false
    if ($Recopy) {
        # !!! THE SECOND ATTEMPT MUST HAPPEN INSIDE THE EXCLUDED FOLDER.
        # The exclusion the user just added covers the GAME folder - it
        # does not cover %TEMP%. So a Recopy block that pulls from a temp
        # staging folder can fail twice over: the scanner may have taken
        # the source there as well, and it will keep taking it. Every
        # Recopy block therefore has to fetch or unpack into a folder
        # UNDER $GameDir, which is now protected ground.
        Write-Host "  Putting the files back - this time from inside the excluded folder..." -ForegroundColor White
        $restoreAttempted = $true
        try { & $Recopy | Out-Null } catch { Write-Warn "The second attempt failed: $($_.Exception.Message)" }
    } elseif ($ArchivePath) {
        Write-Host "  Putting the files back - this time from inside the excluded folder..." -ForegroundColor White
        $restoreAttempted = $true
        [void](Restore-FromArchiveInGameFolder -ArchivePath $ArchivePath -GameDir $GameDir -Paths $Paths)
    }

    # A successful copy is not enough: the original problem was a delayed
    # scanner sweep. Give the second copy the same three-second survival
    # window before allowing the installer to continue.
    if ($restoreAttempted) { Start-Sleep -Seconds $WaitSeconds }
    $still = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($still.Count -eq 0) { Write-OK "The files are in place now."; return $true }
    Write-Warn "Still missing: $($still.Count) file(s). The exclusion may not cover this folder yet."
    foreach ($missing in ($still | Select-Object -First 6)) { Write-Host "    $missing" -ForegroundColor DarkGray }
    Write-Host "  Correct the folder exclusion, then run this installer again." -ForegroundColor Gray
    return $false
}


# ---------------------------------------------------------------
#  Parking two mods that share a folder
# ---------------------------------------------------------------
# Lifted out of BioshockVR-core.ps1 (2026-08-28) because Outlast now
# needs exactly the same thing: two mods that write THE SAME FILE NAMES
# into the same folder, so only one can be in place at a time.
#
# The shape: each mod keeps a full copy of its files in a store under
# _vrmods\<mod>\, and only the ACTIVE one has them lying in the game
# folder. Switching means putting the other one's files back in the
# store first - Set-ActiveMod never deletes anything it cannot restore.

function global:Fill-Store {
    param([string]$Extract, [string]$StoreDir, [string[]]$Files, [switch]$WithPreset)
    if (-not (Test-Path -LiteralPath $StoreDir)) { New-Item -ItemType Directory -Path $StoreDir -Force | Out-Null }
    $got = @(); $miss = @()
    foreach ($f in $Files) {
        $hit = Get-ChildItem -LiteralPath $Extract -Filter $f -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $hit) { $miss += $f; continue }
        try { Copy-Item -LiteralPath $hit.FullName -Destination ([System.IO.Path]::Combine($StoreDir, $f)) -Force -ErrorAction Stop; $got += $f }
        catch { $miss += $f }
    }
    if ($WithPreset) {
        # The bundled calibration travels with the store, not into the game
        # folder - it belongs in %LOCALAPPDATA%\BioshockVR and only if the
        # user wants it. The README explains that.
        # SINCE v0.7.0 THE ZIP CARRIES TWO CALIBRATIONS: preset-bs1\ for this
        # game and preset-bs2\ for BioShock 2, with the SAME file names
        # (vrpreset.ini, weapons.ini, HOW-TO-USE.txt). A plain recursive
        # search with "first hit wins" could therefore drop BioShock 2's
        # tuning into BioShock 1's store. Prefer a bs1 folder, and only fall
        # back to a loose file when no bs1 folder exists (older releases had
        # the presets in "preset\" or at the root).
        foreach ($p in @("vrpreset.ini","hands.ini","weapons.ini","HOW-TO-USE.txt","README.txt")) {
            $all = @(Get-ChildItem -LiteralPath $Extract -Filter $p -Recurse -File -ErrorAction SilentlyContinue)
            if ($all.Count -eq 0) { continue }
            $hit = $all | Where-Object { $_.DirectoryName -match '(?i)preset[-_]?bs1' } | Select-Object -First 1
            if (-not $hit) { $hit = $all | Where-Object { $_.DirectoryName -notmatch '(?i)bs2' } | Select-Object -First 1 }
            if (-not $hit) { continue }
            try { Copy-Item -LiteralPath $hit.FullName -Destination ([System.IO.Path]::Combine($StoreDir, $p)) -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
    return [pscustomobject]@{ Copied = $got; Missing = $miss }
}

function global:Set-ActiveMod {
    param([string]$BuildDir, [string]$StoreDir, [string[]]$Files, [string[]]$OtherFiles, [string]$OtherStore)
    foreach ($f in $OtherFiles) {
        if ($Files -contains $f) { continue }
        $victim = [System.IO.Path]::Combine($BuildDir, $f)
        if (-not (Test-Path -LiteralPath $victim)) { continue }
        if (-not $OtherStore) { continue }
        $keep = [System.IO.Path]::Combine($OtherStore, $f)
        # ONLY DELETE WHAT CAN BE PUT BACK. If the file is not yet in
        # the other mod's store, it is SAVED THERE FIRST and removed
        # afterwards.
        # WHY THIS BECAME NECESSARY: since BioVRDev 1.0.3
        # openxr_loader.dll is only created BY THE SETUP - it is in no
        # archive and therefore never reached the store. Without this
        # safeguard the old lock applied, the file stayed put when
        # switching, and balouza ran alongside a foreign OpenXR
        # loader.
        if (-not (Test-Path -LiteralPath $keep)) {
            try {
                $keepDir = Split-Path -Parent $keep
                if ($keepDir -and -not (Test-Path -LiteralPath $keepDir)) {
                    New-Item -ItemType Directory -Path $keepDir -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Copy-Item -LiteralPath $victim -Destination $keep -Force -ErrorAction Stop
            } catch { continue }   # cannot be backed up -> do not delete either
        }
        try { Remove-Item -LiteralPath $victim -Force -ErrorAction Stop } catch {}
    }
    $ok = $true
    $failed = @()
    foreach ($f in $Files) {
        $src = [System.IO.Path]::Combine($StoreDir, $f)
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dest = [System.IO.Path]::Combine($BuildDir, $f)
        try {
            # .hubbak means "the file YOU had before the Hub touched it".
            # It must never be made from the OTHER mod's file: BioshockVR.dll
            # and bioshockvr.dll are the same name on Windows, so without
            # this guard every switch parked a 3 MB copy of the other mod's
            # payload as BioshockVR.dll.hubbak - junk that also lied about
            # what it was. -contains is case-insensitive, which is exactly
            # what catches the collision.
            $isOtherModsFile = ($OtherFiles -contains $f)
            if ((Test-Path -LiteralPath $dest) -and -not $isOtherModsFile -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
                Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
            }
            # Since 1.0.3 one file also lives in a SUBFOLDER
            # (logs\CollectLogs.bat). Copy-Item does not create it.
            $destDir = Split-Path -Parent $dest
            if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Copy-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
        } catch { $ok = $false; $failed += $f }
    }
    if ($failed.Count -gt 0) {
        Write-Fail "Could not write: $($failed -join ', ')"
        Write-Warn "That usually means the game is still running. Close it and run this installer again."
    }
    return $ok
}

function global:Import-LegacyInstall {
    param([string]$BuildDir, [string]$StoreDir, [string[]]$Files, [string]$Marker)
    $taken = @()
    if ($Marker -and -not (Test-Path -LiteralPath ([System.IO.Path]::Combine($BuildDir, $Marker)))) { return $taken }
    foreach ($f in $Files) {
        $loose = [System.IO.Path]::Combine($BuildDir, $f)
        if (-not (Test-Path -LiteralPath $loose)) { continue }
        $inStore = [System.IO.Path]::Combine($StoreDir, $f)
        if (Test-Path -LiteralPath $inStore) { continue }   # store wins - it is the newer copy
        if (-not (Test-Path -LiteralPath $StoreDir)) { New-Item -ItemType Directory -Path $StoreDir -Force | Out-Null }
        try { Copy-Item -LiteralPath $loose -Destination $inStore -Force -ErrorAction Stop; $taken += $f } catch {}
    }
    return $taken
}
