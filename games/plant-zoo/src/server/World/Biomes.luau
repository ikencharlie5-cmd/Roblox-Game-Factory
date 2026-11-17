--!strict
-- Biome exhibit kits for a 20x20 ExhibitPad: ground tile + fence style + a showpiece.
-- Biomes.Apply(base, dressing, biome) restyles a pad; Biomes.Lock(...) shows hedge + price sign.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad
local hex = Color3.fromHex
local M = Enum.Material

local Biomes = {}

local HALF = Theme.Grid.PadSize / 2

type FenceStyle = {
	post: Vector3,
	postColor: Color3,
	postMat: Enum.Material,
	rail: Vector3?, -- (thickness, height, y)
	railColor: Color3,
	railMat: Enum.Material,
	railT: number?,
}

-- Posts at corners + side mids; rail per side, front side split for a 4-stud walk-in gap.
local function fence(f: Instance, top: CFrame, st: FenceStyle): { CFrame }
	local tops = {}
	for _, x in { -HALF, 0, HALF } do
		for _, z in { -HALF, 0, HALF } do
			if (x ~= 0 or z ~= 0) and not (x == 0 and z == -HALF) then
				local cf = top * C(x, st.post.Y / 2, z)
				Build.Deco(f, { Size = st.post, CFrame = cf, Color = st.postColor, Material = st.postMat })
				table.insert(tops, cf * C(0, st.post.Y / 2, 0))
			end
		end
	end
	local maybeRail = st.rail
	if maybeRail then
		local r: Vector3 = maybeRail
		local function rail(cx: number, cz: number, len: number, alongX: boolean)
			local size = if alongX then V(len, r.Y, r.X) else V(r.X, r.Y, len)
			local p = Build.Deco(
				f,
				{ Size = size, CFrame = top * C(cx, r.Z, cz), Color = st.railColor, Material = st.railMat }
			)
			p.Transparency = st.railT or 0
		end
		rail(0, HALF, HALF * 2, true)
		rail(-HALF, 0, HALF * 2, false)
		rail(HALF, 0, HALF * 2, false)
		local seg = HALF - 2
		rail(-(2 + seg / 2), -HALF, seg, true)
		rail(2 + seg / 2, -HALF, seg, true)
	end
	return tops
end

