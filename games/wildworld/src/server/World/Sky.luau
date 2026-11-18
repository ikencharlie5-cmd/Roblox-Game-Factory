--!strict
-- Lighting, Atmosphere, post FX, 14-minute day cycle (70% day, short golden hour, blue readable night),
-- and drifting puffy clouds. (Weather visuals were cut for v1.)
-- Sets Lighting attribute "IsNight" and toggles every "NightLight"-tagged part's light.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Kit = Theme.Kit

local L = Theme.Lighting
local Sky = {}

local atmosphere: Atmosphere
local isNight = false

local function inst(className: string, name: string?, props: { [string]: any }): Instance
	local i = (if name then Lighting:FindFirstChild(name) else Lighting:FindFirstChildOfClass(className))
		or Instance.new(className)
	if name then
		i.Name = name
	end
	for k, v in props do
		(i :: any)[k] = v
	end
	i.Parent = Lighting
	return i
end

function Sky.Setup()
	-- STUDS_STYLE_GUIDE §7: flatter, brighter light for the brick look.
	Lighting.Brightness = L.Day.Brightness
	Lighting.ClockTime = L.ClockTime
	Lighting.GeographicLatitude = L.Env.Latitude
	Lighting.Ambient = L.Day.Ambient
	Lighting.OutdoorAmbient = L.Day.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = L.Env.DiffuseScale
	Lighting.EnvironmentSpecularScale = L.Env.SpecularScale
	Lighting.ShadowSoftness = L.Env.ShadowSoftness
	Lighting.GlobalShadows = true
	atmosphere = inst("Atmosphere", nil, L.Atmosphere) :: Atmosphere
	inst("Sky", nil, { StarCount = 3000, SunAngularSize = 14, MoonAngularSize = 9, CelestialBodiesShown = true })
	inst("BloomEffect", nil, L.Bloom)
	inst("SunRaysEffect", nil, L.SunRays)
	inst("ColorCorrectionEffect", "Grade", L.ColorCorrection)
	local oldCC = Lighting:FindFirstChild("WeatherCC")
	if oldCC then
		oldCC:Destroy()
	end
	Lighting:SetAttribute("IsNight", false)
end

local function setNight(night: boolean)
	if night == isNight then
		return
	end
	isNight = night
	Lighting:SetAttribute("IsNight", night)
	Workspace:SetAttribute("IsNight", night)
	for _, p in CollectionService:GetTagged("NightLight") do
		local l = p:FindFirstChildWhichIsA("Light")
		if l then
			l.Enabled = night
		end
		if p:IsA("BasePart") and p:GetAttribute("GlowAtNight") then
			-- Remember the day material (Plastic keeps its studs, lamp glass is SmoothPlastic).
			if p:GetAttribute("DayMaterial") == nil then
				p:SetAttribute("DayMaterial", p.Material.Name)
			end
			local day = (Enum.Material :: any)[p:GetAttribute("DayMaterial")] or Enum.Material.SmoothPlastic
			p.Material = if night then Enum.Material.Neon else day
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

-- (atmosphere colour, night blend 0..1) by clock time.
local function palette(t: number): (Color3, number)
	local day, sunset, night = L.Atmosphere.Color, Theme.Colors.Sunset, Theme.Colors.Night
	if t >= 7 and t < 17 then
		return day, 0
	elseif t >= 17 and t < 18.2 then
		return day:Lerp(sunset, (t - 17) / 1.2), 0.1
	elseif t >= 18.2 and t < 19.5 then
		local k = (t - 18.2) / 1.3
		return sunset:Lerp(night, k), 0.1 + 0.9 * k
	elseif t >= 5.5 and t < 7 then
		local k = (t - 5.5) / 1.5
		return night:Lerp(sunset, math.min(1, k * 1.6)):Lerp(day, math.max(0, k * 2 - 1)), 1 - k
	end
	return night, 1
end

-- 70% of real time is day (9–16): ClockTime moves slower then.
local function speed(t: number): number
	return if t >= 9 and t < 16 then 0.417 else 2.36
end

function Sky.StartCycle()
	local length = L.DayLengthSeconds
	task.spawn(function()
		while true do
			local dt = task.wait(1)
			local t = (Lighting.ClockTime + 24 * dt / length * speed(Lighting.ClockTime)) % 24
			Lighting.ClockTime = t
			local col, n = palette(t)
			atmosphere.Color = col
			Lighting.Ambient = L.Day.Ambient:Lerp(L.Night.Ambient, n)
			Lighting.OutdoorAmbient = L.Day.OutdoorAmbient:Lerp(L.Night.OutdoorAmbient, n)
			Lighting.Brightness = L.Day.Brightness + (L.Night.Brightness - L.Day.Brightness) * n
			setNight(t >= 18.5 or t < 5.8)
		end
	end)
end

-- 8 blocky brick clouds around the map edge, drifting slowly in a big circle.
function Sky.Clouds(rng: Random)
	local folder = Kit.Folder(Kit.Folder(Workspace, "World"), "Clouds")
	local clouds: { { m: Model, r: number, a: number, y: number, z: number } } = {}
	for i = 1, 8 do
		local m = Kit.Model(folder, "Cloud")
		Theme.Nature.Cloud(m, CFrame.new(), rng:NextNumber(1, 1.6), rng)
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanQuery = false
			end
		end
		table.insert(clouds, { m = m, r = rng:NextNumber(420, 620), a = i / 8 * math.pi * 2, y = rng:NextNumber(150, 200), z = -300 })
	end
	task.spawn(function()
		while true do
			for _, c in clouds do
				c.a += 0.0012
				c.m:PivotTo(CFrame.new(math.cos(c.a) * c.r, c.y, c.z + math.sin(c.a) * c.r * 1.3))
			end
			task.wait(0.5)
		end
	end)
end

return Sky
