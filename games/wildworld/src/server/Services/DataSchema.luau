--!strict
-- Helper (not a service): save-data defaults, migrations and sanitising. Used only by DataService.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local Items = require(Shared:WaitForChild("Items"))
local Genetics = require(Shared:WaitForChild("Genetics"))

local DataSchema = {}

-- Schema v1. Plot items are plot-relative cells: {id, x, z, r (degrees), u (item uid)}.
-- The starter Small Habitat Pad sits in the centre of the 64-stud starter land with a food bowl.
DataSchema.Default = {
	v = Config.SchemaVersion,
	coins = 0,
	rp = 0,
	xp = 0,
	level = 1,
	totalEarned = 0,
	nextId = 3,
	upgrades = { Land = 0, Capacity = 0, Incubators = 0, CalmNet = 0 },
	plot = {
		v = 1,
		items = {
			{ id = "PadSmall", x = 13, z = 13, r = 0, u = 1 },
			{ id = "FoodBowl", x = 17, z = 17, r = 0, u = 2 },
		},
	},
	creatures = {}, -- uid -> record (see notes/gameplay.md)
	eggs = {}, -- array of egg records
	journal = {}, -- species -> step 0..5
	stats = { hatched = 0, caught = 0, bred = 0, fed = 0, mutations = 0, likes = 0 },
	daily = { streak = 0, last = 0 },
	quests = { day = 0, list = {}, rerolls = 0 },
	flags = { tutorialStep = 1, goldenGiven = false, starterEgg = false, starterPack = false, bow = false },
	bait = { Berry = 0, Honey = 0, Starfruit = 0 },
	decorInv = {},
	zones = { Meadow = true },
	pity = {}, -- species -> fails
	receipts = {}, -- recent PurchaseIds (dupe-proof)
	likes = { day = 0, by = {}, count = 0 },
	boosts = { starfruit = 0 },
	settings = { music = 0.5, sfx = 0.7, musicOn = true, sfxOn = true },
	lastSeen = 0,
}

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end
DataSchema.DeepCopy = deepCopy

function DataSchema.New(): { [string]: any }
	local d = deepCopy(DataSchema.Default)
	for k, n in Config.Capture.StartingBait do
		d.bait[k] = n
	end
	return d
end

-- Fill missing keys (recurses into dictionaries but never refills lists/contents).
local function reconcile(data: { [string]: any }, defaults: { [string]: any })
	for k, v in defaults do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil and #v == 0 then
			if k ~= "creatures" and k ~= "plot" and k ~= "journal" and k ~= "pity" and k ~= "decorInv" then
				reconcile(data[k], v)
			end
		end
	end
end

local function num(v: any, default: number, lo: number, hi: number): number
	if type(v) ~= "number" or v ~= v then
		return default
	end
	return math.clamp(v, lo, hi)
end

-- Migrate + repair so a bad field can never break a load (never deletes creatures).
function DataSchema.Fix(data: { [string]: any }): { [string]: any }
	reconcile(data, DataSchema.Default :: any)
	data.v = Config.SchemaVersion
	data.coins = num(data.coins, 0, 0, 1e15)
	data.rp = num(data.rp, 0, 0, 1e12)
	data.level = math.floor(num(data.level, 1, 1, 10000))
	data.xp = num(data.xp, 0, 0, 1e15)

	-- plot items: drop unknown ids, re-number duplicate uids
	local seenU: { [number]: boolean } = {}
	local items = {}
	for _, it in data.plot.items or {} do
		if type(it) == "table" and Items.Get(it.id) and type(it.x) == "number" and type(it.z) == "number" then
			if type(it.u) ~= "number" or seenU[it.u] then
				it.u = data.nextId
				data.nextId += 1
			end
			seenU[it.u] = true
			it.r = if type(it.r) == "number" then it.r % 360 else 0
			table.insert(items, it)
		end
	end
	data.plot.items = items
	for id in data.decorInv do -- items cut from the catalog (v1 scope) disappear from inventory too
		if not Items.Get(id) then
			data.decorInv[id] = nil
		end
	end

	-- creatures: valid species + genes; pad refs must exist
	local count = 0
	for uid, c in data.creatures do
		if type(c) ~= "table" or not Species[c.species] then
			warn("[DataSchema] dropping invalid creature", uid)
			data.creatures[uid] = nil
			continue
		end
		count += 1
		c.genes = if Genetics.Parse(c.genes) then c.genes else Genetics.Default()
		c.mutations = if type(c.mutations) == "table" then c.mutations else {}
		c.stage = if c.stage == "Baby" then "Baby" else "Adult"
		c.hunger = num(c.hunger, 80, 0, 100)
		c.happy = num(c.happy, 60, 0, 100)
		c.grow = num(c.grow, 0, 0, 1e9)
		c.feeds = num(c.feeds, 0, 0, 1e9)
		c.gen = math.floor(num(c.gen, 1, 1, 1e6))
		c.personality = c.personality or Species[c.species].Personality
		if c.padId ~= nil and not seenU[c.padId] then
			c.padId = nil
		end
	end
	if count > Config.CreatureCap then
		warn("[DataSchema] creature count above cap:", count) -- kept; adding more is blocked
	end
	local eggs = {}
	for _, e in data.eggs do
		if type(e) == "table" and Species[e.species] and type(e.id) == "string" then
			e.genes = if Genetics.Parse(e.genes) then e.genes else Genetics.Default()
			e.mutations = if type(e.mutations) == "table" then e.mutations else {}
			table.insert(eggs, e)
		end
	end
	data.eggs = eggs
	if type(data.receipts) ~= "table" then
		data.receipts = {}
	end
	return data
end

return DataSchema
