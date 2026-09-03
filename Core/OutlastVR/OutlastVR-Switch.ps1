param([ValidateSet('Halcyon','Hammerthis')][string]$Mod, [switch]$Launch)

# Installed beside the launchers; remains usable after replacing the Hub.
function Get-OutlastModFiles {
    param([ValidateSet('Halcyon','Hammerthis')][string]$Name)
    if ($Name -eq 'Halcyon') { return @('d3d9.dll','openxr_loader.dll','outlastvr.ini','Outlast-VR.bat') }
    return @('d3d9.dll','openxr_loader.dll','openxr_loader_real.dll','outlastvr.ini','assets\miles\body_albedo.tga')
}

function Get-OutlastLayout {
    param([string]$GameRoot)
    $root = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
    if (-not (Test-Path -LiteralPath "$root\Binaries\Win64\OLGame.exe" -PathType Leaf)) { throw 'Select the Outlast folder containing Binaries\Win64\OLGame.exe.' }
    foreach ($relative in @('','Binaries','Binaries\Win64','_vrmods','_vrmods\halcyon','_vrmods\hammerthis','_vrmods\VRLaunch')) {
        $path = if ($relative) { Join-Path $root $relative } else { $root }
        $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Linked mod/game directories are not supported: $path" }
    }
    return @{ Root=$root; Bin="$root\Binaries\Win64"; Stores="$root\_vrmods"; State="$root\_vrmods\.active_mod.json" }
}

function Copy-OutlastFile {
    param([string]$Source, [string]$Destination)
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Destination))
    Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
    if ((Get-FileHash -LiteralPath $Source).Hash -ne (Get-FileHash -LiteralPath $Destination).Hash) { throw "Copy verification failed: $Destination" }
}

function Test-OutlastStore {
    param([string]$GameRoot, [string]$Name)
    $layout = Get-OutlastLayout $GameRoot
    foreach ($file in Get-OutlastModFiles $Name) {
        if (-not (Test-Path -LiteralPath (Join-Path "$($layout.Stores)\$Name" $file) -PathType Leaf)) { return $false }
    }
    return $true
}

function Get-OutlastActiveMod {
    param([string]$GameRoot)
    $layout = Get-OutlastLayout $GameRoot
    $proxy = "$($layout.Bin)\d3d9.dll"
    if (-not (Test-Path -LiteralPath $proxy)) { $proxy += '.off' }
    if (-not (Test-Path -LiteralPath $proxy -PathType Leaf)) { return $null }
    $hash = (Get-FileHash -LiteralPath $proxy).Hash
    if (Test-Path -LiteralPath $layout.State) {
        try {
            $state = Get-Content -LiteralPath $layout.State -Raw | ConvertFrom-Json
            if ($state.Name -in @('Halcyon','Hammerthis') -and $state.Hash -eq $hash) { return $state.Name }
        } catch {}
    }
    $matching = @(foreach ($name in @('Halcyon','Hammerthis')) {
        $stored = "$($layout.Stores)\$name\d3d9.dll"
        if ((Test-Path -LiteralPath $stored -PathType Leaf) -and (Get-FileHash -LiteralPath $stored).Hash -eq $hash) { $name }
    })
    if ($matching.Count -eq 1) { return $matching[0] }
    if ($matching.Count -gt 1) { throw 'Both mod stores contain the same proxy. Reinstall the correct packages before switching.' }
    if ((Test-Path -LiteralPath "$($layout.Bin)\Outlast-VR.bat") -and -not (Test-Path -LiteralPath "$($layout.Bin)\openxr_loader_real.dll")) { return 'Halcyon' }
    throw 'The active d3d9.dll cannot be identified. Back up the existing mod and reinstall before switching.'
}

