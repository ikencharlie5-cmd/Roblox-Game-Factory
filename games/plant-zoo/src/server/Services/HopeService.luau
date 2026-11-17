--!strict
-- Hope Shop: BuyHopeItem (Hope Crate / Luck Potion / Grow Tonic) and UseHopeItem.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local GrowthService = require(script.Parent:WaitForChild("GrowthService"))
local AnnounceService = require(script.Parent:WaitForChild("AnnounceService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local HopeService = {}

-- BuyHopeItem(key: "HopeCrate"|"LuckPotion"|"GrowTonic") -> (ok, result)
--   HopeCrate result = species name of the seed won; others = new count owned.
local function buy(player: Player, _data: any, key: any): (boolean, any)
	local def = if Guard.IsString(key) then (Config.HopeShop :: any)[key] else nil
	if not def then
		return Guard.Fail(player, "Unknown item")
	end
	if not DataService.TrySpendHope(player, def.Cost) then
		return Guard.Fail(player, "Need " .. def.Cost .. " Hope")
	end
	if key == "HopeCrate" then
		local species = ShopService.RollSpecies(player, Config.Shop.HopeCrateMinRarity)
		local rarity = Config.Species.ByName[species].Rarity
		ShopService.GiveSeed(player, species, 1)
		Guard.Sound(player, "Reveal" .. rarity)
		Guard.Notify(player, "Hope Crate: " .. rarity .. " " .. species .. " seed!", "success")
		if (Config.AnnounceRarities :: any)[rarity] then
			AnnounceService.Send(
				player.DisplayName .. " opened a " .. string.upper(rarity) .. " " .. species .. " seed!",
				rarity,
				(Config.CrossServerRarities :: any)[rarity] == true
			)
		end
		return true, species
	elseif key == "LuckPotion" then
		local n = 0
		DataService.Update(player, function(d)
			d.potions.luck = (d.potions.luck or 0) + 1
			n = d.potions.luck
		end)
		Guard.Sound(player, "Purchase")
		return true, n
	else
		local n = 0
		DataService.Update(player, function(d)
			d.tonics += 1
			n = d.tonics
		end)
		Guard.Sound(player, "Purchase")
		return true, n
	end
end

-- UseHopeItem("LuckPotion") -> (ok, luckUntil)
-- UseHopeItem("GrowTonic", itemId) -> (ok, itemId)  (finishes one plant, Legendary or below)
local function use(player: Player, data: any, key: any, itemId: any): (boolean, any)
	if key == "LuckPotion" then
		if (data.potions.luck or 0) < 1 then
			return Guard.Fail(player, "No Luck Potions")
		end
		local now = os.time()
		DataService.Update(player, function(d)
			d.potions.luck -= 1
			d.potions.luckUntil = math.max(now, d.potions.luckUntil or 0) + Config.Luck.PotionSeconds
		end)
		player:SetAttribute("LuckUntil", data.potions.luckUntil)
		ShopService.SendStock(player)
		Guard.Sound(player, "Mutation")
		Guard.Notify(player, "Luck x" .. Config.Luck.PotionMult .. " for 15 min!", "success")
		return true, data.potions.luckUntil
	elseif key == "GrowTonic" then
		if data.tonics < 1 then
			return Guard.Fail(player, "No Grow Tonics")
		end
		if type(itemId) ~= "number" then
			return Guard.Fail(player, "Tap a growing plant")
		end
		local target: any = nil
		for _, p in data.placed do
			if p.id == itemId then
				target = p
			end
		end
		if not target or (target.growTotal or 0) <= 0 then
			return Guard.Fail(player, "That plant isn't growing")
		end
		local s = Config.Species.ByName[target.species]
		if s and Formulas.RarityIndex(s.Rarity) > Formulas.RarityIndex(Config.GrowTonicMaxRarity) then
			return Guard.Fail(player, "Too powerful for a Grow Tonic")
		end
		DataService.Update(player, function(d)
			d.tonics -= 1
		end)
		GrowthService.Finish(player, itemId, Config.GrowTonicMaxRarity)
		return true, itemId
	end
	return Guard.Fail(player, "Unknown item")
end

function HopeService.Init()
	Guard.Bind("BuyHopeItem", buy)
	Guard.Bind("UseHopeItem", use)
	DataService.OnLoaded(function(player, data)
		player:SetAttribute("LuckUntil", data.potions.luckUntil or 0)
	end)
end

function HopeService.Start()
	-- Keep a Luck attribute for the HUD (changes with potions expiring etc.)
	while true do
		for _, p in game:GetService("Players"):GetPlayers() do
			if DataService.Get(p) then
				p:SetAttribute("Luck", ShopService.Luck(p))
			end
		end
		task.wait(2)
	end
end

return HopeService
