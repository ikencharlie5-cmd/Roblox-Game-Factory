--!strict
-- Special decor build pieces: pass/starter/RP/shop-rare items + a few small-footprint nature pieces.
-- Builders take (parent, cf at ground, rng). Glow comes from small Neon accents + PointLights (no big Neon).
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Effects = require(script.Parent.Effects)
local Nature = require(script.Parent.Nature)

local Decor = {}
local M = Enum.Material
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

local function shard(parent: Instance, cf: CFrame, len: number, color: Color3): Part
	local s = Kit.Block(parent, Vector3.new(0.9, len, 0.9), cf * CFrame.new(0, len / 2, 0) * CFrame.Angles(0, math.rad(45), 0), color, M.Glass)
	s.Transparency = 0.25
	return s
end

function Decor.BigRock(parent: Instance, cf: CFrame, rng: Random)
	Nature.Rock(parent, cf * CFrame.new(-0.6, 0, 0.4), 1.5, rng, true)
	local cave = Kit.Blob(parent, Vector3.new(2.4, 2, 0.6), cf * CFrame.new(-0.6, 1, -2.3), hex("#3A3442"))
	cave.CastShadow = false
end

function Decor.Sunspot(parent: Instance, cf: CFrame)
	local ring = Kit.Cyl(parent, 0.1, 3.8, cf * CFrame.new(0, 0.05, 0), P.Discovery)
	ring.Transparency = 0.45
	ring.CastShadow = false
	local stone = Kit.Blob(parent, Vector3.new(3, 0.8, 2.6), cf * CFrame.new(0, 0.35, 0), hex("#E8B87A"), M.Sandstone)
	stone.CanCollide = true
end

function Decor.SmallBurrow(parent: Instance, cf: CFrame)
	Nature.Burrow(parent, cf, 0.62)
end

function Decor.VipFountain(parent: Instance, cf: CFrame)
	Kit.Cyl(parent, 1, 7.6, cf * CFrame.new(0, 0.5, 0), GOLD, M.Metal, true)
	local water = Kit.Cyl(parent, 0.2, 6.4, cf * CFrame.new(0, 1.05, 0), P.Water, M.Glass)
	water.Transparency = 0.2
	Kit.Cyl(parent, 3, 0.9, cf * CFrame.new(0, 2.5, 0), GOLD, M.Metal)
	local bowl = Kit.Blob(parent, Vector3.new(3, 0.8, 3), cf * CFrame.new(0, 4, 0), GOLD, M.Metal)
	Kit.Ball(parent, 1.1, cf * CFrame.new(0, 4.8, 0), hex("#FFE59A"), M.Metal)
	Effects.Sparkle(hex("#FFE27A"), 3).Parent = bowl
	local e = Effects.Splash()
	e.Rate = 5
	e.Speed = NumberRange.new(5, 8)
	e.Parent = bowl
end

function Decor.CrystalCluster(parent: Instance, cf: CFrame, rng: Random)
	local base = Kit.Blob(parent, Vector3.new(3.4, 0.8, 3.4), cf * CFrame.new(0, 0.3, 0), P.Rock, M.Slate)
	for k = 1, 4 do
		local a = k / 4 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local tilt = CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), 0, math.rad(rng:NextNumber(-20, 20)))
		shard(parent, cf * CFrame.new(math.cos(a) * 0.8, 0.3, math.sin(a) * 0.8) * tilt, rng:NextNumber(1.6, 3.2), CRYSTAL)
	end
	light(base, CRYSTAL, 8, false)
end

function Decor.GlowShroom(parent: Instance, cf: CFrame, rng: Random)
	for k = 1, 3 do
		local s = ({ 1.2, 0.8, 0.6 })[k]
		local off = CFrame.new((k - 2) * 1.1, 0, rng:NextNumber(-0.6, 0.6))
		Kit.Cyl(parent, 1.4 * s, 0.5 * s, cf * off * CFrame.new(0, 0.7 * s, 0), P.Cream)
		local cap = Kit.Blob(parent, Vector3.new(2, 0.9, 2) * s, cf * off * CFrame.new(0, 1.5 * s, 0), P.MagicPurple, if k == 1 then M.SmoothPlastic else M.Neon)
		if k == 1 then
			light(cap, P.MagicPurple, 8, true)
		end
	end
end

