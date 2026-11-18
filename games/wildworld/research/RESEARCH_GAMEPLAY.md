# RESEARCH — Gameplay (Wildworld)

R&D Gameplay, Chiken Studios. Covers mechanics and systems only (art, UI and audio belong to the other R&D docs). MVP scope = master-spec section 24.

## Summary
- **Make beautiful parks the best strategy.** In Slime Rancher, cramming animals into tight pens earns the most, so players optimize away the charm. Wildworld should multiply visitor income by habitat rating (0.5x–2.0x) and by the rarity and mutation of each creature, so a well-built, well-decorated habitat always out-earns a cramped one.
- **Creature AI: server state machine, client motion.** Use anchored, non-Humanoid creatures (AnimationController). The server picks a goal every 3–8 s per creature, staggered, and replicates only the goal and state as attributes. Clients tween or lerp between goals, run idle animations, and drop to simple motion (or none) beyond 150 studs. Avoid PathfindingService inside habitats, which are open flat areas.
- **Genetics: 2-allele genes, readable rolls, then mutations.** Use 4 MVP genes (color, pattern, size, glow) with dominant and recessive alleles that are hidden until bred. Mutations roll on top: Golden, Albino, Crystal for the MVP, with Glowing as a fourth for safety. Show odds as ranges, never as promises. A "Heirloom" mechanic (a mutated parent raises the mutation chance) makes selective breeding worth doing.
- **Retention follows the Grow a Garden and Build a Zoo model.** Passive income keeps running while away (capped at 2 h), timed breeding and egg reveals, a food shop that restocks every 5 min, weather and wild events every 10–15 min that boost discovery and mutation odds, dailies, and an encyclopedia completion goal. Benchmark target: D1 20–28%, D7 12–18% (tycoon/incremental genre).
- **First 60 seconds:** spawn on your own plot, tap the starter egg, it hatches into a creature that runs to the player and plays a happy animation, feed it, and the first coins pop from a visitor. Show no menus before the first creature exists. Monetization stays cosmetic or convenience only, as the spec requires: no paid breeding luck.

---

## 1. Reference games (borrow mechanics only)
| Game | Hook to borrow | Lesson |
|---|---|---|
| Build a Zoo (Roblox) | Animals sit on plot podiums and earn cash per second. Food levels them up. Mutations multiply income (2x/3x/5x/10x/12x tiers). Weather events (3–5 min) apply mutations to anything on your plot. Food shop restocks every 5 min. | Weather events make "be online now" exciting. Mutation = income multiplier, so a rare creature feels valuable immediately. |
| Grow a Garden (Roblox) | Things grow while away. Mutations from weather and items, with many combinations (e.g. wet + chilled = frozen). Gold 1%, Rainbow 0.1%. Shipped updates every 5–7 days. ~22M peak CCU. | Combination mutations are endlessly shareable. Rarity screenshots drive virality. Sessions work at 2 minutes or 2 hours. |
| Adopt Me | The first action is caring for a pet. Combining 4 fully grown copies makes a glowing "Neon" version; 4 Neons make a "Mega". | Hand over a creature in the first minute. A "combine 4 to upgrade" sink gives duplicates value. |
| Dragon Adventures | Adults only can breed. Co-breeding with another player's creature gives 50/50 species. Mutations change looks. Free daily wheel spin, with extra spins for Robux. | Co-breeding with a friend is a great social hook for after the MVP. |
| Slime Rancher | Creatures always look happy. Merging types into a "largo" doubles output but adds risk, and wrong mixes give a funny bad result. | Reward experimentation, and make failures funny instead of punishing. Avoid one dominant species with a flat price. |
| Pet Simulator 99 | Luck passes (275/800 R$), +pets slots (375), auto (175–350), VIP (400). | Shows what's possible, but luck passes conflict with the spec's no-pay-to-win rule. Use the slot, auto and cosmetic patterns only. |

