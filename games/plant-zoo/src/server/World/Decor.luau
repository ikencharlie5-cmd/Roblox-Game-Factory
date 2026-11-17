--!strict
-- The 19 decor pieces, each fits one 4x4 grid cell. Decor.Build(kind) -> Model (pivot = cell top-center).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad
local hex = Color3.fromHex
local M = Enum.Material

local Decor = {}

-- kind -> biome (for docs/UI). Names match gameplay's Species.Decor.
Decor.Biome = {
	["Flower Bed"] = "Meadow",
	["Log"] = "Meadow",
	["Beehive"] = "Meadow",
	["Lily Pad"] = "Pond",
	["Pond Rock"] = "Pond",
	["Reed Clump"] = "Pond",
	["Sandstone Rock"] = "Desert",
	["Clay Pot"] = "Desert",
	["Palm Shade"] = "Desert",
	["Vine Swing"] = "Canopy",
	["Hollow Log"] = "Canopy",
	["Nest"] = "Canopy",
	["Glow Shroom"] = "Fungus Cave",
	["Crystal"] = "Fungus Cave",
	["Stalagmite"] = "Fungus Cave",
	["Ice Crystal"] = "Frost Garden",
	["Pine Tree"] = "Frost Garden",
	["Snowman"] = "Frost Garden",
	["Info Sign"] = "Any",
} :: { [string]: string }

