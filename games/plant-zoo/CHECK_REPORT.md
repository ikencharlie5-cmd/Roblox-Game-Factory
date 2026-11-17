# CHECK REPORT: plant-zoo (🌱 Sprout Zoo), static review, round 1

**Result: FAIL** (2 high, 5 medium, 6 low)

## Tooling
- `luau-compile` on all 72 `.luau` files: **0 syntax errors**.
- `luau-analyze`: no unknown or typo'd globals.
- `stylua --check`: clean.
- `rojo build games/plant-zoo -o build/plant-zoo.rbxl`: **builds**.
- `selene`: **did not run**. It couldn't download the Roblox std (API dump fetch failed in this sandbox), so `check.sh` prints CHECKS FAILED for this reason only. CI must confirm lint.

## Cross-branch contracts verified OK
- All 20 RemoteFunctions in `Remotes.luau` are bound with `Guard.Bind` in a service. Every UI `Net.Do/Net.Call` name and its argument order matches the server handlers (PlaceItem kind/ref/pad/cell/rotDeg, BuyDecor, MoveItem, Water, UseHopeItem key+id, ClaimQuest index, LikeZoo/VisitPlot plot, and the rest). The `(ok, result)` return shape is handled by `Net.interpret`. All 8 RemoteEvents are fired by the server and listened to on the client.
- Tags exist with the right attrs. World creates Plot, ExhibitPad, TipJar and PlotSpawn (all with PlotIndex/PadIndex), plus ShopStand, HopeShop, UpgradeStand, DailyStand and ReleaseAltar. PlotService.PROMPTS screens map 1:1 to `Main.client` SCREENS.
- The `workspace.ZooItems.Plot<n>.<id>` model contract matches: Hitbox is the PrimaryPart, and the attributes Kind/Species/Stage/Color/Weather/Thriving/DecorKind/PlotIndex/PadIndex are read correctly by ItemVisuals. Grid math in `PlotService.CellCFrame`, `Theme.CellOffset` and client `Plots.CellAt` is identical, including rotation in degrees.
- The GameState folder, TopEarned/WorldReserve JSON and the Weather/NextRestockAt attrs match what StateSync, VisitWindow and Hud read.
- No service require cycles. All folder modules (Theme/init, CreatureModels/init, Effects/Looks/Kinds/Tops) resolve. Every `Style.*`, `Kit.*`, `Config.*`, `Formulas.*` and UI-module member that is referenced exists.
- Species data is consistent: 28 species, every rarity bucket is non-empty, every Decor exists in `Config.Decor` with a matching biome, every Buddy is a real role, and every Look/Top/Decor builder exists.
- Every server `Guard.Sound` name and client `Kit.Sound` name exists in `Sounds.luau`.
- All 6 Dev Products have a ProcessReceipt handler and the 4 passes are wired. Daily reward is saved. Every tutorial and daily-quest Kind is emitted by some service.

## Issues (most severe first)

### High
- [gameplay] src/server/Services/DataService.luau:96-101 — In Studio without "Studio Access to API Services", `GetAsync` throws 3 times (about 6 s), then the player is **kicked**. This blocks the Studio playtest. — Turn on API access in the test place, and/or add a Studio fallback: `if not ok and RunService:IsStudio() then warn(...); saved = nil` (use DefaultData and skip saving), and only kick in live servers.
- [ui] src/client/UI/Derived.luau:166-172 — `Derived.Mutations` only filters `""`, but the server always stores `color = "None"` and `weather = "None"`. Every creature therefore shows as **"None None Sproutling"** (CreatureCard header, Bag, Release list, Release confirm) and the card info line reads "🌈 None None". The player sees this in tutorial step 3. — Skip `"None"` as well (`item.color ~= "" and item.color ~= "None"`, same for weather).

