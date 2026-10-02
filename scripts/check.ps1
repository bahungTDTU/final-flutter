. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    & (Join-Path (Split-Path $Flutter) 'dart.bat') format --output=none --set-exit-if-changed lib test integration_test test_driver
    Assert-Exit 'Format'
    & $Flutter analyze
    Assert-Exit 'Analyze'
    & $Flutter test
    Assert-Exit 'Flutter tests'
    & '.\.venv\Scripts\python.exe' -m pytest backend/tests -q
    Assert-Exit 'Backend tests'
} finally { Pop-Location }
