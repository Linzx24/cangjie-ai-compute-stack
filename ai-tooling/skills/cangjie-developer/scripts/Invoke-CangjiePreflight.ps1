[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [ValidateSet('Text','Json')][string]$Format = 'Text',
    [switch]$FailOnFindings,
    [switch]$StrictNumerical,
    [ValidateRange(1, 10000)][int]$MaxFindings = 40
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectPath).Path
# Exclude by path component, not by substring. This keeps private/evaluation
# source out of both the scan and any finding excerpts even when the caller
# passes a broad repository root. The inline option makes the rule portable
# across case-sensitive and case-insensitive hosts.
$excluded = '(?i)(?:^|[\\/])(?:target|build|\.git|\.cjpm|\.private-evals|hidden|private|formal-results)(?:[\\/]|$)'
$privateRoot = '(?i)(?:^|[\\/])(?:\.private-evals|hidden|private|formal-results)(?:[\\/]|$)'
if ($root -match $privateRoot) {
    throw "Refusing to scan an excluded private/evaluation directory: $root"
}
$lineRules = @(
    @{Code='CJ101'; Pattern='\.toFloat64\s*\('; Message='Use Float64(value) instead of an invented toFloat64 method.'},
    @{Code='CJ102'; Pattern='\bMath\s*\.'; Message='With std.math.*, call functions such as sqrt(value) directly.'},
    @{Code='CJ103'; Pattern='^\s*import\s+std\.thread(?:\.\*)?\s*$'; Message='The pinned SDK has no std.thread module; spawn and Future need no such import.'},
    @{Code='CJ104'; Pattern='\bself\s*\.'; Message='Use this for the current instance.'},
    @{Code='CJ105'; Pattern='\.append\s*\('; Message='For ArrayList use add(); a fixed Array is filled by index.'},
    @{Code='CJ106'; Pattern='Array\s*<[^>]+>\s*\(\s*[A-Za-z_]\w*(?:\.\w+)?\s*\)'; Message='Array<T> has no one-argument size/copy constructor; allocate with size and repeat, then fill by index.'},
    @{Code='CJ107'; Pattern='\b(?:if|for|while)\s*\([^\r\n{}]*\)\s*(?:throw|return)\b'; Message='Control-flow bodies require braces.'},
    @{Code='CJ108'; Pattern='[A-Za-z0-9_)\]]\s+\?\s+[^?:\r\n]+\s*:\s*[^\r\n]+'; Message='Use a Cangjie if expression instead of a C-style ternary expression.'},
    @{Code='CJ112'; Pattern='\.isFinite\s*\('; Message='Cangjie 1.1.3 has no isFinite() method; reject non-finite values with isNaN() and isInf() according to the contract.'},
    @{Code='CJ113'; Pattern='(?<![A-Za-z0-9_])ln\s*\('; Message='Import std.math.* and use log(value), not ln(value).'},
    @{Code='ML201'; Pattern='(?i)\b(?:cursor|offset|position|start(?:Index)?|page(?:Index)?)\w*\s*\+=\s*[^;\r\n]+'; Message='Loop-carried position grows with +=. Prove the next value remains in every callee valid range; wrap, clamp, or reset at the boundary when the contract requires it.'}
)

$modsPattern = '(?:(?:public|private|protected|internal|static|mut|unsafe|operator|override|open|abstract)\s+)*'
$declarationPrefix = '(?m)(?:(?<=^)|(?<=[{};]))[ \t]*'
$typePattern = $declarationPrefix + '(?<mods>' + $modsPattern + ')(?<kind>class|struct)\s+(?<name>[A-Za-z_]\w*)\b[^;{\r\n]*'
$functionPattern = $declarationPrefix + '(?<mods>' + $modsPattern + ')func\s+(?<name>[A-Za-z_]\w*)\s*(?<generic><[^\r\n{}()]*>)?\s*\((?<params>[^)]{0,2000})\)'
$initializerPattern = $declarationPrefix + '(?<mods>' + $modsPattern + ')init\s*\((?<params>[^)]{0,2000})\)'
$fieldPattern = $declarationPrefix + '(?<mods>' + $modsPattern + ')(?<kind>let|var)\s+(?<name>[A-Za-z_]\w*)\s*:\s*(?<type>[^=\r\n;{}]+)'

function ConvertTo-SanitizedLines {
    param([string[]]$Lines)
    $output = [System.Collections.Generic.List[string]]::new()
    $blockDepth = 0
    $doubleQuote = $false
    $singleQuote = $false
    $tripleQuote = $false
    $escaped = $false
    foreach ($line in $Lines) {
        $builder = [System.Text.StringBuilder]::new($line.Length)
        $i = 0
        while ($i -lt $line.Length) {
            $ch = $line[$i]
            $next = if ($i + 1 -lt $line.Length) { $line[$i + 1] } else { [char]0 }
            $triple = $i + 2 -lt $line.Length -and $line.Substring($i, 3) -eq '"""'
            if ($blockDepth -gt 0) {
                if ($ch -eq '/' -and $next -eq '*') { $blockDepth++; [void]$builder.Append('  '); $i += 2; continue }
                if ($ch -eq '*' -and $next -eq '/') { $blockDepth--; [void]$builder.Append('  '); $i += 2; continue }
                [void]$builder.Append(' '); $i++; continue
            }
            if ($tripleQuote) {
                if ($triple) { [void]$builder.Append('   '); $i += 3; $tripleQuote = $false }
                else { [void]$builder.Append(' '); $i++ }
                continue
            }
            if ($doubleQuote -or $singleQuote) {
                [void]$builder.Append(' ')
                if ($escaped) { $escaped = $false }
                elseif ($ch -eq '\') { $escaped = $true }
                elseif ($doubleQuote -and $ch -eq '"') { $doubleQuote = $false }
                elseif ($singleQuote -and $ch -eq "'") { $singleQuote = $false }
                $i++; continue
            }
            if ($ch -eq '/' -and $next -eq '/') { [void]$builder.Append(' ' * ($line.Length - $i)); $i = $line.Length; continue }
            if ($ch -eq '/' -and $next -eq '*') { $blockDepth++; [void]$builder.Append('  '); $i += 2; continue }
            if ($triple) { $tripleQuote = $true; [void]$builder.Append('   '); $i += 3; continue }
            if ($ch -eq '"') { $doubleQuote = $true; $escaped = $false; [void]$builder.Append(' '); $i++; continue }
            if ($ch -eq "'") { $singleQuote = $true; $escaped = $false; [void]$builder.Append(' '); $i++; continue }
            [void]$builder.Append($ch); $i++
        }
        $output.Add($builder.ToString())
    }
    return $output.ToArray()
}

function Get-BracePairs {
    param([string]$Text)
    $pairs = @{}
    $stack = [System.Collections.Generic.Stack[int]]::new()
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if ($Text[$i] -eq '{') { $stack.Push($i) }
        elseif ($Text[$i] -eq '}' -and $stack.Count -gt 0) { $pairs[$stack.Pop()] = $i }
    }
    return $pairs
}

