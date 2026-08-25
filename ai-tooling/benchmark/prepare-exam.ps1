[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$benchmarkRoot = $PSScriptRoot
$resolvedParent = (Resolve-Path -LiteralPath (Split-Path -Parent $OutputPath)).Path
$examRoot = Join-Path $resolvedParent (Split-Path -Leaf $OutputPath)

if (Test-Path -LiteralPath $examRoot) {
    $existingFiles = @(Get-ChildItem -LiteralPath $examRoot -Force)
    if ($existingFiles.Count -gt 0) {
        throw "输出目录不是空目录，为避免覆盖数据已停止：$examRoot"
    }
} else {
    New-Item -ItemType Directory -Path $examRoot | Out-Null
}

$manifest = Get-Content -Raw (Join-Path $benchmarkRoot 'manifest.json') | ConvertFrom-Json
foreach ($task in $manifest.tasks) {
    $sourceRoot = Join-Path $benchmarkRoot ('tasks\' + $task.id)
    $taskOutput = Join-Path $examRoot $task.id
    New-Item -ItemType Directory -Path $taskOutput | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'prompt.md') -Destination (Join-Path $taskOutput 'prompt.md')
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'starter\src\answer.cj') -Destination (Join-Path $taskOutput 'answer.cj')
}

$instructions = @'
# 仓颉学习前考试

这个目录只包含题目和待填写的 `answer.cj`，不包含测试或标准答案。

考试规则：

1. 不使用任何仓颉 Codex Skill；
2. 不访问原项目仓库、标准答案或测试文件；
3. 不联网搜索答案；
4. 阅读每个题目的 `prompt.md`，只修改同目录的 `answer.cj`；
5. 不改变已有 `package` 声明、函数名称、参数和返回类型；
6. 完成目录中的全部题目后停止，不自行判分。
'@
Set-Content -LiteralPath (Join-Path $examRoot 'README.md') -Value $instructions -Encoding utf8

Write-Output $examRoot
