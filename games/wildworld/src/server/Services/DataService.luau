--!strict
-- The ONLY place that touches DataStores. Session-locked (UpdateAsync + lock {job, t}),
-- autosave every 60 s, saved on leave + BindToClose, lock released on leave.
-- A server that lost its lock never overwrites newer data. Also owns the Top Parks OrderedDataStore.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataSchema = require(script.Parent:WaitForChild("DataSchema"))

local DataService = {}

local storeOk, storeOrErr = pcall(function()
	return DataStoreService:GetDataStore(Config.DataStoreName)
end)
local boardOk, boardOrErr = pcall(function()
	return DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
end)
local store: any = if storeOk then storeOrErr else nil
local board: any = if boardOk then boardOrErr else nil
if not storeOk then
	warn("[DataService] DataStores unavailable:", storeOrErr)
end

local JOB = if game.JobId ~= "" then game.JobId else "studio-" .. tostring(math.random(1, 1e9))
local cache: { [Player]: { [string]: any } } = {}
local dirty: { [Player]: boolean } = {}
local noSave: { [Player]: boolean } = {}
local lockLost: { [Player]: boolean } = {}
local leaving: { [Player]: boolean } = {} -- final save started: autosave must not re-take the lock
local loadedCbs: { { fn: (Player, any) -> (), p: number } } = {}
local leavingCbs: { (Player, any) -> () } = {}
local pendingSaves = 0
local started = false

local function key(player: Player): string
	return "u_" .. player.UserId
end

-- Called (player, data) after load, in priority order (lower first), sequentially in one thread.
function DataService.OnLoaded(fn: (Player, any) -> (), priority: number?)
	table.insert(loadedCbs, { fn = fn, p = priority or 100 })
	table.sort(loadedCbs, function(a, b)
		return a.p < b.p
	end)
end

-- Called (player, data) synchronously on leave BEFORE the final save. Don't yield.
function DataService.OnLeaving(fn: (Player, any) -> ())
	table.insert(leavingCbs, fn)
end

local function lockedByOther(old: any): boolean
	local lock = type(old) == "table" and old.lock or nil
	return type(lock) == "table"
		and lock.job ~= JOB
		and type(lock.t) == "number"
		and os.time() - lock.t < Config.SessionLockStaleSeconds
end

-- One UpdateAsync write. Returns true when written (or nothing to write).
local function save(player: Player, release: boolean): boolean
	local data = cache[player]
	if not data or noSave[player] or not store then
		return true
	end
	if lockLost[player] then
		return false -- not saved: receipts must not be granted (another server owns the profile)
	end
	if leaving[player] and not release then
		return true
	end
	data.lastSeen = os.time()
	pendingSaves += 1
	local written = false
	for attempt = 1, 4 do
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(old)
				if leaving[player] and not release then
					return nil -- autosave finishing after leave must not re-write the lock
				end
				if lockedByOther(old) then
					lockLost[player] = true
					return nil -- another server owns this profile now: never overwrite it
				end
				data.lock = if release then nil else { job = JOB, t = os.time() }
				return data
			end)
		end)
		if ok then
			written = true
			break
		end
		warn("[DataService] save attempt", attempt, "failed for", player.UserId, err)
		task.wait(attempt)
	end
	if lockLost[player] then
		written = false
		warn("[DataService] session lock lost for", player.UserId, "- stopped saving this session")
	end
	if written and board and type(data.bestRating) == "number" then
		pcall(function()
			board:SetAsync(tostring(player.UserId), math.floor(data.bestRating))
		end)
	end
	pendingSaves -= 1
	return written
end

local function load(player: Player): (string, any)
	-- returns "ok", data | "locked" | "error"
	for _ = 1, Config.SessionLockRetries do
		local blocked = false
		local ok, result = pcall(function()
			return store:UpdateAsync(key(player), function(old)
				if lockedByOther(old) then
					blocked = true
					return nil
				end
				blocked = false
				local d = if type(old) == "table" then old else DataSchema.New()
				d.lock = { job = JOB, t = os.time() }
				return d
			end)
		end)
		if ok and not blocked then
			return "ok", result
		end
		if not ok then
			warn("[DataService] load failed:", result)
		end
		if not player.Parent then
			return "error", nil
		end
		task.wait(Config.SessionLockRetryWait)
	end
	return "error", nil
