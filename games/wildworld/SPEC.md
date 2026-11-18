# Wildworld — Spec

**One-liner:** Hatch, catch and breed cute original creatures in a magical forest, chase rare Golden/Albino/Crystal mutations, and build them the beautiful park they deserve while visitors pay you to look.
**Inspired by:** Build a Zoo (plot earners + mutation multipliers), Grow a Garden (timers, weather, shareable rarities), Dragon Adventures (breeding). Mechanics only.
**Genre:** creature collection + park-builder simulator (multiplayer, 8 players/server, own plot each).

## Look target
Classic Roblox studs / toy-brick look. Full rules: `research/STUDS_STYLE_GUIDE.md` (replaces the storybook look in ART_STYLE_GUIDE).
- `inspiration/studs-inspo-1.png` ("50 Stud Animals"): copy the creature style exactly. Chunky stacked studded bricks, big BrickHeadz head cube, square black eyes with a white highlight, pink cheek tiles, stubby legs, bright soft colours on a grassy hill.
- `inspiration/studs-ui-inspo-store.png`: copy the UI. Chunky white rounded titles with a dark outline, gold 3D numbers, blue sunburst behind items, white plastic panels with stud rows.
- R&D to add 2 in-game refs to `inspiration/refs/`: a top classic-studs game (baseplate ground, brick trees, saturated primaries) and Build a Zoo (plot density + how a full pen reads from the camera).
- Palette: grass `#5CB83C`, path `#E3CFA0`, wood `#B07A45`, water `#3FA9F5`, accent red/blue/yellow `#E0453A` / `#2F7FE0` / `#F5CD30`, sky `#BFE3FF`.
- Lighting mood: bright sunny toy-box afternoon (ShadowMap, ClockTime 14.5, Brightness 3, high ambient, crisp short shadows, bloom on Neon only). The night is a readable blue, and Glowing/Crystal creatures shine.
- Grade bar: the spawn screenshot (hub plus your plot with a hatched creature) must read as a polished studs game at B+ or better next to the inspo. A Lumibun at 20 studs must show its studs, face and ears.

## v1 scope (hard cap, Manager 2026-11-18)
- **One core loop:** hatch → feed → build habitat → catch → breed (mutation chase) → income → upgrades.
- **One zone:** your plot in the hub ring + **Greenleaf Meadow**, a single wild area (keeps Id `Meadow` for save compatibility) where all 5 species spawn by rarity. Its back edge holds the lake + waterfall landmark (moved in from the old Glade). No zone gates, no unlock costs.
- **8 gameplay Services** (Data/Guard/Signals not counted; helper modules are not Services):
  1. `CreatureService`: owned creatures, AI, needs, care (uses the CreatureAI/CreatureCare/Models helpers)
  2. `PlotService`: plot claim, placement, habitat/park rating (absorbs PlacementService + ParkService as helper modules `Placement`/`ParkRating`)
  3. `GeneticsService`: eggs, incubators, hatch, breed, mutations, Gene Scanner
  4. `WildService`: wild spawns + capture (absorbs CaptureService as helper module `Capture`)
  5. `EconomyService`: income, visitor tips, offline earnings, upgrades, shop stall (absorbs ShopService)
  6. `RewardService`: daily streak + daily quests + Park Level XP (merges DailyRewardService + QuestService)
  7. `VisitService`: visit plots, Likes, Top Parks board (the secure multiplayer layer)
  8. `MonetizationService`: passes, products, receipts
  - `WorldService` becomes the plain `World/init.luau` builder, required once by Main (not a Service). `SettingsService` is folded into DataService (the `SaveSettings` remote). `WeatherService` is **cut**.
- **Saved for updates:** Mossy Hollow + Waterfall Glade as separate gated zones (update 2), weather + Rainbow Shower (with zone 2), trading (update 1), hybrids, discovery spots, extra mutations.
- Build catalog trimmed 35 → 32: cut `FieldTent` (duplicates Shelter Hut), `JournalSign`, `StoneTotem`.

