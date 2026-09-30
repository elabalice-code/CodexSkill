---
name: source-insight-cli
description: Expand complete C/C++ calling chains from Main through every callee with SourceInsightCli, including Linux/Android source and struct function-pointer callbacks. Use for caller/callee queries, callback bindings, call paths and LR call graphs; it does not automate commercial Source Insight.
---

# C/C++ calling

For complete chains, run the bundled Windows x64 tool through the wrapper (no separate .NET installation required):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill>/scripts/invoke.ps1" -SourceRoot "D:\Code" -OutputFile "D:\Result\calling-chains.txt"
```

The wrapper echoes every established calling path and optionally saves the same text. Preserve complete stdout/stderr in the user's result directory; large outputs can be redirected or compressed without removing paths. Do not replace full results with a sample or silently set numeric limits. Report complete/truncated flags and unresolved targets alongside the result.

Use `assets/SourceInsightCli.exe index <source-root> --output <index-dir>`, then `symbols`, `callees`, `callers`, `path`, `graph` or `bindings`. Read [the manual](references/使用手册.md) for command syntax.

For direct complete echo, run `assets/SourceInsightCli.exe <source-root>`; no index step is needed. `--output` additionally saves the same result and does not silence stdout. Self-contained DLL packages are distributed under repository releases/cpp with a local runtime.

Use symbol IDs when names are ambiguous. Every arrow means caller to callee, including callers results; binding or registration is not an execution edge. All branches and candidates expand by default with no depth/path/node cutoff. Use `chains --index <dir> --output <file>` for complete root-to-end calling chains across the index. Recursion is an explicit Loop terminal; missing framework code stays visibly unresolved. Numeric limits are opt-in and any omission returns exit code 5.

This version is a tolerant conditional-union analyzer, not a configured compiler or runtime trace. Check manifest/diagnostics and truncated flags. Reindex after source changes. Keep outputs outside the source root and preserve source files.

For signal producer/consumer dependencies and equations, use the sibling `fastsignaltrace-lacpp` skill. Signal consumption paths and calling paths answer different questions; do not infer execution edges from signal equations.