function Find-OpeningBrace {
    param([string]$Text, [int]$Start, [int]$MaximumDistance = 4000)
    $end = [Math]::Min($Text.Length, $Start + $MaximumDistance)
    for ($i = $Start; $i -lt $end; $i++) {
        if ($Text[$i] -eq '{') { return $i }
        if ($Text[$i] -eq ';') { return -1 }
    }
    return -1
}

function Find-MatchingDelimiter {
    param([string]$Text, [int]$OpenIndex, [char]$OpenCharacter, [char]$CloseCharacter)
    $depth = 0
    for ($i = $OpenIndex; $i -lt $Text.Length; $i++) {
        if ($Text[$i] -eq $OpenCharacter) { $depth++ }
        elseif ($Text[$i] -eq $CloseCharacter) { $depth--; if ($depth -eq 0) { return $i } }
    }
    return -1
}

function Get-LineStarts {
    param([string]$Text)
    $starts = [System.Collections.Generic.List[int]]::new()
    $starts.Add(0)
    for ($i = 0; $i -lt $Text.Length; $i++) { if ($Text[$i] -eq "`n") { $starts.Add($i + 1) } }
    return $starts.ToArray()
}

function Get-LineNumber {
    param([int]$Index, [int[]]$LineStarts)
    $low = 0; $high = $LineStarts.Length - 1
    while ($low -le $high) {
        $middle = [int](($low + $high) / 2)
        if ($LineStarts[$middle] -le $Index) { $low = $middle + 1 } else { $high = $middle - 1 }
    }
    return $high + 1
}

function Get-ContainingBlock {
    param([object[]]$Blocks, [int]$Index)
    $inside = @($Blocks | Where-Object { $_.OpenIndex -lt $Index -and $_.CloseIndex -gt $Index } |
        Sort-Object @{Expression={ $_.CloseIndex - $_.OpenIndex }})
    if ($inside.Count -eq 0) { return $null }
    return $inside[0]
}

function Split-Parameters {
    param([string]$Text)
    if ($Text.Trim().Length -eq 0) { return @() }
    $parts = [System.Collections.Generic.List[string]]::new()
    $start = 0; $round = 0; $square = 0; $angle = 0
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        if ($ch -eq '(') { $round++ }
        elseif ($ch -eq ')' -and $round -gt 0) { $round-- }
        elseif ($ch -eq '[') { $square++ }
        elseif ($ch -eq ']' -and $square -gt 0) { $square-- }
        elseif ($ch -eq '<') { $angle++ }
        elseif ($ch -eq '>' -and $angle -gt 0) { $angle-- }
        elseif ($ch -eq ',' -and $round -eq 0 -and $square -eq 0 -and $angle -eq 0) {
            $parts.Add($Text.Substring($start, $i - $start)); $start = $i + 1
        }
    }
    $parts.Add($Text.Substring($start))
    return $parts.ToArray()
}

function Get-Parameters {
    param([string]$Text)
    $result = [System.Collections.Generic.List[object]]::new()
    foreach ($part in @(Split-Parameters -Text $Text)) {
        $match = [regex]::Match($part, '^\s*(?:(?:named|inout|mut)\s+)*(?<name>[A-Za-z_]\w*)\s*:\s*(?<type>.+?)\s*(?:=.+)?$')
        if ($match.Success) {
            $type = ($match.Groups['type'].Value -replace '\s*=.*$', '').Trim()
            $result.Add([pscustomobject]@{ Name=$match.Groups['name'].Value; Type=$type; NormalizedType=($type -replace '\s+','') })
        }
    }
    return $result.ToArray()
}

function Get-NormalizedSignature {
    param([object]$Declaration)
    $types = [System.Collections.Generic.List[string]]::new()
    $parameters = @(Get-Parameters -Text $Declaration.Parameters)
    if ($parameters.Count -gt 0 -or $Declaration.Parameters.Trim().Length -eq 0) {
        foreach ($parameter in $parameters) { $types.Add($parameter.NormalizedType) }
    } else {
        foreach ($part in @(Split-Parameters -Text $Declaration.Parameters)) { $types.Add(($part -replace '\s+','')) }
    }
    $generic = $Declaration.Generic -replace '\s+',''
    return "$($Declaration.Name)$generic($([string]::Join(',', $types.ToArray())))"
}

function Get-ThrowGuards {
    param([string]$Body)
    $guards = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($Body, '\bif\s*\(')) {
        $openParen = $Body.IndexOf('(', $match.Index)
        $closeParen = Find-MatchingDelimiter -Text $Body -OpenIndex $openParen -OpenCharacter '(' -CloseCharacter ')'
        if ($closeParen -lt 0) { continue }
        $openBrace = $closeParen + 1
        while ($openBrace -lt $Body.Length -and [char]::IsWhiteSpace($Body[$openBrace])) { $openBrace++ }
        if ($openBrace -ge $Body.Length -or $Body[$openBrace] -ne '{') { continue }
        $closeBrace = Find-MatchingDelimiter -Text $Body -OpenIndex $openBrace -OpenCharacter '{' -CloseCharacter '}'
        if ($closeBrace -lt 0) { continue }
        $block = $Body.Substring($openBrace, $closeBrace - $openBrace + 1)
        if ($block -notmatch '\bthrow\s+IllegalArgumentException\s*\(') { continue }
        $guards.Add([pscustomobject]@{
            Index=$match.Index
            Condition=$Body.Substring($openParen + 1, $closeParen - $openParen - 1)
            Block=$block
        })
    }
    return $guards.ToArray()
}

function Test-HelperValidation {
    param([string]$Body, [string]$Name, [int]$BeforeIndex=[int]::MaxValue)
    $escaped = [regex]::Escape($Name)
    # Accept obvious finite/valid helper predicates in addition to
    # validate/require/check naming.
    $pattern = '(?i)\b(?:validate|require|check|finite|valid|[A-Za-z_]\w*(?:finite|valid))\w*\s*\([^)]*\b' + $escaped + '\b'
    foreach ($match in [regex]::Matches($Body, $pattern)) { if ($match.Index -lt $BeforeIndex) { return $true } }
    return $false
}

