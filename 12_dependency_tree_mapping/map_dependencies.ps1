# SKILL-009: Dependency Tree Mapping
# Generates Mermaid graph of project dependencies

param(
    [string]$WorkspacePath = (Get-Location),
    [string]$Format = "mermaid",
    [string]$OutputDir = ".dependencies"
)

$ErrorActionPreference = "Stop"
$WorkspacePath = Resolve-Path $WorkspacePath

# Setup output
$outputPath = Join-Path $WorkspacePath $OutputDir
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath -Force | Out-Null }

Write-Host "Analyzing dependencies in: $WorkspacePath" -ForegroundColor Cyan

# Detection Logic
$deps = @{}
$nodes = @()
$edges = @()

# .NET Analysis
if (Get-ChildItem -Path $WorkspacePath -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue) {
    Write-Host "Detected .NET Project. Running 'dotnet list package'..."
    try {
        # This is a simplified parser. Real-world needs 'dotnet list package --include-transitive' parsing
        $projects = Get-ChildItem -Path $WorkspacePath -Filter "*.csproj" -Recurse
        
        foreach ($proj in $projects) {
            $projName = $proj.BaseName
            $nodes += $projName
            
            # Read csproj XML safely
            [xml]$xml = Get-Content $proj.FullName
            if ($xml.Project.ItemGroup.PackageReference) {
                foreach ($ref in $xml.Project.ItemGroup.PackageReference) {
                    $pkg = $ref.Include
                    $version = $ref.Version
                    $nodes += $pkg
                    $edges += "$projName --> $pkg"
                }
            }
            
            # ProjectReferences
            if ($xml.Project.ItemGroup.ProjectReference) {
                foreach ($ref in $xml.Project.ItemGroup.ProjectReference) {
                    $refName = Split-Path $ref.Include -LeafBase
                    $nodes += $refName
                    $edges += "$projName --> $refName"
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to analyze .NET dependencies: $_"
    }
}

# Node.js Analysis
if (Test-Path "$WorkspacePath/package.json") {
    Write-Host "Detected Node.js Project. analyzing package.json..."
    try {
        $json = Get-Content "$WorkspacePath/package.json" | ConvertFrom-Json
        $rootName = $json.name
        if (-not $rootName) { $rootName = "Root" }
        $nodes += $rootName
        
        if ($json.dependencies) {
            $json.dependencies.PSObject.Properties | ForEach-Object {
                $nodes += $_.Name
                $edges += "$rootName --> $( $_.Name )"
            }
        }
        if ($json.devDependencies) {
            $json.devDependencies.PSObject.Properties | ForEach-Object {
                $nodes += $_.Name
                $edges += "$rootName -.-> $( $_.Name )" # Dotted line for dev
            }
        }
    }
    catch {
        Write-Warning "Failed to analyze Node.js dependencies: $_"
    }
}

# Generate Mermaid
$uniqueNodes = $nodes | Select-Object -Unique
$uniqueEdges = $edges | Select-Object -Unique

$mermaid = "graph TD`n"
foreach ($edge in $uniqueEdges) {
    # Sanitize names for Mermaid (remove dots, etc or quote them)
    # Simple strategy: Quote them or replace dots with underscores if unquoted
    # Here we stick to raw string for simplicity, but risk syntax error
    $mermaid += "    $edge`n"
}

$mmdPath = Join-Path $outputPath "DEPENDENCY_GRAPH.mmd"
$mermaid | Out-File -FilePath $mmdPath -Encoding utf8

# Generate Risk Report
$riskReport = "# Dependency Risk Report`n`n"
$riskReport += "Generated: $(Get-Date)`n`n"
$riskReport += "## Statistics`n"
$riskReport += "- Total Nodes: $($uniqueNodes.Count)`n"
$riskReport += "- Total Edges: $($uniqueEdges.Count)`n`n"

$riskReport += "## Critical Nodes (Most Dependents)`n"
# Count incoming edges
$incoming = @{}
foreach ($edge in $uniqueEdges) {
    if ($edge -match "--> (.*)") {
        $target = $matches[1].Trim()
        $incoming[$target] = [int]$incoming[$target] + 1
    }
}

$incoming.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 | ForEach-Object {
    $riskReport += "- **$($_.Key)**: Referenced by $($_.Value) components`n"
}

$reportPath = Join-Path $outputPath "RISK_REPORT.md"
$riskReport | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`n✅ Success!" -ForegroundColor Green
Write-Host "   Graph: $mmdPath" -ForegroundColor Cyan
Write-Host "   Report: $reportPath" -ForegroundColor Cyan
