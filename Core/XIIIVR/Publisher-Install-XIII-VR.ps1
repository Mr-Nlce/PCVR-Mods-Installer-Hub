# XIII XR Bootstrap installer. Windows PowerShell 5.1+. No administrator access required.
[CmdletBinding()]
param([string]$GameDir, [string]$BepInExZip, [switch]$Uninstall, [string]$RestorePoint, [switch]$OpenXR, [string]$OpenCompositeDll, [switch]$NoOpenComposite, [switch]$DownloadOpenComposite)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Version = '0.1.257'
$PackageRoot = $PSScriptRoot
$BuildName = 'BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.788+5b766a3.zip'
$BuildUrl = 'https://builds.bepinex.dev/projects/bepinex_be/788/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.788%2B5b766a3.zip'
$CoreHash = '46cf1ef802bdf8cb6587fc1e4d98f7af1073a60487b39a64e230e6f6e4c23aec'
# 0.1.174: OpenXR mode (Pimax Play / Oculus OpenXR runtime, no SteamVR):
# OpenComposite (OpenVR on OpenXR). Its official per-game build; or
# OpenComposite\openvr_api.dll beside this script; or -OpenCompositeDll <path>.
# 0.1.180: one install serves all. The mod's openvr_api.dll (the
# runtime switch, buildtools\openvr-shim) chooses at every game start: the
# Windows default OpenXR runtime SteamVR (or none) -> Valve's own DLL
# (openvr_api_valve.dll), any other -> OpenComposite (openvr_api_oc.dll).
# OpenComposite is downloaded once; later installs keep the one in the game.
# -NoOpenComposite: SteamVR only. -OpenXR is accepted and changes nothing.
# 0.1.181: the game goes into the
# default OpenXR runtime by itself (Unity's OpenXR plugin + the mod's
# xiii_openxr.dll, in GameFolder). The OpenVR way stays as the fallback;
# OpenComposite is no longer downloaded (one already in the game is kept;
# -DownloadOpenComposite fetches it for the fallback).
$OpenCompositeUrl = 'https://znix.xyz/OpenComposite/download.php?arch=x64&branch=openxr'
$stage = $null
$journalPath = $null
$journal = $null
$applied = [System.Collections.Generic.List[object]]::new()

function Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Replace-StagedFile([string]$Source,[string]$Destination,[string]$Backup) {
    # Windows PowerShell can marshal $null as an empty System.String. File.Replace
    # rejects that as a backup path. Supply a real same-volume backup instead.
    foreach ($path in @($Source,$Destination,$Backup)) {
        if ([string]::IsNullOrWhiteSpace($path) -or -not [IO.Path]::IsPathRooted($path)) { throw 'Replacement requires three absolute, nonempty paths.' }
    }
    [IO.File]::Replace($Source,$Destination,$Backup)
}
function Under([string]$Path, [string]$Root) {
    $p = [IO.Path]::GetFullPath($Path)
    $r = [IO.Path]::GetFullPath($Root).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    return $p.StartsWith($r, [StringComparison]::OrdinalIgnoreCase)
}
function Resolve-IniPath([string]$Value, [string]$Base) {
    $v = [Environment]::ExpandEnvironmentVariables($Value.Trim().Trim('"'))
    if (-not [IO.Path]::IsPathRooted($v)) { $v = Join-Path $Base $v }
    return [IO.Path]::GetFullPath($v)
}
function Read-Ini([string]$Path) {
    $result = @{}; $section = ''
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[([^\]]+)\]') { $section = $Matches[1].ToLowerInvariant(); continue }
        if ($line -match '^\s*([^#;=]+?)\s*=\s*(.*?)\s*$') { $result[($section + '/' + $Matches[1].ToLowerInvariant())] = $Matches[2] }
    }
    return $result
}
function Assert-Closed([string]$Directory) {
    $exe = Join-Path $Directory 'XIII.exe'
    foreach ($p in @(Get-Process -Name XIII -ErrorAction SilentlyContinue)) {
        $location = $null
        try { $location = $p.Path } catch { throw 'Close XIII before installing (process path unavailable).' }
        if (-not $location -or [string]::Equals($location,$exe,[StringComparison]::OrdinalIgnoreCase)) { throw 'Close XIII before installing or restoring.' }
    }
}
function Assert-X64([string]$Path) {
    $stream = [IO.File]::OpenRead($Path); $reader = [IO.BinaryReader]::new($stream)
    try {
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw 'Not a Windows executable.' }
        $stream.Position = 0x3C; $offset = $reader.ReadInt32()
        if ($offset -lt 64 -or $offset -gt $stream.Length-6) { throw 'Invalid PE header.' }
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x4550 -or $reader.ReadUInt16() -ne 0x8664) { throw 'This package needs XIII Remake Windows x64.' }
    } finally { $reader.Dispose(); $stream.Dispose() }
}
function Assert-Dll64([string]$Path) {
    $stream = [IO.File]::OpenRead($Path); $reader = [IO.BinaryReader]::new($stream)
    try {
        if ($stream.Length -lt 65536 -or $reader.ReadUInt16() -ne 0x5A4D) { throw 'OpenComposite: not a Windows DLL.' }
        $stream.Position = 0x3C; $offset = $reader.ReadInt32()
        if ($offset -lt 64 -or $offset -gt $stream.Length-6) { throw 'OpenComposite: invalid PE header.' }
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x4550 -or $reader.ReadUInt16() -ne 0x8664) { throw 'OpenComposite: the 64-bit (x64) openvr_api.dll is needed.' }
    } finally { $reader.Dispose(); $stream.Dispose() }
}
# OpenComposite's own DLL (not Valve's, not the mod's switch, not a web page).
function Test-OpenComposite([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try { Assert-Dll64 $Path } catch { return $false }
    return [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($Path)).Contains('OpenComposite')
}
# 0.1.204: a Doorstop winhttp.dll (BepInEx's loader proxy, any version), not another program's.
function Test-Doorstop([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try { Assert-Dll64 $Path } catch { return $false }
    $bytes = [IO.File]::ReadAllBytes($Path)
    foreach ($encoding in @([Text.Encoding]::ASCII,[Text.Encoding]::Unicode)) {
        if ($encoding.GetString($bytes).IndexOf('doorstop',[StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    return $false
}
function Get-ActiveOpenXR {
    if ($env:XR_RUNTIME_JSON) { return $env:XR_RUNTIME_JSON }
    try { return [string](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Khronos\OpenXR\1' -Name ActiveRuntime -ErrorAction Stop).ActiveRuntime } catch { return '' }
}
function Get-OpenComposite([string]$Stage) {
    if ($OpenCompositeDll) { $path = (Get-Item -LiteralPath $OpenCompositeDll).FullName }
    elseif (Test-Path -LiteralPath (Join-Path $PackageRoot 'OpenComposite\openvr_api.dll')) { $path = Join-Path $PackageRoot 'OpenComposite\openvr_api.dll' }
    else {
        # 0.1.180: the one a previous install put in the game is kept (no new download).
        foreach ($have in @('XIII_Data\Plugins\openvr_api_oc.dll','openvr_api_oc.dll')) {
            $existing = Join-Path $GameDir $have
            if (Test-OpenComposite $existing) { Write-Host ('OpenComposite already in the game, kept: ' + $existing); return $existing }
        }
        if ($NoOpenComposite -or -not $DownloadOpenComposite) { return $null }
        try {
            $download = Join-Path $Stage 'opencomposite.download'
            Write-Host 'Downloading OpenComposite (OpenVR on OpenXR, x64) from its official site znix.xyz...'
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $OpenCompositeUrl -OutFile $download -UseBasicParsing
            $head = [byte[]]::new(2); $fs = [IO.File]::OpenRead($download); try { [void]$fs.Read($head,0,2) } finally { $fs.Dispose() }
            if ($head[0] -eq 0x50 -and $head[1] -eq 0x4B) {
                $dir = Join-Path $Stage 'opencomposite'; [void][IO.Directory]::CreateDirectory($dir)
                Extract-Safe $download $dir
                $found = @(Get-ChildItem -LiteralPath $dir -Filter openvr_api.dll -Recurse -File | Where-Object { Test-OpenComposite $_.FullName })
                if (-not $found.Count) { throw 'The OpenComposite download has no 64-bit openvr_api.dll.' }
                $path = $found[0].FullName
            } else { $path = Join-Path $Stage 'openvr_api.dll'; Move-Item -LiteralPath $download -Destination $path }
            if (-not (Test-OpenComposite $path)) { throw 'the download is not OpenComposite.' }
        } catch {
            Write-Warning ('OpenComposite could not be downloaded (' + $_.Exception.Message + '). SteamVR works; for Pimax Play / Oculus / other OpenXR runtimes run this installer again with internet, or put OpenComposite''s openvr_api.dll as OpenComposite\openvr_api.dll beside it.')
            return $null
        }
    }
    Assert-Dll64 $path
    Write-Host ('OpenComposite openvr_api.dll: ' + $path + ' SHA256 ' + (Hash $path))
    return $path
}
function Extract-Safe([string]$Archive, [string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('/', '\')
            if ([IO.Path]::IsPathRooted($name) -or $name.Contains(':')) { throw 'Unsafe archive path.' }
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $name))
            if (-not (Under $target $Destination)) { throw 'Archive entry escapes staging directory.' }
            if (-not $entry.Name) { [void][IO.Directory]::CreateDirectory($target); continue }
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$false)
        }
    } finally { $zip.Dispose() }
}
# Helper files that earlier versions put in the game folder and this one no
# longer ships (the sound extractors and the audio collector). Only the log
# collector stays. Each one found is removed and kept in the restore point.
function Get-RetiredFiles([string]$Root) {
    $names = @('Audio-Catalog.html','Collect-XIII-Audio.cmd','Collect-XIII-Audio.ps1',
        'Extract-XIII-SFX.cmd','Extract-XIII-SFX.cs','Extract-XIII-SFX.ps1','Extract-XIII-SFX-README-RU.txt',
        'Extract-XIII-Weapon-Sounds.cmd','Extract-XIII-Weapon-Sounds.ps1','Extract-XIII-Weapon-Sounds-All.cmd','Extract-XIII-Weapon-Sounds-README-RU.txt')
    return @($names | ForEach-Object { Join-Path $Root $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
}
function Save-Journal {
    $json = $journal | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($journalPath,$json,[Text.UTF8Encoding]::new($false))
}
function Restore-Entry($Entry, [string]$BackupRoot) {
    $destination = [string]$Entry.destination
    if ($Entry.installedHash) {
        if (Test-Path -LiteralPath $destination -PathType Leaf) {
            if ((Hash $destination) -ne $Entry.installedHash) { Write-Warning "Kept modified file: $destination"; return $false }
        } elseif ($Entry.existed) {
            Write-Warning "Kept user deletion: $destination"; return $false
        }
    } elseif (Test-Path -LiteralPath $destination) { Write-Warning "Kept replacement file: $destination"; return $false }
    if ($Entry.existed) {
        $backup = Join-Path $BackupRoot $Entry.backup
        if (-not (Under $backup $BackupRoot) -or (Hash $backup) -ne $Entry.previousHash) { throw 'Backup is missing or changed.' }
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        Copy-Item -LiteralPath $backup -Destination $destination -Force
    } elseif (Test-Path -LiteralPath $destination -PathType Leaf) { Remove-Item -LiteralPath $destination }
    return $true
}
# 0.1.232: the package is checked before anything else: the plugin file must
# be beside the installer. GitHub's "Source code" archive (the repository) has
# the installer but no plugin; a player who took it was told that an earlier
# install from inside BepInEx\plugins had moved the plugin, which was not the
# cause. Empty: the package is complete.
function Get-PackageProblem([string]$Root,[string]$Version) {
    foreach ($name in @('BepInEx-plugins\XIII.XRBootstrap.dll.bin','BepInEx-plugins\XIII.XRBootstrap.dll')) {
        if (Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf) { return '' }
    }
    $download = "Download XIII-VR-$Version.zip from the Assets of the release (https://github.com/CastleTroy28/XIII-VR/releases), unpack the whole archive into its own folder (for example Downloads) and run Install-XIII-VR.cmd from there."
    if ((Test-Path -LiteralPath (Join-Path $Root 'src') -PathType Container) -or (Test-Path -LiteralPath (Join-Path $Root 'buildtools') -PathType Container)) {
        return "This folder is the mod's source code (GitHub's 'Source code' archive), not the mod itself: it has no plugin file. $download Nothing changed."
    }
    if ($Root -match '(?i)[\\/]Temp\d*_[^\\/]*\.zip([\\/]|$)') {
        return 'The installer was started from inside the zip, without unpacking it. Right-click the zip, choose Extract All, and run Install-XIII-VR.cmd from the unpacked folder. Nothing changed.'
    }
    if ($Root -match '(?i)[\\/]BepInEx[\\/]plugins([\\/]|$)') {
        return 'The plugin file is missing from this unpacked folder (an earlier install from inside BepInEx\plugins moved it to its restore point). Unpack the archive again outside the game folder (for example Downloads), and run the installer from there. Nothing changed.'
    }
    return "The plugin file (BepInEx-plugins\XIII.XRBootstrap.dll.bin) is missing from this folder: the archive was not fully unpacked, or an antivirus removed the file. $download If it happens again, look in your antivirus quarantine. Nothing changed."
}
try {
    if (-not $Uninstall) { $problem = Get-PackageProblem $PackageRoot $Version; if ($problem) { throw $problem } }
    if (-not $GameDir) {
        if (Test-Path -LiteralPath (Join-Path $PackageRoot 'XIII.exe')) { $GameDir = $PackageRoot }
        elseif (Test-Path -LiteralPath (Join-Path (Split-Path $PackageRoot -Parent) 'XIII.exe')) { $GameDir = Split-Path $PackageRoot -Parent }
        else {
            Add-Type -AssemblyName System.Windows.Forms
            $pick = [Windows.Forms.OpenFileDialog]::new()
            $pick.Title = 'Select XIII Remake / XIII.exe'; $pick.Filter = 'XIII.exe|XIII.exe'; $pick.CheckFileExists = $true
            if ($pick.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw 'No game selected. Nothing changed.' }
            $GameDir = [IO.Path]::GetDirectoryName($pick.FileName); $pick.Dispose()
        }
    }
    $GameDir = (Get-Item -LiteralPath $GameDir).FullName.TrimEnd('\','/')
    foreach ($item in @('XIII.exe','GameAssembly.dll','UnityPlayer.dll','XIII_Data\il2cpp_data\Metadata\global-metadata.dat')) {
        if (-not (Test-Path -LiteralPath (Join-Path $GameDir $item) -PathType Leaf)) { throw "Missing $item. Select the XIII Remake folder." }
    }
    Assert-Closed $GameDir
    Assert-X64 (Join-Path $GameDir 'XIII.exe')
    $backupParent = Join-Path $GameDir 'XIII-VR-backups'
    if ($Uninstall) {
        if (-not $RestorePoint) {
            $points = @(Get-ChildItem -LiteralPath $backupParent -Filter install.json -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)
            foreach ($point in $points) {
                $candidate = Get-Content -LiteralPath $point.FullName -Raw | ConvertFrom-Json
                if ($candidate.status -eq 'installed') { $RestorePoint = $point.FullName; break }
            }
        }
        if (-not $RestorePoint) { throw 'No installed restore point found.' }
        $RestorePoint = (Get-Item -LiteralPath $RestorePoint).FullName
        if (-not (Under $RestorePoint $backupParent)) { throw 'Restore point must be inside this game/XIII-VR-backups.' }
        $old = Get-Content -LiteralPath $RestorePoint -Raw | ConvertFrom-Json
        if ($old.gameDir -ne $GameDir) { throw 'Restore point belongs to another game folder.' }
        $allowed = @($GameDir,[string]$old.bepInExRoot)
        $entries = @($old.entries); [array]::Reverse($entries); $kept = $false
        foreach ($entry in $entries) {
            if (-not (@($allowed | Where-Object { Under $entry.destination $_ }).Count)) { throw 'Restore destination outside recorded installation roots.' }
            if (-not (Restore-Entry $entry (Split-Path $RestorePoint -Parent))) { $kept = $true }
        }
        $old.status = if ($kept) { 'restored-with-retained-files' } else { 'restored' }
        [IO.File]::WriteAllText($RestorePoint,($old | ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
        Write-Host 'Previous files restored. User-modified files, saves and other mods were kept.'
        exit 0
    }
    $unity = [Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $GameDir 'UnityPlayer.dll'))
    if ($unity.FileMajorPart -ne 2020 -or $unity.FileMinorPart -ne 3 -or $unity.FileBuildPart -ne 25) { throw "Unsupported Unity build $($unity.FileVersion). This package targets 2020.3.25f1." }
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('XIII-VR-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($stage)
    $operations = [System.Collections.Generic.List[object]]::new()
    function Queue-File([string]$Source,[string]$Target) { $operations.Add([pscustomobject]@{source=$Source;destination=$Target}) }
    $doorstop = Join-Path $GameDir 'doorstop_config.ini'
    $fresh = -not (Test-Path -LiteralPath $doorstop)
    if (-not $fresh) {
        $ini = Read-Ini $doorstop
        if (-not $ini.ContainsKey('general/target_assembly') -or $ini['general/enabled'] -notmatch '^(?i:true|1)$') { throw 'Existing Doorstop is disabled or unknown. Nothing changed.' }
        $target = Resolve-IniPath $ini['general/target_assembly'] $GameDir
        if ([IO.Path]::GetFileName($target) -ne 'BepInEx.Unity.IL2CPP.dll' -or -not (Test-Path -LiteralPath $target)) { throw 'Existing loader is not a usable IL2CPP BepInEx installation.' }
        if ((Hash $target) -ne $CoreHash) { throw 'Existing BepInEx differs from tested be.788. Keep it and update manually, or install tested be.788 separately.' }
        $bepRoot = Split-Path (Split-Path $target -Parent) -Parent
        Write-Host "Using existing loader: $bepRoot"
    } else {
        # 0.1.204: a BepInEx folder (its settings, logs and
        # generated files, which an uninstall or Steam leaves behind) and a
        # Doorstop winhttp.dll without doorstop_config.ini are left from an
        # earlier install: the loader goes over them, everything replaced is
        # backed up in the restore point. Only a winhttp.dll of another program
        # stops the install.
        $leftProxy = Join-Path $GameDir 'winhttp.dll'
        $leftFolder = Join-Path $GameDir 'BepInEx'
        if (-not $BepInExZip) {
            $BepInExZip = Join-Path $PackageRoot $BuildName
            if (-not (Test-Path -LiteralPath $BepInExZip)) {
                $BepInExZip = Join-Path $stage $BuildName
                Write-Host 'Downloading official BepInEx be.788 (Windows IL2CPP x64)...'
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $BuildUrl -OutFile $BepInExZip -UseBasicParsing
            }
        }
        $loader = Join-Path $stage 'loader'; [void][IO.Directory]::CreateDirectory($loader)
        Extract-Safe $BepInExZip $loader
        $core = Join-Path $loader 'BepInEx\core\BepInEx.Unity.IL2CPP.dll'
        if (-not (Test-Path -LiteralPath $core) -or (Hash $core) -ne $CoreHash) { throw 'Downloaded BepInEx core does not match tested be.788. Nothing installed.' }
        foreach ($file in @('doorstop_config.ini','winhttp.dll','dotnet\coreclr.dll')) { if (-not (Test-Path -LiteralPath (Join-Path $loader $file))) { throw "BepInEx archive missing $file" } }
        $loaderIni = Read-Ini (Join-Path $loader 'doorstop_config.ini')
        foreach ($key in @('general/target_assembly','il2cpp/coreclr_path','il2cpp/corlib_dir')) {
            if (-not $loaderIni.ContainsKey($key) -or [IO.Path]::IsPathRooted($loaderIni[$key])) { throw 'Loader archive must use portable relative paths.' }
            $resolved = Resolve-IniPath $loaderIni[$key] $loader
            if (-not (Under $resolved $loader) -or -not (Test-Path -LiteralPath $resolved)) { throw 'Invalid relative loader runtime path.' }
        }
        if (Test-Path -LiteralPath $leftProxy) {
            if ((Hash $leftProxy) -ne (Hash (Join-Path $loader 'winhttp.dll')) -and -not (Test-Doorstop $leftProxy)) { throw "winhttp.dll in the game folder belongs to another program, not to BepInEx. Nothing changed. Move it out of the game folder ($leftProxy) and run the installer again." }
            Write-Host 'Found winhttp.dll left from an earlier BepInEx install: replaced (backed up in the restore point).' -ForegroundColor Yellow
        }
        if (Test-Path -LiteralPath $leftFolder) { Write-Host 'Found a BepInEx folder left from an earlier install: the loader goes over it; its settings and other files are kept.' -ForegroundColor Yellow }
        foreach ($file in Get-ChildItem -LiteralPath $loader -File -Recurse) { Queue-File $file.FullName (Join-Path $GameDir $file.FullName.Substring($loader.Length+1)) }
        $bepRoot = Join-Path $GameDir 'BepInEx'
    }
    # Update all active copies of THIS plugin, not unrelated plugins.
    $plugins = Join-Path $bepRoot 'plugins'
    $copies = @(Get-ChildItem -LiteralPath $plugins -Filter XIII.XRBootstrap.dll -Recurse -File -ErrorAction SilentlyContinue)
    # 0.1.96: extra copies (for example an archive unpacked into plugins) no
    # longer stop the update. The copy in plugins itself is updated; the others
    # are removed with a backup in the restore point.
    $pluginTarget = [IO.Path]::GetFullPath((Join-Path $plugins 'XIII.XRBootstrap.dll'))
    foreach ($extra in @($copies | Where-Object { -not [string]::Equals([IO.Path]::GetFullPath($_.FullName),$pluginTarget,[StringComparison]::OrdinalIgnoreCase) })) {
        Write-Host "Removing extra plugin copy (backed up): $($extra.FullName)" -ForegroundColor Yellow
        Queue-File '' $extra.FullName
    }
    # 0.1.96: an archive unpacked INSIDE plugins contains the new DLL itself.
    # Stage that source first; the unpacked copy is then removed (backed up)
    # like any other extra copy, so BepInEx never loads two copies.
    # 0.1.176: the package keeps the plugin as XIII.XRBootstrap.dll.bin,
    # which BepInEx never loads and no install moves away.
    $pluginSource = [IO.Path]::GetFullPath((Join-Path $PackageRoot 'BepInEx-plugins\XIII.XRBootstrap.dll.bin'))
    if (-not (Test-Path -LiteralPath $pluginSource)) { $pluginSource = [IO.Path]::GetFullPath((Join-Path $PackageRoot 'BepInEx-plugins\XIII.XRBootstrap.dll')) }
    if (-not (Test-Path -LiteralPath $pluginSource)) { throw (Get-PackageProblem $PackageRoot $Version) }
    if (Under $pluginSource $plugins) {
        Write-Host 'Note: this archive was unpacked inside BepInEx\plugins. Next time unpack it to another folder (for example Downloads).' -ForegroundColor Yellow
        $stagedPlugin = Join-Path $stage 'XIII.XRBootstrap.dll'
        Copy-Item -LiteralPath $pluginSource -Destination $stagedPlugin
        $pluginSource = $stagedPlugin
    }
    Queue-File $pluginSource $pluginTarget
    $openComposite = Get-OpenComposite $stage
    $ocTarget = Join-Path $GameDir 'XIII_Data\Plugins\openvr_api_oc.dll'
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $PackageRoot 'GameFolder') -File -Recurse) {
        $relative = $file.FullName.Substring((Join-Path $PackageRoot 'GameFolder').Length+1)
        # 0.1.177: the plugin needs
        # VRHeadsetView from openvr_api.dll, which OpenComposite lacks. The mod's
        # small openvr_api.dll (OpenXR\openvr_api.dll, buildtools\openvr-shim)
        # answers it and hands everything else to OpenComposite, installed as
        # openvr_api_oc.dll (beside it and beside XIII.exe, where Windows finds it).
        # 0.1.178 (OpenComposite stopped the game: "unknown/unsupported interface
        # IVRSystem_023"): the plugin asks for OpenVR versions newer than
        # OpenComposite has (IVRSystem_023, IVRCompositor_029, IVROverlay_028);
        # the small openvr_api.dll now hands it OpenComposite's previous ones
        # (022/028/027: the newer versions only added methods).
        # 0.1.180: Valve's DLL becomes openvr_api_valve.dll; the runtime switch is openvr_api.dll.
        if ([string]::Equals($relative,'XIII_Data\Plugins\openvr_api.dll',[StringComparison]::OrdinalIgnoreCase)) {
            $shim = Join-Path $PackageRoot 'OpenXR\openvr_api.dll'
            if (-not (Test-Path -LiteralPath $shim)) { throw 'OpenXR\openvr_api.dll is missing from this package. Unpack the archive again.' }
            Queue-File $file.FullName (Join-Path $GameDir 'XIII_Data\Plugins\openvr_api_valve.dll')
            Queue-File $shim (Join-Path $GameDir $relative)
            continue
        }
        Queue-File $file.FullName (Join-Path $GameDir $relative)
    }
    if ($openComposite -and -not [string]::Equals([IO.Path]::GetFullPath($openComposite),[IO.Path]::GetFullPath($ocTarget),[StringComparison]::OrdinalIgnoreCase)) {
        # A copy taken from beside XIII.exe (0.1.177-0.1.179 put one there) is staged first: that one goes below.
        $ocStaged = Join-Path $stage 'openvr_api_oc.dll'; Copy-Item -LiteralPath $openComposite -Destination $ocStaged
        Queue-File $ocStaged $ocTarget
    }
    foreach ($retired in (Get-RetiredFiles $GameDir)) { Write-Host "Removing a helper this version no longer ships (backed up): $(Split-Path $retired -Leaf)"; Queue-File '' $retired }
    # The switch loads OpenComposite by its full path: the copies beside XIII.exe (0.1.177-0.1.179) go (backed up).
    foreach ($old in @('openvr_api_oc.dll','opencomposite.ini')) { if (Test-Path -LiteralPath (Join-Path $GameDir $old)) { Queue-File '' (Join-Path $GameDir $old) } }
    if ($openComposite) {
        # The mod draws its own hands; OpenComposite's own hands stay off.
        $ocIni = Join-Path $stage 'opencomposite.ini'
        [IO.File]::WriteAllText($ocIni,"; XIII VR: the mod draws its own hands`r`nrenderCustomHands=false`r`nhaptics=true`r`n",[Text.UTF8Encoding]::new($false))
        Queue-File $ocIni (Join-Path $GameDir 'XIII_Data\Plugins\opencomposite.ini')
    }
    $config = Join-Path $bepRoot 'config\xiii.vr.xrbootstrap.cfg'
    if (-not (Test-Path -LiteralPath $config)) {
        $newConfig = Join-Path $stage 'fresh.cfg'
        [IO.File]::WriteAllText($newConfig,"[VR]`r`nAutoStartVR = true`r`nRenderScale = 1.0`r`nHandWeaponCollisions = true`r`n",[Text.UTF8Encoding]::new($false))
        Queue-File $newConfig $config
    }
    # Retire our old probe only; the probe also intercepts F8. Backed up for rollback.
    foreach ($probe in @(Get-ChildItem -LiteralPath $plugins -Filter XIII.Diagnostics.dll -Recurse -File -ErrorAction SilentlyContinue)) { Queue-File '' $probe.FullName }
    $pointRoot = Join-Path $backupParent ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($pointRoot)
    $entries = [System.Collections.Generic.List[object]]::new()
    # Stage and hash EVERYTHING before changing any game/loader files.
    foreach ($op in $operations) {
        $dest = [IO.Path]::GetFullPath($op.destination)
        if (-not (Under $dest $GameDir) -and -not (Under $dest $bepRoot)) { throw 'Installation destination outside selected roots.' }
        $existed = Test-Path -LiteralPath $dest -PathType Leaf
        $backup = $entries.Count.ToString('D5') + '.bak'; $previousHash = ''
        if ($existed) { $previousHash = Hash $dest; Copy-Item -LiteralPath $dest -Destination (Join-Path $pointRoot $backup) }
        $newHash = if ($op.source) { Hash $op.source } else { '' }
        $entries.Add([pscustomobject]@{destination=$dest;source=$op.source;existed=$existed;backup=$backup;previousHash=$previousHash;installedHash=$newHash})
    }
    $journalPath = Join-Path $pointRoot 'install.json'
    $journal = [pscustomobject]@{version=$Version;status='installing';gameDir=$GameDir;bepInExRoot=$bepRoot;entries=$entries.ToArray()}
    Save-Journal
    foreach ($entry in $entries) {
        # Check for changes since staging; never overwrite a concurrently modified file.
        if ($entry.existed) { if (-not (Test-Path -LiteralPath $entry.destination) -or (Hash $entry.destination) -ne $entry.previousHash) { throw 'A destination changed during install.' } }
        elseif (Test-Path -LiteralPath $entry.destination) { throw 'A destination appeared during install.' }
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($entry.destination))
        if ($entry.source) {
            $tmp = $entry.destination + '.xiii-vr-' + [Guid]::NewGuid().ToString('N') + '.tmp'
            $swapBackup = $tmp + '.previous'
            try {
                Copy-Item -LiteralPath $entry.source -Destination $tmp
                if ((Hash $tmp) -ne $entry.installedHash) { throw 'Copied file hash mismatch.' }
                if ($entry.existed) { Replace-StagedFile $tmp $entry.destination $swapBackup } else { [IO.File]::Move($tmp,$entry.destination) }
                $applied.Add($entry) # Journal ownership before optional cleanup.
            } finally {
                foreach ($temporary in @($tmp,$swapBackup)) {
                    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -ErrorAction Continue }
                }
            }
        } else { Remove-Item -LiteralPath $entry.destination; $applied.Add($entry) }
    }
    $journal.status = 'installed'; Save-Journal
    Write-Host "Installed XIII VR $Version. Plugin: $pluginTarget"
    Write-Host "Restore point: $journalPath"
    $active = Get-ActiveOpenXR
    Write-Host 'VR runtime: the mod''s own OpenXR goes into the default OpenXR runtime of Windows (SteamVR, Pimax Play, Oculus/Meta, Virtual Desktop, WMR...), no OpenComposite, nothing downloaded.' -ForegroundColor Green
    Write-Host ('Default OpenXR runtime now: ' + $(if ($active) { $active } else { 'none set - make your headset''s app the OpenXR default' })) -ForegroundColor Green
    $fallback = if ($openComposite) { 'SteamVR, or OpenComposite for another default runtime' } else { 'SteamVR' }
    Write-Host ('If the own OpenXR cannot start, the game goes the OpenVR way (' + $fallback + '). [VR] Runtime in BepInEx\config\xiii.vr.xrbootstrap.cfg: Auto / OpenXR / OpenVR / SteamVR / OpenComposite.')
    Write-Host 'Run XIII.exe. Existing config is preserved; F9 starts VR if auto-start is off.'
} catch {
    Write-Host ('Installation stopped: ' + $_.Exception.Message) -ForegroundColor Red
    if ($journal) {
        $rollbackOk = $true
        for ($i=$applied.Count-1;$i -ge 0;$i--) { try { if (-not (Restore-Entry $applied[$i] (Split-Path $journalPath -Parent))) { $rollbackOk=$false } } catch { $rollbackOk=$false; Write-Warning $_.Exception.Message } }
        $journal.status = if ($rollbackOk) { 'rolled-back' } else { 'rollback-incomplete' }; Save-Journal
        Write-Host "Rollback recorded at $journalPath"
    }
    exit 1
} finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
