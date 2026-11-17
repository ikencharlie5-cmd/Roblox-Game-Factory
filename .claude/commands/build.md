---
description: Stages 2–6 — the 4 branches build, Manager resolves questions, Checker reviews, Manager signs off. No questions to Charlie.
argument-hint: <slug>
---
Run the full pipeline for `games/$ARGUMENTS`. Do NOT ask Charlie anything.
Commit + push after every numbered step so the website updates.

1. **Branches.** `python3 scripts/status.py $ARGUMENTS stage branches`, set all 4 branches
   to `waiting`, then launch the **gameplay**, **graphics**, **ui**, and **audio** subagents IN
   PARALLEL (one message, four Agent calls), each told the slug and to read their section of
   `research/RESEARCH.md`.
2. **Manager loop.** If `games/$ARGUMENTS/QUESTIONS.md` has open items (no ✅):
   a. `status.py $ARGUMENTS stage manager` → **manager** subagent decides. If a question needs
      outside knowledge, first run the **rnd** subagent (Job B) on it.
   b. **ideas** subagent (Job B) turns decisions into instructions.
   c. `status.py $ARGUMENTS stage branches` → re-run only the affected branch subagents
      (in parallel), telling them to apply the new SPEC instructions.
   Repeat at most 2 times.
3. **Checker.** `status.py $ARGUMENTS stage checker` → **checker** subagent.
   If FAIL: send each issue to its branch subagent (parallel) to fix, then run checker again.
   Max 3 checker rounds. Remaining issues → "Known issues" in the game README.
4. **Manager sign-off.** `status.py $ARGUMENTS stage signoff` → **manager** subagent runs the
   "Final sign-off" (docs/GOOD_GAME_CHECKLIST.md → SIGNOFF.md). If NEEDS WORK: send each ❌ to its
   branch (parallel), then Checker again, then sign-off again. Max 3 rounds; leftovers go in
   "Known issues" in the README.
5. **Ship.** Fill `games/$ARGUMENTS/README.md` (how to play, how to publish, Charlie TODO),
   `status.py $ARGUMENTS stage done`, push, and confirm CI is green (`gh run list`, fix if red).
6. Message Charlie in 3 lines max: what was built, where the .rbxl is, his TODO.
