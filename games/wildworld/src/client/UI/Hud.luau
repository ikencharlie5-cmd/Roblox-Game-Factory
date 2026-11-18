--!strict
-- HUD (guide §3): Coins + RP chips (top-left), biome chip (top-centre), Level badge + XP bar and
-- the gear (top-right), a small Shop / Daily / Visit row under it, and the quest tracker card.
-- Pieces start hidden and fade in when Tutorial/SideBar unlock them (one new thing per goal).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local State = require(script.Parent:WaitForChild("State"))
local Derived = require(script.Parent:WaitForChild("Derived"))
local Windows = require(script.Parent:WaitForChild("Windows"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local Hud = {}

local root: Frame
local coinsChip: Frame
local rpChip: Frame
local coinsText: TextLabel
local rpText: TextLabel
local biomeChip: Frame
local biomeText: TextLabel
local levelBox: Frame
local levelText: TextLabel
local setXp: (number) -> ()
local topRow: Frame
local shown: { [string]: boolean } = {}
local lastCoins = -1
local rowButtons: { [string]: TextButton } = {}

-- Currency pill 200x52: 48 px icon overlapping the left edge, FredokaOne number, mini "+".
local function chip(name: string, icon: string, pal: any, y: number, onPlus: () -> ()): (Frame, TextLabel)
	local holder = Kit.Make("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, y),
		Size = UDim2.fromOffset(200, 52),
		Visible = false,
	}, root)
	local face = Kit.Slab(holder, { Top = Color3.fromHex("#2C3B39"), Bottom = Style.Color.Chip, Dark = pal.Dark }, 99, 4)
	Kit.Icon(holder, icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.45, 0),
		Size = UDim2.fromOffset(48, 48),
		ZIndex = 6,
	})
	local text = Kit.Title(face, "0", pal.Dark, {
		Name = "Value",
		Position = UDim2.fromOffset(30, 4),
		Size = UDim2.new(1, -78, 1, -10),
		TextSize = 30,
		TextColor3 = pal.Top,
		StrokeThickness = 3,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})
	Kit.Button(holder, "+", "Leaf", onPlus, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 4, 0.45, 0),
		Size = UDim2.fromOffset(44, 44),
		TextSize = 30,
		Lip = 3,
		Radius = 99,
		ZIndex = 7,
	})
	return holder, text
end

local function fadeIn(obj: GuiObject)
	if obj.Visible then
		return
	end
	obj.Visible = true
	Kit.PopIn(obj, 0.3, 0.35)
	Kit.Sound("ButtonUnlock")
end

