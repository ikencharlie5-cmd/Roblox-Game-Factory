--!strict
-- Code-built man-made build pieces: habitat pads (auto-fence + gate), fences, paths, feeders,
-- shelter, toys, lanterns, snack stand, bench, waterfall piece. Builders take (parent, cf at ground, rng).
-- Habitat feature colours are readable categories (§4): feeders yellow, troughs blue, roofs red/teal.
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Effects = require(script.Parent.Effects)

local Structures = {}
local M = Enum.Material

local PAD_FLOOR = Color3.fromHex("#A5E07A")

-- Low fence run along local X from -len/2..len/2 (2.5 studs high, posts every ~4 studs).
function Structures.FenceRun(parent: Instance, cf: CFrame, len: number, color: Color3?)
	local c = color or P.Wood
	local n = math.max(1, math.floor(len / 4 + 0.5))
	for i = 0, n do
		local x = -len / 2 + len * i / n
		local post = Kit.Solid(parent, Vector3.new(0.6, 2.8, 0.6), cf * CFrame.new(x, 1.4, 0), c, M.Wood)
		post.Name = "Post"
		post.CastShadow = false
		local cap = Kit.Ball(parent, 0.75, cf * CFrame.new(x, 2.9, 0), P.WoodDark)
		cap.CastShadow = false
	end
	for _, y in { 1.0, 2.1 } do
		local rail = Kit.Solid(parent, Vector3.new(len, 0.35, 0.3), cf * CFrame.new(0, y, 0), c, M.Wood)
		rail.Name = "Rail"
	end
end

