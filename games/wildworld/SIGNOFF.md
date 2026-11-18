**Result: APPROVED (SHIP)** — re-check 2026-11-17: all 3 prior ❌ fixed; DataService late-autosave lock race also fixed (UpdateAsync transform returns nil when not release and player left / cache[player] ~= data).

Basis: SPEC.md, src/, notes/, CHECK_REPORT.md (round 2 PASS), CI green. No Studio MCP, so there was no playtest. Items that can only be checked in a live session are marked ➖ and listed under Charlie's playtest.

# Good Game Checklist (Manager's final sign-off)

## 1. First 60 seconds — the hook [UI, Gameplay]
- ✅ Player knows what to do within 10 seconds, with no reading required. Only a pulsing Hatch! button and a world arrow show (Tutorial.luau).
- ✅ First reward lands within 15 seconds. The hatch plays a rarity reveal, then a +25 visitor tip with a coin fountain.
- ✅ First upgrade/purchase is possible within 60 seconds. A tree costs 25 coins and the rating bar jumps (tree +5).
- ✅ The big goal is visible early: the quest card, Journal 1/5, the Park tier ladder, and the guaranteed Golden first egg.
- ✅ Spawn looks impressive: Heart Tree fountain plaza, lanterns, flower beds, Top Parks board (Hub.luau).

## 2. Core loop [Gameplay]
- ✅ The loop is clear: catch/breed → place in habitats → visitors pay → build/upgrade → better ratings and more creatures.
- ✅ Every action has an obvious result: toasts, sounds, rating strip, coin fountain, reveal cards.
- ✅ There are choices: which habitat/biome tags, which pair to breed, upgrades, zones, sell or keep.
- ✅ Offline earnings at 50% (2 h cap) with a "While you were away" popup. Bowls feed creatures automatically.

## 3. Progression & content [Gameplay, Graphics]
- ✅ 30–60 minutes of content: 5 species, 3 zones (Lv 4 + 1k, Lv 8 + 5k), upgrades up to 15k, level-gated build items, Journal mastery, and the mutation chase.
- ✅ 3 zones that look different: Meadow Edge, Mossy Hollow (mist, fireflies), Waterfall Glade (lake, waterfall, magic trees).
- ✅ Long-term goal: park tiers Poor → Legendary (+50%), Journal mastery, and Crystal/Gilded mutations.
- ✅ Numbers grow: costs, Level XP 100×n^1.4 and tier multipliers scale, with no dead walls found.
- ✅ Collectibles/rarities: 4 mutations, a combo, genes and rarity tiers.

