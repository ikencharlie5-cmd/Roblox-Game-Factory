# Graphics notes (Wildworld)

Everything is built in code by `WorldService.Init()` and works straight from `rojo build`. No free models; creatures are code-built.

## Files (Graphics-owned)
- `src/server/Services/WorldService.luau`: builds the world and holds the public API (below).
- `src/server/World/`: `Layout` (all coordinates), `Terrain`, `Sky` (lighting, 14-min day cycle, weather, clouds), `Hub`, `Plots`, `Forest`, `Waterfall`, `Scatter` (foliage clusters), `ItemModels` (gameplay hook).
- `src/shared/Theme/`: `init` (palette, lighting values, zone looks, grid math), `Palette`, `Kit` (part helpers), `Effects` (particles), `Moments` (big-moment VFX), `Nature`, `Structures`, `Decor`, `Props` (build-item visuals).
- `src/shared/CreatureBlueprints/`: `Shapes` (blueprint format), the 5 species, and `init` (`Species`, `Get`, `Build(species, look)` hook).
- `src/shared/CreatureBuilder/`: `init` (Build / FromLook / BuildEgg / ScaleFor, clone cache) and `Mutations` (Golden/Albino/Crystal/Glowing layers, bow, egg).
- `default.project.json` → Lighting `$properties` (ShadowMap etc. per ART_STYLE_GUIDE §1).

## Map layout (studs, ground top y = 0, north = -Z)
- Terrain 1280 x 1920 (x -640..640, z -1280..640). Grass `#6CC644` with Decoration, LeafyGrass under the deep forest, Ground roads, backdrop hills ring (r ≈ 440+) and forest flanks (x ≈ ±280). `Workspace.SafetyFloor` at y ≈ -15. Any Baseplate is destroyed.
- **Hub** at the origin (r 80): paved plaza, cobble inner ring, **Heart Tree** (giant pink/purple magic tree in a fountain basin; the focal point), 8 lanterns, 4 benches, 4 flower beds. Landmarks face the centre: Field Shop stall (east, r 64), Top Parks board (225°), Daily Chest (west), forest signpost (north edge). `HubSpawn` SpawnLocation at (0, 0.6, 42).
- **Plots**: 8 plots (128x128) at r 270, angle `-67.5° + 45°·(i-1)`, so the north gap between plots 8 and 1 is the forest road. Spokes (Ground road, 12 wide, with lanterns and flower lines) run from the plaza to each gate. Tree clusters sit on the lawns between the spokes.
- **Greenleaf Forest** (road x = 0): ForestGate arch at z -370.
  - Meadow Edge (z -370..-640): open hills, flowers, light tree clusters.
  - Mossy Hollow (-640..-900): dense mixed trees, mossy rocks, glow mushrooms, mist, night fireflies.
  - Waterfall Glade (-900..-1160): magic trees, a lake at (40, -1040) r 46, a rock cliff at z ≈ -1145, the waterfall at x 40 (part sheets + emitters + rainbow), and 4 discovery spots.
  - Tree walls run along x ±215 and across each zone boundary.

