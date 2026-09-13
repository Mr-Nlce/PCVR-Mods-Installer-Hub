# ============================================================
# Devil May Cry 5 - REFramework VR
#
# REFramework-nightly stopped publishing per-game DMC5.zip files.
# Its current release is the monolithic REFramework.zip plus VR.zip,
# which the maintained shared installer already resolves, verifies,
# caches and extracts. Keep this small game-specific entry point so the
# DMC5 tile cannot drift onto a retired nightly asset again.
# ============================================================

. "$PSScriptRoot\..\Modules\InstallerSafety.ps1"

$shared = Join-Path $PSScriptRoot "..\REFrameworkVR\REFrameworkVR-core.ps1"
if (-not (Test-Path -LiteralPath $shared)) {
    $recovery = Invoke-InstallerFallback -Action "find the shared REFramework installer" `
        -Instructions "The Hub file '$shared' is missing. Re-extract the complete PCVR Mods Hub into this folder, then choose Retry." `
        -RetryCheck { Test-Path -LiteralPath $shared -PathType Leaf } `
        -SourceFolder (Split-Path -Parent $shared) -AllowSkip $false
    if ($recovery -eq 'quit') { exit 1 }
}

& $shared -GameTitle "Devil May Cry 5 VR" -GameFolder "Devil May Cry 5" -GameExe "DevilMayCry5.exe"
