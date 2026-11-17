# Audio notes (Sprout Zoo)

Files: `src/shared/Sounds.luau` (all IDs), `src/client/Audio/SoundController.luau` (API),
`src/client/Audio/MusicDirector.luau` (zone/weather/night music + ambience). `Id = 0` = silent, safe to call.

## How to call
- Client: `SoundController.Play("Name")`, `SoundController.Play("Chirp", 1.3)` (pitch mult),
  `SoundController.PlayAt("Chirp", part or Vector3, pitch?)` (3D), `SoundController.PlayReveal("Epic")`.
- Server: `Remotes.Event("PlaySound"):FireClient(player, "Name")` or `(player, "Name", partOrVector3, pitch?)`
  for 3D. `FireAllClients` for everyone.
- Settings: UI sets `Players.LocalPlayer:SetAttribute("MusicOn", bool)` / `("SFXOn", bool)` (nil = on).
  Helpers: `SoundController.SetMusicOn(bool)`, `SetSFXOn(bool)`. Ambience follows SFXOn.
- Music is automatic. Optional: `MusicDirector.SetZone("Hub"|"Plot"|"Reserve"|nil)`.

## Sound list (name -> where it plays -> who calls)
| Name | Where | Caller | Id |
|---|---|---|---|
| Click | any button | UI | 0 |
| Open / Close | screen open/close | UI | 0 |
| Error | failed buy / invalid cell / not enough cash | UI or server | 0 |
| Purchase | seed/decor/upgrade/pass bought | UI or server | 127645268874265 |
| Notify | generic toast | UI | 0 |
| Cash | tip jar collect (coin pop) | server (PlaySound) | 0 |
| OfflineEarnings | offline popup | UI | 0 |
| Place / Rotate / Remove | build mode | UI | 0 |
| Water | watering can tap | client/server | 0 |
| Sell | creature sold | UI | 0 |
| Expand | new pad bought / biome unlocked | server | 0 |
| Restock | Seed Shop restock (every 5 min) | client timer / server | 131573697 (verify) |
| Photo / Like | photo, Like a zoo | UI | 0 |
| Plant | seed planted | server | 0 |
| GrowStage | Seed->Sprout->Bud (use PlayAt on the plant) | server | 0 |
| Bloom | fully grown; also Common/Uncommon reveal | server | 0 |
| Thriving | all needs met ✓ | server | 0 |
| Mutation | color/weather mutation rolled | server | 0 |
| RevealRare / RevealEpic / RevealLegendary / RevealMythical / RevealSecret | seed bought or creature grown, via `PlayReveal(rarity)` | UI/server | Mythical 1845986486 (APM, cut 5 s), rest 0 |
| Release | Release to the Wild confirm | UI/server | 0 |
| DailyReward | daily claim | UI | 3422389728 |
| QuestComplete | quest claimed | UI | 2686079706 (verify) |
| Announce | server-wide toast (Mythical/Secret/Rainbow/Electric) | UI on Announce RE | 0 |
| WeatherRain / WeatherHeatwave / WeatherSnow / WeatherBloom / WeatherThunder / WeatherStarfall | weather start sting (automatic) | MusicDirector | Thunder 167060366 (verify), rest 0 |
| Chirp / ChirpHappy | creature idle / became Thriving (PlayAt, pitch per species) | gameplay/graphics client | 0 |

Music (automatic, crossfade 1.5 s, paused tracks resume): priority Weather > Reserve > Night (plots only) > zone.
| Name | When | Id |
|---|---|---|
| HubTheme | in hub (within 80 studs of origin) | 1845197284 "Village Day" |
| PlotTheme | on plots, daytime | 1839620427 "Spring Is Coming Ukulele" |
| ReserveTheme | within 40 studs of `ReleaseAltar` tag | 1840700386 "Welcome To Your World (B)" |
| WeatherTheme | any weather active | 1841461968 (Roblox docs upbeat loop) |
| NightTheme | plots at night (ClockTime <6 or >=18, or workspace `IsNight`) | 1845208657 "Sleepy Village" |

Ambience: `AmbMeadow` (hub + Meadow pads), `AmbPond`, `AmbDesert`, `AmbCanopy`, `AmbFungus`, `AmbFrost` (nearest
`ExhibitPad` within 22 studs, Attribute `Biome`), `AmbRain` 1516791621 (Rain/Thunderstorm, layered).

