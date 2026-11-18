--!strict
-- Every tunable number lives here. Species: Species.luau, build items: Items.luau.
local Config = {}

Config.GameName = "Wildworld"
Config.Studio = "Chiken Studios"

-- Data ------------------------------------------------------------------------------
Config.DataStoreName = "wildworld_v1"
Config.LeaderboardStoreName = "wildworld_parks_v1"
Config.SchemaVersion = 1
Config.AutosaveSeconds = 60
Config.DataSyncInterval = 0.25 -- DataChanged batched to max 4x/s
Config.SessionLockStaleSeconds = 180 -- lock not refreshed for this long (crashed server) may be taken over
Config.SessionLockRetries = 6 -- tries to wait for another server's lock to release
Config.SessionLockRetryWait = 5
Config.ShutdownSaveTimeout = 25
Config.WorldReadyTimeout = 15
Config.CreatureCap = 200 -- hard data-safety cap
Config.StorageSlots = 30 -- creatures not on a pad
Config.ReceiptMemory = 50 -- processed purchase ids remembered (dupe-proof)

Config.Leaderstats = {
	{ Name = "Coins", Key = "coins" },
	{ Name = "Level", Key = "level" },
}

-- Remotes: seconds between calls per player per remote (default RemoteCooldown).
Config.RemoteCooldown = 0.2
Config.SettingsSaveCooldown = 0.5 -- SaveSettings RemoteEvent (client debounces 1 s)
Config.RemoteLimits = {
	PlaceItem = 0.1,
	RotateItem = 0.1,
	RemoveItem = 0.1,
	ThrowBait = 0.5,
	CaptureStart = 0.5,
	CaptureRelease = 0.5,
	Breed = 1,
	RenameCreature = 2,
	VisitPlot = 1,
	LikePark = 1,
}

-- Plots & grid --------------------------------------------------------------------------
Config.Grid = {
	Cell = 4, -- studs
	PlotSize = 128, -- studs (32 cells)
	PlotCount = 8,
	PlotRadius = 220, -- fallback ring radius if WorldService has no tagged plots
	LandSizes = { 64, 80, 96, 112, 128 }, -- by Park Land level 0..4
	MaxObjects = 300,
}

-- Creatures: needs, growth, breeding --------------------------------------------------
Config.Needs = {
	HungerTick = 30, -- -1 hunger every 30 s
	FeedAmount = 40,
	FeedCooldown = 10, -- per creature
	PetCooldown = 8,
	PetBonus = 10, -- happiness bonus for PetBonusSeconds
	PetBonusSeconds = 120,
	StationFeed = 15, -- hunger restored per bowl serving
	StationServings = 10,
	DrinkBonus = 5,
	HappyLowThreshold = 30, -- below: income x0.5
	OfflineFloor = 20,
	InteractRange = 30, -- studs from creature to feed/pet
	GoalSlack = 6, -- extra studs when range checks measure to the creature's Goal (feed/pet/bait/capture)
	Weights = { Hunger = 0.3, Habitat = 0.4, Social = 0.15, Enrichment = 0.15 },
}
Config.Growth = { BabySeconds = 600, FeedingsToAdult = 3, BabyIncomeMult = 0.5, BabyScale = 0.6 }
Config.Breeding = {
	MinHappy = 50,
	Cost = { Common = 50, Uncommon = 150, Rare = 400, Epic = 800, Legendary = 1500 },
	ParentCooldown = 300,
	BaseIncubators = 2,
	HueJitter = 0.06,
	SizeJitter = 0.03,
}
Config.StarterSpecies = { "Lumibun", "Mossback", "Emberfox" }
Config.StarterHatchesAdult = true -- so breeding is possible right after the first catch
Config.SellValueMinutes = 15 -- sell = baseValue x mutationMult x this
Config.GeneScanRP = 15

-- Mutations (Glowing is the 4th, built). Disabled rows = post-MVP data only.
Config.Mutations = {
	Golden = { Chance = 0.02, Mult = 3, Enabled = true, Rarity = "Epic" },
	Albino = { Chance = 0.015, Mult = 2.5, Enabled = true, Rarity = "Epic" },
	Crystal = { Chance = 0.005, Mult = 5, Enabled = true, Rarity = "Legendary" },
	Glowing = { Chance = 0.01, Mult = 2, Enabled = true, Rarity = "Epic" },
	Melanistic = { Chance = 0.01, Mult = 2.5, Enabled = false, Rarity = "Epic" },
	Giant = { Chance = 0.003, Mult = 4, Enabled = false, Rarity = "Legendary" },
	Celestial = { Chance = 0.0002, Mult = 15, Enabled = false, Rarity = "Legendary" },
}
Config.MutationOrder = { "Crystal", "Albino", "Glowing", "Golden" } -- rarest first
Config.MutationRules = {
	HeirloomOne = 5,
	HeirloomBoth = 15,
	Cap = 0.35,
	HabitatBonusRating = 80,
	HabitatBonus = 1.25,
	RainbowBonus = 2,
	SecondDivisor = 4,
	Max = 2,
	Exclusive = { { "Golden", "Albino" } },
	Combos = { { A = "Golden", B = "Crystal", Name = "Gilded Crystal", Mult = 12 } },
}
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