## Tags and attributes
| Tag | On | Attributes |
|---|---|---|
| `Plot` | each plot's **Base** part (top = plot ground, LookVector → hub) | `PlotIndex`, `OwnerId` (0 = free), `OwnerName`, `LandSize` (64..128). Gameplay writes these; Plots.luau listens and updates the sign, floor colour and Land square. The model `Plot<i>` also has `PlotIndex`. |
| `PlotSpawn` | invisible part inside each gate, facing in | `PlotIndex` |
| `HubSpawn` | SpawnLocation | – |
| `WorldZone` + `ZoneArea` | invisible zone volume (400 x 120 x depth) | `Zone` = gameplay Id (`Meadow`/`Hollow`/`Glade`), `ZoneKey` (`MeadowEdge`…), `DisplayName`, `Biome`, `ZoneIndex` |
| `AudioZone` | twin volumes for the forest zones + hub + each plot | `Zone` = `MeadowEdge`/`MossyHollow`/`WaterfallGlade`/`Hub`/`Park` (+`PlotIndex`) |
| `ZoneGate` | invisible `GateAnchor` part at the ground on each gate line (Meadow at the ForestGate, Hollow at z -640, Glade at z -900) | `Zone` (Id), `ZoneKey`, `ZoneIndex`, `RequiredLevel`, `Cost` (read from Config.Zones by Id). The arch also has a walk-through ForceField "Barrier" veil (visual only). |
| `ForestGate` | park → forest arch model | `Zone` = `Meadow` |
| `WildSpawn` | invisible 2x1x2 part at ground (16 Meadow, 16 Hollow, 14 Glade; never on the road or in the lake) | `Zone` (Id), `ZoneKey`, `ZoneIndex` |
| `DiscoverySpot` | Glade ring model (PrimaryPart = Ring) | `SpotId`, `Zone` = `Glade` |
| `TopParksBoard` | hub board; SurfaceGui `BoardGui` with `Title`, `Row1..Row5` | use `WorldService.SetTopParks` |
| `DailyChest` / `ShopStall` | hub models, each with a `ProximityPrompt` named `Prompt` (gameplay connects Triggered) | ShopStall: `Shop = "Main"` |
| `HeartTree`, `Waterfall` | landmarks | – |
| `WaterfallSound` | waterfall base part (Audio's 3D loop) | – |
| `NightLight` | parts whose child Light is on only at night (lanterns, glow mushrooms, Lumibun ears) | `GlowAtNight` → Neon at night |
| `Lantern` | lantern lamp parts (Animation flicker) | – |
| `Fireflies` | emitter holders enabled at night | – |

Lighting and Workspace attribute `IsNight` (bool). Workspace attribute `Weather` mirrors the gameplay weather. Workspace attribute `WorldReady` = true once built.

## WorldService API (server)
`WaitReady()`, `GetPlot(i)`, `GetPlots()`, `PlotCFrame(i)` (floor-top centre, -Z → hub), `PlotSpawn(i)`, `SetPlotOwner(i, player?)`, `SetPlotLand(i, studs)`, `CellToWorld(i, cellX, cellZ, footX, footZ, rot?)`, `SpawnItem(i, itemId, cellX, cellZ, rot?, seed?)`, `HubSpawn()`, `ZoneAt(pos)` → `"Hub"|"Park"(, plotIndex)|zone Id|"Wild"`, `WildSpawns(zoneId)`, `ZoneGate(zoneId)`, `SetTopParks({{name, rating}})`, `SetWeather(name)`, `IsNight()`, `Moments` (= Theme.Moments).
Weather is automatic: WorldService follows `ReplicatedStorage.GameState` attribute `Weather` (`Clear`/`Sunny`/`Rain`/`Rainbow Shower`).

## Theme API (shared)
- `Theme.Colors` (palette), `Theme.Rarity`, `Theme.Mutation`, `Theme.Lighting`, `Theme.Zones[key]` (atmosphere per zone for client tweens: Density/Color/Decay/Haze/Glare/Music).
- `Theme.Grid.CellToLocal(cx, cz, footX, footZ, rot)` and `Theme.Grid.IsUnlocked(cx, cz, landStuds)` (cells 1..32, 4 studs each).
- `Theme.Props.Build(itemId, seed?, footX?, footZ?)` gives a Model with pivot at the footprint centre on the ground, PrimaryPart `Root`, and attributes ItemId/Category/FootX/FootZ/BiomeTags/role flag. `Theme.Props.Ghost(itemId, valid)` gives a build-mode preview. IDs match `shared/Items.luau` (all 35). `World/ItemModels.Build(itemId, def)` wraps this for `Models.luau`.
- `Theme.Effects`: Sparkle, Embers, Hearts, CoinBurst, Confetti, Puff, Discovery, Fireflies, Mist, Splash, WaterMist, Fall, Weather("Rain"|"RainbowShower").
- `Theme.Moments`: `Hatch(pos, shellColor, flashColor?)`, `CaptureBubble(pos, size)` → `{Success(), Fail()}`, `DiscoveryBeam(pos, color)`, `RatingUp(center, padSize)`, `Coins(pos, n)`, `Hearts(pos)`.

## Creatures
- `CreatureBuilder.Build(species, {genes="Cc|Pp|Ss|Gg", mutations, stage, seed, scale?, hue?, bow?})`, `CreatureBuilder.FromLook(species, look)` (gameplay look table), `CreatureBlueprints.Build(species, look)` (same, used by Models.luau), `CreatureBuilder.BuildEgg(species, {mutations, seed})`.
- The model's PrimaryPart is an invisible `Hitbox` (CanQuery). The model pivot is the ground point under the creature, facing -Z. All parts are anchored, non-colliding and massless.
- Part attributes: `Role` (Primary/Secondary/Belly/Accent/Feature/Glow/Eye/EyeShine/Cheek/Crystal/Accessory), `Anim` (Body/Head/EarL/EarR/Tail/LegFL/FR/BL/BR), `Rest` (CFrame relative to Hitbox).
- Model attributes: Species, Genes, Mutations, Stage, Scale, HeadPivot (rel. Hitbox), Pulse (Glowing).
- Hero features: Lumibun has long ears with glow tips (night light), Mossback a moss hump with flowers, Emberfox a flame bead tail with embers, Pebblehorn a stacked nose horn and back plates, Thornstag branch antlers with leaf buds. Part counts are 15–25 (pattern spots only with `pp`).
- Genes: `cc` uses the alt palette, `pp` adds spots/stripes, `ss`/`Ss` gives ×0.85/×0.95 size, `gg` makes Glow parts Neon. Baby stage = ×0.5 with the head ×1.25. There is a ±3% hue and size jitter by seed.
- Mutations: Golden = Metal gold + sparkle. Albino = pale + red eyes (it wins over Golden). Crystal = Glass shards + light. Glowing = Neon accents + pulsing light. Golden+Crystal gives gilded shards. Each creature has at most 1 emitter and 1 light.
