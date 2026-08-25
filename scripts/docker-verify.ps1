[CmdletBinding()]
param(
    [string]$ImageName = 'cangjie-ai-stack-dev:1.1.3',
    [string]$SdkArchive = 'docker\sdk\cangjie-sdk-linux-x64-1.1.3.tar.gz'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$archivePath = Join-Path $repoRoot $SdkArchive

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw '未找到 Docker。请先安装并启动 Docker Desktop，然后重新运行此脚本。'
}
if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
    throw "缺少 Linux SDK：$archivePath。请从仓颉官方下载中心下载 1.1.3 Linux x64 压缩包并放到这里。"
}

Push-Location $repoRoot
try {
    docker build --file docker/Dockerfile --tag $ImageName .
    if ($LASTEXITCODE -ne 0) {
        throw "docker build 失败，退出码：$LASTEXITCODE"
    }

    docker run --rm --volume "${repoRoot}:/workspace" $ImageName bash /workspace/docker/verify.sh
    if ($LASTEXITCODE -ne 0) {
        throw "Docker/Linux 验证失败，退出码：$LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
