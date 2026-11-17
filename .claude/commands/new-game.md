---
description: Stage 1 — Ideas lead designs a new game from an idea and stops for Charlie's OK
argument-hint: <game idea>
---
New game idea: $ARGUMENTS

1. Pick a short kebab-case slug. Run `bash scripts/new-game.sh <slug> "<Game Name>" "<idea>"`.
2. Use the **rnd** subagent (Job A) to research the idea online → `research/RESEARCH.md`.
3. `python3 scripts/status.py <slug> stage ideas`, then the **ideas** subagent (Job A) writes
   the full SPEC.md using RESEARCH.md + inspiration.
4. `python3 scripts/status.py <slug> stage approval`
5. Commit + push (`git add -A && git commit -m "<slug>: spec" && git push`).
6. STOP. Send Charlie: the pitch, the core loop (4 lines), any questions, and
   "Reply ok, then run /build <slug>".
