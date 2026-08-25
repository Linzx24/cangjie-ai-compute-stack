[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$SdkRoot = $env:CANGJIE_HOME,
    [switch]$RunTests,
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

function Find-ProjectRoot([string]$StartPath) {
    $current = Get-Item -LiteralPath (Resolve-Path -LiteralPath $StartPath)
    if (-not $current.PSIsContainer) {
        $current = $current.Directory
    }
    while ($null -ne $current) {
        if (Test-Path -LiteralPath (Join-Path $current.FullName 'cjpm.toml') -PathType Leaf) {
            return $current.FullName
        }
        $current = $current.Parent
    }
    throw "从 $StartPath 向上未找到 cjpm.toml。"
}

function Add-Check([System.Collections.Generic.List[object]]$Checks, [string]$Name, [bool]$Passed, [string]$Detail) {
    $Checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed; Detail = $Detail })
}

function Classify-Diagnostic([string]$Output) {
    $rules = @(
        @{ Pattern = 'cannot be modified in immutable function'; Category = '结构体可变性'; Advice = '方法正在修改结构体字段；若这是预期行为，将字段设为 var，并把结构体方法声明为 mut func。' },
        @{ Pattern = 'cannot assign to immutable value'; Category = '不可变值赋值'; Advice = '赋值目标由 let 或不可变字段声明；确认需要修改后再改为 var。' },
        @{ Pattern = 'mismatched types'; Category = '类型不匹配'; Advice = '声明类型与表达式结果不同；先检查报错函数的返回类型和报错表达式。' },
        @{ Pattern = 'undeclared identifier'; Category = '名称或作用域'; Advice = '检查标识符拼写、import 和声明所在作用域。' },
        @{ Pattern = 'failed to compile package'; Category = '编译失败'; Advice = '这是 cjpm 汇总信息；真正原因通常在它前面的第一条 compiler error。' },
        @{ Pattern = 'FAILED'; Category = '测试失败'; Advice = '读取第一个失败测试及断言，不要先修改测试。' }
    )
    $matches = foreach ($rule in $rules) {
        $position = $Output.IndexOf($rule.Pattern, [StringComparison]::OrdinalIgnoreCase)
        if ($position -ge 0) {
            [pscustomobject]@{ Position = $position; Rule = $rule }
        }
    }
    if ($matches) {
        return ($matches | Sort-Object Position | Select-Object -First 1).Rule
    }
    return @{ Category = '未分类'; Advice = '保留完整输出，并从最早出现的 error、文件和行号开始缩小问题。' }
}

$checks = [System.Collections.Generic.List[object]]::new()
$projectRoot = Find-ProjectRoot $ProjectPath

if ([string]::IsNullOrWhiteSpace($SdkRoot)) {
    Add-Check $checks 'SDK' $false '未设置 CANGJIE_HOME，也没有传入 -SdkRoot。'
    $diagnosis = @{ Category = '环境缺失'; Advice = '安装仓颉 SDK，或通过 -SdkRoot 指向 SDK 的 cangjie 目录。' }
    $exitCode = 2
}
else {
    $resolvedSdk = (Resolve-Path -LiteralPath $SdkRoot).Path
    $envSetup = Join-Path $resolvedSdk 'envsetup.ps1'
    if (-not (Test-Path -LiteralPath $envSetup -PathType Leaf)) {
        throw "找不到仓颉环境脚本：$envSetup"
    }
    . $envSetup

    $compilerVersion = (& cjc --version 2>&1 | Out-String).Trim()
    $compilerExit = $LASTEXITCODE
    Add-Check $checks 'SDK' ($compilerExit -eq 0) $compilerVersion

    Push-Location $projectRoot
    try {
        $buildOutput = (& cjpm build 2>&1 | Out-String).Trim()
        $buildExit = $LASTEXITCODE
        Add-Check $checks 'Build' ($buildExit -eq 0) $buildOutput

        $testExit = 0
        if ($buildExit -eq 0 -and $RunTests) {
            $testOutput = (& cjpm test --no-color 2>&1 | Out-String).Trim()
            $testExit = $LASTEXITCODE
            Add-Check $checks 'Tests' ($testExit -eq 0) $testOutput
        }
    }
    finally {
        Pop-Location
    }

    $exitCode = if ($buildExit -ne 0) { $buildExit } elseif ($testExit -ne 0) { $testExit } else { 0 }
    if ($exitCode -eq 0) {
        $diagnosis = @{ Category = '健康'; Advice = '环境、构建和所请求的测试均通过，无需修复。' }
    }
    else {
        $combinedOutput = (($checks | ForEach-Object { $_.Detail }) -join "`n")
        $diagnosis = Classify-Diagnostic $combinedOutput
    }
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Cangjie Doctor 报告')
$lines.Add('')
$lines.Add("- 项目：``$projectRoot``")
$lines.Add("- 结论：$($diagnosis.Category)")
$lines.Add("- 建议：$($diagnosis.Advice)")
$lines.Add('')
$lines.Add('| 检查 | 结果 |')
$lines.Add('| --- | --- |')
foreach ($check in $checks) {
    $status = if ($check.Passed) { '通过' } else { '失败' }
    $lines.Add("| $($check.Name) | $status |")
}
$lines.Add('')
$lines.Add('## 原始证据')
foreach ($check in $checks) {
    $lines.Add('')
    $lines.Add("### $($check.Name)")
    $lines.Add('```text')
    $lines.Add($check.Detail)
    $lines.Add('```')
}

$report = $lines -join "`n"
Write-Output $report
if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportDirectory = Split-Path -Parent $ReportPath
    if (-not [string]::IsNullOrWhiteSpace($reportDirectory)) {
        New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8
}

exit $exitCode
