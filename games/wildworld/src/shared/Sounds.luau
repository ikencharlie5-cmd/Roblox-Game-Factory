--!strict
-- Every sound in Wildworld (owned by the Audio department). Id 0 = not chosen yet (silent, safe to call).
-- Client: SoundController.Play("Name"). Server: Remotes.Event("PlaySound"):FireClient(plr, "Name", opts?).
-- notes/audio.md lists where each plays + Creator Store search terms for every Id = 0 entry.
export type SoundKind = "Music" | "Ambience" | "SFX" | "UI" | "Stinger" | "Creature"
export type SoundDef = {
	Id: number | string, -- rbxassetid number, or "rbxasset://sounds/..." built-in path
	Volume: number,
	Kind: SoundKind,
	Looped: boolean?,
	Pitch: number?, -- base PlaybackSpeed (default 1)
	PitchVar: number?, -- random +/- (default 0.05 for SFX/UI/Creature, 0 for Stinger/Music)
	MaxLength: number?, -- seconds; longer clips fade out after this
	Tier: number?, -- Stinger priority 1..5 (higher interrupts lower, music ducks)
}

-- IDs: Roblox_UI_* / ProSoundEffects / DailySoundsFX / APM picks reused from plant-zoo (found via Studio
-- Creator Store search); music titles from the Roblox APM library. "verify" = ownership/fit not confirmed.
local Defs: { [string]: SoundDef } = {
	-- UI
	UI_Click = { Id = 15675059323, Volume = 0.4, Kind = "UI" },
	UI_Hover = { Id = 15675037413, Volume = 0.12, Kind = "UI", Pitch = 1.3 },
	UI_Open = { Id = 15675024286, Volume = 0.35, Kind = "UI" },
	UI_Close = { Id = 15675028888, Volume = 0.35, Kind = "UI" },
	UI_Tab = { Id = 15675037413, Volume = 0.3, Kind = "UI" },
	UI_Error = { Id = 91501650514390, Volume = 0.35, Kind = "UI", PitchVar = 0 },
	UI_Confirm = { Id = 15675016548, Volume = 0.45, Kind = "UI", PitchVar = 0 },
	Purchase = { Id = 127645268874265, Volume = 0.5, Kind = "UI", PitchVar = 0 }, -- Roblox docs "currency purchase"
	Notification = { Id = 15675085146, Volume = 0.35, Kind = "UI" },
	ButtonUnlock = { Id = 15675046931, Volume = 0.45, Kind = "UI", PitchVar = 0 }, -- new HUD button pops in

	-- Economy / progress
	Coins_Gain = { Id = 130378474223829, Volume = 0.3, Kind = "SFX", PitchVar = 0 }, -- semitone ladder in controller
	OfflineEarnings = { Id = 138309872562566, Volume = 0.55, Kind = "SFX", PitchVar = 0 },
	RP_Gain = { Id = 15675016548, Volume = 0.35, Kind = "SFX", Pitch = 1.2 },
	LevelUp = { Id = 2686079706, Volume = 0.55, Kind = "Stinger", Tier = 3, MaxLength = 3 }, -- "Level Up" (verify)
	QuestComplete = { Id = 15675046931, Volume = 0.5, Kind = "SFX", PitchVar = 0 },
	DailyClaim = { Id = 3422389728, Volume = 0.55, Kind = "SFX", PitchVar = 0 }, -- Roblox docs "retro jingle"
	ParkTierUp = { Id = 1845986486, Volume = 0.55, Kind = "Stinger", Tier = 4, MaxLength = 3.5 },
	Like = { Id = 15675055424, Volume = 0.45, Kind = "SFX" },
	Upgrade = { Id = 15675046931, Volume = 0.5, Kind = "SFX", PitchVar = 0 },
	ZoneUnlock = { Id = 94077390731779, Volume = 0.55, Kind = "Stinger", Tier = 3, MaxLength = 3 },

	-- Build
	Build_Place = { Id = 106984966606682, Volume = 0.5, Kind = "SFX", PitchVar = 0.08 },
	Build_PlaceWood = { Id = 106984966606682, Volume = 0.5, Kind = "SFX", Pitch = 0.95, PitchVar = 0.06 },
	Build_PlaceStone = { Id = 106984966606682, Volume = 0.55, Kind = "SFX", Pitch = 0.75, PitchVar = 0.06 },
	Build_PlacePlant = { Id = 15675055424, Volume = 0.45, Kind = "SFX", Pitch = 1.05, PitchVar = 0.1 },
	Build_PlaceWater = { Id = 0, Volume = 0.45, Kind = "SFX", PitchVar = 0.08 },
	Build_Rotate = { Id = 15675037413, Volume = 0.25, Kind = "SFX", Pitch = 1.3 },
	Build_Remove = { Id = 15675075163, Volume = 0.4, Kind = "SFX" },
	Build_Invalid = { Id = 91501650514390, Volume = 0.3, Kind = "UI", PitchVar = 0 },
	RatingUp = { Id = 15675016548, Volume = 0.45, Kind = "Stinger", Tier = 1 }, -- rising chime

	-- Care
	Feed = { Id = 0, Volume = 0.45, Kind = "SFX", PitchVar = 0.1 },
	Pet = { Id = 15675055424, Volume = 0.4, Kind = "SFX", Pitch = 1.15, PitchVar = 0.1 },
	HappyHearts = { Id = 15675043410, Volume = 0.3, Kind = "SFX", Pitch = 1.25 },

	-- Eggs / hatch / breeding
	Egg_Wobble = { Id = 106984966606682, Volume = 0.3, Kind = "SFX", Pitch = 0.9, PitchVar = 0.05 },
	Egg_Crack = { Id = 0, Volume = 0.55, Kind = "SFX", PitchVar = 0.04 },
	Baby_Chirp = { Id = 0, Volume = 0.5, Kind = "Creature", Pitch = 1.35, PitchVar = 0.08 },
	Breed_Start = { Id = 15675043410, Volume = 0.5, Kind = "SFX", Pitch = 0.9, PitchVar = 0 },
	Breed_Ready = { Id = 15675046931, Volume = 0.5, Kind = "SFX", PitchVar = 0 },
	InstantHatch = { Id = 94077390731779, Volume = 0.45, Kind = "SFX", PitchVar = 0, MaxLength = 1.5 },

	-- Capture
	Bait_Throw = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.35, Kind = "SFX" }, -- built-in (verify ext)
	Capture_Throw = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.4, Kind = "SFX", Pitch = 1.15 },
	Capture_Wobble = { Id = 106984966606682, Volume = 0.4, Kind = "SFX", PitchVar = 0 }, -- pitch 1.0/1.12/1.25
	Capture_Success = { Id = 15675043410, Volume = 0.6, Kind = "Stinger", Tier = 2 },
	Capture_Fail = { Id = 15675075163, Volume = 0.4, Kind = "SFX", Pitch = 0.85 },
	Trust_Up = { Id = 15675016548, Volume = 0.25, Kind = "SFX", Pitch = 1.1 },

	-- Discovery / rarity ladder (stingers, one at a time, music ducks)
	Discover_New = { Id = 15675043410, Volume = 0.6, Kind = "Stinger", Tier = 3, Pitch = 0.9 },
	Journal_NewEntry = { Id = 15675024286, Volume = 0.4, Kind = "SFX", Pitch = 0.85 },
	Reveal_Common = { Id = 15675016548, Volume = 0.45, Kind = "Stinger", Tier = 1 },
	Reveal_Uncommon = { Id = 15675043410, Volume = 0.55, Kind = "Stinger", Tier = 2 },
	Reveal_Rare = { Id = 9038514384, Volume = 0.6, Kind = "Stinger", Tier = 3, MaxLength = 1.5 },
	Reveal_Epic = { Id = 94077390731779, Volume = 0.65, Kind = "Stinger", Tier = 4, MaxLength = 2.2 },
	Reveal_Legendary = { Id = 1845986486, Volume = 0.75, Kind = "Stinger", Tier = 5, MaxLength = 3.5 },
	Mutation_Tease = { Id = 0, Volume = 0.5, Kind = "Stinger", Tier = 2, MaxLength = 1.2 },
	Mutation_Golden = { Id = 130378474223829, Volume = 0.35, Kind = "SFX", Pitch = 1.3, PitchVar = 0 },
	Mutation_Crystal = { Id = 15675043410, Volume = 0.3, Kind = "SFX", Pitch = 1.5, PitchVar = 0 },
	Mutation_Albino = { Id = 15675016548, Volume = 0.3, Kind = "SFX", Pitch = 1.4, PitchVar = 0 },
	Mutation_Glowing = { Id = 15675043410, Volume = 0.3, Kind = "SFX", Pitch = 1.2, PitchVar = 0 },
	RareNearby = { Id = 15675043410, Volume = 0.35, Kind = "SFX", Pitch = 1.6, PitchVar = 0 }, -- 3D, PlayAt
	ServerAnnounce = { Id = 15675085146, Volume = 0.25, Kind = "SFX", Pitch = 0.9, PitchVar = 0 },

	-- Creature voices (3D, pitch per species in Voices below). Base banks.
	Voice_Squeak = { Id = 0, Volume = 0.45, Kind = "Creature", PitchVar = 0.08 },
	Voice_Grunt = { Id = 0, Volume = 0.5, Kind = "Creature", PitchVar = 0.08 },
	Voice_Yip = { Id = 0, Volume = 0.45, Kind = "Creature", PitchVar = 0.08 },
	Voice_Bleat = { Id = 0, Volume = 0.45, Kind = "Creature", PitchVar = 0.08 },
	Voice_Snort = { Id = 0, Volume = 0.45, Kind = "Creature", PitchVar = 0.08 },
	Voice_Munch = { Id = 0, Volume = 0.35, Kind = "Creature", PitchVar = 0.12 },
	Voice_Chime = { Id = 15675043410, Volume = 0.2, Kind = "Creature", Pitch = 1.5, PitchVar = 0.05 }, -- Crystal/Glowing layer
	Voice_Shimmer = { Id = 130378474223829, Volume = 0.15, Kind = "Creature", Pitch = 1.4, PitchVar = 0.05 }, -- Golden layer

	-- Music (APM library tracks uploaded by Roblox; verify fit by listening)
	Music_Park_Day = { Id = 1839620427, Volume = 0.25, Kind = "Music" }, -- "Spring Is Coming Ukulele"
	Music_Park_Night = { Id = 1845208657, Volume = 0.2, Kind = "Music" }, -- "Sleepy Village" - Sean Elder
	Music_Hub = { Id = 1845197284, Volume = 0.25, Kind = "Music" }, -- "Village Day" - Sean Elder
	Music_Forest = { Id = 9041797490, Volume = 0.25, Kind = "Music" }, -- "Hopeful Horizons" - James Hustwit (verify)
	Music_Glade = { Id = 1844232632, Volume = 0.25, Kind = "Music" }, -- "Rippling River 60" (verify)
	Music_Menu = { Id = 9041800311, Volume = 0.3, Kind = "Music" }, -- "Dandelion Wish" - James Hustwit (verify)
	Music_Breeding = { Id = 0, Volume = 0.2, Kind = "Music" },

	-- Ambience beds (loops)
	Amb_Park_Bed = { Id = 9112831327, Volume = 0.3, Kind = "Ambience", Looped = true }, -- birds/bees meadow
	Amb_Night_Bed = { Id = 0, Volume = 0.25, Kind = "Ambience", Looped = true },
	Amb_Forest_Bed = { Id = 9112807051, Volume = 0.35, Kind = "Ambience", Looped = true },
	Amb_Hollow_Bed = { Id = 9112807051, Volume = 0.3, Kind = "Ambience", Looped = true, Pitch = 0.9 },
	Amb_Rain_Bed = { Id = 1516791621, Volume = 0.3, Kind = "Ambience", Looped = true }, -- Roblox docs rain
	Amb_Waterfall = { Id = 0, Volume = 0.6, Kind = "Ambience", Looped = true }, -- 3D on WaterfallSound tag
	-- Ambience one-shots (3D, random 15-60 studs from camera)
	Amb_Bird = { Id = 0, Volume = 0.3, Kind = "Ambience", PitchVar = 0.08 },
	Amb_Rustle = { Id = 0, Volume = 0.3, Kind = "Ambience", PitchVar = 0.08 },
	Amb_Gust = { Id = 0, Volume = 0.25, Kind = "Ambience", PitchVar = 0.08 },
	Amb_Woodpecker = { Id = 0, Volume = 0.25, Kind = "Ambience", PitchVar = 0.05 },
	Amb_Crowd = { Id = 0, Volume = 0.15, Kind = "Ambience", PitchVar = 0.05 },
	Amb_Owl = { Id = 0, Volume = 0.25, Kind = "Ambience", PitchVar = 0.05 },
	Amb_Frog = { Id = 0, Volume = 0.25, Kind = "Ambience", PitchVar = 0.1 },
	Amb_Splash = { Id = 0, Volume = 0.3, Kind = "Ambience", PitchVar = 0.1 },
}

