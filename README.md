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

## The website (live pipeline)
**https://ikencharlie5-cmd.github.io/Roblox-Game-Factory/** — watch each game move through
R&D → Ideas → Gameplay / Graphics / UI → Manager → Checker, read the team chat, and upload inspiration.
Updates on every push.

## Building straight into Studio (on your PC)
1. Install Claude Code on the PC that has Roblox Studio, and clone this repo.
2. Connect the Roblox Studio MCP to Claude Code, and (optional) install Rojo + the Rojo Studio plugin.
3. Open Studio with an empty place, then run `/new-game` / `/build` in Claude Code from the repo folder.
The team builds into Studio live and the Checker playtests it.
