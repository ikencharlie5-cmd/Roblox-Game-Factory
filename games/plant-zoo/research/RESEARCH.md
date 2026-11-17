# Plant Zoo — R&D Research

## Summary
- **The reference game is Planet Zoo 2**, a PC/console zoo sim released Oct 13, 2026 (Steam app 3219030). It is not a Roblox game. Its core loop is: build habitats that meet each species' needs, then breed healthy, genetically diverse animals, then release them to Wildlife Reserves for Conservation Credits, which buy rarer animals and unlock higher Accreditation tiers. We copy that loop's *shape*, simplified for Roblox: grow, cross-breed, release for permanent bonuses, unlock new biomes.
- **What players love:** the animals (best-looking ever), the new **aquariums and aviaries**, mixing species in shared habitats, the **Thriving** state above normal welfare, and releasing animals into reserves (the "conservation gives it purpose" feeling). **What they hate:** fiddly menus, slow habitat micromanagement, a brush-style delete tool, no grid snapping, launch bugs and clipping, about 30 missing species from the first game, and an economy that is too easy. Steam reviews are **Mixed, 63%**, while critics gave 84–85.
- **The lesson for us:** keep the *meaning* (biomes, Thriving, breeding, release, a global market) and drop the *friction*. Use a grid build, one-tap biome tiles, a clear needs checklist with green checks, and no heaters, staff paths or filter networks. Planet Zoo 2's critics literally asked for building that "feels like play rather than work."
- **The Roblox money engine stays the same:** random-rarity seed restock, $/s income per creature, mutations from weather events, rebirth, daily rewards and a season pass. Planet Zoo 2 adds the *depth layer* on top: biome bonuses (Thriving ×1.5), cross-pollination with inherited "genes" (Size/Yield/Speed), "Release to the Wild" as a rebirth-style permanent bonus, Photo Quests, and a player market priced in a second currency (Seeds of Hope).
- **Our twist stays:** seeds grow into plant-creatures that live in biome exhibits (Greenhouse, Pond Tank, Canopy Aviary, Desert Dome...). Visitors pay cash, and released creatures feed a shared server "Wild Reserve" meter.

---

## Planet Zoo 2 — Gameplay Review

> Source: the Steam store, Frontier's site, critic reviews (PC Gamer, But Why Tho?, Gaming Trend, AltChar, GameDaily roundup), guide sites, Steam discussions and patch notes (links in Sources). We borrow **mechanics only**: no Frontier names, art, characters (FEN), UI or branding.

### Basics & popularity
- Made by Frontier Developments. It is the sequel to Planet Zoo (2019, app 703080) and was released **13 Oct 2026** on PC, PS5 and Xbox Series. It costs $49.99, or $64.99 for the Deluxe edition (+6 species). The soundtrack is sold as paid DLC.
- Metacritic 84–85 (14 of 15 reviews positive; PC Gamer gave the low score of 60). Steam: **Mixed, 63% positive (about 4k reviews)**. It was "Mostly Positive, about 70%" in launch week, then fell.
- Franchise mode offers 136 animals at top Accreditation (tier 5). Reviewers count about 30 base-game land species from the first game as missing.

### Modes
- **Career:** the player is a "conservation coordinator" who travels between scenarios and reserves. Each scenario starts with a **partly built zoo plus goals**, earning Bronze, Silver or Gold medals, and medals unlock more reserves and chapters. Mechanics are introduced one at a time. Critics liked that it teaches the tools. PC Gamer found the objectives mundane ("fix the debt", "small space").
- **Sandbox:** everything unlocked, with adjustable economy and welfare settings. Builds can be shared via the cross-platform Workshop.
- **Franchise (online):** a network of zoos and reserves, with one shared Conservation Credit (CC) wallet and separate cash per zoo. It starts at **tier 1 with 38 buyable species and 300 CC**, and a new zoo costs 100 CC. It includes a player animal market and **Community Challenges** (shared global conservation goals). It needs an online account and suffered connection bugs at launch.
- **Planet Hub:** a world map menu used to travel between sites and make research and conservation decisions.

### First hour (Career)
1. The first thing the player does is **drive a jeep through a reserve and photograph animals**, before building anything. This sets up the theme.
2. Then the first zoo scenario (partly built). Beginner advice: start with cheap animals (penguins, warthogs, meerkats), check each species' encyclopedia card (space, terrain, shelter, social group, food cost), and complete one habitat's welfare checklist until the animals reach **Thriving**.
3. Then set up the economy: donation bins next to education boards, guest plazas branching to small paths, staff zones, and a ticket price raised only after appeal is high.
4. Finally, the first Wildlife Reserve unlocks and the first release group is formed.

