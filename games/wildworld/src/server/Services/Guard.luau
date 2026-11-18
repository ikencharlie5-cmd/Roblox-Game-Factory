--!strict
-- Helper (not a service): binds RemoteFunctions with per-remote rate limits, loaded-data check,
-- type helpers and pcall. Handlers return (ok, result). Failures also Toast + PlaySound("Error").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local Guard = {}

local last: { [Player]: { [string]: number } } = {}
local lastSoft: { [Player]: number } = {}

Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
	lastSoft[p] = nil
end)

local function soft(player: Player, msg: string)
	local now = os.clock()
	if now - (lastSoft[player] or 0) >= 1 then
		lastSoft[player] = now
		Remotes.Event("Toast"):FireClient(player, msg, "info")
	end
end

function Guard.Toast(player: Player, text: string, kind: string?)
	Remotes.Event("Toast"):FireClient(player, text, kind or "info")
end

function Guard.Sound(player: Player, name: string, opts: any?)
	Remotes.Event("PlaySound"):FireClient(player, name, opts)
end

function Guard.Reveal(player: Player, kind: string, data: any)
	Remotes.Event("Reveal"):FireClient(player, kind, data)
end

function Guard.Fail(player: Player, msg: string): (boolean, string)
	Guard.Toast(player, msg, "error")
	Guard.Sound(player, "Error")
	return false, msg
end

function Guard.IsInt(v: any, lo: number, hi: number): boolean
	return type(v) == "number" and v == v and v % 1 == 0 and v >= lo and v <= hi
end

function Guard.IsString(v: any, maxLen: number?): boolean
	return type(v) == "string" and #v > 0 and #v <= (maxLen or 64)
end

function Guard.IsVector(v: any): boolean
	return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 1e5
end

-- Character root position or nil.
function Guard.RootPos(player: Player): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

-- ReplicatedStorage.GameState (Folder): global replicated state via Attributes.
local stateFolder: Folder? = nil
function Guard.State(): Folder
	if not stateFolder then
		local f = ReplicatedStorage:FindFirstChild("GameState") :: Folder?
		if not f then
			local nf = Instance.new("Folder")
			nf.Name = "GameState"
			nf.Parent = ReplicatedStorage
			f = nf
		end
		stateFolder = f
	end
	return stateFolder :: Folder
end

-- handler(player, data, ...) -> (ok, result)
function Guard.Bind(name: string, handler: (Player, any, ...any) -> (boolean, any))
	local limit = (Config.RemoteLimits :: any)[name] or Config.RemoteCooldown
	Remotes.Function(name).OnServerInvoke = function(player: Player, ...)
		local t = last[player]
		if not t then
			t = {}
			last[player] = t
		end
		local now = os.clock()
		if now - (t[name] or 0) < limit then
			soft(player, "Slow down!")
			return false, "Slow down!"
		end
		t[name] = now
		local data = DataService.Get(player)
		if not data then
			soft(player, "Still loading...")
			return false, "Still loading..."
		end
		local ok, a, b = pcall(handler, player, data, ...)
		if not ok then
			warn("[Guard]", name, "error:", a)
			return Guard.Fail(player, "Something went wrong")
		end
		return a, b
	end
end

-- Connects Triggered on every ProximityPrompt under instances tagged `tag` (now and later).
-- fn runs only for loaded players.
function Guard.WirePrompt(tag: string, fn: (Player, any) -> ())
	local CollectionService = game:GetService("CollectionService")
	local function hook(inst: Instance)
		for _, d in inst:GetDescendants() do
			if d:IsA("ProximityPrompt") then
				d.Triggered:Connect(function(player: Player)
					local data = DataService.Get(player)
					if data then
						fn(player, data)
					end
				end)
			end
		end
	end
	for _, inst in CollectionService:GetTagged(tag) do
		hook(inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(hook)
end

return Guard
