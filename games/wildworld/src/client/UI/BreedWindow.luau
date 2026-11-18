--!strict
-- Breeding Center (guide §6): Parent A | possible offspring (% per gene, ranges, mutation tiers)
-- | Parent B, requirement ticks, cost + time, a big Breed button (disabled until all ticks are
-- green) and the incubator nest row. The picker only offers compatible creatures. Server rolls.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Genetics = require(script.Parent:WaitForChild("Genetics"))
local CreatureCard = require(script.Parent:WaitForChild("CreatureCard"))
local Nests = require(script.Parent:WaitForChild("Nests"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local BreedWindow = {}

local win: any
local slotA: Frame
local slotB: Frame
local odds: ScrollingFrame
local reqs: Frame
local costLabel: TextLabel
local breedBtn: TextButton
local picker: Frame
local pickGrid: ScrollingFrame
local pickA: any = nil
local pickB: any = nil
local lastSig = ""

local function cooldownLeft(c: { [string]: any }): number
	local t = tonumber(Derived.Field(c, "breedReadyAt", "cooldownUntil", "breedCooldown"))
	return if t then math.max(0, t - State.Now()) else 0
end

-- Why can't c be a parent next to `other`? nil = fine.
local function problem(c: { [string]: any }, other: { [string]: any }?): string?
	if Derived.Stage(c) ~= "Adult" then
		return "Not adult yet"
	end
	if Derived.Happy(c) < Derived.BreedMinHappy() then
		return "Too unhappy"
	end
	if cooldownLeft(c) > 0 then
		return "Resting " .. Format.Time(cooldownLeft(c))
	end
	if other and (other.species ~= c.species or other.uid == c.uid) then
		return if other.uid == c.uid then "Already picked" else "Other species"
	end
	return nil
end

local function slot(parent: Instance, x: number, anchor: number): Frame
	return Kit.Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(anchor, 0),
		Position = UDim2.fromScale(x, 0),
		Size = UDim2.new(0.27, 0, 0, 260),
	}, parent)
end

local function fillSlot(f: Frame, uid: any, other: any, onTap: () -> ())
	Kit.Clear(f)
	local c = if uid ~= nil then Derived.Creature(uid) else nil
	if c then
		CreatureCard.New(f, c, { Size = UDim2.new(1, 0, 0, 220), OnClick = onTap })
		local pairs_ = if Genetics.Known(c) then Genetics.Parse(c.genes) else nil
		Kit.Body(f, if pairs_ then string.gsub(tostring(c.genes), "|", " ") else "Genes hidden", {
			Position = UDim2.fromOffset(0, 228),
			Size = UDim2.new(1, 0, 0, 28),
			TextSize = 18,
		})
	else
		Kit.Button(f, if other ~= nil then "Choose a mate" else "Tap to choose", "Stone", onTap, {
			Size = UDim2.new(1, 0, 0, 220),
			TextSize = 22,
		})
	end
end

local function renderOdds(a: { [string]: any }?, b: { [string]: any }?)
	Kit.Clear(odds)
	if not (a and b) then
		Kit.Body(odds, "Pick two adults of the same species to see what their baby could look like.", {
			Size = UDim2.new(1, 0, 0, 80),
			TextSize = 20,
		})
		return
	end
	local ga = if Genetics.Known(a) then Genetics.Parse(a.genes) else nil
	local gb = if Genetics.Known(b) then Genetics.Parse(b.genes) else nil
	for i, def in Genetics.Defs() do
		local text: string
		if ga and gb and ga[i] and gb[i] then
			local parts = {}
			for _, o in Genetics.Odds(def, ga[i], gb[i]) do
				table.insert(parts, string.format("%s %d%%", o[1], o[2]))
			end
			text = "<b>" .. def.label .. ":</b> " .. table.concat(parts, " · ")
		else
			text = "<b>" .. def.label .. ":</b> ? (scan genes to see)"
		end
		Kit.Body(odds, text, { Size = UDim2.new(1, 0, 0, 40), TextSize = 17, LayoutOrder = i })
	end
	local heir = #Derived.Muts(a) + #Derived.Muts(b)
	local mutText = if heir > 0
		then "<b>Mutations:</b> Heirloom boost! A parent's mutation is much more likely."
		else "<b>Mutations:</b> * Golden / Albino possible   ** Crystal is rare"
	Kit.Body(odds, mutText, { Size = UDim2.new(1, 0, 0, 44), TextSize = 17, LayoutOrder = 20 })
	Kit.Body(odds, "Results are random. Odds shown are estimates.", {
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 14,
		LayoutOrder = 21,
	})
end

