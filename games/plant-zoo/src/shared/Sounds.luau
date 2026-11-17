--!strict
-- Every sound in the game (owned by the Audio department). Id 0 = not chosen yet (silent, safe).
-- Call by name: client `SoundController.Play("Name")`, server fires `PlaySound` remote with the name.
-- See notes/audio.md for where each plays + Studio search terms for the Id = 0 entries.
export type SoundKind = "sfx" | "music" | "ambience"
export type SoundDef = {
	Id: number,
	Volume: number,
	Kind: SoundKind,
	Looped: boolean?,
	Pitch: number?, -- base PlaybackSpeed (default 1)
	PitchVar: number?, -- random +/- (default 0.05 for sfx, 0 otherwise)
	MaxLength: number?, -- seconds; long clips are faded out after this
}

local Sounds: { [string]: SoundDef } = {
	-- UI
	Click = { Id = 15675059323, Volume = 0.5, Kind = "sfx" },
	Open = { Id = 15675024286, Volume = 0.45, Kind = "sfx" },
	Close = { Id = 15675028888, Volume = 0.4, Kind = "sfx" },
	Error = { Id = 91501650514390, Volume = 0.5, Kind = "sfx", PitchVar = 0 },
	Purchase = { Id = 127645268874265, Volume = 0.6, Kind = "sfx" }, -- Roblox docs "currency purchase sound"
	Notify = { Id = 15675085146, Volume = 0.45, Kind = "sfx" },

	-- Money
	Cash = { Id = 130378474223829, Volume = 0.55, Kind = "sfx", PitchVar = 0.1 }, -- tip jar coin pop
	OfflineEarnings = { Id = 138309872562566, Volume = 0.6, Kind = "sfx" },

	-- Building / zoo actions
	Place = { Id = 106984966606682, Volume = 0.55, Kind = "sfx", PitchVar = 0.08 }, -- buy/place thunk
	Rotate = { Id = 15675037413, Volume = 0.4, Kind = "sfx", PitchVar = 0.08 },
	Remove = { Id = 15675075163, Volume = 0.45, Kind = "sfx" },
	Water = { Id = 0, Volume = 0.5, Kind = "sfx", PitchVar = 0.1 },
	Sell = { Id = 130378474223829, Volume = 0.55, Kind = "sfx" },
	Expand = { Id = 15675046931, Volume = 0.6, Kind = "sfx", PitchVar = 0 }, -- new pad / biome unlock
	Restock = { Id = 131573697, Volume = 0.5, Kind = "sfx", PitchVar = 0 }, -- "Bell" (verify in Studio)
	Photo = { Id = 0, Volume = 0.5, Kind = "sfx" },
	Like = { Id = 15675055424, Volume = 0.5, Kind = "sfx" },

	-- Growing
	Plant = { Id = 15675055424, Volume = 0.55, Kind = "sfx", PitchVar = 0.1 },
	GrowStage = { Id = 106984966606682, Volume = 0.5, Kind = "sfx", PitchVar = 0.12 }, -- sprout "bloop"
	Bloom = { Id = 15675043410, Volume = 0.6, Kind = "sfx", PitchVar = 0.04 }, -- fully grown chime
	Thriving = { Id = 15675016548, Volume = 0.5, Kind = "sfx", PitchVar = 0.04 }, -- need met ✓ ding
	Mutation = { Id = 0, Volume = 0.6, Kind = "sfx", PitchVar = 0.04 }, -- sparkle

	-- Rarity reveals (scale C -> S). Common/Uncommon reuse Bloom.
	RevealRare = { Id = 9038514384, Volume = 0.55, Kind = "sfx", PitchVar = 0 },
	RevealEpic = { Id = 0, Volume = 0.6, Kind = "sfx", PitchVar = 0 },
	RevealLegendary = { Id = 0, Volume = 0.65, Kind = "sfx", PitchVar = 0 },
	-- "Fanfare Announcement 1" (APM track, cut at 5 s)
	RevealMythical = { Id = 1845986486, Volume = 0.6, Kind = "sfx", PitchVar = 0, MaxLength = 5 },
	RevealSecret = { Id = 0, Volume = 0.7, Kind = "sfx", PitchVar = 0 },

	-- Progress / rewards
	Release = { Id = 94077390731779, Volume = 0.7, Kind = "sfx", PitchVar = 0 }, -- whoosh + choir
	DailyReward = { Id = 3422389728, Volume = 0.6, Kind = "sfx", PitchVar = 0 }, -- Roblox docs "retro jingle"
	QuestComplete = { Id = 2686079706, Volume = 0.55, Kind = "sfx", PitchVar = 0 }, -- "Level Up" (verify in Studio)
	Announce = { Id = 15675043410, Volume = 0.55, Kind = "sfx", PitchVar = 0 }, -- server-wide toast chime

	-- Weather start stings (Sounds.WeatherStart maps weather -> name)
	WeatherRain = { Id = 0, Volume = 0.55, Kind = "sfx", PitchVar = 0 },
	WeatherHeatwave = { Id = 0, Volume = 0.55, Kind = "sfx", PitchVar = 0 },
	WeatherSnow = { Id = 0, Volume = 0.55, Kind = "sfx", PitchVar = 0 },
	WeatherBloom = { Id = 0, Volume = 0.55, Kind = "sfx", PitchVar = 0 },
	-- "Thunder And Lightning Light Rain" (verify in Studio)
	WeatherThunder = { Id = 167060366, Volume = 0.6, Kind = "sfx", PitchVar = 0, MaxLength = 6 },
	WeatherStarfall = { Id = 0, Volume = 0.55, Kind = "sfx", PitchVar = 0 },

	-- Creatures (3D, via SoundController.PlayAt)
	Chirp = { Id = 0, Volume = 0.35, Kind = "sfx", PitchVar = 0.15 },
	ChirpHappy = { Id = 0, Volume = 0.4, Kind = "sfx", PitchVar = 0.1 },

	-- Music (APM library tracks uploaded by Roblox)
	HubTheme = { Id = 1845197284, Volume = 0.25, Kind = "music", Looped = true }, -- "Village Day" - Sean Elder
	PlotTheme = { Id = 1839620427, Volume = 0.25, Kind = "music", Looped = true }, -- "Spring Is Coming Ukulele"
	ReserveTheme = { Id = 1840700386, Volume = 0.28, Kind = "music", Looped = true }, -- "Welcome To Your World (B)"
	WeatherTheme = { Id = 1841461968, Volume = 0.25, Kind = "music", Looped = true }, -- Roblox docs "upbeat" loop
	NightTheme = { Id = 1845208657, Volume = 0.22, Kind = "music", Looped = true }, -- "Sleepy Village" - Sean Elder

	-- Ambience loops
	AmbMeadow = { Id = 9112831327, Volume = 0.3, Kind = "ambience", Looped = true }, -- birds/bees
	AmbPond = { Id = 9112877174, Volume = 0.3, Kind = "ambience", Looped = true }, -- bubbles
	AmbDesert = { Id = 9113286969, Volume = 0.25, Kind = "ambience", Looped = true }, -- wind
	AmbCanopy = { Id = 9112807051, Volume = 0.3, Kind = "ambience", Looped = true }, -- jungle
	AmbFungus = { Id = 9120526768, Volume = 0.3, Kind = "ambience", Looped = true }, -- cave drips
	AmbFrost = { Id = 9112832297, Volume = 0.25, Kind = "ambience", Looped = true }, -- wind chimes
	AmbRain = { Id = 1516791621, Volume = 0.3, Kind = "ambience", Looped = true }, -- Roblox docs rain loop
}