-- Old/short names other code may already call.
local Aliases: { [string]: string } = {
	Click = "UI_Click",
	Open = "UI_Open",
	Close = "UI_Close",
	Error = "UI_Error",
	Cash = "Coins_Gain",
	Notify = "Notification",
	Place = "Build_Place",
	Rotate = "Build_Rotate",
	Remove = "Build_Remove",
	Hatch = "Egg_Crack",
	DailyReward = "DailyClaim",
}

-- Zone -> music + ambience bed + one-shots {name, minGap, maxGap} + reverb. Night swaps park/hub.
export type ZoneAudio = {
	Music: string,
	NightMusic: string?,
	Bed: string,
	NightBed: string?,
	OneShots: { { any } },
	NightOneShots: { { any } }?,
	Reverb: Enum.ReverbType,
}
local parkShots = { { "Amb_Bird", 8, 20 }, { "Amb_Crowd", 25, 50 } }
local nightShots = { { "Amb_Owl", 30, 70 }, { "Amb_Frog", 10, 25 } }
local forestShots = {
	{ "Amb_Bird", 6, 15 },
	{ "Amb_Rustle", 10, 25 },
	{ "Amb_Gust", 20, 45 },
	{ "Amb_Woodpecker", 40, 90 },
}
local Zones: { [string]: ZoneAudio } = {
	Hub = {
		Music = "Music_Hub",
		NightMusic = "Music_Park_Night",
		Bed = "Amb_Park_Bed",
		NightBed = "Amb_Night_Bed",
		OneShots = parkShots,
		NightOneShots = nightShots,
		Reverb = Enum.ReverbType.Plain,
	},
	Park = {
		Music = "Music_Park_Day",
		NightMusic = "Music_Park_Night",
		Bed = "Amb_Park_Bed",
		NightBed = "Amb_Night_Bed",
		OneShots = parkShots,
		NightOneShots = nightShots,
		Reverb = Enum.ReverbType.Plain,
	},
	MeadowEdge = { Music = "Music_Forest", Bed = "Amb_Forest_Bed", OneShots = forestShots, Reverb = Enum.ReverbType.Forest },
	MossyHollow = {
		Music = "Music_Forest",
		Bed = "Amb_Hollow_Bed",
		OneShots = forestShots,
		Reverb = Enum.ReverbType.Forest,
	},
	WaterfallGlade = {
		Music = "Music_Glade",
		Bed = "Amb_Forest_Bed",
		OneShots = { { "Amb_Bird", 6, 15 }, { "Amb_Splash", 15, 40 }, { "Amb_Rustle", 10, 25 } },
		Reverb = Enum.ReverbType.Forest,
	},
}

