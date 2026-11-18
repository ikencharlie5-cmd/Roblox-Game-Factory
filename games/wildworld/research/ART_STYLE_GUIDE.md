# Wildworld — Art Style Guide

Owner: the Graphics branch (world, lighting, creatures, mutation VFX). Written by R&D Art.
These values are starting points: tune them in Studio, then copy the final values back into code.

**Target look:** a lush, sunny, magical storybook park. It sits between a cozy ranch game (round, candy-coloured creatures on bright green hills) and a toy-like Roblox simulator.
Saturation hierarchy: ground is calm, props are brighter, and **creatures + mutations are the brightest thing on screen**.

**Key constraint (Charlie):** NO free models for creatures. Every creature is built **in code** from primitives (Ball / Cylinder / Block / Wedge parts, plus
SpecialMesh ellipsoids), so creatures are original and data-driven. This overrides the generic R&D template line "never primitive-built creatures". §5 explains how to
make primitive creatures look *designed*, not cheap. Free models are OK only for **scenery** (trees, rocks), and only after scripts are stripped.

## Summary
- **Creatures = code-built "toy figurines":** 12–25 overlapping rounded parts. Use SmoothPlastic, a big head (≥ body), big glossy part-built eyes, tiny limbs, and one strong
  silhouette feature per species (moss hump, ember tail, glowing ears, branch antlers, rock horns). Colour each part by **role** (Primary/Secondary/Belly/Accent/Eye/Glow),
  so genetics and mutations are just palette and attachment swaps.
- **Mutations must read from 30+ studs:** Albino (pale + pink-red eyes), Golden (Metal gold + sparkles), Crystal (Glass shards on the back + soft light), Glowing (Neon markings
  + PointLight + pulse), Melanistic, Giant/Mini (`Model:ScaleTo`). Max 1 ParticleEmitter + 1 light per creature.
- **Lighting:** ShadowMap (not Future: a large outdoor map, mobile-first), ClockTime 14, Brightness 2.8, neutral lifted ambient. Atmosphere Density 0.25 / Haze 1.3.
  ColorCorrection Saturation 0.22 / Contrast 0.08, subtle Bloom (0.35 / 24 / 1.7), SunRays 0.05.
- **Lush but cheap world:** Terrain Grass with `Decoration = true` (animated blades, cheaper than part grass on old phones). Terrain water lakes. Beam-based waterfalls.
  Clustered foliage (3–5 per cluster), CastShadow off on small props, and decoration non-collidable / non-queryable.
- **Performance budget:** creatures are **anchored, non-Humanoid, animated procedurally on the client** with distance tiers (full / 10 Hz / frozen). ≤ ~1,500 creature parts animated
  per client. Highlights only on hovered/selected creatures.

---

## 1. Lighting (exact values)

Set in `default.project.json` → Lighting `$properties`:
```json
"Lighting": { "$properties": {
  "Technology": "ShadowMap", "ClockTime": 14, "Brightness": 2.8,
  "GlobalShadows": true, "ShadowSoftness": 0.3,
  "Ambient": [0.53, 0.53, 0.55], "OutdoorAmbient": [0.5, 0.5, 0.53],
  "EnvironmentDiffuseScale": 1, "EnvironmentSpecularScale": 0.4,
  "GeographicLatitude": 30
} }
```
- **ShadowMap, not Future.** In a DevForum comparison, ShadowMap clearly outperforms Future, and Future's extra shadows made one map unplayable on <2 GB phones. ShadowMap is the recommended mode
  for mostly outdoor maps. Lower quality levels turn shadows off automatically. Glow on crystals/lamps comes from Neon + PointLight + Bloom, which all work in ShadowMap.
- **Day cycle:** about 14 min. 70% of it is day (ClockTime 9–16), golden hour (17–17.6) is a short beauty moment, and night is **blue and readable, not black**: Ambient `#5A6A9A`, OutdoorAmbient `#4A5A8C`,
  Brightness 1.0. Night is when Glowing/Bioluminescent mutations and Lumibun ears shine, which gives a reason to look at night.
