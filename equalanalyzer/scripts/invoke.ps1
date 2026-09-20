[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EquationFile,
    [string]$VariablesFile,
    [string]$OutputFile,
    [string]$JsonFile,
    [string]$TraceSignal,
    [string]$TraceEquation,
    [switch]$IoAnalysis,
    [switch]$AllowInvalid
)

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $skillRoot 'assets\equalanalyzer-console.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Bundled executable not found: $exe" }
$equations = [System.IO.Path]::GetFullPath($EquationFile)
if (-not (Test-Path -LiteralPath $equations -PathType Leaf)) { throw "Equation file not found: $equations" }
if ($TraceSignal -and $TraceEquation) { throw 'TraceSignal and TraceEquation are mutually exclusive.' }

$arguments = [System.Collections.Generic.List[string]]::new()
$arguments.Add($equations)
if (-not $AllowInvalid) { $arguments.Add('--strict') }
if ($IoAnalysis -or $VariablesFile) { $arguments.Add('--io-analysis') }
if ($VariablesFile) {
    $variables = [System.IO.Path]::GetFullPath($VariablesFile)
    if (-not (Test-Path -LiteralPath $variables -PathType Leaf)) { throw "Variables TSV not found: $variables" }
    $arguments.Add('--variables'); $arguments.Add($variables)
}
if ($OutputFile) { $arguments.Add('--output'); $arguments.Add([System.IO.Path]::GetFullPath($OutputFile)) }
if ($JsonFile) { $arguments.Add('--json'); $arguments.Add([System.IO.Path]::GetFullPath($JsonFile)) }
if ($TraceSignal) { $arguments.Add('--trace-signal'); $arguments.Add($TraceSignal) }
if ($TraceEquation) { $arguments.Add('--trace-equation'); $arguments.Add($TraceEquation) }

& $exe @arguments
exit $LASTEXITCODE