-- Rarity -> reveal stinger.
local Reveal: { [string]: string } = {
	Common = "Reveal_Common",
	Uncommon = "Reveal_Uncommon",
	Rare = "Reveal_Rare",
	Epic = "Reveal_Epic",
	Legendary = "Reveal_Legendary",
}

-- Mutation -> flavour layer played with the reveal (and Voice layer for creature calls).
local MutationLayer: { [string]: string } = {
	Golden = "Mutation_Golden",
	Albino = "Mutation_Albino",
	Crystal = "Mutation_Crystal",
	Glowing = "Mutation_Glowing",
}
local VoiceLayer: { [string]: string } = {
	Golden = "Voice_Shimmer",
	Crystal = "Voice_Chime",
	Glowing = "Voice_Chime",
}

-- Species voice: base bank + pitch.
local Voices: { [string]: { Bank: string, Pitch: number } } = {
	Lumibun = { Bank = "Voice_Squeak", Pitch = 1.3 },
	Mossback = { Bank = "Voice_Grunt", Pitch = 0.8 },
	Emberfox = { Bank = "Voice_Yip", Pitch = 1.1 },
	Pebblehorn = { Bank = "Voice_Snort", Pitch = 0.9 },
	Thornstag = { Bank = "Voice_Bleat", Pitch = 0.95 },
}

return {
	Defs = Defs,
	Aliases = Aliases,
	Zones = Zones,
	Reveal = Reveal,
	MutationLayer = MutationLayer,
	VoiceLayer = VoiceLayer,
	Voices = Voices,
}
