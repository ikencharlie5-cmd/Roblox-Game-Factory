# Quality checklist (Checker — technical). The Manager also signs off with docs/GOOD_GAME_CHECKLIST.md.

## Works
- [ ] `scripts/check.sh <slug>` passes (format, lint, build)
- [ ] New player can understand what to do within 60s without reading anything
- [ ] Every remote is validated server-side (types, ranges, cooldowns, affordability)
- [ ] Data saves on leave + autosave + BindToClose; new fields have defaults
- [ ] No infinite yields: every WaitForChild has a reason to exist
- [ ] No `while true` without a `task.wait`

## Feels good
- [ ] Every purchase/reward has feedback (sound, tween, or particles)
- [ ] Numbers are formatted (1.2K, 3.4M) via `Shared/Format`
- [ ] UI works on phone (Scale sizing, buttons ≥ 44px, nothing off-screen)

## Earns
- [ ] At least 2 Game Passes and 1 Dev Product wired up (IDs may be placeholders)
- [ ] Daily reward works and is saved
- [ ] There's always a next goal visible on screen

## Shippable
- [ ] `games/<slug>/README.md` has: how to play, how to publish, Charlie TODO
- [ ] `DECISIONS.md` lists every call made without asking
