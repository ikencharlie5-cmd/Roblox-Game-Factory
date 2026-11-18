--!strict
-- Client entry: builds every UI module in code and wires server events into UI state.
-- The client never decides outcomes; it shows server data and fires intent remotes.
local Players = game:GetService("Players")

local Client = script.Parent
local UI = Client:WaitForChild("UI")
local Audio = Client:WaitForChild("Audio")
local SoundController = require(Audio:WaitForChild("SoundController")) :: any

local Kit = require(UI:WaitForChild("Kit"))
local State = require(UI:WaitForChild("State"))
local Net = require(UI:WaitForChild("Net"))
local Windows = require(UI:WaitForChild("Windows"))
local Notify = require(UI:WaitForChild("Notify"))
local Hud = require(UI:WaitForChild("Hud"))
local SideBar = require(UI:WaitForChild("SideBar"))
local QuestCard = require(UI:WaitForChild("QuestCard"))
local ContextBar = require(UI:WaitForChild("ContextBar"))
local CaptureUI = require(UI:WaitForChild("CaptureUI"))
local BuildMode = require(UI:WaitForChild("BuildMode"))
local Nests = require(UI:WaitForChild("Nests"))
local Reveal = require(UI:WaitForChild("Reveal"))
local Nameplates = require(UI:WaitForChild("Nameplates"))
local CollectionWindow = require(UI:WaitForChild("CollectionWindow"))
local InspectWindow = require(UI:WaitForChild("InspectWindow"))
local BreedWindow = require(UI:WaitForChild("BreedWindow"))
local JournalWindow = require(UI:WaitForChild("JournalWindow"))
local InventoryWindow = require(UI:WaitForChild("InventoryWindow"))
local ParkWindow = require(UI:WaitForChild("ParkWindow"))
local ShopWindow = require(UI:WaitForChild("ShopWindow"))
local DailyWindow = require(UI:WaitForChild("DailyWindow"))
local VisitWindow = require(UI:WaitForChild("VisitWindow"))
local SettingsWindow = require(UI:WaitForChild("SettingsWindow"))
local Tutorial = require(UI:WaitForChild("Tutorial"))

local player = Players.LocalPlayer :: Player

SoundController.Start()

-- World animation (Animation branch): creatures, eggs, visitors, sway, FX. Isolated so it can't break UI.
task.spawn(function()
	local ok, err = pcall(function()
		local anim = require(Client:WaitForChild("Animation"):WaitForChild("AnimationController")) :: any
		anim.Start()
	end)
	if not ok then
		warn("[Animation] failed to start: " .. tostring(err))
	end
end)

-- Camera: a bit wider so whole habitats fit on phones; capped zoom keeps parks readable.
workspace.CurrentCamera.FieldOfView = 72
player.CameraMaxZoomDistance = 80
player.CameraMinZoomDistance = 6

-- Build all UI
Notify.Init()
local gui = Kit.Gui("WildUI", 5)
Windows.Init(gui)
Hud.Mount(gui)
SideBar.Mount(gui)
QuestCard.Mount(gui)
CaptureUI.Mount(gui)
ContextBar.Mount(gui)
BuildMode.Mount(gui)
CollectionWindow.Mount()
InspectWindow.Mount()
BreedWindow.Mount()
JournalWindow.Mount()
InventoryWindow.Mount()
ParkWindow.Mount()
ShopWindow.Mount()
DailyWindow.Mount()
VisitWindow.Mount()
SettingsWindow.Mount()
Reveal.Mount()
Nameplates.Mount()
Tutorial.Mount(gui)

-- Cross-module hooks
Net.SetNotifier(Notify.Toast)
Reveal.SetInspect(function(uid)
	InspectWindow.Open(uid)
end)
ContextBar.SetInspect(function(uid)
	InspectWindow.Open(uid)
end)
ContextBar.Action:Connect(function(action)
	if action == "Feed" then
		Tutorial.MarkFed()
	end
end)
SideBar.SetHandler("Build", function()
	if BuildMode.IsActive() then
		BuildMode.Exit()
	else
		Windows.Close()
		BuildMode.Enter()
	end
end)
InventoryWindow.SetBuild(BuildMode.Enter)
JournalWindow.SetBadge(function(n)
	SideBar.Badge("Journal", n)
end)
DailyWindow.SetBadge(function(on)
	Hud.RowBadge("Daily", on)
end)
BuildMode.Changed:Connect(function(active)
	SideBar.SetHidden(active)
	QuestCard.SetHidden(active)
	if active then
		Windows.Close()
		CaptureUI.Close()
	end
end)

-- Breeding music while the Breeding Center is open (Audio's MusicDirector).
local musicDirector: any = nil
pcall(function()
	musicDirector = require(Audio:WaitForChild("MusicDirector", 5) :: ModuleScript)
end)
Windows.Opened:Connect(function(name)
	if musicDirector and type(musicDirector.SetOverride) == "function" then
		pcall(musicDirector.SetOverride, if name == "Breed" then "Music_Breeding" else nil)
	end
end)

-- Context bar stays quiet during the Hatch/Feed steps and while building.
task.spawn(function()
	while true do
		ContextBar.Suppress(BuildMode.IsActive() or Tutorial.Step() < 3 or Reveal.IsBusy())
		SideBar.Badge("Breed", Nests.ReadyCount())
		task.wait(0.5)
	end
end)

-- Server -> client events
local firstData = true
Net.On("DataChanged", function(data)
	State.SetData(data)
	if firstData then
		firstData = false
		JournalWindow.Seed()
		-- Returning players (tutorial done) see the Daily screen if a reward is waiting.
		task.delay(2.5, function()
			local _, can = DailyWindow.Next()
			if can and Tutorial.Step() >= 5 and not BuildMode.IsActive() and not Reveal.IsBusy() then
				Windows.Open("Daily")
			end
		end)
	end
end)
local function toast(text: any, kind: any)
	Notify.Toast(tostring(text), if type(kind) == "string" then kind else nil)
end
Net.On("Toast", toast)
Net.On("Notify", toast)
Net.On("Announce", function(text, rarity)
	Notify.Announce(tostring(text), if type(rarity) == "string" then rarity else nil)
end)
Net.On("Reveal", function(kind, data)
	local k = string.lower(tostring(kind))
	if k == "offline" and type(data) == "table" then
		Notify.Offline(tonumber(data.coins) or 0, tonumber(data.seconds) or 0, tonumber(data.rp))
	elseif k == "levelup" and type(data) == "table" then
		Notify.Splash("Park Level " .. tostring(data.level or ""), nil)
	elseif k == "journal" and type(data) == "table" then
		Notify.Toast("New species: " .. tostring(data.species or "?") .. "!", "new")
	else
		Reveal.Show(k, data)
	end
end)
Net.On("OfflineEarnings", function(coins, seconds, rp)
	if type(coins) == "number" and coins > 0 then
		Notify.Offline(coins, if type(seconds) == "number" then seconds else 0, tonumber(rp))
	end
end)

-- Hub ProximityPrompts may open screens by name.
Net.On("OpenScreen", function(name)
	local n = tostring(name)
	if n == "Build" then
		BuildMode.Enter()
	elseif not BuildMode.IsActive() then
		Windows.Open(n)
	end
end)
