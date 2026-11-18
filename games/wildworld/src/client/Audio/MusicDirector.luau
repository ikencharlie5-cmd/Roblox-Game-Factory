--!strict
-- Zone music (with 20-60 s silences between tracks), ambience beds + random 3D one-shots, rain layer,
-- waterfall loops and per-zone reverb. Owned by Audio.
-- World contract (all optional, see notes/audio.md):
--   LocalPlayer Attribute `Zone` = "Park" (default) | "Meadow" | "Hollow" | "Glade" | "Hub" (set by WildService)
--   or parts tagged `AudioZone` with Attribute `Zone` (character inside the part's box).
--   Night: workspace Attribute `IsNight` (bool) or Lighting.ClockTime < 6 / >= 18.
--   Rain: workspace Attribute `Weather` == "Rain" (also "Storm"). Tag `WaterfallSound` = 3D waterfall loop.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundsModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local GAP_MIN, GAP_MAX = 20, 60
local MAX_ONESHOTS = 4

local MusicDirector = {}

local player = Players.LocalPlayer
local SC: any = nil
local zone = "Park"
local night = false
local override: string? = nil
local wantMusic: string? = nil
local gapUntil = 0
local playingOneShots = 0
local nextShot: { [string]: number } = {}

local function isNight(): boolean
	local attr = workspace:GetAttribute("IsNight")
	if type(attr) == "boolean" then
		return attr
	end
	local t = Lighting.ClockTime
	return t < 6 or t >= 18
end

local function insidePart(p: BasePart, pos: Vector3): boolean
	local lp = p.CFrame:PointToObjectSpace(pos)
	local h = p.Size / 2
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y + 40 and math.abs(lp.Z) <= h.Z
end

local function detectZone(): string
	local attr = player:GetAttribute("Zone")
	if type(attr) == "string" and SoundsModule.Zones[attr] then
		return attr
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		for _, inst in CollectionService:GetTagged("AudioZone") do
			local z = inst:GetAttribute("Zone")
			if inst:IsA("BasePart") and type(z) == "string" and SoundsModule.Zones[z] then
				if insidePart(inst, root.Position) then
					return z
				end
			end
		end
	end
	return zone
end

local function pickMusic(): string
	if override then
		return override
	end
	local z = SoundsModule.Zones[zone]
	return if night and z.NightMusic then z.NightMusic else z.Music
end

local function startMusic(name: string)
	local s = SC.PlayMusic(name)
	if s then
		s.Ended:Once(function()
			-- track finished: leave a silence, then MusicDirector restarts it
			if SC.CurrentMusic() == name then
				gapUntil = os.clock() + math.random(GAP_MIN, GAP_MAX)
				SC.PlayMusic(nil)
			end
		end)
	end
end

local function refreshMusic(force: boolean)
	local name = pickMusic()
	if name ~= wantMusic or force then
		wantMusic = name
		gapUntil = 0
		startMusic(name)
	elseif SC.CurrentMusic() == nil and os.clock() >= gapUntil then
		startMusic(name)
	end
end

local function refreshAmbience()
	local z = SoundsModule.Zones[zone]
	SC.SetAmbience("bed", if night and z.NightBed then z.NightBed else z.Bed)
	local w = workspace:GetAttribute("Weather")
	local rain = w == "Rain" or w == "Storm"
	SC.SetAmbience("rain", if rain then "Amb_Rain_Bed" else nil)
	SoundService.AmbientReverb = z.Reverb
end

local function oneShots()
	local z = SoundsModule.Zones[zone]
	local list = if night and z.NightOneShots then z.NightOneShots else z.OneShots
	local now = os.clock()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	for _, entry in list do
		local name, lo, hi = entry[1] :: string, entry[2] :: number, entry[3] :: number
		local due = nextShot[name]
		if not due then
			nextShot[name] = now + math.random(lo, hi)
		elseif now >= due then
			nextShot[name] = now + math.random(lo, hi)
			if playingOneShots < MAX_ONESHOTS then
				local angle = math.random() * math.pi * 2
				local dist = 15 + math.random() * 45
				local pos = cam.CFrame.Position
					+ Vector3.new(math.cos(angle) * dist, 4 + math.random() * 10, math.sin(angle) * dist)
				local s = SC.PlayAt(name, pos)
				if s then
					s.Volume *= 0.85 + math.random() * 0.3
					playingOneShots += 1
					s.Destroying:Once(function()
						playingOneShots -= 1
					end)
				end
			end
		end
	end
end

local function addWaterfall(inst: Instance)
	if inst:FindFirstChild("Amb_Waterfall") then
		return
	end
	local s = SC.PlayAt("Amb_Waterfall", inst)
	if s then
		s.Looped = true
		s.RollOffMaxDistance = 90
	end
end

-- Force a track (e.g. "Music_Breeding" while the Breeding Center is open, "Music_Menu" on loading).
-- nil returns to zone music.
function MusicDirector.SetOverride(name: string?)
	override = name
	refreshMusic(false)
end

function MusicDirector.SetZone(z: string)
	if SoundsModule.Zones[z] then
		player:SetAttribute("Zone", z)
	end
end

function MusicDirector.Start(controller: any)
	SC = controller
	night = isNight()
	zone = detectZone()
	refreshAmbience()
	refreshMusic(true)

	for _, inst in CollectionService:GetTagged("WaterfallSound") do
		addWaterfall(inst)
	end
	CollectionService:GetInstanceAddedSignal("WaterfallSound"):Connect(addWaterfall)
	workspace:GetAttributeChangedSignal("Weather"):Connect(refreshAmbience)

	task.spawn(function()
		while true do
			task.wait(1)
			local z, n = detectZone(), isNight()
			if z ~= zone or n ~= night then
				zone, night = z, n
				nextShot = {}
				refreshAmbience()
			end
			refreshMusic(false)
			oneShots()
		end
	end)
end

return MusicDirector