### Habitat building, terrain & scenery
- Barrier tool fences, then terrain/water/foliage brushes, then paint the ground type, then add shelter and enrichment. **Habitat sliders** (terrain %, plant coverage, water, temperature, space) show how well the habitat matches each species. Ready-made **habitat presets/blueprints** exist.
- New tools: smoother **paths** (finer increments, raised/stepped line builder, stamp tool), **free scaling + recolour** on all pieces (one piece serves several biomes), **live water editing**, a **foliage brush**, and **shell buildings** whose walls you can remove. Shops can sit anywhere on a plaza.
- 4 new + 5 returning scenery themes.
- Complaints: placing small objects is fiddly. Sliders lag (they update only after an animal walks around for about 3 min). The delete brush removes too much. Fences don't follow paths. **No grid**. Heaters and coolers clutter habitats. Premade habitats include non-native plants you must remove by hand. Tooltips don't explain items. PC Gamer asked for drag-an-area-to-build.

### Animal welfare, behaviour & Thriving
- Each species has needs for space, terrain, plants, water, temperature, shelter, social group size and sex ratio, enrichment, and food. These form a **welfare checklist**. Meeting all of it moves the animal from okay to **Thriving**, which gives **up to +20% donations** at that habitat, a better zoo husbandry rating, and recovers lost lifespan.
- The new **"animal brain"** uses routines (explore, rest, enrichment), reactions (seek shelter, flee), and moods (happy, sad, angry, scared) that **spread through a group**. Herds form shapes (defensive ring, migration line) and vote on a shared activity such as grazing. Animals also use ordinary scenery as enrichment.
- **Shared habitats** return: ground animals can live in aviaries alongside birds.

### Breeding & genetics
- Traits: **Vitality/Longevity** (added together from both parents), plus **Fertility/Immunity** (driven by genetic diversity). **Inbreeding** lowers fertility and immunity over generations. A **genealogy view** and a **"Compare Mates"** tool preview likely offspring.
- Birds and reptiles need **nests** (cavity, cup, water platform, mud). Some species breed only in a **season** (bad welfare can cost a year). Fish **shoals** grow as a group and split when full, with no genetics. **Contraception** prevents overpopulation, and community requests for auto-population management are being looked at.

### Conservation & Wildlife Reserves (the headline feature)
- There are **6 large reserve maps** (Great Rift Valley, Tanzania, Sumatra, Sweden, Scottish Highlands, Poland), each with 11–28 releasable species. They unlock through Career chapters.
- **Setup:** place a Research Outpost and Observation Platforms (ranges must not overlap), then **paint ecosystems** with an Ecosystem Brush until each reads *Established*, and remove pollution and **invasive plants**.
- **Release groups:** pick a species and group type (e.g. zebra: 1 unrelated male + 3 females), fill it from storage, and make sure the animals meet minimum **longevity, fertility and genetic diversity** with no illness or pregnancy. **Finalise (permanent, the animals never come back)**, then release.
- Released animals live, breed and migrate on their own. An ecosystem becomes **Flourishing** when all its *roles* (grazer, predator...) are filled. The number of roles counts, not the number of species. Some predators need prey released first.
- **Biodiversity stars** = Ecosystem rating + Research rating (camera traps, acoustic monitors).
- **Rewards:** Conservation Credits (CC). Payout rises with species rarity, endangered status, prime age, good genes and the animal's interest rating. **Quick Release** gives instant CC with no reserve. Players advise releasing over selling.
- Critics split: But Why Tho? called reserves the biggest improvement, while PC Gamer called them "a gamified terrain editor and photo space" that pulls focus from the zoo.