## Asset list (3D Art builds these BEFORE branches)
**Method (Manager decision):** every creature and world prop is an **authored brick model** made from studded Plastic parts per STUDS_STYLE_GUIDE, built from code blueprints (`shared/CreatureBlueprints`, `shared/Theme/*`). In this style the bricks *are* the model. 3D Art owns the review: build each one in Studio, run the silhouette + face checks (§4.4), and screenshot it. Studio AI mesh generation is the **fallback only for an asset that grades below B+**, using the prompt below. It must be an original design, never a free-model creature, and stay studded (stud texture). Round props may use Creator Store generic models (no scripts). Icons are ViewportFrame renders of these models: no emoji, no letter badges.
Prompt prefix for every item: *"Low-poly toy brick figure, classic Roblox/LEGO studs on every top face, chunky stacked bricks, bright soft plastic colours, simple flat faces, no textures except studs, cute, game-ready, centred, neutral pose:"*

**Creatures** (adult; Baby = ×0.6 scale; genes/mutations recolour parts by Role)
| Asset | Prompt (after prefix) |
|---|---|
| Lumibun (Common) | white bunny, 3×3 brick head, square black eyes with white highlight, pink cheeks, two tall upright brick ears with pink inner tiles and glowing pale-cyan ear tips, cube tail |
| Mossback (Common) | low wide tan tortoise, stepped green moss-brick hump (3-tier ziggurat) with 3 tiny pink and yellow flower studs, stubby cube legs, square eyes |
| Emberfox (Common) | orange fox, white chest and muzzle, triangle wedge ears with dark tips, dark sock bricks on 4 legs, tail of 3 bricks stepping up with a white tip and a glowing amber cube |
| Pebblehorn (Uncommon) | grey-blue elephant-like creature, big 4×4 head, flat ear slabs with pink insides, stack of 3 shrinking pale cubes as a nose horn, teal diamond plates along the spine, thick legs |
| Thornstag (Rare) | tall proud tan deer, long thin brick legs with dark hooves, white chest, branching brown brick antlers with small green leaf-bud cubes, white tail |

**Eggs & mutation pieces**
| Asset | Prompt |
|---|---|
| Egg (×4 rarity tints) | stacked brick egg shape (wide middle, narrow top), studded, speckle tiles, tints white / green / blue / purple |
| Golden Egg (first-egg reward) | same egg in glossy gold with sparkle tiles |
| Egg shell halves | the egg split into two jagged brick halves (hatch VFX) |
| Crystal brick shard | clear cyan translucent studded brick stack (0.8×1.2×0.8 + 0.6×0.8×0.6) rotated 45° |
| Gold crown plate | small 1×0.4×1 gold plate with 3 studs, for Golden creatures |

**Build props (32)**
| Asset | Prompt |
|---|---|
| Habitat Pad S/M/L | square studded green baseplate with a white brick fence ring and a 2-post gate (sizes 24/36/48 studs) |
| Wood Fence | brick fence segment: 2 posts + 2 rails, studs on top |
| Stone Path | 4×4 tan plate with a darker 1-stud border |
| Park Bench | brick bench, brown seat, white legs |
| Snack Stand | small stall, white walls, red/white striped brick awning, yellow sign |
| Firefly Lantern | brick post with a smooth glass cube top and warm light |
| Round Oak | brown 2×6 trunk + 3 stacked square green canopies (8/6/4) |
| Tall Pine | trunk + 4 stacked dark-green squares 7/5/3/1 |
| Blossom Tree | oak shape with pink and lilac canopy layers + 2 glowing buds |
| Berry Bush | two offset green bricks with red berry cubes |
| Flower Patch | 3 brick stems with red/yellow/white flower plates |
| Mossy Rock | 2 offset grey bricks with a green plate on top |
| Boulder Den | 3 big grey bricks forming a cave nook |
| Hollow Log | 2×2×6 brown brick, light end tiles, dark hole tile |
| Cozy Burrow | dirt brick mound with a dark tunnel opening tile |
| Sand Patch | flat yellow studded plate with 2 pebble cubes |
| Sun Stone | flat warm-orange stone slab with a yellow sun tile |
| Lily Pond | sunken blue basin, grey rim plates, 2 green lily plates |
| Little Waterfall | stepped grey bricks with translucent blue water bricks |
| Food Bowl | 2×1.2×2 red brick bowl with yellow food cubes |
| Water Trough | long brown brick trough with a translucent blue water plate |
| Shelter Hut | white brick walls, red wedge roof, open doorway |
| Toy Ball | round red/white ball (Creator Store generic OK) |
| VIP Golden Fountain | tiered gold brick fountain with blue water plate |
| Crystal Cluster | 3 clear cyan studded crystal brick stacks, soft light |
| Grotto Arch | grey brick arch with crystal bricks on top |
| Glow Shroom | white stem cube + glowing teal neon cap plate |
| Explorer's Arch | brown wood brick arch with a green banner plate |
| Moss Statue | grey brick creature statue with a moss plate |
| Rainbow Flowers | flower patch with 5 rainbow-coloured plates |
| (wild-area set dressing) | brick hills (terraced), boulders, clouds (3 flat white blocks), meadow flowers: same prompts as above |

