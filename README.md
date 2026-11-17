# Roblox Game Factory — Chiken Studios

Claude builds whole Roblox games here. You only approve a 1-page spec.

## How to use (Claude Code on the web)
1. Open this repo in Claude Code.
2. Type `/new-game <your idea>` → Claude writes `games/<slug>/SPEC.md` and stops.
3. Reply "ok" (or tweak it).
4. Type `/build <slug>` → Claude builds everything, checks it, and pushes.

## Getting the game into Roblox
- GitHub → **Actions** → latest run → download **places** → open `<slug>.rbxl` in Studio → Publish.
- Then do the **Charlie TODO** list in `games/<slug>/README.md` (pass IDs, API access).

## What's inside
- `CLAUDE.md` — rules Claude follows
- `template/` — starter game: saving, leaderstats, daily reward, game passes, HUD
- `docs/` — spec template, build plan, quality checklist, coding rules
- `.github/workflows/build.yml` — lints + builds every game into a `.rbxl` on push
