# Graphics notes (Sprout Zoo)

Everything is built in code by `WorldService.Init()` (server). No assets, no unions, only built-in particle textures.
Anchored everywhere except creature/visitor parts, which are welded (unanchored, massless, no collision) to an anchored Root that is moved by tweens.

## Files (graphics-owned)
- `src/server/Services/WorldService.luau` — builds the world, binds gameplay attributes, public API.
- `src/server/World/`
  - `Build` (part helpers), `Plots` (6 plots), `Biomes` (pad kits + locked look), `Decor` (19 decor pieces), `Hub`, `Scenery`, `Sky` (lighting, day/night, weather FX)
  - `ItemVisuals` (renders `workspace.ZooItems`), `Motion` (creature bob/wander, growth pop, visitors), `Reserve` (World Reserve), `StateSync` (GameState → world)
- `src/shared/Theme/` (`init` = palette/biome kits/rarity/grid, `Effects` = particle presets). Shared.
- `src/shared/CreatureModels/` (`init`, `Looks`, `Kinds`, `Tops`, `Effects`). Shared, so UI can put models in ViewportFrames.

## Map layout (studs, ground top y = 0)
- Ground: Charlie's `Baseplate` if present (recolored to grass, at least 900x900), otherwise a new `Ground` part.
- **Hub** at the origin, a Ø120 path-colored disc. In the center: a fountain basin with a giant blossom tree and glowing fruit (the focal point).
  Stalls sit at radius ~40, facing the center:
  - 30°: Seed Shop (restock clock on the roof)
  - 90°: Hope Shop
  - 150°: Upgrades
  - 210°: Leaderboard board
  - 270°: World Reserve diorama: 6 biome zones plus the Release Altar in the middle
  - 330°: Daily Gifts stall + `HubSpawn` SpawnLocation (r = 30)
- **Spoke paths** (10 wide) from the hub to each plot's entrance, with 4 lamp posts each (lit at night).
- **Plots**: plot i sits at angle (i-1)·60°, radius 170. Each is 80x80, its pivot is the center of the floor top (y = 0.5), and its LookVector points at the hub (local -Z = entrance).
  - Pads are 20x20, with their top at y = 1.3. Pad p has row = (p-1)//3, col = (p-1)%3, offset ((col-1)·24, 0, (row-1)·24). Row 0 is nearest the hub.
  - Pad grid: 5x5 cells of 4 studs. Cell 1..25 is row-major, with row 1 on the entrance side (-Z) and col 1 at -X. This is the same math as `PlotService.CellCFrame` and `Theme.CellOffset`.
  - Paths: a ring at ±37 (6 wide) and lanes at ±12 (4 wide). The hedge border has an 18-stud entrance gap. An arch sign at the entrance shows "<Owner>'s Zoo ❤ N".
  - Tip jar: one per pad, on the path 12 studs in front of the pad center (-Z).
  - `PlotSpawn`: on the entrance path, facing into the plot.
- **Scenery**: flower patches, bushes and tree clusters between spokes and plots. Also an outer forest ring (r ≈ 285), hills (r = 340), clouds, and firefly volumes over the hub and each plot (night only).

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
| `NightLight` / `Fireflies` | lantern parts / firefly volumes | | toggled by the day/night cycle |

Other attributes: `Lighting.IsNight` (ClockTime ≥ 18 or < 6), `workspace.WorldReady` = true after Init, `workspace.Lightning` (os.clock of each flash, for audio).

## What Graphics reads from Gameplay
- `workspace.ZooItems.Plot<n>.<id>` item Models. For each one, Graphics adds a child Model `Visual` aligned to the bottom of the `Hitbox`. Visual parts have CanQuery off, so taps hit the Hitbox.
  - `Kind`="plant": `CreatureModels.Build(Species, Stage, {Color, Weather, Thriving})`. Changes to Stage/Species rebuild it with a pop. Changes to Color/Weather/Thriving re-skin it in place. Grown creatures bob and wander ±2.5 studs inside the pad.
  - `Kind`="decor": `Decor.Build(DecorKind)`. The model is rebuilt if the Hitbox moves.
- `ReplicatedStorage.GameState`:
  - `Weather` attribute → sky and particles.
  - `NextRestockAt` → Seed Shop clock (falls back to `Config.Shop.RestockSeconds`).
  - `TopEarned` JSON → board.
  - `WorldReserve` JSON → reserve creatures: the newest 8 per biome, each with an owner name tag. A beam plays over a zone when a new entry appears.

## Day/night + weather
- Full day = 12 min (`Config.DayLengthSeconds` if added, default 720). Sky palette goes from `#9EDCFF` to sunset `#FF9E5E` to night `#1E2A4A`. At night, lamps and fireflies turn on.
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
  - Thriving = neon green ring + sparkles + leaves.
  - Legendary+ get a rarity-colored aura. Mythical adds a light. Secret gets a rainbow aura + light.
- `GetLook(species)`, `StageName(stage)`, `Stages`.
- Stages: Seed = dirt mound + seed. Sprout = 2 leaves. Bud = closed bulb in the species color. Grown = the creature (10 body kinds × 28 signature tops). Grown creatures scale up by rarity, from 1.0 to 1.65.

## Part budget
About 230 parts per plot at the start, about 150 for the hub, and about 550 for the scenery: roughly 2.1k static parts in total. A creature is about 15–30 parts and a visitor about 9.
