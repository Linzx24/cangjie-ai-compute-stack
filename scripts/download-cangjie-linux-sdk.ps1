[CmdletBinding()]
param(
    [string]$Destination = 'docker\sdk\cangjie-sdk-linux-x64-1.1.3.tar.gz'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$destinationPath = Join-Path $repoRoot $Destination
$destinationDirectory = Split-Path -Parent $destinationPath
$expectedSha256 = '2b68905afc466e665ae181595c63f96c18d75fd2c1fb6c6f0cb64e179c28d61a'
$downloadUrl = 'https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.1.3.tar.gz&objectKey=6a19349d21f5a8178d6fd22b'

if (-not (Test-Path -LiteralPath $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
}

if (-not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
    Write-Output '正在从仓颉官方下载 Linux x64 SDK 1.1.3（约 403 MB）……'
    & curl.exe -L --fail --retry 3 --retry-delay 2 --output $destinationPath $downloadUrl
    if ($LASTEXITCODE -ne 0) {
        throw "SDK 下载失败，curl 退出码：$LASTEXITCODE"
    }
}
else {
    Write-Output "SDK 文件已存在，跳过下载：$destinationPath"
}

$actualSha256 = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    throw "SDK SHA-256 不匹配。期望：$expectedSha256，实际：$actualSha256。请不要使用此文件。"
}

$file = Get-Item -LiteralPath $destinationPath
Write-Output "SDK 校验通过：$($file.FullName)"
Write-Output "字节数：$($file.Length)"
Write-Output "SHA-256：$actualSha256"