-- Music per zone (SoundController picks: Weather > Reserve > Night (plots) > zone).
local Music = {
	Hub = "HubTheme",
	Plot = "PlotTheme",
	Reserve = "ReserveTheme",
	Weather = "WeatherTheme",
	Night = "NightTheme",
}

local BiomeAmbience: { [string]: string } = {
	Meadow = "AmbMeadow",
	Pond = "AmbPond",
	Desert = "AmbDesert",
	Canopy = "AmbCanopy",
	Fungus = "AmbFungus",
	Frost = "AmbFrost",
}

local WeatherStart: { [string]: string } = {
	Rain = "WeatherRain",
	Heatwave = "WeatherHeatwave",
	Snow = "WeatherSnow",
	SnowFlurry = "WeatherSnow",
	Bloom = "WeatherBloom",
	BloomSeason = "WeatherBloom",
	Thunderstorm = "WeatherThunder",
	Starfall = "WeatherStarfall",
}

-- Weathers that also loop the rain ambience on top of biome ambience.
local RainyWeather: { [string]: boolean } = { Rain = true, Thunderstorm = true }

local Reveal: { [string]: string } = {
	Common = "Bloom",
	Uncommon = "Bloom",
	Rare = "RevealRare",
	Epic = "RevealEpic",
	Legendary = "RevealLegendary",
	Mythical = "RevealMythical",
	Secret = "RevealSecret",
}

return {
	Defs = Sounds,
	Music = Music,
	BiomeAmbience = BiomeAmbience,
	WeatherStart = WeatherStart,
	RainyWeather = RainyWeather,
	Reveal = Reveal,
}
