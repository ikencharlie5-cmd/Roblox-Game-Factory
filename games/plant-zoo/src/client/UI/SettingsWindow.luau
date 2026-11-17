--!strict
-- Settings: Music / SFX toggles. Sets LocalPlayer Attributes MusicOn / SFXOn (read by SoundController).
local Players = game:GetService("Players")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local SettingsWindow = {}

local player = Players.LocalPlayer :: Player

local function toggleRow(parent: Instance, order: number, icon: string, label: string, attr: string)
	local row = Kit.Panel(parent, Style.Color.Panel, { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 64) })
	Kit.Label(row, icon .. " " .. label, {
		Size = UDim2.new(0.6, -8, 0.8, 0),
		Position = UDim2.new(0, 10, 0.1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local btn: TextButton
	local function refresh()
		local on = player:GetAttribute(attr) ~= false -- nil = on
		btn.Text = if on then "ON" else "OFF"
		Kit.SetButtonColor(btn, if on then Style.Color.Leaf else Style.Color.Grey)
	end
	btn = Kit.Button(row, "ON", Style.Color.Leaf, function()
		player:SetAttribute(attr, player:GetAttribute(attr) == false)
	end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.3, 0, 0, 48) })
	player:GetAttributeChangedSignal(attr):Connect(refresh)
	refresh()
end

function SettingsWindow.Mount()
	local win = Windows.Create("Settings", "⚙️ Settings", Style.Color.Grey)
	win.Frame.Size = UDim2.fromScale(0.4, 0.55)
	local body = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, win.Body)
	Kit.List(body, false, 8, true)
	toggleRow(body, 1, "🎵", "Music", "MusicOn")
	toggleRow(body, 2, "🔊", "Sound effects", "SFXOn")
	Kit.Label(body, "🌱 Sprout Zoo by Chiken Studios", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 28),
		Font = Style.FontBody,
		TextColor3 = Style.Color.InkSoft,
	})
end

return SettingsWindow
