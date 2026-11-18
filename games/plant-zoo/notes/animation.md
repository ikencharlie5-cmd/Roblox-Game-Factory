# Animation notes (Sprout Zoo)

All world animation runs on the **client** (`src/client/Animation/`), started from `Main.client.luau`
(2 lines: require + `AnimationController.Start()`). One `RenderStepped` loop, no network, no per-frame
Instance creation. Server Hitboxes never move.

## Files (animation-owned)
| File | What |
|---|---|
| `AnimationController` | Start(), the single loop, `Play(model, moment)`, `Burst(kind, pos, n?, color?)` |
| `Tuning` | all animation numbers (visual only; gameplay numbers stay in Shared/Config) |
| `Moments` | pure pose curves + pooled particle bursts (Dust/Sparkle/Coins/Leaves via Theme.Effects) |
| `Creatures` | per-creature idle + moments (writes Bob.C0, MeshPart.Size, Model:ScaleTo) |
| `Items` | watches `workspace.ZooItems` + `ReserveCreatures`, turns attribute changes into moments |
| `Visitors` | client-side visitors walking plot paths (BulkMoveTo, legs/arms swing, chat bubbles) |
| `Scenery` | tree canopy + flower sway (wind wave), night lantern flicker |
| `Rewards` | tip-jar coin burst + jar hop, Release float-away |

## Handover from Graphics (server `World/Motion.luau`)
`Motion.luau` keeps its API so `ItemVisuals`, `Reserve`, `WorldService` are unchanged:
- `Motion.Creature`, `Motion.Pop` → **no-ops** (clients animate).
- `Motion.SetVisitors(folder, plotModel, plotCf, n)` → only sets attributes on the plot's `Visitors`
  folder: `Count` (number) and `Origin` (CFrame = plot pivot). Each client spawns its own visitors.
No call sites in `World/*` needed editing.

## Creatures (contract: Root anchored at feet → Weld "Bob" → Body; parts welded to Body)
- Idle (Grown): bob (`BobHeight`, fish/bird ×2), breathing squash & stretch (mesh creatures only, nearest
  `MaxSquash` inside `NearRadius`; resizes MeshParts and lifts by `(sy-1)*centerY` so feet stay down),
  wander ≤ `Wander` = 1.0 stud from home via Bob.C0 (stays within the 1.2-stud Hitbox rule),
  turns to face the local player within 14 studs, random Hop / Spin / Wiggle / Look every 5–12 s.
- Thriving: faster bob, actions ~2× as often, HappyHops. Night (`Lighting.IsNight`): slower, droopy, fewer actions.
- Growing plants (Seed/Sprout/Bud): gentle sway only.
- Culling: re-sorted every 0.5 s, nearest `MaxActive` = 60 within 120 studs animate; others are reset and frozen.
- World Reserve creatures get the same idle (with wander).

## Moments (what triggers them)
| Trigger (replicated, no remotes) | Moment |
|---|---|
| new item, Stage Seed | **Pop** (scale 0→1.15→1, Back easing) + dust |
| new grown creature placed | **Thud** (drop 2.5 studs, landing squash) + dust |
| new / moved decor | decor drop-in thud + dust |
| Visual rebuilt with new Stage | **Bounce** + leaves; to Grown: **Celebrate** (jump + spin) + rarity-colour sparkles |
| item `Color` / `Weather` set (≠ None) | **Celebrate** + sparkles |
| item `Thriving` → true | **HappyHops** + leaves |
| item moved (same Stage) | Thud |
| `TipJar.Amount` drops | coins arc to the local player (if ≤ 14 studs away, else spray + drop), coin particles, jar hop |
| new entry in `GameState.WorldReserve` | **Release float-away**: client copy rises 16 studs, spins, fades, from where the creature stood (removed-item cache) or from the Release Altar |

Items present when the player joins are "armed" only after 3 s, so joining doesn't spam moments.

**Hooks for other branches:**
- Client: `require(Client.Animation.AnimationController).Play(itemModel, "Celebrate")`
  (Pop | Bounce | Celebrate | Hop | HappyHops | Spin | Wiggle | Look | Thud); `.Burst("Sparkle", pos, 30, color)`.
- Server: set attribute `Moment = "<name>"` on a `ZooItems` item Model (plays when the value changes).

## Visitors / scenery
- Visitors: same look and path grid as before (nodes ±12/±37), walk 6 studs/s with limb swing and chat
  bubbles ("Thriving!" when the plot's `ThrivingCount` > 0). Only simulated within 150 studs of the camera.
- Sway: scans `workspace.World` at WorldReady + 6 s and + 31 s. Primitive trees (`Trunk` + leaf balls),
  primitive flowers (0.2×1.2 stem + bloom), and asset Models named `Tree*` / `Flower*` (≤ 12 parts).
  40-stud grid; within 90 studs, ≤ 600 parts, updated at 15 Hz in one BulkMoveTo; out-of-range groups snap back.
- Lantern flicker: `NightLight` PointLights within 90 studs at night (±12 % brightness).
- Not done: stall awning flutter (stall parts have no reliable names; low value).

## Checks
stylua + luau-compile clean on every changed file; `rojo build` OK. selene could not run locally
(it can't download the Roblox std through the proxy) — CI runs it. Not playtested in Studio (no Studio MCP in this run).
