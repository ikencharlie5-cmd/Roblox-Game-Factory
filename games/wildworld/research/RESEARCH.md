# RESEARCH — Wildworld (R&D Lead merge)

R&D Lead, Chiken Studios. This merges the four branch guides. The detailed values live in the branch docs; this file gives the overall takeaways, points to each guide, and makes a call on every place where the guides disagree.
Inputs: `inspiration/charlie-brief.md`, `inspiration/master-spec.md` (MVP = section 24).

## Summary
1. **Beautiful parks must be the best strategy.** Visitor income = habitat rating multiplier (0.5x–2.0x) × creature rarity × mutation multiplier. A decorated habitat always out-earns a cramped pen, which avoids Slime Rancher's "cram for profit" trap. The live habitat-rating bar in build mode is the most rewarding feedback in the loop.
2. **Creatures are original, code-built, anchored, non-Humanoid models.** The server runs a staggered goal/state machine (every 3–8 s) and replicates attributes only. Clients animate procedurally with distance tiers (full / 10 Hz / frozen), within a budget of about 1,500 animated parts per client. Each creature has 12–25 role-coloured parts, so genes and mutations are just palette and attachment swaps.
3. **Genetics should be readable and should reward skill.** Use 4 MVP genes (color, pattern, size, glow) with hidden recessives. Mutations roll afterwards (Golden / Albino / Crystal, with Glowing as a stretch goal). The Heirloom rule (a mutated parent gives ×5 chance) makes "chasing a line" a real goal. The UI shows odds as ranges and percentages, never as a promise.
4. **Every rare moment needs layered payoff.** A rare moment combines a VFX that reads from 30+ studs, a rarity-framed reveal card with a sunburst, and a stinger that scales with tier (all in F major, ≤ 3.5 s, music ducked −8 dB). Force a Golden sibling egg in session 1 so the "wow" moment happens in the first minutes.
5. **Mobile-first and premium-feeling.** ShadowMap lighting (not Future), Terrain grass decoration, the plant-zoo UI Kit re-skinned as an "explorer's field journal" (parchment / deep teal / sunset coral), 44 px hit targets, an on-screen button for every build hotkey, and one major window at a time. Monetization is cosmetic or convenience only, with no paid breeding luck.

## Gameplay → `RESEARCH_GAMEPLAY.md`
Reference loops (Build a Zoo, Grow a Garden, Adopt Me, Dragon Adventures, Slime Rancher), creature AI architecture, the habitat/park rating formulas, gene and mutation tables with chances and multipliers, timers, wild capture (bait → trust → Calm Net ring), the first-60-seconds script, monetization, and retention targets (D1 20–28%, D7 12–18%).

## Graphics → `ART_STYLE_GUIDE.md`
Exact Lighting/Atmosphere/post-processing values, per-biome atmosphere tweens, a 14-minute day cycle with a readable blue night, terrain and foliage rules, the creature construction recipe (chibi proportions, part-built eyes, one hero silhouette feature, silhouette test), the mutation visuals table, and the performance and streaming budget.

## UI → `UI_STYLE_GUIDE.md`
Port the plant-zoo Kit and re-skin it as the field journal. Covers the shared CreatureCard (ViewportFrame), a 4-tab Inspect window, the Breeding panel (Parent A | odds | Parent B), the Build tray plus context action bar, the Journal with silhouettes and a 5-step research bar, the rarity and mutation colour tables, and mobile safe zones.

## Audio → `AUDIO_GUIDE.md`
Melodic-percussion music with 20–60 s gaps, per-biome ambience (a loop bed plus random one-shots) with zone reverb, creature voices from a few base sounds with pitch and effects changed in code per species and mutation, the 5-tier reveal stinger ladder, SoundGroups, and safe asset sourcing (Creator Store search terms, `Id = 0` TODOs for Charlie).

## Conflicts between guides (recommended calls)
| # | Conflict | Recommended call |
|---|---|---|
| 1 | **Rarity tiers.** Gameplay's wild spawns use 4 tiers (Common–Epic). Audio has 5 (up to Legendary). UI has 6 (adds Mythical). | Use **5 tiers, Common → Legendary**, for the MVP. Keep Mythical in the UI tables, reserved for after the MVP. Add Legendary to the wild spawn weights at about 0.2% (Common 70 / Uncommon 22 / Rare 6.8 / Epic 1 / Legendary 0.2). |
| 2 | **Habitat rating scale.** Gameplay stores 0–100. The UI strip shows 0–5 stars. | Store **0–100** on the server and display it as stars (20 points = 1 star, half stars allowed) with the number shown beside them. |
| 3 | **Mutation list size.** Gameplay MVP = Golden, Albino, Crystal (+ Glowing as stretch). Art, UI and Audio also spec Melanistic, Giant/Mini, Rainbow, Frost, Ember, Shadow, Celestial, and others. | Build **only Golden, Albino, Crystal and Glowing** for the MVP. The extra rows in the art/UI/audio tables are post-MVP content; keep them in the data tables but disabled. |
| 4 | **Giant scale.** Gameplay uses ×1.4. Art uses `ScaleTo(1.5)`. | Use **×1.4** (collision-safe in pens). This is post-MVP anyway. |
| 5 | **Glowing priority.** Art's Summary treats Glowing as a core mutation (the night-time showcase). Gameplay marks it "stretch". | Keep it as stretch, but build it first after the three core mutations. It is cheap (Neon + PointLight), and it gives the night cycle a purpose. |

## Open question for Charlie: how should creatures be built?
Your brief says no free models; creatures must be original. The Art branch chose **code-built primitive creatures** (Ball/Cylinder/Wedge + SpecialMesh ellipsoids, 12–25 parts). That option is original, data-driven, easy to recolour for genes and mutations, and works with no asset uploads.
The alternative is **AI-generated meshes via Studio MCP** (original MeshParts made per species). They can look smoother and more detailed, but each one needs generating and importing. They also need part splitting or SurfaceAppearance work so genetics can recolour regions, and a check of the triangle budget on mobile.
**R&D recommendation:** start the MVP with code-built parts (fastest, and the gene recolouring already works). Later, consider a hybrid: an AI mesh for one hero feature per species (antlers, a tail) on top of the part body.
**Charlie needs to decide: parts only, AI meshes, or hybrid?**

## Sources
All links are in the branch guides' Sources sections and in `games/wildworld/inspiration/rnd-links.md`.