## 2. Creature AI that feels alive cheaply
**Architecture**
- Creature model: anchored parts welded to an anchored root PrimitivePart, with an `AnimationController` + `Animator`. **No Humanoid** and no physics.
- **The server owns the state** (`CreatureService`), one record per creature: `{id, state, goalPos, stateEndsAt, needs}`. The server never moves parts every frame.
- **The server ticks the AI on a single Heartbeat loop with a budget:** at most 20 creature decisions per frame, so 100 creatures refresh in about 5 frames. Each creature schedules its next decision with `nextThink = now + random(3, 8)`.
- **Replication:** write `State` (string), `Goal` (Vector3) and `Speed` as Attributes on the creature model. Clients listen with `GetAttributeChangedSignal` and move the model toward the goal with `CFrame:Lerp` in RenderStepped, sampling ground height with one downward raycast on arrival or every 0.25 s. This uses about 3 values per creature every 3–8 s, effectively zero bandwidth.
- **The server also moves its own copy of the position** (`pos += dir*speed*dt` checked at think time, i.e. dead-reckoned), so feeding, capture and visitors can use positions without a physical model.
- **LOD:** the client skips movement for creatures more than 150 studs from the camera (snap to goal on re-entry) and only plays idle animations within 80 studs. Wild creatures in the forest only "think" while a player is within 120 studs.
- **No PathfindingService in habitats.** Pick goals as random points inside the habitat polygon. Before committing, raycast or check against fences (the bounds check is enough when the habitat is an axis-aligned rect or a list of placed cells). Use pathfinding only for the wild biome if needed, at most once per goal.

**State machine (weights driven by needs + personality)**
`Idle (2–5s) → Wander → Eat (walk to food station, 4s) → Drink → Sleep (night or Energy<25, 20–40s) → Play (toy or partner, 5s) → Socialize (approach a compatible creature within 12 studs, both face and emote) → ReactToPlayer (owner within 10 studs: hop + heart; shy: back away 6 studs)`
- Choose with weighted random: `w = base * personalityMult * needUrgency`. Hunger urgency = `(100-Hunger)/25`, squared once Hunger is below 30.
- Personality multipliers: Playful ×2 Play; Lazy ×2 Sleep/Idle, ×0.5 speed; Curious ×2 Wander + approaches newly placed decor; Shy ×0 ReactToPlayer-approach (flees instead); Social ×2 Socialize; Energetic ×1.5 speed.
- **Fake-life touches that cost almost nothing (client-only):** random blink and ear or tail wiggle every 2–6 s, a look-at toward the nearest player head within 15 studs, small hop arcs while walking (sine Y offset, 0.3 studs), heart, Zzz or food emoji BillboardGui on state change, a squash-stretch when stopping. These do more for "alive" than smarter AI.

**Needs (gentle, never lethal)**
- Hunger −1 per 30 s, Energy restored by sleep, Happiness = weighted avg(Hunger 30%, Habitat rating 40%, Social 15%, Enrichment 15%).
- Floor: needs can't drop below 20 while the owner is offline. No death, no running away. An unhappy creature only earns less (×0.5) and looks sad.

