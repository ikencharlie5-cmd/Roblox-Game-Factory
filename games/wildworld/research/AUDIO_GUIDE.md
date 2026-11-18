# Wildworld — Audio Guide (R&D Audio)

## Summary
- **Mood:** bright, wonder-filled, cozy. Melodic percussion (marimba, vibraphone, celesta, soft piano) is the core palette. Each biome adds its own instruments (Forest = acoustic guitar + flute + woodwinds). Music is sparse and leaves 20–60 s of silence between tracks so creature and discovery sounds stand out.
- **Ambience = loop bed + random one-shots** for each biome (and the player park). A 30–60 s loop runs under random spatial one-shots (birds, rustle, gusts, water) with several variations each. SoundService.AmbientReverb changes by zone (Forest, Cave, Mountains, UnderWater).
- **Creature voices come from a small set of base sounds, given an identity in code.** Each species has a base pitch and a call set. Mutations change the playback: Giant ×0.75 pitch, Miniature ×1.35, Crystal/Glowing add a chime layer, Frost adds reverb. That gives one voice per species and a distinct sound per mutation, without needing hundreds of uploads.
- **Discovery and mutation stingers scale with rarity:** 5 tiers, with longer, richer sounds at higher tiers. All musical stingers are in **one key (F major / F Lydian)**. Only one stinger plays at a time; a higher tier interrupts a lower one, and music ducks −8 dB while it plays. Legendary is capped at about 3.5 s, matching the spec's "exciting without overwhelming." A rare creature spawning nearby plays a soft proximity shimmer.
- **Use only safe sources:** the client's built-in `rbxasset://sounds/*` (always plays), audio uploaded by Roblox / Roblox-licensed partners from the Creator Store (APM tracks can be found by their exact title), or Charlie's own uploads. Never re-upload commercial game sounds. Verified numeric IDs were scarce, so most entries below are exact Creator Store search terms, with `Id = 0` plus a Charlie TODO where none was found.

## 1. Music
Reference (mechanics/style only):
- Slime Rancher 2 builds every track on marimba, vibraphone and piano. Each zone has its own instrument palette, and each area gets 3 day and 3 night tracks, pairing an active theme with a relaxed one.
- Casual reward games keep music sparse, with random 5–40 s gaps, so feedback sounds land.

| Track key | Where | Mood / search terms (Creator Store → Audio → Music) | Vol |
|---|---|---|---|
| `Music_Park_Day` | own park / visiting parks | "whimsical marimba", "playful pizzicato", "cheerful acoustic light" | 0.25 |
| `Music_Park_Night` | park, night | "gentle music box", "calm celesta lullaby" | 0.2 |
| `Music_Forest` | Greenleaf Forest | "adventure acoustic guitar flute", "woodland wonder" | 0.25 |
| `Music_Menu` | first join / loading | "magical wonder orchestral light" | 0.3 |
| `Music_Breeding` (optional) | breeding UI open | "tender piano soft" | 0.2 |
| Later biomes | Desert "hand drum oud light", Frost "chimes sleigh bells calm", Coral "steel drum ukulele calm", Ember "low marimba tribal light", Mystic "ethereal choir harp" | 0.25 |

Rules:
- Crossfade 2.0 s when entering a zone. After a track ends, wait `random(20, 60)` s before the next one.
- Music lives in its own SoundGroup (`Music`, default 0.6) and the player can toggle it.
- APM workflow: find a mood on apmmusic.com, then search the **exact title in quotes** on the Creator Store, using the duration filter. Only use the copy uploaded by Roblox/APM.

## 2. Biome ambience (bed + one-shots)
Bed: a looping, non-positional `Sound` in SoundService (or an `AudioPlayer` wired directly to an `AudioDeviceOutput`), fading 3 s in and out on zone change. One-shots: spawn a `Sound` on a random part or attachment 15–60 studs from the camera so they come from a direction. Use RollOffMode `InverseTapered`, RollOffMinDistance 10, RollOffMaxDistance 120. Randomize PlaybackSpeed 0.92–1.08 and volume ±15%.