function Save-OutlastActiveConfig {
    param([string]$GameRoot)
    $layout = Get-OutlastLayout $GameRoot
    $name = Get-OutlastActiveMod $GameRoot
    if (-not $name) { return }
    $ini = "$($layout.Bin)\outlastvr.ini"
    if (Test-Path -LiteralPath $ini -PathType Leaf) { Copy-OutlastFile $ini "$($layout.Stores)\$name\outlastvr.ini" }
    $proxy = "$($layout.Bin)\d3d9.dll"
    if (-not (Test-Path -LiteralPath $proxy)) { $proxy += '.off' }
    [void][IO.Directory]::CreateDirectory($layout.Stores)
    # Store updates must not change the identity of the still-active files.
    @{ Name=$name; Hash=(Get-FileHash -LiteralPath $proxy).Hash } | ConvertTo-Json | Set-Content -LiteralPath $layout.State -Encoding UTF8 -ErrorAction Stop
}

function Initialize-OutlastStores {
    param([string]$GameRoot)
    $layout = Get-OutlastLayout $GameRoot
    if (Get-Process -Name OLGame -ErrorAction SilentlyContinue) { throw 'Close Outlast before installing or switching mods.' }
    $active = Get-OutlastActiveMod $GameRoot
    if ($active -eq 'Halcyon' -and -not (Test-OutlastStore $GameRoot 'Halcyon')) {
        foreach ($file in Get-OutlastModFiles 'Halcyon') {
            $source = Join-Path $layout.Bin $file
            if ($file -eq 'd3d9.dll' -and -not (Test-Path -LiteralPath $source)) { $source += '.off' }
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Cannot preserve the old Halcyon install; missing $file." }
            Copy-OutlastFile $source (Join-Path "$($layout.Stores)\Halcyon" $file)
        }
    }
    Save-OutlastActiveConfig $GameRoot
}

