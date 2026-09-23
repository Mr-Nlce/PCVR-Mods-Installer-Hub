# ============================================================
#  Risk of Rain 2 - VR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "RoR2 VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers (Invoke-DownloadOrFallback,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback)
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# -------------------------------------------------------
# Option 1 - current Steam build, resolved recursively from
# Thunderstore.  The snapshot is a last-known-good fallback only;
# a working API always wins and every manifest supplies the exact
# versions of its own dependencies.
# -------------------------------------------------------
$CURRENT_AUTHOR   = "Blowntobytes"
$CURRENT_PACKAGE  = "Resurrected_VRMod"
$CURRENT_FALLBACK_VERSION = "1.0.4"
$CURRENT_FALLBACK_URL = "https://github.com/Blowntobytes/RoR2VRMod/releases/download/v1.0.4/Blowntobytes-Resurrected_VRMod-1.0.4.zip"
$CURRENT_FALLBACK_CDN_URL = "https://gcdn.thunderstore.io/live/repository/packages/Blowntobytes-Resurrected_VRMod-1.0.4.zip"

# -------------------------------------------------------
# Option 2 - last confirmed current pairing, frozen in its own depot.
# Option 3 - exact pinned original legacy set for the separate depot.
# -------------------------------------------------------
$CONFIRMED_GAME_VERSION = "1.4.1"
$CONFIRMED_GAME_BUILD   = "21587608"
$CONFIRMED_MANIFEST     = "5715419509320521739"
$CONFIRMED_MOD_VERSION  = "1.0.3"
$CONFIRMED_MAIN_INFO = [pscustomobject]@{
    Author=$CURRENT_AUTHOR; Name=$CURRENT_PACKAGE; Version=$CONFIRMED_MOD_VERSION
    DownloadUrl="https://thunderstore.io/package/download/$CURRENT_AUTHOR/$CURRENT_PACKAGE/$CONFIRMED_MOD_VERSION/"
    Deprecated=$false
}
# The package manifest bundled with Resurrected VRMod 1.0.4 still points at
# an obsolete dependency graph. The mod author's published r2modman profile
# supplies these newer packages; most importantly, RoR2BepInExPack 1.43.0
# supplies Newtonsoft.Json 12.0.0.0, which VRMod.dll and VRAPI.dll require at
# runtime. Treat these as compatibility floors for Current: a future main
# package manifest may raise a version, but can never downgrade below the
# known-working author profile.
$AUTHOR_PROFILE_CODE = '01a076cc-d897-138e-a2d2-fdaed4aa561b'
$CURRENT_COMPATIBILITY_FLOOR = @(
    [pscustomobject]@{ Author='RiskofThunder'; Name='RoR2BepInExPack';             Version='1.43.0'; Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-RoR2BepInExPack-1.43.0.zip'; RequiredBy='Blowntobytes author profile' }
    [pscustomobject]@{ Author='RiskofThunder'; Name='FixPluginTypesSerialization'; Version='1.0.4';  Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-FixPluginTypesSerialization-1.0.4.zip'; RequiredBy='Blowntobytes author profile' }
    [pscustomobject]@{ Author='RiskofThunder'; Name='BepInEx_GUI';                 Version='3.0.3';  Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-BepInEx_GUI-3.0.3.zip'; RequiredBy='Blowntobytes author profile' }
    [pscustomobject]@{ Author='pseudopulse';    Name='SeekersPatcher';              Version='1.4.1';  Url='https://gcdn.thunderstore.io/live/repository/packages/pseudopulse-SeekersPatcher-1.4.1.zip'; RequiredBy='Blowntobytes author profile' }
    [pscustomobject]@{ Author='score';          Name='MiscFixes';                   Version='1.5.9';  Url='https://gcdn.thunderstore.io/live/repository/packages/score-MiscFixes-1.5.9.zip'; RequiredBy='Blowntobytes author profile' }
)
# Exact package versions of the dependency graph paired with game 1.4.1.
# These versioned publisher URLs keep the confirmed route reproducible even
# when Thunderstore's "latest" package state has moved on.
$CONFIRMED_PACKAGE_PINS = @{
    'blowntobytes-resurrected_vrmod-1.0.3'            = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/Blowntobytes-Resurrected_VRMod-1.0.3.zip' }
    'bbepis-bepinexpack-5.4.2121'                     = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/bbepis-BepInExPack-5.4.2121.zip' }
    'riskofthunder-hookgenpatcher-1.2.9'              = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-HookGenPatcher-1.2.9.zip' }
    'riskofthunder-bepinex_gui-3.0.3'                 = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-BepInEx_GUI-3.0.3.zip' }
    'riskofthunder-fixplugintypesserialization-1.0.4' = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-FixPluginTypesSerialization-1.0.4.zip' }
    'riskofthunder-ror2bepinexpack-1.43.0'            = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/RiskofThunder-RoR2BepInExPack-1.43.0.zip' }
    'pseudopulse-seekerspatcher-1.4.1'                = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/pseudopulse-SeekersPatcher-1.4.1.zip' }
    'score-miscfixes-1.5.9'                           = @{ Url='https://gcdn.thunderstore.io/live/repository/packages/score-MiscFixes-1.5.9.zip' }
}
$LEGACY_MODS = @(
    @{ Author="bbepis";        Name="BepInExPack";                Version="5.4.2115"; Type="bepinex"  },
    @{ Author="RiskofThunder"; Name="RoR2BepInExPack";            Version="1.16.0";   Type="bepinex"  },
    @{ Author="RiskofThunder"; Name="BepInEx_GUI";                Version="3.0.1";    Type="plugins"  },
    @{ Author="RiskofThunder"; Name="FixPluginTypesSerialization"; Version="1.0.3";    Type="patchers" },
    @{ Author="RiskofThunder"; Name="HookGenPatcher";             Version="1.2.3";    Type="patchers" },
    @{ Author="DrBibop";       Name="VRMod";                      Version="2.9.2";    Type="plugins"  }
)

# Steam Depot details
$DEPOT_APPID    = "632360"
$DEPOT_DEPOTID  = "632361"
$LEGACY_MANIFEST = "9058106608706845920"

# Final stable install location - moved out of steamapps\content
# so Steam can't overwrite it on a future depot download.
$DEFAULT_PARENT = "C:\Games"
$CONFIRMED_DEFAULT_PATH = Join-PathLexical $DEFAULT_PARENT "Risk of Rain 2 $CONFIRMED_GAME_VERSION VR"
$LEGACY_DEFAULT_PATH    = Join-PathLexical $DEFAULT_PARENT "Risk of Rain 2 VR"
$GAME_EXE       = "Risk of Rain 2.exe"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Risk of Rain 2 - VR Mod Installer" -ForegroundColor Cyan
    Write-Host " Installs: current, confirmed or original legacy VR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }

function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host "  $text" -ForegroundColor White
    Read-Host "  "
}

function Get-InstalledTSVersion {
    param([string]$Key, [string]$GamePath)
    $path = Join-Path $GamePath "BepInEx\.ts_versions\$Key"
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        try { return (Get-Content -LiteralPath $path -Raw -ErrorAction Stop).Trim() } catch {}
    }
    return $null
}

function Set-InstalledTSVersion {
    param([string]$Key, [string]$Version, [string]$GamePath)
    $dir = Join-Path $GamePath "BepInEx\.ts_versions"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir $Key), $Version, (New-Object Text.UTF8Encoding $false))
}

