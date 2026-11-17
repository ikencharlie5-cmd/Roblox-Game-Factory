--!strict
-- Release to the Wild (rebirth) + the hub World Reserve list.
-- Reserve is published as JSON in ReplicatedStorage.GameState.WorldReserve (StringValue):
--   [{ species, color, owner, userId }]  (newest last, max Config.Release.ReserveDisplayMax)
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ItemService = require(script.Parent:WaitForChild("ItemService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local AnnounceService = require(script.Parent:WaitForChild("AnnounceService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local ReleaseService = {}

local reserve: { { species: string, color: string, owner: string, userId: number } } = {}
local reserveValue: StringValue

local function publish()
	while #reserve > Config.Release.ReserveDisplayMax do
		table.remove(reserve, 1)
	end
	reserveValue.Value = HttpService:JSONEncode(reserve)
end

local function addToReserve(player: Player, species: string, color: string)
	table.insert(reserve, { species = species, color = color, owner = player.DisplayName, userId = player.UserId })
end

-- Requirement for the player's NEXT release.
function ReleaseService.Requirement(data: any): (number, number, string)
	local n = data.releases + 1
	return n, Formulas.ReleaseCash(n), Config.ReleaseMinRarity(n)
end

local function findCreature(data: any, id: number): (any?, string?, number?)
	for i, p in data.placed do
		if p.id == id then
			return p, "placed", i
		end
	end
	for i, c in data.inventory.creatures do
		if c.id == id then
			return c, "inventory", i
		end
	end
	return nil, nil, nil
end

-- Release(creatureId) -> (ok, { releases, hope })
local function release(player: Player, data: any, id: any): (boolean, any)
	if type(id) ~= "number" then
		return Guard.Fail(player, "Pick a creature to release")
	end
	local item, where, idx = findCreature(data, id)
	if not item then
		return Guard.Fail(player, "Creature not found")
	end
	if where == "placed" and (item.growTotal or 0) > 0 then
		return Guard.Fail(player, "It has to be fully grown")
	end
	local s = Config.Species.ByName[item.species]
	local n, cash, minRarity = ReleaseService.Requirement(data)
	if not s or Formulas.RarityIndex(s.Rarity) < Formulas.RarityIndex(minRarity) then
		return Guard.Fail(player, "Needs a " .. minRarity .. "+ creature")
	end
	if data.cash < cash then
		return Guard.Fail(player, "Need $" .. Format.Number(cash))
	end
	local hope = Config.Release.HopePer * n
	DataService.Update(player, function(d)
		if where == "placed" then
			table.remove(d.placed, idx :: number)
		else
			table.remove(d.inventory.creatures, idx :: number)
		end
		table.insert(d.released, { species = item.species, color = item.color or "None" })
		d.releases = n
		d.hope += hope
		d.cash = Config.Release.ResetCash
		d.padsOwned = 1
		for i in d.jars do
			d.jars[i] = 0
		end
		-- Items on locked pads go back to inventory (kept, not lost).
		local keep = {}
		for _, p in d.placed do
			if p.pad == 1 then
				table.insert(keep, p)
			elseif (p.growTotal or 0) <= 0 then
				table.insert(
					d.inventory.creatures,
					{ id = p.id, species = p.species, color = p.color, weather = p.weather }
				)
			else
				d.inventory.seeds[p.species] = (d.inventory.seeds[p.species] or 0) + 1
			end
		end
		d.placed = keep
		local keepDecor = {}
		for _, dec in d.decor do
			if dec.pad == 1 then
				table.insert(keepDecor, dec)
			else
				d.inventory.decor[dec.kind] = (d.inventory.decor[dec.kind] or 0) + 1
			end
		end
		d.decor = keepDecor
	end)
	player:SetAttribute("PadsOwned", 1)
	ItemService.Rebuild(player)
	PlotService.RefreshPlotAttrs(player)
	ShopService.SendStock(player)
	addToReserve(player, item.species, item.color or "None")
	publish()
	Guard.Sound(player, "Release")
	Guard.Notify(player, "Released! +" .. hope .. " Hope, income x" .. (1 + Config.Income.PerRelease * n), "success")
	AnnounceService.Send(player.DisplayName .. " released a " .. item.species .. " to the Wild!", s.Rarity)
	return true, { releases = n, hope = hope }
end

function ReleaseService.Init()
	reserveValue = Instance.new("StringValue")
	reserveValue.Name = "WorldReserve"
	reserveValue.Value = "[]"
	reserveValue.Parent = Guard.State()

	Guard.Bind("Release", release)

	DataService.OnLoaded(function(player, data)
		-- Show this player's past releases (most recent 5) in the hub reserve.
		local from = math.max(1, #data.released - 4)
		for i = from, #data.released do
			local r = data.released[i]
			addToReserve(player, r.species, r.color or "None")
		end
		if #data.released > 0 then
			publish()
		end
	end)
end

return ReleaseService
