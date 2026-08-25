[CmdletBinding()]
param(
    [string]$ImageName = 'cangjie-ai-stack-dev:1.1.3',
    [string]$SdkArchive = 'docker\sdk\cangjie-sdk-linux-x64-1.1.3.tar.gz',
    [string]$ExpectedSdkSha256 = '2b68905afc466e665ae181595c63f96c18d75fd2c1fb6c6f0cb64e179c28d61a'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$archivePath = Join-Path $repoRoot $SdkArchive

if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
    throw "缺少 Linux SDK：$archivePath。请从仓颉官方下载中心下载 1.1.3 Linux x64 压缩包并放到这里。"
}
$actualSdkSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualSdkSha256 -ne $ExpectedSdkSha256.ToLowerInvariant()) {
    throw "Linux SDK SHA-256 不匹配。期望：$ExpectedSdkSha256，实际：$actualSdkSha256。"
}
Write-Output "Linux SDK 校验通过：$actualSdkSha256"
$dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCommand) {
    $dockerExecutable = $dockerCommand.Source
}
else {
    $perUserDocker = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin\docker.exe'
    if (Test-Path -LiteralPath $perUserDocker -PathType Leaf) {
        $dockerExecutable = $perUserDocker
    }
}
if ([string]::IsNullOrWhiteSpace($dockerExecutable)) {
    throw '未找到 Docker。请先安装并启动 Docker Desktop，然后重新运行此脚本。'
}
Write-Output "Docker CLI：$dockerExecutable"

Push-Location $repoRoot
try {
    & $dockerExecutable build --file docker/Dockerfile --tag $ImageName .
    if ($LASTEXITCODE -ne 0) {
        throw "docker build 失败，退出码：$LASTEXITCODE"
    }

    & $dockerExecutable run --rm --volume "${repoRoot}:/workspace" $ImageName bash /workspace/docker/verify.sh
    if ($LASTEXITCODE -ne 0) {
        throw "Docker/Linux 验证失败，退出码：$LASTEXITCODE"
    }
}
finally {
    Pop-Location
}