-- Habitat pad: raised floor, wood rim, fence on 3.5 sides, gate (4-stud gap + arch) on local -Z.
function Structures.Pad(parent: Instance, cf: CFrame, size: number, rng: Random)
	local h = size / 2
	local floor = Kit.Solid(parent, Vector3.new(size, 0.4, size), cf * CFrame.new(0, 0.2, 0), PAD_FLOOR, M.Grass)
	floor.Name = "Floor"
	floor.CastShadow = false
	for _, side in { { 0, h }, { 0, -h }, { h, 0 }, { -h, 0 } } do
		local alongX = side[1] == 0
		local rim = Kit.Block(
			parent,
			if alongX then Vector3.new(size + 0.8, 0.6, 0.8) else Vector3.new(0.8, 0.6, size + 0.8),
			cf * CFrame.new(side[1], 0.3, side[2]),
			P.WoodDark,
			M.Wood
		)
		rim.CastShadow = false
	end
	-- Fences: back (+Z), left, right full; front split around the gate.
	Structures.FenceRun(parent, cf * CFrame.new(0, 0, h), size)
	Structures.FenceRun(parent, cf * CFrame.new(h, 0, 0) * CFrame.Angles(0, math.rad(90), 0), size)
	Structures.FenceRun(parent, cf * CFrame.new(-h, 0, 0) * CFrame.Angles(0, math.rad(90), 0), size)
	local seg = (size - 4) / 2
	Structures.FenceRun(parent, cf * CFrame.new(-(2 + seg / 2), 0, -h), seg)
	Structures.FenceRun(parent, cf * CFrame.new(2 + seg / 2, 0, -h), seg)
	-- Gate arch
	local gate = Kit.Model(parent, "Gate")
	for _, x in { -2.2, 2.2 } do
		Kit.Solid(gate, Vector3.new(0.8, 4.6, 0.8), cf * CFrame.new(x, 2.3, -h), P.WoodDark, M.Wood)
	end
	local beam = Kit.Block(gate, Vector3.new(5.6, 0.8, 1), cf * CFrame.new(0, 4.8, -h), P.Wood, M.Wood)
	beam.Name = "Beam"
	local sign = Kit.Block(gate, Vector3.new(3.6, 1.2, 0.2), cf * CFrame.new(0, 4.8, -h - 0.6), P.Parchment)
	sign.Name = "Sign"
	Kit.Label(sign, Enum.NormalId.Front, "Habitat", P.Text)
	-- Corner flower tufts (cheap charm)
	for _, c in { { -1, 1 }, { 1, 1 } } do
		local col = P.Flowers[rng:NextInteger(1, #P.Flowers)]
		local base = cf * CFrame.new(c[1] * (h - 1.5), 0.4, c[2] * (h - 1.5))
		for k = 1, 3 do
			local off = CFrame.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
			local head = Kit.Blob(parent, Vector3.new(0.8, 0.4, 0.8), base * off * CFrame.new(0, 0.9, 0), col)
			head.CastShadow = false
			if k == 1 then
				Kit.Ball(parent, 1.4, base * CFrame.new(0, 0.5, 0), P.Leaf2)
			end
		end
	end
end

-- 4x4 path tile with a raised edge strip on both sides.
function Structures.Path(parent: Instance, cf: CFrame)
	local t = Kit.Solid(parent, Vector3.new(4, 0.25, 4), cf * CFrame.new(0, 0.125, 0), P.Path)
	t.CastShadow = false
	for _, x in { -1.85, 1.85 } do
		local e = Kit.Block(parent, Vector3.new(0.3, 0.3, 4), cf * CFrame.new(x, 0.15, 0), P.PathEdge)
		e.CastShadow = false
	end
end

function Structures.FoodBowl(parent: Instance, cf: CFrame)
	Kit.Cyl(parent, 0.8, 2.6, cf * CFrame.new(0, 0.4, 0), P.Food, M.SmoothPlastic, true)
	local food = Kit.Blob(parent, Vector3.new(2.1, 0.7, 2.1), cf * CFrame.new(0, 0.85, 0), P.Coral)
	food.Name = "Food"
	for k = 1, 3 do
		local a = k * 2.1
		Kit.Ball(parent, 0.5, cf * CFrame.new(math.cos(a) * 0.6, 1.1, math.sin(a) * 0.6), P.Leaf3)
	end
end

function Structures.WaterTrough(parent: Instance, cf: CFrame)
	Kit.Solid(parent, Vector3.new(4, 1, 1.8), cf * CFrame.new(0, 0.5, 0), P.Wood, M.Wood)
	local w = Kit.Block(parent, Vector3.new(3.5, 0.2, 1.3), cf * CFrame.new(0, 1.0, 0), P.Water, M.Glass)
	w.Transparency = 0.2
	w.Name = "Water"
	for _, x in { -1.8, 1.8 } do
		Kit.Block(parent, Vector3.new(0.3, 1.2, 2), cf * CFrame.new(x, 0.6, 0), P.Water)
	end
end

function Structures.ShelterHut(parent: Instance, cf: CFrame, rng: Random)
	local roof = P.Roofs[rng:NextInteger(1, #P.Roofs)]
	for _, x in { -2.6, 2.6 } do
		Kit.Solid(parent, Vector3.new(0.6, 3.6, 4.6), cf * CFrame.new(x, 1.8, 0), P.Wood, M.WoodPlanks)
	end
	Kit.Solid(parent, Vector3.new(5.8, 3.6, 0.6), cf * CFrame.new(0, 1.8, 2.3), P.Wood, M.WoodPlanks)
	local l = Kit.Wedge(parent, Vector3.new(6.8, 2.2, 3), cf * CFrame.new(0, 4.7, 1.3) * CFrame.Angles(0, math.rad(180), 0), roof)
	local r = Kit.Wedge(parent, Vector3.new(6.8, 2.2, 3), cf * CFrame.new(0, 4.7, -1.3), roof)
	l.CastShadow, r.CastShadow = true, true
	local straw = Kit.Blob(parent, Vector3.new(4, 0.6, 3.2), cf * CFrame.new(0, 0.3, 0.2), P.Food)
	straw.CastShadow = false
end

function Structures.ToyBall(parent: Instance, cf: CFrame, rng: Random)
	local b = Kit.Ball(parent, 2, cf * CFrame.new(0, 1, 0), P.Toys[rng:NextInteger(1, #P.Toys)])
	b.Name = "Ball"
	local stripe = Kit.Part(parent, {
		Size = Vector3.new(0.5, 2.05, 2.05),
		CFrame = cf * CFrame.new(0, 1, 0),
		Color = P.Cream,
		Shape = Enum.PartType.Cylinder,
	})
	stripe.CastShadow = false
end

-- Lantern: post + Neon-free lamp head that glows at night (tag NightLight, PointLight off by day).
function Structures.Lantern(parent: Instance, cf: CFrame)
	Kit.Cyl(parent, 6, 0.5, cf * CFrame.new(0, 3, 0), P.WoodDark, M.Wood, true)
	Kit.Block(parent, Vector3.new(2, 0.3, 0.4), cf * CFrame.new(0.6, 6, 0), P.WoodDark, M.Wood)
	local lamp = Kit.Blob(parent, Vector3.new(1.2, 1.5, 1.2), cf * CFrame.new(1.3, 5.2, 0), P.Lantern)
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
	Kit.Solid(parent, Vector3.new(5, 0.4, 1.6), cf * CFrame.new(0, 1.4, 0), P.Wood, M.WoodPlanks)
	Kit.Block(parent, Vector3.new(5, 1.2, 0.3), cf * CFrame.new(0, 2.3, 0.75), P.Wood, M.WoodPlanks)
	for _, x in { -2, 2 } do
		Kit.Block(parent, Vector3.new(0.4, 1.4, 1.4), cf * CFrame.new(x, 0.7, 0), P.WoodDark, M.Wood)
	end
end

-- Snack stand: counter, striped awning, little sign.
function Structures.SnackStand(parent: Instance, cf: CFrame, rng: Random)
	local aw = P.Awnings[rng:NextInteger(1, #P.Awnings)]
	Kit.Solid(parent, Vector3.new(6, 3, 3), cf * CFrame.new(0, 1.5, 0.5), P.Cream)
	Kit.Block(parent, Vector3.new(6.4, 0.4, 3.4), cf * CFrame.new(0, 3.2, 0.5), P.Wood, M.Wood)
	for _, x in { -2.8, 2.8 } do
		Kit.Cyl(parent, 4, 0.4, cf * CFrame.new(x, 5, 1.6), P.WoodDark, M.Wood)
	end
	for i = 0, 5 do
		local col = if i % 2 == 0 then aw else P.Cream
		local w = Kit.Wedge(parent, Vector3.new(1.1, 1.2, 4.4), cf * CFrame.new(-2.75 + i * 1.1, 7.4, 0.2), col)
		w.CastShadow = i == 0
	end
	local sign = Kit.Block(parent, Vector3.new(4, 1.2, 0.2), cf * CFrame.new(0, 8.4, 1.6), P.Parchment)
	Kit.Label(sign, Enum.NormalId.Back, "Snacks", P.Text)
	Kit.Ball(parent, 1, cf * CFrame.new(-1.6, 3.9, -0.4), P.Coral)
	Kit.Ball(parent, 1, cf * CFrame.new(1.4, 3.9, -0.4), P.Food)
end

function Structures.SandPatch(parent: Instance, cf: CFrame, rng: Random)
	local s = Kit.Blob(parent, Vector3.new(7.6, 0.5, 7.6), cf * CFrame.new(0, 0.1, 0), P.Sand, M.Sand)
	s.CastShadow = false
	for k = 1, 3 do
		Kit.Ball(parent, 0.4, cf * CFrame.new(rng:NextNumber(-2.5, 2.5), 0.35, rng:NextNumber(-2.5, 2.5)), P.Cream)
	end
end

-- Sunspot: a warm flat basking stone with a soft glow ring.
function Structures.Sunspot(parent: Instance, cf: CFrame)
	local ring = Kit.Cyl(parent, 0.1, 6.5, cf * CFrame.new(0, 0.1, 0), P.Discovery)
	ring.Transparency = 0.45
	ring.CastShadow = false
	local stone = Kit.Blob(parent, Vector3.new(4.6, 0.9, 3.8), cf * CFrame.new(0, 0.4, 0), Color3.fromHex("#E8B87A"), M.Sandstone)
	stone.CanCollide = true
end

-- Waterfall piece: rock stack with a falling-water sheet and a small basin.
function Structures.Waterfall(parent: Instance, cf: CFrame, rng: Random)
	Kit.Solid(parent, Vector3.new(7, 7, 2.6), cf * CFrame.new(0, 3.5, 2.4), P.Rock, M.Slate)
	Kit.Blob(parent, Vector3.new(4, 3, 3), cf * CFrame.new(-2.8, 7, 2.4), P.Rock, M.Slate)
	Kit.Blob(parent, Vector3.new(3.4, 2.6, 3), cf * CFrame.new(2.8, 6.6, 2.6), P.RockWarm, M.Slate)
	Kit.Blob(parent, Vector3.new(3, 0.8, 2), cf * CFrame.new(2.4, 8, 2.4), P.Moss, M.Grass)
	local sheet = Kit.Block(parent, Vector3.new(2.6, 6.6, 0.3), cf * CFrame.new(0, 3.6, 0.9), P.Water, M.Glass)
	sheet.Transparency = 0.3
	sheet.Name = "Fall"
	local basin = Kit.Cyl(parent, 0.5, 7, cf * CFrame.new(0, 0.3, -1.2), P.Water, M.Glass)
	basin.Transparency = 0.25
	local splash = Effects.Splash()
	splash.Rate = 6
	splash.Speed = NumberRange.new(6, 10)
	splash.Parent = basin
	for k = 1, 4 do
		local a = k / 4 * math.pi + math.pi
		Kit.Blob(parent, Vector3.new(1.4, 0.9, 1.2), cf * CFrame.new(math.cos(a) * 3.6, 0.4, -1.2 + math.sin(a) * 3.6), P.Rock, M.Slate)
	end
	Kit.Ball(parent, 1.2, cf * CFrame.new(3.4, 0.6, -2.8), P.Leaf2)
	if rng:NextNumber() < 0.5 then
		Kit.Ball(parent, 0.6, cf * CFrame.new(-3.4, 0.9, -2.8), P.Flowers[1])
	end
end

return Structures
