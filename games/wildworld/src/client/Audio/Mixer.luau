--!strict
-- Audio internals: SoundGroups + volume settings, Sound creation, ducking, music/ambience loops.
-- Only SoundController / MusicDirector / CreatureVoices use this. Owned by Audio.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundsModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))
local Defs = SoundsModule.Defs
type SoundDef = SoundsModule.SoundDef

local MUSIC_FADE = 2
local AMB_FADE = 3
local DUCK = 0.4 -- music x0.4 (about -8 dB) while a stinger plays
local GROUP_VOL = { Music = 0.6, Ambience = 0.7, SFX = 0.8, Creature = 0.8, Stinger = 0.9, UI = 0.5 }

local Mixer = {}

local player = Players.LocalPlayer
local groups: { [string]: SoundGroup } = {}
local loops: { [string]: Sound } = {}
local currentMusic: Sound? = nil
local currentMusicName: string? = nil
local ambience: { [string]: Sound } = {}
local warned: { [string]: boolean } = {}
local duckUntil = 0
local duckToken = 0

local function attrNum(name: string): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then math.clamp(v, 0, 1) else 1
end

local function musicTarget(): number
	local on = player:GetAttribute("MusicOn") ~= false
	return if on then GROUP_VOL.Music * attrNum("MusicVolume") else 0
end

local function applySettings()
	local sfxOn = player:GetAttribute("SFXOn") ~= false
	local sfx = if sfxOn then attrNum("SFXVolume") else 0
	for kind, g in groups do
		if kind ~= "Music" then
			g.Volume = (GROUP_VOL :: any)[kind] * sfx
		end
	end
	local m = musicTarget()
	groups.Music.Volume = if os.clock() < duckUntil then m * DUCK else m
end

local function resolve(name: string): (string, SoundDef?)
	local real = SoundsModule.Aliases[name] or name
	local d = Defs[real]
	if not d then
		if not warned[name] then
			warned[name] = true
			warn("[Audio] unknown sound name: " .. name)
		end
		return real, nil
	end
	if d.Id == 0 then
		return real, nil -- not chosen yet: silent
	end
	return real, d
end

local function make(name: string, d: SoundDef): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = if type(d.Id) == "string" then d.Id else "rbxassetid://" .. tostring(d.Id)
	s.Volume = d.Volume
	s.Looped = d.Looped == true
	s.SoundGroup = groups[d.Kind]
	return s
end

local function pitchFor(d: SoundDef, extra: number?): number
	local defVar = if d.Kind == "Stinger" or d.Kind == "Music" then 0 else 0.05
	local var = d.PitchVar or defVar
	return (d.Pitch or 1) * (extra or 1) * (1 + (math.random() * 2 - 1) * var)
end

local function attach(s: Sound, where: Instance | Vector3)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 80
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
end

local function fire(s: Sound, d: SoundDef)
	s:Play()
	local maxLen = d.MaxLength
	if maxLen then
		task.delay(maxLen, function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(0.4), { Volume = 0 }):Play()
				task.delay(0.45, function()
					s:Destroy()
				end)
			end
		end)
	end
	s.Ended:Once(function()
		s:Destroy()
	end)
end

local function duck(seconds: number)
	duckToken += 1
	local token = duckToken
	duckUntil = os.clock() + seconds
	TweenService:Create(groups.Music, TweenInfo.new(0.15), { Volume = musicTarget() * DUCK }):Play()
	task.delay(seconds, function()
		if token == duckToken then
			TweenService:Create(groups.Music, TweenInfo.new(0.5), { Volume = musicTarget() }):Play()
		end
	end)
end

local function getLoop(name: string): Sound?
	local real, d = resolve(name)
	if not d then
		return nil
	end
	local s = loops[real]
	if not s then
		local ns = make(real, d)
		ns.Looped = d.Kind ~= "Music" -- music gaps are handled by MusicDirector
		ns.PlaybackSpeed = d.Pitch or 1
		ns.Volume = 0
		ns.Parent = SoundService
		loops[real] = ns
		s = ns
	end
	return s
end

local function fade(s: Sound, to: number, t: number)
	TweenService:Create(s, TweenInfo.new(t), { Volume = to }):Play()
	if to <= 0 then
		task.delay(t, function()
			if s.Volume <= 0.001 then
				s:Pause()
			end
		end)
	end
end

local function fadeIn(s: Sound, name: string, t: number)
	if not s.IsPlaying then
		s:Resume()
		if not s.IsPlaying then
			s:Play()
		end
	end
	fade(s, Defs[SoundsModule.Aliases[name] or name].Volume, t)
end

-- Crossfade (2 s) to a music track; nil fades music out. Returns the Sound (for Ended).
function Mixer.PlayMusic(name: string?): Sound?
	local s = if name then getLoop(name) else nil
	if s == currentMusic then
		return s
	end
	if currentMusic then
		fade(currentMusic, 0, MUSIC_FADE)
	end
	currentMusic = s
	currentMusicName = name
	if s and name then
		if s.TimePosition >= s.TimeLength - 1 then
			s.TimePosition = 0
		end
		fadeIn(s, name, MUSIC_FADE)
	end
	return s
end

function Mixer.CurrentMusic(): string?
	return currentMusicName
end

-- Crossfade (3 s) an ambience channel ("bed", "rain", ...) to a loop; nil silences it.
function Mixer.SetAmbience(channel: string, name: string?)
	local s = if name then getLoop(name) else nil
	local old = ambience[channel]
	if s == old then
		return
	end
	if old then
		fade(old, 0, AMB_FADE)
	end
	ambience[channel] = s
	if s and name then
		fadeIn(s, name, AMB_FADE)
	end
end

function Mixer.Init()
	local master = Instance.new("SoundGroup")
	master.Name = "Master"
	master.Parent = SoundService
	for kind in GROUP_VOL do
		local g = Instance.new("SoundGroup")
		g.Name = kind
		g.Parent = master
		groups[kind] = g
	end
	applySettings()
	for _, a in { "MusicOn", "SFXOn", "MusicVolume", "SFXVolume" } do
		player:GetAttributeChangedSignal(a):Connect(applySettings)
	end
end

Mixer.Resolve = resolve
Mixer.Make = make
Mixer.PitchFor = pitchFor
Mixer.Attach = attach
Mixer.Fire = fire
Mixer.Duck = duck

return Mixer
