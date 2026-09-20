[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [Parameter(Mandatory = $true)]
    [string]$RenameTable,
    [string[]]$Extensions = @('.cs', '.gd', '.rs', '.ts', '.tsx', '.json', '.json5'),
    [string[]]$Exclude = @('.git', '.vs', '.godot', 'bin', 'obj', 'node_modules', 'target', 'dist', 'artifacts', 'packages', 'vendor', 'TestResults'),
    [switch]$AllowSubstring,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($SourceRoot)
$tablePath = [IO.Path]::GetFullPath($RenameTable)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "SourceRoot does not exist: $root" }
if (-not (Test-Path -LiteralPath $tablePath -PathType Leaf)) { throw "Rename table does not exist: $tablePath" }

$rows = @(Import-Csv -LiteralPath $tablePath -Delimiter "`t" -Encoding UTF8)
if ($rows.Count -eq 0) { throw 'Rename table has no data rows.' }
$required = @('old_name', 'new_name', 'layer', 'business_scope', 'feature', 'reason', 'status')
$headers = @($rows[0].PSObject.Properties.Name)
foreach ($name in $required) {
    if ($headers -notcontains $name) { throw "Rename table is missing required column: $name" }
}

$rules = foreach ($row in $rows) {
    $old = ([string]$row.old_name).Trim()
    $new = ([string]$row.new_name).Trim()
    if (-not $old -or -not $new) { throw 'old_name and new_name must not be empty.' }
    if ($old -eq $new) { continue }
    [pscustomobject]@{
        Old = $old
        New = $new
        Status = ([string]$row.status).Trim().ToLowerInvariant()
    }
}
$rules = @($rules | Sort-Object @{ Expression = { $_.Old.Length }; Descending = $true }, Old)
if ($rules.Count -eq 0) { throw 'Rename table contains no changes.' }

$duplicateOld = @($rules | Group-Object Old | Where-Object Count -gt 1)
if ($duplicateOld.Count) { throw "Duplicate old_name values: $($duplicateOld.Name -join ', ')" }
$duplicateNew = @($rules | Group-Object New | Where-Object Count -gt 1)
if ($duplicateNew.Count) { throw "Duplicate new_name values: $($duplicateNew.Name -join ', ')" }
if ($Apply) {
    $notApproved = @($rules | Where-Object Status -ne 'approved')
    if ($notApproved.Count) { throw 'Apply requires every rename row to have status=approved.' }
}

Write-Output 'Rename plan (old_name sorted longest to shortest):'
foreach ($rule in $rules) { Write-Output ("  {0} -> {1} [{2}]" -f $rule.Old, $rule.New, $rule.Status) }
if (-not $Apply) { Write-Output 'Preview only. Re-run with -Apply after explicit approval.' }

$map = @{}
foreach ($rule in $rules) { $map[$rule.Old] = $rule.New }
$alternatives = (($rules | ForEach-Object { [Regex]::Escape($_.Old) }) -join '|')
if ($AllowSubstring) {
    $pattern = "(?:$alternatives)"
} else {
    $pattern = "(?<![A-Za-z0-9_])(?:$alternatives)(?![A-Za-z0-9_])"
}
$evaluator = [Text.RegularExpressions.MatchEvaluator]{ param($match) $map[$match.Value] }

function Get-TextEncoding {
    param([byte[]]$Bytes)
    if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE -and $Bytes[2] -eq 0x00 -and $Bytes[3] -eq 0x00) { return [Text.UTF32Encoding]::new($true, $true) }
    if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0x00 -and $Bytes[1] -eq 0x00 -and $Bytes[2] -eq 0xFE -and $Bytes[3] -eq 0xFF) { return [Text.UTF32Encoding]::new($false, $true) }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) { return [Text.UnicodeEncoding]::new($true, $true) }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) { return [Text.UnicodeEncoding]::new($false, $true) }
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) { return [Text.UTF8Encoding]::new($true) }
    return [Text.UTF8Encoding]::new($false)
}

$excluded = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($name in $Exclude) { if ($name) { [void]$excluded.Add($name) } }
$allowedExtensions = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($extension in $Extensions) { if ($extension) { [void]$allowedExtensions.Add($(if ($extension.StartsWith('.')) { $extension } else { ".$extension" })) } }
$stack = [Collections.Generic.Stack[string]]::new()
$stack.Push($root)
$changedFiles = 0
$replacementCount = 0
while ($stack.Count -gt 0) {
    $directory = $stack.Pop()
    foreach ($child in [IO.Directory]::EnumerateDirectories($directory)) {
        if (-not $excluded.Contains([IO.Path]::GetFileName($child))) { $stack.Push($child) }
    }
    foreach ($file in [IO.Directory]::EnumerateFiles($directory)) {
        if (-not $allowedExtensions.Contains([IO.Path]::GetExtension($file))) { continue }
        $bytes = [IO.File]::ReadAllBytes($file)
        $encoding = Get-TextEncoding $bytes
        $text = [IO.File]::ReadAllText($file, $encoding)
        $matches = [Regex]::Matches($text, $pattern)
        if ($matches.Count -eq 0) { continue }
        $changedFiles++
        $replacementCount += $matches.Count
        Write-Output ("{0}: {1} replacement(s)" -f $file, $matches.Count)
        if ($Apply -and $PSCmdlet.ShouldProcess($file, 'Apply approved signal renames')) {
            $updated = [Regex]::Replace($text, $pattern, $evaluator)
            [IO.File]::WriteAllText($file, $updated, $encoding)
        }
    }
}
Write-Output ("Summary: files={0}, replacements={1}, applied={2}" -f $changedFiles, $replacementCount, [bool]$Apply)
