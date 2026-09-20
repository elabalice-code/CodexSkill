[CmdletBinding()]
param(
    [ValidateRange(0, 3)]
    [int] $MaxRetries = 3,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
)

$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$executablePath = Join-Path $skillRoot 'bin\RemoteCmdClient.exe'
$runsRoot = Join-Path $skillRoot 'runs'
$runId = '{0:yyyyMMddTHHmmssfff}-{1}' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0, 8))
$runPath = Join-Path $runsRoot $runId
$recordedArguments = if ($null -eq $Arguments) { [string[]]@() } else { [string[]]@($Arguments) }

New-Item -ItemType Directory -Force -Path $runPath | Out-Null

$request = [ordered]@{
    run_id = $runId
    executable_path = $executablePath
    arguments = $recordedArguments
    argument_count = $recordedArguments.Count
    max_retries = $MaxRetries
    started_at = (Get-Date).ToString('o')
}
$request | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runPath 'request.json') -Encoding utf8

if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
    $result = [ordered]@{
        run_id = $runId
        executable_path = $executablePath
        completed_at = (Get-Date).ToString('o')
        status = 'not_started'
        exit_code = $null
        error = 'RemoteCmdClient.exe was not found at the configured path.'
    }
    $result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runPath 'result.json') -Encoding utf8
    Write-Error "RemoteCmdClient.exe was not found: $executablePath. Run record: $runPath"
}

function Test-RetryablePreExecutionFailure {
    param(
        [int] $ExitCode,
        [string] $StdOut,
        [string] $StdErr
    )

    if ($ExitCode -eq 0) {
        return $false
    }

    $combined = $StdOut + "`n" + $StdErr
    return $combined.Contains('Execution failed before the command completed') -or
        $combined.Contains('Remote command file is not ready')
}

$stdoutPath = Join-Path $runPath 'stdout.txt'
$stderrPath = Join-Path $runPath 'stderr.txt'
$attempts = @()
$attemptCount = 0
$exitCode = $null
$stoppedReason = 'not_started'

for ($attempt = 1; $attempt -le (1 + $MaxRetries); $attempt++) {
    $attemptCount = $attempt
    $attemptStartedAt = (Get-Date).ToString('o')
    $attemptPrefix = 'attempt-{0:D2}' -f $attempt
    $attemptStdoutPath = Join-Path $runPath ($attemptPrefix + '.stdout.txt')
    $attemptStderrPath = Join-Path $runPath ($attemptPrefix + '.stderr.txt')
    $attemptResultPath = Join-Path $runPath ($attemptPrefix + '.result.json')

    & $executablePath @recordedArguments 1> $attemptStdoutPath 2> $attemptStderrPath
    $exitCode = $LASTEXITCODE
    $attemptStdout = if (Test-Path -LiteralPath $attemptStdoutPath) {
        Get-Content -LiteralPath $attemptStdoutPath -Raw -Encoding utf8
    } else {
        ''
    }
    $attemptStderr = if (Test-Path -LiteralPath $attemptStderrPath) {
        Get-Content -LiteralPath $attemptStderrPath -Raw -Encoding utf8
    } else {
        ''
    }
    $retryable = Test-RetryablePreExecutionFailure -ExitCode $exitCode -StdOut $attemptStdout -StdErr $attemptStderr
    $willRetry = $exitCode -ne 0 -and $retryable -and $attempt -le $MaxRetries

    $attemptRecord = [ordered]@{
        attempt = $attempt
        started_at = $attemptStartedAt
        completed_at = (Get-Date).ToString('o')
        exit_code = $exitCode
        retryable_pre_execution_failure = $retryable
        will_retry = $willRetry
        stdout_path = $attemptStdoutPath
        stderr_path = $attemptStderrPath
    }
    $attemptRecord | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $attemptResultPath -Encoding utf8
    $attempts += $attemptRecord

    Copy-Item -LiteralPath $attemptStdoutPath -Destination $stdoutPath -Force
    Copy-Item -LiteralPath $attemptStderrPath -Destination $stderrPath -Force

    if ($exitCode -eq 0) {
        $stoppedReason = 'success'
        break
    }
    if (-not $retryable) {
        $stoppedReason = 'non_retryable_or_ambiguous_failure'
        break
    }
    if (-not $willRetry) {
        $stoppedReason = 'retry_limit_reached'
        break
    }

    Start-Sleep -Seconds ([Math]::Min(2 * $attempt, 5))
}

$result = [ordered]@{
    run_id = $runId
    executable_path = $executablePath
    completed_at = (Get-Date).ToString('o')
    status = 'completed'
    exit_code = $exitCode
    attempt_count = $attemptCount
    retries_performed = [Math]::Max(0, $attemptCount - 1)
    max_retries = $MaxRetries
    stopped_reason = $stoppedReason
    attempts = $attempts
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runPath 'result.json') -Encoding utf8

[pscustomobject]@{
    RunPath = $runPath
    ExitCode = $exitCode
    AttemptCount = $attemptCount
    RetriesPerformed = [Math]::Max(0, $attemptCount - 1)
    StoppedReason = $stoppedReason
    StdOutPath = $stdoutPath
    StdErrPath = $stderrPath
}

exit $exitCode