### Medium
- [gameplay] src/server/Services/PlotService.luau:159/215 (with WorldService.Init, Plots.luau:226, Hub.luau:260,265) — `WorldService.Init` yields (about 8 frames of `task.wait()`) while `DataService` is already loading players. If a player's data loads before the plots exist, `assign` finds no tagged Plot/ExhibitPad/TipJar parts. Fallback positions are then used (items sit 0.8 studs into the pad), IncomeService creates duplicate fallback jars, and WorldService later resets every pad to Unlocked=pad1/Meadow, so a returning player's pads show as locked. `GetChildren` order also decides which `OnLoaded` hooks register before that yield (ZooService currently registers after it). — In `assign` (or at the top of `PlotService.Init`'s callback), wait for `workspace:GetAttribute("WorldReady")` before assigning, or make DataService start loading players in `Start()` instead of `Init()`.
- [audio] src/shared/Sounds.luau:33,37,45,49,50,53,62-65,68,71,72 — 14 sound IDs are still 0. The biggest moments are silent: **Mutation**, **RevealEpic/RevealLegendary/RevealSecret** (rarity fanfare), **Water**, the weather start stings (Rain/Heatwave/Snow/Bloom/Starfall) and creature Chirps. — Pick IDs (Creator Store, then verify in Studio). Until then, alias them to existing IDs (e.g. RevealEpic to the RevealRare ID at a higher pitch, Mutation to Bloom). Add anything left to the README Charlie TODO.
- [graphics] src/server/World/ItemVisuals.luau:25-33,70 + Motion.luau:44-45 — Visual parts get `CanQuery=false` and grown creatures wander ±2.5 studs away from their fixed 3.6-stud Hitbox. Tapping the creature you can see often misses, so the card doesn't open. Tutorial step 3 says "tap your creature to see its needs". — Leave `CanQuery=true` on Visual parts (`Plots.ItemFromHit` already walks up to the item Model with ItemId), or cut the wander to about ±0.8 studs.
- [ui] src/client/UI/BuildMode.luau:207-209 — With a mouse, hover pre-selects the cell, so **every click on a pad confirms right away**. In `buydecor` mode the build bar stays open after a purchase, so a new player clicking around after placing the tutorial Flower Bed keeps buying $50 decor, which can drain the cash they need for Pad 2. — For `buydecor`, call `BuildMode.Stop()` after a successful buy (or during the tutorial), or require the ✅ Place button for paid placements.
- [manager] games/plant-zoo/README.md — "How to play: TBD". The title is still "Plant Zoo (working title)", as is `default.project.json` "name". Charlie TODO lists only pass/product IDs. — Write how to play (3-4 lines) and rename to 🌱 Sprout Zoo. Add Charlie TODOs: the 14 zero sound IDs, enable API Services + MessagingService (Secret announcements), game icon/thumbnails, and verifying the "(verify in Studio)" sounds (Restock, QuestComplete).

### Low
- [gameplay] src/server/Services/Guard.luau:67-69 — A rate-limited call returns `(false, "Slow down!")` with no Notify or sound. `Net.Do` only gives feedback for client-side failures, so a fast double-tap fails silently. — Use `Guard.Fail`, or return quietly and let the UI ignore it (no change needed if it's intended).
- [gameplay] src/server/Services/PlotService.luau:137 — When a player leaves, `setPlotAttrs(i, nil, nil)` sets **pad 1** to Unlocked=false. Free plots then show a hedge plus a "$0" sign on pad 1, which doesn't match the fresh-server look (pad 1 open). — Use `local unlocked = if data then pad <= data.padsOwned else pad == 1`.
- [gameplay] src/server/Services/SocialService.luau:92-96 — The VIP ChatTag only updates on a later Pass_VIP change. It never calls `applyTag` right away and misses players already in the game. — Call `applyTag(p)` on PlayerAdded and loop over `Players:GetPlayers()`.
- [gameplay] src/server/Services/DataService.luau:229-234 — BindToClose waits a fixed 3 s while each save can retry for up to 6 s. There is no session lock, so a fast server hop can load stale data. — Track pending saves and wait until they finish (up to about 25 s). Consider UpdateAsync with a session lock later (v2).
- [ui] src/client/Main.client.luau:160-167 — `lastThriving` is read before data loads, so returning players get a "✨ Thriving! x1.5 ✨" splash on every join (0 → N). — Ignore the first ThrivingCount change after join (or seed it after the first DataChanged plus a short delay).
- [audio] src/client/Audio/MusicDirector.luau:45 — Reads `workspace:GetAttribute("IsNight")`, but Sky sets it on **Lighting**. The ClockTime fallback makes it work anyway. — Read `Lighting:GetAttribute("IsNight")`.

## Quality checklist
- [ ] check.sh passes: stylua ✅, rojo ✅, selene ⚠️ couldn't run here (std download), so CI must confirm
- [x] Understandable in 60 s (tracker, arrows and beam on every tutorial step), except the "None None" names and the missed creature taps above
- [x] Remotes validated server-side (types/ranges/affordability; per-remote 0.2 s cooldown)
- [x] Data saves on leave + autosave + BindToClose; reconcile fills new fields (BindToClose wait is short, see Low)
- [x] No infinite yields (every client WaitForChild targets something the server creates; Net uses timeouts)
- [x] Every `while true` has a `task.wait`
- [ ] Feedback on every purchase/reward: missing for Epic/Legendary/Secret reveals, mutations and watering (sound ID 0)
- [x] Numbers via Shared/Format
- [x] Phone UI: Scale sizing, 44 px min buttons, 2-column sidebar
- [x] 4 Game Passes + 6 Dev Products wired (IDs 0 show "Coming soon")
- [x] Daily reward works and is saved
- [x] Next goal always visible (goal card: next pad + Release bar; tracker)
- [ ] README: how to play missing, Charlie TODO incomplete
- [x] DECISIONS.md is up to date

## First 60 seconds (traced through code)
1. Spawn at the hub SpawnLocation. Data loads (fails in Studio without API access, see High #1). PlotService assigns plot 1 and teleports to PlotSpawn, facing into the plot. HUD shows $100, the goal card "Next: Pad 2 - $500" and the tracker "1/6 Plant your Sproutling - open your 🎒 Bag" with an arrow on the Bag button and a beam to pad 1.
2. Bag → Seeds → "🌱 Plant" starts BuildMode with a ghost on pad 1, cell 13. ✅ Place sends `PlaceItem("seed","Sproutling",1,13,0)`. The server plants it (Plant sound) and pays the tutorial +$50. The seed mound appears through ItemVisuals and grows Seed → Sprout → Bud → Grown over 10 s with a GrowStage bloop.
3. Step 2: arrow to 🔨 Build → Decor → Flower Bed "$50 Place". BuyDecor goes to cell 14 next to the Sproutling. +$50. On PC, clicking again buys another bed (Medium issue).
4. Sproutling matures (Bloom chime). Needs are biome ✓ and decor ✓, so it's Thriving: Thriving ding, splash, +$100 +5 Hope. Tapping the creature to see its card may miss when it has wandered (Medium), and the card header reads "None None Sproutling" (High).
5. Step 4: the beam points to pad 1's Tip Jar. It fills at about $1.5/s, walking over it collects (Cash sound, coin burst) and pays +$100.
6. Step 5: arrow to 🛒 Shop and a beam to the hub Seed Shop (about 170 studs away; the sidebar button also works). BuySeed pays +$150. Step 6, Pad 2 for $500, is reachable within about a minute of tips.

Verdict: the loop is clear and well guided, and the cross-branch contracts are solid. Fix the two High issues (Studio data fallback, "None" mutation text) and the World-ready race, then playtest.
