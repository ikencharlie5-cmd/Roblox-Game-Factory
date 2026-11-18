--!strict
-- Collection (guide §4): search, Sort pill, Filter pill, count, CreatureCard grid paged by 24.
-- Only re-renders when the creature list actually changes. Tap a card -> Inspect.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local CreatureCard = require(script.Parent:WaitForChild("CreatureCard"))

local CollectionWindow = {}

local SORTS = { "Rarity", "Newest", "Species", "Happiness", "Generation" }
local PAGE = 24

local win: any
local grid: ScrollingFrame
local countLabel: TextLabel
local search: TextBox
local sortBtn: TextButton
local filterBtn: TextButton
local sortIdx = 1
local filterIdx = 1 -- 1 = All, 2 = Has mutation, 3+ = species
local shownCount = PAGE
local lastSig = ""

local function filters(): { string }
	local f = { "All", "Mutated", "In park", "Stored" }
	for _, s in Derived.SpeciesList() do
		table.insert(f, tostring(s.name))
	end
	return f
end

local function sorted(): { { [string]: any } }
	local list = Derived.Creatures()
	local q = string.lower(search.Text)
	local f = filters()[filterIdx] or "All"
	local out = {}
	for _, c in list do
		local species = tostring(c.species or "")
		local ok = true
		if f == "Mutated" then
			ok = #Derived.Muts(c) > 0
		elseif f == "In park" then
			ok = c.padId ~= nil
		elseif f == "Stored" then
			ok = c.padId == nil
		elseif f ~= "All" then
			ok = species == f
		end
		if ok and q ~= "" then
			ok = string.find(string.lower(Derived.Name(c) .. " " .. species), q, 1, true) ~= nil
		end
		if ok then
			table.insert(out, c)
		end
	end
	local mode = SORTS[sortIdx]
	table.sort(out, function(a, b)
		if mode == "Rarity" then
			local ra = Style.RarityIndex(Derived.Rarity(a.species)) + #Derived.Muts(a) * 10
			local rb = Style.RarityIndex(Derived.Rarity(b.species)) + #Derived.Muts(b) * 10
			if ra ~= rb then
				return ra > rb
			end
		elseif mode == "Newest" then
			return (tonumber(a.born) or 0) > (tonumber(b.born) or 0)
		elseif mode == "Species" then
			if a.species ~= b.species then
				return tostring(a.species) < tostring(b.species)
			end
		elseif mode == "Happiness" then
			return Derived.Happy(a) > Derived.Happy(b)
		elseif mode == "Generation" then
			return (tonumber(a.gen) or 0) > (tonumber(b.gen) or 0)
		end
		return tostring(a.uid) < tostring(b.uid)
	end)
	return out
end

local function render(force: boolean?)
	if not Windows.IsOpen("Collection") then
		return
	end
	local list = sorted()
	local sig = Kit.Sig({ list, shownCount })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	local all = Derived.Creatures()
	local inPark = 0
	for _, c in all do
		if c.padId ~= nil then
			inPark += 1
		end
	end
	local slots = Derived.ParkSlots()
	countLabel.Text = string.format("%d creatures · %d / %d in park", #all, inPark, slots)
	Kit.Clear(grid)
	if #list == 0 then
		Kit.Body(grid, if #all == 0 then "No creatures yet - hatch your egg!" else "Nothing matches this filter.", {
			Size = UDim2.new(1, 0, 0, 60),
			TextSize = 24,
		})
		return
	end
	for i, c in list do
		if i > shownCount then
			Kit.Button(grid, "Show more", "Teal", function()
				shownCount += PAGE
				render()
			end, { Size = UDim2.fromOffset(150, 70), LayoutOrder = i })
			break
		end
		CreatureCard.New(grid, c, {
			LayoutOrder = i,
			OnClick = function()
				Windows.Open("Inspect", c.uid)
			end,
		})
	end
end

function CollectionWindow.Mount()
	win = Windows.Create("Collection", "Collection", "Teal", "Collection", Vector2.new(900, 640))
	local bar = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52) }, win.Body)
	Kit.List(bar, true, 10).VerticalAlignment = Enum.VerticalAlignment.Center
	local box = Kit.Panel(bar, nil, { Size = UDim2.fromOffset(240, 46), LayoutOrder = 1 })
	search = Kit.Make("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		PlaceholderText = "Search...",
		Text = "",
		Font = Style.FontBody,
		TextSize = 22,
		TextColor3 = Style.Color.Ink,
		PlaceholderColor3 = Style.Color.InkSoft,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 5,
	}, box)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		shownCount = PAGE
		render()
	end)
	sortBtn = Kit.Button(bar, "Sort: Rarity", "Sky", function()
		sortIdx = sortIdx % #SORTS + 1
		sortBtn.Text = "Sort: " .. SORTS[sortIdx]
		render()
	end, { Size = UDim2.fromOffset(190, 48), TextSize = 20, LayoutOrder = 2, Radius = 99, Lip = 4 })
	filterBtn = Kit.Button(bar, "Show: All", "Teal", function()
		local f = filters()
		filterIdx = filterIdx % #f + 1
		filterBtn.Text = "Show: " .. f[filterIdx]
		shownCount = PAGE
		render()
	end, { Size = UDim2.fromOffset(190, 48), TextSize = 20, LayoutOrder = 3, Radius = 99, Lip = 4 })
	countLabel = Kit.Body(bar, "", { Size = UDim2.new(1, -660, 1, 0), TextSize = 18, LayoutOrder = 4 })
	grid = Kit.Scroll(win.Body, { Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 1, -62) })
	Kit.Grid(grid, UDim2.fromOffset(150, 190), 12)
	Kit.Padding(grid, 8)
	win.OnOpen = function()
		shownCount = PAGE
		render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			render()
		end
	end)
end

return CollectionWindow
