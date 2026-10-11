param([ValidateRange(1024,65535)][int]$Port = 7357)
. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    if (!(Test-Path 'build\web\offline_worker.js')) {
        & powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Target web
        Assert-Exit 'Build Web'
    }
    Write-Host "Open http://127.0.0.1:$Port (local release; rebuild after source edits)."
    & '.\.venv\Scripts\python.exe' -m http.server $Port --bind 127.0.0.1 --directory build\web
    Assert-Exit 'Web'
} finally { Pop-Location }
