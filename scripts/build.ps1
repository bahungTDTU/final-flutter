param([ValidateSet('web','apk')][string]$Target='web', [string]$ApiUrl='', [switch]$Production)
. "$PSScriptRoot\toolchain.ps1"
Push-Location $Workspace
try {
    if ($Production) {
        if (!$ApiUrl) { throw 'Production requires an explicit HTTPS ApiUrl.' }
        & '.\.venv\Scripts\python.exe' scripts\release_preflight.py --api-url $ApiUrl
        Assert-Exit 'Production API preflight'
        if ($Target -eq 'apk' -and !(Test-Path -LiteralPath 'android/key.properties' -PathType Leaf)) {
            throw 'Production APK requires ignored android/key.properties and a private keystore.'
        }
    } elseif (!$ApiUrl) { $ApiUrl = 'http://127.0.0.1:8000' }
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