function Test-ArrayElementValidation {
    param([string]$Body, [string]$Name, [int]$BeforeIndex)
    if (Test-HelperValidation -Body $Body -Name $Name -BeforeIndex $BeforeIndex) { return $true }
    $escaped = [regex]::Escape($Name)
    $guards = @(Get-ThrowGuards -Body $Body)
    foreach ($guard in $guards) {
        if ($guard.Index -lt $BeforeIndex -and $guard.Condition -match ('\b' + $escaped + '\s*\[')) { return $true }
    }
    foreach ($assignment in [regex]::Matches($Body, '(?m)\b(?:let|var)\s+(?<alias>[A-Za-z_]\w*)\s*=\s*' + $escaped + '\s*\[[^\]\r\n]+\]')) {
        if ($assignment.Index -ge $BeforeIndex) { continue }
        $alias = [regex]::Escape($assignment.Groups['alias'].Value)
        foreach ($guard in $guards) {
            if ($guard.Index -gt $assignment.Index -and $guard.Index -lt $BeforeIndex -and
                $guard.Condition -match ('\b' + $alias + '\b\s*(?:<=|>=|<|>|==|!=)|\b' + $alias + '\s*\.\s*(?:isNaN|isInf)\s*\(')) { return $true }
        }
    }
    $foreachPattern = '\bfor\s*\(\s*(?<item>[A-Za-z_]\w*)\s+in\s+' + $escaped + '\s*\)'
    foreach ($match in [regex]::Matches($Body, $foreachPattern)) {
        if ($match.Index -ge $BeforeIndex) { continue }
        $openBrace = $Body.IndexOf('{', $match.Index + $match.Length)
        if ($openBrace -lt 0 -or $openBrace -ge $BeforeIndex) { continue }
        $closeBrace = Find-MatchingDelimiter -Text $Body -OpenIndex $openBrace -OpenCharacter '{' -CloseCharacter '}'
        if ($closeBrace -lt 0) { continue }
        $block = $Body.Substring($openBrace, $closeBrace - $openBrace + 1)
        $item = [regex]::Escape($match.Groups['item'].Value)
        if ($block -match '\bthrow\s+IllegalArgumentException\s*\(' -and
            $block -match ('\b' + $item + '\b\s*(?:<=|>=|<|>|==|!=)|\b' + $item + '\s*\.\s*(?:isNaN|isInf)\s*\(')) { return $true }
    }
    return $false
}

function Test-NumericArrayType {
    param([string]$Type)
    $normalized = $Type -replace '\s+',''
    return $normalized -eq 'Array<Float64>' -or $normalized -eq 'Array<Array<Float64>>'
}

function Test-ShapeOverflowGuard {
    param([string]$Body, [int]$BeforeIndex, [string]$Left, [string]$Right)
    if ($BeforeIndex -le 0) { return $false }
    $prefix = $Body.Substring(0, $BeforeIndex)
    $leftEscaped = [regex]::Escape($Left)
    $rightEscaped = [regex]::Escape($Right)
    $guards = @(Get-ThrowGuards -Body $prefix)
    $conditions = [string]::Join(' || ', @($guards | ForEach-Object { $_.Condition }))
    foreach ($guard in $guards) {
        $condition = $guard.Condition
        $leftPositive = $condition -match ('(?i)\b' + $leftEscaped + '\s*(?:<=\s*0|<\s*1)\b|\b0\s*(?:>=|>)\s*' + $leftEscaped + '\b')
        $rightPositive = $condition -match ('(?i)\b' + $rightEscaped + '\s*(?:<=\s*0|<\s*1)\b|\b0\s*(?:>=|>)\s*' + $rightEscaped + '\b')
        $leftBounded = $condition -match ('(?i)\b' + $leftEscaped + '\s*>\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*/\s*' + $rightEscaped + '\b')
        $rightBounded = $condition -match ('(?i)\b' + $rightEscaped + '\s*>\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*/\s*' + $leftEscaped + '\b')
        if ($leftPositive -and $rightPositive -and ($leftBounded -or $rightBounded)) { return $true }
    }
    # Allow separate throw guards for positivity and the division upper bound.
    # The aggregate is still restricted to guards that throw before the product.
    $leftPositive = $conditions -match ('(?i)\b' + $leftEscaped + '\s*(?:<=\s*0|<\s*1)\b|\b0\s*(?:>=|>)\s*' + $leftEscaped + '\b')
    $rightPositive = $conditions -match ('(?i)\b' + $rightEscaped + '\s*(?:<=\s*0|<\s*1)\b|\b0\s*(?:>=|>)\s*' + $rightEscaped + '\b')
    $leftBounded = $conditions -match ('(?i)\b' + $leftEscaped + '\s*>\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*/\s*' + $rightEscaped + '\b')
    $rightBounded = $conditions -match ('(?i)\b' + $rightEscaped + '\s*>\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*/\s*' + $leftEscaped + '\b')
    if ($leftPositive -and $rightPositive -and ($leftBounded -or $rightBounded)) { return $true }
    # Trust a named shape helper only when this call visibly receives both
    # operands. An unrelated checkSomething() must not suppress the finding.
    foreach ($helper in [regex]::Matches($prefix, '(?i)\b(?:validate|require|check)\w*\s*\([^)]*\)')) {
        $mentionsLeft = $helper.Value -match ('(?<![A-Za-z0-9_])' + $leftEscaped + '(?![A-Za-z0-9_])')
        $mentionsRight = $helper.Value -match ('(?<![A-Za-z0-9_])' + $rightEscaped + '(?![A-Za-z0-9_])')
        if ($mentionsLeft -and $mentionsRight) { return $true }
    }
    return $false
}

function Get-GradientAssignments {
    param([string]$Body)
    # Include the common private storage names used by reverse-mode helpers.
    # Qualified targets (for example parent.gradientTensor) are retained so
    # repeated writes to one slot remain distinguishable.
    $slot = '(?:grad(?:ient)?(?:s|Tensor|Values|Data|Buffer|Array)?|adjoints?|derivatives?)'
    $target = '(?<![A-Za-z0-9_])(?:this\s*\.\s*)?(?:[A-Za-z_]\w*\s*\.\s*)?' + $slot + '(?:\s*\[[^\]\r\n]+\])?(?![A-Za-z0-9_])'
    $pattern = '(?im)(?<target>' + $target + ')\s*(?<op>\+=|-=|\*=|/=|=(?!=))\s*(?<rhs>[^\r\n;}]*)'
    return @([regex]::Matches($Body, $pattern))
}

function Get-GradientTargetKey {
    param([string]$Target)
    return (($Target -replace '\s+','') -replace '^this\.','')
}

function Test-GradientWriteReadsOldValue {
    param([object]$Assignment)
    if ($Assignment.Groups['op'].Value -ne '=') { return $true }
    $target = Get-GradientTargetKey -Target $Assignment.Groups['target'].Value
    $rhs = ($Assignment.Groups['rhs'].Value -replace '\s+','') -replace '^this\.',''
    if ($target.Length -eq 0) { return $false }
    return $rhs -match ('(?<![A-Za-z0-9_])' + [regex]::Escape($target) + '(?![A-Za-z0-9_])')
}

