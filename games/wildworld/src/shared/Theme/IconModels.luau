--!strict
-- Small studded brick models for UI icons (ViewportFrame renders, 3/4 view, front = -Z). Same palette and
-- brick rules as the world (Kit.Brick, studs on 5 faces). No particles (viewports don't render them).
--   IconModels.Build(name) -> Model?   unparented; PrimaryPart "Root" (invisible, bounding-box centre),
--                                      pivot = bounding-box centre; model attribute IconName.
--   IconModels.Names                   list of every supported name (aliases resolve via IconModels.Alias).
-- Names: Coin, RP, Berry, Honey, Starfruit, VIP, ExtraIncubator, AutoFeeder, CrystalGrotto,
--   CoinsSmall, CoinsMedium, CoinsLarge, StarterPack, InstantHatch, Egg, EggCommon/Uncommon/Rare/Epic, EggGolden.
-- Aliases: Coins, Bait<Fruit>, InstantHatch1..3, Config.GamePasses / DevProducts keys.
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Structures = require(script.Parent.Structures)
local Decor = require(script.Parent.Decor)

local IconModels = {}

local V = Vector3.new
local hex = Color3.fromHex
local GOLD = hex("#F5C542")
local GOLD_DARK = hex("#D9A21E")
local GOLD_LIGHT = hex("#FFE27A")

type Builder = (m: Model) -> ()

local function b(m: Model, size: Vector3, pos: Vector3, color: Color3, studs: Kit.Studs?): Part
	local p = Kit.Brick(m, size, CFrame.new(pos), color, studs or "All")
	p.CastShadow = false
	return p
end

local function cf(m: Model, size: Vector3, c: CFrame, color: Color3, studs: Kit.Studs?): Part
	local p = Kit.Brick(m, size, c, color, studs or "All")
	p.CastShadow = false
	return p
end

local function tile(m: Model, size: Vector3, pos: Vector3, color: Color3): Part
	local p = Kit.Tile(m, size, CFrame.new(pos), color)
	p.CastShadow = false
	return p
end

local function gold(p: Part): Part
	p.Reflectance = 0.2
	return p
end

-- Upright coin facing -Z: two crossed bricks make a pixel octagon, darker rim inset + raised centre plate.
local function uprightCoin(m: Model, at: Vector3)
	gold(b(m, V(4, 2, 0.8), at, GOLD))
	gold(b(m, V(2, 4, 0.8), at, GOLD))
	gold(b(m, V(3, 3, 0.8), at, GOLD))
	gold(b(m, V(2, 2, 0.4), at + V(0, 0, -0.6), GOLD_DARK))
	tile(m, V(0.6, 1.2, 0.1), at + V(-0.6, 0.4, -0.45), GOLD_LIGHT)
end

-- Flat coin lying down (pile pieces): crossed plates, 0.4 tall.
local function flatCoin(m: Model, at: Vector3, alt: boolean)
	local c = if alt then GOLD_DARK else GOLD
	gold(b(m, V(3, 0.4, 2), at, c, "Top"))
	gold(b(m, V(2, 0.4, 3), at, c, "Top"))
end

local function coinStack(m: Model, at: Vector3, n: number)
	for k = 1, n do
		flatCoin(m, at + V(if k % 2 == 0 then 0.15 else 0, 0.2 + (k - 1) * 0.4, 0), k % 2 == 0)
	end
end

-- Stacked brick egg (same profile as CreatureBuilder eggs) + 2 spot tiles.
local function egg(m: Model, at: Vector3, color: Color3, spot: Color3, isGold: boolean?)
	local layers = { { 1.6, 0.4 }, { 2.4, 0.8 }, { 2.4, 0.8 }, { 2, 0.8 }, { 1.2, 0.4 } }
	local y = 0
	for i, l in layers do
		local col = if i % 2 == 0 then Kit.Shade(color) else color
		local p = b(m, V(l[1], l[2], l[1]), at + V(0, y + l[2] / 2, 0), col)
		if isGold then
			gold(p)
		end
		y += l[2]
	end
	tile(m, V(0.6, 0.4, 0.1), at + V(-0.5, 1.4, -1.25), spot)
	tile(m, V(0.4, 0.4, 0.1), at + V(0.5, 2.2, -1.05), spot)
end

local EGG_SPOT = hex("#9FD6F0")
local function eggOf(tier: string, at: Vector3?): Builder
	local o = at or V(0, 0, 0)
	return function(m)
		if tier == "Golden" then
			egg(m, o, GOLD, GOLD_LIGHT, true)
			return
		end
		local tint = (P.EggRarity :: { [string]: Color3 })[tier] or P.White
		local h, s, v = tint:ToHSV()
		egg(m, o, tint, if tier == "Common" then EGG_SPOT else Color3.fromHSV(h, math.min(1, s + 0.15), v * 0.75))
	end
end

local BUILDERS: { [string]: Builder } = {
	Coin = function(m)
		uprightCoin(m, V(0, 2, 0))
	end,
	-- Blue gem: inverted brick pyramid turned 45°, trans-blue with a bright top plate.
	RP = function(m)
		local rot = CFrame.Angles(0, math.rad(45), 0)
		local rows = { { 1, 0.8 }, { 2, 0.8 }, { 3, 0.8 }, { 4, 0.8 }, { 3, 0.4 } }
		local y = 0
		for i, r in rows do
			local p = cf(m, V(r[1], r[2], r[1]), CFrame.new(0, y + r[2] / 2, 0) * rot, if i % 2 == 0 then P.Blue else hex("#4DA6FF"))
			p.Reflectance = 0.15
			y += r[2]
		end
		local top = cf(m, V(2, 0.4, 2), CFrame.new(0, y + 0.2, 0) * rot, hex("#BFE3FF"), "Top")
		top.Material = Enum.Material.Neon
	end,
	-- Bait fruit
	Berry = function(m)
		local red, dark = P.Red, Kit.Shade(P.Red, 0.85)
		b(m, V(2, 2, 2), V(-1, 1, 0.3), red)
		b(m, V(2, 2, 2), V(1, 1, 0.3), dark)
		b(m, V(2, 2, 2), V(0, 2.6, -0.2), red)
		b(m, V(1, 0.8, 1), V(0, 4, -0.2), P.WoodDark)
		b(m, V(2, 0.4, 1), V(0.9, 4.2, -0.2), P.Leaf2, "Top")
		tile(m, V(0.4, 0.4, 0.1), V(-0.4, 3, -1.25), P.White)
	end,
	Honey = function(m)
		local amber = hex("#F2A33A")
		b(m, V(3, 0.8, 3), V(0, 0.4, 0), Kit.Shade(amber))
		b(m, V(4, 2, 4), V(0, 1.8, 0), amber)
		b(m, V(3, 0.8, 3), V(0, 3.2, 0), Kit.Shade(amber))
		b(m, V(2, 0.4, 2), V(0, 3.8, 0), P.Cream)
		b(m, V(3, 0.4, 3), V(0, 4.2, 0), P.Wood, "Top")
		b(m, V(1, 0.8, 1), V(0, 4.8, 0), P.WoodDark)
		tile(m, V(2, 0.8, 0.1), V(0, 1.8, -2.05), P.Cream)
		tile(m, V(0.6, 1.2, 0.1), V(1, 3, -1.55), P.Yellow)
	end,
	Starfruit = function(m)
		local c = V(0, 2.4, 0)
		b(m, V(2, 2, 1.2), c, P.Yellow)
		for k = 0, 4 do
			local a = math.rad(k * 72)
			local dir = V(-math.sin(a), math.cos(a), 0)
			cf(m, V(1, 1.4, 1.2), CFrame.new(c + dir * 1.5) * CFrame.Angles(0, 0, a), if k % 2 == 0 then P.Yellow else Kit.Shade(P.Yellow))
		end
		b(m, V(1, 0.4, 0.4), c + V(0, 0, -0.75), GOLD_LIGHT, "None")
		b(m, V(0.4, 0.8, 0.4), c + V(0, 2.6, 0), P.Leaf1)
	end,
	-- Game Passes
	VIP = function(m)
		gold(b(m, V(5, 1.6, 5), V(0, 0.8, 0), GOLD))
		for _, x in { -2, 0, 2 } do
			for _, z in { -2, 2 } do
				local h = if x == 0 then 1.6 else 1.2
				gold(b(m, V(1, h, 1), V(x, 1.6 + h / 2, z), GOLD))
				gold(b(m, V(1, h, 1), V(z, 1.6 + h / 2, x), GOLD))
			end
		end
		tile(m, V(1, 0.8, 0.1), V(0, 0.9, -2.55), P.Red)
		tile(m, V(0.6, 0.6, 0.1), V(-1.6, 0.9, -2.55), P.Blue)
		tile(m, V(0.6, 0.6, 0.1), V(1.6, 0.9, -2.55), P.Blue)
	end,
	ExtraIncubator = function(m)
		b(m, V(5, 0.8, 5), V(0, 0.4, 0), P.WoodDark)
		for _, o in { V(0, 0, -2), V(0, 0, 2), V(-2, 0, 0), V(2, 0, 0) } do
			local wide = o.X == 0
			b(m, if wide then V(5, 0.8, 1) else V(1, 0.8, 3), V(0, 1.2, 0) + o, P.Wood)
		end
		b(m, V(3, 0.4, 3), V(0, 1, 0), P.Sand, "Top")
		eggOf("Common", V(0, 1.2, 0))(m)
		-- green "+" badge
		b(m, V(1, 2.4, 0.8), V(2.6, 4, -1), P.Leaf2)
		b(m, V(2.4, 1, 0.8), V(2.6, 4, -1), P.Leaf2)
	end,
	AutoFeeder = function(m)
		Structures.FoodBowl(m, CFrame.new(-0.6, 0, -0.6))
		local g = V(1.4, 3.2, 1.2)
		b(m, V(2, 2, 0.8), g, P.Stone)
		b(m, V(1, 1, 0.8), g + V(0, 0, -0.2), P.StoneDark)
		for k = 0, 7 do
			local a = math.rad(k * 45)
			cf(m, V(0.8, 0.8, 0.8), CFrame.new(g + V(math.cos(a), math.sin(a), 0) * 1.4) * CFrame.Angles(0, 0, a), P.Stone)
		end
	end,
	CrystalGrotto = function(m)
		Decor.CrystalCluster(m, CFrame.new(), Random.new(7))
	end,
	-- Coin packs (3 / 6 / 10 coins)
	CoinsSmall = function(m)
		coinStack(m, V(0, 0, 0), 3)
	end,
	CoinsMedium = function(m)
		coinStack(m, V(-1.4, 0, 0.4), 4)
		coinStack(m, V(1.4, 0, -0.4), 2)
	end,
	CoinsLarge = function(m)
		coinStack(m, V(-2.2, 0, 0.6), 4)
		coinStack(m, V(0.4, 0, 1), 3)
		coinStack(m, V(2.4, 0, -0.6), 2)
		uprightCoin(m, V(0, 2.4, -1.2))
	end,
	StarterPack = function(m)
		b(m, V(4, 3, 4), V(0, 1.5, 0), P.Red)
		b(m, V(5, 0.8, 5), V(0, 3.4, 0), Kit.Shade(P.Red, 0.9))
		b(m, V(1, 3.2, 4.2), V(0, 1.6, 0), P.Yellow, "None")
		b(m, V(4.2, 3.2, 1), V(0, 1.6, 0), P.Yellow, "None")
		b(m, V(1, 0.8, 5.2), V(0, 3.4, 0), P.Yellow, "Top")
		b(m, V(5.2, 0.8, 1), V(0, 3.4, 0), P.Yellow, "Top")
		cf(m, V(1.4, 1, 0.8), CFrame.new(-0.8, 4.3, 0) * CFrame.Angles(0, 0, math.rad(20)), P.Yellow)
		cf(m, V(1.4, 1, 0.8), CFrame.new(0.8, 4.3, 0) * CFrame.Angles(0, 0, math.rad(-20)), P.Yellow)
		b(m, V(0.8, 0.8, 1), V(0, 4.2, 0), GOLD_DARK)
	end,
	InstantHatch = function(m)
		eggOf("Common")(m)
		-- zig-zag lightning bolt in front-right
		local bolt = { { V(1, 1.2, 0.4), V(2.2, 3.4, -1.4) }, { V(1.6, 0.6, 0.4), V(1.8, 2.6, -1.4) }, { V(1, 1.2, 0.4), V(1.4, 1.8, -1.4) } }
		for _, s in bolt do
			local p = b(m, s[1], s[2], P.Yellow, "None")
			p.Material = Enum.Material.Neon
		end
		tile(m, V(0.8, 0.2, 0.1), V(-0.3, 1.9, -1.25), P.Eye)
		tile(m, V(0.2, 0.6, 0.1), V(0.1, 1.6, -1.25), P.Eye)
	end,
	Egg = eggOf("Common"),
	EggCommon = eggOf("Common"),
	EggUncommon = eggOf("Uncommon"),
	EggRare = eggOf("Rare"),
	EggEpic = eggOf("Epic"),
	EggGolden = eggOf("Golden"),
}

IconModels.Alias = {
	Coins = "Coin",
	BaitBerry = "Berry",
	BaitHoney = "Honey",
	BaitStarfruit = "Starfruit",
	InstantHatch1 = "InstantHatch",
	InstantHatch2 = "InstantHatch",
	InstantHatch3 = "InstantHatch",
	PassVIP = "VIP",
	PassExtraIncubator = "ExtraIncubator",
	PassAutoFeeder = "AutoFeeder",
	PassCrystalGrotto = "CrystalGrotto",
} :: { [string]: string }

IconModels.Names = {} :: { string }
for name in BUILDERS do
	table.insert(IconModels.Names, name)
end
table.sort(IconModels.Names)

function IconModels.Has(name: string): boolean
	return BUILDERS[IconModels.Alias[name] or name] ~= nil
end

function IconModels.Build(name: string): Model?
	local key = IconModels.Alias[name] or name
	local build = BUILDERS[key]
	if not build then
		return nil
	end
	local m = Kit.Model(nil, "Icon_" .. key)
	build(m)
	for _, d in m:GetDescendants() do
		if d:IsA("ParticleEmitter") or d:IsA("Light") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local box, size = m:GetBoundingBox()
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Transparency = 1
	root.Size = size
	root.CFrame = CFrame.new(box.Position)
	root.Parent = m
	m.PrimaryPart = root
	m:SetAttribute("IconName", key)
	return m
end

return IconModels
