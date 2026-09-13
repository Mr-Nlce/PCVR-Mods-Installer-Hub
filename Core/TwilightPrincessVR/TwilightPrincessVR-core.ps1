# ============================================================
#  The Legend of Zelda: Twilight Princess VR - Dusklight VR
#  by JoeyAW
# ------------------------------------------------------------
#  STANDALONE, like Ocarina of Time VR: there is no game to patch.
#  The port brings its own dusklight.exe, and the user puts their
#  OWN game dump next to it. So we download the release, unpack it
#  to a location of their choice and create a shortcut.
#
#  TWO THINGS THAT MAKE THIS ENTRY SPECIAL:
#  1. THE ARCHIVE IS HUGE - over 500 MB packed, around 2 GB
#     unpacked. The author ships his COMPLETE build folder (_deps,
#     CMakeFiles, .pdb, .lib, .obj). Playing needs maybe 90 MB of
#     that. We say so beforehand, so nobody thinks something went
#     wrong.
#  2. THE EXE SITS IN A SUBFOLDER windows-msvc-relwithdebinfo, not
#     at the archive root.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Twilight Princess VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers.
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

# Henriko Magnifico currently offers three ZTP variants. Keep the filename
# rules broad enough for browser duplicate suffixes and future point releases,
# while still excluding unrelated ZIP files in Downloads.
$script:TwilightTexturePatterns = @(
    'ZTP*1080p*Mobile Edition*.zip',
    'ZTP*1080p*PC Edition*.zip',
    'ZTP*4K*PC Edition*.zip',
    'ZTP*Henriko*.zip',
    '*Twilight*Texture*.zip'
)

function Test-TwilightTextureArchive {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    if ([IO.Path]::GetExtension($Path) -ine '.zip') { return $false }

    # Transport validation only, never a release-identity gate: verify that the
    # selected file is a non-empty ZIP. The texture layout is checked after
    # extraction, so future releases are not rejected over name, size or SHA.
    $stream = $null
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        if ($stream.Length -lt 4) { return $false }
        $header = New-Object byte[] 4
        if ($stream.Read($header, 0, 4) -ne 4) { return $false }
        return ($header[0] -eq 0x50 -and $header[1] -eq 0x4B -and
                (($header[2] -eq 0x03 -and $header[3] -eq 0x04) -or
                 ($header[2] -eq 0x05 -and $header[3] -eq 0x06) -or
                 ($header[2] -eq 0x07 -and $header[3] -eq 0x08)))
    } catch { return $false }
    finally { if ($stream) { $stream.Dispose() } }
}

function Get-TwilightTextureDownloadFolders {
    param([string[]]$ExtraFolders = @())
    $folders = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

    # Honour a redirected Downloads known folder, then the ordinary profile
    # and OneDrive locations. Pasted M:\ and UNC paths are accepted separately.
    try {
        $shellFolders = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
        $redirected = '' + $shellFolders.'{374DE290-123F-4565-9164-39C4925E467B}'
        if ($redirected) { $redirected = [Environment]::ExpandEnvironmentVariables($redirected); [void]$folders.Add($redirected) }
    } catch {}
    $profile = [Environment]::GetFolderPath('UserProfile')
    if ($profile) { [void]$folders.Add((Join-Path $profile 'Downloads')) }
    if ($env:OneDrive) { [void]$folders.Add((Join-Path $env:OneDrive 'Downloads')) }
    foreach ($extra in @($ExtraFolders)) { if ($extra) { [void]$folders.Add([string]$extra) } }

    $usable = New-Object System.Collections.Generic.List[string]
    foreach ($folder in $folders) {
        if ($folder -and $seen.Add($folder) -and (Test-Path -LiteralPath $folder -PathType Container -ErrorAction SilentlyContinue)) {
            [void]$usable.Add($folder)
        }
    }
    return @($usable)
}

