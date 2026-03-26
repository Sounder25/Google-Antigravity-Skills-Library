Describe "Deterministic verification" {
    It "runs the verification harness" {
        $root = Resolve-Path "."
        $script = Join-Path $root "Publish-Results.ps1"
        & $script | Out-Null
        $summary = Join-Path $root "VERIFICATION_SUMMARY.md"
        Test-Path $summary | Should -BeTrue
    }
}
