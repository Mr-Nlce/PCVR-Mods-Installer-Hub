# State read from the publisher, tied to the selected game folder.
function global:Get-PCVRTrilexReceipt {
    param([string]$Root,[string]$Game,[string[]]$Runtime)
    if (-not $Root -or -not $Game) { return }
    try {
        $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')
        $key = [Security.Cryptography.SHA256]::Create()
        try { $id = [BitConverter]::ToString($key.ComputeHash([Text.Encoding]::UTF8.GetBytes($rootPath.ToUpperInvariant()))).Replace('-','') }
        finally { $key.Dispose() }
        $homePath = Join-Path $env:LOCALAPPDATA 'Trilex\ModInstaller'
        $folder = Join-Path $homePath "installations\$id"
        $receiptPath = Join-Path $folder 'installed.json'
        if (-not [IO.File]::Exists($receiptPath) -or ([IO.FileInfo]::new($receiptPath)).Length -gt 4MB) { return }
        $journal = Join-Path $folder 'journal.json'
        if ([IO.File]::Exists($journal) -and (Get-Content -LiteralPath $journal -Raw | ConvertFrom-Json).phase -ne 'committed') { return }
        $record = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
        if ($record.schema -cne 'trilex-install-v1' -or $record.gameId -cne $Game -or
            $record.root.TrimEnd([char[]]'\/') -ine $rootPath -or -not $record.transactionId -or
            $record.version -notmatch '^v?\d[\w.-]{0,79}$') { return }
        foreach ($relative in $Runtime) {
            $match = @($record.files | Where-Object { $_.path.Replace('\','/') -ieq $relative.Replace('\','/') })
            $file = Join-Path $rootPath $relative
            if ($match.Count -ne 1 -or -not [IO.File]::Exists($file) -or
                (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ine $match[0].installedHash) { return }
        }
        return $record
    } catch { return }
}

function global:Get-PCVRGothic3Version {
    param([string]$Root)
    if (-not $Root) { return }
    $launcher = Join-Path $Root 'Gothic3VRLauncher.exe'
    if (-not [IO.File]::Exists($launcher)) { return }
    $known = (Get-Item -LiteralPath $launcher).VersionInfo.ProductVersion
    if ($known -match '^v?(\d+\.\d+\.\d+)(?:\.0)?\s*$') { return ('v' + $Matches[1]) }
    $expectedRoot = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')
    foreach ($hive in 'HKCU:\SOFTWARE','HKLM:\SOFTWARE','HKLM:\SOFTWARE\WOW6432Node') {
        $entries = Get-ItemProperty "$hive\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
        foreach ($item in $entries) {
            if ($item.DisplayName -eq 'Gothic 3 VR' -and $item.InstallLocation -and
                $item.InstallLocation.TrimEnd([char[]]'\/') -ieq $expectedRoot -and
                $item.DisplayVersion -match '^v?(\d+\.\d+\.\d+)(?:\.0)?\s*$') { return ('v' + $Matches[1]) }
        }
    }
}

function global:Get-PCVRTrilexSignedVersion {
    param([string]$Envelope,[string]$Game)
    try {
        if ($Envelope.Length -gt 4MB) { return }
        $signed = ConvertFrom-Json -InputObject $Envelope
        if ($signed.algorithm -cne 'ECDSA-P256-SHA256-P1363') { return }
        $public = [Convert]::FromBase64String('gU03L5z03wUJMBEyPz9Hnh1W+wvE+kKqXyyyqgyaAIst1S+MS72Q5ANfENO/6xIMB2Hd1m3woAKqD1MucmcTzg==')
        $blob = [byte[]](@(69,67,83,49,32,0,0,0) + $public)
        $key = [Security.Cryptography.CngKey]::Import($blob,[Security.Cryptography.CngKeyBlobFormat]::EccPublicBlob)
        try {
            $ecdsa = [Security.Cryptography.ECDsaCng]::new($key)
            try {
                $payload = [Convert]::FromBase64String($signed.payload)
                if (-not $ecdsa.VerifyData($payload,[Convert]::FromBase64String($signed.signature),[Security.Cryptography.HashAlgorithmName]::SHA256)) { return }
            } finally { $ecdsa.Dispose() }
        } finally { $key.Dispose() }
        $catalog = ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString($payload))
        if ($catalog.schemaVersion -ne 1 -or [DateTimeOffset]$catalog.expiresUtc -le [DateTimeOffset]::UtcNow) { return }
        $matches = @($catalog.games | Where-Object { $_.id -ceq $Game -and $_.state -ceq 'stable' })
        if ($matches.Count -ne 1) { return }
        $core = @($matches[0].modules | Where-Object { $_.id -ceq 'vr-core' -and $_.required -and $_.state -ceq 'stable' })
        if ($core.Count -eq 1 -and $core[0].version -match '^v?\d[\w.-]{0,79}$') { return [string]$core[0].version }
    } catch { return }
}
