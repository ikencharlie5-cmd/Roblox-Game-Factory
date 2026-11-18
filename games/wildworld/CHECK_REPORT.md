# Wildworld — Check Report (round 2)

**Verdict: PASS** (0 blocking, 1 minor left)

`scripts/check.sh wildworld`: stylua, selene and rojo aren't installed locally, so they were skipped. CI reported green.
No Roblox Studio MCP is connected, so there was no playtest. These findings come from reading the code.

## Round 1 issues: re-verified
- [ui] Build grid on rotated plots: **fixed.** PlotInfo.CFrame (PlotInfo.luau:62-75) levels the plot the same way as PlotService.PlotCFrame. ToCell, CellCFrame and BuildGrid all work in plot space, and the math matches PlacementService (CellCentre + ToWorld + rot).
- [gameplay] Berry trust decays before capture: **fixed.** CaptureService.luau:246-248 skips decay while the wild is claimed.
- [ui/gameplay] UnlockZone unreachable: **fixed.** ParkWindow has zone cards (ParkWindow.luau:162-197) and a client ProximityPrompt on each `ZoneGate` anchor (221-258). Zone Ids match across Config.Zones, Layout and the Forest tags, and the server re-checks level and cost.
- [audio] Server sound names missing: **fixed.** Every Guard.Sound name, including the dynamic `Weather_<Name>` names (Sunny/Rain/RainbowShower), resolves through Sounds.Aliases. A full scan found no unknown names.
- [animation] Visitors never spawned: **fixed.** It accepts the tagged Base part, maps Models to PrimaryPart (Base), and watches `workspace.World.Plots`. EconomyService writes TipAmount/Tips onto PlotService.PlotPart (the same tagged Base part).
- [gameplay] Hub DailyChest/ShopStall prompts: **fixed.** Guard.WirePrompt picks up prompts under the tagged models (now and later). The server fires Reveal "OpenWindow" with Daily/Shop, and Main.client.luau:176 opens the window. Both window names exist.
- [ui] Tutorial feed range: **fixed.** Tutorial.luau:122-145 only enables "Feed it" within InteractRange-2. Otherwise it shows "Walk closer" with a world arrow.
- [gameplay] DataService autosave/release race: **partly fixed** (see Minor).
- Minor round 1 fixes: starter-species spawn bias (WildService.luau:89-114, Config.Capture.StarterSpeciesBias) is done. Server `position` maps to `At` (SoundController.luau:31-33). Feed, Egg_Crack and Baby_Chirp have fallback IDs. Ping/2 is used (CaptureService.luau:181). SaveNow returns false on lockLost, so receipts are retried. All done.

## New contracts checked (no breakage)
SaveSettings is declared as a CLIENT_EVENT and created on the server. SettingsService clamps and rate-limits it and writes data.settings, which is in DataSchema. The client debounces it, and SettingsWindow goes through the SoundController setters. Every client `Net.*` name and every server `Guard.Bind`/`Remotes.*` name is declared in Remotes.luau.

## Minor
- [gameplay] src/server/Services/DataService.luau:80-90 + 276-282 — The transform guard `if leaving[player] and not release` only works while `leaving[p]` is set. PlayerRemoving clears `leaving[p] = nil` straight after the release save. An autosave or SaveNow whose UpdateAsync attempt failed and is in its `task.wait(attempt)` retry can run after that cleanup and write `lock = {JOB}` back. The next server then blocks the player for SessionLockStaleSeconds. This is rare: it needs a failed DataStore call right before leaving. — In the transform, use `if not release and cache[player] ~= data then return nil end` (cache is cleared on leave), or check the same thing before each retry.

## Notes (not bugs)
- `DiscoverySpot` tags (Forest.luau:207) are still not read by gameplay. They're harmless decoration.

## First 60 seconds (traced)
1. You spawn 20 studs in front of your plot centre. The "Hatch!" button and an arrow to the egg appear. Hatching plays the server EggCrack sound (now aliased). ✔
2. "Walk closer" (disabled) shows until you're within 28 studs, then "Feed it" works. You get the +25 tip, and the coin fountain plays on the plot. ✔
3. Build → Tree highlighted. The ghost and grid line up with the rotated plot, and the item lands where the ghost was. ✔
4. Catch: walk to the forest, then Throw Bait (1 Berry = 40 trust, no decay while claimed) → HOLD NET works. ✔
5. Breed: a matching-species catch is likely (60% bias). The first egg is Golden, and the Instant Hatch upsell shows. ✔
