# Roblox Game Factory — instructions for Claude

You build complete, publishable Roblox games in this repo with minimal input from Charlie
(studio: **Chiken Studios** — spelled "Chiken", never "Chicken").

## The only two checkpoints with Charlie
1. **Spec approval.** For a new idea, write `games/<slug>/SPEC.md` from `docs/SPEC_TEMPLATE.md`
   (one page max), then STOP and ask Charlie to OK it. Ask any questions in that same message.
2. **Done.** After approval, build the whole game without asking anything else.
   Make reasonable calls yourself and log each one in `games/<slug>/DECISIONS.md`.

Never stop mid-build to ask. If something is truly blocked (e.g. needs an asset ID or a
Game Pass ID), use a placeholder in `Config.luau`, list it under "Charlie TODO" in
`games/<slug>/README.md`, and keep going.

## Workflow
1. `/new-game <idea>` → run `scripts/new-game.sh <slug>`, fill in SPEC.md, stop for approval.
2. `/build <slug>` (after OK) → follow `docs/BUILD_PLAN.md` phase by phase, committing after each.
3. Before saying done: pass every item in `docs/QUALITY_CHECKLIST.md`, run the checks below,
   and fill out `games/<slug>/README.md` (how to play, how to publish, Charlie TODO).

## Checks (run all; fix until clean)
```
bash scripts/check.sh <slug>     # stylua --check, selene lint, rojo build
```
If a tool isn't installed locally, CI (`.github/workflows/build.yml`) runs them on push —
push, then read the Actions result with `gh run view` and fix failures.

## Code rules (short version — full list in docs/ROBLOX_RULES.md)
- Luau with `--!strict` at the top of every module. Rojo project layout from `template/`.
- Server is authoritative: never trust client values for money, damage, or rewards.
- All tunable numbers live in `src/shared/Config.luau`.
- Build world geometry and UI **in code** (no Studio-only assets), so the game works straight
  from `rojo build`.
- Keep files under ~300 lines; one Service per system in `src/server/Services/`.
- Save data with `DataService` only. Never call DataStore elsewhere.

## Charlie's preferences
- Keep messages to him short.
- He wants games that can earn: always include Game Passes / Dev Products stubs, a daily
  reward, and a clear progression loop that hooks in the first 60 seconds.
