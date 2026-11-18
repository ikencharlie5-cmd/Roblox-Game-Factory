# Wildworld — Assets

**Method (DECISIONS.md, 2026-11-18):** every creature and prop is a studded brick model built in code
from Plastic parts (STUDS_STYLE_GUIDE). These are the "real models". Studio AI mesh (original,
stud-textured, SPEC prompt prefix) is the fallback only for an asset that grades below B+ in the Look test.
No Creator Store or mesh IDs are used, so there is no AssetLoaderService. Machine map: `assets.json`.

Paths are relative to `src/`. "Scale" = the scale argument / size the builder uses.

## Creatures (`shared/CreatureBlueprints/<Species>.luau`, assembled by `shared/CreatureBuilder`)
| Asset | Builder | Used in | Scale | Source |
|---|---|---|---|---|
| Lumibun | CreatureBlueprints.Lumibun | plots, wild meadow, icons | Adult 1.0, Baby 0.6 (`CreatureBuilder.ScaleFor`) | code |
| Mossback | CreatureBlueprints.Mossback | same | same | code |
| Emberfox | CreatureBlueprints.Emberfox | same | same | code |
| Pebblehorn | CreatureBlueprints.Pebblehorn | same | same | code |
| Thornstag | CreatureBlueprints.Thornstag | same | same | code |

Genes/mutations recolour parts by Role (`CreatureBuilder/Mutations.Apply`).

## Eggs and mutation pieces
| Asset | Builder | Used in | Source |
|---|---|---|---|
| Egg (x4 rarity tints) | CreatureBuilder.BuildEgg -> Mutations.Egg; shell = `Palette.EggRarity[tier]` white/green/blue/purple (tier = species rarity, Epic for any non-Golden mutation, `opts.rarity` override); model attr `Rarity` | incubators, nests | code |
| Golden Egg | BuildEgg with `Golden` (gold + Reflectance 0.2 + sparkle) | first-egg reward | code |
| Egg shell halves | Theme.Moments.Hatch | hatch VFX | code |
| Crystal brick shard | Mutations.Apply (Crystal: `Shard*` parts) | Crystal mutation | code |
| Gold crown plate | Mutations.Apply (Golden: `Crown` 1x0.4x1) | Golden mutation | code |

## Build props (32; FieldTent / JournalSign / StoneTotem removed) — `shared/Theme/Props.luau` (`Props.Build(itemId)`), also used by `server/World/ItemModels`
| Asset | Item Id | Underlying builder | Scale |
|---|---|---|---|
| Habitat Pad S/M/L | PadSmall / PadMedium / PadLarge | Structures.Pad | 24 / 36 / 48 studs |
| Wood Fence | Fence | Structures.FenceRun | len 4 |
| Stone Path | Path | Structures.Path | 1x1 cell |
| Park Bench | Bench | Structures.Bench | 2x1 |
| Snack Stand | SnackStand | Structures.SnackStand | 2x2 |
| Firefly Lantern | Lantern | Structures.Lantern | 1x1 |
| Round Oak | TreeOak | Nature.Tree | 0.85 |
| Tall Pine | TreePine | Nature.Pine | 0.9 |
| Blossom Tree | TreeMagic | Nature.MagicTree (glow buds) | 0.75 |
| Berry Bush | Bush | Nature.Bush (berries) | 0.8 |
| Flower Patch | Flowers | Nature.FlowerPatch | 0.9 |
| Mossy Rock | Rock | Nature.Rock (mossy) | 0.7 |
| Boulder Den | BigRock | Decor.BigRock | 2x2 |
| Hollow Log | Log | Nature.Log | 1.0 |
| Cozy Burrow | Burrow | Decor.SmallBurrow | 1x1 |
| Sand Patch | SandPatch | Structures.SandPatch | 2x2 |
| Sun Stone | Sunspot | Decor.Sunspot | 1x1 |
| Lily Pond | Pond | Nature.Pond | 0.9 |
| Little Waterfall | Waterfall | Structures.Waterfall | 2x2 |
| Food Bowl | FoodBowl | Structures.FoodBowl | 1x1 |
| Water Trough | WaterTrough | Structures.WaterTrough | 2x1 |
| Shelter Hut | ShelterHut | Structures.ShelterHut | 2x2 |
| Toy Ball | ToyBall | Structures.ToyBall (code; Creator Store not needed) | 1x1 |
| VIP Golden Fountain | VipFountain | Decor.VipFountain | 2x2 |
| Crystal Cluster | CrystalCluster | Decor.CrystalCluster | 1x1 |
| Grotto Arch | GrottoArch | Decor.GrottoArch | 3x1 |
| Glow Shroom | GlowShroom | Decor.GlowShroom | 1x1 |
| Explorer's Arch | StarterArch | Decor.StarterArch | 3x1 |
| Moss Statue | MossStatue | Decor.MossStatue | 1x1 |
| Rainbow Flowers | RainbowFlowers | Decor.RainbowFlowers | 1x1 |

