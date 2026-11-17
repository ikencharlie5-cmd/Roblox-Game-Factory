--!strict
-- Mirrors gameplay's ReplicatedStorage.GameState into the world: Weather attr -> sky FX,
-- TopEarned / WorldReserve JSON StringValues -> leaderboard / reserve, NextRestockAt -> Seed Shop clock.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local StateSync = {}

-- GameState bindings ---------------------------------------------------------------------------------
local function bindJson(state: Instance, name: string, fn: ({ any }) -> ())
	task.spawn(function()
		local v = state:WaitForChild(name, 120)
		if not v or not v:IsA("StringValue") then
			return
		end
		local sv = v :: StringValue
		local function apply()
			local ok, list = pcall(HttpService.JSONDecode, HttpService, sv.Value)
			if ok and typeof(list) == "table" then
				fn(list)
			end
		end
		sv.Changed:Connect(apply)
		apply()
	end)
end

local function bindGameState(setBoard: ({ any }) -> (), syncReserve: ({ any }) -> (), setWeather: (string?) -> ())
	local state = ReplicatedStorage:WaitForChild("GameState", 120)
	if not state then
		warn("[WorldService] GameState folder not found; weather/board/reserve won't sync")
		return
	end
	local function weather()
		local w = state:GetAttribute("Weather")
		setWeather(if typeof(w) == "string" and w ~= "Clear" and w ~= "" then w else nil)
	end
	state:GetAttributeChangedSignal("Weather"):Connect(weather)
	weather()
	bindJson(state, "TopEarned", setBoard)
	bindJson(state, "WorldReserve", syncReserve)
end

function StateSync.Start(
	setBoard: ({ any }) -> (),
	syncReserve: ({ any }) -> (),
	setWeather: (string?) -> (),
	clockLabel: TextLabel
)
	task.spawn(bindGameState, setBoard, syncReserve, setWeather)
	local shop = (Config :: any).Shop
	local period = (if typeof(shop) == "table" then shop.RestockSeconds else nil) or 300
	task.spawn(function()
		while true do
			local state = ReplicatedStorage:FindFirstChild("GameState")
			local nextAt = if state then state:GetAttribute("NextRestockAt") else nil
			local now = os.time()
			local left = if typeof(nextAt) == "number" and nextAt > now then nextAt - now else period - now % period
			clockLabel.Text = string.format("Restock %d:%02d", left // 60, left % 60)
			task.wait(1)
		end
	end)
end

return StateSync