function Get-OuterArrayNames {
    param([string]$Body, [int]$BeforeIndex, [object]$ContainingType, [object[]]$Fields, [object[]]$Parameters)
    $names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $prefix = if ($BeforeIndex -gt 0) { $Body.Substring(0, $BeforeIndex) } else { '' }
    # Only names whose numeric Array type is visible at this call site are
    # reported. An unknown helper's return type is intentionally not guessed.
    foreach ($match in [regex]::Matches($prefix, '(?im)\b(?:let|var)\s+(?<name>[A-Za-z_]\w*)\s*(?::\s*Array\s*<\s*(?:Float64|Array\s*<\s*Float64\s*>)\s*>\s*)?=\s*Array\s*<\s*(?:Float64|Array\s*<\s*Float64\s*>)')) {
        [void]$names.Add($match.Groups['name'].Value)
    }
    if ($null -ne $ContainingType) {
        foreach ($field in @($Fields | Where-Object { $_.ContainingType -eq $ContainingType -and (Test-NumericArrayType -Type $_.NormalizedType) })) {
            [void]$names.Add($field.Name)
        }
    }
    foreach ($parameter in @($Parameters | Where-Object { Test-NumericArrayType -Type $_.NormalizedType })) {
        [void]$names.Add($parameter.Name)
    }
    return $names
}

function Get-StateMutation {
    param([string]$Body, [object]$ContainingType, [object[]]$Fields, [object[]]$Parameters)
    $patterns = [System.Collections.Generic.List[string]]::new()
    $receiverNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    if ($null -ne $ContainingType) {
        foreach ($field in @($Fields | Where-Object { $_.ContainingType -eq $ContainingType })) {
            [void]$receiverNames.Add($field.Name)
        }
    }
    foreach ($parameter in @($Parameters)) { [void]$receiverNames.Add($parameter.Name) }
    # A loop item is a determinable receiver when it iterates a parameter
    # collection (for example parameter in parameters).
    foreach ($parameter in @($Parameters | Where-Object { $_.NormalizedType -match '^Array<' })) {
        $collection = [regex]::Escape($parameter.Name)
        foreach ($match in [regex]::Matches($Body, '(?im)\bfor\s*\(\s*(?<item>[A-Za-z_]\w*)\s+in\s+' + $collection + '\b')) {
            [void]$receiverNames.Add($match.Groups['item'].Value)
        }
    }
    foreach ($name in $receiverNames) {
        $escaped = [regex]::Escape($name)
        # Direct receiver/parameter assignment, including compound updates and
        # indexed numeric-array writes.
        [void]$patterns.Add('(?im)(?:\bthis\s*\.\s*)?' + $escaped + '(?:\s*\[[^\]\r\n]+\])*\s*(?:\+=|-=|\*=|/=|=(?!=))')
        # Common mutating submission methods. Unknown helper semantics are not
        # inferred; only an explicitly named set/replace/apply call is used.
        [void]$patterns.Add('(?im)(?:\bthis\s*\.\s*)?' + $escaped + '(?:\s*\[[^\]\r\n]+\])*\s*\.\s*(?:set|replace|apply)\w*\s*\(')
    }
    # Methods on the receiver itself are also state commits, but unqualified
    # local helper calls are intentionally left alone to keep noise low.
    [void]$patterns.Add('(?im)\bthis\s*\.\s*(?:set|replace|apply|commit|restore)\w*\s*\(')
    $matches = [System.Collections.Generic.List[object]]::new()
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Body, $pattern)) {
            $matches.Add([pscustomobject]@{ Index=$match.Index; Length=$match.Length; Text=$match.Value })
        }
    }
    return @($matches.ToArray() | Sort-Object Index, Length)
}

$rawFindings = [System.Collections.Generic.List[object]]::new()
$findingKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
function Add-Finding {
    param([string]$Code, [object]$FileInfo, [int]$Line, [string]$Message, [string]$UniqueKey)
    $key = if ($UniqueKey.Length -gt 0) { $UniqueKey } else { "$Code|$($FileInfo.RelativePath)|$Line" }
    if (-not $findingKeys.Add($key)) { return }
    $excerpt = if ($Line -ge 1 -and $Line -le $FileInfo.RawLines.Length) { $FileInfo.RawLines[$Line - 1].Trim() } else { '' }
    $rawFindings.Add([pscustomobject]@{ code=$Code; file=$FileInfo.RelativePath; line=$Line; message=$Message; excerpt=$excerpt })
}

$sourceFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.cj' |
    Where-Object {
        $relativeCandidate = $_.FullName.Substring($root.Length).TrimStart([char[]]@('\','/'))
        $relativeCandidate -notmatch $excluded
    } | Sort-Object FullName)
$fileInfos = [System.Collections.Generic.List[object]]::new()

foreach ($file in $sourceFiles) {
    $rawLines = [System.IO.File]::ReadAllLines($file.FullName)
    $sanitized = @(ConvertTo-SanitizedLines -Lines $rawLines)
    $text = [string]::Join("`n", $sanitized)
    $lineStarts = @(Get-LineStarts -Text $text)
    $pairs = Get-BracePairs -Text $text
    $relative = $file.FullName.Substring($root.Length).TrimStart([char[]]@('\','/')).Replace('\','/')
    $packageMatch = [regex]::Match($text, '(?m)^[ \t]*package\s+([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)')
    $package = if ($packageMatch.Success) { $packageMatch.Groups[1].Value } else { '' }

    $types = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($text, $typePattern)) {
        $open = Find-OpeningBrace -Text $text -Start ($match.Index + $match.Length)
        if ($open -lt 0 -or -not $pairs.ContainsKey($open)) { continue }
        $types.Add([pscustomobject]@{ Kind=$match.Groups['kind'].Value; Name=$match.Groups['name'].Value; MatchIndex=$match.Index; OpenIndex=$open; CloseIndex=[int]$pairs[$open]; Line=(Get-LineNumber -Index $match.Index -LineStarts $lineStarts) })
    }

    $functions = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($text, $functionPattern)) {
        $open = Find-OpeningBrace -Text $text -Start ($match.Index + $match.Length)
        if ($open -lt 0 -or -not $pairs.ContainsKey($open)) { continue }
        $mods = $match.Groups['mods'].Value
        $returnType = ''
        $tailStart = $match.Index + $match.Length
        if ($open -gt $tailStart) {
            $tail = $text.Substring($tailStart, $open - $tailStart)
            $returnMatch = [regex]::Match($tail, ':\s*(?<type>[A-Za-z_]\w*(?:\s*<[^>{}]+>)?(?:\s*\[\])?)\s*$')
            if ($returnMatch.Success) { $returnType = $returnMatch.Groups['type'].Value.Trim() }
        }
        $functions.Add([pscustomobject]@{
            Kind='func'; Name=$match.Groups['name'].Value; Generic=$match.Groups['generic'].Value; Parameters=$match.Groups['params'].Value
            Mods=$mods; IsPublic=($mods -match '(?:^|\s)public(?:\s|$)'); IsMut=($mods -match '(?:^|\s)mut(?:\s|$)')
            ReturnType=$returnType; ReturnTypeNormalized=($returnType -replace '\s+','')
            MatchIndex=$match.Index; OpenIndex=$open; CloseIndex=[int]$pairs[$open]; Line=(Get-LineNumber -Index $match.Index -LineStarts $lineStarts)
            Body=$text.Substring($open, [int]$pairs[$open] - $open + 1); ContainingType=$null; ContainingCallable=$null
        })
    }

    $initializers = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($text, $initializerPattern)) {
        $open = Find-OpeningBrace -Text $text -Start ($match.Index + $match.Length)
        if ($open -lt 0 -or -not $pairs.ContainsKey($open)) { continue }
        $mods = $match.Groups['mods'].Value
        $initializers.Add([pscustomobject]@{
            Kind='init'; Name='init'; Generic=''; Parameters=$match.Groups['params'].Value; Mods=$mods
            ReturnType=''; ReturnTypeNormalized=''
            IsPublic=($mods -match '(?:^|\s)public(?:\s|$)'); IsMut=$false; MatchIndex=$match.Index; OpenIndex=$open; CloseIndex=[int]$pairs[$open]
            Line=(Get-LineNumber -Index $match.Index -LineStarts $lineStarts); Body=$text.Substring($open, [int]$pairs[$open] - $open + 1)
            ContainingType=$null; ContainingCallable=$null
        })
    }
    $callables = @($functions.ToArray()) + @($initializers.ToArray())
    foreach ($callable in $callables) {
        $callable.ContainingType = Get-ContainingBlock -Blocks $types.ToArray() -Index $callable.MatchIndex
        $callable.ContainingCallable = Get-ContainingBlock -Blocks @($callables | Where-Object { $_ -ne $callable }) -Index $callable.MatchIndex
    }

    $fields = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches($text, $fieldPattern)) {
        $type = Get-ContainingBlock -Blocks $types.ToArray() -Index $match.Index
        $callable = Get-ContainingBlock -Blocks $callables -Index $match.Index
        if ($null -eq $type -or $null -ne $callable) { continue }
        $fieldType = $match.Groups['type'].Value.Trim()
        $fields.Add([pscustomobject]@{
            Name=$match.Groups['name'].Value; Kind=$match.Groups['kind'].Value; Type=$fieldType
            NormalizedType=($fieldType -replace '\s+',''); MatchIndex=$match.Index
            Line=(Get-LineNumber -Index $match.Index -LineStarts $lineStarts); ContainingType=$type
        })
    }

    $info = [pscustomobject]@{
        FullName=$file.FullName; RelativePath=$relative; Package=$package; RawLines=$rawLines; SanitizedLines=$sanitized; ScanText=$text; LineStarts=$lineStarts
        Types=$types.ToArray(); Functions=$functions.ToArray(); Initializers=$initializers.ToArray(); Callables=$callables; Fields=$fields.ToArray()
        IsTestFile=($relative -match '(?i)(^|/)(?:test|tests)/|_test\.cj$')
    }
    $fileInfos.Add($info)
    for ($lineIndex = 0; $lineIndex -lt $sanitized.Length; $lineIndex++) {
        foreach ($rule in $lineRules) {
            if ([regex]::IsMatch($sanitized[$lineIndex], $rule.Pattern)) {
                Add-Finding -Code $rule.Code -FileInfo $info -Line ($lineIndex + 1) -Message $rule.Message -UniqueKey "$($rule.Code)|$relative|$($lineIndex + 1)"
            }
        }
    }
}

foreach ($info in $fileInfos) {
    $firstMathCallLine = $null
    for ($lineIndex = 0; $lineIndex -lt $info.SanitizedLines.Length; $lineIndex++) {
        $line = $info.SanitizedLines[$lineIndex]
        if ($line -notmatch '(?<![A-Za-z0-9_.])(?:sqrt|exp|log|pow)\s*\(') { continue }
        if ($line -match '\bfunc\s+(?:sqrt|exp|log|pow)\s*\(') { continue }
        $firstMathCallLine = $lineIndex + 1
        break
    }
    if ($null -eq $firstMathCallLine) { continue }
    $hasMathImport = @($info.SanitizedLines | Where-Object { $_ -match '^\s*import\s+std\.math\.\*\s*$' }).Count -gt 0
    if (-not $hasMathImport) {
        Add-Finding -Code 'CJ114' -FileInfo $info -Line $firstMathCallLine -Message 'This file calls sqrt, exp, log, or pow without importing std.math.*.' -UniqueKey "CJ114|$($info.RelativePath)"
    }
}

$firstSignatures = [System.Collections.Generic.Dictionary[string,object]]::new([System.StringComparer]::Ordinal)
foreach ($info in @($fileInfos.ToArray() | Sort-Object RelativePath)) {
    foreach ($function in @($info.Functions | Sort-Object Line)) {
        if ($null -ne $function.ContainingType -or $null -ne $function.ContainingCallable) { continue }
        $signature = Get-NormalizedSignature -Declaration $function
        $key = "$($info.Package)|$signature"
        if ($firstSignatures.ContainsKey($key)) {
            $first = $firstSignatures[$key]
            Add-Finding -Code 'CJ109' -FileInfo $info -Line $function.Line -Message "Top-level function '$signature' duplicates the same package signature first declared at $($first.File):$($first.Line). Rename or reuse one helper." -UniqueKey "CJ109|$key|$($info.RelativePath)|$($function.Line)"
        } else { $firstSignatures[$key] = [pscustomobject]@{ File=$info.RelativePath; Line=$function.Line } }
    }
}