## World contract I read (all optional)
- workspace Attribute `Weather` (string, ""/nil = clear) or `WeatherChanged` RE; workspace `IsNight` (bool) optional.
- `ExhibitPad` tag + Attribute `Biome`; `ReleaseAltar` tag (World Reserve).

## ID sources
- Roblox docs (Roblox-owned examples): 127645268874265, 3422389728, 1841461968, 1516791621.
- APM library tracks uploaded by Roblox (listed on bloxodes.com genre pages): 1845197284, 1839620427,
  1840700386, 1845208657, 1845986486.
- Third-party list (gamertweak), ownership unverified: 131573697 (Bell), 2686079706 (Level Up),
  167060366 (thunder, from allthings.how). Swap if they don't load.

## Charlie TODO
- In Studio Toolbox > Audio, fill every `Id = 0` in `src/shared/Sounds.luau` (search terms below) and test
  the 3 "verify" IDs. Prefer sounds uploaded by "Roblox".

## Search terms (one per sound)
- Click: "ui click soft"
- Open: "ui pop open"
- Close: "ui whoosh close"
- Error: "error buzz soft"
- Purchase: "cash register purchase"
- Notify: "notification ding"
- Cash: "coin pop collect"
- OfflineEarnings: "coins pile reward"
- Place: "wood thunk place"
- Rotate: "click rotate tick"
- Remove: "pop remove"
- Water: "water splash small"
- Sell: "coin cash register"
- Expand: "unlock success chime"
- Restock: "shop bell ring"
- Photo: "camera shutter"
- Like: "heart pop"
- Plant: "dirt dig plant"
- GrowStage: "bloop bubble pop cartoon"
- Bloom: "magic chime sparkle"
- Thriving: "positive ding correct"
- Mutation: "sparkle shimmer magic"
- RevealRare: "reward chime short"
- RevealEpic: "magic reveal"
- RevealLegendary: "fanfare short"
- RevealMythical: "epic fanfare orchestral"
- RevealSecret: "mysterious reveal choir"
- Release: "choir swell whoosh"
- DailyReward: "reward jingle"
- QuestComplete: "level up quest complete"
- Announce: "announcement chime"
- WeatherRain: "rain start"
- WeatherHeatwave: "heat shimmer"
- WeatherSnow: "winter wind chime"
- WeatherBloom: "magical spring harp"
- WeatherThunder: "thunder clap"
- WeatherStarfall: "twinkle stars magic"
- Chirp: "cute creature chirp"
- ChirpHappy: "cute happy trill"
- HubTheme: "village market cheerful"
- PlotTheme: "cozy pastoral acoustic"
- ReserveTheme: "uplifting orchestral"
- WeatherTheme: "upbeat happy"
- NightTheme: "lullaby calm night"
- AmbMeadow: "birds nature ambience"
- AmbPond: "underwater bubbles ambience"
- AmbDesert: "desert wind ambience"
- AmbCanopy: "jungle ambience"
- AmbFungus: "cave drips ambience"
- AmbFrost: "wind chimes ambience"
- AmbRain: "rain ambience loop"

## IDs filled by orchestrator via Studio Creator Store search
From Roblox-owned (Roblox_UI_*), ProSoundEffects (licensed), DailySoundsFX (original, free), APMOfficial: Click=15675059323, Open=15675024286, Close=15675028888, Error=91501650514390, Notify=15675085146, Cash=130378474223829, OfflineEarnings=138309872562566, Place=106984966606682, Rotate=15675037413, Remove=15675075163, Sell=130378474223829, Expand=15675046931, Like=15675055424, Plant=15675055424, GrowStage=106984966606682, Bloom=15675043410, Thriving=15675016548, RevealRare=9038514384, Release=94077390731779, Announce=15675043410, AmbMeadow=9112831327, AmbPond=9112877174, AmbDesert=9113286969, AmbCanopy=9112807051, AmbFungus=9120526768, AmbFrost=9112832297
Still 0: Water, Photo, Mutation, RevealEpic/Legendary/Secret, Weather* starts, Chirp, ChirpHappy.
