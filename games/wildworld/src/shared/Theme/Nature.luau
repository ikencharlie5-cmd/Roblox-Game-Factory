--!strict
-- Brick nature kit (STUDS_STYLE_GUIDE §6): trees, bushes, flowers, rocks, logs, burrows, ponds, clouds.
-- Every builder takes (parent, cf at ground level, scale, rng) and builds straight into parent.
-- Sizes are snapped to the stud grid after scaling (whole-stud X/Z, 0.4 plates in Y) so studs line up.
-- Used by the world scenery (server) and by Theme.Props build items (server + client ghost).
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)

local Nature = {}

local V = Vector3.new
local snap = Kit.Snap

-- Stack of square layers on top of y0. layers = { {width, height, colour} } bottom -> top. Returns top y.
local function stack(parent: Instance, cf: CFrame, y0: number, s: number, layers: { { any } }, studs: Kit.Studs?): number
	local y = y0
	for i, l in layers do
		local size = snap(V(l[1] * s, l[2] * s, l[1] * s))
		local b = Kit.Brick(parent, size, cf * CFrame.new(0, y + size.Y / 2, 0), l[3], studs or "All", i == 1)
		b.Name = "Canopy" .. i
		b.CastShadow = i <= 2
		y += size.Y
	end
	return y
end

local function trunk(parent: Instance, cf: CFrame, w: number, h: number, s: number): number
	local size = snap(V(w * s, h * s, w * s))
	local t = Kit.Brick(parent, size, cf * CFrame.new(0, size.Y / 2, 0), P.Trunk, "All", true)
	t.Name = "Trunk"
	t.CanQuery = true
	return size.Y
end

-- Brick oak: trunk 2x6x2 + canopy 8x2.4x8 / 6x2.4x6 / 4x1.2x4. 4 parts.
function Nature.Tree(parent: Instance, cf: CFrame, s: number, rng: Random, leaves: { Color3 }?)
	local pal = leaves or { P.Leaf1, P.Leaf2, P.Leaf3 }
	local h = trunk(parent, cf, 2, 6, s)
	local j = function(c: Color3): Color3
		return Kit.Jitter(c, rng, 0.03)
	end
	stack(parent, cf, h - 0.4, s, {
		{ 8, 2.4, j(pal[1]) },
		{ 6, 2.4, j(pal[2] or pal[1]) },
		{ 4, 1.2, j(pal[3] or pal[2] or pal[1]) },
	})
end

-- Brick pine: short trunk + 4 squares 7/5/3/1 wide, 1.6 tall, alternating ×0.95 shade.
function Nature.Pine(parent: Instance, cf: CFrame, s: number, rng: Random)
	local c = Kit.Jitter(P.PineLeaf, rng, 0.03)
	local h = trunk(parent, cf, 2, 3.2, s)
	stack(parent, cf, h, s, {
		{ 7, 1.6, c },
		{ 5, 1.6, Kit.Shade(c) },
		{ 3, 1.6, c },
		{ 1, 1.6, Kit.Shade(c) },
	})
end

-- Magic tree (Glade + Heart Tree): oak shape in pink/purple layers + 2 Neon 1x1 glow buds.
function Nature.MagicTree(parent: Instance, cf: CFrame, s: number, rng: Random, glowBuds: boolean?)
	local a, b = P.MagicPink, P.MagicPurple
	if rng:NextNumber() < 0.5 then
		a, b = b, a
	end
	local h = trunk(parent, cf, 2, 7.2, s)
	stack(parent, cf, h - 0.4, s, {
		{ 9, 2.4, a },
		{ 7, 2.4, b },
		{ 5, 2.4, a },
		{ 3, 1.2, Kit.Shade(b) },
	})
	if glowBuds then
		-- Hang under opposite corners of the bottom canopy layer.
		local w = snap(V(9 * s, 1, 9 * s)).X
		local d = snap(V(s, s, s))
		for _, side in { -1, 1 } do
			local pos = CFrame.new(side * (w / 2 - d.X / 2), h - 0.4 - d.Y / 2, side * (w / 2 - d.X / 2))
			local bud = Kit.Brick(parent, d, cf * pos, P.Discovery)
			bud.Material = Enum.Material.Neon
			bud.Name = "GlowBud"
			bud.CastShadow = false
		end
	end
