# Wildworld — Spec

**One-liner:** Hatch, catch and breed cute original creatures in a magical forest, chase rare Golden/Albino/Crystal mutations, and build them the beautiful park they deserve while visitors pay you to look.
**Inspired by:** Build a Zoo (plot earners + mutation multipliers), Grow a Garden (timers, weather, shareable rarities), Dragon Adventures (breeding). Mechanics only.
**Genre:** creature collection + park-builder simulator (multiplayer, 8 players/server, own plot each).

## Core loop (first 60 seconds)
1. **0–15 s:** spawn on your own empty plot. One pulsing starter egg on a Small Habitat Pad, one arrow, "Hatch!". Tap: wobble, crack, rarity banner. Starter = random Lumibun / Mossback / Emberfox. No other UI yet.
2. **15–30 s:** it runs to you, hops, heart. "Feed it" arrow to the food bowl: munch, happy spin, happiness ring fills.
3. **30–45 s:** a visitor walks up, +25 coin fountain, Coins chip fades in. "Place a tree": rating bar jumps 22 → 34, income ticks up (first purchase, 25 coins).
4. **45–60 s:** quest card "Catch a wild friend in Greenleaf Forest" + gate arrow. First catch of the same species unlocks Breed; **the first egg is a guaranteed Golden** (big goal shown: Journal 1/5, Park Rating "Poor → Legendary").
Rule: one new HUD button per goal reached; full menu only after 2 creatures.

## Progression
- **Currencies:** Coins (visitor income, sells, quests). Research Points (RP: discoveries, breeding, mutations, quests; spent on Gene Scanner and Journal decor sets).
- **Income (server formula, per minute):** `Σ habitats [ Σ creatures (baseValue × mutationMult × happyMult) × habitatMult ] × parkTierMult`. `habitatMult = 0.5 + 1.5 × rating/100`; `happyMult` = 0.5 if happiness < 30, else 1. Offline: 50% rate, cap 2 h, popup on join.
- **MVP species (all Greenleaf Forest, code-built):**

| Species | Rarity | baseValue/min | Space (cells) | Personality | Biome tags needed | Egg timer |
|---|---|---|---|---|---|---|
| Lumibun | Common | 4 | 6 | Shy | grass, flower, burrow | 2 min |
| Mossback | Common | 5 | 12 | Lazy | grass, tree, rock | 2 min |
| Emberfox | Common | 6 | 9 | Playful | tree, log, sunspot | 2 min |
| Pebblehorn | Uncommon | 12 | 12 | Social | rock, water, sand | 5 min |
| Thornstag | Rare | 25 | 16 | Curious | tree, water, bush | 10 min |

- **Genetics:** 4 genes, 2 alleles, string `"Cc|Pp|Ss|Gg"`: Color (c = alt palette), Pattern (p = spots), Size (s = ×0.85, Ss = ×0.95), Glow (g = Neon marks). Mendelian roll, hue jitter ±6%, size jitter ±3%. Genes hidden until parent has bred once or Gene Scanner (15 RP). Same species only in v1.
- **Mutations:** Golden 2% ×3 · Albino 1.5% ×2.5 · Crystal 0.5% ×5 · Glowing 1% ×2 (build 4th). Heirloom: each parent with M → M chance ×5 (both ×15), cap 35%. Habitat rating ≥ 80 → ×1.25. Rainbow Shower weather → ×2. Max 2 mutations (second rolls at chance/4; Golden+Albino exclusive). Combo Golden+Crystal = "Gilded Crystal" ×12.
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
- **Zones (3 forest areas, gated by Park Level + coins):** Meadow Edge (Lv 1: commons) → Mossy Hollow (Lv 4 + 1,000: + Pebblehorn, rain spawns) → Waterfall Glade (Lv 8 + 5,000: + Thornstag, discovery spots, only area with Legendary wild spawns). Wild spawns: max 12 alive, respawn 45 s. Wild mutation roll: Epic (Albino or Golden) 1%, Legendary (Crystal) 0.2% Glade only.
- **Park Level (XP):** hatch 20, catch 30, breed 25, place item 2, quest 50. Level n needs 100 × n^1.4 XP. Levels unlock build items (fences Lv1, paths Lv2, water Lv3, waterfall Lv6, lanterns Lv7…).

