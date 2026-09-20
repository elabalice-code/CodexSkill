[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DataDir,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArguments
)

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$package = Join-Path $skillRoot 'assets\TaskControllerCli-0.1.2.zip'
$toolDirectory = Join-Path $skillRoot 'tool'
$executable = Join-Path $toolDirectory 'TaskControllerCli.exe'

if (-not (Test-Path -LiteralPath $package -PathType Leaf)) {
    throw "Bundled release package not found: $package"
}

if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    Expand-Archive -LiteralPath $package -DestinationPath $toolDirectory -Force
}

if (-not (Test-Path -LiteralPath $DataDir -PathType Container)) {
    throw "Task data directory not found: $DataDir"
}

& $executable @CliArguments --data-dir $DataDir
exit $LASTEXITCODE
