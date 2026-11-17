--!strict
-- Zoo management: BuyPad, UnlockBiome, SetPadBiome, SellCreature, BuyUpgrade.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ItemService = require(script.Parent:WaitForChild("ItemService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local ZooService = {}

local function findIndex(list: { any }, id: number): number?
	for i, v in list do
		if v.id == id then
			return i
		end
	end
	return nil
end

function ZooService.Init()
	-- BuyPad(padIndex?) -> (ok, newPadsOwned). Pads unlock in order.
	Guard.Bind("BuyPad", function(player, data, padIndex)
		local nextPad = data.padsOwned + 1
		if nextPad > #Config.PadCosts then
			return Guard.Fail(player, "All pads unlocked!")
		end
		if padIndex ~= nil and padIndex ~= nextPad then
			return Guard.Fail(player, "Unlock Pad " .. nextPad .. " first")
		end
		local cost = Config.PadCosts[nextPad]
		if not DataService.TrySpend(player, cost) then
			return Guard.Fail(player, "Need $" .. Format.Number(cost))
		end
		DataService.Update(player, function(d)
			d.padsOwned = nextPad
		end)
		player:SetAttribute("PadsOwned", nextPad)
		PlotService.RefreshPlotAttrs(player)
		Guard.Sound(player, "Expand")
		Guard.Notify(player, "Exhibit Pad " .. nextPad .. " unlocked!", "success")
		QuestService.Progress(player, "BuyPad", 1)
		return true, nextPad
	end)

	-- UnlockBiome(biomeName) -> (ok)
	Guard.Bind("UnlockBiome", function(player, data, biome)
		local def = if Guard.IsString(biome) then (Config.Biomes :: any)[biome] else nil
		if not def then
			return Guard.Fail(player, "Unknown biome")
		end
		if data.biomes[biome] then
			return Guard.Fail(player, "Already unlocked")
		end
		if not DataService.TrySpend(player, def.Cost) then
			return Guard.Fail(player, "Need $" .. Format.Number(def.Cost))
		end
		DataService.Update(player, function(d)
			d.biomes[biome] = true
		end)
		Guard.Sound(player, "Expand")
		Guard.Notify(player, biome .. " biome unlocked!", "success")
		return true, biome
	end)

	-- SetPadBiome(padIndex, biomeName) -> (ok). Free once the biome is unlocked.
	Guard.Bind("SetPadBiome", function(player, data, pad, biome)
		if not Guard.IsInt(pad, 1, data.padsOwned) then
			return Guard.Fail(player, "That pad is locked")
		end
		if not Guard.IsString(biome) or not (Config.Biomes :: any)[biome] then
			return Guard.Fail(player, "Unknown biome")
		end
		if not data.biomes[biome] then
			return Guard.Fail(player, "Unlock " .. biome .. " first")
		end
		DataService.Update(player, function(d)
			d.padBiome[pad] = biome
		end)
		PlotService.RefreshPlotAttrs(player)
		ItemService.RefreshPad(player, pad)
		Guard.Sound(player, "Place")
		return true, biome
	end)

	-- SellCreature(itemId) -> (ok, cashGained). Grown creatures only (placed or in inventory).
	Guard.Bind("SellCreature", function(player, data, id)
		if type(id) ~= "number" then
			return Guard.Fail(player, "Invalid creature")
		end
		local pi = findIndex(data.placed, id)
		local ii = findIndex(data.inventory.creatures, id)
		local item = if pi then data.placed[pi] elseif ii then data.inventory.creatures[ii] else nil
		if not item then
			return Guard.Fail(player, "Creature not found")
		end
		if pi and Formulas.Progress(item, os.time()) < 1 then
			return Guard.Fail(player, "Wait until it's grown")
		end
		local value = Formulas.SellValue(item)
		local pad = item.pad
		DataService.Update(player, function(d)
			if pi then
				table.remove(d.placed, pi)
			else
				table.remove(d.inventory.creatures, ii :: number)
			end
			d.cash += value
		end)
		if pi then
			ItemService.Remove(player, id)
			ItemService.RefreshPad(player, pad)
		end
		Guard.Sound(player, "Sell")
		Guard.Notify(player, "Sold " .. item.species .. " for $" .. Format.Number(value), "success")
		return true, value
	end)

	-- BuyUpgrade(key) -> (ok, newLevel)
	Guard.Bind("BuyUpgrade", function(player, data, key)
		local def = if Guard.IsString(key) then (Config.Upgrades :: any)[key] else nil
		if not def then
			return Guard.Fail(player, "Unknown upgrade")
		end
		local level = data.upgrades[key] or 0
		local cost = Formulas.UpgradeCost(key, level)
		if not cost then
			return Guard.Fail(player, def.Name .. " is maxed!")
		end
		if not DataService.TrySpend(player, cost) then
			return Guard.Fail(player, "Need $" .. Format.Number(cost))
		end
		DataService.Update(player, function(d)
			d.upgrades[key] = level + 1
		end)
		Guard.Sound(player, "Purchase")
		if key == "VisitorAppeal" then
			ItemService.RefreshAll(player)
		elseif key == "ShopLuck" or key == "BiggerRestock" then
			ShopService.SendStock(player)
		end
		return true, level + 1
	end)

	DataService.OnLoaded(function(player, data)
		player:SetAttribute("PadsOwned", data.padsOwned)
	end)
end

return ZooService