local function light(p: BasePart, color: Color3, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 1
	l.Shadows = false
	l.Parent = p
end

local KITS: { [string]: (Folder, CFrame, Theme.BiomeKit) -> () } = {}

KITS.Meadow = function(f, top, k)
	local tops = fence(f, top, {
		post = V(0.5, 2.2, 0.5),
		postColor = k.Fence,
		postMat = M.WoodPlanks,
		rail = V(0.25, 0.35, 1.5),
		railColor = k.Fence,
		railMat = M.WoodPlanks,
	})
	for i, cf in tops do
		Build.Ball(f, 0.7, cf * C(0, 0.3, 0), if i % 2 == 0 then k.Accent else k.Accent2)
	end
end

KITS.Pond = function(f, top, k)
	fence(f, top, {
		post = V(0.6, 3, 0.6),
		postColor = k.Fence3,
		postMat = M.Metal,
		rail = V(0.3, 2.6, 1.4),
		railColor = k.Fence,
		railMat = M.Glass,
		railT = 0.6,
	})
	local water = Build.Deco(f, {
		Size = V(19.6, 0.35, 19.6),
		CFrame = top * C(0, 0.12, 0),
		Color = k.Accent,
		Material = M.Glass,
		Name = "Water",
	})
	water.Transparency = 0.45
	water.CanQuery = false
	local bubbles = Theme.Effects.Sparkle(hex("#DDF6FF"), 3)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Parent = water
end

KITS.Desert = function(f, top, k)
	local tops = fence(f, top, {
		post = V(1, 1.6, 1),
		postColor = k.Fence,
		postMat = M.Brick,
		rail = V(0.6, 1.1, 0.55),
		railColor = k.Fence3,
		railMat = M.Sandstone,
	})
	for i, cf in tops do
		if i % 3 == 1 then
			Build.Blob(f, V(0.8, 2, 0.8), cf * C(0, 1, 0), k.Accent)
			Build.Ball(f, 0.4, cf * C(0, 2.1, 0), k.Accent2)
		end
	end
end

KITS.Canopy = function(f, top, k)
	for _, x in { -HALF, HALF } do
		for _, z in { -HALF, HALF } do
			Build.Cyl(f, 7, 0.9, top * C(x, 3.5, z), k.Fence, M.Wood, false)
			Build.Blob(f, V(3, 1.2, 3), top * C(x, 7.2, z), Theme.Colors.Leaf, M.Grass)
			Build.Deco(f, { Size = V(0.15, 3, 0.15), CFrame = top * C(x * 0.9, 5.5, z * 0.9), Color = k.Fence3 })
		end
	end
	local dome = Build.Blob(f, V(23, 15, 23), top, k.Accent)
	dome.Transparency = 0.82
	dome.Material = M.ForceField
	dome.CanQuery = false
	dome.CastShadow = false
	dome.Name = "AviaryDome"
end

KITS["Fungus Cave"] = function(f, top, k)
	local tops = fence(f, top, {
		post = V(1.4, 2.4, 1.4),
		postColor = k.Fence,
		postMat = M.Slate,
		rail = V(0.35, 0.3, 0.3),
		railColor = k.Accent,
		railMat = M.Neon,
	})
	for i, cf in tops do
		if i % 2 == 1 then
			Build.Cyl(f, 0.8, 0.3, cf * C(0, 0.4, 0), Theme.Colors.Cream, nil, false)
			local cap =
				Build.Blob(f, V(1.6, 0.7, 1.6), cf * C(0, 0.9, 0), if i % 4 == 1 then k.Accent else k.Accent2, M.Neon)
			if i == 1 then
				light(cap, k.Accent, 16)
			end
		end
	end
end

KITS["Frost Garden"] = function(f, top, k)
	local tops = fence(f, top, {
		post = V(0.7, 2.6, 0.7),
		postColor = k.Fence,
		postMat = M.Ice,
		rail = V(0.4, 0.4, 1.6),
		railColor = k.Fence3,
		railMat = M.Snow,
	})
	for _, cf in tops do
		Build.Blob(f, V(1, 0.4, 1), cf * C(0, 0.1, 0), Color3.new(1, 1, 1), M.Snow)
	end
	local snow =
		Build.Deco(f, { Size = V(18, 0.2, 18), CFrame = top * C(0, 9, 0), Transparency = 1, Name = "SnowSource" })
	snow.CanQuery = false
	local e = Theme.Effects.Weather("Snow")
	if e then
		e.Rate = 5
		e.Parent = snow
	end
end

function Biomes.TopCFrame(base: BasePart): CFrame
	return base.CFrame * C(0, base.Size.Y / 2, 0)
end

function Biomes.Apply(base: BasePart, dressing: Folder, biome: string?)
	dressing:ClearAllChildren()
	local key = Theme.BiomeKey(biome) or "Meadow"
	local kit = Theme.Biomes[key]
	base.Color = kit.Ground
	base.Material = kit.GroundMaterial
	base:SetAttribute("Biome", key)
	local top = Biomes.TopCFrame(base)
	-- Thin border strip so pads read as tiles.
	Build.Deco(dressing, {
		Size = V(20.6, 0.2, 20.6),
		CFrame = top * C(0, -0.25, 0),
		Color = kit.Ground:Lerp(Color3.new(0, 0, 0), 0.25),
		Material = kit.GroundMaterial,
	})
	KITS[key](dressing, top, kit)
end

function Biomes.Lock(base: BasePart, lock: Folder, priceText: string, padIndex: number)
	lock:ClearAllChildren()
	base.Color = hex("#9C7A55")
	base.Material = M.Ground
	local top = Biomes.TopCFrame(base)
	local hedge = Theme.Colors.Hedge
	local e = HALF - 0.7
	for _, s in { { 0, -e, true }, { 0, e, true }, { -e, 0, false }, { e, 0, false } } do
		local x, z, alongX = s[1] :: number, s[2] :: number, s[3] :: boolean
		local size = if alongX then V(20, 3, 1.4) else V(1.4, 3, 20)
		Build.Part(
			lock,
			{ Size = size, CFrame = top * C(x, 1.5, z), Color = hedge, Material = M.Grass, Name = "Hedge" }
		)
	end
	for i = 0, 5 do
		local a = rad(i * 60)
		Build.Ball(lock, 1, top * C(math.cos(a) * 10, 3.1, math.sin(a) * 10), hex("#FF8FB8"))
	end
	Build.Deco(
		lock,
		{ Size = V(0.5, 4, 0.5), CFrame = top * C(0, 2, 0), Color = Theme.Colors.WoodDark, Material = M.Wood }
	)
	local board = Build.Deco(
		lock,
		{ Size = V(7, 3.4, 0.4), CFrame = top * C(0, 4.6, 0), Color = Theme.Colors.Cream, Name = "PriceSign" }
	)
	local txt = string.format("Exhibit %d\n🔒 %s", padIndex, priceText)
	Build.Label(board, Enum.NormalId.Front, txt, Theme.Colors.Text)
	Build.Label(board, Enum.NormalId.Back, txt, Theme.Colors.Text)
	Build.Deco(
		lock,
		{ Size = V(7.4, 0.4, 0.8), CFrame = top * C(0, 6.4, 0), Color = Theme.Colors.Leaf, Material = M.Grass }
	)
end

return Biomes
