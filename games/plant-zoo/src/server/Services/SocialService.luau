--!strict
-- LikeZoo (once per day per zoo), hub Top-10 Total Earned board, VIP chat tag attribute.
-- Board is published as JSON in ReplicatedStorage.GameState.TopEarned (StringValue):
--   [{ rank, userId, name, value }]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local SocialService = {}

local boardValue: StringValue
local names: { [number]: string } = {}

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local name = if ok and type(n) == "string" then n else ("Player " .. userId)
	names[userId] = name
	return name
end

-- LikeZoo(plotIndex) -> (ok, ownerLikes)
local function like(player: Player, data: any, plot: any): (boolean, any)
	if not Guard.IsInt(plot, 1, Config.Grid.PlotCount) then
		return Guard.Fail(player, "Invalid zoo")
	end
	local owner = PlotService.GetOwner(plot)
	if not owner then
		return Guard.Fail(player, "Nobody owns that zoo")
	end
	if owner == player then
		return Guard.Fail(player, "You can't like your own zoo")
	end
	local today = Formulas.Day(os.time())
	local key = tostring(owner.UserId)
	if data.likedToday[key] == today then
		return Guard.Fail(player, "Already liked today")
	end
	DataService.Update(player, function(d)
		-- forget old days so the table stays small
		for k, day in d.likedToday do
			if day ~= today then
				d.likedToday[k] = nil
			end
		end
		d.likedToday[key] = today
	end)
	local likes = 0
	DataService.Update(owner, function(d)
		d.likes += 1
		likes = d.likes
	end)
	PlotService.RefreshPlotAttrs(owner)
	Guard.Sound(player, "Like")
	Guard.Notify(owner, player.DisplayName .. " liked your zoo!", "success")
	Guard.Sound(owner, "Like")
	QuestService.Progress(player, "Like", 1)
	return true, likes
end

local function refreshBoard()
	local top = DataService.GetTopEarned(10)
	local out = {}
	for i, e in top do
		table.insert(out, { rank = i, userId = e.userId, name = nameOf(e.userId), value = e.value })
	end
	boardValue.Value = HttpService:JSONEncode(out)
end

function SocialService.Init()
	boardValue = Instance.new("StringValue")
	boardValue.Name = "TopEarned"
	boardValue.Value = "[]"
	boardValue.Parent = Guard.State()

	Guard.Bind("LikeZoo", like)

	-- VIP chat tag: client TextChatService reads Player Attribute "ChatTag".
	local function applyTag(p: Player)
		p:SetAttribute("ChatTag", if p:GetAttribute("Pass_VIP") then "[VIP]" else nil)
	end
	Players.PlayerAdded:Connect(function(p)
		p:GetAttributeChangedSignal("Pass_VIP"):Connect(function()
			applyTag(p)
		end)
	end)
end

function SocialService.Start()
	while true do
		local ok, err = pcall(refreshBoard)
		if not ok then
			warn("[SocialService] leaderboard refresh failed:", err)
		end
		task.wait(60)
	end
end

return SocialService
