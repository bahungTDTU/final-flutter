$ErrorActionPreference = 'Stop'
$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$temporaryRoot = Join-Path $workspaceRoot 'tmp'
# Exact, reviewed generated outputs. Backups, databases and evidence are excluded.
$relativeTargets = @(
    'tmp/bilingual-web-2026-10-16', 'tmp/dashboard-web-2026-10-14',
    'tmp/desk-navigation-web-2026-10-14', 'tmp/inspector-web-2026-10-13',
    'tmp/palettes-web-2026-10-16', 'tmp/rubric-ux-web-2026-10-14',
    'tmp/pdfs', 'tmp/__pycache__'
)
$results = @()
foreach ($relative in $relativeTargets) {
    $target = [IO.Path]::GetFullPath((Join-Path $workspaceRoot $relative))
    if (!$target.StartsWith($temporaryRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe cleanup path: $target"
    }
    if (!(Test-Path -LiteralPath $target)) { continue }
    $entry = Get-Item -LiteralPath $target -Force
    $children = @(Get-ChildItem -LiteralPath $target -Recurse -Force)
    if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
        @($children | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
        throw "Refusing to traverse links in $target"
    }
    $files = @($children | Where-Object { !$_.PSIsContainer })
    $bytes = ($files | Measure-Object Length -Sum).Sum
    Remove-Item -LiteralPath $target -Recurse -Force
    $results += [pscustomobject]@{ path=$relative; files=$files.Count; bytes=$bytes; removed=!(Test-Path -LiteralPath $target) }
}
$results | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot 'cleanup.json')
$results | Measure-Object files,bytes -Sum
