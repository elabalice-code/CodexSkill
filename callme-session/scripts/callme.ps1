<#
    callme.ps1 <prompt>

    The first positional argument is the prompt to queue to an existing Codex
    thread. A copy is also written under this skill's audits directory.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Prompt,

    [string]$Thread = "",

    [string]$CodexExecutable = "codex",

    [string]$Sender = "B Codex",

    [switch]$NoQueue
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Prompt)) {
    throw "Usage: .\callme.ps1 <prompt>"
}

if ([string]::IsNullOrWhiteSpace($Thread)) {
    if ($env:CODEX_THREAD_ID -match '^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$') {
        $Thread = $env:CODEX_THREAD_ID
    } elseif ($env:CODEX_SESSION_ID -match '^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$') {
        $Thread = $env:CODEX_SESSION_ID
    } else {
        throw "No target Codex thread. Set CODEX_THREAD_ID or pass -Thread <thread-id>."
    }
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$auditDir = Join-Path $skillRoot "audits"
New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
$notificationId = [guid]::NewGuid().ToString()
$auditPath = Join-Path $auditDir ("CALLME_{0}.md" -f $notificationId)
$audit = @(
    "# Callme audit",
    "- Notification ID: $notificationId",
    "- Sender: $Sender",
    "- Local time: $(Get-Date -Format o)",
    "- UTC time: $([DateTime]::UtcNow.ToString('o'))",
    "- Target thread: $Thread",
    "",
    "## Exact prompt",
    "",
    $Prompt
) -join [Environment]::NewLine
Set-Content -LiteralPath $auditPath -Value $audit -Encoding UTF8
Write-Host "Audit archived: $auditPath"
if ($NoQueue) {
    Write-Host "Queue step skipped (-NoQueue)."
    exit 0
}
Write-Host "Queueing prompt to Codex thread $Thread ..."
& $CodexExecutable queue --thread $Thread --message $Prompt
$queueExit = $LASTEXITCODE
if ($queueExit -eq 0) {
    Write-Host "Prompt queued successfully."
} else {
    Write-Error "codex queue failed with exit code $queueExit. The prompt was archived, but delivery was not confirmed."
}
exit $queueExit
