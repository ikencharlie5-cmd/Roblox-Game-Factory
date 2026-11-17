--!strict
-- Picks the music track + ambience loops from where the player is, weather and time of day.
-- Owned by the Audio department. Started by SoundController.Start().
--
-- World contract (all optional, see notes/audio.md):
--   Zone:    within HUB_RADIUS of the origin = Hub, else Plot. Near a `ReleaseAltar` tagged part = Reserve.
--   Biome:   nearest `ExhibitPad` tagged part within PAD_RANGE; Attribute `Biome` (default "Meadow").
--   Weather: workspace Attribute `Weather` (string, "" / "None" / nil = clear) OR the
--            `WeatherChanged` remote (arg = weather name, or a table with Name/name/Kind/Type/Id).
--   Night:   Lighting.ClockTime < 6 or >= 18 (or workspace Attribute `IsNight`).
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundsModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local HUB_RADIUS = 80
local RESERVE_RANGE = 40
local PAD_RANGE = 22
local TICK = 0.5

type Controller = {
	Play: (name: string, pitch: number?) -> (),
	PlayMusic: (name: string?) -> (),
	SetAmbience: (channel: string, name: string?) -> (),
}

local MusicDirector = {}

local weather: string? = nil
local zoneOverride: string? = nil

local function normalizeWeather(v: any): string?
	if type(v) == "table" then
		v = v.Name or v.name or v.Kind or v.Type or v.Id or v.Weather
	end
	if type(v) ~= "string" or v == "" or v == "None" or v == "Clear" then
		return nil
	end
	return (v:gsub("%s", ""))
end

local function isNight(): boolean
	local attr = workspace:GetAttribute("IsNight")
	if type(attr) == "boolean" then
		return attr
	end
	local t = Lighting.ClockTime
	return t < 6 or t >= 18
end

local function rootPos(): Vector3?
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function partPos(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

local function nearestTagged(tag: string, pos: Vector3, range: number): Instance?
	local best: Instance? = nil
	local bestD = range
	for _, inst in CollectionService:GetTagged(tag) do
		local p = partPos(inst)
		if p then
			local d = (Vector3.new(p.X, pos.Y, p.Z) - pos).Magnitude
			if d < bestD then
				bestD = d
				best = inst
			end
		end
	end
	return best
end

local function zoneAt(pos: Vector3): string
	if zoneOverride then
		return zoneOverride
	end
	if nearestTagged("ReleaseAltar", pos, RESERVE_RANGE) then
		return "Reserve"
	end
	if Vector3.new(pos.X, 0, pos.Z).Magnitude <= HUB_RADIUS then
		return "Hub"
	end
	return "Plot"
end

local function update(ctl: Controller)
	local pos = rootPos()
	local zone = if pos then zoneAt(pos) else "Hub"
	local music: string
	if weather then
		music = SoundsModule.Music.Weather
	elseif zone == "Reserve" then
		music = SoundsModule.Music.Reserve
	elseif zone == "Plot" and isNight() then
		music = SoundsModule.Music.Night
	else
		music = SoundsModule.Music[zone] or SoundsModule.Music.Hub
	end
	ctl.PlayMusic(music)

	-- Biome ambience: nearest pad on plots, birds in hub/reserve.
	local amb: string? = SoundsModule.BiomeAmbience.Meadow
	if pos and zone == "Plot" then
		local pad = nearestTagged("ExhibitPad", pos, PAD_RANGE)
		if pad then
			local biome = pad:GetAttribute("Biome")
			local key = if type(biome) == "string" then biome else "Meadow"
			amb = SoundsModule.BiomeAmbience[key] or SoundsModule.BiomeAmbience.Meadow
		end
	end
	ctl.SetAmbience("biome", amb)
	ctl.SetAmbience("weather", if weather and SoundsModule.RainyWeather[weather] then "AmbRain" else nil)
end

local function setWeather(ctl: Controller, v: any)
	local w = normalizeWeather(v)
	if w == weather then
		return
	end
	weather = w
	if w then
		local sting = SoundsModule.WeatherStart[w]
		if sting then
			ctl.Play(sting)
		end
	end
	update(ctl)
end

-- Force a zone ("Hub" | "Plot" | "Reserve"), nil = automatic.
function MusicDirector.SetZone(zone: string?)
	zoneOverride = zone
end

function MusicDirector.Start(ctl: Controller)
	weather = normalizeWeather(workspace:GetAttribute("Weather"))
	workspace:GetAttributeChangedSignal("Weather"):Connect(function()
		setWeather(ctl, workspace:GetAttribute("Weather"))
	end)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Remotes")
		local ev = folder:WaitForChild("WeatherChanged", 15)
		if ev and ev:IsA("RemoteEvent") then
			ev.OnClientEvent:Connect(function(v: any)
				setWeather(ctl, v)
			end)
		end
	end)
	task.spawn(function()
		while true do
			update(ctl)
			task.wait(TICK)
		end
	end)
end

return MusicDirector