foreach ($info in $fileInfos) {
    foreach ($type in $info.Types) {
        $fields = @($info.Fields | Where-Object { $_.ContainingType -eq $type })
        $methods = @($info.Functions | Where-Object { $_.ContainingType -eq $type -and $null -eq $_.ContainingCallable })
        foreach ($field in $fields) {
            foreach ($method in @($methods | Where-Object { $_.Name -ceq $field.Name })) {
                $later = if ($field.MatchIndex -gt $method.MatchIndex) { $field } else { $method }
                Add-Finding -Code 'CJ110' -FileInfo $info -Line $later.Line -Message "Type '$($type.Name)' declares both a field and a method named '$($field.Name)'. Rename the private storage member." -UniqueKey "CJ110|$($info.RelativePath)|$($type.MatchIndex)|$($field.Name)"
            }
        }
        if ($type.Kind -eq 'class') {
            foreach ($method in @($methods | Where-Object { $_.IsMut })) {
                Add-Finding -Code 'CJ111' -FileInfo $info -Line $method.Line -Message "Class method '$($method.Name)' must not be declared mut; mut func is for a field-mutating struct method." -UniqueKey "CJ111|$($info.RelativePath)|$($type.MatchIndex)|$($method.MatchIndex)"
            }
        }
    }

    if (-not $StrictNumerical -or $info.IsTestFile) { continue }
    foreach ($callable in $info.Callables) {
        if ($null -ne $callable.ContainingCallable) { continue }
        $parameters = @(Get-Parameters -Text $callable.Parameters)
        $guards = @(Get-ThrowGuards -Body $callable.Body)
        $containingFields = @()
        if ($null -ne $callable.ContainingType) {
            $containingFields = @($info.Fields | Where-Object { $_.ContainingType -eq $callable.ContainingType })
        }

        # Public-boundary checks use the visibility parsed from the
        # declaration. Lifecycle and worker checks below intentionally also
        # inspect private/internal helpers.
        if ($callable.IsPublic) {
        foreach ($parameter in @($parameters | Where-Object { $_.NormalizedType -eq 'Float64' })) {
            $name = [regex]::Escape($parameter.Name)
            $ordered = '(?<![A-Za-z0-9_])' + $name + '\s*(?:<=|>=|<|>)|(?:<=|>=|<|>)\s*' + $name + '(?![A-Za-z0-9_])'
            if (@($guards | Where-Object { $_.Condition -match $ordered }).Count -eq 0) { continue }
            $safe = '\b' + $name + '\s*\.\s*isNaN\s*\(|\b' + $name + '\s*!=\s*' + $name + '\b|!\s*\(\s*' + $name + '\s*(?:>|>=|<|<=)'
            if ($callable.Body -match $safe -or (Test-HelperValidation -Body $callable.Body -Name $parameter.Name)) { continue }
            Add-Finding -Code 'ML202' -FileInfo $info -Line $callable.Line -Message "Ordered Float64 validation for '$($parameter.Name)' lets NaN bypass the guard. Use $($parameter.Name).isNaN(); when the contract requires a finite value, also use $($parameter.Name).isInf(), or use an equivalent NaN-safe predicate." -UniqueKey "ML202|$($info.RelativePath)|$($callable.MatchIndex)|$($parameter.Name)"
        }

        foreach ($parameter in @($parameters | Where-Object { $_.NormalizedType -eq 'Array<Float64>' })) {
            $name = [regex]::Escape($parameter.Name)
            $uses = [System.Collections.Generic.List[int]]::new()
            foreach ($match in [regex]::Matches($callable.Body, '(?<!/)/(?!/)\s*(?:=\s*)?' + $name + '\s*\[')) { $uses.Add($match.Index) }
            foreach ($assignment in [regex]::Matches($callable.Body, '(?m)\b(?:let|var)\s+(?<alias>[A-Za-z_]\w*)\s*=\s*' + $name + '\s*\[[^\]\r\n]+\]')) {
                $alias = [regex]::Escape($assignment.Groups['alias'].Value)
                foreach ($use in [regex]::Matches($callable.Body, '(?<!/)/(?!/)\s*(?:=\s*)?' + $alias + '\b')) { if ($use.Index -gt $assignment.Index) { $uses.Add($use.Index) } }
            }
            if ($uses.Count -eq 0) { continue }
            $firstUse = @($uses.ToArray() | Sort-Object)[0]
            if (Test-ArrayElementValidation -Body $callable.Body -Name $parameter.Name -BeforeIndex $firstUse) { continue }
            $line = Get-LineNumber -Index ($callable.OpenIndex + $firstUse) -LineStarts $info.LineStarts
            Add-Finding -Code 'ML203' -FileInfo $info -Line $line -Message "External Float64 array '$($parameter.Name)' is used as a divisor without visible element validation before the first division. Validate every denominator before numerical work." -UniqueKey "ML203|$($info.RelativePath)|$($callable.MatchIndex)|$($parameter.Name)"
        }

        $isMethod = $null -ne $callable.ContainingType -and $callable.Kind -eq 'func'
        if ($isMethod -and ($callable.Name -match '(?i)(?:at|get|set|item|element|index|sequence|path|row|column|length)' -or
            $callable.Body -match '\breturn\s+[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*\[[^\]]+\]')) {
            $missing = [System.Collections.Generic.List[string]]::new()
            foreach ($parameter in @($parameters | Where-Object { $_.NormalizedType -eq 'Int64' })) {
                $name = [regex]::Escape($parameter.Name)
                $subscripts = @([regex]::Matches($callable.Body, '\[[^\]\r\n]*\b' + $name + '\b[^\]\r\n]*\]'))
                if ($subscripts.Count -eq 0) { continue }
                $firstUse = @($subscripts | Sort-Object Index)[0].Index
                if (Test-HelperValidation -Body $callable.Body -Name $parameter.Name -BeforeIndex $firstUse) { continue }
                $conditions = [string]::Join(' ', @($guards | Where-Object { $_.Index -lt $firstUse } | ForEach-Object { $_.Condition }))
                $lower = $conditions -match ('\b' + $name + '\s*<\s*0\b|\b0\s*>\s*' + $name + '\b')
                $upper = $conditions -match ('\b' + $name + '\s*>=\s*[^|&\r\n)]+|[^|&\r\n(]+<=\s*' + $name + '\b')
                $negated = $conditions -match ('!\s*\([^)]*\b' + $name + '\s*>=\s*0\b[^)]*&&[^)]*\b' + $name + '\s*<')
                if (-not (($lower -and $upper) -or $negated)) { $missing.Add($parameter.Name) }
            }
            if ($missing.Count -gt 0) {
                Add-Finding -Code 'ML204' -FileInfo $info -Line $callable.Line -Message "Public accessor '$($callable.Name)' directly indexes with parameter(s) $([string]::Join(', ', $missing.ToArray())) without visible lower and upper IllegalArgumentException guards." -UniqueKey "ML204|$($info.RelativePath)|$($callable.MatchIndex)"
            }
        }

        $topLevel = $null -eq $callable.ContainingType -and $null -eq $callable.ContainingCallable -and $callable.Kind -eq 'func'
        if ($topLevel -and $callable.Name -match '(?i)(?:train|fit|learn|optimi[sz]e|run|process|decode|pipeline|workflow|update)') {
            foreach ($parameter in @($parameters | Where-Object { $_.NormalizedType -eq 'Int64' -and $_.Name -match '(?i)^(?:iterations?|steps?|epochs?|rounds?|updates?|passes?)$' })) {
                $name = [regex]::Escape($parameter.Name)
                $loop = [regex]::Match($callable.Body, '\bfor\s*\([^)]*\bin\s+0\s*\.\.\s*' + $name + '\b')
                if (-not $loop.Success -or (Test-HelperValidation -Body $callable.Body -Name $parameter.Name -BeforeIndex $loop.Index)) { continue }
                $positive = '\b' + $name + '\s*<=\s*0\b|\b' + $name + '\s*==\s*0\b|\b' + $name + '\s*<\s*1\b|!\s*\(\s*' + $name + '\s*>\s*0\s*\)'
                if (@($guards | Where-Object { $_.Index -lt $loop.Index -and $_.Condition -match $positive }).Count -gt 0) { continue }
                Add-Finding -Code 'ML205' -FileInfo $info -Line $callable.Line -Message "Top-level workflow '$($callable.Name)' can execute its '$($parameter.Name)' loop zero times. Check whether zero is valid under the public contract and validate loop-only parameters before the loop." -UniqueKey "ML205|$($info.RelativePath)|$($callable.MatchIndex)|$($parameter.Name)"
            }
        }

        # ML206: a public tensor/parameter boundary directly aliases a mutable
        # numeric array. This deliberately uses parsed fields and parameters;
        # arbitrary local arrays and documented views are outside the rule.
        if ($callable.Kind -eq 'init' -and $callable.IsPublic -and $null -ne $callable.ContainingType) {
            foreach ($field in @($containingFields | Where-Object { $_.Kind -eq 'var' -and (Test-NumericArrayType -Type $_.NormalizedType) })) {
                foreach ($parameter in @($parameters | Where-Object { $_.NormalizedType -eq $field.NormalizedType })) {
                    $fieldName = [regex]::Escape($field.Name)
                    $parameterName = [regex]::Escape($parameter.Name)
                    $assignmentPattern = '(?im)(?:^|[;{}])\s*(?:this\s*\.\s*)?' + $fieldName + '\s*=\s*' + $parameterName + '\s*(?:;|$)'
                    $assignment = [regex]::Match($callable.Body, $assignmentPattern)
                    if (-not $assignment.Success) { continue }
                    $line = Get-LineNumber -Index ($callable.OpenIndex + $assignment.Index) -LineStarts $info.LineStarts
                    Add-Finding -Code 'ML206' -FileInfo $info -Line $line -Message "Public initializer aliases numeric array parameter '$($parameter.Name)' into mutable field '$($field.Name)'. Copy the array before storing it." -UniqueKey "ML206|$($info.RelativePath)|$($callable.MatchIndex)|$($field.Name)|$($parameter.Name)"
                }
            }
        }
        if ($callable.Kind -eq 'func' -and $callable.IsPublic -and $parameters.Count -eq 0 -and
            (Test-NumericArrayType -Type $callable.ReturnTypeNormalized) -and $callable.Name -notmatch '(?i)^(?:unsafe)?view$') {
            foreach ($field in @($containingFields | Where-Object { Test-NumericArrayType -Type $_.NormalizedType })) {
                $fieldName = [regex]::Escape($field.Name)
                $returnPattern = '(?im)\breturn\s+(?:this\s*\.\s*)?' + $fieldName + '\s*(?:;|$)'
                $returnMatch = [regex]::Match($callable.Body, $returnPattern)
                if (-not $returnMatch.Success) { continue }
                $line = Get-LineNumber -Index ($callable.OpenIndex + $returnMatch.Index) -LineStarts $info.LineStarts
                Add-Finding -Code 'ML206' -FileInfo $info -Line $line -Message "Public array accessor '$($callable.Name)' returns numeric field '$($field.Name)' directly. Return an owned copy unless aliasing is an explicit view contract." -UniqueKey "ML206|$($info.RelativePath)|$($callable.MatchIndex)|$($field.Name)|getter"
            }
        }
        }

        # ML207: flag an obvious shape/count product before a visible
        # quotient/positivity guard. Cover bindings, Array allocation sizes,
        # and direct expressions; element-index arithmetic remains excluded by
        # requiring shape-like operands (including properties such as
        # other.cols).
        $shapeAtomPattern = '(?:[A-Za-z_]\w*\.)*(?:rows|cols|height|width|channels|batch(?:Size)?|input(?:Height|Width)|output(?:Height|Width)?|size|length)'
        $numericArrayTypePattern = 'Array\s*<\s*(?:Float64|Array\s*<\s*Float64\s*>)\s*>'
        $shapeProductPatterns = @(
            ('(?im)\b(?:let|var)\s+(?<binding>(?:size|count|total|length|capacity|elements|expected|outputSize)\w*)\s*=\s*\(?\s*(?<a>' + $shapeAtomPattern + ')\s*\)?\s*\*\s*\(?\s*(?<b>' + $shapeAtomPattern + ')\s*\)?')
            ('(?im)\b' + $numericArrayTypePattern + '\s*\(\s*(?<a>' + $shapeAtomPattern + ')\s*\*\s*(?<b>' + $shapeAtomPattern + ')(?=\s*(?:,|\)))')
            ('(?im)(?<a>' + $shapeAtomPattern + ')\s*\*\s*(?<b>' + $shapeAtomPattern + ')')
        )
        $shapeProducts = [System.Collections.Generic.List[object]]::new()
        foreach ($pattern in $shapeProductPatterns) {
            foreach ($match in [regex]::Matches($callable.Body, $pattern)) {
                $shapeProducts.Add([pscustomobject]@{ Index=$match.Index; Left=$match.Groups['a'].Value; Right=$match.Groups['b'].Value })
            }
        }
        foreach ($shapeProduct in @($shapeProducts.ToArray() | Sort-Object Index)) {
            if (Test-ShapeOverflowGuard -Body $callable.Body -BeforeIndex $shapeProduct.Index -Left $shapeProduct.Left -Right $shapeProduct.Right) { continue }
            $line = Get-LineNumber -Index ($callable.OpenIndex + $shapeProduct.Index) -LineStarts $info.LineStarts
            Add-Finding -Code 'ML207' -FileInfo $info -Line $line -Message "Shape/count product '$($shapeProduct.Left) * $($shapeProduct.Right)' is used before an obvious overflow and positivity guard. Guard the quotient before evaluating the product." -UniqueKey "ML207|$($info.RelativePath)|$($callable.MatchIndex)"
            break
        }

        # ML208: repeated replacement of the same gradient slot inside a graph
        # control-flow body loses one branch. Include private/internal reverse
        # helpers and explicit slots such as gradientTensor, gradientValues,
        # gradients, and gradData; aliases and topology remain semantic.
        $gradientAssignments = @(Get-GradientAssignments -Body $callable.Body)
        $gradientCallable = $callable.Name -match '(?i)(?:backward|backprop|propagate|accumulate|gradient|adjoint|tape)' -or $gradientAssignments.Count -gt 0
        if ($gradientCallable -and $callable.Name -notmatch '(?i)(?:zero|clear).*grad' -and
            $callable.Body -match '(?i)\b(?:for|while|if)\s*\(') {
            $gradientGroups = @{}
            foreach ($assignment in $gradientAssignments) {
                $key = Get-GradientTargetKey -Target $assignment.Groups['target'].Value
                if ($key.Length -eq 0) { continue }
                if (-not $gradientGroups.ContainsKey($key)) { $gradientGroups[$key] = [System.Collections.Generic.List[object]]::new() }
                [void]$gradientGroups[$key].Add($assignment)
            }
            $gradientReported = $false
            foreach ($key in @($gradientGroups.Keys)) {
                $assignments = @($gradientGroups[$key].ToArray())
                if ($assignments.Count -lt 2) { continue }
                foreach ($assignment in $assignments) {
                    if (Test-GradientWriteReadsOldValue -Assignment $assignment) { continue }
                    $line = Get-LineNumber -Index ($callable.OpenIndex + $assignment.Index) -LineStarts $info.LineStarts
                    Add-Finding -Code 'ML208' -FileInfo $info -Line $line -Message "Repeated gradient target '$key' is assigned without reading its previous contribution. Accumulate branch/loop gradients or call an explicit accumulation helper." -UniqueKey "ML208|$($info.RelativePath)|$($callable.MatchIndex)|$key"
                    $gradientReported = $true
                    break
                }
                if ($gradientReported) { break }
            }
        }

        # ML209: detect a receiver/parameter state mutation followed by a
        # visible rejection path in stateful numerical APIs. Use parsed fields,
        # parameters, and parameter-collection loop items so common direct or
        # compound writes and set*/replace*/apply* submissions are covered
        # without treating arbitrary local variables as receiver state.
        $statefulCallable = "$($callable.Name) $($callable.ContainingType.Name)" -match '(?i)(?:step|update|train|fit|optimi[sz]e|replace|load|restore|commit|apply|set)'
        if ($statefulCallable -and $callable.Name -notmatch '(?i)(?:zero|clear).*grad') {
            $mutation = @(Get-StateMutation -Body $callable.Body -ContainingType $callable.ContainingType -Fields $info.Fields -Parameters $parameters) | Select-Object -First 1
            if ($null -ne $mutation) {
                $suffixStart = $mutation.Index + $mutation.Length
                $suffix = if ($suffixStart -lt $callable.Body.Length) { $callable.Body.Substring($suffixStart) } else { '' }
                $laterValidation = $suffix -match '(?i)\bthrow\s+IllegalArgumentException\b|\b(?:validate|require|check)\w*\s*\(|\.(?:isNaN|isInf)\s*\(|\bif\s*\([^)]*(?:\.size|\.length|shape|rows|cols|isNaN|isInf)[^)]*\)'
                if ($laterValidation) {
                    $line = Get-LineNumber -Index ($callable.OpenIndex + $mutation.Index) -LineStarts $info.LineStarts
                    Add-Finding -Code 'ML209' -FileInfo $info -Line $line -Message "State mutation occurs before a later validation/rejection path in '$($callable.Name)'. Compute and validate the complete candidate, then commit once." -UniqueKey "ML209|$($info.RelativePath)|$($callable.MatchIndex)"
                }
            }
        }

        # ML210: isolate each spawn lambda and look only for direct writes to
        # an enclosing numerical Array. Cover every visible assignment and
        # compound operator; parent writes after Future.get() are intentionally
        # outside the lambda and therefore safe here. An unknown helper's
        # possible write is not guessed and is documented as a review item.
        if ($callable.Body -match '(?i)\bspawn\b') {
            $bodyPairs = Get-BracePairs -Text $callable.Body
            $spawnMatches = @([regex]::Matches($callable.Body, '(?i)\bspawn\b'))
            $spawnReported = $false
            foreach ($spawnMatch in $spawnMatches) {
                $lambdaOpen = Find-OpeningBrace -Text $callable.Body -Start ($spawnMatch.Index + $spawnMatch.Length)
                if ($lambdaOpen -lt 0 -or -not $bodyPairs.ContainsKey($lambdaOpen)) { continue }
                $lambdaClose = [int]$bodyPairs[$lambdaOpen]
                $outerNames = @(Get-OuterArrayNames -Body $callable.Body -BeforeIndex $lambdaOpen -ContainingType $callable.ContainingType -Fields $info.Fields -Parameters $parameters)
                if ($outerNames.Count -eq 0) { continue }
                $lambdaBody = $callable.Body.Substring($lambdaOpen, $lambdaClose - $lambdaOpen + 1)
                $localArrayNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
                foreach ($local in [regex]::Matches($lambdaBody, '(?im)\b(?:let|var)\s+(?<name>[A-Za-z_]\w*)\s*(?::\s*Array\s*<\s*(?:Float64|Array\s*<\s*Float64\s*>)\s*>\s*)?=\s*Array\s*<\s*(?:Float64|Array\s*<\s*Float64\s*>)')) { [void]$localArrayNames.Add($local.Groups['name'].Value) }
                foreach ($name in $outerNames) {
                    if ($localArrayNames.Contains($name)) { continue }
                    $escapedName = [regex]::Escape($name)
                    $write = [regex]::Match($lambdaBody, '(?im)(?:this\s*\.\s*)?' + $escapedName + '(?:\s*\[[^\]\r\n]+\])*\s*(?:\+=|-=|\*=|/=|=(?!=))')
                    if (-not $write.Success) { continue }
                    $line = Get-LineNumber -Index ($callable.OpenIndex + $lambdaOpen + $write.Index) -LineStarts $info.LineStarts
                    Add-Finding -Code 'ML210' -FileInfo $info -Line $line -Message "Spawn worker writes captured numerical array '$name'. Return an isolated partial result and merge it after Future.get() in a deterministic order." -UniqueKey "ML210|$($info.RelativePath)|$($callable.MatchIndex)|$name"
                    $spawnReported = $true
                    break
                }
                if ($spawnReported) { break }
            }
        }
    }
}

