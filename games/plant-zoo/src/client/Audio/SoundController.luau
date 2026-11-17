--!strict
-- Plays SFX, music and ambience by name from Shared/Sounds. Owned by the Audio department.
-- Settings: LocalPlayer Attributes `MusicOn` / `SFXOn` (bool, nil = on). UI just sets them.
-- Ambience follows SFXOn. Zone/weather/night music + biome ambience live in MusicDirector.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundsModule = require(Shared:WaitForChild("Sounds"))
local Defs = SoundsModule.Defs

local FADE = 1.5

local SoundController = {}

local player = Players.LocalPlayer
local groups: { [string]: SoundGroup } = {}
local loops: { [string]: Sound } = {} -- music + ambience instances, reused
local currentMusic: Sound? = nil
local currentAmbience: { [string]: Sound } = {} -- channel -> sound
local warned: { [string]: boolean } = {}

local function group(kind: string): SoundGroup
	local g = groups[kind]
	if not g then
		local ng = Instance.new("SoundGroup")
		ng.Name = "Zoo_" .. kind
		ng.Volume = 1
		ng.Parent = SoundService
		groups[kind] = ng
		g = ng
	end
	return g
end

local function isOn(attr: string): boolean
	return player:GetAttribute(attr) ~= false
end

local function applySettings()
	group("music").Volume = if isOn("MusicOn") then 1 else 0
	local sfx = if isOn("SFXOn") then 1 else 0
	group("sfx").Volume = sfx
	group("ambience").Volume = sfx
end

local function def(name: string): SoundsModule.SoundDef?
	local d = Defs[name]
	if not d then
		if not warned[name] then
			warned[name] = true
			warn("[Audio] unknown sound name: " .. name)
		end
		return nil
	end
	if d.Id == 0 then
		return nil -- not chosen yet; silent
	end
	return d
end

local function make(name: string, d: SoundsModule.SoundDef): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = "rbxassetid://" .. d.Id
	s.Volume = d.Volume
	s.Looped = d.Looped == true
	s.SoundGroup = group(d.Kind)
	return s
end

local function pitchFor(d: SoundsModule.SoundDef, extra: number?): number
	local var = d.PitchVar or (if d.Kind == "sfx" then 0.05 else 0)
	return (d.Pitch or 1) * (extra or 1) * (1 + (math.random() * 2 - 1) * var)
end

local function fire(s: Sound, d: SoundsModule.SoundDef)
	s:Play()
	local maxLen = d.MaxLength
	if maxLen then
		task.delay(maxLen, function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(0.6), { Volume = 0 }):Play()
				task.delay(0.7, function()
					s:Destroy()
				end)
			end
		end)
	end
	s.Ended:Once(function()
		s:Destroy()
	end)
end

-- One-shot 2D sound. `pitch` multiplies the base pitch (e.g. per-species chirp).
function SoundController.Play(name: string, pitch: number?)
	local d = def(name)
	if not d then
		return
	end
	if d.Kind ~= "sfx" then
		SoundController.PlayMusic(name)
		return
	end
	local s = make(name, d)
	s.PlaybackSpeed = pitchFor(d, pitch)
	s.Parent = SoundService
	fire(s, d)
end

-- One-shot 3D sound at a part/attachment or world position (creature chirps, tip jars).
function SoundController.PlayAt(name: string, where: Instance | Vector3, pitch: number?)
	local d = def(name)
	if not d then
		return
	end
	local s = make(name, d)
	s.PlaybackSpeed = pitchFor(d, pitch)
	s.RollOffMaxDistance = 80
	s.RollOffMinDistance = 8
	if typeof(where) == "Vector3" then
		local a = Instance.new("Attachment")
		a.Name = "AudioPoint"
		a.WorldPosition = where
		a.Parent = workspace.Terrain
		s.Parent = a
		s.Destroying:Once(function()
			a:Destroy()
		end)
	else
		s.Parent = where
	end
	fire(s, d)
end

-- Rarity-scaled reveal ("Common".."Secret").
function SoundController.PlayReveal(rarity: string)
	SoundController.Play(SoundsModule.Reveal[rarity] or "Bloom")
end

local function getLoop(name: string): Sound?
	local d = def(name)
	if not d then
		return nil
	end
	local s = loops[name]
	if not s then
		local ns = make(name, d)
		ns.Looped = true
		ns.Volume = 0
		ns.Parent = SoundService
		loops[name] = ns
		s = ns
	end
	return s
end

local function fadeOut(s: Sound)
	TweenService:Create(s, TweenInfo.new(FADE), { Volume = 0 }):Play()
	task.delay(FADE, function()
		if s.Volume <= 0.001 then
			s:Pause()
		end
	end)
end

local function fadeIn(s: Sound, name: string)
	if not s.IsPlaying then
		s:Resume()
		if not s.IsPlaying then
			s:Play()
		end
	end
	TweenService:Create(s, TweenInfo.new(FADE), { Volume = Defs[name].Volume }):Play()
end

-- Crossfades to a music track. nil = fade music out. Paused tracks resume where they left off.
function SoundController.PlayMusic(name: string?)
	local s = if name then getLoop(name) else nil
	if s == currentMusic then
		return
	end
	if currentMusic then
		fadeOut(currentMusic)
	end
	currentMusic = s
	if s and name then
		fadeIn(s, name)
	end
end

-- Crossfades an ambience channel ("biome", "weather") to a loop; nil = silence that channel.
function SoundController.SetAmbience(channel: string, name: string?)
	local s = if name then getLoop(name) else nil
	local old = currentAmbience[channel]
	if s == old then
		return
	end
	if old then
		fadeOut(old)
	end
	currentAmbience[channel] = s
	if s and name then
		fadeIn(s, name)
	end
end

function SoundController.SetMusicOn(on: boolean)
	player:SetAttribute("MusicOn", on)
end

function SoundController.SetSFXOn(on: boolean)
	player:SetAttribute("SFXOn", on)
end

local started = false
function SoundController.Start()
	if started then
		return
	end
	started = true
	applySettings()
	player:GetAttributeChangedSignal("MusicOn"):Connect(applySettings)
	player:GetAttributeChangedSignal("SFXOn"):Connect(applySettings)

	-- Server -> client: PlaySound(name, where?: Instance | Vector3, pitch?: number)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Remotes")
		local ev = folder:WaitForChild("PlaySound") :: RemoteEvent
		ev.OnClientEvent:Connect(function(name: any, where: any, pitch: any)
			if type(name) ~= "string" then
				return
			end
			local p = if type(pitch) == "number" then pitch else nil
			if typeof(where) == "Vector3" or typeof(where) == "Instance" then
				SoundController.PlayAt(name, where, p)
			else
				SoundController.Play(name, p)
			end
		end)
	end)

	local MusicDirector = require(script.Parent:WaitForChild("MusicDirector"))
	MusicDirector.Start(SoundController)
end

return SoundController
