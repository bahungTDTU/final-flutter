. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    & '.\.venv\Scripts\python.exe' -m uvicorn backend.app:create_app --factory --host 127.0.0.1 --port 8000 --no-access-log
    Assert-Exit 'Backend'
} finally { Pop-Location }