function Get-TSPackageInfo {
    param([string]$Author, [string]$Name)
    foreach ($url in @(
        "https://thunderstore.io/api/experimental/package/$Author/$Name/",
        "https://web.archive.org/web/0/https://thunderstore.io/api/experimental/package/$Author/$Name/"
    )) {
        try {
            $data = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).Content | ConvertFrom-Json
            if ($data -and $data.latest -and $data.latest.version_number) {
                return [pscustomobject]@{
                    Author      = $Author
                    Name        = $Name
                    Version     = [string]$data.latest.version_number
                    DownloadUrl = [string]$data.latest.download_url
                    Deprecated  = ($data.is_deprecated -eq $true)
                }
            }
        } catch {}
    }
    return $null
}

function ConvertFrom-TSDependency {
    param([string]$Dependency, [string]$RequiredBy = "")
    $parts = @($Dependency -split '-')
    if ($parts.Count -lt 3) { return $null }
    $version = [string]$parts[-1]
    $author  = [string]$parts[0]
    $name    = [string](($parts[1..($parts.Count - 2)]) -join '-')
    if (-not $author -or -not $name -or -not $version) { return $null }
    return [pscustomobject]@{ Author=$author; Name=$name; Version=$version; RequiredBy=$RequiredBy }
}

function Compare-TSVersion {
    param([string]$Left, [string]$Right)
    try { return ([version]$Left).CompareTo([version]$Right) } catch {
        return [string]::Compare($Left, $Right, [StringComparison]::OrdinalIgnoreCase)
    }
}

function Get-TSPackageArchive {
    param($Requirement, [string]$TempDir, [switch]$MainPackage, [switch]$PinnedSnapshot)
    $author  = [string]$Requirement.Author
    $name    = [string]$Requirement.Name
    $version = [string]$Requirement.Version
    $key     = "$author-$name"
    $zip     = Join-Path $TempDir "$key-$version.zip"
    $primary = "https://thunderstore.io/package/download/$author/$name/$version/"
    $urls = @($primary)
    $pinKey = "$author-$name-$version".ToLowerInvariant()
    if ($PinnedSnapshot -and $CONFIRMED_PACKAGE_PINS.ContainsKey($pinKey)) {
        $pin = $CONFIRMED_PACKAGE_PINS[$pinKey]
        # Pinning is provided by the exact package version and its publisher
        # URL. A stored fingerprint must never reject the package.
        $urls += [string]$pin.Url
    }
    $floor = @($CURRENT_COMPATIBILITY_FLOOR | Where-Object {
        $_.Author -eq $author -and $_.Name -eq $name -and $_.Version -eq $version
    } | Select-Object -First 1)
    if ($floor.Count -gt 0) {
        # Exact publisher CDN fallback for the compatibility floor documented
        # by the author's profile. This is a route fallback, never an identity
        # or fingerprint gate.
        $urls += [string]$floor[0].Url
    }
    if (-not $PinnedSnapshot -and $MainPackage -and $version -eq $CURRENT_FALLBACK_VERSION) {
        # These are two publisher-controlled routes for the same moving Current
        # package. They are ordinary download fallbacks; no reviewed hash, byte
        # count, filename or archive identity is allowed to reject a future build.
        $urls += @($CURRENT_FALLBACK_CDN_URL, $CURRENT_FALLBACK_URL)
    }
    $downloadArgs = @{
        Urls=@($urls | Where-Object { $_ } | Select-Object -Unique)
        Destination=$zip; Label="$name $version"
        ManualUrl="https://thunderstore.io/c/riskofrain2/p/$author/$name/"
        Instructions="Download exactly $key $version, drag the ZIP into this window, then choose Retry."
        SkipMessage="Skipped - $key $version is missing; this installation will be reported as incomplete."
    }
    $result = Invoke-SafeDownload @downloadArgs
    if ([string]$result -eq 'quit') { return 'quit' }
    if (-not ($result -is [bool] -and $result)) { return $null }
    return $zip
}

