# Silent Hill 3 VR - safe three-component installer.
# Downloads are acquired at run time. No mod archive is bundled with the Hub.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Silent Hill 3 VR Installer"
$GAME_EXE = "sh3.exe"
$MOD_NAME = "Silent Hill 3 VR"
$MOD_VERSION = "Beta 0.1"
$MOD_AUTHOR = "NotGodlikeUwU"
$REPO = "NotGodlikeUwU/Silent-Hill-3-VR-Mod"
$RELEASES_URL = "https://github.com/$REPO/releases"
$PC_FIX_URL = "https://community.pcgamingwiki.com/files/file/1331-silent-hill-3-pc-fix-by-steam006/"
$CAMERA_URL = "https://github.com/zealottormunds/sh3cammod/releases/download/1.0/Silent.Hill.3.-.Zealot.s.Camera.Mod.v1.0.rar"
$PC_FIX_NAME = "Silent_Hill_3_PC_Fix_2.8.5-Steam006.zip"
$PC_FIX_PASSWORD = "pcgw"
$CAMERA_NAME = "Silent.Hill.3.-.Zealot.s.Camera.Mod.v1.0.rar"
$PINNED_VR_NAME = "Silent.Hill.3.VR.v0.1.5-beta.zip"
$PINNED_VR_URL = "https://github.com/$REPO/releases/download/Beta_0.1.5/$PINNED_VR_NAME"
$MANIFEST_NAME = ".pcvrhub-sh3vr-install.tsv"
$BACKUP_NAME = ".pcvrhub-sh3vr-backup"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Silent Hill 3 VR - Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ""; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!]  $Text" -ForegroundColor Yellow }
function Write-Fail { param([string]$Text) Write-Host " [X]  $Text" -ForegroundColor Red }
function Pause-User { param([string]$Text="Press Enter to continue...") Write-Host ""; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-SH3Root([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function Find-SH3Root {
    $recorded = $null
    try { $recorded = (Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Raw).Trim() } catch {}
    if (Test-SH3Root $recorded) { return $recorded }
    foreach ($candidate in @(
        "C:\Program Files (x86)\KONAMI\SILENT HILL 3",
        "C:\Program Files\KONAMI\SILENT HILL 3"
    )) { if (Test-SH3Root $candidate) { return $candidate } }
    return $null
}

function Read-SH3Location {
    while ($true) {
        Write-Warn "Silent Hill 3 has no current PC store installation to detect."
        Write-Host " Drag sh3.exe into this window, or drag/paste its folder," -ForegroundColor White
        Write-Host " then press Enter. Leave the field empty to cancel." -ForegroundColor Gray
        $picked = ("" + (Read-Host " Game file or folder")).Trim().Trim('"').Trim("'")
        if (-not $picked) { return $null }
        if (Test-Path -LiteralPath $picked -PathType Leaf) {
            $item = Get-Item -LiteralPath $picked -ErrorAction SilentlyContinue
            if ($item -and $item.Name -ieq $GAME_EXE) { return $item.DirectoryName }
            Write-Fail "That is not $GAME_EXE."
            continue
        }
        if (Test-SH3Root $picked) { return (Get-Item -LiteralPath $picked).FullName }
        Write-Fail "$GAME_EXE was not found there."
    }
}

function Get-ArchiveInputFolder {
    try {
        $workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        return (Join-Path $workspace "Archive Input\Neue Spiele")
    } catch { return "" }
}

function Get-PCFixArchive {
    $extra = Get-ArchiveInputFolder
    $found = Find-PredownloadedFile -Patterns @($PC_FIX_NAME) -AllowUnverified `
        -ExtraFolders @($extra) -Label "Silent Hill 3 PC Fix 2.8.5"
    if ($found) { return $found }
    Write-Host ""
    Write-Host " The required PC Fix must be downloaded by you from PCGamingWiki." -ForegroundColor Yellow
    Write-Host " The Hub checks that it is a usable archive, then verifies the required files after extraction." -ForegroundColor Gray
    try { Start-Process $PC_FIX_URL } catch { Write-Warn "Open this page manually: $PC_FIX_URL" }
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        $raw = ("" + (Read-Host " Download it, then press Enter to search Downloads - or drag the ZIP here")).Trim().Trim('"').Trim("'")
        if ($raw) {
            if (Test-DownloadedPayload -Path $raw -IntendedPath $PC_FIX_NAME) { return $raw }
            Write-Fail "That is not a usable ZIP archive."
            continue
        }
        $found = Find-PredownloadedFile -Patterns @($PC_FIX_NAME) -AllowUnverified -ExtraFolders @($extra) `
            -PageAlreadyOpen -Label "Silent Hill 3 PC Fix 2.8.5"
        if ($found) { return $found }
        Write-Warn "The archive is not in Downloads yet."
    }
    return $null
}

function Get-CameraArchive([string]$Destination) {
    $extra = Get-ArchiveInputFolder
    $found = Find-PredownloadedFile -Patterns @($CAMERA_NAME) -AllowUnverified `
        -ExtraFolders @($extra) -Label "Zealot's Camera Mod v1.0"
    if ($found) { Copy-Item -LiteralPath $found -Destination $Destination -Force; return $Destination }
    if (Invoke-SafeDownload -Urls @($CAMERA_URL) -Destination $Destination -Label "Zealot's Camera Mod v1.0" `
        -ManualUrl "https://github.com/zealottormunds/sh3cammod/releases") { return $Destination }
    return $null
}

function Get-LatestVRRelease {
    try {
        # Do not wrap Invoke-RestMethod directly in @(...). PowerShell 7 can
        # retain GitHub's JSON array as one nested object in that form, so the
        # release loop never reaches .assets and silently falls back to an old
        # package. Materialize the response first, then normalize it.
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" -Headers @{"User-Agent"="PCVR-Mods-Hub"} -TimeoutSec 25 -ErrorAction Stop
        $releases = @($response)
        foreach ($release in $releases) {
            if ($release.draft) { continue }
            $asset = @($release.assets | Where-Object { $_.name -match '(?i)Silent[._ -]?Hill[._ -]?3.*VR.*\.zip$' } | Select-Object -First 1)[0]
            if ($asset) {
                return [pscustomobject]@{ Tag=[string]$release.tag_name; Name=[string]$asset.name; Url=[string]$asset.browser_download_url }
            }
        }
    } catch {}
    return [pscustomobject]@{ Tag="Beta_0.1.5"; Name=$PINNED_VR_NAME; Url=$PINNED_VR_URL }
}

function Get-VRArchive([string]$Destination,$Release) {
    $found = Find-PredownloadedFile -Patterns @($Release.Name) -ExtraFolders @((Get-ArchiveInputFolder)) -Label "Silent Hill 3 VR $($Release.Tag)"
    if ($found) { Copy-Item -LiteralPath $found -Destination $Destination -Force; return $Destination }
    if (-not (Invoke-SafeDownload -Urls @($Release.Url) -Destination $Destination -Label "Silent Hill 3 VR $($Release.Tag)" `
        -ManualUrl $RELEASES_URL)) { return $null }
    return $Destination
}

function Read-Manifest([string]$Path) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $map }
    try {
        foreach ($row in @((Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Csv -Delimiter "`t")) {
            if ($row.RelativePath) { $map[[string]$row.RelativePath] = $row }
        }
    } catch {}
    return $map
}

function Install-Component([string]$Name,[string]$PayloadRoot,[string]$GameRoot,[hashtable]$Rows,[string[]]$KeepFiles=@()) {
    $backupRoot = Join-Path (Join-Path $GameRoot $BACKUP_NAME) "original"
    $newPaths = New-Object 'System.Collections.Generic.List[string]'
    $payloadPrefix = $PayloadRoot.TrimEnd('\')
    foreach ($file in @(Get-ChildItem -LiteralPath $PayloadRoot -Recurse -File)) {
        $relative = $file.FullName.Substring($payloadPrefix.Length).TrimStart('\')
        [void]$newPaths.Add($relative)
        $destination = Join-Path $GameRoot $relative
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

        $keep = [bool]($KeepFiles | Where-Object { $_ -ieq $relative } | Select-Object -First 1)
        $old = if ($Rows.ContainsKey($relative)) { $Rows[$relative] } else { $null }
        $action = if ($old) { [string]$old.Action } else { "remove" }
        if ($keep -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $Rows[$relative] = [pscustomobject]@{ Component=$Name; Action="keep"; RelativePath=$relative; InstalledSha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash }
            Write-Info "Kept your existing setting: $relative"
            continue
        }
        if (-not $old -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $backup = Join-Path $backupRoot $relative
            $backupParent = Split-Path -Parent $backup
            if (-not (Test-Path -LiteralPath $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
            Copy-Item -LiteralPath $destination -Destination $backup -Force
            $action = "restore"
        } elseif ($old -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $oldHash = [string]$old.InstalledSha256
            $currentHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            if ($oldHash -and $currentHash -ne $oldHash -and $action -ne "keep") {
                $conflict = Join-Path (Join-Path $GameRoot ".pcvrhub-sh3vr-conflicts") ($relative + "." + (Get-Date -Format "yyyyMMddHHmmss"))
                $conflictParent = Split-Path -Parent $conflict
                if (-not (Test-Path -LiteralPath $conflictParent)) { New-Item -ItemType Directory -Path $conflictParent -Force | Out-Null }
                Copy-Item -LiteralPath $destination -Destination $conflict -Force
                Write-Warn "Preserved a changed file before updating: $relative"
            }
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        $Rows[$relative] = [pscustomobject]@{ Component=$Name; Action=$(if ($keep) { "keep" } else { $action }); RelativePath=$relative; InstalledSha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash }
    }

    # Remove files retired by a newer release, but only when the previous
    # installed hash still matches. Changed files remain tracked and intact.
    foreach ($key in @($Rows.Keys)) {
        $row = $Rows[$key]
        if ([string]$row.Component -ne $Name -or $newPaths.Contains([string]$key)) { continue }
        $target = Join-Path $GameRoot ([string]$key)
        if ([string]$row.Action -eq "keep") { $Rows.Remove($key); continue }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne [string]$row.InstalledSha256) { Write-Warn "Kept changed retired file: $key"; continue }
            if ([string]$row.Action -eq "restore") {
                $backup = Join-Path $backupRoot ([string]$key)
                if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { Write-Warn "Kept retired file because its original backup is missing: $key"; continue }
                Copy-Item -LiteralPath $backup -Destination $target -Force
            } else { Remove-Item -LiteralPath $target -Force }
        }
        $Rows.Remove($key)
    }
}

function Save-Manifest([string]$Path,[hashtable]$Rows) {
    $lines = @("Component`tAction`tRelativePath`tInstalledSha256")
    foreach ($key in @($Rows.Keys | Sort-Object)) {
        $r = $Rows[$key]
        $lines += "$($r.Component)`t$($r.Action)`t$($r.RelativePath)`t$($r.InstalledSha256)"
    }
    [IO.File]::WriteAllLines($Path, [string[]]$lines, (New-Object Text.UTF8Encoding($false)))
}

function Install-SafeShortcut([string]$GameRoot) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Silent Hill 3 VR.lnk"
    $state = Join-Path $GameRoot ".pcvrhub-sh3vr-shortcut-state.txt"
    $backup = Join-Path (Join-Path $GameRoot $BACKUP_NAME) "original-shortcut.lnk"
    if (-not (Test-Path -LiteralPath $state -PathType Leaf)) {
        if (Test-Path -LiteralPath $lnk -PathType Leaf) {
            $parent = Split-Path -Parent $backup
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $lnk -Destination $backup -Force
            [IO.File]::WriteAllText($state, "restore", (New-Object Text.UTF8Encoding($false)))
        } else {
            [IO.File]::WriteAllText($state, "remove", (New-Object Text.UTF8Encoding($false)))
        }
    }
    $exePath = Join-Path $GameRoot $GAME_EXE
    return (New-DesktopShortcut -LnkPath $lnk -TargetPath $exePath -WorkingDir $GameRoot -IconPath "$exePath,0" -Description "Launch Silent Hill 3 VR")
}

$work = $null
try {
    Write-Header
    Write-Host " REQUIRED: Silent Hill 3 PC Fix by Steam006 and Zealot's" -ForegroundColor Yellow
    Write-Host " Camera Mod. The Hub verifies and installs both before VR." -ForegroundColor Yellow
    Write-Host " The PC Fix download page opens only when its exact ZIP is" -ForegroundColor White
    Write-Host " not already in Downloads; you may also drag the ZIP here." -ForegroundColor White
    Write-Host ""
    Write-Host " The current beta supports the system OpenXR runtime and" -ForegroundColor Gray
    Write-Host " SteamVR. Quest 3 through Virtual Desktop remains the author's" -ForegroundColor Gray
    Write-Host " validated setup; other headsets still need testing." -ForegroundColor Gray
    Show-AntivirusNotice -Compact
    Pause-User "Press Enter to proceed with setup..." | Out-Null

    Write-Step 1 5 "Locating Silent Hill 3"
    $gamePath = Find-SH3Root
    if (-not (Test-SH3Root $gamePath)) { $gamePath = Read-SH3Location }
    if (-not (Test-SH3Root $gamePath)) { throw "Setup cancelled before any game file was changed." }
    Write-OK "Found: $gamePath"
    if (@(Get-Process -Name "sh3" -ErrorAction SilentlyContinue).Count) { throw "Silent Hill 3 is running. Close it and run setup again." }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_path"), $gamePath, (New-Object Text.UTF8Encoding($false)))

    $work = Join-Path $env:TEMP ("pcvr_sh3_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $sevenZip = Get-SevenZip -Required
    if (-not $sevenZip) { throw "7-Zip is required for the password-protected PC Fix and Camera Mod archives." }
    $manifestPath = Join-Path $gamePath $MANIFEST_NAME
    $rows = Read-Manifest $manifestPath
    $recoverySpecs = New-Object 'System.Collections.Generic.List[object]'

    Write-Step 2 5 "Installing the required PC Fix"
    if (Test-Path -LiteralPath (Join-Path $gamePath "Silent_Hill_3_PC_Fix.dll") -PathType Leaf) {
        Write-OK "PC Fix already present; it is left untouched."
    } else {
        $pcArchive = Get-PCFixArchive
        if (-not $pcArchive) { throw "The required PC Fix was not supplied." }
        $pcOut = Join-Path $work "pcfix"
        if (-not (Expand-7zWithProgress -SevenZip $sevenZip -Archive $pcArchive -Dest $pcOut -Label "Silent Hill 3 PC Fix" -Password $PC_FIX_PASSWORD)) { throw "Could not extract the PC Fix." }
        $pcRoot = Get-ExtractedPayloadRoot -ExtractDir $pcOut -RelModFile "Silent_Hill_3_PC_Fix.dll"
        if (-not (Test-Path -LiteralPath (Join-Path $pcRoot "Silent_Hill_3_PC_Fix.dll") -PathType Leaf)) { throw "The PC Fix payload is incomplete." }
        Install-Component -Name "PCFix" -PayloadRoot $pcRoot -GameRoot $gamePath -Rows $rows
        $pcBinaries = @(Get-ChildItem -LiteralPath $pcRoot -Recurse -File | Where-Object Extension -in @('.dll','.exe') | ForEach-Object { $_.FullName.Substring($pcRoot.TrimEnd('\').Length).TrimStart('\') })
        [void]$recoverySpecs.Add([pscustomobject]@{ Name="PCFix"; Archive=$pcArchive; Password=$PC_FIX_PASSWORD; Marker="Silent_Hill_3_PC_Fix.dll"; Relatives=$pcBinaries })
        Write-OK "PC Fix 2.8.5 installed."
    }

    Write-Step 3 5 "Installing Zealot's Camera Mod"
    if ((Test-Path -LiteralPath (Join-Path $gamePath "plugins\OTSMod.dll") -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $gamePath "dsound.dll") -PathType Leaf)) {
        Write-OK "Camera Mod already present; it is left untouched."
    } else {
        $cameraArchive = Get-CameraArchive (Join-Path $work $CAMERA_NAME)
        if (-not $cameraArchive) { throw "Could not acquire the required Camera Mod." }
        $cameraOut = Join-Path $work "camera"
        if (-not (Expand-7zWithProgress -SevenZip $sevenZip -Archive $cameraArchive -Dest $cameraOut -Label "Camera Mod")) { throw "Could not extract the Camera Mod." }
        $cameraRoot = Get-ExtractedPayloadRoot -ExtractDir $cameraOut -RelModFile "dsound.dll"
        if (-not (Test-Path -LiteralPath (Join-Path $cameraRoot "plugins\OTSMod.dll") -PathType Leaf)) { throw "The Camera Mod payload is incomplete." }
        Install-Component -Name "Camera" -PayloadRoot $cameraRoot -GameRoot $gamePath -Rows $rows
        $cameraBinaries = @(Get-ChildItem -LiteralPath $cameraRoot -Recurse -File | Where-Object Extension -in @('.dll','.exe') | ForEach-Object { $_.FullName.Substring($cameraRoot.TrimEnd('\').Length).TrimStart('\') })
        [void]$recoverySpecs.Add([pscustomobject]@{ Name="Camera"; Archive=$cameraArchive; Password=""; Marker="dsound.dll"; Relatives=$cameraBinaries })
        Write-OK "Camera Mod v1.0 installed."
    }

    Write-Step 4 5 "Downloading and installing the newest VR release"
    $release = Get-LatestVRRelease
    Write-Info "Newest usable release: $($release.Tag)"
    $vrArchive = Get-VRArchive -Destination (Join-Path $work $release.Name) -Release $release
    if (-not $vrArchive) { throw "Could not acquire the Silent Hill 3 VR release." }
    $vrOut = Join-Path $work "vr"
    if (-not (Expand-7zWithProgress -SevenZip $sevenZip -Archive $vrArchive -Dest $vrOut -Label "Silent Hill 3 VR")) { throw "Could not extract the VR release." }
    $vrRoot = Get-ExtractedPayloadRoot -ExtractDir $vrOut -RelModFile "dinput8.dll"
    foreach ($required in @("dinput8.dll","sh3vr_host64.exe","sh3vr.ini","sh3vr_weapons.ini","sh3vr_assets")) {
        if (-not (Test-Path -LiteralPath (Join-Path $vrRoot $required))) { throw "The VR release is incomplete: missing $required." }
    }
    Install-Component -Name "VR" -PayloadRoot $vrRoot -GameRoot $gamePath -Rows $rows -KeepFiles @("sh3vr.ini","sh3vr_weapons.ini")
    $vrBinaries = @(Get-ChildItem -LiteralPath $vrRoot -Recurse -File | Where-Object Extension -in @('.dll','.exe') | ForEach-Object { $_.FullName.Substring($vrRoot.TrimEnd('\').Length).TrimStart('\') })
    [void]$recoverySpecs.Add([pscustomobject]@{ Name="VR"; Archive=$vrArchive; Password=""; Marker="dinput8.dll"; Relatives=$vrBinaries })
    if (-not (Test-Path -LiteralPath (Join-Path $gamePath "dinput8.dll") -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $gamePath "sh3vr_host64.exe") -PathType Leaf)) { throw "Installation verification failed: the VR loader or host is missing." }

    Write-Step 5 5 "Saving recovery data and launch tools"
    Save-Manifest -Path $manifestPath -Rows $rows
    $watchPaths = @($recoverySpecs | ForEach-Object { $spec=$_; @($spec.Relatives | ForEach-Object { Join-Path $gamePath $_ }) })
    $gameForRecovery = $gamePath
    $sevenForRecovery = $sevenZip
    # PowerShell 5.1 and 7.x cannot reliably materialize List[object] via @(...)
    # and may throw "Argument types do not match". Keep this as ToArray().
    $specsForRecovery = $recoverySpecs.ToArray()
    $recoverBinaries = {
        $recoveryRoot = Join-Path $gameForRecovery ".pcvrhub-sh3vr-recovery"
        Remove-Item -LiteralPath $recoveryRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $recoveryRoot -Force | Out-Null
        try {
            foreach ($spec in $specsForRecovery) {
                $componentStage = Join-Path $recoveryRoot ([string]$spec.Name)
                $extractArgs = @{ SevenZip=$sevenForRecovery; Archive=[string]$spec.Archive; Dest=$componentStage; Label=("$($spec.Name) recovery") }
                if ($spec.Password) { $extractArgs.Password = [string]$spec.Password }
                if (-not (Expand-7zWithProgress @extractArgs)) { continue }
                $componentRoot = Get-ExtractedPayloadRoot -ExtractDir $componentStage -RelModFile ([string]$spec.Marker)
                foreach ($relative in @($spec.Relatives)) {
                    $source = Join-Path $componentRoot ([string]$relative)
                    $destination = Join-Path $gameForRecovery ([string]$relative)
                    if (-not (Test-Path -LiteralPath $destination -PathType Leaf) -and (Test-Path -LiteralPath $source -PathType Leaf)) {
                        $parent = Split-Path -Parent $destination
                        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                        Copy-Item -LiteralPath $source -Destination $destination -Force
                    }
                }
            }
        } finally {
            Remove-Item -LiteralPath $recoveryRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }.GetNewClosure()
    if (-not (Confirm-PlacedFilesSurvive -Paths $watchPaths -GameDir $gamePath -Recopy $recoverBinaries)) { throw "One or more required mod binaries did not survive the antivirus check." }
    Save-InstalledStamp -GameDir $gamePath -Version ([string]$release.Tag) -HubDir $PSScriptRoot
    $shortcut = Install-SafeShortcut -GameRoot $gamePath
    if ($shortcut) { Write-OK "Desktop shortcut created: Silent Hill 3 VR" }
    Write-OK "Silent Hill 3 VR $($release.Tag) installed."

    Write-Host ""
    Write-Host " STARTING THE GAME" -ForegroundColor Cyan
    Write-Host " Start your chosen OpenXR runtime, then use Start in VR in" -ForegroundColor White
    Write-Host " the Hub or the Silent Hill 3 VR desktop shortcut." -ForegroundColor White
    Write-Host " SteamVR is supported from Beta 0.1.5; Virtual Desktop remains" -ForegroundColor Gray
    Write-Host " the author's tested route." -ForegroundColor Gray
    Write-Host ""
    Write-Host " CONTROLS AND CAMERA" -ForegroundColor Cyan
    Write-Host " The Camera Mod menu is available with F1; F2 toggles its" -ForegroundColor White
    Write-Host " camera. VR resolution and FPS lock live in sh3vr.ini." -ForegroundColor White
    Write-Host ""
    Write-Host " Heather brought a flashlight. The mall brought everything else." -ForegroundColor Magenta
} catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
    throw
} finally {
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Pause-User "Press Enter to exit..." | Out-Null
