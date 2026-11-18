# Wildworld: Studs Style Guide (classic brick look)

Owner: the Graphics branch (world and creatures) and the UI branch (§8). Written by R&D Art.
**This guide replaces the "lush storybook" look in `ART_STYLE_GUIDE.md`** for materials, palette, creature shapes, world geometry and lighting. The ART_STYLE_GUIDE rules on performance budgets, client-side animation tiers, and the 1 emitter + 1 light per creature limit still apply.

**Target look (Charlie's inspo `inspiration/studs-inspo-1.png`, "50 Stud Animals"):** chunky toy-brick animals made of stacked studded bricks. Studs are visible on every face and brick seams show. Bodies are boxy, heads are big, legs are short and stubby. Eyes are flat square black tiles with a small white highlight square, cheeks are pink rectangles, and the muzzle and nose are simple. Ears and tails are also bricks. Colours are bright and saturated but soft: a white bunny, an orange fox with a white chest and tail tip, a green frog with a pale belly, a grey-blue elephant with pink inner ears, a navy penguin. The setting is a grassy hill under a bright blue sky.

## Summary
- **Get studs from the legacy `SurfaceType.Studs` on `Plastic` block parts.** This is a property on parts we already create, so it needs no asset IDs and adds no instances or draw calls. Roblox only deprecated the Surface *tool*. The API is kept for backwards compatibility. Studs render **only on Plastic**, and only on block faces (not on balls, cylinders or wedge slopes). Nothing else on this list is free, so it is the primary method. Fallbacks are in §2.
- **Creatures become brick figures of 18–30 big parts, not hundreds of tiny ones.** Every size is on a stud grid: X and Z are whole studs, Y is a multiple of a 0.4 plate (1.2 = a brick). Heads are "BrickHeadz" cubes: **3×3** for small species, **4×4** for big ones. Seams come from stacked layers with ±5% value shading and a 0.1-stud inset on alternate layers. They do not come from extra parts.
- **The face is the identity.** Every species uses the same face: square black eyes (0.6×0.8) with a 0.25 white highlight square in the upper-outer corner, pink 0.8×0.4 cheek tiles, and a small muzzle block with a dark nose tile. Face tiles use **SmoothPlastic** (no studs) and sit 0.05 studs proud of the head.
- **Mutations keep the studs.** Every body part stays Plastic. Golden = gold palette + Reflectance 0.2 + sparkles. Albino = white palette + red square eyes. Crystal = pale-cyan tint + "trans-clear" crystal bricks (Plastic, Transparency 0.3) + a soft light. Glowing = Neon *marking* bricks only + a pulsing light. Each mutation must read from 30 studs through colour over large areas plus one silhouette change.
- **World:** terrain grass is swapped for **studded Plastic ground plates** (256×256 tiles), terraced brick hills, brick trees (trunk + 3 stacked square canopies) and brick fences. Lighting is flatter and brighter (ShadowMap, Brightness 3, high ambient, low atmosphere, subtle bloom). **UI: reskin the existing Kit as "toy brick" (white plastic body, brick-coloured header with a row of studs). Keep every layout and component.** Do not rebuild it, and drop the field-journal parchment.

---

## 1. Why this approach (research)

- **Legacy surfaces still work.** Roblox removed the Surface *tool* and marked its API deprecated, but [says it will maintain the API "for the foreseeable future"](https://devforum.roblox.com/t/deprecating-surface-tool-api/1222218). Community reference pages list Studs and Inlet as *not* deprecated (only Glue is). They also say surfaces only appear on **Plastic** ([Roblox Wiki: Surface](https://roblox.fandom.com/wiki/Surface), [DevForum](https://devforum.roblox.com/t/why-dont-surfaces-appear-once-a-material-is-chosen/802554)). The author of the HD stud materials confirms that legacy studs "only work with plastic" ([HD Stud Materials](https://devforum.roblox.com/t/hd-stud-materials-and-creation-pipeline-now-with-welds/2916846)). Builders still set them from the command bar or a script by setting each `*Surface` property ([tutorial](https://devforum.roblox.com/t/how-to-change-a-parts-surface-to-studs-no-textures-or-decals-required/3497234)).
- **Performance.** Roblox's guidance is that built-in materials use far less memory than custom textures, and that you should stay under about 1,000 draw calls ([Performance: design](https://create.roblox.com/docs/performance-optimization/design.md)). A `Texture` instance per face (six per brick) on hundreds of creature parts would multiply instances and draw cost. A legacy surface is just a property.
- **Brick-figure design.** BrickHeadz-style figures are built around a perfect square head cube, usually 4×4 studs, and 3×3 for small characters. Character comes from the eyes plus silhouette additions (ears, horns, hair). Mouths are usually left off except on animals ([BrickNerd study](https://bricknerd.com/home/brickheadz-blueprints-a-study-of-shape-and-form-1-19-23), [custom BrickHeadz tips](https://unnecessarynews.substack.com/p/10-tips-to-make-custom-lego-brickheadz)). The inspo image follows this exactly.

## 2. Stud technique (exact)

### 2.1 Primary: legacy surfaces (use this)
```lua
-- Theme/Kit.luau + CreatureBuilder makePart, for every "Brick" part
part.Material = Enum.Material.Plastic          -- REQUIRED: studs only render on Plastic
part.TopSurface = Enum.SurfaceType.Studs
part.BottomSurface = Enum.SurfaceType.Inlet
-- creatures ("All" mode, matches inspo): also Front/Back/Left/Right = Studs
-- world ("Top" mode): sides = Enum.SurfaceType.Smooth
```
- **Stud density is fixed by the engine at about 1 stud per 1×1 stud of face area.** A 3×3 head face shows 3×3 studs. This is why creatures must be built at the sizes in §4. Small parts show too few studs, and a creature with a 2-stud head reads as smooth. *Verify in Studio on the first build: drop a 4×1.2×2 Plastic block with all surfaces set to Studs, and you should see 8 studs on top.*
- **Use whole-stud X/Z sizes** so studs line up and no half-studs are cut off at the edges. Babies and juveniles are scaled (`part.Size = size * scale`), so they show partial studs. That is acceptable, and the coarser studs make them look cuter. If Gameplay is flexible, Baby scale 0.5 would read better as 0.6.
- `WedgePart` slopes show no studs. That is authentic (real slope bricks are smooth), so use wedges for ear tips, snouts and roofs.
- Balls, cylinders and `SpecialMesh` blobs show no studs. **Remove them from creatures entirely.** Keep them only for round props (toy ball, lantern glass, bowls).
- Studs show on all quality levels. Selene/stylua have no issue with the `*Surface` properties.

### 2.2 Fallback A: stud Texture (only if legacy studs ever stop rendering)
- `Texture` instance on a face: `StudsPerTileU = 1`, `StudsPerTileV = 1`, `Color3` = part colour, `Transparency = 0`. **No public stud texture ID could be verified from this environment** (the Roblox asset API is blocked by the proxy). One community ID, `rbxassetid://8130710802`, is posted as a recolourable generic surface texture with 1×1 tiling ([thread](https://devforum.roblox.com/t/where-can-i-get-textures-of-the-studs-inlets-glue-and-etc-surfaces/1569174)). Treat it as **unverified**.
- If this fallback is needed, the safest option is a Charlie TODO: upload a 128×128 PNG stud tile (one light-grey stud with a soft AO ring on a transparent background) and put its ID in `Config.StudTextureId`. Apply it to **top faces of world plates only**, never to creature parts.

### 2.3 Fallback B: MaterialVariant
- Community "HD studs" MaterialVariants (2×2 / 4×4 Plastic and Smooth) are published as Creator Store model **17042355690** ([thread](https://devforum.roblox.com/t/hd-stud-materials-and-creation-pipeline-now-with-welds/2916846)). An older pack, "Studs As PBR Materials", is model **11120912366** ([thread](https://devforum.roblox.com/t/how-to-get-back-the-old-stud-texture-easily-includes-meshes-unions/3157449)). Neither ID was verified here.
- MaterialVariants can't target a single face ([same thread](https://devforum.roblox.com/t/how-to-get-back-the-old-stud-texture-easily-includes-meshes-unions/3157449)). Overriding terrain materials costs performance if the place uses legacy terrain ([MaterialService docs](https://create.roblox.com/docs/reference/engine/classes/MaterialService.md)). **Not recommended for the MVP.** The legacy surfaces in §2.1 already give the look.

## 3. Palette (Plastic, exact hex)

Studs and Plastic darken the read colour slightly, so pick values one step brighter than you would for SmoothPlastic. Use soft-saturated colours like the inspo, not pure primaries. The nearest classic BrickColor is listed as a reference.

| Token | Hex | ≈ BrickColor | Use |
|---|---|---|---|
| GrassTop | `#5CB83C` | Bright green | ground plates |
| GrassAlt | `#52AA36` | Bright green (dark) | checker tile / alternating plates |
| GrassSide | `#3F8F2E` | Dark green | terrace sides, hill steps |
| Dirt | `#A0703F` | Dark orange | cliff/terrace sides under grass |
| Path | `#E3CFA0` | Brick yellow | paths, plaza ring |
| PathEdge | `#B89C6B` | Nougat (dk) | path border plates |
| Plaza | `#E5E4DF` | Light stone grey | hub floor |
| Stone | `#A3A2A5` | Medium stone grey | rocks, walls |
| StoneDark | `#635F62` | Dark stone grey | rock shading layer |
| Wood | `#B07A45` | Nougat/brown | fences, stalls |
| WoodDark | `#694028` | Reddish brown | trunks, posts |
| Leaf1 / 2 / 3 | `#3E9B45` / `#5CC04A` / `#A4CF4A` | Earth/Bright/Br. yellowish green | tree canopy layers, bottom→top |
| Water | `#3FA9F5` (Transparency 0.35) | Bright blue (light) | ponds, waterfall bricks |
| Sand | `#F2D98A` | Cool yellow | sand patches |
| White | `#F4F5F7` | Institutional white | fences, clouds, bunny |
| Red / Blue / Yellow (roofs, awnings, toys) | `#E0453A` / `#2F7FE0` / `#F5CD30` | Bright red / blue / yellow | hub buildings, stalls |
| Pink accent | `#FF9EB5` | Light pink | cheeks, inner ears |
| Eye | `#1B1B1F` | Really black | eyes, nose |
| Sky (Atmosphere colour) | `#BFE3FF` | | |

Flowers: `#E0453A`, `#F5CD30`, `#FFFFFF`, `#FF98DC`, `#6E99CA`.
Keep the existing `Palette.Rarity` and `Palette.Mutation` tables unchanged. UI and VFX already depend on them.

## 4. Creatures: brick figures

### 4.1 Universal rules
- **Grid:** X and Z are whole studs. Y is in plates (0.4) or bricks (1.2). Rotate parts only in 90° steps, except ear and antler tilts of ≤15°.
- **Proportions:** head cube ≥ body width. Legs 0.8–1.2 tall (Thornstag up to 3.2). The head sits on the body with a 0.4 overlap.
- **Part budget:** 18–30 parts per adult, including face tiles. Average about 24, which is close to today's ~15–25, so the existing animation tiers hold.
- **Seams without extra parts:** (a) Split the body and head into 2–3 stacked layers ("slabs") instead of one tall block. (b) The builder multiplies the colour value of every other layer **×0.95**. (c) Inset the middle layer by **0.1 stud** on X and Z so a thin shadow line shows. These three together read as brick seams in the inspo.
- **Surfaces:** body parts get studs on all 6 sides (`Studs` on 5, `Inlet` on the bottom). Face tiles (eyes, highlights, cheeks, nose, belly patch) use **SmoothPlastic** with smooth surfaces.
- **Hue jitter:** reduce `HUE_JITTER` from 0.06 to **0.02**. Brick colours should look like catalogue colours, not muddy.
- **CastShadow:** body and head only (same as now).

### 4.2 The standard face (new `Shapes.BrickFace`)
Facing -Z, measured on the head's front face (z = head front - 0.05):

| Piece | Size (W×H×D) | Position | Colour |
|---|---|---|---|
| Eye L/R | 0.6×0.8×0.1 (4×4 heads: 0.8×1.0) | x = **±0.7** (3-wide head) / **±1.0** (4-wide head); y = 55% of head height | `#1B1B1F` |
| Highlight L/R | 0.25×0.25×0.05 | upper-outer corner of each eye, 0.03 proud | `#FFFFFF` |
| Cheek L/R | 0.8×0.4×0.1 | under and 0.3 outside each eye, 0.5 below the eye centre | `#FF9EB5` |
| Muzzle | 1.6×1.2×0.6 (3-wide) / 2×1.2×0.8 | centre, bottom third | species Belly colour |
| Nose | 0.6×0.4×0.1 | top-centre of the muzzle | `#1B1B1F` (Lumibun: `#FF9EB5`) |

Eye role "Eye" stays, so Albino can recolour it. Highlight role becomes "EyeShine" (squares, not balls). This is about 9 parts, identical on every species, so the five species read as one family.

### 4.3 Species mapping (adult sizes in studs, facing -Z)

**Lumibun → inspo white bunny** (≈20 parts)
- Body 3×2.4×3 (2 slabs of 1.2), belly tile 2×1.6×0.1 on the front (Belly).
- Head 3×3.2×3 (slabs 1.2 / 1.2 / 0.8), centred on the body, top at y≈5.6.
- Feet 2× 1×0.8×1.6, poking 0.6 forward.
- Ears 2× 1×3.2×0.6, tilted ±8°. Inner ear tile 0.6×2.4×0.1 (Secondary pink) on the front. **Ear tips** 1×0.8×0.6 (Glow role, the hero feature).
- Tail: 1×1×1 cube at the back (Secondary).
- Palette: Primary `#F4F5F7`, Secondary `#FFB7CE`, Belly `#FFFFFF`, Accent `#D9C6F5` (spot tiles when pp), Glow `#9FE8FF`. Alt (cc): Primary `#D9B48C`, Secondary `#FFE3C2`, Accent `#A87C55`, Glow `#FFE27A`.

**Emberfox → inspo orange fox** (≈26 parts)
- Body 2×2.4×4 (2 slabs). Chest block 2×1.6×0.6 on the front (Belly, white).
- Head 3×2.8×3. Muzzle 1.6×1.2×1 white, protruding. Nose 0.6×0.4.
- Ears 2× WedgePart 1×1.6×0.6 (triangle silhouette) with a dark 1×0.4×0.6 tip plate (Accent).
- Legs 4× 0.8×1.2×0.8, with a 0.8×0.4×0.8 dark "sock" plate at the bottom of each (Accent).
- Tail = 3 bricks stepping up and back: 1×1×1.6 → 1.4×1.4×1.6 → 1.2×1.2×1.2 white tip (Belly), plus a **Glow 0.8 cube** on the tip (hero feature, ember emitter host).
- Palette: Primary `#F5862A`, Secondary/Belly `#FFF4E6`, Accent `#4A2E22`, Feature `#F5862A`, Glow `#FFC84A`. Alt: Primary `#E8D9C8`, Accent `#6B5A70`, Glow `#9FE8FF`.

**Mossback → wide, low moss tortoise, with the inspo frog's green/pale-belly scheme on its hump** (≈24 parts)
- Body 4×2×5 (slabs 1.2 + 0.8). Underside plate 4×0.4×5 (Belly).
- **Moss hump = ziggurat:** 4×1.2×4 → 3×0.8×3 → 2×0.8×2 (Feature green, the ×0.95 alternation makes the steps read). 3 flower studs, each 0.6 cube (Glow pink / `#F5CD30`).
- Head 3×2.4×3, low at the front (top flush with body top + 0.4).
- Legs 4× 1.2×1.2×1.2 stubby cubes. Tail: 0.8 cube.
- Palette: Primary `#A87C55`, Secondary/Belly `#F2D6B3`, Accent `#7A5A40`, Feature `#6FC24A`, Glow `#FF8FB8`. Alt: Primary `#7C8898`, Feature `#3FAF8A`, Glow `#FFE27A`.

**Pebblehorn → inspo grey-blue elephant** (≈27 parts)
- Body 4×3.2×5 (3 slabs). Head 4×3.6×3.6 (4×4 face class).
- **Ears:** 2× flat slabs 0.4×2.4×2.4 on the head sides, with a pink inner tile 0.1×1.6×1.6 (`#FFB7CE`), as in the inspo elephant.
- **Horn stack on the nose (hero feature):** cubes 1.2 → 0.8 → 0.6 stacked up and forward (Feature).
- Back plates: 3× 1.2×1.2×1.2 rotated 45° on Y along the spine (Accent teal).
- Legs 4× 1.6×2×1.6.
- Palette: Primary `#9FAED0`, Secondary/Belly `#DDE4F0`, Accent `#5FD3C4`, Feature `#E8ECF4`, Glow `#5FD3C4`. Alt: Primary `#A0785A`, Secondary `#E6CBA8`, Accent `#FF9E6B`, Feature `#D8B48A`.

**Thornstag → deer, tall and proud** (≈30 parts; Rare, so it may use the full budget)
- Body 2.4 → round to **3×2.8×4.4** (Z may be non-integer at the back, hidden by the tail). Chest 2×2×0.6 (Belly).
- Neck 1.6×2×1.6. Head 3×2.8×3 with a 1.6×1.2×1.2 muzzle.
- Legs 4× 0.8×3.2×0.8 (the tallest species, which gives a "proud" silhouette) with 0.8×0.4 dark hooves.
- **Antlers (hero feature), per side:** upright 0.6×2.4×0.6 + branch 1.6×0.6×0.6 + small upright 0.6×1.2×0.6 (Feature brown), plus 2 leaf-bud cubes 0.6 (Accent green). Antlers use studs on all faces.
- Tail: 1×1.2×0.6 white.
- Palette: Primary `#C89263`, Secondary/Belly `#F5E3C8`, Accent `#5CC04A`, Feature `#7A4A2A`, Glow `#A8E36A`. Alt: Primary `#8C8FA8`, Accent `#FF9EC8`, Glow `#FFB3D9`.

### 4.4 Readability checks (Graphics must pass)
1. **Silhouette test:** fill all parts black at 40 studs and check that each species is identifiable (bunny = tall ears, fox = steps-up tail, Mossback = ziggurat hump, Pebblehorn = wide head + ear slabs + nose stack, Thornstag = long legs + antlers).
2. **Face at 20 studs:** the eyes and highlight squares must be visible. If not, go up to the 0.8×1.0 eye.
3. **Viewport thumbnails** (UI CreatureCard): a 3/4 front view, camera FOV 30 and yaw 25°, shows studs on the top and front of the head.

## 5. Mutations in brick style (`CreatureBuilder/Mutations.luau`)
Order and exclusivity stay the same (recolour → material → attachments → VFX; Albino beats Golden). **Never switch body parts away from Plastic, because that removes the studs.**

| Mutation | Recolour (body roles) | Material/props | Attachments | VFX (≤1 emitter + 1 light) |
|---|---|---|---|---|
| **Golden** | Primary `#F5C542`, Secondary `#E0A11B`, Belly `#FFE38A`, Accent/Feature `#C98A12` | Plastic, **Reflectance 0.2** (studs stay) | Optional 1×0.4×1 gold "crown plate" on the head (Feature) | Sparkle emitter, Rate 4, Size 0.3–0.5, colour `#FFF3A0`, LightEmission 1 |
| **Albino** | Primary `#F6F2EE`, Secondary `#FFE6EC`, Belly `#FFFFFF`, Accent `#FFD6DE` | Plastic | Eyes `#E8505B` (squares stay square), cheeks `#FF7FA0` (stronger) | none (subtle by design, the eyes sell it) |
| **Crystal** | Body lerp **35%** toward `#9FE8FF` | Plastic | 3–4 **crystal bricks** at the blueprint `Shards` mounts: a stack of 0.8×1.2×0.8 + 0.6×0.8×0.6, rotated 45° on Y, **Plastic, Transparency 0.3, Reflectance 0.15, colour `#9FE8FF`**, studs on (reads like a clear toy brick) | PointLight `#9FE8FF`, Range 8, Brightness 0.6 (always on) |
| **Glowing** | none on the body | **Accent + Glow role parts → Neon** (`#7CFFB2` if the species Glow is dark). Studs vanish on those parts only, which is intended: they read as glow-in-the-dark pieces | none | PointLight `#7CFFB2`, Range 10, Brightness 1, pulse 0.6–1.2 over 2 s (existing `Pulse` attr) |
| **Gilded Crystal** | Golden recolour | Plastic + Reflectance 0.2 | crystal bricks coloured `#FFE9A8` | Golden sparkle (emitter) + PointLight `#FFE9A8` Range 8 |

Rules: Neon is reserved for Glowing markings and Lumibun/Emberfox native glow parts. Bloom threshold 2.2 (§7) means only Neon blooms. Particle textures stay as they are now. Square "confetti brick" particles are optional polish.

## 6. World in brick style

**Terrain vs parts:** studs can't render on Terrain, so the **playable area becomes Plastic parts**. Terrain is removed (or kept only for distant backdrop under far fog). This also makes `Scatter.GroundY` raycasts hit parts. Keep ground parts `CanQuery = true`.

- **Ground:** tiles of 256×4×256 Plastic (top at y = 0, `TopSurface = Studs`, sides Smooth). Alternate `GrassTop`/`GrassAlt` in a checker so the plates read as baseplates. Expect about 100 parts for a 2,500-stud map.
- **Paths/plaza:** 0.4-thick plates on top of the ground (top y = 0.4), studs on top, with a 1-stud `PathEdge` border plate. Width stays as now.
- **Hills/backdrop:** terraced ziggurats. Each level is 1.2–2.4 tall and 4–8 studs narrower than the one below. Tops are `GrassTop` with studs and sides are `GrassSide` (cliffs: `Dirt`, with `Stone` toward the base). Max 6 levels, at most 8 hills, so about 50 parts.
- **Water:** sunken basin. The floor plate is `#2F7FE0`, and the water surface part is `Water` SmoothPlastic, Transparency 0.35, Reflectance 0.1, 0.4 below ground. The rim is 1-stud grey plates. The waterfall is stepped transparent blue bricks, keeping the existing Beams and mist emitter.
- **Trees:** trunk 2×6×2 `WoodDark`, then canopy layers 8×2.4×8 (Leaf1), 6×2.4×6 (Leaf2) and 4×1.2×4 (Leaf3), all studded on every face. That is 4 parts. Pine: 4 squares 7/5/3/1 wide, 1.6 tall each, in `#3E9B45`. MagicTree: the same with `#FFB3D9`/`#B9A4FF` layers and 2 Neon 1×1 buds.
- **Bush:** 3×2.4×3 + 2×1.2×2 offset, with optional 0.6 red berry cubes. **Flower:** stem 0.4×1.2×0.4 + a 1×0.4×1 coloured plate. **Rock:** 2–3 offset `Stone`/`StoneDark` bricks, and mossy = a green 0.4 plate on top. **Log:** 2×2×6 brown brick with a light end tile.
- **Fences:** posts 1×3.6×1 every 4 studs plus 2 rails 1×1.2×L, studs on top, `White` or `Wood`. **Clouds:** 3 flat white SmoothPlastic blocks (8×2×6, 6×2×4, 4×1.6×4).
- **Hub buildings/stalls:** walls are Plastic with studs on all faces in `White`/`Plaza`, roofs are WedgePart slopes in Red/Blue, and awnings are alternating 1-stud stripes (Red/White, Yellow/White).
- **Foliage density:** clusters of 3–5 trees as before, but brick trees are bigger and blockier, so use **about 30% fewer instances** than the lush plan. Set CastShadow off on flowers, small rocks and fence rails.
- **Creator Store search terms** (scenery only, strip scripts; most of this is easy to build in code, so this is optional): "classic brick tree", "lego style tree", "studs house", "classic roblox building", "brick fence".

## 7. Lighting for the brick look (exact)
`default.project.json` Lighting:
```json
"Technology": "ShadowMap", "ClockTime": 14.5, "Brightness": 3,
"GlobalShadows": true, "ShadowSoftness": 0.2,
"Ambient": [0.55, 0.55, 0.58], "OutdoorAmbient": [0.6, 0.6, 0.62],
"EnvironmentDiffuseScale": 0.5, "EnvironmentSpecularScale": 0.2,
"GeographicLatitude": 30
```
- **Atmosphere:** Density **0.18**, Offset 0.1, Color `#BFE3FF`, Decay `#9CCBFF`, Glare 0, Haze 0.5. Keep the biome tints from ART_STYLE_GUIDE §1, but multiply each biome Density by 0.7.
- **ColorCorrection:** Saturation **0.12**, Contrast **0.12**, Brightness 0.03, Tint `#FFFFFF`. Brick colours are already saturated, so don't push this higher.
- **Bloom:** Intensity 0.2, Size 18, Threshold **2.2**. **SunRays:** 0.03 / 0.5.
- **Night:** same as before (Ambient `#5A6A9A`, OutdoorAmbient `#4A5A8C`, Brightness 1). Neon markings and crystal lights carry it.
- The "blue sunburst sky" in the inspo is a thumbnail/loading-screen treatment. Use it in the game icon and in UI, not in the 3D sky.

## 8. UI: recommendation (Manager: follow this)
**Reskin the existing Kit to "toy brick". Do not rebuild it, and do not keep the field-journal parchment.** Reasons: parchment and stitched teal ink clash with a plastic-brick world. The inspo's typography (chunky rounded white title with a dark outline and gold 3D numbers) already matches our Kit recipe (FredokaOne, white-base gradient faces, 6 px lip). Changing only tokens and window chrome is about 3 files and keeps every window, layout, CreatureCard and mobile rule working.

## For Graphics (rebuild list, mapped to files)
1. `src/shared/Theme/Palette.luau`: replace the world tokens with §3 (keep `Rarity` and `Mutation`). Add `GrassAlt`, `GrassSide`, `Dirt`, `Stone`, `StoneDark`, `White`, `Red`, `Blue`, `Yellow`, `Pink`, `Eye`.
2. `src/shared/Theme/Kit.luau`: default material → **Plastic**. Add `Kit.Brick(parent, size, cf, color, studs: "Top"|"All"|"None")`, which sets the surfaces per §2.1 (bottom Inlet). Keep `Ball`/`Blob`/`Cyl` for round props only, with SmoothPlastic.
3. `src/shared/Theme/Nature.luau`: Tree/Pine/MagicTree/Bush/Flower/FlowerPatch/Rock/Log/Pond/Cloud → brick versions per §6 (4–6 parts each).
4. `src/shared/Theme/Structures.luau`: FenceRun (posts + rails), Path (plate), FoodBowl (2×1.2×2 brick + yellow 1×1 food cubes), WaterTrough, ShelterHut (brick walls + wedge roof), Lantern (keep the glass SmoothPlastic + light), Bench, SnackStand (striped awning), SandPatch, Waterfall (stepped transparent bricks).
5. `src/shared/Theme/Decor.luau`: CrystalCluster → stacked clear Plastic crystal bricks (Transparency 0.3) + 1 PointLight. GlowShroom → stem cube + Neon cap plate. GrottoArch/StarterArch/StoneTotem/MossStatue → brick stacks. BigRock → 3 offset bricks.
6. `src/shared/Theme/Props.luau`: every build item uses `Kit.Brick`, on a 4-stud grid (already the case). Ghost unchanged.
7. `src/shared/Theme/Effects.luau` / `Moments.luau`: no structural change. Optional square-particle variant for Confetti/CoinBurst.
8. `src/shared/Theme/init.luau`: lighting/zone values per §7.
9. `src/shared/CreatureBlueprints/Shapes.luau`: add the `Brick` shape (`Shapes.Brick(name, size, cf, role, anim, studs?)`), `Shapes.Slab` (stacked layers with alternating ×0.95 shade + 0.1 inset), and `Shapes.BrickFace(list, headW, headH, headCenter)` per §4.2. Shard → crystal brick mounts.
10. `src/shared/CreatureBlueprints/{Lumibun,Emberfox,Mossback,Pebblehorn,Thornstag}.luau`: rewrite per §4.3 (sizes, palettes, Shards, EmitterPart = hero glow part, HeadPivot = neck point).
11. `src/shared/CreatureBuilder/init.luau` `makePart`: "Brick" → `Part` Plastic + surfaces from the spec. Face roles → SmoothPlastic. `HUE_JITTER` 0.06 → 0.02. Shade alternation from a `Layer` index in the spec.
12. `src/shared/CreatureBuilder/Mutations.luau`: §5 table. Remove any Metal/Glass switch on body parts. Crystal shards → Plastic T 0.3. Glowing → Neon on Accent/Glow only.
13. `src/server/World/Terrain.luau`: Ground/Paint/PaintDisc/Road/Hill/Lake/Backdrop/Cliff → part plates, terraces and basins (§6). `Setup()` no longer fills terrain grass.
14. `src/server/World/Hub.luau` (plaza, stalls, heart tree, board), `Forest.luau` (arches, mushrooms, meadow), `Plots.luau` (plot floor = 64×0.4×64 studded plate, `#5CB83C` owned / `#9DB98A` locked, line ~168: always Plastic), `Scatter.luau` (raycast against parts), `Sky.luau` (blocky clouds), `Waterfall.luau` (stepped bricks + existing Beams).
15. **Studio checks:** stud density verify (§2.1), silhouette test (§4.4), Render stats Draw (scene) < 1,000 on the hub view.

## For UI (reskin list, mapped to files)
1. `src/client/UI/Style.luau`: `Body` → `pal("#FFFFFF", "#E9EEF3", "#1F3B57")` (white plastic with a navy frame). `Frame` `#1F3B57`, `Ink` `#1F2A36`, `InkSoft` `#5A6B7D`. `Stitch` → rename it `Stud` and recolour it as a highlight (`#FFFFFF`, transparency 0.35). Keep `Accent` coral `#FF8A5B`, the category palettes and the fonts (FredokaOne titles, BuilderSansExtraBold body).
2. `src/client/UI/Kit/Window.luau`: replace `stitch()` with `studRow(header)`. Add a row of stud circles along the top edge of the category-colour header pill: Frame 18×18 px, `UICorner` 0.5, colour = header Top colour lightened 15%, a 2 px UIStroke in the header Dark colour, a 10 px gap, and as many as fit, with a maximum of 10. Body corner radius → 10 px (more brick, less journal).
3. `src/client/UI/Kit/Button.luau`: keep the face, gradient, 6 px lip and Back-Out press. For buttons ≥ 160 px wide, add 2 small stud circles (14 px) on the top edge. Skip them on icon buttons.
4. `src/client/UI/Kit/Parts.luau`: `Card`/`Panel` use the new Body tokens. The rarity frame stays, and gets a 3-stud row on Epic and above.
5. `src/client/UI/Kit/Extras.luau`, `Fx.luau`, `View.luau`, `init.luau`: no change, except the ViewportFrame camera for brick creatures (FOV 30, 3/4 yaw 25°, see §4.4). Thumbnails/loading screen: the blue sunburst background (`#3D8FE0` → `#7EC4FF` radial rays) behind creatures, as in the inspo.

## Sources
- [Deprecating Surface Tool API (DevForum)](https://devforum.roblox.com/t/deprecating-surface-tool-api/1222218)
- [Roblox Wiki: Surface](https://roblox.fandom.com/wiki/Surface)
- [Why don't surfaces appear once a material is chosen (DevForum)](https://devforum.roblox.com/t/why-dont-surfaces-appear-once-a-material-is-chosen/802554)
- [Change a part's surface to studs without textures (DevForum)](https://devforum.roblox.com/t/how-to-change-a-parts-surface-to-studs-no-textures-or-decals-required/3497234)
- [HD Stud Materials and Creation Pipeline (DevForum)](https://devforum.roblox.com/t/hd-stud-materials-and-creation-pipeline-now-with-welds/2916846)
- [Get back the old stud texture: MaterialVariants (DevForum)](https://devforum.roblox.com/t/how-to-get-back-the-old-stud-texture-easily-includes-meshes-unions/3157449)
- [Where to get textures of studs/inlets (DevForum)](https://devforum.roblox.com/t/where-can-i-get-textures-of-the-studs-inlets-glue-and-etc-surfaces/1569174)
- [Trendy stud texture: layering technique (DevForum)](https://devforum.roblox.com/t/trendy-stud-texture/4876870)
- [MaterialService docs](https://create.roblox.com/docs/reference/engine/classes/MaterialService.md)
- [Performance optimization: design](https://create.roblox.com/docs/performance-optimization/design.md)
- [BrickHeadz Blueprints: shape and form (BrickNerd)](https://bricknerd.com/home/brickheadz-blueprints-a-study-of-shape-and-form-1-19-23)
- [10 tips for custom BrickHeadz](https://unnecessarynews.substack.com/p/10-tips-to-make-custom-lego-brickheadz)
- [Games that execute the low-detail studs aesthetic (DevForum)](https://devforum.roblox.com/t/looking-for-games-and-showcases-that-execute-the-low-detail-studs-aesthetic-pretty-well/120873)
- [Roblox "The Classic" event (Pocket Tactics)](https://pockettactics.com/roblox/classic-event)