## 3. Park building on plots
- **Plots:** 6–8 plots per server (match the server size to 8 players), each **128×128 studs**, with plot-relative CFrames. Assign the plot on join and free it on leave.
- **Grid:** 4-stud cells, snap = `math.floor(v/4+0.5)*4` in plot-local space. Rotate in 90° steps (R key or a mobile button), with a 15° toggle for decor only. Disable fine placement for gameplay objects.
- **The client previews; the server validates:** the client sends `{itemId, cellX, cellZ, rot}` only. The server checks that the player owns the plot, the item is unlocked and affordable, the footprint is inside bounds, the occupancy grid is free (keep a `cells[x][z]` table server-side, so no physics query is needed), and the per-plot cap is not exceeded (MVP: 300 objects). Then it spawns the object from ServerStorage.
- **Save format:** `{v=1, items={{id,"x","z","r"}...}}`, plot-relative so the park loads on any plot slot. About 20 bytes per item, so 300 items ≈ 6 KB, well under DataStore limits.
- **Habitats:** a "Habitat" is formed by a closed fence loop. MVP shortcut: place a **Habitat Pad** item (12×12, 20×20 or 28×28 cells, auto-fenced with a gate) and score everything inside it. This avoids flood-fill enclosure detection for the MVP.
- **Habitat rating (0–100) → income multiplier 0.5x–2.0x:**
  - Space 25 (cells per creature vs species need, e.g. Lumibun 9 cells, Mossback 25)
  - Biome match 20 (count of required tags present: e.g. forest = tree, grass, rock)
  - Food + water 15 (≥1 of each in range)
  - Shelter 10
  - Enrichment 15 (toys or decor, diminishing: 5 + 4 + 3 + 2 + 1)
  - Social 15 (group size within the species' preferred range)
  - Show a checklist with a "+X if you add ___" hint. This is the single best teacher of the build loop.
- **Visitors (cheap):** at most 8 visitor NPCs per plot, client-side only (purely cosmetic) and following placed path cells. Income is computed server-side as a formula, not from simulated visitors:
  `coinsPerMin = Σ habitats (Σ creature baseValue × rarityMult × mutationMult) × habitatMult × parkRatingMult`
  Park rating = avg habitat rating + decor/path/shop bonus, mapped to tiers Poor <20, Developing <40, Good <60, Excellent <75, World-class <90, Legendary ≥90, each giving +0/5/10/20/35/50% income.
- **Offline earnings:** 50% rate, capped at 2 h. Show a "While you were away: +X" popup on join (a strong return hook).

## 4. Genetics & mutations
**Genes (MVP: 4 genes, 2 alleles each, stored as a string like "Cc|pP|Ss|gg")**
| Gene | Dominant | Recessive | Visible effect |
|---|---|---|---|
| Color | C = base species palette | c = alt palette (each species defines 2) | body Color3 |
| Pattern | P = plain | p = spots/stripes | decal or part toggle |
| Size | S = normal | s = small (×0.85) | scale; mixed Ss = ×0.95 (incomplete dominance → "mixed traits") |
| Glow | G = none | g = soft glow marks | Neon material on marking parts |
- Inheritance: the child gets one random allele from each parent per gene (Mendelian). Recessives stay hidden in carriers, so "two normal parents had a spotted baby!" moments happen naturally.
- Random variation: hue jitter of ±6% and size jitter of ±3% per child, so no two babies are identical (the Slime Rancher "every one is unique" feel).
- Parents' **known** genes are revealed after the parent has bred once or by using a "Gene Scanner" (Research Points), which gives a reason to spend Research Points.
- **Breeding UI odds:** show each possible outcome as a percentage computed from known genes, and "?" for unknown. Never show the mutation result beforehand.

**Mutations (rolled after genes, server-side, configurable per species)**
| Mutation | MVP? | Base chance | Income mult | Visual |
|---|---|---|---|---|
| Golden | yes | 2% | ×3 | gold Color3 + Metal material + sparkle |
| Albino | yes | 1.5% | ×2.5 | white body, pink eyes |
| Crystal | yes | 0.5% | ×5 | 3–5 translucent Glass spikes on the back |
| Glowing | stretch | 1% | ×2 | PointLight + neon marks (overrides g) |
| Giant | later | 0.3% | ×4 | scale ×1.4, collision-safe |
| Celestial | later | 0.02% | ×15 | starry texture + aura |
- **Heirloom rule (makes selective breeding worth it):** each parent carrying mutation M multiplies M's chance by ×5 (both parents: ×15, capped at 35%). This gives a real breeding goal ("chase a Crystal line") that is deterministic enough to feel like skill.
- **Bonus modifiers (all free and earnable):** a habitat rating ≥80 adds ×1.25 to all mutation chances. A "Rainbow Shower" weather event (5 min, every 40–60 min) gives ×2.
- Combinations: allow at most 2 mutations per creature (e.g. Golden + Crystal = "Gilded Crystal" ×12). Roll a second mutation only if the first hits (chance /4). Golden + Albino are exclusive (color overrides).
- **Timers:** egg incubation 2 min (common) / 5 min (uncommon) / 10 min (rare) for the MVP. Breeding cooldown 5 min per parent. Growth stages Baby → Adult take 10 min of online time or 3 feedings (skippable by feeding, which is the care loop). Short timers keep the first session exciting; lengthen them later.
- **Duplicates:** the Adopt Me–style "Bond" mechanic, where combining 3 of the same species and mutation makes an "Elder" cosmetic with ×1.5 value. Post-MVP.

## 5. Capture (MVP forest)
- Wild creatures spawn at 6–10 spawn nodes, with at most 12 alive. Respawn 45 s after a capture. Rarity weights: Common 70 / Uncommon 22 / Rare 7 / Epic 1. Night-only and rain-only spawns come post-MVP.
- **Interaction (not a single click):** 1) approach (a crouch or slow walk halves the scare radius from 20 to 10 studs; shy creatures flee), 2) toss bait (the creature walks to it, eats 3 s, and its trust meter rises), 3) hold the **Calm Net** while a ring shrinks and release in the green zone (green width = 35% common, 20% rare). Success rate = zone hit × trust bonus. A miss scares the creature (it runs 15 studs) but never despawns it immediately, and the player gets 2 retries.
- Pity: guarantee a successful catch after 4 failures on the same species (the spec says rare creatures should not be impossible to get).
- First discovery of a species: full-screen card showing name, rarity and encyclopedia entry, plus 25 Research Points and coins.

