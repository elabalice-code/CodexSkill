[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string[]]$Extensions = @('.cs', '.gd', '.rs', '.ts', '.tsx', '.js', '.jsx', '.java', '.kt', '.kts', '.go', '.py', '.cpp', '.h', '.hpp', '.sql'),
    [string[]]$Exclude = @('.git', '.vs', '.godot', 'bin', 'obj', 'node_modules', 'target', 'dist', 'artifacts', 'packages', 'vendor', 'TestResults'),
    [string]$EquationFile,
    [string]$VariablesFile,
    [string]$OutputFile,
    [string]$JsonFile,
    [switch]$SignalOnly
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($SourceRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "SourceRoot does not exist: $root" }
$equationSignals = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$variableSignals = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
if ($EquationFile) {
    $equationsPath = [IO.Path]::GetFullPath($EquationFile)
    if (-not (Test-Path -LiteralPath $equationsPath -PathType Leaf)) { throw "EquationFile does not exist: $equationsPath" }
    foreach ($line in [IO.File]::ReadAllLines($equationsPath)) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#') -or $line.TrimStart().StartsWith('//')) { continue }
        $colon = $line.IndexOf(':')
        $equals = $line.IndexOf('=')
        if ($colon -lt 1 -or $equals -le $colon) { continue }
        foreach ($token in (($line.Substring($colon + 1, $equals - $colon - 1) + '+' + $line.Substring($equals + 1)).Split('+'))) {
            $signal = $token.Trim()
            if ($signal -and $signal -ne 'NONE') { [void]$equationSignals.Add($signal) }
        }
    }
}
if ($VariablesFile) {
    $variablesPath = [IO.Path]::GetFullPath($VariablesFile)
    if (-not (Test-Path -LiteralPath $variablesPath -PathType Leaf)) { throw "VariablesFile does not exist: $variablesPath" }
    foreach ($row in @(Import-Csv -LiteralPath $variablesPath -Delimiter "`t" -Encoding UTF8)) {
        if ($row.Signal) { [void]$variableSignals.Add(([string]$row.Signal).Trim()) }
    }
}
$knownSignals = if ($equationSignals.Count -gt 0) { $equationSignals } else { $variableSignals }
$signalAliases = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$signalCanonical = @{}
$ambiguousAliases = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($signal in $knownSignals) {
    [void]$signalAliases.Add($signal)
    $signalCanonical[$signal] = $signal
    $separator = $signal.LastIndexOf('.')
    if ($separator -ge 0 -and $separator + 1 -lt $signal.Length) {
        $alias = $signal.Substring($separator + 1)
        if ($signalCanonical.ContainsKey($alias) -and $signalCanonical[$alias] -ne $signal) {
            [void]$ambiguousAliases.Add($alias)
            [void]$signalAliases.Remove($alias)
        } elseif (-not $ambiguousAliases.Contains($alias)) {
            [void]$signalAliases.Add($alias)
            $signalCanonical[$alias] = $signal
        }
    }
}
$signalAliases = @($signalAliases | Where-Object { -not $ambiguousAliases.Contains($_) })

$allowed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($extension in $Extensions) {
    if ($extension) { [void]$allowed.Add($(if ($extension.StartsWith('.')) { $extension } else { ".$extension" })) }
}
$excluded = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($name in $Exclude) { if ($name) { [void]$excluded.Add($name) } }

$boolPattern = '(?<And>&&|\band\b|\bAND\b)|(?<Or>\|\||\bor\b|\bOR\b)|(?<Not>(?<![=<>!])!(?!=)|\bnot\b|\bNOT\b)'
$identifierPattern = '(?<![A-Za-z0-9_])(?:ORIGIN|MODELVIEW|SIGNAL)_[A-Za-z0-9_.]+'
$knownSignalPattern = $null
if ($signalAliases.Count -gt 0) {
    $knownSignalAlternatives = @($signalAliases | Sort-Object Length -Descending | ForEach-Object { [Regex]::Escape($_) }) -join '|'
    $knownSignalPattern = "(?<![A-Za-z0-9_])(?:$knownSignalAlternatives)(?![A-Za-z0-9_])"
}
$tickPattern = '(?i)(?:_process|_physics_process|\b(?:tick|update|fixedupdate|lateupdate|process)\s*\()'
$conditionPattern = '(?i)\b(?:if|elif|elseif|while|for|when|switch|case)\b'
$assignmentPattern = '(?<![=!<>])(?:=|:=|\+=|-=|\*=|/=|%=)'
$writePattern = '(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_.]*)\s*(?:=|:=|\+=|-=|\*=|/=|%=|\+\+|--)'
$identifierScanPattern = '(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_.]*)'
$keywords = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($keyword in @('if','else','elif','elseif','while','for','when','switch','case','return','and','or','not','true','false','null','none','new','in','is','as','await','yield')) { [void]$keywords.Add($keyword) }

