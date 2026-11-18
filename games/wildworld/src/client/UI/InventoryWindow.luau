--!strict
-- Inventory: bait, stored build items and eggs-in-incubators at a glance, with jumps to the
-- Shop (buy bait), Build (place stored items) and Breeding (eggs). Read-only display.
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local InventoryWindow = {}

local win: any
local list: ScrollingFrame
local lastSig = ""
local buildFn: (() -> ())? = nil

function InventoryWindow.SetBuild(fn: () -> ())
	buildFn = fn
end

local function section(title: string, order: number, pal: any, entries: { { any } }, action: string?, onAction: (() -> ())?)
	local head = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 50), LayoutOrder = order }, list)
	Kit.Label(head, title, { Size = UDim2.new(0.6, 0, 1, 0), TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left })
	if action and onAction then
		Kit.Button(head, action, pal, onAction, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(200, 48),
			TextSize = 20,
		})
	end
	local grid = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order + 1,
	}, list)
	Kit.Grid(grid, UDim2.fromOffset(150, 110), 10).HorizontalAlignment = Enum.HorizontalAlignment.Left
	if #entries == 0 then
		Kit.Body(grid, "None yet", { TextSize = 18 })
	end
	for i, e in entries do
		local c = Kit.Card(grid, nil, { LayoutOrder = i })
		Kit.Icon(c, tostring(e[1]), { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(48, 48), ZIndex = 3 })
		Kit.Label(c, tostring(e[1]), { Position = UDim2.fromOffset(4, 56), Size = UDim2.new(1, -8, 0, 22), TextSize = 18, ZIndex = 3 })
		Kit.Body(c, "x" .. tostring(e[2]), { Position = UDim2.fromOffset(4, 80), Size = UDim2.new(1, -8, 0, 22), TextSize = 18, ZIndex = 3 })
	end
end

local function counts(t: any): { { any } }
	local out = {}
	if type(t) == "table" then
		for k, v in t do
			local n = tonumber(v)
			if n and n > 0 then
				table.insert(out, { k, n })
			end
		end
	end
	table.sort(out, function(a, b)
		return tostring(a[1]) < tostring(b[1])
	end)
	return out
end

local function render()
	if not Windows.IsOpen("Inventory") then
		return
	end
	local inv = State.Tbl("inventory")
	local sig = Kit.Sig({ inv, State.Get("bait"), State.Get("eggs") })
	if sig == lastSig then
		return
	end
	lastSig = sig
	Kit.Clear(list)
	section("Bait", 1, "Sun", counts(inv.bait or State.Get("bait")), "Buy bait", function()
		Windows.Open("Shop", "Bait")
	end)
	section("Stored items", 10, "Wood", counts(inv.items or inv.decor), "Place items", function()
		Windows.Close()
		if buildFn then
			(buildFn :: () -> ())()
		end
	end)
	local eggs = {}
	for _, e in Derived.Eggs() do
		local sp = tostring(Derived.Field(e, "species") or "Egg")
		local found = false
		for _, row in eggs do
			if row[1] == sp then
				row[2] += 1
				found = true
			end
		end
		if not found then
			table.insert(eggs, { sp, 1 })
		end
	end
	section("Eggs", 20, "Coral", eggs, "Open nests", function()
		Windows.Open("Breed")
	end)
end

function InventoryWindow.Mount()
	win = Windows.Create("Inventory", "Inventory", "Sky", "Inventory", Vector2.new(820, 600))
	list = Kit.Scroll(win.Body)
	Kit.List(list, false, 8)
	Kit.Padding(list, 4)
	win.OnOpen = function()
		lastSig = ""
		render()
	end
	State.OnChange(function(what)
		if what == "data" then
			render()
		end
	end)
end

return InventoryWindow
