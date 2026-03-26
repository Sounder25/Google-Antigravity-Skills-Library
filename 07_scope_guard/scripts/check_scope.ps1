param(
    [Parameter(Mandatory = $true)]
    [string[]]$AllowedRoots,
    [Parameter(Mandatory = $true)]
    [string[]]$ObservedPaths
)

$ErrorActionPreference = "Stop"

$normalizedRoots = $AllowedRoots | ForEach-Object { [System.IO.Path]::GetFullPath($_) }
$out = @()

foreach ($p in $ObservedPaths) {
    $full = [System.IO.Path]::GetFullPath($p)
    $inScope = $false
    foreach ($root in $normalizedRoots) {
        if ($full.StartsWith($root)) { $inScope = $true; break }
    }
    if (-not $inScope) { $out += $p }
}

$status = if ($out.Count -gt 0) { "FAIL" } else { "PASS" }

@{
    status = $status
    out_of_scope = $out
} | ConvertTo-Json -Depth 3