- **Atmosphere:** Density **0.25**, Offset **0.25**, Color `#CDEBFF`, Decay `#FFE0BF`, Glare **0.3**, Haze **1.3**. Per biome, tween over 2 s at zone entry:
  - Greenleaf: as above.
  - Sunstone Desert: Color `#FFE3B0`, Decay `#F2A65A`, Density 0.3, CC Tint `#FFF2DC`.
  - Frostpeak: Color `#DDEEFF`, Decay `#B8D4FF`, Density 0.35, CC Tint `#F0F6FF`, Saturation 0.1.
  - Coral Coast: Color `#BFF3FF`, Decay `#7FE0E8`, Density 0.2.
  - Emberlands: Color `#FFB59A`, Decay `#B5403A`, Density 0.4, Haze 2.
  - Mystic Valley: Color `#E6D4FF`, Decay `#8B6FE0`, Density 0.3, Glare 0.6.
- **Post-processing** (Lighting children, created in code):

| Effect | Values |
|---|---|
| ColorCorrectionEffect | Saturation **0.22**, Contrast **0.08**, Brightness **0.02**, TintColor `#FFF8EE`. Never above 0.35, or the greens turn radioactive. |
| BloomEffect | Intensity **0.35**, Size **24**, Threshold **1.7** (only Neon/glow blooms, not white fences) |
| SunRaysEffect | Intensity **0.05**, Spread **0.6** |
| DepthOfField | Off in gameplay. Photo mode / discovery cutscene only: FocusDistance 20, InFocusRadius 15, FarIntensity 0.3 |
| BlurEffect | Camera, client-only, Size 0→8 behind full-screen menus |

- **Sky:** the default sky + Atmosphere is fine. Add 6–10 big puffy cloud models built from 4–6 white Balls each (`#FFFFFF`, Transparency 0.05, CastShadow false)
  that drift slowly around the map edge. This is cheap and very effective.

## 2. Ground, water, terrain

