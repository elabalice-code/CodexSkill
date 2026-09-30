---
name: fastsignaltrace-lacpp
description: Trace Linux/Android (LA) and ordinary C/C++ source signals with FastSignalTraceLACpp, including struct function-pointer callbacks, cross-function dependencies, and complete signal consumption paths. Use for LA C++ trace, C/C++ signal equations, or producer/consumer analysis; use SourceInsightCli for caller/callee queries and the UEFI sibling for firmware-specific protocol semantics.
---

# LA C/C++ signals

LA means Linux/Android source analysis; the bundled tool runs on Windows x64 without a separate .NET installation. Select this skill directly for an explicit LA C/C++ request, or use the top-level `fastsignaltrace` router (`-Language Auto`, or explicit `-Language Lacpp`). Ordinary C/C++ routes here; UEFI metadata retains firmware routing priority.

Run `scripts/invoke.ps1 -SourceRoot <root> -EquationOutput <file> -VariablesOutput <file> -Detailed`.
The wrapper uses `assets/fastsignaltrace-lacpp.exe`; the output includes an evidence sidecar and manifest.
Version 2.1 echoes full signal consumption chains by default, including when equation files are written. Loops have complete member/internal-edge definitions. For machine-only equations use the executable's explicit `--equations-only`; for very large stdout preserve raw bytes with redirection/compression rather than imposing a hidden path limit.
Read [the manual](references/使用手册.md) for supported options and limitations.

The current engine is tolerant and flow-insensitive. Include/macros and build configuration are not evaluated. Report candidate and unresolved facts explicitly, especially when framework API table implementations are outside the source root. Field binding alone is not execution. Equation read/input is Producer and write/output is Consumer by project convention; caller/callee direction is independent.

Validate equation/TSV closure. When source calling paths are requested, run the sibling SourceInsightCli against the same root and compare callsite IDs rather than deriving calls from signal equations.
