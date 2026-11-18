--!strict
-- Wild creatures in Greenleaf Forest: spawns at nodes tagged "WildSpawn" (attribute Zone =
-- "Meadow" | "Hollow" | "Glade"), max 12 alive, respawn 45 s. Zone gating: players inside a
-- "ZoneArea" part of a locked zone are sent back (server-enforced). Sets player attribute Zone.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Species = require(Shared:WaitForChild("Species"))
local Genetics = require(Shared:WaitForChild("Genetics"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local CreatureAI = require(script.Parent:WaitForChild("CreatureAI"))
local Models = require(script.Parent:WaitForChild("Models"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local WildService = {}

export type Wild = {
	id: string,
	species: string,
	genes: string,
	mutations: { string },
	seed: number,
	zone: string,
	node: number,
	model: Model,
	agent: any,
	trust: number,
	claimedBy: Player?,
	claimUntil: number,
	attempts: number,
	window: any?,
}

local rng = Random.new()
local folder: Folder
local wilds: { [string]: Wild } = {}
local nodes: { { pos: Vector3, zone: string } } = {}
local nextId = 1
local pendingRespawns = 0

local function zoneDef(id: string): any?
	for _, z in Config.Zones do
		if z.Id == id then
			return z
		end
	end
	return nil
end
WildService.ZoneDef = zoneDef

local function findNodes()
	for _, inst in CollectionService:GetTagged("WildSpawn") do
		local zone = inst:GetAttribute("Zone")
		if type(zone) == "string" and zoneDef(zone) then
			local pos = if inst:IsA("BasePart") then inst.Position elseif inst:IsA("Model") then inst:GetPivot().Position else nil
			if pos then
				table.insert(nodes, { pos = pos, zone = zone })
			end
		end
	end
	if #nodes == 0 then
		warn("[WildService] no parts tagged WildSpawn; using fallback forest nodes north of the hub")
		local r = Config.Grid.PlotRadius
		local centres = { Meadow = Vector3.new(0, 0, -(r + 160)), Hollow = Vector3.new(-90, 0, -(r + 300)), Glade = Vector3.new(90, 0, -(r + 440)) }
		for zone, c in centres do
			for i = 1, 4 do
				local a = i * math.pi / 2
				table.insert(nodes, { pos = c + Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30), zone = zone })
			end
		end
	end
end

local function nearestStarfruit(pos: Vector3): boolean
	for _, p in Players:GetPlayers() do
		local d = DataService.Get(p)
		local root = Guard.RootPos(p)
		if d and root and d.boosts.starfruit > os.time() and (root - pos).Magnitude < 200 then
			return true
		end
	end
	return false
end

-- Species that a player who hasn't bred their first (Golden) egg owns exactly one of.
local function wantedSpecies(zone: any): { string }
	local out = {}
	for _, p in Players:GetPlayers() do
		local d = DataService.Get(p)
		if d and not d.flags.goldenGiven then
			local count: { [string]: number } = {}
			for _, c in d.creatures do
				count[c.species] = (count[c.species] or 0) + 1
			end
			for sp, n in count do
				if n == 1 and table.find(zone.Species, sp) and not table.find(out, sp) then
					table.insert(out, sp)
				end
			end
		end
	end
	return out
end

local function pickSpecies(zone: any): string
	local want = wantedSpecies(zone)
	if #want > 0 and rng:NextNumber() < Config.Capture.StarterSpeciesBias then
		return want[rng:NextInteger(1, #want)]
	end
	local weights: any = Config.Capture.SpawnWeights
	local rain = Guard.State():GetAttribute("Weather") == "Rain"
	local total, list = 0, {}
	for _, sp in zone.Species do
		local w = weights[Species[sp].Rarity] or 1
		if rain and zone.RainBoost == sp then
			w *= 2
		end
		total += w
		table.insert(list, { sp = sp, w = w })
	end
	local roll = rng:NextNumber(0, total)
	for _, e in list do
		roll -= e.w
		if roll <= 0 then
			return e.sp
		end
	end
	return list[1].sp
end

local function rollWildMutations(zone: any, pos: Vector3): { string }
	local mult = if nearestStarfruit(pos) then Config.Capture.StarfruitEpicMult else 1
	if zone.Legendary and rng:NextNumber() < Config.Capture.WildLegendaryChance * mult then
		return { "Crystal" }
	end
	if rng:NextNumber() < Config.Capture.WildEpicChance * mult then
		return { if rng:NextNumber() < 0.5 then "Golden" else "Albino" }
	end
	return {}
end

local function spawnOne()
	local used: { [number]: boolean } = {}
	for _, w in wilds do
		used[w.node] = true
	end
	local free = {}
	for i in nodes do
		if not used[i] then
			table.insert(free, i)
		end
	end
	if #free == 0 then
		return
	end
	local ni = free[rng:NextInteger(1, #free)]
	-- Starter guarantee: if a new player needs a breeding match and the first (always-open) zone
	-- has none alive, this spawn goes there as that species, so nobody gets stuck on the tutorial.
	local firstZone = Config.Zones[1]
	local forced: string? = nil
	local want = wantedSpecies(firstZone)
	if #want > 0 then
		local present = false
		for _, w in wilds do
			if w.zone == firstZone.Id and table.find(want, w.species) then
				present = true
			end
		end
		if not present then
			local firstFree = {}
			for _, i in free do
				if nodes[i].zone == firstZone.Id then
					table.insert(firstFree, i)
				end
			end
			if #firstFree > 0 then
				ni = firstFree[rng:NextInteger(1, #firstFree)]
				forced = want[rng:NextInteger(1, #want)]
			end
		end
	end
	local node = nodes[ni]
	local zone = zoneDef(node.zone)
	local species = forced or pickSpecies(zone)
	local rec = {
		species = species,
		genes = Genetics.Random(rng, Config.Capture.RecessiveAlleleChance),
		mutations = rollWildMutations(zone, node.pos),
		stage = "Adult",
		hue = rng:NextNumber(-0.06, 0.06),
		sz = rng:NextNumber(-0.03, 0.03),
		seed = rng:NextInteger(1, 2 ^ 30),
	}
	local id = "w" .. nextId
	nextId += 1
	local m = Models.Creature(rec, false)
	m.Name = "Wild_" .. id
	local foot = Models.FootOffset(m)
	local start = node.pos + Vector3.new(0, foot, 0)
	m:PivotTo(CFrame.new(start))
	m:SetAttribute("Wild", true)
	m:SetAttribute("WildId", id)
	m:SetAttribute("Species", species)
	m:SetAttribute("Zone", node.zone)
	m:SetAttribute("Mutations", table.concat(rec.mutations, ","))
	m:SetAttribute("MutationLabel", Genetics.MutationLabel(rec.mutations))
	m:SetAttribute("Rarity", Genetics.DisplayRarity(species, rec.mutations))
	m:SetAttribute("Trust", 0)
	m:SetAttribute("ClaimedBy", 0)
	m:SetAttribute("Goal", start)
	m:SetAttribute("State", "Idle")
	m:SetAttribute("Speed", 0)
	m:SetAttribute("Stage", "Adult")
	CollectionService:AddTag(m, "WildCreature")
	CollectionService:AddTag(m, "Creature")
	m.Parent = folder
	local agent = {
		model = m,
		kind = "wild",
		species = species,
		personality = Species[species].Personality,
		speed = Species[species].Speed,
		centre = node.pos,
		half = Config.AI.WildWanderRadius,
		foot = foot,
		from = start,
		goal = start,
		departAt = 0,
		arriveAt = 0,
		state = "Idle",
		nextThink = os.clock() + rng:NextNumber(0, 3),
		hunger = function()
			return 80
		end,
	}
	CreatureAI.Add(agent :: any)
	wilds[id] = {
		id = id,
		species = species,
		genes = rec.genes,
		mutations = rec.mutations,
		seed = rec.seed,
		zone = node.zone,
		node = ni,
		model = m,
		agent = agent,
		trust = 0,
		claimedBy = nil,
		claimUntil = 0,
		attempts = Config.Capture.Attempts,
		window = nil,
	}
end

function WildService.Get(id: any): Wild?
	return if type(id) == "string" then wilds[id] else nil
end

function WildService.All(): { [string]: Wild }
	return wilds
end

function WildService.Position(w: Wild): Vector3
	return CreatureAI.Position(w.agent)
end

-- Removes a wild (captured) and schedules a respawn. `delay` keeps the model visible (not interactable)
-- for that many seconds so the client can play the "Captured" moment.
function WildService.Despawn(id: string, delay: number?)
	local w = wilds[id]
	if not w then
		return
	end
	wilds[id] = nil
	CreatureAI.Remove(w.model)
	local model = w.model
	if delay and delay > 0 then
		model:SetAttribute("Wild", false)
		task.delay(delay, function()
			model:Destroy()
		end)
	else
		model:Destroy()
	end
	pendingRespawns += 1
	task.delay(Config.Capture.RespawnSeconds, function()
		pendingRespawns -= 1
		spawnOne()
	end)
end

function WildService.ZoneUnlocked(data: any, zone: string): boolean
	return data.zones[zone] == true
end

-- Zone of a world position from "ZoneArea" parts (nil = park/hub).
function WildService.ZoneAt(pos: Vector3): string?
	for _, inst in CollectionService:GetTagged("ZoneArea") do
		if inst:IsA("BasePart") then
			local l = inst.CFrame:PointToObjectSpace(pos)
			local h = inst.Size / 2
			if math.abs(l.X) <= h.X and math.abs(l.Z) <= h.Z and math.abs(l.Y) <= h.Y + 30 then
				return inst:GetAttribute("Zone") :: string?
			end
		end
	end
	return nil
end

local function gateCFrame(zone: string): CFrame?
	for _, inst in CollectionService:GetTagged("ZoneGate") do
		if inst:GetAttribute("Zone") == zone and inst:IsA("BasePart") then
			return inst.CFrame * CFrame.new(0, 3, 6)
		end
	end
	return nil
end

function WildService.Init()
	folder = Instance.new("Folder")
	folder.Name = "WildCreatures"
	folder.Parent = workspace
end

function WildService.Start()
	local t0 = os.clock()
	while not workspace:GetAttribute("WorldReady") and os.clock() - t0 < Config.WorldReadyTimeout do
		task.wait(0.2)
	end
	findNodes()
	for _ = 1, math.min(Config.Capture.MaxWild, #nodes) do
		spawnOne()
	end
	while true do
		task.wait(1)
		local alive = 0
		for _ in wilds do
			alive += 1
		end
		if alive + pendingRespawns < math.min(Config.Capture.MaxWild, #nodes) then
			spawnOne()
		end
		for _, p in Players:GetPlayers() do
			local data = DataService.Get(p)
			local root = Guard.RootPos(p)
			if data and root then
				local zone = WildService.ZoneAt(root)
				p:SetAttribute("Zone", zone or "Park")
				if zone and not WildService.ZoneUnlocked(data, zone) then
					local def = zoneDef(zone)
					local back = gateCFrame(zone)
					local char = p.Character
					if char then
						local plot = PlotService.GetPlot(p)
						char:PivotTo(back or (if plot then PlotService.SpawnCFrame(plot) else CFrame.new(0, 10, 0)))
					end
					if def then
						Guard.Toast(p, def.Name .. " unlocks at Park Level " .. def.Level .. " + " .. def.Cost .. " coins", "error")
					end
				end
			end
		end
	end
end

return WildService
