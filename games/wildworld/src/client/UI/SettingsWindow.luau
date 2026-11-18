--!strict
-- Settings: Music and Sound effects, each with an On/Off toggle and -/+ volume (10% steps).
-- Uses Audio's SoundController setters (LocalPlayer attributes MusicVolume/SFXVolume/MusicOn/SFXOn).
local Players = game:GetService("Players")

local Kit = require(script.Parent:WaitForChild("Kit"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local SettingsWindow = {}

local player = Players.LocalPlayer :: Player
local rows: { [string]: { toggle: TextButton, set: (number) -> (), value: TextLabel } } = {}

local DEFS = {
	{ key = "Music", label = "Music", vol = "MusicVolume", on = "MusicOn", setVol = "SetMusicVolume", setOn = "SetMusicOn" },
	{ key = "SFX", label = "Sound effects", vol = "SFXVolume", on = "SFXOn", setVol = "SetSFXVolume", setOn = "SetSFXOn" },
}

local function read(def: { [string]: string }): (number, boolean)
	local v = player:GetAttribute(def.vol)
	local on = player:GetAttribute(def.on)
	return if type(v) == "number" then v else 1, on ~= false
end

local function refresh()
	for _, def in DEFS do
		local r = rows[def.key]
		if r then
			local v, on = read(def)
			r.set(if on then v else 0)
			r.value.Text = if on then math.floor(v * 100 + 0.5) .. "%" else "Off"
			r.toggle.Text = if on then "On" else "Off"
			Kit.SetButtonColor(r.toggle, if on then "Leaf" else "Stone")
		end
	end
end

function SettingsWindow.Mount()
	local win = Windows.Create("Settings", "Settings", "Stone", "Settings", Vector2.new(640, 380))
	local list = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, win.Body)
	Kit.List(list, false, 18)
	for i, def in DEFS do
		local row = Kit.Panel(list, nil, { Size = UDim2.new(1, 0, 0, 110), LayoutOrder = i })
		Kit.Label(row, def.label, {
			Position = UDim2.fromOffset(16, 8),
			Size = UDim2.new(0.5, 0, 0, 36),
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		})
		local toggle = Kit.Button(row, "On", "Leaf", function()
			local _, on = read(def)
			Kit.SoundFn(def.setOn, not on)
			task.defer(refresh)
		end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(120, 50), ZIndex = 4 })
		local function step(d: number)
			local v = read(def)
			Kit.SoundFn(def.setVol, math.clamp(math.floor((v + d) * 10 + 0.5) / 10, 0, 1))
			Kit.SoundFn(def.setOn, true)
			task.defer(refresh)
		end
		Kit.Button(row, "-", "Sky", function()
			step(-0.1)
		end, { Position = UDim2.fromOffset(16, 56), Size = UDim2.fromOffset(50, 46), TextSize = 32, ZIndex = 4 })
		local _, set = Kit.Progress(row, "Teal", { Position = UDim2.new(0, 80, 0, 70), Size = UDim2.new(1, -250, 0, 18), ZIndex = 3 })
		Kit.Button(row, "+", "Sky", function()
			step(0.1)
		end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -96, 0, 56), Size = UDim2.fromOffset(50, 46), TextSize = 32, ZIndex = 4 })
		local value = Kit.Label(row, "100%", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 60), Size = UDim2.fromOffset(76, 36), TextSize = 24, ZIndex = 3 })
		rows[def.key] = { toggle = toggle, set = set, value = value }
	end
	win.OnOpen = refresh
	player.AttributeChanged:Connect(function(attr)
		if string.find(attr, "Music", 1, true) or string.find(attr, "SFX", 1, true) then
			refresh()
		end
	end)
end

return SettingsWindow
