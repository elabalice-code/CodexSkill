---
name: pm-agent
description: Bootstrap and govern one or more projects as a PM-Agent, including resolving project locations, preparing project structure, maintaining TaskController data, cloning owner-provided Git repositories, and starting Codex work. Use when PMAgent must turn owner-approved project goals into controlled workspaces and executable task flows, including a complete batch bootstrap request.
---

# PM-Agent

Build this skill incrementally from owner-verified project operations. Preserve confirmed environment facts and authorization boundaries; do not generalize a single directory example into an unrelated machine-wide convention.

## Role contract

PM-Agent turns an owner-approved objective into a controlled, dependency-aware, verifiable delivery flow. It owns project-state coherence, task readiness, sequencing, risk visibility, decision traceability, execution handoffs, and acceptance evidence.

PM-Agent may choose reversible operating details inside confirmed scope, such as inspection order, task granularity, validation steps, and the least-privilege tool mode. It must not invent business goals, approve scope changes for the owner, create unconfirmed people or roles, conceal tool limitations with manual data edits, or declare work complete without observable evidence.

For active project governance, read [references/pm-governance-loop.md](references/pm-governance-loop.md). Use the specialized sections below only when the request involves creating a project folder, deploying a cockpit, initializing TaskController data, downloading source code, launching Codex, or performing the complete batch bootstrap.

## Resolve a sibling project directory

### Project-folder creation command

Treat a clear instruction matching `请建立<PROJECT_NAME>项目文件夹` as authorization to complete both operations in the same turn:

1. Calculate the absolute project path from the real filesystem hierarchy described below.
2. Verify that the shared parent exists and that the resolved target remains directly beneath it.
3. Create exactly one empty directory at the calculated target when it does not exist.
4. If the target already exists as a directory, leave it unchanged and report that fact. If it exists as a file or resolves outside the expected parent, stop and report the conflict.
5. Verify the created path and report the result.

Do not pause for a second path-confirmation round when the project name and hierarchy are unambiguous. This command authorizes only the empty project directory: do not create a cockpit, source tree, TaskController data, or any other contents unless separately instructed.

When the owner asks for a new project beside the current main-task directory, calculate the target from the real filesystem hierarchy:

1. Resolve the current working directory to an absolute path. Treat the actual directory name as authoritative when conversational wording contains a typo.
2. Treat the current working directory's parent as the main-task directory.
3. Treat the main-task directory's parent as the container shared by sibling projects.
4. Join the owner-provided new project name to that shared container.
5. If the owner only asks where the project should be located, report the computed absolute path and wait. If the owner gives the project-folder creation command above, create the empty directory in the same turn.

Use path-aware operations such as PowerShell `Split-Path`, `Join-Path`, and `[IO.Path]::GetFullPath()` when executing this calculation. Do not rely on manual string replacement.

### Confirmed project example

```text
Current working directory:
D:\Task_Panel\0_ElabAlice\Ex_AgentPM\workspace

Main-task directory:
D:\Task_Panel\0_ElabAlice\Ex_AgentPM

Shared parent for sibling projects:
D:\Task_Panel\0_ElabAlice

Owner-provided project name:
DemoProject

Approved target:
D:\Task_Panel\0_ElabAlice\DemoProject
```

The intended relationship is:

```text
D:\Task_Panel\0_ElabAlice\
+-- Ex_AgentPM\
|   +-- workspace\
+-- DemoProject\
```

### Spelling and parsing invariants

- The physical working-folder name is `workspace`. Preserve this exact spelling whenever deploying a cockpit.
- In Markdown or rich-text input, `Task\_Panel` and similar escaped underscores represent the filesystem name `Task_Panel`; the backslash before `_` is formatting escape syntax, not an extra path character.
- A sibling of `Ex_AgentPM` is created under `D:\Task_Panel\0_ElabAlice`, not inside `Ex_AgentPM\workspace` and not inside `Ex_AgentPM`.
- A request to calculate or confirm a path authorizes no filesystem mutation. The explicit project-folder creation command authorizes creation of the empty directory only, not scaffolding its contents.

## Prepare a reusable cockpit template

Before copying a cockpit into a new project, audit the source template as data, not merely as a folder structure. For this environment, the confirmed source is:

```text
E:\Librarian\AgentController
```

