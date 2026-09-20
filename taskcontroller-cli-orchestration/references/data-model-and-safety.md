# Data model and mutation safeguards

Task data normally lives in a directory containing `data.json`, `TaskRelyData.json`, `TaskBlocks.json`, `dict.txt`, and `staff.txt`. The CLI supports legacy field names such as `Task_Unit` and preserves file compatibility when it writes.

## Before and after any write

1. Confirm the intended `--data-dir`; never write into a checked-in or shared sample unless that is explicitly the target.
2. Run `validate --strict` and stop on errors.
3. Run the requested command without `--write` to inspect its preview.
4. Repeat with `--write` only after the preview matches the request.
5. Run `validate --strict` again. Keep CLI-generated `.bak` files unless the user explicitly requests cleanup.

The CLI uses validated write paths and produces a `.bak` backup on writes. This does not make direct JSON editing safe: it can bypass dependency synchronization and create data that strict validation rejects.

## Relations and names

Relations refer to task names. Dependencies must not be self-referential, circular, or connect ancestors and descendants. Use `relation list` to inspect them and `relation set` to change them. Rename through `task tree rename` so relationship references are synchronized.

Use `reconcile` to preview or persist status/relationship normalization. Do not use it as a substitute for resolving an actual design conflict.