| Surface | Build with | Values |
|---|---|---|
| Open ground, hills, map edge | Terrain **Grass** (FillBlock 3 studs thick, FillBall hills r 25–70) | `Terrain.Decoration = true`. `SetMaterialColor(Grass, #6CC644)`, backdrop hills `#5DB43C` |
| Forest floor | Terrain **LeafyGrass** (no blades, so it's cheaper under trees) | `#4FA63A` |
| Natural paths (wild world) | Terrain **Ground** strips 10–14 studs wide | `#D4B386` |
| Lakes / rivers | Terrain **Water** | `WaterColor #3CC3E8`, Transparency 0.4, Reflectance 0.35, WaveSize 0.08, WaveSpeed 6. Rim with Sand `#F2DFA7` + Rock |
| Cliffs / mountains | Terrain **Rock** `#9AA3B5`, **Slate** `#7E8799` | Snow caps `#F4F8FF` in Frostpeak |
| Player plot floor | Parts, SmoothPlastic `#8BD65E` (lighter than terrain) with a 1-stud raised wood border `#B8784A` | Plots read as "your land" |
| Placed paths (build mode) | Parts, SmoothPlastic `#EBD5A6`, edge strip `#C9A979` 0.3 studs high | Rounded corner pieces (Cylinder quarter) |

The DevForum grass launch post says grass blades follow the Grass material colour and use a simpler shader than terrain, so they don't hurt (and can even help) old phones.
Blades don't show on LeafyGrass. Never use the default studded Plastic. Use Neon only on small accents (< 2×2 studs).

**Waterfalls (signature feature):** a cliff of Rock terrain + 2–3 **Beams** with a scrolling water texture. Roblox's waterfall tutorial values are FastDrop TextureSpeed 1.3,
TextureLength 2, Width 5→10, CurveSize 10/20, FaceCamera on, plus a SlowDrop copy at TextureSpeed 1. Add a splash emitter at the base (Lifetime 0.25–0.35, Rate 30 → **use 15 on mobile**,
Speed 20–35, Acceleration 0,−40,0) and a mist emitter (Size 8→10, Rate 20 → **10**). Optional rainbow sprite (Rate 0.25, LightEmission 1).
Beam textures need an image asset: upload one original white-streak texture (Charlie TODO), and use a translucent part fallback until then.

## 3. World palette

| Group | Hex |
|---|---|
| Grass | `#6CC644`, hills `#5DB43C`, forest floor `#4FA63A` |
| Tree leaves (mix 3 per cluster) | `#4FBF4A`, `#7AD65A`, `#A8E36A`; magic trees `#FFB3D9`, `#B9A4FF` |
| Trunks / wood | `#8A5A3B`, fences `#B8784A`, dark trim `#7A4A2A` |
| Flowers | `#FF6FA8`, `#FFD54F`, `#FFFFFF`, `#8F7CFF`, `#FF8A3D` |
| Rock | `#9AA3B5`, moss on rock `#7BBF4E` |
| Water | `#3CC3E8` |
| Shop awnings | `#FF7B7B`, `#FFD45C`, `#7FD0FF`, `#C79BFF` with white stripes `#FFF6E6` |
| Discovery spots | glow `#FFF3A0`, Neon ring, ~3 sparkle particles |

Rules: at most ~6 hues per screen. No pure white or pure black on big surfaces. No grey props (tint them warm or cool). Biome kits re-tint the same prop builders.

## 4. Foliage and props (lush on mobile)

- **Cluster, don't scatter:** groups of 3–5 (1 big, 2 medium, 1–2 small), with random Y rotation, scale ×0.8–1.3, and ±5% lightness jitter.
- **Code-built tree kit** (no free models needed): a trunk (Cylinder, tapered by stacking 2) + a canopy of 3–5 overlapping Balls in 2–3 leaf greens. About 6–8 parts per tree.
  Pine variant: 3 stacked shrinking cones made from 4 Wedges each, or stacked squashed Balls. Bush = 2–3 Balls. Flower = a thin Cylinder stem + 1 Ball head (2 parts).
  Creator Store scenery is allowed if needed: search `low poly tree`, `stylized tree`, `low poly bush`, `low poly rock`, `cartoon flowers`, `wooden fence low poly`, `lamp post cartoon`.
  Strip scripts and pick one consistent style.
- **Density:** about 1 tree cluster per 40×40 studs in the open, dense forest walls at biome edges and the map edge (so there's never a void), and flower strips along fences.
- **Flags on every decoration part:** `Anchored`, `CanCollide=false` (except trunks/rocks the player shouldn't walk through), `CanQuery=false`, `CanTouch=false`,
  and `CastShadow=false` for anything smaller than ~3 studs.
- **Streaming:** keep StreamingEnabled (default) and the default StreamingMinRadius (64), and use StreamOutBehavior Opportunistic. Group scenery into small models (extent < ~64 studs)
  and set `LevelOfDetail = SLIM` on static scenery only (SLIM doesn't support animated/changing models, so never use it on creatures). Player plots: `ModelStreamingMode = PersistentPerPlayer` for the owner.
- **Habitat build pieces** (fences, shelters, feeders, ponds, rocks, logs, toys) must be readable as categories: feeders use a yellow `#FFD45C` bowl, water troughs blue `#3CC3E8`, shelters have red/teal
  roofs, and toys use bright primaries. A low fence (2.5 studs) keeps creatures visible. Glass walls for aquatic tanks (Glass material, Transparency 0.5).

## 5. Creatures: code-built toy figurines (the big one)

### 5.1 Construction rules (what separates "designed" from "cheap")
1. **Shapes:** `Part.Shape = Ball` for spheres. For **ellipsoids** (bodies, snouts, cheeks, ears) use a Block part + `SpecialMesh{MeshType=Sphere, Scale=…}`
   (a Ball part stays a perfect sphere). Limbs = short `Cylinder` or two overlapping Balls (capsule). Ears/horns/fins = Wedge/CornerWedge or tapered
   bead-chains of 2–4 shrinking Balls. Use as few Blocks as possible: **round shapes read as friendly**, and sharp triangles signal danger (use them only on "fierce" species).
2. **Overlap everything:** sink every joint 30–40% into its parent. No visible gaps or seams. Order: body → head → features.
3. **Chibi proportions:** head ≈ 0.9–1.2× body volume. Eyes sit in the **lower half** of the head, wide apart. Legs ≤ 25% of total height. Total height **2.5–4 studs** (adult common).
4. **Eyes sell cute:** each eye = a black Ball `#1E1B2E` (0.45–0.6 studs) + a white highlight Ball `#FFFFFF` (≈ 30% size) offset up/out + optionally an iris tint ring. Add
   blush cheeks: flat pink ellipsoids `#FF9EB5`, Transparency 0.35. A tiny smile = 2 thin dark Wedges (optional).
5. **SmoothPlastic** for all creature parts. `Glass`, `Neon`, `Metal`, `ForceField` only through mutations.
6. **One hero feature per species** that defines the silhouette from 40 studs away. Do the **silhouette test** (render the creature all black). If two species look alike, change the hero shape,
   not the colour. Colour should reinforce shape, never carry readability alone.
7. **Part budget:** 12–20 parts (common), ≤ 25 (rare+). Mutation attachments ≤ 6 extra parts.
8. **Physics flags:** every creature part `Anchored=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless`. One invisible **Hitbox** part
   (Transparency 1, CanQuery=true) is the PrimaryPart and the click/ProximityPrompt target. `CastShadow=false` on everything except the body and head.
9. **Tag every part with an attribute `Role`**: `Primary`, `Secondary`, `Belly`, `Accent`, `Eye`, `EyeShine`, `Cheek`, `Glow`, `Feature`. Genetics and mutations then recolour by role.
   Also tag `Anim` (`Body`, `Head`, `LegFL/FR/BL/BR`, `Tail`, `EarL/R`, `Wing`) for the procedural animator.

### 5.2 Builder architecture (data-driven, no hardcoding in unrelated scripts)
`shared/CreatureBlueprints/<Species>.luau` returns a list of `{name, shape, size, offset CFrame (from root), role, anim, mesh?}`.
`shared/CreatureBuilder.luau` builds a Model from blueprint + genes:
- Colours: `genes.primary/secondary/accent` (hex) override the role colours. Pattern genes toggle optional parts (spots/stripes = small flat ellipsoids on the body).
- Size gene → `Model:ScaleTo(0.85–1.15)`. Growth stage → ScaleTo: Baby 0.5 (and head ×1.25 relative, which is extra cute), Juvenile 0.75, Adult 1.0, Elder 1.0 + grey-tinted Secondary +5%.
- Then apply mutation layers (5.4) in a fixed order: recolour → material → attachments → VFX.
- **Cache:** build each unique look once per client and `Clone()` it for repeats. Cloning pre-built NPCs is cheaper than building each one.
- **Never** use `EditableMesh` for runtime creatures in v1. Client memory budgets for editable assets are strict, and the Mesh/Image API setting must be enabled. Primitives are enough.

### 5.3 MVP species blueprints (Greenleaf Forest). Hero feature in **bold**.
| Species | Body plan (parts) | Palette (Primary / Secondary / Accent) | Hero feature |
|---|---|---|---|
| **Mossback** (gentle, slow) | wide low ellipsoid body (5×2.5×3.5), big round head, 4 stubby cylinder legs, tiny tail ball | `#8C6A4F` / `#F2D6B3` belly / `#6CC644` moss | **Moss hump**: 4–6 overlapping green Balls on the back + 2 tiny pink flower balls `#FF8FB8` |
| **Lumibun** (tiny, shy) | small round body (1.6), bigger round head (1.8), 2 foot balls, cotton tail | `#F7F1FF` / `#FFC8E0` / `#9FE8FF` ear tips | **Long ears**: 2 tall ellipsoids (0.5×2.4×0.25) with Neon tips (Glow role, PointLight Range 5 at night only) |
| **Emberfox** (playful, quick) | slim ellipsoid body, pointed snout ellipsoid, 4 thin legs | `#FF8A3D` / `#FFF1E0` / `#FF4E3A` markings | **Flame tail**: 3 bead-chain balls growing to a big tip; Glow role on the tip; 1 small ember ParticleEmitter (Rate 2) |
| **Thornstag** (proud, calm) | tall ellipsoid body, long neck cylinder, head, 4 long legs | `#B5835A` / `#F5E3C8` / `#4FA63A` leaves | **Branch antlers**: 2 forks × 3 thin cylinders + 3 leaf balls each |
| **Pebblehorn** (sturdy, lazy) | chunky round body, flat broad head, thick legs | `#7E8799` / `#C9CFDB` / `#5FD3C4` mineral | **Rock horn**: 3 stacked shrinking Balls on the nose + 3–4 flat Wedge "plates" on the back |
Later species reuse the same kit: Aquafin (Glass fins, Transparency 0.4), Glimmerwing (2 Neon-edged ellipsoid wings), Cloudhopper (cloud-ball body, 0.6-stud float bob),
Volcarok (dark rock + Neon crack strips), Starwhale (navy `#2B2F6B` with small Neon star dots), Crystalback (Glass shards as base anatomy).

### 5.4 Mutation visuals (each must read from 30+ studs)
| Mutation | Recolour | Material / extras | VFX (≤ 1 emitter + 1 light) |
|---|---|---|---|
| Albino | Primary/Secondary → `#F6F2EE` / `#FFE6EC`, Accent desaturated | Eye → `#E8505B` (pink-red), EyeShine stays white | none (the look is the reward) |
| Melanistic | Primary `#2B2733`, Secondary `#3D3646` | Eye → `#FFD23F` | none |
| Golden | all body roles `#F5C542`, Belly `#FFE59A` | Material **Metal** (EnvironmentSpecular gives a sheen), Eye stays dark | sparkle emitter: Rate 3, Lifetime 1, Size 0.25→0, LightEmission 1, colour `#FFE27A` |
| Silver | `#D6DCE6` | Metal | white sparkle, Rate 2 |
| Crystal | Primary tinted 30% toward `#9FE8FF` | **adds 3–5 shards** (Wedge pairs / stretched ellipsoids) along the back/hero feature: **Glass**, Transparency 0.25, `#9FE8FF` (or a species tint) | PointLight Range 6, Brightness 0.6, `#9FE8FF` |
| Glowing | unchanged base | `Glow` + `Accent` roles → **Neon** (small parts only) | PointLight Range 8, Brightness 1; client pulse Brightness 0.6↔1.2 over 2 s |
| Bioluminescent | Primary darkened 20% | spot pattern parts → Neon `#5CFFD8` | pulse only at night |
| Frost-touched | tint toward `#CFEFFF` | Accent → Ice material | snowflake emitter Rate 2 |
| Ember-touched | tint toward `#FF7A3D` | Accent → Neon `#FF5A1F` | ember emitter Rate 2 |
| Shadow-touched | Primary `#3A2E4F` | Eye → Neon `#FFFFFF` | dark smoke emitter Rate 2, LightEmission 0 |
| Rainbow | — | Accent/Glow hue-cycled on the client (6 s loop, only when within 60 studs) | rainbow sparkles Rate 3 |
| Celestial | Primary `#2B2F6B` | 6–10 tiny Neon star dots | PointLight `#B9A4FF` |
| Giant / Miniature | — | `Model:ScaleTo(1.5)` / `ScaleTo(0.6)` (clamp the hitbox) | none |
**Stacking:** recolour mutations conflict (pick the rarest). Material + attachment + VFX layers can stack, but the total is still ≤ 1 emitter + 1 light per creature (merge colours).
**Rarity aura** (for the species' rarity, separate from mutation): Rare = nothing extra. Epic = a soft ground ring (flat Cylinder, rarity colour, Transparency 0.6) under the feet.
Legendary = ring + slow spin. Keep it subtle: the mutation is the star.

### 5.5 Procedural animation (no Humanoid, no Animator)
The server owns the position/target at **~4 Hz** (an attribute or remote). The client interpolates and animates each part from its blueprint offset. Using non-Humanoid, client-rendered NPCs with
distance tiers is the standard DevForum approach for many NPCs.
- **Idle:** body bob 0.12 studs, 1.4 s Sine. Breathing scale isn't possible on parts, so fake it with a ±0.05 stud Y offset on Body parts.
- **Walk:** legs swing ±25° around the hip at 6 Hz × speed, body bob ×2, head counter-bob. **Hop** species (Lumibun, Cloudhopper): arcs of 1 stud with squash (Y offset −0.15 at landing).
- **Tail:** wag ±15° at 2 Hz (happy: 4 Hz, ±30°). **Ears:** random flick every 3–6 s. **Blink:** eye Size Y ×0.1 for 0.12 s every 3–6 s (random).
- **Moods:** Happy = little hop + 3 heart particles (one-shot). Sleeping = eyes closed (Y ×0.1), slow bob, "Z" BillboardGui. Hungry = head droop 10°.
- **Distance tiers:** 0–60 studs full animation at frame rate. 60–140 at 10 Hz, position + bob only. > 140 position only at 2 Hz, no parts animated. Off-screen = skip.
  Apply all part CFrames with **`workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)`** once per frame.
- **Budget:** ≤ 60 animated creatures (~1,500 parts) per client. Pool and reuse models when creatures stream out.

### 5.6 Selection and readability
- `Highlight` **only** on the hovered/selected creature and the tutorial target: FillTransparency 1, OutlineColor = rarity colour. The limit is now 255, but each one costs extra draw calls + a
  post-process pass.
- Above each creature (within 40 studs): a small BillboardGui name tag (FredokaOne, white, dark stroke, rarity-coloured dot, mutation icon). Hide it beyond 40 studs.

## 6. Discovery, capture, breeding moments (VFX)
- **Wild discovery spot:** a glowing ground ring (Neon, `#FFF3A0`, Transparency 0.5) + 3 rising sparkles, a footprint trail of flat dark ellipsoids leading to the creature.
- **First discovery:** a FOV punch 70→62→70 (0.3 s), a beam column of the rarity colour (tween a Neon cylinder up, Transparency 0.4→1), confetti, and the creature spins 360° in place.
- **Capture:** a bubble of ForceField material (Ball) shrinks around the creature, a pop, and particles. Fail = the bubble bursts and the creature hops away.
- **Egg / birth:** eggs are ellipsoids in the parents' blended Primary with Secondary spots. They wobble (±8°) faster as hatching nears. On hatch: shell halves fly out + a mutation reveal
  (screen flash in the mutation colour, then the creature appears and its mutation VFX turns on 0.5 s later for drama).

## 7. Camera
Default follow camera, `CameraMaxZoomDistance = 90`, `CameraMinZoomDistance = 6`, FOV 70. Build mode: an orbit camera (scroll zoom 20–120, Q/E or a two-finger rotate).
Inspect creature: tween to 8 studs in front of it at FOV 50, background DOF on. Photo mode: UI hidden, DOF on.

## For Graphics
Build order (each step is visible on its own):
1. **Lighting + post FX + Atmosphere** (§1) in `default.project.json` + a `Lighting.luau` client module with per-biome tweens.
2. **Terrain world:** Greenleaf grass hills, a lake, 1 waterfall (Beam + 2 emitters), Ground paths, and forest walls at the edges. Plot floors + wood borders.
3. **`CreatureBuilder` + 5 blueprints** (§5.2–5.3), with the Role/Anim attributes, a Hitbox PrimaryPart, all flags, and clone caching. Pass the silhouette test.
4. **Procedural animator** (§5.5) with distance tiers + BulkMoveTo.
5. **Mutation layers** (§5.4): at least Albino, Golden, Crystal, Glowing for MVP (the spec needs ≥ 3).
6. **Tree/bush/flower/rock builders** + cluster scatter, then habitat build pieces (§4).
7. Moment VFX (§6) and Highlight-on-select.
Performance acceptance: 4 players × 8 creatures + 20 wild creatures + the full Greenleaf map stays ≥ 50 FPS on a mid phone at auto quality. ≤ 1 emitter + 1 light per creature. No Neon surface > 2×2 studs.
Charlie TODO: upload 1 original waterfall streak texture + 1 sparkle texture (or use the built-in default sparkle).

## Sources
- https://create.roblox.com/docs/reference/engine/classes/EditableMesh.md (memory/permission limits, the reason to avoid it for runtime creatures)
- https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent (shape language, silhouette test)
- https://bloxodes.com/wiki/creatures-of-sonaria/mutations (how a top Roblox creature game presents mutations: recolours, neon, glass, metallic, size)
- https://devforum.roblox.com/t/how-to-make-a-good-crystal-material/2996845 (crystal look: semi-transparent Glass, no Reflectance)
- https://devforum.roblox.com/t/future-vs-shadowmap-performance/3246937 (ShadowMap vs Future cost on mobile)
- https://devforum.roblox.com/t/introducing-grass/386129 (terrain grass cost, colour)
- https://create.roblox.com/docs/tutorials/use-case-tutorials/vfx/create-waterfalls.md (waterfall Beam/emitter values)
- https://create.roblox.com/docs/workspace/streaming/techniques.md (LevelOfDetail SLIM, ModelStreamingMode, NPC grouping)
- https://devforum.roblox.com/t/optimizing-hundreds-of-moving-npcs-rendering/3074292 (client-side NPCs, distance tiers, BulkMoveTo, pooling)
- https://devforum.roblox.com/t/lights-camera-more-highlights/4061534 (Highlight limit 255 + draw-call cost)
- https://devforum.roblox.com/t/particle-emitter-limit-on-low-graphics-is-impacting-my-game/2159584 (particles reduced on low graphics)
- https://devforum.roblox.com/t/performance-question-parts-or-unions/1360129 (parts over unions)
- https://devforum.roblox.com/t/cartoon-lighting-settings/333686 (cartoon lighting baseline, via the Sprout Zoo guide)
- games/plant-zoo/research/ART_STYLE_GUIDE.md (studio house values for palette/post FX)
