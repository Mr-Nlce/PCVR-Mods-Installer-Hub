# ============================================================
#  Singularity VR - SingularityVR by letsgosportsteam
# ------------------------------------------------------------
#  The mod is a d3d9.dll PROXY: it forwards every Direct3D 9 call to
#  the real system library and renders in stereo to an OpenXR headset
#  along the way. NO game file is modified - three files land next to
#  Singularity.exe, and uninstalling means deleting one of them.
#
#  THREE THINGS THAT SHAPE THIS INSTALLER:
#   1. VC++ 2015-2022 x86 IS REQUIRED, not "recommended" - the proxy
#      DLL is 32 bit, and the x64 runtime almost everyone already has
#      does NOT help. Hence a step of its own with UAC.
#   2. ALL releases are prereleases. /releases/latest returns NOTHING
#      here (verified: the web redirect lands on /releases). So the
#      list is queried - the same situation as World War VR. The
#      catalog carries GithubPrerelease = $true for it.
#   3. Select-PayloadAsset does NOT fit here: it used to discard
#      everything under 1 MB and this package is 833 KB. The asset is
#      therefore picked by hand.
#
#  THE FIRST RUN IS ALWAYS AT THE WRONG RESOLUTION, and that is not a
#  fault: the mod has to set -ResX/-ResY BEFORE the engine reads the
#  command line - so before it can ask the headset anything. It asks
#  during that run and uses the answer on the next start.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Singularity VR Installer"
$ErrorActionPreference = "Stop"

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m"  -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m"  -ForegroundColor Red }
function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}

$GAME_NAME  = "Singularity"
$APP_ID     = "42670"
$GAME_EXE   = "Binaries\Singularity.exe"
$MOD_NAME   = "SingularityVR"
$MOD_AUTHOR = "letsgosportsteam"
$REPO       = "letsgosportsteam/singularity-vr-mod"
$RELEASES   = "https://github.com/$REPO/releases"
$REL_MOD    = "Binaries\d3d9.dll"
$MOD_FILES  = @("d3d9.dll", "openxr_loader.dll", "SingularityVR.ini")

# VC++ 2015-2022 x86. On 64-bit Windows the key lives under
# WOW6432Node; on a 32-bit system directly below. Both are checked,
# otherwise the installer would wrongly report it as missing.
$VCRT_REGS  = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86",
    "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86"
)
$VCRT_URL   = "https://aka.ms/vs/17/release/vc_redist.x86.exe"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Singularity VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Singularity (2010) in stereo with 6-DOF head tracking and" -ForegroundColor White
Write-Host "  motion controllers: the weapon follows your hand, the shot" -ForegroundColor White
Write-Host "  follows the controller and the view never moves with it. HUD," -ForegroundColor White
Write-Host "  menus and the sniper scope are drawn in both eyes." -ForegroundColor White
Write-Host ""
Write-Host "  VIRTUAL DESKTOP WITH VDXR ONLY. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  This build supports no other runtime - SteamVR and OpenVR are" -ForegroundColor White
Write-Host "  planned but not in yet. All testing was done on a Quest 3S." -ForegroundColor White
Write-Host ""
Write-Host "  It is an alpha and has run on very few machines. Nothing in" -ForegroundColor Gray
Write-Host "  your game folder is modified - three files go in next to" -ForegroundColor Gray
Write-Host "  Singularity.exe, and deleting d3d9.dll undoes all of it." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Singularity") -ProbeExe $GAME_EXE
if (-not $gameDir) {
    # Join-Path would throw on a dead drive letter - hence string
    # concatenation plus -LiteralPath (hub-wide rule).
    foreach ($c in @("C:\GOG Games\Singularity",
                     "C:\Program Files (x86)\GOG Galaxy\Games\Singularity",
                     "C:\Program Files (x86)\Activision\Singularity",
                     "D:\GOG Games\Singularity",
                     "E:\GOG Games\Singularity")) {
        if (Test-Path -LiteralPath "$c\$GAME_EXE") { $gameDir = $c; break }
    }
}
while (-not $gameDir) {
    Write-Warn "Could not find $GAME_NAME automatically."
    Write-Host "  Drag the game folder into this window (the one holding" -ForegroundColor White
    Write-Host "  the Binaries folder), or paste its path, then press Enter." -ForegroundColor White
    Write-Host "  Leave it empty to stop - nothing has been changed yet." -ForegroundColor Gray
    $raw = (Read-Host "  Game folder").Trim().Trim('"')
    if (-not $raw) { Write-Info "Stopped. Nothing was changed."; Pause-User "Press Enter to exit."; exit 1 }
    if (Test-Path -LiteralPath "$raw\$GAME_EXE") { $gameDir = $raw }
    else { Write-Fail "That folder does not contain $GAME_EXE." }
}
Write-OK "Found $GAME_NAME`: $gameDir"
$binDir = "$gameDir\Binaries"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameDir -RelModFile $REL_MOD -Label "Singularity VR"