end

-- Bush: 3x2.4x3 + 2x1.2x2 offset brick, optional red berry cubes.
function Nature.Bush(parent: Instance, cf: CFrame, s: number, rng: Random, berries: boolean?)
	local c = Kit.Jitter(({ P.Leaf1, P.Leaf2, P.Leaf2 })[rng:NextInteger(1, 3)], rng, 0.03)
	local big = snap(V(3, 2.4, 3) * s)
	Kit.Brick(parent, big, cf * CFrame.new(0, big.Y / 2, 0), c, "All").Name = "Bush"
	local small = snap(V(2, 1.2, 2) * s)
	local off = math.floor(big.X / 2)
	Kit.Brick(parent, small, cf * CFrame.new(off * 0.5, big.Y + small.Y / 2, off * 0.5), Kit.Shade(c, 1.08), "All").CastShadow = false
	if berries then
		for k = 1, 3 do
			local a = k * 2.1
			local berry = Kit.Brick(parent, V(0.6, 0.6, 0.6), cf * CFrame.new(math.cos(a) * big.X / 2, big.Y * 0.6, math.sin(a) * big.Z / 2), P.Red, "Top")
			berry.CastShadow = false
		end
	end
end

-- 2-part flower: stem 0.4x1.2x0.4 + 1x0.4x1 coloured plate.
function Nature.Flower(parent: Instance, cf: CFrame, s: number, color: Color3)
	local k = math.max(0.6, s)
	local stem = Kit.Brick(parent, V(0.4, 1.2, 0.4) * k, cf * CFrame.new(0, 0.6 * k, 0), P.Leaf1, "None")
	stem.CastShadow = false
	local head = Kit.Brick(parent, V(1, 0.4, 1) * k, cf * CFrame.new(0, 1.4 * k, 0), color, "Top")
	head.CastShadow = false
	head.Name = "Bloom"
end

