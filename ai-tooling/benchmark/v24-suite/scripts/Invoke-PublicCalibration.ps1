[CmdletBinding()]
param(
    [string]$CjpmPath = '',
    [string]$CjcPath = '',
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
function Test-ExactCangjie113([string]$Text) {
    $value = [string]$Text
    if ([string]::IsNullOrWhiteSpace($value)) { return $false }
    $hasExact = $false
    foreach ($line in @($value -split '\r?\n' | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ })) {
        if ($line -match '(?<![A-Za-z0-9.])1\.1\.3[-+A-Za-z0-9.]') { return $false }
        if ($line -match '(?<![A-Za-z0-9.])1\.1\.3(?![-+A-Za-z0-9.])') { $hasExact = $true }
    }
    return [bool]$hasExact
}
function Resolve-CangjieTool([string]$ConfiguredPath, [string]$Label, [string[]]$VersionArguments) {
    if ([string]::IsNullOrWhiteSpace($ConfiguredPath)) { throw "$Label path is required." }
    $resolved = (Resolve-Path -LiteralPath $ConfiguredPath -ErrorAction Stop).Path
    $item = Get-Item -LiteralPath $resolved -Force -ErrorAction Stop
    if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "$Label path must be a non-reparse executable file: $resolved" }
    $version = (& $resolved @VersionArguments 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not (Test-ExactCangjie113 $version)) { throw "Public calibration requires exact $Label 1.1.3; observed: $version" }
    return [IO.Path]::GetFullPath($resolved)
}

if ($SelfTest) {
    if (-not (Test-ExactCangjie113 'Cangjie Project Manager: 1.1.3') -or (Test-ExactCangjie113 'Cangjie Project Manager: 1.1.30') -or (Test-ExactCangjie113 'Cangjie Project Manager: 1.1.3-beta')) { throw 'Public calibration version predicate self-test failed.' }
    Write-Output 'V24_PUBLIC_CALIBRATION_SELFTEST_VALID explicit_cjpm_path=True explicit_cjc_path=True exact_version=True cleanup_finally=True model_calls=0'
    exit 0
}
if ([string]::IsNullOrWhiteSpace($CjpmPath) -or [string]::IsNullOrWhiteSpace($CjcPath)) { throw 'CjpmPath and CjcPath are required outside -SelfTest.' }
$cjpm = Resolve-CangjieTool $CjpmPath 'cjpm' @('--version')
$cjc = Resolve-CangjieTool $CjcPath 'cjc' @('-v')
$suiteRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$tasks = @(
    @{ Id = "01-windowed-attention"; Source = "starter/src/windowed_attention.cj"; Tests = @("tests/public_test_01.cj", "tests/public_test_02.cj", "tests/public_test_03.cj", "tests/public_test_04.cj") },
    @{ Id = "02-softmax-trainer"; Source = "starter/src/softmax_trainer.cj"; Tests = @("tests/public_test_01.cj", "tests/public_test_02.cj", "tests/public_test_03.cj", "tests/public_test_04.cj") },
    @{ Id = "03-event-batch-parser"; Source = "starter/src/event_batch_parser.cj"; Tests = @("tests/public_test_01.cj", "tests/public_test_02.cj", "tests/public_test_03.cj", "tests/public_test_04.cj") },
    @{ Id = "04-state-snapshot"; Source = "starter/src/state_snapshot.cj"; Tests = @("tests/public_test_01.cj", "tests/public_test_02.cj", "tests/public_test_03.cj", "tests/public_test_04.cj") }
)

$passed = 0
$total = 0
$rows = [Collections.Generic.List[object]]::new()
$cleanupScript = Join-Path $PSScriptRoot "Cleanup-CalibrationArtifacts.ps1"

try {
foreach ($task in $tasks) {
    $taskRoot = Join-Path $suiteRoot $task.Id
    $starterRoot = Join-Path $taskRoot "starter"
    Push-Location $starterRoot
    try {
        & $cjpm build
        if ($LASTEXITCODE -ne 0) { throw "cjpm build failed for $($task.Id)" }
    }
    finally {
        Pop-Location
    }

    $sourcePath = Join-Path $taskRoot $task.Source
    $index = 0
    foreach ($testRelative in $task.Tests) {
        $index += 1
        $total += 1
        $testPath = Join-Path $taskRoot $testRelative
        $exePath = Join-Path $taskRoot (".calibration-{0}.exe" -f $index)
        & $cjc $sourcePath $testPath -o $exePath
        $compileExit = $LASTEXITCODE
        $runExit = 1
        if ($compileExit -eq 0) {
            & $exePath
            $runExit = $LASTEXITCODE
        }
        $ok = ($compileExit -eq 0 -and $runExit -eq 0)
        if ($ok) { $passed += 1 }
        $rows.Add([PSCustomObject]@{ Task = $task.Id; Test = $index; Passed = $ok })
        if (Test-Path -LiteralPath $exePath) { Remove-Item -LiteralPath $exePath -Force }
    }
}

foreach ($row in $rows) {
    Write-Output ("{0} test {1}: {2}" -f $row.Task, $row.Test, $(if ($row.Passed) { "PASS" } else { "FAIL" }))
}
Write-Output ("Starter public calibration: {0}/{1} tests passed" -f $passed, $total)
}
finally {
    & $cleanupScript | Out-Host
}
