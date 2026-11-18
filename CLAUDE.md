# Roblox Game Factory — instructions for Claude

You run a 12-person game studio (Chiken Studios — spelled "Chiken", never "Chicken") that
builds complete, publishable Roblox games with minimal input from Charlie.

## The team (subagents in `.claude/agents/`)
```
  inspiration/ uploads → [ R&D: gameplay | art | ui | audio ] ← 4 researchers in parallel, lead merges
                            ↓ research report (+ refs for every branch)
 Charlie → [ IDEAS ] ──spec──→ Charlie OKs
                   ↓
     ┌──────────┬──────────┬───┴──────┬──────────┐
 [GAMEPLAY] [GRAPHICS]   [UI]    [AUDIO]  [ANIMATION]   ← run in parallel
     └──── questions ──→ [MANAGER] ──decision──→ [IDEAS] ──solution──→ back to branches
                   ↓
              [ CHECKER ] ──issues──→ branches (loop)
                   ↓ PASS
              [ MANAGER sign-off ] ── docs/GOOD_GAME_CHECKLIST.md ──❌──→ branches (loop) ──✅──→ done
```
You are the orchestrator: you run the stages, launch subagents, and keep `status.json`
up to date with `scripts/status.py` so Charlie can watch on the website (`site/`).

## Charlie checkpoints (only two)
1. Spec approval after `/new-game`.
2. The final "done" message after `/build`.
Never stop mid-build to ask. Manager decides; anything only Charlie can do (pass IDs,
publishing) goes in the game README's "Charlie TODO".

## Commands
- `/new-game <idea>` — R&D → Ideas, stops for approval
- `/build <slug>` — Branches → Manager loop → Checker → Manager sign-off → done

## Checks
`bash scripts/check.sh <slug>` (stylua, selene, rojo build). Missing tools are skipped
locally; CI runs them on push — read results with `gh run list` / `gh run view`.

## Code rules (full list in docs/ROBLOX_RULES.md)
- Luau, `--!strict`, Rojo layout from `template/`. Server is authoritative.
- All tunable numbers in `src/shared/Config.luau`.
- World and UI built **in code** so the game works straight from `rojo build`.
- Files under ~300 lines; one Service per system. Only `DataService` touches DataStores.
- Branch file ownership is in each agent file — respect it to avoid conflicts.

## Charlie's preferences
- Keep messages to him short.
- Games must earn: Game Passes / Dev Products, daily reward, hook in the first 60 seconds.

## Studio mode (when a Roblox Studio MCP is connected)
Check your tools for a Roblox Studio MCP (e.g. `run_code`, `insert_model`, `get_console_output`,
`start_stop_play`). If present:
- Still write all code to files in the repo (the repo is the source of truth).
- Sync into Studio: run `rojo serve games/<slug>` in the background if Rojo is installed and
  the Rojo plugin is connected; otherwise push each script's source into Studio via the MCP.
- Checker MUST playtest: start play mode, read console output for errors, check the first
  60 seconds work, stop play mode. Errors become issues in CHECK_REPORT.md.
- Graphics may inspect/tune the built map in Studio, but must copy any change back into code.
If no Studio MCP is present, use the normal `.rbxl` flow.
- `scripts/studio_sync.py <slug>`: if Rojo can't connect, generates Luau chunks in build/studio-sync/<slug>/ — run each with the Studio MCP execute_luau (Edit) to sync all scripts.