# ---- 2. Visual C++ 2015-2022 x86 ------------------------------
# REQUIRED, not optional: the proxy DLL is 32 bit. Anyone who only
# has the x64 runtime - which is almost everyone - gets a missing
# VCRUNTIME140.dll on launch and nothing else.
Write-Step 2 5 "Visual C++ 2015-2022 Redistributable (x86)"

$vcOk = $false
foreach ($k in $VCRT_REGS) {
    try {
        $vc = Get-ItemProperty -Path $k -ErrorAction Stop
        if ($vc -and ($vc.Installed -eq 1 -or $vc.Version)) { $vcOk = $true; break }
    } catch {}
}

if ($vcOk) {
    Write-OK "The x86 runtime is already installed."
} else {
    Write-Host ""
    Write-Host "  +======================================================+" -ForegroundColor Yellow
    Write-Host "  |            ACTION REQUIRED - MISSING RUNTIME          |" -ForegroundColor Yellow
    Write-Host "  +======================================================+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  The mod needs the " -NoNewline -ForegroundColor White
    Write-Host " x86 (32-bit) " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " build of the Visual C++" -ForegroundColor White
    Write-Host "  2015-2022 Redistributable. The x64 one you almost certainly" -ForegroundColor White
    Write-Host "  already have will NOT do - the proxy DLL is 32-bit, and the" -ForegroundColor White
    Write-Host "  game will start with a missing VCRUNTIME140.dll instead." -ForegroundColor White
    Write-Host ""
    Write-Host "  It comes straight from Microsoft (free, official):" -ForegroundColor Gray
    Write-Host "  $VCRT_URL" -ForegroundColor Cyan
    Write-Host ""
    if (Read-YesNo "Download and install it now?") {
        $vcExe = Join-Path $env:TEMP "vc_redist.x86.exe"
        if (Invoke-SafeDownload -Urls @($VCRT_URL) -Destination $vcExe -Label "Visual C++ 2015-2022 (x86)" `
                -ManualUrl $VCRT_URL `
                -Instructions "Download vc_redist.x86.exe from the Microsoft link, save it as '$vcExe', then choose Retry." `
                -SkipMessage "Skipped - install it yourself before playing, or the game will not start.") {
            Pause-User "Press Enter to run the Microsoft installer - UAC required..." | Out-Null
            try {
                $p = Start-Process -FilePath $vcExe -ArgumentList "/install","/passive","/norestart" -Wait -PassThru -Verb RunAs -ErrorAction Stop
                if ($p.ExitCode -eq 0 -or $p.ExitCode -eq 3010 -or $p.ExitCode -eq 1638) {
                    Write-OK "The x86 runtime is installed."
                    if ($p.ExitCode -eq 3010) { Write-Info "Windows wants a restart at some point - not now." }
                } else {
                    Write-Warn "The installer exited with code $($p.ExitCode). If the game will not start, run vc_redist.x86.exe by hand."
                }
            } catch {
                Write-Warn "Could not run it: $($_.Exception.Message)"
                Write-Host "  Run it yourself: $vcExe" -ForegroundColor Gray
                Pause-User "Press Enter once you have, or to continue anyway..." | Out-Null
            }
            try { Remove-Item -LiteralPath $vcExe -Force -ErrorAction SilentlyContinue } catch {}
        }
    } else {
        Write-Warn "Skipped. Install it before you play, or the game will not start."
    }
}

# ---- 3. Fetch the mod and put it in place ---------------------
Write-Step 3 5 "Downloading and installing $MOD_NAME"

# All releases are prereleases -> query the LIST. And pick the asset
# by hand: Select-PayloadAsset used to discard anything under 1 MB
# and this package is smaller. The .pdb next to it is purely a symbol
# file for bug reports and is deliberately NOT downloaded.
$zipUrl = $null; $tag = ""
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    $pick = @($rel) | Where-Object { -not $_.draft } | Select-Object -First 1
    if ($pick) {
        $zips = @($pick.assets) | Where-Object { $_.name -match '(?i)\.zip$' -and $_.name -notmatch '(?i)source|symbols|debug' }
        $a = $zips | Where-Object { $_.name -match '(?i)singularity' } | Select-Object -First 1
        if (-not $a) { $a = $zips | Select-Object -First 1 }
        if ($a -and $a.browser_download_url) {
            $zipUrl = [string]$a.browser_download_url; $tag = [string]$pick.tag_name
            # Remember name AND size: that lets Find-PredownloadedFile
            # hold a file in the downloads folder against the CURRENT
            # release instead of accepting anything similarly named.
            $assetName = [string]$a.name; $assetSize = [long]$a.size
        }
    }
    if ($zipUrl) { Write-OK "Release: $tag" }
} catch { Write-Warn "GitHub could not be reached - falling back to the releases page." }

$tmp = Join-Path $env:TEMP ("sgvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zipPath = Join-Path $tmp "SingularityVR.zip"

$have = Find-PredownloadedFile -Patterns @("SingularityVR-*.zip") -Label "the SingularityVR release" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $zipPath = $have
    Write-Info "Using the copy you already downloaded."
} else {
    if (-not $zipUrl) { $zipUrl = "$RELEASES" }
    Invoke-SafeDownload -Urls @($zipUrl) -Destination $zipPath -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download the SingularityVR .zip from the releases page, save it as '$zipPath', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Fail "No package - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive is FLAT (d3d9.dll at the root). Expand-ArchiveToTarget
# still survives a future wrapper folder - RelModFile is the anchor.
$st = Expand-ArchiveToTarget -ArchivePath $zipPath -TargetDir $binDir `
        -RelModFile "d3d9.dll" -Markers @("openxr_loader.dll","SingularityVR.ini") `
        -Label "SingularityVR" `
        -SkipMessage "Nothing was copied - the game is untouched."
if ([string]$st -ne "ok" -and [string]$st -ne "manual") {
    Write-Fail "The package could not be unpacked - the game is untouched."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
try { if ($zipPath -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

$missing = @()
foreach ($f in $MOD_FILES) { if (-not (Test-Path -LiteralPath "$binDir\$f")) { $missing += $f } }
if ($missing.Count -gt 0) {
    Write-Fail ("These did not arrive in Binaries: " + ($missing -join ", "))
    Write-Host "  Unpack the zip into $binDir by hand and run this again." -ForegroundColor White
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "d3d9.dll, openxr_loader.dll and SingularityVR.ini are in place."
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
if ($tag) { try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {} }

# ---- 4. Which build of the game is this? ----------------------
# !!! THE GERMAN EDITION IS AN OLDER BUILD, NOT MERELY A CENSORED
# !!! ONE - WHICH IS WHY THE MOD DOES NOT WORK ON IT.
# Proven on a real machine: the mod did not find the engine table
# GObjects, refused EVERY hook with "prologue mismatch - refusing to
# hook", never had a camera matrix and split ZERO draw calls across
# four runs. Result in the headset: two flat images, no head
# tracking. After swapping the exe: 445,593 split calls, 100 % of
# them with parallax.
# The timestamps say why: German 2010-05-28, international
# 2010-07-08. The mod's addresses come from the newer build.
$HASH_SP_UNCUT = "777e2bf260563558c28de70088c655459755cf0d8b56ebc3d28e17074b7114a4"  # 27.084.288 B
$HASH_SP_CUT   = "80085dc9c584e996987c525dc1aed9ee62b5b460bcedd8bd9981aaf474e5d8c6"  # 27.441.664 B
$UNCUT_PAGE    = "https://www.compiware-forum.de/file-download/9608/"
# The same address is used for the direct attempt. If it serves a
# page rather than a file, the installer falls back to the manual
# route on its own - it recognises that from the first bytes.
$UNCUT_URL     = $UNCUT_PAGE

Write-Step 4 5 "Checking which build of the game you have"
$exePath = Join-Path $gameDir "Binaries\Singularity.exe"
$edition = "unknown"
if (Test-Path -LiteralPath $exePath) {
    $h = $null
    try { $h = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch {}
    if     ($h -eq $HASH_SP_UNCUT) { $edition = "uncut" }
    elseif ($h -eq $HASH_SP_CUT)   { $edition = "cut" }
} else { $edition = "missing" }

if ($edition -eq "uncut") {
    Write-OK "International build - this is the one the mod was built against."
} elseif ($edition -eq "cut") {
    Write-Warn "German build detected - THE MOD CANNOT HOOK THIS ONE."
    Write-Host "  It is not only censored, it is an OLDER build (28 May 2010" -ForegroundColor White
    Write-Host "  against 8 July 2010). The mod's engine addresses come from the" -ForegroundColor White
    Write-Host "  newer one, so it refuses to hook and you get two flat images" -ForegroundColor White
    Write-Host "  with no head tracking. Measured: zero draw calls split." -ForegroundColor White
    Write-Host ""
    Write-Host "  Swapping in the international executable fixes it completely -" -ForegroundColor White
    Write-Host "  same test afterwards: 445,593 draw calls split, all with" -ForegroundColor White
    Write-Host "  parallax. The uncut patch for the German release provides it." -ForegroundColor White
    Write-Host ""
    if (Read-YesNo "Fetch it and swap the executable for you?") {

        # ---- Automatic, with an honest fallback -------------------
        # Whether that address serves the file DIRECTLY or a forum page
        # cannot be checked from here. So: download it, LOOK AT what
        # arrived, and only continue when it is genuinely usable.
        # Otherwise the manual route, as before.
        $uTmp = Join-Path $env:TEMP ("sguncut_" + [Guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $uTmp -Force | Out-Null
        $dl   = Join-Path $uTmp "uncut.bin"
        $newExe = $null
        $manual = $false

        Write-Host ""
        Write-Info "Downloading the uncut package ..."
        $got = $false
        try { $got = [bool](Invoke-SafeDownload -Urls @($UNCUT_URL) -Destination $dl -Label "uncut package" `
                        -ManualUrl $UNCUT_PAGE `
                        -Instructions "Download the archive from the page and save it as '$dl', then choose Retry.") } catch {}

        if ($got -and (Test-Path -LiteralPath $dl)) {
            # WHAT IS THIS, ACTUALLY? Read the first bytes instead of
            # trusting the extension - otherwise a forum page passes as
            # an "archive" and extraction throws mid-run.
            $magic = ""
            try {
                $fs = [IO.File]::OpenRead($dl)
                try { $b = New-Object byte[] 4; [void]$fs.Read($b,0,4); $magic = -join ($b | ForEach-Object { $_.ToString("X2") }) } finally { $fs.Dispose() }
            } catch {}
            $kind = switch -Regex ($magic) {
                '^504B0304' { "zip" }
                '^526172' { "rar" }
                '^377ABC' { "7z" }
                '^4D5A'   { "exe" }
                default   { "other" }
            }
            Write-Info "Downloaded $([math]::Round((Get-Item -LiteralPath $dl).Length / 1MB, 1)) MB - looks like: $kind"

            if ($kind -eq "exe") {
                $newExe = $dl
            } elseif ($kind -eq "zip") {
                # NOT Expand-Archive: that goes ONLY by the file
                # extension and rejects a .bin even when the content is a
                # clean zip ("'.zip' is the only supported archive file
                # format"). Here the type is already known from the first
                # bytes. ZipFile::ExtractToDirectory looks inside the
                # file and is therefore the right choice.
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($dl, (Join-Path $uTmp "x"))
                    $newExe = (Get-ChildItem -LiteralPath (Join-Path $uTmp "x") -Recurse -Filter "Singularity.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                } catch { Write-Warn "The archive could not be unpacked: $($_.Exception.Message)" }
            } elseif ($kind -eq "rar" -or $kind -eq "7z") {
                # PowerShell cannot handle RAR or 7z itself - use 7-Zip
                # when it is there. When it is not, that is no error, it
                # is the manual route.
                $sevenZip = $null
                foreach ($c in @("C:\Program Files\7-Zip\7z.exe","C:\Program Files (x86)\7-Zip\7z.exe")) {
                    if (Test-Path -LiteralPath $c) { $sevenZip = $c; break }
                }
                if ($sevenZip) {
                    try {
                        & $sevenZip x "-o$(Join-Path $uTmp 'x')" $dl -y | Out-Null
                        $newExe = (Get-ChildItem -LiteralPath (Join-Path $uTmp "x") -Recurse -Filter "Singularity.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                    } catch { Write-Warn "7-Zip could not unpack it: $($_.Exception.Message)" }
                } else {
                    Write-Warn "This is a $kind archive and 7-Zip is not installed."
                    $manual = $true
                }
            } else {
                # Usually an HTML page: the address wants a click or a
                # forum login.
                Write-Warn "What came back is not an archive - the page most likely needs a click in a browser."
                $manual = $true
            }
            if (-not $newExe -and -not $manual) {
                Write-Warn "Singularity.exe was not found inside the download."
                $manual = $true
            }
        } else {
            $manual = $true
        }

        # ---- The swap, with a backup -----------------------------
        if ($newExe) {
            $newHash = $null
            try { $newHash = (Get-FileHash -LiteralPath $newExe -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch {}
            if ($newHash -eq $HASH_SP_CUT) {
                Write-Warn "The download is the SAME German build - not swapping anything."
                $manual = $true
            } else {
                if ($newHash -ne $HASH_SP_UNCUT) {
                    Write-Warn "This is not the build we know the checksum of."
                    Write-Host "  It may still be fine - it will be checked again after the swap." -ForegroundColor White
                }
                # THE OLD EXE IS NEVER SIMPLY OVERWRITTEN. It is part of
                # a purchased installation; without a backup the only way
                # back would be a Steam file verification.
                $backup = "$exePath.german.bak"
                try {
                    if (-not (Test-Path -LiteralPath $backup)) {
                        Copy-Item -LiteralPath $exePath -Destination $backup -Force -ErrorAction Stop
                        Write-OK "Original kept as Singularity.exe.german.bak"
                    } else {
                        Write-Info "A backup of the original is already there."
                    }
                    Copy-Item -LiteralPath $newExe -Destination $exePath -Force -ErrorAction Stop
                    Write-OK "Executable replaced."
                } catch {
                    Write-Fail "Could not replace the file: $($_.Exception.Message)"
                    Write-Host "  Close the game and Steam, then run this again." -ForegroundColor White
                    $manual = $true
                }
            }
        }
        try { Remove-Item -LiteralPath $uTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

        # ---- manual route, if the automatic one did not get through --
        if ($manual) {
            Write-Host ""
            Write-Host "  ============================================================" -ForegroundColor Yellow
            Write-Host "   DOING IT BY HAND" -ForegroundColor Yellow
            Write-Host "  ============================================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "    1. Download the archive from the page that opens" -ForegroundColor White
            Write-Host "    2. Unpack it OVER your game's Binaries folder," -ForegroundColor White
            Write-Host "       replacing Singularity.exe when asked" -ForegroundColor White
            Write-Host "    3. Come back here - this window waits" -ForegroundColor White
            Write-Host ""
            Write-Host "  Your Binaries folder:" -ForegroundColor Gray
            Write-Host "    $(Join-Path $gameDir 'Binaries')" -ForegroundColor DarkGray
            Write-Host ""
            Pause-User "Press Enter to open the download page..." | Out-Null
            try { Start-Process $UNCUT_PAGE } catch { Write-Warn "Could not open the browser. The address is: $UNCUT_PAGE" }
            Write-Host ""
            Pause-User "Press Enter once you have replaced Singularity.exe..." | Out-Null
        }

        # ---- Cross-check, in both cases --------------------------
        $h2 = $null
        try { $h2 = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower() } catch {}
        Write-Host ""
        if ($h2 -eq $HASH_SP_UNCUT) {
            Write-OK "Verified: the international executable is in place."
            $edition = "uncut"
        } elseif ($h2 -eq $HASH_SP_CUT) {
            Write-Warn "Still the German build - nothing was replaced."
            Write-Host "  Check that you unpacked into Binaries and overwrote the file." -ForegroundColor White
        } else {
            Write-Warn "The executable changed, but it is not the build we know."
            Write-Host "  It may still work. If VR stays flat, this is the reason." -ForegroundColor White
        }
    } else {
        Write-Info "Skipped. VR will stay flat on this build - run this again"
        Write-Info "whenever you want to do it."
    }
} elseif ($edition -eq "missing") {
    Write-Warn "Singularity.exe was not where it was expected - build unknown."
} else {
    Write-Info "Unknown build - neither the German nor the international one."
    Write-Info "If VR stays flat with no head tracking, that is the likely reason."
}

# ---- 5. Playing -----------------------------------------------
Write-Step 5 5 "Before you play - two things that matter"
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   1. TURN OFF EVERY VIDEO OPTION IN THE GAME" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  In the game's " -NoNewline -ForegroundColor White
Write-Host " Video Settings " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " untick " -NoNewline -ForegroundColor White
Write-Host "EVERY" -NoNewline -ForegroundColor Yellow
Write-Host " option." -ForegroundColor White
Write-Host "  " -NoNewline
Write-Host " High Quality Decals " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " above all - it enables dynamic" -ForegroundColor White
Write-Host "  shadows, and those are broken in VR. This is not optional." -ForegroundColor White
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   2. THE FIRST RUN IS AT THE WRONG RESOLUTION" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Expected, not a fault: the mod must set the resolution before" -ForegroundColor White
Write-Host "  the engine reads the command line - before it can ask your" -ForegroundColor White
Write-Host "  headset anything. It asks during that run and uses the answer" -ForegroundColor White
Write-Host "  on the next one. So: " -NoNewline -ForegroundColor White
Write-Host "launch once, quit, launch again." -ForegroundColor Yellow
Write-Host ""
Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Connect Virtual Desktop FIRST, then Start in VR in the Hub." -ForegroundColor White
Write-Host "  Hold Y for the in-headset settings menu, hold Menu to recentre." -ForegroundColor Gray
Write-Host "  The full controller map is on this game's page in the Hub." -ForegroundColor Gray
Write-Host "  Back to flat: the Flat / VR switch on that same page." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> Time is a weapon here. So is your other hand." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