| Zone | Bed (loop, vol) | One-shots (variations, interval s, vol) | AmbientReverb |
|---|---|---|---|
| Park (day) | "meadow ambience" / "light breeze" 0.3 | birds ×6+ (8–20), distant visitor chatter "crowd park distant" (25–50, 0.15), fountain/water near water parts (positional loop, Max 50) | Plain |
| Park (night) | "night crickets" 0.25 | owl ×2 (30–70), frog ×3 (10–25) | Plain |
| Greenleaf Forest | "forest ambience" 0.35 | birds ×8 (6–15), leaf rustle ×4 (10–25), wind gust ×4 (20–45), woodpecker (40–90) | Forest |
| River / lake / waterfall | positional loops: "stream gentle" (Max 60, 0.5), "waterfall" (Max 90, 0.7) | splash/plop ×3 (15–40) | — |
| Desert (later) | "desert wind" 0.3 | sand hiss, distant hawk | Plain |
| Frostpeak (later) | "cold wind howl soft" 0.3 | ice creak, snow crunch | Mountains; Cave in ice caves |
| Coral Coast (later) | "ocean waves shore" 0.35 | seagull, bubbles | UnderWater when the camera is below the surface |
| Emberlands (later) | "lava bubbling" 0.3 | rumble, ember crackle | Quarry / Cave |
| Mystic Valley (later) | "magical ambience shimmer" 0.25 | chimes, soft whispers of wind | Forest |

Search tips: use broad terms ("ambience", "environment"), then synonyms ("breeze", "gust"). For beds, sort longest first and pick clips over 30 s; for one-shots, sort shortest first.

## 3. Creature vocals
Design approach (layering, pitch-down = bigger, use emotional states, add breaths/small grunts between rare calls):
- Give each species `Sound = { Base = "<bank>", Pitch = n, Calls = {Idle, Happy, Eat, Alert, Sleep} }` in the creature config. The spec already lists "Sound configuration" as a creature data field.
- Banks to search for (Creator Store SFX): "cute creature chirp", "small animal squeak", "cartoon creature coo", "purr", "creature grunt cute", "bird trill", "deer bleat soft", "fox yip", "bunny squeak", "creature yawn". Use 3–5 variations per call.
- MVP species → bank (suggested): Mossback = low grunt/coo (pitch 0.8), Lumibun = squeak + tiny chime (1.3), Thornstag = soft bleat (0.95), Emberfox = yip + faint crackle (1.1), 5th species picks an unused bank.
- Mutation modifiers (multiply or add): Giant PlaybackSpeed ×0.75; Miniature ×1.35; Albino/Melanistic no change; Golden adds "coin shimmer" layer at 0.3; Crystal/Glowing/Bioluminescent add "glass chime" layer at 0.25; Frost-touched adds an `EchoSoundEffect` (Delay 0.12, Feedback 0.2, WetLevel −12); Ember-touched adds a crackle layer; Shadow adds `PitchShiftSoundEffect` 0.9 + low EQ; Celestial adds a "sparkle" layer + `ReverbSoundEffect`.
- Triggers and rates: Idle call `random(12, 30)` s per creature. Only play if within 60 studs of the camera and the global creature-voice budget is under **6 concurrent**. Eat on feed. Happy when happiness crosses 80%. Alert when a wild creature notices the player. Sleep breath loop at 0.1.
- 3D settings: RollOffMode InverseTapered, Min 8, Max 70, vol 0.5 (Giant 0.6, Miniature 0.4). Client-only playback, triggered from the creature's AI state attribute and never by the server per frame.

## 4. Discovery, capture, breeding, mutation stingers
All in F major / F Lydian. No pitch randomization on musical stingers, because it would put them off-key. A "Stingers" SoundGroup holds them. Only 1 plays at a time; a higher tier interrupts and replaces a lower one, and an equal or lower tier arriving mid-play is dropped. Music ducks −8 dB (`Music` group volume ×0.4) for the stinger's length + 0.5 s release.

