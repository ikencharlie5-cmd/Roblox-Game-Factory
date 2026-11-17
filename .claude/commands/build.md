---
description: Build an approved game end to end with no further questions
argument-hint: <slug>
---
Build `games/$ARGUMENTS` from its approved SPEC.md.

- Follow `docs/BUILD_PLAN.md` phase by phase. Commit and push after each phase.
- Follow `CLAUDE.md` and `docs/ROBLOX_RULES.md`.
- Do NOT ask Charlie anything. Log every judgment call in `games/$ARGUMENTS/DECISIONS.md`;
  put anything only he can do (asset IDs, pass IDs, publishing) under "Charlie TODO" in
  the game's README.
- Finish only when `bash scripts/check.sh $ARGUMENTS` passes (or CI is green) and every box
  in `docs/QUALITY_CHECKLIST.md` is ticked.
- Final message to Charlie: 3 lines max — what was built, where the .rbxl is, his TODO list.
