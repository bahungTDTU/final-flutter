param()
. "$PSScriptRoot\toolchain.ps1"
$aiKeyPath = Join-Path $Workspace 'backend\state\gemini-api-key.txt'
$aiDirectory = Split-Path -Parent $aiKeyPath
Write-Host 'Google AI Studio: https://aistudio.google.com/api-keys'
Write-Host 'Chon key trong project Free tier. Khong can bat billing.'
$aiSecret = Read-Host 'Dan Gemini API key (an ky tu; khong gui key vao chat)' -AsSecureString
$aiPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($aiSecret)
try {
    $aiValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($aiPointer).Trim()
    if ($aiValue.Length -lt 20 -or $aiValue.Length -gt 512 -or $aiValue -match '\s') {
        throw 'API key khong hop le. Khong luu key.'
    }
    New-Item -ItemType Directory -Path $aiDirectory -Force | Out-Null
    [IO.File]::WriteAllText($aiKeyPath, $aiValue, [Text.UTF8Encoding]::new($false))
    Write-Host 'Da luu key local trong backend/state (Git ignored). Restart backend de ap dung.'
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($aiPointer)
    $aiValue = $null
    $aiSecret.Dispose()
}
