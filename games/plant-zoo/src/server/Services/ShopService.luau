--!strict
-- Global seed restock every 300 s. Each slot's random draws come from Random.new(restockId)
-- so every server sees the same base stock; each player's luck then maps the same draw to
-- a rarity (luckier = higher). Instant Restock (Dev Product) = a personal reroll.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local AnnounceService = require(script.Parent:WaitForChild("AnnounceService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local ShopService = {}

-- Personal reroll seeds: { [player] = { restockId, seed } }
local personal: { [Player]: { restockId: number, seed: number } } = {}

local function restockId(): number
	return os.time() // Config.Shop.RestockSeconds
end

function ShopService.Luck(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 1
	end
	return Formulas.Luck(data, MonetizationService.HasPass(player, "SuperLuck"), os.time())
end

-- key used in data.stockBought + the seed for this player's current stock
local function stockKey(player: Player): (string, number)
	local rid = restockId()
	local p = personal[player]
	if p and p.restockId == rid then
		return "p" .. rid .. "_" .. p.seed, p.seed
	end
	return "r" .. rid, rid
end

function ShopService.GetStock(player: Player): { [string]: any }
	local data = DataService.Get(player)
	local key, seed = stockKey(player)
	local luck = ShopService.Luck(player)
	local rng = Random.new(seed)
	local slots = {}
	local count = if data then Formulas.SlotCount(data) else Config.Shop.BaseSlots
	local bought = if data then data.stockBought[key] or {} else {}
	for i = 1, Config.Shop.MaxSlots do
		local uR, uS, uQ = rng:NextNumber(), rng:NextNumber(), rng:NextNumber()
		if i <= count then
			local rarity = Formulas.RollRarity(uR, luck)
			local bucket = Config.Species.ByRarity[rarity]
			local s = bucket[math.floor(uS * #bucket) + 1]
			local range = (Config.Rarities :: any)[rarity].Qty
			local qty = range[1] + math.floor(uQ * (range[2] - range[1] + 1))
			local left = math.max(0, qty - (bought[tostring(i)] or 0))
			table.insert(slots, { slot = i, species = s.Name, rarity = rarity, cost = s.Cost, qty = qty, left = left })
		end
	end
	local rid = restockId()
	return { restockId = rid, nextRestockAt = (rid + 1) * Config.Shop.RestockSeconds, luck = luck, slots = slots }
end

function ShopService.SendStock(player: Player)
	Remotes.Event("StockChanged"):FireClient(player, ShopService.GetStock(player))
end

-- Random species with rarity >= minRarity (luck-weighted). Used by Hope Crate.
function ShopService.RollSpecies(player: Player, minRarity: string?): string
	local rarity = Formulas.RollRarity(math.random(), ShopService.Luck(player), minRarity)
	local bucket = Config.Species.ByRarity[rarity]
	return bucket[math.random(1, #bucket)].Name
end

function ShopService.RandomOfRarity(rarity: string): string
	local bucket = Config.Species.ByRarity[rarity]
	return bucket[math.random(1, #bucket)].Name
end

function ShopService.GiveSeed(player: Player, species: string, n: number?)
	DataService.Update(player, function(d)
		d.inventory.seeds[species] = (d.inventory.seeds[species] or 0) + (n or 1)
	end)
end

local function pruneBought(data: any, keep: string)
	for k in data.stockBought do
		if k ~= keep then
			data.stockBought[k] = nil
		end
	end
end

function ShopService.Init()
	Guard.Bind("GetStock", function(player)
		return true, ShopService.GetStock(player)
	end)

	-- BuySeed(slot: number) -> (ok, speciesName)
	Guard.Bind("BuySeed", function(player, _data, slot)
		if not Guard.IsInt(slot, 1, Config.Shop.MaxSlots) then
			return Guard.Fail(player, "Invalid slot")
		end
		local stock = ShopService.GetStock(player)
		local entry = stock.slots[slot]
		if not entry then
			return Guard.Fail(player, "Slot locked")
		end
		if entry.left <= 0 then
			return Guard.Fail(player, "Sold out! Restock soon")
		end
		if not DataService.TrySpend(player, entry.cost) then
			return Guard.Fail(player, "Not enough cash")
		end
		local key = stockKey(player)
		DataService.Update(player, function(d)
			pruneBought(d, key)
			local t = d.stockBought[key] or {}
			t[tostring(slot)] = (t[tostring(slot)] or 0) + 1
			d.stockBought[key] = t
			d.inventory.seeds[entry.species] = (d.inventory.seeds[entry.species] or 0) + 1
		end)
		Guard.Sound(
			player,
			if Formulas.RarityIndex(entry.rarity) >= Formulas.RarityIndex("Rare")
				then "Reveal" .. entry.rarity
				else "Purchase"
		)
		QuestService.Progress(player, "BuySeed", 1)
		if Formulas.RarityIndex(entry.rarity) >= Formulas.RarityIndex("Rare") then
			QuestService.Progress(player, "BuyRare", 1)
		end
		if (Config.AnnounceRarities :: any)[entry.rarity] then
			AnnounceService.Send(
				player.DisplayName .. " bought a " .. string.upper(entry.rarity) .. " " .. entry.species .. " seed!",
				entry.rarity,
				(Config.CrossServerRarities :: any)[entry.rarity] == true
			)
		end
		ShopService.SendStock(player)
		return true, entry.species
	end)

	MonetizationService.RegisterProduct("InstantRestock", function(player)
		personal[player] = { restockId = restockId(), seed = math.random(1, 2 ^ 30) }
		ShopService.SendStock(player)
		Guard.Sound(player, "Restock")
		return true
	end)

	DataService.OnLoaded(function(player)
		ShopService.SendStock(player)
	end)
	MonetizationService.OnPassesChanged(function(player)
		if DataService.Get(player) then
			ShopService.SendStock(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		personal[p] = nil
	end)
end

function ShopService.Start()
	local last = restockId()
	local state = Guard.State()
	while true do
		local rid = restockId()
		state:SetAttribute("RestockId", rid)
		state:SetAttribute("NextRestockAt", (rid + 1) * Config.Shop.RestockSeconds)
		if rid ~= last then
			last = rid
			for _, p in Players:GetPlayers() do
				if DataService.Get(p) then
					ShopService.SendStock(p)
					Guard.Sound(p, "Restock")
				end
			end
		end
		task.wait(1)
	end
end

return ShopService
