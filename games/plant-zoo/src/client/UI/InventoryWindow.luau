--!strict
-- Bag: Seeds (plant), Creatures (place / sell / view), Items (decor, potions, tonics).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local BuildMode = require(script.Parent:WaitForChild("BuildMode"))

local InventoryWindow = {}

local list: ScrollingFrame
local tab = "Seeds"
local lastSig = ""
local openCard: ((any) -> ())? = nil

function InventoryWindow.SetCardOpener(fn: (any) -> ())
	openCard = fn
end

-- Card with a picture on top: a creature render (species given) or an icon.
local function card(title: string, rarity: string?, sub: string, order: number, view: any?): Frame
	local c = Kit.Card(list, rarity, { LayoutOrder = order })
	if type(view) == "table" then
		Kit.CreatureView(c, tostring(view.species), view.stage, {
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.new(1, -16, 0, 96),
			ZIndex = 2,
		})
	else
		Kit.Icon(c, tostring(view or "Decor"), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 14),
			Size = UDim2.fromOffset(72, 72),
			Depth = true,
			ZIndex = 2,
		})
	end
	Kit.Label(c, title, { Position = UDim2.fromOffset(6, 102), Size = UDim2.new(1, -12, 0, 28), TextSize = 22, ZIndex = 3 })
	Kit.Body(c, sub, { Position = UDim2.fromOffset(8, 128), Size = UDim2.new(1, -16, 0, 40), TextSize = 17, ZIndex = 3 })
	return c
end

local function actions(c: Frame, defs: { { text: string, color: any, fn: () -> () } })
	local row = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, if c:FindFirstChild("Band") then -34 else -8),
		Size = UDim2.new(1, -12, 0, 52),
		ZIndex = 4,
	}, c)
	Kit.List(row, true, 6, true)
	for i, d in defs do
		Kit.Button(row, d.text, d.color, d.fn, {
			Size = UDim2.new(1 / #defs, -4, 1, 0),
			LayoutOrder = i,
			TextSize = 22,
			Lip = 4,
		})
	end
end

local function empty(text: string)
	Kit.Body(list, text, { LayoutOrder = 1, TextSize = 24 })
end

local function renderSeeds()
	local seeds = State.Tbl("seeds", State.Tbl("inventory"))
	local names = {}
	for name, count in seeds do
		if type(count) == "number" and count > 0 then
			table.insert(names, name)
		end
	end
	table.sort(names, function(a, b)
		local sa, sb = Derived.Species(a), Derived.Species(b)
		local ra = if sa then Style.RarityIndex(sa.Rarity) else 0
		local rb = if sb then Style.RarityIndex(sb.Rarity) else 0
		return if ra == rb then a < b else ra > rb
	end)
	for i, name in names do
		local s = Derived.Species(name)
		local c = card(
			string.format("%s x%d", name, seeds[name]),
			if s then s.Rarity else nil,
			if s
				then string.format("%s · %s grow", s.Biome, Format.Time(s.Grow))
				else "",
			i,
			{ species = name, stage = "Grown" }
		)
		actions(c, {
			{
				text = "Plant",
				color = "Leaf",
				fn = function()
					BuildMode.Start({ mode = "seed", ref = name, label = "Plant " .. name .. " - tap a cell" })
				end,
			},
		})
	end
	if #names == 0 then
		empty("No seeds - visit the Seed Shop!")
	end
end

local function renderCreatures()
	local all = Derived.AllCreatures()
	table.sort(all, function(a, b)
		local sa, sb = Derived.Species(a.item.species), Derived.Species(b.item.species)
		return (if sa then sa.Income else 0) > (if sb then sb.Income else 0)
	end)
	for i, entry in all do
		local item = entry.item
		local s = Derived.Species(item.species)
		local stage = if entry.placed then Derived.Stage(item) else "Grown"
		local where = if entry.placed then string.format("Pad %s · %s", tostring(item.pad), stage) else "In bag"
		local c = card(
			Derived.DisplayName(item),
			if s then s.Rarity else nil,
			where,
			i,
			{ species = item.species, stage = if entry.placed then stage else "Grown" }
		)
		if entry.placed then
			actions(c, {
				{
					text = "View",
					color = "Sky",
					fn = function()
						if openCard then
							(openCard :: (any) -> ())(item.id)
						end
					end,
				},
			})
		else
			actions(c, {
				{
					text = "Place",
					color = "Leaf",
					fn = function()
						BuildMode.Start({ mode = "creature", ref = item.id, label = "Place " .. tostring(item.species) })
					end,
				},
				{
					text = "$" .. Format.Number(Derived.SellValue(item)),
					color = "Sun",
					fn = function()
						Windows.Confirm(
							"Sell " .. tostring(item.species) .. "?",
							"You get $" .. Format.Number(Derived.SellValue(item)),
							"Sell",
							function()
								Net.Do("SellCreature", nil, item.id)
							end
						)
					end,
				},
			})
		end
	end
	if #all == 0 then
		empty("No creatures yet - plant a seed!")
	end
end

local function renderItems()
	local order = 0
	local decor = State.Tbl("decor", State.Tbl("inventory"))
	for kind, count in decor do
		if type(count) == "number" and count > 0 then
			order += 1
			local c = card(string.format("%s x%d", kind, count), nil, "Decor from your bag", order, "Decor")
			actions(c, {
				{
					text = "Place",
					color = "Leaf",
					fn = function()
						BuildMode.Start({ mode = "decor", ref = kind, label = "Place " .. kind })
					end,
				},
			})
		end
	end
	local potions = State.Num("luck", State.Tbl("potions"))
	if potions > 0 then
		order += 1
		local c = card("Luck Potion x" .. potions, "Rare", "x2 luck for 15 min", order, "LuckPotion")
		actions(c, {
			{
				text = "Drink!",
				color = "Purple",
				fn = function()
					Net.Do("UseHopeItem", nil, "LuckPotion")
				end,
			},
		})
	end
	local tonics = State.Num("tonics")
	if tonics > 0 then
		order += 1
		card("Grow Tonic x" .. tonics, "Uncommon", "Tap a growing plant, then 'Tonic'", order, "GrowTonic")
	end
	if order == 0 then
		empty("No items yet. Decor bought without a spot lands here.")
	end
end

function InventoryWindow.Render(force: boolean?)
	if not Windows.IsOpen("Inventory") then
		return
	end
	local d = State.data
	local sig = tab .. Kit.Sig({ d.inventory, #State.Tbl("placed"), d.potions, d.tonics })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	Kit.Clear(list)
	if tab == "Seeds" then
		renderSeeds()
	elseif tab == "Creatures" then
		renderCreatures()
	else
		renderItems()
	end
end

function InventoryWindow.Mount()
	local win = Windows.Create("Inventory", "Bag", "Sky", "Inventory")
	local tabs = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 0, 58) }, win.Body)
	local choose = Kit.Tabs(tabs, { "Seeds", "Creatures", "Items" }, function(name)
		tab = name
		InventoryWindow.Render(true)
	end, "Sky")
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
	Kit.Grid(list, UDim2.fromOffset(172, 250), 12)
	Kit.Padding(list, 8)
	win.OnOpen = function(arg: any)
		choose(if type(arg) == "string" then arg else tab)
	end
	State.OnChange(function(what)
		if what == "data" then
			InventoryWindow.Render()
		end
	end)
end

return InventoryWindow
