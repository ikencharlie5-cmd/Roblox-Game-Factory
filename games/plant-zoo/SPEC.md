# 🌱 Sprout Zoo — Spec

**One-liner:** Buy random-rarity seeds, grow them into cute plant-creatures, give each one the right biome exhibit so it's Thriving, and earn $/s from visitors to build the biggest zoo in the server.
**Inspired by:** Grow a Garden (restock + mutations + weather), Build a Zoo (plots, expansion), Planet Zoo 2 depth layer (biomes → Thriving, Release to the Wild).
**Genre:** tycoon / simulator

## Core loop (first 60 seconds)
1. Spawn on your own plot with $100 and a free **Sproutling** seed; arrow → plant it on the Meadow exhibit (grows in 10 s, 4 visible stages).
2. Quest: "Buy a Flower Bed" ($50) → creature card shows 2/2 ✓ → **Thriving!** sparkles, ×1.5. Visitors walk up, the Tip Jar fills, walk over it → coin pop.
3. Spend tips at the **Seed Shop** (restocks every 5 min, rarity roll, countdown visible) on a Pebble Pea / Lily Guppy.
4. Bigger goal on HUD: "Next: Exhibit Pad 2 — $500" and the **Release to the Wild** bar ($1M + one Epic).

## Progression
- **Currency:** Cash ($, main) and **Hope** 🌟 (from releases, daily reward, quests, Robux).
- **Upgrades** (kept through Release; 5 levels each, cost per level):

| Upgrade | Effect / level | Costs (L1→L5) |
|---|---|---|
| Watering Can | water cuts 10/15/20/25/30% of remaining grow time (30 s cooldown per plant) | free, 2k, 20k, 200k, 2M |
| Fertilizer | +10% grow speed | 1k, 15k, 150k, 1.5M, 15M |
| Shop Luck | +10% luck | 5k, 50k, 500k, 5M, 50M |
| Bigger Restock | shop slots 6→10 (4 levels) | 10k, 100k, 1M, 10M |
| Visitor Appeal | +10% income | 3k, 30k, 300k, 3M, 30M |
| Comfy Benches | offline cap 2→4→6→8 h (3 levels) | 5k, 50k, 500k |

- **Exhibit Pads** (plot = 3×3 pads, each 5×5 grid cells): $0, 500, 5k, 40k, 250k, 1.5M, 10M, 60M, 400M.
- **Biomes** (unlock once, kept forever): Meadow free, Pond 1k, Desert 10k, Canopy 100k, Fungus Cave 1M, Frost Garden 10M.
- **Rebirth = Release to the Wild** (replaces cash rebirth). *Why:* one prestige button is easier to teach and build, and giving up your best creature is a more meaningful cost than cash alone. Release #n needs cash `[1M, 25M, 250M, 2B, 20B, then ×10]` plus releasing 1 creature of Epic+ (n=1), Legendary+ (n=2–3), Mythical+ (n≥4). Gives permanent **+50% income** and **+10% luck** per release, `25×n` Hope, +1 shop slot every 2 releases (max 12), and your creature + name tag join the hub **World Reserve**. Resets cash to $100 and pads to 1. Keeps creatures (unplaced ones go to inventory), upgrades, biomes, Hope, Index.

## Monetization
- **Game Passes:** VIP 249 R$ (+25% income, 100% offline earnings, chat tag) · 2× Cash 599 R$ · Super Luck 399 R$ (+50% luck) · Auto Gardener 349 R$ (auto-collects jars + auto-waters every 10 s).
- **Dev Products:** Instant Restock 29 R$ · Finish All Growing 49 R$ · Hope packs 100/49 R$, 500/199 R$, 1,500/499 R$ · Cash Boost (30 min of current income) 99 R$.
- **Daily reward** (7-day streak, resets if a day is missed): 5 min income (min $200) → 10 Hope → Luck Potion → 15 min income → 2 Grow Tonics → 30 Hope → free Epic seed.

## World & UI
- **Map:** central hub (Seed Shop, Hope Shop, Upgrade stand, World Reserve diorama, leaderboards) with 6 plots (80×80 studs) on a ring around it, built on Charlie's baseplate.
- **HUD:** Cash + $/s, Hope, weather banner + timer, restock timer, quest tracker, left button bar.

## Sound & music
- **Music mood:** calm, cozy pastoral (acoustic/marimba); uplifting swell in World Reserve; upbeat during weather events.
- **Key sounds:** coin pop, sprout bloop per stage, maturity chime, rarity-scaled fanfare, Thriving ✓ ding, release whoosh + choir.

