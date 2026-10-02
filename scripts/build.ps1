param([ValidateSet('web','apk')][string]$Target='web', [string]$ApiUrl='http://127.0.0.1:8000')
. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    if ($Target -eq 'web') {
        & $Flutter build web --release --no-web-resources-cdn "--dart-define=API_URL=$ApiUrl"
    } else {
        & $Flutter build apk --release "--dart-define=API_URL=$ApiUrl"
    }
    Assert-Exit 'Release build'
    if ($Target -eq 'web') {
        & '.\.venv\Scripts\python.exe' scripts\prepare_web_offline.py
        Assert-Exit 'Offline shell manifest'
    }
} finally { Pop-Location }
