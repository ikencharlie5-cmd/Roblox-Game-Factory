--!strict
-- Mirrors each player's placed plants/creatures/decor into workspace.ZooItems.Plot<n>
-- as Models with Attributes + an invisible Hitbox (Graphics builds visuals inside them).
-- Caches needs/income per item; recomputed only when a pad changes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Needs = require(Shared:WaitForChild("Needs"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local ItemService = {}

type Cache = { models: { [number]: Model }, income: { [number]: number }, thriving: { [number]: boolean } }
local caches: { [Player]: Cache } = {}

local root = Instance.new("Folder")
root.Name = "ZooItems"
root.Parent = workspace

local function plotFolder(plot: number): Folder
	local name = "Plot" .. plot
	local f = root:FindFirstChild(name) :: Folder?
	if not f then
		local nf = Instance.new("Folder")
		nf.Name = name
		nf:SetAttribute("PlotIndex", plot)
		nf.Parent = root
		f = nf
	end
	return f :: Folder
end

function ItemService.PlayerMult(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 1
	end
	return Formulas.PlayerMult(
		data,
		MonetizationService.HasPass(player, "VIP"),
		MonetizationService.HasPass(player, "DoubleCash")
	)
end

local function makeModel(player: Player, plot: number, id: number): Model
	local m = Instance.new("Model")
	m.Name = tostring(id)
	local hb = Instance.new("Part")
	hb.Name = "Hitbox"
	hb.Size = Vector3.new(3.6, 4, 3.6)
	hb.Transparency = 1
	hb.Anchored = true
	hb.CanCollide = false
	hb.CanTouch = false
	hb.CanQuery = true
	hb.Parent = m
	m.PrimaryPart = hb
	m:SetAttribute("ItemId", id)
	m:SetAttribute("OwnerUserId", player.UserId)
	m:SetAttribute("PlotIndex", plot)
	m.Parent = plotFolder(plot)
	return m
end

local function place(m: Model, plot: number, item: any)
	m:SetAttribute("PadIndex", item.pad)
	m:SetAttribute("Cell", item.cell)
	m:SetAttribute("Rot", item.rot)
	-- Hitbox bottom sits on the pad surface; visuals should align to Hitbox.CFrame.
	local cf = PlotService.CellCFrame(plot, item.pad, item.cell, item.rot)
	m:PivotTo(cf * CFrame.new(0, 2, 0))
end

-- Create or update the model for a placed plant/creature (kind "plant") or decor ("decor").
function ItemService.Upsert(player: Player, item: any, kind: string)
	local c = caches[player]
	local plot = PlotService.GetPlotIndex(player)
	if not c or not plot then
		return
	end
	local m = c.models[item.id]
	if not m then
		m = makeModel(player, plot, item.id)
		c.models[item.id] = m
	end
	local model = m :: Model
	model:SetAttribute("Kind", kind)
	if kind == "decor" then
		model:SetAttribute("DecorKind", item.kind)
	else
		local s = Config.Species.ByName[item.species]
		model:SetAttribute("Species", item.species)
		model:SetAttribute("Rarity", if s then s.Rarity else "Common")
		model:SetAttribute("Role", if s then s.Role else "")
		model:SetAttribute("PlantedAt", item.plantedAt)
		model:SetAttribute("ReadyAt", Formulas.ReadyAt(item))
		model:SetAttribute("Stage", Formulas.Stage(Formulas.Progress(item, os.time())))
		model:SetAttribute("Color", item.color or "None")
		model:SetAttribute("Weather", item.weather or "None")
	end
	place(model, plot, item)
end

function ItemService.Remove(player: Player, id: number)
	local c = caches[player]
	if not c then
		return
	end
	local m = c.models[id]
	if m then
		m:Destroy()
	end
	c.models[id] = nil
	c.income[id] = nil
	c.thriving[id] = nil
end

function ItemService.GetModel(player: Player, id: number): Model?
	local c = caches[player]
	return if c then c.models[id] else nil
end

-- Recompute needs/income for one pad and push Attributes.
function ItemService.RefreshPad(player: Player, pad: number)
	local c = caches[player]
	local data = DataService.Get(player)
	if not c or not data then
		return
	end
	local now = os.time()
	local mult = ItemService.PlayerMult(player)
	local results = Needs.ForPad(data, pad, now)
	local newThriving = false
	for _, p in data.placed do
		if p.pad == pad then
			local r = results[p.id]
			local m = c.models[p.id]
			local inc = Needs.CreatureIncome(p, r, now) * mult
			c.income[p.id] = inc
			if r and r.thriving and not c.thriving[p.id] then
				newThriving = true
			end
			c.thriving[p.id] = if r then r.thriving else false
			if m and r then
				m:SetAttribute("NeedBiome", r.biome)
				m:SetAttribute("NeedDecor", r.decor)
				m:SetAttribute("NeedBuddy", r.buddy)
				m:SetAttribute("NeedsMet", r.met)
				m:SetAttribute("NeedsTotal", r.total)
				m:SetAttribute("Thriving", r.thriving)
				m:SetAttribute("Herd", r.herd)
				m:SetAttribute("Income", inc)
			end
		end
	end
	if newThriving then
		Guard.Sound(player, "Thriving")
	end
	local count = 0
	for _, t in c.thriving do
		if t then
			count += 1
		end
	end
	player:SetAttribute("ThrivingCount", count)
	QuestService.SetState(player, "Thriving", count)
	ItemService.RecalcTotal(player)
end

function ItemService.RefreshAll(player: Player)
	for pad = 1, #Config.PadCosts do
		ItemService.RefreshPad(player, pad)
	end
end

-- Sums cached income -> player Attribute IncomePerSec. Returns { [pad] = $/s }, total.
function ItemService.RecalcTotal(player: Player): ({ [number]: number }, number)
	local c = caches[player]
	local data = DataService.Get(player)
	local perPad: { [number]: number } = {}
	local total = 0
	if c and data then
		for _, p in data.placed do
			local v = c.income[p.id] or 0
			perPad[p.pad] = (perPad[p.pad] or 0) + v
			total += v
		end
	end
	player:SetAttribute("IncomePerSec", total)
	return perPad, total
end

function ItemService.Income(player: Player): ({ [number]: number }, number)
	return ItemService.RecalcTotal(player)
end

function ItemService.Rebuild(player: Player)
	local c = caches[player]
	local data = DataService.Get(player)
	if not c or not data then
		return
	end
	for id in c.models do
		ItemService.Remove(player, id)
	end
	for _, p in data.placed do
		ItemService.Upsert(player, p, "plant")
	end
	for _, d in data.decor do
		ItemService.Upsert(player, d, "decor")
	end
	ItemService.RefreshAll(player)
end

function ItemService.Init()
	PlotService.OnAssigned(function(player)
		caches[player] = { models = {}, income = {}, thriving = {} }
		ItemService.Rebuild(player)
	end)
	MonetizationService.OnPassesChanged(function(player)
		if caches[player] then
			ItemService.RefreshAll(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		local c = caches[p]
		if c then
			for _, m in c.models do
				m:Destroy()
			end
		end
		caches[p] = nil
	end)
end

return ItemService
