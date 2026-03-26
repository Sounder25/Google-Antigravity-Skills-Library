param(
    [string]$Text,
    [string]$Path,
    [switch]$CommentUnknown
)

$ErrorActionPreference = "Stop"

if (-not $Text -and -not $Path) {
    Write-Error "Provide -Text or -Path."
    exit 1
}

if ($Path) {
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        exit 1
    }
    $Text = Get-Content $Path -Raw
}

$lines = $Text -split "`r?`n"

$commandPrefixes = @(
    "git", "dotnet", "npm", "yarn", "pnpm", "python", "pip", "pwsh", "powershell",
    "cd", "mkdir", "rmdir", "rm", "del", "copy", "move", "robocopy", "xcopy",
    "curl", "wget", "Invoke-WebRequest", "Invoke-RestMethod", "gh", "go", "cargo",
    "make", "msbuild", "cmake", "docker", "kubectl", "az", "aws", "gcloud"
)

$outputPatterns = @(
    "^PS ", "^> ", "^C:\\", "Everything up-to-date", "At line:", "CategoryInfo:",
    "^error:", "^warning:", "^fatal:", "Traceback", "Exception:", "^INFO:", "^NOTICE:"
)

$clean = @()

foreach ($raw in $lines) {
    $line = $raw.Trim()
    if (-not $line) { continue }

    $isOutput = $false
    foreach ($pattern in $outputPatterns) {
        if ($line -match $pattern) { $isOutput = $true; break }
    }
    if ($isOutput) { continue }

    $isCommand = $false
    foreach ($prefix in $commandPrefixes) {
        if ($line -match "^$([regex]::Escape($prefix))\b") { $isCommand = $true; break }
    }

    if ($isCommand) {
        $clean += $line
    } elseif ($CommentUnknown) {
        $clean += "# $line"
    }
}

"## COPY/PASTE COMMANDS"
'```powershell'
foreach ($c in $clean) { $c }
'```'
