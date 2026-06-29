# ============================================================
#   GameDetection.ps1  -  Read-only game install detection
# ============================================================
#
#  This library is a PURE LOOKUP TOOL. It does not modify
#  anything on disk, in the registry, or any game file. All
#  it ever does is ask "is this game installed, and where?".
#
#  USAGE in an installer:
#
#    . "$PSScriptRoot\..\Utils\GameDetection.ps1"
#
#    $result = Find-GameInstall -GameName "Starfield" `
#                               -Steam  @{ AppID = "1716740"; Folder = "Starfield" } `
#                               -Gamepass @{ Folder = "Starfield"; ContentSubfolder = $true } `
#                               -ExeName "Starfield.exe"
#
#    if ($result.Found) {
#        $gamePath = $result.Path
#        Write-Host "Found via $($result.Source): $gamePath"
#    } else {
#        # fall through to existing manual-input path
#    }
#
#  RETURN SHAPE (always a PSCustomObject):
#
#    Found       [bool]    true if any detector matched
#    Path        [string]  absolute game folder path (null if not found)
#    Source      [string]  which detector won:
#                          "Steam-Manifest" | "Steam-Scan" |
#                          "Gamepass-Appx" | "Gamepass-Scan" |
#                          "Epic"          | "GOG"          |
#                          "None"
#    Confidence  [string]  "High" | "Medium" | "Low"
#    Candidates  [array]   all matching candidates from all detectors
#                          (useful when a game exists in multiple stores)
#    Log         [array]   string lines describing what was tried
#
#  SAFETY:
#    - No writes anywhere. Ever.
#    - Every external call is in try/catch with ErrorAction Stop
#      so a malformed file or missing registry key just moves on.
#    - Returns "not found" rather than throwing.
# ============================================================

function New-DetectionResult {
    return [PSCustomObject]@{
        Found      = $false
        Path       = $null
        Source     = "None"
        Confidence = "None"
        Candidates = @()
        Log        = @()
    }
}

# ------------------------------------------------------------
#  STEAM
# ------------------------------------------------------------

function Get-SteamInstallPath {
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

function Get-SteamLibraries {
    param([Parameter(Mandatory)][string]$SteamPath)
    $libraries = @($SteamPath)
    $vdfPath = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $vdfPath) {
        try {
            $content = Get-Content $vdfPath -Raw -ErrorAction Stop
            $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
            foreach ($m in $found) {
                $lib = $m.Groups[1].Value -replace '\\\\', '\'
                if (Test-Path $lib) { $libraries += $lib }
            }
        } catch {}
    }
    # De-dupe while preserving order
    $seen = @{}
    $out  = @()
    foreach ($l in $libraries) {
        $k = $l.ToLowerInvariant()
        if (-not $seen.ContainsKey($k)) { $seen[$k] = $true; $out += $l }
    }
    return $out
}

function Get-SteamGameViaManifest {
    param(
        [Parameter(Mandatory)][string]$AppID,
        [Parameter(Mandatory)][array]$Libraries
    )
    # appmanifest_<AppID>.acf contains the authoritative "installdir" value.
    foreach ($lib in $Libraries) {
        $manifest = Join-Path $lib "steamapps\appmanifest_$AppID.acf"
        if (-not (Test-Path $manifest)) { continue }
        try {
            $content = Get-Content $manifest -Raw -ErrorAction Stop
            $m = [regex]::Match($content, '"installdir"\s+"([^"]+)"')
            if ($m.Success) {
                $installDir = $m.Groups[1].Value -replace '\\\\', '\'
                $gamePath   = Join-Path $lib "steamapps\common\$installDir"
                if (Test-Path $gamePath) { return $gamePath }
            }
        } catch {}
    }
    return $null
}

