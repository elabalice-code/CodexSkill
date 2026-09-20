---
name: elabalice
description: Personal Elabalice skill group index. Use when the user explicitly invokes $elabalice or asks Codex to locate, organize, or apply Elabalice-provided skills and workflows.
---

# Elabalice

## Overview

This skill indexes the Elabalice skill group. The individual skills are registered as top-level Codex skills under `$HOME\.codex\skills\`.

## Registered Skills

- `session-startup-flow`: elabalice new-session startup protocol.
- `pm-danger-signal`: PM risk escalation and dependency checks.
- `fastsearch`: Boolean CLI search for large projects.
- `fastdeai`: Clean AI-style Markdown formatting noise.

## Intake

When the user provides more Elabalice skill material, preserve the provided structure where reasonable, register complete skills at `$HOME\.codex\skills\<skill-name>`, keep `SKILL.md` concise, and move detailed instructions into `references/` only when they are too large or conditional.