## Monetization (cosmetic/convenience only — never mutation luck or capture guarantees)
- **Game Passes:** VIP 399 (gold name, tag, VIP decor set, +1 daily quest reroll, +10% coins) · Extra Incubator 199 (+1 egg slot) · Auto-Feeder 149 (food stations refill) · Crystal Grotto Decor Pack 249.
- **Dev Products:** Instant Hatch 15 / 25 / 49 (by time left) · Coin packs 49 (2.5k) / 149 (10k) / 449 (40k) · Starter Pack 99 one-time (theme decor + creature bow + 2k coins, offered after first habitat).
- **Daily reward (7-day streak, resets if a day missed):** 100 coins → 200 → 3 Honey Bait → 500 coins + 20 RP → Starfruit Bait → 1,500 coins → **Mutation Egg** (random common, guaranteed Albino or Golden).
- **Daily quests ×3** (e.g. feed 10, breed 1, catch 2) → 150–400 coins + 10–25 RP. Shop restock every 5 min (food + 1 rare decor slot).

## World & UI
- **Map:** central hub plaza (spawn, Top Parks board, daily chest, shop stall) ringed by 8 plots (128×128 each); north gate to Greenleaf Forest (3 areas, lake + waterfall in the Glade).
- **HUD:** Coins + RP chips (top-left), biome chip (top-centre), Level badge + XP (top-right), 6 left buttons (Collection, Breed, Build, Journal, Inventory, Park), quest tracker (right), context bar near creatures (Feed / Inspect / Pet / Capture).

## Sound & music
- **Music:** sparse melodic percussion (marimba, vibraphone, celesta); forest adds guitar + flute; 20–60 s silences.
- **Key sounds:** egg crack + chirp, 5-tier rarity reveal ladder (F major, ≤ 3.5 s, music ducks −8 dB), capture success/fail, coin tick ladder, place thud, rating-up chime.

## Out of scope (v1)
Trading (planned update 1), co-breeding, cross-species hybrids (later update), biomes 2–6, water/flying creatures, freeform fence enclosures (pads only), elders/bonding, photo mode, extra mutations (Melanistic, Giant, Celestial…; keep disabled in data).

## Decided (Manager)
Creatures code-built parts only · trading = update 1 (v1 has visits + Likes) · same-species breeding only in v1. See `DECISIONS.md`.

---