## 4. Retention [Gameplay, UI]
- ✅ 7-day daily streak ending in a Mutation Egg (DailyRewardService, DailyWindow auto-opens).
- ✅ Time-based content: egg timers, shop restock every 5 min, 3 daily quests, weather (Rainbow Shower).
- ✅ Saves feel safe: session lock, autosave, save on leave, BindToClose, reconcile defaults, dupe-proof receipts. (There is one rare lock-race minor in CHECK_REPORT. It doesn't lose progress.)
- ✅ A "next unlock" is always visible: QuestCard, level locks in the build tray, zone cards in ParkWindow.

## 5. Social [Gameplay, UI]
- ✅ Leaderboard: leaderstats plus the Top Parks board (OrderedDataStore).
- ✅ Show-off: visit any park (VisitWindow), see rare mutated creatures on display, Likes.
- ✅ Better with friends: visits and Likes add rating. Trading is planned for update 1, per DECISIONS.

## 6. Monetization [Gameplay, UI]
- ✅ 2+ Game Passes with clear value: 4 passes; VIP "Gold name + tag" now built — gold VIP BillboardGui on Head via CharacterAdded/VIP attribute (MonetizationService.applyVipTag) + gold [VIP] chat prefix (client/Chat/VipChatTag.luau, TextChatService.OnIncomingMessage).
- ✅ 1+ Dev Product: Instant Hatch x3, Coin packs x3, Starter Pack.
- ✅ The shop is easy to find (HUD row, "+" on the Coins chip, hub stall) and never blocks free players. Passes are cosmetic/convenience only.
- ✅ Purchases give instant feedback: Purchase sound plus a Splash ("Starter Pack!" / name).
- ➖ Premium Payouts are optional. No specific hook, and that's fine for v1.

## 7. Game feel / juice [UI, Graphics, Audio]
- ✅ Every button has hover/press tweens and a click sound (Kit/Button.luau).
- ✅ Every reward shows a popup number, pooled particles/coins and Coins_Gain tick-ladder sound.
- ✅ Big moments feel big: reveal sunburst, flash and stinger with an 8 dB music duck. Level/tier/zone get a Splash and a stinger.
- ➖ "Nothing feels laggy" can't be checked without a playtest. Remotes return immediately and the animation is a client-side, budgeted BulkMoveTo.

## 7b. Animation [Animation]
- ✅ Creatures never freeze: idle bob, breathing, blink, ear flick, tail wag, Lumibun hops, look-at.
- ✅ Key moments animate: egg wobble → crack → pop, mutation reveal delay, capture bubble, coin fountain, drop-in thud, release.
- ✅ Scenery moves gently (canopy sway, lantern flicker) inside distance tiers.

## 8. Visuals & world [Graphics]
- ✅ Consistent palette and style (Theme/Palette, ART_STYLE_GUIDE).
- ✅ No grey filler: all 35 build items have Theme.Props models, and the terrain is materialised.
- ✅ Lighting and atmosphere are set: ShadowMap, Sky, 14-min day cycle, weather (Sky.luau, project Lighting).
- ✅ Clear paths: spoke roads to each plot, a forest road with a signpost and gate arches.
- ✅ Kill floors/invisible walls: Terrain.Bounds adds invisible collide walls (park box ±420, forest corridor x ±225 to z -1240; clear of plots and zones HalfWidth 200), and SafetyFloor.Touched teleports characters to HubSpawn with per-character debounce (WorldService).

## 9. Sound & music [Audio]
- ✅ Background music fits the mood (marimba/ukulele park, acoustic forest), with Music on/off in Settings.
- ✅ SFX for click, purchase, reward and error are all set. Some flavour one-shots are `Id = 0` (silent-safe, in Charlie TODO).
- ✅ Different music/ambience per zone: Hub, Park day/night, Meadow/Hollow forest, Glade.
- ✅ Volumes are balanced: music 0.2–0.25 × group 0.6, under SFX 0.8, plus ducking.

## 10. UI / UX [UI]
- ✅ Looks premium: plant-zoo Kit re-skinned as a field journal (gradients, stitch outline, shadows, real fonts).
- ➖ Image icons: no emoji anywhere. Letter-badge fallbacks show until Charlie uploads the icon pack (already in Charlie TODO, needs real asset IDs).
- ➖ Studio screenshot review: no Studio MCP in this run.
- ✅ Works on every device: root UIScale, CoreUISafeInsets, 44 px minimum hit, SideBar 3x2 on phones, no hover-only actions.
- ✅ Nothing off-screen on a small phone (by code: UIScale clamp 0.55, phone layout). It still needs a visual check on a device.
- ✅ Menus open and close smoothly, one window at a time, with a single tap to close.
- ✅ Numbers are formatted (Format.Number).
- ✅ Settings menu has Music and SFX on/off plus volume, saved via SaveSettings.

## 11. Stability & security [Gameplay, Checker]
- ✅ The server validates every remote: Guard.Bind checks type and ownership, and the server re-checks cost/level/range.
- ✅ Remotes are rate-limited (Guard, with a limit for each remote).
- ➖ No console errors in a full playthrough: unverifiable without Studio. The static review is clean and CI is green.
- ✅ Data: autosave 60 s, save on leave, BindToClose, reconcile defaults.
- ➖ 1 player and full server: 8 plots, one per player, and a visit flow. Needs a live 8-player test.

## 12. Performance [Graphics, Gameplay]
- ✅ Map parts are anchored, terrain is used for ground/hills, and Scatter clusters keep the part count reasonable.
- ✅ No server loops move parts. CreatureAI only sets attributes, budgeted per frame.
- ✅ Effects are pooled (FxPools) or destroyed.

## 13. Ready to publish [Manager → Charlie TODO]
- ✅ README publish-ready: title + emoji tag, description, How to play, icon/thumbnail ideas, pass/product table matching Config prices, publish steps, Charlie TODO.
- ✅ (in README) Game description
- ✅ (in README) Icon + thumbnail ideas
- ✅ (in README) Game Pass / Product names, prices, descriptions
- ✅ The Charlie TODO list is short. It needs one line added: "create the 4 passes + 7 products from the table and paste IDs".

## Fix list
- [gameplay+ui] VIP "Gold name + tag": on CharacterAdded, if `player:GetAttribute("VIP")`, add a gold BillboardGui tag "VIP" over the head (Gameplay). Gold chat tag via TextChatService.OnIncomingMessage (UI client). Or drop that line from ShopWindow INFO.VIP and the SPEC.
- [graphics] Map edge: add invisible anchored CanCollide boundary walls (Transparency 1, CanQuery false) around the playable area, outside the backdrop hill ring and along the terrain edge. Also make `SafetyFloor` touch-teleport players back to HubSpawn so nobody is ever stuck.
- [manager] README: add title "Wildworld 🦊" (+ "[🥚 MUTATIONS]" style tag), How to play, a 2–3 line description, 2 icon + 3 thumbnail ideas, and a table of the 4 Game Passes + 7 Dev Products (name, price, description) from Config.luau.

## Charlie's playtest (can't check without Studio)
Console clean through the first 10 min, phone layout, 2+ players visiting/liking, lag feel.
