--!strict
-- Brick build pieces (STUDS_STYLE_GUIDE §6): habitat pads (auto-fence + gate), fences, paths, feeders,
-- shelter, toys, lanterns, snack stand, bench, waterfall piece. Builders take (parent, cf at ground, rng).
-- Habitat feature colours are readable categories: feeders yellow, troughs blue, roofs red/blue.
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Effects = require(script.Parent.Effects)

local Structures = {}
local V = Vector3.new

local PAD_FLOOR = Color3.fromHex("#7ED05A")

-- Fence run along local X from -len/2..len/2: posts 1x3.6x1 every ~4 studs + 2 rails (1.2 tall, 1 deep).
function Structures.FenceRun(parent: Instance, cf: CFrame, len: number, color: Color3?)
	local c = color or P.Wood
	local n = math.max(1, math.floor(len / 4 + 0.5))
	for i = 0, n do
		local x = -len / 2 + len * i / n
		local post = Kit.Brick(parent, V(1, 3.6, 1), cf * CFrame.new(x, 1.8, 0), Kit.Shade(c, 0.9), "All", true)
		post.Name = "Post"
		post.CastShadow = false
	end
	for i, y in { 1.0, 2.6 } do
		local rail = Kit.Brick(parent, V(len, 1.2, 0.8), cf * CFrame.new(0, y, 0), if i == 1 then Kit.Shade(c) else c, "Top", true)
		rail.Name = "Rail"
		rail.CastShadow = false
	end
end

