--!strict
-- Every tunable number lives here. Species table: Config.Species (see Species.luau).
local Species = require(script.Parent:WaitForChild("Species"))

local Config = {}

Config.GameName = "Sprout Zoo"
Config.Studio = "Chiken Studios"

Config.DataStoreName = "plant-zoo_v1"
Config.LeaderboardStoreName = "plant-zoo_totalEarned_v1"
Config.AutosaveSeconds = 120
Config.RemoteCooldown = 0.2
Config.DataSyncInterval = 0.25 -- DataChanged is batched to at most once per this many seconds

-- leaderstats: display name -> data key
Config.Leaderstats = { { Name = "Cash", Key = "cash" }, { Name = "Releases", Key = "releases" } }

Config.Species = Species

-- Rarities in order. Weight = base shop weight; Qty = shop stock range.
Config.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" }
Config.Rarities = {
	Common = { Index = 1, Weight = 60, Qty = { 3, 5 }, Color = Color3.fromHex("B0B0B0") },
	Uncommon = { Index = 2, Weight = 25, Qty = { 2, 3 }, Color = Color3.fromHex("5BD35B") },
	Rare = { Index = 3, Weight = 10, Qty = { 1, 2 }, Color = Color3.fromHex("3BA7FF") },
	Epic = { Index = 4, Weight = 4, Qty = { 1, 1 }, Color = Color3.fromHex("A55BFF") },
	Legendary = { Index = 5, Weight = 0.9, Qty = { 1, 1 }, Color = Color3.fromHex("FFB300") },
	Mythical = { Index = 6, Weight = 0.09, Qty = { 1, 1 }, Color = Color3.fromHex("FF3D7F") },
	Secret = { Index = 7, Weight = 0.01, Qty = { 1, 1 }, Color = Color3.fromHex("1A1A1A") },
}
Config.AnnounceRarities = { Mythical = true, Secret = true } -- announce shop buys server-wide
Config.CrossServerRarities = { Secret = true } -- also announce in every server

-- Start
Config.StartCash = 100
Config.StarterSeed = "Sproutling"

-- Shop
Config.Shop = {
	RestockSeconds = 300,
	BaseSlots = 6,
	MaxSlots = 12,
	SlotsPerReleases = 2, -- +1 slot every 2 releases
	HopeCrateMinRarity = "Rare",
}

-- Growth stages (fraction of grow time where each stage starts)
Config.Stages = { { Name = "Seed", From = 0 }, { Name = "Sprout", From = 0.25 }, { Name = "Bud", From = 0.6 } }
Config.WaterCooldown = 30
Config.GrowTonicMaxRarity = "Legendary"

-- Grid
Config.Grid = { CellSize = 4, CellsPerSide = 5, PadSize = 20, PadSpacing = 24, PlotCount = 6, PlotRadius = 170 }
Config.PadCosts = { 0, 500, 5000, 40000, 250000, 1500000, 10000000, 60000000, 400000000 }

Config.BiomeOrder = { "Meadow", "Pond", "Desert", "Canopy", "Fungus Cave", "Frost Garden" }
Config.Biomes = {
	Meadow = { Cost = 0 },
	Pond = { Cost = 1000 },
	Desert = { Cost = 10000 },
	Canopy = { Cost = 100000 },
	["Fungus Cave"] = { Cost = 1000000 },
	["Frost Garden"] = { Cost = 10000000 },
}

-- Decor: Biome = nil means usable anywhere (needs no biome unlock).
Config.Decor = {
	["Flower Bed"] = { Biome = "Meadow", Cost = 50 },
	["Log"] = { Biome = "Meadow", Cost = 50 },
	["Beehive"] = { Biome = "Meadow", Cost = 50 },
	["Lily Pad"] = { Biome = "Pond", Cost = 300 },
	["Pond Rock"] = { Biome = "Pond", Cost = 300 },
	["Reed Clump"] = { Biome = "Pond", Cost = 300 },
	["Sandstone Rock"] = { Biome = "Desert", Cost = 2000 },
	["Clay Pot"] = { Biome = "Desert", Cost = 2000 },
	["Palm Shade"] = { Biome = "Desert", Cost = 2000 },
	["Vine Swing"] = { Biome = "Canopy", Cost = 15000 },
	["Hollow Log"] = { Biome = "Canopy", Cost = 15000 },
	["Nest"] = { Biome = "Canopy", Cost = 15000 },
	["Glow Shroom"] = { Biome = "Fungus Cave", Cost = 100000 },
	["Crystal"] = { Biome = "Fungus Cave", Cost = 100000 },
	["Stalagmite"] = { Biome = "Fungus Cave", Cost = 100000 },
	["Ice Crystal"] = { Biome = "Frost Garden", Cost = 700000 },
	["Pine Tree"] = { Biome = "Frost Garden", Cost = 700000 },
	["Snowman"] = { Biome = "Frost Garden", Cost = 700000 },
	["Info Sign"] = { Cost = 1000 },
}

