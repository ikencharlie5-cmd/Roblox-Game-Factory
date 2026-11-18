# Gameplay notes (Wildworld)

Server-authoritative. All numbers: `src/shared/Config.luau`. Species: `Species.luau`. Build catalog:
`Items.luau` (`Items.Defs[id]`, `Items.List()`, `Items.Footprint(def, rotDeg)`).
Shared pure modules UI can use for previews (same math as server):
- `Genetics` — `Parse`, `Traits(genes)`, `Odds(genesA, genesB, knownA, knownB)` (per gene recessivePct/mixedPct),
  `MutationChance(name, mutsA, mutsB, mods)`, `MutationMult`, `MutationLabel`, `DisplayRarity(species, muts)`.
- `Habitat.Rate(padDef, itemDefs, speciesList)` -> `{rating, checklist[{key,label,score,max,hint}], social, enrichment}`;
  `Habitat.Stars(rating)` (0..5 in halves).
- `Formulas` — `LevelXP(n)`, `ParkTier(rating)`, `HabitatMult`, `CreatureValue(rec)`, `SellValue(rec)`, `ParkSlots(lvl)`,
  `LandSize(lvl)`, `Incubators(lvl, hasPass)`, `UpgradeCost(key, lvl)`, `BreedCost(species)`, `InstantHatchKey(secsLeft)`,
  `BuildRange(landLevel)` (inclusive cell range, 0-based), `CellCentre(x, z, w, d)` (plot-local studs), `Day()`.

## Files (gameplay-owned) — v1 scope: exactly 8 gameplay Services
shared: `Config, Species, Items (32 build items; FieldTent/JournalSign/StoneTotem cut), Genetics, Habitat, Formulas, Remotes, Format`.
server/Services — the 8 Services (booted by Main, in this order after DataService):
1. `MonetizationService` — passes, products, receipts, VIP tag.
2. `PlotService` — plot claim + building + habitat/park rating + income. Facade that re-exports every function of
   helpers `PlotCore` (claim/transforms/OnAssigned), `Placement` (Place/Rotate/Move/RemoveItem, uses `PlotGrid`) and
   `ParkRating` (ratings, IncomePerMin, GetHabitat). Other code only requires `PlotService`.
3. `CreatureService` — owned creatures; helpers `CreatureCare` (care remotes + needs loop), `CreatureAI` (brains; its
   loop is now started by `CreatureService.Start` via `CreatureAI.Run()`), `Models`.
4. `GeneticsService` — breed, eggs, hatch, scan, starter egg (helper `Journal`).
5. `WildService` — Meadow spawns + capture; helpers `WildRoll` (species/mutation rolls) and `Capture` (ThrowBait /
   CaptureStart / CaptureRelease; bound by WildService).
6. `EconomyService` — visitor tips, offline, BuyUpgrade, UnlockZone; helper `Shop` (GetShop / BuyShop / restock).
7. `RewardService` — daily streak (ClaimDaily), Park Level XP + LevelUp, helper `Quests` (tutorial + ClaimQuest /
   RerollQuest).
8. `VisitService` — VisitPlot / LikePark / ReturnHome / GetTopParks + hub board (`require(server.World).SetTopParks`).
Not counted: `DataService` (+ helpers `DataSchema`, `DataSettings` = the old SettingsService / SaveSettings), `Guard`,
`Signals`. Helpers have no Init/Start; Main only boots the 9 modules in its ORDER list plus `World` (Graphics).
**Cut:** WeatherService (no weather, no Sunny bonus, no Rainbow mutation bonus, no Rain spawn boost).

## v1 zone
One wild zone, `Meadow` ("Greenleaf Meadow", Config.Zones[1], `Enabled = true`): all 5 species, weighted by
`Config.Capture.SpawnWeights` (Common 70 / Uncommon 22 / Rare 6.8), wild Crystal possible (`Legendary = true`).
`Hollow` / `Glade` stay in Config with `Enabled = false` (update 2): their WildSpawn nodes are ignored, a player inside
their ZoneArea is sent back with "<name> opens in a future update!", and `UnlockZone` fails with the same message.

## Remotes
Every client->server remote is a **RemoteFunction** returning `(ok: boolean, result)`. On failure `result` is a message
and the server already fired `Toast(msg, "error")` + `PlaySound("Error")`. Rate limits: default 0.2 s; PlaceItem /
RotateItem / MoveItem / RemoveItem 0.1 s, ThrowBait / CaptureStart / CaptureRelease 0.5 s, Breed 1 s.
"Slow down!" / "Still loading..." come back as a quiet `Toast(..., "info")`.

