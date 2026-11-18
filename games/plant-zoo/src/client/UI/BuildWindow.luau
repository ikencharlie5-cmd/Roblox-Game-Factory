--!strict
-- Build menu: Decor shop (buy + place), Exhibits (buy pads, set pad biome), Biomes (unlock),
-- and an Edit button (move/remove). Opened by Fix buttons with a filter: {tab, decor?, pad?, biome?}.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Net = require(script.Parent:WaitForChild("Net"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local BuildMode = require(script.Parent:WaitForChild("BuildMode"))

local BuildWindow = {}

local Config = Derived.Config
local list: ScrollingFrame
local tab = "Decor"
local filter: any = {}
local pickingPad: number? = nil
local lastSig = ""
local choose: (string) -> ()

local function highlight(c: Frame)
	local s = c:FindFirstChildOfClass("UIStroke") :: UIStroke
	s.Color = Style.Color.Sun
	s.Thickness = 4
	task.spawn(function()
		for _ = 1, 6 do
			Kit.Tween(s, 0.3, { Thickness = 7 })
			task.wait(0.3)
			Kit.Tween(s, 0.3, { Thickness = 3 })
			task.wait(0.3)
		end
	end)
end

-- Card: biome chip (or icon) on top, title, sub line. Stroke tinted by the biome colour.
local function cardBase(order: number, title: string, sub: string, color: Color3?, icon: string?): Frame
	local c = Kit.Card(list, nil, { LayoutOrder = order })
	if color then
		(c:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = Style.PaletteFor(color).Dark
	end
	local badge = {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(64, 64),
		ZIndex = 3,
	}
	if icon and string.sub(icon, 1, 6) == "biome:" then
		Kit.BiomeChip(c, string.sub(icon, 7), badge)
	elseif icon then
		Kit.Icon(c, icon, badge)
	else
		Kit.BiomeChip(c, title, badge)
	end
	Kit.Label(
		c,
		title,
		{ Position = UDim2.fromOffset(6, 80), Size = UDim2.new(1, -12, 0, 30), TextSize = 22, ZIndex = 3 }
	)
	Kit.Body(
		c,
		sub,
		{ Position = UDim2.fromOffset(8, 110), Size = UDim2.new(1, -16, 0, 44), TextSize = 17, ZIndex = 3 }
	)
	return c
end

local function bottomButton(c: Frame, text: string, color: any, fn: () -> (), icon: string?)
	Kit.Button(c, text, color, fn, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 54),
		Icon = icon,
		IconSize = 30,
		TextSize = 22,
		Lip = 4,
		ZIndex = 4,
	})
end

local function renderDecor()
	local biomes = State.Tbl("biomes")
	local order = 0
	local groups = table.clone(Config.BiomeOrder)
	table.insert(groups, "Any")
	for gi, biome in groups do
		for kind, def in Config.Decor do
			if (def.Biome or "Any") == biome then
				order += 1
				local wanted = filter.decor == kind
				local unlocked = def.Biome == nil or biomes[def.Biome] == true
				local info = Style.BiomeInfo(def.Biome)
				local c = cardBase(
					if wanted then 0 else gi * 100 + order,
					kind,
					if def.Biome then def.Biome .. " decor" else "Any pad: +5% income",
					if def.Biome then info.Color else nil,
					if def.Biome then nil else "Decor"
				)
				if def.Biome then
					Kit.BiomeChip(c, def.Biome, {
						Position = UDim2.fromOffset(8, 8),
						Size = UDim2.fromOffset(30, 30),
						ZIndex = 4,
					})
				end
				if unlocked then
					bottomButton(c, "$" .. Format.Number(def.Cost), "Leaf", function()
						BuildMode.Start({
							mode = "buydecor",
							ref = kind,
							label = kind .. " - tap a cell to buy & place",
						})
					end, "Cash")
				else
					bottomButton(c, "Locked", Style.Color.Grey, function()
						filter = { biome = def.Biome }
						choose("Biomes")
					end)
				end
				if wanted then
					highlight(c)
				end
			end
		end
	end
end

local function renderExhibits()
	local owned = math.max(1, State.Num("padsOwned"))
	local padBiome = State.Tbl("padBiome")
	local biomes = State.Tbl("biomes")
	for pad = 1, #Config.PadCosts do
		local price = Config.PadCosts[pad]
		if pad <= owned then
			local b = padBiome[pad] or "Meadow"
			local info = Style.BiomeInfo(b)
			if pickingPad == pad then
				local c = cardBase(pad, "Pad " .. pad, "", info.Color, "biome:" .. tostring(b))
				local row = Kit.Make("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -8),
					Size = UDim2.new(1, -12, 0, 104),
					ZIndex = 5,
				}, c)
				Kit.Grid(row, UDim2.fromOffset(48, 48), 6)
				for i, name in Config.BiomeOrder do
					if biomes[name] then
						local bi = Style.BiomeInfo(name)
						Kit.Button(row, bi.Code, bi.Color, function()
							pickingPad = nil
							Net.Do("SetPadBiome", "Pad " .. pad .. " is now " .. name .. "!", pad, name)
							lastSig = ""
							BuildWindow.Render()
						end, { LayoutOrder = i, TextSize = 20, Lip = 4, Radius = 12 })
					end
				end
			else
				local c = cardBase(pad, "Pad " .. pad, tostring(b), info.Color, "biome:" .. tostring(b))
				bottomButton(c, "Biome", info.Color, function()
					pickingPad = pad
					lastSig = ""
					BuildWindow.Render()
				end)
				if filter.pad == pad then
					highlight(c)
				end
			end
		elseif pad == owned + 1 then
			local c = cardBase(pad, "Pad " .. pad, "Expand your zoo!", Style.Color.Leaf, "Build")
			bottomButton(c, "$" .. Format.Number(price), "Leaf", function()
				Net.Do("BuyPad", nil, pad)
			end, "Cash")
			highlight(c)
		else
			local c = cardBase(pad, "Pad " .. pad, "Locked · $" .. Format.Number(price), Style.Color.Grey, "Locked")
			c.BackgroundTransparency = 0.35
		end
	end
