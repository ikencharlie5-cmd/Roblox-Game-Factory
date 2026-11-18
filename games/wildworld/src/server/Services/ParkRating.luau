--!strict
-- Helper for PlotService (not a service). Habitat ratings per pad, park rating + tier, income per
-- minute (server formula).
-- income/min = Σ pads [ Σ creatures (base × mutationMult × happyMult) × habitatMult ] × parkTierMult
--              × (1 + snack stands) × VIP
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Habitat = require(Shared:WaitForChild("Habitat"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotCore = require(script.Parent:WaitForChild("PlotCore"))
local Placement = require(script.Parent:WaitForChild("Placement"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local ParkRating = {}

local results: { [Player]: { [number]: any } } = {}
local income: { [Player]: number } = {}
local queued: { [Player]: boolean } = {}

-- Creature records on pad u.
function ParkRating.CreaturesOnPad(data: any, padU: number): { any }
	local out = {}
	for _, c in data.creatures do
		if c.padId == padU then
			table.insert(out, c)
		end
	end
	return out
end

local function rate(player: Player, data: any, pad: any): any
	local defs = {}
	for _, row in Placement.ItemsInPad(player, pad.u) do
		table.insert(defs, row.def)
	end
	local species = {}
	for _, c in ParkRating.CreaturesOnPad(data, pad.u) do
		table.insert(species, c.species)
	end
	return Habitat.Rate(pad.def, defs, species)
end

local function decorBonus(player: Player, data: any): number
	local grid = Placement.Grid(player)
	if not grid then
		return 0
	end
	local paths, stands, decor = 0, 0, 0
	for _, it in grid.items do
		local def = Items.Get(it.id)
		if def then
			if def.Kind == "path" then
				paths += 1
			elseif def.Kind == "stand" then
				stands += 1
			elseif def.Layer == "object" and not grid:PadAt(it.x, it.z) and (def.Enrich or def.Kind == "decor") then
				decor += 1
			end
		end
	end
	local likes = if data.likes.day == Formulas.Day() then data.likes.count else 0
	local b = math.min(paths * 0.1, 3) + math.min(stands, 3) + math.min(decor * 0.5, 4)
	return math.min(b, Config.Economy.DecorBonusMax) + math.min(likes, Config.Economy.LikeBonusCap)
end

-- Recompute everything for a player now.
function ParkRating.Recalc(player: Player)
	local data = DataService.Get(player)
	if not data or not PlotCore.GetPlot(player) then
		return
	end
	local prev = results[player] or {}
	local now: { [number]: any } = {}
	local sum, n, sumAll, nAll = 0, 0, 0, 0
	local perMin = 0
	for _, pad in Placement.GetPads(player) do
		local res = rate(player, data, pad)
		now[pad.u] = res
		local creatures = ParkRating.CreaturesOnPad(data, pad.u)
		sumAll += res.rating
		nAll += 1
		if #creatures > 0 then
			sum += res.rating
			n += 1
		end
		local padValue = 0
		for _, c in creatures do
			padValue += Formulas.CreatureValue(c)
		end
		perMin += padValue * Formulas.HabitatMult(res.rating)
		if pad.model then
			pad.model:SetAttribute("Rating", res.rating)
			pad.model:SetAttribute("Stars", Habitat.Stars(res.rating))
			pad.model:SetAttribute("Count", #creatures)
		end
		local old = prev[pad.u]
		if not old or old.rating ~= res.rating then
			Remotes.Event("HabitatChanged"):FireClient(player, pad.u, res)
			if old and res.rating > old.rating then
				Guard.Sound(player, "RatingUp", { position = pad.cf.Position })
			end
		end
	end
	results[player] = now
	local avg = if n > 0 then sum / n elseif nAll > 0 then sumAll / nAll else 0
	local rating = math.clamp(math.floor(avg + decorBonus(player, data) + 0.5), 0, 100)
	local tierIdx, tier = Formulas.ParkTier(rating)
	local mult = (1 + tier.Bonus)
	mult *= 1 + Config.Economy.SnackStandBonus * math.min(Placement.CountKind(player, "stand"), 3)
	if MonetizationService.HasPass(player, "VIP") then
		mult *= 1 + Config.Economy.VipCoinBonus
	end
	perMin *= mult
	income[player] = perMin

	local oldTier = player:GetAttribute("ParkTierIndex")
	player:SetAttribute("ParkRating", rating)
	player:SetAttribute("ParkTier", tier.Name)
	player:SetAttribute("ParkTierIndex", tierIdx)
	player:SetAttribute("IncomePerMin", math.floor(perMin * 10) / 10)
	local plotPart = PlotCore.PlotPart(PlotCore.GetPlot(player) :: number)
	if plotPart then
		plotPart:SetAttribute("ParkRating", rating)
		plotPart:SetAttribute("ParkTier", tier.Name)
	end
	if type(oldTier) == "number" and tierIdx > oldTier then
		Guard.Reveal(player, "Tier", { tier = tier.Name, rating = rating, bonus = tier.Bonus })
		Guard.Sound(player, "TierUp")
	end
	if rating > (data.bestRating or 0) then
		DataService.Update(player, function(d)
			d.bestRating = rating
		end)
	end
end

-- Debounced recalc (many changes in one frame -> one recalc).
function ParkRating.Queue(player: Player)
	if queued[player] then
		return
	end
	queued[player] = true
	task.defer(function()
		queued[player] = nil
		if player.Parent then
			ParkRating.Recalc(player)
		end
	end)
end

function ParkRating.PadResult(player: Player, padU: number): any?
	local r = results[player]
	return r and r[padU]
end

function ParkRating.IncomePerMin(player: Player): number
	return income[player] or 0
end

-- Called from PlotService.Init.
function ParkRating.Bind()
	Signals.On("PlotChanged", function(p)
		ParkRating.Queue(p)
	end)
	Signals.On("CreaturesChanged", function(p)
		ParkRating.Queue(p)
	end)
	PlotCore.OnAssigned(function(player)
		ParkRating.Recalc(player)
	end, 40)
	Players.PlayerRemoving:Connect(function(p)
		results[p] = nil
		income[p] = nil
		queued[p] = nil
	end)
	Guard.Bind("GetHabitat", function(player, _data, padU)
		if type(padU) ~= "number" then
			return false, "Bad request"
		end
		local r = ParkRating.PadResult(player, padU)
		if not r then
			return false, "No such habitat"
		end
		return true, r
	end)
end

-- Called from PlotService.Start.
function ParkRating.Loop()
	-- happiness/hunger drift changes income: refresh every 15 s
	while true do
		task.wait(15)
		for _, p in Players:GetPlayers() do
			ParkRating.Queue(p)
		end
	end
end

return ParkRating
