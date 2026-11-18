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
Step = server attribute `TutorialStep` (1 Hatch, 2 Feed, 3 Tree, 4 Catch, 5 Breed, 6 done); derived from data only if missing.
1. 0 creatures: hint + big pulsing **Hatch!** button (HatchEgg first egg) + world beam/arrow to my egg. Nothing else on screen.
2. Feed: **Feed it** button (FeedCreature) + arrow to my FoodBowl item. Collection button pops in.
3. Fed (`flags.fed`, tutorialStep >= 3, or a successful Feed this session): Coins chip + Build button pop in, arrow on Build; in build mode the "Tree" item pulses; rating strip shows the jump.
4. Non-pad item placed: Journal button + quest card "Catch a wild friend" + arrow to `ForestGate`.
5. Breed (and done): Breed/Inventory/Park, RP, Level, Shop/Daily/Visit; quest card "Breed your first egg - GOLDEN!" until `flags.goldenGiven`.
Context bar is suppressed during steps 1-2 so the screen stays clean.

## Remotes used (all via `UI/Net.luau`; matches notes/gameplay.md)
Client -> server: `HatchEgg(eggId)`, `FeedCreature(uid)`, `PetCreature(uid)`, `AssignCreature(uid, padUid|nil)`,
`RenameCreature(uid, name)`, `SellCreature(uid)` (hidden if it's your last creature), `ScanGenes(uid)`,
`Breed(uidA, uidB)`, `RequestInstantHatch(eggId)`, `ThrowBait(pos, baitId)` (cheapest bait owned),
`CaptureStart(wildId)` (ring uses serverStart/duration/greenFrom/greenTo), `CaptureRelease(wildId)`,
`PlaceItem(itemId, cellX, cellZ, rot)`, `RemoveItem(itemUid)` (uid found from plot.items cells), `GetHabitat(padUid)`
(on entering build mode), `BuyUpgrade(Land|Capacity|Incubators|CalmNet)`, `GetShop()` / `BuyShop(slot)` (Shop >
Market tab), `ClaimDaily()`, `ClaimQuest(index)`, `VisitPlot(userId)`, `LikePark(userId)`, `ReturnHome()`,
`PromptPurchase("pass"|"product", key)`.
Server -> client: `DataChanged`, `Toast`/`Notify`, `Reveal` (Hatch/Capture = big card; Discovery, LevelUp, Tier,
Offline, Daily, ZoneUnlocked, StarterPack, PassBought = toasts/splashes; Tutorial ignored - UI reads the
`TutorialStep` attribute), `HabitatChanged` (rating strip), `ShopChanged`. `PlaySound` is Audio's.
Player attributes read: `TutorialStep`, `Zone`, `ParkRating`, `ParkTier`, `IncomePerMin`, `DailyReady`, `DailyDay`,
`Pass_<key>`, `MusicVolume`/`SFXVolume`/`MusicOn`/`SFXOn` (Audio).
Shared modules read: `Config`, `Species`, `Items` (catalog, footprints, layers), `Formulas` (LandSize, BuildRange,
CellCentre, Incubators, ParkSlots, BreedCost, LevelXP).

## World markup read
Park creatures tag `Creature` (Uid, OwnerId), wild tag `WildCreature` (WildId, Trust), eggs = any instance under
`workspace.ParkObjects` with `EggId` + `OwnerId`, placed items tag `ParkItem` (ItemId "FoodBowl" for the tutorial
arrow), plot = tag `Plot` part with `OwnerId`, forest arch tag `ForestGate`. Creature pictures use
`Shared/CreatureBuilder.Build(species, {genes, mutations, stage})`.

## Assumptions
- `DailyDay` = when `DailyReady` true, the day the claim gives; when false, the day already claimed today (that tile shows "Claimed"; next = DailyDay % 7 + 1). HUD zone chip shows `Config.Zones[].Name` looked up by `Zone` Id (Park -> "My Park", Hub -> "Plaza").
- Tutorial step 3 highlights `TreeOak` in the build tray.
- No favourites in v1 (Manager decision). Move action skipped (Remove + Place covers it; MoveItem exists).

## Check-report fixes (ui)
- Build math uses the levelled plot CFrame (`PlotInfo.CFrame`, same as PlotService.PlotCFrame): ToCell/CellCFrame/grid lines in plot space.
- Zone unlocking: ParkWindow lists locked zones (Config.Zones) with an Unlock button -> confirm -> `UnlockZone(zoneId)`; client ProximityPrompt on each `ZoneGate` anchor opens the same dialog (hidden once owned).
- Tutorial Feed step: arrow points at the creature; "Feed it" only active within Needs.InteractRange - 2 studs, otherwise "Walk closer".
