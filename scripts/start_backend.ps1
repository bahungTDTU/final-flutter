param([ValidateRange(1024,65535)][int]$Port = 8000)

. "$PSScriptRoot\toolchain.ps1"
if (-not $env:GEMINI_API_KEY -and -not $env:GEMINI_API_KEY_FILE) {
    $aiKeyPath = Join-Path $Workspace 'backend\state\gemini-api-key.txt'
    if (Test-Path -LiteralPath $aiKeyPath) { $env:GEMINI_API_KEY_FILE = $aiKeyPath }
}
Push-Location $Workspace
try {
    & '.\.venv\Scripts\python.exe' -m uvicorn backend.app:create_app --factory --host 127.0.0.1 --port $Port --no-access-log
    Assert-Exit 'Backend'
} finally { Pop-Location }