function Mask-Code {
    param([string]$Line, [ref]$BlockComment)
    $builder = [Text.StringBuilder]::new()
    $quote = [char]0
    for ($i = 0; $i -lt $Line.Length; $i++) {
        $ch = $Line[$i]
        $next = if ($i + 1 -lt $Line.Length) { $Line[$i + 1] } else { [char]0 }
        if ($BlockComment.Value) {
            if ($ch -eq '*' -and $next -eq '/') { $BlockComment.Value = $false; $i++ }
            continue
        }
        if ($quote -ne [char]0) {
            if ($ch -eq [char]92 -and $i + 1 -lt $Line.Length) { $builder.Append(' ') | Out-Null; $builder.Append(' ') | Out-Null; $i++; continue }
            if ($ch -eq $quote) { $quote = [char]0 }
            $builder.Append(' ') | Out-Null
            continue
        }
        if ($ch -eq '/' -and $next -eq '/') { break }
        if ($ch -eq '/' -and $next -eq '*') { $BlockComment.Value = $true; $i++; continue }
        if ($ch -eq '#' -and $builder.ToString().Trim().Length -eq 0) { break }
        if ($ch -eq '-' -and $next -eq '-') { break }
        if ($ch -eq [char]39 -or $ch -eq [char]34) { $quote = $ch; $builder.Append(' ') | Out-Null; continue }
        $builder.Append($ch) | Out-Null
    }
    return $builder.ToString()
}

function Is-StateSignal {
    param([string]$Name)
    if ($knownSignals.Count -gt 0) { return (-not $ambiguousAliases.Contains($Name)) -and $signalCanonical.ContainsKey($Name) }
    return $Name -match '(?i)^(?:ORIGIN|MODELVIEW|SIGNAL)_' -or $Name -match '(?i)(state|buffer|snapshot|current|next|previous|prev|pending|input|output)'
}

function Add-ReportLine {
    param([Collections.Generic.List[string]]$Lines, [string]$Line)
    [void]$Lines.Add($Line)
}

$booleanFindings = [Collections.Generic.List[object]]::new()
$bufferFindings = [Collections.Generic.List[object]]::new()
$report = [Collections.Generic.List[string]]::new()
$stack = [Collections.Generic.Stack[string]]::new()
$stack.Push($root)

while ($stack.Count -gt 0) {
    $directory = $stack.Pop()
    foreach ($child in [IO.Directory]::EnumerateDirectories($directory)) {
        if (-not $excluded.Contains([IO.Path]::GetFileName($child))) { $stack.Push($child) }
    }
    foreach ($file in [IO.Directory]::EnumerateFiles($directory)) {
        if (-not $allowed.Contains([IO.Path]::GetExtension($file))) { continue }
        $lines = [IO.File]::ReadAllLines($file)
        $blockComment = $false
        $depth = 0
        $inTick = $false
        $tickStart = 0
        $tickName = ''
        $tickDepth = 0
        $tickReads = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $tickWrites = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $tickReadLines = @{}
        $tickWriteLines = @{}

        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            $raw = [string]$lines[$lineIndex]
            $code = Mask-Code $raw ([ref]$blockComment)
            $boolMatches = @([Regex]::Matches($code, $boolPattern))
            if ($boolMatches.Count -gt 0) {
                $ops = @($boolMatches | ForEach-Object { $_.Value } | Select-Object -Unique)
                if ($code.Contains('(')) { $ops += '(' }
                if ($code.Contains(')')) { $ops += ')' }
                $context = if ($code -match $conditionPattern) { 'condition/consumer' } elseif ($code -match '(?i)\breturn\b') { 'return/consumer' } elseif ($code -match $assignmentPattern) { 'precompute/assignment' } elseif ($code -match '(?<![A-Za-z0-9_])[A-Za-z_][A-Za-z0-9_.]*\s*\(') { 'call/consumer' } else { 'unknown' }
                $signalPatternForLine = if ($knownSignalPattern) { $knownSignalPattern } else { $identifierPattern }
                $signals = @([Regex]::Matches($code, $signalPatternForLine) | ForEach-Object { if ($signalCanonical.ContainsKey($_.Value)) { $signalCanonical[$_.Value] } else { $_.Value } } | Select-Object -Unique)
                $recommendation = if ($context -eq 'precompute/assignment') { 'Verify LHS is a descriptive ORIGIN_/MODELVIEW_/SIGNAL_ signal.' } else { 'Move boolean computation before consumption and store a descriptive signal.' }
                $finding = [pscustomobject]@{ File = $file; Line = $lineIndex + 1; Context = $context; Operators = ($ops -join ','); Signals = ($signals -join ','); SignalRelated = ($signals.Count -gt 0); Recommendation = $recommendation; Text = $raw.Trim() }
                [void]$booleanFindings.Add($finding)
            }

            $isTick = $code -match $tickPattern
            if ($isTick -and -not $inTick) {
                $inTick = $true; $tickStart = $lineIndex + 1
                $tickDepth = $depth
                $tickName = ([Regex]::Match($code, '(?i)(_process|_physics_process|tick|update|fixedupdate|lateupdate|process)')).Value
                $tickReads = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                $tickWrites = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                $tickReadLines = @{}; $tickWriteLines = @{}
            }

            if ($inTick) {
                $writes = @([Regex]::Matches($code, $writePattern) | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
                foreach ($write in $writes) {
                    if (Is-StateSignal $write) {
                        $canonicalWrite = if ($signalCanonical.ContainsKey($write)) { $signalCanonical[$write] } else { $write }
                        [void]$tickWrites.Add($canonicalWrite); $tickWriteLines[$canonicalWrite] = $lineIndex + 1
                    }
                }
                $reads = @([Regex]::Matches($code, $identifierScanPattern) | ForEach-Object { $_.Groups[1].Value } | Where-Object { -not $keywords.Contains($_) } | Select-Object -Unique)
                foreach ($read in $reads) {
                    if (Is-StateSignal $read) {
                        $canonicalRead = if ($signalCanonical.ContainsKey($read)) { $signalCanonical[$read] } else { $read }
                        [void]$tickReads.Add($canonicalRead); if (-not $tickReadLines.ContainsKey($canonicalRead)) { $tickReadLines[$canonicalRead] = $lineIndex + 1 }
                    }
                }
            }

            $opens = ([Regex]::Matches($code, '\{')).Count
            $closes = ([Regex]::Matches($code, '\}')).Count
            $depth += $opens - $closes
            if ($inTick -and $code.Contains('}') -and $depth -le $tickDepth) {
                foreach ($name in $tickWrites) {
                    if ($tickReads.Contains($name)) {
                        [void]$bufferFindings.Add([pscustomobject]@{ File = $file; Tick = $tickName; StartLine = $tickStart; EndLine = $lineIndex + 1; Signal = $name; ReadLine = $tickReadLines[$name]; WriteLine = $tickWriteLines[$name]; Finding = 'Potential single-buffer read/write hazard; verify double buffering or snapshot-before-mutate.' })
                    }
                }
                $inTick = $false
            }
        }
    }
}

