--!strict
-- First-60-seconds tutorial chain (flags.tutorialStep) + 3 daily quests (UTC day) with rerolls.
-- Progress comes from Signals: Hatch, Feed, Pet, Place, Catch, Breed, Bait, Visit, Earn.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))

local QuestService = {}

local rng = Random.new()

local function poolDef(id: string): any?
	for _, q in Config.Quests.Pool do
		if q.Id == id then
			return q
		end
	end
	return nil
end

local function pickNew(exclude: { [string]: boolean }): string
	local options = {}
	for _, q in Config.Quests.Pool do
		if not exclude[q.Id] then
			table.insert(options, q.Id)
		end
	end
	if #options == 0 then
		return Config.Quests.Pool[1].Id
	end
	return options[rng:NextInteger(1, #options)]
end

-- New quest list when the UTC day changes.
local function ensureDay(player: Player, data: any)
	local today = Formulas.Day()
	if data.quests.day == today and #data.quests.list == Config.Quests.PerDay then
		return
	end
	DataService.Update(player, function(d)
		local used: { [string]: boolean } = {}
		local list = {}
		for _ = 1, Config.Quests.PerDay do
			local id = pickNew(used)
			used[id] = true
			table.insert(list, { id = id, progress = 0, claimed = false })
		end
		d.quests = { day = today, list = list, rerolls = 0 }
	end)
end

local function setTutorialAttr(player: Player, data: any)
	local step = data.flags.tutorialStep
	player:SetAttribute("TutorialStep", step)
	local def = Config.Tutorial[step]
	player:SetAttribute("TutorialText", if def then def.Text else "")
end

local function progress(player: Player, kind: string, amount: number, extra: any?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	-- tutorial
	local step = data.flags.tutorialStep
	local tdef = Config.Tutorial[step]
	if tdef and tdef.Kind == kind and (not tdef.ItemKind or tdef.ItemKind == extra) then
		DataService.Update(player, function(d)
			d.flags.tutorialStep = step + 1
		end)
		setTutorialAttr(player, data)
		Guard.Sound(player, "QuestComplete")
		if tdef.Coins > 0 then
			task.delay(1, function()
				if player.Parent then
					EconomyService.VisitorTip(player, tdef.Coins)
				end
			end)
		end
		local nextDef = Config.Tutorial[step + 1]
		Guard.Reveal(player, "Tutorial", { step = step + 1, text = if nextDef then nextDef.Text else "" })
	end
	-- daily quests
	ensureDay(player, data)
	local changed = false
	for _, q in data.quests.list do
		local def = poolDef(q.id)
		if def and def.Kind == kind and not q.claimed and q.progress < def.Target then
			q.progress = math.min(def.Target, q.progress + amount)
			changed = true
			if q.progress >= def.Target then
				Guard.Toast(player, "Quest done: " .. def.Text .. " - claim it!", "reward")
				Guard.Sound(player, "QuestReady")
			end
		end
	end
	if changed then
		DataService.Update(player, function() end)
	end
end

local function claim(player: Player, data: any, index: any)
	ensureDay(player, data)
	if not Guard.IsInt(index, 1, Config.Quests.PerDay) then
		return false, "Bad request"
	end
	local q = data.quests.list[index]
	local def = q and poolDef(q.id)
	if not q or not def then
		return false, "Bad request"
	end
	if q.claimed then
		return Guard.Fail(player, "Already claimed")
	end
	if q.progress < def.Target then
		return Guard.Fail(player, "Not finished yet")
	end
	DataService.Update(player, function(d)
		q.claimed = true
		d.coins += def.Coins
		d.rp += def.RP
	end)
	Guard.Sound(player, "QuestComplete")
	Guard.Toast(player, "+" .. def.Coins .. " coins, +" .. def.RP .. " RP", "reward")
	Signals.Fire("QuestDone", player, q.id)
	return true, { coins = def.Coins, rp = def.RP }
end

local function reroll(player: Player, data: any, index: any)
	ensureDay(player, data)
	if not Guard.IsInt(index, 1, Config.Quests.PerDay) then
		return false, "Bad request"
	end
	local allowed = Config.Quests.BaseRerolls
		+ (if MonetizationService.HasPass(player, "VIP") then Config.Quests.VipRerolls else 0)
	if data.quests.rerolls >= allowed then
		return Guard.Fail(player, "No rerolls left today")
	end
	local q = data.quests.list[index]
	if not q or q.claimed then
		return Guard.Fail(player, "Can't reroll that quest")
	end
	local used: { [string]: boolean } = {}
	for _, other in data.quests.list do
		used[other.id] = true
	end
	DataService.Update(player, function(d)
		d.quests.list[index] = { id = pickNew(used), progress = 0, claimed = false }
		d.quests.rerolls += 1
	end)
	return true, data.quests.list[index]
end

function QuestService.Init()
	PlotService.OnAssigned(function(player, _plot, data)
		ensureDay(player, data)
		setTutorialAttr(player, data)
	end, 70)
	local simple = { "Hatch", "Feed", "Pet", "Catch", "Breed", "Bait", "Visit" }
	for _, kind in simple do
		Signals.On(kind, function(p)
			progress(p, kind, 1)
		end)
	end
	Signals.On("Place", function(p, _id, itemKind)
		progress(p, "Place", 1, itemKind)
	end)
	Signals.On("Earn", function(p, amount)
		progress(p, "Earn", amount)
	end)
	Guard.Bind("ClaimQuest", claim)
	Guard.Bind("RerollQuest", reroll)
end

function QuestService.Start()
	while true do
		task.wait(60)
		for _, p in Players:GetPlayers() do
			local d = DataService.Get(p)
			if d then
				ensureDay(p, d)
			end
		end
	end
end

return QuestService