function Decor.GrottoArch(parent: Instance, cf: CFrame, rng: Random)
	for _, x in { -5, 5 } do
		Kit.Solid(parent, Vector3.new(2, 8, 2.4), cf * CFrame.new(x, 4, 0), P.Rock, M.Slate)
		shard(parent, cf * CFrame.new(x, 7.5, 0) * CFrame.Angles(0, 0, math.rad(x * -3)), 2.4, CRYSTAL)
	end
	Kit.Blob(parent, Vector3.new(12.5, 2.4, 2.6), cf * CFrame.new(0, 8.6, 0), P.Rock, M.Slate)
	local top = shard(parent, cf * CFrame.new(0, 9.4, 0), 2.6, CRYSTAL)
	light(top, CRYSTAL, 10, false)
	Kit.Blob(parent, Vector3.new(5, 0.6, 2), cf * CFrame.new(rng:NextNumber(-2, 2), 9.8, 0), P.Moss, M.Grass)
end

function Decor.StarterArch(parent: Instance, cf: CFrame)
	for _, x in { -5, 5 } do
		Kit.Solid(parent, Vector3.new(1.2, 8, 1.2), cf * CFrame.new(x, 4, 0), P.WoodDark, M.Wood)
		Kit.Ball(parent, 2.2, cf * CFrame.new(x, 8.4, 0), P.Leaf2)
	end
	Kit.Block(parent, Vector3.new(11.4, 0.8, 1), cf * CFrame.new(0, 7.6, 0), P.Wood, M.Wood)
	local sign = Kit.Block(parent, Vector3.new(7, 1.6, 0.3), cf * CFrame.new(0, 6.4, -0.4), P.Teal)
	Kit.Label(sign, Enum.NormalId.Front, "Explorer's Park", P.Discovery, true)
	for k = 0, 4 do
		Kit.Ball(parent, 0.6, cf * CFrame.new(-4 + k * 2, 8.2, -0.5), P.Flowers[k + 1])
	end
end

function Decor.FieldTent(parent: Instance, cf: CFrame)
	local c = P.Coral
	local l = Kit.Wedge(parent, Vector3.new(7, 4.5, 3.4), cf * CFrame.new(0, 2.25, 1.7) * CFrame.Angles(0, math.pi, 0), c)
	local r = Kit.Wedge(parent, Vector3.new(7, 4.5, 3.4), cf * CFrame.new(0, 2.25, -1.7), P.Parchment)
	l.CanCollide, r.CanCollide = true, true
	Kit.Cyl(parent, 5.4, 0.3, cf * CFrame.new(-3.6, 2.7, 0), P.WoodDark, M.Wood)
	local flag = Kit.Block(parent, Vector3.new(0.1, 0.8, 1.2), cf * CFrame.new(-3.6, 5, 0.6), P.Teal)
	flag.CastShadow = false
end

function Decor.JournalSign(parent: Instance, cf: CFrame)
	Kit.Cyl(parent, 4, 0.5, cf * CFrame.new(0, 2, 0), P.WoodDark, M.Wood, true)
	local board = Kit.Block(parent, Vector3.new(3.4, 2.2, 0.3), cf * CFrame.new(0, 4, -0.3), P.Parchment)
	Kit.Label(board, Enum.NormalId.Front, "Field Notes", P.Teal)
	Kit.Ball(parent, 0.5, cf * CFrame.new(1.4, 5, -0.4), P.Coral)
end

function Decor.MossStatue(parent: Instance, cf: CFrame)
	Kit.Solid(parent, Vector3.new(3, 1, 3), cf * CFrame.new(0, 0.5, 0), P.RockWarm, M.Slate)
	Kit.Blob(parent, Vector3.new(2.6, 1.6, 3), cf * CFrame.new(0, 1.9, 0.2), P.Rock, M.Slate)
	Kit.Ball(parent, 1.8, cf * CFrame.new(0, 2.6, -1), P.Rock, M.Slate)
	Kit.Ball(parent, 1.6, cf * CFrame.new(0, 2.9, 0.3), P.Moss, M.Grass)
	Kit.Ball(parent, 0.4, cf * CFrame.new(0.3, 3.7, 0.2), P.Flowers[1])
end

function Decor.RainbowFlowers(parent: Instance, cf: CFrame, rng: Random)
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		local col = Color3.fromHSV(k / 6, 0.55, 1)
		Nature.Flower(parent, cf * CFrame.new(math.cos(a) * 1.1, 0, math.sin(a) * 1.1), rng:NextNumber(0.9, 1.2), col)
	end
end

function Decor.StoneTotem(parent: Instance, cf: CFrame)
	local cols = { P.Rock, P.RockWarm, P.Rock }
	for k = 1, 3 do
		Kit.Solid(parent, Vector3.new(2.2 - k * 0.3, 1.6, 2.2 - k * 0.3), cf * CFrame.new(0, k * 1.6 - 0.8, 0) * CFrame.Angles(0, k * 0.4, 0), cols[k], M.Slate)
	end
	local eye = Kit.Ball(parent, 0.5, cf * CFrame.new(0, 4, -0.85), P.Water, M.Neon)
	eye.CastShadow = false
end

return Decor
