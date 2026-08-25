[CmdletBinding()]
param(
    [string]$SdkRoot = $env:CANGJIE_HOME,
    [switch]$RunSmokeTest
)

$ErrorActionPreference = 'Stop'
$requiredVersion = '1.1.3'

if (-not (Get-Command cjc -ErrorAction SilentlyContinue)) {
    if (-not $SdkRoot) {
        throw '未找到 cjc。请先执行 cangjie/envsetup.ps1，或通过 -SdkRoot 指定 SDK 的 cangjie 目录。'
    }

    $envSetup = Join-Path $SdkRoot 'envsetup.ps1'
    if (-not (Test-Path -LiteralPath $envSetup)) {
        throw "找不到环境脚本：$envSetup"
    }
    . $envSetup
}

$compilerVersion = (& cjc -v 2>&1 | Out-String).Trim()
$projectManagerVersion = (& cjpm --version 2>&1 | Out-String).Trim()

if ($compilerVersion -notmatch [regex]::Escape($requiredVersion)) {
    throw "cjc 版本不符合要求，需要 $requiredVersion。实际输出：$compilerVersion"
}
if ($projectManagerVersion -notmatch [regex]::Escape($requiredVersion)) {
    throw "cjpm 版本不符合要求，需要 $requiredVersion。实际输出：$projectManagerVersion"
}

Write-Host "[OK] $compilerVersion"
Write-Host "[OK] $projectManagerVersion"

if ($RunSmokeTest) {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $examplePath = Join-Path $repoRoot 'examples\hello-cangjie'
    Push-Location $examplePath
    try {
        & cjpm build
        if ($LASTEXITCODE -ne 0) { throw 'cjpm build 失败。' }
        & cjpm run
        if ($LASTEXITCODE -ne 0) { throw 'cjpm run 失败。' }
        & cjpm test --no-color
        if ($LASTEXITCODE -ne 0) { throw 'cjpm test 失败。' }
    }
    finally {
        Pop-Location
    }
    Write-Host '[OK] 编译、运行和测试均通过。'
}