## 6. Retention loops (by time scale)
- **Seconds:** creature reactions, coin pops from visitors, building placement feedback.
- **Minutes:** egg timers (2–10 min), shop restock every 5 min (food + 1 rare decor slot), weather every 10–15 min (Rain = shy spawns ×2 in the forest; Sunny = +10% income; Rainbow Shower rare).
- **Session:** daily quests ×3 (feed 10, breed 1, catch 2 → coins + Research Points), park rating tier-ups, encyclopedia percentage.
- **Return:** offline earnings popup, eggs left incubating ("Your egg hatched while you were away!"), 7-day login streak (day 7 = random mutation egg), weekly limited decor.
- **Social:** visit parks (a "Like" button gives the owner +1 rating point per unique visitor per day, capped at 20), a "Top Parks" board in the hub, and visible titles ("Crystal Breeder"). Trading comes after the MVP and must be a server-validated two-sided confirm.
- Fix the content wall: tycoon D30 crashes if nothing is new after about 2 weeks, so plan new biomes and species each update (Grow a Garden shipped every 5–7 days).

## 7. Monetization (cosmetic or convenience; spec-compliant)
| Product | Type | Robux | Notes |
|---|---|---|---|
| Starter Pack (theme decor + 1 cosmetic creature hat + 2k coins) | Dev product, one-time, flagged | 99 | impulse price, show after the first habitat |
| Extra Incubator (+1 simultaneous egg) | Pass | 199 | convenience; free players have 2 |
| Park Expansion (+64 studs of plot width) | Pass | 249 | more building space, not power |
| VIP (chat tag, gold name, VIP decor set, +1 daily quest reroll) | Pass | 399 | the "anchor" mid-tier pass |
| Auto-Feeder (food stations auto-refill) | Pass | 149 | convenience |
| Decor theme packs (Crystal Cave, Candy, Sky) | Pass each | 149–299 | the main long-term earner |
| Creature cosmetic skins (hats, ribbons; no stats) | Dev product | 49–99 | |
| Instant Hatch (finish one egg now) | Dev product | 15–49 by remaining time | the common "skip timer" product |
| Coin packs | Dev product | 49 / 149 / 449 | |
- **Do NOT sell** mutation-chance boosts, exclusive stat creatures, or capture guarantees. Pay-to-win drives roughly 30% player drop-off. Passes above 500 Robux sell poorly unless the value is obvious. Premium Payouts and Creator Rewards favor 10+ minute sessions, which this design gets from timers.

## 8. First 60 seconds (hook script)
1. **0–5 s:** spawn standing on your own empty plot (with a glowing name sign). A pulsing starter egg sits on a Habitat Pad. One arrow points to it with the prompt "Hatch!". There is no other UI yet.
2. **5–15 s:** tap the egg. It wobbles, cracks and pops, and a rarity banner appears. The starter is a random pick from 3 commons (Lumibun, Mossback, Emberfox). **Force a Golden mutation on the starter's first sibling egg** (see step 5) so the "wow, a mutation" moment happens in session 1.
3. **15–30 s:** the creature runs to the player, hops and shows a heart. Prompt "Feed it" points to the food bowl. Feeding plays a munch animation, raises happiness, and the creature does a happy spin.
4. **30–45 s:** a visitor walks in, looks and drops +25 coins (a coin fountain). The HUD fades in with coins only. Prompt "Build: place a tree (+habitat rating)". The habitat rating bar visibly jumps and income ticks up.
5. **45–60 s:** quest card: "Catch a wild friend in Greenleaf Forest", with a gate arrow. Your creature follows you there. The first catch's partner unlocks breeding, and that first breeding egg is the guaranteed Golden (the hook for the next 10 minutes).
- Rule: never show the full menu bar until the player has 2 creatures. Introduce one new button per goal achieved.

