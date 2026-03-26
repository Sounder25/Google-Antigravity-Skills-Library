param(
    [Parameter(Mandatory = $true)]
    [string]$Plan,
    [string]$Environment = "local",
    [bool]$Strict = $true,
    [string[]]$Files,
    [string[]]$EnvVars
)

$ErrorActionPreference = "Stop"

$deps = @()
$blocking = 0

if ($Files) {
    foreach ($f in $Files) {
        $exists = Test-Path $f
        $status = if ($exists) { "CONFIRMED" } else { "MISSING" }
        $block = (-not $exists) -and $Strict
        if ($block) { $blocking++ }
        $deps += @{ name = $f; type = "file"; status = $status; blocking = $block }
    }
}

if ($EnvVars) {
    foreach ($e in $EnvVars) {
        $val = [Environment]::GetEnvironmentVariable($e)
        $exists = -not [string]::IsNullOrWhiteSpace($val)
        $status = if ($exists) { "CONFIRMED" } else { "MISSING" }
        $block = (-not $exists) -and $Strict
        if ($block) { $blocking++ }
        $deps += @{ name = $e; type = "environment_variable"; status = $status; blocking = $block }
    }
}

@{
    ready_to_execute = ($blocking -eq 0)
    environment = $Environment
    dependencies = $deps
    blocking_count = $blocking
    recommendation = if ($blocking -eq 0) { "Proceed" } else { "BLOCK - resolve missing dependencies" }
    plan = $Plan
} | ConvertTo-Json -Depth 4
