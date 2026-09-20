# CLI commands and release use

## Bundled package

`assets/TaskControllerCli-0.1.2.zip` is the verified framework-dependent release package. Use `scripts/run-taskcontroller-cli.ps1 -DataDir <directory> -- <CLI arguments>`; the script expands the package locally on first run and forwards the exact process exit code.

The CLI writes previews by default. Append `--write` only to persist a reviewed change. Global options include `--data-dir <dir>`, `--format table|json`, `--encoding auto|utf8|utf8bom|system`, `--no-color`, `--quiet`, and `--yes`.

## Recommended sequence

```powershell
# Read only
& $runner -DataDir $data -- status --format json
& $runner -DataDir $data -- validate --strict --format json
& $runner -DataDir $data -- task list --format json

# Preview, then persist a reviewed operation
& $runner -DataDir $data -- task set-status DefineInputOutputContract Done --format json
& $runner -DataDir $data -- task set-status DefineInputOutputContract Done --write --format json
& $runner -DataDir $data -- validate --strict --format json
```

## Common commands

```powershell
# Tasks and tree
& $runner -DataDir $data -- task list --status NotStart
& $runner -DataDir $data -- task show DefineInputOutputContract --format json
& $runner -DataDir $data -- task tree add ParentTask ChildTask --write
& $runner -DataDir $data -- task tree rename OldTaskName NewTaskName --write

# Dependencies, status, and scheduling
& $runner -DataDir $data -- relation list --format json
& $runner -DataDir $data -- relation set UpstreamTask DownstreamTask --write
& $runner -DataDir $data -- reconcile --write
& $runner -DataDir $data -- plan --strategy clever --count 3 --write --format json

# Exports
& $runner -DataDir $data -- export schedule --output 'D:\work\schedule.csv' --yes
& $runner -DataDir $data -- export excel --output 'D:\work\schedule.xlsx' --yes
```

Known exit codes: `0` success; `1` argument error; `2` data/format error; `3` validation error; `4` business conflict; `5` write/export error; `10` internal error.

## Modifying the CLI implementation

The source repository is `D:\Task_Panel\0_ElabAlice\6_TaskTool\workspace\AliceTaskTool`. Build there with:

```powershell
.\build-cli.ps1 -Configuration Release
.\test-winforms-baseline.ps1
.\test-release-package.ps1
```

Use the repository's documentation and current test parameters when the latter two scripts require explicit paths.
