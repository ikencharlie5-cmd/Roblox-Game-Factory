---
description: Stages 2–5 — the 3 branches build, Manager resolves questions, Checker reviews. No questions to Charlie.
argument-hint: <slug>
---
Run the full pipeline for `games/$ARGUMENTS`. Do NOT ask Charlie anything.
Commit + push after every numbered step so the website updates.

1. **Branches.** `python3 scripts/status.py $ARGUMENTS stage branches`, set all 3 branches
   to `waiting`, then launch the **gameplay**, **graphics**, and **ui** subagents IN PARALLEL
   (one message, three Agent calls), each told the slug.
2. **Manager loop.** If `games/$ARGUMENTS/QUESTIONS.md` has open items (no ✅):
   a. `status.py $ARGUMENTS stage manager` → **manager** subagent decides.
   b. **ideas** subagent (Job B) turns decisions into instructions.
   c. `status.py $ARGUMENTS stage branches` → re-run only the affected branch subagents
      (in parallel), telling them to apply the new SPEC instructions.
   Repeat at most 2 times.
3. **Checker.** `status.py $ARGUMENTS stage checker` → **checker** subagent.
   If FAIL: send each issue to its branch subagent (parallel) to fix, then run checker again.
   Max 3 checker rounds. Remaining issues → "Known issues" in the game README.
4. **Ship.** Fill `games/$ARGUMENTS/README.md` (how to play, how to publish, Charlie TODO),
   `status.py $ARGUMENTS stage done`, push, and confirm CI is green (`gh run list`, fix if red).
5. Message Charlie in 3 lines max: what was built, where the .rbxl is, his TODO.
