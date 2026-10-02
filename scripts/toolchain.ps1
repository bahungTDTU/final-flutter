$ErrorActionPreference = 'Stop'
$script:Workspace = Split-Path -Parent $PSScriptRoot
$script:Flutter = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } elseif (Get-Command flutter -ErrorAction SilentlyContinue) { (Get-Command flutter).Source } elseif (Test-Path 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat') { 'C:\Users\LENOVO\flutter-sdk\bin\flutter.bat' } else { throw 'Set FLUTTER_BIN to flutter.bat.' }
function Assert-Exit([string]$Step) { if ($LASTEXITCODE -ne 0) { throw "$Step failed with exit code $LASTEXITCODE" } }
