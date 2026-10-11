param([string]$Python = '')
. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    if (!(Test-Path '.venv\Scripts\python.exe')) {
        if ($Python) {
            $pythonCommand = $Python
            $pythonArguments = @()
        } elseif ($env:PYTHON_BIN) {
            $pythonCommand = $env:PYTHON_BIN
            $pythonArguments = @()
        } elseif (Get-Command py -ErrorAction SilentlyContinue) {
            $pythonCommand = (Get-Command py).Source
            $pythonArguments = @('-3.12')
        } else {
            $pythonCommand = 'python'
            $pythonArguments = @()
        }
        & $pythonCommand @pythonArguments -c 'import sys; assert sys.version_info[:2] == (3, 12), "Python 3.12 required; pass -Python or set PYTHON_BIN to its executable."'
        Assert-Exit 'Python 3.12 discovery (install Python 3.12 or pass -Python)'
        & $pythonCommand @pythonArguments -m venv .venv
        Assert-Exit 'Create Python environment'
    }
    & '.\.venv\Scripts\python.exe' -c 'import sys; assert sys.version_info[:2] == (3, 12), "Existing .venv must use Python 3.12; create a separate checkout or recreate the environment explicitly."'
    Assert-Exit 'Python environment version'
    & '.\.venv\Scripts\python.exe' -m pip install -r backend\requirements.txt
    Assert-Exit 'Backend dependencies'
    & $Flutter pub get
    Assert-Exit 'Flutter dependencies'
} finally { Pop-Location }
