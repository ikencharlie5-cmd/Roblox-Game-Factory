--!strict
-- The ONLY place that touches DataStores. Session-cached, autosaved, saved on leave/shutdown.
-- Also owns the Total Earned OrderedDataStore (hub leaderboard).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local board = DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
local cache: { [Player]: { [string]: any } } = {}
local dirty: { [Player]: boolean } = {}
local loadedCbs: { (Player, any) -> () } = {}
local leavingCbs: { (Player, any) -> () } = {}
-- Studio only: players whose load failed (e.g. API access off) play on DefaultData, never saved.
local noSave: { [Player]: boolean } = {}
local studioWarned = false
local pendingSaves = 0
local started = false

-- Called (player, data) after data loads (runs in its own thread).
function DataService.OnLoaded(fn: (Player, any) -> ())
	table.insert(loadedCbs, fn)
end

-- Called (player, data) synchronously on leave, BEFORE the final save. Don't yield.
function DataService.OnLeaving(fn: (Player, any) -> ())
	table.insert(leavingCbs, fn)
end

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

-- Fill missing keys from defaults. Recurses ONE level into dictionaries (upgrades, potions,
-- inventory...) so new sub-keys appear, but never refills contents like inventory.seeds.
local function reconcile(data: { [string]: any }, defaults: { [string]: any }, depth: number)
	for k, v in defaults do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif depth < 1 and type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil and #v == 0 then
			reconcile(data[k], v, depth + 1)
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
	for _, entry in Config.Leaderstats do
		local v = ls:FindFirstChild(entry.Name) :: NumberValue?
		if v then
			v.Value = data[entry.Key] or 0
		end
	end
end

local function save(player: Player)
	local data = cache[player]
	if not data or noSave[player] then
		return
	end
	data.lastOnline = os.time()
	pendingSaves += 1 -- retry() pcalls each attempt, so this always gets decremented
	retry(function()
		store:SetAsync("u_" .. player.UserId, data)
		return true
	end)
	retry(function()
		board:SetAsync(tostring(player.UserId), math.floor(math.min(data.totalEarned or 0, 2 ^ 52)))
		return true
	end)
	pendingSaves -= 1
end

-- Plots/pads/jars are built by WorldService.Init; don't hand out data until they exist.
local function waitWorldReady()
	local t0 = os.clock()
	while not workspace:GetAttribute("WorldReady") and os.clock() - t0 < Config.WorldReadyTimeout do
		task.wait(0.1)
	end
	if not workspace:GetAttribute("WorldReady") then
		warn("[DataService] workspace.WorldReady not set after", Config.WorldReadyTimeout, "s; continuing")
	end
end

local function onJoin(player: Player)
	local ok, saved = retry(function()
		return store:GetAsync("u_" .. player.UserId)
	end)
	if not ok then
		if not RunService:IsStudio() then
			player:Kick("Couldn't load your data. Please rejoin.")
			return
		end
		if not studioWarned then
			studioWarned = true
			warn(
				"[DataService] DataStore unavailable in Studio (enable Game Settings > Security > "
					.. "Studio Access to API Services). Using default data; this session will NOT be saved."
			)
		end
		noSave[player] = true
		saved = nil
	end
	local data = (saved :: any) or deepCopy(Config.DefaultData)
	reconcile(data, Config.DefaultData :: any, 0)
	waitWorldReady()
	if not player.Parent then
		noSave[player] = nil
		return
	end
	cache[player] = data

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, entry in Config.Leaderstats do
		local v = Instance.new("NumberValue")
		v.Name = entry.Name
		v.Parent = ls
	end
	ls.Parent = player
	syncLeaderstats(player, data)
	Remotes.Event("DataChanged"):FireClient(player, data)
	for _, fn in loadedCbs do
		task.spawn(fn, player, data)
	end
end

-- Returns the live data table (read-only use) or nil if not loaded.
function DataService.Get(player: Player): { [string]: any }?
	return cache[player]
end

-- Yields until the player's data is loaded (or they leave).
function DataService.WaitFor(player: Player): { [string]: any }?
	while not cache[player] and player.Parent do
		task.wait(0.1)
	end
	return cache[player]
end

-- All writes go through here so leaderstats + client stay in sync (client sync is batched).
function DataService.Update(player: Player, fn: (data: { [string]: any }) -> ())
	local data = cache[player]
	if not data then
		return
	end
	fn(data)
	syncLeaderstats(player, data)
	dirty[player] = true
end

-- For per-second internal bookkeeping (jar fill, growth shifts) that the client
-- doesn't need instantly; saved normally, synced on the next real Update.
function DataService.UpdateQuiet(player: Player, fn: (data: { [string]: any }) -> ())
	local data = cache[player]
	if data then
		fn(data)
	end
end

function DataService.AddCash(player: Player, amount: number, earned: boolean?)
	DataService.Update(player, function(d)
		d.cash += amount
		if earned then
			d.totalEarned += amount
		end
	end)
end

function DataService.TrySpend(player: Player, amount: number): boolean
	local data = cache[player]
	if not data or amount < 0 or data.cash < amount then
		return false
	end
	DataService.Update(player, function(d)
		d.cash -= amount
	end)
	return true
end

function DataService.TrySpendHope(player: Player, amount: number): boolean
	local data = cache[player]
	if not data or amount < 0 or data.hope < amount then
		return false
	end
	DataService.Update(player, function(d)
		d.hope -= amount
	end)
	return true
end

function DataService.NewId(player: Player): number
	local data = cache[player]
	assert(data, "data not loaded")
	local id = data.nextId
	data.nextId += 1
	return id
end

-- Top N of Total Earned: { {userId, value} }. Yields; call from a loop.
function DataService.GetTopEarned(n: number): { { userId: number, value: number } }
	local out = {}
	local ok, pages = pcall(function()
		return board:GetSortedAsync(false, n)
	end)
	if ok and pages then
		for _, entry in (pages :: any):GetCurrentPage() do
			table.insert(out, { userId = tonumber(entry.key) or 0, value = entry.value })
		end
	end
	return out
end

local function startLoading()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end
end

-- Players are loaded from Start() (after every Service's Init, incl. WorldService's build),
-- so every OnLoaded hook is registered and the plots exist before the first player loads.
function DataService.Init()
	Players.PlayerRemoving:Connect(function(p)
		if cache[p] then
			for _, fn in leavingCbs do
				local ok, err = pcall(fn, p, cache[p])
				if not ok then
					warn("[DataService] leaving callback failed:", err)
				end
			end
		end
		save(p)
		cache[p] = nil
		dirty[p] = nil
		noSave[p] = nil
	end)
	game:BindToClose(function()
		for _, p in Players:GetPlayers() do
			task.spawn(save, p)
		end
		-- wait for every in-flight save (leave saves included), up to the timeout
		local t0 = os.clock()
		task.wait()
		while pendingSaves > 0 and os.clock() - t0 < Config.ShutdownSaveTimeout do
			task.wait(0.2)
		end
	end)
end

function DataService.Start()
	startLoading()
	task.spawn(function()
		while true do
			task.wait(Config.DataSyncInterval)
			for p in dirty do
				dirty[p] = nil
				local d = cache[p]
				if d and p.Parent then
					Remotes.Event("DataChanged"):FireClient(p, d)
				end
			end
		end
	end)
	while true do
		task.wait(Config.AutosaveSeconds)
		for _, p in Players:GetPlayers() do
			task.spawn(save, p)
		end
	end
end

return DataService
