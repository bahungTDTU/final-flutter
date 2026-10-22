$ErrorActionPreference = 'Stop'
$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$temporaryRoot = Join-Path $workspaceRoot 'tmp'
$script:removedFiles = 0
$script:removedBytes = 0L
$script:removedLinks = 0
$script:failures = @()
function Remove-TestCache([string]$path) {
    $absolute = [IO.Path]::GetFullPath($path)
    if (!$absolute.StartsWith($temporaryRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Outside temporary root: $absolute"
    }
    try {
        $item = Get-Item -LiteralPath $absolute -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            # Delete the link itself, never resolve or traverse its target.
            Remove-Item -LiteralPath $absolute -Force
            $script:removedLinks++
        } elseif ($item.PSIsContainer) {
            foreach ($child in @(Get-ChildItem -LiteralPath $absolute -Force)) {
                Remove-TestCache $child.FullName
            }
            if (@(Get-ChildItem -LiteralPath $absolute -Force).Count -eq 0) {
                Remove-Item -LiteralPath $absolute -Force
            }
        } else {
            $length = $item.Length
            Remove-Item -LiteralPath $absolute -Force
            $script:removedFiles++
            $script:removedBytes += $length
        }
    } catch {
        $script:failures += [pscustomobject]@{path=$absolute; error=$_.Exception.Message}
    }
}
# These are old pytest outputs, not the current run's system-temp directory.
foreach ($directory in Get-ChildItem -LiteralPath $temporaryRoot -Directory -Filter 'pytest-*') {
    Remove-TestCache $directory.FullName
}
[pscustomobject]@{files=$removedFiles;bytes=$removedBytes;links=$removedLinks;failures=$failures} |
    ConvertTo-Json -Depth 4 | Set-Content (Join-Path $PSScriptRoot 'cleanup-test-cache.json')
Get-Content (Join-Path $PSScriptRoot 'cleanup-test-cache.json')
