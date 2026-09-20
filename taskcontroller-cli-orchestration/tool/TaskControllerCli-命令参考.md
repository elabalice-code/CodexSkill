# TaskControllerCli Command Reference

All mutating commands preview by default. Add `--write` to persist a validated change with a `.bak` backup. Global options are `--data-dir <dir>`, `--format table|json`, `--encoding auto|utf8|utf8bom|system`, `--no-color`, `--quiet`, and `--yes`.

## Inspection And Validation

| Command | Table form | JSON form |
|---|---|---|
| Status | `status --data-dir .\samples\basic` | `status --data-dir .\samples\basic --format json` |
| Validation | `validate --strict --data-dir .\samples\basic` | `validate --strict --data-dir .\samples\basic --format json` |
| List tasks | `task list --status NotStart` | `task list --status NotStart --format json` |
| Show a task | `task show prepare` | `task show prepare --format json` |
| List relations | `relation list` | `relation list --format json` |
| Generate equations | `equation generate` | `equation generate --format json` |
| Analyze paths | `equation paths` | `equation paths --format json` |

## Preview And Write Commands

| Command | Preview | Persisted form |
|---|---|---|
| Set task status | `task set-status prepare Done` | `task set-status prepare Done --write` |
| Set relation | `relation set prepare review` | `relation set prepare review --write` |
| Reconcile relations | `reconcile` | `reconcile --write` |
| Plan tasks | `plan --strategy random --seed 42 --count 2` | `plan --strategy random --seed 42 --count 2 --write` |
| Tree add | `task tree add root report` | `task tree add root report --write` |
| Dictionary | `dict add artifact` | `dict add artifact --write` |
| Staff | `staff add operator-c` | `staff add operator-c --write` |

## Export

```powershell
TaskControllerCli export schedule --output .\schedule.csv
TaskControllerCli export excel --output .\schedule.xlsx
TaskControllerCli export schedule --output .\schedule.csv --format json
TaskControllerCli export excel --output .\schedule.xlsx --format json
```

Exit codes: `0` success, `1` parameter error, `2` data error, `3` validation error, `4` business conflict, `5` write/export error, `10` internal error.
