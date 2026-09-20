---
name: taskcontroller-cli-orchestration
description: Use the bundled TaskController CLI to validate task data, maintain dependency-aware task trees, and create fine-grained, role-assigned execution plans. Use for TaskControl planning and CLI operations, not for changing the CLI implementation.
metadata:
  short-description: TaskControl CLI task orchestration
---

# TaskController CLI Orchestration

Use this skill to operate TaskControl task data through its CLI. It includes a verified, framework-dependent `TaskControllerCli-0.1.2.zip` release package and a PowerShell launcher; no source checkout or Visual Studio installation is required to run the bundled tool.

## Start here

1. Run `scripts/run-taskcontroller-cli.ps1` with a data directory and CLI arguments.
2. Inspect the current data with `status`, then run `validate --strict` before any write.
3. Treat a command without `--write` as a preview. Use `--write` only after reviewing that preview and confirming the requested target.

Example:

```powershell
$skill = '<this skill folder>'
& "$skill\scripts\run-taskcontroller-cli.ps1" `
  -DataDir 'D:\work\task-data' -- validate --strict --format json
```

The launcher expands the package to `tool/` on first use. This generated directory is not source data; remove it only when deliberately refreshing the bundled release.

## Safe task-data workflow

- Preserve the user's existing data and generated files. Write commands create `.bak` backups, but a backup is not permission to overwrite unrelated work.
- Never issue a write command until strict validation succeeds. Re-run strict validation after tree or relation changes.
- Exports that overwrite a file require `--yes`; set a specific `--output` path and do not overwrite unless requested.
- Use `reconcile --write` only to persist reviewed status/relation normalization, then validate again.
- Use `task tree rename <old> <new> --write` for renames so dependencies are updated. Do not edit task names directly in JSON.

Read [references/cli-commands.md](references/cli-commands.md) for command forms and [references/data-model-and-safety.md](references/data-model-and-safety.md) before mutations or data recovery work.

## Planning and delegation

For a new engineering task, create semantic module nodes such as specification, implementation, quality, and delivery; module nodes are organizational and normally have no executor. Break modules into independently verifiable leaf tasks, then assign each leaf's `Executor` to the requested role. Keep role names out of task names.

Use parent-child hierarchy for decomposition and relations for ordering constraints. Add another subtree when a leaf is still a multi-step deliverable, rather than giving a broad task an executor prematurely. A task is execution-ready only when its output, owner, dependencies, and verification criterion are clear.

Use `plan --strategy clever --count <N> --write` to start currently unblocked work. After a deliverable is complete, set it to `Done`, then run `plan` again to unlock its successors.

Read [references/modular-task-planning.md](references/modular-task-planning.md) when creating or reviewing a task breakdown.

## Build and regression work

This skill operates the release package. If the request is to modify the TaskController CLI itself, work in the source repository and use its build/test workflow instead. See [references/cli-commands.md](references/cli-commands.md) for the known source location and regression commands.
