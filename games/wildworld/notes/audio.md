# Audio notes (Wildworld)

Files: `src/shared/Sounds.luau` (all IDs + zone/rarity/voice maps), `src/client/Audio/SoundController.luau`
(public API), `Mixer.luau` (groups, settings, ducking, loops), `MusicDirector.luau` (zone music, silences,
ambience, reverb), `CreatureVoices.luau` (idle/happy/eat calls). `Id = 0` = silent, safe to call.

## How to call
- Client: `SoundController.Play("Name")`, `Play("Name", 1.2)` (pitch mult), `Play("Name", { Pitch, Volume, At })`.
- 3D: `SoundController.PlayAt("Name", partOrVector3, pitch?)`.
- Reveal: `SoundController.PlayReveal("Epic", { "Golden" })` (tease -> 0.3 s pause -> tier stinger + mutation layer).
- Creature: `SoundController.PlayCreature(model, "Happy" | "Eat" | "Alert" | "Idle" | "Sleep")`.
- Server: `Remotes.Event("PlaySound"):FireClient(plr, "Name", opts?)`; opts = number pitch, Instance/Vector3
  (3D), or `{ Pitch, Volume, At }`. Reveal: `FireClient(plr, "Reveal", { Rarity = "Rare", Mutations = {"Crystal"} })`.
- Music override: `require(Audio.MusicDirector).SetOverride("Music_Breeding")` while Breeding Center is open,
  `SetOverride(nil)` on close. `MusicDirector.SetZone("Hollow")` sets the player's `Zone` attribute.
- Settings (UI): `SetMusicVolume(0..1)`, `SetSFXVolume(0..1)`, `SetMusicOn(bool)`, `SetSFXOn(bool)` -> LocalPlayer
  Attributes `MusicVolume`, `SFXVolume`, `MusicOn`, `SFXOn`. SFX volume covers UI, SFX, stingers, creatures, ambience.
  DataService sets the 4 Attributes on load; each Set* call fires `SaveSettings({music, sfx, musicOn, sfxOn})` (1 s debounce).
- Old short names still work: Click, Open, Close, Error, Cash, Notify, Place, Rotate, Remove, Hatch, DailyReward.

## Mixing rules (built)
- SoundGroups Master -> Music 0.6, Ambience 0.7, SFX 0.8, Creature 0.8, Stinger 0.9, UI 0.5.
- Stingers: one at a time, higher Tier interrupts, equal/lower dropped; music ducks x0.4 (-8 dB) + 0.5 s release.
- Coins_Gain: +1 semitone per tick within 1.5 s (max +7). 0.05 s per-sound cooldown (2D only).
- SFX/UI/Creature pitch jitter +/-5% (override with PitchVar); stingers/music never jittered.
- Music crossfade 2 s; after a track ends, 20-60 s silence. Ambience beds crossfade 3 s.
- Creature idle call every 12-30 s per creature within 60 studs; max 6 voices; Baby x1.3 pitch; Golden adds
  shimmer layer, Crystal/Glowing add chime layer. Ambience one-shots 15-60 studs from camera, max 4.

## Sound list (name -> where -> caller)
| Name | Where | Caller | Id |
|---|---|---|---|
| UI_Click / UI_Hover / UI_Tab | buttons / desktop hover / tabs | UI | set |
| UI_Open / UI_Close | panel open/close | UI | set |
| UI_Error | not enough coins, can't do it | UI/server | set |
| UI_Confirm / Purchase | confirm / pass, product, upgrade bought | UI/server | set |
| Notification / ButtonUnlock | toast / new HUD button pops in | UI | set |
| Coins_Gain | visitor income tick, coin fountain | UI/server | set |
| OfflineEarnings | "While you were away" popup | UI | set |
| RP_Gain | Research Points gained | UI | set |
| LevelUp | Park Level up (stinger) | server | 2686079706 (verify) |
| QuestComplete / DailyClaim | quest claim / daily claim | UI/server | set |
| ParkTierUp | park tier rises (Good -> Excellent...) | server | set |
| Like / Upgrade / ZoneUnlock | Like a park / upgrade bought / forest area unlocked | UI/server | set |
| Build_Place, Build_PlaceWood, Build_PlaceStone, Build_PlacePlant, Build_PlaceWater | place by material | UI | Water = 0 |
| Build_Rotate / Build_Remove / Build_Invalid | build mode | UI | set |
| RatingUp | habitat rating rises (stinger tier 1) | UI/server | set |
| Feed / Pet / HappyHearts | feed bowl / pet / happy hop hearts | client/server | Feed = 0 |
| Egg_Wobble / Egg_Crack / Baby_Chirp | egg wobble / crack / baby pops | animation/server | Crack, Chirp = 0 |
| Breed_Start / Breed_Ready / InstantHatch | breeding started / egg ready / dev product | UI/server | set |
| Bait_Throw / Capture_Throw / Trust_Up | bait / net / trust meter step | client | built-in swoosh |
| Capture_Wobble | play with pitch 1.0, 1.12, 1.25 per wobble | client | set |
| Capture_Success / Capture_Fail | capture result | server | set |
| Discover_New / Journal_NewEntry | first sighting / journal step | server/UI | set |
| Reveal_Common..Reveal_Legendary | via PlayReveal(rarity) | server "Reveal" | set |
| Mutation_Tease | riser before Rare+ mutated reveal | PlayReveal | 0 |
| Mutation_Golden / _Albino / _Crystal / _Glowing | flavour layer on reveal | PlayReveal | set |
| RareNearby | mutated/Epic+ wild spawn within 80 studs (PlayAt creature) | gameplay client | set |
| ServerAnnounce | another player got a Legendary | UI | set |
| Voice_Squeak / Grunt / Yip / Snort / Bleat / Munch | creature banks (Lumibun 1.3, Mossback 0.8, Emberfox 1.1, Pebblehorn 0.9, Thornstag 0.95) | CreatureVoices | 0 |
| Voice_Chime / Voice_Shimmer | mutation voice layers | CreatureVoices | set |

