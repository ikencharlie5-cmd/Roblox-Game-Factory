# Wildworld — UI Style Guide (build-in-code)

Owner: UI branch. Everything is built with `Instance.new`. The only image assets are icons. Creatures appear as ViewportFrame renders.
**Baseline:** The button, window, font, juice and Luau recipes in `games/plant-zoo/research/UI_STYLE_GUIDE.md` §2–§11 are proven in this factory.
Port the plant-zoo `Kit` (`games/plant-zoo/src/client/UI/Kit/` with Button, Window, Fx, View and Parts) into `games/wildworld/src/client/UI/Kit/`, then **re-skin it** with the Wildworld palette in §2.
This doc covers only what is new or different for Wildworld.

## Summary
- **Same premium recipe, new identity.** Use the plant-zoo Kit (white-base face, UIGradient Rotation 90, 3.5 px same-hue dark UIStroke, 6 px lip, gloss strip, Back-Out press, FredokaOne white text with a dark Contextual stroke). Re-skin it as an **"explorer's field journal"**: a parchment body, a deep-teal frame and a sunset-coral accent. Players should recognise it at a glance and not mistake it for Sprout Zoo.
- **Creature-first windows.** Every creature surface (Collection card, Inspect, Breeding slots, Journal) uses the same **CreatureCard**: a ViewportFrame render, a rarity frame, mutation badges and a happiness ring. Inspect is one window with 4 tabs (Overview / Genetics / Family / Care). Don't spread these across many submenus. Planet Zoo 2's "spider's web of menus" is the cautionary tale.
- **Breeding panel = Parent A | odds | Parent B.** Show gene chips with dominant and recessive marks, and a "Possible offspring" strip with **ranges and % odds**, never one promised result (spec §8). Show mutation *categories* with sparkle-tier chance labels. A big Breed button shows cost and duration. Hatching gets a centre reveal with a rarity sunburst.
- **The Build menu is a bottom tray plus a context action bar.** The tray has category tabs, item cards with price and "habitat value" tags, and a ghost preview that turns green or red. Every keyboard action (R rotate, X delete, G grid, Q/E fine rotate) also has an on-screen **84 px button** on the right side, above the jump button. Touch and gamepad then work with no hidden keys.
- **The Journal shows unknown species as silhouettes.** Unknown species appear as black-tinted ViewportFrames with "???". Each species has a 5-step research bar (Seen → Captured → Bred → Mutation found → Mastered). Completion % shows per biome and per category. Mobile rules apply everywhere: root UIScale, `CoreUISafeInsets`, nothing in the bottom-left 35%×40% or bottom-right jump zone, 44 px minimum hit size, and windows at 92% width on phones.

---

## 1. Visual identity: "field journal"

| Element | Wildworld choice | Why |
|---|---|---|
| Window body | Parchment gradient `#FFF8E7 → #F3E3BF`, 4 px stroke `#2E4A45` (deep teal-ink) | Exploration/naturalist feel, distinct from Sprout Zoo's wood frame |
| Window header | **Category colour** pill (§2), sticks up 24 px, with title and icon | Players learn colour = menu (Roblox: map colours to key info) |
| Corner accent | Optional small 28 px leaf/paw icon at the header's left; a dashed 2 px "stitch" inner border (`#C9B48A`, transparency 0.3) 8 px inside the body | Cheap "journal" texture without a tile asset |
| Accent | Sunset coral `#FF8A5B` for "new", "!" and featured items | Warm against the teal/green park |
| Card | White `#FFFFFF` → `#FBF4E2`, UICorner 14, 3 px stroke in the rarity dark shade | Same as the plant-zoo card |

Behind open windows, use a Camera BlurEffect (0 → 10 over 0.2 s) and a black dim at 0.6. Only one major window is open at a time (a stack of depth 1, plus modal confirms).

## 2. Palette (Top / Bottom / Dark)

