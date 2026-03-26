param(
    [string[]]$ExpectedPresent,
    [string[]]$ExpectedAbsent,
    [hashtable]$ExpectedContains
)

$ErrorActionPreference = "Stop"

$failures = @()
$checks = 0

if ($ExpectedPresent) {
    foreach ($p in $ExpectedPresent) {
        $checks++
        if (-not (Test-Path $p)) { $failures += "Missing: $p" }
    }
}

if ($ExpectedAbsent) {
    foreach ($p in $ExpectedAbsent) {
        $checks++
        if (Test-Path $p) { $failures += "Should be absent: $p" }
    }
}

if ($ExpectedContains) {
    foreach ($k in $ExpectedContains.Keys) {
        $checks++
        if (-not (Test-Path $k)) { $failures += "Missing: $k"; continue }
        $content = Get-Content $k -Raw
        if ($content -notmatch [regex]::Escape($ExpectedContains[$k])) {
            $failures += "Content mismatch: $k"
        }
    }
}

$status = if ($failures.Count -eq 0) { "PASS" } else { "FAIL" }

@{
    status = $status
    checks = $checks
    failures = $failures
} | ConvertTo-Json -Depth 4
