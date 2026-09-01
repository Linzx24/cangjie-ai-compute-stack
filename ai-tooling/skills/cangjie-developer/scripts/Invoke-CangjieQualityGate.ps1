[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [ValidateSet('Text','Json')][string]$Format = 'Text',
    [switch]$StrictNumerical,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path -LiteralPath $ProjectPath).Path
$manifest = Join-Path $root 'cjpm.toml'
if (-not (Test-Path -LiteralPath $manifest)) { throw "No cjpm.toml found at $root" }
if (-not (Get-Command cjpm -ErrorAction SilentlyContinue)) { throw 'cjpm is unavailable.' }

$preflightTool = Join-Path $PSScriptRoot 'Invoke-CangjiePreflight.ps1'
$preflightArgs = @{ProjectPath=$root; Format='Json'}
if ($StrictNumerical) { $preflightArgs.StrictNumerical = $true }
$preflight = (& $preflightTool @preflightArgs | Out-String) | ConvertFrom-Json
$buildOutput = ''
$testOutput = ''
$buildExit = $null
$testExit = $null

Push-Location $root
try {
    $global:LASTEXITCODE = 0
    $buildOutput = (& cjpm build 2>&1 | Out-String).Trim()
    $buildExit = $LASTEXITCODE
    if ($buildExit -eq 0 -and -not $SkipTests) {
        $global:LASTEXITCODE = 0
        $testOutput = (& cjpm test --no-color 2>&1 | Out-String).Trim()
        $testExit = $LASTEXITCODE
    }
} finally {
    Pop-Location
}

$passed = $buildExit -eq 0 -and ($SkipTests -or $testExit -eq 0)
$result = [ordered]@{
    schema_version = '1.0'
    project = $root
    passed = $passed
    strict_numerical = [bool]$StrictNumerical
    preflight_finding_count = $preflight.finding_count
    preflight_findings = $preflight.findings
    build_exit = $buildExit
    test_exit = $testExit
    build_output = $buildOutput
    test_output = $testOutput
}

if ($Format -eq 'Json') {
    $result | ConvertTo-Json -Depth 7
} else {
    Write-Output "Cangjie quality gate: strict_numerical=$([bool]$StrictNumerical), preflight=$($preflight.finding_count), build=$buildExit, test=$(if($SkipTests){'skipped'}elseif($null -eq $testExit){'not-run'}else{$testExit})."
    foreach ($finding in $preflight.findings) {
        Write-Output "$($finding.file):$($finding.line) [$($finding.code)] $($finding.message)"
    }
    if ($buildExit -ne 0) { Write-Output $buildOutput }
    elseif (-not $SkipTests -and $testExit -ne 0) { Write-Output $testOutput }
}

if (-not $passed) { exit 1 }
