---
name: fasttts
description: Synthesize supplied text into a WAV file on Windows, including timed pauses, using the bundled FastTTS utility. Use when a local audio asset is needed; do not use for transcription, audio editing, or combining existing audio.
---

# FastTTS

Create a WAV from user-supplied text with the bundled Windows executable:

```powershell
& "$env:USERPROFILE\.codex\skills\fasttts\scripts\fasttts.exe" \
  "Text to synthesize<0.5s>after a timed pause" \
  "D:\\path\\to\\output.wav"
```

Pass exactly two arguments: non-empty text and an output path ending in `.wav`. Create the output in the user-requested or current project location; do not overwrite an existing audio asset unless the user asked to do so. Verify that the command succeeds and that the WAV was created before reporting completion.

## Speech source

By default, FastTTS uses Volc online TTS when both `VOLC_RT_APP_ID` and `VOLC_RT_ACCESS_TOKEN` are present in the process environment; otherwise it uses installed Windows voices. Do not expose environment-variable values in terminal output or responses.

Set the following only when the user asks for deterministic/local synthesis or voice selection:

```powershell
$env:FASTTTS_FORCE_LOCAL = '1'       # bypass online TTS
$env:FASTTTS_LOCAL_LANG = 'zh'       # or en; Chinese input still selects zh
$env:FASTTTS_LOCAL_GENDER = 'female' # female, male, or neutral
```

For online voice selection, preserve any existing credentials and use the requested settings through `FASTTTS_VOLC_SPEAKER`, `FASTTTS_VOLC_SPEAKER_ZH`, or `FASTTTS_VOLC_SPEAKER_EN`. The endpoint and cluster may be set through `FASTTTS_VOLC_TTS_URL` and `FASTTTS_VOLC_TTS_CLUSTER` when the user's environment requires them.

## Mandatory FastSTT validation

After every successful FastTTS synthesis, validate the generated WAV with the
workspace FastSTT executable before reporting completion:

```powershell
$fastStt = "D:\Task_Panel\19_APO_Next\138_Rag_Extend\workspace\00_STATUS\debug_workflow\faststt\faststt.exe"
& $fastStt --lang auto --prompt "<expected non-silent spoken text>" "D:\path\to\output.wav"
```

Use `--lang zh` for Chinese or Chinese-mixed requests, including English product
names spoken inside Chinese; use `--lang auto` only when the language is truly
unknown. Keep `--prompt` limited to the expected non-silent spoken text.

FastSTT accepts only 16 kHz WAV input. Inspect the generated WAV first; when
its sample rate differs, create a temporary 16 kHz PCM validation copy and
leave the delivered FastTTS WAV unchanged:

```powershell
ffmpeg -n -i "D:\path\to\output.wav" -ar 16000 -ac 1 -c:a pcm_s16le "D:\temp\output.faststt-16k.wav"
& $fastStt --lang auto --prompt "<expected non-silent spoken text>" "D:\temp\output.faststt-16k.wav"
```

Use a unique temporary path and remove the validation copy after recording the
result; never replace the delivered WAV.

If a long deliberate `<Ns>` pause causes FastSTT to return no transcription,
validate each intended non-silent speech segment in separate temporary 16 kHz
clips, using the explicit pause timings to select the clips. Preserve every
spoken segment in at least one clip: a phrase after `<30s>` is speech to verify,
not trailing silence to discard. Do not use generic silence removal, because it
can mistake an intentional pause between phrases for the end of the WAV. Do not
treat an empty result as a pass, and do not change the delivered WAV. If any
spoken segment still has no evidence of its intended content, report failed
validation.

Check that the transcription provides evidence for the intended non-silent
speech: the wake phrase, requested content, and closing phrase when present.
Use the supplied text as the short `--prompt` to improve recognition of product
names and mixed-language requests. Do not fail validation solely for
hallucinated words from deliberate `<Ns>` silence segments; only the spoken
portions determine whether the generated audio is valid. Report the FastSTT
result together with the created WAV path. If the spoken content is absent or
materially wrong, do not call the WAV valid; retry only with authorization or
report the failed validation.

## Text and output

Use `<Ns>` in the text for a silent pause of `N` seconds; `N` may be decimal, such as `<5s>` or `<0.5s>`. The pause marker is not spoken. Quote text and paths so Chinese, spaces, and punctuation are preserved.

The tool defaults to a 3× output gain. `FASTTTS_GAIN` is an optional multiplier of that baseline and can clip loud 16-bit PCM audio, so change it only when the user requests a volume adjustment. The tool requires Windows and an installed, enabled system voice when local mode is selected.
