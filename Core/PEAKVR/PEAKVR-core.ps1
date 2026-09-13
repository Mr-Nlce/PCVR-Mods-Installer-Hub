# ============================================================
#  PEAK VR Installer
# ============================================================
#  Three routes, two VR mods and three game builds:
#
#    [1] PeakVR by Andrey04o  - into the normal Steam copy. This
#        route is currently broken by PEAK's 2026-08-27 update.
#        THIS PART WAS REWRITTEN FROM SCRATCH ON 2026-08-19.
#    [2] PeakVR by Andrey04o  - recommended pinned PEAK 2.1.a in
#        C:\Games\PEAK VR 2.1a, with PeakVersionBypass.
#    [3] PEAK_VR by AstienVR  - its own folder with pinned PEAK
#        1.44.a. The original route remains below the divider.
#
#  ------------------------------------------------------------
#  WHY IT WAS REWRITTEN, AND WHAT IS DIFFERENT NOW
#  ------------------------------------------------------------
#  The old version kept making decisions WHILE installing: it
#  installed, then checked, fetched what was missing, checked
#  again. Every fault of that evening came out of that
#  interleaving - endless loops, half-installed states, warnings
#  that multiplied with every round.
#
#  THE NEW VERSION SEPARATES THREE PHASES STRICTLY:
#
#    PHASE 1  PLAN     - work everything out, touch nothing.
#    PHASE 2  FETCH    - download and verify everything, still
#                        touching nothing in the game.
#    PHASE 3  INSTALL  - only once the WHOLE plan stands is
#                        anything written. After that nothing is
#                        downloaded and nothing is decided.
#
#  WHY THIS CANNOT HANG, short and checkable:
#    - Phase 1 is a breadth-first search over a SET. Every package
#      name enters the queue AT MOST ONCE, so it ends after at
#      most as many steps as there are packages. No repetition,
#      no asking twice.
#    - Every package is queried over the network AT MOST ONCE and
#      downloaded AT MOST ONCE. A failure is remembered too, so it
#      is not retried.
#    - Phase 3 is a plain list with no conditions and no loop
#      waiting on a state.
#    - There is NO while loop in this part apart from the input
#      prompts, and those are capped at 20 attempts.
#
#  CURRENT-ROUTE DEPENDENCY VERSIONS ARE MINIMUMS, NOT PINS.
#  Thunderstore names a version for every dependency. If one
#  package asks for 1.6.0 and another for 1.7.2, then 1.7.2
#  satisfies both. So, on option 1, the highest requirement wins.
#  Option 2 is different: its tested PeakVR 1.4.1 package and every
#  exact dependency version named by the package manifests stay
#  frozen together with the PEAK 2.1.a game depot.
#
#  THE MAIN MOD SHIPS ON TWO TRACKS. Andrey publishes on GitHub;
#  Thunderstore follows later or not at all. 1.4.1 ("Fixed: The
#  loading screen could stay over the whole view after spawning
#  in") sat on GitHub for four days while Thunderstore still
#  served 1.4.0. Both are queried and the newer one wins.
# ============================================================

$Host.UI.RawUI.WindowTitle = "PEAK VR Installer"
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# -------------------------------------------------------
#  Depot-route settings (used further down)
# -------------------------------------------------------
$MOD_NAME       = "PEAK_VR v1.0.0 (by AstienVR)"
$MOD_URL        = "https://github.com/AstienVR/PEAK_VR/releases/download/1.0.0/PEAK_VR.zip"
$GITHUB_URL     = "https://github.com/AstienVR/PEAK_VR"
$BYPASS_NAME    = "PeakVersionBypass v1.0.2 (by kirigiri)"
$BYPASS_URL     = "https://thunderstore.io/package/download/kirigiri/PeakVersionBypass/1.0.2/"
$BYPASS_PAGE    = "https://thunderstore.io/package/kirigiri/PeakVersionBypass/"
$BYPASS_DLL     = "PeakVersionBypass.dll"
$DEPOT_APPID    = "3527290"
$DEPOT_DEPOTID  = "3527291"
$DEPOT_MANIFEST = "1663614006819171465"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"
$GAME_EXE       = "PEAK.exe"
$DEFAULT_PATH   = "C:\Games\PEAK VR"
$ANDREY_DEPOT_MANIFEST = "4845579380240751548"
$ANDREY_DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $ANDREY_DEPOT_MANIFEST"
$ANDREY_DEFAULT_PATH   = "C:\Games\PEAK VR 2.1a"
$ANDREY_BYPASS_NAME    = "PeakVersionBypass v1.2.0 (by RadiatorExtrem)"
$ANDREY_BYPASS_URL     = "https://thunderstore.io/package/download/RadiatorExtrem/PeakVersionBypass/1.2.0/"
$ANDREY_BYPASS_PAGE    = "https://thunderstore.io/c/peak/p/RadiatorExtrem/PeakVersionBypass/"
$ANDREY_BYPASS_MARKER  = ".pcvrhub-peak-version-bypass-1.2.0"
$ANDREY_PINNED_MOD_VERSION = "1.4.1"
$ANDREY_PINNED_MOD_ASSET   = "Andrey04o-PeakVR-1.4.1.zip"
$ANDREY_PINNED_MOD_URL     = "https://github.com/Andrey04o/PeakVR/releases/download/v1.4.1/Andrey04o-PeakVR-1.4.1.zip"
$ANDREY_CURRENT_FALLBACK_VERSION = "1.5.0"
$ANDREY_CURRENT_FALLBACK_GITHUB  = "https://github.com/Andrey04o/PeakVR/releases/download/v1.5.0/Andrey04o-PeakVR-1.5.0.zip"
$ANDREY_CURRENT_FALLBACK_TS      = "https://gcdn.thunderstore.io/live/repository/packages/Andrey04o-PeakVR-1.5.0.zip"
$VIGEM_REL_PATH = "BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe"

# -------------------------------------------------------
#  Ausgabe
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " PEAK VR Installer" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($num, $total, $text)
    Write-Host ""
    Write-Host "  [$num/$total] $text" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}

# EVERY prompt is bounded. With no console - task scheduler, a pipe,
# a closed window - Read-Host returns an empty line immediately, and
# an unbounded prompt would then spin forever.
function Read-Choice {
    param([string]$Prompt, [string[]]$Valid, [string]$Default = $null)
    for ($i = 0; $i -lt 20; $i++) {
        # ("" + ...) CATCHES $null: with the input closed Read-Host returns
        # $null, and .Trim() on it throws - with ErrorActionPreference
        # Stop that would have aborted the whole installer. Reproduced
        # on real PowerShell 7.4 with empty input.
        $a = ("" + (Read-Host "  $Prompt")).Trim()
        foreach ($v in $Valid) { if ($a -eq $v) { return $v } }
        Write-Warn ("Please answer with: " + ($Valid -join " / "))
    }
    Write-Warn "No usable answer after 20 tries."
    return $Default
}
function Read-YesNoP { param([string]$Prompt)
    $a = Read-Choice -Prompt "$Prompt [Y/N]" -Valid @("Y","y","N","n") -Default "N"
    return ($a -eq "Y" -or $a -eq "y")
}

function Find-7Zip {
    foreach ($c in @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )) { if (Test-Path $c) { return $c } }
    return $null
}

function Get-SteamPathP {
    foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try {
            $v = Get-ItemProperty -Path $r -ErrorAction Stop
            if ($v.InstallPath) { return $v.InstallPath }
            if ($v.SteamPath)   { return $v.SteamPath }
        } catch {}
    }
    return $null
}
function Get-SteamLibrariesP { param($sp)
    $libs = @($sp)
    $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s*"([^"]+)"')) {
            $l = $m.Groups[1].Value -replace '\\\\','\'
            if (Test-Path $l) { $libs += $l }
        }
    }
    return $libs
}

# -------------------------------------------------------
#  Versionsvergleich
# -------------------------------------------------------
# Returns -1 / 0 / 1. Everything after a non-digit is cut off
# ("1.4.1-beta" -> "1.4.1") so [version] accepts it; if the
# comparison still fails, it falls back to a string compare
# instead of throwing.
function Compare-ModVersion { param([string]$a,[string]$b)
    if ($a -eq $b) { return 0 }
    if (-not $a) { return -1 }
    if (-not $b) { return 1 }
    try {
        $va = [version](($a -replace '^[vV]','') -replace '[^0-9.].*$','')
        $vb = [version](($b -replace '^[vV]','') -replace '[^0-9.].*$','')
        if ($va -gt $vb) { return 1 }
        if ($va -lt $vb) { return -1 }
        return 0
    } catch {
        if ($a -gt $b) { return 1 }
        if ($a -lt $b) { return -1 }
        return 0
    }
}

# -------------------------------------------------------
#  Network: every address is queried AT MOST ONCE
# -------------------------------------------------------
# Failures are cached too. That is the difference from the old
# version, where a throttled package was queried again in every
# round - against the very service that was throttling us.
$script:Net       = @{}
$script:NetFails  = @{}

function Get-Json { param([string]$Url, [string]$Key)
    if ($script:Net.ContainsKey($Key)) { return $script:Net[$Key] }
    $r = $null
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $r = Invoke-RestMethod -Uri $Url -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    } catch {
        $script:NetFails[$Key] = $_.Exception.Message
        $r = $null
    }
    $script:Net[$Key] = $r
    return $r
}

function Get-ThunderstorePackage { param([string]$Author, [string]$Name)
    $k = "ts:$Author/$Name".ToLowerInvariant()
    $d = Get-Json -Url "https://thunderstore.io/api/experimental/package/$Author/$Name/" -Key $k
    if (-not $d -or -not $d.latest) { return $null }
    return @{
        Version      = [string]$d.latest.version_number
        Url          = [string]$d.latest.download_url
        Dependencies = @($d.latest.dependencies)
    }
}

