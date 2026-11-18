--!strict
-- Plays SFX, UI, stingers, creature voices, music and ambience by name (Shared/Sounds). Owned by Audio.
-- Settings: LocalPlayer Attributes MusicVolume / SFXVolume (0..1, nil = 1) and MusicOn / SFXOn (bool,
-- nil = on), set by DataService on load. The UI calls the Set* helpers (saved via SaveSettings). Zone music/ambience: MusicDirector. Idle creature calls: CreatureVoices.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundsModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))
local Mixer = require(script.Parent:WaitForChild("Mixer"))

local COOLDOWN = 0.05
local COIN_WINDOW = 1.5
local SEMITONE = 2 ^ (1 / 12)

export type PlayOpts = { Pitch: number?, Volume: number?, At: (Instance | Vector3)? }

local SoundController = {}

local player = Players.LocalPlayer
local lastPlayed: { [string]: number } = {}
local stingerTier, stingerUntil = 0, 0
local stingerSound: Sound? = nil
local coinStep, coinLast = 0, 0
local voices: any = nil -- CreatureVoices, set in Start

local function normalizeOpts(opts: any): PlayOpts
	if type(opts) == "number" then
		return { Pitch = opts }
	elseif typeof(opts) == "Instance" or typeof(opts) == "Vector3" then
		return { At = opts }
	elseif type(opts) == "table" then
		return opts
	end
	return {}
end

-- Play a sound by name. opts: number (pitch mult) or { Pitch?, Volume?, At? = Instance | Vector3 }.
function SoundController.Play(name: string, opts: any?): Sound?
	local real, d = Mixer.Resolve(name)
	if not d then
		return nil
	end
	if d.Kind == "Music" then
		Mixer.PlayMusic(real)
		return nil
	end
	local o = normalizeOpts(opts)
	local now = os.clock()
	if now - (lastPlayed[real] or 0) < COOLDOWN and not o.At then
		return nil
	end
	lastPlayed[real] = now

	local pitch = o.Pitch
	if real == "Coins_Gain" then -- rising semitone ladder for rapid coin ticks
		coinStep = if now - coinLast < COIN_WINDOW then math.min(coinStep + 1, 7) else 0
		coinLast = now
		pitch = (pitch or 1) * SEMITONE ^ coinStep
	end

	if d.Kind == "Stinger" then
		local tier = d.Tier or 1
		if now < stingerUntil and tier <= stingerTier then
			return nil -- equal/lower tier mid-play is dropped
		end
		if stingerSound and stingerSound.Parent then
			stingerSound:Destroy() -- higher tier interrupts
		end
		stingerTier = tier
	end

	local s = Mixer.Make(real, d)
	s.PlaybackSpeed = Mixer.PitchFor(d, pitch)
	if o.Volume then
		s.Volume = d.Volume * o.Volume
	end
	if o.At then
		Mixer.Attach(s, o.At)
	else
		s.Parent = SoundService
	end
	if d.Kind == "Stinger" then
		stingerSound = s
		local len = d.MaxLength or (if s.TimeLength > 0 then s.TimeLength / s.PlaybackSpeed else 1.5)
		stingerUntil = now + len
		Mixer.Duck(len + 0.5)
	end
	Mixer.Fire(s, d)
	return s
end

-- 3D one-shot at a part/attachment or world position.
function SoundController.PlayAt(name: string, where: Instance | Vector3, pitch: number?): Sound?
	return SoundController.Play(name, { At = where, Pitch = pitch })
end

-- Creature call on a model (kind: "Idle" | "Happy" | "Eat" | "Alert" | "Sleep"); pitch per species.
function SoundController.PlayCreature(model: Instance, kind: string?)
	if voices then
		voices.Call(model, kind)
	end
end

-- Rarity reveal ("Common".."Legendary") with optional mutation list ({"Golden"}).
-- Rare+ with a mutation: tease riser -> 0.3 s silence -> payoff + mutation flavour layer.
function SoundController.PlayReveal(rarity: string, mutations: { string }?)
	local stinger = SoundsModule.Reveal[rarity] or "Reveal_Common"
	local hasMut = mutations ~= nil and #mutations > 0
	local big = rarity == "Rare" or rarity == "Epic" or rarity == "Legendary"
	local function payoff()
		SoundController.Play(stinger)
		for _, m in mutations or {} do
			local layer = SoundsModule.MutationLayer[m]
			if layer then
				SoundController.Play(layer)
			end
		end
	end
	if hasMut and big then
		local tease = SoundController.Play("Mutation_Tease")
		local wait = if tease then math.min(tease.TimeLength, 1.2) + 0.3 else 0.3
		stingerUntil = 0 -- let the payoff replace the tease
		task.delay(wait, payoff)
	else
		payoff()
	end
end

-- Music / ambience (crossfades). MusicDirector drives these automatically.
SoundController.PlayMusic = Mixer.PlayMusic
SoundController.CurrentMusic = Mixer.CurrentMusic
SoundController.SetAmbience = Mixer.SetAmbience

-- Settings helpers for the UI. DataService sets the 4 Attributes on load; changes go to the server
-- via the SaveSettings RemoteEvent ({music, sfx, musicOn, sfxOn}), debounced so slider drags send once.
local saveToken = 0
local function attrOr(name: string, default: any): any
	local v = player:GetAttribute(name)
	return if v == nil then default else v
end
local function queueSave()
	saveToken += 1
	local token = saveToken
	task.delay(1, function()
		if token ~= saveToken then
			return
		end
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local ev = remotes and remotes:FindFirstChild("SaveSettings")
		if ev and ev:IsA("RemoteEvent") then
			ev:FireServer({
				music = attrOr("MusicVolume", 1),
				sfx = attrOr("SFXVolume", 1),
				musicOn = attrOr("MusicOn", true),
				sfxOn = attrOr("SFXOn", true),
			})
		end
	end)
end
function SoundController.SetMusicVolume(v: number)
	player:SetAttribute("MusicVolume", math.clamp(v, 0, 1))
	queueSave()
end
function SoundController.SetSFXVolume(v: number)
	player:SetAttribute("SFXVolume", math.clamp(v, 0, 1))
	queueSave()
end
function SoundController.SetMusicOn(on: boolean)
	player:SetAttribute("MusicOn", on)
	queueSave()
end
function SoundController.SetSFXOn(on: boolean)
	player:SetAttribute("SFXOn", on)
	queueSave()
end

local started = false
function SoundController.Start()
	if started then
		return
	end
	started = true
	Mixer.Init()

	-- Server -> client: PlaySound(name, opts?) ; name "Reveal" uses opts.Rarity + opts.Mutations.
	task.spawn(function()
		local ev = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlaySound") :: RemoteEvent
		ev.OnClientEvent:Connect(function(name: any, opts: any)
			if type(name) ~= "string" then
				return
			end
			if name == "Reveal" and type(opts) == "table" and type(opts.Rarity) == "string" then
				SoundController.PlayReveal(opts.Rarity, if type(opts.Mutations) == "table" then opts.Mutations else nil)
			else
				SoundController.Play(name, opts)
			end
		end)
	end)

	local Audio = script.Parent
	require(Audio:WaitForChild("MusicDirector")).Start(SoundController)
	voices = require(Audio:WaitForChild("CreatureVoices"))
	voices.Start(SoundController)
end

return SoundController