---

## For Ideas
- Pitch line: *"Hatch, catch and breed glowing creatures, then build them the park they deserve."* The ultimate goal (from Charlie's brief) is the loop: catch, breed for a mutation, build a habitat, show it off to visitors.
- MVP five creatures: Lumibun, Mossback, Emberfox, Pebblehorn, Bloomtail. All are land creatures, so Aquafin (water tech) and Glimmerwing (flight) stay out of the MVP. Each needs 2 color alleles, a pattern part, and marking parts for glow.
- MVP mutations: Golden, Albino, Crystal (Glowing as a stretch goal). These are all cheap color, material or part changes.
- Keep the economy to Coins + Research Points only. One biome (forest). Use habitat pads instead of freeform fence enclosures.

## For Gameplay
- Build order (Charlie's priority): 1) CreatureService (anchored + AnimationController, server state machine with budgeted ticks, attribute replication, client lerp + LOD), 2) PlotService + PlacementService (4-stud grid, server occupancy grid, plot-relative save), 3) GeneticsService (allele strings, Mendelian roll, jitter, mutation roll with Heirloom ×5 and a cap of 35%, all in shared config modules), 4) DataService (ProfileStore-style session locking, versioned schema, creature records `{uid, species, genes, mutations, parents, gen, born, personality, stage}`), 5) multiplayer: plot visits + server-side ownership checks on every remote.
- All odds, timers and multipliers listed above go in `src/shared/Config.luau`. The client never sends outcomes, only intents (itemId plus cell; creature uids for breeding; the release timing for capture is validated against a server-started window ±150 ms).
- Income uses the formula, not a simulation. Visitors are client-side cosmetics.
- Rate-limit remotes: placement 10/s, breeding 1/s, capture 2/s.

## Sources
- [Build a Zoo: big pets and mutations (CommonSenseGamer)](https://commonsensegamer.com/complete-build-a-zoo-guide-to-big-pets-and-mutations/)
- [Grow a Garden mutations & multipliers (Pocket Tactics)](https://www.pockettactics.com/grow-a-garden-mutations)
- [Grow a Garden CCU record analysis (rolearn.dev)](https://rolearn.dev/insights/grow-a-garden-ccu-record-analysis)
- [10,000+ NPCs at 60 fps — server-computed, client-rendered, bit-packed (DevForum)](https://devforum.roblox.com/t/10000-physical-npcs-running-with-60-fps-on-low-end-device/3660293)
- [Methods of reducing lag with many humanoids (DevForum)](https://devforum.roblox.com/t/methods-of-reducing-network-and-physics-lag-with-large-numbers-of-humanoids/371319)
- [Creating a furniture placement system (DevForum)](https://devforum.roblox.com/t/creating-a-furniture-placement-system/205509)
- [Retention benchmarks by Roblox genre (RoWatcher)](https://rowatcher.com/news/retention-benchmarks-by-roblox-genre-what-good-actually-looks-like)
- [What Roblox players need in their first week (RoWatcher)](https://rowatcher.com/news/day-by-day-what-roblox-players-need-in-their-first-week)
- [Roblox monetization strategies 2026 (RoWatcher)](https://rowatcher.com/news/roblox-monetization-strategies-that-actually-work-in-2026)
- [Pet Simulator 99 gamepasses & prices (Pro Game Guides)](https://progameguides.com/roblox/all-pet-simulator-99-gamepasses-are-they-worth-it-roblox/)
- [Dragon Adventures beginner guide — breeding, potions (Roonby)](https://roonby.com/2025/02/21/dragon-adventures-roblox-beginner-noob-to-pro-guide-tips-tricks/)
- [Slime Rancher design critique (Radiator Blog)](https://www.blog.radiator.debacle.us/2017/08/go-west-young-slime-rancher.html)
- [Adopt Me: how to make a Neon pet (RobloxDen)](https://robloxden.com/game-codes/adopt-me/guides/adopt-me-how-to-make-a-neon-pet)
