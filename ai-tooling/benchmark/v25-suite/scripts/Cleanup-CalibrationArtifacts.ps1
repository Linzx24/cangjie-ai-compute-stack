[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$suiteRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$rootPrefix = $suiteRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$taskNames = @(
    "01-masked-smoothing",
    "02-gradient-window",
    "03-beam-frontier",
    "04-tensor-checkpoint"
)

foreach ($taskName in $taskNames) {
    $taskRoot = [IO.Path]::GetFullPath((Join-Path $suiteRoot $taskName))
    $starterRoot = [IO.Path]::GetFullPath((Join-Path $taskRoot "starter"))
    if (-not $taskRoot.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean outside the v25 suite: $taskRoot"
    }
    foreach ($ownedRoot in @($taskRoot, $starterRoot)) {
        if (Test-Path -LiteralPath $ownedRoot) {
            $ownedItem = Get-Item -LiteralPath $ownedRoot -Force
            if (($ownedItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing to clean through a reparse point: $ownedRoot"
            }
        }
    }
    foreach ($name in @("x", "target", "t", "build", "cjpm.lock")) {
        $artifact = [IO.Path]::GetFullPath((Join-Path $starterRoot $name))
        if (-not $artifact.StartsWith($starterRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean outside the starter: $artifact"
        }
        if (Test-Path -LiteralPath $artifact) {
            $artifactItem = Get-Item -LiteralPath $artifact -Force
            if (($artifactItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing to remove a reparse point: $artifact"
            }
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

Write-Output "Calibration artifacts removed from all v25 task roots."
