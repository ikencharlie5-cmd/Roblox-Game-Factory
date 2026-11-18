--!strict
-- Always-on HUD (guide section 7). Top-left: currency chips (Cash + $/s, Hope, Luck). Top-centre:
-- weather banner (WeatherBanner.luau). Top-right: restock pill, Store (pulse + shine) and settings gear, goal card,
-- active boosts. All px at 1080p inside the scaled root.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local WeatherBanner = require(script.Parent:WaitForChild("WeatherBanner"))

local Hud = {}
local _skip: any = nil -- sink for unused multiple-return values

local cashChip: Frame
local cashLabel: TextLabel
local rateLabel: TextLabel
local hopeLabel: TextLabel
local luckLabel: TextLabel
local restockLabel: TextLabel
local padLabel: TextLabel
local setPad: (number) -> ()
local releaseLabel: TextLabel
local setRelease: (number) -> ()
local goalCard: Frame
local boostTile: Frame
local boostLabel: TextLabel
local cashValue: NumberValue
local shownCash = 0
local cashInit = false
local lastHope = -1
local lastRestockId = -1

-- Currency chip: dark translucent pill, big icon overlapping the left edge, white number, optional "+".
local function chip(parent: Instance, icon: string, y: number, width: number, onPlus: (() -> ())?): (Frame, TextLabel)
	local c = Kit.Make("Frame", {
		Name = "Chip",
		BackgroundColor3 = Style.Color.Chip,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(30, y),
		Size = UDim2.fromOffset(width, 52),
	}, parent)
	Kit.Corner(c, 99)
	Kit.Stroke(c, Style.Color.Chip, 3)
	Kit.Make("UIScale", { Name = "Pop", Scale = 1 }, c)
	Kit.Icon(c, icon, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -14, 0.5, 0),
		Size = UDim2.fromOffset(56, 56),
		Depth = true,
		ZIndex = 3,
	})
	local l = Kit.Title(c, "0", Style.Color.Dark, {
		Position = UDim2.fromOffset(50, 4),
		Size = UDim2.new(1, if onPlus then -100 else -60, 1, -8),
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	if onPlus then
		Kit.Button(c, "+", "Leaf", onPlus, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(40, 42),
			Radius = 12,
			Lip = 4,
			TextSize = 30,
			ZIndex = 3,
		})
	end
	return c, l
end

local function pop(obj: Instance)
	local s = obj:FindFirstChild("Pop") :: UIScale?
	if s then
		s.Scale = 1.12
		Kit.Tween(s, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

function Hud.Mount(gui: ScreenGui)
	local root = Kit.Root(gui)
	local left = Kit.Make("Frame", {
		Name = "Currencies",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.fromOffset(300, 220),
		ZIndex = 2,
	}, root)
	local openStore = function()
		Windows.Open("Store")
	end
	cashChip, cashLabel = chip(left, "Cash", 0, 270, openStore)
	cashLabel.Text = "$0"
	rateLabel = Kit.Title(left, "+$0/s", Style.Pal.Leaf.Dark, {
		Position = UDim2.fromOffset(84, 54),
		Size = UDim2.fromOffset(200, 26),
		TextSize = 22,
		TextColor3 = Style.Color.Cash,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	_skip, hopeLabel = chip(left, "Hope", 88, 220, openStore)
	_skip, luckLabel = chip(left, "Luck", 150, 180, nil)
	cashValue = Kit.Make("NumberValue", { Value = 0 }, left)
	cashValue.Changed:Connect(function(v)
		cashLabel.Text = "$" .. Format.Number(v)
	end)

	WeatherBanner.Mount(root)

	-- Top-right: restock pill + Store + gear
	local right = Kit.Make("Frame", {
		Name = "TopRight",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 10),
		Size = UDim2.fromOffset(400, 100),
		ZIndex = 2,
	}, root)
	local gear = Kit.Button(right, "", "Stone", function()
		Windows.Toggle("Settings")
	end, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(52, 56),
		Radius = 14,
		Lip = 4,
		Icon = "Settings",
	})
	gear.Name = "Settings"
	local store = Kit.IconButton(right, "Store", "Store", "Pink", function()
		Windows.Toggle("Store")
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 0), Shine = true, Pulse = true })
	store.Name = "Store"
	local restock = Kit.Button(right, "", "Wood", function()
		Windows.Open("Shop")
	end, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -162, 0, 6),
		Size = UDim2.fromOffset(220, 56),
		Radius = 99,
		Lip = 4,
	})
	restockLabel = Kit.Title(Kit.ButtonFace(restock), "Restock 5:00", Style.Pal.Wood.Dark, {
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		TextSize = 24,
		ZIndex = 5,
	})

	-- Goal card (right, under the top row): next pad + Release progress. Tap = open that screen.
	goalCard = Kit.Panel(root, Style.Color.Cream, {
		Name = "GoalCard",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 126),
		Size = UDim2.fromOffset(300, 128),
		ZIndex = 2,
	})
	local function goalRow(y: number, color: any, onTap: () -> ()): (TextLabel, (number) -> ())
		local btn = Kit.Make("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Position = UDim2.fromOffset(12, y),
			Size = UDim2.new(1, -24, 0, 56),
			ZIndex = 3,
		}, goalCard)
		local l = Kit.Label(btn, "", { Size = UDim2.new(1, 0, 0, 28), TextSize = 22, ZIndex = 3 })
		l.TextXAlignment = Enum.TextXAlignment.Left
		local _, set = Kit.Progress(btn, color, { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 18) })
		btn.Activated:Connect(function()
			Kit.Sound("Click")
			onTap()
		end)
		return l, set
	end
	padLabel, setPad = goalRow(8, "Leaf", function()
		Windows.Open("Build", { tab = "Exhibits" })
	end)
	releaseLabel, setRelease = goalRow(66, "Teal", function()
		Windows.Open("Release")
	end)

	-- Active boost tile (Luck Potion) under the goal card.
	boostTile = Kit.Make("Frame", {
		Name = "Boost",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 270),
		Size = UDim2.fromOffset(64, 70),
		Visible = false,
		ZIndex = 2,
	}, root)
	local bface = Kit.Slab(boostTile, Style.Pal.Purple, 16, 4, 3, true)
	Kit.Icon(bface, "LuckPotion", { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.06) })
	boostLabel = Kit.Title(boostTile, "", Style.Color.Dark, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(100, 24),
		TextSize = 20,
		ZIndex = 6,
	})

	State.OnChange(function(what)
		if what == "data" then
			Hud.Refresh()
		end
	end)
	task.spawn(function()
		while true do
			Hud.Tick()
			task.wait(0.25)
		end
	end)