end

local function renderBiomes()
	local biomes = State.Tbl("biomes")
	for i, name in Config.BiomeOrder do
		local def = Config.Biomes[name] or { Cost = 0 }
		local info = Style.BiomeInfo(name)
		local c = cardBase(i, name, if biomes[name] then "Unlocked forever!" else "Kept through Release", info.Color)
		if not biomes[name] then
			bottomButton(c, "$" .. Format.Number(def.Cost), "Leaf", function()
				Net.Do("UnlockBiome", nil, name)
			end, "Cash")
		end
		if filter.biome == name then
			highlight(c)
		end
	end
end

function BuildWindow.Render()
	if not Windows.IsOpen("Build") then
		return
	end
	local d = State.data
	local sig = tab .. Kit.Sig({ d.padsOwned, d.padBiome, d.biomes, pickingPad })
	if sig == lastSig then
		return
	end
	lastSig = sig
	Kit.Clear(list)
	if tab == "Decor" then
		renderDecor()
	elseif tab == "Exhibits" then
		renderExhibits()
	else
		renderBiomes()
	end
end

-- Fix flow: wanted biome on a pad. Unlocked -> offer to switch now; locked -> Biomes tab.
local function applyBiomeFix(pad: number, biome: string)
	if State.Tbl("biomes")[biome] then
		Windows.Confirm(
			"Make Pad " .. pad .. " " .. biome .. "?",
			"Creatures that need another biome will lose that check.",
			"Switch",
			function()
				Net.Do("SetPadBiome", "Pad " .. pad .. " is now " .. biome .. "!", pad, biome)
			end
		)
	else
		filter = { biome = biome }
		choose("Biomes")
	end
end

function BuildWindow.Mount()
	local win = Windows.Create("Build", "Build", "Wood", "Build")
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58) }, win.Body)
	local tabHolder = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0) }, top)
	choose = Kit.Tabs(tabHolder, { "Decor", "Exhibits", "Biomes" }, function(name)
		tab = name
		pickingPad = nil
		lastSig = ""
		BuildWindow.Render()
	end, "Wood")
	Kit.Button(top, "Edit", "Sky", function()
		BuildMode.Start({ mode = "edit" })
	end, { Size = UDim2.new(0.18, 0, 0, 56), Position = UDim2.new(0.61, 0, 0, 0), TextSize = 24, Lip = 4 })
	-- Upgrades lives here (the left bar is capped at 8 buttons).
	Kit.Button(top, "Upgrades", "Leaf", function()
		Windows.Open("Upgrades")
	end, {
		Size = UDim2.new(0.2, 0, 0, 56),
		Position = UDim2.new(0.8, 0, 0, 0),
		TextSize = 22,
		Lip = 4,
		Icon = "Upgrades",
		IconSize = 32,
	})
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
	Kit.Grid(list, UDim2.fromOffset(172, 230), 12)
	Kit.Padding(list, 8)

	win.OnOpen = function(arg: any)
		filter = if type(arg) == "table" then arg else {}
		choose(filter.tab or "Decor")
		if filter.tab == "Exhibits" and filter.pad and filter.biome then
			applyBiomeFix(filter.pad, filter.biome)
		end
	end
	State.OnChange(function(what)
		if what == "data" then
			BuildWindow.Render()
		end
	end)
end

return BuildWindow
