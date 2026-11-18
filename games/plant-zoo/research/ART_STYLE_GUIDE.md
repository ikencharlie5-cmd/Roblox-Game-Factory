# Sprout Zoo — Art Style Guide (whole game)

Owner: Graphics branch (world, lighting, creatures, VFX). Written by R&D after Charlie said the **whole game looks bad**.
Companion to `UI_STYLE_GUIDE.md`. Values are starting points. Tune them in Studio, then copy the final values back into code.

**Target look:** a bright, soft, toy-like cartoon garden, in the spirit of Grow a Garden, Adopt Me and Pet Simulator 99.
That means high sun, lifted shadows, saturated but not neon colours, smooth chunky shapes, **real meshes for anything alive**,
dense clustered foliage, and sparkly rarity VFX. Players' eyes should go to creatures first, then plots, then the scenery.

---

## 1. Honest diagnosis: why the world looks cheap right now

1. **Creatures are built from primitives** (cylinders/balls/blocks in `shared/CreatureModels/Kinds.luau`). This is the #1 problem.
   No top pet/zoo game ships primitive-assembled creatures. Pets in Pet Simulator–style games are custom Blender meshes:
   smooth shading, beveled rounded bodies, simple stubby paws, and a face decal on its own transparent part
   ([Creating simulator-styled pets in Blender](https://devforum.roblox.com/t/creating-simulator-styled-pets-in-blender/517174)).
   Visible seams, cylinder legs and sharp part edges read as "made in 5 minutes".
2. **The ground is flat parts.** There's no grass terrain, so there's no wind-animated grass and no soft edges.
3. **Lighting is too flat and grey.** The current Ambient `110,105,120` / OutdoorAmbient `150,150,165` plus ColorCorrection Saturation 0.15 give a grey-violet cast.
   `Lighting.Technology` is never set (it isn't in `default.project.json`).
4. **Sparse, evenly-spaced props** look like a grid of placeholders instead of a garden.
5. **Lots of Neon (8 uses).** Neon on big surfaces blows out with bloom and looks cheap. Keep it for small accents only.

---

## 2. Lighting (exact values)

Set Technology in **`default.project.json`** (Rojo `$properties` on Lighting), not from a script:
```json
"Lighting": { "$properties": {
  "Technology": "Future", "ClockTime": 14, "Brightness": 3,
  "GlobalShadows": true, "ShadowSoftness": 0.25,
  "Ambient": [0.55, 0.55, 0.58], "OutdoorAmbient": [0.52, 0.52, 0.56],
  "EnvironmentDiffuseScale": 1, "EnvironmentSpecularScale": 0.35
} }
```
- **Technology:** `Future` (best for night lamps and fireflies; low-end devices fall back automatically). Use `ShadowMap` if performance tests are bad.
- **Daytime ClockTime: 13.5–14.5.** A high sun gives short, clean shadows, the bright "toy" look. Spend most of the 12-minute cycle in day; golden hour
  (ClockTime 17–17.5) is a short beauty moment. Night should be **blue and readable, not dark**: Ambient `#5A6A9A`, OutdoorAmbient `#4A5A8C`, Brightness 1.2, fireflies + lamp PointLights.
- **Ambient / OutdoorAmbient lifted** (≈ 140/133 grey) so shadows are soft colour, not black. A cartoon-lighting thread recommends Ambient 163,163,163,
  OutdoorAmbient 128,128,128 and Brightness 2.67 with soft ShadowMap ([DevForum cartoon lighting settings](https://devforum.roblox.com/t/cartoon-lighting-settings/333686)).
  Keep the ambient **neutral**: a tinted ambient makes things look purplish ([DevForum cartoon lighting style](https://devforum.roblox.com/t/how-to-achieve-this-cartoon-lighting-style/782233)).
- **EnvironmentSpecularScale 0.35:** stops plastic looking wet/shiny. EnvironmentDiffuseScale 1 lets the sky colour fill shadows (the Roblox Future-lighting tutorial uses 1/1,
  [Enhance outdoor environments](https://create.roblox.com/docs/tutorials/3D-art/enhancing-outdoor-environments-with-future-lighting)).

**Atmosphere** (in code, Sky.luau):
| Property | Day value | Why |
|---|---|---|
| Density | **0.22** | Enough depth haze to soften the far map edge, but plots stay crisp (the doc says higher density obstructs the view) |
| Offset | **0.3** | A gentle horizon silhouette; too low lets the sky bleed through terrain |
| Color | `#CDEBFF` | Light sky blue haze |
| Decay | `#FFE3C4` | A warm tint away from the sun |
| Glare | **0.25** | Soft sun glow (needs Haze > 0) |
| Haze | **1.2** | Dreamy distance |
Property meanings are from [Atmosphere docs](https://create.roblox.com/docs/environment/atmosphere.md).

**Post-processing** (Lighting children):
| Effect | Values |
|---|---|
| ColorCorrectionEffect | Saturation **0.25**, Contrast **0.1**, Brightness **0.03**, TintColor `#FFF8EC` (very slight warm). DevForum cartoon setups use Contrast 0.1 / Saturation 0.3 / Tint 241,241,231, and 0.2 / 0.6 at the extreme ([thread](https://devforum.roblox.com/t/cartoon-lighting-settings/333686)). Don't go above 0.35 or the greens turn radioactive. |
| BloomEffect | Intensity **0.4**, Size **24**, Threshold **1.6**: only Neon/glowing VFX bloom, not white walls. (Some cartoon builders skip bloom entirely; we keep it subtle for rarity glow.) |
| SunRaysEffect | Intensity **0.06**, Spread **0.55** |
| DepthOfFieldEffect | **Off during gameplay** (it blurs your own zoo). Use it only in photo mode / cutscenes: FocusDistance 30, InFocusRadius 25, FarIntensity 0.25, NearIntensity 0. |
| BlurEffect | Only behind open UI windows (Size 0 → 10), in the Camera, client-side |
| ColorGradingEffect | Leave the `TonemapperPreset` at Default (vivid). `Retro` is less saturated ([post-processing docs](https://create.roblox.com/docs/environment/post-processing-effects.md)). |

Weather looks (already in Sky.luau) are fine, but make Rain/Thunder **cooler, not greyer**: Saturation no lower than -0.05, a blue tint `#DCE8FF`.

**Sky:** a cartoon skybox from the Creator Store (search `cartoon sky`, `stylized skybox`, `anime sky`, `clouds skybox`) with puffy white clouds on light blue.
With no asset, the default sky + the Atmosphere above is acceptable. Keep `SunAngularSize` 14 and add a few big **3D cloud meshes** (search `low poly cloud`)
around the map edge at different heights. This is cheap and very effective.

---

## 3. Ground: terrain vs parts

| Surface | Build with | Values |
|---|---|---|
| Main ground (hub, around plots, map edge) | **Terrain Grass** via `Terrain:FillBlock` / `FillRegion` (2–4 studs thick) | `Terrain.Decoration = true` (animated grass blades, the single cheapest "alive" upgrade). `Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromHex("#6CC644"))` |
| Rolling edges/hills | Terrain `FillBall` hills (r 20–60) around the map edge | Hides the map edge. Put trees on top. |
| Paths | Terrain **Ground** or **Sandstone** strips 12–16 studs wide, or a part path with SmoothPlastic `#EBD5A6` and rounded corner pieces | `SetMaterialColor(Ground, #D9B98A)` |
| Ponds / Pond Tank | **Terrain Water** | `Terrain.WaterColor = #3CC3E8`, `WaterTransparency 0.35`, `WaterReflectance 0.4`, `WaterWaveSize 0.08`, `WaterWaveSpeed 6`. Rim it with Rock/Sand terrain. |
| Plot floors | Parts (players build on them), SmoothPlastic, **slightly lighter/warmer green than the terrain** (`#8BD65E`) with a 1-stud raised wooden border | The plot reads as "your land" |
| Exhibit tiles (biomes) | Parts, SmoothPlastic or Sand/Slate/Ice per biome, using the existing biome palette | Use a **bevel/edge trim** (a thin darker strip) on each tile edge, not a raw cube |
| Rock/cliff | Terrain Rock / Slate, `SetMaterialColor(Rock, #9AA3B5)` | |

Materials: **SmoothPlastic** is the cartoon default for props. Use the Wood/WoodPlanks materials for fences and signs, Grass/Sand/Ice only where the texture helps,
and **never the default studded Plastic or big Neon surfaces**. MaterialVariants need uploaded textures, so skip them for now (optional later: one
stylized grass variant, see [Material docs](https://create.roblox.com/docs/parts/materials.md)).

---

## 4. World colour palette and saturation rules

**Saturation hierarchy (most important rule):** ground and backdrop are *medium* saturation, props are *higher*, and **creatures + rarity VFX are highest/brightest**.
If the ground is as saturated as the creatures, nothing pops.

| Group | Hex |
|---|---|
| Grass terrain | `#6CC644` (hub), backdrop hills `#5FB13D` |
| Plot floor | `#8BD65E` |
| Path | `#EBD5A6`, edge `#C9A979` |
| Wood (fences, signs, stalls) | `#B8784A`, dark trim `#7A4A2A` |
| Stall roofs (alternate) | `#FF7B7B`, `#FFD45C`, `#7FD0FF`, `#C79BFF` (white stripes `#FFF6E6`) |
| Water | `#3CC3E8` |
| Rock | `#9AA3B5` |
| Tree leaves (mix 3 per cluster) | `#4FBF4A`, `#7AD65A`, `#A8E36A` (+ blossom trees `#FFB3D9`) |
| Flowers | `#FF6FA8`, `#FFD54F`, `#FFFFFF`, `#8F7CFF`, `#FF8A3D` |
| Sky haze | `#CDEBFF` |
| Night | ambient `#5A6A9A`, fireflies `#FFF3A0` |
Biome kits and rarity colours: keep RESEARCH.md "For Graphics". Rarity colours are in UI_STYLE_GUIDE §6.

Rules: no pure white `#FFFFFF` or pure black on large surfaces. No grey props (tint them warm or cool). Max ~6 hues per screen; repeat them.

---

## 5. Creatures and plants (the big one)

**Be honest: primitive-built creatures look cheap.** This is the change with the most visual impact. In order of preference:

1. **AI mesh generation in Studio (the orchestrator can do this via the Studio MCP / Assistant).** Studio's Assistant has `/generate_mesh`, which makes a
   **textured mesh from a text prompt or an image**. Selecting a Part first uses it as a **bounding box**. The optional max triangle count defaults to **10,000**,
   and lower values give a more faceted low-poly look ([Assistant guide](https://create.roblox.com/docs/assistant/guide)). Roblox's Cube model powers 3D generation
   ([Roblox Cube](https://corp.roblox.com/newsroom/2025/03/introducing-roblox-cube)). In-experience `GenerationService:GenerateModelAsync` only supports the
   `Car5`/`Body1` schemas, so do generation at **edit time**, not at runtime ([Model generation](https://create.roblox.com/docs/parts/model-generation)).
   - Settings: max triangles **2,000–4,000** per creature (many on screen), a bounding box of 3×3×3 studs.
   - Prompt template: *"cute chibi [plant] creature, big round head, huge shiny eyes, tiny stubby legs, smooth soft cartoon style, pastel [colour],
     toy figurine, simple shapes, no background"*. Example species: "sunflower lion cub with petal mane", "cactus hedgehog", "mushroom frog",
     "lily-pad turtle", "frost fern fox", "bluebell bunny".
   - Generate **one base mesh per species** and do rarity/mutation variants with **colour tint + VFX + size**, not new meshes.
   - Save each as a Model in `ReplicatedStorage/CreatureMeshes/<Species>` and **export the .rbxm into the repo**. Code then clones by name, and falls back to the primitive
     builder only if the mesh is missing. Note the asset IDs in the README.
2. **Creator Store free models** (Toolbox → Models, check **"Creator Store" verified / no scripts**, and delete any scripts inside). Search terms:
   `cute low poly animal`, `chibi pet`, `simulator pet`, `low poly bunny`, `low poly fox`, `cute frog`, `cute turtle`, `plant monster cute`, `mushroom creature`,
   `cactus character`, `flower creature`, `slime pet`. Pick a **single art style** (same outline/no-outline, same proportions).
3. **If staying with primitives for a species (fallback only):** use only `Ball` + rounded shapes (no cylinders for legs; use small balls), make the head
   **60% of body height**, put big eyes (black ball + white specular dot) on the front, no visible gaps, SmoothPlastic, and one part = one colour. Add a squash-and-stretch
   bob animation. This still looks primitive; treat it as a placeholder.

**Proportions (all creatures):** head ≈ body size or bigger, eyes in the lower half of the head, tiny limbs, a round silhouette. Scale **2.5–3.5 studs** tall (Common) →
up to 4.5 studs (Legendary+), so they read from the default camera.
**Motion sells "alive":** an idle bob (0.15 studs, 1.2 s Sine), a hop when moving, blinks (eye scale Y 1 → 0.1 → 1 every 3–6 s random), and a little spin when Thriving.

**Plants (growth stages):** generate or source a **seed mound → sprout → bud → bloom** set per biome (4 meshes, reused across species with tint).
Search `low poly sprout`, `cartoon flower`, `stylized plant`, `seedling`, `low poly bush`. Stage pops: scale 0.6 → 1.1 → 1 (Back Out, 0.4 s) + a leaf particle burst.

---

## 6. Props and foliage

- **Cluster, don't scatter.** Groups of 3–5 (one big, two medium, one or two small), random Y rotation, scale ×0.8–1.3, slight colour variation (±5% lightness).
- **Density targets:** the hub has 1 tree cluster per ~40×40 studs. Along every fence line there's a flower strip (a flower every 2–3 studs, 3 colours). Each plot corner gets a bush.
- **Frame the map** with a ring of dense trees + hills + clouds, so there's no visible void or baseplate edge.
- **Hub landmarks:** each shop is a **stall with a coloured striped awning, a big sign (SurfaceGui, FredokaOne, white text, dark stroke), and a 3D icon prop on top**
  (a giant seed bag, a coin, a book), so players find shops from far away. This is Grow a Garden's seed/gear/sell-stall approach of physical shops
  ([GAG guide](https://gamertweak.com/how-to-play-grow-a-garden/)).
- Creator Store search terms (free models, check for scripts):
  - Trees: `low poly tree`, `stylized tree`, `cartoon tree`, `blossom tree`, `round tree`, `palm tree low poly`, `pine tree low poly`
  - Bushes/flowers/grass: `low poly bush`, `cartoon flowers`, `flower patch`, `tulip`, `stylized grass clump`, `mushroom low poly`
  - Fences/paths: `wooden fence low poly`, `picket fence`, `stone path`, `stepping stones`, `garden arch`, `lamp post cartoon`
  - Zoo props: `zoo sign`, `zoo entrance`, `market stall`, `food stand`, `bench low poly`, `trash can cartoon`, `balloon`, `greenhouse`, `glass dome`, `aquarium`
  - Rocks/terrain dressing: `low poly rock`, `cliff low poly`, `pond`, `lily pad`, `log`, `stump`
  - Sky: `low poly cloud`, `cartoon sky`
  Off-platform stylized nature packs exist if Charlie wants to buy some (e.g. [Stylized Grass & Flowers](https://builtbybit.com/resources/stylized-grass-and-flowers-asset-pack.106964/),
  [Stylized Nature Pack](https://builtbybit.com/resources/stylized-nature-pack.114796/)). Note them in the Charlie TODO list.
- Performance: set `CastShadow = false` on small flowers/grass clumps, `CanCollide = false` + `CanQuery = false` on decoration, and keep instances under control with
  StreamingEnabled (default).

---

## 7. Plot / zoo layout readability

- Each plot has a **raised 1-stud wood border**, a lighter floor colour, a **big owner sign** at the entrance (BillboardGui/SurfaceGui with the player name + zoo level),
  and an arch gate facing the hub. Unclaimed plots: grey-green floor + a floating "CLAIM" sign that bobs.
- Paths **12–16 studs** wide from the hub to every plot. A clear sightline from spawn to the seed shop.
- Exhibits: low fences (2–3 studs) so creatures stay visible from outside. Glass for the Pond Tank (Transparency 0.6, Glass material).
- **Height variation:** the hub sits 2 studs lower (or plots are on gentle terraces), so the overview from spawn shows everything.
- Biome tiles get a **thin trim edge** of a darker biome colour, which makes placed builds look finished.

---

## 8. VFX for rarity and feedback

| Rarity | On the creature |
|---|---|
| Common / Uncommon | none (maybe a tiny dust puff when hopping) |
| Rare | a blue sparkle ParticleEmitter: Rate 2, Lifetime 1–1.5, Size 0.3→0, LightEmission 1, Speed 0.5, SpreadAngle 180 |
| Epic | a purple sparkle (Rate 4) + a ground ring Decal/part glow under the feet (rarity colour, transparency 0.6) |
| Legendary | gold sparkles (Rate 6) + a slow-rotating ground ring + a PointLight (Range 8, Brightness 1, gold) |
| Mythical | pink/purple sparkles + Beam swirl or orbiting particle + PointLight |
| Secret | rainbow particles (ColorSequence across 6 hues) + a black/rainbow ring + a slight float (0.5 studs) |
- `Highlight` (outline) **only for the selected/hovered creature** or the current tutorial target: a client can show only a limited number of Highlights at once (31),
  so never put one on every creature. Use FillTransparency 1 and OutlineColor = rarity colour.
- Feedback FX: coin collect → coin burst particles + a floating "+$" BillboardGui (FredokaOne, green, dark stroke); growth stage → a leaf burst;
  rare hatch/bloom → a light beam column (a Beam or a neon cylinder with Transparency 0.5 tweened up) + confetti.
- Keep Neon to **small** particles/rings. `LightEmission 1` particles look glowy without Neon.

---

## 9. Camera

- Keep the default follow camera (all top simulators do). `CameraMaxZoomDistance = 80` (let players admire their zoo), `CameraMinZoomDistance = 8`, FieldOfView 70.
- Spawn/claim moment: a 1.5 s camera tween from a high wide shot of the plot down to the player (Scriptable → Custom). Make it skippable.
- Photo mode: FOV 50, a DOF on (see §2), UI hidden.
- On a rare reveal: a quick FOV punch 70 → 64 → 70 (0.25 s).

---

## 10. Top 10 changes, ranked by visual impact

1. **Replace primitive creatures with real meshes** (AI `/generate_mesh` in Studio at 2–4k triangles, or matching Creator Store models). One mesh per species; variants by tint + VFX.
2. **Terrain grass with Decoration on** for all open ground + hills around the map edge + terrain water ponds.
3. **Lighting pass:** Technology Future in project.json, ClockTime 14, Brightness 3, neutral lifted Ambient (~140 grey), Specular 0.35, Atmosphere Density 0.22 / Haze 1.2.
4. **Colour grade:** CC Saturation 0.25 / Contrast 0.1 / warm tint, subtle Bloom (0.4/24/1.6), SunRays 0.06. Remove large Neon surfaces.
5. **Saturation hierarchy:** calmer ground, brighter props, brightest creatures.
6. **Dense clustered foliage** (Creator Store low-poly trees/bushes/flowers) + flower strips on fences + a tree/hill/cloud ring framing the map.
7. **Readable plots:** raised wood border, lighter floor, owner sign + arch gate, wide paths.
8. **Landmark shop stalls** with striped awnings, big signs and 3D icon props.
9. **Rarity VFX ladder** (sparkles → rings → lights → rainbow) and juicy collect/grow/hatch effects.
10. **Creature life:** idle bob, blink, hop, Thriving spin. Plants pop between growth stages.

---

## Sources
- https://devforum.roblox.com/t/creating-simulator-styled-pets-in-blender/517174
- https://devforum.roblox.com/t/how-are-modern-simulator-pets-made/2882620 (found; forum was in maintenance when fetched)
- https://devforum.roblox.com/t/cartoon-lighting-settings/333686
- https://devforum.roblox.com/t/how-to-achieve-this-cartoon-lighting-style/782233
- https://devforum.roblox.com/t/assistant-updates-mesh-generation-new-mcp-server-tools-screenshot-tool-and-more/4527258 (found; maintenance)
- https://devforum.roblox.com/t/beta-cube-3d-generation-tools-and-apis-for-creators/3558947 (listed)
- https://create.roblox.com/docs/assistant/guide
- https://create.roblox.com/docs/parts/model-generation
- https://corp.roblox.com/newsroom/2025/03/introducing-roblox-cube
- https://create.roblox.com/docs/tutorials/3D-art/enhancing-outdoor-environments-with-future-lighting
- https://create.roblox.com/docs/environment/atmosphere.md
- https://create.roblox.com/docs/environment/post-processing-effects.md
- https://create.roblox.com/docs/parts/materials.md
- https://www.pocketgamer.com/roblox/best-looking-games/
- https://gamertweak.com/how-to-play-grow-a-garden/
- https://builtbybit.com/resources/stylized-grass-and-flowers-asset-pack.106964/
- https://builtbybit.com/resources/stylized-nature-pack.114796/
- https://builtbybit.com/resources/low-poly-tree-pack.113974/