**Hub & world**
| Asset | Prompt |
|---|---|
| Hub plaza | light-grey studded plaza with a tan path ring and flower-bed plates |
| Shop stall | brick stall, blue wedge roof, yellow/white striped awning, crate of fruit cubes |
| Top Parks board | white brick billboard frame with a blue header and a gold star |
| Daily chest | chunky brown brick chest with gold trim and a star |
| Plot border + name sign | brown fence ring, white brick sign with a glowing name plate |
| Meadow gate arch | big green-and-wood brick arch reading "Greenleaf Meadow" |
| Lake + waterfall | stepped grey cliff bricks, translucent blue water bricks, mist |
| Visitor NPC | classic blocky Roblox-style figure (R6 shape) in bright shirts |

**Icons** (ViewportFrame renders, 3/4 view, FOV 30, blue sunburst background): 5 species (+ silhouette for the Journal), egg, Coins (gold studded coin brick), RP (blue studded gem brick), the 4 Bait items (Berry/Honey/Starfruit as brick fruit), 4 Game Pass icons (VIP crown brick, Extra Incubator egg in nest, Auto-Feeder bowl with gear, Crystal Grotto crystal), Coin pack piles ×3, Starter Pack box.

## Core loop (first 60 seconds)
1. **0–15 s:** spawn on your own empty plot. One pulsing starter egg on a Small Habitat Pad, one arrow, "Hatch!". Tap: wobble, crack, rarity banner. Starter = random Lumibun / Mossback / Emberfox. No other UI yet.
2. **15–30 s:** it runs to you, hops, heart. "Feed it" arrow to the food bowl: munch, happy spin, happiness ring fills.
3. **30–45 s:** a visitor walks up, +25 coin fountain, Coins chip fades in. "Place a tree": rating bar jumps 22 → 34, income ticks up (first purchase, 25 coins).
4. **45–60 s:** quest card "Catch a wild friend in Greenleaf Meadow" + gate arrow. First catch of the same species unlocks Breed; **the first egg is a guaranteed Golden** (big goal shown: Journal 1/5, Park Rating "Poor → Legendary").
Rule: one new HUD button per goal reached; full menu only after 2 creatures.

## Progression
- **Currencies:** Coins (visitor income, sells, quests). Research Points (RP: discoveries, breeding, mutations, quests; spent on Gene Scanner and Journal decor sets).
- **Income (server formula, per minute):** `Σ habitats [ Σ creatures (baseValue × mutationMult × happyMult) × habitatMult ] × parkTierMult`. `habitatMult = 0.5 + 1.5 × rating/100`; `happyMult` = 0.5 if happiness < 30, else 1. Offline: 50% rate, cap 2 h, popup on join.
- **MVP species (all spawn in Greenleaf Meadow, studded brick models):**

| Species | Rarity | baseValue/min | Space (cells) | Personality | Biome tags needed | Egg timer |
|---|---|---|---|---|---|---|
| Lumibun | Common | 4 | 6 | Shy | grass, flower, burrow | 2 min |
| Mossback | Common | 5 | 12 | Lazy | grass, tree, rock | 2 min |
| Emberfox | Common | 6 | 9 | Playful | tree, log, sunspot | 2 min |
| Pebblehorn | Uncommon | 12 | 12 | Social | rock, water, sand | 5 min |
| Thornstag | Rare | 25 | 16 | Curious | tree, water, bush | 10 min |

