# UI notes (Wildworld)

All UI is built in code under `src/client/UI/` (entry `src/client/Main.client.luau`). Style = plant-zoo Kit
ported to `UI/Kit/` and re-skinned as the "field journal" (parchment body, deep-teal frame + stitch border,
category-colour header pills, sunset-coral accent). Palette/rarity/mutation colours in `UI/Style.luau`.
Root UIScale = clamp(viewportY/1080, 0.55, 1.25), `CoreUISafeInsets`, one big window at a time, blur + dim.
No emoji: icons are `Style.Icons` image ids (empty now) with coloured-circle letter fallbacks.

## Screens / modules
| Module | What |
|---|---|
| `Hud` | Coins + RP chips (top-left, "+" opens Shop/Journal), biome chip (top-centre, reads player attr `Zone`/`Biome`/`Area`), Level badge + XP bar + gear (top-right), Shop/Daily/Visit row |
| `SideBar` | Collection, Breed, Build, Journal, Inventory, Park. 2x3 (tall) / 3x2 (phones), hidden until unlocked, red badges (Breed = ready eggs, Journal = new research) |
| `QuestCard` | right-side tracker: tutorial goal, then first unclaimed daily quest + Claim, collapsible chip |
| `ContextBar` | bottom-centre, within 12 studs: own creature Feed/Pet/Inspect, wild Capture, own egg Hatch/timer |
| `CaptureUI` | trust bar (creature attr `Trust`), Throw Bait, HOLD NET shrinking ring with green zone |
| `Nameplates` | Billboard over own creatures: name, mutation dots, red heart < 30% happy; hidden when a window is open |
| `CollectionWindow` | search, Sort (Rarity/Newest/Species/Happiness/Generation), Show filter, CreatureCard grid paged by 24 |
| `InspectWindow` + `InspectTabs` | live rotating viewport, rename, tabs Overview / Genetics / Family / Care ("Fix it" < 40%) |
| `BreedWindow` + `Nests` + `Genetics` | Parent A / odds / Parent B, requirement ticks, cost + egg time, Breed, picker (incompatible greyed with reason), nest row with timers, HATCH, Instant Hatch |
| `Reveal` | hatch/capture/discovery reveal: egg shake, flash, pop, rarity sunburst, mutation badges, NEW DISCOVERY ribbon, queued |
| `BuildMode` + `BuildTray` + `BuildGrid` + `PlotInfo` | tray (category tabs, item cards, price, +tags, level locks), action column (Place/Rotate/Delete/Grid/Done, key hints), ghost green/red + reason, rating strip (stars + "Needs: ...") |
| `JournalWindow` | completion bar, species grid with silhouettes, species page: 5-step research track + mutation gallery |
| `ParkWindow` | rating stars, tier ladder, income/min, coin upgrades |
| `ShopWindow` | Featured (Starter Pack, VIP), Passes, Coins packs, Bait |
| `DailyWindow` | 7-day strip, Claim, timer; auto-opens for returning players |
| `VisitWindow` | players in server, Visit / Like, Return home |
| `InventoryWindow` | bait, stored items, eggs, with jumps |
| `SettingsWindow` | Music + SFX On/Off and volume (Audio's `SetMusicVolume` etc.) |
| `Notify` | toasts (max 3), Announce banner, Splash, "While you were away" popup |
| `Tutorial` + `Arrows` | first 60 s (below) |

## First 60 seconds (Tutorial.luau)
Step comes from data (display only): `flags.tutorialDone` / `flags.tutorialStep >= 5` / 2+ creatures = done.
1. 0 creatures: hint + big pulsing **Hatch!** button (HatchEgg first egg) + world beam/arrow to my egg. Nothing else on screen.
2. 1 creature, not fed: **Feed it** button (FeedCreature) + arrow to `FoodBowl`. Collection button pops in.
3. Fed (`flags.fed`, tutorialStep >= 3, or a successful Feed this session): Coins chip + Build button pop in, arrow on Build; in build mode the "Tree" item pulses; rating strip shows the jump.
4. Non-pad item placed: Journal button + quest card "Catch a wild friend" + arrow to `ForestGate`.
5. 2+ creatures: Breed/Inventory/Park, RP, Level, Shop/Daily/Visit; quest card "Breed your first egg - GOLDEN!" until `flags.goldenGiven`.
Context bar is suppressed during steps 1-2 so the screen stays clean.

## Remotes used (all via `UI/Net.luau`: works for RemoteFunction or RemoteEvent, never hangs, toasts on failure)
Client -> server: `HatchEgg(eggId)`, `FeedCreature(uid)`, `PetCreature(uid)`, `AssignCreature(uid, padId|nil)`,
`ScanGenes(uid)`, `Breed(uidA, uidB)`, `ThrowBait(pos: Vector3)`, `CaptureStart(wildId)`, `CaptureRelease(wildId)`,
`PlaceItem({itemId, cellX, cellZ, rot})`, `RemoveItem({cellX, cellZ})`, `BuyUpgrade(key)`, `ClaimDaily()`,
`ClaimQuest(id)`, `VisitPlot(userId)`, `LikePark(userId)`, `ReturnHome()`.
Optional (button hidden unless the remote exists): `RenameCreature(uid, text)`, `SellCreature(uid)`, `BuyBait(key)`
(else Bait uses `BuyUpgrade(key)`).
Server -> client: `DataChanged(data)`, `Toast(text, kind?)` / `Notify(text, kind?)`, `Reveal(kind, data)`,
`Announce(text, rarity?)`, `OfflineEarnings(coins, seconds, rp?)`, `OpenScreen(name)`. `PlaySound` is Audio's.
`Reveal` kinds: `hatch`, `golden`, `capture`, `discovery` (card), `offline` {coins, seconds, rp}, `levelup` {level},
`journal` {species} (toast). Card data: `{uid?, species, genes?, mutations = {"Golden"}, rarity?, stage?, isNew?}`.
Robux: UI prompts `Config.GamePasses[key].Id` / `Config.DevProducts[key].Id`; Id 0 -> "Coming soon!" toast.
Instant Hatch = any DevProducts key starting `InstantHatch` (cheapest for < 2 min left, then next tiers).

## Data the UI reads (camelCase or PascalCase both work)
`coins, rp, xp, level, upgrades{key=level}, plot{items{{id,x,z,r}}}, creatures{uid -> {species, genes, mutations,
parents, gen, born, personality, stage, hunger, happy, padId, nickname, genesKnown?, breedReadyAt?}}, eggs{id ->
{species, readyAt, duration?}}, journal{species -> step | {step, mutations}}, daily{streak, last, canClaim?},
quests{daily = {{id, text, progress, goal, claimed}}}, flags{tutorialStep, tutorialDone, fed, goldenGiven,
starterBought}, passes{key=true}` plus optional `parkRating, incomePerMin, parkSlots, incubators, habitats{padId ->
{rating, hints = {"water"}}}, pads, inventory{bait{Berry=n}, items{}}`.
Config read (with SPEC fallbacks): `Species, Mutations, Genes, Breeding{Cost, MinHappiness}, Items|BuildItems,
Upgrades, ParkTiers, Daily{Rewards, CooldownSeconds}, Bait, GeneScanner{Cost}, GamePasses, DevProducts, CellSize`.

## World markup the UI expects (Gameplay / Graphics)
- Creatures: tag `Creature`; attrs `Uid` + `OwnerId` (owned) or `WildId` (wild), `Species`, `Trust` (wild, 0-100).
- Eggs in world: tag `Egg`; attrs `EggId`, `OwnerId`, `ReadyAt` (server time).
- Plot: player attrs `PlotCenter` (Vector3, ground top) + `PlotSize` (studs), or a tag `Plot` instance with
  `OwnerId` (+ optional `BuildSize`). Cells are 4 studs from the plot's min X/Z corner, 0-based.
- Landmarks for arrows: tag `FoodBowl` (with `OwnerId`) and `ForestGate` (or parts with those names).
- Creature view builder: `Shared/CreatureBuilder|CreatureBlueprints|CreatureModels` with
  `Build(species, {genes, mutations, stage}) -> Model`. Without it cards show letter badges.
- Player attrs `ParkRating`, `Likes` for the Visit list.

## Assumptions
- PlaceItem/RemoveItem use a table arg and cell coords (spec says `{itemId, cellX, cellZ, rot}`).
- Build catalog item ids `Tree`, `PadSmall` etc. when Config has no list (tutorial highlights "Tree").
- Favourite star on cards skipped (no remote in spec). Move-object build action skipped (Remove + Place covers it).
