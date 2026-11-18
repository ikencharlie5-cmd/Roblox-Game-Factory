--!strict
-- The Glade's signature waterfall. No texture upload needed: layered translucent Glass sheets + a falling
-- streak emitter, splash + mist emitters at the base (mobile rates), mossy lip rocks and a rainbow arc.
-- Charlie TODO (optional): upload a white streak texture and swap the sheets for scrolling Beams.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Layout = require(script.Parent.Layout)

local Kit, P, Effects = Theme.Kit, Theme.Colors, Theme.Effects
local M = Enum.Material
local Waterfall = {}

function Waterfall.Build(parent: Instance)
	local m = Kit.Model(parent, "Waterfall")
	local top = Layout.WaterfallTop
	local h = top.Y
	-- Layered sheets: wide pale back sheet, brighter front sheet, thin highlight streaks.
	local back = Kit.Block(m, Vector3.new(20, h, 1), CFrame.new(top.X, h / 2, top.Z + 0.5), P.Water, M.Glass)
	back.Transparency = 0.35
	back.Name = "SheetBack"
	local front = Kit.Block(m, Vector3.new(15, h - 2, 0.6), CFrame.new(top.X, h / 2, top.Z + 1.6), Color3.fromHex("#8FE3F7"), M.Glass)
	front.Transparency = 0.45
	front.Name = "SheetFront"
	for i, x in { -5, -1.5, 2.5, 5.5 } do
		local streak = Kit.Block(m, Vector3.new(0.8, h - 4, 0.3), CFrame.new(top.X + x, h / 2, top.Z + 2.1), Color3.fromHex("#E8FAFF"))
		streak.Transparency = 0.3 + i * 0.08
		streak.CastShadow = false
	end
	-- Falling streak particles from a strip at the lip.
	local lip = Kit.Block(m, Vector3.new(16, 1, 2), CFrame.new(top.X, h + 0.5, top.Z + 2), P.Water)
	lip.Transparency = 1
	lip.Name = "Lip"
	Effects.Fall().Parent = lip
	-- Lip rocks + moss.
	for _, x in { -12, 12 } do
		Kit.Blob(m, Vector3.new(9, 7, 8), CFrame.new(top.X + x, h - 1, top.Z), P.Rock, M.Slate)
		Kit.Blob(m, Vector3.new(7, 2, 6), CFrame.new(top.X + x, h + 2.4, top.Z), P.Moss, M.Grass)
	end
	-- Base: splash + mist + foam disc.
	local base = Kit.Block(m, Vector3.new(18, 1, 6), CFrame.new(top.X, 0.5, top.Z + 4), P.Water)
	base.Transparency = 1
	base.Name = "Base"
	Effects.Splash().Parent = base
	base:AddTag("WaterfallSound")
	local mistHolder = Kit.Block(m, Vector3.new(18, 1, 6), CFrame.new(top.X, 1, top.Z + 6), P.Water)
	mistHolder.Transparency = 1
	mistHolder.Name = "MistSource"
	Effects.WaterMist().Parent = mistHolder
	local foam = Kit.Cyl(m, 0.3, 22, CFrame.new(top.X, -0.2, top.Z + 8), Color3.fromHex("#E8FAFF"))
	foam.Transparency = 0.4
	foam.CastShadow = false
	for k = 1, 6 do
		local a = k / 6 * math.pi
		Kit.Blob(m, Vector3.new(4, 3, 3.5), CFrame.new(top.X + math.cos(a) * 15, 0.4, top.Z + 8 + math.sin(a) * 9), P.Rock, M.Slate)
	end
	-- Rainbow arc: thin translucent SmoothPlastic segments (no large Neon).
	local colors = { "#FF8A8A", "#FFD27A", "#9BEA8A", "#7FD0FF", "#B9A4FF" }
	for band, hexc in colors do
		local r = 26 - band * 1.1
		for seg = 0, 8 do
			local a0 = math.rad(seg * 20)
			local a1 = math.rad((seg + 1) * 20)
			local p0 = Vector3.new(top.X - 6 + math.cos(a0) * r, 6 + math.sin(a0) * r * 0.9, top.Z + 14)
			local p1 = Vector3.new(top.X - 6 + math.cos(a1) * r, 6 + math.sin(a1) * r * 0.9, top.Z + 14)
			local mid = (p0 + p1) / 2
			local seg3 = Kit.Block(m, Vector3.new(0.9, 0.9, (p1 - p0).Magnitude + 0.3), CFrame.lookAt(mid, p1), Color3.fromHex(hexc), M.SmoothPlastic)
			seg3.Transparency = 0.7
			seg3.CastShadow = false
		end
	end
	Kit.Tag(m, "Waterfall")
	return m
end

return Waterfall
