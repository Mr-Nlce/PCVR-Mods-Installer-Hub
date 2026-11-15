function New-PCVRPerformanceLog {
    param([string]$LocalRoot, [ValidateSet('classic','update')][string]$Process)
    try {
        if (-not $LocalRoot) { return }
        $folder = Join-Path $LocalRoot 'PCVR Mods Installer Hub\Logs\Performance'
        [void][IO.Directory]::CreateDirectory($folder)
        $id = '{0}-{1}' -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(), $PID
        $path = Join-Path $folder "$Process-$id.tsv"
        $encoding = [Text.UTF8Encoding]::new($false)
        [IO.File]::WriteAllText($path, "utc_unix_ms`tprocess`ttrace_id`tarea`tevent`telapsed_ms`n", $encoding)
        return @{ Id=$id; Path=$path; Process=$Process; Encoding=$encoding }
    } catch { }
}

function Write-PCVRPerformance {
    param($Log, [string]$Area, [string]$Event, [double]$ElapsedMs, [string]$TraceId)
    if (-not $Log) { return }
    try {
        if (-not $TraceId) { $TraceId = $Log.Id }
        $elapsed = $ElapsedMs.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture)
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        [IO.File]::AppendAllText($Log.Path, "$now`t$($Log.Process)`t$TraceId`t$Area`t$Event`t$elapsed`n", $Log.Encoding)
    } catch { }
}

function Get-PCVRPerformanceMs {
    param([long]$Since)
    return ([Diagnostics.Stopwatch]::GetTimestamp() - $Since) * 1000.0 / [Diagnostics.Stopwatch]::Frequency
}
