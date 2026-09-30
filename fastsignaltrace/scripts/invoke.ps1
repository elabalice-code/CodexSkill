param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,
    [string]$EquationOutput,
    [string]$VariablesOutput,
    [string[]]$Exclude,
    [switch]$Detailed,
    [ValidateSet("Auto", "CSharp", "Godot", "RustTauri", "Uefi", "Lacpp")]
    [string]$Language = "Auto"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath($SourceRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    [Console]::Error.WriteLine("SourceRoot does not exist: $root")
    exit 2
}

$excludedNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($name in @(".git", ".vs", ".godot", "bin", "obj", "node_modules", "target", "dist", "artifacts", "packages", "vendor", "TestResults")) {
    [void]$excludedNames.Add($name)
}
foreach ($name in @($Exclude)) { if ($name) { [void]$excludedNames.Add($name) } }

$counts = @{ CSharp = 0; Godot = 0; Rust = 0; TypeScript = 0; C = 0; Cpp = 0; Header = 0; UefiMeta = 0 }
$markers = @{ CSharp = $false; Godot = $false; Cargo = $false; Package = $false; Tauri = $false; Uefi = $false }
$directories = [Collections.Generic.Stack[string]]::new()
$directories.Push($root)

while ($directories.Count -gt 0) {
    $directory = $directories.Pop()
    try {
        foreach ($child in [IO.Directory]::EnumerateDirectories($directory)) {
            $name = [IO.Path]::GetFileName($child)
            if ($excludedNames.Contains($name)) { continue }
            if ($name.Equals("src-tauri", [StringComparison]::OrdinalIgnoreCase)) { $markers.Tauri = $true }
            if ($name -in @("MdePkg", "MdeModulePkg", "UefiCpuPkg", "ArmPkg", "ArmPlatformPkg", "QcomPkg", "ShellPkg")) { $markers.Uefi = $true }
            $directories.Push($child)
        }

        foreach ($file in [IO.Directory]::EnumerateFiles($directory)) {
            $name = [IO.Path]::GetFileName($file)
            $extension = [IO.Path]::GetExtension($file).ToLowerInvariant()
            switch ($extension) {
                ".cs" { $counts.CSharp++ }
                ".gd" { $counts.Godot++ }
                ".rs" { $counts.Rust++ }
                ".ts" { $counts.TypeScript++ }
                ".tsx" { $counts.TypeScript++ }
                ".c" { $counts.C++ }
                ".cc" { $counts.Cpp++ }
                ".cpp" { $counts.Cpp++ }
                ".cxx" { $counts.Cpp++ }
                ".hpp" { $counts.Header++ }
                ".hxx" { $counts.Header++ }
                ".hh" { $counts.Header++ }
                ".h" { $counts.Header++ }
                ".dsc" { $counts.UefiMeta++; $markers.Uefi = $true }
                ".dec" { $counts.UefiMeta++; $markers.Uefi = $true }
                ".inf" { $counts.UefiMeta++; $markers.Uefi = $true }
                ".fdf" { $counts.UefiMeta++; $markers.Uefi = $true }
                ".sln" { $markers.CSharp = $true }
                ".csproj" { $markers.CSharp = $true }
            }
            if ($name.Equals("project.godot", [StringComparison]::OrdinalIgnoreCase)) { $markers.Godot = $true }
            elseif ($name.Equals("Cargo.toml", [StringComparison]::OrdinalIgnoreCase)) { $markers.Cargo = $true }
            elseif ($name.Equals("package.json", [StringComparison]::OrdinalIgnoreCase)) { $markers.Package = $true }
            elseif ($name.Equals("tauri.conf.json", [StringComparison]::OrdinalIgnoreCase) -or $name.Equals("tauri.conf.json5", [StringComparison]::OrdinalIgnoreCase)) { $markers.Tauri = $true }
            elseif ($name.Equals("Uefi.h", [StringComparison]::OrdinalIgnoreCase) -or $name.Equals("PiPei.h", [StringComparison]::OrdinalIgnoreCase)) { $markers.Uefi = $true }
        }
    }
    catch [UnauthorizedAccessException] { continue }
    catch [IO.IOException] { continue }
}

[Console]::Error.WriteLine(("DetectedFiles: CSharp={0}, GDScript={1}, Rust={2}, TypeScript={3}, C={4}, Header={5}, UefiMeta={6}, Cpp={7}" -f $counts.CSharp, $counts.Godot, $counts.Rust, $counts.TypeScript, $counts.C, $counts.Header, $counts.UefiMeta, $counts.Cpp))

