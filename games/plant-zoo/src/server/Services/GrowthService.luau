--!strict
-- Growth: os.time timestamps (grows offline), stage changes, maturity (color mutation roll,
-- Index), weather growth boost, Water, Finish All Growing product, Grow Tonic, Auto Gardener water.
-- When a plant matures its growTotal/plantedAt are set to 0 (= "grown creature").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ItemService = require(script.Parent:WaitForChild("ItemService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local AnnounceService = require(script.Parent:WaitForChild("AnnounceService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local GrowthService = {}

local stages: { [Player]: { [number]: string } } = {}
local watered: { [Player]: { [number]: number } } = {}

local function weatherDef(): any
	local name = Guard.State():GetAttribute("Weather")
	for _, w in Config.Weather.Types do
		if w.Name == name then
			return w
		end
	end
	return nil
end

-- Marks species/mutation as found in the Index. Returns true if it's a new entry.
function GrowthService.MarkFound(player: Player, species: string, mutation: string): boolean
	local data = DataService.Get(player)
	if not data then
		return false
	end
	local entry = data.indexFound[species]
	if entry and entry[mutation] then
		return false
	end
	DataService.Update(player, function(d)
		d.indexFound[species] = d.indexFound[species] or {}
		d.indexFound[species][mutation] = true
	end)
	return true
end

local function rollColor(): string
	local w = weatherDef()
	local oddsMult = if w and w.ColorOddsMult then w.ColorOddsMult else 1
	local r = math.random()
	local acc = 0
	for _, m in Config.ColorMutations do
		acc += m.Chance * oddsMult
		if r < acc then
			return m.Name
		end
	end
	return "None"
end

local function mature(player: Player, item: any)
	local color = rollColor()
	DataService.Update(player, function()
		item.plantedAt = 0
		item.growTotal = 0
		item.color = color
	end)
	ItemService.Upsert(player, item, "plant")
	ItemService.RefreshPad(player, item.pad)
	local s = Config.Species.ByName[item.species]
	Guard.Sound(player, "Bloom")
	if s and Formulas.RarityIndex(s.Rarity) >= Formulas.RarityIndex("Rare") then
		Guard.Sound(player, "Reveal" .. s.Rarity)
	end
	if GrowthService.MarkFound(player, item.species, "None") then
		Guard.Notify(player, "New Index entry: " .. item.species .. "!", "success")
	end
	if color ~= "None" then
		GrowthService.MarkFound(player, item.species, color)
		Guard.Sound(player, "Mutation")
		Guard.Notify(player, "Your " .. item.species .. " grew " .. string.upper(color) .. "!", "success")
		if (Config.AnnounceMutations :: any)[color] then
			AnnounceService.Send(
				player.DisplayName .. " grew a " .. string.upper(color) .. " " .. item.species .. "!",
				s and s.Rarity
			)
		end
	end
end

local function tickPlayer(player: Player, dt: number)
	local data = DataService.Get(player)
	local st = stages[player]
	if not data or not st then
		return
	end
	local now = os.time()
	local w = weatherDef()
	local boost = if w then w.Growth - 1 else 0
	for _, item in table.clone(data.placed) do
		if (item.growTotal or 0) > 0 then
			if boost > 0 then
				DataService.UpdateQuiet(player, function()
					item.plantedAt -= boost * dt
				end)
				local m = ItemService.GetModel(player, item.id)
				if m then
					m:SetAttribute("ReadyAt", Formulas.ReadyAt(item))
				end
			end
			local stage = Formulas.Stage(Formulas.Progress(item, now))
			if stage == "Grown" then
				mature(player, item)
				st[item.id] = "Grown"
			elseif st[item.id] ~= stage then
				local m = ItemService.GetModel(player, item.id)
				if st[item.id] ~= nil then
					Guard.Sound(player, "GrowStage", m and m.PrimaryPart)
				end
				st[item.id] = stage
				if m then
					m:SetAttribute("Stage", stage)
				end
			end
		end
	end
end

local function findPlaced(data: any, id: any): any?
	for _, p in data.placed do
		if p.id == id then
			return p
		end
	end
	return nil
end

-- Cuts `fraction` of the remaining grow time. Returns false if on cooldown/not growing.
function GrowthService.WaterItem(player: Player, item: any): boolean
	local data = DataService.Get(player)
	local w = watered[player]
	if not data or not w or (item.growTotal or 0) <= 0 then
		return false
	end
	local now = os.time()
	if now - (w[item.id] or 0) < Config.WaterCooldown then
		return false
	end
	w[item.id] = now
	local lvl = math.max(1, data.upgrades.WateringCan or 1)
	local pct = Config.Upgrades.WateringCan.Values[lvl] or 0.1
	local remaining = math.max(0, Formulas.ReadyAt(item) - now)
	DataService.Update(player, function()
		item.plantedAt -= remaining * pct
	end)
	local m = ItemService.GetModel(player, item.id)
	if m then
		m:SetAttribute("ReadyAt", Formulas.ReadyAt(item))
		m:SetAttribute("PlantedAt", item.plantedAt)
	end
	QuestService.Progress(player, "Water", 1)
	return true
end

-- Finish one growing plant now (Grow Tonic). Returns false if not allowed.
function GrowthService.Finish(player: Player, id: number, maxRarity: string?): boolean
	local data = DataService.Get(player)
	local item = if data then findPlaced(data, id) else nil
	if not item or (item.growTotal or 0) <= 0 then
		return false
	end
	local s = Config.Species.ByName[item.species]
	if maxRarity and s and Formulas.RarityIndex(s.Rarity) > Formulas.RarityIndex(maxRarity) then
		return false
	end
	DataService.Update(player, function()
		item.plantedAt = os.time() - item.growTotal - 1
	end)
	tickPlayer(player, 0)
	return true
end

function GrowthService.Init()
	DataService.OnLoaded(function(player)
		stages[player] = {}
		watered[player] = {}
	end)
	Players.PlayerRemoving:Connect(function(p)
		stages[p] = nil
		watered[p] = nil
	end)

	-- Water(itemId) -> (ok, newReadyAt)
	Guard.Bind("Water", function(player, data, id)
		local item = findPlaced(data, id)
		if not item then
			return Guard.Fail(player, "Plant not found")
		end
		if (item.growTotal or 0) <= 0 then
			return Guard.Fail(player, "Already grown!")
		end
		if not GrowthService.WaterItem(player, item) then
			return Guard.Fail(player, "Still wet - try again soon")
		end
		Guard.Sound(player, "Water")
		return true, Formulas.ReadyAt(item)
	end)

	MonetizationService.RegisterProduct("FinishGrowing", function(player)
		local data = DataService.Get(player)
		if not data then
			return false
		end
		DataService.Update(player, function(d)
			for _, item in d.placed do
				if (item.growTotal or 0) > 0 then
					item.plantedAt = os.time() - item.growTotal - 1
				end
			end
		end)
		tickPlayer(player, 0)
		return true
	end)
end

function GrowthService.Start()
	local lastAuto = 0
	local lastT = os.clock()
	while true do
		task.wait(1)
		local nowC = os.clock()
		local dt = nowC - lastT
		lastT = nowC
		local doAuto = nowC - lastAuto >= Config.AutoGardenerSeconds
		if doAuto then
			lastAuto = nowC
		end
		for _, p in Players:GetPlayers() do
			local ok, err = pcall(tickPlayer, p, dt)
			if not ok then
				warn("[GrowthService] tick failed:", err)
			end
			if doAuto and MonetizationService.HasPass(p, "AutoGardener") then
				local data = DataService.Get(p)
				if data then
					for _, item in table.clone(data.placed) do
						GrowthService.WaterItem(p, item)
					end
				end
			end
		end
	end
end

return GrowthService