## Out of scope (v1) → v2
Trading + Greenhouse Market, cross-pollination/genes (Size/Yield/Speed), Photo Quests + Album, Zoo Stars, combo exhibits, season pass, limited-time events, community goals, Pond walk-through tunnel, achievements/player levels, path painting.

## Questions for Charlie
1. Name "🌱 Sprout Zoo" OK? *Default: yes.*
2. Sell luck for Robux (Super Luck pass)? *Default: yes, 399 R$ — peers do it.*

---

## For Gameplay
**Species** (`Config.Species`; rarity weights before luck: Common 60, Uncommon 25, Rare 10, Epic 4, Legendary 0.9, Mythical 0.09, Secret 0.01). Role ∈ Pollinator/Grazer/Glower/Guardian. Commons have 2 needs (biome, decor); Uncommon+ add a 3rd (buddy role in same pad).

| # | Name | Rarity | Biome | $/s | Cost | Grow | Decor need | Buddy | Role |
|---|---|---|---|---|---|---|---|---|---|
|1|Sproutling|C|Meadow|1|10|10 s|Flower Bed|—|Pollinator|
|2|Pebble Pea|C|Meadow|2|25|25 s|Log|—|Grazer|
|3|Lily Guppy|C|Pond|3|50|30 s|Lily Pad|—|Grazer|
|4|Prickle Pup|C|Desert|3|60|35 s|Sandstone Rock|—|Guardian|
|5|Mossmouse|C|Fungus|4|80|45 s|Glow Shroom|—|Grazer|
|6|Snowdrop Bunny|C|Frost|5|100|60 s|Pine Tree|—|Pollinator|
|7|Dandelion Lion|U|Meadow|12|300|90 s|Beehive|Grazer|Guardian|
|8|Kelp Eel|U|Pond|15|450|2 m|Reed Clump|Grazer|Glower|
|9|Vine Monkey|U|Canopy|18|600|2 m|Vine Swing|Pollinator|Grazer|
|10|Tumbleweed Hog|U|Desert|22|850|2.5 m|Clay Pot|Guardian|Grazer|
|11|Puffball Frog|U|Fungus|30|1.2k|3 m|Stalagmite|Glower|Pollinator|
|12|Sunflower Owl|R|Canopy|60|3k|4 m|Nest|Grazer|Guardian|
|13|Bubble Lotus Turtle|R|Pond|90|5k|5 m|Pond Rock|Glower|Grazer|
|14|Cactus Camel|R|Desert|120|7k|6 m|Palm Shade|Guardian|Grazer|
|15|Frostfern Fox|R|Frost|160|10k|7 m|Ice Crystal|Pollinator|Guardian|
|16|Glowcap Snail|R|Fungus|200|12k|8 m|Crystal|Grazer|Glower|
|17|Orchid Parrot|E|Canopy|500|45k|10 m|Hollow Log|Glower|Pollinator|
|18|Venus Croc|E|Pond|750|75k|12 m|Reed Clump|Grazer|Guardian|
|19|Crystal Moth|E|Fungus|1,000|110k|15 m|Crystal|Pollinator|Glower|
|20|Pinecone Bear|E|Frost|1,400|150k|18 m|Snowman|Grazer|Guardian|
|21|Blossom Stag|L|Meadow|5,000|700k|30 m|Beehive|Pollinator|Grazer|
|22|Bonsai Dragon|L|Canopy|8,000|1.2M|35 m|Vine Swing|Guardian|Glower|
|23|Sandstorm Scorpion|L|Desert|11,000|1.7M|40 m|Palm Shade|Grazer|Guardian|
|24|Glacier Yeti|L|Frost|15,000|2.2M|45 m|Ice Crystal|Glower|Guardian|
|25|Phoenix Fern|M|Desert|60,000|15M|90 m|Clay Pot|Guardian|Glower|
|26|Moonpetal Unicorn|M|Meadow|100,000|30M|2 h|Flower Bed|Glower|Pollinator|
|27|World Tree Tortoise|S|Canopy|500,000|200M|3 h|Nest|Pollinator|Guardian|
|28|Abyss Bloom Kraken|S|Pond|1,000,000|500M|4 h|Pond Rock|Guardian|Glower|