function Get-TwilightTextureArchiveCandidates {
    param([string[]]$Folders = @())
    if (-not $Folders -or $Folders.Count -eq 0) { $Folders = @(Get-TwilightTextureDownloadFolders) }
    $candidates = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($folder in @($Folders)) {
        if (-not $folder -or -not (Test-Path -LiteralPath $folder -PathType Container -ErrorAction SilentlyContinue)) { continue }
        try {
            foreach ($file in @(Get-ChildItem -LiteralPath $folder -Filter '*.zip' -File -ErrorAction SilentlyContinue)) {
                $nameMatches = $false
                foreach ($pattern in $script:TwilightTexturePatterns) {
                    if ($file.Name -like $pattern) { $nameMatches = $true; break }
                }
                if ($nameMatches -and $seen.Add($file.FullName) -and (Test-TwilightTextureArchive $file.FullName)) {
                    [void]$candidates.Add($file)
                }
            }
        } catch {}
    }
    return @($candidates | Sort-Object LastWriteTime -Descending)
}

function Read-TwilightTextureArchive {
    param([switch]$FoundInDownloads)

    for ($attempt = 1; $attempt -le 10; $attempt++) {
        Write-Host ''
        Write-Host '  You can drag or paste the downloaded ZIP path here.' -ForegroundColor Yellow
        if ($FoundInDownloads) {
            Write-Host '  Or press Enter to show/use the found ZIP in Downloads.' -ForegroundColor Yellow
        } else {
            Write-Host '  Or press Enter to search Downloads for the finished ZIP.' -ForegroundColor Yellow
        }
        Write-Host '  Type O to reopen the page, or S to skip the texture pack.' -ForegroundColor Gray
        $raw = ('' + (Read-Host '  ZIP path / Enter / O / S')).Trim()
        $choice = $raw.ToUpperInvariant()
        if ($choice -eq 'S') { return '__SKIP__' }
        if ($choice -eq 'O') {
            Pause-User 'Press Enter to reopen the download page...' | Out-Null
            try { Start-Process $TEX_PAGE } catch { Write-Warn "Open manually: $TEX_PAGE" }
            continue
        }
        if ($raw) {
            $candidate = $raw.Trim('"').Trim("'").Trim()
            if (Test-TwilightTextureArchive $candidate) {
                Write-OK "Using: $candidate"
                return $candidate
            }
            Write-Warn 'That path is not a readable ZIP file.'
            if ($candidate -match '^[A-Za-z]:\\') {
                Write-Host '  If it is a mapped network drive, paste its UNC path or copy' -ForegroundColor Gray
                Write-Host '  the ZIP to Downloads if this installer cannot see the mapping.' -ForegroundColor Gray
            }
            continue
        }

        $found = @(Get-TwilightTextureArchiveCandidates)
        if ($found.Count -eq 0) {
            Write-Warn "No matching ZTP texture ZIP was found in Downloads (attempt $attempt/10)."
            continue
        }
        Write-Host ''
        Write-Host '  Matching ZTP texture downloads:' -ForegroundColor Cyan
        for ($i = 0; $i -lt $found.Count; $i++) {
            $size = if ($found[$i].Length -ge 1GB) { '{0:N2} GB' -f ($found[$i].Length / 1GB) } else { '{0:N1} MB' -f ($found[$i].Length / 1MB) }
            Write-Host ("   [{0}] {1}" -f ($i + 1), $found[$i].Name) -ForegroundColor White
            Write-Host ("       {0}  {1}" -f $size, $found[$i].DirectoryName) -ForegroundColor DarkGray
        }
        if ($found.Count -eq 1) {
            $selectionPrompt = '  Press Enter to use [1], or type B to go back'
        } else {
            $selectionPrompt = "  Press Enter to use [1], choose 1-$($found.Count), or type B to go back"
        }
        $pick = ('' + (Read-Host $selectionPrompt)).Trim()
        if ($pick -ieq 'B') { continue }
        if (-not $pick) { $pick = '1' }
        $number = 0
        if ([int]::TryParse($pick, [ref]$number) -and $number -ge 1 -and $number -le $found.Count) {
            Write-OK "Using: $($found[$number - 1].FullName)"
            return [string]$found[$number - 1].FullName
        }
    }
    Write-Warn 'No texture archive was selected after 10 attempts.'
    return $null
}

# Use the Hub's clean native 7-Zip percentage display for both large
# Twilight Princess archives. Resolve 7-Zip only once; if the user declines
# it or the progress extraction fails, keep the established safe fallback.
$script:TwilightSevenZipChecked = $false
$script:TwilightSevenZip = $null
function Expand-TwilightArchive {
    param(
        [Parameter(Mandatory=$true)][string]$Archive,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][string]$Label
    )
    if (-not $script:TwilightSevenZipChecked) {
        $script:TwilightSevenZipChecked = $true
        $script:TwilightSevenZip = Get-SevenZip
    }
    if ($script:TwilightSevenZip) {
        if (Expand-7zWithProgress -SevenZip $script:TwilightSevenZip -Archive $Archive -Dest $Destination -Label $Label) {
            return "ok"
        }
        Write-Warn "The progress extraction failed - trying the safe fallback."
    }
    return (Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $Destination -Label $Label)
}

