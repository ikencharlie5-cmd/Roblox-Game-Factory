--!strict
-- Special decor build pieces (pass / starter / RP / shop-rare items + small nature pieces), brick style.
-- Builders take (parent, cf at ground, rng). Glow comes from small Neon accents + PointLights (no big Neon).
-- Crystals are "trans-clear" toy bricks: Plastic, Transparency 0.3, Reflectance 0.15, studs on.
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Effects = require(script.Parent.Effects)
local Nature = require(script.Parent.Nature)

local Decor = {}
local V = Vector3.new
local hex = Color3.fromHex
local CRYSTAL = hex("#9FE8FF")
local GOLD = hex("#F5C542")

local function light(parent: BasePart, color: Color3, range: number, nightOnly: boolean)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 0.8
	l.Shadows = false
	l.Enabled = not nightOnly
	l.Parent = parent
	if nightOnly then
		parent:AddTag("NightLight")
	end
end

-- Crystal brick stack: 0.8x1.2x0.8 + 0.6x0.8x0.6 (×k), rotated 45° on Y. Returns the top brick.
local function crystal(parent: Instance, cf: CFrame, k: number, color: Color3?): Part
	local c = color or CRYSTAL
	local rot = cf * CFrame.Angles(0, math.rad(45), 0)
	local a = V(0.8, 1.2, 0.8) * k
	local b = V(0.6, 0.8, 0.6) * k
	local lo = Kit.Brick(parent, a, rot * CFrame.new(0, a.Y / 2, 0), c, "All")
	local hi = Kit.Brick(parent, b, rot * CFrame.new(0, a.Y + b.Y / 2, 0), c, "All")
	for _, p in { lo, hi } do
		p.Transparency = 0.3
		p.Reflectance = 0.15
		p.CastShadow = false
		p.Name = "Crystal"
	end
	return hi
end

local function gold(p: BasePart): BasePart
	p.Reflectance = 0.2
	return p
end

function Decor.BigRock(parent: Instance, cf: CFrame, rng: Random)
	Kit.Brick(parent, V(6, 3.6, 5), cf * CFrame.new(0, 1.8, 0.5), P.Stone, "All", true)
	Kit.Brick(parent, V(4, 2.4, 4), cf * CFrame.new(-1, 4.8, 1), P.StoneDark, "All", true)
	Kit.Brick(parent, V(3, 2.4, 3), cf * CFrame.new(2.5, 1.2, -1.5), Kit.Shade(P.Stone), "All")
	Kit.Brick(parent, V(3, 0.4, 3), cf * CFrame.new(-1 + rng:NextInteger(0, 1), 6.2, 1), P.Moss, "Top").CastShadow = false
	local cave = Kit.Tile(parent, V(2.4, 2, 0.1), cf * CFrame.new(-0.6, 1.2, -2.05), hex("#2E2A33"))
	cave.CastShadow = false
	cave.Name = "Cave"
end

function Decor.Sunspot(parent: Instance, cf: CFrame)
	local ring = Kit.Tile(parent, V(4, 0.1, 4), cf * CFrame.new(0, 0.05, 0), P.Discovery)
	ring.Transparency = 0.45
	ring.CastShadow = false
	Kit.Brick(parent, V(3, 0.8, 2), cf * CFrame.new(0, 0.4, 0), hex("#E8B87A"), "Top", true)
end

function Decor.SmallBurrow(parent: Instance, cf: CFrame)
	Nature.Burrow(parent, cf, 0.62)
end

-- Golden studded fountain: gold Plastic bricks (Reflectance 0.2) + water plate + sparkle/splash.
function Decor.VipFountain(parent: Instance, cf: CFrame)
	gold(Kit.Brick(parent, V(7, 1.2, 7), cf * CFrame.new(0, 0.6, 0), GOLD, "Top", true))
	local water = Kit.Tile(parent, V(6, 0.2, 6), cf * CFrame.new(0, 1.3, 0), P.Water)
	water.Transparency = 0.3
	water.Name = "Water"
	gold(Kit.Brick(parent, V(1, 3.2, 1), cf * CFrame.new(0, 2.8, 0), GOLD, "All"))
	local bowl = gold(Kit.Brick(parent, V(3, 0.8, 3), cf * CFrame.new(0, 4.8, 0), GOLD, "All"))
	gold(Kit.Brick(parent, V(1, 1.2, 1), cf * CFrame.new(0, 5.8, 0), hex("#FFE59A"), "All"))
	Effects.Sparkle(hex("#FFE27A"), 3).Parent = bowl
	local e = Effects.Splash()
	e.Rate = 5
	e.Speed = NumberRange.new(5, 8)
	e.Parent = bowl
end