| Event | Length | Character (search terms) | Vol |
|---|---|---|---|
| `Discover_New` (first time species seen) | 1.2 s | bright harp gliss + "discovery chime" / "magic reveal" | 0.6 |
| `Capture_Throw` | 0.3 s | soft whoosh (`rbxasset://sounds/swoosh`) | 0.4 |
| `Capture_Wobble` ×1–3 | 0.25 s each | "bubble pop soft" / "boing small", pitch rising 1.0 → 1.12 → 1.25 per wobble | 0.4 |
| `Capture_Success` | 0.9 s | "success chime magical" + pop | 0.6 |
| `Capture_Fail` | 0.5 s | "cartoon poof" / "pop release", soft and not punishing | 0.4 |
| `Breed_Start` | 1.0 s | warm "heart sparkle" / "soft chime rise" | 0.5 |
| `Breed_Hatch` (egg/offspring ready) | 1.5 s | "egg crack" + "baby creature chirp" + chime | 0.6 |
| Rarity reveal ladder (offspring/wild rarity) | Common 0.4 s / Uncommon 0.7 s / Rare 1.2 s / Epic 2.0 s / Legendary 3.5 s | each tier adds a layer: ping → +bell → +harp run → +choir pad/whoosh riser → +full fanfare + sparkle tail | 0.45 → 0.75 |
| `Mutation_Reveal` | tier-matched (above) | play a riser/anticipation `Mutation_Tease` (0.6–1.2 s, "magic riser short") **before** the reveal for Rare+, then the tier sound. Add the mutation flavour layer (crystal chime, golden coin shimmer, ember crackle, frost glass) | — |
| `RareNearby` (Epic+/mutated wild spawn within 80 studs) | 1.5 s | quiet positional "sparkle shimmer" from the creature, vol 0.35, once per spawn | 0.35 |
| `Journal_NewEntry` | 0.6 s | "page flip" + ping | 0.4 |
| `ServerAnnounce_Legendary` (other player) | 0.8 s | single soft bell, 2D, vol 0.25, no ducking | 0.25 |

Reveal pacing: anticipation (tease) → short pause (0.3 s of silence) → payoff. Commons resolve fast and can be skipped. Legendaries get the full pacing but stay under 4 s total.

## 5. UI sounds
UI SoundGroup default 0.5. Randomize pitch 0.95–1.05 only on non-musical clicks. Add a 0.05 s per-sound cooldown so rapid taps don't stack.

| Name | Source (verified built-in first) | Vol |
|---|---|---|
| `UI_Click` | `rbxasset://sounds/clickfast` or Creator Store "ui click soft" / "bubble click" | 0.4 |
| `UI_Hover` (desktop only) | "ui tick soft" | 0.15 |
| `UI_Open` / `UI_Close` | "ui pop open" / `rbxasset://sounds/swoosh` at speed 1.2 / 0.9 | 0.35 |
| `UI_Tab` | `rbxasset://sounds/switch` | 0.3 |
| `UI_Error` | "ui error soft" / "negative blip", low and short | 0.35 |
| `UI_Confirm` / `Purchase` | `rbxasset://sounds/electronicpingshort` or "coin purchase" | 0.45 |
| `Coins_Gain` (visitor income tick) | "coin collect", pitch ladder +1 semitone per tick in a 1.5 s window (max +7), then reset | 0.3 |
| `LevelUp` / `QuestComplete` | `rbxasset://sounds/victory` or "level up fanfare short" | 0.55 |
| `Notification` | "notification bell soft" | 0.35 |
| `Trade_Request` / `Trade_Accept` | "ui ding double" / "success chime" | 0.45 |

## 6. Building, footsteps, care
- Place: "place object thud wood" or `rbxasset://sounds/woodwood*` (3 variations), pitched by material category (fence = wood, rock = `stone*`, path = `grassstone*`).
- Rotate: `rbxasset://sounds/switch` at speed 1.3, vol 0.25. Invalid placement: `UI_Error`. Remove/sell: "pop small" + reverse swoosh.
- Footsteps: Roblox's default character footsteps vary by Humanoid floor material. Add only creature footfalls for Giant mutations ("heavy footstep soft", vol 0.3, Max 40).
- Feed: "crunch munch cute" ×3 + `Eat` call. Pet/interact: "purr" or happy call. Habitat rating up: soft rising chime (2-note F→C).

