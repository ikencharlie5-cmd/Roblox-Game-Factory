# Open questions

1. **How should creatures be built?** Code-built parts only, AI-generated meshes via Studio MCP, or a hybrid (part bodies + one AI-mesh hero feature)? ✅ Code-built parts only (gene-recolourable, no uploads, no Charlie IDs)
   *Default until answered:* code-built parts only (original, recolourable by genes, no uploads).
2. **Trading in the first build or the next update?** The MVP spec lists park visits only; your priority list includes trading. ✅ Not in v1; secure two-sided trading is update 1 (park visits + Likes now)
   *Default:* park visits + Likes now; secure two-sided trading as the first update.
3. **Same-species breeding only for v1?** Cross-species hybrids would add more surprising babies but need extra models and balancing. ✅ Same species only in v1; hybrids are a later update
   *Default:* same species only, with 4 genes + 4 mutations for variety; hybrids later.

- [audio] Who sets the player's audio zone? I read LocalPlayer Attribute `Zone` (Hub/Park/MeadowEdge/MossyHollow/WaterfallGlade) or parts tagged `AudioZone` with Attribute `Zone`; defaults to Park. Gameplay or Graphics please provide one. (built: notes/audio.md "World contract") ✅ Gameplay WildService sets `Zone` = Meadow/Hollow/Glade/Park; Audio rekeys to those
- [audio] Creature voices need creature models tagged `Creature` with Attributes `Species`, `Mutations` (comma string), `Stage`, `State`. OK for Gameplay/Graphics? (built: CreatureVoices.luau, silent if missing) ✅ OK; Gameplay also tags wild creatures `Creature` + Stage=Adult
- [audio] Should DataService persist the volume settings (LocalPlayer Attributes `MusicVolume`, `SFXVolume`, `MusicOn`, `SFXOn`)? Client sets them, so server would need a small settings remote. (built: attributes only, not saved) ✅ Yes; Gameplay adds SaveSettings remote into data.settings, sets attrs on load
- [audio] Graphics: please tag the Glade waterfall part `WaterfallSound` and set workspace `IsNight` / `Weather` attributes if the day cycle / weather uses them. (built: falls back to Lighting.ClockTime) ✅ Graphics tags WaterfallSound; WeatherService sets workspace Weather; IsNight skipped
- [animation] The server never moves creature parts (CreatureAI only sets `Goal`/`Speed`/`State`), so the client animator walks each creature to `Goal` at `Speed` and also moves the **Hitbox locally** so clicks, prompts and nameplates stay on the visible creature. OK? (built: client moves Hitbox + parts; server Hitbox CFrame untouched) ✅ OK; Gameplay range checks use Goal +6 studs tolerance
- [animation] Capture: CaptureService doesn't exist yet. Please set creature attribute `Moment = "CaptureFail:<n>"` on a miss and `"Captured:<n>"` about 0.9 s before destroying a caught wild creature. (built: a wild creature with `ClaimedBy = me` that disappears already gets a bubble + sparkle pop) ✅ Gameplay CaptureService sets Moment CaptureFail:<n>/Captured:<n> (0.9 s before destroy)
- [animation] Visitor coin fountain: no server signal exists for "a visitor tipped". Gameplay, please increment plot Model attribute `Tips` (and set `TipAmount`) on each visitor payout, e.g. the first-60s +25. (built: client visitors walk every owned plot; fountain plays when `Tips` goes up, or via `AnimationController.Tip(plotModel)`) ✅ Gameplay increments plot Tips + sets TipAmount on every payout
- [animation] Graphics `Theme.Moments.Hatch` (shell halves) duplicates the client egg-shell burst. (built: Animation plays pooled shells on the client; set `Tuning.EggShellBurst = false` if Graphics calls Theme.Moments.Hatch on hatch) ✅ Client burst only; server never calls Theme.Moments.Hatch
- [animation] Gameplay `Models.luau` looks for `Shared.CreatureBlueprints.Build`, but Graphics' builder is `Shared.CreatureBuilder.Build`. With the fallback 3-part models the animator can only bob/hop the whole body. (built: animator works with both; no limbs/ears/tail on fallbacks) ✅ Graphics owns both; Models uses CreatureBuilder (done), fallback only on error
- [ui] Favourite creatures: worth a `FavoriteCreature(uid)` remote + saved flag? (built: no favourite star) ✅ Skip v1