## Music and ambience (automatic)
| Zone | Music day / night | Bed | One-shots | Reverb |
|---|---|---|---|---|
| Hub | Music_Hub 1845197284 "Village Day" / Music_Park_Night 1845208657 "Sleepy Village" | Amb_Park_Bed / Amb_Night_Bed (0) | birds, crowd / owl, frog | Plain |
| Park | Music_Park_Day 1839620427 "Spring Is Coming Ukulele" / Music_Park_Night | same | same | Plain |
| Meadow | Music_Forest 9041797490 "Hopeful Horizons" (verify) | Amb_Forest_Bed | birds, rustle, gust, woodpecker | Forest |
| Hollow | Music_Forest | Amb_Hollow_Bed (forest bed, pitch 0.9) | same | Forest |
| Glade | Music_Glade 1844232632 "Rippling River 60" (verify) | Amb_Forest_Bed + Amb_Waterfall (3D) | birds, splash, rustle | Forest |
Also: Music_Menu 9041800311 "Dandelion Wish" (verify; use via SetOverride on loading), Music_Breeding (0),
Amb_Rain_Bed 1516791621 layered when workspace `Weather` = "Rain"/"Storm".

## World contract I read (all optional; defaults to Park)
- LocalPlayer Attribute `Zone` = Hub | Park | Meadow | Hollow | Glade, or parts tagged
  `AudioZone` with Attribute `Zone`.
- Night: workspace Attribute `IsNight` (bool), else Lighting.ClockTime < 6 or >= 18.
- workspace Attribute `Weather`. Tag `WaterfallSound` on the waterfall part (3D loop).
- Creature models tagged `Creature` with Attributes `Species`, `Mutations` ("Golden,Crystal"), `Stage`, `State`.

## ID sources
- Roblox_UI_* / ProSoundEffects / DailySoundsFX / APMOfficial IDs reused from plant-zoo (found via Studio
  Creator Store search by the orchestrator).
- Roblox docs examples: 127645268874265, 3422389728, 1516791621.
- APM/Roblox library music (bloxodes.com listings): 1845197284, 1839620427, 1845208657, 1845986486; new picks
  9041797490, 9041800311, 1844232632 (titles only, not listened to — verify).
- Third-party list, unverified: 2686079706 (Level Up).
- Built-in: `rbxasset://sounds/swoosh.wav` (check extension in Studio).

## Search terms for Id = 0 (Creator Store -> Audio, prefer creator Roblox / ProSoundEffects / APM)
Build_PlaceWater "water splash small" · Feed "crunch munch cute" · Egg_Crack "egg crack" · Baby_Chirp
"baby creature chirp" · Mutation_Tease "magic riser short" · Voice_Squeak "bunny squeak" · Voice_Grunt "creature
grunt cute" · Voice_Yip "fox yip" · Voice_Snort "animal snort small" · Voice_Bleat "deer bleat soft" ·
Voice_Munch "eating crunch" · Music_Breeding "tender piano soft" · Amb_Night_Bed "night crickets" ·
Amb_Waterfall "waterfall" · Amb_Bird "bird chirp" · Amb_Rustle "leaves rustle" · Amb_Gust "wind gust" ·
Amb_Woodpecker "woodpecker" · Amb_Crowd "crowd park distant" · Amb_Owl "owl hoot" · Amb_Frog "frog croak" ·
Amb_Splash "water plop".
Note: the "F major" stinger rule can't be guaranteed with library sounds; swap stingers by ear if they clash.