| RemoteFunction | Args | Result on success |
|---|---|---|
| PlaceItem | (itemId, cellX, cellZ, rot) | item uid (number). Cells are **0-based** 0..31, min corner of the footprint; rot in degrees (multiple of 90, or 15 if `def.Fine`). Pays coins / RP / uses `decorInv` / free for owned pass + Starter items |
| RotateItem | (itemUid, rot) | itemUid |
| MoveItem | (itemUid, cellX, cellZ, rot) | itemUid (pads only move when empty of objects) |
| RemoveItem | (itemUid) | itemUid. Refund 50% coins (RP items 50% RP, shop-rare back to `decorInv`). Pads must be empty of objects; creatures on it go to storage |
| RefillStation | (itemUid) | servings (food bowl, 10) |
| GetHabitat | (padUid) | `Habitat.Rate` result (rating 0..100 + checklist with "+X if you add ___" hints) |
| AssignCreature | (uid, padUid or nil/0) | padUid (nil/0 = to storage). Checks pad capacity (4/8/12) and park slots |
| FeedCreature | (uid) | new hunger. Must be within 30 studs; per-creature 10 s cooldown; 3 feeds grow a Baby |
| PetCreature | (uid) | new happiness (+10 for 2 min). 30 studs, 8 s cooldown |
| RenameCreature | (uid, name<=20) | filtered name ("" clears) |
| SellCreature | (uid) | coins (baseValue x mutationMult x 15). Can't sell your last creature |
| ThrowBait | (position: Vector3, baitId? "Berry"/"Honey"/"Starfruit") | wildId or nil (bait used even if nothing is near). Within 45 studs of you; attracts the nearest unclaimed wild within 16 studs; adds trust; claims it for you for 25 s |
| CaptureStart | (wildId) | `{wildId, serverStart (GetServerTimeNow), duration, greenFrom, greenTo, guaranteed}` — ring progress p = (now-serverStart)/duration from 0 to 1; release when p is inside [greenFrom, greenTo]. Needs trust >= 40, within 30 studs, claimed by you |
| CaptureRelease | (wildId) | `{success=true, uid, species}` or `{success=false, attemptsLeft}` (ok is still true). Server judges timing on its own clock ±150 ms |
| Breed | (uidA, uidB) | eggId. Same species, both Adult, happy >= 50, cost 50/150/400, 5 min parent cooldown, free incubator |
| HatchEgg | (eggId) | creature uid (egg must be ready: `readyAt <= os.time()`) |
| ScanGenes | (uid) | genes string (15 RP unless already known) |
| BuyUpgrade | ("Land"\|"Capacity"\|"Incubators"\|"CalmNet") | new level |
| UnlockZone | (zoneId) | v1: always fails "<name> opens in a future update!" (Hollow/Glade disabled); "Meadow" returns "Meadow" |
| GetShop | () | shop view (see ShopChanged) |
| BuyShop | (slot) | new shop view. Bait goes to `data.bait`, rare decor to `data.decorInv` (UI's "BuyBait" = this) |
| ClaimDaily | () | `{day, text}` |
| ClaimQuest | (index 1..3) | `{coins, rp}` |
| RerollQuest | (index 1..3) | new quest `{id, progress, claimed}` (1/day, VIP 2/day) |
| VisitPlot | (userId) | plot index (teleports you) |
| LikePark | (userId) | owner's like count today (must be on their plot or visited in last 10 min; once/day) |
| ReturnHome | () | plot index |
| RequestInstantHatch | (eggId) | product key it prompted (`InstantHatch1/2/3` by time left: <=2 min 15 R$, <=5 min 25, else 49) |
| PromptPurchase | ("pass"\|"product", key) | key. Id 0 -> fails with "Coming soon!" |
| GetTopParks | () | `{server = [{userId,name,rating,tier,likes}], global = [{userId,name,rating}]}` |

| RemoteEvent (server -> client) | Args |
|---|---|
| DataChanged | (data) full save table, batched max 4x/s |
| Toast | (text, kind) kind: info / success / error / reward (server no longer sends "weather"). (`Notify` also exists but is unused) |
| Reveal | (kind, data) — see below |
| PlaySound | (name, opts?) opts may have `position: Vector3`, `species: string`, `kind: string` (item kind for place thud) |
| VisitorTip | (amount, position) coin fountain at a habitat (income is paid this way every 10 s) |
| HabitatChanged | (padUid, rateResult) whenever one of your pads' rating changes |
| ShopChanged | ({restockId, nextRestockAt (os.time), slots = [{slot, kind "bait"\|"decor", ref, name, price, stock, left}]}) |
| CaptureState | (wildId, {trust, attemptsLeft, claimedBy (userId), needed}) |

| RemoteEvent (client -> server) | Args |
|---|---|
| SaveSettings | ({music 0..1, sfx 0..1, musicOn bool, sfxOn bool}) -> clamped, bad fields ignored, max 1 per 0.5 s (extra calls dropped), saved to `data.settings`; server re-sets the 4 player attributes |

**Range checks** (Feed/Pet/ThrowBait attract/CaptureStart) use the nearer of the creature's server position and its
`Goal`, with `Config.Needs.GoalSlack` (6) studs of slack on the Goal distance.

**Reveal kinds:** `Hatch` {uid, species, mutations, label, rarity, firstDiscovery, starter, padId} ·
`Capture` (same fields) · `Discovery` {species, rarity, blurb, rp, coins} (first time a species is owned; fires
right after Hatch/Capture) · `LevelUp` {level, unlocks[]} · `Tier` {tier, rating, bonus} · `Offline` {coins, seconds,
cappedSeconds, eggsReady} · `Daily` {day, text, streak} · `Tutorial` {step, text} · `ZoneUnlocked` {zone, name} ·
`StarterPack` {coins} · `PassBought` {key, name} · `OpenWindow` {name = "Daily" | "Shop"} (fired when the hub
`DailyChest` / `ShopStall` ProximityPrompt is triggered; Main.client.luau opens that window — listener already added).

**PlaySound names fired by the server:** Error, Place, Rotate, Remove, Assign, Munch, Pet, GrowUp, Refill, Sell,
EggLaid, EggCrack, EggReady, Scan, Discovery, JournalStep, BaitThrow, NetCharge, CaptureSuccess, CaptureFail,
RatingUp, TierUp, LevelUp, Purchase, Unlock, QuestComplete, QuestReady, DailyClaim, Restock, Like.
(Weather_* / WeatherClear are no longer fired: weather is cut.) `ZoneUnlocked` Reveal can no longer fire in v1.

## Data (DataChanged payload)
`coins, rp, xp, level, totalEarned, bestRating, upgrades{Land,Capacity,Incubators,CalmNet}`,
`plot{v, items[{id, x, z, r, u}]}` (0-based cells, r degrees, u = item uid),
`creatures{uid -> {uid, species, genes "Cc|Pp|Ss|Gg", mutations[], parents[], gen, born, personality, stage "Baby"|"Adult",
hunger, happy, grow, feeds, bred, scanned, breedReadyAt, padId|nil, nickname, seed, source}}` — genes are "known" to the
player when `bred > 0 or scanned` (UI shows "?" otherwise),
`eggs[{id, species, genes, mutations, parents, gen, laidAt, readyAt (os.time), source "breed"|"starter"|"daily"}]`,
`journal{species -> step 0..5}`, `journalStats{species -> {bred, mutated}}`,
`stats{hatched, caught, bred, fed, mutations, likes}`, `daily{streak, last (UTC day)}`,
`quests{day, rerolls, list[{id, progress, claimed}]}` (defs in `Config.Quests.Pool` by id),
`flags{tutorialStep 1..6, goldenGiven, starterEgg, starterPack, bow}`, `bait{Berry, Honey, Starfruit}`,
`decorInv{itemId -> n}`, `zones{Meadow=true, ...}`, `pity{species -> fails}`, `likes{day, by, count}`,
`boosts{starfruit (os.time until)}`, `shop{id, bought}`, `lastSeen`. (`lock`, `receipts` are internal.)
Journal steps: 1 Discover · 2 Raise an adult · 3 Breed once · 4 Own 3 at once · 5 Get a mutation.
Incubators = `Formulas.Incubators(upgrades.Incubators, Pass_ExtraIncubator)`.

## Attributes
- **Player:** `PlotIndex`, `DataLoaded`, `Level`, `ParkRating` (0..100), `ParkTier` ("Poor".."Legendary"), `ParkTierIndex`,
  `IncomePerMin`, `TutorialStep` (1..5, 6 = done), `TutorialText`, `DailyReady` (bool), `DailyDay` (1..7),
  `Zone` ("Park" or "Meadow"; Hollow/Glade only if those ZoneAreas still exist), `Pass_VIP` / `Pass_ExtraIncubator` / `Pass_AutoFeeder` /
  `Pass_CrystalGrotto`, `VIP` (bool — UI: gold name + chat tag), `MusicVolume` / `SFXVolume` (0..1) /
  `MusicOn` / `SFXOn` (bool) from `data.settings` on load.
- **Park creature model** (workspace.Creatures, tag `Creature`): `Uid, Species, OwnerId, Personality, Stage, Mutations`
  ("Golden,Crystal"), `MutationLabel, Rarity, AltColor, Spots, Glow, Hue, Wild=false, Hunger, Happy, Nickname, PadUid, Bow,
  State, Goal (Vector3), Speed, LastFed, LastPet` (GetServerTimeNow stamps for munch/heart moments).
  States: Idle, Wander, Eat, Drink, Sleep, Play, Socialize, ReactToPlayer. Server never moves parts after spawn;
  clients move the model toward `Goal` at `Speed`.
- **Wild creature model** (workspace.WildCreatures, tags `WildCreature` + `Creature`): `Wild=true, WildId, Species, Zone,
  Mutations, MutationLabel, Rarity, Stage="Adult", Trust, ClaimedBy (userId), State (also "Flee", "Calm" while the ring
  is up), Goal, Speed, Moment` ("CaptureFail:<n>" on a miss; "Captured:<n>" on a catch — the model then stays 0.9 s
  (`Config.Capture.CapturedMomentSeconds`) with `Wild=false` and is no longer interactable before it's destroyed).
- **Placed item models** (workspace.ParkObjects.Plot_<i>, tag `ParkItem`): `ItemUid, ItemId, Kind, OwnerId, PlotIndex`.
  Pads also tag `HabitatPad` + `PadSize, Capacity, Rating, Stars, Count`.
- **Plot base part** (Graphics' `Plot` tag): gameplay sets `OwnerId, OwnerName, LandSize, ParkRating, ParkTier`, and on
  every visitor payout (incl. the first-60s +25) `TipAmount` (number) then `Tips` (+1 counter -> client coin fountain).
- **Starter egg** (in the plot folder): `EggId, OwnerId, Starter=true` + ProximityPrompt "Hatch!".
- **ReplicatedStorage.GameState:** `ShopRestockAt` (os.time). (`Weather*` attributes are gone; gameplay no longer
  sets workspace `Weather` either.)

## First 60 seconds (server side)
New data = Small Habitat Pad + Food Bowl in the plot centre, 5 Berry bait. On first load a starter egg (random
Lumibun/Mossback/Emberfox, ready instantly) appears on the pad with a "Hatch!" prompt (HatchEgg also works).
Tutorial chain (`TutorialStep`): 1 Hatch -> 2 Feed (completing pays a **25-coin visitor tip** = the first tree) ->
3 Place a tree -> 4 Catch a wild -> 5 Breed -> 6 done. The starter hatches as an **Adult** so the first catch of the
same species can breed at once; the **first bred egg is always Golden** (`flags.goldenGiven`).
Until `goldenGiven`, each wild spawn has a `Config.Capture.StarterSpeciesBias` (60%) chance to be a species some
online player owns exactly one of (WildService.wantedSpecies). Trust doesn't decay while a wild is claimed by the
baiting player, so one Berry (40 = TrustNeeded) is enough. Capture timing subtracts ping/2 (one-way).
**Hub prompts:** DailyChest -> Reveal OpenWindow Daily; ShopStall -> ShopChanged + Reveal OpenWindow Shop
(`Guard.WirePrompt(tag, fn)`). **DiscoverySpot** is decor only — no gameplay reads it.

## Saving (never lose data)
UpdateAsync with a session lock `{job, t}`: a second server waits up to 30 s for the lock, takes over a lock older than
180 s, and a server that lost its lock never writes. Autosave 60 s, save + release on leave, BindToClose waits for all
saves. Robux receipts are deduped by PurchaseId saved in data and force-saved before PurchaseGranted. Studio without
API access plays on default data and doesn't save (warns once). An autosave in flight when the player
leaves writes nothing (transform returns nil) so it can't re-take the lock after release. `save`/`SaveNow` return
false when the lock was lost, so receipts stay NotProcessedYet (also re-checked for already-cached receipts).

## Needs from other branches
- **Graphics:** gameplay uses `Shared.Theme.Props.Build(itemId, seed)` and `Shared.CreatureBuilder.Build/BuildEgg`.
  Footprints must match `Items.luau`. `Theme.Props` can drop FieldTent / JournalSign / StoneTotem (no longer in Items;
  saves holding them drop them on load). VisitService calls `World.SetTopParks(rows)`; nothing calls SetWeather.
  WildService reads `WildSpawn` parts with `Zone = "Meadow"` (needs ≥ 12 nodes; fallback ring of 8 otherwise).
- **UI:** ParkWindow's zone-unlock list should skip `Config.Zones` entries with `Enabled == false` (UnlockZone now
  always fails for them); hide any weather UI (GameState Weather attrs no longer exist).
- **Audio/Animation:** no weather sounds/attributes from the server any more.
- **Main.server.luau** (edited by gameplay for the merge, per coordinator): requires `World` and calls `World.Init()`
  before the Services' Init and `World.Start()` alongside their Start; boots only DataService + the 8 Services.

## VIP tag (sign-off fix)
- MonetizationService adds a gold "VipTag" BillboardGui on the Head for players with the `VIP` attribute (on CharacterAdded and when VIP changes mid-session).
- Client `src/client/Chat/VipChatTag.luau` sets TextChatService.OnIncomingMessage to prefix gold [VIP]; required in a pcall from Main.client.luau.
