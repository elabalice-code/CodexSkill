---
name: remote-cmd-client
description: Invoke the bundled RemoteCmdClient.exe with user-authorized arguments and save auditable run records. Use for remote device discovery, command execution, and file transfer.
---

# Remote Cmd Client

Use the bundled executable at `bin/RemoteCmdClient.exe`; never depend on a copy in the current project.

## Invocation

- Invoke `scripts/invoke-remote-command.ps1`, passing the user-supplied arguments as an argument array. It starts only the bundled executable and does not run a shell command locally.
- Preserve the supplied arguments exactly: do not add, remove, reorder, or reinterpret them.
- If the user asks for a state-changing remote operation but omits a material target such as a remote path, local destination, or device, obtain that information rather than guessing. Do not add `--overwrite` unless the user specifically authorizes replacement.

## Retry

- The wrapper automatically retries a known pre-execution transport failure up to three times after the initial attempt. Every retry uses the exact same RemoteCmdClient arguments and device.
- Retry only when the audit output explicitly says the remote command did not begin, such as `Execution failed before the command completed` or `Remote command file is not ready`.
- Do not automatically retry a remote command that started, completed with a non-zero exit code, timed out after execution began, or has an ambiguous outcome. Repeating such a command could duplicate a state change.
- `-MaxRetries` controls the wrapper retry limit from 0 through 3 and defaults to 3. Do not issue additional manual retries after the wrapper stops unless the user explicitly asks.

## Records

Each invocation creates a timestamped folder under `runs/`. It contains the overall `request.json`, `stdout.txt`, `stderr.txt`, and `result.json`, plus per-attempt `attempt-NN.stdout.txt`, `attempt-NN.stderr.txt`, and `attempt-NN.result.json`. Report the final result, attempt count, and record folder after each invocation.
