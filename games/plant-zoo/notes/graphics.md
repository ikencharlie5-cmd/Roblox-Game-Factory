# Graphics notes (Sprout Zoo)

Everything is built in code by `WorldService.Init()` (server) and works straight from `rojo build`.
Real 3D assets placed in Studio under `ReplicatedStorage.Assets` are picked up automatically (see **Asset hooks**); without them every hook falls back to primitives.
Art pass (2026-11-17) follows `research/ART_STYLE_GUIDE.md`: Future lighting, terrain grass with Decoration, hills/ponds, clustered foliage, wood-bordered plots with arch gates, landmark stalls, rarity VFX ladder, no large Neon.
Anchored everywhere except creature/visitor parts, which are welded (unanchored, massless, no collision) to an anchored Root that is moved by tweens.

## Files (graphics-owned)
- `src/server/Services/WorldService.luau` — builds the world, binds gameplay attributes, public API.
- `src/server/World/`
  - `Build` (part helpers), `Plots` (6 plots), `PlotDressing` (wood curb, hedge-bush rows, flower strips, arch gate + owner sign, floor colour), `Biomes` (pad kits + locked look), `Decor` (19 decor pieces), `Hub`, `Stalls` (landmark shop stalls), `Scenery` (terrain ground, spokes, foliage, ponds, hills, clouds), `Terrain` (Smooth Terrain helpers), `Props` (asset-hook props with primitive fallback), `Sky` (lighting, day/night, weather FX)
  - `ItemVisuals` (renders `workspace.ZooItems`), `Motion` (creature bob/wander, growth pop, visitors), `Reserve` (World Reserve), `StateSync` (GameState → world)
