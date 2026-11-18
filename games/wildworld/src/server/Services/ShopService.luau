--!strict
-- Shop stall: bait + 1 rare decor slot, restocks every 5 min (same stock for everyone, seeded by
-- the restock id; each player has their own quantity left, saved so rejoining can't refill it).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local ShopService = {}

local function restockId(): number
	return os.time() // Config.Shop.RestockSeconds
end

-- Slots for a restock: { {slot, kind, ref, name, price, stock} }
local function stockFor(id: number): { any }
	local rng = Random.new(id)
	local rares = {}
	for _, def in Items.List() do
		if def.ShopRare then
			table.insert(rares, def)
		end
	end
	local out = {}
	for i, s in Config.Shop.Slots do
		if s.Chance and rng:NextNumber() > s.Chance then
			continue
		end
		if s.Kind == "bait" then
			local bait = (Config.Capture.Bait :: any)[s.Ref]
			table.insert(out, { slot = i, kind = "bait", ref = s.Ref, name = s.Ref .. " Bait", price = bait.Coins, stock = s.Stock })
		elseif s.Kind == "decor" and #rares > 0 then
			local def = rares[rng:NextInteger(1, #rares)]
			table.insert(out, { slot = i, kind = "decor", ref = def.Id, name = def.Name, price = Config.Shop.RareDecorPrice, stock = s.Stock })
		end
	end
	return out
end

local function view(data: any): any
	local id = restockId()
	local bought = if data.shop and data.shop.id == id then data.shop.bought else {}
	local slots = {}
	for _, s in stockFor(id) do
		local row = table.clone(s)
		row.left = math.max(0, s.stock - (bought[tostring(s.slot)] or 0))
		table.insert(slots, row)
	end
	return { restockId = id, nextRestockAt = (id + 1) * Config.Shop.RestockSeconds, slots = slots }
end

local function buy(player: Player, data: any, slot: any)
	if not Guard.IsInt(slot, 1, #Config.Shop.Slots) then
		return false, "Bad request"
	end
	local shop = view(data)
	local row: any = nil
	for _, s in shop.slots do
		if s.slot == slot then
			row = s
		end
	end
	if not row then
		return Guard.Fail(player, "Not in stock right now")
	end
	if row.left <= 0 then
		return Guard.Fail(player, "Sold out - restock soon!")
	end
	if not DataService.TrySpend(player, row.price) then
		return Guard.Fail(player, "Not enough coins")
	end
	DataService.Update(player, function(d)
		if not d.shop or d.shop.id ~= shop.restockId then
			d.shop = { id = shop.restockId, bought = {} }
		end
		local k = tostring(slot)
		d.shop.bought[k] = (d.shop.bought[k] or 0) + 1
		if row.kind == "bait" then
			d.bait[row.ref] = (d.bait[row.ref] or 0) + 1
		else
			d.decorInv[row.ref] = (d.decorInv[row.ref] or 0) + 1
		end
	end)
	Guard.Sound(player, "Purchase")
	local newView = view(data)
	Remotes.Event("ShopChanged"):FireClient(player, newView)
	return true, newView
end

function ShopService.Init()
	Guard.Bind("GetShop", function(_player, data)
		return true, view(data)
	end)
	Guard.Bind("BuyShop", buy)
	-- Hub Field Shop stall: refresh stock and open the Shop window
	Guard.WirePrompt("ShopStall", function(player, data)
		Remotes.Event("ShopChanged"):FireClient(player, view(data))
		Guard.Reveal(player, "OpenWindow", { name = "Shop" })
	end)
	PlotService.OnAssigned(function(player, _plot, data)
		Remotes.Event("ShopChanged"):FireClient(player, view(data))
	end, 90)
end

function ShopService.Start()
	local last = restockId()
	while true do
		task.wait(1)
		local id = restockId()
		if id ~= last then
			last = id
			Guard.State():SetAttribute("ShopRestockAt", (id + 1) * Config.Shop.RestockSeconds)
			for _, p in Players:GetPlayers() do
				local d = DataService.Get(p)
				if d then
					Remotes.Event("ShopChanged"):FireClient(p, view(d))
					Guard.Sound(p, "Restock")
				end
			end
		end
	end
end

return ShopService
