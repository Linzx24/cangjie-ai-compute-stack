[CmdletBinding()]
param(
    [string]$SuitePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "public-suite.json"),
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$suiteRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$rootPrefix = $suiteRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$forbiddenSegments = @(".private-evals", "v17", "v18", "v19", "v20", "v21", "v22", "v23", "hidden", "reference", "private", "formal", "results", "target", "build", "x", "t")
$forbiddenArtifacts = @("target", "build", "x", "t", "cjpm.lock", "*.exe", "*.cjo", "*.a", "*.bc")
$taskNamePattern = '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*$'
$sourcePattern = '^src/[a-z0-9]+(?:[_-][a-z0-9]+)*\.cj$'
$genericRelativePattern = '^[A-Za-z0-9][A-Za-z0-9._-]*(?:/[A-Za-z0-9][A-Za-z0-9._-]*)*$'

function Assert-ExactProperties($Object, [string[]]$Expected, [string]$Label) {
    if ($null -eq $Object) { throw "$Label is missing" }
    $actual = @($Object.PSObject.Properties.Name)
    $missing = @($Expected | Where-Object { $_ -notin $actual })
    $extra = @($actual | Where-Object { $_ -notin $Expected })
    if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
        throw "$Label properties mismatch; missing=[$($missing -join ',')], extra=[$($extra -join ',')]"
    }
}

function Assert-CanonicalRelativePath([string]$RawPath, [string]$Label, [string]$Pattern) {
    if ($null -eq $RawPath -or $RawPath.Length -eq 0) { throw "$Label is empty" }
    if ($RawPath -cne $RawPath.Trim()) { throw "$Label has leading/trailing whitespace: $RawPath" }
    if ($RawPath.Contains('\')) { throw "$Label contains a backslash: $RawPath" }
    if ($RawPath.StartsWith('/')) { throw "$Label is absolute: $RawPath" }
    if ($RawPath -match '^[A-Za-z]:') { throw "$Label has a drive prefix: $RawPath" }
    if ($RawPath.Contains('//')) { throw "$Label has an empty path component: $RawPath" }
    if ($RawPath -match '(^|/)\.(?:/|$)' -or $RawPath -match '(^|/)\.\.(?:/|$)') { throw "$Label has dot component: $RawPath" }
    if ($RawPath -match '[\x00-\x1F\x7F]') { throw "$Label has a control character: $RawPath" }
    if ($RawPath -notmatch $Pattern) { throw "$Label is not canonical: $RawPath" }
}

function Assert-NoForbiddenSegments([string]$RelativePath, [string]$Label) {
    foreach ($segment in ($RelativePath -split '[\\/]')) {
        if ($segment.Length -eq 0) { continue }
        if ($forbiddenSegments -contains $segment.ToLowerInvariant()) { throw "$Label contains forbidden path segment '$segment'" }
    }
}

function Assert-NoReparsePath([string]$Candidate, [string]$Label) {
    if (-not $Candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "$Label escapes suite root: $Candidate" }
    $relative = [IO.Path]::GetRelativePath($suiteRoot, $Candidate)
    $current = $suiteRoot
    foreach ($segment in ($relative -split '[\\/]')) {
        if ($segment.Length -eq 0 -or $segment -eq '.') { continue }
        $current = Join-Path $current $segment
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "ReparsePoint in $Label path: $current" }
        }
    }
}

function Resolve-SafeManifestPath([string]$RawPath, [string]$Label, [string]$Pattern) {
    Assert-CanonicalRelativePath $RawPath $Label $Pattern
    Assert-NoForbiddenSegments $RawPath $Label
    $candidate = [IO.Path]::GetFullPath([IO.Path]::Combine($suiteRoot, $RawPath.Replace('/', [IO.Path]::DirectorySeparatorChar)))
    Assert-NoReparsePath $candidate $Label
    return $candidate
}

function Get-SuiteAggregateHash([string]$ManifestHash, [hashtable]$HashByPath) {
    $orderedPaths = [string[]]@($HashByPath.Keys)
    [Array]::Sort($orderedPaths, [StringComparer]::Ordinal)
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add("manifest-sha256=$($ManifestHash.ToLowerInvariant())")
    foreach ($path in $orderedPaths) { $lines.Add("$path`t$($HashByPath[$path].ToLowerInvariant())") }
    $payload = (($lines -join "`n") + "`n")
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($payload)))).Replace('-', '').ToLowerInvariant() }
    finally { $hasher.Dispose() }
}