- **Restock:** global every 300 s, RNG seeded by `os.time()//300` (same stock every server). Each slot rolls rarity (weights: non-Common × luck), then a random species of that rarity. Qty: C 3–5, U 2–3, R 1–2, Epic+ 1. Per-player purchase counters keyed by restockId. Instant Restock = personal reroll.
- **Luck** = `(1 + 0.1·shopLuck + 0.1·releases + 0.5·SuperLuck) × (2 if Luck Potion, 15 min)`.
- **Growth:** stages Seed 0–25%, Sprout 25–60%, Bud 60–100%, Grown. `growTime = base / (1+0.1·fert) / eventMult`. Store `plantedAt` + `growTotal`; progress continues offline. Only Grown earns.
- **Color mutation** (rolled when Grown, odds ×2 in Bloom Season): Gold ×3 (1.5%), Diamond ×5 (0.5%), Rainbow ×10 (0.1%).
- **Weather** (every 20 min, lasts 4 min; one weather mutation max per creature, rolled per creature per minute): Rain 30% weight — Dewy ×2 (3%/min), growth ×1.5 · Heatwave 20% — Sunkissed ×2 (3%) · Snow Flurry 20% — Frosted ×3 (1.5%) · Bloom Season 15% — growth ×2, color odds ×2 · Thunderstorm 10% — Electric ×8 (0.3%) · Starfall 5% (night only, else reroll) — Starlit ×5 (0.6%).
- **Income per creature** = `base × color × weather × (1.5 if Thriving) × (1.1 if 3+ same species in pad) × (1.05 if Info Sign in pad)`. **Player mult** = `(1+0.5·releases) × (1+0.1·appeal) × 1.25 VIP × 2 (2× Cash)`. Server ticks 1/s into each pad's Tip Jar; walking over (server Touched) collects. Offline: `rate × min(away, cap) × 0.5` (1.0 with VIP), shown in popup.
- **Needs:** recomputed server-side on any place/move/remove in that pad; cached per creature (no lag).
- **Grid:** 4-stud cells, 5×5 per pad, 1 item per cell, rotate 90°. Decor: 3 per biome (Meadow Flower Bed/Log/Beehive $50; Pond Lily Pad/Pond Rock/Reed Clump $300; Desert Sandstone Rock/Clay Pot/Palm Shade $2k; Canopy Vine Swing/Hollow Log/Nest $15k; Fungus Glow Shroom/Crystal/Stalagmite $100k; Frost Ice Crystal/Pine Tree/Snowman $700k) + Info Sign $1k. Positions saved relative to plot.
- **Sell:** 50% of cost × color × weather. **Water:** Watering Can tool, tap a growing plant.
- **Hope Shop:** Hope Crate 100 (roll Rare+), Luck Potion 30, Grow Tonic 20 (finish one plant, Legendary or below).
- **Quests:** 6-step tutorial chain, then 3 daily from pool (plant 5, collect $X = 10 min income, 2 Thriving creatures, buy a Rare+, water 15×, like another zoo) → cash + 10 Hope each.
- **Social:** Visit button teleports to any plot; Like once/day per zoo (count on plot sign). Announce Mythical/Secret buys + Rainbow/Electric mutations server-wide (MessagingService cross-server for Secret). Leaderboards: leaderstats (Cash, Releases) + hub board Top 10 Total Earned (OrderedDataStore via DataService).
- **Data:** `cash, hope, totalEarned, releases, upgrades{}, biomes{}, padsOwned, padBiome[9], inventory{seeds{}, creatures[]}, placed[{id,species,pad,cell,rot,plantedAt,growTotal,color,weather}], decor[{id,kind,pad,cell,rot}], indexFound{}, released[{species,color}], daily{last,streak}, quests{day,list,progress}, tutorialStep, potions{luckUntil}, tonics, likes, likedToday{}, lastOnline, stockBought{restockId:{slot:qty}}`.
- **Remotes (RF):** BuySeed, PlaceItem, MoveItem, RemoveItem, SellCreature, Water, BuyPad, SetPadBiome, UnlockBiome, BuyDecor, BuyUpgrade, Release, ClaimDaily, ClaimQuest, UseHopeItem, BuyHopeItem, VisitPlot, LikeZoo, GoHome. **(RE, server→client):** DataChanged, StockChanged, WeatherChanged, Announce, Notify, OfflineEarnings.

