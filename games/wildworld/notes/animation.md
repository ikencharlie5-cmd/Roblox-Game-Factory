# Animation notes (Wildworld)

All world animation runs on the **client** in `src/client/Animation/`. It is started from `Main.client.luau`
(a pcall'd `AnimationController.Start()`, so a failure can't break the UI). There is one `RenderStepped` loop,
one `workspace:BulkMoveTo` per frame (`Batch`), pooled FX (nothing is created per frame) and no network traffic.

## Files
| File | What |
|---|---|
| `AnimationController` | Start(), the loop, public API |
| `Tuning` | every animation number: tiers, idle, walk, moods, eggs, visitors, sway, mutation colours, species/personality feel |
| `Batch` | collects part CFrames and runs one BulkMoveTo (FireCFrameChanged) |
| `Rig` | builds a procedural rig from a creature Model (bones from `Anim`, rest from `Rest`, neck from `HeadPivot`) |
| `CreatureState` | per-creature state + eyes/hide/size/VFX-mute helpers |
| `CreaturePose` | per-frame pose: walking to Goal, idle, moods, limbs, moment overlay, squash & stretch |
| `CreatureMoments` | starts one-shot moments (+ their FX), mutation reveal timer, captured hide |
| `CreatureHooks` | attribute and `Reveal` remote -> moments |
| `Creatures` | registry, distance sort, tiers, budget |
| `Poses` | pure moment curves |
| `Eggs` | egg wobble (speeds up near hatch), ready hops, crack + shell burst |
| `Visitors` | client-only park visitors + tip coin fountain |
| `Scenery` | tree canopy sway, lantern flicker, placement drop-in thud |
| `Fx` / `FxPools` | pooled sparkle/dust bursts, floating text (hearts, z, +N), coins, shells, bubble, ring, flash |
| `Sfx` | optional sound cues through `Audio/SoundController.PlayAt` (Egg_Wobble, Egg_Crack, Baby_Chirp, HappyHearts) |

## Creature contract (matches CreatureBuilder + CreatureService/WildService)
- Found by tag `Creature` / `WildCreature`, or by any Model with a `Species` attribute. Eggs are excluded (`IsEgg`, `EggId`, `HatchAt`, name `Egg`).
- Hitbox = child `Hitbox` or PrimaryPart. The client moves the **Hitbox locally** along with the visual,
  because the server never moves parts. This keeps clicks, prompts, nameplates and `GetPivot` on the visible creature.
- Movement: the visual root walks to `Goal` (model pivot position) at `Speed` studs/s. That is the same speed the
  server dead-reckons with, so the two stay in sync. It snaps if more than 40 studs off. With no `Goal`, it stays at its spawn pivot.
- Bones per part: `Anim` = Body, Head, EarL/EarR, Tail, LegFL/LegFR/LegBL/LegBR, Wing (side from X), Eye. If a part
  has no `Anim`, the bone comes from its name, then its Role (Eye/EyeShine/Cheek go to Head), then the nearest tagged part.
- Rest offsets: the part attribute `Rest` (relative to Hitbox) if present, else read once at registration.
- Attributes read: `State`, `Goal`, `Speed`, `Hunger`, `Happy`, `Personality`, `Stage` (Baby = livelier),
  `Mutations`/`Pulse` (reveal colour, glow pulse), `Wild`/`ClaimedBy`/`Trust`, `LastFed`, `LastPet`, `Uid`, `Moment`.

## What animates
- **Idle:** body bob 0.12 studs / 1.4 s, breathing squash, blink every 3–6 s (Ball eyes hide, mesh/Block eyes squash),
  ear flicks (Shy creatures flick more), tail wag 15° at 2 Hz (Happy ≥ 70 / Play / Social: 30° at 4 Hz), and the head looks
  around. Within 15 studs the head turns to the nearest player and the body follows.
- **Walk:** legs swing ±25° (diagonal pairs) at 3 Hz scaled by speed, walk bob and head counter-bob. Lumibun hops
  (1-stud arcs with a landing squash).
- **States:** Sleep (eyes shut, sunk lower, head droop, slow breathing, floating "z"), Eat/Drink (munching nods),
  Socialize (head tilts), Play (frequent Hop/Spin/Happy), ReactToPlayer (faces the player and does a Happy hop on entry).
  Hungry (`Hunger` < 30) gives a 10° head droop and a slower tail. Night slows everything a little.
- **Idle actions** every 4–9 s × the personality factor: Shy Look/Hop/Sniff, Lazy Stretch/Sniff, Playful Hop/Spin/Wiggle,
  Social Hop/Look/Wiggle, Curious Sniff/Look/Hop.
- **Glowing / `Pulse`:** creature lights pulse 0.9–1.2× over 2 s (full tier only).

