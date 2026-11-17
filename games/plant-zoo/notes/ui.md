# UI notes (Sprout Zoo)

All UI is built in code from `src/client/Main.client.luau` -> modules in `src/client/UI/` (each < 300 lines).
Phone-first: Scale sizing + UISizeConstraint (buttons min 44 px), safe insets (`CoreUISafeInsets`),
right-bottom thumb zone kept clear. Every button: `Click` sound + press/hover UIScale tween.
The client never decides outcomes: it previews with `Shared/Formulas` + `Shared/Needs`, then calls a remote.

## Screens / modules
| Module | What |
|---|---|
| Style | UI palette, rarity colors (spec hexes), biome/weather icons |
| Kit | builders: Button (sound+tween+44px), Label, Panel, Progress, Tabs, Scroll, Grid, Sig |
| Windows | window frames + manager (one open at a time, pop-in), `Confirm` dialog |
| State / Derived | synced data mirror; display helpers (stage, needs, income, luck, release req, next pad) |
| Net | safe remote calls (RF or RE, timeout, no double error toasts), `Net.On` for server events |
| Hud | top: Cash + $/s, Hope, Luck (+potion timer); weather banner + timer (or "next weather in"); top-right restock timer (tap = Shop) + Settings gear; top-left goal card (Next pad $ bar, Release bar) |
| SideBar | left 2x5: Shop, Bag, Build, Index, Upgrade, Release, Quests, Daily, Visit, Store; red "!" badges (Daily ready, Quest claimable) |
| ShopWindow | Seed Shop (rarity frames, $/s, qty left, countdown, locked slots, Instant Restock R$) + Hope Shop tab |
| InventoryWindow | Bag tabs: Seeds (Plant), Creatures (Place / Sell / View), Items (decor, Luck Potion "Drink", tonics) |
| BuildMode + BuildGhost | placement: 5x5 cell tiles green/red, ghost + facing nose, Rotate 90°, Place, Done; edit mode (tap item -> Move/Remove). PC: hover+click, R rotate, Q/Esc cancel, Enter place. Touch: TouchTap a cell, then Place |
| BuildWindow | Decor shop (buy+place, locked by biome), Exhibits (buy next pad, per-pad biome picker), Biomes (unlock), Edit button |
| CreatureCard | tap your creature (or View): rarity, stage + timer bar, $/s, role, mutations, needs ✅/❌ with Fix, Thriving line, Water, Tonic, Move, Sell |
| IndexWindow | 28 species, "???" silhouettes until found, rarity bands (Secret rainbow outline), mutation badges, role filter (from buddy Fix) |
| UpgradesWindow | 6 upgrades, level pips, next cost, MAX |
| ReleaseWindow | requirement (cash ✅/❌ + rarity), rewards, pick eligible creature, confirm "They won't come back!", camera cutscene to `ReleaseAltar` |
| QuestsWindow | tutorial step progress + 3 daily quests with bars and Claim |
| DailyWindow | 7-day strip (today pulses), Claim; auto-opens on join for returning players with a reward waiting |
| VisitWindow | Zoos tab (Visit / Like per plot, Go Home) + Top tab (server players + all-time Top 10 from `GameState.TopEarned`) |
| StoreWindow | 4 passes (Owned state from `Pass_*` attrs) + 6 dev products; Id 0 -> "Coming soon!" |
| SettingsWindow | Music / SFX toggles -> LocalPlayer attrs `MusicOn` / `SFXOn` |
| Notify | stacked toasts, rarity-colored announce banner (Mythical/Secret rainbow outline), center splash, offline-earnings popup |
| Tutorial | bottom tracker (tutorial step or next daily quest, tap = Quests), bouncing 👈 on the right UI button, world beam + ⬇️ billboard to pad 1 / Tip Jar / Seed Shop |
| ChatTags | shows `ChatTag` attr ("[VIP]") in TextChatService |

## First 60 s (driven by `data.tutorialStep`, Config.Tutorial)
1 Plant: 👈 Bag, beam to pad 1, "tap your glowing pad, then Place" in build mode.
2 Flower Bed: 👈 Build + "(🌱 grows in Xs)". 3 Thriving: countdown, then "✨ Thriving! x1.5" splash (on `ThrivingCount` rise).
4 Tip Jar: beam to my `TipJar` pad 1. 5 Seed Shop: beam to `ShopStand` + 👈 Shop. 6 Pad 2: 👈 goal card. Then daily quests.

## Remotes used (args per notes/gameplay.md)
RF: GetStock, BuySeed(slot), PlaceItem(kind, ref, pad, cell, rotDeg), MoveItem(id, pad, cell, rotDeg), RemoveItem(id),
SellCreature(id), Water(id), BuyPad(pad), SetPadBiome(pad, biome), UnlockBiome(biome), BuyDecor(kind, pad, cell, rotDeg),
BuyUpgrade(key), Release(id), ClaimDaily(), ClaimQuest(index), UseHopeItem("LuckPotion" | "GrowTonic", id),
BuyHopeItem(key), VisitPlot(plot), LikeZoo(plot), GoHome().
RE in: DataChanged, StockChanged, WeatherChanged, Notify, Announce, OfflineEarnings, OpenScreen
(SeedShop/HopeShop/Upgrades/Release/Daily). Robux via MarketplaceService prompts with Config IDs.

## Reads (no remotes)
Player attrs: PlotIndex, IncomePerSec, Luck, ThrivingCount, Pass_*, ChatTag, MusicOn/SFXOn.
GameState attrs: Weather/WeatherEndsAt/NextWeatherAt, Plot<n>_OwnerUserId/OwnerName/Likes/PadsOwned; `TopEarned` JSON.
World: `ExhibitPad` tag (PlotIndex/PadIndex), `TipJar`, `ShopStand`, `ReleaseAltar`; item Models in
`workspace.ZooItems.Plot<n>` with ItemId / OwnerUserId / Kind attrs (tap = raycast to Hitbox).

## Sounds called (notes/audio.md)
Client: Click, Open, Close, Error (client-side failures only), Notify, Announce, OfflineEarnings, Cash, Rotate, Remove.
Server already plays Purchase/Reveal*/Place/Plant/Sell/Water/Expand/Release/DailyReward/QuestComplete/Like/Restock, so
the UI doesn't repeat them. Server also toasts its own failures, so `Net.Do` only toasts client-side errors.

## Assumptions
- Restock countdown is computed client-side from `Config.Shop.RestockSeconds` and server time (same as the server).
- Needs on the card come from `Shared/Needs.ForPad` on synced data (same math the server caches).
- Settings are not saved between sessions (see QUESTIONS.md).
- Camera: FOV 72, max zoom 70 (90 during build mode); Scriptable only for the 3 s Release cutscene.