function Expand-TSPackage {
    param([string]$ArchivePath, [string]$Destination, [string]$Label)
    $result = Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $Destination -Label $Label `
        -SkipMessage "Skipped - $Label could not be extracted; the installation will be reported as incomplete."
    if ([string]$result -eq 'quit') { return 'quit' }
    if ([string]$result -notin @('ok','manual')) { return $null }
    $manifestPath = Join-Path $Destination 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json) } catch { return $null }
}

function Resolve-CurrentPackageSet {
    param($MainInfo, [string]$TempDir, [array]$CompatibilityRequirements = @(), [switch]$PinnedSnapshot)
    $queue = New-Object 'System.Collections.Generic.Queue[object]'
    $queue.Enqueue([pscustomobject]@{ Author=$MainInfo.Author; Name=$MainInfo.Name; Version=$MainInfo.Version; RequiredBy='Risk of Rain 2 VR'; Main=$true })
    foreach ($compatibilityRequirement in @($CompatibilityRequirements)) {
        $queue.Enqueue([pscustomobject]@{
            Author=[string]$compatibilityRequirement.Author
            Name=[string]$compatibilityRequirement.Name
            Version=[string]$compatibilityRequirement.Version
            RequiredBy=[string]$compatibilityRequirement.RequiredBy
            Main=$false
        })
    }
    $resolved = @{}
    $failed = New-Object Collections.Generic.List[string]

    while ($queue.Count -gt 0) {
        $requirement = $queue.Dequeue()
        $key = "$($requirement.Author)-$($requirement.Name)".ToLowerInvariant()
        if ($resolved.ContainsKey($key)) {
            if ((Compare-TSVersion -Left ([string]$resolved[$key].Version) -Right ([string]$requirement.Version)) -ge 0) { continue }
        }

        Write-Info "Resolving $($requirement.Author)-$($requirement.Name) $($requirement.Version) (required by $($requirement.RequiredBy))"
        $zip = Get-TSPackageArchive -Requirement $requirement -TempDir $TempDir -MainPackage:([bool]$requirement.Main) -PinnedSnapshot:$PinnedSnapshot
        if ([string]$zip -eq 'quit') { return [pscustomobject]@{ Quit=$true; Packages=@(); Failed=@() } }
        if (-not $zip) { $failed.Add("$($requirement.Author)-$($requirement.Name) $($requirement.Version)"); continue }
        $extract = Join-Path $TempDir ("extract-" + $key + '-' + $requirement.Version)
        $manifest = Expand-TSPackage -ArchivePath $zip -Destination $extract -Label "$($requirement.Name) $($requirement.Version)"
        if ([string]$manifest -eq 'quit') { return [pscustomobject]@{ Quit=$true; Packages=@(); Failed=@() } }
        if (-not $manifest) {
            $failed.Add("$($requirement.Author)-$($requirement.Name) $($requirement.Version)")
            continue
        }
        if ($requirement.Main) {
            $requiredMainFiles = @('plugins\VRMod.dll','patchers\VRPatcher.dll')
            $missingMainFile = @($requiredMainFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $extract $_) -PathType Leaf) })
            if ($missingMainFile.Count -gt 0) {
                $failed.Add("$($requirement.Author)-$($requirement.Name) $($requirement.Version)")
                continue
            }
        }

        $status = Get-TSPackageInfo -Author $requirement.Author -Name $requirement.Name
        $resolved[$key] = [pscustomobject]@{
            Key        = "$($requirement.Author)-$($requirement.Name)"
            Author     = [string]$requirement.Author
            Name       = [string]$requirement.Name
            Version    = [string]$requirement.Version
            Archive    = $zip
            Extract    = $extract
            Deprecated = [bool]($status -and $status.Deprecated)
            Main       = [bool]$requirement.Main
        }
        foreach ($dependency in @($manifest.dependencies)) {
            $parsed = ConvertFrom-TSDependency -Dependency ([string]$dependency) -RequiredBy ([string]$requirement.Name)
            if ($parsed) { $queue.Enqueue($parsed) }
        }
    }
    return [pscustomobject]@{ Quit=$false; Packages=@($resolved.Values); Failed=@($failed) }
}

function Install-TSResolvedPackage {
    param($Package, [string]$GamePath)
    $source = [string]$Package.Extract
    $metadata = @('manifest.json','README.md','CHANGELOG.md','INSTALL.txt','LICENSE','LICENSE.md','icon.png')
    $handled = @{}

    $wrapper = Join-Path $source 'BepInExPack'
    if (Test-Path -LiteralPath $wrapper -PathType Container) {
        $null = Merge-DirectoryTreeVerified -Source $wrapper -Destination $GamePath -Label "$($Package.Name) loader files" `
            -KeepExistingRelativePaths @('BepInEx\config')
        $handled['BepInExPack'] = $true
    }
    $bepRoot = Join-Path $source 'BepInEx'
    if (Test-Path -LiteralPath $bepRoot -PathType Container) {
        $null = Merge-DirectoryTreeVerified -Source $bepRoot -Destination (Join-Path $GamePath 'BepInEx') `
            -Label "$($Package.Name) BepInEx files" -KeepExistingRelativePaths @('config')
        $handled['BepInEx'] = $true
    }
    foreach ($route in @('plugins','patchers','core','monomod','config')) {
        $routeSource = Join-Path $source $route
        if (Test-Path -LiteralPath $routeSource -PathType Container) {
            $routeDestination = Join-Path $GamePath "BepInEx\$route"
            if ($route -eq 'plugins' -and $Package.Name -eq 'RoR2BepInExPack') {
                # The current BepInEx preloader deliberately deletes the old
                # bare BepInEx\plugins\RoR2BepInExPack layout during startup.
                # r2modman installs this package below its package key, so keep
                # the exact manager layout and the Newtonsoft dependency alive.
                $routeDestination = Join-Path $routeDestination $Package.Key
            }
            if ($route -eq 'config') {
                # Config is user-owned after first launch. Supply defaults only
                # where the package has no existing counterpart; never replace
                # a player's settings while updating the mod or dependencies.
                foreach ($configFile in @(Get-ChildItem -LiteralPath $routeSource -File -Recurse -Force)) {
                    $relative = $configFile.FullName.Substring($routeSource.Length).TrimStart([char[]]'\/')
                    $target = Join-Path $routeDestination $relative
                    if (Test-Path -LiteralPath $target -PathType Leaf) {
                        Write-Info "Keeping existing config: BepInEx\config\$relative"
                        continue
                    }
                    $null = Merge-PathItemVerified -Source $configFile.FullName -Destination $target `
                        -Label "$($Package.Name) config $relative"
                }
            } else {
                $null = Merge-DirectoryTreeVerified -Source $routeSource -Destination $routeDestination `
                    -Label "$($Package.Name) $route files"
            }
            $handled[$route] = $true
        }
    }

    $loose = @(Get-ChildItem -LiteralPath $source -Force | Where-Object {
        $_.Name -notin $metadata -and -not $handled.ContainsKey($_.Name)
    })
    if ($loose.Count -gt 0) {
        $pluginDir = Join-Path $GamePath "BepInEx\plugins\$($Package.Key)"
        foreach ($item in $loose) {
            $null = Merge-PathItemVerified -Source $item.FullName -Destination (Join-Path $pluginDir $item.Name) `
                -Label "$($Package.Name) $($item.Name)"
        }
    }
}

