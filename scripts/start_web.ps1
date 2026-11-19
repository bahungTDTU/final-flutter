param(
    [ValidateRange(1024,65535)][int]$Port = 7357,
    [string]$ApiUrl,
    [switch]$Rebuild
)
. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    $requiredAssets = @('index.html', 'main.dart.js', 'offline_worker.js')
    $missing = $requiredAssets | Where-Object {
        !(Test-Path -LiteralPath (Join-Path 'build\web' $_) -PathType Leaf)
    }
    # API_URL is compiled into the bundle. Honor an explicit URL even if a build exists.
    if ($Rebuild -or $ApiUrl -or $missing) {
        & "$PSScriptRoot\build.ps1" -Target web -ApiUrl $ApiUrl
    }
    Write-Host "Open http://127.0.0.1:$Port (local release; rebuild after source edits)."
    & '.\.venv\Scripts\python.exe' -m http.server $Port --bind 127.0.0.1 --directory build\web
    Assert-Exit 'Web'
} finally { Pop-Location }