function Get-OrdinalSortedStrings([string[]]$Values, [switch]$Descending) {
    $copy = [string[]]@($Values)
    [Array]::Sort($copy, [StringComparer]::Ordinal)
    if ($Descending) { [Array]::Reverse($copy) }
    return $copy
}

function Invoke-MaliciousPathSelfTest {
    $malicious = @("", "../outside", "/absolute", "C:/absolute", "x\..\z", "x//z", "./x", "x/../z")
    $rejected = 0
    foreach ($candidate in $malicious) {
        $accepted = $false
        try { Assert-CanonicalRelativePath $candidate "self-test" $genericRelativePattern; $accepted = $true } catch { $rejected += 1 }
        if ($accepted) { throw "Malicious path accepted: '$candidate'" }
    }
    $ordered = [ordered]@{ alpha = 'beta' }
    if ($ordered.Keys.Count -ne 1 -or [string]$ordered['alpha'] -ne 'beta') { throw 'OrderedDictionary self-test failed.' }
    Write-Output ("V24_PUBLIC_SUITE_SELFTEST_VALID malicious_paths={0}/{1} ordinal_sort=True idictionary=True private_reads=0 hidden_reads=0 model_calls=0" -f $rejected, $malicious.Count)
}

Invoke-MaliciousPathSelfTest
if ($SelfTest) { return }

$suitePathFull = [IO.Path]::GetFullPath($SuitePath)
if (-not $suitePathFull.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "SuitePath escapes v24-suite" }
if ([IO.Path]::GetRelativePath($suiteRoot, $suitePathFull) -ne "public-suite.json") { throw "SuitePath must be public-suite.json" }
Assert-NoReparsePath $suitePathFull "suite manifest"

$schemaPath = Join-Path $suiteRoot "suite.schema.json"
Assert-NoReparsePath $schemaPath "schema"
$schema = Get-Content -Raw -LiteralPath $schemaPath | ConvertFrom-Json
Assert-ExactProperties $schema @('$schema', '$id', 'title', 'type', 'additionalProperties', 'required', 'properties') "suite.schema.json"
if ($schema.type -ne "object" -or $schema.additionalProperties -ne $false) { throw "Schema root must be a closed object" }

$suite = Get-Content -Raw -LiteralPath $suitePathFull | ConvertFrom-Json
Assert-ExactProperties $suite @("id", "version", "schema", "cangjie_version", "target", "cpu_only", "dependencies", "tasks", "integrity") "public-suite.json"
if ($suite.id -ne "cangjie-v24-public" -or $suite.version -ne "24.0" -or $suite.schema -ne "v24-public-1" -or $suite.cangjie_version -ne "1.1.3") { throw "Unexpected suite identity" }
if ($suite.target -ne "cjnative-x86_64-w64-mingw32" -or $suite.cpu_only -ne $true -or @($suite.dependencies).Count -ne 0) { throw "Unexpected target/dependency policy" }
if (@($suite.tasks).Count -ne 4) { throw "Suite must contain exactly four tasks" }

Assert-ExactProperties $suite.integrity @("algorithm", "manifest_hash_scope", "aggregate_algorithm", "aggregate_hash_scope", "files", "boundary_inventory") "integrity"
if ($suite.integrity.algorithm -ne "SHA-256" -or $suite.integrity.manifest_hash_scope -ne "all-v24-files-except-public-suite.json" -or $suite.integrity.aggregate_algorithm -ne "sha256-utf8-lf-v1" -or $suite.integrity.aggregate_hash_scope -ne "manifest-sha256-plus-sorted-ordinal-declared-path-sha256-records") { throw "Unexpected integrity declaration" }
Assert-ExactProperties $suite.integrity.boundary_inventory @("task_count", "replaceable_source_count", "public_test_count", "prompt_count", "script_count", "forbidden_path_segments", "forbidden_artifact_names") "boundary_inventory"
$inventory = $suite.integrity.boundary_inventory
if ($inventory.task_count -ne 4 -or $inventory.replaceable_source_count -ne 4 -or $inventory.public_test_count -ne 16 -or $inventory.prompt_count -ne 4 -or $inventory.script_count -ne 3) { throw "Boundary counts are inconsistent" }
if (@($inventory.forbidden_path_segments) -join '|' -ne ($forbiddenSegments -join '|')) { throw "Forbidden path inventory mismatch" }
if (@($inventory.forbidden_artifact_names) -join '|' -ne ($forbiddenArtifacts -join '|')) { throw "Forbidden artifact inventory mismatch" }

