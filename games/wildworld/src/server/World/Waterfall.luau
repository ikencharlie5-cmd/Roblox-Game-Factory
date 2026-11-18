--!strict
-- The meadow's signature waterfall (back edge, pours into the lake), brick style: stepped translucent blue Plastic bricks (each step juts a
-- little further out going down) + highlight streaks, the falling-streak emitter, splash + mist emitters at
-- the base (mobile rates), stone lip bricks with moss plates and a brick rainbow arc.
-- Charlie TODO (optional): upload a white streak texture and swap the sheets for scrolling Beams.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Layout = require(script.Parent.Layout)

local Kit, P, Effects = Theme.Kit, Theme.Colors, Theme.Effects
local V = Vector3.new
local Waterfall = {}

function Waterfall.Build(parent: Instance)
	local m = Kit.Model(parent, "Waterfall")
	local top = Layout.WaterfallTop
	local h = top.Y
	-- Stepped water bricks: 7 steps of ~8 studs, each 0.6 further out, alternating two blues.
	local steps = 7
	local sh = h / steps
	for i = 0, steps - 1 do
		local y = h - (i + 0.5) * sh
		local col = if i % 2 == 0 then P.Water else Color3.fromHex("#8FD3FF")
		local step = Kit.Brick(m, V(18, sh, 2), CFrame.new(top.X, y, top.Z + 1 + i * 0.6), col, "Top")
		step.Transparency = 0.35
		step.CastShadow = false
		step.Name = if i == 0 then "SheetBack" elseif i == steps - 1 then "SheetFront" else "Step" .. i
	end
	for i, x in { -5, -1, 3, 6 } do
		local streak = Kit.Tile(m, V(1, h - 4, 0.3), CFrame.new(top.X + x, h / 2, top.Z + 5.4), Color3.fromHex("#E8FAFF"))
		streak.Transparency = 0.3 + i * 0.08
		streak.CastShadow = false
	end
	-- Falling streak particles from a strip at the lip.
	local lip = Kit.Block(m, V(16, 1, 2), CFrame.new(top.X, h + 0.5, top.Z + 2), P.Water)
	lip.Transparency = 1
	lip.Name = "Lip"
	Effects.Fall().Parent = lip
	-- Lip bricks + moss plates.
	for _, x in { -13, 13 } do
		Kit.Brick(m, V(8, 7.2, 8), CFrame.new(top.X + x, h - 1.2, top.Z), P.Stone, "Top", true)
		Kit.Brick(m, V(6, 0.8, 6), CFrame.new(top.X + x, h + 2.8, top.Z), P.Moss, "Top")
	end
	-- Base: splash + mist + foam disc.
	local base = Kit.Block(m, V(18, 1, 6), CFrame.new(top.X, 0.5, top.Z + 4), P.Water)
	base.Transparency = 1
	base.Name = "Base"
	Effects.Splash().Parent = base
	base:AddTag("WaterfallSound")
	local mistHolder = Kit.Block(m, V(18, 1, 6), CFrame.new(top.X, 1, top.Z + 6), P.Water)
	mistHolder.Transparency = 1
	mistHolder.Name = "MistSource"
	Effects.WaterMist().Parent = mistHolder
	local foam = Kit.Tile(m, V(18, 0.2, 8), CFrame.new(top.X, 0.9, top.Z + 9), Color3.fromHex("#E8FAFF"))
	foam.Transparency = 0.4
	foam.CastShadow = false
	for k = 1, 6 do
		local a = k / 6 * math.pi
		local pos = CFrame.new(top.X + math.floor(math.cos(a) * 15), 1.2, top.Z + 8 + math.floor(math.sin(a) * 9))
		Kit.Brick(m, V(4, 2.4, 4), pos, if k % 2 == 0 then P.Stone else P.StoneDark, "Top", true)
	end
	-- Rainbow arc: thin translucent SmoothPlastic segments (no large Neon).
	local colors = { "#FF8A8A", "#FFD27A", "#9BEA8A", "#7FD0FF", "#B9A4FF" }
	for band, hexc in colors do
		local r = 26 - band * 1.1
		for seg = 0, 8 do
			local a0 = math.rad(seg * 20)
			local a1 = math.rad((seg + 1) * 20)
			local p0 = V(top.X - 6 + math.cos(a0) * r, 6 + math.sin(a0) * r * 0.9, top.Z + 14)
			local p1 = V(top.X - 6 + math.cos(a1) * r, 6 + math.sin(a1) * r * 0.9, top.Z + 14)
			local mid = (p0 + p1) / 2
			local seg3 = Kit.Tile(m, V(1, 1, (p1 - p0).Magnitude + 0.3), CFrame.lookAt(mid, p1), Color3.fromHex(hexc))
			seg3.Transparency = 0.6
			seg3.CastShadow = false
		end
	end
	Kit.Tag(m, "Waterfall")
	return m
end

return Waterfall