| Role | Top | Bottom | Dark | Used for |
|---|---|---|---|---|
| Jungle green (primary) | `#8EE66B` | `#38A83A` | `#1B5A1E` | Confirm, Place, Feed |
| Lagoon teal | `#6FF0D8` | `#14A99A` | `#0A5049` | Collection, Visit |
| Sky blue | `#82D8FF` | `#2E86EE` | `#103F7A` | Inventory, Info |
| Sunset coral | `#FFB08A` | `#FF6A3D` | `#7A2A10` | Breeding Center, "New!" |
| Amber gold | `#FFE36B` | `#FFAA1C` | `#874C00` | Buy, Coins, Rewards |
| Berry purple | `#D2A6FF` | `#8C4BEF` | `#3D1B78` | Journal/Encyclopedia, Research Points |
| Bark brown | `#E2B07A` | `#A86B3A` | `#4D2E14` | Build menu |
| Tomato red | `#FF8A80` | `#E8383A` | `#7A1416` | Close, Release, Danger |
| Stone | `#E3E7EE` | `#A7B0C0` | `#4A5263` | Settings, Disabled |
| Ink (body text on parchment) | `#3A2E22` | | | |

**Rarity** (frame colour / dark stroke; Epic and above animate): Common `#B8C0C8/#59616B` · Uncommon `#5BD35B/#1F6B1F` · Rare `#3BA7FF/#0F4F8F` · Epic `#A55BFF/#4A1A8F` (slow shine) · Legendary `#FFB300/#8A5200` (gold gradient rotating over 3 s) · Mythical `#FF3D7F/#7A0F35` (pan). Always print the rarity word too.

**Mutation badge colours** (24 px round chips on cards, 36 px in Inspect). Use one code per mutation, so the system stays data-driven:
Albino `#F4F4F4` (pink ring `#FF9EC4`) · Melanistic `#2A2A2A` · Golden `#FFC83D` (animated shine) · Silver `#D7DEE8` · Crystal `#9EF2FF` (shine) · Glowing / Bioluminescent `#7CFFB0` (pulse transparency 0.2↔0.5, 1.6 s) · Giant `#FF9A3D` (up-arrow glyph) · Miniature `#7FD0FF` · Rainbow (7-key gradient pan) · Frost `#BDEBFF` · Ember `#FF5A2A` · Shadow `#4B3A6B` · Celestial `#2B2F7A` + star specks.
Use icon images when they arrive. The fallback is a coloured circle plus a 1–2 letter FredokaOne code (`AL`, `GD`, `CR`). **No emoji.**

## 3. HUD (1920×1080 reference, root UIScale = clamp(viewportY/1080, 0.55, 1.25))

```
┌──────────────────────────────────────────────────────────────────────┐
│[Roblox]  [Coins 12.4K +] [RP 340 +]    [Biome chip: Greenleaf Forest]   [Lv 7 ███░ XP] [gear] │
│                                                       ┌──────────────┐ │
│ [Collection][Breed ]   left column                    │ Quest tracker │ │ right: 300×~120 card,
│ [Build     ][Journal]  2×3 grid, 84×84 icon buttons   │ ▸ Capture 3/5 │ │ collapsible to 56 px chip
│ [Inventory ][Park  ]   label under each, x=16, gap 10 └──────────────┘ │
│                         vertically centred                             │
│                                                                        │
│        [ Context bar: Capture / Feed / Inspect / Pet  (bottom-centre) ]│ only when near a creature
│ (joystick zone: bottom-left 35%×40% – KEEP CLEAR)    [Rotate][Delete]  │ build actions stack ABOVE the jump button
│                                                        (jump)          │
└──────────────────────────────────────────────────────────────────────┘
```
- **Currency chips** (top-left, under the Roblox button, all inside `CoreUISafeInsets`) are pills 200×52. The 48 px icon overlaps the left edge by 8 px, the number is FredokaOne 30 with a 3 px stroke, and a mini green "+" sits on the right. Coins are gold. Research Points are purple.
- **Biome chip** (top-centre, 360×48) shows the current biome. It is tinted with the biome colour and slides down when you enter a new biome (0.3 s Back Out). The same slot hosts toasts underneath it (max 3, 420×56, 2.5 s life).
- **Level:** a 56 px coral badge with the number, plus a 180×14 XP bar (green gradient fill, 3 px dark stroke, UICorner 1,0).
- **MVP left buttons (6):** Collection, Breed, Build, Journal, Inventory, Park. Add Quests, Map, Trade and Profile later, and at **max 8** total. Settings is the gear at the top-right. Spec §18 says not to show buttons that don't work yet: either hide them, or show a **greyed "Soon" button** (Stone palette, a 22 px coral "SOON" ribbon, and a toast when clicked).
- **Notification badge:** a red 26 px circle with a count (an egg ready, a new journal entry). It bobs 1 → 1.15 over 0.6 s, Sine InOut. At most 2 things pulse at once.
- **Context bar:** it appears when the player is within ~12 studs of an owned or wild creature. Use 200×64 wide buttons with an icon on the left. Use ProximityPrompt-style context, so there's no permanent "Capture" button (Roblox: show vital info only during gameplay).
- **Over-creature nameplate** (BillboardGui, `MaxDistance` 40, `AlwaysOnTop` false): the name in FredokaOne 22 with a dark stroke, a 2–3 mutation dot row, and a tiny happiness heart that turns red below 30%. Hide it entirely while a window is open.

