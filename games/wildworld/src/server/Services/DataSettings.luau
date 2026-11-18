--!strict
-- Helper for DataService (not a service): persisted audio settings in data.settings.
-- On load sets player attributes MusicVolume / SFXVolume (0..1) and MusicOn / SFXOn (bool).
-- Client saves via the SaveSettings RemoteEvent ({music, sfx, musicOn, sfxOn}); values are clamped,
-- rate-limited (Config.SettingsSaveCooldown, extra calls dropped) and bad fields ignored.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataSettings = {}

local DEFAULTS = { music = 0.5, sfx = 0.7, musicOn = true, sfxOn = true }
local last: { [Player]: number } = {}

local function apply(player: Player, s: any)
	player:SetAttribute("MusicVolume", s.music)
	player:SetAttribute("SFXVolume", s.sfx)
	player:SetAttribute("MusicOn", s.musicOn)
	player:SetAttribute("SFXOn", s.sfxOn)
end

local function vol(v: any, default: number): number
	return if type(v) == "number" and v == v then math.clamp(v, 0, 1) else default
end

local function flag(v: any, default: boolean): boolean
	return if type(v) == "boolean" then v else default
end

-- Sanitises whatever is in data.settings (old saves only had music/sfx).
local function clean(s: any, cur: any): any
	return {
		music = vol(s.music, cur.music),
		sfx = vol(s.sfx, cur.sfx),
		musicOn = flag(s.musicOn, cur.musicOn),
		sfxOn = flag(s.sfxOn, cur.sfxOn),
	}
end

-- Called once from DataService.Init (DataService passed in to avoid a require cycle).
function DataSettings.Bind(DataService: any)
	DataService.OnLoaded(function(player: Player, data: any)
		local s = clean(if type(data.settings) == "table" then data.settings else {}, DEFAULTS)
		data.settings = s
		apply(player, s)
	end)
	Remotes.Event("SaveSettings").OnServerEvent:Connect(function(player: Player, payload: any)
		local now = os.clock()
		if now - (last[player] or 0) < Config.SettingsSaveCooldown or type(payload) ~= "table" then
			return
		end
		last[player] = now
		local data = DataService.Get(player)
		if not data then
			return
		end
		local s = clean(payload, clean(data.settings or {}, DEFAULTS))
		DataService.Update(player, function(d)
			d.settings = s
		end)
		apply(player, s)
	end)
	Players.PlayerRemoving:Connect(function(p)
		last[p] = nil
	end)
end

return DataSettings
