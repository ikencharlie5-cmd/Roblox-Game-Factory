--!strict
-- 7-day daily reward streak (UTC days). Missing a day resets to day 1; after day 7 it loops.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local DailyRewardService = {}

local function randomOfRarity(rarity: string): string
	local bucket = Config.Species.ByRarity[rarity]
	return bucket[math.random(1, #bucket)].Name
end

-- Which streak day (1..7) the next claim would be, and whether it's claimable now.
function DailyRewardService.Next(data: any): (number, boolean)
	local today = Formulas.Day(os.time())
	local last = data.daily.last or 0
	if last == today then
		return data.daily.streak, false
	end
	if last == today - 1 then
		return (data.daily.streak % #Config.Daily.Rewards) + 1, true
	end
	return 1, true
end

-- ClaimDaily() -> (ok, { day, text })
local function claim(player: Player, data: any): (boolean, any)
	local day, can = DailyRewardService.Next(data)
	if not can then
		return Guard.Fail(player, "Come back tomorrow!")
	end
	local r: any = Config.Daily.Rewards[day]
	local text = ""
	local income = (player:GetAttribute("IncomePerSec") :: number?) or 0
	DataService.Update(player, function(d)
		d.daily.last = Formulas.Day(os.time())
		d.daily.streak = day
		if r.Kind == "Income" then
			local amount = math.max(r.Min, math.floor(income * 60 * r.Minutes))
			d.cash += amount
			d.totalEarned += amount
			text = "$" .. Format.Number(amount)
		elseif r.Kind == "Hope" then
			d.hope += r.Amount
			text = r.Amount .. " Hope"
		elseif r.Kind == "LuckPotion" then
			d.potions.luck = (d.potions.luck or 0) + r.Amount
			text = r.Amount .. " Luck Potion"
		elseif r.Kind == "GrowTonic" then
			d.tonics += r.Amount
			text = r.Amount .. " Grow Tonics"
		elseif r.Kind == "Seed" then
			local species = randomOfRarity(r.Rarity)
			d.inventory.seeds[species] = (d.inventory.seeds[species] or 0) + 1
			text = r.Rarity .. " seed: " .. species
		end
	end)
	player:SetAttribute("DailyReady", false)
	Guard.Sound(player, "DailyReward")
	Guard.Notify(player, "Day " .. day .. " reward: " .. text, "success")
	return true, { day = day, text = text }
end

function DailyRewardService.Init()
	Guard.Bind("ClaimDaily", claim)
	DataService.OnLoaded(function(player, data)
		local _, can = DailyRewardService.Next(data)
		player:SetAttribute("DailyReady", can)
	end)
end

function DailyRewardService.Start()
	while true do
		task.wait(60)
		for _, p in game:GetService("Players"):GetPlayers() do
			local d = DataService.Get(p)
			if d then
				local _, can = DailyRewardService.Next(d)
				p:SetAttribute("DailyReady", can)
			end
		end
	end
end

return DailyRewardService
