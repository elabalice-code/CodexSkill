---
name: callme-session
description: Leave a callable contact script in the current workspace root, queue a prompt into an existing Codex thread, and retain a durable audit copy. Use when another script, person, or process must hand off a message to a Codex session.
---

# Callme Session

Use `scripts/callme.ps1` (or `scripts/callme.cmd` from cmd/Explorer) to enqueue a prompt with `codex queue`. The skill stores audit files under its own `audits/` directory, so it does not depend on the current project workspace.

## Workspace contact script (required)

Every use of this skill must leave a callable PowerShell script in the current workspace root before the task is considered complete. A Markdown contact note by itself does not satisfy this requirement.

- Use the workspace root supplied by the current environment; use the current working directory only when no separate workspace root is available.
- Create or update `callme.ps1` in that root. If an existing `callme.ps1` is unrelated to this skill, preserve it and instead create `callme-<thread-id>.ps1` in the same root.
- Resolve the target Thread ID from an explicitly supplied value, then `CODEX_THREAD_ID`, then `CODEX_SESSION_ID`. Embed the validated UUID as a literal in the workspace script; never invent one.
- Make the exact prompt the first positional parameter. The workspace script must forward it unchanged to this skill's `scripts/callme.ps1` with the embedded value passed through `-Thread`.
- Keep the workspace script as a thin wrapper; do not duplicate `codex queue` or audit-writing logic in it.
- Verify that the workspace script exists and parses as valid PowerShell. Do not send a test queue message merely to validate the wrapper.
- If the workspace root is not writable or no valid Thread ID is available, report the blocker instead of claiming completion.

## Delivery contract

- Queue into an existing thread with `codex queue --thread <THREAD_ID> --message <PROMPT>`; do not use `codex resume` as a delivery mechanism.
- Pass the exact prompt as the first positional argument. It is user content, not a command to reinterpret.
- Use `-Thread` when supplied. Otherwise, the script accepts a valid UUID from `CODEX_THREAD_ID`, then `CODEX_SESSION_ID`; it must fail rather than invent a thread ID.
- The script writes an audit record before queueing. If delivery fails, report that archival succeeded but delivery was not confirmed.
- `-NoQueue` is available for a deliberate audit-only run. It does not test or deliver a queued message.

## Invocation

```powershell
& "$env:USERPROFILE\.codex\skills\callme-session\scripts\callme.ps1" "Please review the handoff." -Thread <thread-id>
```

The `.cmd` wrapper forwards all arguments to the PowerShell script and contains no delivery logic.
