--!strict
-- 6-step tutorial chain (auto-advances + auto-rewards) then 3 daily quests (ClaimQuest).
-- Other services report with QuestService.Progress(player, kind, n) / SetState(player, kind, value).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local QuestService = {}

-- Kinds where progress is a current count (not a running total).
local STATE_KINDS = { Thriving = true }

local function incomeOf(player: Player): number
	return (player:GetAttribute("IncomePerSec") :: number?) or 0
end

local function grant(player: Player, cash: number, hope: number, text: string)
	DataService.Update(player, function(d)
		d.cash += cash
		d.hope += hope
	end)
	local parts = {}
	if cash > 0 then
		table.insert(parts, "$" .. Format.Number(cash))
	end
	if hope > 0 then
		table.insert(parts, Format.Number(hope) .. " Hope")
	end
	Guard.Notify(player, "Quest done: " .. text .. "  +" .. table.concat(parts, " +"), "success")
	Guard.Sound(player, "QuestComplete")
end

local function ensureDaily(player: Player, data: any)
	local today = Formulas.Day(os.time())
	if data.quests.day == today then
		return
	end
	local pool = table.clone(Config.DailyQuests.Pool)
	local rng = Random.new(today * 7919 + player.UserId)
	local list = {}
	for _ = 1, math.min(Config.DailyQuests.PerDay, #pool) do
		local q = table.remove(pool, rng:NextInteger(1, #pool)) :: any
		local goal = q.Goal or 1
		local text = q.Text
		if q.Kind == "CollectCash" then
			goal = math.max(q.Min, math.floor(incomeOf(player) * 60 * q.Minutes))
			text = string.format(q.Text, Format.Number(goal))
		end
		table.insert(list, { kind = q.Kind, goal = goal, progress = 0, claimed = false, text = text })
	end
	DataService.Update(player, function(d)
		d.quests = { day = today, list = list }
	end)
end

local function checkTutorial(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local step = Config.Tutorial[data.tutorialStep]
	if not step then
		return
	end
	if STATE_KINDS[step.Kind] then
		local cur = (player:GetAttribute(step.Kind .. "Count") :: number?) or 0
		if cur > data.tutorialProgress then
			DataService.Update(player, function(d)
				d.tutorialProgress = cur
			end)
		end
	end
	if data.tutorialProgress >= step.Goal then
		DataService.Update(player, function(d)
			d.tutorialStep += 1
			d.tutorialProgress = 0
		end)
		player:SetAttribute("TutorialStep", data.tutorialStep)
		grant(player, step.Cash, step.Hope, step.Text)
		task.defer(checkTutorial, player) -- next step may already be satisfied
	end
end

function QuestService.Progress(player: Player, kind: string, amount: number?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local n = amount or 1
	ensureDaily(player, data)
	DataService.Update(player, function(d)
		local step = Config.Tutorial[d.tutorialStep]
		if step and step.Kind == kind and not STATE_KINDS[kind] then
			d.tutorialProgress += n
		end
		for _, q in d.quests.list do
			if q.kind == kind and not q.claimed and not STATE_KINDS[kind] then
				q.progress = math.min(q.goal, q.progress + n)
			end
		end
	end)
	checkTutorial(player)
end

function QuestService.SetState(player: Player, kind: string, value: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	ensureDaily(player, data)
	local changed = false
	for _, q in data.quests.list do
		if q.kind == kind and not q.claimed and value > q.progress then
			changed = true
		end
	end
	if changed then
		DataService.Update(player, function(d)
			for _, q in d.quests.list do
				if q.kind == kind and not q.claimed then
					q.progress = math.max(q.progress, math.min(q.goal, value))
				end
			end
		end)
	end
	checkTutorial(player)
end

function QuestService.Init()
	DataService.OnLoaded(function(player, data)
		ensureDaily(player, data)
		player:SetAttribute("TutorialStep", data.tutorialStep)
	end)

	-- ClaimQuest(index: number 1..3) -> (ok, {cash, hope})
	Guard.Bind("ClaimQuest", function(player, data, index)
		ensureDaily(player, data)
		if not Guard.IsInt(index, 1, #data.quests.list) then
			return Guard.Fail(player, "Invalid quest")
		end
		local q = data.quests.list[index]
		if q.claimed then
			return Guard.Fail(player, "Already claimed")
		end
		if q.progress < q.goal then
			return Guard.Fail(player, "Not finished yet")
		end
		local cash =
			math.max(Config.DailyQuests.CashMin, math.floor(incomeOf(player) * 60 * Config.DailyQuests.CashMinutes))
		DataService.Update(player, function(d)
			d.quests.list[index].claimed = true
		end)
		grant(player, cash, Config.DailyQuests.Hope, q.text)
		return true, { cash = cash, hope = Config.DailyQuests.Hope }
	end)
end

function QuestService.Start()
	-- Roll over daily quests at UTC midnight for everyone online.
	while true do
		task.wait(60)
		for _, p in game:GetService("Players"):GetPlayers() do
			local d = DataService.Get(p)
			if d then
				ensureDaily(p, d)
			end
		end
	end
end

return QuestService
