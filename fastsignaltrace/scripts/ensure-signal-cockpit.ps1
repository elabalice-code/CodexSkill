[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string]$StatusRoot,
    [string]$TemplatePath
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($SourceRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "SourceRoot does not exist: $root" }

if ($StatusRoot) {
    $status = [IO.Path]::GetFullPath($StatusRoot)
    if (-not (Test-Path -LiteralPath $status -PathType Container)) {
        [IO.Directory]::CreateDirectory($status) | Out-Null
        Write-Output "Created cockpit: $status"
    }
} else {
    $cursor = $root
    $status = $null
    while ($cursor) {
        $candidate = Join-Path $cursor '00_STATUS'
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $status = [IO.Path]::GetFullPath($candidate)
            break
        }
        $parent = [IO.Directory]::GetParent($cursor)
        if (-not $parent -or $parent.FullName -eq $cursor) { break }
        $cursor = $parent.FullName
    }
    if (-not $status) {
        $status = Join-Path $root '00_STATUS'
        [IO.Directory]::CreateDirectory($status) | Out-Null
        Write-Output "Created cockpit: $status"
    }
}

$mapPath = Join-Path $status 'Extra_SignalMap.md'
if (-not (Test-Path -LiteralPath $mapPath -PathType Leaf)) {
    if (-not $TemplatePath) {
        $skillRoot = Split-Path -Parent $PSScriptRoot
        $TemplatePath = Join-Path $skillRoot 'assets\Extra_SignalMap.template.md'
    }
    $template = [IO.Path]::GetFullPath($TemplatePath)
    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) { throw "Signal map template not found: $template" }
    [IO.File]::Copy($template, $mapPath, $false)
    Write-Output "Created signal map: $mapPath"
} else {
    Write-Output "Signal map exists; preserved: $mapPath"
}
Write-Output "StatusRoot=$status"
Write-Output "SignalMap=$mapPath"