- **Genetics:** 4 genes, 2 alleles, string `"Cc|Pp|Ss|Gg"`: Color (c = alt palette), Pattern (p = spots), Size (s = ×0.85, Ss = ×0.95), Glow (g = Neon marks). Mendelian roll, hue jitter ±6%, size jitter ±3%. Genes hidden until parent has bred once or Gene Scanner (15 RP). Same species only in v1.
- **Mutations:** Golden 2% ×3 · Albino 1.5% ×2.5 · Crystal 0.5% ×5 · Glowing 1% ×2 (build 4th). Heirloom: each parent with M → M chance ×5 (both ×15), cap 35%. Habitat rating ≥ 80 → ×1.25. (Rainbow Shower weather ×2 is cut from v1.) Max 2 mutations (second rolls at chance/4; Golden+Albino exclusive). Combo Golden+Crystal = "Gilded Crystal" ×12.
- **Breeding:** both Adult, same species, both happiness ≥ 50, cost 50 / 150 / 400 coins (Common/Uncommon/Rare), parent cooldown 5 min. Baby → Adult = 10 min online or 3 feedings.
- **Upgrades (coins):**

| Upgrade | Levels and cost | Effect |
|---|---|---|
| Park Land | 500 / 2,000 / 6,000 / 15,000 | buildable area 64 → 80 → 96 → 112 → 128 studs square |
| Creature Capacity | 300 / 900 / 2,500 / 6,000 / 15,000 | park slots 6 → 8 → 10 → 12 → 14 → 16 (storage 30 free) |
| Incubators | 1,500 / 8,000 | 2 → 3 → 4 eggs at once |
| Calm Net | 400 / 2,000 / 7,000 | capture green zone +5% each |
| Habitat Pads | Small 100 / Medium 600 / Large 2,500 | 24² / 36² / 48² studs, max 4 / 8 / 12 creatures |
| Snack Stand | 750 each (max 3) | +5% park income each, visitors path to it |
| Bait | Berry 10 / Honey 50 / Starfruit 250 | trust +40 / +70 / +100; Starfruit doubles Epic+ wild odds 3 min |

- **Park tiers (long-term goal, replaces rebirth):** park rating = avg habitat rating + decor/path/shop bonus (max +10). Poor < 20 / Developing < 40 / Good < 60 / Excellent < 75 / World-class < 90 / Legendary ≥ 90 → +0 / 5 / 10 / 20 / 35 / 50% income. Plus Journal mastery (5 steps × 5 species) and titles ("Crystal Breeder").
- **Zone (v1 = one):** Greenleaf Meadow, open from the start. Spawn weights: Lumibun/Mossback/Emberfox 25% each, Pebblehorn 18%, Thornstag 7%. Its lower catch chance (20%) is the only gate. Wild spawns: max 12 alive, respawn 45 s. Wild mutation roll: Epic (Albino or Golden) 1%, Legendary (Crystal) 0.2%. Mossy Hollow / Waterfall Glade are kept in Config with `Enabled = false` for update 2.
- **Park Level (XP):** hatch 20, catch 30, breed 25, place item 2, quest 50. Level n needs 100 × n^1.4 XP. Levels unlock build items (fences Lv1, paths Lv2, water Lv3, waterfall Lv6, lanterns Lv7…).

## Monetization (cosmetic/convenience only — never mutation luck or capture guarantees)
- **Game Passes:** VIP 399 (gold name, tag, VIP decor set, +1 daily quest reroll, +10% coins) · Extra Incubator 199 (+1 egg slot) · Auto-Feeder 149 (food stations refill) · Crystal Grotto Decor Pack 249.
- **Dev Products:** Instant Hatch 15 / 25 / 49 (by time left) · Coin packs 49 (2.5k) / 149 (10k) / 449 (40k) · Starter Pack 99 one-time (theme decor + creature bow + 2k coins, offered after first habitat).
- **Daily reward (7-day streak, resets if a day missed):** 100 coins → 200 → 3 Honey Bait → 500 coins + 20 RP → Starfruit Bait → 1,500 coins → **Mutation Egg** (random common, guaranteed Albino or Golden).
- **Daily quests ×3** (e.g. feed 10, breed 1, catch 2) → 150–400 coins + 10–25 RP. Shop restock every 5 min (food + 1 rare decor slot).

## World & UI
- **Map:** central hub plaza (spawn, Top Parks board, daily chest, shop stall) ringed by 8 plots (128×128 each); north gate to Greenleaf Meadow (one wild area, lake + waterfall at its back edge).
- **HUD:** Coins + RP chips (top-left), biome chip (top-centre), Level badge + XP (top-right), 6 left buttons (Collection, Breed, Build, Journal, Inventory, Park), quest tracker (right), context bar near creatures (Feed / Inspect / Pet / Capture).