function Get-SteamGameViaScan {
    param(
        [Parameter(Mandatory)][string]$Folder,
        [Parameter(Mandatory)][array]$Libraries
    )
    foreach ($lib in $Libraries) {
        $candidate = Join-Path $lib "steamapps\common\$Folder"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# ------------------------------------------------------------
#  GAMEPASS / MICROSOFT STORE
# ------------------------------------------------------------

function Get-GamepassViaAppx {
    param([Parameter(Mandatory)][string]$PackageName)
    # Get-AppxPackage gives the canonical InstallLocation for MS Store apps.
    # We use -ErrorAction SilentlyContinue because calling this on systems
    # where Appx module is disabled should not throw.
    try {
        $pkg = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pkg -and $pkg.InstallLocation -and (Test-Path $pkg.InstallLocation)) {
            return $pkg.InstallLocation
        }
    } catch {}
    return $null
}

function Get-GamepassViaDriveScan {
    param(
        [Parameter(Mandatory)][string]$Folder,
        [bool]$ContentSubfolder = $true
    )
    # Xbox PC App installs to <drive>:\XboxGames\<Folder>\Content by default.
    # Users can change the install drive, so we scan all fixed drives.
    try {
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction Stop |
                  Where-Object { $_.Root -match '^[A-Z]:\\$' }
    } catch { return $null }

    foreach ($d in $drives) {
        $base = Join-Path $d.Root "XboxGames\$Folder"
        if ($ContentSubfolder) {
            $candidate = Join-Path $base "Content"
        } else {
            $candidate = $base
        }
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# ------------------------------------------------------------
#  EPIC GAMES
# ------------------------------------------------------------

function Get-EpicGameInstall {
    param(
        [string]$AppName,
        [string]$FolderName,
        [string]$ExeName
    )
    # Epic writes one .item manifest per installed game as JSON under
    # C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests\
    $manifestDir = "$env:ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
    if (-not (Test-Path $manifestDir)) { return $null }

    try {
        $items = Get-ChildItem -Path $manifestDir -Filter "*.item" -ErrorAction Stop
    } catch { return $null }

    foreach ($item in $items) {
        try {
            $json = Get-Content $item.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } catch { continue }

        # Guard every field access - some manifests have missing or malformed values
        $loc = $null
        try { $loc = $json.InstallLocation } catch { continue }
        if (-not $loc) { continue }
        try { if (-not (Test-Path $loc)) { continue } } catch { continue }

        # Strategy 1: match on AppName if provided (preferred)
        if ($AppName) {
            $appN  = try { $json.AppName }          catch { $null }
            $disp  = try { $json.DisplayName }      catch { $null }
            $main  = try { $json.MainGameAppName }  catch { $null }
            foreach ($c in @($appN, $disp, $main)) {
                if (-not $c) { continue }
                if ($c -eq $AppName -or $c -like "$AppName*") {
                    return $loc
                }
            }
        }

        # Strategy 2: match on InstallLocation folder basename against FolderName
        if ($FolderName) {
            try {
                $leaf = Split-Path $loc -Leaf -ErrorAction Stop
                if ($leaf -and ($leaf -ieq $FolderName -or $leaf -like "$FolderName*")) {
                    return $loc
                }
            } catch {}
        }

        # Strategy 3: match on exe presence
        if ($ExeName) {
            try {
                $exeHit = Get-ChildItem -Path $loc -Filter $ExeName -Recurse `
                    -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
                if ($exeHit) { return $loc }
            } catch {}
        }
    }
    return $null
}

# ------------------------------------------------------------
#  GOG
# ------------------------------------------------------------

function Get-GOGGameInstall {
    param([Parameter(Mandatory)][string]$GameID)
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\$GameID",
        "HKLM:\SOFTWARE\GOG.com\Games\$GameID"
    )) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).PATH
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

# ------------------------------------------------------------
#  UBISOFT CONNECT
# ------------------------------------------------------------

function Get-UbisoftGameInstall {
    <#
     Searches HKLM\SOFTWARE\WOW6432Node\Ubisoft\Launcher\Installs\<id>\InstallDir
     for a folder that matches $FolderName or contains $ExeName.
     Ubisoft does not store game display names in the registry, so matching is
     done on the install folder basename or on the presence of the known exe.
    #>
    param(
        [string]$FolderName,
        [string]$ExeName
    )

    $installsKey = "HKLM:\SOFTWARE\WOW6432Node\Ubisoft\Launcher\Installs"
    if (-not (Test-Path $installsKey)) { return $null }

    try {
        $subKeys = Get-ChildItem -Path $installsKey -ErrorAction Stop
    } catch { return $null }

    foreach ($sk in $subKeys) {
        try {
            $props = Get-ItemProperty -Path $sk.PSPath -ErrorAction Stop
            $installDir = $null
            try { $installDir = $props.InstallDir } catch {}
            if (-not $installDir) { continue }
            # Ubisoft stores paths with forward slashes sometimes - normalize.
            $installDir = ($installDir -replace '/', '\').TrimEnd('\')
            if (-not (Test-Path $installDir)) { continue }

            $baseName = $null
            try { $baseName = Split-Path $installDir -Leaf -ErrorAction Stop } catch { continue }
            if (-not $baseName) { continue }

            # Match on folder basename (case-insensitive)
            if ($FolderName -and ($baseName -ieq $FolderName -or $baseName -like "$FolderName*")) {
                return $installDir
            }

            # Match on exe presence (depth-limited to avoid crawling huge game folders)
            if ($ExeName) {
                try {
                    $exeHit = Get-ChildItem -Path $installDir -Filter $ExeName -Recurse `
                        -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
                    if ($exeHit) { return $installDir }
                } catch {}
            }
        } catch { continue }
    }
    return $null
}

# ------------------------------------------------------------
#  EA APP / ORIGIN
# ------------------------------------------------------------
#
#  EA uses two parallel registry namespaces for game installs:
#    1. HKLM\SOFTWARE\WOW6432Node\Origin Games\<contentID>
#       (the original Origin format, EA App inherits this)
#    2. HKLM\SOFTWARE\WOW6432Node\EA Games\<GameName>
#       (used for newer EA-published titles)
#
#  Both variants store an "Install Dir" value (note the space).
#  We scan both namespaces and match on folder basename or exe.
#
function Get-EAGameInstall {
    param(
        [string]$FolderName,
        [string]$ExeName
    )

    $rootKeys = @(
        "HKLM:\SOFTWARE\WOW6432Node\Origin Games",
        "HKLM:\SOFTWARE\WOW6432Node\EA Games",
        "HKLM:\SOFTWARE\Origin Games",
        "HKLM:\SOFTWARE\EA Games"
    )

    foreach ($root in $rootKeys) {
        if (-not (Test-Path $root)) { continue }
        try {
            $subKeys = Get-ChildItem -Path $root -ErrorAction Stop
        } catch { continue }

        foreach ($sk in $subKeys) {
            try {
                $props = Get-ItemProperty -Path $sk.PSPath -ErrorAction Stop
                $installDir = $null
                try { $installDir = $props.'Install Dir' } catch {}
                if (-not $installDir) {
                    try { $installDir = $props.InstallLocation } catch {}
                }
                if (-not $installDir) { continue }
                $installDir = ($installDir -replace '/', '\').TrimEnd('\')
                if (-not (Test-Path $installDir)) { continue }

                $baseName = $null
                try { $baseName = Split-Path $installDir -Leaf -ErrorAction Stop } catch { continue }
                if (-not $baseName) { continue }

                if ($FolderName -and ($baseName -ieq $FolderName -or $baseName -like "$FolderName*")) {
                    return $installDir
                }

                if ($ExeName) {
                    try {
                        $exeHit = Get-ChildItem -Path $installDir -Filter $ExeName -Recurse `
                            -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
                        if ($exeHit) { return $installDir }
                    } catch {}
                }
            } catch { continue }
        }
    }
    return $null
}

# ------------------------------------------------------------
#  MAIN ENTRY POINT
# ------------------------------------------------------------

function Find-GameInstall {
    <#
    .SYNOPSIS
      Locate a game installation across Steam, Xbox Game Pass, Epic, and GOG.

    .PARAMETER GameName
      Human-readable game name, used for logging only.

    .PARAMETER Steam
      Hashtable: @{ AppID = "..."; Folder = "..." }
      - AppID  : Steam AppID, triggers the most reliable appmanifest lookup.
      - Folder : steamapps\common\<Folder> name, used as fallback.
      Either key alone works; providing both is safest.

    .PARAMETER Gamepass
      Hashtable: @{ Folder = "..."; PackageName = "..."; ContentSubfolder = $true }
      - Folder : XboxGames\<Folder>\Content folder name (required for scan).
      - PackageName : Appx package name (optional, preferred over scan when present).
      - ContentSubfolder : true if the install has a \Content\ subfolder (Starfield does, some do not).

    .PARAMETER Epic
      Hashtable: @{ AppName = "..."; FolderName = "..."; ExeName = "..." }
      Tries AppName match first (most accurate), then matches install-folder
      basename, then searches for ExeName inside each registered install.
      Any single field is enough.

    .PARAMETER Ubisoft
      Hashtable: @{ FolderName = "..."; ExeName = "..." }
      Matches the install folder basename under Ubisoft Connect, or falls back
      to the presence of ExeName inside any registered Ubisoft install.

    .PARAMETER EAApp
      Hashtable: @{ FolderName = "..."; ExeName = "..." }
      Covers both EA App and legacy Origin via the "Origin Games" and "EA Games"
      registry namespaces. Matches on folder basename or ExeName presence.
      (Named EAApp rather than EA to avoid conflict with PowerShell's
      built-in -EA alias for -ErrorAction.)

    .PARAMETER GOG
      Hashtable: @{ GameID = "..." } (numeric GOG game ID)

    .PARAMETER ExeName
      If provided, candidates are verified by checking this exe exists in the path.
      Avoids false positives on empty folders or stubs.

    .OUTPUTS
      PSCustomObject with Found/Path/Source/Confidence/Candidates/Log.
    #>
    [CmdletBinding()]
    param(
        [string]$GameName = "<unknown>",
        [hashtable]$Steam,
        [hashtable]$Gamepass,
        [hashtable]$Epic,
        [hashtable]$Ubisoft,
        [hashtable]$EAApp,
        [hashtable]$GOG,
        [string]$ExeName
    )

    $result = New-DetectionResult
    $result.Log += "Searching for '$GameName'..."

    function Test-ExeIfRequired {
        param([string]$Path)
        if (-not $ExeName) { return $true }
        $full = Join-Path $Path $ExeName
        return (Test-Path $full)
    }

    function Add-Candidate {
        param($Path, [string]$Source, [string]$Confidence)
        if (-not $Path) { return }
        if (-not (Test-ExeIfRequired $Path)) {
            $result.Log += "  - $Source match at '$Path' but '$ExeName' missing, ignoring"
            return
        }
        $result.Candidates += [PSCustomObject]@{
            Path = $Path; Source = $Source; Confidence = $Confidence
        }
        $result.Log += "  + $Source match: $Path"
    }

    # ---- Steam (priority 1) ----
    if ($Steam) {
        try {
            $steamRoot = Get-SteamInstallPath
            if ($steamRoot) {
                $libs = Get-SteamLibraries -SteamPath $steamRoot
                $result.Log += "Steam root: $steamRoot  (libraries: $($libs.Count))"

                # 1a. ACF-based lookup (most reliable)
                if ($Steam.AppID) {
                    $p = Get-SteamGameViaManifest -AppID $Steam.AppID -Libraries $libs
                    if ($p) { Add-Candidate -Path $p -Source "Steam-Manifest" -Confidence "High" }
                }

                # 1b. Library scan via folder name
                if (-not ($result.Candidates | Where-Object { $_.Source -eq "Steam-Manifest" })) {
                    if ($Steam.Folder) {
                        $p = Get-SteamGameViaScan -Folder $Steam.Folder -Libraries $libs
                        if ($p) { Add-Candidate -Path $p -Source "Steam-Scan" -Confidence "Medium" }
                    }
                }
            } else {
                $result.Log += "Steam not installed or registry unreachable"
            }
        } catch {
            $result.Log += "Steam detection error: $($_.Exception.Message)"
        }
    }

    # ---- Gamepass (priority 2) ----
    if ($Gamepass) {
        try {
            if ($Gamepass.PackageName) {
                $p = Get-GamepassViaAppx -PackageName $Gamepass.PackageName
                if ($p) {
                    # Some Gamepass installs have a Content subfolder, some don't.
                    $withContent = Join-Path $p "Content"
                    if ((Test-Path $withContent) -and ($Gamepass.ContentSubfolder -ne $false)) {
                        Add-Candidate -Path $withContent -Source "Gamepass-Appx" -Confidence "High"
                    } else {
                        Add-Candidate -Path $p -Source "Gamepass-Appx" -Confidence "High"
                    }
                }
            }

            if ($Gamepass.Folder) {
                $useContent = if ($null -eq $Gamepass.ContentSubfolder) { $true } else { [bool]$Gamepass.ContentSubfolder }
                $p = Get-GamepassViaDriveScan -Folder $Gamepass.Folder -ContentSubfolder $useContent
                if ($p) {
                    # Don't add duplicate if Appx already found it
                    $already = $result.Candidates | Where-Object { $_.Path -eq $p }
                    if (-not $already) {
                        Add-Candidate -Path $p -Source "Gamepass-Scan" -Confidence "Medium"
                    }
                }
            }
        } catch {
            $result.Log += "Gamepass detection error: $($_.Exception.Message)"
        }
    }

    # ---- Epic (priority 3) ----
    if ($Epic) {
        try {
            $p = Get-EpicGameInstall `
                -AppName    $Epic.AppName `
                -FolderName $Epic.FolderName `
                -ExeName    $Epic.ExeName
            if ($p) { Add-Candidate -Path $p -Source "Epic" -Confidence "High" }
        } catch {
            $result.Log += "Epic detection error: $($_.Exception.Message)"
        }
    }

    # ---- Ubisoft Connect (priority 4) ----
    if ($Ubisoft) {
        try {
            $p = Get-UbisoftGameInstall -FolderName $Ubisoft.FolderName -ExeName $Ubisoft.ExeName
            if ($p) { Add-Candidate -Path $p -Source "Ubisoft" -Confidence "High" }
        } catch {
            $result.Log += "Ubisoft detection error: $($_.Exception.Message)"
        }
    }

    # ---- EA App / Origin (priority 5) ----
    if ($EAApp) {
        try {
            $p = Get-EAGameInstall -FolderName $EAApp.FolderName -ExeName $EAApp.ExeName
            if ($p) { Add-Candidate -Path $p -Source "EA" -Confidence "High" }
        } catch {
            $result.Log += "EA detection error: $($_.Exception.Message)"
        }
    }

    # ---- GOG (priority 6) ----
    if ($GOG -and $GOG.GameID) {
        try {
            $p = Get-GOGGameInstall -GameID $GOG.GameID
            if ($p) { Add-Candidate -Path $p -Source "GOG" -Confidence "High" }
        } catch {
            $result.Log += "GOG detection error: $($_.Exception.Message)"
        }
    }

    # ---- Pick winner ----
    if ($result.Candidates.Count -gt 0) {
        # Source priority, then Confidence within source
        $priority = @{
            "Steam-Manifest" = 1; "Steam-Scan"    = 2
            "Gamepass-Appx"  = 3; "Gamepass-Scan" = 4
            "Epic"           = 5; "Ubisoft"       = 6
            "EA"             = 7; "GOG"           = 8
        }
        $confMap = @{ "High" = 1; "Medium" = 2; "Low" = 3; "None" = 4 }
        $winner = $result.Candidates |
                  Sort-Object `
                    @{Expression={$priority[$_.Source]}}, `
                    @{Expression={$confMap[$_.Confidence]}} |
                  Select-Object -First 1

        $result.Found      = $true
        $result.Path       = $winner.Path
        $result.Source     = $winner.Source
        $result.Confidence = $winner.Confidence
        $result.Log       += "Winner: $($winner.Source) ($($winner.Confidence)) -> $($winner.Path)"
    } else {
        $result.Log += "No install detected across any store"
    }

    return $result
}

# ------------------------------------------------------------
#  ONE-LINE HELPER FOR INSTALLERS
# ------------------------------------------------------------
#
#  This is the simplest possible entry point for existing
#  installers. It returns ONLY the path string or $null, so
#  a migrated installer can do:
#
#    $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title $GAME_TITLE
#    # ... existing legacy lookup code stays as fallback ...
#
#  If the library cannot find the game OR anything throws,
#  this returns $null and the installer falls through to its
#  existing legacy behaviour. Safe by design.
#
function Try-FindSteamGame {
    param(
        [Parameter(Mandatory)][string]$Folder,
        [string]$Title      = $Folder,
        [string]$AppID,
        [string]$ExeName
    )
    try {
        $steamHash = @{ Folder = $Folder }
        if ($AppID) { $steamHash.AppID = $AppID }

        $params = @{
            GameName = $Title
            Steam    = $steamHash
        }
        if ($ExeName) { $params.ExeName = $ExeName }

        $r = Find-GameInstall @params
        if ($r.Found) {
            Write-Host "  [..] Detection library: $($r.Source) match" -ForegroundColor DarkGray
            return $r.Path
        }
    } catch {
        # Any failure: silently return null so legacy path takes over.
        Write-Host "  [..] Detection library error (falling back to legacy lookup): $_" -ForegroundColor DarkGray
    }
    return $null
}
