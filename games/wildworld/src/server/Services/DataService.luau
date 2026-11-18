--!strict
-- The ONLY place that touches DataStores. Session-cached, autosaved, saved on leave/shutdown.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local cache: { [Player]: { [string]: any } } = {}
local loadedSignal = Instance.new("BindableEvent")

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end

local function reconcile(data: { [string]: any })
	for k, v in Config.DefaultData :: any do
		if data[k] == nil then
			data[k] = deepCopy(v)
		end
	end
end

local function retry<T>(fn: () -> T): (boolean, T?)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn("[DataService] attempt", attempt, "failed:", result)
		task.wait(attempt)
	end
	return false, nil
end

local function syncLeaderstats(player: Player, data: { [string]: any })
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		return
	end
	for _, key in Config.Leaderstats do
		local v = ls:FindFirstChild(key) :: NumberValue?
		if v then
			v.Value = data[key]
		end
	end
end

local function save(player: Player)
	local data = cache[player]
	if not data then
		return
	end
	retry(function()
		store:SetAsync("u_" .. player.UserId, data)
		return true
	end)
end

local function onJoin(player: Player)
	local ok, saved = retry(function()
		return store:GetAsync("u_" .. player.UserId)
	end)
	if not ok then
		player:Kick("Couldn't load your data. Please rejoin.")
		return
	end
	local data = (saved :: any) or deepCopy(Config.DefaultData)
	reconcile(data)
	if not player.Parent then
		return
	end
	cache[player] = data

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, key in Config.Leaderstats do
		local v = Instance.new("NumberValue")
		v.Name = key
		v.Parent = ls
	end
	ls.Parent = player
	syncLeaderstats(player, data)
	Remotes.Event("DataChanged"):FireClient(player, data)
	loadedSignal:Fire(player)
end

-- Returns the live data table (read-only use) or nil if not loaded.
function DataService.Get(player: Player): { [string]: any }?
	return cache[player]
end

-- Yields until the player's data is loaded (or they leave).
function DataService.WaitFor(player: Player): { [string]: any }?
	while not cache[player] and player.Parent do
		loadedSignal.Event:Wait()
	end
	return cache[player]
end

-- All writes go through here so leaderstats + client stay in sync.
function DataService.Update(player: Player, fn: (data: { [string]: any }) -> ())
	local data = cache[player]
	if not data then
		return
	end
	fn(data)
	syncLeaderstats(player, data)
	Remotes.Event("DataChanged"):FireClient(player, data)
end

function DataService.AddCash(player: Player, amount: number)
	DataService.Update(player, function(d)
		d.Cash += amount
	end)
end

function DataService.TrySpend(player: Player, amount: number): boolean
	local data = cache[player]
	if not data or amount < 0 or data.Cash < amount then
		return false
	end
	DataService.Update(player, function(d)
		d.Cash -= amount
	end)
	return true
end

function DataService.Init()
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		save(p)
		cache[p] = nil
	end)
	game:BindToClose(function()
		for _, p in Players:GetPlayers() do
			task.spawn(save, p)
		end
		task.wait(3)
	end)
end

function DataService.Start()
	while true do
		task.wait(Config.AutosaveSeconds)
		for _, p in Players:GetPlayers() do
			task.spawn(save, p)
		end
	end
end

return DataService
