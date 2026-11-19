param(
    [ValidateRange(1024,65535)][int]$Port = 8000,
    [string]$EnvFile = '.env'
)

. "$PSScriptRoot\toolchain.ps1"
if (-not $env:GEMINI_API_KEY -and -not $env:GEMINI_API_KEY_FILE) {
    $aiKeyPath = Join-Path $Workspace 'backend\state\gemini-api-key.txt'
    if (Test-Path -LiteralPath $aiKeyPath) { $env:GEMINI_API_KEY_FILE = $aiKeyPath }
}
Push-Location $Workspace
try {
    $uvicornArgs = @('backend.app:create_app', '--factory', '--host', '127.0.0.1',
        '--port', $Port, '--no-access-log')
    if (Test-Path -LiteralPath $EnvFile -PathType Leaf) {
        $uvicornArgs += @('--env-file', (Resolve-Path -LiteralPath $EnvFile).Path)
    } elseif ($PSBoundParameters.ContainsKey('EnvFile')) {
        throw 'EnvFile does not exist or is not a file.'
    }
    & '.\.venv\Scripts\python.exe' -m uvicorn @uvicornArgs
    Assert-Exit 'Backend'
} finally { Pop-Location }