function Get-GithubRelease { param([string]$Repo, [string]$AssetPattern)
    $k = "gh:$Repo".ToLowerInvariant()
    $d = Get-Json -Url "https://api.github.com/repos/$Repo/releases/latest" -Key $k
    if (-not $d) { return $null }
    $a = @($d.assets) | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1
    if (-not $a -or -not $a.browser_download_url) { return $null }
    return @{
        Version = ([string]$d.tag_name) -replace '^[vV]',''
        Url     = [string]$a.browser_download_url
        Asset   = [string]$a.name
        Body    = [string]$d.body
    }
}

# -------------------------------------------------------
#  Paket-Werkzeuge
# -------------------------------------------------------
# Thunderstore dependencies are named "namespace-name-version".
# Split from the END: the name may contain hyphens, the version
# may not.
function Split-DependencyString { param([string]$Dep)
    if (-not $Dep) { return $null }
    $p = [string]$Dep -split '-'
    if ($p.Count -lt 3) { return $null }
    return @{
        Author  = $p[0]
        Name    = ($p[1..($p.Count-2)]) -join '-'
        Version = $p[-1]
        Key     = ($p[0] + "-" + (($p[1..($p.Count-2)]) -join '-'))
    }
}

# The dependencies are inside the package ITSELF (manifest.json).
# That is the most reliable source: it belongs to exactly the
# build we are holding, and it needs no network.
function Get-ManifestDependencies { param([string]$ZipPath)
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $z = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        try {
            $e = $z.Entries | Where-Object { $_.FullName -eq "manifest.json" } | Select-Object -First 1
            if (-not $e) { return $null }
            $sr = New-Object System.IO.StreamReader($e.Open())
            try { $json = $sr.ReadToEnd() } finally { $sr.Dispose() }
            $m = $json | ConvertFrom-Json
            return @($m.dependencies)
        } finally { $z.Dispose() }
    } catch { return $null }
}

function Get-InstalledVersion { param([string]$Key, [string]$GamePath)
    $f = Join-Path $GamePath "BepInEx\.ts_versions\$Key"
    if (Test-Path -LiteralPath $f) { return (Get-Content -LiteralPath $f -Raw).Trim() }
    return $null
}
function Set-InstalledVersion { param([string]$Key, [string]$Version, [string]$GamePath)
    $d = Join-Path $GamePath "BepInEx\.ts_versions"
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Set-Content -LiteralPath (Join-Path $d $Key) -Value $Version -Encoding UTF8 -Force
}

# Thunderstore layout -> game folder.
#   BepInExPack_PEAK\  is a wrapper folder; its CONTENT belongs in
#                      die Spielwurzel
#   plugins\ patchers\ monomod\  go under BepInEx\, and every
#                      package gets its own folder in there
#   core\ config\      are shared, with no subfolder
function Install-Package { param([string]$Zip, [string]$Work, [string]$GamePath, [string]$Key, [switch]$ReplaceOwnedFolders)
    if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $Work -Force | Out-Null
    Expand-Archive -LiteralPath $Zip -DestinationPath $Work -Force -ErrorAction Stop

    $meta = @("manifest.json","icon.png","README.md","CHANGELOG.md","LICENSE")
    $root = $Work
    # -Force, because .doorstop_version is a dot file
    $top = @(Get-ChildItem -LiteralPath $Work -Force | Where-Object { $_.Name -notin $meta })
    if ($top.Count -eq 1 -and $top[0].PSIsContainer -and $top[0].Name -notin @("BepInEx","plugins","patchers","monomod","core","config")) {
        $root = $top[0].FullName
    }
    $copied = 0
    foreach ($item in @(Get-ChildItem -LiteralPath $root -Force | Where-Object { $_.Name -notin $meta })) {
        if ($item.PSIsContainer -and $item.Name -in @("plugins","patchers","monomod","core","config")) {
            $dest = Join-Path $GamePath ("BepInEx\" + $item.Name + "\" + $Key)
            if ($item.Name -in @("core","config")) { $dest = Join-Path $GamePath ("BepInEx\" + $item.Name) }
            elseif ($ReplaceOwnedFolders -and (Test-Path -LiteralPath $dest -PathType Container)) {
                # Only package-owned, namespaced folders are replaced. Shared
                # core/config and every unrelated mod or user config survive.
                Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction Stop
            }
            if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
            # -Path, NOT -LiteralPath: otherwise the * is taken literally
            Copy-Item -Path (Join-Path $item.FullName "*") -Destination $dest -Recurse -Force
            $copied += @(Get-ChildItem -LiteralPath $item.FullName -Recurse -File).Count
        } else {
            Copy-Item -LiteralPath $item.FullName -Destination $GamePath -Recurse -Force
            if ($item.PSIsContainer) { $copied += @(Get-ChildItem -LiteralPath $item.FullName -Recurse -File).Count } else { $copied++ }
        }
    }
    return $copied
}

# -------------------------------------------------------
#  Recommended pinned build for Andrey04o's PeakVR
# -------------------------------------------------------
# Steam uses one content folder for every manifest of this depot. Do not
# treat an arbitrary leftover depot as 2.1.a: the user is always shown the
# exact command, and the stable target receives a manifest proof file after
# the verified move. A completed Hub install can therefore be reused safely.
function Get-AndreyDepotDurablePathFile {
    try {
        $localState = [Environment]::GetFolderPath('LocalApplicationData')
        if ([string]::IsNullOrWhiteSpace($localState)) { return $null }
        return [IO.Path]::Combine($localState, 'PCVR Mods Installer Hub', 'State', '3527290_PEAK_VR', 'installed_path_depot.txt')
    } catch { return $null }
}

function Get-AndreyDepotInstalledPath {
    param(
        [string]$DefaultPath = $ANDREY_DEFAULT_PATH,
        [string]$HubPathFile = (Join-Path $PSScriptRoot '.installed_path_depot'),
        [string]$DurablePathFile = (Get-AndreyDepotDurablePathFile)
    )

    $candidates = @($DefaultPath)
    foreach ($record in @($HubPathFile, $DurablePathFile)) {
        if ([string]::IsNullOrWhiteSpace($record) -or -not (Test-Path -LiteralPath $record -PathType Leaf)) { continue }
        try {
            $candidate = ('' + (Get-Content -LiteralPath $record -Raw -ErrorAction Stop)).Trim().Trim('"')
            if ($candidate -and $candidates -notcontains $candidate) { $candidates = @($candidate) + $candidates }
        } catch {}
    }

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        # Never let a stale or hand-edited record turn the normal Steam copy
        # into the pinned route, even if somebody copied the proof file there.
        if ($candidate -match '(?i)steamapps[\\/]+common[\\/]+PEAK[\\/]*$') { continue }
        $exe = Join-PathLexical $candidate $GAME_EXE
        $proofFile = Join-PathLexical $candidate '.pcvrhub_depot_manifest'
        if (-not (Test-LiteralPathSafe -Path $exe -PathType Leaf) -or
            -not (Test-LiteralPathSafe -Path $proofFile -PathType Leaf)) { continue }
        try {
            $proof = ('' + (Get-Content -LiteralPath $proofFile -Raw -ErrorAction Stop)).Trim()
            if ($proof -eq $ANDREY_DEPOT_MANIFEST) { return $candidate }
        } catch {}
    }
    return $null
}

function Save-AndreyDepotPathRecords {
    param([string]$GamePath, [string]$Version)
    if ([string]::IsNullOrWhiteSpace($GamePath)) { return }
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($record in @(
        (Join-Path $PSScriptRoot '.installed_path'),
        (Join-Path $PSScriptRoot '.installed_path_depot'),
        (Get-AndreyDepotDurablePathFile)
    )) {
        if ([string]::IsNullOrWhiteSpace($record)) { continue }
        try {
            $parent = Split-Path -Parent $record
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
            [IO.File]::WriteAllText($record, $GamePath.Trim(), $enc)
        } catch {}
    }
    if (-not [string]::IsNullOrWhiteSpace($Version)) {
        try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version_depot'), $Version.Trim(), $enc) } catch {}
        Save-InstalledStamp -GameDir $GamePath -Version $Version
    }
}

function Ensure-AndreyDepotShortcut {
    param([string]$GamePath)
    try {
        $gameExePath = Join-Path $GamePath $GAME_EXE
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\PEAK VR 2.1a.lnk" -TargetPath $gameExePath `
                  -WorkingDir $GamePath -IconPath "$gameExePath,0" -Arguments $D3D11_ARG
        if ($sc) { Write-OK "Desktop shortcut 'PEAK VR 2.1a' created." }
    } catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }
}

function Install-AndreyDepotBuild {
    $existingPath = Get-AndreyDepotInstalledPath
    if ($existingPath) {
        Write-OK "PEAK 2.1.a depot already installed: $existingPath"
        return $existingPath
    }

    $targetPath = $ANDREY_DEFAULT_PATH
    $manifestProof = Join-PathLexical $targetPath ".pcvrhub_depot_manifest"
    $targetExe = Join-PathLexical $targetPath $GAME_EXE

    Write-Header
    Write-Host "  RECOMMENDED: PEAK 2.1.a + PeakVR by Andrey04o" -ForegroundColor Green
    Write-Host "  This creates a separate pinned game copy. Your current Steam" -ForegroundColor White
    Write-Host "  install and the older AstienVR depot are not touched." -ForegroundColor White
    Write-Host ""
    Write-Host "  Steam Console command:" -ForegroundColor Gray
    Write-Host "    $ANDREY_DEPOT_COMMAND" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Manifest $ANDREY_DEPOT_MANIFEST = PEAK 2.1.a (13 August 2026)." -ForegroundColor Gray
    Write-Host "  Steam must be running, logged in, and PEAK must be owned." -ForegroundColor Gray
    Write-Host ""
    # LOOK BEFORE ASKING: Steam keeps completed depots under
    # steamapps\content.  A retry or interrupted earlier run must reuse those
    # files instead of prompting the user to download the same 4 GB again.
    $steamInstallPath = Get-SteamPathP
    $probePaths = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -AdditionalSteamRoots @($steamInstallPath))
    $depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamInstallPath)
    if (-not $depotPath) {
        Pause-User "Press Enter to prepare the Steam depot download..." | Out-Null
        try { Set-Clipboard -Value $ANDREY_DEPOT_COMMAND } catch {}
        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host "   ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host "  The exact command is in your clipboard. Paste it with Ctrl+V" -ForegroundColor White
        Write-Host "  into Steam Console, press Enter, and wait for completion." -ForegroundColor White
        Write-Host ""
        foreach ($cu in @("steam://open/console", "steam://nav/console")) {
            try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
        }
        Pause-User "Press Enter once this exact depot download is complete..." | Out-Null

        $depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamInstallPath)
        if (-not $depotPath) {
            $depotPath = Resolve-DepotPath -GameName "PEAK 2.1.a" -DepotCommand $ANDREY_DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $ANDREY_DEPOT_MANIFEST
        }
    } else {
        Write-OK "The completed PEAK 2.1.a depot is already downloaded: $depotPath"
        Write-Info "Skipping Steam Console - nothing needs to be fetched again."
    }
    if (-not $depotPath -or -not (Test-LiteralPathSafe -Path (Join-PathLexical $depotPath $GAME_EXE) -PathType Leaf)) {
        Write-Fail "The completed PEAK depot could not be verified. Nothing was moved."
        return $null
    }
    Write-OK "Downloaded depot found: $depotPath"

    Write-Host ""
    Write-Host "  Default install location: $ANDREY_DEFAULT_PATH" -ForegroundColor Gray
    $userInput = ("" + (Read-Host "  Press Enter to use default, or type a different full path")).Trim().Trim('"')
    if ($userInput) { $targetPath = $userInput }
    if ($targetPath -match '(?i)steamapps[\\/]+common[\\/]+PEAK[\\/]*$') {
        Write-Fail "The pinned build cannot replace the normal Steam copy."
        return $null
    }
    if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) {
        Write-Fail "The target folder is not writable: $targetPath"
        return $null
    }

    if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
        Write-Warn "A folder already exists at $targetPath"
        Write-Info "The depot is merged safely; existing BepInEx configs and extra files remain."
    }
    try {
        $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "PEAK 2.1.a depot build"
        if (-not (Test-LiteralPathSafe -Path (Join-PathLexical $targetPath $GAME_EXE) -PathType Leaf)) {
            throw "$GAME_EXE is missing after the verified move"
        }
        Set-Content -LiteralPath (Join-PathLexical $targetPath "steam_appid.txt") -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
        Set-Content -LiteralPath (Join-PathLexical $targetPath ".pcvrhub_depot_manifest") -Value $ANDREY_DEPOT_MANIFEST -Encoding ASCII -NoNewline -Force
        Write-OK "PEAK 2.1.a pinned at: $targetPath"
        return $targetPath
    } catch {
        Write-Fail "The depot could not be installed safely: $($_.Exception.Message)"
        Write-Info "The downloaded files remain recoverable at: $depotPath"
        return $null
    }
}