-- Habitat pad: studded floor plate, wood rim plates, fence on 3.5 sides, gate (4-stud gap + arch) on -Z.
function Structures.Pad(parent: Instance, cf: CFrame, size: number, rng: Random)
	local h = size / 2
	local floor = Kit.Brick(parent, V(size, 0.4, size), cf * CFrame.new(0, 0.2, 0), PAD_FLOOR, "Top", true)
	floor.Name = "Floor"
	floor.CastShadow = false
	for _, side in { { 0, h }, { 0, -h }, { h, 0 }, { -h, 0 } } do
		local alongX = side[1] == 0
		local rim = Kit.Brick(
			parent,
			if alongX then V(size + 1, 0.8, 1) else V(1, 0.8, size + 1),
			cf * CFrame.new(side[1], 0.4, side[2]),
			P.WoodDark,
			"Top"
		)
		rim.CastShadow = false
	end
	Structures.FenceRun(parent, cf * CFrame.new(0, 0.8, h), size)
	Structures.FenceRun(parent, cf * CFrame.new(h, 0.8, 0) * CFrame.Angles(0, math.rad(90), 0), size)
	Structures.FenceRun(parent, cf * CFrame.new(-h, 0.8, 0) * CFrame.Angles(0, math.rad(90), 0), size)
	local seg = (size - 4) / 2
	Structures.FenceRun(parent, cf * CFrame.new(-(2 + seg / 2), 0.8, -h), seg)
	Structures.FenceRun(parent, cf * CFrame.new(2 + seg / 2, 0.8, -h), seg)
	-- Gate arch
	local gate = Kit.Model(parent, "Gate")
	for _, x in { -2.5, 2.5 } do
		Kit.Brick(gate, V(1, 5.2, 1), cf * CFrame.new(x, 2.6, -h), P.WoodDark, "All", true)
	end
	local beam = Kit.Brick(gate, V(7, 1.2, 1), cf * CFrame.new(0, 5.8, -h), P.Wood, "Top")
	beam.Name = "Beam"
	local sign = Kit.Tile(gate, V(4, 1.2, 0.2), cf * CFrame.new(0, 5.8, -h - 0.6), P.White)
	sign.Name = "Sign"
	Kit.Label(sign, Enum.NormalId.Front, "Habitat", P.Text)
	-- Corner flower tufts + a leaf cube (cheap charm).
	for _, c in { { -1, 1 }, { 1, 1 } } do
		local col = P.Flowers[rng:NextInteger(1, #P.Flowers)]
		local base = cf * CFrame.new(c[1] * (h - 2), 0.4, c[2] * (h - 2))
		Kit.Brick(parent, V(2, 1.2, 2), base * CFrame.new(0, 0.6, 0), P.Leaf2, "All").CastShadow = false
		for k = 1, 2 do
			local head = Kit.Brick(parent, V(1, 0.4, 1), base * CFrame.new((k - 1.5) * 1.2, 1.8, -0.5), col, "Top")
			head.CastShadow = false
		end
	end
end

-- 4x4 path tile: Path plate with 1-stud PathEdge border plates on both sides.
function Structures.Path(parent: Instance, cf: CFrame)
	local t = Kit.Brick(parent, V(2, 0.4, 4), cf * CFrame.new(0, 0.2, 0), P.Path, "Top", true)
	t.CastShadow = false
	for _, x in { -1.5, 1.5 } do
		local e = Kit.Brick(parent, V(1, 0.4, 4), cf * CFrame.new(x, 0.2, 0), P.PathEdge, "Top", true)
		e.CastShadow = false
	end
end

-- Food bowl: 2x1.2x2 red brick, yellow food plate ("Food") + yellow 1x1 food cubes.
function Structures.FoodBowl(parent: Instance, cf: CFrame)
	Kit.Brick(parent, V(2, 1.2, 2), cf * CFrame.new(0, 0.6, 0), P.Red, "All", true)
	local food = Kit.Brick(parent, V(2, 0.4, 2), cf * CFrame.new(0, 1.4, 0), P.Food, "Top")
	food.Name = "Food"
	for k, o in { V(-0.5, 0, -0.5), V(0.5, 0, 0.5) } do
		local cube = Kit.Brick(parent, V(1, 0.8, 1), cf * CFrame.new(o + V(0, 2.0, 0)), if k == 1 then P.Food else Kit.Shade(P.Food), "Top")
		cube.CastShadow = false
	end
end

function Structures.WaterTrough(parent: Instance, cf: CFrame)
	Kit.Brick(parent, V(4, 1.2, 2), cf * CFrame.new(0, 0.6, 0), P.Wood, "All", true)
	local w = Kit.Tile(parent, V(3.4, 0.2, 1.4), cf * CFrame.new(0, 1.25, 0), P.Water)
	w.Transparency = 0.2
	w.Name = "Water"
	for _, x in { -2.5, 2.5 } do
		Kit.Brick(parent, V(1, 1.6, 2), cf * CFrame.new(x, 0.8, 0), P.Blue, "Top")
	end
end

-- Shelter hut: studded wood brick walls, red/blue wedge roof, straw plate.
function Structures.ShelterHut(parent: Instance, cf: CFrame, rng: Random)
	local roof = P.Roofs[rng:NextInteger(1, #P.Roofs)]
	for _, x in { -2.5, 2.5 } do
		Kit.Brick(parent, V(1, 3.6, 5), cf * CFrame.new(x, 1.8, 0), P.Wood, "All", true)
	end
	Kit.Brick(parent, V(4, 3.6, 1), cf * CFrame.new(0, 1.8, 2), Kit.Shade(P.Wood), "All", true)
	local l = Kit.Wedge(parent, V(7, 2.4, 3), cf * CFrame.new(0, 4.8, 1.5) * CFrame.Angles(0, math.rad(180), 0), roof)
	local r = Kit.Wedge(parent, V(7, 2.4, 3), cf * CFrame.new(0, 4.8, -1.5), Kit.Shade(roof))
	l.CastShadow, r.CastShadow = true, true
	local straw = Kit.Brick(parent, V(4, 0.4, 3), cf * CFrame.new(0, 0.2, 0), P.Yellow, "Top")
	straw.CastShadow = false
end

-- Toy ball stays round (round prop) with a white stripe.
function Structures.ToyBall(parent: Instance, cf: CFrame, rng: Random)
	local b = Kit.Ball(parent, 2, cf * CFrame.new(0, 1, 0), P.Toys[rng:NextInteger(1, #P.Toys)])
	b.Name = "Ball"
	local stripe = Kit.Part(parent, {
		Size = V(0.5, 2.05, 2.05),
		CFrame = cf * CFrame.new(0, 1, 0),
		Color = P.White,
		Shape = Enum.PartType.Cylinder,
	})
	stripe.CastShadow = false
end

-- Lantern: brick post + arm, SmoothPlastic lamp box that glows at night (tag NightLight, PointLight off by day).
function Structures.Lantern(parent: Instance, cf: CFrame)
	Kit.Brick(parent, V(1, 6, 1), cf * CFrame.new(0, 3, 0), P.WoodDark, "All", true)
	Kit.Brick(parent, V(2, 0.4, 1), cf * CFrame.new(1, 6.2, 0), P.WoodDark, "Top")
	Kit.Brick(parent, V(2, 0.4, 2), cf * CFrame.new(1.5, 5.8, 0), P.Red, "Top").CastShadow = false
	local lamp = Kit.Tile(parent, V(1.2, 1.6, 1.2), cf * CFrame.new(1.5, 4.8, 0), P.Lantern)
	lamp.Name = "Lamp"
	lamp:SetAttribute("GlowAtNight", true)
	local light = Instance.new("PointLight")
	light.Color = P.Lantern
	light.Range = 14
	light.Brightness = 1.2
	light.Shadows = false
	light.Enabled = false
	light.Parent = lamp
	lamp:AddTag("NightLight")
	lamp:AddTag("Lantern")
end

function Structures.Bench(parent: Instance, cf: CFrame)
	Kit.Brick(parent, V(5, 0.4, 2), cf * CFrame.new(0, 1.4, 0), P.Wood, "Top", true)
	Kit.Brick(parent, V(5, 1.2, 0.4), cf * CFrame.new(0, 2.2, 0.8), Kit.Shade(P.Wood), "Top")
	for _, x in { -2, 2 } do
		Kit.Brick(parent, V(1, 1.2, 2), cf * CFrame.new(x, 0.6, 0), P.WoodDark, "All")
	end
end

-- Snack stand: white brick counter, posts, alternating 1-stud awning stripes, sign.
function Structures.SnackStand(parent: Instance, cf: CFrame, rng: Random)
	local aw = P.Awnings[rng:NextInteger(1, #P.Awnings)]
	Kit.Brick(parent, V(6, 2.8, 3), cf * CFrame.new(0, 1.4, 0.5), P.White, "All", true)
	Kit.Brick(parent, V(6, 0.4, 3), cf * CFrame.new(0, 3.0, 0.5), P.Wood, "Top")
	for _, x in { -2.5, 2.5 } do
		Kit.Brick(parent, V(1, 4, 1), cf * CFrame.new(x, 5.2, 1.5), P.WoodDark, "All")
	end
	for i = 0, 5 do
		local col = if i % 2 == 0 then aw else P.White
		local w = Kit.Wedge(parent, V(1, 1.2, 4), cf * CFrame.new(-2.5 + i, 7.8, 0), col)
		w.CastShadow = i == 0
	end
	local sign = Kit.Tile(parent, V(4, 1.2, 0.2), cf * CFrame.new(0, 9, 1.6), P.White)
	Kit.Label(sign, Enum.NormalId.Back, "Snacks", P.Text)
	Kit.Brick(parent, V(1, 1, 1), cf * CFrame.new(-1.5, 3.7, 0), P.Red, "All")
	Kit.Brick(parent, V(1, 1, 1), cf * CFrame.new(1.5, 3.7, 0), P.Yellow, "All")
end

function Structures.SandPatch(parent: Instance, cf: CFrame, rng: Random)
	local s = Kit.Brick(parent, V(7, 0.4, 7), cf * CFrame.new(0, 0.2, 0), P.Sand, "Top", true)
	s.CastShadow = false
	for _ = 1, 3 do
		local shell = Kit.Brick(parent, V(1, 0.4, 1), cf * CFrame.new(rng:NextInteger(-2, 2), 0.6, rng:NextInteger(-2, 2)), P.White, "Top")
		shell.CastShadow = false
	end
end

-- Sunspot: warm basking stone brick on a soft glow plate.
function Structures.Sunspot(parent: Instance, cf: CFrame)
	local ring = Kit.Tile(parent, V(6, 0.2, 6), cf * CFrame.new(0, 0.1, 0), P.Discovery)
	ring.Transparency = 0.45
	ring.CastShadow = false
	Kit.Brick(parent, V(4, 0.8, 3), cf * CFrame.new(0, 0.4, 0), Color3.fromHex("#E8B87A"), "Top", true)
end

-- Waterfall piece: stone brick stack, stepped translucent blue water bricks, basin with rim.
function Structures.Waterfall(parent: Instance, cf: CFrame, rng: Random)
	Kit.Brick(parent, V(7, 6, 3), cf * CFrame.new(0, 3, 2.5), P.Stone, "Top", true)
	Kit.Brick(parent, V(3, 2.4, 3), cf * CFrame.new(-2, 7.2, 2.5), P.StoneDark, "All")
	Kit.Brick(parent, V(3, 1.2, 3), cf * CFrame.new(2, 6.6, 2.5), P.RockWarm, "All")
	Kit.Brick(parent, V(3, 0.4, 3), cf * CFrame.new(-2, 8.6, 2.5), P.Moss, "Top")
	for k = 0, 2 do
		local step = Kit.Brick(parent, V(3, 2, 1), cf * CFrame.new(0, 5 - k * 2, 0.5 - k * 0.6), if k % 2 == 0 then P.Water else Kit.Shade(P.Water, 1.1), "Top")
		step.Transparency = 0.35
		step.CastShadow = false
		if k == 0 then
			step.Name = "Fall"
		end
	end
	local basin = Kit.Tile(parent, V(7, 0.4, 4), cf * CFrame.new(0, 0.4, -1.5), P.Water)
	basin.Transparency = 0.35
	basin.Name = "Water"
	Kit.Brick(parent, V(7, 0.4, 4), cf * CFrame.new(0, 0.2, -1.5), P.WaterDeep, "Top").CastShadow = false
	Kit.Brick(parent, V(7, 1.2, 1), cf * CFrame.new(0, 0.6, -3.5), P.Stone, "Top", true)
	local splash = Effects.Splash()
	splash.Rate = 6
	splash.Speed = NumberRange.new(6, 10)
	splash.Parent = basin
	Kit.Brick(parent, V(1, 1, 1), cf * CFrame.new(3, 1.7, -3.5), P.Leaf2, "All")
	if rng:NextNumber() < 0.5 then
		Kit.Brick(parent, V(1, 0.4, 1), cf * CFrame.new(-3, 1.4, -3.5), P.Flowers[1], "Top")
	end
end

return Structures