local function blk(m: Model, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	return Build.Deco(m, { Size = size, CFrame = cf, Color = color, Material = mat })
end
local function cyl(m: Model, h: number, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	local p = Build.Cyl(m, h, d, cf, color, mat, false)
	p.CanTouch = false
	return p
end
local function blob(m: Model, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	return Build.Blob(m, size, cf, color, mat)
end
local function ball(m: Model, d: number, cf: CFrame, color: Color3, mat: Enum.Material?): Part
	return Build.Ball(m, d, cf, color, mat)
end
local function glow(p: BasePart, color: Color3, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 1.2
	l.Shadows = false
	l.Parent = p
end

local B: { [string]: (Model) -> () } = {}

B["Flower Bed"] = function(m)
	blk(m, V(3.4, 0.6, 3.4), C(0, 0.3, 0), Theme.Colors.Wood, M.WoodPlanks)
	blk(m, V(3, 0.2, 3), C(0, 0.65, 0), Theme.Colors.Dirt, M.Ground)
	local cols = { hex("#FFD54F"), hex("#FF8FB8"), hex("#FFFFFF"), hex("#FF6F61"), hex("#B57CFF"), hex("#FFD54F") }
	for i, col in cols do
		local x = ((i - 1) % 3 - 1) * 0.95
		local z = (i <= 3) and -0.6 or 0.6
		Build.Flower(m, V(x, 0.7, z), col)
	end
end

B["Log"] = function(m)
	local log = C(0, 0.8, 0) * A(0, rad(90), 0)
	local p = Build.Part(m, {
		Size = V(3.6, 1.6, 1.6),
		CFrame = log,
		Color = hex("#8B5A2B"),
		Material = M.Wood,
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	p.CanTouch = false
	local cap = Build.Part(m, {
		Size = V(0.1, 1.3, 1.3),
		CFrame = log * C(1.8, 0, 0),
		Color = hex("#E0B07A"),
		Material = M.Wood,
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	cap.CanTouch = false
	blob(m, V(1.4, 0.4, 1), C(0.2, 1.55, 0.3), hex("#5FB23A"), M.Grass)
	ball(m, 0.4, C(-0.4, 1.7, -0.6), hex("#FF6F61"))
end

B["Beehive"] = function(m)
	cyl(m, 1.6, 0.35, C(0, 0.8, 0), Theme.Colors.WoodDark, M.Wood)
	for i = 0, 2 do
		local w = 1.8 - i * 0.4
		blob(m, V(w, 0.7, w), C(0, 1.9 + i * 0.5, 0), hex("#FFC83D"))
	end
	blk(m, V(0.5, 0.4, 0.1), C(0, 2, -0.85), hex("#3B2A1A"))
	for i = 0, 2 do
		local a = rad(i * 120)
		ball(m, 0.3, C(math.cos(a) * 1.3, 2.4 + i * 0.3, math.sin(a) * 1.3), hex("#1B1B1B"))
	end
end

B["Lily Pad"] = function(m)
	cyl(m, 0.1, 3.6, C(0, 0.1, 0), Theme.Colors.Water, M.Glass).Transparency = 0.3
	cyl(m, 0.12, 2.4, C(-0.4, 0.2, 0.3), hex("#5FBF6A"))
	cyl(m, 0.12, 1.4, C(0.9, 0.2, -0.8), hex("#7FD07A"))
	blob(m, V(0.8, 0.6, 0.8), C(-0.4, 0.5, 0.3), hex("#FF9EC4"))
	ball(m, 0.3, C(-0.4, 0.75, 0.3), hex("#FFE066"), M.Neon)
end

B["Pond Rock"] = function(m)
	blob(m, V(2.8, 1.8, 2.4), C(0, 0.8, 0), hex("#8E949C"), M.Slate)
	blob(m, V(1.6, 1.2, 1.4), C(1.1, 0.5, 0.8), hex("#A3A9B0"), M.Slate)
	blob(m, V(1.8, 0.4, 1.4), C(-0.2, 1.65, 0.1), hex("#5FB23A"), M.Grass)
end

B["Reed Clump"] = function(m)
	for i = 0, 5 do
		local a = rad(i * 60 + 15)
		local r = 0.4 + (i % 2) * 0.5
		local h = 2.4 + (i % 3) * 0.6
		local x, z = math.cos(a) * r, math.sin(a) * r
		local tilt = A(rad(math.sin(a) * 6), 0, rad(math.cos(a) * 6))
		blk(m, V(0.15, h, 0.15), C(x, h / 2, z) * tilt, hex("#5E9E4A"))
		if i % 2 == 0 then
			blob(m, V(0.35, 0.8, 0.35), C(x, h + 0.2, z) * tilt, hex("#7A4E2D"))
		end
	end
end

B["Sandstone Rock"] = function(m)
	blk(m, V(3.2, 1, 2.6), C(0, 0.5, 0) * A(0, rad(8), 0), hex("#E0A060"), M.Sandstone)
	blk(m, V(2.6, 0.9, 2.1), C(0.2, 1.4, 0.1) * A(0, rad(-10), 0), hex("#F2C27B"), M.Sandstone)
	blk(m, V(1.6, 0.8, 1.4), C(-0.1, 2.2, 0) * A(0, rad(15), 0), hex("#C8643B"), M.Sandstone)
end

B["Clay Pot"] = function(m)
	cyl(m, 1.6, 2.4, C(0, 0.8, 0), hex("#C8643B"), M.Slate)
	cyl(m, 0.3, 2.8, C(0, 1.65, 0), hex("#E07A4B"), M.Slate)
	blob(m, V(1, 2.2, 1), C(0, 2.6, 0), hex("#5E9E4A"))
	blob(m, V(0.6, 1.1, 0.6), C(0.6, 2.7, 0) * A(0, 0, rad(-40)), hex("#5E9E4A"))
	ball(m, 0.5, C(0, 3.75, 0), hex("#FF7FA0"))
end

B["Palm Shade"] = function(m)
	for i = 0, 3 do
		cyl(m, 1.2, 0.7 - i * 0.05, C(i * 0.2, 0.6 + i * 1.15, 0) * A(0, 0, rad(-8)), hex("#B07A45"), M.Wood)
	end
	local top = C(0.8, 4.9, 0)
	for i = 0, 4 do
		blob(
			m,
			V(3, 0.2, 0.9),
			top * A(0, rad(i * 72), 0) * C(1.3, -0.3, 0) * A(0, 0, rad(-20)),
			hex("#4FA84A"),
			M.Grass
		)
	end
	ball(m, 0.5, top * C(0.2, -0.3, 0.3), hex("#7A4E2D"))
end

B["Vine Swing"] = function(m)
	for _, x in { -1.6, 1.6 } do
		blk(m, V(0.4, 4.4, 0.4), C(x, 2.2, 0), Theme.Colors.WoodDark, M.Wood)
	end
	blk(m, V(3.8, 0.4, 0.4), C(0, 4.4, 0), Theme.Colors.WoodDark, M.Wood)
	for _, x in { -0.7, 0.7 } do
		blk(m, V(0.12, 2.6, 0.12), C(x, 3.1, 0), hex("#4E7D3A"))
	end
	blk(m, V(1.8, 0.2, 0.7), C(0, 1.8, 0), Theme.Colors.Wood, M.WoodPlanks)
	blob(m, V(1.8, 0.6, 1.2), C(-1, 4.7, 0), hex("#2F8F4E"), M.Grass)
	blob(m, V(1.4, 0.5, 1), C(1.1, 4.7, 0.2), hex("#4CAF50"), M.Grass)
end

B["Hollow Log"] = function(m)
	local cf = C(0, 1.2, 0) * A(0, rad(90), 0)
	local p = Build.Part(m, {
		Size = V(3.8, 2.4, 2.4),
		CFrame = cf,
		Color = hex("#6B4A2E"),
		Material = M.Wood,
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	p.CanTouch = false
	local hole = Build.Part(m, {
		Size = V(0.1, 1.7, 1.7),
		CFrame = cf * C(-1.9, 0, 0),
		Color = hex("#2A1A10"),
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	hole.CanTouch = false
	blob(m, V(2.2, 0.5, 1.6), C(0, 2.4, 0.2), hex("#2F8F4E"), M.Grass)
	cyl(m, 0.4, 0.2, C(0.9, 2.6, -0.5), hex("#FFF6E0"))
	blob(m, V(0.7, 0.35, 0.7), C(0.9, 2.85, -0.5), hex("#FF6F61"))
end

B["Nest"] = function(m)
	for i = 0, 7 do
		local a = rad(i * 45)
		blob(
			m,
			V(1.4, 0.6, 0.6),
			C(math.cos(a) * 1.1, 0.4, math.sin(a) * 1.1) * A(0, -a, 0),
			hex(i % 2 == 0 and "#8B5A2B" or "#A8673A"),
			M.Wood
		)
	end
	blob(m, V(2.2, 0.3, 2.2), C(0, 0.25, 0), hex("#6B4A2E"), M.Wood)
	for i, col in { "#BDE7FF", "#FFF6E0", "#FFD9E8" } do
		local a = rad(i * 120)
		blob(m, V(0.6, 0.8, 0.6), C(math.cos(a) * 0.4, 0.75, math.sin(a) * 0.4), hex(col))
	end
end

B["Glow Shroom"] = function(m)
	cyl(m, 1.8, 0.6, C(0, 0.9, 0), hex("#FFF6E0"))
	local cap = blob(m, V(2.6, 1.2, 2.6), C(0, 2, 0), hex("#B57CFF"), M.Neon)
	glow(cap, hex("#B57CFF"), 10)
	cyl(m, 0.9, 0.3, C(1.1, 0.45, 0.7), hex("#FFF6E0"))
	blob(m, V(1, 0.5, 1), C(1.1, 1, 0.7), hex("#7CF7FF"), M.Neon)
end

B["Crystal"] = function(m)
	local cols = { hex("#B57CFF"), hex("#7CF7FF"), hex("#D9B8FF") }
	local main = blk(m, V(0.9, 3, 0.9), C(0, 1.4, 0) * A(0, rad(45), rad(5)), cols[1], M.Neon)
	blk(m, V(0.6, 2, 0.6), C(0.8, 0.9, 0.3) * A(0, rad(20), rad(-25)), cols[2], M.Neon)
	blk(m, V(0.5, 1.6, 0.5), C(-0.7, 0.7, -0.3) * A(rad(15), rad(60), rad(25)), cols[3], M.Neon)
	blob(m, V(2.6, 0.5, 2.2), C(0, 0.2, 0), hex("#4A4A5A"), M.Slate)
	glow(main, cols[1], 10)
end

B["Stalagmite"] = function(m)
	for i = 0, 3 do
		local d = 2.4 - i * 0.55
		cyl(m, 1, d, C(0, 0.5 + i * 0.9, 0), hex("#5A5A6E"):Lerp(hex("#8A8AA0"), i / 4), M.Slate)
	end
	cyl(m, 1.2, 1.1, C(1.2, 0.6, 0.6), hex("#4A4A5A"), M.Slate)
	ball(m, 0.4, C(0, 3.9, 0), hex("#7CF7FF"), M.Neon)
end

B["Ice Crystal"] = function(m)
	local ice = hex("#9FD8FF")
	blk(m, V(1, 3.4, 1), C(0, 1.6, 0) * A(0, rad(45), rad(6)), ice, M.Ice).Transparency = 0.15
	blk(m, V(0.7, 2.2, 0.7), C(0.9, 1, 0.2) * A(0, rad(10), rad(-25)), hex("#CFEFFF"), M.Ice).Transparency = 0.15
	blk(m, V(0.6, 1.6, 0.6), C(-0.8, 0.8, -0.4) * A(rad(10), rad(50), rad(28)), ice, M.Ice).Transparency = 0.15
	blob(m, V(2.8, 0.4, 2.4), C(0, 0.15, 0), hex("#EAF6FF"), M.Snow)
end

B["Pine Tree"] = function(m)
	cyl(m, 1.4, 0.6, C(0, 0.7, 0), hex("#6B4A2E"), M.Wood)
	for i = 0, 2 do
		local w = 3.2 - i * 0.9
		blk(m, V(w, 1.2, w), C(0, 1.8 + i * 1.05, 0) * A(0, rad(45 * i), 0), hex("#2E6B5A"), M.Grass)
		blk(m, V(w * 0.7, 0.25, w * 0.7), C(0, 2.45 + i * 1.05, 0) * A(0, rad(45 * i), 0), hex("#FFFFFF"), M.Snow)
	end
end

B["Snowman"] = function(m)
	ball(m, 2.4, C(0, 1.1, 0), hex("#FFFFFF"), M.Snow)
	ball(m, 1.8, C(0, 2.7, 0), hex("#FFFFFF"), M.Snow)
	ball(m, 1.3, C(0, 3.9, 0), hex("#FFFFFF"), M.Snow)
	Build.Wedge(m, V(0.25, 0.25, 0.8), C(0, 3.9, -0.9) * A(0, math.pi, 0), hex("#FF8A3D"))
	for _, x in { -0.25, 0.25 } do
		ball(m, 0.2, C(x, 4.1, -0.55), hex("#1B1B1B"))
	end
	cyl(m, 0.8, 0.8, C(0, 4.8, 0), hex("#2A2A3A"))
	cyl(m, 0.1, 1.3, C(0, 4.45, 0), hex("#2A2A3A"))
	blk(m, V(1.9, 0.3, 0.4), C(0, 3.3, 0), hex("#FF5E5E"), M.Fabric)
end

B["Info Sign"] = function(m)
	blk(m, V(0.3, 2.2, 0.3), C(0, 1.1, 0), Theme.Colors.WoodDark, M.Wood)
	local board = Build.Part(m, {
		Size = V(2.6, 1.6, 0.2),
		CFrame = C(0, 2.6, 0) * A(rad(-10), 0, 0),
		Color = Theme.Colors.Cream,
		CanCollide = false,
	})
	board.CanTouch = false
	Build.Label(board, Enum.NormalId.Front, "Did you know?", Theme.Colors.Text)
	blk(m, V(2.8, 0.15, 0.3), C(0, 3.45, 0.15), hex("#4CAF50"), M.Grass)
end

local byNorm: { [string]: string } = {}
for name in B do
	byNorm[Theme.Normalize(name)] = name
end

-- Canonical kind name for "FlowerBed", "flower_bed", "Flower Bed" ... or nil.
function Decor.KindName(kind: string): string?
	return byNorm[Theme.Normalize(kind)]
end

function Decor.Build(kind: string): Model?
	local name = Decor.KindName(kind)
	if not name then
		return nil
	end
	local m = Instance.new("Model")
	m.Name = name
	local root = Build.Deco(m, { Size = V(3.8, 0.1, 3.8), CFrame = C(0, 0.05, 0), Transparency = 1, Name = "Root" })
	root.CanQuery = true
	root.PivotOffset = C(0, -0.05, 0)
	m.PrimaryPart = root
	B[name](m)
	m:SetAttribute("Decor", name)
	m:SetAttribute("Biome", Decor.Biome[name])
	return m
end

return Decor
