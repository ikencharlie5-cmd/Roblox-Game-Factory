# Gameplay notes (Sprout Zoo)

Server is authoritative. All numbers in `src/shared/Config.luau` (species in `Species.luau` = `Config.Species`).
Shared pure math UI can use: `Shared/Formulas.luau` (Luck, Progress, Stage, ReadyAt, SellValue, SlotCount,
ReleaseCash, UpgradeCost, OfflineCapSeconds), `Shared/Needs.luau` (needs per pad, for build-mode previews).
Biome names: `Meadow`, `Pond`, `Desert`, `Canopy`, `Fungus Cave`, `Frost Garden`.

## Files (gameplay-owned)
- shared: `Config`, `Species`, `Formulas`, `Needs`, `Remotes`, `Format` (Sounds/Theme/CreatureModels are other branches')
- server/Services: `DataService` (only DataStore user + OrderedDataStore board), `Guard` (helper: remote binding,
  rate limit, Notify/Sound, `GameState` folder), `PlotService`, `ItemService`, `PlacementService`, `ZooService`,
  `ShopService`, `GrowthService`, `WeatherService`, `IncomeService`, `QuestService`, `ReleaseService`,
  `HopeService`, `DailyRewardService`, `SocialService`, `AnnounceService`, `MonetizationService`.

## Remotes
All RemoteFunctions return `(ok: boolean, result)`. On failure `result` is an error string AND the server already
fired `Notify(text, "error")` + `PlaySound("Error")`, so UI only needs to refresh. Rate limit 0.2 s per remote;
"Slow down!" / "Still loading..." fire a quiet `Notify(text, "info")` (no Error sound, max 1/s per player).

| RemoteFunction | Args | Result on success | Notes |
|---|---|---|---|
| GetStock | () | stock (see StockChanged) | |
| BuySeed | (slot: number) | species name | slot = index in `stock.slots` |
| PlaceItem | (kind: "seed"\|"creature"\|"decor", ref, pad, cell, rot) | itemId | seed: ref = species name; creature: ref = inventory creature `id`; decor: ref = decor kind. cell 1..25 (row-major, 5x5), rot 0/90/180/270 |
| MoveItem | (itemId, pad, cell, rot) | itemId | plants keep growth |
| RemoveItem | (itemId) | itemId | grown creature -> `inventory.creatures`, growing plant -> seed back (growth lost), decor -> `inventory.decor` |
| SellCreature | (itemId) | cash gained | grown only; placed or inventory creature id. 50% cost x color x weather |
| Water | (itemId) | new ReadyAt | own growing plant, 30 s cooldown per plant |
| BuyPad | (padIndex?) | new padsOwned | pads unlock in order |
| UnlockBiome | (biome) | biome | |
| SetPadBiome | (pad, biome) | biome | free once unlocked |
| BuyDecor | (kind, pad?, cell?, rot?) | itemId, or "inventory" | with pad+cell it buys AND places in one call |
| BuyUpgrade | (key) | new level | keys: WateringCan, Fertilizer, ShopLuck, BiggerRestock, VisitorAppeal, ComfyBenches |
| Release | (creatureId) | {releases, hope} | grown creature (placed or inventory) of rarity >= requirement + cash. Requirement: `Formulas.ReleaseCash(releases+1)`, `Config.ReleaseMinRarity(releases+1)` |
| ClaimDaily | () | {day, text} | **now a RemoteFunction** (template Hud used `Remotes.Event("ClaimDaily")` - UI must switch to `Remotes.Function`) |
| ClaimQuest | (index 1..3) | {cash, hope} | daily quests only; tutorial auto-claims |
| BuyHopeItem | ("HopeCrate"\|"LuckPotion"\|"GrowTonic") | crate: species won; else new count | |
| UseHopeItem | ("LuckPotion") or ("GrowTonic", itemId) | luckUntil / itemId | tonic: Legendary or below |
| VisitPlot | (plotIndex 1..6) | plotIndex | teleports to that plot |
| LikeZoo | (plotIndex) | owner's likes | once per day per zoo, not your own |
| GoHome | () | plotIndex | |

| RemoteEvent (server -> client) | Args |
|---|---|
| DataChanged | (data) - full save table, batched max 4x/s |
| StockChanged | ({restockId, nextRestockAt, luck, slots = {{slot, species, rarity, cost, qty, left}}}) - on join, buy, restock, luck change |
| WeatherChanged | ({name, endsAt, nextAt}) - name "Clear" when none. Times are `os.time()` (use `workspace:GetServerTimeNow()` on client) |
| Announce | (text, rarity?) - server-wide toast; text prefixed "[Global] " if from another server |
| Notify | (text, kind) - kind: "info" \| "success" \| "error" \| "weather" |
| OfflineEarnings | (amount, seconds) |
| PlaySound | (name, part?) - names from Audio's list: Error, Purchase, Cash, Place, Plant, GrowStage (with part), Bloom, Thriving, Mutation, RevealRare..RevealSecret, Release, DailyReward, QuestComplete, Water, Sell, Expand, Restock, Like |
| OpenScreen | (screenName) - fired when a hub ProximityPrompt is used: "SeedShop", "HopeShop", "Upgrades", "Release", "Daily" |

Robux: UI prompts directly with `MarketplaceService:PromptGamePassPurchase/PromptProductPurchase` using
`Config.GamePasses[key].Id` / `Config.DevProducts[key].Id` (all 0 now -> show "Coming soon"). Server grants.

## Data (DataChanged payload) - key fields for UI
`cash, hope, totalEarned, releases, upgrades{key=level}, biomes{name=true}, padsOwned, padBiome[9],
inventory{seeds{species=count}, creatures[{id,species,color,weather}], decor{kind=count}},
placed[{id,species,pad,cell,rot,plantedAt,growTotal,color,weather}]` (growTotal 0 = grown creature),
`decor[{id,kind,pad,cell,rot}], jars[9], indexFound{species={None|Gold|...|Dewy...=true}}, released[{species,color}],
daily{last (UTC day), streak}, quests{day, list[{kind,goal,progress,claimed,text}]}, tutorialStep (1..6, 7 = done),
tutorialProgress, potions{luckUntil, luck (count owned)}, tonics, likes`.
Tutorial steps text: `Config.Tutorial[step].Text`. Daily reward strip: `Config.Daily.Rewards`.

## Attributes I set
**Player:** `PlotIndex`, `PadsOwned`, `IncomePerSec` (final $/s), `ThrivingCount`, `TutorialStep`, `DailyReady`,
`Luck` (current multiplier), `LuckUntil`, `Pass_VIP` / `Pass_DoubleCash` / `Pass_SuperLuck` / `Pass_AutoGardener`,
`ChatTag` ("[VIP]" or nil - UI/client TextChatService should show it).

**ReplicatedStorage.GameState (Folder):** `Weather` ("Clear" or name), `WeatherEndsAt`, `NextWeatherAt`, `RestockId`,
`NextRestockAt`, `Plot<n>_OwnerUserId`, `Plot<n>_OwnerName`, `Plot<n>_Likes`, `Plot<n>_PadsOwned`,
`Plot<n>_Pad<p>_Biome`, `Plot<n>_Pad<p>_Unlocked`. Children: StringValue `TopEarned` (JSON `[{rank,userId,name,value}]`,
refresh 60 s), StringValue `WorldReserve` (JSON `[{species,color,owner,userId}]`, max 60).
Testing: set GameState attribute `ForceWeather = "Rain"` (etc.) to force a weather event; `""` to clear.
**workspace:** `Weather` ("" when clear) for Audio/Graphics.

**Tagged world parts** (if found): `Plot` gets `OwnerUserId`, `OwnerName`, `Likes`, `PadsOwned`;
`ExhibitPad` gets `Biome`, `Unlocked`, `Price`, `OwnerUserId`; `TipJar` gets `Amount` (current $ in jar).

## Placed items in the world (for Graphics + UI)
`workspace.ZooItems.Plot<n>` contains one **Model per placed item**, named by item id, `PrimaryPart = "Hitbox"`
(invisible 3.6x4x3.6, CanQuery=true so the client can raycast/tap it; its bottom sits on the pad surface, centre
of the grid cell, rotated by Rot). **Graphics: build the visual inside this Model** (e.g. `CreatureModels.Build`
aligned to `Hitbox.CFrame * CFrame.new(0,-2,0)`), rebuild when `Stage`/`Color`/`Weather`/`Thriving` change.
Attributes on every item: `ItemId`, `OwnerUserId`, `PlotIndex`, `PadIndex`, `Cell`, `Rot`, `Kind` ("plant"|"decor").
- decor: `DecorKind` (e.g. "Flower Bed", "Info Sign").
- plant: `Species`, `Rarity`, `Role`, `Stage` ("Seed"|"Sprout"|"Bud"|"Grown"), `PlantedAt`, `ReadyAt` (os.time; 0 when
  grown), `Color` ("None"|"Gold"|"Diamond"|"Rainbow"), `Weather` ("None"|"Dewy"|"Sunkissed"|"Frosted"|"Electric"|"Starlit"),
  `Thriving`, `NeedBiome`, `NeedDecor`, `NeedBuddy` (nil for Commons), `NeedsMet`, `NeedsTotal`, `Herd`, `Income` (final $/s).
  UI creature card can read all of this straight off the tapped model.

## What Gameplay expects from Graphics (WorldService) - all optional, with fallbacks + one warning
- Tag `Plot` (Part/Model), Attribute `PlotIndex` 1..6. Pivot = plot centre at ground; -Z (LookVector) toward the hub.
- Tag `ExhibitPad` (BasePart 20x20), Attributes `PlotIndex`, `PadIndex` 1..9. Top surface = planting surface.
  Fallback pad layout: pad p -> row (p-1)//3, col (p-1)%3, offset ((col-1)*24, 0, (row-1)*24) from the plot pivot
  (row 0 = nearest the hub).
- Tag `TipJar` (BasePart or Model), Attributes `PlotIndex`, `PadIndex`. Server hooks `.Touched`. If missing, server
  creates a gold cylinder "FallbackTipJar" at the pad's front-right corner.
- Tag `PlotSpawn` (optional) with `PlotIndex`.
- Hub tags `ShopStand`, `HopeShop`, `UpgradeStand`, `ReleaseAltar`, `DailyStand` -> server adds a ProximityPrompt
  that fires `OpenScreen`.
- Graphics should show locked pads (hedge + price) using `ExhibitPad` attrs `Unlocked`/`Price`, and the biome kit from `Biome`.
- Hub World Reserve reads `GameState.WorldReserve`; leaderboard reads `GameState.TopEarned`.
- Lighting.ClockTime < 6 or >= 18 is "night" (Starfall weather only rolls at night).

## Design choices
- Restock luck: the global seed gives every server the same random draws; each player's luck maps the same draw
  to a rarity, so lucky players see better seeds in the same slots. Instant Restock = personal reroll until next restock.
- Weather schedule is global (os.time based): each 20-min cycle = 16 min clear + 4 min event.
- Mutations: color rolled once at maturity; weather mutation rolled per grown creature per minute in an event (1 max).
- Buddy need counts any OTHER placed creature (growing or grown) with the needed role in that pad.
- Release: items on pads 2..9 go back to inventory (growing plants -> seed), jars reset.
- Auto Gardener waters each growing plant whenever its 30 s cooldown is up (checked every 10 s) and auto-collects jars every 10 s.
- Tutorial steps auto-complete and auto-reward (no claim button needed); daily quests need ClaimQuest.

## Needs from others
- UI: switch ClaimDaily to RemoteFunction; Robux prompts client-side via Config IDs; VIP chat tag from `ChatTag`.
- Graphics: render inside `workspace.ZooItems` models (above); tags/attrs above.
- Audio: my biome names are `Fungus Cave` / `Frost Garden` (Config.BiomeOrder); `Sounds.BiomeAmbience` uses `Fungus`/`Frost`
  keys, so those pads fall back to Meadow ambience - please add the full-name keys. Weather names have spaces
  ("Snow Flurry", "Bloom Season"); MusicDirector already strips spaces, so that works.

## Check round 1 fixes
- **Studio data fallback**: if `GetAsync` fails 3x and `RunService:IsStudio()`, the player gets a deep copy of
  `Config.DefaultData`, one warning is printed (enable Studio Access to API Services), and that player is never saved.
  Live servers still kick.
- **World-ready ordering**: DataService now starts loading players in `Start()` (after every Service's `Init`, incl.
  WorldService's build, so all `OnLoaded` hooks are registered). `onJoin` also waits for `workspace.WorldReady`
  (timeout `Config.WorldReadyTimeout` = 20 s) before caching data/firing hooks. `PlotService.WaitWorldReady()` is
  called in `assign` and IncomeService `ensureJars` as a second guard. If a real `TipJar` is tagged after a fallback
  jar was made, the fallback is destroyed (never two jars).
- Free plots (owner left) show pad 1 Unlocked=true, others locked (matches fresh server).
- VIP `ChatTag` applied immediately on join and for players already in game, plus on `Pass_VIP` change.
- BindToClose waits for all in-flight saves (leave + shutdown) up to `Config.ShutdownSaveTimeout` = 25 s.
  Session locking (UpdateAsync) is still v2.
- Handler errors now go through `Guard.Fail` ("Something went wrong" toast + Error sound).
- Graphics: notes/graphics.md lists `WorldService.WaitReady()` but it isn't implemented; gameplay uses the
  `workspace.WorldReady` attribute, which is.
