--!strict
-- Weather events every 10-15 min: Sunny (+10% income), Rain (more Pebblehorn in Mossy Hollow),
-- Rainbow Shower (x2 mutation chance when breeding). Replicated via ReplicatedStorage.GameState
-- attributes: Weather ("Clear" | name), WeatherEndsAt, NextWeatherAt (os.time()).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Guard = require(script.Parent:WaitForChild("Guard"))

local WeatherService = {}

-- Graphics' sky/atmosphere tint (optional; names without spaces: "Rain", "RainbowShower", "Sunny").
local function worldWeather(name: string?)
	-- workspace "Weather" (no spaces: "Clear" | "Sunny" | "Rain" | "RainbowShower") for Audio/Animation
	workspace:SetAttribute("Weather", if name then (string.gsub(name, " ", "")) else "Clear")
	local ws = script.Parent:FindFirstChild("WorldService")
	if ws then
		local ok, mod = pcall(require, ws)
		if ok and mod.SetWeather then
			pcall(mod.SetWeather, if name then (string.gsub(name, " ", "")) else nil)
		end
	end
end

local rng = Random.new()

local function pick(): any
	local total = 0
	for _, k in Config.Weather.Kinds do
		total += k.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, k in Config.Weather.Kinds do
		roll -= k.Weight
		if roll <= 0 then
			return k
		end
	end
	return Config.Weather.Kinds[1]
end

local function announce(text: string)
	for _, p in Players:GetPlayers() do
		Guard.Toast(p, text, "weather")
	end
end

function WeatherService.Current(): string
	return (Guard.State():GetAttribute("Weather") :: string?) or "Clear"
end

function WeatherService.Init()
	local s = Guard.State()
	s:SetAttribute("Weather", "Clear")
	s:SetAttribute("WeatherEndsAt", 0)
	workspace:SetAttribute("Weather", "Clear")
end

function WeatherService.Start()
	local s = Guard.State()
	while true do
		local gap = rng:NextInteger(Config.Weather.MinGap, Config.Weather.MaxGap)
		s:SetAttribute("NextWeatherAt", os.time() + gap)
		task.wait(gap)
		local k = pick()
		s:SetAttribute("Weather", k.Name)
		s:SetAttribute("WeatherEndsAt", os.time() + k.Seconds)
		worldWeather(k.Name)
		announce(if k.Name == "Rainbow Shower"
			then "A Rainbow Shower! Mutation chances x2 while it lasts!"
			elseif k.Name == "Rain" then "Rain in the forest: Pebblehorns are out in Mossy Hollow!"
			else "Sunny skies: +10% visitor coins!")
		for _, p in Players:GetPlayers() do
			Guard.Sound(p, "Weather_" .. (string.gsub(k.Name, " ", "")))
		end
		task.wait(k.Seconds)
		s:SetAttribute("Weather", "Clear")
		s:SetAttribute("WeatherEndsAt", 0)
		worldWeather(nil)
		for _, p in Players:GetPlayers() do
			Guard.Sound(p, "WeatherClear")
		end
	end
end

return WeatherService
