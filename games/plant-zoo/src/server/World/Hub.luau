--!strict
-- Central hub at the origin: fountain-tree centerpiece, shop stalls, leaderboard, World Reserve, spawn.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)
local Stalls = require(script.Parent.Stalls)
local Props = require(script.Parent.Props)

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad
local hex = Color3.fromHex
local M = Enum.Material

local Hub = {}
Hub.Radius = 60
Hub.Top = 0.3

export type HubRefs = {
	restockLabel: TextLabel,
	boardRows: { TextLabel },
	reserveZones: { [string]: BasePart },
	altar: BasePart,
}

-- CFrame on the hub floor at angle/radius, facing the center.
local function at(angleDeg: number, r: number): CFrame
	local a = rad(angleDeg)
	local p = V(math.cos(a) * r, Hub.Top, math.sin(a) * r)
	return CFrame.lookAt(p, V(0, Hub.Top, 0))
end

local function centerpiece(f: Instance)
	local stone = Theme.Colors.Stone
	Build.Cyl(f, 2.4, 26, C(0, 1.2, 0), stone, M.SmoothPlastic, true)
	Build.Cyl(f, 0.5, 27, C(0, 2.45, 0), stone:Lerp(Color3.new(1, 1, 1), 0.3), M.SmoothPlastic, true)
	local water = Build.Cyl(f, 0.4, 23, C(0, 2.2, 0), Theme.Colors.Water, M.Glass, false)
	water.Transparency = 0.3
	water.Reflectance = 0.15
	Build.Cyl(f, 3, 7, C(0, 2.5, 0), stone, M.SmoothPlastic, true)
	Build.Cyl(f, 22, 4.5, C(0, 13, 0), hex("#8B5A2B"), M.SmoothPlastic, true)
	for i = 0, 4 do
		local a = rad(i * 72)
		Build.Blob(
			f,
			V(2.2, 3, 5),
			C(math.cos(a) * 2.6, 4.5, math.sin(a) * 2.6) * A(0, -a + rad(90), rad(20)),
			hex("#7A4E2D"),
			M.SmoothPlastic
		)
	end
	local leaves = { hex("#FFB3D9"), hex("#7AD65A"), hex("#FF8FB8"), hex("#4FBF4A"), hex("#FFD1E3") }
	local spots = { V(0, 27, 0), V(6, 24, 2), V(-5, 25, -4), V(2, 24, -7), V(-3, 23, 6) }
	for i, p in spots do
		local d = if i == 1 then 16 else 11
		Build.Ball(f, d, C(p), leaves[i], M.SmoothPlastic)
	end
	for i = 0, 5 do
		local a = rad(i * 60 + 20)
		local fruit = Build.Ball(
			f,
			1.6,
			C(math.cos(a) * 8, 21 + (i % 2) * 3, math.sin(a) * 8),
			Theme.Colors.Gold,
			M.SmoothPlastic
		)
		if i % 2 == 0 then
			local l = Instance.new("PointLight")
			l.Color = Theme.Colors.Gold
			l.Range = 14
			l.Brightness = 0.8
			l.Parent = fruit
		end
	end
	local spout = Build.Deco(f, { Size = V(20, 0.2, 20), CFrame = C(0, 2.5, 0), Transparency = 1, Name = "Spray" })
	local e = Theme.Effects.Sparkle(hex("#CFF3FF"), 12)
	e.EmissionDirection = Enum.NormalId.Top
	e.Speed = NumberRange.new(2, 4)
	e.Parent = spout
	Build.Tag(spout, "HubCenter")
end

local function seedShop(f: Instance, cf: CFrame): TextLabel
	local refs = Stalls.Build(f, cf, "Seed Shop", hex("#7BD148"), "SeedIcon", "ShopStand", { Shop = "Seed" })
	local holder = refs.model
	for i = 0, 4 do
		local x = -4.4 + i * 2.2
		Build.Blob(holder, V(1.6, 0.6, 1.6), cf * C(x, 3.9, -0.4), Theme.Colors.Dirt, M.Ground)
		Build.Flower(holder, (cf * C(x, 4, -0.4)).Position, Theme.Rarity[Theme.RarityOrder[i + 1]])
	end
	-- Restock clock hangs under the awning's front edge.
	local board = Build.Deco(
		holder,
		{ Size = V(6, 1.6, 0.3), CFrame = cf * C(0, 8.2, -2.6), Color = Theme.Colors.Cream, Name = "RestockClock" }
	)
	Build.Deco(holder, { Size = V(6.4, 2, 0.2), CFrame = board.CFrame * C(0, 0, 0.2), Color = Theme.Colors.Gold })
	local label = Build.Label(board, Enum.NormalId.Front, "Restock 5:00", Theme.Colors.Text)
	Build.Label(board, Enum.NormalId.Back, "Restock 5:00", Theme.Colors.Text)
	return label