function Invoke-OutlastFileTransaction {
    param([string]$GameRoot, [string[]]$Targets, [scriptblock]$Action)
    $layout = Get-OutlastLayout $GameRoot
    $backup = Join-Path $layout.Stores ('.rollback-' + [Guid]::NewGuid().ToString('N'))
    $saved = @{}
    $keepBackup = $false
    try {
        foreach ($target in $Targets) {
            $full = [IO.Path]::GetFullPath($target)
            if (-not $full.StartsWith($layout.Root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Target outside Outlast folder.' }
            $check = $full
            while ($check.Length -gt $layout.Root.Length) {
                $item = Get-Item -LiteralPath $check -Force -ErrorAction SilentlyContinue
                if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Linked target is not supported: $check" }
                $check = Split-Path -Parent $check
            }
            $saved[$full] = $null
            if (Test-Path -LiteralPath $full -PathType Leaf) {
                $copy = Join-Path $backup ([string]$saved.Count)
                Copy-OutlastFile $full $copy
                $saved[$full] = $copy
            }
        }
        try { & $Action } catch {
            $failure = $_
            try {
                foreach ($target in $saved.Keys) {
                    if ($saved[$target]) { Copy-OutlastFile $saved[$target] $target }
                    elseif (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
                }
            } catch { $keepBackup = $true; Write-Warning "Rollback incomplete. Keep the recovery files in $backup. $_" }
            throw $failure
        }
    } finally {
        if (-not $keepBackup -and (Test-Path -LiteralPath $backup)) {
            $resolved = (Resolve-Path -LiteralPath $backup).Path
            if ($resolved.StartsWith($layout.Stores + '\.rollback-', [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction Stop }
        }
    }
}

function Install-OutlastStore {
    param([string]$GameRoot, [string]$Name, [string]$Source)
    $layout = Get-OutlastLayout $GameRoot
    $files = @(Get-OutlastModFiles $Name)
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath (Join-Path $Source $file) -PathType Leaf)) { throw "Incomplete $Name package: $file is missing." }
    }
    $store = Join-Path $layout.Stores $Name
    $targets = @($files | ForEach-Object { Join-Path $store $_ })
    Invoke-OutlastFileTransaction -GameRoot $GameRoot -Targets $targets -Action {
        foreach ($file in $files) {
            $destination = Join-Path $store $file
            if ($file -eq 'outlastvr.ini' -and (Test-Path -LiteralPath $destination)) { continue }
            Copy-OutlastFile (Join-Path $Source $file) $destination
        }
    }
}

function Switch-OutlastMod {
    param([string]$GameRoot, [ValidateSet('Halcyon','Hammerthis')][string]$Name)
    $layout = Get-OutlastLayout $GameRoot
    if (Get-Process -Name OLGame -ErrorAction SilentlyContinue) { throw 'Close Outlast before switching mods.' }
    if (-not (Test-OutlastStore $GameRoot $Name)) { throw "$Name is incomplete. Run the installer again; no files were switched." }
    [void][IO.Directory]::CreateDirectory($layout.Stores)
    $lock = [IO.File]::Open((Join-Path $layout.Stores '.switch.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        Save-OutlastActiveConfig $GameRoot
        $files = @(Get-OutlastModFiles $Name)
        $all = @((Get-OutlastModFiles 'Halcyon') + (Get-OutlastModFiles 'Hammerthis') | Sort-Object -Unique)
        $targets = @($all | ForEach-Object { Join-Path $layout.Bin $_ }) + @($layout.State, "$($layout.Bin)\d3d9.dll.off")
        Invoke-OutlastFileTransaction -GameRoot $GameRoot -Targets $targets -Action {
            foreach ($file in $files) { Copy-OutlastFile (Join-Path "$($layout.Stores)\$Name" $file) (Join-Path $layout.Bin $file) }
            foreach ($file in $all) {
                $path = Join-Path $layout.Bin $file
                if ($file -notin $files -and (Test-Path -LiteralPath $path -PathType Leaf)) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
            }
            $oldProxy = "$($layout.Bin)\d3d9.dll.off"
            if (Test-Path -LiteralPath $oldProxy -PathType Leaf) { Remove-Item -LiteralPath $oldProxy -Force -ErrorAction Stop }
            @{ Name=$Name; Hash=(Get-FileHash -LiteralPath "$($layout.Bin)\d3d9.dll").Hash } | ConvertTo-Json | Set-Content -LiteralPath $layout.State -Encoding UTF8 -ErrorAction Stop
        }
    } finally { $lock.Dispose() }
}

function Write-OutlastLaunchers {
    param([string]$GameRoot, [string]$RuntimePath)
    $layout = Get-OutlastLayout $GameRoot
    $launchDir = Join-Path $layout.Stores 'VRLaunch'
    [void][IO.Directory]::CreateDirectory($launchDir)
    Copy-OutlastFile $RuntimePath (Join-Path $launchDir 'OutlastVR-Switch.ps1')
    foreach ($name in @('Halcyon','Hammerthis')) {
        $path = Join-Path $launchDir "Outlast VR ($name).bat"
        if (Test-OutlastStore $GameRoot $name) {
            $lines = @('@echo off','setlocal DisableDelayedExpansion', ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OutlastVR-Switch.ps1" -Mod ' + $name + ' -Launch'), 'if errorlevel 1 (', '  pause', '  exit /b 1', ')')
            Set-Content -LiteralPath $path -Value $lines -Encoding ASCII -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
    }
}

if ($Mod) {
    try {
        $gameRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        Switch-OutlastMod -GameRoot $gameRoot -Name $Mod
        if ($Launch) {
            $steamApps = Split-Path (Split-Path $gameRoot -Parent) -Parent
            if (Test-Path -LiteralPath (Join-Path $steamApps 'appmanifest_238320.acf')) {
                Start-Process -FilePath 'steam://rungameid/238320' -ErrorAction Stop
            } else {
                $bin = Join-Path $gameRoot 'Binaries\Win64'
                Start-Process -FilePath (Join-Path $bin 'OLGame.exe') -WorkingDirectory $bin -ErrorAction Stop
            }
        }
    } catch { Write-Host "Outlast was not started: $_" -ForegroundColor Red; exit 1 }
}
