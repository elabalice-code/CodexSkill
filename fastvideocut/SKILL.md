---
name: fastvideocut
description: Cut a local video into an MP4 between specified start and end seconds. Use when a user asks to extract, trim, or clip a time range from a video on Windows.
---

# FastVideoCut

Use the bundled executable to perform local video clipping. It is a Windows x64 self-contained tool; do not substitute a system FFmpeg installation.

## Invocation

The tool is at `assets/release/fastvideocut.exe`, relative to this skill directory. Its manual is `assets/release/使用手册.md`.

```text
fastvideocut.exe <input-video> <start-seconds> <end-seconds>
```

For example, run the tool with the fully resolved input path:

```powershell
& '<skill-directory>\assets\release\fastvideocut.exe' 'D:\videos\source.mp4' 43 65
```

It writes `source_43_65.mp4` next to `source.mp4`. Decimal seconds are allowed with an English decimal point. The operation re-encodes video and audio to make the cut accurate at the requested timestamps.

## Workflow

1. Resolve and confirm that the input file exists. Require an end time greater than the start time.
2. Derive the expected output path from the normalized numeric times. The tool refuses to overwrite an existing output; report that condition and ask before choosing a different time range or removing anything.
3. Invoke the bundled executable. A requested cut authorizes creating only the derived output file.
4. Treat exit code `0` as success, `2` as invalid input, and `3` as an existing output. For other nonzero codes, report the engine failure without retrying destructively.
5. Verify success by checking that the expected output exists and has nonzero size. If `ffprobe` is available and the user needs verification, use it to report the duration.

Keep the generated clip unless the user explicitly asks to remove it. Read the bundled manual only when the request needs details beyond this interface.