### Aquariums & aviaries (new)
- **Aquariums:** glass barrier walls, then a staff entrance that auto-fills the tank, then a **filter** linked by a network (needs power, and must exceed the needs set by tank volume and fish count), then **salinity** (fresh, salt or brackish; species can't mix across salinity), then temperature. Keepers clean the tank, mechanics repair cracks and leaks (or guests leave and you get fined), and dirty water causes disease. **Walk-through glass tunnels** let guests see sharks and rays overhead.
- **Aviaries:** barrier walls plus support poles, then a one-click generated mesh roof. A gap in the roof means birds escape (reported in reviews).

### Wildlife photography
- In reserves you drive a research jeep or walk. Some animals flee the engine noise, so you approach on foot. Photos are **scored on the animals shown, framing, distance and behaviour**, and earn small CC rewards. Reviewers loved moments like eye contact with an elephant, and praised the camera "splash" effect.

### Guests, shops, education, staff, economy
- Guest needs are hunger, thirst, energy, comfort, and **education**. **Heatmaps** show unmet needs, and **guest thoughts** show likes and complaints. Some guests have **diet restrictions** (no sugar, no wheat), so you need varied food. There are open, cabana-style shops and restaurants.
- Income comes from tickets (with an auto setting tied to appeal), shops, and **donation bins** (more after education boards or speakers, and Thriving habitats give +20%).
- Staff are keepers, vets, mechanics, caretakers and educators, assigned to work zones. Staff buildings no longer upset guests.
- **Zoo reputation stars** have 4 equal parts: Animal Welfare, Sustainability, Education and Visitor Experience. **Accreditation tiers 1–5** need multiple zoos and reserves at set star levels ("one 5-star zoo doesn't replace a second zoo"). Tiers unlock species, storage slots, reserve research tools and marketing campaigns.
- **Two currencies:** cash (buildings, staff) and CC (most animals, especially rare ones).
- Critique: the economy is **too easy**. PC Gamer ignored its zoo, even during escapes, and still profited.

### Online / Franchise trading
- Send an animal to storage, list it at your own CC price, and another player "adopts" it, or it returns to you if unsold. Only healthy adults can be traded (no juveniles, pregnant, old, sick or injured animals). Market supply varies by biome (Grassland 19 species vs Tundra 1 at launch). **Storage is capped** (250, and players complain about it). Community Challenges pool everyone's conservation toward a shared goal.

### What's new vs Planet Zoo 1
Fully aquatic species and aquariums with tunnels. Flying birds and aviaries. Wildlife Reserves with release groups, ecosystems and biodiversity. Reserve photography by jeep or on foot. The "animal brain" with herds and mood spreading. Grazing. The Thriving state. Nests and egg incubation. Overhauled paths and terrain with live water editing. Scale and recolour on everything. Cross-platform blueprints. Guest heatmaps and diet restrictions. The Planet Hub world map. Accreditation reworked around multiple sites. The 2-currency CC economy carries over, but is now tied to releases.

### Why Steam is Mixed (63%)
1. **Launch bugs:** crashes, animals clipping through glass, rocks and each other, animals running on water, camera stuck in hills, delayed mouse input, objectives that became impossible, and sold animals reappearing. Patches 1.0.5 through 1.0.9 are still fixing these.
2. **Missing animals:** more than 30 land species from the first game are gone (cheetah, grizzly, okapi, bison...), and players fear they will return as paid DLC. The new roster leans toward birds and fish.
3. **UI/menus:** "a tangled spider's web," with unreliable sorting and search and slow menus. The game is seen as *harder to use than Planet Zoo 1*.
4. **Micromanagement:** heaters and coolers, filter networks, too many guest education needs, and storage caps.
5. **Value:** about $70 with Deluxe edition, and it "feels like a beta."
- **Loved:** animal visuals, animation and sound. Aquariums and aviaries. Shared habitats. Reserves "giving purpose." Thriving. Building flexibility. Career scenarios.

### YouTube / community framing
Video and article titles focus on aquariums and aviaries, "animals steal the show," building showcases ("Let's Build"), and "how to get a 5-star reserve". Players want *showcase builds* and *star ratings to chase*. A long-running community request was "Planet Zoo 2 needs to be gamified." The audience wants clearer goals, which is exactly what Roblox does well.

---

## Turning Planet Zoo 2 into a Roblox plant zoo

Rule: every system below must be understandable in **one sentence** and reachable with **one or two taps**. Planet Zoo 2's biggest complaint is friction, so none of it comes with us.

| Planet Zoo 2 system | Our Roblox mechanic | Hook it feeds |
|---|---|---|
| Habitats + needs sliders | **Biome Exhibits.** Each exhibit is a grid pad you set to one biome (Meadow, Pond Tank, Desert Dome, Canopy Aviary, Fungus Cave, Frost Garden...). Each creature card lists 3 needs (biome, neighbour, decor) with ✓/✗. All 3 ✓ = **Thriving: ×1.5 $/s** and sparkle aura. | $/s, building |
| Terrain/foliage brushes, scaling | **Grid placement + "biome tiles"**: one tap paints a 4×4 tile. Decor has 3 sizes, not free scale. Rotate in 90° steps. Delete one item at a time (no brush). | Showing off |
| Welfare checklist → Thriving | Needs checklist above (always visible; no hidden lag). Neglect = no penalty, just no bonus (Roblox players hate losing stuff). | Retention |
| Animal brain / herds / moods | Cosmetic: 3+ creatures of one species in an exhibit **"flock"** (move together, idle emotes) and add **+10% herd bonus**. Mood emoji bubbles over creatures. | Collect sets |
| Shared habitats | **Combo Exhibits**: certain species pairs listed in the Index give a combo bonus (e.g. a pond creature with a canopy creature in a "Rainforest" exhibit = +25%). Discovering a combo shows a server announcement. | Discovery |
| Breeding + genetics | **Cross-Pollination Pot**: put 2 grown creatures in a pot, and after a timer you get a seed. 3 genes: **Size** (affects $/s and visual scale, which YouTubers love), **Yield** ($/s), **Speed** (growth). Child gene = parents' average ± random roll. A small chance of a **new hybrid species** (Index entry) or a **mutation**. "Compare" preview shows the gene range. No inbreeding penalty. | Mutations, gigantic creatures |
| Nests / seasonal breeding | **Bloom Season** weather event: cross-pollination is 2× faster and mutation odds are higher for 5 min every ~25 min (fits our server weather cycle). | Event log-ins |
| Contraception / pop. management | Not needed. Use slot caps per exhibit that rise with upgrades (paid slots = monetization). | Robux |
| Wildlife Reserves + release groups | **Release to the Wild** (our rebirth layer): pick creatures meeting a gene threshold (e.g. Size ≥ 3★) and release them. They're gone for good, and you get **Seeds of Hope** (2nd currency) + a **permanent +X% income** per species released. A shared **World Reserve** map (in the hub) fills with every player's released creatures, with your name tag on them. | Rebirth, social flex |
| Ecosystem roles → Flourishing | The Reserve has **roles** (Pollinator, Grazer, Glower, Guardian...). Filling all roles in a reserve biome = **Flourishing star + big permanent bonus**. You need *variety*, not 10 copies (straight from Planet Zoo 2's "roles, not species count" rule). | Collection breadth |
| Biodiversity / reputation stars → Accreditation | **Zoo Stars (1–5)** from 4 bars: Thriving %, Variety, Visitor Happiness, Released. Stars unlock new biomes, seed shop tiers and land. One clear "Next star" goal on the HUD. | Progression |
| Conservation Credits (2-currency) | **Seeds of Hope**: earned from releases, photo quests and daily login. Spent on rare seed packs, biome unlocks and market buys. Coins stay the main $/s currency. Can be sold as a Dev Product. | Economy, Robux |
| Quick Release | **Compost** button: instant small Seeds of Hope for unwanted creatures (replaces "sell"). | Clears inventory |
| Wildlife photography | **Photo Quests**: a camera tool. Daily quests like "Snap a Thriving Rainbow creature", "Snap 3 creatures in a flock" or "Snap a creature at night". Rated 1–3 stars on framing (is it centred and close?) and rarity. Rewards Seeds of Hope. Photos are saved to an in-game **Album** shown on your zoo's sign. Works in other players' zoos too, which encourages visiting. | Daily quests, visiting |
| Aquariums + tunnels | **Pond Tank** exhibit with a walk-through glass tunnel (a showpiece build). Water creatures (lily-fish, kelp-eels) only live in tanks. Skip filtration and salinity entirely. | Wow moment |
| Aviaries + net roofs | **Canopy Aviary**: auto dome roof generated over the exhibit pad. Flying seed-birds circle inside. | Visual variety |
| Guests, heatmaps, thoughts | NPC visitors with **thought bubbles** ("Want: Desert creature!", "Wow, Thriving!"). Fulfilling a wish = tip bonus. No hunger/thirst management. Optional cosmetic food stand that boosts tips. | $/s, readability |
| Donation bins + education boards | **Tip Jar** next to each exhibit (walk-over collect, like peers). **Info Sign** decor adds +5% tips (an education nod that takes no effort). | Collect loop |
| Ticket price / staff / mechanics | Cut. Staff = optional cosmetic "Gardener" helper pass (auto-waters, auto-collects) = **Game Pass**. | Robux |
| Franchise market (list in CC, adopt) | **Greenhouse Market**: list a creature for Seeds of Hope. A listing lasts 1 h, and the creature comes back if not bought. Only fully grown creatures can be listed. Use a two-sided confirm for direct trades too. Cross-server via MemoryStore. | Trading |
| Community Challenges | **Server/Global Goal**: "All players release 10,000 Desert creatures this weekend". Progress bar in the hub, everyone gets a reward. | Events, social |
| Storage cap (complaint) | Generous free inventory. Sell extra **storage** only as a convenience pass, never as a hard wall. | Avoid the hate |
| Career medal scenarios | **Zoo Challenges** (later update): timed mini-objectives on your own plot ("Get 3 Thriving exhibits in 10 min") for medals. | Replay |
| Missing-species backlash | Ship with a **full rarity ladder across every biome** (at least 5 species per biome), and add new species in updates. Never remove species. | Trust |

Keep from existing Roblox research (below): random-rarity seed restock, $/s per creature, mutations (Gold/Rainbow + weather), server weather every ~20–25 min, tile expansion, rebirth, daily reward, season pass, offline earnings, global rare-drop announcements.

**How it fits together:** Release to the Wild *is* our rebirth. Instead of "reset your cash for +50%", the player gives up top creatures for a permanent bonus and their name in the World Reserve. That is the conservation feeling, Roblox-style. Optionally keep a classic Cash Rebirth too, for the tier ladder (Ideas decides).

---

## Roblox Genre Research (proven hooks, kept from the first pass)

### Core loop & first 5 minutes (peers)
- **Grow a Garden:** start with an empty plot and a few coins, buy carrot seeds, plant, harvest, sell, and buy better seeds. Crops grow offline.
- **Build a Zoo:** a short tutorial (codes are locked until it's done), then buy eggs off a conveyor, place them on squares, they hatch into animals, and you walk near them to collect cash.
- **Steal a Brainrot:** buy units off a central conveyor and put them on pedestals for $/s.

### Rarity, income, upgrades
- Build a Zoo ladder: Common to Prismatic (Prismatic eggs under 1%). Conveyor upgrades go through 8 tiers and raise egg quality and mutation odds.
- Plants vs Brainrots: Rare to Secret. Water Bucket gives +25% growth speed, and rows hold 5 plants.
- Steal a Brainrot income bands: Common $1–5/s, Rare $25–100/s, Epic $250–1k/s, Legendary $3k–10k/s, Mythic up to $50k/s, God $200k+/s. That is roughly ×10 per tier.

### Mutations & events
- **Grow a Garden:** Gold ×20 (1%), Rainbow ×50 (0.1%). Weather mutations: Wet ×2, Chilled ×2, Sandy ×3 ... Shocked ×100, Celestial ×120.
- **Build a Zoo:** Gold, Diamond, Electric, Fire, Jurassic (up to about ×12). A meteor shower every 25 min, lasting 5 min, boosts mutation odds.
- Grow a Garden runs weekly updates, timed weather and admin events, and 6 daily season-pass quests. Codes are redeemed via a gear icon and a Codes tab.

### Rebirth
- **Plants vs Brainrots:** R1 $1M, R2 $50M, R3 $100M ... R9–11 $2B. Each also needs 2 named units. +50% money and +50% luck each time. Cash resets; plants, gear and eggs are kept.
- **Steal a Brainrot:** rebirth takes about 8–10 h and about $100k/s. Wipes units, gives a multiplier and more pedestals.

### Trading / visiting
- Grow a Garden has a huge trade economy, but also scams and real-money trading. Build a Zoo allows stealing, which is divisive. **Ours:** visit, like, photograph and trade with a two-sided confirm. No stealing.

### Monetization (peers)
| Item | Game | Price |
|---|---|---|
| Season pass premium (50 tiers) | Grow a Garden | 749 R$ (49 R$/tier skip, 1,699 R$ full) |
| Double Money | Steal a Brainrot | 800 R$ |
| Fast Steal | Steal a Brainrot | 400 R$ |
| Battle Pass | Steal a Brainrot | 800 R$ |
| VIP (+25% income, tag) | Plants vs Brainrots | 249 R$ |
| Cash pack ($100k) | Steal a Brainrot | 500 R$ |
| Extra slots, instant restock, seed packs | Grow a Garden | prices not found |

### Love / complain / YouTube
- **Love:** jackpot hatches and mutations, watching income climb, showing off bases, live events, and absurd or cute creatures.
- **Complain:** pay-to-win, stealing, scams, and "standard AFK game" depth (Kotaku, PCGamesN). Planet Zoo 2's depth layer (Thriving, genes, release) is our answer to "AFK depth".
- **YouTube titles:** "Hatching & GROWING GIGANTIC Animals", "Building the Biggest Zoo", "100 Days building the BEST ZOO". Creators want scale, giant sizes and rare reveals. The **Size gene** directly serves this.

### Competitors — what they do better
- **Grow a Garden:** global restocks, server weather, mutation stacking, offline growth, season pass.
- **Steal a Brainrot:** a central conveyor everyone watches; clear $/s tiers.
- **Plants vs Brainrots:** light action; rebirth goals that name the units needed.
- **Build a Zoo:** closest theme; conveyor tiers, tile expansion, meteor events, creative building.

---

## For Ideas
- **Hook (first 60 s):** a free starter seed sprouts on screen within 15 s into a cute plant-creature. The first visitor walks up, shows a "Wow!" bubble and pays, a coin pop plays, and the needs checklist shows 2/3 ✓ with an arrow to "Place a Meadow tile" for 3/3. **Thriving!** Sparkles and ×1.5 income. That teaches the depth layer in second 45. (Planet Zoo 2 opens with photographing animals; we can make the first quest "Snap your first creature" for a free seed.)
- **Planet Zoo 2 ideas to take:** biome exhibits plus Thriving, combo/shared exhibits, cross-pollination genes (Size/Yield/Speed), Release to the Wild + World Reserve with ecosystem roles, Photo Quests, Zoo Stars that unlock biomes, a second currency (Seeds of Hope), a market with "adopt" listings, community goals, and a showpiece tunnel tank and aviary dome.
- **Copy (Roblox mechanics are fine):** timed seed restock, $/s per species, ×~10 per tier, Gold/Rainbow-style mutations, server weather every ~20–25 min, tile expansion, rebirth, daily quests feeding a pass, offline earnings.
- **Do NOT copy:** the names "Planet Zoo", "Frontier", "FEN", "Conservation Credits", "Franchise", "Accreditation", "Zoopedia", "Planet Hub", or Frontier's real reserve names. Also no Grow a Garden, Brainrot or Build a Zoo names, and no signature mutation names ("Voidtouched", "Bloodlit"). No logos, art, UI or music from any of them. Use our own words: Seeds of Hope, Zoo Stars, World Reserve, Plantpedia/Index.
- **Avoid (lessons from Planet Zoo 2's Mixed reviews):** nested menus, brush deletes, freeform placement without a grid, hidden or slow-updating stats, penalties for neglect, storage walls, launch bugs (the Checker should test exhibits and creature pathing for clipping), and releasing with thin species lists. Also avoid stealing, a pay-to-win feel, and a long tutorial.

## For Gameplay
- **Rarity ladder:** Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 0.9%, Mythical 0.09%, Secret 0.01% in the base shop. Luck from rebirth, release and upgrades shifts these odds.
- **Income:** base $/s ≈ 10^(tier index) bands (Common 1–5 ... Legendary 3k–10k). Final $/s = base × Size gene × Yield gene × mutation × Thriving (1.5) × herd (1.1 at 3+ of a species) × combo (1.25) × permanent release bonus. Multipliers *multiply* here; use additive mutation stacking if numbers get out of hand.
- **Needs checklist (replaces habitat sliders):** each species has `biome`, `neighbourTag` (e.g. "near water tile" or "next to a Pollinator"), and `decorTag` (e.g. "rock", "log"). Check on place/move server-side, cache the result, and update instantly. Planet Zoo 2's 3-minute slider lag was a top complaint.
- **Genes:** Size, Yield, Speed, each 1–5★ (store as a 0–100 float; ★ = floor/20+1). Child = avg(parents) + random(-8, +12) (a slight upward drift rewards breeding). Cross-pollination pot timer 2–10 min by rarity. Hybrid chance 5% if the pair is a listed combo, and mutation chance 2% (×2 during Bloom Season).
- **Release to the Wild:** eligibility is a grown creature with average genes ≥ 3★. Reward: Seeds of Hope = base(rarity) × gene avg. Permanent +2% income per *new species* released (the first one counts most) and +0.5% for repeats. Reserve roles: 4–6 roles per reserve biome; filling all = Flourishing star (+10% permanent). Planet Zoo 2 rule to copy: roles count, not quantity.
- **Zoo Stars:** 4 bars (Thriving %, Species variety, Visitor happiness, Releases), each 25%, then 1–5★. Star thresholds unlock biomes and land tiles. Show "next star needs: ..." with the weakest bar highlighted (copy Planet Zoo 2's "fix your lowest quarter" logic).
- **Photo Quests:** the client camera tool raycasts and checks that the target creature is within the view frustum centre (≤ 20% from centre = framing ★), distance ≤ 25 studs (★), and is Thriving, rare or flocking (★). The server re-validates the target ID and position. Use 3 rotating daily quests.
- **Market:** MemoryStoreService SortedMap for listings (1 h expiry). Escrow the creature on listing, and on buy run an atomic UpdateAsync, then transfer via DataService. Two-sided trade: 3 s countdown and an ownership re-check. ([MemoryStore docs](https://create.roblox.com/docs/cloud-services/memory-stores))
- **Global/community goal:** MessagingService or a MemoryStore counter incremented in batches every 30 s.
- **Offline growth:** save `os.time()`, compute elapsed time on join, cap at 8 h ([DevForum offline gardening](https://devforum.roblox.com/t/going-about-to-create-an-offline-gardening-system/391833)).
- **Placement:** grid snap, client preview, server validation, positions saved relative to the plot ([Grid placement](https://devforum.roblox.com/t/how-to-make-a-grid-placement-system/2723673), [Placement saving](https://devforum.roblox.com/t/placement-system-saving/334078)).
- **Global restock:** seeded RNG from `os.time() // 300` ([GaG tutorial series](https://devforum.roblox.com/t/how-to-make-roblox-grow-a-garden-game-tutorial-series/3769116)).
- **Rebirth (if a classic cash rebirth is kept too):** $1M, then $50M, then $100M ..., +50% money each time.

## For Graphics
- Style: bright, low-poly, cartoony greenhouse zoo. Planet Zoo 2's appeal is **lively creatures**: idle animations, herds moving together, mood emotes. Spend effort on creature animation over map detail.
- **Biome exhibit kits** (each a tile colour plus 3 decor pieces plus a fence style), using Planet Zoo 2's "one piece, recoloured, many biomes" idea to save parts:
  - Meadow: ground `#7BD148`, flowers `#FFD54F`
  - Pond Tank: glass `#A7E8F5` (Transparency 0.6), water `#2EA6D9`, sand `#E8D3A3`
  - Desert Dome: sand `#F2C27B`, cactus `#5E9E4A`, terracotta `#C8643B`
  - Canopy Aviary: leaf `#2F8F4E`, net `#D9D9D9`, bark `#6B4A2E`
  - Fungus Cave: moss `#3B5E3A`, glow `#B57CFF` (Neon), stone `#4A4A5A`
  - Frost Garden: snow `#EAF6FF`, ice `#9FD8FF`, pine `#2E6B5A`
- **Showpieces:** a walk-through **glass tunnel** under the Pond Tank, and an auto-generated **dome net** over the Canopy Aviary.
- **Thriving FX:** soft green sparkle ring + small leaf particles. Flock: creatures within 6 studs drift together.
- **World Reserve** (in the hub): a big natural diorama with a zone per biome that fills up with released creatures and floating name tags. Each zone gets greener and fuller as roles fill (Invalid, then Established, then Flourishing visuals).
- Rarity colours: Common `#B0B0B0`, Uncommon `#5BD35B`, Rare `#3BA7FF`, Epic `#A55BFF`, Legendary `#FFB300`, Mythical `#FF3D7F`, Secret `#1A1A1A` + rainbow glow.
- Base palette: grass `#7BD148`, path `#E8D3A3`, wood `#A8673A`, sky `#9EDCFF`, sunset `#FF9E5E`, night `#1E2A4A` (with fireflies).
- Map: central hub (seed shop, market, World Reserve, photo board) and a ring of 6–8 plots.
- **QA note from Planet Zoo 2's reviews:** clipping is the #1 immersion breaker. Keep creatures on simple wander paths inside exhibit bounds, with no physics collisions between creatures.

## For UI
- **Left bar:** Shop, Inventory, Index, Build, Breed (Pot), Release, Market, Quests. **Top:** coins, Seeds of Hope, Zoo Stars. Weather/event banner with a timer.
- **Creature card** (tap a creature): rarity, genes as 3 star rows, $/s, **needs checklist ✓/✗** with a one-tap "fix" button that opens Build filtered to the missing tile or decor. Planet Zoo 2's critics wanted fewer menus; the "fix" button is our answer.
- **Breed screen:** two slots, a preview of the gene range (like a "compare mates" preview), and a timer. Show a hybrid chance if it's a known combo.
- **Release screen:** pick creatures, see the reward and the permanent bonus, then a big "Release to the Wild" button with a confirm ("They won't come back!"), then a cutscene of the creature walking into the World Reserve.
- **Zoo Stars panel:** 4 bars, with the weakest highlighted and a "How to improve" tip.
- **Photo mode:** a full-screen viewfinder with a framing overlay, live ★ indicators, and a shutter flash plus splash effect (PC Gamer singled out the camera splash as a nice touch). The Album grid sits in the Index.
- **Market:** listing grid with rarity/biome filters that **work reliably** (broken sorting was a Planet Zoo 2 complaint). Show 10 listings per page.
- Mobile: Scale sizing, UIAspectRatioConstraint, big touch targets, right thumb area clear ([Roblox UI/UX docs](https://create.roblox.com/docs/production/game-design/ui-ux-design)).
- Season pass: Free and Premium tracks, with 6 daily quests (mix in Photo Quests).
- Global announcement: "PLAYER bred a SECRET ___!" or "PLAYER's reserve is Flourishing!"

## For Audio
- Planet Zoo 2's audio is praised for **creature sounds**: every species has its own calls, and moods change them. For us: give each creature a short, pitch-varied "chirp" or "bloop" call on idle, a happy trill when it becomes Thriving, and a group chorus when flocking.
- Music moods (use original Creator Store tracks; do not use Planet Zoo 2's soundtrack): calm pastoral or orchestral-light for building, a nature ambience bed (birds, insects, water) that changes per biome (bubbles in the Pond Tank, wind in Frost, drips in the Cave), an uplifting swelling theme in the World Reserve, and energetic music for weather events.
- Signature sounds: coin pop on collect, a sprout "bloop" per growth stage, a maturity chime, a rarity-scaled fanfare, a camera shutter plus pop on photos, a soft "release" whoosh with a choir swell, and a gentle ✓ ding when a need is met.
- Creator Store: https://create.roblox.com/store/audio (search "pastoral", "nature ambience", "underwater ambience", "cozy farm", "uplifting orchestral").

## Sources
### Planet Zoo 2
- https://store.steampowered.com/app/3219030 (Steam store: features, modes, review score, price)
- https://en.wikipedia.org/wiki/Planet_Zoo_2
- https://www.planetzoogame.com/2/game-modes
- https://www.planetzoogame.com/2/features
- https://www.planetzoogame.com/2/news/2026-07-16/creature-feature-animal-brain
- https://www.planetzoogame.com/2/news/2026-07-23/behind-scenes-going-underwater
- https://www.pcgamer.com/games/sim/planet-zoo-2-review/ (60/100)
- https://butwhytho.net/2026/10/planet-zoo-2-review-frontier-developments/ (8/10)
- https://gamingtrend.com/reviews/planet-zoo-2-review/ (85)
- https://www.altchar.com/reviews/planet-zoo-2-review-a-better-zoo-missing-some-old-friends-aQgna1j2K4sr
- https://www.altchar.com/game-news/planet-zoo-2-sandbox-deep-dive-shows-off-aviaries-aquariums-and-an-overhauled-building-system-a2kPF9T43MZH
- https://gamedaily.com/games/planet-zoo-2-review-roundup
- https://opencritic.com/news/38085/a-week-after-launch-planet-zoo-2-deemed-completely-unplayable-
- https://www.metacritic.com/game/planet-zoo-2/
- https://steamcommunity.com/app/3219030/reviews/
- https://steamcommunity.com/app/3219030/discussions/0/567048404944873106/ (Mixed-reviews thread)
- https://steamcommunity.com/app/3219030/discussions/0/587314487387944763/ ("Disappointed entirely" thread)
- https://afktimes.com/en/planet-zoo-2/guides/wildlife-reserves/
- https://allthings.how/planet-zoo-2-game-modes-explained-career-sandbox-and-franchise/
- https://allthings.how/planet-zoo-2-best-beginner-tips-to-get-your-first-zoo-running/
- https://theplanetzoo2.wiki/guides/conservation-credits-guide/
- https://planetzoo2animals.com/franchise-mode
- https://www.playnews.gg/en/guides/planet-zoo-2-accreditation-level-how-to-level-up-and-unlock-more-animals
- https://www.playnews.gg/en/guides/how-to-build-an-aquarium-in-planet-zoo-2-walls-filtration-salinity
- https://thegameswiki.com/planet-zoo-2/wiki/breeding-and-nesting
- https://wikily.gg/planet-zoo-2/known-issues
- https://pcgamer.com/games/sim/planet-zoo-2s-gameplay-reveal-shows-how-to-manage-the-new-aquariums-and-aviaries/ (title reference)
- https://primagames.com/gaming/how-to-build-a-five-star-wildlife-reserve-in-planet-zoo-2 (title reference)
- https://reddit.birdcat.cafe/r/PlanetZoo/comments/1gb2i3k/planet_zoo_2_needs_to_be_gamified (title reference)
### Roblox genre & techniques
- https://en.wikipedia.org/wiki/Grow_a_Garden
- https://www.pockettactics.com/grow-a-garden-mutations
- https://www.sportskeeda.com/roblox-news/grow-garden-season-1-pass-all-tier-rewards-premium-price
- https://www.gamezebo.com/walkthroughs/is-grow-a-garden-f2p-friendly/
- https://www.sportskeeda.com/roblox-news/grow-garden-music-list
- https://www.ofzenandcomputing.com/build-a-zoo-roblox-guide
- https://deltiasgaming.com/?p=348789 (Build a Zoo beginner guide)
- https://deltiasgaming.com/?p=347541 (Build a Zoo mutations)
- https://rowatcher.com/games/8066283370/build-a-zoo
- https://earnaldo.com/blog/build-a-zoo-vs-grow-a-garden (low trust)
- https://www.sportskeeda.com/roblox-news/all-seeds-plants-vs-brainrots-cost-rarity
- https://www.pockettactics.com/plants-vs-brainrots-rebirth
- https://deltiasgaming.com/?p=392035 (Plants vs Brainrots VIP)
- https://games.gg/plants-vs-brainrots
- https://www.playnews.gg/en/guides/steal-a-brainrot-roblox-the-complete-strategy-rebirth-and-tier-list-guide-for-july-2026
- https://devforum.roblox.com/t/going-about-to-create-an-offline-gardening-system/391833
- https://devforum.roblox.com/t/how-to-make-roblox-grow-a-garden-game-tutorial-series/3769116
- https://devforum.roblox.com/t/how-to-make-a-grid-placement-system/2723673
- https://devforum.roblox.com/t/how-to-use-placement-service/698753
- https://devforum.roblox.com/t/creating-a-furniture-placement-system/205509
- https://devforum.roblox.com/t/placement-system-saving/334078
- https://create.roblox.com/docs/production/game-design/ui-ux-design
- https://create.roblox.com/docs/cloud-services/memory-stores
- https://www.youtube.com/watch?v=Q8oVezLKbYw (title reference)
- https://www.youtube.com/watch?v=lXHH6D6356g (title reference)
- https://www.youtube.com/watch?v=HFNE4i9yU_M (Build a Zoo beginner guide video)