The source contains a workspace-level `README.md`, an inner `00_STATUS` directory with canonical startup, objective, status, decision, risk, handoff, and team-role files, plus the empty engineering directories `0_Codes/`, `1_UserInpus/`, and `999_Docs/`.

1. List the exact source contents and read every template document before copying it.
2. Search at least for the owner-identified legacy anchors `NAS`, `Claude`, and `GLM`. Extend the scan with project-specific names discovered during reading; the confirmed contamination also included Android AutoTest, AICaller, STVSync, Hermes, DeepSeek, PPQA, old roles, dates, and decisions.
3. For a template intended to be an empty shell, remove project facts rather than renaming them to the new project. Preserve the generic file purpose and governance instructions.
4. Reset role tables, decisions, status, risks, and handoffs to neutral placeholders. Do not carry model names, team members, historical events, deliverable counts, or project-specific policies into a new project.
5. Re-scan the complete template and require zero legacy-anchor hits before treating it as reusable.

Keep cleanup and deployment as separate authorities. Permission to sanitize the shared template does not by itself authorize copying it into a destination project or creating additional project structure.

### Packaged cockpit asset

The sanitized snapshot bundled with this skill is:

```text
assets/AgentController.zip
```

The archive contains `README.md`, `00_STATUS/`, `0_Codes/`, `1_UserInpus/`, and `999_Docs/` at its root; it does not add an outer `AgentController/` directory. The three engineering directory entries are retained even while empty. This layout allows an authorized deployment to extract directly into a project root.

Before deployment, inspect the archive entries and reject absolute paths or `..` traversal. Check the destination for conflicts and do not overwrite existing project files unless the owner explicitly authorizes replacement. Extracting the asset is a separate mutation from creating an empty project folder and requires its own instruction.

### Cockpit creation command

Treat a clear instruction matching `在<TARGET_FOLDER>文件夹下建立驾驶舱` as authorization to deploy the bundled cockpit in the same turn:

1. Resolve `TARGET_FOLDER` to the exact absolute destination project directory and require that it already exists as a directory.
2. Set the final cockpit root to `<TARGET_FOLDER>\workspace`. The spelling `workspace` is required for this command.
3. Stop on any existing `<TARGET_FOLDER>\workspace` path unless the owner separately authorizes merging or replacement. Do not silently overwrite a previous cockpit.
4. Inspect `assets/AgentController.zip` before extraction. Reject absolute entries, `..` traversal, an unexpected outer directory, missing `README.md`, missing `00_STATUS/README.md`, missing canonical `00_STATUS/01_本轮目的.md` or `00_STATUS/02_当前状态.md`, or missing engineering directory entries.
5. Create an isolated temporary directory under a verified safe temp root. Extract the archive contents into a temporary `AgentController` directory.
6. Rename the extracted temporary `AgentController` directory to `workspace`.
7. Copy that complete `workspace` directory under `TARGET_FOLDER`, producing `<TARGET_FOLDER>\workspace\README.md`, `<TARGET_FOLDER>\workspace\00_STATUS\...`, and the three engineering directories.
8. Verify the final file inventory and confirm the copied documents still contain no legacy project anchors.
9. After successful verification, delete only the resolved temporary extraction directory. Never delete or move the source asset or destination cockpit during cleanup.

This command authorizes deployment of the packaged generic cockpit only. Do not personalize objectives, roles, status, or other project facts unless the owner also requests initialization of those documents.

### Confirmed sanitized template state

On 2026-09-03, the shared template was sanitized and aligned with the project startup agreement. Its canonical structure is:

```text
E:\Librarian\AgentController\README.md
E:\Librarian\AgentController\00_STATUS\README.md
E:\Librarian\AgentController\00_STATUS\01_本轮目的.md
E:\Librarian\AgentController\00_STATUS\01_current_objective.md
E:\Librarian\AgentController\00_STATUS\02_当前状态.md
E:\Librarian\AgentController\00_STATUS\02_current_status.md
E:\Librarian\AgentController\00_STATUS\03_decision_log.md
E:\Librarian\AgentController\00_STATUS\04_open_issues_and_risks.md
E:\Librarian\AgentController\00_STATUS\05_agent_handoff_log.md
E:\Librarian\AgentController\00_STATUS\06_team_roles_and_responsibilities.md
E:\Librarian\AgentController\0_Codes\
E:\Librarian\AgentController\1_UserInpus\
E:\Librarian\AgentController\999_Docs\
```

