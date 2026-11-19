param(
    [ValidateRange(1024,65535)][int]$Port = 8000,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$username = (Read-Host 'Dia chi Gmail gui thu').Trim()
if ($username -notmatch '^[A-Za-z0-9._%+-]+@gmail\.com$') {
    throw 'Nhap dia chi Gmail ca nhan. Voi provider khac, xem docs/EMAIL_DELIVERY.md.'
}

$securePassword = Read-Host 'Google App Password (an ky tu)' -AsSecureString
$credential = [PSCredential]::new($username, $securePassword)
$appPassword = $credential.GetNetworkCredential().Password -replace '\s', ''
$settings = @{
    SMTP_HOST = 'smtp.gmail.com'
    SMTP_PORT = '587'
    SMTP_SECURITY = 'starttls'
    SMTP_USERNAME = $username
    SMTP_PASSWORD = $appPassword
    SMTP_FROM = $username
    SMTP_TIMEOUT = '6'
}
$previous = @{}
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    if ($appPassword -notmatch '^[A-Za-z0-9]{16}$') {
        throw 'Can Google App Password 16 ky tu. Khoang trang phan nhom duoc bo qua.'
    }
    $python = '.\.venv\Scripts\python.exe'
    if (!(Test-Path -LiteralPath $python -PathType Leaf)) {
        throw 'Chua co Python venv. Chay scripts/setup.ps1 truoc.'
    }
    foreach ($name in $settings.Keys) {
        $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $settings[$name], 'Process')
    }
    @'
import os
import smtplib
import ssl
from backend.email_delivery import delivery_from_environment

try:
    settings = delivery_from_environment(os.environ).settings
    with smtplib.SMTP(settings.host, settings.port, timeout=settings.timeout) as smtp:
        smtp.ehlo()
        smtp.starttls(context=ssl.create_default_context(cafile=settings.ca_file))
        smtp.ehlo()
        smtp.login(settings.username, settings.password)
except smtplib.SMTPAuthenticationError as error:
    raise SystemExit(f"Gmail rejected SMTP authentication (code {error.smtp_code}). Check the account and App Password.")
except (OSError, smtplib.SMTPException, ValueError):
    raise SystemExit("SMTP connection or TLS check failed. Check network access to smtp.gmail.com:587 and trusted certificates.")
print("Gmail SMTP TLS and authentication passed. No message sent by this check.")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw 'Kiem tra SMTP khong thanh cong.'
    }
    if (!$CheckOnly) {
        & "$PSScriptRoot\start_backend.ps1" -Port $Port
    }
} finally {
    foreach ($name in $previous.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
    }
    $settings.Clear()
    $appPassword = $null
    $credential = $null
    $securePassword.Dispose()
    Pop-Location
}
