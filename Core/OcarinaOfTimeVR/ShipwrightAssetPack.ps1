Set-StrictMode -Version 2.0

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