end

local function leaderboard(f: Instance, cf: CFrame): { TextLabel }
	local m = Build.Model(f, "Leaderboard")
	for _, x in { -8.5, 8.5 } do
		Build.Part(
			m,
			{ Size = V(1, 16, 1), CFrame = cf * C(x, 8, 0), Color = Theme.Colors.WoodDark, Material = M.Wood }
		)
	end
	local board = Build.Part(
		m,
		{ Size = V(16, 12, 0.8), CFrame = cf * C(0, 9, 0), Color = hex("#2F5D3A"), Material = M.Wood, Name = "Board" }
	)
	Build.Tag(board, "Leaderboard", { Stat = "TotalEarned" })
	Build.Deco(
		m,
		{ Size = V(18, 1, 1.6), CFrame = cf * C(0, 15.5, 0), Color = Theme.Colors.Leaf, Material = M.SmoothPlastic }
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = gui
	local rows = {}
	for i = 0, 10 do
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, if i == 0 then 0.14 else 0.086)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.LayoutOrder = i
		l.TextColor3 = if i == 0 then Theme.Colors.Gold else Color3.new(1, 1, 1)
		l.Text = if i == 0 then "🏆 Top Earners" else string.format("%d. ---", i)
		l.Name = if i == 0 then "Title" else "Row" .. i
		l.Parent = gui
		if i > 0 then
			table.insert(rows, l)
		end
	end
	return rows
end

local RESERVE_PROPS: { [string]: (Instance, CFrame) -> () } = {
	Meadow = function(f, cf)
		Build.Flower(f, cf.Position, hex("#FFD54F"))
		Build.Flower(f, (cf * C(1, 0, 1)).Position, hex("#FF8FB8"))
	end,
	Pond = function(f, cf)
		local w = Build.Cyl(f, 0.2, 4, cf * C(0, 0.05, 0), Theme.Colors.Water, M.Glass, false)
		w.Transparency = 0.3
	end,
	Desert = function(f, cf)
		Build.Blob(f, V(1, 2.6, 1), cf * C(0, 1.3, 0), hex("#5E9E4A"))
	end,
	Canopy = function(f, cf)
		Build.Tree(f, cf.Position, 0.5, hex("#2F8F4E"))
	end,
	["Fungus Cave"] = function(f, cf)
		Build.Cyl(f, 1.2, 0.4, cf * C(0, 0.6, 0), Theme.Colors.Cream, nil, false)
		Build.Blob(f, V(2, 0.8, 2), cf * C(0, 1.4, 0), hex("#B57CFF"), M.SmoothPlastic)
	end,
	["Frost Garden"] = function(f, cf)
		Build.Deco(f, {
			Size = V(0.8, 2.4, 0.8),
			CFrame = cf * C(0, 1.2, 0) * A(0, rad(45), 0),
			Color = hex("#9FD8FF"),
			Material = M.Ice,
		})
	end,
}