## For Graphics
- **Layout:** hub at origin (circle Ø120, path `#E8D3A3`, fountain-tree centerpiece); 6 plots at radius 170, entrance facing hub. Plot = 3×3 pads (20×20 each) with 4-stud paths, owner sign + likes at entrance, locked pads show a hedge + price sign. Hub: Seed Shop stall (restock clock on roof), Hope Shop, Upgrade stand, World Reserve diorama (6 biome zones that fill with released creatures + name tags), leaderboard board.
- **Biome pad kits** (ground tile + fence style): Meadow `#7BD148`/`#FFD54F` · Pond water `#2EA6D9`, glass `#A7E8F5` (T 0.6), sand `#E8D3A3` · Desert `#F2C27B`/`#5E9E4A`/`#C8643B` · Canopy `#2F8F4E`, net `#D9D9D9` dome, bark `#6B4A2E` · Fungus `#3B5E3A`, Neon `#B57CFF`, stone `#4A4A5A` · Frost `#EAF6FF`/`#9FD8FF`/`#2E6B5A`. Build all 19 decor pieces from parts.
- **Creatures:** code-built part models, chunky and cute; stages Seed (dirt mound) → Sprout (2 leaves) → Bud (closed bulb in species color) → Grown (creature, idle bob + slow wander inside its pad, no collisions). Scale up a bit per rarity; Legendary+ get a particle aura in rarity color.
- **Rarity colors:** C `#B0B0B0`, U `#5BD35B`, R `#3BA7FF`, E `#A55BFF`, L `#FFB300`, M `#FF3D7F`, S `#1A1A1A` + rainbow glow.
- **Mutations:** Gold (Metal, `#FFC83D`), Diamond (Glass, `#BFF3FF`), Rainbow (hue cycle). Weather marks: Dewy droplets, Sunkissed orange glow, Frosted ice tint, Electric sparks, Starlit twinkles.
- **FX:** Thriving green sparkle ring + leaf particles; coin burst on jar collect; growth "pop" scale tween; release beam.
- **Weather/lighting:** day/night cycle 12 min (sky `#9EDCFF`, sunset `#FF9E5E`, night `#1E2A4A` + fireflies). Rain, heat haze (warm ColorCorrection), snow, lightning flashes, falling petals (Bloom), shooting stars (Starfall).
- **Visitors:** 2–6 simple blocky NPCs per plot (count scales with grown creatures), walk paths, cosmetic thought bubbles ("Wow!", "Thriving!").

## For UI
- **Top:** Cash + $/s, Hope, weather banner with timer. **Right-top:** restock timer. **Left bar:** Shop, Inventory, Build, Index, Upgrades, Release, Quests, Daily, Visit, Store (Robux). **Bottom:** quest tracker / tutorial arrow.
- **Screens:** Seed Shop (slots with rarity frame, price, qty, countdown, Instant Restock), Hope Shop, Inventory (seeds / creatures tabs), Build mode (grid ghost, green/red cell, Rotate, Move, Remove, biome picker per pad, decor list), Creature card (tap: rarity, stage + timer, $/s, mutations, needs ✓/✗ with **Fix** button opening Build filtered to the missing decor/biome, Water, Sell), Index (28 species grid, silhouettes until found, mutation badges), Upgrades, Release (pick eligible creature, show requirement + reward, confirm "They won't come back!"), Quests, Daily (7-day strip), Visit (list of server plots + Like), Store (passes + products), Offline-earnings popup, Settings (music/SFX toggle).
- **First 60 s:** arrow to the pad → "Plant your Sproutling" → stage timer → "Buy a Flower Bed" → Thriving banner → "Walk over your Tip Jar" → arrow to Seed Shop → goal card "Pad 2: $500".
- **Announcements:** top-center toast, rarity-colored ("PLAYER grew a RAINBOW Moonpetal Unicorn!"). Mobile: Scale sizing, big buttons, keep right-thumb zone clear.

## For Audio
- **Music:** cozy pastoral loop on plots; slightly busier market tune in hub; uplifting orchestral swell near World Reserve; upbeat track during weather events; soft lullaby-ish variant at night.
- **Ambience per biome** (play near pad): Meadow birds/bees, Pond bubbles, Desert wind, Canopy jungle calls, Fungus drips, Frost wind chimes.
- **Key sounds:** coin pop (jar collect), sprout bloop per stage, maturity chime, rarity fanfare (scales C→S), mutation sparkle, Thriving ✓ ding, buy/place thunk, rotate click, error buzz, water splash, restock bell, weather start sting, release whoosh + choir, daily claim jingle, creature idle chirps (pitch-varied per species).
