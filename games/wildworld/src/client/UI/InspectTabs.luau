--!strict
-- Inspect tab bodies: Overview, Genetics (readable allele chips), Family (3 generations),
-- Care (needs bars + "Fix it" quick-jumps). Every action only fires a remote.
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Genetics = require(script.Parent:WaitForChild("Genetics"))

local InspectTabs = {}

local opener: ((any) -> ())? = nil
function InspectTabs.SetOpener(fn: (any) -> ())
	opener = fn
end

-- Habitat pads in the player's plot: data.pads (preferred) or plot items whose id has "Pad".
function InspectTabs.Pads(): { { id: any, label: string } }
	local out = {}
	local pads = State.Tbl("pads")
	for k, p in pads do
		table.insert(out, { id = if type(p) == "table" then (p.id or k) else k, label = "Habitat " .. tostring(k) })
	end
	if #out == 0 then
		local items = State.Tbl("plot").items or {}
		for i, it in items do
			if type(it) == "table" and string.find(string.lower(tostring(it.id)), "pad", 1, true) then
				table.insert(out, { id = it.uid or it.key or i, label = "Habitat " .. #out + 1 })
			end
		end
	end
	return out
end

local function row(parent: Instance, h: number, order: number): Frame
	return Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), LayoutOrder = order }, parent)
end

local function overview(body: Frame, c: { [string]: any })
	local species = tostring(c.species)
	local def = Derived.Species(species)
	local rarity = Derived.Rarity(species)
	local banner = row(body, 50, 1)
	local face = Kit.Slab(banner, Style.RarityPalette(rarity), 99, 4)
	Kit.Title(face, string.upper(rarity) .. "  ·  " .. species .. "  ·  " .. Derived.Stage(c), Style.RarityDark[Style.NormRarity(rarity)], {
		Size = UDim2.new(1, -20, 1, -6),
		Position = UDim2.fromOffset(10, 3),
		TextSize = 24,
		ZIndex = 4,
	})
	local muts = Derived.Muts(c)
	local mrow = row(body, 40, 2)
	Kit.List(mrow, true, 8).VerticalAlignment = Enum.VerticalAlignment.Center
	if #muts == 0 then
		Kit.Body(mrow, "No mutations", { Size = UDim2.fromOffset(200, 30), TextSize = 18 })
	end
	for i, m in muts do
		Kit.MutationBadge(mrow, m, 36, { LayoutOrder = i * 2 })
		Kit.Label(mrow, m, { Size = UDim2.fromOffset(110, 30), TextSize = 20, LayoutOrder = i * 2 + 1 })
	end
	local origin = if type(c.parents) == "table" and next(c.parents) then "Bred in your park" else "Wild-caught"
	local info = string.format(
		"%s · Generation %d · %s\nPersonality: %s · Earns about %s coins/min",
		origin,
		tonumber(c.gen) or 1,
		if c.padId ~= nil then "In a habitat" else "In storage",
		tostring(c.personality or Derived.Field(def, "personality") or "?"),
		tostring(Derived.Field(def, "baseValue", "BaseValue") or "?")
	)
	Kit.Body(body, info, { Size = UDim2.new(1, 0, 0, 56), TextSize = 18, LayoutOrder = 3 })
	local actions = row(body, 64, 4)
	Kit.List(actions, true, 10)
	if c.padId == nil then
		local pads = InspectTabs.Pads()
		for i, p in pads do
			if i > 3 then
				break
			end
			Kit.Button(actions, "Put in " .. p.label, "Teal", function()
				Net.Do("AssignCreature", "Moved in!", c.uid, p.id)
			end, { Size = UDim2.fromOffset(170, 60), TextSize = 18, LayoutOrder = i })
		end
		if #pads == 0 then
			Kit.Body(actions, "Build a Habitat Pad to show this creature to visitors.", {
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = 18,
			})
		end
	else
		Kit.Button(actions, "Store", "Sky", function()
			Net.Do("AssignCreature", "Stored", c.uid, nil)
		end, { Size = UDim2.fromOffset(150, 60), LayoutOrder = 1 })
	end
	if Net.Has("SellCreature") then
		Kit.Button(actions, "Sell", "Red", function()
			Windows.Confirm("Sell creature?", "Sell " .. Derived.Name(c) .. "? This can't be undone.", "Sell", function()
				Net.Do("SellCreature", nil, c.uid)
			end)
		end, { Size = UDim2.fromOffset(120, 60), LayoutOrder = 9 })
	end
end

local function chip(parent: Instance, allele: string, order: number)
	local dom = Genetics.IsDominant(allele)
	local pal = if allele == "?" then Style.Pal.Stone else Style.Pal.Teal
	local f = Kit.Make("Frame", {
		BackgroundColor3 = if dom then pal.Bottom else Color3.new(1, 1, 1),
		BackgroundTransparency = if dom then 0 else 0.5,
		Size = UDim2.fromOffset(62, 34),
		LayoutOrder = order,
	}, parent)
	Kit.Corner(f, 10)
	Kit.Stroke(f, pal.Dark, 2.5)
	local mark = if allele == "?" then "?" elseif dom then allele .. " ^" else allele .. " v"
	Kit.Title(f, mark, pal.Dark, { TextSize = 20, TextColor3 = if dom then Style.Color.White else pal.Dark })
end