-- A tuft of 3–5 flowers on a 1-stud grid.
function Nature.FlowerPatch(parent: Instance, cf: CFrame, s: number, rng: Random)
	local base = P.Flowers[rng:NextInteger(1, #P.Flowers)]
	for k = 1, rng:NextInteger(3, 5) do
		local off = V(rng:NextInteger(-1, 1) * 1.2, 0, rng:NextInteger(-1, 1) * 1.2) * s
		local col = if k == 1 then P.Flowers[rng:NextInteger(1, #P.Flowers)] else base
		Nature.Flower(parent, cf * CFrame.new(off), s * (0.9 + 0.1 * (k % 3)), col)
	end
end

-- Rock: 2–3 offset Stone / StoneDark bricks; mossy = green plate on top.
function Nature.Rock(parent: Instance, cf: CFrame, s: number, rng: Random, mossy: boolean?)
	local c = Kit.Jitter(if rng:NextNumber() < 0.6 then P.Stone else P.RockWarm, rng, 0.03)
	local a = snap(V(4, 2.4, 3) * s)
	local r = Kit.Brick(parent, a, cf * CFrame.new(0, a.Y / 2, 0), c, "All", true)
	r.CanQuery = true
	r.Name = "Rock"
	local b = snap(V(2, 1.2, 2) * s)
	Kit.Brick(parent, b, cf * CFrame.new(a.X / 2, b.Y / 2, a.Z / 2 - 0.5), P.StoneDark, "All")
	if rng:NextNumber() < 0.5 then
		local t = snap(V(2, 1.2, 2) * s)
		Kit.Brick(parent, t, cf * CFrame.new(-0.5, a.Y + t.Y / 2, 0), Kit.Shade(c), "All").CastShadow = false
	end
	if mossy then
		local m = Kit.Brick(parent, snap(V(3, 0.4, 2) * s), cf * CFrame.new(0.5, a.Y + 0.2, -0.5), P.Moss, "Top")
		m.CastShadow = false
	end
end

-- Log: 6x2x2 brown brick lying along X, light end tiles, moss plate on top.
function Nature.Log(parent: Instance, cf: CFrame, s: number)
	local size = snap(V(6, 2, 2) * s)
	local log = Kit.Brick(parent, size, cf * CFrame.new(0, size.Y / 2, 0), P.Wood, "All", true)
	log.CanQuery = true
	log.Name = "Log"
	for _, side in { -1, 1 } do
		local ring = Kit.Tile(parent, V(0.1, size.Y - 0.4, size.Z - 0.4), cf * CFrame.new(side * (size.X / 2 + 0.05), size.Y / 2, 0), P.Path)
		ring.CastShadow = false
	end
	Kit.Brick(parent, snap(V(2, 0.4, 2) * s), cf * CFrame.new(s, size.Y + 0.2, 0), P.Moss, "Top").CastShadow = false
end

-- Burrow: stepped dirt mound with a dark entrance tile and a leaf cube.
function Nature.Burrow(parent: Instance, cf: CFrame, s: number)
	local a = snap(V(6, 1.2, 5) * s)
	local b = snap(V(4, 1.2, 3) * s)
	Kit.Brick(parent, a, cf * CFrame.new(0, a.Y / 2, 0), P.Dirt, "Top", true)
	Kit.Brick(parent, b, cf * CFrame.new(0, a.Y + b.Y / 2, 0.5 * s), Kit.Shade(P.Dirt, 1.08), "All")
	local hole = Kit.Tile(parent, V(2 * s, 1.6 * s, 0.1), cf * CFrame.new(0, 0.9 * s, -a.Z / 2 - 0.05), Color3.fromHex("#2B1D14"))
	hole.CastShadow = false
	hole.Name = "Hole"
	Kit.Brick(parent, snap(V(1, 1, 1) * s), cf * CFrame.new(1.5 * s, a.Y + b.Y + 0.5 * s, 0.5 * s), P.Leaf2, "All")
end

-- Square pond (sits on top of the plot floor): stone rim bricks, blue floor plate, translucent water
-- surface, lily-pad plate + flower.
function Nature.Pond(parent: Instance, cf: CFrame, s: number, rng: Random)
	local w = math.max(5, math.floor(11 * s + 0.5))
	local floor = Kit.Brick(parent, V(w, 0.4, w), cf * CFrame.new(0, 0.2, 0), P.WaterDeep, "Top")
	floor.CastShadow = false
	for _, side in { -1, 1 } do
		Kit.Brick(parent, V(w, 1.2, 1), cf * CFrame.new(0, 0.6, side * (w / 2 + 0.5)), P.Stone, "Top", true)
		Kit.Brick(parent, V(1, 1.2, w + 2), cf * CFrame.new(side * (w / 2 + 0.5), 0.6, 0), Kit.Shade(P.Stone), "Top", true)
	end
	local water = Kit.Tile(parent, V(w, 0.4, w), cf * CFrame.new(0, 0.8, 0), P.Water)
	water.Transparency = 0.35
	water.Reflectance = 0.1
	water.Name = "Water"
	local px, pz = rng:NextInteger(-1, 1) * 2, -2
	local pad = Kit.Brick(parent, V(2, 0.4, 2), cf * CFrame.new(px, 1.0, pz), P.Leaf2, "Top")
	pad.CastShadow = false
	Nature.Flower(parent, cf * CFrame.new(px, 1.2, pz), 0.6, P.Flowers[4])
end

-- Blocky cloud: 3 flat white SmoothPlastic blocks (8x2x6, 6x2x4, 4x1.6x4) × scale.
function Nature.Cloud(parent: Instance, cf: CFrame, s: number, rng: Random)
	local k = s * 3
	local pieces = {
		{ V(8, 2, 6), V(0, 0, 0) },
		{ V(6, 2, 4), V(rng:NextInteger(-2, 2), 2, rng:NextInteger(-1, 1)) },
		{ V(4, 1.6, 4), V(rng:NextInteger(3, 5), 0.6, rng:NextInteger(-1, 1)) },
	}
	for _, p in pieces do
		local b = Kit.Tile(parent, p[1] * k, cf * CFrame.new(p[2] * k), P.Cloud)
		b.Transparency = 0.05
		b.CastShadow = false
		b.Name = "Cloud"
	end
end

return Nature