$MOD_NAME    = "Dusklight VR"
$MOD_AUTHOR  = "JoeyAW"
$REPO        = "JoeyAW/dusklight-vr"
$RELEASES    = "https://github.com/$REPO/releases"
$ASSET       = "Dusklight-VR-Windows-x64.zip"
$BUILD_SUB   = "windows-msvc-relwithdebinfo"
$GAME_EXE    = "dusklight.exe"
$DEFAULT_DIR = "C:\Games\Twilight Princess VR"
$TEX_PAGE    = "https://www.henrikomagnifico.com/zelda-twilight-princess-4k"
# The texture folder is NOT in the install folder but under
# %APPDATA% - the most common mix-up with this package.
$TEX_DIR     = Join-Path $env:APPDATA "TwilitRealm\Dusklight\texture_replacements"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " The Legend of Zelda: Twilight Princess VR" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Twilight Princess in stereoscopic VR with tracked hands -" -ForegroundColor White
Write-Host "  swing the sword, bash with the shield, aim with your right" -ForegroundColor White
Write-Host "  hand. You can drop to flatscreen any time for the parts you" -ForegroundColor White
Write-Host "  would rather not play in a headset." -ForegroundColor White
Write-Host ""
Write-Host "  YOU SUPPLY THE GAME. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  This port ships no game data at all. You need your own dump" -ForegroundColor White
Write-Host "  of the GameCube release as .iso or .rvz - other versions are" -ForegroundColor White
Write-Host "  not supported yet." -ForegroundColor White
Write-Host ""
Write-Host "  Tested on Quest 2 and 3; other headsets are untested. Needs a" -ForegroundColor Gray
Write-Host "  D3D12-capable GPU, Windows only. Virtual Desktop with VDXR is" -ForegroundColor Gray
Write-Host "  the author's recommendation for performance." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Pick the location -------------------------------------
Write-Step 1 5 "Choosing where it goes"
Write-Host ""
Write-Host "  This is a standalone build - it does not go into any existing" -ForegroundColor White
Write-Host "  game folder. Pick a place with room to spare." -ForegroundColor White
Write-Host ""
Write-Host "    Default: $DEFAULT_DIR" -ForegroundColor Cyan
Write-Host ""
$dir = ""
try { $dir = (Read-Host "  Folder (Enter for the default)").Trim().Trim('"') } catch {}
if (-not $dir) { $dir = $DEFAULT_DIR }
try { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
catch {
    Write-Fail "Could not create $dir - $($_.Exception.Message)"
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Install folder: $dir"

# ---- 2. Download ----------------------------------------------
Write-Step 2 5 "Downloading $MOD_NAME"
Write-Host ""
Write-Host "  HEADS UP - THIS IS A BIG ONE. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Over 500 MB to download and around 2 GB once unpacked. That" -ForegroundColor White
Write-Host "  is not a mistake: the author ships his whole build folder," -ForegroundColor White
Write-Host "  compiler leftovers and all. The game itself is a fraction of" -ForegroundColor White
Write-Host "  it. Nothing is wrong if it takes a while." -ForegroundColor White
Write-Host ""

$tmp = Join-Path $env:TEMP ("dusklight_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp $ASSET

$url = "https://github.com/$REPO/releases/latest/download/$ASSET"
$tag = "latest"
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
    if (Test-IsPayloadRelease -Release $rel) {
        $pick = Select-PayloadAsset -Assets $rel.assets -PlatformPattern '(?i)windows|x64' -MinBytes 10000000
        if ($pick -and $pick.browser_download_url) {
            $url = [string]$pick.browser_download_url
            $tag = [string]$rel.tag_name
        }
    }
    Write-OK "Release: $tag"
} catch { Write-Warn "GitHub could not be reached - trying the direct link." }

# An existing file on disk first - at this size a real time saver
# when the user already downloaded it.
$have = Find-PredownloadedFile -Patterns @("Dusklight-VR-Windows*.zip", "*Dusklight*VR*.zip") -Label "the Dusklight VR release"
if ($have -and (Test-Path -LiteralPath $have)) {
    $zip = $have
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download $ASSET from the releases page, save it as '$zip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No archive - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 3. Entpacken ---------------------------------------------
Write-Step 3 5 "Unpacking"
Write-Host "  This takes a few minutes - it is a lot of small files." -ForegroundColor Gray
[void](Expand-TwilightArchive -Archive $zip -Destination $dir -Label $MOD_NAME)

# The exe sits in windows-msvc-relwithdebinfo, not at the root - but
# search the whole tree in case the author changes that.
$exe = Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue |
       Where-Object { $_.Name -ieq $GAME_EXE } | Select-Object -First 1
if (-not $exe) {
    Write-Fail "No $GAME_EXE below $dir - the install did not complete."
    Write-Host "  Expected it in: $dir\$BUILD_SUB\" -ForegroundColor Yellow
    try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Ready: $($exe.FullName)"

# THE FOLDER TO EXCLUDE IS WHERE THE MOD LIVES - this one installs into
# its own folder, not into a game directory. The archive is still there,
# so recovery can unpack it again on excluded ground.
$avFilesOk = Confirm-PlacedFilesSurvive `
    -Paths @($exe.FullName) `
    -GameDir $dir `
    -ArchivePath $zip
if (-not $avFilesOk) {
    try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    Write-Fail "Twilight Princess VR could not be restored after the antivirus check."
    Pause-User "Press Enter to exit, then run the installer again."
    exit 1
}
try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

# ---- 4. Shortcut and marker -----------------------------------
Write-Step 4 5 "Finishing up"
$exeDir = Split-Path $exe.FullName -Parent
try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Twilight Princess VR.lnk"))
    $lnk.TargetPath = $exe.FullName
    $lnk.WorkingDirectory = $exeDir
    $lnk.Save()
    Write-OK "Desktop shortcut created."
} catch { Write-Warn "Could not create the desktop shortcut." }

# Marker for the Hub - into the INSTALLER folder.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $dir -Encoding UTF8 -Force } catch {}
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".launch_exe")     -Value $exe.FullName -Encoding UTF8 -Force } catch {}
if (Test-IsTrackableInstalledVersion -Version $tag) {
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {}
    Save-InstalledStamp -GameDir $dir -Version $tag
}

# ---- 5. ZTP HD texture pack (optional) ------------------------
# By Henriko Magnifico. Hosted behind the author's download page,
# so the user chooses one variant and supplies the downloaded ZIP.
Write-Step 5 5 "Optional: the ZTP HD texture pack"
Write-Host ""
Write-Host "  Henriko Magnifico's pack redraws the game's textures in HD." -ForegroundColor White
Write-Host "  It works with Dusklight and is switched on inside the game." -ForegroundColor White
Write-Host ""
Write-Host "  CHOOSE ONE VERSION: " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " 1080p Mobile, 1080p PC, or 4K PC." -ForegroundColor White
Write-Host "  The 4K PC edition is about 4 GB packed and several GB unpacked." -ForegroundColor Gray
Write-Host ""
Write-Host "  Purely cosmetic; the game runs fine without it." -ForegroundColor Gray
Write-Host ""
if (Read-YesNo "  Set up one ZTP texture-pack version as well?") {
    $texZip = $null
    $textureSkipRequested = $false
    $existingTextureDownloads = @(Get-TwilightTextureArchiveCandidates)
    if ($existingTextureDownloads.Count -gt 0) {
        Write-OK 'Found a matching ZTP download in Downloads.'
        $texChoice = Read-TwilightTextureArchive -FoundInDownloads
        if ($texChoice -eq '__SKIP__') { $textureSkipRequested = $true }
        else { $texZip = $texChoice }
    }
    if (-not $texZip -and -not $textureSkipRequested) {
        Write-Host ""
        Write-Host "  The pack is hosted on the author's site, so it cannot be" -ForegroundColor White
        Write-Host "  fetched from here - the page opens and you download it" -ForegroundColor White
        Write-Host "  there. EXPECT THIS TO TAKE A WHILE." -ForegroundColor White
        Write-Host ""
        Pause-User "Press Enter to open the download page..." | Out-Null
        try { Start-Process $TEX_PAGE } catch { Write-Warn "Open manually: $TEX_PAGE" }
        Write-Host ""
        Write-Host "  Download ONE edition: 1080p Mobile, 1080p PC, or 4K PC." -ForegroundColor White
        Write-Host "  When it is complete, return here. You can leave it in" -ForegroundColor White
        Write-Host "  Downloads, or supply its full path from any local, mapped" -ForegroundColor White
        Write-Host "  or network location." -ForegroundColor White
        $texChoice = Read-TwilightTextureArchive
        if ($texChoice -eq '__SKIP__') { $textureSkipRequested = $true }
        else { $texZip = $texChoice }
    }
    if ($texZip -and (Test-Path -LiteralPath $texZip)) {
        Write-Host ""
        Write-Host "  Unpacking - this one takes several minutes." -ForegroundColor Gray
        $textureLocation = Join-Path $TEX_DIR "HenrikosTP4K_..."
        try {
            New-Item -ItemType Directory -Path $TEX_DIR -Force -ErrorAction Stop | Out-Null
            [void](Expand-TwilightArchive -Archive $texZip -Destination $TEX_DIR -Label "ZTP texture pack")
            # IMPORTANT: Dusklight expects the pack's own HenrikosTP4K...
            # folder to remain directly below texture_replacements. Do not
            # flatten it or move its province folders one level upwards.
            $packFolder = Get-ChildItem -LiteralPath $TEX_DIR -Directory -Force -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -like "HenrikosTP4K*" } |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
            if ($packFolder) {
                $dds = @(Get-ChildItem -LiteralPath $packFolder.FullName -Recurse -Filter "*.dds" -File -ErrorAction SilentlyContinue)
                if ($dds.Count -gt 0) { Write-OK "$($dds.Count) textures kept inside '$($packFolder.Name)'." }
                else { Write-Warn "No .dds files found inside $($packFolder.FullName) - check the archive by hand." }
                $textureLocation = $packFolder.FullName
            } else {
                Write-Warn "The required HenrikosTP4K folder was not found below $TEX_DIR."
            }
        } catch { Write-Warn "Could not unpack it: $($_.Exception.Message)" }
        Write-Host ""
        Write-Host "  They live here, NOT in the install folder:" -ForegroundColor White
        Write-Host "   $textureLocation " -ForegroundColor Black -BackgroundColor Yellow
        Write-Host "  Keep the HenrikosTP4K folder itself - do not move its contents out." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  ONE SWITCH LEFT, INSIDE THE GAME:" -ForegroundColor Yellow
        Write-Host "  Settings > Video > turn " -NoNewline -ForegroundColor White
        Write-Host " Use Texture Pack " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
        Write-Host " on." -ForegroundColor White
        Write-Host "  Without that the textures sit there and do nothing." -ForegroundColor Gray
    } else {
        Write-Info "Skipped - you can run this installer again later."
    }
} else {
    Write-Info "Skipped."
}

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host "  NOW YOUR OWN COPY OF THE GAME" -ForegroundColor Cyan
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Dusklight ships no game data. Dump your own GameCube disc" -ForegroundColor White
Write-Host "  and point the launcher at the .iso or .rvz when it asks." -ForegroundColor White
Write-Host "  Dolphin's wiki explains dumping; nodtool or Dolphin can turn" -ForegroundColor White
Write-Host "  an .iso into the smaller .rvz." -ForegroundColor White
Write-Host ""
Write-Host "  To play: start your VR software FIRST, then run the shortcut." -ForegroundColor White
Write-Host "  A window opens on your desktop - press Enter there or click" -ForegroundColor White
Write-Host "  Play to start the game. Nothing appears in the headset before" -ForegroundColor White
Write-Host "  that." -ForegroundColor White
Write-Host ""
Write-Host "  Worth knowing, straight from the author:" -ForegroundColor Gray
Write-Host "   - Cutscenes are broken in VR by design of the engine -" -ForegroundColor Gray
Write-Host "     watch them in flatscreen." -ForegroundColor Gray
Write-Host "   - Wolf Link sections stay in third person." -ForegroundColor Gray
Write-Host "   - After a loading screen, stand still for about 3 seconds" -ForegroundColor Gray
Write-Host "     until the hearts and map appear - that settles the camera" -ForegroundColor Gray
Write-Host "     height." -ForegroundColor Gray
Write-Host ""
Write-Host "  Twilight and light, and you between them - with a sword." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
