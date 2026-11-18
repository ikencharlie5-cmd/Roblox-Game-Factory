# Sprout Zoo — UI Style Guide (build-in-code)

Owner: UI branch. Written by R&D after Charlie's playtest: the UI "looks cheap and bad".
Everything here can be built with `Instance.new`. The only image assets are icons.

Look we're going for: **chunky cartoon simulator UI**, like Grow a Garden, Pet Simulator 99, Adopt Me and the
"stud/brainrot" simulator kits sold on BuiltByBit. That means saturated gradient buttons, thick dark outlines,
a darker "base" under each button, white bold text with a dark outline, and bouncy motion.

---

## 1. Why our UI looks cheap, and the fix for each

| Cheap tell (what we have now) | Premium fix |
|---|---|
| Emoji as icons (🌼💧🌵, sidebar emojis) | Image icons only (Charlie's uploads + a single icon pack). For creatures, use a ViewportFrame render. No emoji anywhere in the HUD or buttons. |
| Flat single-colour buttons | A UIGradient on every button (light top to dark bottom), plus a highlight strip on the top half |
| Thin 2 px outline, colour close to the fill (`Kit.Darker(c, 0.2)`) | A **3–4 px** UIStroke in a *much* darker shade of the fill (about 55–65% darker) |
| No depth | A "base" frame under each button, 4–6 px lower and darker, plus an optional soft shadow |
| Cream panels with a thin outline | A coloured header bar, a thick wood/dark stroke, a gradient body, inset cards and a pattern |
| GothamBold body text, dark ink text on buttons | **White** FredokaOne with a dark UIStroke on every button and number |
| Things appear instantly | Popups bounce in (UIScale 0 to 1, Back easing), buttons squash when pressed, numbers tick up |
| Too many visible buttons | 6–8 main buttons. Everything else lives inside them. |
| Mixed styles (each window looks different) | One `Kit.Button` / `Kit.Window` used everywhere, with the same radius, stroke and font |

Source themes: on the DevForum, consistency, quick asymmetric (non-linear) animation, gradient shine on major buttons,
staggered entrances and sound on every action are what separate polished UI from cheap UI
([DevForum: polished & crisp](https://devforum.roblox.com/t/what-makes-a-ui-have-that-polished-and-crisp-look-and-how-do-i-get-that/703624)).
The standard designer recipe is a saturated gradient with the brightest colour on top, a darker copy shifted down for depth, an outside
stroke, FredokaOne text with a thick stroke, white icons with the same depth, and a masked shine
([“Make Your Roblox UI Look 10x Better” transcript](https://sozai.app/transcript/make-roblox-ui-look-better/index.md)).
Roblox's own guidance: put buttons in a contrasting container, use highlights/shadows for a tactile feel, and grey out unusable buttons
([Roblox UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

---

## 2. Scaling system (do this first)

Design everything in **pixels at a 1920×1080 reference**. Put **one `UIScale` on each ScreenGui's root frame**:
`scale = math.clamp(viewport.Y / 1080, 0.55, 1.25)`, and update it on `Camera:GetPropertyChangedSignal("ViewportSize")`.
- Why: UIStroke thickness, corner radius and text all scale together, so a 4 px stroke stays chunky on phones and on 4K.
  (Pure Scale sizing leaves strokes at fixed pixels, which makes them look thin on large screens and fat on phones.)
- Use fixed `TextSize` (no TextScaled) inside this system. If something must use TextScaled, add a `UITextSizeConstraint`.
- Anchor HUD clusters to screen edges with Scale **position** (e.g. `UDim2.new(0, 16, 0.5, 0)`), and use pixel **sizes**.
- Keep `ScreenInsets = CoreUISafeInsets` (already set in Kit.Gui). Touch targets must be at least 44 px. Roblox cites a 9×9 mm minimum
  ([Choose an art style](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style)).

---

## 3. Buttons (exact recipe)

Structure (all built in code):
```
ButtonRoot (Frame, transparent, the size you want, e.g. 200×64)  ← UIScale here for animation
 ├─ Base   (Frame) colour = Dark,  pos (0, 0, 0, 6), same size, UICorner     ← the 3D "lip"
 ├─ Shadow (Frame) black, BackgroundTransparency 0.75, pos (0, 0, 0, 10), ZIndex below Base (optional)
 └─ Face   (TextButton/ImageButton) BackgroundColor3 = WHITE, size (1,0,1,-6), UICorner
     ├─ UIGradient   Color = ColorSequence(Top → Bottom), Rotation = 90
     ├─ UIStroke     Thickness 3.5, Color = Dark, ApplyStrokeMode = Border, LineJoinMode = Round
     ├─ Highlight (Frame) white, pos (0,6,0,4), size (1,-12,0.42,0), BackgroundTransparency 0.55, UICorner (radius-4)
     │     └─ UIGradient Transparency = NumberSequence(0.2 → 1), Rotation = 90
     ├─ Shine (Frame) white, full size, ClipsDescendants on Face, UIGradient for the sweep (see §8)
     ├─ Icon  (ImageLabel)  left or top
     └─ Label (TextLabel) FredokaOne, white, UIStroke Contextual 2.5 px, Color = Dark
```

| Property | Value |
|---|---|
| **Face BackgroundColor3** | `#FFFFFF`. **Important:** UIGradient *multiplies* the background, so a white base gives exact gradient colours. |
| **UICorner** | Wide buttons: `UDim.new(0, 14)` at 64 px tall. Square icon buttons: `UDim.new(0, 18)` at 84 px. Pill/currency chips: `UDim.new(1, 0)` |
| **UIGradient** | `ColorSequence.new({Keypoint(0, Top), Keypoint(0.5, Mid), Keypoint(1, Bottom)})`, `Rotation = 90`. Keypoint 0 is the **top**. |
| **UIStroke** | Thickness **3.5** (buttons), **4** (panels), **2.5** (small chips). Colour = `Dark` from the palette (§6), never black or grey. |
| **Base (lip)** | Same colour as the stroke (`Dark`). Offset **6 px** down for big buttons, **4 px** for small ones. |
| **Shadow** | Black, transparency **0.75**, offset 10 px down. Optional `UIShadow` (see note). |
| **Highlight strip** | Top 42% of the face, white, transparency 0.55, fading to 1 at the bottom |
| **Label** | FredokaOne, TextSize 28 (wide buttons) / 20 (under-icon labels), `TextColor3 = #FFFFFF` |
| **Disabled** | Swap the gradient to `#C9C9C9 → #9A9A9A`, stroke `#5A5A5A`, and set Active = false |

Note on `UIShadow`: Roblox now documents a `UIShadow` class (BlurRadius, Offset, Spread, Color, Transparency; it follows the UICorner),
but the May 2026 recap listed native drop shadows as a **Studio Beta**
([UIShadow API](https://create.roblox.com/docs/en-us/reference/engine/classes/UIShadow.md),
[Weekly recap May 2026](https://devforum.roblox.com/t/weekly-recap-may-11-to-may-15-2026/4638298)).
Build the frame shadow by default. Only add UIShadow inside `pcall(Instance.new, "UIShadow")` as a bonus layer.
The same applies to the UIStroke `BorderStrokePosition` / `StrokeSizingMode` / `BorderOffset` properties: they're documented, but may need the "Improved UIStrokes" beta
([UIStroke API](https://create.roblox.com/docs/reference/engine/classes/UIStroke.md)). Don't depend on them.

**Button types**
- **Side/HUD buttons:** icon-only square, 84×84, with the label *under* the button (outside the face), FredokaOne 18, white with a 2 px dark stroke.
  This is the PS99 / Grow a Garden pattern, where the icon does the talking.
- **Action buttons (Buy, Claim, Release):** wide, 200–260 × 64, with an icon on the left (40 px) and the label right of it.
- **Price buttons:** green, with a small currency icon plus the number. Robux prices use the Robux green and a Robux icon.
- **Close button:** red, 52×52, `UICorner(0, 14)`, a white bold "X" (FredokaOne 34) with a dark-red stroke, placed **overlapping the top-right corner**
  of the window (AnchorPoint 0.5,0.5 at Position (1,-6,0,6)) and rotated **-6°**. This is the classic simulator look.

**Press / hover animation** (a UIScale child on ButtonRoot)
| Event | Tween |
|---|---|
| Hover (PC) | scale **1.0 → 1.06**, 0.12 s, Quad Out. Icon rotation 0 → 8°. |
| Press down | scale **→ 0.92**, 0.07 s, Quad Out. Face moves down by the lip height (pos Y +6), so it "sinks" onto the base. |
| Release | scale **→ 1.0**, 0.25 s, **Back Out**. Face returns to Y 0. Play the click sound. |
| Leave | scale → 1.0, 0.12 s |
Reference values: a UI-animation skill set uses hover 1.12 / press 0.95, popups 0.30 s Back Out, closes 0.20 s Quad In, and says UI "snaps best at 0.15–0.35 s"
([roblox-ui-animation skill](https://unpkg.com/roblox-mcp-pro@1.0.51/.agents/skills/roblox-ui-animation/SKILL.md)). We use a smaller hover (1.06) because our buttons are big.

---

## 4. Panels / windows

```
Window (Frame, AnchorPoint 0.5,0.5, centre, e.g. 820×560) + UIScale (open anim)
 ├─ Base   dark wood lip, offset 8 px down
 ├─ Body   BackgroundColor3 white + UIGradient #FFF6DC → #FFE6B0 (Rotation 90), UICorner 22, UIStroke 4 #6B4A2E
 │   ├─ Pattern (ImageLabel, ScaleType Tile, TileSize 64×64, ImageTransparency 0.92) ← subtle leaf/dot/stud pattern
 │   └─ Content (Frame, transparent) UIPadding 20 px, top padding 84 px
 ├─ Header (Frame) height 64, width (1, -40), centred at the top, sticking up 24 px above the body edge (pos Y -24)
 │   gradient Leaf #8BE36A → #3FAE2A, UIStroke 4 #1F5E14, UICorner 18, lip 5 px
 │   └─ Title: FredokaOne 38, white, UIStroke 3.5 #1F5E14, plus an icon (44 px) left of the title
 └─ Close button (red, §3) overlapping the top-right corner
```
- **Header colour = category colour**: Shop is green, Index purple, Inventory blue, Store/Robux gold-pink, Release teal, Settings grey-blue.
  Players learn the colours. Roblox recommends a colour theme where each colour maps to key information
  ([Choose an art style](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style)).
- **Inner cards** (items in the grid): white `#FFFFFF` with UICorner 14, UIStroke 3 in the **rarity colour's dark shade**, a rarity gradient band at the bottom
  (rarity colour → darker), and a ViewportFrame or icon on top. Grid cell 150×180, gap 12 px, UIPadding 16 px.
- Leave a ~24 px gap between the outer container and the inner panels ([decorated shop UI tutorial](https://devforum.roblox.com/t/how-to-make-a-decorated-shop-ui-using-built-in-tools/2065783)).
- **Pattern without an asset:** if there's no tile image, skip it. A gradient body plus an inset white card area is still fine. Never fake a pattern
  with dozens of frames.
- **Tabs** (Shop: Seeds / Decor / Boosts): pill buttons on top of the content. The active tab is full colour and scale 1.0. Inactive tabs are white with a coloured stroke and scale 0.92.
- **ScrollingFrame:** ScrollBarThickness 8, ScrollBarImageColor3 `#6B4A2E`, background transparent, `AutomaticCanvasSize = Y`.
- **Behind open windows:** a `BlurEffect` in the Camera, Size tweened 0 → 10 over 0.2 s, plus a dim frame (black, transparency 0.6). Only one big window open at a time.

---

## 5. Fonts and text

| Use | Font | Size @1080p | Stroke |
|---|---|---|---|
| Window titles, big banners | `Enum.Font.FredokaOne` (or **LuckiestGuy** for event banners only) | 38–56 | UIStroke Contextual 3.5–4, header's dark colour |
| Button labels | FredokaOne | 20–28 | 2.5, button's dark colour |
| Numbers (currency, prices, timers) | FredokaOne | 26–34 | 3, `#2B1D14` |
| Body / descriptions | `Enum.Font.BuilderSansExtraBold` (or BuilderSansBold) | 18–20 | none on light cards (ink `#4A3426`); 2 px dark stroke on top of the 3D world |
| Rarity tag | FredokaOne, uppercase | 16–18 | 2, rarity dark shade |

- **GothamBold/GothamBlack are removed fonts** (they map to Montserrat) per the [Font enum](https://create.roblox.com/docs/reference/engine/enums/Font.md).
  Replace `Style.FontBody = GothamBold` with `BuilderSansExtraBold`.
- FredokaOne is the most iconic Roblox simulator font ([10x UI transcript](https://sozai.app/transcript/make-roblox-ui-look-better/index.md)). Use stylized fonts only for titles and alerts
  ([Choose an art style](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style)).
- Text stroke = a **UIStroke child with `ApplyStrokeMode = Contextual`**, not `TextStrokeTransparency` (the legacy stroke is thin and jaggy).
  Never tween a text UIStroke's Thickness: the docs warn it causes flicker and costs performance ([appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers.md)).
- White text with a dark stroke on all buttons and HUD numbers. Dark text only on the white/cream cards inside windows.
- Use number abbreviations (1.2K, 3.4M, 5.6B) with a max of 4 significant characters on the HUD.

---

## 6. Colour palette (UI)

Each button colour comes as **Top / Bottom / Dark** (Dark = stroke + lip + text stroke).

| Role | Top | Bottom | Dark |
|---|---|---|---|
| Leaf green (primary, Plant, Claim, Shop) | `#8BE36A` | `#3FAE2A` | `#1F5E14` |
| Sun gold (Buy, featured, Daily) | `#FFE36B` | `#FFAE1A` | `#8A4F00` |
| Sky blue (Inventory, Info, Visit) | `#7FDBFF` | `#2A8CF0` | `#0F427F` |
| Blossom pink (Store, Robux offers) | `#FFA3D4` | `#F2479A` | `#7A1048` |
| Berry purple (Index, Rebirth) | `#CFA0FF` | `#8A47F0` | `#3E1B7A` |
| Pond teal (Release, Quests) | `#7DF0DE` | `#1FB5A5` | `#0B5A52` |
| Tomato red (Close, Cancel, Danger) | `#FF8A80` | `#E8383A` | `#7A1416` |
| Stone (Settings, disabled) | `#E3E7EE` | `#A7B0C0` | `#4A5263` |
| Window body | `#FFF6DC` | `#FFE6B0` | `#6B4A2E` (wood) |
| Card | `#FFFFFF` | `#F4EEDC` | rarity dark |
| Text ink (on cards) | `#4A3426` | | |
| Currency chip bg | `#2B1D14` at transparency 0.35 | | |

**Rarity** (colour / dark stroke / card gradient). Keep the existing hues; add the dark shade:
| Rarity | Colour | Dark | Extra |
|---|---|---|---|
| Common | `#B8C0C8` | `#59616B` | none |
| Uncommon | `#5BD35B` | `#1F6B1F` | none |
| Rare | `#3BA7FF` | `#0F4F8F` | soft glow |
| Epic | `#A55BFF` | `#4A1A8F` | glow + slow shine |
| Legendary | `#FFB300` | `#8A5200` | animated gold gradient (Rotation spins 0→360 over 3 s) |
| Mythical | `#FF3D7F` | `#7A0F35` | pink/purple gradient pan |
| Secret | `#1A1A1A` | `#000000` | **rainbow** gradient on the stroke (7 keypoints, Offset pan loop) |

Use a rarity *gradient* on the UIStroke of Legendary and above (a UIGradient child of the UIStroke works, per the
[appearance modifiers doc](https://create.roblox.com/docs/ui/appearance-modifiers.md)). Don't rely on colour alone: also show the rarity word.

---

## 7. HUD layout (what top simulators do)

Observed patterns: Grow a Garden has 3 top-centre teleport buttons (Seeds / Garden / Sell), cash at the bottom-left, a hotbar at the bottom,
a bag at the top-left and a weather icon at the bottom-right ([Gamer Tweak GAG guide](https://gamertweak.com/how-to-play-grow-a-garden/)).
PS99, Bee Swarm and the "simulator UI kits" all use a **left-side column of big square icon buttons**, a **currency stack** on the left,
and boosts/timers on the right ([Modern Cartoon Simulator UI kit contents](https://builtbybit.com/resources/modern-cartoon-simulator-ui.109159/)).
Roblox says: on mobile, show only what's useful now, and let one button reveal sub-buttons ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

Sprout Zoo layout (1080p px; anchored with Scale positions):
```
┌────────────────────────────────────────────────────────────────────┐
│[Roblox menu]      [ ☀ Weather banner + timer ]          [Store $] │ top: banner centre (420×56), Store button top-right (gold-pink, pulses)
│ ┌───────────┐                                         ┌─────────┐ │
│ │ $ 12.4K   │  currency chips, top-left under the     │ boosts  │ │ right column: active boosts 56×56 with
│ │ ✿ 340     │  Roblox button (y≈ 60 px)                │ x2 05:12│ │ a radial/time label; Daily gift with "!" badge
│ └───────────┘                                         └─────────┘ │
│ [Shop][Inv ]   ← left column: 2×4 grid of 84×84 icon buttons,      │
│ [Index][Build]   vertically centred, x = 16 px, gap 10 px          │
│ [Release][Quests]                                                  │
│ [Daily][Visit]                                                     │
│                                                                    │
│            [ Build / Breed / Photo context bar (bottom-centre) ]   │ only shows when relevant
│ (mobile joystick zone: bottom-left 35%×40%)    (jump: bottom-right) │ KEEP CLEAR
└────────────────────────────────────────────────────────────────────┘
```
- **Max 8 left buttons**, 2 columns. Settings goes into a small gear (48 px) at the top-right next to Store, not in the main column.
- **Currency chip:** a pill (UICorner 1,0), dark translucent background `#2B1D14` at 0.35, a 3 px stroke `#2B1D14`, a 48 px icon overlapping the left edge
  (sticking out 8 px), a FredokaOne 30 number, and a "+" mini green button on the right that opens the Store at currency packs.
- **Notification badges:** a red 26 px circle, white number, 2.5 px dark-red stroke, at the top-right corner of any button with something to claim. It bobs (scale 1 → 1.15, 0.6 s, Sine InOut, looping).
- **Bottom-left / bottom-right** on touch: no buttons (joystick and jump). Check `UserInputService.TouchEnabled` and push the context bar up 140 px.
- **Notifications/toasts:** top-centre under the weather banner, stacked max 3, each a 420×56 pill, slide down + fade, 2.5 s life.
- **First 60 seconds:** only Shop + Plant arrow + currency visible; reveal other buttons with a pop as the tutorial reaches them (staggered 0.06 s).

---

## 8. Icons

- **Kill all emoji in the UI.** They render differently per device, have no outline, and instantly read as amateur.
- **Charlie's uploaded icons** (in `Style.Icons`): Store, Settings, Daily, Release, Cash, DoubleCash, VIP, AutoGardener, CashBoost.
  Use these first. For the remaining ones (Shop, Inventory, Index, Build, Quests, Visit, Hope currency, Weather icons, biome icons),
  put them in the README **Charlie TODO** list to upload from the same pack/style, so everything stays consistent.
- **Where to get matching free icons** (Creator Store → Images/Decals, or Toolbox → Images). Search terms:
  `simulator icons`, `cartoon icon pack`, `simulator ui icons`, `shop icon cartoon`, `backpack icon cartoon`, `book index icon`,
  `quest scroll icon`, `gift icon cartoon`, `hammer build icon`, `seed bag icon`, `coin icon cartoon`, `leaf icon outline`.
  Pick **one** pack/artist so all icons share the same thick dark outline and glossy shading. Free off-platform packs exist
  ([Free Roblox Icons](https://builtbybit.com/resources/free-roblox-icons.116747/), [gvesster free icon pack](https://gvesster.itch.io/free-icon-pack));
  if Flaticon icons are used, credit them ([Flaticon attribution note](https://devforum.roblox.com/t/how-to-make-ui-styled-for-simulator-detailed-tutorial/2895762)).
- **Icon style:** an outlined cartoon look (thick dark outline, 2-tone shading, white specular dot), shown at 56–64 px inside 84 px buttons.
  Give the icon a fake "depth" with a duplicate ImageLabel behind it, `ImageColor3 = Dark`, ImageTransparency 0.4, offset (0, 3).
- **Creatures/plants in cards:** use a **ViewportFrame** with the real 3D model (camera FOV 30, 3/4 view, `Ambient = #FFFFFF`, `LightColor = #FFFFFF`, `LightDirection = (-1,-1,-1)`).
  This is how pet games show pets, and it needs no uploads.
- **Biome/weather fallback until icons arrive:** a coloured circle chip (biome colour gradient + white 2-letter code in FredokaOne + dark stroke). That's better than emoji.

---

## 9. Animations and juice

| Effect | Recipe |
|---|---|
| **Window open** | UIScale 0.6 → 1.0, 0.30 s **Back Out**. The dim frame fades 1 → 0.6 in 0.2 s. Children (cards) stagger in: each card UIScale 0.8 → 1, 0.22 s Quad Out, delay index × 0.03 s (cap at 0.4 s total). |
| **Window close** | UIScale → 0.8 + GroupTransparency → 1 (use a CanvasGroup only for the close fade), 0.18 s Quad In, then Visible = false |
| **Shine sweep** (featured buttons: Store, Claim, Daily) | White Shine frame with UIGradient Transparency `0:1, 0.45:1, 0.5:0.35, 0.55:1, 1:1`, Rotation 20. Tween **Offset (-1, 0) → (1, 0)** over 0.7 s Quad Out, wait 2.5 s, loop. Based on the [UIGradient animations post](https://devforum.roblox.com/t/4-uigradient-animations-including-rainbow/557922) (offset -1 → 1, ~1 s, Circular Out, 2.5 s pause). |
| **Idle pulse** (Store, Claim-ready) | UIScale 1 → 1.06 → 1, 1.2 s Sine InOut, loop. Only **1–2 buttons** pulse at once. |
| **Number tick-up** | Hold a NumberValue per currency. On change, tween it to the new value over 0.35 s Quad Out and format on `.Changed`. On a gain, also pop the chip (UIScale 1.12 → 1, 0.25 s Back Out) and float a green "+1.2K" label up 40 px, fading over 0.6 s. |
| **Coin fly** (collect) | Spawn 6–8 coin ImageLabels at the world point (`Camera:WorldToViewportPoint`), scatter them ±40 px (0.15 s), then tween each to the currency icon (0.45 s Quad In, stagger 0.04 s), and pop the chip when each arrives. The polished-UI thread recommends animating multiple items flying to a counter ([DevForum](https://devforum.roblox.com/t/what-makes-a-ui-have-that-polished-and-crisp-look-and-how-do-i-get-that/703624)). |
| **Reward / rare popup** | Centre card UIScale 0 → 1.1 → 1 (0.35 s Back Out), a rotating sunburst behind it (ImageLabel or wedge frames, Rotation +45°/s), rarity-coloured gradient, and confetti. The "Claim" button shines. |
| **Toast** | Slide from Y -60 → 0 + fade in (0.25 s Back Out), live 2.5 s, fade out 0.2 s |
| **Tab switch** | The content slides 30 px + fades (0.15 s). The active tab pops to 1.0. |
| **Sound** | Every press: click. Hover: a soft tick at volume 0.25. Open: a whoosh-pop. Purchase: a coin cascade. |

Keep motion purposeful. Roblox warns that too much motion overwhelms players ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

---

## 10. Do / Don't checklist (UI branch must pass this)

**Do**
- [ ] One `Kit.Button(variant, size, icon, text)` and one `Kit.Window(title, color, icon)`, used by **every** screen.
- [ ] Every button: white-base Face + UIGradient (Rotation 90) + UIStroke 3.5 dark + 6 px lip + highlight strip + UIScale press anim + sound.
- [ ] Every window: a coloured header sticking out of the top, a red rotated close button overlapping the corner, a gradient cream body, a 4 px wood stroke, and Back Out open.
- [ ] White FredokaOne + a Contextual UIStroke on all button labels and HUD numbers. BuilderSansExtraBold for body text.
- [ ] Root UIScale from viewport height; pixel sizes at the 1080p reference.
- [ ] Image icons or ViewportFrames only.
- [ ] Rarity = colour + word + (Epic+) an animated gradient.
- [ ] At most 8 left HUD buttons + Store + gear. Joystick/jump zones clear on touch.
- [ ] Numbers abbreviated and tick up; currency chip pops on gain.
- [ ] Test at 1920×1080, 1366×768, iPhone SE (667×375) and iPad in Studio's Device emulator.

**Don't**
- [ ] No emoji in any button, label, chip or title.
- [ ] No GothamBold/GothamBlack/SourceSans/Arial/Legacy fonts.
- [ ] No flat buttons (no gradient), no strokes thinner than 2.5 px, no grey/black strokes on coloured buttons (use the dark shade of the same hue).
- [ ] No `TextStrokeTransparency` legacy strokes, no tweening text stroke Thickness.
- [ ] No coloured BackgroundColor3 under a UIGradient (it multiplies and goes muddy). The base is white.
- [ ] No Linear easing for UI. No instant show/hide.
- [ ] No more than 2 elements pulsing/shining at the same time.
- [ ] No full-screen windows on PC (max ~820×560 at 1080p). Windows can fill 92% width on phones.
- [ ] No dark text on coloured buttons.

---

## 11. Example: premium button with Instance.new (reference for the UI branch)

```lua
--!strict
local TweenService = game:GetService("TweenService")

type Palette = { Top: Color3, Bottom: Color3, Dark: Color3 }
local LEAF: Palette = {
	Top = Color3.fromHex("#8BE36A"), Bottom = Color3.fromHex("#3FAE2A"), Dark = Color3.fromHex("#1F5E14"),
}

local function make(class: string, props: { [string]: any }, parent: Instance?): any
	local i = Instance.new(class)
	for k, v in props do (i :: any)[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function premiumButton(parent: Instance, text: string, icon: string?, pal: Palette, size: Vector2): TextButton
	local LIP, RADIUS = 6, 14
	local root = make("Frame", { Size = UDim2.fromOffset(size.X, size.Y), BackgroundTransparency = 1 }, parent)
	local scale = make("UIScale", { Scale = 1 }, root)

	-- drop shadow + 3D lip
	local shadow = make("Frame", { Size = UDim2.new(1, 0, 1, -LIP), Position = UDim2.fromOffset(0, LIP + 4),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.75, ZIndex = 1 }, root)
	make("UICorner", { CornerRadius = UDim.new(0, RADIUS) }, shadow)
	local base = make("Frame", { Size = UDim2.new(1, 0, 1, -LIP), Position = UDim2.fromOffset(0, LIP),
		BackgroundColor3 = pal.Dark, ZIndex = 2 }, root)
	make("UICorner", { CornerRadius = UDim.new(0, RADIUS) }, base)

	-- face: WHITE base so the gradient colours are exact
	local face = make("TextButton", { Size = UDim2.new(1, 0, 1, -LIP), BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "", AutoButtonColor = false, ZIndex = 3, ClipsDescendants = false }, root)
	make("UICorner", { CornerRadius = UDim.new(0, RADIUS) }, face)
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, pal.Top), ColorSequenceKeypoint.new(1, pal.Bottom) }) }, face)
	make("UIStroke", { Thickness = 3.5, Color = pal.Dark, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round }, face)

	-- glossy highlight on the top half
	local hl = make("Frame", { Size = UDim2.new(1, -12, 0.42, 0), Position = UDim2.fromOffset(6, 4),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, ZIndex = 4 }, face)
	make("UICorner", { CornerRadius = UDim.new(0, RADIUS - 4) }, hl)
	make("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.2, 1) }, hl)

	-- icon + label
	local x = 14
	if icon then
		make("ImageLabel", { Image = icon, BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(0, x, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 5 }, face)
		x += 46
	end
	local label = make("TextLabel", { Text = text, Font = Enum.Font.FredokaOne, TextSize = 28,
		TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.new(1, -x - 10, 1, 0),
		Position = UDim2.fromOffset(x, 0), ZIndex = 5 }, face)
	make("UIStroke", { Thickness = 2.5, Color = pal.Dark, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, label)

	-- juice
	local function tw(inst: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
		TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	end
	face.MouseEnter:Connect(function() tw(scale, 0.12, { Scale = 1.06 }) end)
	face.MouseLeave:Connect(function()
		tw(scale, 0.12, { Scale = 1 }); tw(face, 0.08, { Position = UDim2.fromOffset(0, 0) })
	end)
	face.MouseButton1Down:Connect(function()
		tw(scale, 0.07, { Scale = 0.92 }); tw(face, 0.07, { Position = UDim2.fromOffset(0, LIP) })
	end)
	face.MouseButton1Up:Connect(function()
		tw(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back); tw(face, 0.12, { Position = UDim2.fromOffset(0, 0) })
	end)
	return face
end
```
(Shine sweep: add a white child frame to `face` with the §9 transparency gradient and loop-tween its UIGradient.Offset.)

---

## Sources
- https://devforum.roblox.com/t/what-makes-a-ui-have-that-polished-and-crisp-look-and-how-do-i-get-that/703624
- https://devforum.roblox.com/t/how-to-make-ui-styled-for-simulator-detailed-tutorial/2895762
- https://devforum.roblox.com/t/how-to-make-a-decorated-shop-ui-using-built-in-tools/2065783
- https://devforum.roblox.com/t/4-uigradient-animations-including-rainbow/557922
- https://devforum.roblox.com/t/how-to-make-semi-skeumorphic-ui/1943325 (found; forum was in maintenance when fetched)
- https://devforum.roblox.com/t/3074034 (Designing UI – Tips and Best Practices; listed, not fetched)
- https://devforum.roblox.com/t/weekly-recap-may-11-to-may-15-2026/4638298
- https://devforum.roblox.com/t/studio-beta-uistroke-improvements-scaling-offsets-and-more/3958036 (listed; maintenance)
- https://devforum.roblox.com/t/studio-beta-upgraded-ui-gradients/4846594 (listed)
- https://create.roblox.com/docs/ui/appearance-modifiers.md
- https://create.roblox.com/docs/reference/engine/classes/UIStroke.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/UIShadow.md
- https://create.roblox.com/docs/ui/9-slice.md
- https://create.roblox.com/docs/reference/engine/enums/Font.md
- https://create.roblox.com/docs/production/game-design/ui-ux-design
- https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style
- https://create.roblox.com/docs/ui/animation
- https://sozai.app/transcript/make-roblox-ui-look-better/index.md ("Make Your Roblox UI Look 10x Better" video transcript)
- https://unpkg.com/roblox-mcp-pro@1.0.51/.agents/skills/roblox-ui-animation/SKILL.md
- https://gamertweak.com/how-to-play-grow-a-garden/
- https://builtbybit.com/resources/modern-cartoon-simulator-ui.109159/
- https://builtbybit.com/resources/ui-pack-grow-a-garden-style.102616/ (GAG-style kit; page failed to load)
- https://adrianart.itch.io/gag-ui-pack
- https://builtbybit.com/resources/huge-clean-stud-gui-pack-20-frames.110766/
- https://builtbybit.com/resources/free-roblox-icons.116747/
- https://gvesster.itch.io/free-icon-pack