-- Income multipliers
Config.Income = {
	Thriving = 1.5,
	Herd = 1.1,
	HerdSize = 3,
	InfoSign = 1.05,
	PerRelease = 0.5,
	PerAppeal = 0.1,
	VIP = 1.25,
	DoubleCash = 2,
	OfflineRate = 0.5,
	OfflineRateVIP = 1.0,
	OfflineBaseCapHours = 2,
	OfflineCapHoursPerBench = 2,
	OfflineMinSeconds = 60,
}

-- Color mutations (rolled once when grown). Chance is 0..1.
Config.ColorMutations = {
	{ Name = "Rainbow", Mult = 10, Chance = 0.001 },
	{ Name = "Diamond", Mult = 5, Chance = 0.005 },
	{ Name = "Gold", Mult = 3, Chance = 0.015 },
}
Config.AnnounceMutations = { Rainbow = true, Electric = true }

-- Weather: global schedule. Every CycleSeconds, the last DurationSeconds are a weather event.
Config.Weather = {
	CycleSeconds = 20 * 60,
	DurationSeconds = 4 * 60,
	RollEverySeconds = 60,
	Types = {
		{ Name = "Rain", Weight = 30, Growth = 1.5, Mutation = "Dewy", Mult = 2, Chance = 0.03 },
		{ Name = "Heatwave", Weight = 20, Growth = 1, Mutation = "Sunkissed", Mult = 2, Chance = 0.03 },
		{ Name = "Snow Flurry", Weight = 20, Growth = 1, Mutation = "Frosted", Mult = 3, Chance = 0.015 },
		{ Name = "Bloom Season", Weight = 15, Growth = 2, ColorOddsMult = 2 },
		{ Name = "Thunderstorm", Weight = 10, Growth = 1, Mutation = "Electric", Mult = 8, Chance = 0.003 },
		{ Name = "Starfall", Weight = 5, Growth = 1, Mutation = "Starlit", Mult = 5, Chance = 0.006, NightOnly = true },
	},
}
Config.WeatherMults = { Dewy = 2, Sunkissed = 2, Frosted = 3, Electric = 8, Starlit = 5 }
Config.ColorMults = { Gold = 3, Diamond = 5, Rainbow = 10 }

-- Upgrades (kept through Release). Costs[i] = price of level i. WateringCan starts at level 1 (free).
Config.UpgradeOrder = { "WateringCan", "Fertilizer", "ShopLuck", "BiggerRestock", "VisitorAppeal", "ComfyBenches" }
Config.Upgrades = {
	WateringCan = { Name = "Watering Can", Costs = { 0, 2000, 20000, 200000, 2000000 }, Values = { 0.10, 0.15, 0.20, 0.25, 0.30 } },
	Fertilizer = { Name = "Fertilizer", Costs = { 1000, 15000, 150000, 1500000, 15000000 } },
	ShopLuck = { Name = "Shop Luck", Costs = { 5000, 50000, 500000, 5000000, 50000000 } },
	BiggerRestock = { Name = "Bigger Restock", Costs = { 10000, 100000, 1000000, 10000000 } },
	VisitorAppeal = { Name = "Visitor Appeal", Costs = { 3000, 30000, 300000, 3000000, 30000000 } },
	ComfyBenches = { Name = "Comfy Benches", Costs = { 5000, 50000, 500000 } },
}
Config.Luck = { PerShopLuck = 0.1, PerRelease = 0.1, SuperLuck = 0.5, PotionMult = 2, PotionSeconds = 15 * 60 }
Config.FertilizerPerLevel = 0.1

-- Release to the Wild
Config.Release = {
	CashReq = { 1e6, 25e6, 250e6, 2e9, 20e9 }, -- after the list: x10 each
	HopePer = 25, -- x release number
	ResetCash = 100,
	ReserveDisplayMax = 60,
}
function Config.ReleaseMinRarity(n: number): string
	if n <= 1 then
		return "Epic"
	elseif n <= 3 then
		return "Legendary"
	end
	return "Mythical"
end

-- Hope Shop
Config.HopeShop = {
	HopeCrate = { Name = "Hope Crate", Cost = 100 },
	LuckPotion = { Name = "Luck Potion", Cost = 30 },
	GrowTonic = { Name = "Grow Tonic", Cost = 20 },
}