function Install-AndreyDepotVersionBypass {
    param([string]$GamePath)
    $bypassDst = Join-PathLexical $GamePath "BepInEx\plugins\$BYPASS_DLL"
    $markerPath = Join-PathLexical $GamePath "BepInEx\plugins\$ANDREY_BYPASS_MARKER"
    if ((Test-LiteralPathSafe -Path $bypassDst -PathType Leaf) -and
        (Test-LiteralPathSafe -Path $markerPath -PathType Leaf)) {
        Write-OK "$BYPASS_DLL is already installed for the 2.1.a depot."
        return $true
    }
    if (Test-LiteralPathSafe -Path $bypassDst -PathType Leaf) {
        Write-Warn "An existing $BYPASS_DLL will be backed up before the pinned 1.2.0 package is installed."
    }

    Write-Info "Adding $ANDREY_BYPASS_NAME for the pinned game build..."
    $bypassTmp = Join-Path $env:TEMP ("PeakVersionBypass_Andrey_" + [Guid]::NewGuid().ToString("N"))
    $bypassZip = Join-Path $bypassTmp "PeakVersionBypass.zip"
    $bypassExtract = Join-Path $bypassTmp "extract"
    $bypassStaged = "$bypassDst.pcvrhub-new"
    $bypassBackup = "$bypassDst.pre-pcvrhub"
    $rollbackCopy = Join-Path $bypassTmp "previous-$BYPASS_DLL"
    $hadExisting = Test-LiteralPathSafe -Path $bypassDst -PathType Leaf
    New-Item -ItemType Directory -Path $bypassTmp -Force | Out-Null
    try {
        $download = Invoke-DownloadOrFallback -Url $ANDREY_BYPASS_URL -Destination $bypassZip `
            -Label "PEAK 2.1.a Version Bypass" -ManualUrl $ANDREY_BYPASS_PAGE `
            -Instructions "Download RadiatorExtrem PeakVersionBypass v1.2.0, place its ZIP at '$bypassZip', then choose Retry." `
            -SkipMessage "Skipped - the pinned build cannot pass PEAK's version check without this plugin."
        if ([string]$download -eq "quit" -or -not (Test-LiteralPathSafe -Path $bypassZip -PathType Leaf)) { return $false }
        $expanded = Expand-ArchiveOrFallback -ArchivePath $bypassZip -DestinationFolder $bypassExtract -Label "PeakVersionBypass" `
            -SkipMessage "Skipped - PeakVersionBypass was not extracted."
        if ([string]$expanded -notin @("ok","manual")) { return $false }
        $source = Get-ChildItem -LiteralPath $bypassExtract -Filter $BYPASS_DLL -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $source) { Write-Fail "$BYPASS_DLL was not found in the downloaded package."; return $false }
        $plugins = Split-Path -Parent $bypassDst
        if (-not (Test-LiteralPathSafe -Path $plugins -PathType Container)) { New-Item -ItemType Directory -Path $plugins -Force | Out-Null }
        if ($hadExisting) { Copy-Item -LiteralPath $bypassDst -Destination $rollbackCopy -Force }
        Copy-Item -LiteralPath $source.FullName -Destination $bypassStaged -Force
        if ((Test-LiteralPathSafe -Path $bypassDst -PathType Leaf) -and -not (Test-LiteralPathSafe -Path $bypassBackup -PathType Leaf)) {
            Copy-Item -LiteralPath $bypassDst -Destination $bypassBackup
        }
        Copy-Item -LiteralPath $bypassStaged -Destination $bypassDst -Force
        if (-not (Test-LiteralPathSafe -Path $bypassDst -PathType Leaf)) { throw "$BYPASS_DLL was not copied into the depot." }
        Set-Content -LiteralPath $markerPath -Value "RadiatorExtrem-PeakVersionBypass-1.2.0" -Encoding ASCII -NoNewline -Force
        Write-OK "$BYPASS_DLL installed from the pinned 1.2.0 package."
        return $true
    } catch {
        if ($hadExisting -and (Test-LiteralPathSafe -Path $rollbackCopy -PathType Leaf)) {
            try { Copy-Item -LiteralPath $rollbackCopy -Destination $bypassDst -Force } catch {}
        } elseif (-not $hadExisting) { try { Remove-Item -LiteralPath $bypassDst -Force -ErrorAction SilentlyContinue } catch {} }
        Write-Fail "PeakVersionBypass failed: $($_.Exception.Message)"
        return $false
    } finally {
        try { Remove-Item -LiteralPath $bypassStaged -Force -ErrorAction SilentlyContinue } catch {}
        try { Remove-Item -LiteralPath $bypassTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}

# -------------------------------------------------------
#  The main mod and what it stands on
# -------------------------------------------------------
$MOD_KEY        = "Andrey04o-PeakVR"
$MOD_AUTHOR     = "Andrey04o"
$MOD_TSNAME     = "PeakVR"
$MOD_GITHUB     = "Andrey04o/PeakVR"
$MOD_GH_ASSET   = '(?i)^Andrey04o-PeakVR-.*\.zip$'
$MOD_PROOF      = "BepInEx\plugins\Andrey04o-PeakVR\com.andrey04o.PeakVR.dll"
# Launch option the author recommends (framerate). Declared up here
# so the closing text and the clipboard use the same value.
$D3D11_ARG      = "-force-d3d11"

# ------------------------------------------------------------
#  HARD UPPER BOUNDS
# ------------------------------------------------------------
# There is not a single loop left in this branch whose end depends
# on a condition. Each runs on a counter with a fixed upper bound -
# the number of passes is settled BEFORE the first one starts. If a
# limit is reached, the run aborts with a message, having changed
# nothing in the game.
$MAX_RESOLVE_STEPS = 500   # steps of the dependency search
$MAX_CROSS_ROUNDS  = 10    # rounds of the cross-check
# BepInEx is the loader, not an ordinary package - it is always
# installed first and never pulled in by the dependency search.
$LOADER_KEY     = "BepInEx-BepInExPack_PEAK"
$LOADER_AUTHOR  = "BepInEx"
$LOADER_NAME    = "BepInExPack_PEAK"
$LOADER_MIN     = "5.4.75301"

Write-Header
Write-Host "  Three PEAK VR installs can coexist. Pick one:" -ForegroundColor White
Write-Host ""
Write-Host "  [1] Current PEAK" -NoNewline -ForegroundColor White
Write-Host "  - PeakVR by Andrey04o" -ForegroundColor Gray
Write-Host "       CURRENTLY RECOMMENDED" -ForegroundColor Green
Write-Host "       PeakVR 1.5.0 supports the current PEAK 2.4.b build." -ForegroundColor Gray
Write-Host ""
$andreyDepotPath = Get-AndreyDepotInstalledPath
Write-Host "  [2] PEAK 2.1.a depot" -NoNewline -ForegroundColor White
Write-Host "  - PeakVR by Andrey04o" -ForegroundColor Gray
Write-Host "       LAST-CONFIRMED FALLBACK" -ForegroundColor Yellow
if ($andreyDepotPath) { Write-Host "       Already installed at $andreyDepotPath" -ForegroundColor Green }
else                    { Write-Host "       Separate pinned build with version-check bypass." -ForegroundColor Gray }
Write-Host ""
$legacyDepotHere = Test-Path -LiteralPath (Join-Path $DEFAULT_PATH $GAME_EXE)
Write-Host "  [3] Older PEAK 1.44.a depot" -NoNewline -ForegroundColor White
Write-Host "  - PEAK_VR by AstienVR" -ForegroundColor Gray
if ($legacyDepotHere) { Write-Host "       Already installed at $DEFAULT_PATH" -ForegroundColor Green }
else                  { Write-Host "       Downloads the legacy pinned build into its own folder." -ForegroundColor Gray }
Write-Host ""
$peakMode = Read-Choice -Prompt "Your choice (1, 2 or 3)" -Valid @("1","2","3") -Default $null
if (-not $peakMode) {
    Write-Fail "No choice made - nothing was changed."
    Pause-User "Press Enter to exit..." | Out-Null
    return
}

if ($peakMode -in @("1","2")) {

    # ===================================================
    #  PHASE 0 - find the game
    # ===================================================
    Write-Step 1 4 $(if ($peakMode -eq "2") { "Preparing the PEAK 2.1.a depot" } else { "Finding your PEAK installation" })
    $gamePath = if ($peakMode -eq "2") { Install-AndreyDepotBuild } else { $null }
    if ($peakMode -eq "1") {
        $sp = Get-SteamPathP
        if ($sp) {
            foreach ($lib in (Get-SteamLibrariesP $sp)) {
                # Lexical: $lib comes from libraryfolders.vdf and may name a drive
                # that no longer exists - Join-Path would resolve it and throw.
                $c = Join-PathLexical $lib "steamapps\common\PEAK"
                if (Test-LiteralPathSafe -Path (Join-PathLexical $c $GAME_EXE) -PathType Leaf) { $gamePath = $c; break }
            }
        }
        if (-not $gamePath) { $gamePath = Get-GameFolderInteractive -GameName "PEAK" -ProbeFile $GAME_EXE }
    }
    if (-not $gamePath -or -not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE))) {
        Write-Fail "Could not find $GAME_EXE - nothing was installed."
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    Write-OK $(if ($peakMode -eq "2") { "PEAK 2.1.a depot: $gamePath" } else { "PEAK: $gamePath" })

    # ===================================================
    #  PHASE 1 - PLAN. Nothing is written here.
    # ===================================================
    Write-Step 2 4 "Working out what is needed"

    $tmp = Join-Path $env:TEMP ("peakvr_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    # --- main mod --------------------------------------------------
    # Option 1 follows the newer live source. Option 2 never consults a
    # moving release endpoint: PeakVR 1.4.1 is the author-tested partner
    # for the PEAK 2.1.a depot and remains fixed until a reviewed update
    # round replaces this whole confirmed pairing.
    $ts = $null
    $gh = $null
    $main = $null
    if ($peakMode -eq "2") {
        $main = @{
            Version = $ANDREY_PINNED_MOD_VERSION
            Url = $ANDREY_PINNED_MOD_URL
            Asset = $ANDREY_PINNED_MOD_ASSET
            Body = $null
            From = "pinned GitHub release"
        }
    } else {
        $ts = Get-ThunderstorePackage -Author $MOD_AUTHOR -Name $MOD_TSNAME
        $gh = Get-GithubRelease -Repo $MOD_GITHUB -AssetPattern $MOD_GH_ASSET
        if ($ts -and $gh) {
            if ((Compare-ModVersion $gh.Version $ts.Version) -gt 0) {
                Write-Info "GitHub has $($gh.Version), Thunderstore has $($ts.Version) - taking GitHub."
                $main = @{ Version = $gh.Version; Url = $gh.Url; Asset = $gh.Asset; Body = $gh.Body; From = "GitHub" }
            } else {
                $main = @{ Version = $ts.Version; Url = $ts.Url; From = "Thunderstore" }
            }
        } elseif ($gh) { $main = @{ Version = $gh.Version; Url = $gh.Url; Asset = $gh.Asset; Body = $gh.Body; From = "GitHub" } }
        elseif ($ts)   { $main = @{ Version = $ts.Version; Url = $ts.Url; From = "Thunderstore" } }
        else {
            $main = @{
                Version = $ANDREY_CURRENT_FALLBACK_VERSION
                Url = $ANDREY_CURRENT_FALLBACK_GITHUB
                From = "last reviewed fallback"
            }
            Write-Warn "Live release lookup unavailable - trying reviewed PeakVR $ANDREY_CURRENT_FALLBACK_VERSION fallbacks."
        }
    }

    Write-OK "PeakVR $($main.Version) (from $($main.From))"

    # --- fetch the main mod so its manifest can be read
    # The manifest INSIDE THE PACKAGE is the most reliable
    # dependency list there is: it belongs to exactly this build.
    $mainZip = Join-Path $tmp "$MOD_KEY.zip"
    $mainManualUrl = if ($peakMode -eq "2") { "https://github.com/$MOD_GITHUB/releases/tag/v$ANDREY_PINNED_MOD_VERSION" } else { "https://github.com/$MOD_GITHUB/releases/latest" }
    $mainInstructions = if ($peakMode -eq "2") {
        "Download '$ANDREY_PINNED_MOD_ASSET' from the v$ANDREY_PINNED_MOD_VERSION release and save it as '$mainZip', then choose Retry."
    } else { "Download the PeakVR zip and save it as '$mainZip', then choose Retry." }
    $mainUrls = @($main.Url)
    if ($peakMode -ne "2" -and (Compare-ModVersion $main.Version $ANDREY_CURRENT_FALLBACK_VERSION) -eq 0) {
        $mainUrls += @($ANDREY_CURRENT_FALLBACK_GITHUB, $ANDREY_CURRENT_FALLBACK_TS)
    }
    $mainUrls = @($mainUrls | Where-Object { $_ } | Select-Object -Unique)
    $mainDownload = @{
        Urls=$mainUrls; Destination=$mainZip; Label="PeakVR $($main.Version)"
        ManualUrl=$mainManualUrl; Instructions=$mainInstructions
    }
    if (-not (Invoke-SafeDownload @mainDownload)) {
        Write-Fail "PeakVR could not be downloaded - nothing was changed."
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    # --- breadth-first search over the dependencies ---------------
    # WHY THIS TERMINATES: $need is a SET. Every key is entered at
    # most once and taken off the queue at most once. There is no
    # branch that re-queues a key already seen.
    $need    = @{}          # Key -> geforderte Mindestversion
    $order   = New-Object System.Collections.Generic.List[string]
    $queue   = New-Object System.Collections.Generic.Queue[object]
    $seen    = @{}
    $planFail = @()

    $mainDeps = Get-ManifestDependencies -ZipPath $mainZip
    if (-not $mainDeps) {
        Write-Warn "The package has no readable manifest - falling back to the Thunderstore list."
        if ($ts) { $mainDeps = $ts.Dependencies }
    }
    foreach ($d in @($mainDeps)) { $queue.Enqueue($d) }

    # A COUNTED LOOP, NOT A CONDITIONAL ONE. The number of passes is
    # settled BEFORE the first one runs. Whether $queue ever empties no
    # longer decides the end - after $MAX_RESOLVE_STEPS it stops, no
    # matter what. 500 is far beyond any real tree (a real one has 5
    # packages).
    $resolveOverflow = $false
    for ($step = 0; $step -lt $MAX_RESOLVE_STEPS; $step++) {
        if ($queue.Count -eq 0) { break }
        if ($step -eq ($MAX_RESOLVE_STEPS - 1)) { $resolveOverflow = $true }
        $dep = $queue.Dequeue()
        $p = Split-DependencyString -Dep $dep
        if (-not $p) { continue }
        $k = $p.Key
        # The loader is handled outside the normal order.
        if ($k -ieq $LOADER_KEY) {
            if ((Compare-ModVersion $p.Version $LOADER_MIN) -gt 0) { $LOADER_MIN = $p.Version }
            continue
        }
        # The HIGHEST requirement wins - versions are minimums.
        if (-not $need.ContainsKey($k) -or (Compare-ModVersion $p.Version $need[$k]) -gt 0) {
            $need[$k] = $p.Version
        }
        if ($seen.ContainsKey($k)) { continue }
        $seen[$k] = $true
        $order.Add($k) | Out-Null

        if ($peakMode -ne "2") {
            $info = Get-ThunderstorePackage -Author $p.Author -Name $p.Name
            if (-not $info) { $planFail += $k; continue }
            foreach ($d2 in @($info.Dependencies)) { $queue.Enqueue($d2) }
        }
    }

    if ($resolveOverflow) {
        Write-Fail "The dependency tree did not settle within $MAX_RESOLVE_STEPS steps."
        Write-Host "  That should be impossible with a healthy set of packages," -ForegroundColor White
        Write-Host "  so something is wrong upstream. Nothing was changed." -ForegroundColor White
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    Write-OK ("Dependency tree: " + ($order.Count + 1) + " package(s), resolved in one pass.")

    if ($planFail.Count -gt 0) {
        Write-Warn "Thunderstore did not answer for these, so their own requirements are unknown:"
        foreach ($k in $planFail) { Write-Host "     $k" -ForegroundColor Yellow }
        Write-Host "  An incomplete plan is exactly what makes the mod fail" -ForegroundColor White
        Write-Host "  silently later. Waiting a minute usually fixes it." -ForegroundColor White
        if (-not (Read-YesNoP "Continue anyway?")) {
            Write-Info "Stopped. Nothing was changed."
            try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            return
        }
    }

    # --- which of these are actually missing? ---------------------
    # The loader first, then the dependencies in the order they were
    # found, the main mod last.
    $plan = New-Object System.Collections.Generic.List[object]

    $haveLoader = Get-InstalledVersion -Key $LOADER_KEY -GamePath $gamePath
    $loaderMatches = if ($peakMode -eq "2") { $haveLoader -eq $LOADER_MIN } else { $haveLoader -and (Compare-ModVersion $haveLoader $LOADER_MIN) -ge 0 }
    if (-not $loaderMatches) {
        $li = if ($peakMode -eq "2") {
            @{ Version=$LOADER_MIN; Url="https://thunderstore.io/package/download/$LOADER_AUTHOR/$LOADER_NAME/$LOADER_MIN/" }
        } else { Get-ThunderstorePackage -Author $LOADER_AUTHOR -Name $LOADER_NAME }
        if ($li) {
            $plan.Add(@{ Key = $LOADER_KEY; Label = "BepInEx (PEAK pack)"; Version = $li.Version; Url = $li.Url }) | Out-Null
        } elseif (-not $haveLoader) {
            Write-Fail "BepInEx could not be looked up and is not installed - nothing was changed."
            try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            return
        }
    } else {
        Write-OK "BepInEx $haveLoader already installed."
    }

    foreach ($k in $order) {
        $p = Split-DependencyString -Dep ($k + "-" + $need[$k])
        $have = Get-InstalledVersion -Key $k -GamePath $gamePath
        # Current accepts newer dependencies; the confirmed depot accepts
        # only the exact version named by its frozen package manifests.
        $dependencyMatches = if ($peakMode -eq "2") { $have -eq $need[$k] } else { $have -and (Compare-ModVersion $have $need[$k]) -ge 0 }
        if ($dependencyMatches) {
            if ($peakMode -eq "2") { Write-OK "$k $have already installed (exact pinned version)." }
            else { Write-OK "$k $have already installed (needs $($need[$k]) or newer)." }
            continue
        }
        $info = if ($peakMode -eq "2") { $null } else { Get-ThunderstorePackage -Author $p.Author -Name $p.Name }
        $ver  = $need[$k]
        $url  = "https://thunderstore.io/package/download/$($p.Author)/$($p.Name)/$ver/"
        # Take the newest build if it satisfies the requirement -
        # otherwise exactly the one required.
        if ($peakMode -ne "2" -and $info -and (Compare-ModVersion $info.Version $ver) -ge 0) { $ver = $info.Version; $url = $info.Url }
        $plan.Add(@{ Key = $k; Label = $k; Version = $ver; Url = $url }) | Out-Null
    }

    $haveMain = Get-InstalledVersion -Key $MOD_KEY -GamePath $gamePath
    $mainVersionMatches = if ($peakMode -eq "2") { $haveMain -eq $main.Version } else { $haveMain -and (Compare-ModVersion $haveMain $main.Version) -ge 0 }
    $mainNeeded = (-not $mainVersionMatches -or -not (Test-Path -LiteralPath (Join-Path $gamePath $MOD_PROOF)))
    if ($mainNeeded) {
        $plan.Add(@{ Key = $MOD_KEY; Label = "PeakVR"; Version = $main.Version; Url = $main.Url; Zip = $mainZip }) | Out-Null
    } else {
        Write-OK "PeakVR $haveMain already installed and up to date."
    }

    if ($plan.Count -eq 0) {
        Write-Host ""
        Write-OK "Everything is already in place - nothing to do."
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        if ($peakMode -eq "2") {
            if (-not (Install-AndreyDepotVersionBypass -GamePath $gamePath)) {
                Write-Fail "PeakVersionBypass could not be repaired. No completion state was changed."
                Pause-User "Press Enter to exit..." | Out-Null
                return
            }
            Save-AndreyDepotPathRecords -GamePath $gamePath -Version $main.Version
            Ensure-AndreyDepotShortcut -GamePath $gamePath
        }
        Write-Step 4 4 "Done"
        Write-Host ""
        Write-Host "  START: " -NoNewline -ForegroundColor Cyan
        Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
        Write-Host "in the Hub." -ForegroundColor Cyan
        Write-Host ""
        Pause-User "Press Enter to exit." | Out-Null
        return
    }

    Write-Host ""
    Write-Host "  This will be installed:" -ForegroundColor White
    foreach ($p in $plan) { Write-Host ("     " + $p.Label + " " + $p.Version) -ForegroundColor Gray }

    # ===================================================
    #  PHASE 2 - FETCH. Still nothing touched in the game.
    # ===================================================
    Write-Step 3 4 "Downloading everything first"

    $downloadFailed = @()
    foreach ($p in $plan) {
        if ($p.Zip -and (Test-Path -LiteralPath $p.Zip)) { continue }   # main mod already fetched
        $z = Join-Path $tmp ("$($p.Key).zip")
        Write-Info "$($p.Label) $($p.Version) ..."
        $ok = Invoke-SafeDownload -Urls @($p.Url) -Destination $z -Label "$($p.Label) $($p.Version)" `
                  -ManualUrl "https://thunderstore.io/c/peak/" `
                  -Instructions "Download the ZIP for $($p.Label) and save it as '$z', then choose Retry."
        if (-not $ok -or -not (Test-Path -LiteralPath $z)) { $downloadFailed += $p.Label; continue }
        $p.Zip = $z
    }

    # Every archive must open and must have content. A damaged
    # archive shows up HERE, not halfway through the game folder.
    $badZip = @()
    foreach ($p in $plan) {
        if (-not $p.Zip -or -not (Test-Path -LiteralPath $p.Zip)) { continue }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $z = [System.IO.Compression.ZipFile]::OpenRead($p.Zip)
            try { if ($z.Entries.Count -lt 1) { $badZip += $p.Label } } finally { $z.Dispose() }
        } catch { $badZip += $p.Label }
    }

    if ($downloadFailed.Count -gt 0 -or $badZip.Count -gt 0) {
        Write-Host ""
        Write-Fail "The download stage did not complete - THE GAME WAS NOT TOUCHED."
        foreach ($l in $downloadFailed) { Write-Host "     could not download: $l" -ForegroundColor Red }
        foreach ($l in $badZip)         { Write-Host "     damaged archive:    $l" -ForegroundColor Red }
        Write-Host "  Run this again in a minute." -ForegroundColor White
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    Write-OK "$($plan.Count) package(s) downloaded and readable."

    # ===================================================
    #  PHASE 2b - CROSS-CHECK FROM THE PACKAGES THEMSELVES
    # ===================================================
    # Phase 1 resolved the tree through the Thunderstore API. That
    # names the dependencies of the NEWEST build of each package -
    # and we do not always install the newest. Where the API says
    # something different from the package actually on disk, THE
    # PACKAGE WINS.
    #
    # So every downloaded file is opened here and its own
    # manifest.json is read. If a dependency turns up that is missing
    # from the plan or too old in it, it is fetched NOW - before the
    # first write.
    #
    # WHY THIS TERMINATES: a round only starts when the previous one
    # added something NEW, and every package key can be added at most
    # once ($seen only grows). After at most as many rounds as there
    # are packages, it is over.
    Write-Info "Cross-checking the packages against their own manifests ..."

    $extraRounds  = 0
    $extraTotal   = 0
    $lateFail     = @()
    $roundAdded   = 0
    $crossOverflow = $false
    # COUNTED HERE TOO. Ten rounds cover any chain that occurs in
    # reality; the deepest ever seen had three links.
    for ($round = 1; $round -le $MAX_CROSS_ROUNDS; $round++) {
        if ($round -gt 1 -and $roundAdded -eq 0) { break }
        if ($round -eq $MAX_CROSS_ROUNDS -and $roundAdded -gt 0) { $crossOverflow = $true }
        $roundAdded = 0
        $extraRounds = $round
        # A snapshot: whatever is added in this round is only read in
        # the next one - otherwise the list changes while it is being
        # walked.
        # .ToArray() AND NOT @($plan): the @() form throws "Argument
        # types do not match" on a generic list of hashtables and the
        # whole round aborts. Reproduced on real PowerShell 7.4, not
        # assumed. ToArray() gives a true snapshot - what is added in
        # this round is read in the next, exactly as intended.
        foreach ($p in $plan.ToArray()) {
            if (-not $p.Zip -or -not (Test-Path -LiteralPath $p.Zip)) { continue }
            if ($p.Checked) { continue }
            $p.Checked = $true
            foreach ($dep in @(Get-ManifestDependencies -ZipPath $p.Zip)) {
                $d = Split-DependencyString -Dep $dep
                if (-not $d) { continue }
                $k = $d.Key
                if ($k -ieq $LOADER_KEY) { continue }
                # Is what is already planned or installed good enough?
                $planned = $plan | Where-Object { $_.Key -eq $k } | Select-Object -First 1
                if ($planned -and (Compare-ModVersion $planned.Version $d.Version) -ge 0) { continue }
                if (-not $planned) {
                    $have = Get-InstalledVersion -Key $k -GamePath $gamePath
                    if ($have -and (Compare-ModVersion $have $d.Version) -ge 0) { continue }
                }
                # No - so fetch it now.
                Write-Warn "$($p.Label) also requires $k $($d.Version) - the API had not listed it."
                $info = if ($peakMode -eq "2") { $null } else { Get-ThunderstorePackage -Author $d.Author -Name $d.Name }
                $ver  = $d.Version
                $url  = "https://thunderstore.io/package/download/$($d.Author)/$($d.Name)/$ver/"
                if ($peakMode -ne "2" -and $info -and (Compare-ModVersion $info.Version $ver) -ge 0) { $ver = $info.Version; $url = $info.Url }
                $z = Join-Path $tmp ("late_$k.zip")
                $ok = Invoke-SafeDownload -Urls @($url) -Destination $z -Label "$k $ver" `
                          -ManualUrl "https://thunderstore.io/c/peak/" `
                          -Instructions "Download the ZIP for $k and save it as '$z', then choose Retry."
                if (-not $ok -or -not (Test-Path -LiteralPath $z)) { $lateFail += "$k $ver"; continue }
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                    $zz = [System.IO.Compression.ZipFile]::OpenRead($z)
                    try { if ($zz.Entries.Count -lt 1) { throw "empty archive" } } finally { $zz.Dispose() }
                } catch { $lateFail += "$k $ver (damaged)"; continue }

                if ($planned) {
                    # Already in the plan but too old - raise the entry.
                    $planned.Version = $ver
                    $planned.Url     = $url
                    $planned.Zip     = $z
                    $planned.Checked = $false
                } else {
                    # Insert BEFORE the main mod: that one comes last.
                    $plan.Insert([Math]::Max(0, $plan.Count - 1), @{ Key = $k; Label = $k; Version = $ver; Url = $url; Zip = $z; Checked = $false }) | Out-Null
                }
                $need[$k] = $ver
                if (-not $order.Contains($k)) { $order.Add($k) | Out-Null }
                $roundAdded++
                $extraTotal++
            }
        }
    }

    if ($crossOverflow) {
        Write-Fail "The cross-check was still finding new packages after $MAX_CROSS_ROUNDS rounds."
        Write-Host "  A dependency chain that deep is not plausible - something is" -ForegroundColor White
        Write-Host "  wrong upstream. THE GAME WAS NOT TOUCHED." -ForegroundColor White
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }

    if ($lateFail.Count -gt 0) {
        Write-Host ""
        Write-Fail "These extra requirements could not be fetched - THE GAME WAS NOT TOUCHED."
        foreach ($l in $lateFail) { Write-Host "     $l" -ForegroundColor Red }
        Write-Host "  Run this again in a minute." -ForegroundColor White
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    if ($extraTotal -gt 0) {
        Write-OK "$extraTotal extra package(s) found in the manifests and fetched (after $extraRounds rounds)."
        Write-Host "  Final list:" -ForegroundColor White
        foreach ($p in $plan) { Write-Host ("     " + $p.Label + " " + $p.Version) -ForegroundColor Gray }
    } else {
        Write-OK "The manifests agree with the plan - nothing was missing."
    }

    # ===================================================
    #  PHASE 3 - INSTALL. No more decisions.
    # ===================================================
    Write-Step 4 4 "Installing"

    $failed = @()
    foreach ($p in $plan) {
        try {
            $n = Install-Package -Zip $p.Zip -Work (Join-Path $tmp ("x_" + $p.Key)) -GamePath $gamePath -Key $p.Key -ReplaceOwnedFolders:($peakMode -eq "2")
            if ($n -lt 1) { throw "the package contained no files" }
            Set-InstalledVersion -Key $p.Key -Version $p.Version -GamePath $gamePath
            Write-OK "$($p.Label) $($p.Version) - $n file(s)."
        } catch {
            Write-Fail "$($p.Label): $($_.Exception.Message)"
            $failed += $p.Label
        }
    }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

    # --- Final check: the claim against the disk -----------------
    Write-Host ""
    $proofPath = Join-Path $gamePath $MOD_PROOF
    $missingNow = @()
    foreach ($k in $order) {
        $have = Get-InstalledVersion -Key $k -GamePath $gamePath
        $verifiedVersion = if ($peakMode -eq "2") { $have -eq $need[$k] } else { $have -and (Compare-ModVersion $have $need[$k]) -ge 0 }
        if (-not $verifiedVersion) { $missingNow += "$k (needs $($need[$k]))" }
    }
    if (-not (Test-Path -LiteralPath $proofPath)) { $missingNow += "PeakVR itself" }

    if ($failed.Count -gt 0 -or $missingNow.Count -gt 0) {
        Write-Fail "The install is NOT complete:"
        foreach ($l in $failed)     { Write-Host "     failed to install: $l" -ForegroundColor Red }
        foreach ($l in $missingNow) { Write-Host "     still missing:     $l" -ForegroundColor Red }
        Write-Host ""
        Write-Host "  Run this installer again. If it keeps failing on the same" -ForegroundColor White
        Write-Host "  package, install that one from Thunderstore by hand." -ForegroundColor White
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }

    Write-OK "Verified on disk: PeakVR and all $($order.Count) requirement(s)."
    if ($peakMode -eq "2" -and -not (Install-AndreyDepotVersionBypass -GamePath $gamePath)) {
        Write-Fail "The depot and PeakVR are present, but the required version-check bypass is missing."
        Write-Host "  Run this installer again; no VR Ready marker or shortcut was created." -ForegroundColor White
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    try {
        if ($peakMode -eq "2") {
            Save-AndreyDepotPathRecords -GamePath $gamePath -Version $main.Version
        } else {
            Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
            Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $main.Version -Encoding UTF8 -Force
        }
    } catch {}
    # ALSO write the durable stamp next to the GAME (2026-08-20).
    # The line above lands inside the Hub folder and is gone as
    # soon as a new Hub build is dropped in; the scan then finds
    # no marker and seeds the CURRENT online tag, swallowing a
    # pending update. The game-side stamp survives that.
    Save-InstalledStamp -GameDir $gamePath -Version $main.Version
    try {
        if ($peakMode -eq "2") {
            Ensure-AndreyDepotShortcut -GamePath $gamePath
        } else {
            $sc = New-DesktopShortcut -ShortcutName "PEAK VR" -TargetPath "steam://rungameid/$DEPOT_APPID" `
                      -WorkingDir $gamePath -Description "PEAK in VR (PeakVR)"
            if ($sc) { Write-OK "Desktop shortcut 'PEAK VR' created." }
        }
    } catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " PeakVR $($main.Version) is installed!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  START: " -NoNewline -ForegroundColor Cyan
    Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    if ($peakMode -eq "2") {
        Write-Host "then choose Depot 2.1a, or use the PEAK VR 2.1a shortcut." -ForegroundColor Cyan
    } else {
        Write-Host "in the Hub, or launch PEAK from Steam." -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "  IMAGE LOOKS BLURRY? In the game: Settings > Mod Settings >" -ForegroundColor Cyan
    Write-Host "  PEAK VR > VR GRAPHICS > " -NoNewline -ForegroundColor Cyan
    Write-Host " MAKE IMAGE SHARPER = Enable " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "  TOO MUCH TUNNEL VISION? Settings > Mod Settings > PEAK VR >" -ForegroundColor Gray
    Write-Host "  COMFORT > Movement Tunneling = off." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  You climb the way the base game does - this is not a" -ForegroundColor Gray
    Write-Host "  hand-over-hand climbing simulator." -ForegroundColor Gray
    Write-Host ""
    if ($peakMode -eq "2") {
        Write-Host "  The pinned copy stays in $gamePath" -ForegroundColor Gray
        Write-Host "  Steam is still required for ownership authentication." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  The mountain does not care which manifest got you there." -ForegroundColor Magenta
        Write-Host ""
        Pause-User "Press Enter to exit." | Out-Null
        return
    }
    # ===================================================
    #  FINAL STEP - DirectX 11 as a launch option
    # ===================================================
    # The author recommends this explicitly for the framerate (it says
    # so in his mod's About window). Steam does not let launch options
    # be set from outside - editing localconfig.vdf would mean writing
    # into Steam's own file, which can be overwritten on the next Steam
    # start or worse. So the same route as the depot command further
    # down: put it on the clipboard, open the right window, let the
    # user paste.
    # OPTIONAL: saying no leaves a finished install, just without this
    # one setting.
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  ONE OPTIONAL SETTING" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  The mod author recommends running PEAK on " -NoNewline -ForegroundColor White
    Write-Host "DirectX 11" -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host " for a" -ForegroundColor White
    Write-Host "  better framerate in VR. It is a Steam launch option:" -ForegroundColor White
    Write-Host ""
    Write-Host "    $D3D11_ARG" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Steam does not let anything set that from the outside, so" -ForegroundColor Gray
    Write-Host "  this is a copy-and-paste job - the same way the depot route" -ForegroundColor Gray
    Write-Host "  works. Your game is fully installed either way." -ForegroundColor Gray
    Write-Host ""

    if (Read-YesNoP "Set it up now?") {
        $clip = $false
        try { Set-Clipboard -Value $D3D11_ARG; $clip = $true } catch {}
        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host "   ACTION REQUIRED - paste into Steam" -ForegroundColor Yellow
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host ""
        if ($clip) {
            Write-Host "  [OK] $D3D11_ARG copied to your clipboard." -ForegroundColor Yellow
        } else {
            Write-Warn "The clipboard could not be used - type it by hand:"
            Write-Host "    $D3D11_ARG" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "  Next: PEAK's properties window opens." -ForegroundColor White
        Write-Host "    1. Stay on the GENERAL page" -ForegroundColor White
        Write-Host "    2. Click the LAUNCH OPTIONS field" -ForegroundColor White
        Write-Host "    3. Paste with Ctrl+V, then close the window" -ForegroundColor White
        Write-Host ""
        Write-Host "  If there is already something in that field, put a space" -ForegroundColor Gray
        Write-Host "  between the entries instead of replacing it." -ForegroundColor Gray
        Write-Host ""
        Pause-User "Press Enter to open PEAK's properties in Steam..."
        $opened = $false
        # Two protocol addresses, because depending on the Steam build
        # only one of them works - exactly as with the Steam console in
        # the depot route.
        foreach ($u in @("steam://gameproperties/$DEPOT_APPID", "steam://nav/games/details/$DEPOT_APPID")) {
            try { Start-Process $u -ErrorAction Stop; $opened = $true; break } catch {}
        }
        if ($opened) {
            Write-OK "Steam should be showing PEAK's properties now."
        } else {
            Write-Warn "Steam could not be opened from here."
            Write-Host "  Do it by hand: Steam library, right-click PEAK, Properties," -ForegroundColor White
            Write-Host "  General, Launch Options - then paste." -ForegroundColor White
        }
        Write-Host ""
        Write-Host "  (i) Virtual Desktop users: windows opened from inside a VD" -ForegroundColor DarkGray
        Write-Host "      session sometimes appear on the desktop only. Take the" -ForegroundColor DarkGray
        Write-Host "      headset off for a moment if you cannot see it." -ForegroundColor DarkGray
        Write-Host ""
        Pause-User "Press Enter when you are done."
    } else {
        Write-Info "Skipped. You can add $D3D11_ARG later: Steam, right-click PEAK,"
        Write-Info "Properties, General, Launch Options."
    }

    Write-Host ""
    Write-Host "  The mountain does not care that you can see it properly now." -ForegroundColor Magenta
    Write-Host ""
    Pause-User "Press Enter to exit." | Out-Null
    return
}

# =======================================================
#  From here on: option 3, the original depot route for PEAK_VR
#  by AstienVR. Its game/mod flow remains unchanged.
# =======================================================

Write-Header

$sevenZip = Find-7Zip
if (-not $sevenZip) {
    Write-Fail "7-Zip not installed."
    Write-Host ""
    Write-Host "  This installer needs 7-Zip's command-line tool. Install it:" -ForegroundColor Yellow
    Write-Host "    https://www.7-zip.org" -ForegroundColor White
    Pause-User "Press Enter to exit..."
    exit 1
}
Write-OK "7-Zip detected: $sevenZip"

Write-Host ""
Write-Host "  PEAK has been updated past version 1.44.a, which broke the VR mod." -ForegroundColor White
Write-Host "  This installer pins the game to the last mod-compatible Steam" -ForegroundColor White
Write-Host "  manifest in a separate folder so your normal Steam install isn't" -ForegroundColor White
Write-Host "  touched." -ForegroundColor White
Write-Host ""
Write-Host "  You'll need:" -ForegroundColor White
Write-Host "    - PEAK owned on Steam (App $DEPOT_APPID)" -ForegroundColor Gray
Write-Host "    - Steam running and logged in" -ForegroundColor Gray
Write-Host "    - About 4 GB free disk space" -ForegroundColor Gray
Write-Host "    - Admin rights for the ViGEmBus driver install (UAC prompt)" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
#  STEP 1: Steam Console download_depot
# -------------------------------------------------------
Write-Step 1 7 "Download PEAK v1.44.a via Steam Console"

Write-Host "  Steam Console will be opened. The depot command is already" -ForegroundColor White
Write-Host "  copied to your clipboard - just paste (Ctrl+V) into the console" -ForegroundColor White
Write-Host "  input field and press Enter." -ForegroundColor White
Write-Host ""
Write-Host "  Command:" -ForegroundColor Gray
Write-Host "    $DEPOT_COMMAND" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Manifest $DEPOT_MANIFEST is PEAK v1.44.a (the last mod-compatible build)." -ForegroundColor Gray
Write-Host "  About 4 GB to download." -ForegroundColor Gray
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Depot command copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Press Enter to open the Steam Console..." -ForegroundColor Yellow
Write-Host "  Then click the input field, paste (Ctrl+V) and hit Enter." -ForegroundColor Yellow
Write-Host ""
Write-Host ""
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
    Write-Host "  (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
    Write-Host "      automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
    Write-Host "      doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
    Write-Host "      then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
    Write-Host "      next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
    Write-Host ""
}
# !!! LOOK BEFORE ASKING. Steam keeps a finished depot in
# steamapps\content, so a second run - or a run after a crash - already
# has the files. Prompting first and probing only afterwards sends the
# user to fetch gigabytes that are already on disk. Find-SteamDepotPath
# is cheap and touches nothing.
$script:PreFoundDepot = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE
if ($script:PreFoundDepot) {
    Write-OK "The depot is already downloaded: $script:PreFoundDepot"
    Write-Info "Skipping the download - nothing to fetch again."
}
if (-not $script:PreFoundDepot) {

Pause-User "Press Enter to open the Steam Console..."
# Both protocol addresses: depending on the Steam build only one works.
foreach ($cu in @("steam://open/console", "steam://nav/console")) {
    try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
}
}
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
#  STEP 2: Locate + move depot to stable folder
# -------------------------------------------------------
Write-Step 2 7 "Locate depot and move to stable folder"

Write-Host "  Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
foreach ($reg in @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$probePaths = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -AdditionalSteamRoots @($steamInstallPath))
$depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamInstallPath)
if ($depotPath) { Write-OK "Depot folder found automatically: $depotPath" }
else { Write-Warn "Depot folder not found yet in any Steam library." }

if (-not $depotPath) {
    $depotPath = Resolve-DepotPath -GameName "PEAK" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# Sanity check: depot should contain the game exe
$depotExe = Join-PathLexical $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
    Write-Warn "'$GAME_EXE' not found inside depot."
    Write-Host "  Expected: $depotExe" -ForegroundColor Gray
    Write-Host "  This usually means the download is incomplete or the wrong" -ForegroundColor Gray
    Write-Host "  manifest was downloaded. Install anyway?" -ForegroundColor White
    $choice = ""
    for ($t = 0; $t -lt 20; $t++) {
        $choice = ("" + (Read-Host "  Continue? (Y/N)")).Trim()
        if ($choice -in @("y","Y","n","N")) { break }
    }
    if ($choice -notin @("y","Y","n","N")) { Write-Warn "No usable answer - assuming No."; $choice = "n" }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..."
        exit 0
    }
} else {
    Write-OK "$GAME_EXE confirmed in depot."
}

# Pick target folder and move there
$parentOfDepot = Get-PathParentLexical $depotPath  # ...\app_3527290

Write-Host ""
Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = ("" + (Read-Host "  Press Enter to use default, or type a different full path")).Trim().Trim('"')
if (-not $userInput) {
    $targetPath = $DEFAULT_PATH
} else {
    $targetPath = $userInput
}

$targetParent = Get-PathParentLexical $targetPath
if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) {
    Write-Fail "The target folder is not writable: $targetParent"
    Pause-User "Press Enter to exit..."; exit 1
}

Write-Host ""
Write-Host "  Current location:  $depotPath" -ForegroundColor Gray
Write-Host "  Moving to:         $targetPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Why? Steam may overwrite the app_$DEPOT_APPID folder during" -ForegroundColor Gray
Write-Host "  future depot downloads. Moving to a stable name keeps the" -ForegroundColor Gray
Write-Host "  VR install safe and separate from your retail PEAK." -ForegroundColor Gray
Write-Host ""

if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Info "Merging the pinned build; saves, BepInEx configs/plugins and other additional files are preserved."
}

try {
    $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "PEAK depot build"
    Write-OK "Game installed at: $targetPath"
} catch {
    Write-Fail "Merge failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Pause-User "Press Enter to exit..."
    exit 1
}

# Clean up empty app_<id> folder
try {
    if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Item $parentOfDepot -Force
    }
} catch {}

$gamePath    = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
#  STEP 3: steam_appid.txt
# -------------------------------------------------------
Write-Step 3 7 "Drop steam_appid.txt"

# Without this, Steam may try to re-install or update PEAK whenever
# the user launches the EXE while Steam is running.
try {
    $steamAppIdFile = Join-Path $gamePath "steam_appid.txt"
    Set-Content -Path $steamAppIdFile -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
    Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
} catch {
    Write-Warn "Could not create steam_appid.txt: $_"
    Write-Host "  Create a file called 'steam_appid.txt' next to PEAK.exe," -ForegroundColor Gray
    Write-Host "  containing only the number $DEPOT_APPID." -ForegroundColor Gray
}

# -------------------------------------------------------
#  STEP 4: Download + extract PEAK_VR mod
# -------------------------------------------------------
Write-Step 4 7 "Download PEAK_VR mod and apply"

$modTmp = Join-Path $env:TEMP "PEAKVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $modTmp | Out-Null
$modZip = Join-Path $modTmp "PEAK_VR.zip"

$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "PEAK VR mod v1.0.0" `
        -ManualUrl "https://github.com/AstienVR/PEAK_VR/releases/tag/1.0.0" `
        -Instructions "Download 'PEAK_VR.zip' from the GitHub releases page. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - PEAK VR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without the VR mod. Press Enter to exit..."; exit 1 }

Write-Info "Extracting the mod into a staging folder..."
$modExtract = Join-Path $modTmp "extracted"
$efb = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $modExtract -Label "PEAK_VR" `
        -SkipMessage "Skipped - PEAK_VR was not extracted; the VR mod will NOT load."
if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$efb -ne "ok" -and [string]$efb -ne "manual") {
    Pause-User "Mod extraction skipped/failed. Install incomplete. Press Enter to exit..."
    exit 1
}
$modPayload = $modExtract
$modChildren = @(Get-ChildItem -Path $modExtract -Force -ErrorAction SilentlyContinue)
if ($modChildren.Count -eq 1 -and $modChildren[0].PSIsContainer) { $modPayload = $modChildren[0].FullName }
try {
    $null = Merge-DirectoryTreeVerified -Source $modPayload -Destination $gamePath -Label "PEAK_VR mod files" `
        -KeepExistingRelativePaths @("BepInEx\config")
    Write-OK "Mod files merged; existing BepInEx configuration was retained."
} catch {
    Write-Fail "Could not merge the mod files: $_"
    Pause-User "Press Enter to exit without deleting existing files..."
    exit 1
}

# Sanity check
$missing = @()
foreach ($f in @("winhttp.dll", $VIGEM_REL_PATH)) {
    if (-not (Test-Path (Join-Path $gamePath $f))) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Warn "Some expected mod files are missing: $($missing -join ', ')"
    Write-Warn "The mod may not function. Inspect $gamePath manually."
} else {
    Write-OK "Mod files in place (winhttp.dll, ViGEmBus installer present)."
}

try { Remove-Item -Path $modTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# Correct two shipped config values
# -------------------------------------------------------
# The mod archive ships UnityVR_Bepinex.cfg with two settings that break
# controllers in practice:
#   fixControllerTracking = false  -> controller tracking dies on every
#                                     scene load; must be true
#   controllerType        = ps4    -> must be xbox360 for the emulated
#                                     gamepad to be recognised
# Both are rewritten in place, keeping the rest of the file untouched.
# Only the setting lines are matched (not the "# Default value:" comment
# lines above them), and each is verified after writing.
$vrCfg = Join-Path $gamePath "BepInEx\config\UnityVR_Bepinex.cfg"
if (Test-Path -LiteralPath $vrCfg) {
    try {
        $cfgRaw = Get-Content -LiteralPath $vrCfg -Raw -Encoding UTF8
        $before = $cfgRaw
        $cfgRaw = [regex]::Replace($cfgRaw, '(?m)^(\s*fixControllerTracking\s*=\s*).*$', '${1}true')
        $cfgRaw = [regex]::Replace($cfgRaw, '(?m)^(\s*controllerType\s*=\s*).*$', '${1}xbox360')
        if ($cfgRaw -ne $before) {
            Set-Content -LiteralPath $vrCfg -Value $cfgRaw -Encoding UTF8 -NoNewline -Force
        }
        $check = Get-Content -LiteralPath $vrCfg -Raw -Encoding UTF8
        $okTrack = $check -match '(?m)^\s*fixControllerTracking\s*=\s*true\s*$'
        $okType  = $check -match '(?m)^\s*controllerType\s*=\s*xbox360\s*$'
        if ($okTrack -and $okType) {
            Write-OK "VR config corrected (fixControllerTracking = true, controllerType = xbox360)."
        } else {
            Write-Warn "Could not confirm both config values. Open $vrCfg and set"
            Write-Warn "fixControllerTracking = true and controllerType = xbox360 manually."
        }
    } catch {
        Write-Warn "Could not edit $vrCfg ($_)."
        Write-Warn "Set fixControllerTracking = true and controllerType = xbox360 manually."
    }
} else {
    Write-Warn "UnityVR_Bepinex.cfg not found yet - it is created on first launch."
    Write-Warn "After the first start, set fixControllerTracking = true and"
    Write-Warn "controllerType = xbox360 in BepInEx\config\UnityVR_Bepinex.cfg."
}

# -------------------------------------------------------
#  STEP 5: Install PeakVersionBypass (kirigiri)
# -------------------------------------------------------
# PEAK refuses to enter the main menu when its client version doesn't
# match Steam's expected current version. Since we deliberately pinned
# to manifest 1.44.a, PEAK on launch shows an "update required" prompt
# and never reaches gameplay - not even offline. kirigiri's
# PeakVersionBypass is a tiny BepInEx plugin that silences that check.
Write-Step 5 7 "Install PeakVersionBypass (version-check bypass)"

$bypassTmp = Join-Path $env:TEMP "PeakVersionBypass_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $bypassTmp | Out-Null
$bypassZip = Join-Path $bypassTmp "PeakVersionBypass.zip"

Write-Info "Downloading $BYPASS_NAME ..."
$r = Invoke-DownloadOrFallback -Url $BYPASS_URL -Destination $bypassZip `
        -Label "PEAK Version Bypass" `
        -ManualUrl "$BYPASS_PAGE" `
        -Instructions "Download the latest PeakVersionBypass ZIP from the Thunderstore page. Place it at '$bypassZip' and choose Retry. Alternatively, extract '$BYPASS_DLL' into '$gamePath\BepInEx\plugins\' yourself and choose Skip." `
        -SkipMessage "Skipped - PEAK Version Bypass missing; PEAK will block at the version check (high impact)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) {
    Write-Warn "Bypass auto-download skipped. PEAK may block at version check."
    Pause-User "Press Enter once you've handled the bypass manually (or to continue without it)..."
}

# Extract only the DLL we need into the existing BepInEx\plugins folder
if (Test-Path $bypassZip) {
    $bypassExtract = Join-Path $bypassTmp "extract"
    try {
        $proc = Start-Process -FilePath $sevenZip -ArgumentList @(
            "x", "-y", "`"$bypassZip`"", "-o`"$bypassExtract`""
        ) -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -ne 0) { throw "7-Zip exit code $($proc.ExitCode)" }

        $bypassSrc = Join-Path $bypassExtract "BepInEx\plugins\$BYPASS_DLL"
        if (-not (Test-Path $bypassSrc)) {
            Write-Warn "$BYPASS_DLL not found in bypass ZIP after extract."
            Write-Warn "Skipping bypass install. PEAK will block at version check."
        } else {
            $bypassDst = Join-Path $gamePath "BepInEx\plugins\$BYPASS_DLL"
            $pluginsDir = Split-Path $bypassDst -Parent
            if (-not (Test-Path $pluginsDir)) {
                New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
            }
            Copy-Item -Path $bypassSrc -Destination $bypassDst -Force
            Write-OK "$BYPASS_DLL copied into BepInEx\plugins\."
        }
    } catch {
        Write-Warn "Bypass extract / copy failed: $_"
        Write-Warn "PEAK may block at the version check on launch."
    }
}

try { Remove-Item -Path $bypassTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
#  STEP 6: Install ViGEmBus driver
# -------------------------------------------------------
Write-Step 6 7 "Install ViGEmBus driver (gamepad emulation)"

$vigemExe = Join-Path $gamePath $VIGEM_REL_PATH
if (-not (Test-Path $vigemExe)) {
    Write-Warn "ViGEmBus installer not found at expected path:"
    Write-Warn "  $vigemExe"
    Write-Warn "Skipping driver install. You will need to install it manually."
    Write-Info "Download: https://github.com/nefarius/ViGEmBus/releases"
} else {
    # Detect an existing ViGEmBus install so users who already have it
    # (very common - it ships with many VR mods, Virtual Desktop,
    # DS4Windows, etc.) can just press Enter. Re-installing stays
    # available via V.
    $vigemPresent = $false
    try { $vigemPresent = Test-ViGEmBusInstalled } catch { $vigemPresent = $false }

    if ($vigemPresent) {
        Write-OK "ViGEmBus already detected on this PC."
        Write-Host ""
        Write-Host "  Press ENTER to continue to the next step (recommended)." -ForegroundColor White
        Write-Host "  If your VR controllers give you trouble, you can (re)install" -ForegroundColor Gray
        Write-Host "  it: type V then Enter." -ForegroundColor Gray
        $reinst = ("" + (Read-Host "  [Enter] skip / [V] reinstall")).Trim()
        if ($reinst -in @("v","V")) {
            Write-Info "Launching ViGEmBus installer..."
            try {
                Start-Process -FilePath $vigemExe -Wait
                Write-OK "ViGEmBus setup finished."
            } catch {
                Write-Warn "ViGEmBus install threw: $_"
                Write-Warn "Run it manually from: $vigemExe"
            }
        } else {
            Write-Info "Keeping the existing ViGEmBus install."
        }
    } else {
        Write-Host "  PEAK_VR uses ViGEmBus to emulate an Xbox controller from your VR" -ForegroundColor White
        Write-Host "  controllers. The driver needs admin rights (UAC prompt)." -ForegroundColor White
        Write-Host ""
        Write-Host "  If ViGEmBus is ALREADY installed on your system, just close the" -ForegroundColor Cyan
        Write-Host "  setup window when it appears - no re-install needed." -ForegroundColor Cyan
        Write-Host ""
        $skip = ("" + (Read-Host "  Run ViGEmBus installer now? (Y/N)")).Trim()
        if ($skip -in @("y","Y","")) {
            Write-Info "Launching ViGEmBus installer..."
            try {
                Start-Process -FilePath $vigemExe -Wait
                Write-OK "ViGEmBus setup finished."
                Write-Info "When PEAK launches you should hear a Windows 'device connected' sound -"
                Write-Info "that confirms the ViGEmBus driver is active."
            } catch {
                Write-Warn "ViGEmBus install threw: $_"
                Write-Warn "Run it manually from: $vigemExe"
            }
        } else {
            Write-Info "Skipped. Run later from: $vigemExe"
        }
    }
}

# Record the general path for the immediate one-game refresh, plus a
# dedicated legacy marker so the detail page never mistakes this 1.44.a
# copy for the recommended Andrey 2.1.a depot.
try {
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path_legacy_depot") -Value $gamePath -Encoding UTF8 -Force
} catch {}

# -------------------------------------------------------
#  STEP 7: Desktop shortcut
# -------------------------------------------------------
Write-Step 7 7 "Create desktop shortcut"

try {
    $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\PEAK VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0" -Arguments "-force-vulkan"
    Write-OK "Desktop shortcut 'PEAK VR' created (with -force-vulkan)."
} catch {
    Write-Warn "Could not create desktop shortcut: $_"
    Write-Host "  Launch manually from:" -ForegroundColor Gray
    Write-Host "  $gameExePath -force-vulkan" -ForegroundColor Yellow
}

# -------------------------------------------------------
#  Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Done. Before launching:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  1. Steam client must be running (PEAK still needs Steam auth)" -ForegroundColor White
Write-Host "  2. Start SteamVR" -ForegroundColor White
Write-Host "  3. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host "     'PEAK VR' desktop shortcut" -ForegroundColor White
Write-Host ""
Write-Host "  The shortcut launches PEAK with -force-vulkan, which is the" -ForegroundColor Cyan
Write-Host "  author's recommended VR API combo (OpenVR + Vulkan). VR renders" -ForegroundColor Cyan
Write-Host "  to the headset; the flatscreen window may not show an image -" -ForegroundColor Cyan
Write-Host "  that's normal and not a bug." -ForegroundColor Cyan
Write-Host ""
Write-Host "  If VR doesn't render with -force-vulkan, the only other combo" -ForegroundColor Gray
Write-Host "  that works for some setups is OpenXR + D3D12:" -ForegroundColor Gray
Write-Host "    1) Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor Gray
Write-Host "    2) Change 'vrApi = OpenVR' to 'vrApi = OpenXR'" -ForegroundColor Gray
Write-Host "    3) Edit the shortcut: replace -force-vulkan with -force-d3d12" -ForegroundColor Gray
Write-Host ""
Write-Host "  Quick controls:" -ForegroundColor Cyan
Write-Host "    - VR controllers map as an Xbox gamepad" -ForegroundColor White
Write-Host "    - Click BOTH thumbsticks to recenter VR view" -ForegroundColor White
Write-Host "    - Hold left hand near your head: hotkey gesture mode" -ForegroundColor White
Write-Host "    - White laser = interact / pick / throw" -ForegroundColor White
Write-Host "    - Red laser   = aim (shootable items)" -ForegroundColor White
Write-Host ""
Write-Host "  Virtual Desktop users: in the headset's VD input settings," -ForegroundColor Yellow
Write-Host "  make sure NO gamepad emulation is checked (Gamepad / Dpad off)." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Full config guide, troubleshooting and known issues are on the" -ForegroundColor Gray
Write-Host "  PEAK VR description page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  Reach the summit. Try not to fall. See you up top, Scout." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
