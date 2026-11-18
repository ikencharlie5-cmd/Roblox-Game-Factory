--!strict
-- Shop: Featured (Starter Pack + VIP), Passes, Coins (dev products), Bait (coins).
-- Robux items only prompt (server grants). Monetization is cosmetic/convenience only.
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Market = require(script.Parent:WaitForChild("Market"))

local ShopWindow = {}

-- Display text per known key (Config may add Desc/Price which win).
local INFO: { [string]: { string } } = {
	VIP = { "VIP", "Gold name + tag, VIP decor set, +10% coins, +1 quest reroll" },
	ExtraIncubator = { "Extra Incubator", "+1 egg slot forever" },
	AutoFeeder = { "Auto-Feeder", "Food stations refill themselves" },
	CrystalGrotto = { "Crystal Grotto Decor", "Sparkly cave decor pack" },
	StarterPack = { "Starter Pack", "Theme decor + creature bow + 2,000 Coins (one time)" },
}

local BAIT = {
	{ key = "Berry", title = "Berry Bait", price = 10, text = "Trust +40" },
	{ key = "Honey", title = "Honey Bait", price = 50, text = "Trust +70" },
	{ key = "Starfruit", title = "Starfruit Bait", price = 250, text = "Trust +100, rare spawns x2 for 3 min" },
}

local win: any
local content: Frame
local choose: (string) -> ()
local tab = "Featured"
local lastSig = ""

local function card(parent: Instance, order: number, title: string, text: string, price: string, color: string, onBuy: () -> (), featured: boolean?)
	local c = Kit.Panel(parent, nil, { Size = UDim2.new(1, -12, 0, if featured then 130 else 96), LayoutOrder = order })
	Kit.Icon(c, title, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(if featured then 96 else 68, if featured then 96 else 68),
		ZIndex = 3,
	})
	local x = if featured then 120 else 92
	Kit.Label(c, title, { Position = UDim2.fromOffset(x, 8), Size = UDim2.new(1, -x - 240, 0, 36), TextSize = if featured then 32 else 26, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	Kit.Body(c, text, { Position = UDim2.fromOffset(x, 46), Size = UDim2.new(1, -x - 240, 1, -52), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 })
	Kit.Button(c, price, color, onBuy, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(210, 64),
		TextSize = 26,
		Shine = featured,
		ZIndex = 4,
	})
end

local function robux(def: { [string]: any }?): string
	local p = def and tonumber(def.Price)
	return if p then "R$ " .. p else "Buy"
end

local function render(force: boolean?)
	local sig = Kit.Sig({ tab, State.Get("inventory"), State.Get("passes"), State.Get("flags") })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	Kit.Clear(content)
	local scroll = Kit.Scroll(content)
	Kit.List(scroll, false, 10)
	Kit.Padding(scroll, 4)
	local order = 0
	local function add(...)
		order += 1
		card(scroll, order, ...)
	end
	if tab == "Featured" then
		if not Derived.Flag("starterBought") then
			local d = Market.ProductDef("StarterPack")
			add(INFO.StarterPack[1], INFO.StarterPack[2], robux(d), "Robux", function()
				Market.PromptProduct("StarterPack")
			end, true)
		end
		add(INFO.VIP[1], INFO.VIP[2], if Derived.HasPass("VIP") then "Owned" else robux(Market.PassDef("VIP")), "Robux", function()
			Market.PromptPass("VIP")
		end, true)
	elseif tab == "Passes" then
		local keys = {}
		for k in Derived.Config.GamePasses or {} do
			table.insert(keys, k)
		end
		table.sort(keys)
		for _, k in keys do
			local d = Market.PassDef(k) or {}
			local info = INFO[k] or { tostring(d.Name or k), tostring(d.Desc or "") }
			add(info[1], tostring(d.Desc or info[2]), if Derived.HasPass(k) then "Owned" else robux(d), "Robux", function()
				Market.PromptPass(k)
			end)
		end
	elseif tab == "Coins" then
		local keys = {}
		for k, d in Derived.Config.DevProducts or {} do
			if type(d) == "table" and (d.Coins or string.find(k, "Coin", 1, true)) then
				table.insert(keys, k)
			end
		end
		table.sort(keys, function(a, b)
			return (tonumber((Market.ProductDef(a) or {}).Coins) or 0) < (tonumber((Market.ProductDef(b) or {}).Coins) or 0)
		end)
		for _, k in keys do
			local d = Market.ProductDef(k) or {}
			add(tostring(d.Name or k), (tonumber(d.Coins) and (tostring(d.Coins) .. " Coins") or "Coins"), robux(d), "Robux", function()
				Market.PromptProduct(k)
			end)
		end
	else
		local cfg = Derived.List(Derived.Cfg("Bait"))
		local list = if #cfg > 0 then cfg else BAIT
		local inv = State.Tbl("inventory").bait or State.Tbl("bait")
		for _, b in list do
			local key = tostring(Derived.Field(b, "key", "id", "name"))
			local have = if type(inv) == "table" then tonumber(inv[key]) or 0 else 0
			local price = tonumber(Derived.Field(b, "price", "Price", "cost")) or 0
			local text = tostring(Derived.Field(b, "text", "desc") or "") .. string.format("  ·  You have %d", have)
			add(tostring(Derived.Field(b, "title", "Title") or key), text, price .. " Coins", "Sun", function()
				if State.Num("coins") < price then
					Kit.Sound("Error")
					Net.Toast("Not enough Coins", "error")
					return
				end
				local remote = if Net.Has("BuyBait") then "BuyBait" else "BuyUpgrade"
				if Net.Do(remote, nil, key) then
					Kit.Sound("Purchase")
				end
			end)
		end
	end
end

function ShopWindow.Mount()
	win = Windows.Create("Shop", "Shop", "Sun", "Shop", Vector2.new(860, 620))
	local tabs = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52) }, win.Body)
	content = Kit.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 1, -64) }, win.Body)
	choose = Kit.Tabs(tabs, { "Featured", "Passes", "Coins", "Bait" }, function(name)
		tab = name
		render(true)
	end, "Sun")
	win.OnOpen = function(arg: any)
		choose(if type(arg) == "string" then arg else "Featured")
	end
	State.OnChange(function(what)
		if what == "data" and Windows.IsOpen("Shop") then
			render()
		end
	end)
end

return ShopWindow
