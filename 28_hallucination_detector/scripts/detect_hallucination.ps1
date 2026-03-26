param(
    [Parameter(Mandatory = $true)]
    [string]$Content,
    [string]$Domain = "General",
    [float]$Threshold = 0.7
)

$ErrorActionPreference = "Stop"

$claims = @()

if ($Content -match "v\d+\.\d+\.\d+") {
    $claims += @{ claim = $matches[0]; type = "version_reference"; verifiable = $false; confidence = 0.3; risk = "HIGH"; required_action = "Verify version" }
}

if ($Content -match "\/api\/[A-Za-z0-9_\/\-]+") {
    $claims += @{ claim = $matches[0]; type = "api_path"; verifiable = $false; confidence = 0.4; risk = "HIGH"; required_action = "Verify API path" }
}

if ($Content -match "[A-Za-z0-9_]+\([^\)]*\)") {
    $claims += @{ claim = $matches[0]; type = "function_signature"; verifiable = $false; confidence = 0.4; risk = "MEDIUM"; required_action = "Verify signature" }
}

$risk = if ($claims.Count -eq 0) { "LOW" } elseif ($claims | Where-Object { $_.risk -eq "HIGH" } ) { "HIGH" } else { "MEDIUM" }

@{
    hallucination_risk = $risk
    flagged_claims = $claims
    safe_to_proceed = ($risk -eq "LOW")
    recommendation = if ($risk -eq "LOW") { "Proceed" } else { "Verify flagged claims before proceeding" }
} | ConvertTo-Json -Depth 4
