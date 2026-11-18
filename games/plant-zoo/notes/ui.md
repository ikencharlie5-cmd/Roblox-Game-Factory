# UI notes (Sprout Zoo)

All UI is built in code from `src/client/Main.client.luau` -> modules in `src/client/UI/` (each < 300 lines).
Phone-first: Scale sizing + UISizeConstraint (buttons min 44 px), safe insets (`CoreUISafeInsets`),
right-bottom thumb zone kept clear. Every button: `Click` sound + press/hover UIScale tween.
The client never decides outcomes: it previews with `Shared/Formulas` + `Shared/Needs`, then calls a remote.

## Premium UI rebuild (follows research/UI_STYLE_GUIDE.md)
- **Scaling:** `Kit.Gui` adds a `Root` frame with one UIScale = clamp(viewport.Y/1080, 0.55, 1.25); everything is sized in px at 1080p
  (`Kit.Root(gui)`, `Kit.Virtual(gui)` = usable screen in ref px, `Kit.ToRoot` converts absolute -> ref px, `Kit.Resized` signal).
  Windows fit to min(design size, 92% width, height-70). Text: fixed max size (TextScaled + UITextSizeConstraint only shrinks).
- **Fonts:** FredokaOne (titles, buttons, numbers; white + Contextual UIStroke in the dark shade) and BuilderSansExtraBold (body). No Gotham, no legacy TextStroke.
- **Palette:** `Style.Pal` = Top/Bottom/Dark per colour (Leaf, Sun, Sky, Pink, Purple, Teal, Red, Stone, Disabled, Robux, Wood, Body, Card). `Style.PaletteFor` maps palettes, names or old `Style.Color.*` values. Rarity: `Style.RarityDark`, `Style.RarityPalette`.
- **Kit (folder module):** `init` (core, Label/Title/Body, StripEmoji), `Button` (Button, IconButton, CloseButton, Tabs, SetButtonColor, ButtonFace/ButtonPress), `Window` (Kit.Window chrome), `Parts` (Slab, Panel, Card, Progress, Icon, CodeBadge, BiomeChip, Badge), `Fx` (Gradient, Highlight, Shine, Pulse, Stagger, PopIn, Float, RarityFx), `View` (CreatureView).
- **Button recipe:** white face + UIGradient + 3.5 px same-hue dark stroke + dark lip + shadow + gloss strip; parts sit in a centre-anchored `Holder` with the press UIScale (hover 1.06, press 0.92 + face sinks onto lip, Back-Out release, Click sound). Grey (`Style.Color.Grey`) = disabled palette. Old `Kit.Button(parent, text, color, onClick, props)` signature kept; setting `.Text` updates the label.
- **Windows:** coloured header slab sticking 24 px out of the top (icon + title), tilted red close button on the corner, cream gradient body, 4 px wood stroke, 8 px lip; Back-Out open, Quad-In close, BlurEffect (Lighting, "SproutUIBlur") + dim behind; cards stagger in. Header colour = category (Shop green, Bag/Visit blue, Index purple, Build wood, Release teal, Quests pink, Daily gold, Store pink, Settings stone).
- **Rarity cards:** white card, rarity-dark stroke, rarity band + word at the bottom; Epic gradient stroke, Legendary spinning gold, Mythical pink/purple pan, Secret rainbow (one shared 30 Hz loop).
- **Creature pictures:** `Kit.CreatureView` renders Shared/CreatureModels in a ViewportFrame (FOV 30, 3/4 view, white light). Each species+stage is built once and cached; viewports get a Clone. Undiscovered Index entries = dark silhouette tint.
- **No emoji anywhere.** Server toast/quest/daily text goes through `Kit.StripEmoji`. Biomes/weather/mutations use code-drawn 2-letter chips.