function Install-ResolvedModSet {
    param(
        [string]$GamePath,
        $MainInfo,
        [string]$PathFile,
        [string]$VersionFile,
        [string]$TempLabel = 'Current',
        [array]$CompatibilityRequirements = @(),
        [switch]$PinnedSnapshot
    )
    $tempDir = Join-Path $env:TEMP ("RoR2$TempLabel" + [IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $resolution = Resolve-CurrentPackageSet -MainInfo $MainInfo -TempDir $tempDir `
        -CompatibilityRequirements $CompatibilityRequirements -PinnedSnapshot:$PinnedSnapshot
    if ($resolution.Quit) {
        try { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        return [pscustomobject]@{ Quit=$true; Packages=@(); Failed=@() }
    }
    $deprecated = @($resolution.Packages | Where-Object Deprecated)
    if ($deprecated.Count -gt 0) {
        Write-Warn "Thunderstore currently marks these required packages DEPRECATED:"
        foreach ($pkg in $deprecated) { Write-Host "      $($pkg.Key) $($pkg.Version)" -ForegroundColor Yellow }
    } else {
        Write-OK "The complete resolved package chain is not deprecated."
    }

    $failed = @($resolution.Failed)
    $ordered = @($resolution.Packages | Sort-Object @{Expression={ if ($_.Name -eq 'BepInExPack') { 0 } elseif ($_.Main) { 20 } else { 10 } }}, Name)
    $copiedPackages = @()
    foreach ($pkg in $ordered) {
        try {
            Install-TSResolvedPackage -Package $pkg -GamePath $GamePath
            $copiedPackages += $pkg
            Write-OK "$($pkg.Key) $($pkg.Version) files copied."
        } catch {
            Write-Fail "$($pkg.Key) failed: $($_.Exception.Message)"
            $failed += "$($pkg.Key) $($pkg.Version)"
        }
    }
    $proofRelative = @(
        'winhttp.dll',
        'BepInEx\plugins\VRMod.dll',
        'BepInEx\patchers\VRPatcher.dll',
        'BepInEx\patchers\Bepinex.MonoMod.HookGenPatcher\BepInEx.MonoMod.HookGenPatcher.dll',
        'BepInEx\plugins\RiskofThunder-RoR2BepInExPack\RoR2BepInExPack\RoR2BepInExPack.dll',
        'BepInEx\plugins\RiskofThunder-RoR2BepInExPack\RoR2BepInExPack\Newtonsoft.Json.dll'
    )
    $proofPaths = @($proofRelative | ForEach-Object { Join-Path $GamePath $_ })
    $missingImmediately = @($proofRelative | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $GamePath $_) -PathType Leaf)
    })
    if ($missingImmediately.Count -gt 0) {
        $failed += $missingImmediately
    } elseif ($failed.Count -eq 0) {
        # The old installer committed Thunderstore receipts immediately after
        # copying. A delayed scanner could then remove VRMod.dll while the Hub
        # continued to treat the orphaned receipt as a complete installation.
        # Keep all downloaded archives until the survival check has passed and
        # restore each required file from its owning publisher archive, staged
        # inside the game folder after the user adds an exclusion.
        $mainPackage = @($copiedPackages | Where-Object Main | Select-Object -First 1)
        $loaderPackage = @($copiedPackages | Where-Object Name -eq 'BepInExPack' | Select-Object -First 1)
        $hookPackage = @($copiedPackages | Where-Object Name -eq 'HookGenPatcher' | Select-Object -First 1)
        $runtimePackage = @($copiedPackages | Where-Object Name -eq 'RoR2BepInExPack' | Select-Object -First 1)
        $recover = {
            if ($loaderPackage) {
                [void](Restore-FromArchiveInGameFolder -ArchivePath $loaderPackage.Archive -GameDir $GamePath `
                    -Paths @((Join-Path $GamePath 'winhttp.dll')))
            }
            if ($mainPackage) {
                [void](Restore-FromArchiveInGameFolder -ArchivePath $mainPackage.Archive -GameDir $GamePath `
                    -Paths @(
                        (Join-Path $GamePath 'BepInEx\plugins\VRMod.dll'),
                        (Join-Path $GamePath 'BepInEx\patchers\VRPatcher.dll')
                    ))
            }
            if ($hookPackage) {
                [void](Restore-FromArchiveInGameFolder -ArchivePath $hookPackage.Archive -GameDir $GamePath `
                    -Paths @((Join-Path $GamePath 'BepInEx\patchers\Bepinex.MonoMod.HookGenPatcher\BepInEx.MonoMod.HookGenPatcher.dll')))
            }
            if ($runtimePackage) {
                [void](Restore-FromArchiveInGameFolder -ArchivePath $runtimePackage.Archive -GameDir $GamePath `
                    -Paths @(
                        (Join-Path $GamePath 'BepInEx\plugins\RiskofThunder-RoR2BepInExPack\RoR2BepInExPack\RoR2BepInExPack.dll'),
                        (Join-Path $GamePath 'BepInEx\plugins\RiskofThunder-RoR2BepInExPack\RoR2BepInExPack\Newtonsoft.Json.dll')
                    ))
            }
        }
        if (-not (Confirm-PlacedFilesSurvive -Paths $proofPaths -GameDir $GamePath -Recopy $recover)) {
            $failed += 'required VR runtime files did not survive the antivirus check'
        }
    }
    $failed = @($failed | Select-Object -Unique)
    if ($failed.Count -eq 0) {
        # Receipts are completion evidence, not copy-attempt evidence. Commit
        # them only after every package, runtime proof and delayed AV check has
        # succeeded.
        foreach ($pkg in $copiedPackages) {
            Set-InstalledTSVersion -Key $pkg.Key -Version $pkg.Version -GamePath $GamePath
        }
        try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot $PathFile), $GamePath, (New-Object Text.UTF8Encoding $false)) } catch {}
        try { [IO.File]::WriteAllText((Join-Path $PSScriptRoot $VersionFile), ([string]$MainInfo.Version), (New-Object Text.UTF8Encoding $false)) } catch {}
        Save-InstalledStamp -GameDir $GamePath -Version $MainInfo.Version -HubDir $PSScriptRoot
    }
    try { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    return [pscustomobject]@{ Quit=$false; Packages=@($resolution.Packages); Failed=@($failed) }
}

function Show-CurrentFinish {
    param([string]$GamePath, [string]$Version, [array]$Packages, [array]$Failed, [switch]$SeparateDepot)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Installation Summary" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    foreach ($pkg in @($Packages | Sort-Object Main, Name)) {
        $installed = Get-InstalledTSVersion -Key $pkg.Key -GamePath $GamePath
        if ($installed -eq $pkg.Version) { Write-Host " [x] $($pkg.Key) $installed" -ForegroundColor Green }
        else { Write-Host " [ ] $($pkg.Key) $($pkg.Version) -- FAILED" -ForegroundColor Red }
    }
    foreach ($name in $Failed) { Write-Host " [ ] $name -- FAILED" -ForegroundColor Red }
    Write-Host ""
    if ($Failed.Count -eq 0) {
        if ($SeparateDepot) {
            Write-Host " Start with" -NoNewline -ForegroundColor White
            Write-Host " Start 1.4.1 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host "in the Hub, or its dedicated desktop shortcut." -ForegroundColor White
            Write-Host " Do not launch this depot through Steam; Steam opens the current copy." -ForegroundColor Gray
        } else {
            Write-Host " Start with" -NoNewline -ForegroundColor White
            Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host "in the Hub, or launch normally through Steam." -ForegroundColor White
        }
        Write-Host " The first launch places the OpenXR native files. If the" -ForegroundColor Gray
        Write-Host " headset stays black that first time, close it and launch again." -ForegroundColor Gray
    } else {
        Write-Warn "This installation is incomplete. Run the same installer option again to retry only the missing packages."
    }
    Write-Host ""
    Write-Host " Seek and destroy. It's raining again!" -ForegroundColor Magenta
    Write-Host ""
    Pause-User "Press Enter to exit."
}

# -------------------------------------------------------
# OPTION SELECTION
# -------------------------------------------------------
Write-Header
Show-AntivirusNotice -Compact
Write-Step 1 4 "Select installation mode"
Write-Host "  [1] Current game version - Resurrected VRMod by Blowntobytes" -ForegroundColor White
$currentInfo = Get-TSPackageInfo -Author $CURRENT_AUTHOR -Name $CURRENT_PACKAGE
if (-not $currentInfo) {
    $currentInfo = [pscustomobject]@{
        Author=$CURRENT_AUTHOR; Name=$CURRENT_PACKAGE; Version=$CURRENT_FALLBACK_VERSION
        DownloadUrl="https://thunderstore.io/package/download/$CURRENT_AUTHOR/$CURRENT_PACKAGE/$CURRENT_FALLBACK_VERSION/"
        Deprecated=$false
    }
    Write-Warn "Thunderstore status unavailable - the last known publisher package $CURRENT_FALLBACK_VERSION will be used."
} elseif ($currentInfo.Deprecated) {
    Write-Host "      [DEPRECATED on Thunderstore - current option may be broken]" -ForegroundColor Yellow
} else {
    Write-Host "      [current Steam build / Thunderstore $($currentInfo.Version) / not deprecated]" -ForegroundColor Green
}
Write-Host ""
Write-Host "  [2] Last confirmed working version - recommended fallback" -ForegroundColor White
Write-Host "      [game $CONFIRMED_GAME_VERSION / build $CONFIRMED_GAME_BUILD / Resurrected VRMod $CONFIRMED_MOD_VERSION]" -ForegroundColor Gray
if (Test-Path -LiteralPath (Join-Path $CONFIRMED_DEFAULT_PATH $GAME_EXE) -PathType Leaf) {
    Write-Host "      [installed at $CONFIRMED_DEFAULT_PATH]" -ForegroundColor Green
} else {
    Write-Host "      [separate pinned build / not installed]" -ForegroundColor Gray
}
Write-Host ""
Write-Host "  [3] Original legacy depot - VRMod 2.9.2 by DrBibop" -ForegroundColor White
if (Test-Path -LiteralPath (Join-Path $LEGACY_DEFAULT_PATH $GAME_EXE) -PathType Leaf) {
    Write-Host "      [installed at $LEGACY_DEFAULT_PATH]" -ForegroundColor Green
} else {
    Write-Host "      [original separate fallback / not installed]" -ForegroundColor Gray
}
Write-Host ""
$mode = ''
while ($mode -notin @('1','2','3')) { $mode = ('' + (Read-Host '  Choice (1, 2 or 3)')).Trim() }

# -------------------------------------------------------
# OPTION 1: CURRENT STEAM VERSION
# -------------------------------------------------------
if ($mode -eq '1') {
    Write-Step 2 4 "Locating the current Risk of Rain 2 install"
    $gamePath = Find-SteamGameFolder -AppId $DEPOT_APPID -SteamFolderNames @('Risk of Rain 2')
    if (-not $gamePath) {
        $gamePath = Get-GameFolderInteractive -GameName 'Risk of Rain 2' -ProbeFile $GAME_EXE `
            -ManualUrl 'https://store.steampowered.com/app/632360/Risk_of_Rain_2/'
    }
    if ($gamePath -in @('quit','skip',$null,'')) {
        Write-Warn "No game folder selected; nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
    Write-OK "Found: $gamePath"

    Write-Step 3 4 "Resolving and installing Thunderstore requirements"
    $result = Install-ResolvedModSet -GamePath $gamePath -MainInfo $currentInfo `
        -PathFile '.installed_path' -VersionFile '.installed_version' -TempLabel 'Current' `
        -CompatibilityRequirements $CURRENT_COMPATIBILITY_FLOOR
    if ($result.Quit) {
        Write-Warn "Installer stopped by request; nothing was installed."
        Pause-User "Press Enter to exit."
        exit 0
    }
    Write-Step 4 4 "Verifying the current-version package set"
    Show-CurrentFinish -GamePath $gamePath -Version $currentInfo.Version -Packages $result.Packages -Failed $result.Failed
    exit 0
}

# -------------------------------------------------------
# OPTIONS 2 / 3: Steam Depot Download
# -------------------------------------------------------
$depotRoute = if ($mode -eq '2') { 'Confirmed' } else { 'Legacy' }
if ($depotRoute -eq 'Confirmed') {
    $DEPOT_MANIFEST = $CONFIRMED_MANIFEST
    $DEFAULT_PATH = $CONFIRMED_DEFAULT_PATH
} else {
    $DEPOT_MANIFEST = $LEGACY_MANIFEST
    $DEFAULT_PATH = $LEGACY_DEFAULT_PATH
}
$DEPOT_COMMAND = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"
Write-Step 2 4 "Steam Depot Download"

$depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE
if ($depotPath) {
    Write-OK "The depot is already downloaded: $depotPath"
    Write-Info "Skipping the Steam Console and download prompts."
} else {
Write-Host "  We need to download a specific older version of Risk of Rain 2 via Steam." -ForegroundColor White
Write-Host ""
Write-Host "  Here's what's about to happen:" -ForegroundColor Cyan
Write-Host "    1) The Steam Console will open automatically" -ForegroundColor White
Write-Host "    2) The download command is already copied to your clipboard" -ForegroundColor White
Write-Host "    3) Paste with Ctrl+V into the Steam Console and hit Enter" -ForegroundColor Yellow
Write-Host "    4) Wait for Steam to finish, then come back here" -ForegroundColor White
Write-Host ""
Write-Host "  When Steam finishes it will show:" -ForegroundColor Gray
Write-Host "    Depot download complete : ...\depot_632361" -ForegroundColor Yellow
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND -DeferManualFallback } catch {}

Write-Host ""
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
Pause-User "Press Enter to open the Steam Console..."
# Both protocol addresses: depending on the Steam build only one works.
foreach ($cu in @("steam://open/console", "steam://nav/console")) {
    try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
}
Show-PCVRClipboardManualFallback -Text $DEPOT_COMMAND
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."
}

# -------------------------------------------------------
# Auto-detect depot path from Steam registry
# -------------------------------------------------------
Write-Host ""
Write-Host "  Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
$steamRegPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)
foreach ($reg in $steamRegPaths) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$probePaths = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -AdditionalSteamRoots @($steamInstallPath))
if (-not $depotPath) {
    $depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamInstallPath)
    if ($depotPath) { Write-OK "Depot folder found automatically: $depotPath" }
    else { Write-Warn "Depot folder not found yet in any Steam library." }
}

