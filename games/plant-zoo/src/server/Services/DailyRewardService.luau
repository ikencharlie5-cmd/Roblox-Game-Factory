--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Format = require(Shared:WaitForChild("Format"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local DailyRewardService = {}

local lastCall: { [Player]: number } = {}

local function claim(player: Player)
	local now = os.time()
	if os.clock() - (lastCall[player] or 0) < Config.RemoteCooldown then
		return
	end
	lastCall[player] = os.clock()

	local data = DataService.Get(player)
	if not data then
		return
	end
	local since = now - data.LastDailyClaim
	if since < Config.Daily.CooldownSeconds then
		Remotes.Event("Notify"):FireClient(player, "Next daily in " .. Format.Time(Config.Daily.CooldownSeconds - since))
		return
	end

	local streak = if since > Config.Daily.StreakResetSeconds then 1 else data.DailyStreak + 1
	local reward = Config.Daily.BaseReward + Config.Daily.StreakBonus * (streak - 1)
	DataService.Update(player, function(d)
		d.LastDailyClaim = now
		d.DailyStreak = streak
		d.Cash += reward
	end)
	Remotes.Event("Notify"):FireClient(player, "Daily reward: +" .. Format.Number(reward) .. " (streak " .. streak .. ")")
end

function DailyRewardService.Init()
	Remotes.Event("ClaimDaily").OnServerEvent:Connect(claim)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		lastCall[p] = nil
	end)
end

return DailyRewardService