function Decor.CrystalCluster(parent: Instance, cf: CFrame, rng: Random)
	local base = Kit.Brick(parent, V(3, 0.8, 3), cf * CFrame.new(0, 0.4, 0), P.Stone, "Top", true)
	local offs = { V(-0.6, 0, -0.6), V(0.7, 0, -0.4), V(-0.4, 0, 0.7), V(0.6, 0, 0.6) }
	for k, o in offs do
		crystal(parent, cf * CFrame.new(o + V(0, 0.8, 0)), if k == 1 then 1.8 else rng:NextNumber(1, 1.4))
	end
	light(base, CRYSTAL, 8, false)
end

-- 3 shrooms: cream stem cube + cap plate (first one Plastic + night light, others Neon).
function Decor.GlowShroom(parent: Instance, cf: CFrame, rng: Random)
	for k = 1, 3 do
		local s = ({ 1.2, 0.8, 0.6 })[k]
		local off = CFrame.new((k - 2) * 1.2, 0, rng:NextInteger(-1, 1) * 0.5)
		Kit.Brick(parent, V(1, 1.2, 1) * s, cf * off * CFrame.new(0, 0.6 * s, 0), P.Cream, "All")
		local cap = Kit.Brick(parent, V(2, 0.8, 2) * s, cf * off * CFrame.new(0, 1.6 * s, 0), P.MagicPurple, "Top")
		cap.CastShadow = false
		if k == 1 then
			light(cap, P.MagicPurple, 8, true)
		else
			cap.Material = Enum.Material.Neon
		end
	end
end

function Decor.GrottoArch(parent: Instance, cf: CFrame, rng: Random)
	for _, x in { -5, 5 } do
		Kit.Brick(parent, V(2, 8, 2), cf * CFrame.new(x, 4, 0), P.Stone, "All", true)
		Kit.Brick(parent, V(2, 1.2, 2), cf * CFrame.new(x, 1.8, 0), P.StoneDark, "All")
		crystal(parent, cf * CFrame.new(x, 8, 0), 1.4)
	end
	Kit.Brick(parent, V(12, 2.4, 2), cf * CFrame.new(0, 9.2, 0), Kit.Shade(P.Stone), "All")
	local top = crystal(parent, cf * CFrame.new(0, 10.4, 0), 1.6)
	light(top, CRYSTAL, 10, false)
	Kit.Brick(parent, V(5, 0.4, 2), cf * CFrame.new(rng:NextInteger(-2, 2), 10.6, 0), P.Moss, "Top").CastShadow = false
end

function Decor.StarterArch(parent: Instance, cf: CFrame)
	for _, x in { -5, 5 } do
		Kit.Brick(parent, V(1, 8, 1), cf * CFrame.new(x, 4, 0), P.WoodDark, "All", true)
		Kit.Brick(parent, V(2, 2, 2), cf * CFrame.new(x, 9, 0), P.Leaf2, "All")
	end
	Kit.Brick(parent, V(12, 0.8, 1), cf * CFrame.new(0, 7.6, 0), P.Wood, "Top")
	local sign = Kit.Tile(parent, V(7, 1.6, 0.3), cf * CFrame.new(0, 6.4, -0.5), P.Teal)
	Kit.Label(sign, Enum.NormalId.Front, "Explorer's Park", P.Discovery, true)
	for k = 0, 4 do
		Kit.Brick(parent, V(1, 0.4, 1), cf * CFrame.new(-4 + k * 2, 8.2, 0), P.Flowers[k + 1], "Top").CastShadow = false
	end
end

-- Little brick creature statue: stone base, body, big head, moss plate + flower.
function Decor.MossStatue(parent: Instance, cf: CFrame)
	Kit.Brick(parent, V(3, 1.2, 3), cf * CFrame.new(0, 0.6, 0), P.RockWarm, "All", true)
	Kit.Brick(parent, V(2, 1.6, 3), cf * CFrame.new(0, 2, 0.2), P.Stone, "All")
	Kit.Brick(parent, V(3, 2.4, 2), cf * CFrame.new(0, 3.6, -0.8), P.Stone, "All")
	for _, x in { -0.7, 0.7 } do
		Kit.Tile(parent, V(0.6, 0.8, 0.1), cf * CFrame.new(x, 3.8, -1.85), P.Eye).CastShadow = false
	end
	Kit.Brick(parent, V(2, 0.4, 2), cf * CFrame.new(0, 5, -0.5), P.Moss, "Top").CastShadow = false
	Kit.Brick(parent, V(1, 0.4, 1), cf * CFrame.new(0.5, 5.4, -0.5), P.Flowers[4], "Top").CastShadow = false
end

function Decor.RainbowFlowers(parent: Instance, cf: CFrame, rng: Random)
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		local col = Color3.fromHSV(k / 6, 0.55, 1)
		Nature.Flower(parent, cf * CFrame.new(math.cos(a) * 1.2, 0, math.sin(a) * 1.2), rng:NextNumber(0.9, 1.2), col)
	end
end

return Decor