## 4. CreatureCard (shared component)

Grid cell **150×190** (PC). On phones the grid is 3 columns at 92% window width.
```
Card (UICorner 14, stroke 3 = rarity dark, white→#FBF4E2 gradient)
 ├─ Viewport (130×110, top)     ← static render, 3/4 view, FOV 30, Ambient/Light #FFFFFF
 ├─ Fav star (top-left 28 px)    ← toggles favorite
 ├─ Mutation dots (top-right, up to 3 × 20 px, "+2" if more)
 ├─ Happiness ring (bottom-left of viewport, 32 px; green >60, amber 30–60, red <30)
 ├─ Name (FredokaOne 20, ink) / Species + stage (BuilderSansBold 15, #7A6A55)
 └─ Rarity band (bottom 26 px, rarity gradient, rarity word FredokaOne 16 white w/ dark stroke)
```
- **ViewportFrame performance:** hundreds of VPFs lag low-end devices, and rebuilding the whole list on every change makes it worse. Rules: (1) render **only visible cells** (page by 24, or lazily build cards as the ScrollingFrame's CanvasPosition reaches them); (2) VPFs are **static** (no per-frame camera spin; spin only the single Inspect preview); (3) on add/remove, update just that card, never `Clear()` and rebuild; (4) **no WorldModel** unless it's animated (WorldModels cost physics step time even when idle); (5) clone a lightweight "display" model (no scripts, no constraints, Anchored).
- **Sort/filter bar** (top of Collection): a 260×44 search box, a Sort pill (Rarity / Newest / Species / Happiness / Generation), a Filter pill (Species, Rarity, Has mutation, Biome, Favorites), and a count label "42 / 60 slots". Store a creature with a single "Store" button. Never use drag-and-drop as the only way to do anything (it's bad on touch).

## 5. Creature Inspect window (820×580 PC; full 92%×88% on phones)

The left 40% is a **large live ViewportFrame** that auto-rotates (8°/s, pauses on touch). The player can drag to rotate. Under it are 3 chip toggles: Baby / Juvenile / Adult preview (only stages reached). Under those is a name field (rename, server-filtered via TextService).
The right 60% has **4 tabs** (pill tabs; the active tab is full colour at 1.0, inactive tabs are white at 0.92):

| Tab | Content |
|---|---|
| **Overview** | Rarity banner, species, category, biome chip, growth stage bar, **mutation list** (36 px badge + name + rarity tier), discovery info ("Captured in Greenleaf Forest · 12 Nov"), value. Buttons: Assign to habitat (teal), Favorite, Release (red, confirm modal). |
| **Genetics** | One row per gene category (Colour, Pattern, Eyes, Size, Shape, Horns/Ears, Tail, Wings, Glow, FX): a label, then **two allele chips** (e.g. `[Teal ▲] [Albino ▽]`). ▲ = dominant (solid chip), ▽ = recessive (outlined chip, 50% fill), `?` = hidden gene (striped grey chip "Hidden"), plus the **expressed result** at the right in bold. Size uses a 0–100 bar with the species range shaded. The legend sits in a 1-line footer. This is the "readable genetics" layer: letter-pair dumps (Planet Zoo's ABCD codes) are too opaque for our audience. |
| **Family** | A 3-generation tree: the creature centred at the bottom, parents above, grandparents above them (mini cards 96×110, connected by 3 px ink lines drawn as rotated Frames). Tap a relative to open their Inspect if owned, or a ghost card "Not in your park". Shows Generation number, birth date and breeding history count. Wild-caught = a single "Wild-caught" root node. |
| **Care** | Needs bars (Hunger, Energy, Comfort, Cleanliness, Social, Environment) at 260×18 each, with an icon left and a % right. Colour by value. A **"Fix it" button next to any bar under 40%** jumps straight to the cause (open Build at Food stations, or highlight the habitat). Planet Zoo 2's quick-jump buttons were the praised part of an otherwise tangled UI. |

## 6. Breeding Center (900×600 PC)

```
┌ header: Breeding Center (coral) ─────────────────────────────── [X] ┐
│ [ Parent A slot ]     [  Possible offspring  ]     [ Parent B slot ] │
│  CreatureCard 180×220   ┌──────────────────┐        CreatureCard     │
│  "Tap to choose"        │ Colour: Teal 50% │        "Tap to choose"  │
│  gene mini-chips        │         Albino 25%│       gene mini-chips  │
│                         │ Size: 40–65       │                        │
│                         │ Mutation chance:  │                        │
│                         │  ✦ Common  ✦✦ Rare│                        │
│                         └──────────────────┘                         │
│ Requirements: ✔ same species group ✔ both adult ✔ happiness ≥60 ✘ nest │
│ [ Cost: 250 Coins ]   [ Time: 10:00 ]        [  BREED  (big green) ]  │
│ Nests: [egg 03:12][egg READY][ empty ][ locked +RP ]                 │
└──────────────────────────────────────────────────────────────────────┘
```
- **Choosing parents:** tapping a slot opens a picker sheet (a bottom sheet on phones, a right-hand drawer on PC) pre-filtered to **compatible** creatures. Incompatible ones are greyed out with the reason on hover/long-press. Never let the player pick something that will fail.
- **Offspring panel:** per gene, show the possible outcomes with % from the shared genetics config (computed client-side for display only; the server rolls). For numeric genes, show a range. The mutation line shows **categories and tier marks**, not exact %, for rare tiers ("Rare mutations possible"). Footer in small text: "Results are random. Odds shown are estimates." (Spec: don't promise exact outcomes.)
- **Requirements checklist:** a green tick or red cross row. Each red row is tappable and explains the fix.
- **Breed button** states: disabled (Stone) until all ticks are green, then green with a shine sweep. Press → Back Out pop → the egg flies into the next nest slot (0.45 s Quad In).
- **Nests/timers:** 64×64 egg tiles with a radial progress overlay (use a rotating half-frame mask or a simple fill-up bar). The time label is in FredokaOne 18. A **READY** egg pulses and gets a red badge on the HUD Breed button.
- **Hatch reveal:** a full-screen dim, then the egg shakes 3× (Rotation ±8°, 0.08 s each), cracks to white flash (0.15 s), and the creature viewport pops in (UIScale 0 → 1.1 → 1, 0.35 s Back Out). A sunburst rotates at 45°/s behind it in the **rarity colour**. Mutation badges drop in one by one (0.12 s stagger) with an escalating chime. If something new appeared (a new mutation or Journal entry), show a coral **"NEW DISCOVERY!"** ribbon. Buttons: Name it / Inspect / Close.

## 7. Build menu

- **Entry:** the HUD Build button. It hides the left column, quest card and context bar (they slide out 0.2 s) and shows the **build tray**.
- **Tray** (bottom, full width minus safe insets, height 200; on phones 170, docked *above* the joystick zone by pushing up 0 and narrowing to the centre 60%): category tabs on top. For MVP: Paths, Fences, Plants & Trees, Rocks, Water, Food/Water stations, Shelter, Decor. Use 64×64 icon tabs that scroll horizontally. Below them is a horizontal ScrollingFrame of item cards 120×140 (icon/viewport, name, price chip, and a small **"+Habitat"** tag showing which needs it satisfies, e.g. a leaf icon for "Forest comfort").
- **Placement feedback:** the ghost model at 0.5 transparency plus a SelectionBox/Highlight, green `#5BFF7A` when valid and red `#FF4D4D` when blocked. A small BillboardGui above the ghost shows the reason when it's red ("Outside your plot", "Overlapping").
- **Action column** (right side, vertically stacked **above** the jump button, 84×84 square buttons, 10 px gap): Place (green, PC: click), Rotate 90° (R), Fine rotate ±15° (Q/E, long-press on touch), Move (select an existing object), Delete (red, X), Grid toggle (G; on = teal, off = stone), Exit (red X). Each button shows its **key hint** as a 20 px dark chip at the top-right on PC and hides it on touch.
- **Touch:** tap the ground to move the ghost, then tap Place to confirm. Never place on the first tap (accidental placements are the #1 mobile build complaint). Taps that land on GUI must not fall through to the world. Check `GuiService:GetGuiObjectsAtPosition` / `UserInputService` `gameProcessed` before raycasting.
- **Gamepad:** the ghost follows the screen centre, A = place, X = rotate, Y = delete, B = exit, and LB/RB change category. Set `GuiService.SelectedObject` to the first tray card when the tray opens.
- **Habitat rating strip** (top-centre while building): a 360×44 bar showing the habitat's star rating (0–5) and the top missing need ("Needs: water"). It ticks up live as objects are placed, which is the most rewarding feedback in the loop.

## 8. Discovery Journal (Encyclopedia)

- Purple header. A tab per **biome** (MVP: Greenleaf Forest only; locked biomes shown as padlocked tabs). A sub-filter per category.
- **Grid of species cards** (same CreatureCard frame):
  - *Unknown:* ViewportFrame with `ImageColor3 = #1A1A2E` (black silhouette), name "???", a hint line ("Seen near water at night").
  - *Seen:* full colour but grey rarity band, "Seen".
  - *Captured+:* full card.
- **Species page** (opens in place, back arrow top-left): a big viewport, description, biome, diet, preferred habitat, and a **research track**: 5 steps (Seen, Captured, Bred, Mutation found, Mastered) as connected 40 px nodes on a line. Filled nodes are purple and award RP. Below it is a **mutation gallery** with all mutations for that species: found ones in colour, unfound as "?" chips. This is the long-term collection goal from Charlie's brief (rare variants to show off).
- **Completion:** a header bar "Greenleaf Forest 7/12 (58%)" plus per-category rings. Reaching 100% fires the reward popup.
- **New entry toast:** a coral toast "New species: Mossback!" with a mini viewport. The Journal button gets a red badge until the entry is viewed.

## 9. Mobile and cross-platform checklist

- Set `ScreenGui.ScreenInsets = CoreUISafeInsets` for all interactive GUIs (it avoids notches and Roblox core UI). Use `None` only for full-screen backgrounds and dims.
- Keep the bottom-left (joystick) and bottom-right (jump) corners free of important UI. Put frequent actions **near the jump button**, positioned relative to it. Thumb reach differs between phones and tablets.
- Minimum hit area is 44×44 px after scaling (Roblox cites about 9 mm). Small visuals like favourite stars get an invisible 44 px hit frame.
- On phones (viewport Y < 500): windows are 92% wide and 88% tall, tabs become a horizontal scroll, the Breeding layout stacks vertically (Parent A, Parent B, odds, Breed), and the Inspect viewport moves to the top 35%.
- **Every** keyboard shortcut has an on-screen button, and every hover tooltip has a long-press equivalent (0.4 s).
- For gamepad, set `GuiService.SelectedObject` on window open, use `NextSelection*` on the grid edges, and B closes the top window.
- Test in Studio's Device Emulator at 1920×1080, 1366×768, iPhone SE (667×375), iPhone 14 Pro (notch) and iPad.

## 10. Do / Don't (Wildworld additions to plant-zoo §10)

**Do:** use one CreatureCard everywhere · use tabs inside Inspect instead of new windows · show odds and ranges for breeding · show silhouettes for unknown species · add a "Fix it" jump button on low needs · give every build key an on-screen button · use loading states (a 0.6 s skeleton card shimmer while server data arrives) and clear red error toasts ("Not enough Coins") instead of silent failures (spec §18).
**Don't:** use emoji · use empty or decorative buttons (hide them or mark them "Soon") · show exact offspring promises · use drag-only interactions · use spinning viewports in grids · place on the first tap on mobile · open more than one big window at once · nest menus more than 2 levels deep.

---

## For UI

1. Port the plant-zoo `Kit` (Button, Window, Fx, View, Parts, init) into `src/client/UI/Kit/`. Swap `Style` to the §2 palette and the §1 parchment/teal window skin. Add `Kit.Badge(mutationId)` and `Kit.RarityFrame(card, rarity)`.
2. Build `CreatureCard.luau` (§4) first. Collection, Breeding, Journal and Build all reuse it.
3. Build the MVP screens in this order: HUD (§3) → Collection + Inspect (§4–5) → Build tray + action column (§7) → Breeding Center + hatch reveal (§6) → Journal (§8).
4. All odds and labels read from `shared/Config.luau` (species, genes, mutations, rarity colours). Don't hardcode species in UI files. The UI never decides outcomes. It only displays server results.
5. Pass §9 and the plant-zoo §10 checklist before handing to the Checker.
6. Icons: list any missing icons (Collection, Breed, Build, Journal, Inventory, Park, Coins, RP, mutation badges, build categories) in README **Charlie TODO**, all from one pack/style. Until then, use coloured-circle + letter-code fallbacks.

## Sources
- Plant-zoo baseline guide: `games/plant-zoo/research/UI_STYLE_GUIDE.md` (its sources cover the button, window, font and juice recipes)
- [Roblox: Position and size / cross-platform (reserved corners, thumb zones, context UI)](https://create.roblox.com/docs/ui/cross-platform-design)
- [Roblox: ScreenInsets enum](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)
- [Roblox: UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- [DevForum: Performance issues with lots of ViewportFrames](https://devforum.roblox.com/t/performance-issues-with-lots-of-viewportframes-mostly-occurring-on-low-end-devices/958962)
- [DevForum: Idle WorldModels consume physics step time](https://devforum.roblox.com/t/emptyidle-worldmodels-unconditionally-consume-physics-step-time-causing-significant-fps-drops-at-scale/4818531) (title only)
- [PlacementService tutorial (mobile build actions are custom buttons)](https://zblox164.github.io/PlacementService/tutorial)
- [PC Gamer: Planet Zoo 2 review (menu sprawl, quick-jump buttons)](https://www.pcgamer.com/games/sim/planet-zoo-2-review/)
- [Planet Zoo 2 breeding guide (Genetics section, Compare Mates, Genealogy)](https://gamerblurb.com/guides/planet-zoo-2-breeding-spreadsheet-guide)
- [Planet Zoo: The Animals guide (Animal Info panel, welfare)](https://one.planetzoogame.com/nl-NL/hulpcentrum/speler-guides/the-animals)
- [Creatures of Sonaria: Main Menu (creature slot cards: mutations, traits, needs)](https://creatures-of-sonaria-official.fandom.com/wiki/Main_Menu)
- [Palworld 1.0 breeding and trait inheritance](https://allthings.how/palworld-1-0-how-breeding-and-trait-inheritance-work/)
- [Pal Breeding Preview mod (players want offspring previews)](https://www.curseforge.com/palworld/lua-code-mods/pal-breeding-preview)
- [Legends: Arceus research tasks (per-species research level)](https://www.thegamer.com/pokemon-legends-arceus-research-tasks-explained-guide/)