-- Creature AI --------------------------------------------------------------------------
Config.AI = {
	MaxDecisionsPerFrame = 20,
	ThinkMin = 3,
	ThinkMax = 8,
	WildThinkRange = 120,
	ReactRange = 10,
	SocialRange = 12,
	ShyFleeDistance = 6,
	NightStart = 19, -- Lighting.ClockTime
	NightEnd = 6,
	Base = { Idle = 2, Wander = 3, Eat = 1, Drink = 0.6, Sleep = 0.4, Play = 1, Socialize = 1, ReactToPlayer = 3 },
	NightSleepMult = 6,
	Personality = {
		Playful = { Play = 2, speed = 1.2 },
		Lazy = { Sleep = 2, Idle = 2, speed = 0.5 },
		Curious = { Wander = 2, speed = 1 },
		Shy = { ReactToPlayer = 1, speed = 1, flees = true },
		Social = { Socialize = 2, speed = 1 },
		Energetic = { Wander = 1.5, speed = 1.5 },
	},
	GroupRange = { -- preferred group size (same species in pad)
		Shy = { 1, 3 },
		Lazy = { 1, 4 },
		Playful = { 2, 5 },
		Curious = { 1, 4 },
		Social = { 3, 8 },
		Energetic = { 2, 6 },
	},
	WildWanderRadius = 22,
}

-- Capture --------------------------------------------------------------------------------
Config.Capture = {
	MaxWild = 12,
	RespawnSeconds = 45,
	Bait = {
		Berry = { Trust = 40, Coins = 10 },
		Honey = { Trust = 70, Coins = 50 },
		Starfruit = { Trust = 100, Coins = 250, BoostSeconds = 180 },
	},
	StartingBait = { Berry = 5 },
	ThrowRange = 45, -- bait position max distance from player
	BaitAttract = 16, -- wilds within this of the bait walk to it
	TrustNeeded = 40,
	TrustDecayPerSecond = 0.5,
	ClaimSeconds = 25, -- baiting player owns the wild for this long
	CaptureRange = 30, -- player to wild
	CapturedMomentSeconds = 0.9, -- caught wild stays visible for the "Captured" moment
	Green = { Common = 0.35, Uncommon = 0.25, Rare = 0.2, Epic = 0.15, Legendary = 0.12 },
	CalmNetBonus = 0.05,
	TrustBonusMax = 0.1, -- extra green at 100 trust
	RingSeconds = 2.2,
	GreenCentreMin = 0.35,
	GreenCentreMax = 0.8,
	Tolerance = 0.15, -- seconds
	Attempts = 3, -- 1 + 2 retries per encounter
	PityFails = 4,
	FleeDistance = 15,
	SpawnWeights = { Common = 70, Uncommon = 22, Rare = 6.8 },
	WildEpicChance = 0.01, -- Golden or Albino
	WildLegendaryChance = 0.002, -- Crystal, Glade only
	StarfruitEpicMult = 2,
	RecessiveAlleleChance = 0.3,
}

Config.Zones = {
	{ Id = "Meadow", Name = "Meadow Edge", Level = 1, Cost = 0, Species = { "Lumibun", "Mossback", "Emberfox" } },
	{
		Id = "Hollow",
		Name = "Mossy Hollow",
		Level = 4,
		Cost = 1000,
		Species = { "Lumibun", "Mossback", "Emberfox", "Pebblehorn" },
		RainBoost = "Pebblehorn",
	},
	{
		Id = "Glade",
		Name = "Waterfall Glade",
		Level = 8,
		Cost = 5000,
		Species = { "Mossback", "Emberfox", "Pebblehorn", "Thornstag" },
		Legendary = true,
	},
}

-- Economy ---------------------------------------------------------------------------------
Config.Economy = {
	TipInterval = 10, -- income paid as visitor tips every N s (coin fountain)
	FirstTip = 25, -- tutorial visitor tip
	OfflineRate = 0.5,
	OfflineCapSeconds = 7200,
	OfflineMinSeconds = 120,
	SnackStandBonus = 0.05,
	VipCoinBonus = 0.1,
	SunnyBonus = 0.1,
	ParkTiers = {
		{ Name = "Poor", Min = 0, Bonus = 0 },
		{ Name = "Developing", Min = 20, Bonus = 0.05 },
		{ Name = "Good", Min = 40, Bonus = 0.1 },
		{ Name = "Excellent", Min = 60, Bonus = 0.2 },
		{ Name = "World-class", Min = 75, Bonus = 0.35 },
		{ Name = "Legendary", Min = 90, Bonus = 0.5 },
	},
	DecorBonusMax = 10,
	LikeBonusCap = 10,
}
Config.XP = { Hatch = 20, Catch = 30, Breed = 25, Place = 2, Quest = 50, Base = 100, Exp = 1.4 }
Config.RP = { Discovery = 25, DiscoveryCoins = 100, Breed = 2, Mutation = 10, JournalStep = 5 }