## Moments (`Poses.Duration` names)
Hop, Happy (2 hops + hearts), Spin, Wiggle, Look, Sniff, Stretch, Eat, Feed (munch then a spinning hop + hearts), Pet (wiggle +
hearts), Sad, Pop (scale 0→1.15→1, Back easing), **Hatch** (pop + dust ring + flash, then a jump + 360° spin; mutation VFX stays off
and turns on 0.5 s after the pop with a burst in the mutation colour; Golden/Crystal get a bigger burst, flash, ring and star),
Celebrate, Discover, Thud (drops 2.5 studs, then landing dust), Captured (shrinks and spins into a bubble), CaptureFail (shakes,
bubble pops, hops away).

| Trigger (all replicated, no new remotes) | Moment |
|---|---|
| `Reveal("Hatch", {uid})` (existing remote) | Hatch on the creature with that `Uid` (queued if the model arrives later) |
| a creature appearing within 20 studs of an egg that just burst | Hatch |
| `Reveal("Discovery", {species})` | Discover on the nearest creature of that species (within 60 studs) |
| `LastFed` changes / `LastPet` changes | Feed / Pet |
| `State` becomes ReactToPlayer | Happy |
| `Trust` goes up (wild) | Sniff, or Happy if it jumps by 30 or more |
| a wild creature with `ClaimedBy == me` disappears | bubble + sparkle pop where it stood |
| **`Moment` attribute set to `"Name"` or `"Name:<n>"`** | that moment (the suffix lets the same moment repeat) |

**Hooks for other branches**
- Server: `model:SetAttribute("Moment", "Celebrate:" .. tick)` on any creature.
- Client: `AnimationController.Play(model, "Happy")`, `.CoinFountain(pos, n?, target?)`, `.Burst("Sparkle"|"Dust", pos, n?, color?)`,
  `.Float(text, pos, color?, size?)`, `.Tip(plotModel)`.

## Eggs
An egg is anything tagged `Egg`, or a Model with `IsEgg` / `EggId` / `HatchAt`, or a Model named `Egg`.
- Progress comes from `HatchAt` or `ReadyAt` (server unix time) and `Duration` (default 120 s). `Ready` or `Starter` counts as fully ready.
- Wobble bursts come every 4 s when the egg is fresh and every 0.6 s when it is ready. The angle grows from 4° to 14° and the
  frequency from 7 Hz to 14 Hz. A ready egg also hops every 1.6 s (the pulsing starter egg).
- Hatch: `Moment = "Hatch"` cracks it (0.4 s shake). An egg that disappears near the camera and is ours (`OwnerId`), or was
  ≥ 97% done, plays the shell halves + sparkles + flash + Egg_Crack. `Tuning.EggShellBurst = false` turns off the client shells.

## Visitors
For every plot tagged `Plot` with a non-zero `OwnerId`/`OwnerUserId`, there are 3 visitors (`Visitors` attribute overrides, max 6). Visitors are 8-part studded blocky R6 minifigs (Plastic, Studs on top, block head + 2 square eyes, shirts from `Palette` brick colours).
They walk a 16-point square loop 4 studs outside the `LandSize`/`Land` square (so they never cross habitats).
They pause to look in and emote ("Wow!", hearts). Only plots within 150 studs are simulated. When the plot attribute `Tips` goes up,
a random visitor throws a coin fountain (coins home in on the player within 30 studs) and shows `+TipAmount`.

## Scenery
- Tree sway: canopy parts around every part named `Trunk` (Graphics' Nature kit), scanned 6/30/90 s after join, plus Models
  tagged `Sway`. The nearest 600 parts within 90 studs update at 15 Hz. Groups that leave range snap back to rest.
- Lantern flicker: lights under `NightLight`/`Lantern` tags (creature lights excluded). At night and within 90 studs they flicker ±12%.
- Placement thud: a new Model with `ItemId` (or tag `PlacedItem`) in **your own** plot (`OwnerId`) drops 2.5 studs with dust
  and a ring. Other plots' items stream in silently.

## Performance
- Tiers are re-sorted every 0.25 s. Full (frame rate) within 60 studs, at most 60 creatures and 1,500 parts. Mid (10 Hz: root + body
  bob + moments) to 140 studs. Far (2 Hz, rigid, only when moved) beyond that. Off-screen creatures are skipped, except
  those within 20 studs.
- Egg animation within 90 studs, visitors within 150, sway ≤ 600 parts within 90. Size writes only happen during
  Pop/Hatch/Captured and on blinking Block eyes.

## Checks
stylua, selene and rojo are not installed in this sandbox, so `check.sh` skipped them and CI runs them. I could not compile-check
the code locally (running a downloaded luau binary was blocked), so it was reviewed by hand. It has not been playtested in Studio.
