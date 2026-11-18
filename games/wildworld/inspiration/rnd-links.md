# R&D links

## Gameplay
- https://commonsensegamer.com/complete-build-a-zoo-guide-to-big-pets-and-mutations/ — Build a Zoo mutation tiers, food leveling, weather mutations
- https://www.pockettactics.com/grow-a-garden-mutations — Grow a Garden mutation multipliers + combo mutations
- https://rolearn.dev/insights/grow-a-garden-ccu-record-analysis — why GaG retained (5–7 day updates, layered depth)
- https://devforum.roblox.com/t/10000-physical-npcs-running-with-60-fps-on-low-end-device/3660293 — server-computed/client-rendered NPCs
- https://rowatcher.com/news/retention-benchmarks-by-roblox-genre-what-good-actually-looks-like — D1/D7 benchmarks
- https://rowatcher.com/news/roblox-monetization-strategies-that-actually-work-in-2026 — pass price tiers
- https://www.blog.radiator.debacle.us/2017/08/go-west-young-slime-rancher.html — Slime Rancher: reward humane habitats

## UI (rnd-ui)
- https://create.roblox.com/docs/ui/cross-platform-design — reserved mobile corners, thumb zones, context UI
- https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md — use CoreUISafeInsets for interactive UI
- https://devforum.roblox.com/t/performance-issues-with-lots-of-viewportframes-mostly-occurring-on-low-end-devices/958962 — VPF lag in big inventories
- https://zblox164.github.io/PlacementService/tutorial — mobile build actions need custom buttons
- https://www.pcgamer.com/games/sim/planet-zoo-2-review/ — menu sprawl anti-pattern; quick-jump buttons
- https://gamerblurb.com/guides/planet-zoo-2-breeding-spreadsheet-guide — Compare Mates / Genealogy
- https://creatures-of-sonaria-official.fandom.com/wiki/Main_Menu — creature slot card contents
- https://allthings.how/palworld-1-0-how-breeding-and-trait-inheritance-work/ — breeding/inheritance flow
- https://www.thegamer.com/pokemon-legends-arceus-research-tasks-explained-guide/ — per-species research level

## Art (R&D Art)
- [EditableMesh limits (why not for runtime creatures)](https://create.roblox.com/docs/reference/engine/classes/EditableMesh.md)
- [Shape language & silhouette test](https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent)
- [How a top Roblox creature game shows mutations](https://bloxodes.com/wiki/creatures-of-sonaria/mutations)
- [Crystal material tips](https://devforum.roblox.com/t/how-to-make-a-good-crystal-material/2996845)
- [Future vs ShadowMap performance](https://devforum.roblox.com/t/future-vs-shadowmap-performance/3246937)
- [Waterfall VFX tutorial (Beam/emitter values)](https://create.roblox.com/docs/tutorials/use-case-tutorials/vfx/create-waterfalls.md)
- [Streaming techniques (LOD, ModelStreamingMode)](https://create.roblox.com/docs/workspace/streaming/techniques.md)
- [Many NPCs: client-side, distance tiers, BulkMoveTo](https://devforum.roblox.com/t/optimizing-hundreds-of-moving-npcs-rendering/3074292)
- [Highlight limit raised to 255](https://devforum.roblox.com/t/lights-camera-more-highlights/4061534)

## Audio (rnd-audio)
- https://gamedeveloper.com/audio/deep-dive-the-music-of-slime-rancher-2 — melodic-percussion core, per-zone palettes, day/night track pairs
- https://www.audiokinetic.com/en/blog/midas-merge — one-key stingers, priority/drop rules, sparse music with silences
- https://www.pcgamer.com/how-animal-sounds-are-made-in-games — creature vocal layering/pitch tricks
- https://devforum.roblox.com/t/ambientsorcery%E2%80%99s-tutorial-1-creating-compelling-environmental-audio/3507022 — ambience bed + random one-shots, search terms
- https://devforum.roblox.com/t/how-to-find-good-music-in-robloxs-audio-library-using-the-apm-music-website/2149632 — find APM tracks by exact title
- https://github.com/Githolz/All-Classic-Roblox-Sound-Paths- — built-in rbxasset://sounds paths

## Art: Studs style (R&D Art)
- [Surface API kept for back-compat (studs still settable)](https://devforum.roblox.com/t/deprecating-surface-tool-api/1222218)
- [Surfaces render only on Plastic](https://roblox.fandom.com/wiki/Surface)
- [HD stud MaterialVariants (fallback)](https://devforum.roblox.com/t/hd-stud-materials-and-creation-pipeline-now-with-welds/2916846)
- [Old stud texture via MaterialVariants + caveats](https://devforum.roblox.com/t/how-to-get-back-the-old-stud-texture-easily-includes-meshes-unions/3157449)
- [BrickHeadz shape study (cube head 4x4 / 3x3)](https://bricknerd.com/home/brickheadz-blueprints-a-study-of-shape-and-form-1-19-23)
- [Perf: built-in materials vs textures, draw calls](https://create.roblox.com/docs/performance-optimization/design.md)
