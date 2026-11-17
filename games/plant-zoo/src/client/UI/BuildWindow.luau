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

local function cardBase(order: number, title: string, sub: string, color: Color3?): Frame
	local c = Kit.Panel(list, Style.Color.Panel, { LayoutOrder = order })
	if color then
		(c:FindFirstChildOfClass("UIStroke") :: UIStroke).Color = color
	end
	Kit.Label(c, title, { Size = UDim2.new(1, -8, 0.24, 0), Position = UDim2.new(0, 4, 0.04, 0) })
	Kit.Label(c, sub, {
		Size = UDim2.new(1, -8, 0.28, 0),
		Position = UDim2.new(0, 4, 0.3, 0),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
	return c
end

local function bottomButton(c: Frame, text: string, color: Color3, fn: () -> ())
	Kit.Button(c, text, color, fn, { Size = UDim2.new(1, -12, 0.3, 0), Position = UDim2.new(0, 6, 0.64, 0) })
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
					(if def.Biome then info.Icon else "🪧") .. " " .. kind,
					if def.Biome then def.Biome .. " decor" else "Any pad: +5% income",
					if def.Biome then info.Color else nil
				)
				if unlocked then
					bottomButton(c, "$" .. Format.Number(def.Cost) .. " Place", Style.Color.Leaf, function()
						BuildMode.Start({ mode = "buydecor", ref = kind, label = "🪴 " .. kind .. " - tap cells to buy & place" })
					end)
				else
					bottomButton(c, "🔒 " .. def.Biome, Style.Color.Grey, function()
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
				local c = cardBase(pad, "Pad " .. pad .. ": pick a biome", "", info.Color)
				local row = Kit.Make("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0.62, 0),
					Position = UDim2.new(0, 4, 0.34, 0),
				}, c)
				Kit.Grid(row, UDim2.new(0.33, -4, 0.5, -4), 4)
				for i, name in Config.BiomeOrder do
					if biomes[name] then
						local bi = Style.BiomeInfo(name)
						Kit.Button(row, bi.Icon, bi.Color, function()
							pickingPad = nil
							Net.Do("SetPadBiome", "Pad " .. pad .. " is now " .. name .. "!", pad, name)
							lastSig = ""
							BuildWindow.Render()
						end, { LayoutOrder = i })
					end
				end
			else
				local c = cardBase(pad, string.format("Pad %d %s", pad, info.Icon), tostring(b), info.Color)
				bottomButton(c, "🔄 Biome", info.Color, function()
					pickingPad = pad
					lastSig = ""
					BuildWindow.Render()
				end)
				if filter.pad == pad then
					highlight(c)
				end
			end
		elseif pad == owned + 1 then
			local c = cardBase(pad, "🌿 Pad " .. pad, "Expand your zoo!", Style.Color.Leaf)
			bottomButton(c, "$" .. Format.Number(price), Style.Color.Leaf, function()
				if Net.Do("BuyPad", "🎉 Pad " .. pad .. " unlocked!") then
					Kit.Sound("Expand")
				end
			end)
			highlight(c)
		else
			local c = cardBase(pad, "🔒 Pad " .. pad, "$" .. Format.Number(price), Style.Color.Grey)
			c.BackgroundTransparency = 0.35
		end
	end
end

local function renderBiomes()
	local biomes = State.Tbl("biomes")
	for i, name in Config.BiomeOrder do
		local def = Config.Biomes[name] or { Cost = 0 }
		local info = Style.BiomeInfo(name)
		local c = cardBase(i, info.Icon .. " " .. name, if biomes[name] then "Unlocked forever ✅" else "Kept through Release", info.Color)
		if not biomes[name] then
			bottomButton(c, "$" .. Format.Number(def.Cost), Style.Color.Leaf, function()
				if Net.Do("UnlockBiome", "🎉 " .. name .. " unlocked!", name) then
					Kit.Sound("Expand")
				end
			end)
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
	local win = Windows.Create("Build", "🔨 Build", Style.Color.Sun)
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44) }, win.Body)
	local tabHolder = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.72, 0, 1, 0) }, top)
	choose = Kit.Tabs(tabHolder, { "Decor", "Exhibits", "Biomes" }, function(name)
		tab = name
		pickingPad = nil
		lastSig = ""
		BuildWindow.Render()
	end)
	Kit.Button(top, "✋ Edit", Style.Color.Sky, function()
		BuildMode.Start({ mode = "edit" })
	end, { Size = UDim2.new(0.26, 0, 1, 0), Position = UDim2.new(0.74, 0, 0, 0) })
	list = Kit.Scroll(win.Body, { Position = UDim2.new(0, 0, 0, 52), Size = UDim2.new(1, 0, 1, -52) })
	Kit.Grid(list, UDim2.new(0.24, -6, 0.48, -6), 8)
	Kit.Padding(list, 4)

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