$ordered = @($rawFindings.ToArray() | Sort-Object file, line, code, message)
$bucketCounts = @{}
$limited = [System.Collections.Generic.List[object]]::new()
foreach ($finding in $ordered) {
    if ($limited.Count -ge $MaxFindings) { break }
    $bucket = "$($finding.code)|$($finding.file)"
    $count = if ($bucketCounts.ContainsKey($bucket)) { [int]$bucketCounts[$bucket] } else { 0 }
    if ($count -ge 3) { continue }
    $bucketCounts[$bucket] = $count + 1
    $limited.Add($finding)
}
$findings = @($limited.ToArray())
$result = [ordered]@{
    schema_version='1.0'
    project=$root
    files_scanned=$sourceFiles.Count
    finding_count=$findings.Count
    findings=$findings
}

if ($Format -eq 'Json') { $result | ConvertTo-Json -Depth 6 }
elseif ($findings.Count -eq 0) { Write-Output "Cangjie preflight: no known high-risk patterns found in $($result.files_scanned) file(s)." }
else {
    Write-Output "Cangjie preflight: $($findings.Count) finding(s) in $($result.files_scanned) file(s)."
    foreach ($finding in $findings) { Write-Output "$($finding.file):$($finding.line) [$($finding.code)] $($finding.message)" }
}
if ($FailOnFindings -and $findings.Count -gt 0) { exit 2 }
