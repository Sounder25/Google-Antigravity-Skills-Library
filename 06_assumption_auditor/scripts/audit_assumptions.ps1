param(
    [Parameter(Mandatory = $true)]
    [string[]]$Assumptions,
    [string[]]$VerifiedAssumptions
)

$ErrorActionPreference = "Stop"

$verified = @()
$unverified = @()

$verifiedSet = @()
if ($VerifiedAssumptions) { $verifiedSet += $VerifiedAssumptions }
if ($verifiedSet.Count -eq 1 -and $verifiedSet[0] -match ",") {
    $verifiedSet = $verifiedSet[0].Split(",") | ForEach-Object { $_.Trim() }
}

foreach ($a in $Assumptions) {
    $isVerified = $false
    if ($verifiedSet) {
        foreach ($v in $verifiedSet) {
            if ($a -eq $v) { $isVerified = $true; break }
        }
    }
    if ($isVerified) { $verified += $a }
    else { $unverified += $a }
}

$status = if ($unverified.Count -gt 0) { "WARN" } else { "PASS" }

@{
    status = $status
    verified = $verified
    unverified = $unverified
} | ConvertTo-Json -Depth 3
