--!strict
-- Helper (not a real service): binds RemoteFunctions with rate-limit, loaded-data check,
-- and pcall. Handlers return (ok, result). Failures also Notify + play "Error".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local Guard = {}

local last: { [Player]: { [string]: number } } = {}

Players.PlayerRemoving:Connect(function(p)
	last[p] = nil
end)

function Guard.Notify(player: Player, text: string, kind: string?)
	Remotes.Event("Notify"):FireClient(player, text, kind or "info")
end

function Guard.Sound(player: Player, name: string, extra: any?)
	Remotes.Event("PlaySound"):FireClient(player, name, extra)
end

function Guard.Fail(player: Player, msg: string): (boolean, string)
	Guard.Notify(player, msg, "error")
	Guard.Sound(player, "Error")
	return false, msg
end

function Guard.IsInt(v: any, lo: number, hi: number): boolean
	return type(v) == "number" and v == v and v % 1 == 0 and v >= lo and v <= hi
end

function Guard.IsString(v: any, maxLen: number?): boolean
	return type(v) == "string" and #v <= (maxLen or 64)
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
	Remotes.Function(name).OnServerInvoke = function(player: Player, ...)
		local t = last[player]
		if not t then
			t = {}
			last[player] = t
		end
		local now = os.clock()
		if now - (t[name] or 0) < Config.RemoteCooldown then
			return false, "Slow down!"
		end
		t[name] = now
		local data = DataService.Get(player)
		if not data then
			return false, "Still loading..."
		end
		local ok, a, b = pcall(handler, player, data, ...)
		if not ok then
			warn("[Guard]", name, "error:", a)
			return false, "Something went wrong"
		end
		return a, b
	end
end

return Guard
