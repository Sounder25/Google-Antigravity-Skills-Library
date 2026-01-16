param([string]$Command, [int]$Retries=3, [switch]$Heuristics=$true)
$ErrorActionPreference = "Continue"

function Log { param($M, $C="Cyan") Write-Host "[RECOVERY] $M" -ForegroundColor $C }

Log "Exec: $Command"

for ($i=1; $i -le $Retries; $i++) {
    Log "Attempt $i/$Retries"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo.FileName = "powershell.exe"
    $p.StartInfo.Arguments = "-NoProfile -Command `"$Command`""
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError = $true
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.CreateNoWindow = $true
    
    $p.Start() | Out-Null
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    
    if ($out) { Write-Host $out }
    if ($err) { Write-Host $err -ForegroundColor Red }
    
    if ($p.ExitCode -eq 0) { Log "Success!" "Green"; exit 0 }
    
    Log "Exit Code $($p.ExitCode)" "Red"
    if (-not $Heuristics) { exit $p.ExitCode }
    
    $full = "$out`n$err"
    $fixed = $false
    
    if ($full -match "ModuleNotFoundError: No module named '(.*)'") {
        Log "Installing module: $($matches[1])" "Yellow"
        pip install $matches[1]
        if ($LASTEXITCODE -eq 0) { $fixed = $true }
    }
    
    if (-not $fixed -and $full -match "Could not find a part of the path '([^']*)'") {
        $d = Split-Path $matches[1] -Parent
        if ($d) {
            Log "Creating dir: $d" "Yellow"
            New-Item -ItemType Directory -Path $d -Force | Out-Null
            $fixed = $true
        }
    }
    
    if ($fixed) { Log "Retrying..."; continue }
    break
}
exit 1
