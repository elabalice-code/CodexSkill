param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string]$EquationOutput,
    [string]$VariablesOutput,
    [string[]]$Exclude,
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"
$exe = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\assets\fastsignaltrace-lacpp.exe"))
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    Write-Error "Bundled executable is missing: $exe"
    exit 4
}

$arguments = [Collections.Generic.List[string]]::new()
$arguments.Add([IO.Path]::GetFullPath($SourceRoot))
if ($EquationOutput) { $arguments.Add("--output"); $arguments.Add([IO.Path]::GetFullPath($EquationOutput)) }
if ($VariablesOutput) { $arguments.Add("--variables-output"); $arguments.Add([IO.Path]::GetFullPath($VariablesOutput)) }
foreach ($name in @($Exclude)) { if ($name) { $arguments.Add("--exclude"); $arguments.Add($name) } }
if ($Detailed) { $arguments.Add("--verbose") }

& $exe @arguments
exit $LASTEXITCODE