local function render(force: boolean?)
	if not Windows.IsOpen("Breed") then
		return
	end
	local a = if pickA ~= nil then Derived.Creature(pickA) else nil
	local b = if pickB ~= nil then Derived.Creature(pickB) else nil
	if pickA ~= nil and not a then
		pickA = nil
	end
	if pickB ~= nil and not b then
		pickB = nil
	end
	local sig = Kit.Sig({ a, b, Derived.Eggs(), State.Num("coins") })
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	fillSlot(slotA, pickA, pickB, function()
		BreedWindow.Pick("A")
	end)
	fillSlot(slotB, pickB, pickA, function()
		BreedWindow.Pick("B")
	end)
	renderOdds(a, b)
	-- Requirements
	Kit.Clear(reqs)
	local cost = if a then Derived.BreedCost(tostring(a.species)) else 0
	local nestFree = Nests.FreeSlots() > 0
	local checks = {
		{ "Same species", a ~= nil and b ~= nil and a.species == b.species },
		{ "Both adult", a ~= nil and b ~= nil and Derived.Stage(a) == "Adult" and Derived.Stage(b) == "Adult" },
		{
			"Happiness " .. Derived.BreedMinHappy() .. "+",
			a ~= nil and b ~= nil and problem(a) == nil and problem(b) == nil,
		},
		{ "Free nest", nestFree },
		{ "Coins", a ~= nil and State.Num("coins") >= cost },
	}
	local allOk = true
	for i, ch in checks do
		local ok = ch[2] == true
		allOk = allOk and ok
		local pal = if ok then Style.Pal.Leaf else Style.Pal.Red
		local pill = Kit.Make("Frame", {
			BackgroundColor3 = pal.Bottom,
			Size = UDim2.fromOffset(150, 34),
			LayoutOrder = i,
		}, reqs)
		Kit.Corner(pill, 99)
		Kit.Stroke(pill, pal.Dark, 2.5)
		Kit.Title(pill, (if ok then "OK  " else "X  ") .. ch[1], pal.Dark, { TextSize = 16, StrokeThickness = 2 })
	end
	local eggTime = if a then tonumber(Derived.Field(Derived.Species(tostring(a.species)), "EggSeconds", "eggTime")) else nil
	costLabel.Text = if a
		then string.format("Cost: %s Coins   ·   Egg: %s", Format.Number(cost), Format.Time(eggTime or 120))
		else "Cost and egg time show here"
	Kit.SetButtonColor(breedBtn, if allOk then "Leaf" else "Stone")
	breedBtn:SetAttribute("Ready", allOk)
	Nests.Refresh()
end

function BreedWindow.Pick(which: string)
	local other = if which == "A" then pickB else pickA
	local otherC = if other ~= nil then Derived.Creature(other) else nil
	Kit.Clear(pickGrid)
	local list = Derived.Creatures()
	table.sort(list, function(x, y)
		return (problem(x, otherC) == nil and 0 or 1) < (problem(y, otherC) == nil and 0 or 1)
	end)
	for i, c in list do
		local why = problem(c, otherC)
		CreatureCard.New(pickGrid, c, {
			LayoutOrder = i,
			Disabled = why,
			OnClick = function()
				if which == "A" then
					pickA = c.uid
				else
					pickB = c.uid
				end
				picker.Visible = false
				render(true)
			end,
		})
	end
	picker.Visible = true
	Kit.PopIn(picker, 0.8, 0.25)
end

function BreedWindow.Mount()
	win = Windows.Create("Breed", "Breeding Center", "Coral", "Breed", Vector2.new(920, 640))
	local top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 260) }, win.Body)
	slotA = slot(top, 0, 0)
	slotB = slot(top, 1, 1)
	local mid = Kit.Panel(top, nil, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.42, 0, 1, 0),
	})
	Kit.Label(mid, "Possible offspring", { Size = UDim2.new(1, 0, 0, 30), TextSize = 22, ZIndex = 3 })
	odds = Kit.Scroll(mid, { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -20, 1, -40), ZIndex = 3 })
	Kit.List(odds, false, 2)
	reqs = Kit.Make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 270),
		Size = UDim2.new(1, 0, 0, 36),
	}, win.Body)
	Kit.List(reqs, true, 8, true)
	costLabel = Kit.Body(win.Body, "", {
		Position = UDim2.fromOffset(0, 316),
		Size = UDim2.new(0.6, 0, 0, 64),
		TextSize = 22,
		TextColor3 = Style.Color.Ink,
	})
	breedBtn = Kit.Button(win.Body, "BREED", "Stone", function()
		if breedBtn:GetAttribute("Ready") ~= true then
			Kit.Sound("Error")
			Net.Toast("Tick every requirement first", "error")
			return
		end
		local ok = Net.Do("Breed", nil, pickA, pickB)
		if ok then
			Kit.Sound("Breed_Start")
			Nests.FlyEgg(breedBtn)
			pickA, pickB = nil, nil
			task.delay(0.3, render, true)
		end
	end, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 316),
		Size = UDim2.fromOffset(300, 74),
		TextSize = 36,
		Shine = true,
	})
	Nests.Mount(win.Body, UDim2.new(0, 0, 0, 400), UDim2.new(1, 0, 1, -400))
	picker = Kit.Panel(win.Body, nil, { Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 40 })
	Kit.Label(picker, "Choose a parent", { Size = UDim2.new(1, -80, 0, 44), Position = UDim2.fromOffset(16, 6), TextSize = 28, ZIndex = 41, TextXAlignment = Enum.TextXAlignment.Left })
	Kit.Button(picker, "Back", "Stone", function()
		picker.Visible = false
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(120, 50), ZIndex = 42 })
	pickGrid = Kit.Scroll(picker, { Position = UDim2.fromOffset(8, 62), Size = UDim2.new(1, -16, 1, -70), ZIndex = 41 })
	Kit.Grid(pickGrid, UDim2.fromOffset(150, 190), 12)
	win.OnOpen = function()
		picker.Visible = false
		render(true)
	end
	State.OnChange(function(what)
		if what == "data" then
			render()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if Windows.IsOpen("Breed") then
				Nests.Refresh()
			end
		end
	end)
end

return BreedWindow
