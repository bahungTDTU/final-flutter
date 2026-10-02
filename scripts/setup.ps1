param([string]$Python = 'C:\Users\LENOVO\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe')
. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    if (!(Test-Path '.venv\Scripts\python.exe')) {
        & $Python -m venv .venv
        Assert-Exit 'Create Python environment'
    }
    & '.\.venv\Scripts\python.exe' -m pip install -r backend\requirements.txt
    Assert-Exit 'Backend dependencies'
    & $Flutter pub get
    Assert-Exit 'Flutter dependencies'
} finally { Pop-Location }
