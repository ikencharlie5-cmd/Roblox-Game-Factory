--!strict
-- 7-day login streak (UTC days). Missing a day resets to day 1. Day 7 = Mutation Egg
-- (random common, guaranteed Golden or Albino). Sets player attribute DailyReady.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Genetics = require(Shared:WaitForChild("Genetics"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local GeneticsService = require(script.Parent:WaitForChild("GeneticsService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local DailyRewardService = {}

local rng = Random.new()

-- Which reward day (1..7) the next claim gives, and whether it can be claimed now.
function DailyRewardService.Next(data: any): (number, boolean)
	local today = Formulas.Day()
	local last = data.daily.last or 0
	if last == today then
		return ((data.daily.streak - 1) % #Config.Daily) + 1, false
	end
	local streak = if last == today - 1 then data.daily.streak + 1 else 1
	return ((streak - 1) % #Config.Daily) + 1, true
end

local function refreshAttr(player: Player, data: any)
	local day, ready = DailyRewardService.Next(data)
	player:SetAttribute("DailyReady", ready)
	player:SetAttribute("DailyDay", day)
end

local function claim(player: Player, data: any)
	local day, ready = DailyRewardService.Next(data)
	if not ready then
		return Guard.Fail(player, "Come back tomorrow for day " .. (day % #Config.Daily) + 1 .. "!")
	end
	local today = Formulas.Day()
	local reward: any = Config.Daily[day]
	local text = {}
	DataService.Update(player, function(d)
		d.daily.streak = if d.daily.last == today - 1 then d.daily.streak + 1 else 1
		d.daily.last = today
		if reward.Coins then
			d.coins += reward.Coins
			table.insert(text, reward.Coins .. " coins")
		end
		if reward.RP then
			d.rp += reward.RP
			table.insert(text, reward.RP .. " RP")
		end
		if reward.Bait then
			for k, n in reward.Bait do
				d.bait[k] = (d.bait[k] or 0) + n
				table.insert(text, n .. " " .. k .. " Bait")
			end
		end
	end)
	if reward.MutationEgg then
		local species = Config.StarterSpecies[rng:NextInteger(1, #Config.StarterSpecies)]
		local mut = if rng:NextNumber() < 0.5 then "Golden" else "Albino"
		GeneticsService.MakeEgg(player, {
			species = species,
			genes = Genetics.Random(rng, Config.Capture.RecessiveAlleleChance),
			mutations = { mut },
			source = "daily",
		})
		table.insert(text, "a Mutation Egg!")
	end
	refreshAttr(player, data)
	Guard.Sound(player, "DailyClaim")
	Guard.Reveal(player, "Daily", { day = day, text = table.concat(text, " + "), streak = data.daily.streak })
	return true, { day = day, text = table.concat(text, " + ") }
end

function DailyRewardService.Init()
	PlotService.OnAssigned(function(player, _plot, data)
		refreshAttr(player, data)
	end, 80)
	Guard.Bind("ClaimDaily", claim)
end

function DailyRewardService.Start()
	while true do
		task.wait(60)
		for _, p in Players:GetPlayers() do
			local d = DataService.Get(p)
			if d then
				refreshAttr(p, d)
			end
		end
	end
end

return DailyRewardService