end

function Hud.Refresh()
	local cash = State.Num("cash")
	if cash ~= shownCash then
		local gained = cash - shownCash
		local first = not cashInit
		cashInit = true
		shownCash = cash
		if first then
			cashValue.Value = cash
		else
			Kit.Tween(cashValue, 0.35, { Value = cash })
		end
		if gained > 0 and not first then
			pop(cashChip)
			Kit.Float(cashChip, "+$" .. Format.Number(gained), UDim2.new(0.5, 0, 1, 10))
		end
	end
	local hope = State.Num("hope")
	if hope ~= lastHope then
		if lastHope >= 0 and hope > lastHope then
			pop(hopeLabel.Parent :: Instance)
		end
		lastHope = hope
		hopeLabel.Text = Format.Number(hope)
	end

	local nextIdx, price = Derived.NextPad()
	if nextIdx and price then
		padLabel.Text = string.format("Next: Pad %d  $%s", nextIdx, Format.Number(price))
		setPad(cash / price)
	else
		padLabel.Text = "All pads owned!"
		setPad(1)
	end
	local n, need, rarity = Derived.ReleaseInfo()
	releaseLabel.Text = string.format("Release #%d: $%s + %s", n, Format.Number(need), rarity)
	setRelease(cash / need)
end

function Hud.Tick()
	local now = State.Now()
	rateLabel.Text = "+$" .. Format.Number(Derived.Income()) .. "/s"

	luckLabel.Text = string.format("x%.1f", Derived.Luck())
	local potion = Derived.LuckPotionLeft()
	boostTile.Visible = potion > 0
	if potion > 0 then
		boostLabel.Text = Format.Time(potion)
	end

	-- Restock countdown is global and deterministic: every RestockSeconds of server time.
	local period = Derived.Config.Shop.RestockSeconds
	local restockId = math.floor(now / period)
	local left = (restockId + 1) * period - now
	restockLabel.Text = "Restock " .. Format.Time(left)
	if lastRestockId ~= -1 and restockId ~= lastRestockId then
		restockLabel.TextColor3 = Style.Color.Hope
		Kit.Tween(restockLabel, 1, { TextColor3 = Style.Color.White })
	end
	lastRestockId = restockId

	WeatherBanner.Tick(now)
end

-- Used by the tutorial to point at things.
function Hud.GoalCard(): Frame
	return goalCard
end

return Hud
