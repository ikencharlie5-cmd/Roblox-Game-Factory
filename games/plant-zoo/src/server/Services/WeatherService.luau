--!strict
-- Global weather schedule (same in every server): each 20-min cycle ends with a 4-min event.
-- Type picked by Random.new(cycle). During an event, each grown creature without a weather
-- mutation rolls once per minute. Growth boosts are applied by GrowthService.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local ItemService = require(script.Parent:WaitForChild("ItemService"))
local GrowthService = require(script.Parent:WaitForChild("GrowthService"))
local AnnounceService = require(script.Parent:WaitForChild("AnnounceService"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local WeatherService = {}

local W = Config.Weather
local chosen: { [number]: string } = {} -- cycle -> weather name (fixed once picked)

local function isNight(): boolean
	local t = Lighting.ClockTime
	return t < 6 or t >= 18
end

local function pickFor(cycle: number): string
	if chosen[cycle] then
		return chosen[cycle]
	end
	local rng = Random.new(cycle)
	local total = 0
	for _, w in W.Types do
		total += w.Weight
	end
	local name = "Rain"
	for _ = 1, 6 do
		local r = rng:NextNumber() * total
		local pick: any = W.Types[1]
		for _, w in W.Types do
			if r < w.Weight then
				pick = w
				break
			end
			r -= w.Weight
		end
		if not pick.NightOnly or isNight() then
			name = pick.Name
			break
		end
	end
	chosen[cycle] = name
	return name
end

-- Returns name ("Clear" if none), endsAt (0 if clear), nextStartAt.
function WeatherService.Current(): (string, number, number)
	local now = os.time()
	local cycle = now // W.CycleSeconds
	-- Testing hook: set ReplicatedStorage.GameState attribute ForceWeather = "Rain" etc.
	local forced = Guard.State():GetAttribute("ForceWeather")
	if type(forced) == "string" and forced ~= "" then
		return forced, (cycle + 1) * W.CycleSeconds, (cycle + 1) * W.CycleSeconds
	end
	local start = cycle * W.CycleSeconds + (W.CycleSeconds - W.DurationSeconds)
	local cycleEnd = (cycle + 1) * W.CycleSeconds
	if now >= start then
		return pickFor(cycle), cycleEnd, cycleEnd + (W.CycleSeconds - W.DurationSeconds)
	end
	return "Clear", 0, start
end

local function info(): { name: string, endsAt: number, nextAt: number }
	local name, endsAt, nextAt = WeatherService.Current()
	return { name = name, endsAt = endsAt, nextAt = nextAt }
end

local function rollMutations(name: string)
	local def: any = nil
	for _, w in W.Types do
		if w.Name == name then
			def = w
		end
	end
	if not def or not def.Mutation then
		return
	end
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			local pads: { [number]: boolean } = {}
			for _, item in data.placed do
				if (item.growTotal or 0) <= 0 and (item.weather or "None") == "None" and math.random() < def.Chance then
					DataService.Update(player, function()
						item.weather = def.Mutation
					end)
					ItemService.Upsert(player, item, "plant")
					pads[item.pad] = true
					GrowthService.MarkFound(player, item.species, def.Mutation)
					Guard.Sound(player, "Mutation")
					Guard.Notify(
						player,
						"Your " .. item.species .. " became " .. string.upper(def.Mutation) .. "!",
						"success"
					)
					if (Config.AnnounceMutations :: any)[def.Mutation] then
						local s = Config.Species.ByName[item.species]
						AnnounceService.Send(
							player.DisplayName .. " got an " .. string.upper(def.Mutation) .. " " .. item.species .. "!",
							s and s.Rarity
						)
					end
				end
			end
			for pad in pads do
				ItemService.RefreshPad(player, pad)
			end
		end
	end
end

function WeatherService.Init()
	DataService.OnLoaded(function(player)
		Remotes.Event("WeatherChanged"):FireClient(player, info())
	end)
end

function WeatherService.Start()
	local state = Guard.State()
	local lastName = ""
	local lastRoll = os.time()
	while true do
		local i = info()
		state:SetAttribute("Weather", i.name)
		state:SetAttribute("WeatherEndsAt", i.endsAt)
		state:SetAttribute("NextWeatherAt", i.nextAt)
		if i.name ~= lastName then
			lastName = i.name
			lastRoll = os.time()
			Remotes.Event("WeatherChanged"):FireAllClients(i)
			workspace:SetAttribute("Weather", if i.name == "Clear" then "" else i.name)
			if i.name ~= "Clear" then
				Remotes.Event("Notify"):FireAllClients("Weather event: " .. i.name .. "!", "weather")
			end
		end
		if i.name ~= "Clear" and os.time() - lastRoll >= W.RollEverySeconds then
			lastRoll = os.time()
			local ok, err = pcall(rollMutations, i.name)
			if not ok then
				warn("[WeatherService] roll failed:", err)
			end
		end
		task.wait(1)
	end
end

return WeatherService