end

local function onJoin(player: Player)
	local data: any = nil
	if store then
		local status, result = load(player)
		if status == "ok" then
			data = result
		end
	end
	if not data then
		if store and not RunService:IsStudio() then
			player:Kick("Your park is still saving on another server or couldn't load. Please rejoin in a minute.")
			return
		end
		warn("[DataService] Studio / no DataStore access: using default data, NOT saved this session.")
		noSave[player] = true
		data = DataSchema.New()
	end
	data = DataSchema.Fix(data)
	local t0 = os.clock()
	while not workspace:GetAttribute("WorldReady") and os.clock() - t0 < Config.WorldReadyTimeout do
		task.wait(0.1)
	end
	if not player.Parent then
		-- left while loading: release the lock we just took
		cache[player] = data
		save(player, true)
		cache[player] = nil
		noSave[player] = nil
		return
	end
	cache[player] = data

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, entry in Config.Leaderstats do
		local v = Instance.new("NumberValue")
		v.Name = entry.Name
		v.Value = data[entry.Key] or 0
		v.Parent = ls
	end
	ls.Parent = player
	for _, cb in loadedCbs do
		local ok, err = pcall(cb.fn, player, data)
		if not ok then
			warn("[DataService] OnLoaded callback failed:", err)
		end
	end
	player:SetAttribute("DataLoaded", true)
	Remotes.Event("DataChanged"):FireClient(player, data)
end

function DataService.Get(player: Player): { [string]: any }?
	return cache[player]
end

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
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		for _, entry in Config.Leaderstats do
			local v = ls:FindFirstChild(entry.Name) :: NumberValue?
			if v then
				v.Value = data[entry.Key] or 0
			end
		end
	end
	dirty[player] = true
end

function DataService.AddCoins(player: Player, amount: number, earned: boolean?)
	if amount ~= amount or amount <= 0 then
		return
	end
	DataService.Update(player, function(d)
		d.coins += amount
		if earned then
			d.totalEarned += amount
		end
	end)
end

function DataService.TrySpend(player: Player, amount: number): boolean
	local data = cache[player]
	if not data or amount ~= amount or amount < 0 or data.coins < amount then
		return false
	end
	DataService.Update(player, function(d)
		d.coins -= amount
	end)
	return true
end

function DataService.TrySpendRP(player: Player, amount: number): boolean
	local data = cache[player]
	if not data or amount ~= amount or amount < 0 or data.rp < amount then
		return false
	end
	DataService.Update(player, function(d)
		d.rp -= amount
	end)
	return true
end

-- Unique id string with a prefix ("c" creature, "e" egg) or number (prefix nil, plot items).
function DataService.NewId(player: Player, prefix: string?): any
	local data = cache[player]
	assert(data, "data not loaded")
	local id = data.nextId
	data.nextId += 1
	return if prefix then prefix .. tostring(id) else id
end

-- Saves immediately (used after Robux purchases so they can't be lost). Yields.
function DataService.SaveNow(player: Player): boolean
	return save(player, false)
end

-- Top N park ratings: { {userId, value} }. Yields.
function DataService.GetTopParks(n: number): { { userId: number, value: number } }
	local out = {}
	if not board then
		return out
	end
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

function DataService.Init()
	Players.PlayerRemoving:Connect(function(p)
		if cache[p] and not leaving[p] then
			for _, fn in leavingCbs do
				local ok, err = pcall(fn, p, cache[p])
				if not ok then
					warn("[DataService] leaving callback failed:", err)
				end
			end
		end
		leaving[p] = true
		save(p, true)
		cache[p] = nil
		dirty[p] = nil
		noSave[p] = nil
		lockLost[p] = nil
		leaving[p] = nil
	end)
	game:BindToClose(function()
		for _, p in Players:GetPlayers() do
			if cache[p] and not leaving[p] then
				for _, fn in leavingCbs do
					pcall(fn, p, cache[p])
				end
				leaving[p] = true
				task.spawn(save, p, true)
			end
		end
		local t0 = os.clock()
		task.wait()
		while pendingSaves > 0 and os.clock() - t0 < Config.ShutdownSaveTimeout do
			task.wait(0.2)
		end
	end)
end

function DataService.Start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(onJoin)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end
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
			task.spawn(save, p, false)
		end
	end
end

return DataService
