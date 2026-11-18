--!strict
-- Client entry: builds every UI module in code, wires server events into UI state.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = script.Parent:WaitForChild("UI")
local SoundController = require(script.Parent:WaitForChild("Audio"):WaitForChild("SoundController")) :: any

local Style = require(UI:WaitForChild("Style"))
local Kit = require(UI:WaitForChild("Kit"))
local State = require(UI:WaitForChild("State"))
local Net = require(UI:WaitForChild("Net"))
local Derived = require(UI:WaitForChild("Derived"))
local Windows = require(UI:WaitForChild("Windows"))
local Notify = require(UI:WaitForChild("Notify"))
local Market = require(UI:WaitForChild("Market"))
local Hud = require(UI:WaitForChild("Hud"))
local SideBar = require(UI:WaitForChild("SideBar"))
local BuildMode = require(UI:WaitForChild("BuildMode"))
local ShopWindow = require(UI:WaitForChild("ShopWindow"))
local InventoryWindow = require(UI:WaitForChild("InventoryWindow"))
local BuildWindow = require(UI:WaitForChild("BuildWindow"))
local CreatureCard = require(UI:WaitForChild("CreatureCard"))
local IndexWindow = require(UI:WaitForChild("IndexWindow"))
local UpgradesWindow = require(UI:WaitForChild("UpgradesWindow"))
local ReleaseWindow = require(UI:WaitForChild("ReleaseWindow"))
local QuestsWindow = require(UI:WaitForChild("QuestsWindow"))
local DailyWindow = require(UI:WaitForChild("DailyWindow"))
local VisitWindow = require(UI:WaitForChild("VisitWindow"))
local StoreWindow = require(UI:WaitForChild("StoreWindow"))
local SettingsWindow = require(UI:WaitForChild("SettingsWindow"))
local Tutorial = require(UI:WaitForChild("Tutorial"))
local ChatTags = require(UI:WaitForChild("ChatTags"))

local player = Players.LocalPlayer :: Player

SoundController.Start()
ChatTags.Start()

-- Camera: a little wider so whole exhibits fit on phones.
workspace.CurrentCamera.FieldOfView = 72
player.CameraMaxZoomDistance = 70

-- Build all UI
Notify.Init()
local gui = Kit.Gui("SproutUI", 5)
Windows.Init(gui)
Hud.Mount(gui)
SideBar.Mount(gui)
BuildMode.Mount(gui)
ShopWindow.Mount()
InventoryWindow.Mount()
BuildWindow.Mount()
CreatureCard.Mount()
IndexWindow.Mount()
UpgradesWindow.Mount()
ReleaseWindow.Mount()
QuestsWindow.Mount()
DailyWindow.Mount()
VisitWindow.Mount()
StoreWindow.Mount()
SettingsWindow.Mount()
Tutorial.Mount(gui)

-- Cross-module hooks
Net.SetNotifier(Notify.Toast)
Market.SetNotifier(Notify.Toast)
CreatureCard.SetNotifier(Notify.Toast)
InventoryWindow.SetCardOpener(CreatureCard.Open)
ReleaseWindow.SetSplash(Notify.Splash)
Tutorial.SetGoalCard(Hud.GoalCard())
DailyWindow.SetBadge(function(on)
	SideBar.Badge("Daily", on)
end)
QuestsWindow.SetBadge(function(on)
	SideBar.Badge("Quests", on)
end)

-- Server -> client events
local firstData = true
Net.On("DataChanged", function(data)
	State.SetData(data)
	if firstData then
		firstData = false
		-- Returning players (tutorial done) get the Daily screen if a reward is waiting.
		task.delay(2, function()
			local _, can = DailyWindow.Next()
			local tutorialDone = Derived.Config.Tutorial[State.Num("tutorialStep")] == nil
			if can and tutorialDone and not BuildMode.IsActive() then
				Windows.Open("Daily")
			end
		end)
	end
end)
Net.On("StockChanged", function(stock)
	State.stock = stock
	State.Fire("stock")
end)
Net.On("WeatherChanged", function(info)
	State.weather = info
	State.Fire("weather")
end)
Net.On("Notify", function(text, kind)
	Notify.Toast(tostring(text), if type(kind) == "string" then kind else nil)
end)
Net.On("Announce", function(text, rarity)
	Notify.Announce(tostring(text), if type(rarity) == "string" then rarity else nil)
end)
Net.On("OfflineEarnings", function(amount, seconds)
	if type(amount) == "number" and amount > 0 then
		Notify.Offline(amount, if type(seconds) == "number" then seconds else 0, Derived.HasPass("VIP"))
	end
end)

-- Server ProximityPrompts (hub stands) open screens by name.
local SCREENS: { [string]: { string } } = {
	SeedShop = { "Shop" },
	Shop = { "Shop" },
	HopeShop = { "Shop", "Hope" },
	Upgrades = { "Upgrades" },
	Release = { "Release" },
	Daily = { "Daily" },
	Quests = { "Quests" },
	Store = { "Store" },
	Index = { "Index" },
}
Net.On("OpenScreen", function(name)
	local target = SCREENS[tostring(name)]
	if target and not BuildMode.IsActive() then
		Windows.Open(target[1], target[2])
	end
end)

-- Weather fallback from replicated GameState attributes (in case the event fired before we listened).
task.spawn(function()
	local st = ReplicatedStorage:WaitForChild("GameState", 30)
	if not st then
		return
	end
	local function read()
		local name = st:GetAttribute("Weather")
		if type(name) == "string" then
			State.weather = {
				name = name,
				endsAt = st:GetAttribute("WeatherEndsAt") or 0,
				nextAt = st:GetAttribute("NextWeatherAt") or 0,
			}
			State.Fire("weather")
		end
	end
	read()
	st.AttributeChanged:Connect(function(attr)
		if string.sub(attr, 1, 7) == "Weather" or attr == "NextWeatherAt" then
			read()
		end
	end)
end)

-- "Thriving!" splash whenever the server reports more Thriving creatures than before.
-- Changes before data has loaded (+3 s settle) only seed the count, so returning players
-- don't get a splash on every join.
local lastThriving = player:GetAttribute("ThrivingCount") or 0
local thrivingArmedAt: number? = if State.loaded then os.clock() + 3 else nil
State.OnChange(function(what)
	if what == "data" and not thrivingArmedAt then
		thrivingArmedAt = os.clock() + 3
	end
end)
player:GetAttributeChangedSignal("ThrivingCount"):Connect(function()
	local n = player:GetAttribute("ThrivingCount") or 0
	local armed = thrivingArmedAt ~= nil and os.clock() >= thrivingArmedAt
	if armed and type(n) == "number" and type(lastThriving) == "number" and n > lastThriving then
		Notify.Splash("Thriving! x1.5", Style.Color.Leaf)
	end
	lastThriving = n
end)
