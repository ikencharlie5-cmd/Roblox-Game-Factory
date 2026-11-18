# Good Game Checklist (Manager's final sign-off)

The game is NOT done until the Manager marks every item ✅ (or ➖ with a reason it doesn't apply).
Any ❌ goes back to the branch in [brackets] to fix.

## 0. Look test — BLOCKING [Checker, Graphics, UI, 3D Art]
Judged ONLY from real screenshots in `games/<slug>/screens/`. No screenshots = LOOK TEST NEEDED.
- [ ] Spawn screenshot grades B or better next to the Look target references
- [ ] HUD and shop screenshots look like a top game's UI (not default Roblox, no emoji icons)
- [ ] Every prop/creature/building is a real model or mesh, not stacked Parts
- [ ] Lighting has mood (not flat daylight grey); colors match the spec palette
- [ ] Would this screenshot make a kid click the game? If no → ❌

## 0b. Scope — small and deep [Manager]
- [ ] v1 is ONE core loop and ONE polished zone (more zones only if they're already polished)
- [ ] ≤ 8 gameplay Services (not counting Data/Guard/Signals/AssetLoader)
- [ ] Every system that shipped is finished and juicy; half-done systems are cut, not shipped

## 1. First 60 seconds — the hook [UI, Gameplay]
- [ ] Player knows what to do within 10 seconds, with no reading required
- [ ] First reward lands within 15 seconds
- [ ] First upgrade/purchase is possible within 60 seconds
- [ ] The big goal (next zone, rebirth, boss, top of leaderboard) is visible early
- [ ] Spawn looks impressive — first screenshot moment

## 2. Core loop [Gameplay]
- [ ] The loop is clear: do X → earn Y → spend on Z → do X faster/better
- [ ] Every action has an obvious result
- [ ] There's a choice to make (not just one button forever)
- [ ] Idle/AFK progress or offline earnings if it fits the genre

## 3. Progression & content [Gameplay, Graphics]
- [ ] At least 30–60 minutes of content before things repeat
- [ ] At least 3 zones/tiers/worlds that look and feel different
- [ ] Rebirth/prestige or another long-term goal
- [ ] Numbers grow satisfyingly (costs and rewards scale, no dead walls)
- [ ] Collectibles or rarities (pets, items, mutations) if the genre supports it

## 4. Retention — reasons to come back [Gameplay, UI]
- [ ] Daily reward with a streak
- [ ] Something time-based (events, restocks, growing timers, quests)
- [ ] Saved progress feels safe (data saves; nothing lost on rejoin)
- [ ] A visible "next unlock" at all times

## 5. Social [Gameplay, UI]
- [ ] Leaderboard (in-world board or leaderstats)
- [ ] Players can see each other's progress or show off (titles, rare items, effects)
- [ ] Something better with friends (trading, co-op, gifting, bonus) if it fits

## 6. Monetization — earns but stays fair [Gameplay, UI]
- [ ] 2+ Game Passes (e.g. 2x Cash, VIP, Auto-collect) with clear value
- [ ] 1+ Dev Product (cash pack, skip, spin)
- [ ] Shop is easy to find but never blocks free players from fun
- [ ] Purchases give instant visible feedback
- [ ] Optional: Premium Payouts friendly (reason for Premium players to stay)

## 7. Game feel / juice [UI, Graphics, Audio]
- [ ] Every button: hover/press animation + click sound
- [ ] Every reward: popup number, particles, and a sound
- [ ] Big moments (level up, rebirth, rare drop) feel BIG: screen effect + special sound
- [ ] Nothing feels laggy or unresponsive

## 7b. Animation [Animation]
- [ ] Creatures never stand frozen: idle bob/squash, occasional hops or wiggles
- [ ] Key moments animate: plant pop-in, stage-up, bloom/mutation celebration, coin burst, Release
- [ ] Scenery has gentle motion (sway, flicker) without hurting phone performance

## 8. Visuals & world [Graphics]
- [ ] Consistent art style and color palette
- [ ] No flat grey boxes or untextured filler
- [ ] Lighting/atmosphere set (Sky, Atmosphere, ClockTime) to match the mood
- [ ] Clear paths — players can't get lost or stuck
- [ ] Kill floors/invisible walls where players could fall or escape

## 9. Sound & music [Audio]
- [ ] Background music that fits the mood (and a mute toggle)
- [ ] SFX for every click, purchase, reward, and error
- [ ] Different music or ambience per zone if there are zones
- [ ] Volumes balanced (music under SFX)

## 10. UI / UX [UI]
- [ ] Looks premium, not cheap: follows research/UI_STYLE_GUIDE.md (gradients, thick outlines, shadows, real fonts)
- [ ] Main buttons use image icons, not emoji (Charlie's uploaded icons or Creator Store icon pack)
- [ ] In Studio mode: screenshot reviewed side-by-side with a top game's UI
- [ ] Works on phone, tablet, PC, and console (Scale sizing, ≥44px buttons, no hover-only actions)
- [ ] Nothing off-screen or overlapping on a small phone
- [ ] Menus open/close smoothly and can be closed with one tap
- [ ] Numbers are formatted (1.2K, 3.4M)
- [ ] Settings menu (music, SFX)

## 11. Stability & security [Gameplay, Checker]
- [ ] Server validates every remote (no free money exploits)
- [ ] Remotes rate-limited
- [ ] No errors in the console during a full playthrough
- [ ] Data: autosave, save on leave, BindToClose, defaults for new fields
- [ ] Works with 1 player and with a full server

## 12. Performance [Graphics, Gameplay]
- [ ] Map parts are anchored; part count reasonable for phones
- [ ] No server loops moving parts every frame
- [ ] Particles/effects are cleaned up (Debris or :Destroy)

## 13. Ready to publish [Manager → Charlie TODO]
- [ ] Catchy title + emoji tag (e.g. "Grow a Cloud ☁️")
- [ ] Game description written (in the game README)
- [ ] Icon + thumbnail ideas written for Charlie
- [ ] Game Pass / Product names, prices, and descriptions written for Charlie
- [ ] Charlie TODO list is complete and short