local function reserve(f: Instance, cf: CFrame): ({ [string]: BasePart }, BasePart)
	local m = Build.Model(f, "WorldReserve")
	local base = Build.Cyl(m, 1.4, 32, cf * C(0, 0.7, 0), Theme.Colors.PlotFloor, M.SmoothPlastic, true)
	base.Name = "ReserveBase"
	Build.Tag(base, "ReserveArea")
	Build.Cyl(m, 1, 34, cf * C(0, 0.3, 0), Theme.Colors.WoodDark, M.WoodPlanks, true)
	local zones: { [string]: BasePart } = {}
	for i, biome in Theme.BiomeOrder do
		local a = rad((i - 1) * 60)
		local zcf = cf * C(math.cos(a) * 9.5, 1.45, math.sin(a) * 9.5)
		local kit = Theme.Biomes[biome]
		local zone = Build.Cyl(m, 0.2, 9, zcf, kit.Ground, kit.GroundMaterial, false)
		zone.Name = "Zone_" .. biome
		Build.Tag(zone, "ReserveZone", { Biome = biome, Count = 0 })
		zones[biome] = zone
		RESERVE_PROPS[biome](m, zcf * C(math.cos(a) * 2.5, 0.1, math.sin(a) * 2.5))
	end
	local altar = Build.Cyl(m, 3, 4, cf * C(0, 2.9, 0), hex("#C9C2B2"), M.Marble, true)
	altar.Name = "ReleaseAltar"
	Build.Tag(altar, "ReleaseAltar")
	local gem = Build.Deco(m, {
		Size = V(1.6, 3, 1.6),
		CFrame = cf * C(0, 6.2, 0) * A(rad(45), rad(45), 0),
		Color = Theme.Colors.Thriving,
		Material = M.Neon,
		Name = "Gem",
	})
	Theme.Effects.Sparkle(Theme.Colors.Thriving, 8).Parent = gem
	local sign = Build.Deco(
		m,
		{ Size = V(12, 2.4, 0.4), CFrame = cf * C(0, 2.6, -16.5), Color = Theme.Colors.Cream, Name = "Sign" }
	)
	Build.Label(sign, Enum.NormalId.Front, "🌍 World Reserve", Theme.Colors.Text)
	return zones, altar
end

-- Benches, flower beds and lamps around the hub ring (between the stalls / spoke mouths).
local function plaza(f: Instance)
	local rng = Random.new(42)
	for k = 0, 5 do
		local ang = k * 60
		-- Flower bed + lamps flank each spoke mouth (spokes leave the hub at multiples of 60 deg).
		for _, d in { -11, 11 } do
			local p = at(ang + d, 56).Position
			Props.Lamp(f, Vector3.new(p.X, 0.3, p.Z), rng)
		end
		local inner = at(ang, 22)
		Props.Bench(f, inner, rng) -- faces the fountain
	end
	-- Flower ring around the central lawn.
	for k = 0, 35 do
		local a = rad(k * 10)
		Props.Flower(f, V(math.cos(a) * 19.6, 0.3, math.sin(a) * 19.6), rng, Theme.FlowerColors[k % 5 + 1])
	end
end

function Hub.Build(parent: Instance): HubRefs
	local f = Build.Folder(parent, "Hub")
	local floor = Build.Cyl(f, 0.6, Hub.Radius * 2, C(0, 0, 0), Theme.Colors.Path, M.SmoothPlastic, true)
	floor.Name = "HubFloor"
	Build.Cyl(f, 0.5, Hub.Radius * 2 + 4, C(0, -0.05, 0), Theme.Colors.PathEdge, M.SmoothPlastic, true)
	Build.Cyl(f, 0.3, 36, C(0, 0.3, 0), Theme.Colors.PlotFloor, M.SmoothPlastic, true)
	Build.Cyl(f, 0.28, 37.6, C(0, 0.28, 0), Theme.Colors.PathEdge, M.SmoothPlastic, true)
	centerpiece(f)
	task.wait()
	local restock = seedShop(f, at(30, 40))
	Stalls.Build(f, at(90, 40), "Hope Shop", hex("#FFD45C"), "HopeIcon", "HopeShop", { Shop = "Hope" })
	Stalls.Build(f, at(150, 40), "Upgrades", hex("#7FD0FF"), "UpgradeIcon", "UpgradeStand", { Shop = "Upgrades" })
	local rows = leaderboard(f, at(210, 44))
	task.wait()
	local zones, altar = reserve(f, at(270, 38))
	Stalls.Build(f, at(330, 46), "Daily Gifts", hex("#FF7B7B"), "DailyIcon", "DailyStand", { Shop = "Daily" })
	plaza(f)
	local spawnCf = at(330, 30)
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = V(8, 0.4, 8)
	spawn.CFrame = spawnCf * C(0, 0.2, 0)
	spawn.Color = hex("#FFE9A8")
	spawn.Material = M.Sand
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Name = "HubSpawn"
	spawn.Parent = f
	Build.Tag(spawn, "HubSpawn")
	return { restockLabel = restock, boardRows = rows, reserveZones = zones, altar = altar }
end

return Hub
