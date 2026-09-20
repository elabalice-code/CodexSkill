param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string]$EquationOutput,
    [string]$VariablesOutput,
    [string[]]$Exclude,
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"
$exe = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\assets\fastsignaltrace-csharp.exe"))
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    Write-Error "Bundled executable is missing: $exe"
    exit 4
}

$toolArguments = [Collections.Generic.List[string]]::new()
$toolArguments.Add([IO.Path]::GetFullPath($SourceRoot))
if ($EquationOutput) { $toolArguments.Add("--output"); $toolArguments.Add([IO.Path]::GetFullPath($EquationOutput)) }
if ($VariablesOutput) { $toolArguments.Add("--variables-output"); $toolArguments.Add([IO.Path]::GetFullPath($VariablesOutput)) }
foreach ($name in @($Exclude)) { if ($name) { $toolArguments.Add("--exclude"); $toolArguments.Add($name) } }
if ($Detailed) { $toolArguments.Add("--verbose") }

& $exe @toolArguments
exit $LASTEXITCODE