# Fallback: ask user
if (-not $depotPath) {
    $depotPath = Resolve-DepotPath -GameName "Risk of Rain 2" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 1.5: Move depot to stable folder
# -------------------------------------------------------
# The depot is delivered into steamapps\content\app_<id>\depot_<id>
# which Steam may overwrite during a future depot download. Move
# it to a stable, separate folder under C:\Games\ so the VR
# install survives Steam updates and stays separate from the
# retail RoR2 install.
Write-Step 3 4 "Moving game to stable folder"

Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use default, or type a different full path").Trim().Trim('"')
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

if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
    Write-Info "Existing installation found. The depot will be merged; saves, settings and additional mods are preserved."
}

try {
    $parentOfDepot = Get-PathParentLexical $depotPath
    $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "Risk of Rain 2 depot build"
    Write-OK "Game merged into: $targetPath"
    # Clean up empty app_<id> folder
    try {
        if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
            Remove-Item $parentOfDepot -Force
        }
    } catch {}
} catch {
    Write-Fail "Move failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Pause-User "Press Enter to exit..."
    exit 1
}

$gamePath = $targetPath

if ($depotRoute -eq 'Confirmed') {
    Write-Step 4 4 "Installing the confirmed package snapshot"
    $result = Install-ResolvedModSet -GamePath $gamePath -MainInfo $CONFIRMED_MAIN_INFO `
        -PathFile '.installed_path_depot' -VersionFile '.installed_version_depot' -TempLabel 'Confirmed' `
        -CompatibilityRequirements $CURRENT_COMPATIBILITY_FLOOR -PinnedSnapshot
    if ($result.Quit) {
        Write-Warn "Installer stopped by request; the depot game files remain available at $gamePath."
        Pause-User "Press Enter to exit."
        exit 0
    }
    try { Set-Content -Path (Join-Path $gamePath 'steam_appid.txt') -Value '632360' -Encoding ASCII -NoNewline -Force } catch {}
    $confirmedExe = Join-Path $gamePath $GAME_EXE
    if ($result.Failed.Count -eq 0 -and (Test-Path -LiteralPath $confirmedExe -PathType Leaf)) {
        try {
            $null = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Risk of Rain 2 $CONFIRMED_GAME_VERSION VR.lnk" `
                -TargetPath $confirmedExe -WorkingDir $gamePath -IconPath "$confirmedExe,0"
            Write-OK "Desktop shortcut 'Risk of Rain 2 $CONFIRMED_GAME_VERSION VR' created."
        } catch { Write-Warn "Could not create the confirmed-version shortcut: $($_.Exception.Message)" }
    }
    Show-CurrentFinish -GamePath $gamePath -Version $CONFIRMED_MAIN_INFO.Version `
        -Packages $result.Packages -Failed $result.Failed -SeparateDepot
    exit 0
}

$MODS = $LEGACY_MODS

# -------------------------------------------------------
# STEP 2: Download and install mods into the stable folder
# -------------------------------------------------------
Write-Step 4 4 "Installing the depot VR mod"

$tempDir = Join-Path $env:TEMP "RoR2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$failed = @()

foreach ($mod in $MODS) {
    $author  = $mod.Author
    $name    = $mod.Name
    $version = $mod.Version
    $type    = $mod.Type

    Write-Host "  Downloading $name $version ... " -NoNewline -ForegroundColor White

    $url        = "https://thunderstore.io/package/download/$author/$name/$version/"
    $zipFile    = Join-Path $tempDir "$name-$version.zip"
    $extractDir = Join-Path $tempDir "$name-$version"

    $r = Invoke-DownloadOrFallback -Url $url -Destination $zipFile `
            -Label "$name $version" `
            -ManualUrl "https://thunderstore.io/c/risk-of-rain-2/p/$author/$name/" `
            -Instructions "Find '$name' version $version on the Thunderstore page, download the ZIP, place it at '$zipFile', then choose Retry." `
            -SkipMessage "Skipped - $name $version was not downloaded (questionable result)."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if (-not ($r -is [bool] -and $r)) {
        $failed += $name
        continue
    }

    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    $efb = Expand-ArchiveOrFallback -ArchivePath $zipFile -DestinationFolder $extractDir -Label "$name $version" `
            -SkipMessage "Skipped - $name was not extracted (questionable result)."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -ne "ok" -and [string]$efb -ne "manual") {
        $failed += $name
        continue
    }

    $ignore = @("manifest.json", "README.md", "icon.png", "CHANGELOG.md", "changelog.txt")

    try {
        switch ($type) {

            "bepinex" {
                # BepInExPack has an extra BepInExPack/ wrapper folder - copy its contents to game root
                $packSubdir = Join-Path $extractDir "BepInExPack"
                if (Test-Path $packSubdir) {
                    $null = Merge-DirectoryTreeVerified -Source $packSubdir -Destination $gamePath -Label "$name files" `
                        -KeepExistingRelativePaths @("BepInEx\config")
                } else {
                    # Other bepinex type mods (RoR2BepInExPack) - copy straight to game root
                    Get-ChildItem -Path $extractDir | Where-Object { $_.Name -notin $ignore } | ForEach-Object {
                        $target = Join-Path $gamePath $_.Name
                        $keep = if ($_.Name -ieq "BepInEx") { @("config") } else { @() }
                        $null = Merge-PathItemVerified -Source $_.FullName -Destination $target -Label "$($_.Name) files" `
                            -KeepExistingRelativePaths $keep
                    }
                }
            }

            { $_ -in "plugins", "patchers" } {
                $bepinexInZip = Join-Path $extractDir "BepInEx"
                if (Test-Path $bepinexInZip) {
                    # Mod ships with BepInEx/ folder structure - merge into game root
                    $null = Merge-DirectoryTreeVerified -Source $bepinexInZip -Destination (Join-Path $gamePath "BepInEx") `
                        -Label "$name BepInEx files" -KeepExistingRelativePaths @("config")
                } else {
                    # Mod ships plugins/ and patchers/ folders directly (e.g. VRMod)
                    # Copy their contents straight into BepInEx/plugins/ and BepInEx/patchers/
                    foreach ($subfolder in @("plugins", "patchers")) {
                        $src = Join-Path $extractDir $subfolder
                        if (Test-Path $src) {
                            $dst = Join-Path $gamePath "BepInEx\$subfolder"
                            if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
                            Get-ChildItem -Path $src | ForEach-Object {
                                Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
                            }
                        }
                    }
                }
            }
        }
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "INSTALL FAILED" -ForegroundColor Red
        Write-Host "    $_" -ForegroundColor Gray
        $failed += $name
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Warn "The following mods failed and need manual installation from thunderstore.io:"
    foreach ($f in $failed) { Write-Host "    - $f" -ForegroundColor Red }
}

# -------------------------------------------------------
# STEP 3: Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "  Your complete RoR2 VR installation is ready at:" -ForegroundColor White
Write-Host "  $gamePath" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Installed mods:" -ForegroundColor White
foreach ($mod in $MODS) {
    if ($mod.Name -notin $failed) {
        Write-Host "    [x] $($mod.Name) $($mod.Version)" -ForegroundColor Green
    } else {
        Write-Host "    [ ] $($mod.Name) $($mod.Version)  <-- FAILED, install manually" -ForegroundColor Red
    }
}
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  Next steps:" -ForegroundColor White
Write-Host ""
Write-Host "  Game installed at: $gamePath" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANT: Do NOT launch via Steam!" -ForegroundColor Yellow
Write-Host "  Use the desktop shortcut 'Risk of Rain 2 Legacy VR'." -ForegroundColor Yellow
Write-Host "  (Launching via Steam would run your retail flat version)" -ForegroundColor Gray
Write-Host ""
Write-Host "  BepInEx and VRMod load automatically." -ForegroundColor Gray
Write-Host "  SteamVR will launch alongside the game." -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""

# Create desktop shortcut to RoR2 exe
$ror2Exe = Join-Path $gamePath $GAME_EXE
try { Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value "632360" -Encoding ASCII -NoNewline -Force } catch {}

$legacyProof = Join-Path $gamePath "BepInEx\plugins\VRMod.dll"
if ((Test-Path -LiteralPath $legacyProof -PathType Leaf) -and ('VRMod' -notin $failed)) {
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path_legacy_depot") -Value $gamePath -Encoding UTF8 -Force } catch {}
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version_legacy_depot") -Value "2.9.2" -Encoding UTF8 -Force } catch {}
    Save-InstalledStamp -GameDir $gamePath -Version "2.9.2" -HubDir $PSScriptRoot
}

if (Test-Path $ror2Exe) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Risk of Rain 2 Legacy VR.lnk" -TargetPath $ror2Exe -WorkingDir $gamePath -IconPath "$ror2Exe,0"
        Write-OK "Desktop shortcut 'Risk of Rain 2 Legacy VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $_"
    }
} else {
    Write-Info "$GAME_EXE not found - create a shortcut manually."
}

Write-Host ""
Write-Host "  Opening installation folder..." -ForegroundColor Gray
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

Write-Host "  Seek and destroy. It's raining again!" -ForegroundColor Magenta
  Write-Host ""
  Pause-User "Press Enter to exit."
