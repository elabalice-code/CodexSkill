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

## Execution and Retry

- If a target command or script is running, do not submit a duplicate command until it finishes. If the client returns or times out while the target's execution status is unknown, check whether the target is still running before submitting it again.
- Once the target finishes, continue any further diagnostics, fixes, and tests within the user's authorized task as needed.
- The wrapper automatically retries a known pre-execution transport failure up to three times after the initial attempt. Every retry uses the exact same RemoteCmdClient arguments and device.
- `-MaxRetries` controls the wrapper retry limit from 0 through 3 and defaults to 3.

## Records

Each invocation creates a timestamped folder under `runs/`. It contains the overall `request.json`, `stdout.txt`, `stderr.txt`, and `result.json`, plus per-attempt `attempt-NN.stdout.txt`, `attempt-NN.stderr.txt`, and `attempt-NN.result.json`. Report the final result, attempt count, and record folder after each invocation.