The canonical startup order is `00_STATUS/README.md` → `01_本轮目的.md` → `02_当前状态.md`. The old English objective and status files are compatibility pointers only. The post-cleanup scan returned zero hits for the identified legacy project and model terms. The verified packaged snapshot has SHA-256 `0B87FAA3AC07541A7CBEC1CD905CBB966A2468AA1FC58A9D7B5018577C158D63`. Re-check the source at repackaging time because a shared template may change after this observation.

## Initialize TaskController data

When the owner asks to initialize TaskController management for a project, treat the project directory itself as the data directory unless they specify another location. Do not place task data inside `workspace` merely because the cockpit lives there.

1. Confirm the exact data directory and inventory the managed files: `data.json`, `TaskRelyData.json`, `TaskBlocks.json`, `dict.txt`, and `staff.txt`.
2. Inspect the installed TaskController CLI help for a documented `init` or `create` command.
3. If `data.json` exists, require `validate --strict` to pass before any mutation. If it is missing, record the expected validation failure and use only the CLI's documented initialization path; do not manufacture a file merely to satisfy the pre-check.
4. Run initialization without `--write` first. Review the root task, schema, conflicts, and every `create` or `preserve` action. Persist only when the preview exactly matches the request.
5. After writing, require `validate --strict`, `status`, and `task show <root-name>` to succeed. Verify there is exactly one intended root task with a stable ID.
6. If neither `init` nor `create` exists, stop without creating task files. Do not copy sample data or handwrite JSON as a fallback; those approaches bypass schema, stable-ID, relation-file, and atomic-write guarantees.
7. Record a missing or insufficient capability for the CLI developer with the tested artifact, commands, exit codes, target preconditions, expected contract, and acceptance criteria.

### Preserve existing dictionary and staff

Use the documented `--preserve-existing` mode only for the narrow partial-initialization state where all three core JSON files are missing and `dict.txt` and/or `staff.txt` already exist.

1. Record the hashes, byte lengths, and last-write times of existing `dict.txt` and `staff.txt`; do the same for the cockpit if one exists.
2. Preview `init --root-name <name> --preserve-existing --format json`.
3. Require exactly three `create` actions for `data.json`, `TaskRelyData.json`, and `TaskBlocks.json`; require existing auxiliary files to be `preserve` and `conflicts` to be empty.
4. Repeat with `--write`, then perform the post-write checks above.
5. Recheck hashes, byte lengths, and last-write times. Existing auxiliary files and the complete `workspace` tree must be unchanged.

If only some core JSON files exist, stop on the CLI conflict. Do not use `batch import` to turn a root-task naming request into an opaque five-file replacement.

### Current capability gate

The portable release bundled with this skill supports `init`, the `create` alias, and `init --preserve-existing` even though `--version` still reports `TaskControllerCli 0.1.0`:

```text
assets/TaskControllerCli/TaskControllerCli.exe
```

Keep all five files in `assets/TaskControllerCli/` together: `TaskControllerCli.exe`, its `.config`, `TaskController.Core.dll`, `TaskController.Infrastructure.dll`, and `DocumentFormat.OpenXml.dll`. Copying only the EXE is not a portable runtime deployment.

Verified EXE SHA-256: `FFB6680DD673D71808CE16E14CFEE806E0109A0CCEF81A6F2B883717316EC62A`. The bundled files match the Release build that implemented the documented initialization behavior. The implementation and edge-case contracts are recorded in the source repository under `TaskControllerCli/docs/TC-FB-002_目标目录一键初始化任务数据.md` and `TC-FB-003_不完整任务目录补全初始化与总任务命名.md`.

For the confirmed DemoProject layout, task data belongs directly under `D:\Task_Panel\0_ElabAlice\DemoProject`; its `workspace` directory is unrelated content that initialization must preserve. This project was successfully initialized with the single root task `维护DemoProject工程` through `--preserve-existing` on 2026-09-03.

## Download source code

### Source-download command

Treat a clear instruction matching `下载代码 <GIT_URL>` as authorization to clone exactly the owner-provided Git repository into the active project's `workspace\0_Codes` directory in the same turn.

This command authorizes the network clone and creation of that repository's destination directory. It does not authorize running repository code, executing setup scripts, installing dependencies, initializing submodules, changing branches, pulling an existing checkout, or modifying files after the clone.

