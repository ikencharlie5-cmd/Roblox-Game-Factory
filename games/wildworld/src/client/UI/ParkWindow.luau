--!strict
-- Park panel: park rating (stars + number), tier ladder (Poor -> Legendary with income bonus),
-- income per minute, and the coin upgrades (BuyUpgrade). Server decides prices and effects.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
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
	{ key = "Land", title = "Park Land", costs = { 500, 2000, 6000, 15000 }, text = "Bigger buildable area" },
	{ key = "Capacity", title = "Creature Capacity", costs = { 300, 900, 2500, 6000, 15000 }, text = "+2 park slots" },
	{ key = "Incubators", title = "Incubators", costs = { 1500, 8000 }, text = "+1 egg at once" },
	{ key = "CalmNet", title = "Calm Net", costs = { 400, 2000, 7000 }, text = "Capture green zone +5%" },
}

local win: any
local top: Frame
local list: ScrollingFrame
local lastSig = ""

-- Config.Upgrades is keyed (Land/Capacity/Incubators/CalmNet); the key is what BuyUpgrade wants.
local ORDER = { Land = 1, Capacity = 2, Incubators = 3, CalmNet = 4 }
local TEXT = {
	Land = "Bigger buildable area",
	Capacity = "+2 creatures on show",
	Incubators = "+1 egg at once",
	CalmNet = "Capture green zone +5%",
}
local function upgrades(): { { [string]: any } }
	local cfg = Derived.Cfg("Upgrades")
	if type(cfg) ~= "table" then
		return FALLBACK_UPGRADES
	end
	local out = {}
	for key, u in cfg do
		if type(u) == "table" then
			table.insert(out, { key = key, title = u.Name or key, costs = u.Costs or {}, text = u.Text or TEXT[key] or "" })
		end
	end
	table.sort(out, function(a, b)
		return (ORDER[a.key] or 9) < (ORDER[b.key] or 9)
	end)
	return out
end

local function renderTop()
	Kit.Clear(top)
	local player = Players.LocalPlayer :: Player
	local rating = tonumber(player:GetAttribute("ParkRating")) or 0
	local tier, nxt = Derived.ParkTier(rating)
	local _, setStars = Kit.Stars(top, { Position = UDim2.fromOffset(0, 6) })
	setStars(rating)
	Kit.Label(top, string.format("Park rating %d  ·  %s", math.floor(rating), tostring(tier.name)), {
		Position = UDim2.fromOffset(186, 0),
		Size = UDim2.new(1, -186, 0, 40),
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local income = tonumber(player:GetAttribute("IncomePerMin")) or 0
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
		local key = tostring(u.key)
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

-- Locked wild zones (Config.Zones): Park Level + coins, unlocked by the server via UnlockZone.
local function unlockZone(z: { [string]: any })
	local name, cost = tostring(z.Name or z.Id), tonumber(z.Cost) or 0
	if Derived.Level() < (tonumber(z.Level) or 1) then
		Kit.Sound("Error")
		Net.Toast(name .. " unlocks at Park Level " .. tostring(z.Level), "error")
		return
	end
	if State.Num("coins") < cost then
		Kit.Sound("Error")
		Net.Toast("Needs " .. Format.Number(cost) .. " Coins", "error")
		return
	end
	Windows.Confirm("Unlock " .. name .. "?", "Open " .. name .. " for " .. Format.Number(cost) .. " Coins?", "Unlock", function()
		if Net.Do("UnlockZone", name .. " unlocked!", z.Id) then
			Kit.Sound("Purchase")
		end
	end)
end
ParkWindow.UnlockZone = unlockZone

local function renderZones(order: number)
	local owned = State.Tbl("zones")
	local lvlNow = Derived.Level()
	for i, z in Derived.Cfg("Zones") or {} do
		if type(z) == "table" and (tonumber(z.Cost) or 0) > 0 and not owned[z.Id] then
			local need = tonumber(z.Level) or 1
			local cost = tonumber(z.Cost) or 0
			local ready = lvlNow >= need and State.Num("coins") >= cost
			local card = Kit.Panel(list, nil, { Size = UDim2.new(1, -12, 0, 84), LayoutOrder = order + i })
			Kit.Label(card, "Zone: " .. tostring(z.Name or z.Id), {
				Position = UDim2.fromOffset(16, 6),
				Size = UDim2.new(0.6, 0, 0, 36),
				TextSize = 26,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
			})
			Kit.Body(card, string.format("Needs Park Level %d  ·  New wild creatures", need), {
				Position = UDim2.fromOffset(16, 44),
				Size = UDim2.new(0.6, 0, 0, 28),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
			})
			local text = if lvlNow < need then "Lv " .. need else "Unlock " .. Format.Number(cost)
			Kit.Button(card, text, if ready then "Sun" else "Disabled", function()
				unlockZone(z)
			end, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(220, 62),
				TextSize = 24,
				ZIndex = 4,
			})
		end
	end
end

local function render()
	if not Windows.IsOpen("Park") then
		return
	end
	local player = Players.LocalPlayer :: Player
	local sig = Kit.Sig({
		player:GetAttribute("ParkRating"),
		State.Get("upgrades"),
		State.Num("coins"),
		State.Get("zones"),
		State.Get("level"),
		player:GetAttribute("IncomePerMin"),
	})
	if sig == lastSig then
		return
	end
	lastSig = sig
	renderTop()
	renderList()
	renderZones(100)
end

-- Client-side "Unlock" prompt on each locked ZoneGate anchor (opens the confirm dialog).
local gatePrompts: { [ProximityPrompt]: { [string]: any } } = {}
local function refreshGates()
	local owned = State.Tbl("zones")
	for prompt, z in gatePrompts do
		if prompt.Parent then
			prompt.Enabled = not owned[z.Id]
		else
			gatePrompts[prompt] = nil
		end
	end
end
local function addGate(anchor: Instance)
	if not anchor:IsA("BasePart") then
		return
	end
	for _, z in Derived.Cfg("Zones") or {} do
		if type(z) == "table" and z.Id == anchor:GetAttribute("Zone") and (tonumber(z.Cost) or 0) > 0 then
			local prompt = Kit.Make("ProximityPrompt", {
				ActionText = "Unlock " .. tostring(z.Name or z.Id),
				ObjectText = string.format("Park Lv %d + %s Coins", tonumber(z.Level) or 1, Format.Number(tonumber(z.Cost) or 0)),
				HoldDuration = 0,
				MaxActivationDistance = 14,
				RequiresLineOfSight = false,
			}, anchor)
			prompt.Triggered:Connect(function()
				unlockZone(z)
			end)
			gatePrompts[prompt] = z
		end
	end
	refreshGates()
end

function ParkWindow.Mount()
	CollectionService:GetInstanceAddedSignal("ZoneGate"):Connect(addGate)
	for _, g in CollectionService:GetTagged("ZoneGate") do
		addGate(g)
	end
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
			refreshGates()
			render()
		end
	end)
	local lp = Players.LocalPlayer :: Player
	lp.AttributeChanged:Connect(function(attr)
		if attr == "ParkRating" or attr == "IncomePerMin" then
			render()
		end
	end)
end

return ParkWindow
