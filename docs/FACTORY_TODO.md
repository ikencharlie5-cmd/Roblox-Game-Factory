# Factory TODO & lessons (from Sprout Zoo, game #1)

## Lessons — apply to every new game
- **Asset-driven from day one.** Code-built worlds and primitive creatures look cheap. Plan the asset
  list in the spec (creatures, trees, bushes, flowers, rocks, fences, stalls, signs, gates, icons) and
  generate them with Studio AI mesh generation in Studio mode BEFORE branches build. Record every
  publishedAssetId in the repo and load them at runtime (AssetLoaderService pattern) so the repo stays
  self-contained. Generate in batches of 3–8 (Roblox rate-limits around ~20 quick generations).
- **Icons:** no emoji or letter badges. Use Charlie's uploaded icons, or generate small 3D icon objects
  and render them in ViewportFrames (Pet-Sim style).
- **Layout/first impression:** no tall walls blocking the view; spawn camera faces the best view; low
  fences instead of hedges; open sightlines.
- **Lighting:** tune in Studio with screenshots (Future lighting, Atmosphere, ColorCorrection) — don't
  trust numbers alone.
- **Studio sync:** a fresh `rojo build` .rbxl that Charlie opens is cheaper than pasting code; use
  `scripts/studio_patch.py` for small fixes. Scripts can't set Terrain.Decoration or Lighting.Technology —
  set those in project.json / Studio.
- **Usage:** start a fresh chat per game; keep v1 scope small; one checker round before the final sign-off.

## Polish overhaul (Nov 18) — Charlie: "it all looks bad, overall like a bad game"
- Causes: v1 scope too big (Wildworld ~25 services, everything half-done), sign-off without anyone
  seeing the game, props built from Parts.
- Fixes: scope cap (1 loop, 1 zone, ≤8 services), Look target refs in every SPEC, art3d before
  branches, blocking Look test (screenshots graded B+) in checker + checklist section 0.

## Next
- [x] Add **3D Art** department (art3d agent: asset list, mesh gen / Creator Store, asset IDs) — Nov 18
- [ ] Add **Economy/Balance** department (simulate first hour; tune prices, timers, odds)
- [ ] Optional "lite mode": 1 R&D researcher, smaller v1, single checker round
- [x] R&D split into 4 researchers · Animation department · Office-building website

## Sprout Zoo (paused — Charlie moved to a new game)
State: playable v2 in Studio (SproutZoo_v2.rbxl), 28 AI creature meshes, premium UI, terrain/lighting
pass, animation. Remaining: props into Assets/Props (ids in docs/ASSET_LIBRARY.json), layout fixes,
3D icons, lighting tuning, checker round 2, manager sign-off.
