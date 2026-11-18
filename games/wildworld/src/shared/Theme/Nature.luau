--!strict
-- Code-built nature kit (ART_STYLE_GUIDE §4): trees, bushes, flowers, rocks, logs, burrows, ponds.
-- Every builder takes (parent, cf at ground level, scale, rng) and builds straight into parent.
-- Used by the world scenery (server) and by Theme.Props build items (server + client ghost).
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)

local Nature = {}

local M = Enum.Material

local function leafColor(rng: Random, i: number, set: { Color3 }?): Color3
	local pal = set or { P.Leaf1, P.Leaf2, P.Leaf3 }
	return Kit.Jitter(pal[((i - 1) % #pal) + 1], rng, 0.05)
end

-- Round storybook tree: tapered trunk (2 cylinders) + 4 overlapping canopy balls. ~7 parts.
function Nature.Tree(parent: Instance, cf: CFrame, s: number, rng: Random, leaves: { Color3 }?)
	local trunk = Kit.Cyl(parent, 5 * s, 1.6 * s, cf * CFrame.new(0, 2.5 * s, 0), P.Trunk, M.Wood, true)
	trunk.Name = "Trunk"
	Kit.Cyl(parent, 3.5 * s, 1.1 * s, cf * CFrame.new(0, 6 * s, 0), P.Trunk, M.Wood)
	local tops = {
		{ 7.5, Vector3.new(0, 9, 0) },
		{ 5.5, Vector3.new(2.6, 8, 1) },
		{ 5.2, Vector3.new(-2.4, 8.4, -1.2) },
		{ 4.6, Vector3.new(0.5, 11.4, -0.4) },
	}
	for i, t in tops do
		local b = Kit.Ball(parent, t[1] * s, cf * CFrame.new(t[2] * s), leafColor(rng, i, leaves))
		b.CastShadow = i == 1
	end
end

-- Pine: trunk + 3 stacked squashed balls shrinking upward. ~4 parts.
function Nature.Pine(parent: Instance, cf: CFrame, s: number, rng: Random)
	local trunk = Kit.Cyl(parent, 4 * s, 1.3 * s, cf * CFrame.new(0, 2 * s, 0), P.Trunk, M.Wood, true)
	trunk.Name = "Trunk"
	local c = Kit.Jitter(P.PineLeaf, rng, 0.05)
	for i = 0, 2 do
		local w = (7 - i * 2) * s
		local b = Kit.Blob(parent, Vector3.new(w, 3.4 * s, w), cf * CFrame.new(0, (5 + i * 2.8) * s, 0), c)
		b.CastShadow = i == 0
	end
	Kit.Blob(parent, Vector3.new(1.6 * s, 2.4 * s, 1.6 * s), cf * CFrame.new(0, 12.4 * s, 0), c)
end

-- Magic tree (Waterfall Glade + hub centrepiece): curvy trunk, pink/purple canopy, hanging glow buds.
function Nature.MagicTree(parent: Instance, cf: CFrame, s: number, rng: Random, glowBuds: boolean?)
	local trunk = Kit.Cyl(parent, 6 * s, 2 * s, cf * CFrame.new(0, 3 * s, 0), P.Trunk, M.Wood, true)
	trunk.Name = "Trunk"
	Kit.Cyl(parent, 4 * s, 1.4 * s, cf * CFrame.new(0.4 * s, 7.5 * s, 0) * CFrame.Angles(0, 0, math.rad(-10)), P.Trunk, M.Wood)
	local set = if rng:NextNumber() < 0.5 then { P.MagicPink, P.MagicPurple } else { P.MagicPurple, P.MagicPink }
	local tops = {
		{ 8, Vector3.new(0.6, 11, 0) },
		{ 6, Vector3.new(3.6, 10, 1.2) },
		{ 6, Vector3.new(-2.8, 10.4, -1.4) },
		{ 5, Vector3.new(0.4, 13.6, 0.4) },
		{ 4.4, Vector3.new(-1.4, 9.4, 3) },
	}
	for i, t in tops do
		local b = Kit.Ball(parent, t[1] * s, cf * CFrame.new(t[2] * s), leafColor(rng, i, set))
		b.CastShadow = i == 1
	end
	if glowBuds then
		for k = 1, 4 do
			local a = math.rad(k * 90 + 20)
			local pos = Vector3.new(math.cos(a) * 3.6, 7.6, math.sin(a) * 3.6) * s
			local bud = Kit.Ball(parent, 0.8 * s, cf * CFrame.new(pos), P.Discovery, M.Neon)
			bud.Name = "GlowBud"
		end
	end
end

function Nature.Bush(parent: Instance, cf: CFrame, s: number, rng: Random, berries: boolean?)
	local c = leafColor(rng, rng:NextInteger(1, 3))
	Kit.Ball(parent, 3.4 * s, cf * CFrame.new(0, 1.2 * s, 0), c)
	Kit.Ball(parent, 2.6 * s, cf * CFrame.new(1.5 * s, 0.9 * s, 0.4 * s), Kit.Jitter(c, rng, 0.06))
	Kit.Ball(parent, 2.4 * s, cf * CFrame.new(-1.3 * s, 0.8 * s, -0.5 * s), Kit.Jitter(c, rng, 0.06))
	if berries then
		for k = 1, 3 do
			local a = rng:NextNumber(0, math.pi * 2)
			Kit.Ball(parent, 0.45 * s, cf * CFrame.new(math.cos(a) * 1.5 * s, 1.6 * s, math.sin(a) * 1.5 * s), P.Coral)
		end
	end
end

-- 2-part flower (stem + bloom head).
function Nature.Flower(parent: Instance, cf: CFrame, s: number, color: Color3)
	local stem = Kit.Block(parent, Vector3.new(0.18, 1.1, 0.18) * s, cf * CFrame.new(0, 0.55 * s, 0), P.Leaf1)
	stem.CastShadow = false
	local head = Kit.Blob(parent, Vector3.new(0.9, 0.45, 0.9) * s, cf * CFrame.new(0, 1.15 * s, 0), color)
	head.CastShadow = false
end

-- A tuft of 3–5 flowers.
function Nature.FlowerPatch(parent: Instance, cf: CFrame, s: number, rng: Random)
	local base = P.Flowers[rng:NextInteger(1, #P.Flowers)]
	for k = 1, rng:NextInteger(3, 5) do
		local off = Vector3.new(rng:NextNumber(-1.4, 1.4), 0, rng:NextNumber(-1.4, 1.4)) * s
		local col = if k == 1 then P.Flowers[rng:NextInteger(1, #P.Flowers)] else base
		Nature.Flower(parent, cf * CFrame.new(off), s * rng:NextNumber(0.8, 1.2), col)
	end
end

function Nature.Rock(parent: Instance, cf: CFrame, s: number, rng: Random, mossy: boolean?)
	local c = Kit.Jitter(if rng:NextNumber() < 0.5 then P.Rock else P.RockWarm, rng, 0.04)
	local r = Kit.Blob(parent, Vector3.new(4, 2.6, 3.2) * s, cf * CFrame.new(0, 0.9 * s, 0), c, M.Slate)
	r.CanCollide = true
	r.CanQuery = true
	Kit.Blob(parent, Vector3.new(2.2, 1.6, 2) * s, cf * CFrame.new(1.8 * s, 0.5 * s, 0.9 * s), Kit.Jitter(c, rng, 0.04), M.Slate)
	if mossy then
		local m = Kit.Blob(parent, Vector3.new(3, 0.8, 2.4) * s, cf * CFrame.new(-0.2 * s, 2 * s, 0), P.Moss, M.Grass)
		m.CastShadow = false
	end
end

function Nature.Log(parent: Instance, cf: CFrame, s: number)
	local log = Kit.Part(parent, {
		Size = Vector3.new(6, 1.6, 1.6) * s,
		CFrame = cf * CFrame.new(0, 0.8 * s, 0),
		Color = P.Trunk,
		Material = M.Wood,
		Shape = Enum.PartType.Cylinder,
		CanCollide = true,
		Name = "Log",
	})
	log.CanQuery = true
	for _, x in { -3, 3 } do
		local ring = Kit.Part(parent, {
			Size = Vector3.new(0.1, 1.3, 1.3) * s,
			CFrame = cf * CFrame.new(x * s, 0.8 * s, 0),
			Color = P.Path,
			Shape = Enum.PartType.Cylinder,
		})
		ring.CastShadow = false
	end
	Kit.Blob(parent, Vector3.new(2, 0.5, 1.2) * s, cf * CFrame.new(0.8 * s, 1.6 * s, 0), P.Moss, M.Grass)
end

-- Burrow: dirt mound with a dark entrance.
function Nature.Burrow(parent: Instance, cf: CFrame, s: number)
	Kit.Blob(parent, Vector3.new(6, 2.6, 5) * s, cf * CFrame.new(0, 0.6 * s, 0), P.Trunk, M.Ground)
	local hole = Kit.Blob(parent, Vector3.new(1.8, 1.6, 0.6) * s, cf * CFrame.new(0, 0.8 * s, -2.3 * s), Color3.fromHex("#3A2618"))
	hole.CastShadow = false
	Kit.Ball(parent, 0.8 * s, cf * CFrame.new(1.6 * s, 2 * s, 0.6 * s), P.Leaf2)
end

-- Flat round pond (part-based, sits on top of the plot floor).
function Nature.Pond(parent: Instance, cf: CFrame, s: number, rng: Random)
	local rim = Kit.Cyl(parent, 0.4, 11 * s, cf * CFrame.new(0, 0.2, 0), P.Sand, M.Sand)
	rim.CastShadow = false
	local w = Kit.Cyl(parent, 0.5, 9 * s, cf * CFrame.new(0, 0.3, 0), P.Water, M.Glass)
	w.Transparency = 0.25
	w.Name = "Water"
	for k = 1, 5 do
		local a = k / 5 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		Kit.Blob(parent, Vector3.new(1.4, 0.9, 1.2) * s, cf * CFrame.new(math.cos(a) * 5 * s, 0.4, math.sin(a) * 5 * s), P.Rock, M.Slate)
	end
	local pad = Kit.Cyl(parent, 0.1, 1.6 * s, cf * CFrame.new(1.5 * s, 0.58, -1 * s), P.Leaf2)
	pad.CastShadow = false
	Nature.Flower(parent, cf * CFrame.new(1.5 * s, 0.4, -1 * s), 0.7 * s, P.Flowers[1])
end

function Nature.Cloud(parent: Instance, cf: CFrame, s: number, rng: Random)
	for k = 1, 5 do
		local d = rng:NextNumber(10, 18) * s
		local b = Kit.Ball(parent, d, cf * CFrame.new((k - 3) * 7 * s, rng:NextNumber(-1, 3) * s, rng:NextNumber(-3, 3) * s), P.Cloud)
		b.Transparency = 0.05
		b.CastShadow = false
	end
end

return Nature
