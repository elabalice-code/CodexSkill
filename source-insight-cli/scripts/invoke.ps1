param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string]$OutputFile
)

$ErrorActionPreference = "Stop"
$exe = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\assets\SourceInsightCli.exe"))
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    [Console]::Error.WriteLine("Bundled executable is missing: $exe")
    exit 4
}

$arguments = [Collections.Generic.List[string]]::new()
$arguments.Add([IO.Path]::GetFullPath($SourceRoot))
if ($OutputFile) {
    $arguments.Add("--output")
    $arguments.Add([IO.Path]::GetFullPath($OutputFile))
}
& $exe @arguments
exit $LASTEXITCODE
