# Wildworld — decisions made without asking

| Decision | Why |
|---|---|
| Creatures are code-built parts only (12–25 part toy figurines, blueprints in shared/CreatureBlueprints) | Genes/mutations recolour parts for free, works straight from rojo build, no mesh uploads or Charlie IDs; AI meshes can't be gene-tinted per part |
| Trading ships in update 1, not v1; v1 social = park visits + Likes | Trading needs dupe-proof two-sided escrow in DataService and scam UI — big risk for no first-60s fun; a planned update also gives a re-engagement beat |
| Breeding is same-species only in v1 (4 genes + 4 mutations + combos) | Mutation chase already gives surprise babies; hybrids need extra models/balancing per pair — save as a headline update |
| One zone-id set: `Meadow` / `Hollow` / `Glade` (Config.Zones Id) + `Park` (+ `Hub` only if a hub area exists). Audio rekeys Sounds zones + MusicDirector to these; Graphics drops the twin `AudioZone` volumes; Theme may keep long keys internally via Layout `Key`; UI shows `Config.Zones[].Name` | Config Ids are already in save data and server logic; one key set removes a whole class of silent mismatches |
| Gameplay (WildService) owns the player `Zone` attribute (already sets Id or `Park`) | Server already tracks zone for gates/spawns; single writer |
| Wild creatures also get tag `Creature` + `Stage="Adult"`; owned creatures keep current attrs. Contract: `Species`, `Mutations` (comma string), `Stage`, `State`, `Goal`, `Speed` | Audio voices + Animation need one tag for all creatures; wild ones are the first thing players meet |
| Persist volume settings: gameplay adds `SaveSettings({music,sfx,musicOn,sfxOn})` RemoteEvent (clamped, rate-limited) into existing `data.settings`; DataService sets the 4 player attributes on load | Schema already has `settings`; tiny cost, players hate re-muting every join |
| Graphics tags the Glade waterfall `WaterfallSound`; WeatherService sets workspace `Weather`; `IsNight` skipped (ClockTime fallback is fine) | Two one-liners; night detection already works |
| Approve client-side Hitbox move. Gameplay server range checks (feed/pet/bait) measure to the creature's `Goal` with +6 stud tolerance | Keeps clicks on the visible creature without false "too far" fails |
| CaptureService sets `Moment = "CaptureFail:<n>"` on miss and `"Captured:<n>"` 0.9 s before destroying a caught wild creature (`n` = per-creature counter so the value always changes) | The catch is the first-60s hook; it needs its payoff animation |
| Visitor payouts increment plot Model attribute `Tips` and set `TipAmount` (incl. the first-60s +25) | Coin fountain is a visible "it earns" moment for free |
| Egg hatch: Animation's client shell burst is the only one (`Tuning.EggShellBurst = true`); server never calls `Theme.Moments.Hatch` | Avoid double shells; client effect is pooled and cheaper |
| Graphics owns `shared/CreatureBlueprints` + `shared/CreatureBuilder`; Models.luau calls `CreatureBuilder.Build/BuildEgg` (already), `CreatureBlueprints.Build` stays as a thin alias; fallback 3-part model only on error | Single owner; real limbs/ears/tail make the animator work |
| UI uses `BuyShop(slot)` (no BuyBait) and `ClaimDaily` as a RemoteFunction via Net.Do (already built) | Matches server; template event is gone |
| `DailyDay` = when `DailyReady` true, the day the claim will give; when false, the day already claimed today (next = DailyDay % 7 + 1) | That is what DailyRewardService already does; UI just marks that tile Claimed |
| All 35 Items have a Theme.Props model (the 11 "missing" now exist); Gameplay removes the stale note, Checker verifies none fall back to blocks | Graphics already added them; just confirm |
| No favourites remote in v1 | Not a first-60s or earning feature; nickname covers attachment |
| Locked zones block by teleport + walk-through veil; client hides veil once unlocked | Already built, simple, no physics edge cases |
| Waterfall stays part sheets + particles; scrolling-Beam texture is an optional Charlie TODO | Works without uploads |
| Starter egg hatches Adult (`Config.StarterHatchesAdult`); bred babies grow normally | Breeding right after first catch is the hook |
| 30 storage + Capacity-upgrade park slots; 200 is a hidden hard data cap | Matches spec intent, protects DataStore size |
| Feeding free with 10 s cooldown; bowls 10 servings, free refill; Auto-Feeder pass = never empty | No friction early; pass sells convenience |
| Likes: +1 rating per unique visitor/day, `LikeBonusCap` lowered 20 -> 10 | 20/100 from likes alone swamps building the park |
| Tutorial rating numbers follow the formula; tree +5 guarantees the visible jump | Exact 22->34 doesn't matter, the jump does |
| New saves get 5 Berry bait; shop stall restocks every 5 min | Player can catch in the first minute without buying |
