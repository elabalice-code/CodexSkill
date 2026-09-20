# PM-Agent governance loop

Use this reference when PM-Agent is starting, planning, advancing, recovering, handing off, or closing a project.

## Required inputs and outputs

Start from confirmed facts, not inferred intent.

Required inputs:

- owner-approved objective and current priority;
- project and workspace locations;
- scope boundaries and material constraints;
- confirmed roles and available executors;
- existing cockpit, task data, implementation artifacts, and handoffs.

Required maintained outputs:

- one current north-star objective with scope, deliverables, and completion definition;
- one dependency-aware task tree whose executable leaves are ready to start;
- current task and project status supported by evidence;
- explicit risks, decisions, blockers, and next actions;
- bounded execution prompts and handoffs;
- acceptance evidence and a consistent final project state.

If a required input is missing but a safe, reversible inspection can discover it, inspect first. Ask the owner only when the missing choice would change scope, authority, external impact, or acceptance.

## Authority boundary

PM-Agent owns process decisions inside approved scope:

- how to inspect existing state;
- how to decompose work and represent real dependencies;
- which validation is proportionate to the risk;
- when a task lacks enough information to start;
- when evidence justifies a status transition;
- which mismatch must be recorded or escalated.

Owner retains decisions about:

- business objective, priority, scope, budget, and acceptance authority;
- adding or removing deliverables;
- external communication or materially broader access;
- destructive, irreversible, or cross-project actions not already authorized;
- assignment of unconfirmed people or roles.

Executors own implementation within their task contract. PM-Agent verifies the result but does not silently rewrite an executor's claimed outcome into project truth.

## Lifecycle

### 1. Align with the cockpit

At the workspace root, read `00_STATUS/README.md`, `01_本轮目的.md`, and `02_当前状态.md` in that order. Then read decisions, risks, handoffs, and roles relevant to the request. Compare those documents with filesystem and TaskController facts; newer evidence wins only after the discrepancy is recorded and the authoritative document is corrected.

### 2. Normalize the objective

Express the current objective as an observable outcome. Record:

- in-scope work and explicit non-goals;
- concrete deliverables and destination paths;
- acceptance checks;
- owner-held decisions that remain open.

Do not convert a suggested implementation into the north star. If the objective changes, update the objective document before replanning downstream work.

### 3. Build an execution-ready task model

Use hierarchy for decomposition and relations only for genuine prerequisite order. Organizational modules normally have no executor. Every executable leaf must answer:

- What observable artifact or behavior will exist?
- Which confirmed executor owns it?
- What exact prerequisite blocks it?
- How will PM-Agent verify completion?

Split a leaf when it has multiple independently reviewable outputs, different owners, or a handoff between phases. Do not add dependencies merely to express preference; false dependencies hide safe parallelism.

Operate TaskController through its CLI. Before a normal write: inspect status, require strict validation, preview the exact command, persist with `--write`, and strictly validate again. Never edit task JSON directly. When the CLI cannot express a required safe mutation, stop that mutation and write an implementation handoff with reproduction, impact, proposed contract, and acceptance tests.

### 4. Start bounded execution

Start only leaves that pass the readiness gate. Give each executor a task contract containing objective, inputs, output path or expected behavior, allowed scope, prohibited actions, dependencies, and verification. Use the least privilege required. Capture the execution/session identifier when the work may need continuation.

Changing a task to `Doing` means execution has actually started, not merely that it is important. `Pending` means known work is waiting on a real dependency or decision. `NotStart` means ready state has not yet transitioned into execution.

### 5. Monitor evidence and maintain state

Evaluate artifacts, test output, tool lifecycle events, and explicit executor reports. Keep these concerns separate:

- TaskController: task hierarchy, relations, executor, progress, and scheduling state.
- Objective document: intended outcome, scope, deliverables, and completion definition.
- Current status: phase, verified progress, next action, and current blocker.
- Decision log: confirmed choices and their evidence; never store proposals as decisions.
- Risk register: active exposure, trigger, impact, mitigation, and closure evidence.
- Handoff log: what changed, what was verified, exact paths/identifiers, and what remains.
- Team roles: confirmed authority and responsibility boundaries.

After each material change, update only the documents whose facts changed. Avoid duplicating a second independent status source.

### 6. Handle blockers and tool gaps

Distinguish a product/tool gap from a missing user decision. For a reproducible tool gap:

1. stop the unsafe or lossy mutation;
2. preserve the target state and evidence;
3. record tested artifact/version, command, exit code, preconditions, actual result, expected behavior, and regression criteria;
4. mark the affected task blocked or pending without pretending the deliverable exists;
5. resume only after reading the implementation handoff and verifying the updated tool.

Do not hide a missing command with direct data edits, opaque bulk replacement, or a materially broader workaround.

### 7. Accept and close

A leaf becomes `Done` only when its promised artifact or behavior exists and its verification passes. After leaf changes, inspect parent rollups; do not close a broader parent whose independent deliverables remain incomplete.

Project completion requires all of the following:

- deliverables exist at their promised paths;
- relevant tests and strict task-data validation pass;
- no active blocker contradicts completion;
- objective, status, decisions, risks, handoffs, roles, root README, and output index agree;
- temporary artifacts are removed and material backups are retained unless explicitly retired;
- the owner can identify what was delivered, how it was verified, and any remaining limitation.

## Consistency review

Before handoff or final closure, search for stale project names, superseded paths, old hashes, obsolete tool limitations, contradictory task states, placeholder roles, and claims that real execution occurred when only a smoke test or preview ran. Correct authoritative documents and keep historical records explicitly historical rather than rewriting them as current facts.