Add-ReportLine $report 'Signal consumption audit'
Add-ReportLine $report ("SourceRoot: $root")
Add-ReportLine $report ("Boolean expression findings: $($booleanFindings.Count)")
Add-ReportLine $report ("Signal-related boolean expressions: $(@($booleanFindings | Where-Object SignalRelated).Count)")
Add-ReportLine $report ("Potential single-buffer hazards: $($bufferFindings.Count)")
Add-ReportLine $report ''
Add-ReportLine $report '[Boolean expressions]'
$findingsToReport = if ($SignalOnly) { @($booleanFindings | Where-Object SignalRelated) } else { @($booleanFindings) }
foreach ($finding in $findingsToReport) {
    Add-ReportLine $report ("{0}:{1} [{2}] operators={3} signals={4} :: {5}" -f $finding.File, $finding.Line, $finding.Context, $finding.Operators, $(if ($finding.Signals) { $finding.Signals } else { '(none)' }), $finding.Text)
    Add-ReportLine $report ("  Recommendation: {0}" -f $finding.Recommendation)
}
if ($findingsToReport.Count -eq 0) { Add-ReportLine $report '(none)' }
Add-ReportLine $report ''
Add-ReportLine $report '[Potential single-buffer hazards]'
foreach ($finding in $bufferFindings) {
    Add-ReportLine $report ("{0}:{1}-{2} tick={3} signal={4} read={5} write={6} :: {7}" -f $finding.File, $finding.StartLine, $finding.EndLine, $finding.Tick, $finding.Signal, $finding.ReadLine, $finding.WriteLine, $finding.Finding)
}
if ($bufferFindings.Count -eq 0) { Add-ReportLine $report '(none detected by heuristic)' }

$reportText = $report -join [Environment]::NewLine
Write-Output $reportText
if ($OutputFile) {
    $outputPath = [IO.Path]::GetFullPath($OutputFile)
    $parent = [IO.Directory]::GetParent($outputPath)
    if ($parent) { [IO.Directory]::CreateDirectory($parent.FullName) | Out-Null }
    [IO.File]::WriteAllText($outputPath, $reportText, [Text.UTF8Encoding]::new($false))
}
if ($JsonFile) {
    $jsonPath = [IO.Path]::GetFullPath($JsonFile)
    $parent = [IO.Directory]::GetParent($jsonPath)
    if ($parent) { [IO.Directory]::CreateDirectory($parent.FullName) | Out-Null }
    [IO.File]::WriteAllText($jsonPath, (@{ BooleanExpressions = @($booleanFindings); SingleBufferHazards = @($bufferFindings) } | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
}
