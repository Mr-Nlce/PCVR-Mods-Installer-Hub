Set-StrictMode -Version 2.0

function Get-ShipwrightInstalledHdPack {
    param([string]$ModsDir)
    if (-not (Test-Path -LiteralPath $ModsDir -PathType Container)) { return $null }
    Get-ChildItem -LiteralPath $ModsDir -File -Filter '*.o2r' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '(?i)^OoT_Reloaded.*_4K\.o2r$' -and $_.Length -gt 0 } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-ShipwrightInstalledDjipiBackgrounds {
    param([string]$ModsDir)
    if (-not (Test-Path -LiteralPath $ModsDir -PathType Container)) { return @() }
    $files = @(Get-ChildItem -LiteralPath $ModsDir -File -ErrorAction SilentlyContinue)
    $scene = @($files | Where-Object { $_.Name -match "(?i)^Djipi's 3DE\s*-\s*26\s+Background\s+3DS\.(otr|o2r)$" -and $_.Length -gt 0 } | Select-Object -First 1)
    $textures = @($files | Where-Object { $_.Name -match "(?i)^Djipi's 3DE\s*-\s*27\s+Background\s+Textures\.(otr|o2r)$" -and $_.Length -gt 0 } | Select-Object -First 1)
    if ($scene.Count -ne 1 -or $textures.Count -ne 1) { return @() }
    return @($scene[0], $textures[0])
}

function Read-ShipwrightOptionalPackChoice {
    param([string]$Name, [object[]]$InstalledFiles)
    $present = @($InstalledFiles | Where-Object { $_ })
    if ($present.Count -gt 0) {
        Write-Host "  $Name is already installed:" -ForegroundColor Green
        foreach ($file in $present) { Write-Host "    $($file.Name)" -ForegroundColor Gray }
        while ($true) {
            $answer = (Read-Host "  Download and install $Name again? [y/N]").Trim()
            if (-not $answer -or $answer -match '^(?i:n|no)$') { return $false }
            if ($answer -match '^(?i:y|yes)$') { return $true }
            Write-Host '  Please type Y or N.' -ForegroundColor Yellow
        }
    }
    while ($true) {
        $answer = (Read-Host "  Install $Name now? (Y/N)").Trim()
        if ($answer -match '^(?i:y|yes)$') { return $true }
        if ($answer -match '^(?i:n|no)$') { return $false }
        Write-Host '  Please type Y or N.' -ForegroundColor Yellow
    }
}

function Get-ShipwrightDjipiPayload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $all = @()
    if (Test-Path -LiteralPath $Root -PathType Container) {
        $all = @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @('.otr', '.o2r') })
    }

    # The former final pack used .o2r. The current GameBanana file 1810733
    # uses .otr. Both are valid Ship of Harkinian packages; the functional
    # identity is the numbered payload, never the historical ZIP name.
    $djipiFiles = @($all | Where-Object {
        $_.FullName -notmatch '(?i)(Skilar|Art\s*Plus)' -and
        $_.Name -match "(?i)^Djipi's 3DE\s*-\s*"
    })
    $background3d = @($djipiFiles | Where-Object {
        $_.BaseName -match "(?i)^Djipi's 3DE\s*-\s*26\s+Background\s+3DS$"
    })
    $backgroundTextures = @($djipiFiles | Where-Object {
        $_.BaseName -match "(?i)^Djipi's 3DE\s*-\s*27\s+Background\s+Textures$"
    })
    $background = @($background3d | Select-Object -First 1) +
                  @($backgroundTextures | Select-Object -First 1)

    [pscustomobject]@{
        IsComplete       = ($background3d.Count -gt 0 -and $backgroundTextures.Count -gt 0)
        AllPayloadFiles  = $djipiFiles
        BackgroundFiles  = @($background)
        SkilarFileCount  = $all.Count - $djipiFiles.Count
        Extensions       = @($djipiFiles | ForEach-Object Extension | Sort-Object -Unique)
    }
}
