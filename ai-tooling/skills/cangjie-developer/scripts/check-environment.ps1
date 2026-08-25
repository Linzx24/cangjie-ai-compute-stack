param(
    [string]$SdkRoot = $env:CANGJIE_HOME,
    [string]$ProjectPath,
    [switch]$RunTests
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SdkRoot)) {
    throw "Cangjie SDK not found. Pass -SdkRoot or set CANGJIE_HOME."
}

$resolvedSdk = (Resolve-Path -LiteralPath $SdkRoot).Path
$cjcPath = Join-Path $resolvedSdk "bin\cjc.exe"
$cjpmPath = Join-Path $resolvedSdk "tools\bin\cjpm.exe"
$envSetupPath = Join-Path $resolvedSdk "envsetup.ps1"

if (-not (Test-Path -LiteralPath $cjcPath -PathType Leaf)) {
    throw "cjc.exe not found at $cjcPath"
}
if (-not (Test-Path -LiteralPath $cjpmPath -PathType Leaf)) {
    throw "cjpm.exe not found at $cjpmPath"
}

if (Test-Path -LiteralPath $envSetupPath -PathType Leaf) {
    . $envSetupPath
}
else {
    $runtimeLib = Join-Path $resolvedSdk "runtime\lib\windows_x86_64_cjnative"
    $compilerLib = Join-Path $resolvedSdk "lib\windows_x86_64_cjnative"
    $toolsLib = Join-Path $resolvedSdk "tools\lib"
    $env:PATH = "$toolsLib;$(Split-Path -Parent $cjpmPath);$(Split-Path -Parent $cjcPath);$compilerLib;$runtimeLib;$env:PATH"
    $env:CANGJIE_HOME = $resolvedSdk
}

Write-Output "SDK: $resolvedSdk"
& $cjcPath --version
& $cjpmPath --version

if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
    $resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
    $manifest = Join-Path $resolvedProject "cjpm.toml"
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        throw "cjpm.toml not found in $resolvedProject"
    }

    Push-Location $resolvedProject
    try {
        & $cjpmPath build
        if ($LASTEXITCODE -ne 0) {
            throw "cjpm build failed with exit code $LASTEXITCODE"
        }
        if ($RunTests) {
            & $cjpmPath test --no-color
            if ($LASTEXITCODE -ne 0) {
                throw "cjpm test failed with exit code $LASTEXITCODE"
            }
        }
    }
    finally {
        Pop-Location
    }
}