function Hud.Mount(gui: ScreenGui)
	root = Kit.Root(gui)
	coinsChip, coinsText = chip("Coins", "Coins", Style.Pal.Sun, 64, function()
		Windows.Open("Shop", "Coins")
	end)
	rpChip, rpText = chip("RP", "RP", Style.Pal.Purple, 126, function()
		Windows.Open("Journal")
	end)

	-- Biome chip (top-centre, 360x48), slides down on biome change.
	biomeChip = Kit.Make("Frame", {
		Name = "Biome",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(360, 48),
	}, root)
	local bface = Kit.Slab(biomeChip, Style.PaletteFor(Style.Biome.Park), 99, 4)
	biomeText = Kit.Title(bface, "My Park", Style.Color.Chip, {
		Size = UDim2.new(1, -24, 1, -8),
		Position = UDim2.fromOffset(12, 4),
		TextSize = 26,
		ZIndex = 4,
	})

	-- Level badge (56 px coral) + XP bar (180x14) + gear (top-right).
	levelBox = Kit.Make("Frame", {
		Name = "Level",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -96, 0, 12),
		Size = UDim2.fromOffset(250, 60),
		Visible = false,
	}, root)
	local badge = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(56, 60) }, levelBox)
	local lface = Kit.Slab(badge, Style.Pal.Coral, 99, 4)
	levelText = Kit.Title(lface, "1", Style.Pal.Coral.Dark, { TextSize = 30, ZIndex = 4 })
	Kit.Title(levelBox, "Park Lv", Style.Color.Chip, {
		Position = UDim2.fromOffset(66, 2),
		Size = UDim2.fromOffset(180, 24),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local _, setter = Kit.Progress(levelBox, "Leaf", {
		Position = UDim2.fromOffset(66, 32),
		Size = UDim2.fromOffset(180, 14),
	})
	setXp = setter
	Kit.IconButton(root, "Settings", "", "Stone", function()
		Windows.Toggle("Settings")
	end, {
		Name = "Gear",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 10),
		Size = UDim2.fromOffset(64, 64),
	})

	-- Shop / Daily / Visit row under the level (appears after the tutorial).
	topRow = Kit.Make("Frame", {
		Name = "TopRow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 90),
		Size = UDim2.fromOffset(240, 76),
		Visible = false,
	}, root)
	local list = Kit.List(topRow, true, 10)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	for i, def in { { "Shop", "Sun" }, { "Daily", "Sun" }, { "Visit", "Teal" } } do
		local name = def[1]
		rowButtons[name] = Kit.IconButton(topRow, name, name, def[2], function()
			Windows.Toggle(name)
		end, { Size = UDim2.fromOffset(68, 68), LayoutOrder = i })
		Kit.Badge(rowButtons[name])
	end

	State.OnChange(function(what)
		if what == "data" then
			Hud.Refresh()
		end
	end)
	local player = Players.LocalPlayer :: Player
	local function biome()
		local z = player:GetAttribute("Biome") or player:GetAttribute("Zone") or player:GetAttribute("Area")
		Hud.SetBiome(if type(z) == "string" and z ~= "" then z else "My Park")
	end
	player:GetAttributeChangedSignal("Biome"):Connect(biome)
	player:GetAttributeChangedSignal("Zone"):Connect(biome)
	player:GetAttributeChangedSignal("Area"):Connect(biome)
	biome()
end

local EXTRA_NAMES = { Park = "My Park", Hub = "Plaza" }

-- Zone attribute is a Config.Zones Id (Meadow/Hollow/Glade) or Park/Hub; show Config.Zones[].Name.
local function zoneName(id: string): string
	local zones = Derived.Cfg("Zones")
	if type(zones) == "table" then
		for _, z in zones do
			if type(z) == "table" and z.Id == id and type(z.Name) == "string" then
				return z.Name
			end
		end
	end
	return EXTRA_NAMES[id] or id
end

function Hud.SetBiome(raw: string)
	local name = zoneName(raw)
	if biomeText.Text == name then
		return
	end
	biomeText.Text = name
	local face = Kit.ButtonFace(biomeChip)
	local g = face:FindFirstChildOfClass("UIGradient")
	local pal = Style.PaletteFor(Style.BiomeColor(name))
	if g then
		Kit.SetGradient(g, pal)
	end
	local s = face:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = pal.Dark
	end
	biomeChip.Position = UDim2.new(0.5, 0, 0, -60)
	Kit.Tween(biomeChip, 0.3, { Position = UDim2.new(0.5, 0, 0, 12) }, Enum.EasingStyle.Back)
end

-- Unlock a HUD piece by name: "Coins", "RP", "Level", "TopRow".
function Hud.Show(name: string)
	if shown[name] then
		return
	end
	shown[name] = true
	local obj = ({ Coins = coinsChip, RP = rpChip, Level = levelBox, TopRow = topRow } :: any)[name]
	if obj then
		fadeIn(obj)
	end
end

function Hud.RowBadge(name: string, on: boolean)
	local b = rowButtons[name]
	local badge = b and b:FindFirstChild("NotifyBadge")
	if badge and badge:IsA("GuiObject") then
		badge.Visible = on
	end
end

-- Screen position (root px) of the coins chip, for coin fly-ins.
function Hud.CoinsAnchor(): UDim2
	return UDim2.fromOffset(124, 90)
end

function Hud.Refresh()
	local coins = State.Num("coins")
	coinsText.Text = Format.Number(coins)
	if lastCoins >= 0 and coins > lastCoins then
		Kit.Float(root, "+" .. Format.Number(coins - lastCoins), UDim2.fromOffset(160, 130), Style.Color.Coins)
		local s = coinsChip:FindFirstChild("Bump") :: UIScale?
		if not s then
			s = Kit.Make("UIScale", { Name = "Bump" }, coinsChip)
		end
		(s :: UIScale).Scale = 1.12
		Kit.Tween(s :: UIScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	lastCoins = coins
	rpText.Text = Format.Number(State.Num("rp"))
	local lvl, alpha = Derived.Level()
	if levelText.Text ~= tostring(lvl) and levelText.Text ~= "1" then
		Kit.PopIn(levelBox, 1.3, 0.4)
	end
	levelText.Text = tostring(lvl)
	setXp(alpha)
end

return Hud
