--!strict
-- Plays SFX and music by name from Shared/Sounds. Owned by the Audio department.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared:WaitForChild("Sounds"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local SoundController = {}

local cache: { [string]: Sound } = {}
local currentMusic: Sound? = nil

local function get(name: string): Sound?
	local def = Sounds[name]
	if not def or def.Id == 0 then
		return nil
	end
	local s = cache[name]
	if not s then
		local snd = Instance.new("Sound")
		snd.Name = name
		snd.SoundId = "rbxassetid://" .. def.Id
		snd.Volume = def.Volume
		snd.Looped = def.Looped == true
		snd.Parent = SoundService
		cache[name] = snd
		s = snd
	end
	return s
end

function SoundController.Play(name: string)
	local s = get(name)
	if s then
		s.PlaybackSpeed = 0.95 + math.random() * 0.1
		SoundService:PlayLocalSound(s)
	end
end

function SoundController.PlayMusic(name: string)
	local s = get(name)
	if not s or s == currentMusic then
		return
	end
	local old = currentMusic
	if old then
		TweenService:Create(old, TweenInfo.new(1), { Volume = 0 }):Play()
		task.delay(1, function()
			old:Stop()
		end)
	end
	s.Volume = 0
	s:Play()
	TweenService:Create(s, TweenInfo.new(1), { Volume = Sounds[name].Volume }):Play()
	currentMusic = s
end

function SoundController.Start()
	Remotes.Event("PlaySound").OnClientEvent:Connect(function(name: string)
		SoundController.Play(name)
	end)
	SoundController.PlayMusic("MainTheme")
end

return SoundController
