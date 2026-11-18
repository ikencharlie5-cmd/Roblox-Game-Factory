--!strict
-- Social: VisitPlot / ReturnHome teleports, LikePark (+1 park rating per unique visitor per day,
-- cap Config.Economy.LikeBonusCap), Top Parks (this server + global best rating board from DataService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local Guard = require(script.Parent:WaitForChild("Guard"))
local Signals = require(script.Parent:WaitForChild("Signals"))
local World = require(script.Parent.Parent:WaitForChild("World")) -- Graphics builder (cached; Main runs Init)

local VisitService = {}

local visited: { [Player]: { [number]: number } } = {} -- visitor -> ownerId -> os.clock()
local names: { [number]: string } = {}
local globalTop: { any } = {}

local function ownerFromId(userId: any): Player?
	if not Guard.IsInt(userId, 1, 2 ^ 53) then
		return nil
	end
	local p = Players:GetPlayerByUserId(userId)
	return if p and PlotService.GetPlot(p) then p else nil
end

local function visit(player: Player, _data: any, userId: any)
	local owner = ownerFromId(userId)
	if not owner then
		return Guard.Fail(player, "That park isn't in this server")
	end
	local plot = PlotService.GetPlot(owner) :: number
	PlotService.TeleportTo(player, plot)
	if owner ~= player then
		local v = visited[player] or {}
		visited[player] = v
		v[owner.UserId] = os.clock()
		Guard.Toast(owner, player.DisplayName .. " is visiting your park!", "info")
		Signals.Fire("Visit", player, owner.UserId)
	end
	return true, plot
end

local function like(player: Player, _data: any, userId: any)
	local owner = ownerFromId(userId)
	if not owner or owner == player then
		return false, "Bad request"
	end
	local plot = PlotService.GetPlot(owner) :: number
	local root = Guard.RootPos(player)
	local v = visited[player] and visited[player][owner.UserId]
	local onPlot = root ~= nil and PlotService.IsOnPlot(plot, root)
	if not onPlot and not (v and os.clock() - v < Config.Visits.VisitMemorySeconds) then
		return Guard.Fail(player, "Visit the park first")
	end
	local od = DataService.Get(owner)
	if not od then
		return false, "Bad request"
	end
	local today = Formulas.Day()
	local key = tostring(player.UserId)
	if od.likes.day == today and od.likes.by[key] then
		return Guard.Fail(player, "You already liked this park today")
	end
	DataService.Update(owner, function(d)
		if d.likes.day ~= today then
			d.likes = { day = today, by = {}, count = 0 }
		end
		d.likes.by[key] = true
		d.likes.count += 1
		d.stats.likes += 1
	end)
	PlotService.Queue(owner)
	Guard.Toast(owner, player.DisplayName .. " liked your park! +1 rating", "success")
	Guard.Sound(owner, "Like")
	Guard.Sound(player, "Like")
	return true, od.likes.count
end

local function nameOf(userId: number): string
	local n = names[userId]
	if n then
		return n
	end
	local ok, res = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	n = if ok and type(res) == "string" then res else "Explorer"
	names[userId] = n
	return n
end

local function top(_player: Player, _data: any)
	local server = {}
	for _, p in Players:GetPlayers() do
		local d = DataService.Get(p)
		if PlotService.GetPlot(p) and d then
			table.insert(server, {
				userId = p.UserId,
				name = p.DisplayName,
				rating = p:GetAttribute("ParkRating") or 0,
				tier = p:GetAttribute("ParkTier") or "Poor",
				likes = if d.likes.day == Formulas.Day() then d.likes.count else 0,
			})
		end
	end
	table.sort(server, function(a, b)
		return a.rating > b.rating
	end)
	return true, { server = server, global = globalTop }
end

function VisitService.Init()
	Guard.Bind("VisitPlot", visit)
	Guard.Bind("LikePark", like)
	Guard.Bind("ReturnHome", function(player)
		local plot = PlotService.GetPlot(player)
		if not plot then
			return false, "Bad request"
		end
		PlotService.TeleportTo(player, plot)
		return true, plot
	end)
	Guard.Bind("GetTopParks", top)
	Players.PlayerRemoving:Connect(function(p)
		visited[p] = nil
	end)
end

-- Hub "Top Parks" board (World.SetTopParks): global board, else this server.
local function updateBoard()
	local mod = World :: any
	if not mod.SetTopParks then
		return
	end
	local rows = {}
	if #globalTop > 0 then
		for i = 1, math.min(5, #globalTop) do
			table.insert(rows, { globalTop[i].name, globalTop[i].rating })
		end
	else
		local _, res = top(nil :: any, nil)
		for i = 1, math.min(5, #res.server) do
			table.insert(rows, { res.server[i].name, res.server[i].rating })
		end
	end
	pcall(mod.SetTopParks, rows)
end

function VisitService.Start()
	local lastGlobal = -math.huge
	while true do
		if os.clock() - lastGlobal > 120 then
			lastGlobal = os.clock()
			local list = {}
			for _, e in DataService.GetTopParks(10) do
				table.insert(list, { userId = e.userId, name = nameOf(e.userId), rating = e.value })
			end
			globalTop = list
		end
		updateBoard()
		task.wait(30)
	end
end

return VisitService
