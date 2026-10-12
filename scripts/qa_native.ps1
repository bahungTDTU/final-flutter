param(
    [Parameter(Mandatory = $true)][string]$Device,
    [Parameter(Mandatory = $true)][uri]$ApiUrl,
    [ValidateSet('note_flow', 'sharing', 'realtime')]
    [string[]]$Suites = @('note_flow', 'sharing', 'realtime'),
    [string]$JvmSocketDirectory = '',
    [switch]$SoftwareRendering,
    [string]$EvidenceDirectory = 'output/native-acceptance'
)
. "$PSScriptRoot\toolchain.ps1"

# Run only against a disposable local QA backend. Never start/stop other services.
if ($ApiUrl.Scheme -ne 'http' -or $ApiUrl.Host -notin @('127.0.0.1', 'localhost', '10.0.2.2') -or
    $ApiUrl.UserInfo -or $ApiUrl.Query -or $ApiUrl.Fragment -or $ApiUrl.AbsolutePath -ne '/') {
    throw 'Use a disposable local HTTP backend (127.0.0.1, localhost or Android emulator host 10.0.2.2).'
}
$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
Push-Location $Workspace
try {
    if ($JvmSocketDirectory) {
        if (![IO.Path]::IsPathRooted($JvmSocketDirectory) -or $JvmSocketDirectory -match '[\s"\r\n]') {
            throw 'JvmSocketDirectory must be an absolute Windows path without spaces or quotes.'
        }
        $socketPath = [IO.Path]::GetFullPath($JvmSocketDirectory)
        New-Item -ItemType Directory -Force -Path $socketPath | Out-Null
        # Windows packaged-app filesystem virtualization can break JDK Unix sockets.
        # Scope the workaround to child JVMs and restore the caller environment below.
        $env:JAVA_TOOL_OPTIONS = "$previousJavaOptions -Djdk.net.unixdomain.tmpdir=$socketPath".Trim()
    }
    New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
    $source = (& git rev-parse HEAD).Trim()
    Assert-Exit 'Read source commit'
    $changes = @(& git status --porcelain --untracked-files=no)
    Assert-Exit 'Read source changes'
    $runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $results = @()
    foreach ($suite in $Suites) {
        $log = Join-Path $EvidenceDirectory "$runId-$suite.txt"
        $arguments = @('drive', '--driver=test_driver/integration_test.dart', "--target=integration_test/${suite}_test.dart", '-d', $Device,
            "--dart-define=API_URL=$($ApiUrl.AbsoluteUri.TrimEnd('/'))")
        if ($SoftwareRendering) {
            $arguments += @('--enable-software-rendering', '--no-enable-impeller')
        }
        & $Flutter @arguments 2>&1 | ForEach-Object {
            # The driver prints a temporary VM-service capability; omit it from publishable logs.
            [regex]::Replace($_.ToString(), '(http://127\.0\.0\.1:\d+/)[A-Za-z0-9_-]+=/','${1}[REDACTED]/')
        } | Tee-Object -FilePath $log | Out-Host
        $code = $LASTEXITCODE
        $results += [pscustomobject]@{
            suite = $suite; exit_code = $code; log = $log
            command = @($Flutter) + $arguments
        }
        [pscustomobject]@{
            source = $source; tracked_changes = $changes
            date = (Get-Date).ToUniversalTime().ToString('o')
            device = $Device; api_url = $ApiUrl.AbsoluteUri
            scope = 'Android integration: injected text input and database reopen; not real IME or OS relaunch.'
            results = $results
        } | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $EvidenceDirectory "$runId-results.json")
        if ($code -ne 0) { throw "Native suite $suite failed (exit $code). See $log." }
    }
} finally {
    $env:JAVA_TOOL_OPTIONS = $previousJavaOptions
    Pop-Location
}