## Sound & music
- **Music:** sparse melodic percussion (marimba, vibraphone, celesta); forest adds guitar + flute; 20–60 s silences.
- **Key sounds:** egg crack + chirp, 5-tier rarity reveal ladder (F major, ≤ 3.5 s, music ducks −8 dB), capture success/fail, coin tick ladder, place thud, rating-up chime.

## Out of scope (v1)
Trading (planned update 1), Mossy Hollow + Waterfall Glade zones and weather (update 2), co-breeding, cross-species hybrids (later update), biomes 2–6, water/flying creatures, freeform fence enclosures (pads only), elders/bonding, photo mode, extra mutations (Melanistic, Giant, Celestial…; keep disabled in data).

## Decided (Manager)
v1 cut to 1 zone + 8 Services (2026-11-18) · creatures and props are studded brick models (parts are the art medium in this style; AI mesh is the fallback if one grades below B+) · trading = update 1 (v1 has visits + Likes) · same-species breeding only in v1. See `DECISIONS.md`.

---

## For Gameplay
- **Consolidation pass (do first, no behaviour change):** merge to the 8 Services in "v1 scope" (Placement/ParkRating/Capture become helper modules, Daily+Quest → RewardService, Shop → EconomyService, Settings → DataService, WorldService → `World/init.luau`). Delete WeatherService and its `Weather` workspace attribute and remote. Set the Hollow/Glade zones to `Enabled = false`, remove their gates and teleport blocks, and put all 5 species in the Meadow spawn table. Saves stay schema v1 (zone unlocks are just ignored).
- **Priority order (Charlie's):** creature AI → building → genetics → saving → secure multiplayer.
- **Creature AI:** anchored non-Humanoid models. Server Heartbeat loop, max 20 decisions/frame, `nextThink = now + rand(3,8)`. States: Idle, Wander, Eat, Drink, Sleep, Play, Socialize, ReactToPlayer. Weight `w = base × personalityMult × needUrgency`; hunger urgency `(100−Hunger)/25`, squared below 30. Replicate attributes `State`, `Goal` (Vector3), `Speed` only. Goals = random points inside pad bounds (no PathfindingService). Wild creatures think only with a player within 120 studs.
- **Needs:** Hunger −1/30 s; Happiness = Hunger 30% + Habitat rating 40% + Social 15% + Enrichment 15%. Offline floor 20. No death, no running away.
- **Habitat rating (0–100):** Space 25 · Biome tags 20 · Food+water 15 · Shelter 10 · Enrichment 15 (5+4+3+2+1) · Social 15. Return a checklist with "+X if you add ___" hints.
- **Placement:** client sends `{itemId, cellX, cellZ, rot}`; server checks plot owner, unlocked, affordable, in bounds, `cells[x][z]` free, cap 300 objects. 4-stud grid, 90° rotation (15° decor only). Remove refunds 50%.
- **Capture:** bait → trust meter → hold Calm Net, release in shrinking ring's green zone (35% common / 25% uncommon / 20% rare, + Calm Net levels). Server opens the window; release timing validated ±150 ms. Miss = creature runs 15 studs, 2 retries. Pity: guaranteed after 4 fails on one species.
- **Data (schema v1, session-locked, autosave 60 s + leave + BindToClose):** `coins, rp, xp, level, upgrades{}, plot{v,items{{id,x,z,r}}}, creatures{uid → {species, genes, mutations, parents, gen, born, personality, stage, hunger, happy, padId|nil, nickname}}, eggs{}, journal{species → step}, daily{streak,last}, quests{}, flags{tutorialStep, goldenGiven}, lastSeen`. Creature cap 200. Only DataService touches DataStores.
- **Remotes (intents only, rate-limited):** `PlaceItem` / `RotateItem` / `RemoveItem` (10/s), `AssignCreature(uid,padId)`, `FeedCreature(uid)`, `PetCreature(uid)`, `ThrowBait(pos)`, `CaptureStart(wildId)` / `CaptureRelease(wildId)` (2/s), `Breed(uidA,uidB)` (1/s), `HatchEgg(eggId)`, `ScanGenes(uid)`, `BuyUpgrade(id)`, `ClaimDaily`, `ClaimQuest(id)`, `VisitPlot(userId)` / `LikePark(userId)` (+1 rating/visitor/day, cap 20), `ReturnHome`. Server→client: `Reveal(kind, data)`, `Toast(text)`, `PlaySound(name, opts)`. Every remote checks ownership and type.
- All numbers above live in `src/shared/Config.luau`; species/genes/mutations in shared data modules.

## For Graphics
- **Look:** classic studs/toy-brick look per `research/STUDS_STYLE_GUIDE.md` and the Look target above. 14-min day cycle, readable blue night (Glowing creatures shine).
- **Layout:** hub plaza (stalls, Top Parks board, daily chest) → 8 plots in a ring → north gate → **Greenleaf Meadow only**: terraced brick hills, brick tree clusters, flowers, rocks, with the lake + waterfall moved from the old Glade to the meadow's back edge. Delete the Mossy Hollow and Waterfall Glade geometry and their gates. Spend the freed part budget on making the meadow denser and more polished.
- **Palette:** STUDS_STYLE_GUIDE §3.
- **Creatures:** studded brick figures (18–30 parts, Role + Anim attributes, Hitbox PrimaryPart) per STUDS_STYLE_GUIDE §4. They must pass the silhouette and face checks (§4.4). Blueprints in `shared/CreatureBlueprints/`.
- **Mutation layers:** STUDS_STYLE_GUIDE §5 (body parts stay Plastic). ≤ 1 emitter + 1 light per creature.
- **Build props:** 3 habitat pads (auto-fence + gate), fences, paths, trees ×3, bushes, flowers, rocks, logs, burrow, sand patch, pond, waterfall piece, food bowl, water trough, shelter hut, toy ball, lanterns, snack stand, benches. Each tagged with biome tags.
- **Moments:** egg hatch (shell halves, mutation-colour flash), capture bubble, first discovery beam column + FOV punch, rating-up sparkle on the pad.

## For UI
- **Style:** port plant-zoo Kit, re-skin as "explorer's field journal" (parchment, deep teal, sunset coral) per `research/UI_STYLE_GUIDE.md`. 44 px min hit, CoreUISafeInsets, joystick/jump zones clear.
- **Screens:** HUD · Collection (CreatureCard grid, filter by species/mutation) · Inspect (Overview / Genetics / Family / Care tabs) · Build tray + action column (Rotate, Delete, Grid, Done) + live habitat-rating checklist · Breeding Center (Parent A | odds | Parent B, % ranges, "?" unknowns, Breed button with cost/time) + incubator row · Hatch/discovery reveal card with rarity sunburst · Journal (silhouettes, 5-step research bar) · Park panel (rating, tier, income/min, upgrades) · Shop (passes, products, Starter Pack) · Daily reward 7-day strip · Visit list (players in server + Like) · "While you were away" popup · Settings (volume).
- **First 60 s:** nothing but an arrow + "Hatch!" → Feed prompt → Coins chip fades in → Build prompt with rating bar → quest card. Buttons appear one per goal.

## For Animation
- Procedural, client-side, distance tiers (full < 60 studs, 10 Hz to 140, position-only beyond), one `BulkMoveTo` per frame, ≤ 60 animated creatures.
- Idle bob, blink, ear flick, tail wag (faster when happy), walk leg swing, Lumibun hop with squash, sleep Z, hungry head droop, happy hop + hearts, look-at nearest player within 15 studs.
- **Juice moments:** egg wobble speeding up near hatch → crack → creature pops and spins; mutation reveal delay (VFX turns on 0.5 s after); capture ring shrink + bubble pop; coin fountain from visitors; rating bar jump with number count-up; button pop-in when unlocked; Golden first-egg reveal is the biggest moment of session 1.

## For Audio
- **Music:** Park day "whimsical marimba", Park night "gentle music box", Forest "adventure acoustic guitar flute", Menu "magical wonder". Sparse with silences. Keys/IDs per `research/AUDIO_GUIDE.md`.
- **Ambience:** park bed (birds, distant visitors), meadow bed + random one-shots, waterfall loop near the lake at the meadow's back edge. Drop the Hollow/Glade/weather keys.
- **Must-have sounds:** egg crack + baby chirp, 5-tier rarity ladder + mutation tease, capture throw/wobble/success/fail, coin tick ladder, place thud by material, rotate, invalid, rating-up chime, feed munch, per-species voice (pitch per species, chime layer for Crystal/Glowing), daily claim, level up, purchase.
