--!strict
-- Seed Shop (global restock, rarity frames, qty left, countdown, Instant Restock) + Hope Shop tab.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Market = require(script.Parent:WaitForChild("Market"))

local ShopWindow = {}

local win: Windows.Win
local list: ScrollingFrame
local timerLabel: TextLabel
local tab = "Seeds"
local choose: (string) -> ()

local HOPE_ITEMS = {
	{ Key = "HopeCrate", Desc = "Random Rare+ seed!" },
	{ Key = "LuckPotion", Desc = "x2 luck for 15 min" },
	{ Key = "GrowTonic", Desc = "Instantly grow 1 plant (up to Legendary)" },
}

local CELL = UDim2.fromOffset(172, 250)

local function priceButton(card: Frame, text: string, color: any, icon: string?, fn: () -> ())
	Kit.Button(card, text, color, fn, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -36),
		Size = UDim2.new(1, -16, 0, 54),
		Icon = icon,
		IconSize = 30,
		TextSize = 24,
		Lip = 4,
		ZIndex = 4,
	})
end

local function seedCard(entry: any, order: number)
	local rarity = Style.NormRarity(entry.rarity)
	local s = Derived.Species(entry.species)
	local card = Kit.Card(list, rarity, { LayoutOrder = order })
	Kit.CreatureView(card, tostring(entry.species), "Grown", {
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 0, 92),
		ZIndex = 2,
	})
	if s then
		Kit.BiomeChip(card, s.Biome, { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(32, 32), ZIndex = 3 })
	end
	Kit.Label(card, tostring(entry.species), {
		Position = UDim2.fromOffset(6, 98),
		Size = UDim2.new(1, -12, 0, 28),
		TextSize = 22,
		ZIndex = 3,
	})
	local income = if s then s.Income else 0
	Kit.Body(card, string.format("+$%s/s · %d left", Format.Number(income), entry.left or 0), {
		Position = UDim2.fromOffset(6, 124),
		Size = UDim2.new(1, -12, 0, 24),
		TextSize = 18,
		ZIndex = 3,
	})
	local soldOut = (entry.left or 0) <= 0
	priceButton(
		card,
		if soldOut then "Sold out" else "$" .. Format.Number(entry.cost or 0),
		if soldOut then Style.Color.Grey else "Leaf",
		if soldOut then nil else "Cash",
		function()
			if soldOut then
				Kit.Sound("Error")
				return
			end
			Net.Do("BuySeed", nil, entry.slot) -- server plays Purchase / Reveal<Rarity>
		end
	)
end

local function infoCard(order: number, icon: string, title: string, desc: string): Frame
	local card = Kit.Card(list, nil, { LayoutOrder = order })
	Kit.Icon(card, icon, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(70, 70),
		Depth = true,
		ZIndex = 3,
	})
	Kit.Label(
		card,
		title,
		{ Position = UDim2.fromOffset(6, 84), Size = UDim2.new(1, -12, 0, 28), TextSize = 22, ZIndex = 3 }
	)
	Kit.Body(
		card,
		desc,
		{ Position = UDim2.fromOffset(8, 112), Size = UDim2.new(1, -16, 0, 50), TextSize = 18, ZIndex = 3 }
	)
	return card
end

local function hopeCard(item: any, order: number)
	local def = Derived.Config.HopeShop[item.Key] or { Name = item.Key, Cost = 0 }
	local card = infoCard(order, item.Key, def.Name, item.Desc)
	priceButton(card, Format.Number(def.Cost), "Sun", "Hope", function()
		-- Server plays the sound and toasts the crate result; we only add a hint for potions/tonics.
		local ok = Net.Do("BuyHopeItem", nil, item.Key)
		if ok and item.Key ~= "HopeCrate" then
			Net.Toast("Got " .. def.Name .. "! It's in your Bag > Items", "success")
		end
	end)
end

function ShopWindow.Render()
	if not Windows.IsOpen("Shop") then
		return
	end
	Kit.Clear(list)
	if tab == "Seeds" then
		local stock = State.stock
		local slots = if type(stock) == "table" and type(stock.slots) == "table" then stock.slots else {}
		for i, entry in slots do
			seedCard(entry, i)
		end
		if #slots == 0 then
			Kit.Body(list, "Loading stock...", { LayoutOrder = 1 })
		end
		local maxSlots = Derived.Config.Shop.MaxSlots
		for i = #slots + 1, maxSlots do
			local locked = infoCard(100 + i, "Locked", "Locked", "More slots: Bigger Restock or Release")
			locked.BackgroundTransparency = 0.35
		end
	else
		for i, item in HOPE_ITEMS do
			hopeCard(item, i)
		end
		local more = infoCard(10, "Hope", "Need more Hope?", "Hope packs in the Store")
		priceButton(more, "Get Hope", "Robux", "Store", function()
			Windows.Open("Store")
		end)
	end
end

function ShopWindow.RefreshStock()
	local ok, stock = Net.Call("GetStock")
	if ok and type(stock) == "table" then
		State.stock = stock
		State.Fire("stock")
	end
end

function ShopWindow.Mount()
	win = Windows.Create("Shop", "Seed Shop", "Leaf", "Shop")
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58) }, win.Body)
	local tabHolder = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.44, 0, 1, 0) }, top)
	choose = Kit.Tabs(tabHolder, { "Seeds", "Hope Shop" }, function(name)
		tab = name
		win.Title.Text = if name == "Seeds" then "Seed Shop" else "Hope Shop"
		ShopWindow.Render()
	end, "Leaf")
	timerLabel = Kit.Label(top, "", {
		Size = UDim2.new(0.26, 0, 0, 40),
		Position = UDim2.new(0.45, 0, 0, 8),
		TextSize = 22,
		TextColor3 = Style.Pal.Leaf.Dark,
	})
	Kit.Button(top, "Restock R$29", "Robux", function()
		Market.PromptProduct("InstantRestock")
	end, { Size = UDim2.new(0.28, 0, 0, 56), Position = UDim2.new(0.72, 0, 0, 0), TextSize = 22, Lip = 4 })

	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
	Kit.Grid(list, CELL, 12)
	Kit.Padding(list, 8)

	win.OnOpen = function(arg: any)
		choose(if arg == "Hope" then "Hope Shop" else "Seeds")
		ShopWindow.RefreshStock()
	end
	State.OnChange(function(what)
		if what == "stock" then
			ShopWindow.Render()
		end
	end)
	-- Countdown + auto-refresh when the global restock ticks over.
	task.spawn(function()
		local lastId = -1
		while true do
			local period = Derived.Config.Shop.RestockSeconds
			local now = State.Now()
			local id = math.floor(now / period)
			timerLabel.Text = "New seeds in " .. Format.Time((id + 1) * period - now)
			if id ~= lastId then
				if lastId ~= -1 or State.stock == nil then
					task.delay(1, ShopWindow.RefreshStock)
				end
				lastId = id
			end
			task.wait(0.5)
		end
	end)
end

return ShopWindow