Config.Upgrades = {
	Land = { Name = "Park Land", Costs = { 500, 2000, 6000, 15000 } },
	Capacity = { Name = "Creature Capacity", Costs = { 300, 900, 2500, 6000, 15000 }, Slots = { 6, 8, 10, 12, 14, 16 } },
	Incubators = { Name = "Incubators", Costs = { 1500, 8000 } },
	CalmNet = { Name = "Calm Net", Costs = { 400, 2000, 7000 } },
}

-- Daily, quests, shop, weather -----------------------------------------------------------
Config.Daily = {
	{ Coins = 100 },
	{ Coins = 200 },
	{ Bait = { Honey = 3 } },
	{ Coins = 500, RP = 20 },
	{ Bait = { Starfruit = 1 } },
	{ Coins = 1500 },
	{ MutationEgg = true },
}
Config.Quests = {
	PerDay = 3,
	BaseRerolls = 1,
	VipRerolls = 1,
	Pool = {
		{ Id = "feed10", Kind = "Feed", Target = 10, Coins = 150, RP = 10, Text = "Feed creatures 10 times" },
		{ Id = "pet5", Kind = "Pet", Target = 5, Coins = 150, RP = 10, Text = "Pet creatures 5 times" },
		{ Id = "breed1", Kind = "Breed", Target = 1, Coins = 300, RP = 20, Text = "Breed 1 egg" },
		{ Id = "catch2", Kind = "Catch", Target = 2, Coins = 350, RP = 20, Text = "Catch 2 wild creatures" },
		{ Id = "hatch2", Kind = "Hatch", Target = 2, Coins = 250, RP = 15, Text = "Hatch 2 eggs" },
		{ Id = "place10", Kind = "Place", Target = 10, Coins = 200, RP = 10, Text = "Place 10 build items" },
		{ Id = "bait3", Kind = "Bait", Target = 3, Coins = 150, RP = 10, Text = "Throw bait 3 times" },
		{ Id = "visit1", Kind = "Visit", Target = 1, Coins = 200, RP = 15, Text = "Visit another park" },
		{ Id = "earn2k", Kind = "Earn", Target = 2000, Coins = 400, RP = 25, Text = "Earn 2,000 coins" },
	},
}
-- Tutorial steps (flags.tutorialStep 1..5, 6 = done). Coins are paid as a visitor tip when the
-- step completes (the Feed tip pays for the first tree).
Config.Tutorial = {
	{ Kind = "Hatch", Text = "Hatch your egg!", Coins = 0 },
	{ Kind = "Feed", Text = "Feed your new friend", Coins = 25 },
	{ Kind = "Place", Text = "Place a tree to raise your rating", Coins = 50, ItemKind = "tree" },
	{ Kind = "Catch", Text = "Catch a wild friend in Greenleaf Forest", Coins = 100 },
	{ Kind = "Breed", Text = "Breed two of the same species", Coins = 150 },
}
Config.Shop = {
	RestockSeconds = 300,
	RareDecorPrice = 600,
	Slots = {
		{ Kind = "bait", Ref = "Berry", Stock = 10 },
		{ Kind = "bait", Ref = "Honey", Stock = 3 },
		{ Kind = "bait", Ref = "Starfruit", Stock = 1, Chance = 0.35 },
		{ Kind = "decor", Stock = 1 }, -- random rare decor (Items with ShopRare)
	},
}
Config.Weather = {
	MinGap = 600,
	MaxGap = 900,
	Kinds = {
		{ Name = "Sunny", Weight = 45, Seconds = 180 },
		{ Name = "Rain", Weight = 45, Seconds = 180 },
		{ Name = "Rainbow Shower", Weight = 10, Seconds = 300 },
	},
}
Config.Visits = { LikeRange = 120, VisitMemorySeconds = 600 }

-- Monetization (Id 0 = not created yet; Charlie TODO) -------------------------------------
Config.GamePasses = {
	VIP = { Id = 0, Name = "VIP", Price = 399 },
	ExtraIncubator = { Id = 0, Name = "Extra Incubator", Price = 199 },
	AutoFeeder = { Id = 0, Name = "Auto-Feeder", Price = 149 },
	CrystalGrotto = { Id = 0, Name = "Crystal Grotto Decor Pack", Price = 249 },
}
Config.DevProducts = {
	InstantHatch1 = { Id = 0, Name = "Instant Hatch", Price = 15, MaxSecondsLeft = 120 },
	InstantHatch2 = { Id = 0, Name = "Instant Hatch", Price = 25, MaxSecondsLeft = 300 },
	InstantHatch3 = { Id = 0, Name = "Instant Hatch", Price = 49, MaxSecondsLeft = math.huge },
	CoinsSmall = { Id = 0, Name = "2,500 Coins", Price = 49, Coins = 2500 },
	CoinsMedium = { Id = 0, Name = "10,000 Coins", Price = 149, Coins = 10000 },
	CoinsLarge = { Id = 0, Name = "40,000 Coins", Price = 449, Coins = 40000 },
	StarterPack = { Id = 0, Name = "Starter Pack", Price = 99, Coins = 2000 },
}
Config.InstantHatchFallbackCoins = 500 -- if the egg is gone when the receipt arrives

return Config