$declaredSourcePaths = [Collections.Generic.List[string]]::new()
$declaredTestPaths = [Collections.Generic.List[string]]::new()
$declaredPromptPaths = [Collections.Generic.List[string]]::new()
$expectedTasks = @("01-windowed-attention", "02-softmax-trainer", "03-event-batch-parser", "04-state-snapshot")
$taskIndex = 0
foreach ($task in @($suite.tasks)) {
    Assert-ExactProperties $task @("id", "path", "prompt", "starter", "project_files", "public_tests", "api_checks") "task"
    if ($task.id -ne $expectedTasks[$taskIndex] -or $task.path -ne $task.id) { throw "Unexpected task identity/order" }
    $taskIndex += 1
    Assert-CanonicalRelativePath $task.id "task.id" $taskNamePattern
    Assert-CanonicalRelativePath $task.path "task.path" $taskNamePattern
    Assert-CanonicalRelativePath $task.prompt "task.prompt" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/public/task\.md$'
    Assert-CanonicalRelativePath $task.starter "task.starter" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/starter$'
    if ($task.prompt -cne "$($task.path)/public/task.md" -or $task.starter -cne "$($task.path)/starter") { throw "Task paths are not rooted at id" }
    $taskRoot = Resolve-SafeManifestPath $task.path "task[$($task.id)]" $taskNamePattern
    $starterRoot = Resolve-SafeManifestPath $task.starter "starter[$($task.id)]" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/starter$'
    $promptPath = Resolve-SafeManifestPath $task.prompt "prompt[$($task.id)]" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/public/task\.md$'
    if (-not (Test-Path -LiteralPath $taskRoot -PathType Container) -or -not (Test-Path -LiteralPath $starterRoot -PathType Container) -or -not (Test-Path -LiteralPath $promptPath -PathType Leaf)) { throw "Missing task/starter/prompt: $($task.id)" }
    $declaredPromptPaths.Add($task.prompt)

    if (@($task.project_files).Count -ne 1) { throw "Task must declare exactly one replaceable source" }
    Assert-CanonicalRelativePath $task.project_files[0] "project_files[$($task.id)]" $sourcePattern
    $sourcePath = Resolve-SafeManifestPath "$($task.starter)/$($task.project_files[0])" "source[$($task.id)]" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/starter/src/[a-z0-9]+(?:[_-][a-z0-9]+)*\.cj$'
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Missing source: $sourcePath" }
    $declaredSourcePaths.Add("$($task.path)/$($task.project_files[0])")

    $starterFiles = Get-OrdinalSortedStrings ([string[]]@(Get-ChildItem -LiteralPath $starterRoot -Recurse -File -Force | ForEach-Object { [IO.Path]::GetRelativePath($starterRoot, $_.FullName).Replace('\', '/') }))
    $expectedStarterFiles = Get-OrdinalSortedStrings ([string[]]@("cjpm.toml", $task.project_files[0]))
    if (($starterFiles -join '|') -cne ($expectedStarterFiles -join '|')) { throw "Starter contains files outside cjpm.toml and the replaceable source: $($task.id)" }

    if (@($task.public_tests).Count -ne 4) { throw "Task must declare four public tests" }
    foreach ($testRelative in @($task.public_tests)) {
        Assert-CanonicalRelativePath $testRelative "public_tests[$($task.id)]" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/tests/public_test_[0-9]{2}\.cj$'
        if (-not $testRelative.StartsWith("$($task.path)/", [StringComparison]::Ordinal)) { throw "Test escapes task" }
        $testPath = Resolve-SafeManifestPath $testRelative "test[$($task.id)]" '^[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/tests/public_test_[0-9]{2}\.cj$'
        if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) { throw "Missing public test: $testRelative" }
        $declaredTestPaths.Add($testRelative)
    }
    if (@($task.api_checks).Count -lt 4) { throw "Task must declare four API checks" }
    foreach ($check in @($task.api_checks)) {
        Assert-ExactProperties $check @("source", "pattern") "api_check[$($task.id)]"
        if ($check.source -cne $task.project_files[0] -or [string]::IsNullOrEmpty([string]$check.pattern)) { throw "API check source/pattern mismatch" }
        $sourceText = Get-Content -Raw -LiteralPath $sourcePath
        if (-not $sourceText.Contains([string]$check.pattern)) { throw "API check failed for $($task.id): $($check.pattern)" }
    }
}

$hashByPath = @{}
foreach ($record in @($suite.integrity.files)) {
    Assert-ExactProperties $record @("path", "sha256", "kind") "integrity file"
    Assert-CanonicalRelativePath $record.path "integrity.files.path" '^(?:[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/(?:public/task\.md|starter/cjpm\.toml|starter/src/[a-z0-9]+(?:[_-][a-z0-9]+)*\.cj|tests/public_test_[0-9]{2}\.cj)|(?:README|COVERAGE|CALIBRATION)\.md|suite\.schema\.json|scripts/[A-Za-z0-9_-]+\.ps1)$'
    Assert-NoForbiddenSegments $record.path "integrity[$($record.path)]"
    if ($hashByPath.ContainsKey($record.path)) { throw "Duplicate integrity path: $($record.path)" }
    if ($record.sha256 -notmatch '^[0-9A-Fa-f]{64}$') { throw "Invalid SHA-256 for $($record.path)" }
    if ($record.kind -notin @("prompt", "config", "source", "public-test", "documentation", "schema", "script")) { throw "Invalid kind" }
    $hashPath = Resolve-SafeManifestPath $record.path "integrity[$($record.path)]" '^(?:[0-9]{2}-[a-z0-9]+(?:-[a-z0-9]+)*/(?:public/task\.md|starter/cjpm\.toml|starter/src/[a-z0-9]+(?:[_-][a-z0-9]+)*\.cj|tests/public_test_[0-9]{2}\.cj)|(?:README|COVERAGE|CALIBRATION)\.md|suite\.schema\.json|scripts/[A-Za-z0-9_-]+\.ps1)$'
    if (-not (Test-Path -LiteralPath $hashPath -PathType Leaf)) { throw "Integrity file missing: $($record.path)" }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $hashPath).Hash.ToUpperInvariant()
    if ($actual -cne $record.sha256.ToUpperInvariant()) { throw "SHA-256 mismatch for $($record.path): expected $($record.sha256), got $actual" }
    $hashByPath[$record.path] = $record.sha256.ToUpperInvariant()
}

$actualFiles = @{}
foreach ($item in Get-ChildItem -LiteralPath $suiteRoot -Recurse -Force) {
    Assert-NoReparsePath $item.FullName "existing component"
    $relative = [IO.Path]::GetRelativePath($suiteRoot, $item.FullName).Replace('\', '/')
    if ($relative -eq '.') { continue }
    Assert-NoForbiddenSegments $relative "existing path $relative"
    if ($item.PSIsContainer -and $item.Name.ToLowerInvariant() -in @("target", "build", "x", "t", "hidden", "reference", "private", "results")) { throw "Forbidden directory exists: $relative" }
    if (-not $item.PSIsContainer) {
        if ($item.Name -eq "cjpm.lock" -or $item.Extension.ToLowerInvariant() -in @(".exe", ".cjo", ".a", ".bc")) { throw "Forbidden build artifact exists: $relative" }
        $actualFiles[$relative] = $true
    }
}
if ($actualFiles.ContainsKey("public-suite.json")) { $actualFiles.Remove("public-suite.json") }
$actualSet = Get-OrdinalSortedStrings ([string[]]@($actualFiles.Keys))
$hashSet = Get-OrdinalSortedStrings ([string[]]@($hashByPath.Keys))
if (($actualSet -join '|') -cne ($hashSet -join '|')) { throw "Integrity file inventory differs from existing public tree" }

$manifestHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $suitePathFull).Hash.ToLowerInvariant()
$aggregate = Get-SuiteAggregateHash $manifestHash $hashByPath
$reverse = @{}
foreach ($path in (Get-OrdinalSortedStrings ([string[]]@($hashByPath.Keys)) -Descending)) { $reverse[$path] = $hashByPath[$path] }
if ($aggregate -cne (Get-SuiteAggregateHash $manifestHash $reverse)) { throw "Aggregate reproducibility self-test failed" }
if (@($declaredSourcePaths).Count -ne $inventory.replaceable_source_count -or @($declaredTestPaths).Count -ne $inventory.public_test_count -or @($declaredPromptPaths).Count -ne $inventory.prompt_count) { throw "Boundary inventory does not match task declarations" }

Write-Output "Schema-equivalent validation: PASS (closed root/schema and canonical path checks)"
Write-Output ("Integrity validation: PASS ({0} SHA-256 records verified; public-suite.json excluded)" -f @($hashByPath.Keys).Count)
Write-Output "Reparse-point and forbidden-artifact validation: PASS"
Write-Output "Suite aggregate self-test: PASS (ordinal sort reproduced from reversed insertion order)"
Write-Output ("Suite aggregate SHA-256: {0}" -f $aggregate)
Write-Output ("Validated v24 public suite: {0} tasks, {1} public tests" -f @($suite.tasks).Count, @($declaredTestPaths).Count)
