# Graphics notes (Wildworld)

Everything is built in code by `World.Init()` (`src/server/World/init.luau`, a plain module required once by Main, not a Service) and works straight from `rojo build`. No free models; creatures are code-built.

**Art style: classic Roblox studs** (`research/STUDS_STYLE_GUIDE.md`, target `inspiration/studs-inspo-1.png`). Studs come from legacy `SurfaceType.Studs` on `Plastic` blocks (no textures/asset IDs). World blocks = studs on top + Inlet below; creatures, trees and props = studs on all 5 faces. Face tiles, signs, water surfaces, lamp glass and clouds are SmoothPlastic. Balls/cylinders only on round props (toy ball, discovery ring, VFX).

## Files (Graphics-owned)
- `src/server/World/init.luau` (ModuleScript `ServerScriptService.Server.World`): builds the world and holds the public API (below). `Services/WorldService.luau` is deleted.
- `src/server/World/`: `Layout` (all coordinates), `Terrain`, `Sky` (lighting, 14-min day cycle, clouds; weather cut), `Hub`, `Plots`, `Forest` (Greenleaf Meadow builder), `Waterfall`, `Scatter` (foliage clusters), `ItemModels` (gameplay hook).
- `src/shared/Theme/`: `init` (palette, lighting values, zone looks, grid math), `Palette`, `Kit` (part helpers), `Effects` (particles), `Moments` (big-moment VFX), `Nature`, `Structures`, `Decor`, `Props` (build-item visuals), `IconModels` (UI icon brick models).
- `src/shared/CreatureBlueprints/`: `Shapes` (blueprint format), the 5 species, and `init` (`Species`, `Get`, `Build(species, look)` hook).
- `src/shared/CreatureBuilder/`: `init` (Build / FromLook / BuildEgg / ScaleFor, clone cache) and `Mutations` (Golden/Albino/Crystal/Glowing layers, bow, egg).
- `default.project.json` → Lighting `$properties` (STUDS_STYLE_GUIDE §7: ShadowMap, ClockTime 14.5, Brightness 3, Ambient 0.55/0.55/0.58, OutdoorAmbient 0.6/0.6/0.62, EnvDiffuse 0.5, EnvSpecular 0.2, ShadowSoftness 0.2).