1. Resolve the active workspace. If the instruction names a project, use that project's `<PROJECT>\workspace`; otherwise require the current working root to contain both `00_STATUS/` and the expected project structure.
2. Resolve the destination parent as `<WORKSPACE>\0_Codes` and verify its absolute path remains inside the intended workspace. Create `0_Codes` if it alone is missing from an otherwise confirmed workspace.
3. Validate that `GIT_URL` is one repository location supplied by the owner. Reject an empty value, a value beginning with `-`, embedded shell syntax, or multiple URLs. Pass it to Git as one argument rather than interpolating it into a generated shell command.
4. Derive the default repository directory name from the Git URL, removing only the final `.git` suffix. Resolve the final destination directly under `0_Codes` and reject traversal or an empty name.
5. If the destination already exists, stop. Do not reinterpret `下载代码` as `git pull`, merge, reset, delete, or overwrite.
6. Run the equivalent of `git clone -- <GIT_URL> <DESTINATION>` without `--recurse-submodules`. Preserve Git's normal authentication prompts or failures; do not expose credentials in logs.
7. Verify the clone with `git -C <DESTINATION> rev-parse --show-toplevel`, `git remote get-url origin`, `git rev-parse HEAD`, the active branch, and `git status --short`. The resolved top level and origin must match the requested destination and repository.
8. Report the destination, origin, branch, and commit. Record them in the project handoff or current status when this clone is part of an active managed project.

If cloning fails and Git leaves a partial directory, report its exact path and stop. Do not recursively delete it without separately confirming the cleanup target and authority.

## Launch a Codex task

Use `codex exec` when PM-Agent must start a non-interactive Codex task from a script or parent-agent workflow. The official behavior and flags are documented in [OpenAI Docs: Non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode).

Treat a clear owner instruction to have Codex start a named task as authorization for one Codex run scoped to that task. It does not authorize unrelated work, broader filesystem access, or additional agents.

### Establish the execution contract

Before launching, make these fields explicit in the prompt:

- objective and exact deliverable;
- working directory and in-scope paths;
- allowed mutations and prohibited actions;
- required validation;
- completion report or handoff format.

Use the project's `workspace` as `codex exec -C <dir>` when that directory directly contains `00_STATUS/`. Do not point `-C` at the outer project folder merely because TaskController data lives there. Before starting, require these files at the execution root:

```text
00_STATUS/README.md
00_STATUS/01_本轮目的.md
00_STATUS/02_当前状态.md
```

If any are missing, repair or redeploy the cockpit before starting substantive work. A process that starts but cannot read its control documents has not passed project-startup validation.

### Choose permissions and session behavior

- Use `--sandbox read-only` for inspection, smoke tests, planning, or review.
- Use `--sandbox workspace-write` only when the delegated task requires edits inside the workspace.
- Do not use `danger-full-access` or bypass approvals unless the owner explicitly authorizes that broader boundary and the environment is controlled.
- Use `--ephemeral` for disposable smoke tests. Omit it for real work that may need `codex exec resume <SESSION_ID>`.
- Use `--skip-git-repo-check` only after confirming the target is an intended non-Git project directory.
- Use `--json` when PM-Agent needs machine-readable lifecycle events and the `thread_id`; use `-o <path>` only when a durable final-message artifact is required.

On Windows, prompts that require reading Chinese UTF-8 documents should tell the executor to set PowerShell console output encoding to UTF-8 and use `Get-Content -Encoding UTF8`. This prevents successful reads from becoming unusable mojibake in captured command output.

Example read-only smoke test:

```powershell
codex exec `
  --ephemeral `
  --json `
  --sandbox read-only `
  --skip-git-repo-check `
  -C 'D:\Task_Panel\0_ElabAlice\DemoProject\workspace' `
  '<bounded read-only startup check>'
```

### Verify that the task actually started

Do not equate process creation with task startup. For JSONL mode require all of the following:

1. CLI process exits with code `0`.
2. Output contains `thread.started` and a captured `thread_id`.
3. Output contains `turn.started` followed by `turn.completed`.
4. No `turn.failed` or terminal `error` event appears.
5. The final agent message reports the requested verification result.
6. For write-enabled work, independently inspect the deliverable and run its required tests before changing the TaskController task to `Done`.

Warnings about optional plugin catalog synchronization are not automatically fatal when the required task events complete successfully. Record them when they affect requested tools or outputs; otherwise judge completion from the lifecycle events and deliverable verification.