## For Gameplay
- **Build order (Charlie's priority):** 1) CreatureService 2) PlotService + PlacementService 3) GeneticsService 4) DataService 5) VisitService + remote security. Then CaptureService, EconomyService, QuestService, DailyService, MonetizationService.
- **Creature AI:** anchored non-Humanoid models. Server Heartbeat loop, max 20 decisions/frame, `nextThink = now + rand(3,8)`. States: Idle, Wander, Eat, Drink, Sleep, Play, Socialize, ReactToPlayer. Weight `w = base × personalityMult × needUrgency`; hunger urgency `(100−Hunger)/25`, squared below 30. Replicate attributes `State`, `Goal` (Vector3), `Speed` only. Goals = random points inside pad bounds (no PathfindingService). Wild creatures think only with a player within 120 studs.
- **Needs:** Hunger −1/30 s; Happiness = Hunger 30% + Habitat rating 40% + Social 15% + Enrichment 15%. Offline floor 20. No death, no running away.
- **Habitat rating (0–100):** Space 25 · Biome tags 20 · Food+water 15 · Shelter 10 · Enrichment 15 (5+4+3+2+1) · Social 15. Return a checklist with "+X if you add ___" hints.
- **Placement:** client sends `{itemId, cellX, cellZ, rot}`; server checks plot owner, unlocked, affordable, in bounds, `cells[x][z]` free, cap 300 objects. 4-stud grid, 90° rotation (15° decor only). Remove refunds 50%.
- **Capture:** bait → trust meter → hold Calm Net, release in shrinking ring's green zone (35% common / 25% uncommon / 20% rare, + Calm Net levels). Server opens the window; release timing validated ±150 ms. Miss = creature runs 15 studs, 2 retries. Pity: guaranteed after 4 fails on one species.
- **Data (schema v1, session-locked, autosave 60 s + leave + BindToClose):** `coins, rp, xp, level, upgrades{}, plot{v,items{{id,x,z,r}}}, creatures{uid → {species, genes, mutations, parents, gen, born, personality, stage, hunger, happy, padId|nil, nickname}}, eggs{}, journal{species → step}, daily{streak,last}, quests{}, flags{tutorialStep, goldenGiven}, lastSeen`. Creature cap 200. Only DataService touches DataStores.
- **Remotes (intents only, rate-limited):** `PlaceItem` / `RotateItem` / `RemoveItem` (10/s), `AssignCreature(uid,padId)`, `FeedCreature(uid)`, `PetCreature(uid)`, `ThrowBait(pos)`, `CaptureStart(wildId)` / `CaptureRelease(wildId)` (2/s), `Breed(uidA,uidB)` (1/s), `HatchEgg(eggId)`, `ScanGenes(uid)`, `BuyUpgrade(id)`, `ClaimDaily`, `ClaimQuest(id)`, `VisitPlot(userId)` / `LikePark(userId)` (+1 rating/visitor/day, cap 20), `ReturnHome`. Server→client: `Reveal(kind, data)`, `Toast(text)`, `PlaySound(name, opts)`. Every remote checks ownership and type.
- All numbers above live in `src/shared/Config.luau`; species/genes/mutations in shared data modules.

## For Graphics
- **Look:** sunny storybook park, ShadowMap lighting, values in `research/ART_STYLE_GUIDE.md` §1. 14-min day cycle, readable blue night (Glowing creatures shine).
- **Layout:** hub plaza (stone paths, flower beds, Top Parks board, shop stall with awnings) → 8 plots in a ring, wood borders, glowing name signs → north gate → Meadow Edge (open hills, flowers) → Mossy Hollow (dense trees, mossy rocks, mist) → Waterfall Glade (lake, 1 waterfall, pink/purple magic trees, discovery-spot rings).
- **Palette:** grass `#6CC644`, leaves `#4FBF4A/#7AD65A/#A8E36A`, magic trees `#FFB3D9/#B9A4FF`, wood `#8A5A3B`, water `#3CC3E8`, discovery glow `#FFF3A0`.
- **Creatures:** code-built "toy figurines" (12–25 parts, Role + Anim attributes, Hitbox PrimaryPart) — Mossback (moss hump), Lumibun (long glowing ears), Emberfox (flame tail), Pebblehorn (rock nose horn), Thornstag (branch antlers). Must pass the silhouette test. Blueprints in `shared/CreatureBlueprints/`.
- **Mutation layers:** Golden (Metal gold + sparkle), Albino (white + pink-red eyes), Crystal (Glass shards + light), Glowing (Neon + pulsing light). ≤ 1 emitter + 1 light per creature.
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
- **Ambience:** park bed (birds, distant visitors), forest bed + random one-shots, Glade adds waterfall loop.
- **Must-have sounds:** egg crack + baby chirp, 5-tier rarity ladder + mutation tease, capture throw/wobble/success/fail, coin tick ladder, place thud by material, rotate, invalid, rating-up chime, feed munch, per-species voice (pitch per species, chime layer for Crystal/Glowing), daily claim, level up, purchase.