- `src/shared/Theme/` (`init` = palette/biome kits/rarity/grid, `Effects` = particle presets, `Assets` = asset-hook lookup + fit). Shared.
- `src/shared/CreatureModels/` (`init`, `Looks`, `Kinds`, `Tops`, `Effects`, `Mesh` = mesh creature hook). Shared, so UI can put models in ViewportFrames.
- `default.project.json` → `Lighting.$properties` (Technology = Future etc.; Technology can't be set from scripts).

## Map layout (studs, ground top y = 0)
- Ground: **Smooth Terrain** 1024x1024, 12 deep, top at y = 0 (same height as the old Ground part). Grass `#6CC644` with `Terrain.Decoration = true`. Terrain **Ground** (dirt `#D9B98A`) is painted under the hub, every plot (92x92) and every spoke so grass blades don't poke through parts. Any `Workspace.Baseplate` is destroyed; an invisible `Workspace.SafetyFloor` sits at y = -14.
  - Hills: 20 terrain hills (Grass/LeafyGrass `#5FB13D`, some Rock) at r ≈ 330–420 plus a taller outer layer, trees on every other hilltop.
  - Ponds: terrain Water (`#3CC3E8`, sand rim, rocks, lily pads) between spokes at 90° and 270°, r = 100, radius 11.
- **Hub** at the origin, a Ø120 path-colored SmoothPlastic disc, central lawn with a flower ring, benches facing the fountain, lamps flanking every spoke mouth. In the center: a fountain basin with a giant blossom tree and glowing fruit (the focal point).
  Stalls sit at radius ~40, facing the center:
  - 30°: Seed Shop (restock clock on the roof)
  - 90°: Hope Shop
  - 150°: Upgrades
  - 210°: Leaderboard board
  - 270°: World Reserve diorama: 6 biome zones plus the Release Altar in the middle
  - 330°: Daily Gifts stall + `HubSpawn` SpawnLocation (r = 30)
- **Spoke paths** (14 wide, r 58 → 131) from the hub to each plot's entrance, with edge trims, 4 lamps, a bench and flower strips along both edges.
- **Plots**: plot i sits at angle (i-1)·60°, radius 170. Each is 80x80, its pivot is the center of the floor top (y = 0.5), and its LookVector points at the hub (local -Z = entrance).
  - Pads are 20x20, with their top at y = 1.3. Pad p has row = (p-1)//3, col = (p-1)%3, offset ((col-1)·24, 0, (row-1)·24). Row 0 is nearest the hub.
  - Pad grid: 5x5 cells of 4 studs. Cell 1..25 is row-major, with row 1 on the entrance side (-Z) and col 1 at -X. This is the same math as `PlotService.CellCFrame` and `Theme.CellOffset`.
  - Paths: a ring at ±37 (6 wide) and lanes at ±12 (4 wide). Border = raised 1-stud wood curb (WoodPlanks `#B8784A`, dark cap) at ±40.7 with an 18-stud entrance gap; bush hedge rows outside the back/sides, flower strips outside the front, bushes at the front corners, trees at the back corners. An **arch gate** (posts at x ±9.5, z = -41) carries the big owner sign "<Owner>'s Zoo ❤ N" (white stroked text).
  - Floor: SmoothPlastic, `#A7C495` (grey-green) while unclaimed, `#8BD65E` once `OwnerUserId` ≠ 0.
  - Tip jar: one per pad, on the path 12 studs in front of the pad center (-Z).
  - `PlotSpawn`: on the entrance path, facing into the plot.
- **Shop stalls**: counters unchanged (same size/position/tags). Each stall has 4 posts, a striped Fabric awning (roof colour / cream), a scalloped front edge, a 13x3.6 sign with white stroked text above the roof, and a 3D icon on top (seed bag / heart / up-arrow / gift box). The Seed Shop restock clock now hangs under the awning front.
- **Scenery**: meadow patches (bushes + flowers) or a pond between spokes, bushes ringing the hub, tree clusters (3–5 trees, some blossom) at r 158 and 228, an outer forest ring of 24 clusters (r 268–300), hills, 10 clouds, and firefly volumes over the hub and each plot (night only).

## CollectionService tags + attributes
| Tag | Instance | Attributes (set by Graphics) | Notes |
|---|---|---|---|
| `Plot` | Model `World.Plots.Plot<i>` (PrimaryPart `Floor`, pivot = floor top center, -Z → hub) | `PlotIndex`, `OwnerUserId`=0, `OwnerName`="", `Likes`=0 | Gameplay writes Owner*/Likes/PadsOwned; the sign updates itself. Graphics adds `ThrivingCount`, `GrownCount` |
| `ExhibitPad` | Part `Pad<p>.Base` 20x0.8x20 | `PlotIndex`, `PadIndex`, `Unlocked`, `Biome`, `Price`, `CellSize`=4, `GridCells`=5 | **Gameplay sets `Unlocked`/`Biome`/`Price` → Graphics re-renders** (hedge + price sign, or biome kit) |
| `TipJar` | invisible trigger Part 4x3x4 `Pad<p>.TipJar` (CanCollide off, CanTouch on) | `PlotIndex`, `PadIndex`, `Amount`, `Active` | Gameplay sets `Amount` → fill height + "$N" billboard. When Amount drops, a coin burst plays. CanTouch is off while the pad is locked |
| `PlotSpawn` | invisible Part | `PlotIndex` | faces into the plot |
| `PlotSign` | sign board Part | `PlotIndex` | |
| `ShopStand` | Seed Shop counter Part | `Shop`="Seed" | Gameplay adds the ProximityPrompt |
| `HopeShop` | counter Part | `Shop`="Hope" | |
| `UpgradeStand` | counter Part | `Shop`="Upgrades" | |
| `DailyStand` | counter Part | `Shop`="Daily" | |
| `ReleaseAltar` | altar Part in the World Reserve | | |
| `ReserveArea` | reserve base Part | | |
| `ReserveZone` | one per biome | `Biome`, `Count` | |
| `Leaderboard` | board Part | `Stat`="TotalEarned" | |
| `HubSpawn` | SpawnLocation | | |
| `HubCenter` | fountain spray Part | | |
| `NightLight` / `Fireflies` | lantern parts / firefly volumes | `GlowAtNight` (primitive lanterns only: Neon at night) | toggled by the day/night cycle |

Other attributes: `Lighting.IsNight` (ClockTime ≥ 18 or < 6), `workspace.WorldReady` = true (also `WorldService.Ready`) once WorldService.Init has built the hub, all plots, exhibit pads and tip jars (Scenery keeps filling in async; it is decorative only). Gameplay/client can `if not workspace:GetAttribute("WorldReady") then workspace:GetAttributeChangedSignal("WorldReady"):Wait() end`. `workspace.Lightning` (os.clock of each flash, for audio).

## What Graphics reads from Gameplay
- `workspace.ZooItems.Plot<n>.<id>` item Models. For each one, Graphics adds a child Model `Visual` aligned to the bottom of the `Hitbox`. Visual parts keep CanQuery on (CanCollide/CanTouch off), so a tap on the visible creature hits a Visual part and `Plots.ItemFromHit` walks up to the item Model (ItemId). FX parts (glows/rings) are CanQuery off. Grown creatures wander only ±1.2 studs from their cell.
  - `Kind`="plant": `CreatureModels.Build(Species, Stage, {Color, Weather, Thriving})`. Changes to Stage/Species rebuild it with a pop. Changes to Color/Weather/Thriving re-skin it in place. Grown creatures bob and wander ±2.5 studs inside the pad.
  - `Kind`="decor": `Decor.Build(DecorKind)`. The model is rebuilt if the Hitbox moves.
- `ReplicatedStorage.GameState`:
  - `Weather` attribute → sky and particles.
  - `NextRestockAt` → Seed Shop clock (falls back to `Config.Shop.RestockSeconds`).
  - `TopEarned` JSON → board.
  - `WorldReserve` JSON → reserve creatures: the newest 8 per biome, each with an owner name tag. A beam plays over a zone when a new entry appears.

## Lighting
- project.json: Technology Future, ClockTime 14, Brightness 3, ShadowSoftness 0.25, Ambient ≈ 140 grey, OutdoorAmbient ≈ 133 grey, EnvironmentDiffuseScale 1, EnvironmentSpecularScale 0.35. `Sky.Setup` sets the same values in code.
- Atmosphere Density 0.22, Offset 0.3, Color `#CDEBFF`, Decay `#FFE3C4`, Glare 0.25, Haze 1.2. ColorCorrection Saturation 0.25 / Contrast 0.1 / Brightness 0.03 / Tint `#FFF8EC`. Bloom 0.4/24/1.6. SunRays 0.06/0.55. No DepthOfField during gameplay.
- Neon is only used on small accents (jar knob, creature eye glints, kraken suckers, small decor sparks, primitive lanterns at night, release beam at 0.5 transparency).

## Day/night + weather
- Full day = 12 min (`Config.DayLengthSeconds` if added, default 720); the clock runs at 0.75x between 09:00 and 16:00 and 1.35x otherwise, so most of the cycle is bright day. Haze goes day `#CDEBFF` → sunset `#FF9E5E` → night `#5A6A9A`; Ambient/OutdoorAmbient lerp to `#5A6A9A`/`#4A5A8C` and Brightness 3 → 1.2 (blue, readable night). At night, lamps and fireflies turn on.
- Rain/Thunderstorm are cooler, not greyer (tint `#DCE8FF`, saturation -0.05).
- Weather names: `Rain`, `Heatwave`, `Snow Flurry`, `Bloom Season`, `Thunderstorm` (with lightning flashes), `Starfall`. Each sets a color-correction tint and atmosphere density, plus particle sheets over the hub and each plot.

## WorldService API (server)
```lua
WorldService.Ready / WaitReady()
GetPlot(i) -> Model?            GetPlotCFrame(i) -> CFrame      GetSpawnCFrame(i) -> CFrame
GetPad(plot, pad) -> BasePart?  GetPadTop(plot, pad) -> CFrame?  GetCellCFrame(plot, pad, cell, rotDeg?) -> CFrame?
SetPadUnlocked(plot, pad, unlocked, price?)   SetPadBiome(plot, pad, biome)   -- same as setting the attributes
SetTipJar(plot, pad, amount)    PlayCoinBurst(plot, pad, count?)
SetPlotOwner(plot, player?)     SetPlotLikes(plot, n)           SetVisitorCount(plot, n?)  -- nil = auto 2..6
SpawnCreatureModel(species, stage, look?, cframe, parent?) -> Model
SetLeaderboard(entries)         AddReserveCreature(species, color?, owner)   PlayReleaseBeam(position)
SetWeather(name?)               IsNight() -> boolean
```

## Theme API (shared)
- `Theme.Colors.*`, `Theme.Biomes[biome]` = {Ground, GroundMaterial, Fence, FenceMaterial, Accent, Accent2, Fence3}, `Theme.BiomeOrder`.
- `Theme.BiomeKey(name)` normalizes "Fungus" / "fungus_cave" to "Fungus Cave".
- `Theme.Rarity[r]`, `Theme.RarityOrder`, `Theme.RarityScale[r]`, `Theme.ColorMutations`, `Theme.WeatherMarks`, `Theme.Grid`.
- `Theme.CellOffset(cell, rot)`: `rot` may be in degrees or quarter turns.
- `Theme.Effects.Sparkle(color, rate?)`, `Aura(color)`, `RainbowAura()`, `Leaves()`, `CoinBurst()` (call `:Emit(n)`), `Puff(color)`, `Fireflies()`, `Weather(kind)`. Each returns an unparented ParticleEmitter.

## CreatureModels API (shared — usable on the client for ViewportFrames)
- `Build(species, stage?, {Color?, Weather?, Thriving?, Scale?}) -> Model`.
  - stage is "Seed"/"Sprout"/"Bud"/"Grown" or 1..4.
  - The model's PrimaryPart `Root` sits at the feet and the front faces -Z.
  - Attributes: Species, Stage, Rarity, Kind, Scale.
- `ApplyLook(model, {Color, Weather, Thriving})`. Pass false or "None" to clear a value.
  - Gold = Metal tint, Diamond = Glass tint, Rainbow = hue cycle (call `StepRainbow(model, hue)` on the client).
  - Weather marks: Dewy droplets, Sunkissed glow, Frosted tint, Electric sparks, Starlit twinkles.
  - Thriving = green ring (SmoothPlastic, 0.45 transparent) + sparkles + leaves.
  - Rarity ladder: Rare = blue sparkles (rate 2); Epic = purple sparkles (4) + ground ring; Legendary/Mythical = sparkles (6) + ring + aura + PointLight (range 8); Secret = rainbow aura + dark ring + light.
  - Mesh creatures (asset hook): untextured parts are tinted like primitives; **textured** parts (MeshPart.TextureID or SurfaceAppearance — Color is ignored) get a tinted translucent **shell** copy (×1.04 size, TextureID cleared) inside the FX folder: Gold = Metal 0.35, Diamond = Glass 0.45 + reflectance, Rainbow = cycled by StepRainbow, weather tints = 0.7. No Highlights (client limit of 31).
- `GetLook(species)`, `StageName(stage)`, `Stages`.
- Stages: Seed = dirt mound + seed. Sprout = 2 leaves. Bud = closed bulb in the species color. Grown = the creature (10 body kinds × 28 signature tops). Grown creatures scale up by rarity, from 1.0 to 1.65.

## Asset hooks (orchestrator fills these in Studio; they can't live in the repo)
Put a Folder `Assets` in **ReplicatedStorage** (it replicates, so client ViewportFrames get meshes too). Rojo keeps it: ReplicatedStorage has no `$path`, so unknown children are not deleted by `rojo serve`. Scripts inside assets are deleted on clone; Humanoids/AnimationControllers are removed from creatures.
```
ReplicatedStorage.Assets
  Creatures/<SpeciesName>        Model or MeshPart, name = Species.Name exactly (e.g. "Dandelion Lion"; case/space-insensitive match)
  Props/Tree1..TreeN             any child named Tree, Tree<digits>, Tree_<x> or "Tree <x>" is a variant of kind "Tree"
  Props/Bush*, Flower*, Rock*, Lamp*, Bench*, Cloud*, Fence*
  Props/SeedIcon, HopeIcon, UpgradeIcon, DailyIcon   (stall roof icons, optional)
  Sky                            a Sky instance (cartoon skybox), optional
```
**Fitting (all hooks, `Theme.Assets.Fit`)**: the asset's orientation = its pivot (Model: WorldPivot or PrimaryPart pivot; MeshPart: its CFrame). **Front must face -Z of that pivot**; if it doesn't, set a number attribute `YawOffset` (degrees) on the asset. Position/pivot location doesn't matter: the code measures the bounding box of all BaseParts in that frame, scales the whole thing uniformly (`Model:ScaleTo`) to the target height, and puts the **bottom-center of the bounding box** on the ground point. Optional attribute `HeightScale` multiplies the target height. Any size is fine in the source.

| Kind | Target height (studs) | Notes |
|---|---|---|
| Creature (Grown) | 3 × rarity scale (Common 3 → Secret ≈ 5), footprint clamped to 4 × scale | welded to Body; keeps Root (anchored, feet, front -Z)/Body/Bob contract; used in plots, World Reserve (×0.55) and UI viewports. Seed/Sprout/Bud stay primitive. Generated meshes: 2–4k tris. |
| Tree | 10 × scale (≈ 10–25) | random yaw; collidable |
| Bush | 3 × scale (≈ 2.4–4.5) | not collidable |
| Flower | 1.2–1.8 | no shadows; used ~1000×, keep it very low-poly |
| Rock | 1.5–4 | collidable |
| Lamp | 9 | name the glowing part `Lantern` (or `Light`), else the highest part gets the PointLight + `NightLight` tag |
| Bench | 3 | front = side you sit facing (-Z) |
| Cloud | 14–22 | no shadows |
| Fence | 2.5 | **long axis = X**; tiled along the plot curb (segment length = its X size after fitting) |
| *Icon | 4.5 | stall roof icons |

Missing kind → primitive fallback. Variants are chosen with a seeded Random, so the layout is stable per server.

## Part budget
Roughly 400 parts per plot at the start (curb, bush rows, flower strips, gate), ~350 for the hub, ~2k for scenery (flowers are 3 parts each): about 5k static parts, plus terrain. Swapping in Flower/Bush assets cuts this a lot. A creature is about 15–30 parts and a visitor about 9.
