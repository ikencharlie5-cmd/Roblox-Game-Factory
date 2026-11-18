--!strict
-- Settings: Music / SFX toggles. Sets LocalPlayer Attributes MusicOn / SFXOn (read by SoundController).
local Players = game:GetService("Players")

local Style = require(script.Parent:WaitForChild("Style"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Windows = require(script.Parent:WaitForChild("Windows"))

local SettingsWindow = {}

local player = Players.LocalPlayer :: Player

local function toggleRow(parent: Instance, order: number, glyph: string, label: string, attr: string)
	local row = Kit.Panel(parent, Style.Color.Panel, { LayoutOrder = order, Size = UDim2.new(1, -12, 0, 80) })
	Kit.CodeBadge(row, glyph, Style.Pal.Sky, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(54, 54),
	})
	Kit.Label(row, label, {
		Size = UDim2.new(0.6, -80, 0, 40),
		Position = UDim2.new(0, 80, 0.5, -20),
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local btn: TextButton
	local function refresh()
		local on = player:GetAttribute(attr) ~= false -- nil = on
		btn.Text = if on then "ON" else "OFF"
		Kit.SetButtonColor(btn, if on then "Leaf" else Style.Color.Grey)
	end
	btn = Kit.Button(row, "ON", "Leaf", function()
		player:SetAttribute(attr, player:GetAttribute(attr) == false)
	end, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(130, 60),
		TextSize = 28,
	})
	player:GetAttributeChangedSignal(attr):Connect(refresh)
	refresh()
end

function SettingsWindow.Mount()
	local win = Windows.Create("Settings", "Settings", "Stone", "Settings", Vector2.new(560, 380))
	local body = Kit.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, win.Body)
	Kit.List(body, false, 12).HorizontalAlignment = Enum.HorizontalAlignment.Center
	toggleRow(body, 1, "M", "Music", "MusicOn")
	toggleRow(body, 2, "S", "Sound effects", "SFXOn")
	Kit.Body(body, "Sprout Zoo by Chiken Studios", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 30),
	})
end

return SettingsWindow
