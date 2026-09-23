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

# A bare drive designator (for example F:) is drive-relative on Windows: it
# means the hidden current directory of that drive, not F:\. Native extractors
# and PowerShell can consequently write to and search two different folders.
function Resolve-TwilightInstallRoot {
    param([string]$InputPath,[string]$DefaultPath)
    $candidate = [Environment]::ExpandEnvironmentVariables(('' + $InputPath).Trim().Trim('"').Trim("'"))
    if (-not $candidate) { $candidate = $DefaultPath }
    if ($candidate -match '^[A-Za-z]:$') { $candidate += '\' }
    elseif ($candidate -match '^([A-Za-z]):([^\\/].*)$') { $candidate = $matches[1] + ':\' + $matches[2] }
    try {
        $full = [IO.Path]::GetFullPath($candidate)
        $root = [IO.Path]::GetPathRoot($full)
        if ($root -and $full -ieq $root) { return $root }
        return $full.TrimEnd('\','/')
    } catch { throw "That install folder is not a valid full filesystem path: $candidate" }
}

function Test-TwilightExecutable {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    $stream = $null
    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        if ($item.Length -lt 65536) { return $false }
        $stream = [IO.File]::Open($item.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
        return ($stream.ReadByte() -eq 0x4d -and $stream.ReadByte() -eq 0x5a)
    } catch { return $false }
    finally { if ($stream) { $stream.Dispose() } }
}

# Do not hard-code one publisher folder. Read every plausible Dusklight
# executable path from the live archive and use those paths only as positive
# discovery hints; names, sizes and hashes never reject a future release.
function Get-TwilightArchiveExecutableRelatives {
    param([string]$ArchivePath)
    if (-not $ArchivePath -or -not (Test-Path -LiteralPath $ArchivePath -PathType Leaf -ErrorAction SilentlyContinue)) { return @() }
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $zip = $null
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
        return @($zip.Entries | Where-Object {
            $_.Name -match '(?i)^dusklight[^\\/]*\.exe$' -and
            -not [IO.Path]::IsPathRooted($_.FullName) -and
            -not (@($_.FullName -split '[\\/]' | Where-Object { $_ }) -contains '..')
        } | ForEach-Object { $_.FullName.Replace('/','\') } | Sort-Object -Unique)
    } catch { return @() }
    finally { if ($zip) { $zip.Dispose() } }
}

function Find-TwilightRuntime {
    param(
        [Parameter(Mandatory=$true)][string]$InstallRoot,
        [string]$ArchivePath = '',
        [string]$RawInstallInput = '',
        [string[]]$AdditionalRoots = @()
    )
    $known = Join-Path (Join-Path $InstallRoot 'windows-msvc-relwithdebinfo') 'dusklight.exe'
    if (Test-TwilightExecutable $known) {
        return [pscustomobject]@{ Exe=(Get-Item -LiteralPath $known).FullName; RuntimeRoot=(Split-Path -Parent $known); Method='primary-known-layout' }
    }

    # Fallback 1: a future package may flatten the build beside the selected
    # install root while keeping the executable name.
    $rootLevel = Join-Path $InstallRoot 'dusklight.exe'
    if (Test-TwilightExecutable $rootLevel) {
        return [pscustomobject]@{ Exe=(Get-Item -LiteralPath $rootLevel).FullName; RuntimeRoot=$InstallRoot; Method='fallback-1-root-level' }
    }

    # Fallback 2: follow the live ZIP's own safe relative paths. This survives
    # renamed build folders, added wrappers and suffixed executable names.
    foreach ($relative in @(Get-TwilightArchiveExecutableRelatives -ArchivePath $ArchivePath)) {
        $candidate = Join-Path $InstallRoot $relative
        if (Test-TwilightExecutable $candidate) {
            return [pscustomobject]@{ Exe=(Get-Item -LiteralPath $candidate).FullName; RuntimeRoot=(Split-Path -Parent $candidate); Method='fallback-2-archive-layout' }
        }
    }

    # Fallback 3: packaging can change even when archive metadata is unavailable.
    # Scan the entire chosen target for a functional Dusklight executable.
    try {
        $hit = Get-ChildItem -LiteralPath $InstallRoot -Recurse -File -Filter '*.exe' -Force -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '(?i)^dusklight.*\.exe$' -and (Test-TwilightExecutable $_.FullName) } |
               Sort-Object @{Expression={ if ($_.Name -ieq 'dusklight.exe') { 0 } else { 1 } }}, @{Expression={$_.FullName.Length}} |
               Select-Object -First 1
        if ($hit) { return [pscustomobject]@{ Exe=$hit.FullName; RuntimeRoot=$hit.DirectoryName; Method='fallback-3-recursive-target' } }
    } catch {}

    # Fallback 4: recover the exact class of old F: versus F:\ failures and
    # other extractor redirections by checking the raw provider location plus
    # explicitly supplied related roots.
    $related = New-Object System.Collections.Generic.List[string]
    if ($RawInstallInput) {
        try {
            $rawResolved = (Get-Item -LiteralPath $RawInstallInput -Force -ErrorAction Stop).FullName
            if ($rawResolved -and $rawResolved -ine $InstallRoot) { [void]$related.Add($rawResolved) }
        } catch {}
    }
    foreach ($root in @($AdditionalRoots)) { if ($root) { [void]$related.Add([string]$root) } }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($root in $related) {
        if (-not $seen.Add($root) -or -not (Test-Path -LiteralPath $root -PathType Container -ErrorAction SilentlyContinue)) { continue }
        foreach ($relative in @(Get-TwilightArchiveExecutableRelatives -ArchivePath $ArchivePath)) {
            $candidate = Join-Path $root $relative
            if (Test-TwilightExecutable $candidate) {
                return [pscustomobject]@{ Exe=(Get-Item -LiteralPath $candidate).FullName; RuntimeRoot=(Split-Path -Parent $candidate); Method='fallback-4-related-root' }
            }
        }
        try {
            $hit = Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.exe' -Force -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -match '(?i)^dusklight.*\.exe$' -and (Test-TwilightExecutable $_.FullName) } |
                   Sort-Object @{Expression={ if ($_.Name -ieq 'dusklight.exe') { 0 } else { 1 } }}, @{Expression={$_.FullName.Length}} |
                   Select-Object -First 1
            if ($hit) { return [pscustomobject]@{ Exe=$hit.FullName; RuntimeRoot=$hit.DirectoryName; Method='fallback-4-related-root' } }
        } catch {}
    }
    return $null
}

# The Hub keeps one stable on-disk contract even if upstream renames or nests
# its build folder. Catalog detection and Start in VR therefore stay reliable.
function Copy-TwilightRuntimeToCanonical {
    param([Parameter(Mandatory=$true)][string]$SourceRoot,[Parameter(Mandatory=$true)][string]$InstallRoot)
    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container -ErrorAction SilentlyContinue)) { return $null }
    $destination = Join-Path $InstallRoot 'windows-msvc-relwithdebinfo'
    $sourceFull = [IO.Path]::GetFullPath($SourceRoot).TrimEnd('\')
    $destinationFull = [IO.Path]::GetFullPath($destination).TrimEnd('\')
    if ($sourceFull -ieq $destinationFull) {
        return Get-ChildItem -LiteralPath $destination -File -Filter '*.exe' -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '(?i)^dusklight.*\.exe$' -and (Test-TwilightExecutable $_.FullName) } |
               Select-Object -First 1
    }
    $items = @(Get-ChildItem -LiteralPath $SourceRoot -Force -ErrorAction Stop)
    [void][IO.Directory]::CreateDirectory($destination)
    foreach ($item in $items) {
        $target = Join-Path $destination $item.Name
        if ([IO.Path]::GetFullPath($item.FullName).TrimEnd('\') -ieq $destinationFull) { continue }
        Copy-Item -LiteralPath $item.FullName -Destination $target -Recurse -Force -ErrorAction Stop
    }
    return Get-ChildItem -LiteralPath $destination -File -Filter '*.exe' -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -match '(?i)^dusklight.*\.exe$' -and (Test-TwilightExecutable $_.FullName) } |
           Select-Object -First 1
}

# Fallback 5 is deliberately last because the archive is large. It decouples
# extraction from the chosen folder, discovers the payload in a clean tree,
# and then normalizes it into the stable Hub layout.
function Invoke-TwilightRecoveryExtraction {
    param([Parameter(Mandatory=$true)][string]$ArchivePath,[Parameter(Mandatory=$true)][string]$InstallRoot)
    $stage = Join-Path $InstallRoot ('.pcvrhub_dusklight_recovery_' + [Guid]::NewGuid().ToString('N'))
    $success = $false
    try {
        [void][IO.Directory]::CreateDirectory($stage)
        $result = Expand-TwilightArchive -Archive $ArchivePath -Destination $stage -Label 'Dusklight VR recovery'
        if ([string]$result -ne 'ok') { return $null }
        $found = Find-TwilightRuntime -InstallRoot $stage -ArchivePath $ArchivePath
        if (-not $found) { return $null }
        $canonicalExe = Copy-TwilightRuntimeToCanonical -SourceRoot $found.RuntimeRoot -InstallRoot $InstallRoot
        if (-not $canonicalExe -or -not (Test-TwilightExecutable $canonicalExe.FullName)) { return $null }
        $success = $true
        return [pscustomobject]@{ Exe=$canonicalExe.FullName; RuntimeRoot=$canonicalExe.DirectoryName; Method='fallback-5-clean-reextract' }
    } catch { return $null }
    finally {
        if (Test-Path -LiteralPath $stage) {
            try { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop } catch {
                if ($success) { Write-Warn "Recovery staging could not be removed: $stage" }
            }
        }
    }
}

function Resolve-TwilightRuntimeInteractively {
    param(
        [Parameter(Mandatory=$true)][string]$InstallRoot,
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [string]$RawInstallInput=''
    )
    $lastProblem = 'No functional Dusklight runtime was found after all automatic discovery and clean extraction routes.'
    while ($true) {
        try {
            $manual = Get-PCVRRecoveryInput
            $found = Find-TwilightRuntime -InstallRoot $InstallRoot -ArchivePath $ArchivePath -RawInstallInput $RawInstallInput `
                -AdditionalRoots $(if ($manual -and (Test-Path -LiteralPath $manual -PathType Container -ErrorAction SilentlyContinue)) { @($manual) } else { @() })

            if (-not $found -and $manual -and (Test-Path -LiteralPath $manual -PathType Leaf -ErrorAction SilentlyContinue)) {
                if ([IO.Path]::GetFileName($manual) -like 'dusklight*.exe' -and (Test-TwilightExecutable $manual)) {
                    $item = Get-Item -LiteralPath $manual -Force
                    $found = [pscustomobject]@{ Exe=$item.FullName; RuntimeRoot=$item.DirectoryName; Method='manual-executable' }
                } elseif ([IO.Path]::GetExtension($manual) -ieq '.zip') {
                    $found = Invoke-TwilightRecoveryExtraction -ArchivePath $manual -InstallRoot $InstallRoot
                } else {
                    $lastProblem = 'The supplied file is neither a valid Dusklight executable nor a readable ZIP payload.'
                }
            }

            if (-not $found) {
                $found = Invoke-TwilightRecoveryExtraction -ArchivePath $ArchivePath -InstallRoot $InstallRoot
            }
            if ($found -and (Test-TwilightExecutable $found.Exe)) {
                $canonicalRoot = Join-Path $InstallRoot $BUILD_SUB
                if ([IO.Path]::GetFullPath($found.RuntimeRoot).TrimEnd('\') -ine [IO.Path]::GetFullPath($canonicalRoot).TrimEnd('\')) {
                    $canonicalExe = Copy-TwilightRuntimeToCanonical -SourceRoot $found.RuntimeRoot -InstallRoot $InstallRoot
                    if (-not $canonicalExe) { throw 'The recovered runtime could not be normalized into the stable Hub layout.' }
                    $found = [pscustomobject]@{ Exe=$canonicalExe.FullName; RuntimeRoot=$canonicalExe.DirectoryName; Method=($found.Method+'-normalized') }
                }
                return $found
            }
        } catch {
            $lastProblem = $_.Exception.Message
        }

        $decision = Invoke-PCVRUniversalRecovery -FailureMessage $lastProblem -InstallerFolder $PSScriptRoot
        if ($decision.Action -eq 'retry') {
            $lastProblem = 'The retry still found no usable Dusklight runtime. Supply the extracted folder, dusklight.exe, or the release ZIP.'
            continue
        }
    }
}

$MOD_NAME    = "Dusklight VR"
$MOD_AUTHOR  = "JoeyAW"
$REPO        = "JoeyAW/TPVR"
$RELEASES    = "https://github.com/$REPO/releases"
$ASSET       = "TPVR-Windows-x64.zip"
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
$requestedDir = Get-PCVRRememberedGameFolder -ProbeFiles @('windows-msvc-relwithdebinfo\dusklight.exe')
$recoveryInstallRoot = Get-PCVRRecoveryInput -PathType Container
if ($recoveryInstallRoot) {
    $requestedDir = $recoveryInstallRoot
    Write-Info "Trying the folder handed over by installer recovery: $requestedDir"
} elseif (-not $requestedDir) {
    try { $requestedDir = (Read-Host "  Folder (Enter for the default)").Trim().Trim('"') } catch {}
} else {
    Write-Info "Using remembered install location: $requestedDir"
}
try { $dir = Resolve-TwilightInstallRoot -InputPath $requestedDir -DefaultPath $DEFAULT_DIR }
catch {
    throw "Install folder could not be resolved: $($_.Exception.Message)"
}
try { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
catch {
    throw "Could not create the selected install folder '$dir': $($_.Exception.Message)"
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
$have = Find-PredownloadedFile -Patterns @("TPVR-Windows*.zip", "Dusklight-VR-Windows*.zip", "*Dusklight*VR*.zip") -Label "the Dusklight VR release"
if ($have -and (Test-Path -LiteralPath $have)) {
    $zip = $have
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download $ASSET from the releases page, save it as '$zip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zip)) {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    throw 'No usable Dusklight archive is available. Retry, or drag the downloaded ZIP onto the recovery screen.'
}

# ---- 3. Entpacken ---------------------------------------------
Write-Step 3 5 "Unpacking"
Write-Host "  This takes a few minutes - it is a lot of small files." -ForegroundColor Gray
$extractResult = Expand-TwilightArchive -Archive $zip -Destination $dir -Label $MOD_NAME
$runtime = $null
if ([string]$extractResult -eq 'ok') {
    $runtime = Find-TwilightRuntime -InstallRoot $dir -ArchivePath $zip -RawInstallInput $requestedDir
} else {
    Write-Warn 'The first extraction did not produce a verified result.'
}

if ($runtime) {
    Write-Info "Runtime discovery: $($runtime.Method)"
    $canonicalRoot = Join-Path $dir $BUILD_SUB
    if ([IO.Path]::GetFullPath($runtime.RuntimeRoot).TrimEnd('\') -ine [IO.Path]::GetFullPath($canonicalRoot).TrimEnd('\')) {
        Write-Warn 'The publisher layout changed; normalizing it for stable Hub detection.'
        try {
            $canonicalExe = Copy-TwilightRuntimeToCanonical -SourceRoot $runtime.RuntimeRoot -InstallRoot $dir
            if ($canonicalExe) { $runtime = [pscustomobject]@{ Exe=$canonicalExe.FullName; RuntimeRoot=$canonicalExe.DirectoryName; Method=($runtime.Method + '-normalized') } }
        } catch { $runtime = $null; Write-Warn "Layout normalization failed: $($_.Exception.Message)" }
    }
}

if (-not $runtime -or -not (Test-TwilightExecutable $runtime.Exe)) {
    Write-Warn 'The first extraction tree could not be verified.'
    Write-Host '  Fallback 5 will now re-extract into a clean staging folder.' -ForegroundColor Gray
    Write-Host '  This is active recovery, not a frozen installer; the large archive' -ForegroundColor Gray
    Write-Host '  can take several more minutes to unpack a second time.' -ForegroundColor Gray
    $runtime = Invoke-TwilightRecoveryExtraction -ArchivePath $zip -InstallRoot $dir
}

if (-not $runtime -or -not (Test-TwilightExecutable $runtime.Exe)) {
    Write-Warn 'All automatic routes were exhausted. Manual recovery remains available.'
    Write-Host '  You may supply the extracted folder, dusklight.exe, or the release ZIP.' -ForegroundColor Yellow
    $runtime = Resolve-TwilightRuntimeInteractively -InstallRoot $dir -ArchivePath $zip -RawInstallInput $requestedDir
}
$exe = Get-Item -LiteralPath $runtime.Exe -Force
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
    throw 'Twilight Princess VR could not be restored after the post-copy survival check. Retry or supply the archive/runtime folder on the recovery screen.'
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