local function genetics(body: Frame, c: { [string]: any })
	local known = Genetics.Known(c)
	local pairs_ = if known then Genetics.Parse(c.genes) else nil
	for i, def in Genetics.Defs() do
		local r = row(body, 44, i)
		Kit.Label(r, def.label, { Size = UDim2.new(0.25, 0, 1, 0), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
		local chips = Kit.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.25, 0), Size = UDim2.new(0.35, 0, 1, 0) }, r)
		Kit.List(chips, true, 6).VerticalAlignment = Enum.VerticalAlignment.Center
		local pair = if pairs_ then pairs_[i] else nil
		chip(chips, if pair then pair[1] else "?", 1)
		chip(chips, if pair then pair[2] else "?", 2)
		Kit.Label(r, if pair then Genetics.Express(def, pair) else "Hidden", {
			Position = UDim2.fromScale(0.6, 0),
			Size = UDim2.new(0.4, 0, 1, 0),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end
	Kit.Body(body, "^ dominant (solid)   v recessive (outlined)   ? hidden", { Size = UDim2.new(1, 0, 0, 24), TextSize = 16, LayoutOrder = 20 })
	if not known then
		local cost = tonumber(Derived.Field(Derived.Cfg("GeneScanner") or {}, "Cost", "cost")) or 15
		Kit.Button(body, "Scan genes (" .. cost .. " RP)", "Purple", function()
			Net.Do("ScanGenes", "Genes revealed!", c.uid)
		end, { Size = UDim2.fromOffset(280, 60), LayoutOrder = 21, TextSize = 22 })
	end
end

local function family(body: Frame, c: { [string]: any })
	local function node(parent: Instance, uid: any, label: string, order: number)
		local owned = if uid ~= nil then Derived.Creature(uid) else nil
		local text = if owned then Derived.Name(owned) elseif uid ~= nil then "Not in your park" else label
		Kit.Button(parent, text, if owned then "Teal" else "Stone", function()
			if owned and opener then
				(opener :: (any) -> ())(owned.uid)
			end
		end, { Size = UDim2.fromOffset(150, 52), TextSize = 18, LayoutOrder = order })
	end
	local parents = if type(c.parents) == "table" then c.parents else {}
	local pa, pb = parents[1] or parents.a, parents[2] or parents.b
	if pa == nil and pb == nil then
		Kit.Body(body, "Wild-caught - this is where the family line starts.", { Size = UDim2.new(1, 0, 0, 40), TextSize = 20, LayoutOrder = 1 })
	else
		local gp = row(body, 60, 1)
		Kit.List(gp, true, 8, true)
		for i, p in { pa, pb } do
			local owned = Derived.Creature(p)
			local pp = if owned and type(owned.parents) == "table" then owned.parents else {}
			node(gp, pp[1], "Wild", i * 2 - 1)
			node(gp, pp[2], "Wild", i * 2)
		end
		local pr = row(body, 60, 2)
		Kit.List(pr, true, 40, true)
		node(pr, pa, "Parent", 1)
		node(pr, pb, "Parent", 2)
	end
	local me = row(body, 60, 3)
	Kit.List(me, true, 0, true)
	Kit.Button(me, Derived.Name(c), "Coral", nil, { Size = UDim2.fromOffset(200, 56), TextSize = 22 })
	Kit.Body(body, string.format("Generation %d", tonumber(c.gen) or 1), { Size = UDim2.new(1, 0, 0, 28), TextSize = 18, LayoutOrder = 4 })
end

local function care(body: Frame, c: { [string]: any })
	local needs: { { any } } = {
		{ "Hunger", tonumber(c.hunger) or 100, "Feed", function()
			Net.Do("FeedCreature", nil, c.uid)
		end },
		{ "Happiness", Derived.Happy(c), "Pet", function()
			Net.Do("PetCreature", nil, c.uid)
		end },
	}
	for _, k in { "habitat", "social", "enrichment" } do
		local v = tonumber(c[k])
		if v then
			table.insert(needs, { string.upper(string.sub(k, 1, 1)) .. string.sub(k, 2), v, "Fix it", function()
				Windows.Close()
				Net.Toast("Add items to the habitat to raise this", "info")
			end })
		end
	end
	for i, n in needs do
		local r = row(body, 50, i)
		Kit.Label(r, n[1], { Size = UDim2.new(0.28, 0, 1, 0), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
		local _, set = Kit.Progress(r, Kit.HappyPal(n[2]), { Position = UDim2.new(0.28, 0, 0.5, -9), Size = UDim2.new(0.4, 0, 0, 18) })
		set(n[2] / 100)
		Kit.Label(r, math.floor(n[2]) .. "%", { Position = UDim2.fromScale(0.69, 0), Size = UDim2.new(0.1, 0, 1, 0), TextSize = 20 })
		if n[2] < 40 or i <= 2 then
			Kit.Button(r, if n[2] < 40 then "Fix it" else n[3], if n[2] < 40 then "Coral" else "Leaf", n[4], {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0.2, 0, 0, 46),
				TextSize = 20,
			})
		end
	end
end

function InspectTabs.Render(tab: string, parent: Frame, c: { [string]: any })
	local body = Kit.Scroll(parent)
	Kit.List(body, false, 10)
	Kit.Padding(body, 4)
	if tab == "Overview" then
		overview(body, c)
	elseif tab == "Genetics" then
		genetics(body, c)
	elseif tab == "Family" then
		family(body, c)
	else
		care(body, c)
	end
end

return InspectTabs