## Screens / modules
| Module | What |
|---|---|
| Hud | top-left currency chips (Cash + "+" -> Store, $/s under it, Hope + "+", Luck), tick-up + pop + floating "+$" on gain; top-right restock pill (tap = Shop), Store icon button (pulse + shine), settings gear; goal card (Next pad / Release bars) under it; Luck Potion boost tile with timer |
| WeatherBanner | top-centre weather pill (weather colour + code chip + effect + timer), grey "Next weather in" teaser |
| SideBar | 8 icon buttons (Shop, Bag, Build, Index, Release, Quests, Daily, Visit), 2 columns (3-4 on short screens so the bottom-left joystick zone stays clear on touch), red bobbing "!" badges; `SetVisible` reveals buttons with a staggered pop |
| ShopWindow | seed cards (creature render, biome chip, $/s, qty left, green price button with cash icon), locked slots, Hope Shop tab, Restock R$29 |
| InventoryWindow | Seeds / Creatures / Items cards with renders/icons and Plant / Place / View / Sell / Drink |
| BuildWindow | Decor / Exhibits / Biomes cards + Edit + **Upgrades** button (Upgrades moved off the left bar: max 8 buttons) |
| UpgradesWindow | rows with code badge, gradient level pips, price button / MAX |
| ReleaseWindow | requirement (cash coloured green/red), rewards, selectable creature cards (render + teal "OK" badge), Release button |
| QuestsWindow / DailyWindow | progress rows with shining Claim; 7 day slabs (today pulses, done = OK badge), shining Claim |
| VisitWindow | zoo rows (Visit / Like), Top tab with gold/silver/bronze rank badges |
| StoreWindow / SettingsWindow | pass/product cards with icons + green Robux buttons; ON/OFF toggles |
| CreatureCard | big rarity card with the creature render, name, $/s, stage bar, Thriving line, needs rows (OK/X badge + Fix), Water / Tonic / Move / Sell |
| Notify | slab toasts (max 3, slide + fade, 2.5 s), rarity announce banner with animated stroke, splash with rotating sunburst, offline popup window |
| Tutorial | bottom tracker card (pushed up on touch), code-drawn gold arrow at the target button, world beam + arrow billboard; reveals left buttons per step |
| BuildMode | bottom-centre context bar (cream panel, Rotate / Place / Move / Remove / Done) |

## Charlie TODO: icons
Upload in the same style as the existing pack, then add the id to `Style.Icons` (the code-drawn badge is replaced automatically):
Shop, Inventory (Bag), Build, Index, Upgrades, Quests, Visit, Hope, Luck, SuperLuck, LuckPotion, GrowTonic, HopeCrate,
FinishGrowing, InstantRestock, Decor, Locked. Optional: biome icons (Meadow, Pond, Desert, Canopy, Fungus, Frost) and
weather icons (currently 2-letter chips).

## First 60 s (driven by `data.tutorialStep`, Config.Tutorial)
1 Plant: arrow at Bag, beam to pad 1, "tap your glowing pad, then Place" in build mode.
2 Flower Bed: arrow at Build + "(grows in Xs)". 3 Thriving: countdown, then "Thriving! x1.5" splash (on `ThrivingCount` rise).
4 Tip Jar: beam to my `TipJar` pad 1. 5 Seed Shop: beam to `ShopStand` + arrow at Shop. 6 Pad 2: arrow at goal card. Then daily quests.
Left buttons revealed per step: 1 Shop+Bag, 2 +Build, 3 +Index, 4 +Quests, 5 +Daily, 6 +Release+Visit; tutorial done = all 8.

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

## Checker fixes (round 2)
- `Derived.Mutations` / new `Derived.IsMutation`: "None", "", nil and false count as no mutation, so names never read "None None Sproutling" (card, Bag, Release, confirm). Index badges skip "None"; Notify toasts/announcements strip a stray "None None " / "NONE " word defensively.
- BuildMode: every successful placement, including paid `buydecor`, now exits build mode (no more repeat buys from hover+click). A `busy` flag blocks double clicks while the request is in flight.
- Thriving splash only fires 3 s after the first data load, so returning players don't get it on join.