-- Daily reward (7-day streak; missing a UTC day resets)
Config.Daily = {
	Rewards = {
		{ Kind = "Income", Minutes = 5, Min = 200 },
		{ Kind = "Hope", Amount = 10 },
		{ Kind = "LuckPotion", Amount = 1 },
		{ Kind = "Income", Minutes = 15, Min = 500 },
		{ Kind = "GrowTonic", Amount = 2 },
		{ Kind = "Hope", Amount = 30 },
		{ Kind = "Seed", Rarity = "Epic" },
	},
}

-- Quests
Config.Tutorial = {
	{ Kind = "PlantSeed", Goal = 1, Text = "Plant your Sproutling", Cash = 50, Hope = 0 },
	{ Kind = "PlaceDecor", Goal = 1, Text = "Buy & place a Flower Bed", Cash = 50, Hope = 0 },
	{ Kind = "Thriving", Goal = 1, Text = "Get a Thriving creature", Cash = 100, Hope = 5 },
	{ Kind = "CollectJar", Goal = 1, Text = "Walk over your Tip Jar", Cash = 100, Hope = 0 },
	{ Kind = "BuySeed", Goal = 1, Text = "Buy a seed at the Seed Shop", Cash = 150, Hope = 0 },
	{ Kind = "BuyPad", Goal = 1, Text = "Unlock Exhibit Pad 2 ($500)", Cash = 250, Hope = 10 },
}
Config.DailyQuests = {
	PerDay = 3,
	Hope = 10,
	CashMinutes = 5, -- cash reward = X minutes of income (min CashMin)
	CashMin = 500,
	Pool = {
		{ Kind = "PlantSeed", Goal = 5, Text = "Plant 5 seeds" },
		{ Kind = "CollectCash", Minutes = 10, Min = 1000, Text = "Collect $%s from Tip Jars" },
		{ Kind = "Thriving", Goal = 2, Text = "Have 2 Thriving creatures" },
		{ Kind = "BuyRare", Goal = 1, Text = "Buy a Rare+ seed" },
		{ Kind = "Water", Goal = 15, Text = "Water plants 15 times" },
		{ Kind = "Like", Goal = 1, Text = "Like another zoo" },
	},
}

-- Auto Gardener pass
Config.AutoGardenerSeconds = 10

-- Placeholder IDs: 0 = not set yet (Charlie TODO).
Config.GamePasses = {
	VIP = { Id = 0, Name = "VIP", Price = 249 },
	DoubleCash = { Id = 0, Name = "2x Cash", Price = 599 },
	SuperLuck = { Id = 0, Name = "Super Luck", Price = 399 },
	AutoGardener = { Id = 0, Name = "Auto Gardener", Price = 349 },
}
Config.DevProducts = {
	InstantRestock = { Id = 0, Name = "Instant Restock", Price = 29 },
	FinishGrowing = { Id = 0, Name = "Finish All Growing", Price = 49 },
	Hope100 = { Id = 0, Name = "100 Hope", Price = 49, Hope = 100 },
	Hope500 = { Id = 0, Name = "500 Hope", Price = 199, Hope = 500 },
	Hope1500 = { Id = 0, Name = "1,500 Hope", Price = 499, Hope = 1500 },
	CashBoost = { Id = 0, Name = "Cash Boost", Price = 99, Minutes = 30, Min = 5000 },
}

Config.DefaultData = {
	cash = Config.StartCash,
	hope = 0,
	totalEarned = 0,
	releases = 0,
	upgrades = { WateringCan = 1, Fertilizer = 0, ShopLuck = 0, BiggerRestock = 0, VisitorAppeal = 0, ComfyBenches = 0 },
	biomes = { Meadow = true },
	padsOwned = 1,
	padBiome = { "Meadow", "Meadow", "Meadow", "Meadow", "Meadow", "Meadow", "Meadow", "Meadow", "Meadow" },
	inventory = { seeds = { Sproutling = 1 }, creatures = {}, decor = {} },
	placed = {}, -- {id,species,pad,cell,rot,plantedAt,growTotal,color,weather}
	decor = {}, -- {id,kind,pad,cell,rot}
	jars = { 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	indexFound = {}, -- [species] = { [mutation] = true }
	released = {}, -- {species,color}
	daily = { last = 0, streak = 0 }, -- last = UTC day number
	quests = { day = 0, list = {} },
	tutorialStep = 1,
	tutorialProgress = 0,
	potions = { luckUntil = 0, luck = 0 },
	tonics = 0,
	likes = 0,
	likedToday = {}, -- [ownerUserId] = day
	lastOnline = 0,
	stockBought = {}, -- [restockId] = { [slot] = qty }
	nextId = 1,
}

return Config