## Map layout (studs, ground top y = 0, north = -Z)
- **No Smooth Terrain** (`Terrain:Clear()`). Ground = 48 studded Plastic plates 256x4x256 (x -768..768, z -1024..768) in a `GrassTop`/`GrassAlt` checker, with a hole cut for the lake basin. Every walkable ground part (plates, hills, ridges, cliff, lake basin) lives in `Workspace.World.Ground`; `Scatter.GroundY` raycasts against that folder. Paths/roads are 0.4 plates on top (top y = 0.4) with 1-stud `PathEdge` borders. `Workspace.SafetyFloor` at y ≈ -15: touching it teleports the character to HubSpawn (1 s debounce). Invisible walls in `World/Bounds` (400 tall): park box x/z ±420, meadow corridor x ±225 down to z -800 (the meadow's back edge, inside the cliff). Any Baseplate is destroyed.
- **Backdrop**: terraced brick ridges (4–6 levels, 4.8–9.6 tall each, 9 studs in per side, Stone/Dirt base on every other segment) ringing the park (x/z ≈ ±470..600) flanking the meadow (x ±250..380, z -600..-1000) plus a skyline ridge behind the cliff (z -890..-1000). Trees on every other ridge top.
- **Hub** at the origin (r 80): pixel-circle plaza of studded `Plaza` strips (top 0.4), `Path` inner ring (r 32, top 0.8), **Heart Tree** (giant pink/purple brick magic tree on a grass island in a square brick fountain with 6 spout cubes; the focal point), 8 lanterns, 4 benches, 4 red flower planters. Landmarks face the centre: Field Shop stall (east, r 64, striped wedge awning), Top Parks board (225°), Daily Chest (west), forest signpost (north edge). `HubSpawn` = visible blue studded SpawnLocation at (0, 0.6, 42).
- **Plots**: 8 plots (128x128) at r 270, angle `-67.5° + 45°·(i-1)`, so the north gap between plots 8 and 1 is the meadow road. Base = smooth pale `#9DB98A` (locked land), `Land` = studded 0.4 plate on top (top 0.52; `#5CB83C` owned / `#9DB98A` free, always Plastic). Studded wood border bricks, gate with leaf-cube posts. Spokes (12-wide path plates, lanterns, flower lines) run from the plaza to each gate. Brick tree clusters sit on the lawns between the spokes.
- **Greenleaf Meadow** (the only v1 wild zone, Id `Meadow`, z -370..-800, x ±210; road x = 0 from the plaza to z -612): ForestGate arch "Greenleaf Meadow" at z -370.
  - 8 terraced brick hills (3–6 levels), 18 tree clusters (round oaks; pink/purple magic trees near the lake), ~44 flower patches + flower borders along the road, 24 sprinkled rocks/bushes/logs, 10 glow mushrooms round the lake shore, one night `Fireflies` volume over the whole meadow.
  - Back edge (focal point, dead ahead up the road): sunken square lake basin at (40, -680) r 46 (blue floor, stone rim, translucent water, sand plates), stepped brick cliff (Stone / Dirt / studded grass cap) with its face at z ≈ -785, the brick waterfall at (40, top y 56, z -784) (7 stepped translucent bricks + streaks + emitters + brick rainbow), a raised stream channel into the lake.
  - Tree walls along x ±215. Mossy Hollow, Waterfall Glade, their gates/veils, mist and discovery spots are deleted (update 2).
- Foliage: brick oak (trunk + 3 square canopies), pine (7/5/3/1 squares), magic tree (pink/purple + 2 Neon bud cubes), bush, flower (stem + 1x1 plate), rock (offset Stone/StoneDark bricks), log. Clusters are 2–4 pieces (~30% sparser than before), yaw in 90° steps.

## Tags and attributes
| Tag | On | Attributes |
|---|---|---|
| `Plot` | each plot's **Base** part (top = plot ground, LookVector → hub) | `PlotIndex`, `OwnerId` (0 = free), `OwnerName`, `LandSize` (64..128). Gameplay writes these; Plots.luau listens and updates the sign, floor colour and Land square. The model `Plot<i>` also has `PlotIndex`. |
| `PlotSpawn` | invisible part inside each gate, facing in | `PlotIndex` |
| `HubSpawn` | SpawnLocation | – |
| `WorldZone` + `ZoneArea` | invisible Meadow zone volume (420 x 120 x 430) | `Zone` = `Meadow`, `ZoneKey` = `MeadowEdge`, `DisplayName`, `Biome`, `ZoneIndex` |
| `AudioZone` | the Meadow volume (same part as `WorldZone`) + hub + each plot | `Zone` = `Meadow`/`Hub`/`Park` (+`PlotIndex`) |
| `ZoneGate` | one invisible `GateAnchor` part in the ForestGate (Meadow, Level 1, Cost 0 = always open; no other gates) | `Zone` (Id), `ZoneKey`, `ZoneIndex`, `RequiredLevel`, `Cost` (read from Config.Zones by Id). |
| `ForestGate` | park → forest arch model | `Zone` = `Meadow` |
| `WildSpawn` | invisible 2x1x2 part at ground (24, all `Meadow`; never on the road, in the lake or at the cliff foot) | `Zone` (Id), `ZoneKey`, `ZoneIndex` |
| `TopParksBoard` | hub board; SurfaceGui `BoardGui` with `Title`, `Row1..Row5` | use `World.SetTopParks` |
| `DailyChest` / `ShopStall` | hub models, each with a `ProximityPrompt` named `Prompt` (gameplay connects Triggered) | ShopStall: `Shop = "Main"` |
| `HeartTree`, `Waterfall` | landmarks | – |
| `WaterfallSound` | waterfall base part (Audio's 3D loop) | – |
| `NightLight` | parts whose child Light is on only at night (lanterns, lake-shore glow mushrooms, Lumibun ears) | `GlowAtNight` → Neon at night |
| `Lantern` | lantern lamp parts (Animation flicker) | – |
| `Fireflies` | emitter holders enabled at night | – |

Lighting and Workspace attribute `IsNight` (bool). Workspace attribute `WorldReady` = true once built.

## World API (server) — `local World = require(ServerScriptService.Server.World)`
`WaitReady()`, `GetPlot(i)`, `GetPlots()`, `PlotCFrame(i)` (floor-top centre, -Z → hub), `PlotSpawn(i)`, `SetPlotOwner(i, player?)`, `SetPlotLand(i, studs)`, `CellToWorld(i, cellX, cellZ, footX, footZ, rot?)`, `SpawnItem(i, itemId, cellX, cellZ, rot?, seed?)`, `HubSpawn()`, `ZoneAt(pos)` → `"Hub"|"Park"(, plotIndex)|zone Id|"Wild"`, `WildSpawns(zoneId)`, `ZoneGate(zoneId)`, `SetTopParks({{name, rating}})`, `IsNight()`, `Moments` (= Theme.Moments), `Layout`. Plus `Init()` (build; idempotent, yields until built) and `Start()` (day cycle; idempotent).
**Changes from WorldService:** module moved to `World/init`; `SetWeather` removed (weather cut); `ZoneAt` only returns `Meadow` as a zone; `ZoneGate("Hollow"/"Glade")` and `WildSpawns("Hollow"/"Glade")` return nil/empty.
**Callers must update:** Main must `require(script.Parent.World)`, call `.Init()` before the Services' `Init` and `.Start()` with them (Main only auto-loads `Services/`). VisitService's Top Parks lookup (`script.Parent:FindFirstChild("WorldService")`) must become `require(script.Parent.Parent.World)`.

## Theme API (shared)
- `Theme.Colors` (palette, STUDS_STYLE_GUIDE §3: `GrassTop/GrassAlt/GrassSide/Dirt/Path/PathEdge/Plaza/Stone/StoneDark/Wood/WoodDark/Leaf1-3/Water/WaterDeep/Sand/White/Red/Blue/Yellow/Pink/Eye/Sky`; old token names kept and re-pointed), `Theme.Rarity`, `Theme.Mutation` (unchanged), `Theme.Lighting` (Day/Night/Atmosphere/ColorCorrection/Bloom/SunRays + `ClockTime`, `Env`), `Theme.Zones[key]` (atmosphere per zone for client tweens: Density/Color/Decay/Haze/Glare/Music; densities ×0.7 for the brick look).
- `Theme.Kit`: `Brick(parent, size, cf, color, studs: "Top"|"All"|"None"?, collide?)`, `Studs(part, mode)`, `Snap(size)` (whole-stud X/Z, 0.4-plate Y), `Shade(color, k?)` (×0.95 seam shade), `Tile` (SmoothPlastic), `Mat(material)` (maps textured materials to Plastic; Metal → Reflectance 0.2). `Part/Solid/Block` default to studded Plastic; `Ball/Blob/Cyl` are SmoothPlastic round props.
- `Theme.Grid.CellToLocal(cx, cz, footX, footZ, rot)` and `Theme.Grid.IsUnlocked(cx, cz, landStuds)` (cells 1..32, 4 studs each).
- `Theme.Props.Build(itemId, seed?, footX?, footZ?)` gives a Model with pivot at the footprint centre on the ground, PrimaryPart `Root`, and attributes ItemId/Category/FootX/FootZ/BiomeTags/role flag. `Theme.Props.Ghost(itemId, valid)` gives a build-mode preview. IDs match `shared/Items.luau` (32 items; FieldTent/JournalSign/StoneTotem cut); every item is built from studded bricks. `World/ItemModels.Build(itemId, def)` wraps this for `Models.luau`.
- `Theme.IconModels.Build(name): Model?` for UI ViewportFrames (front -Z, PrimaryPart `Root` = invisible bounding box, no particles/lights; attr `IconName`). Names: `Coin`, `RP`, `Berry`, `Honey`, `Starfruit`, `VIP`, `ExtraIncubator`, `AutoFeeder`, `CrystalGrotto`, `CoinsSmall/Medium/Large`, `StarterPack`, `InstantHatch`, `Egg`, `EggCommon/Uncommon/Rare/Epic`, `EggGolden`. Aliases: `Coins`, `Bait<Fruit>`, `Pass<Key>`, `InstantHatch1..3`. `IconModels.Has(name)`, `IconModels.Names`.
- `Theme.Colors.EggRarity` = Common white `#F4F5F7`, Uncommon/Rare/Epic = `Theme.Rarity` green/blue/purple (Legendary eggs use Epic).
- `Theme.Effects`: Sparkle, Embers, Hearts, CoinBurst, Confetti, Puff, Discovery, Fireflies, Mist, Splash, WaterMist, Fall. (`Weather` removed.) `Theme.Zones` keeps Park/Hub/MeadowEdge (DisplayName "Greenleaf Meadow").
- `Theme.Moments`: `Hatch(pos, shellColor, flashColor?)`, `CaptureBubble(pos, size)` → `{Success(), Fail()}`, `DiscoveryBeam(pos, color)`, `RatingUp(center, padSize)`, `Coins(pos, n)`, `Hearts(pos)`.
- Night: parts with `GlowAtNight` switch to Neon at night and back to their own day material (saved in attribute `DayMaterial`).

## Creatures (brick figures, STUDS_STYLE_GUIDE §4)
- `CreatureBuilder.Build(species, {genes="Cc|Pp|Ss|Gg", mutations, stage, seed, scale?, hue?, bow?})`, `CreatureBuilder.FromLook(species, look)` (gameplay look table), `CreatureBlueprints.Build(species, look)` (same, used by Models.luau), `CreatureBuilder.BuildEgg(species, {mutations, seed})`. API unchanged.
- The model's PrimaryPart is an invisible `Hitbox` (CanQuery). The model pivot is the ground point under the creature, facing -Z. All parts are anchored, non-colliding and massless.
- Part attributes: `Role` (Primary/Secondary/Belly/Accent/Feature/Glow/Eye/EyeShine/Cheek/Nose/Crystal/Accessory), `Anim` (Body/Head/EarL/EarR/Tail/LegFL/FR/BL/BR), `Rest` (CFrame relative to Hitbox). New role `Nose` (dark nose tile; not an eye, so it doesn't blink or turn red on Albino).
- Model attributes: Species, Genes, Mutations, Stage, Scale, HeadPivot (rel. Hitbox), Pulse (Glowing).
- Build: every body part is a studded Plastic brick (studs on 5 faces, inlet below) on the stud grid; bodies/heads are stacked slabs with ×0.95 shade + 0.1 inset on alternate layers for seams. Wedges = smooth slope bricks. Shared face on every species (`Shapes.BrickFace`): square black eyes with a white highlight square (role `EyeShine`), pink cheek tiles, muzzle brick (Belly colour) + nose tile; face tiles are SmoothPlastic. Blueprint helpers: `Shapes.Brick/Wedge/Tile/Slab/BrickFace/Shard`.
- Species (adult, studs): Lumibun = white bunny, 3x3 head, ears to y ≈ 9 with Glow tips (night light), 23 parts. Emberfox = orange fox, 3x3 head, white chest/muzzle, dark socks + ear tips, stepped tail with white tip + Glow ember cube (embers), 30. Mossback = low tortoise, 4x5 body, ziggurat moss hump + flower studs, 25. Pebblehorn = grey-blue elephant, 4-class head, ear flaps with pink inner tiles, nose horn stack, teal back plates, 29. Thornstag = deer on 3.2 legs, 3x3 head on a neck, brick antlers with leaf buds, ~14 tall, 33.
- Genes: `cc` uses the alt palette, `pp` adds spot tiles/stripes, `ss`/`Ss` gives ×0.85/×0.95 size, `gg` makes Glow parts Neon. Baby stage = ×0.6 (matches `Config.Growth.BabyScale`) with the head ×1.25. Hue jitter ±1% (`HUE_JITTER` 0.02), size jitter ±3% by seed.
- Mutations (body stays Plastic so studs stay): Golden = gold palette + Reflectance 0.2 + gold crown plate + sparkle (Rate 4). Albino = pale palette + red square eyes + stronger cheeks (wins over Golden). Crystal = body lerp 35% to `#9FE8FF` + trans-clear crystal brick stacks (Plastic, T 0.3, Reflectance 0.15) at the blueprint mounts + light (range 8). Glowing = Accent/Glow parts Neon (`#7CFFB2` if the species glow is dark) + pulsing light (range 10). Golden+Crystal = gilded `#FFE9A8` crystals. Each creature has at most 1 emitter and 1 light.
- Eggs: stacked studded brick egg (5 layers, 3.2 tall, widest 2.4, biggest layer named `Shell`) + 3 spot tiles; Golden = gold + Reflectance + sparkle. Hitbox 2.6x3.4x2.6. Shell tinted by **rarity** (`Palette.EggRarity`: white/green/blue/purple), not species: tier = species rarity, raised to Epic by any non-Golden mutation; `BuildEgg(species, {rarity = "Rare"})` overrides. `Mutations.EggRarity(species, mutations, override?)` gives the tier; egg model attribute `Rarity` (or `Golden`).
