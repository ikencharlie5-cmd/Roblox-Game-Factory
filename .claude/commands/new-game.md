---
description: Start a new Roblox game from an idea — writes a 1-page spec for approval
argument-hint: <game idea>
---
New game idea: $ARGUMENTS

1. Pick a short kebab-case slug for the game.
2. Run `bash scripts/new-game.sh <slug> "<Game Name>"`.
3. Fill in `games/<slug>/SPEC.md` using `docs/SPEC_TEMPLATE.md`. Be decisive — pick
   real numbers, real upgrade names, real pass ideas. One page max.
4. Commit, then STOP and send Charlie a short message: the one-liner, the core loop, and
   any questions. Do not start building until he approves.
