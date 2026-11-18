--!strict
-- Lighting, Atmosphere, Sky, post FX, 12-minute day/night cycle, weather visuals.
-- Sets Lighting attribute "IsNight" (ClockTime >= 18 or < 6, same rule as gameplay WeatherService).
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("Config"))
local Build = require(script.Parent.Build)

local Sky = {}

local atmosphere: Atmosphere
local weatherCC: ColorCorrectionEffect
local weatherParts: { BasePart } = {}
local currentWeather: string? = nil
local isNight = false

local function inst(className: string, props: { [string]: any }): Instance
	local existing = Lighting:FindFirstChildOfClass(className)
	local i = existing or Instance.new(className)
	for k, v in props do
		(i :: any)[k] = v
	end
	i.Parent = Lighting
	return i
end

-- Day look (ART_STYLE_GUIDE §2). Technology = Future is set in default.project.json (not scriptable).
local DAY_AMBIENT = Color3.fromRGB(140, 140, 148)
local DAY_OUTDOOR = Color3.fromRGB(133, 133, 143)
local NIGHT_AMBIENT = Color3.fromHex("#5A6A9A")
local NIGHT_OUTDOOR = Color3.fromHex("#4A5A8C")
local DAY_DENSITY = 0.22

function Sky.Setup(areas: { Vector3 })
	Lighting.Brightness = 3
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 35
	Lighting.Ambient = DAY_AMBIENT
	Lighting.OutdoorAmbient = DAY_OUTDOOR
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.ShadowSoftness = 0.25
	Lighting.GlobalShadows = true
	atmosphere = inst("Atmosphere", {
		Density = DAY_DENSITY,
		Offset = 0.3,
		Color = Theme.Colors.Sky,
		Decay = Color3.fromHex("#FFE3C4"),
		Glare = 0.25,
		Haze = 1.2,
	}) :: Atmosphere
	-- Asset hook: a Sky instance at ReplicatedStorage.Assets.Sky (cartoon skybox) replaces the default.
	local skyAsset = Theme.Assets.Folder("Sky")
	if skyAsset and skyAsset:IsA("Sky") then
		local old = Lighting:FindFirstChildOfClass("Sky")
		if old then
			old:Destroy()
		end
		skyAsset:Clone().Parent = Lighting
	end
	inst("Sky", { StarCount = 3000, SunAngularSize = 14, MoonAngularSize = 9, CelestialBodiesShown = true })
	inst("BloomEffect", { Intensity = 0.4, Size = 24, Threshold = 1.6 })
	inst("SunRaysEffect", { Intensity = 0.06, Spread = 0.55 })
	inst("ColorCorrectionEffect", {
		Saturation = 0.25,
		Contrast = 0.1,
		Brightness = 0.03,
		TintColor = Color3.fromHex("#FFF8EC"),
	})
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "WeatherCC"
	cc.Parent = Lighting
	weatherCC = cc
	local folder = Build.Folder(Workspace:WaitForChild("World"), "WeatherFX")
	for _, pos in areas do
		local p = Build.Deco(folder, {
			Size = Vector3.new(110, 1, 110),
			CFrame = CFrame.new(pos + Vector3.new(0, 50, 0)),
			Transparency = 1,
			Name = "WeatherSource",
		})
		p.CanQuery = false
		table.insert(weatherParts, p)
	end
end

local function setNight(night: boolean)
	if night == isNight then
		return
	end
	isNight = night
	Lighting:SetAttribute("IsNight", night)
	for _, p in CollectionService:GetTagged("NightLight") do
		local l = p:FindFirstChildOfClass("PointLight")
		if l then
			l.Enabled = night
		end
		if p:IsA("BasePart") and p:GetAttribute("GlowAtNight") then
			p.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
	for _, p in CollectionService:GetTagged("Fireflies") do
		local e = p:FindFirstChildOfClass("ParticleEmitter")
		if e then
			e.Enabled = night
		end
	end
end

function Sky.IsNight(): boolean
	return isNight
end

-- Sky palette by clock time: night -> sunrise -> day -> golden hour -> blue night.
-- Returns (haze colour, blend 0 = day .. 1 = night) for ambient + brightness.
local function palette(t: number): (Color3, number)
	local day, sunset, night = Theme.Colors.Sky, Theme.Colors.Sunset, Theme.Colors.Night
	if t >= 7 and t < 17 then
		return day, 0
	elseif t >= 17 and t < 18.5 then
		return day:Lerp(sunset, (t - 17) / 1.5), 0.15
	elseif t >= 18.5 and t < 20 then
		local k = (t - 18.5) / 1.5
		return sunset:Lerp(night, k), 0.15 + 0.85 * k
	elseif t >= 5.5 and t < 7 then
		local k = (t - 5.5) / 1.5
		return night:Lerp(sunset, k):Lerp(day, math.max(0, (t - 6.3) / 0.7)), 1 - k
	end
	return night, 1
