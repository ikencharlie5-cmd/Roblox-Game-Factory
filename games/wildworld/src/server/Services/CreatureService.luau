--!strict
-- Park creatures: records <-> models, needs (hunger/happiness), growth, Feed / Pet / Assign /
-- Rename / Sell / RefillStation. AI brains live in CreatureAI (anchored, attribute-replicated).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local Genetics = require(Shared:WaitForChild("Genetics"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local PlacementService = require(script.Parent:WaitForChild("PlacementService"))
local ParkService = require(script.Parent:WaitForChild("ParkService"))
local CreatureAI = require(script.Parent:WaitForChild("CreatureAI"))
local Models = require(script.Parent:WaitForChild("Models"))
local Signals = require(script.Parent:WaitForChild("Signals"))
local CreatureCare = require(script.Parent:WaitForChild("CreatureCare"))

local CreatureService = {}

local rng = Random.new()
local folder: Folder
local live: { [Player]: { [string]: Model } } = {}
local padCtx: { [Player]: { [number]: any } } = {}

local function rec(player: Player, uid: any): any?
	local data = DataService.Get(player)
	return if data and type(uid) == "string" then data.creatures[uid] else nil
end

local function stamp(m: Model, r: any)
	m:SetAttribute("Stage", r.stage)
	m:SetAttribute("Hunger", math.floor(r.hunger))
	m:SetAttribute("Happy", math.floor(r.happy))
	m:SetAttribute("Nickname", r.nickname or "")
	m:SetAttribute("PadUid", r.padId or 0)
end

-- Context for the AI: station positions + same-pad partners (cached per pad, reset on PlotChanged).
local function context(player: Player, padU: number, self: Model): any
	local byPad = padCtx[player]
	if not byPad then
		return {}
	end
	local c = byPad[padU]
	if not c then
		c = { partners = {} }
		for _, row in PlacementService.ItemsInPad(player, padU) do
			local k, def = row.def.Kind, row.def
			if k == "food" and not c.food then
				c.food, c.foodU = row.pos, row.item.u
			elseif (k == "drink" or def.Drink) and not c.water then
				c.water = row.pos
			elseif (k == "toy" or k == "log") and not c.toy then
				c.toy = row.pos
			elseif (k == "shelter" or k == "burrow" or def.Shelter) and not c.shelter then
				c.shelter = row.pos
			end
		end
		byPad[padU] = c
	end
	local partners = {}
	for _, m in live[player] or {} do
		if m ~= self and m:GetAttribute("PadUid") == padU then
			local a = CreatureAI.Get(m)
			if a then
				table.insert(partners, a)
			end
		end
	end
	return { food = c.food, water = c.water, toy = c.toy, shelter = c.shelter, partners = partners, foodU = c.foodU }
end

local function despawn(player: Player, uid: string)
	local m = live[player] and live[player][uid]
	if m then
		CreatureAI.Remove(m)
		m:Destroy()
		live[player][uid] = nil
	end
end

local function spawnModel(player: Player, r: any)
	local data = DataService.Get(player)
	if not data or not r.padId or not live[player] then
		return
	end
	local pad: any = nil
	for _, p in PlacementService.GetPads(player) do
		if p.u == r.padId then
			pad = p
		end
	end
	if not pad then
		r.padId = nil
		return
	end
	despawn(player, r.uid)
	local m = Models.Creature(r, data.flags.bow)
	m.Name = r.uid .. "_" .. player.UserId
	local traits = Genetics.Traits(r.genes)
	m:SetAttribute("Uid", r.uid)
	m:SetAttribute("Species", r.species)
	m:SetAttribute("OwnerId", player.UserId)
	m:SetAttribute("Personality", r.personality)
	m:SetAttribute("Mutations", table.concat(r.mutations, ","))
	m:SetAttribute("MutationLabel", Genetics.MutationLabel(r.mutations))
	m:SetAttribute("Rarity", Genetics.DisplayRarity(r.species, r.mutations))
	m:SetAttribute("AltColor", traits.altColor)
	m:SetAttribute("Spots", traits.spots)
	m:SetAttribute("Glow", traits.glow)
	m:SetAttribute("Hue", r.hue or 0)
	m:SetAttribute("Wild", false)
	stamp(m, r)
	local foot = Models.FootOffset(m)
	local half = math.max(pad.half - 3, 1)
	local centre = pad.cf.Position
	local start = centre + Vector3.new(rng:NextNumber(-half, half), foot, rng:NextNumber(-half, half))
	m:PivotTo(CFrame.new(start) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	m:SetAttribute("Goal", start)
	m:SetAttribute("State", "Idle")
	m:SetAttribute("Speed", 0)
	CollectionService:AddTag(m, "Creature")
	m.Parent = folder
	live[player][r.uid] = m
	local def = Species[r.species]
	local pers = (Config.AI.Personality :: any)[r.personality] or {}
	local padU = r.padId
	CreatureAI.Add({
		model = m,
		kind = "park",
		owner = player,
		species = r.species,
		personality = r.personality,
		speed = def.Speed * (pers.speed or 1) * (if r.stage == "Baby" then 0.8 else 1),
		centre = centre,
		half = half,
		foot = foot,
		from = start,
		goal = start,
		departAt = 0,
		arriveAt = 0,
		state = "Idle",
		nextThink = os.clock() + rng:NextNumber(0.5, 3),
		hunger = function()
			return r.hunger
		end,
		context = function()
			return context(player, padU, m)
		end,
		onDone = function(_a, state)
			CreatureCare.StateDone(player, r, state, context(player, padU, m))
		end,
	})
end

function CreatureService.Model(player: Player, uid: string): Model?
	return live[player] and live[player][uid]
end

function CreatureService.Position(player: Player, uid: string): Vector3?
	local m = CreatureService.Model(player, uid)
	local a = m and CreatureAI.Get(m)
	return if a then CreatureAI.Position(a) else nil
end

-- Counts: (onPads, inStorage, total)
function CreatureService.Counts(data: any): (number, number, number)
	local park, storage = 0, 0
	for _, c in data.creatures do
		if c.padId then
			park += 1
		else
			storage += 1
		end
	end
	return park, storage, park + storage
end

-- Can a new creature be added? (reason if not)
function CreatureService.CanAdd(player: Player): (boolean, string?)
	local data = DataService.Get(player)
	if not data then
		return false, "Still loading..."
	end
	local park, storage, total = CreatureService.Counts(data)
	if total >= Config.CreatureCap then
		return false, "You have the max number of creatures"
	end
	if park < Formulas.ParkSlots(data.upgrades.Capacity) then
		return true, nil
	end
	if storage >= Config.StorageSlots then
		return false, "Storage is full - sell or place creatures first"
	end
	return true, nil
end

-- Finds a pad with room (capacity + park slots) or nil.
function CreatureService.PadWithRoom(player: Player, data: any, preferSpecies: string?): number?
	local park = CreatureService.Counts(data)
	if park >= Formulas.ParkSlots(data.upgrades.Capacity) then
		return nil
	end
	local best: number? = nil
	for _, pad in PlacementService.GetPads(player) do
		local here = ParkService.CreaturesOnPad(data, pad.u)
		if #here < (pad.def.PadCapacity or 4) then
			for _, c in here do
				if c.species == preferSpecies then
					return pad.u
				end
			end
			best = best or pad.u
		end
	end
	return best
end

-- New record defaults (caller fills species/genes/mutations/parents/gen/stage).
function CreatureService.NewRecord(player: Player, fields: any): any
	local def = Species[fields.species]
	local r = {
		uid = DataService.NewId(player, "c"),
		species = fields.species,
		genes = fields.genes or Genetics.Default(),
		mutations = fields.mutations or {},
		parents = fields.parents or {},
		gen = fields.gen or 1,
		born = os.time(),
		personality = def.Personality,
		stage = fields.stage or "Baby",
		hunger = 80,
		happy = 60,
		grow = 0,
		feeds = 0,
		bred = 0,
		scanned = false,
		hue = rng:NextNumber(-Config.Breeding.HueJitter, Config.Breeding.HueJitter),
		sz = rng:NextNumber(-Config.Breeding.SizeJitter, Config.Breeding.SizeJitter),
		source = fields.source or "hatch",
		seed = fields.seed or rng:NextInteger(1, 2 ^ 30),
	}
	return r
end

-- Adds a record (auto-assigns to a pad with room). Call CanAdd first. Returns uid.
function CreatureService.Add(player: Player, r: any): string
	local data = DataService.Get(player)
	assert(data, "not loaded")
	r.padId = CreatureService.PadWithRoom(player, data, r.species)
	DataService.Update(player, function(d)
		d.creatures[r.uid] = r
	end)
	spawnModel(player, r)
	Signals.Fire("CreaturesChanged", player)
	return r.uid
end

function CreatureService.Respawn(player: Player, uid: string)
	local r = rec(player, uid)
	if r then
		spawnModel(player, r)
	end
end

function CreatureService.Remove(player: Player, uid: string)
	despawn(player, uid)
	DataService.Update(player, function(d)
		d.creatures[uid] = nil
	end)
	Signals.Fire("CreaturesChanged", player)
end

-- Despawns a creature's model (record untouched).
function CreatureService.Despawn(player: Player, uid: string)
	despawn(player, uid)
end

function CreatureService.Init()
	folder = Instance.new("Folder")
	folder.Name = "Creatures"
	folder.Parent = workspace
	CreatureCare.Setup(CreatureService, live)
	PlotService.OnAssigned(function(player, _plot, data)
		live[player] = {}
		padCtx[player] = {}
		CreatureCare.OfflineCatchUp(player, data)
		for uid, r in data.creatures do
			r.uid = uid
			if r.padId then
				spawnModel(player, r)
			end
		end
	end, 30)
	PlotService.OnFreed(function(player)
		for uid in live[player] or {} do
			despawn(player, uid)
		end
		live[player] = nil
		padCtx[player] = nil
	end)
	Signals.On("PlotChanged", function(player)
		if padCtx[player] then
			padCtx[player] = {}
		end
		-- pads may have moved: re-home creatures whose pad moved (cheap: respawn those models)
		for _, pad in PlacementService.GetPads(player) do
			for uid, m in live[player] or {} do
				local a = CreatureAI.Get(m)
				if a and m:GetAttribute("PadUid") == pad.u and (a.centre - pad.cf.Position).Magnitude > 0.5 then
					task.defer(CreatureService.Respawn, player, uid)
				end
			end
		end
	end)
	Signals.On("PadRemoved", function(player, padU)
		local data = DataService.Get(player)
		if not data then
			return
		end
		for uid, r in data.creatures do
			if r.padId == padU then
				despawn(player, uid)
				r.padId = nil
			end
		end
		Signals.Fire("CreaturesChanged", player)
	end)
	Signals.On("BowUnlocked", function(player)
		for uid in live[player] or {} do
			task.defer(CreatureService.Respawn, player, uid)
		end
	end)
	CreatureCare.Bind()
end

function CreatureService.Start()
	CreatureCare.Loop()
end

return CreatureService
