<#
.SYNOPSIS
    fastdeai.ps1 - thin PowerShell wrapper around the self-contained fastdeai.exe.

.DESCRIPTION
    fastdeai strips AI-flavored formatting noise from a Markdown document
    (decorative emoji, blockquotes, rules, emphasis, inline code, bold, etc.)
    while protecting fenced code blocks verbatim. See SKILL.md for the full
    rule set and verified gotchas.

    This wrapper adds ONE convenience the exe lacks: batch processing of a
    whole directory. Single-file use is forwarded verbatim to fastdeai.exe,
    so semantics are byte-for-byte identical.

    Core = fastdeai.exe (self-contained, .NET 9 single-file, no runtime needed).
    Source of truth: 0_FastTool/17_FastDeai/workspace/fastdeai_src/fastdeai/*.cs

.USAGE
    # passthrough (identical to calling the exe directly)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File fastdeai.ps1 <input.md> [output.md]

    # batch: clean every *.md under a directory (skip *_out.md outputs)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File fastdeai.ps1 -Batch <dir> [-Recurse]
#>

# PositionalBinding=$false + ValueFromRemainingArguments: positional args
# (input/output file paths) flow into $PassThruArgs for passthrough mode and
# are NEVER bound to the named $Batch. $Batch/$Recurse are name-only flags.
[CmdletBinding(PositionalBinding=$false)]
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$PassThruArgs,
    [string]$Batch,
    [switch]$Recurse
)

$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot 'fastdeai.exe'

if (-not (Test-Path -LiteralPath $exe)) {
    [Console]::Error.WriteLine("fastdeai.exe not found next to wrapper: $exe")
    exit 3
}

# --- batch mode: clean every .md in a directory, skipping generated _out.md ---
if ($Batch) {
    if (-not (Test-Path -LiteralPath $Batch)) {
        [Console]::Error.WriteLine("Batch directory not found: $Batch")
        exit 3
    }
    $files = if ($Recurse) {
        Get-ChildItem -LiteralPath $Batch -Filter *.md -Recurse -File
    } else {
        Get-ChildItem -LiteralPath $Batch -Filter *.md -File
    }
    $ok = 0; $skip = 0; $fail = 0
    foreach ($f in $files) {
        if ($f.Name -like '*_out.md') { $skip++; continue }   # don't re-clean outputs
        & $exe $f.FullName *> $null
        if ($LASTEXITCODE -eq 0) { $ok++ } else { $fail++ }
    }
    [Console]::WriteLine("Batch done. Cleaned: $ok / Skipped(_out): $skip / Failed: $fail")
    exit 0
}

# --- passthrough mode: forward all positional args to the exe as-is ---
& $exe @PassThruArgs
exit $LASTEXITCODE
