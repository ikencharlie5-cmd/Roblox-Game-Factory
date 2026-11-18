# Open questions

1. **How should creatures be built?** Code-built parts only, AI-generated meshes via Studio MCP, or a hybrid (part bodies + one AI-mesh hero feature)? ✅ Code-built parts only (gene-recolourable, no uploads, no Charlie IDs)
   *Default until answered:* code-built parts only (original, recolourable by genes, no uploads).
2. **Trading in the first build or the next update?** The MVP spec lists park visits only; your priority list includes trading. ✅ Not in v1; secure two-sided trading is update 1 (park visits + Likes now)
   *Default:* park visits + Likes now; secure two-sided trading as the first update.
3. **Same-species breeding only for v1?** Cross-species hybrids would add more surprising babies but need extra models and balancing. ✅ Same species only in v1; hybrids are a later update
   *Default:* same species only, with 4 genes + 4 mutations for variety; hybrids later.

- [audio] Who sets the player's audio zone? I read LocalPlayer Attribute `Zone` (Hub/Park/MeadowEdge/MossyHollow/WaterfallGlade) or parts tagged `AudioZone` with Attribute `Zone`; defaults to Park. Gameplay or Graphics please provide one. (built: notes/audio.md "World contract")
- [audio] Creature voices need creature models tagged `Creature` with Attributes `Species`, `Mutations` (comma string), `Stage`, `State`. OK for Gameplay/Graphics? (built: CreatureVoices.luau, silent if missing)
- [audio] Should DataService persist the volume settings (LocalPlayer Attributes `MusicVolume`, `SFXVolume`, `MusicOn`, `SFXOn`)? Client sets them, so server would need a small settings remote. (built: attributes only, not saved)
- [audio] Graphics: please tag the Glade waterfall part `WaterfallSound` and set workspace `IsNight` / `Weather` attributes if the day cycle / weather uses them. (built: falls back to Lighting.ClockTime)
- [animation] The server never moves creature parts (CreatureAI only sets `Goal`/`Speed`/`State`), so the client animator walks each creature to `Goal` at `Speed` and also moves the **Hitbox locally** so clicks, prompts and nameplates stay on the visible creature. OK? (built: client moves Hitbox + parts; server Hitbox CFrame untouched)
- [animation] Capture: CaptureService doesn't exist yet. Please set creature attribute `Moment = "CaptureFail:<n>"` on a miss and `"Captured:<n>"` about 0.9 s before destroying a caught wild creature. (built: a wild creature with `ClaimedBy = me` that disappears already gets a bubble + sparkle pop)
- [animation] Visitor coin fountain: no server signal exists for "a visitor tipped". Gameplay, please increment plot Model attribute `Tips` (and set `TipAmount`) on each visitor payout, e.g. the first-60s +25. (built: client visitors walk every owned plot; fountain plays when `Tips` goes up, or via `AnimationController.Tip(plotModel)`)
- [animation] Graphics `Theme.Moments.Hatch` (shell halves) duplicates the client egg-shell burst. (built: Animation plays pooled shells on the client; set `Tuning.EggShellBurst = false` if Graphics calls Theme.Moments.Hatch on hatch)
- [animation] Gameplay `Models.luau` looks for `Shared.CreatureBlueprints.Build`, but Graphics' builder is `Shared.CreatureBuilder.Build`. With the fallback 3-part models the animator can only bob/hop the whole body. (built: animator works with both; no limbs/ears/tail on fallbacks)
- [ui] PlaceItem / RemoveItem / RotateItem argument shape? (built: one table `{itemId, cellX, cellZ, rot}` for Place, `{cellX, cellZ}` for Remove; cells 4 studs, 0-based from the plot's min corner)
- [ui] How does the client find my plot and creatures in the world? (built: player attrs `PlotCenter`/`PlotSize` or tag `Plot` + `OwnerId`; creatures tag `Creature` with `Uid`/`OwnerId` or `WildId`; eggs tag `Egg` with `EggId`/`ReadyAt`; landmarks tags `FoodBowl`, `ForestGate` - see notes/ui.md)
- [ui] Is there a rename / sell / buy-bait remote? (built: Rename/Sell buttons only show if `RenameCreature` / `SellCreature` exist; Bait uses `BuyBait(key)` if it exists, else `BuyUpgrade(key)`)
- [ui] Instant Hatch: which egg does a purchase apply to? (built: UI prompts the `InstantHatch*` product sized by time left; server should apply it to the soonest egg)
- [ui] Favourite creatures: worth a `FavoriteCreature(uid)` remote + saved flag? (built: no favourite star)
