---
name: fastwavget
description: "Extract exact millisecond WAV segments from long WAV, MP4, or other Windows-decodable media with the bundled fastwavget.exe. Use when Codex needs to cut a known utterance from a long regression recording, align audio with Replay/log timestamps, feed only a selected segment to FastSTT, or reuse a proven Deck-accepted utterance when synthesized speech repeatedly fails Deck admission."
---

# FastWavGet

Use the bundled executable:

```powershell
$tool = Join-Path $env:USERPROFILE '.codex\skills\fastwavget\scripts\fastwavget.exe'
& $tool <input> <output.wav> <startMs> <endMs>
```

All times are milliseconds. Require `endMs > startMs`. The output is always WAV; an end time beyond the media duration is truncated automatically.

## Extract a verified utterance

1. Identify the authoritative source recording and its time origin. Do not assume wall-clock time equals media offset; convert from Replay time or use the source timeline.
2. Prefer an utterance that previously crossed the application's `UserWavs` boundary. Use its saved UserWav directly when available; otherwise cut the corresponding interval from the original long input/AEC recording.
3. Include modest leading and trailing context, normally 300–800 ms, so the first and last phonemes are not clipped.
4. Run `fastwavget.exe` with absolute paths.
5. Inspect the output duration and format. For offline AIA harnesses, normalize only if the application requires a specific format such as 16 kHz, mono, PCM16.
6. Verify the extracted speech with FastSTT. Ignore known hallucinations in pure silence, but require the intended utterance to appear in the voiced interval.

## Build a Deck-safe Nokws harness

When FastTTS speech repeatedly produces physical energy but no Deck wave:

1. Keep timing/silence and unrelated prompts from the existing harness.
2. Replace only the rejected prompt with a clip taken from the original long regression audio that was previously accepted by Deck.
3. Concatenate segments without changing their order. Use a WAV combiner that normalizes formats consistently.
4. Name the result with `Nokws` when the launch path intentionally bypasses KWS gating.
5. Verify the final composite with FastSTT before launching.
6. During the run, require evidence in this order before judging the target feature:

```text
UserWav
-> committed user turn
-> intended tool call
-> target Claim
-> target transition request
```

If the utterance does not cross `UserWavs`, report `ATTACK_INPUT_NOT_ACCEPTED`; do not classify the target engine as PASS or FAIL.

## Command example

```powershell
$tool = Join-Path $env:USERPROFILE '.codex\skills\fastwavget\scripts\fastwavget.exe'
& $tool 'D:\media\long.wav' 'D:\media\archive-list.wav' 417500 422000
```

Quote paths containing spaces or non-ASCII characters. Use FFmpeg for general format conversion rather than treating this extractor as a transcoder.