## Hub and world (`server/World/*`)
| Asset | Builder |
|---|---|
| Wild set dressing: hills / boulders / clouds / meadow flowers | Terrain.Hill / Nature.Rock + Scatter.Sprinkle / Nature.Cloud + Sky.Clouds / Nature.FlowerPatch + Scatter.FlowerLine |
| Hub plaza | Hub.Build (`disc` plaza + inner ring + `heartTree`) |
| Shop stall | Hub.shopStall |
| Top Parks board | Hub.topParksBoard |
| Daily chest | Hub.dailyChest |
| Plot border + name sign | Plots.border + Plots.sign |
| Meadow gate arch | Forest.arch |
| Lake + waterfall | Terrain.Lake + Waterfall.Build |
| Visitor NPC | client/Animation/Visitors.newVisitor |

## Icons (ViewportFrame renders, 3/4 view, FOV 30, blue sunburst)
Done: 5 species + Journal silhouette via `Kit.CreatureView` (`client/UI/Kit/View.luau`).
Icon models: `shared/Theme/IconModels.luau` (`Theme.IconModels.Build(name): Model?`, front = -Z, PrimaryPart
`Root` = invisible bounding box, pivot = box centre, no particles/lights). Names:
| Icon | Name (aliases) | Model |
|---|---|---|
| Coins | `Coin` (`Coins`) | upright gold octagon coin brick, dark inset, highlight tile |
| RP | `RP` | blue gem: inverted brick pyramid at 45°, Neon top plate |
| Bait | `Berry` / `Honey` / `Starfruit` (`Bait<Fruit>`) | 3 red berry bricks + leaf; amber honey pot + lid + drip; yellow 5-arm star |
| Game Passes | `VIP` / `ExtraIncubator` / `AutoFeeder` / `CrystalGrotto` (`Pass<Key>`) | gold crown; egg in brick nest + green plus; FoodBowl + stone gear; CrystalCluster |
| Coin packs | `CoinsSmall` / `CoinsMedium` / `CoinsLarge` | 3 / 6 / 10 gold coin bricks (stacks) |
| Starter Pack | `StarterPack` | red gift box, yellow ribbon + bow |
| Instant Hatch | `InstantHatch` (`InstantHatch1..3`) | cracked egg + Neon lightning bolt |
| Eggs | `Egg`, `EggCommon/Uncommon/Rare/Epic`, `EggGolden` | rarity-tinted brick egg |
Names match `Config.GamePasses` / `Config.DevProducts` keys. UI still needs `Kit.ModelView(parent, model)` (reuse
CreatureView's clone/camera fit) and to route `Kit.Icon` names through `IconModels.Has/Build` before the letter
fallback; build-tray items use `Props.Build(itemId)`.

## Flags (no builder yet, or mismatch with SPEC)
1. ~~Icon models missing~~ Fixed: `Theme/IconModels.luau`. Remaining (UI branch): `Kit.ModelView` + wire `Kit.Icon` to it
   so letter badges (`Style.IconFallback`) are no longer used for these icons.
2. ~~Egg rarity tints~~ Fixed: eggs tinted by rarity, not species.
3. ~~Gate arch text~~ Fixed: ForestGate arch reads "Greenleaf Meadow".
4. **Visitor NPC:** built from SmoothPlastic parts with a ball head, not studded classic R6 bricks (Animation branch).
5. ~~Cut items still present~~ Fixed: FieldTent, JournalSign, StoneTotem removed from `Theme/Props.luau` and `Theme/Decor.luau`.

## Charlie TODO: assets
None required. Mesh fallback only if an asset grades below B+ in the Look test: use the SPEC prompt prefix + that
asset's prompt in Studio AI mesh generation.