The confirmed 2026-09-03 smoke test used `codex-cli 0.151.0-alpha.7.2`, `--sandbox read-only`, `--ephemeral`, `--json`, and `-C D:\Task_Panel\0_ElabAlice\DemoProject\workspace`. It exited `0`, read all three control documents, and completed the turn without modifying files.

## Fully bootstrap multiple tasks

### Complete-task command

Treat a clear instruction matching the following form as one batch authorization to prepare every named project through all five project-startup capabilities in this skill:

```text
全面建立任务<PROJECT_1>、<PROJECT_2>……。<GIT_URL>
```

For example, `全面建立任务TaskDemo1、TaskDemo2、TaskDemo3。<GIT_URL>` names three sibling projects and one repository URL to clone independently into all three projects.

`GIT_URL` is mandatory. Parse and validate it before any filesystem write, network request, TaskController mutation, or Codex launch. If the text after the final separator is absent, blank, still a placeholder such as `<git url>` or `<GIT_URL>`, contains more than one URL, or cannot be unambiguously separated from the project names, stop the entire command immediately and ask the owner to provide one Git URL. Do not create even the empty project folders while waiting.

### Preflight the whole batch

Complete all read-only preflight checks before creating the first project:

1. Parse a non-empty, unique ordered list of project names. Reject path separators, `.` / `..`, rooted paths, invalid filename characters, and names that resolve anywhere except directly beneath the confirmed shared sibling-project parent.
2. Resolve and report every absolute project path using the sibling-directory rules above. Require every target not to exist; any file or directory conflict stops the whole batch before writes.
3. Validate the Git URL under the Source-download command rules and, when credentials permit, use a read-only remote check such as `git ls-remote` to catch an inaccessible repository before creating projects. Never expose embedded credentials in output.
4. Confirm that Git and Codex are available, `assets/AgentController.zip` passes its structure and traversal checks, and a TaskController CLI with the required `init` behavior is available.

This complete command supplies the separate mutation authority normally required by the project-folder, cockpit, TaskController initialization, source-download, and Codex-start sections. Do not pause between those stages for repeated authorization when preflight succeeds.

### Execute each project completely

Process projects in the owner's listed order. Finish and validate all stages for one project before starting the next:

1. Create the empty sibling project root.
2. Deploy the bundled cockpit as `<PROJECT>\workspace` and verify the canonical startup files and engineering directories.
3. Initialize TaskController in `<PROJECT>`, not in `workspace`. Use the exact project name as the single root-task name unless the owner supplied another naming rule. Preview first, write only after the preview matches, then run `validate --strict`, `status`, and `task show`.
4. Clone the same supplied Git repository into `<PROJECT>\workspace\0_Codes\<repository>` and perform all source-download verification.
5. Run one bounded, read-only, ephemeral Codex startup check from `<PROJECT>\workspace`. Its prompt must only verify the three startup documents and report readiness; the complete-task command does not invent or execute an unspecified business task. Require the full successful lifecycle evidence defined above.

Apply batch-wide fail-fast only to Git download: if `git clone` or a required post-clone Git verification fails for any project, stop immediately and do not begin later projects. Report completed projects, the failed Git stage and exact residual paths, and projects not started; do not automatically delete, overwrite, reset, pull, or reclone the failed checkout.

For cockpit, TaskController, Codex, and other non-Git stages, do not stop the whole batch merely because of the first operational error. Diagnose the cause, make a safe in-scope correction, and retry or resume the current stage when this neither destroys project data nor expands authority. Exact temporary artifacts created solely by this command may be cleaned after their paths and contents are verified. If a non-Git failure cannot be safely recovered, record that project as incomplete and continue with independent later projects when doing so cannot compound the failure; stop only when continued execution would be unsafe or genuinely requires new authority. Never pretend the batch was atomic or complete.

### Batch completion evidence

The command is complete only when every named project has all of the following evidence:

- its resolved project root and `workspace` path;
- the required cockpit files and engineering directories;
- valid TaskController data, exactly one intended root task, and strict validation with no issues;
- the cloned repository destination, verified origin, branch, commit, and clean initial status;
- a Codex startup run with exit code `0`, `thread.started`, `turn.started`, and `turn.completed`, with no terminal failure.

Return a per-project result table or equally explicit report. These are task-ready execution paths; starting substantive Codex work still requires an objective, deliverable, scope, permissions, validation, and handoff contract.
