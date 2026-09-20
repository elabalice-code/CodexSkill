---
name: adb
description: Use the bundled Android Debug Bridge on Windows to discover, inspect, and monitor Android devices. Prefer the read-only wrapper for diagnostics; use direct adb only when the user explicitly authorizes a device-changing operation.
---

# ADB

Use this skill for Android device discovery, system-property inspection, performance snapshots, logs, and bounded monitoring. The bundled Windows binary is `scripts/adb/adb.exe`; its adjacent DLLs are required at runtime.

## Safe default

Run commands through `scripts/invoke-adb-readonly.ps1`. It accepts device selection plus a constrained set of non-mutating host and shell commands, and rejects shell metacharacters and known mutation options.

```powershell
$ro = '<skill-dir>/scripts/invoke-adb-readonly.ps1'
& $ro -AdbArguments @('devices', '-l')
& $ro -AdbArguments @('-s', '<serial>', 'get-state')
& $ro -AdbArguments @('-s', '<serial>', 'shell', 'getprop', 'ro.build.version.release')
& $ro -AdbArguments @('-s', '<serial>', 'shell', 'top', '-H', '-b', '-n', '1')
```

Pass an explicit string array as shown so PowerShell does not reinterpret adb options such as `-a` or `-n` as wrapper parameters.

When more than one device is present, always select one with `-s <serial>`. Keep monitoring bounded by a sample count or a host-side timeout. Record the exact serial and command used when reporting observations.

## Safety boundary

- Device discovery and reads are authorized when requested: `devices`, `get-state`, selected `shell` diagnostics, snapshots, and log reads.
- Do not install/uninstall, push, delete, remount, root, reboot, change settings or properties, clear data/logs, inject input, alter networking/forwarding, or start an unbounded capture unless the user explicitly requests that operation.
- Even with authorization, resolve the target serial first and explain material device effects before running a mutation.
- If the wrapper rejects a needed read-only command, inspect it and extend the narrow allowlist instead of bypassing the wrapper casually.

## Direct binary

Use `scripts/adb/adb.exe` directly only for an explicitly authorized operation outside the read-only wrapper. Do not assume that a request to inspect or validate a device authorizes changes.

The extensionless `scripts/adb/adb` is the supplied Linux x86_64 build and is retained for portability; on Windows use `adb.exe`.
