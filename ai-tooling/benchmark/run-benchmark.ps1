[CmdletBinding()]
param(
    [ValidateSet('Reference', 'Submission')]
    [string]$Mode = 'Reference',
    [string]$SubmissionPath,
    [string]$ReportPath,
    [string]$SdkRoot = $env:CANGJIE_HOME
)

$ErrorActionPreference = 'Stop'
$benchmarkRoot = $PSScriptRoot
$manifest = Get-Content -Raw (Join-Path $benchmarkRoot 'manifest.json') | ConvertFrom-Json

if (-not (Get-Command cjpm -ErrorAction SilentlyContinue)) {
    if (-not $SdkRoot) {
        throw '未找到 cjpm。请先载入仓颉环境，或使用 -SdkRoot 指定 SDK 的 cangjie 目录。'
    }
    $envSetup = Join-Path $SdkRoot 'envsetup.ps1'
    if (-not (Test-Path -LiteralPath $envSetup)) {
        throw "找不到环境脚本：$envSetup"
    }
    . $envSetup
}

if ($Mode -eq 'Submission') {
    if (-not $SubmissionPath) {
        throw 'Submission 模式必须提供 -SubmissionPath。'
    }
    $SubmissionPath = (Resolve-Path -LiteralPath $SubmissionPath).Path
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$runRoot = Join-Path $tempBase ('cangjie-benchmark-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null

$results = @()
try {
    foreach ($task in $manifest.tasks) {
        $taskRoot = Join-Path $benchmarkRoot ('tasks\' + $task.id)
        $workRoot = Join-Path $runRoot $task.id
        Copy-Item -LiteralPath (Join-Path $taskRoot 'starter') -Destination $workRoot -Recurse
        Copy-Item -LiteralPath (Join-Path $taskRoot 'tests\answer_test.cj') -Destination (Join-Path $workRoot 'src\answer_test.cj')

        if ($Mode -eq 'Reference') {
            $answerPath = Join-Path $taskRoot 'reference\answer.cj'
        } else {
            $answerPath = Join-Path $SubmissionPath ($task.id + '\answer.cj')
        }

        if (-not (Test-Path -LiteralPath $answerPath)) {
            $results += [pscustomobject]@{
                id = $task.id
                category = $task.category
                points = [int]$task.points
                earned = 0
                passed = $false
                message = '缺少 answer.cj'
            }
            continue
        }

        Copy-Item -LiteralPath $answerPath -Destination (Join-Path $workRoot 'src\answer.cj') -Force
        Push-Location $workRoot
        try {
            $output = (& cjpm test --no-color 2>&1 | Out-String).Trim()
            $passed = $LASTEXITCODE -eq 0
        } finally {
            Pop-Location
        }

        $results += [pscustomobject]@{
            id = $task.id
            category = $task.category
            points = [int]$task.points
            earned = if ($passed) { [int]$task.points } else { 0 }
            passed = $passed
            message = if ($passed) { '编译和测试通过' } else { $output }
        }
    }
} finally {
    $resolvedRunRoot = [IO.Path]::GetFullPath($runRoot)
    if ($resolvedRunRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedRunRoot)) {
        Remove-Item -LiteralPath $resolvedRunRoot -Recurse -Force
    }
}

$earned = ($results | Measure-Object -Property earned -Sum).Sum
$total = [int]$manifest.total_points
$lines = @(
    '# Cangjie Benchmark 报告',
    '',
    "- 模式：$Mode",
    "- 仓颉版本：$($manifest.cangjie_version)",
    "- 总成绩：$earned/$total",
    '',
    '| 题目 | 类别 | 结果 | 得分 |',
    '| --- | --- | --- | ---: |'
)
foreach ($result in $results) {
    $status = if ($result.passed) { '通过' } else { '失败' }
    $lines += "| $($result.id) | $($result.category) | $status | $($result.earned)/$($result.points) |"
}
$report = $lines -join [Environment]::NewLine
Write-Output $report

if ($ReportPath) {
    $reportDirectory = Split-Path -Parent $ReportPath
    if ($reportDirectory) {
        New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
    }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8
    Write-Host "报告已写入：$ReportPath"
}

if ($earned -ne $total) {
    exit 1
}
