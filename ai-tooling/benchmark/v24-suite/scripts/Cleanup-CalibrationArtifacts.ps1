[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$suiteRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$taskNames = @(
    "01-windowed-attention",
    "02-softmax-trainer",
    "03-event-batch-parser",
    "04-state-snapshot"
)

foreach ($taskName in $taskNames) {
    $taskRoot = Join-Path $suiteRoot $taskName
    $starterRoot = Join-Path $taskRoot "starter"
    foreach ($name in @("x", "target", "t", "build", "cjpm.lock")) {
        $artifact = Join-Path $starterRoot $name
        if (Test-Path -LiteralPath $artifact) {
            Remove-Item -LiteralPath $artifact -Recurse -Force
        }
    }
    if (Test-Path -LiteralPath $taskRoot -PathType Container) {
        Get-ChildItem -LiteralPath $taskRoot -File -Force | ForEach-Object {
            if ($_.Name -eq "cjpm.lock" -or $_.Extension.ToLowerInvariant() -in @(".exe", ".cjo", ".a", ".bc")) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
    }
}

Write-Output "Calibration artifacts removed from all v24 task roots."