end

-- Most of the 12-minute cycle is day: ClockTime runs slower between 9 and 16.
local function speed(t: number): number
	return if t >= 9 and t < 16 then 0.75 else 1.35
end

function Sky.StartCycle()
	local length = ((Config :: any).DayLengthSeconds :: number?) or 720
	local step = 1
	task.spawn(function()
		while true do
			local t = (Lighting.ClockTime + 24 * step / length * speed(Lighting.ClockTime)) % 24
			Lighting.ClockTime = t
			local col, n = palette(t)
			atmosphere.Color = col
			Lighting.Ambient = DAY_AMBIENT:Lerp(NIGHT_AMBIENT, n)
			Lighting.OutdoorAmbient = DAY_OUTDOOR:Lerp(NIGHT_OUTDOOR, n)
			Lighting.Brightness = 3 + (1.2 - 3) * n
			setNight(t >= 18 or t < 6)
			task.wait(step)
		end
	end)
end

local WEATHER_CC: { [string]: { TintColor: Color3, Saturation: number, Brightness: number, Density: number } } = {
	-- Rain/Thunder: cooler, not greyer (guide §2: saturation >= -0.05, blue tint #DCE8FF).
	Rain = { TintColor = Color3.fromHex("#DCE8FF"), Saturation = -0.05, Brightness = -0.03, Density = 0.35 },
	Thunderstorm = { TintColor = Color3.fromHex("#D0DEFF"), Saturation = -0.05, Brightness = -0.08, Density = 0.4 },
	Heatwave = { TintColor = Color3.fromRGB(255, 235, 210), Saturation = 0.1, Brightness = 0.03, Density = 0.32 },
	["Snow Flurry"] = {
		TintColor = Color3.fromRGB(230, 242, 255),
		Saturation = -0.05,
		Brightness = 0.03,
		Density = 0.38,
	},
	["Bloom Season"] = {
		TintColor = Color3.fromRGB(255, 240, 248),
		Saturation = 0.2,
		Brightness = 0.02,
		Density = 0.28,
	},
	Starfall = { TintColor = Color3.fromRGB(235, 235, 255), Saturation = 0.1, Brightness = 0, Density = 0.25 },
}

local function canonicalWeather(name: string?): string?
	if not name then
		return nil
	end
	local n = Theme.Normalize(name)
	for k in WEATHER_CC do
		if
			Theme.Normalize(k) == n
			or (n == "snow" and k == "Snow Flurry")
			or (n == "bloom" and k == "Bloom Season")
		then
			return k
		end
	end
	return nil
end

local function lightning()
	while currentWeather == "Thunderstorm" do
		task.wait(math.random(4, 10))
		if currentWeather ~= "Thunderstorm" then
			break
		end
		weatherCC.Brightness = 0.45
		TweenService:Create(weatherCC, TweenInfo.new(0.35), { Brightness = WEATHER_CC.Thunderstorm.Brightness }):Play()
		Workspace:SetAttribute("Lightning", os.clock())
	end
end

-- name: "Rain" | "Heatwave" | "Snow Flurry" | "Bloom Season" | "Thunderstorm" | "Starfall" | nil/"Clear".
function Sky.SetWeather(name: string?)
	local key = canonicalWeather(name)
	currentWeather = key
	for _, p in weatherParts do
		p:ClearAllChildren()
		if key then
			local e = Theme.Effects.Weather(key)
			if e then
				e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
				e.Parent = p
			end
		end
	end
	local look = if key then WEATHER_CC[key] else nil
	local info = TweenInfo.new(3)
	TweenService:Create(weatherCC, info, {
		TintColor = if look then look.TintColor else Color3.new(1, 1, 1),
		Saturation = if look then look.Saturation else 0,
		Brightness = if look then look.Brightness else 0,
	}):Play()
	TweenService:Create(atmosphere, info, { Density = if look then look.Density else DAY_DENSITY }):Play()
	if key == "Thunderstorm" then
		task.spawn(lightning)
	end
end

return Sky