- [graphics] Zone keys differ: gameplay uses `Meadow/Hollow/Glade`, Audio/Theme use `MeadowEdge/MossyHollow/WaterfallGlade`. (built: zone volumes/spawns/gates carry `Zone` = gameplay Id + `ZoneKey`; separate `AudioZone` volumes carry the audio keys. WildService sets player `Zone` to the Id, so Audio falls back to AudioZone parts — works, but one shared key set would be cleaner.) ✅ One set: Meadow/Hollow/Glade(+Park); drop twin AudioZone volumes
- [graphics] Zone gates: locked zones block by teleport (WildService), not collision. (built: walk-through ForceField veil + invisible `GateAnchor` part tagged `ZoneGate` at ground level; clients may hide the veil once unlocked.) ✅ Approved as built
- [graphics] Waterfall uses translucent part sheets + particles instead of textured Beams (no upload needed). (Charlie TODO optional: upload a white streak texture to swap in scrolling Beams.) ✅ Approved; Beam texture = optional Charlie TODO

- [gameplay] Starter creature: spec says Baby -> Adult takes 10 min / 3 feedings, but the 45-60 s hook wants breeding right after the first catch. (built: starter egg hatches as Adult via `Config.StarterHatchesAdult`; bred babies grow normally) ✅ Approved (starter hatches Adult)
- [gameplay] Spec has "storage 30 free" and "creature cap 200". (built: park slots by Capacity upgrade + 30 storage; 200 is a hard data-safety cap) ✅ Approved as built
- [gameplay] How are food bowls / feeding paid for? (built: FeedCreature is free with a 10 s per-creature cooldown; bowls hold 10 servings creatures eat on their own, refilled free via RefillStation; Auto-Feeder pass = never empty) ✅ Approved as built
- [gameplay] Likes "+1 rating/visitor/day, cap 20" added directly to park rating (0-100) is strong. (built: literal, clamped to 100; tune `Config.Economy.LikeBonusCap`) ✅ Keep per-visitor/day, LikeBonusCap 20 -> 10
- [gameplay] Exact tutorial rating numbers (22 -> 34) aren't reproducible with the rating formula. (built: formula as spec'd; a tree adds +5 enrichment so the bar always jumps) ✅ Approved; formula + tree jump
- [gameplay] Bait sources: spec lists bait prices but not how players get the first one. (built: 5 Berry bait in new saves + shop stall restock every 5 min) ✅ Approved (5 Berry bait + restock)

## Sign-off fixes
- [gameplay] VIP "Gold name + tag" promised in shop/SPEC but not built: gold "VIP" BillboardGui over VIP players' heads on CharacterAdded (UI: gold chat tag via TextChatService.OnIncomingMessage) — or remove the claim from ShopWindow INFO.VIP. ✅ Built (head billboard + chat tag)
- [graphics] Map edge has no invisible walls; players can walk over backdrop hills off the terrain onto SafetyFloor and get stuck. Add invisible boundary walls + make SafetyFloor teleport touched players to HubSpawn. ✅ Built (Terrain.Bounds + SafetyFloor teleport)
- [manager] README not publish-ready: title + emoji tag, How to play, description, icon/thumbnail ideas, pass/product names+prices+descriptions table. ✅ Done

## Studs restyle
- [graphics] Brick creatures follow STUDS_STYLE_GUIDE §4.3 sizes exactly, so adults are about 1.5–2x bigger than before (Lumibun ≈ 9 tall with ears, Pebblehorn ≈ 7 tall / 11 long, Thornstag ≈ 14 tall). Hitboxes come from the model bounds, so clicks/prompts still line up, but pad wander radius, nameplate offsets and capture ranges may want a look. (built: guide sizes; Baby ×0.6 already matches Config.Growth.BabyScale)
- [graphics] Backdrop ridges use taller terrace steps (4.8–9.6 per level) than the guide's 1.2–2.4 so they still hide the map edge; meadow hills use the guide values. (built: as described)
