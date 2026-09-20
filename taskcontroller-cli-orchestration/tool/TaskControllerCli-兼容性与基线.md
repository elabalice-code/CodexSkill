# TaskControllerCli Compatibility And Baseline

## Scope

`TaskControllerCli/samples/basic` is a desensitized, deterministic sample directory. It contains `data.json`, `TaskRelyData.json`, `TaskBlocks.json`, `dict.txt`, and `staff.txt` and must be used for automated CLI regression.

## Legacy Tree Compatibility

The legacy `data.json` structure is retained:

- Tree node fields: `Value`, `Task_Unit`, `Children`; `Parent` is rebuilt in memory and is not written.
- `Task_Unit` fields: `Id`, `TaskName`, `Executor`, `WorkTime`, `StartRestrict`, `EndRestrict`, `Inputs`, `Outputs`, `ReferenceExePath`, `Progress`, `ProgressedWorkTime`, and numeric `Status`.
- Status numeric values: `0=NotStart`, `1=Doing`, `2=Done`, `3=Pending`, `4=Abort`.
- Relation values use task names; the CLI normalizes comma and semicolon variants into de-duplicated semicolon semantics.

## Schema And Unknown Fields

- Missing `schemaVersion` denotes legacy data. The next successful CLI write adds `"schemaVersion": 1`.
- The CLI accepts schema version `1` and rejects a newer version before making any write.
- Unknown properties at the tree, node, and `Task_Unit` levels are preserved when a tree is loaded and written by the same CLI operation. Managed fields always use the current CLI value.

## Baseline Expectations

| Check | Expected result |
|---|---|
| `status --format json` | `taskCount=3`, all five sample files exist, `NotStart=3` |
| `validate --strict` | no issues, exit code `0` |
| `equation paths` | `prepare -> review` is a path |
| `plan --strategy random --seed 42 --count 2` | stable result for identical input and seed |
| `reconcile` without `--write` | no source-file modification |
| `export schedule` | UTF-8 CSV with one header plus three task rows |

## Legacy Loader Evidence

The legacy WinForms assembly was rebuilt with the supplied VS2022 MSBuild and loaded the desensitized sample through its original `TreeNode<string>.Load` method without starting a form. The observed static baseline is three tasks (`root`, `prepare`, `review`), `NotStart=3`, and one `prepare -> review` relation.

An STA-only, no-`Application.Run` legacy-baseline host also invoked the original private reconciliation and scheduling operations in an isolated copied sample directory. Its deterministic result was `Pending=2`, `Doing=1`, one `prepare -> review` relation, and a one-day legacy schedule with `prepare` assigned to `operator-a` and `review` assigned to `operator-b`. The CLI clever write path now applies prerequisite gating and the same status result. Exact legacy CSV layout remains a separate comparison item.

`test-winforms-baseline.ps1` is the golden comparison gate. It creates independent legacy and CLI sample copies, then checks equal task count, status counts, normalized relations, and the schedule task-membership result of the legacy daily CSV and CLI schedule export.

## Regression Commands

```powershell
$exe = '.\TaskControllerCli.exe'
$data = '.\samples\basic'
& $exe status --data-dir $data --format json
& $exe validate --strict --data-dir $data --format json
& $exe equation paths --data-dir $data --format json
& $exe plan --data-dir $data --strategy random --seed 42 --count 2 --format json
& $exe export schedule --data-dir $data --output .\schedule.csv --format json
```