$selected = $Language
if ($selected -eq "Auto") {
    $hasRustProject = $markers.Cargo -or $markers.Tauri
    if ($markers.Uefi -and ($markers.Godot -or $markers.Tauri)) {
        [Console]::Error.WriteLine("Ambiguous source root: both UEFI and Godot/Tauri project markers were found. Narrow the root or set -Language explicitly.")
        exit 5
    }
    elseif ($markers.Uefi) { $selected = "Uefi" }
    elseif ($markers.Godot -and $hasRustProject) {
        [Console]::Error.WriteLine("Ambiguous source root: both Godot and Cargo/Tauri project markers were found. Narrow the root or set -Language explicitly.")
        exit 5
    }
    elseif ($hasRustProject -and $markers.CSharp) {
        [Console]::Error.WriteLine("Ambiguous source root: both CSharp and Cargo/Tauri project markers were found. Narrow the root or set -Language explicitly.")
        exit 5
    }
    elseif ($markers.Godot) { $selected = "Godot" }
    elseif ($hasRustProject) { $selected = "RustTauri" }
    elseif ($markers.CSharp -and $counts.CSharp -gt 0) { $selected = "CSharp" }
    else {
        $scores = @{
            CSharp = $(if ($counts.CSharp -gt 0) { 1 } else { 0 })
            Lacpp = $(if (($counts.C + $counts.Cpp + $counts.Header) -gt 0) { 1 } else { 0 })
            Godot = $(if ($counts.Godot -gt 0) { 1 } else { 0 })
            RustTauri = $(if (($counts.Rust + $counts.TypeScript) -gt 0) { 1 } else { 0 }) + $(if ($markers.Package) { 1 } else { 0 })
        }
        $supported = @($scores.GetEnumerator() | Where-Object Value -gt 0)
        if ($supported.Count -eq 0) {
            [Console]::Error.WriteLine("No supported source files were found.")
            exit 3
        }
        $highest = ($supported | Measure-Object -Property Value -Maximum).Maximum
        $winners = @($supported | Where-Object Value -eq $highest)
        if ($winners.Count -ne 1) {
            [Console]::Error.WriteLine(("Ambiguous source root. Scores: CSharp={0}, Godot={1}, RustTauri={2}, Lacpp={3}. Narrow the root or set -Language explicitly." -f $scores.CSharp, $scores.Godot, $scores.RustTauri, $scores.Lacpp))
            exit 5
        }
        $selected = $winners[0].Key
    }
}

if (($selected -eq "CSharp" -and $counts.CSharp -eq 0) -or
    ($selected -eq "Godot" -and $counts.Godot -eq 0) -or
    ($selected -eq "RustTauri" -and ($counts.Rust + $counts.TypeScript) -eq 0) -or
    ($selected -eq "Uefi" -and ($counts.C + $counts.Header) -eq 0) -or
    ($selected -eq "Lacpp" -and ($counts.C + $counts.Cpp + $counts.Header) -eq 0)) {
    [Console]::Error.WriteLine("Selected language $selected has no matching source files in $root")
    exit 3
}

[Console]::Error.WriteLine("SelectedLanguage=$selected")
$skillsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$childName = switch ($selected) {
    "CSharp" { "fastsignaltrace-csharp" }
    "Godot" { "fastsignaltrace-godot" }
    "RustTauri" { "fastsignaltrace-rusttauri" }
    "Uefi" { "fastsignaltrace-uefi" }
    "Lacpp" { "fastsignaltrace-lacpp" }
}
$childScript = Join-Path $skillsRoot "$childName\scripts\invoke.ps1"
if (-not (Test-Path -LiteralPath $childScript -PathType Leaf)) {
    [Console]::Error.WriteLine("Child skill is missing: $childScript")
    exit 4
}

$invokeParameters = @{ SourceRoot = $root }
if ($EquationOutput) { $invokeParameters.EquationOutput = [IO.Path]::GetFullPath($EquationOutput) }
if ($VariablesOutput) { $invokeParameters.VariablesOutput = [IO.Path]::GetFullPath($VariablesOutput) }
if ($Exclude) { $invokeParameters.Exclude = $Exclude }
if ($Detailed) { $invokeParameters.Detailed = $true }

& $childScript @invokeParameters
exit $LASTEXITCODE
