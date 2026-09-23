function global:Invoke-DeusExHRVRElevatedOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateSet('Install','Restore','Uninstall')][string]$Action,
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [string]$SourceRoot = '',
        [string]$Version = '',
        [string]$SnapshotRoot = ''
    )

    $worker = Join-Path $PSScriptRoot 'DeusExHRVRElevatedWorker.ps1'
    if (-not (Test-Path -LiteralPath $worker -PathType Leaf)) { throw 'The Deus Ex HR VR elevation worker is missing.' }
    $requestRoot = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_deusexhrvr_admin_' + [Guid]::NewGuid().ToString('N'))
    $requestPath = Join-Path $requestRoot 'request.json'
    $resultPath = Join-Path $requestRoot 'result.json'
    try {
        [void][IO.Directory]::CreateDirectory($requestRoot)
        $request = [ordered]@{
            Action = $Action
            GameRoot = [IO.Path]::GetFullPath($GameRoot)
            SourceRoot = $(if ($SourceRoot) { [IO.Path]::GetFullPath($SourceRoot) } else { '' })
            Version = $Version
            SnapshotRoot = $(if ($SnapshotRoot) { [IO.Path]::GetFullPath($SnapshotRoot) } else { '' })
            InstalledPathReceipt = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '.installed_path'))
            ResultPath = $resultPath
        }
        [IO.File]::WriteAllText($requestPath,($request | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false))
        $arguments = @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $worker + '"'),
            '-RequestFile',('"' + $requestPath + '"')
        )
        $process = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ErrorAction Stop
        $result = $null
        if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
            try { $result = Get-Content -LiteralPath $resultPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop } catch {}
        }
        if ($result -and [string]$result.FailureKind -eq 'MissingAfterCopy') { return $result }
        if ($process.ExitCode -ne 0 -or -not $result -or -not [bool]$result.Success) {
            $reason = if ($result -and $result.Error) { [string]$result.Error } else { "elevated helper exit code $($process.ExitCode)" }
            throw "The administrator-rights step did not complete: $reason"
        }
        return $result
    } finally {
        if (Test-Path -LiteralPath $requestRoot -PathType Container) { Remove-Item -LiteralPath $requestRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