## For Audio
- **Sounds.luau keys:** every key in sections 1–6 (`Music_*`, `Amb_<Zone>_Bed`, `Amb_<Zone>_<OneShot>`, `Creature_<Bank>_<Call>`, stingers, `UI_*`, build sounds). Each entry is `{ Id = "rbxasset://..." or "rbxassetid://n" or 0, Volume, Kind = "Music"|"Ambience"|"SFX"|"UI"|"Stinger"|"Creature", Looped?, Variations = {...}? }`.
- **SoundGroups:** Master → Music (0.6), Ambience (0.7), SFX (0.8), Creatures (0.8), Stingers (0.9), UI (0.5). Save volume settings in a player Attribute.
- **Built-in, always-available IDs (no permission needed):** `rbxasset://sounds/` + `clickfast`, `button`, `swoosh`, `switch`, `snap`, `electronicpingshort`, `victory`, `splat`, `Kerplunk`, `woodwood`/`woodwood2`/`woodwood3`, `stone`/`stone2`/`stone3`, `grass`/`grass2`/`grass3`, `grassstone*`, `ice*`. Check the extension in Studio (`.wav` in current clients, `.mp3` in older lists).
- **Verified Roblox/APM numeric ID found:** `1841610162` "Chiptune" (APM, 120 BPM, about 2:38). It's off-theme, so use it only as a placeholder. Every other ID: search the terms above in Studio's Toolbox, Creator Store → Audio, filtering by creator Roblox, APMOfficial, ProSoundEffects or DailySoundsFX. If a search finds nothing, write `Id = 0` and add a Charlie TODO with the search term.
- **Engine values:** SoundService.AmbientReverb per zone (Forest, Cave, Mountains, UnderWater, Plain). 3D sounds use InverseTapered rolloff. Cap at **6 creature voices + 4 ambience one-shots** at once. Play stingers 2D on the client only.
- **Server → client:** the server fires `PlaySound(name, opts)` only for authoritative moments (capture result, hatch, mutation reveal with tier, legendary announce). Creature idle calls and ambience are entirely client-side.
- Never hardcode IDs outside `Sounds.luau`. Never upload ripped audio from Planet Zoo, Slime Rancher or Pokémon.

## Sources
- [Game Developer — Deep dive: the music of Slime Rancher 2](https://gamedeveloper.com/audio/deep-dive-the-music-of-slime-rancher-2)
- [Audiokinetic — The Sound Behind Midas Merge (stingers, one key, sparse music)](https://www.audiokinetic.com/en/blog/midas-merge)
- [PC Gamer — How animal sounds are made in games](https://www.pcgamer.com/how-animal-sounds-are-made-in-games)
- [N3TWORK — Choreographed Emotion: card reveal UX](https://medium.com/n3twork/choreographed-emotion-6-steps-to-a-great-card-reveal-ux-a6e6bb8487dd)
- [DevForum — AmbientSorcery: Creating Compelling Environmental Audio](https://devforum.roblox.com/t/ambientsorcery%E2%80%99s-tutorial-1-creating-compelling-environmental-audio/3507022)
- [DevForum — Finding APM music in Roblox's library](https://devforum.roblox.com/t/how-to-find-good-music-in-robloxs-audio-library-using-the-apm-music-website/2149632)
- [Roblox Docs — Audio assets (limits, privacy, free Creator Store audio)](https://create.roblox.com/docs/audio/assets.md)
- [Roblox Docs — ReverbType enum](https://create.roblox.com/docs/reference/engine/enums/ReverbType.md)
- [DevForum — A simple guide to the Audio API](https://devforum.roblox.com/t/a-simple-guide-to-the-audio-api/3132049)
- [GitHub — Classic Roblox built-in sound paths](https://github.com/Githolz/All-Classic-Roblox-Sound-Paths-)
- [Wikipedia — Shiny Pokémon (overworld rare-spawn audio cue)](https://en.wikipedia.org/wiki/Shiny_Pok%C3%A9mon)
