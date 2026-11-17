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
	{ Key = "HopeCrate", Icon = "📦", Desc = "Random Rare+ seed!" },
	{ Key = "LuckPotion", Icon = "🧪", Desc = "x2 luck for 15 min" },
	{ Key = "GrowTonic", Icon = "💧", Desc = "Instantly grow 1 plant (up to Legendary)" },
}

local function seedCard(entry: any, order: number)
	local rarity = Style.NormRarity(entry.rarity)
	local color = Style.RarityColor(rarity)
	local s = Derived.Species(entry.species)
	local card = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = order })
	local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = color
	stroke.Thickness = 3
	local band =
		Kit.Make("Frame", { BackgroundColor3 = color, Size = UDim2.fromScale(1, 0.2), BorderSizePixel = 0 }, card)
	Kit.Corner(band, 10)
	Kit.Label(band, rarity, { TextColor3 = Style.Color.White, Size = UDim2.fromScale(1, 0.9) })
	local biome = if s then Style.BiomeInfo(s.Biome).Icon else ""
	Kit.Label(card, biome .. " " .. entry.species, {
		Size = UDim2.new(1, -8, 0.2, 0),
		Position = UDim2.new(0, 4, 0.22, 0),
	})
	local income = if s then s.Income else 0
	Kit.Label(card, string.format("+$%s/s  ·  %d left", Format.Number(income), entry.left or 0), {
		Size = UDim2.new(1, -8, 0.15, 0),
		Position = UDim2.new(0, 4, 0.43, 0),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	local soldOut = (entry.left or 0) <= 0
	Kit.Button(
		card,
		if soldOut then "Sold out" else "$" .. Format.Number(entry.cost or 0),
		if soldOut then Style.Color.Grey else Style.Color.Leaf,
		function()
			if soldOut then
				Kit.Sound("Error")
				return
			end
			Net.Do("BuySeed", nil, entry.slot) -- server plays Purchase / Reveal<Rarity>
		end,
		{ Size = UDim2.new(1, -12, 0.3, 0), Position = UDim2.new(0, 6, 0.64, 0) }
	)
end

local function hopeCard(item: any, order: number)
	local def = Derived.Config.HopeShop[item.Key] or { Name = item.Key, Cost = 0 }
	local card = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = order })
	Kit.Label(
		card,
		item.Icon .. " " .. def.Name,
		{ Size = UDim2.new(1, -8, 0.24, 0), Position = UDim2.new(0, 4, 0.04, 0) }
	)
	Kit.Label(card, item.Desc, {
		Size = UDim2.new(1, -8, 0.3, 0),
		Position = UDim2.new(0, 4, 0.3, 0),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	Kit.Button(card, "🌟 " .. Format.Number(def.Cost), Style.Color.Sun, function()
		-- Server plays the sound and toasts the crate result; we only add a hint for potions/tonics.
		local ok = Net.Do("BuyHopeItem", nil, item.Key)
		if ok and item.Key ~= "HopeCrate" then
			Net.Toast("Got " .. def.Name .. "! It's in your Bag > Items", "success")
		end
	end, { Size = UDim2.new(1, -12, 0.3, 0), Position = UDim2.new(0, 6, 0.64, 0) })
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
			Kit.Label(list, "Loading stock...", { LayoutOrder = 1 })
		end
		local maxSlots = Derived.Config.Shop.MaxSlots
		for i = #slots + 1, maxSlots do
			local locked = Kit.Panel(list, Style.Color.Card, { LayoutOrder = 100 + i, BackgroundTransparency = 0.3 })
			Kit.Label(locked, "🔒\nMore slots:\nBigger Restock\nor Release", {
				Font = Style.FontBody,
				TextColor3 = Style.Color.InkSoft,
				Size = UDim2.fromScale(0.9, 0.9),
				Position = UDim2.fromScale(0.05, 0.05),
			})
		end
	else
		for i, item in HOPE_ITEMS do
			hopeCard(item, i)
		end
		local more = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = 10 })
		Kit.Label(more, "Need more 🌟?", { Size = UDim2.new(1, -8, 0.4, 0), Position = UDim2.new(0, 4, 0.08, 0) })
		Kit.Button(more, "💎 Get Hope", Style.Color.Robux, function()
			Windows.Open("Store")
		end, { Size = UDim2.new(1, -12, 0.3, 0), Position = UDim2.new(0, 6, 0.64, 0) })
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
	win = Windows.Create("Shop", "🛒 Seed Shop", Style.Color.Leaf)
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, win.Body)
	local tabHolder = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.42, 0, 1, 0) }, top)
	choose = Kit.Tabs(tabHolder, { "Seeds", "Hope Shop" }, function(name)
		tab = name
		win.Title.Text = if name == "Seeds" then "🛒 Seed Shop" else "🌟 Hope Shop"
		ShopWindow.Render()
	end)
	timerLabel = Kit.Label(top, "", {
		Size = UDim2.new(0.3, 0, 0.8, 0),
		Position = UDim2.new(0.43, 0, 0.1, 0),
		TextColor3 = Style.Color.LeafDark,
	})
	Kit.Button(top, "⚡ Restock Now (R$29)", Style.Color.Robux, function()
		Market.PromptProduct("InstantRestock")
	end, { Size = UDim2.new(0.26, 0, 1, 0), Position = UDim2.new(0.74, 0, 0, 0) })

	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52) })
	Kit.Grid(list, UDim2.new(0.24, -6, 0.48, -6), 8)
	Kit.Padding(list, 4)

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
			timerLabel.Text = "⏱ New seeds in " .. Format.Time((id + 1) * period - now)
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
