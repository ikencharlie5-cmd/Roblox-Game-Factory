--!strict
-- Park panel: park rating (stars + number), tier ladder (Poor -> Legendary with income bonus),
-- income per minute, and the coin upgrades (BuyUpgrade). Server decides prices and effects.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Net = require(script.Parent:WaitForChild("Net"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local ParkWindow = {}

local FALLBACK_UPGRADES = {
	{ name = "ParkLand", title = "Park Land", costs = { 500, 2000, 6000, 15000 }, text = "Bigger buildable area" },
	{ name = "Capacity", title = "Creature Capacity", costs = { 300, 900, 2500, 6000, 15000 }, text = "+2 park slots" },
	{ name = "Incubators", title = "Incubators", costs = { 1500, 8000 }, text = "+1 egg at once" },
	{ name = "CalmNet", title = "Calm Net", costs = { 400, 2000, 7000 }, text = "Capture green zone +5%" },
	{ name = "SnackStand", title = "Snack Stand", costs = { 750, 750, 750 }, text = "+5% park income each" },
}

local win: any
local top: Frame
local list: ScrollingFrame
local lastSig = ""

local function upgrades(): { { [string]: any } }
	local cfg = Derived.List(Derived.Cfg("Upgrades"))
	return if #cfg > 0 then cfg else FALLBACK_UPGRADES
end

local function renderTop()
	Kit.Clear(top)
	local rating = State.Num("parkRating")
	local tier, nxt = Derived.ParkTier(rating)
	local _, setStars = Kit.Stars(top, { Position = UDim2.fromOffset(0, 6) })
	setStars(rating)
	Kit.Label(top, string.format("Park rating %d  ·  %s", math.floor(rating), tostring(tier.name)), {
		Position = UDim2.fromOffset(186, 0),
		Size = UDim2.new(1, -186, 0, 40),
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local income = tonumber(State.Get("incomePerMin")) or 0
	local bonus = tonumber(Derived.Field(tier, "bonus", "Bonus")) or 0
	local nextText = if nxt
		then string.format("Next tier: %s at %d", tostring(nxt.name), tonumber(Derived.Field(nxt, "min", "Min")) or 0)
		else "Top tier reached!"
	Kit.Body(top, string.format("Income: %s Coins/min  ·  Tier bonus +%d%%  ·  %s", Format.Number(income), math.floor(bonus * 100), nextText), {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- Tier ladder chips
	local ladder = Kit.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 40) }, top)
	Kit.List(ladder, true, 6)
	for i, t in Derived.ParkTiers() do
		local on = t.name == tier.name
		local pal = if on then Style.Pal.Leaf else Style.Pal.Card
		local chip = Kit.Make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1 / 6, -6, 1, 0), LayoutOrder = i }, ladder)
		Kit.Corner(chip, 99)
		Kit.Gradient(chip, pal)
		Kit.Stroke(chip, pal.Dark, 2.5)
		Kit.Title(chip, tostring(t.name), if on then pal.Dark else Style.Color.Chip, { TextSize = 16, StrokeThickness = if on then 2 else 1 })
	end
end

local function renderList()
	Kit.Clear(list)
	local levels = State.Tbl("upgrades")
	local coins = State.Num("coins")
	for i, u in upgrades() do
		local key = tostring(Derived.Field(u, "id", "key", "name"))
		local lvl = tonumber(levels[key]) or 0
		local costs = Derived.Field(u, "costs", "Costs", "levels", "Levels") or {}
		local cost = tonumber(if type(costs[lvl + 1]) == "table" then costs[lvl + 1].cost else costs[lvl + 1])
		local maxed = cost == nil
		local card = Kit.Panel(list, nil, { Size = UDim2.new(1, -12, 0, 84), LayoutOrder = i })
		Kit.Label(card, tostring(Derived.Field(u, "title", "Title", "displayName") or key), {
			Position = UDim2.fromOffset(16, 6),
			Size = UDim2.new(0.6, 0, 0, 36),
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		})
		Kit.Body(card, string.format("Level %d / %d  ·  %s", lvl, #costs, tostring(Derived.Field(u, "text", "desc", "description") or "")), {
			Position = UDim2.fromOffset(16, 44),
			Size = UDim2.new(0.6, 0, 0, 28),
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		})
		local afford = not maxed and coins >= (cost or 0)
		Kit.Button(card, if maxed then "MAX" else Format.Number(cost or 0) .. " Coins", if maxed then "Stone" elseif afford then "Sun" else "Disabled", function()
			if maxed then
				return
			end
			if not afford then
				Kit.Sound("Error")
				Net.Toast("Not enough Coins", "error")
				return
			end
			if Net.Do("BuyUpgrade", nil, key) then
				Kit.Sound("Purchase")
			end
		end, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(220, 62),
			TextSize = 24,
			ZIndex = 4,
		})
	end
end

local function render()
	if not Windows.IsOpen("Park") then
		return
	end
	local sig = Kit.Sig({ State.Get("parkRating"), State.Get("upgrades"), State.Num("coins"), State.Get("incomePerMin") })
	if sig == lastSig then
		return
	end
	lastSig = sig
	renderTop()
	renderList()
end

function ParkWindow.Mount()
	win = Windows.Create("Park", "My Park", "Leaf", "Park", Vector2.new(860, 620))
	top = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 130) }, win.Body)
	list = Kit.Scroll(win.Body, { Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 1, -140) })
	Kit.List(list, false, 10)
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

return ParkWindow
