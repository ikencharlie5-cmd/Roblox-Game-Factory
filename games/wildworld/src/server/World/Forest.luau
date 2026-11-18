--!strict
-- Greenleaf Meadow, north of the plot ring: the only v1 wild zone (Id "Meadow"). Road from the plaza through
-- the ForestGate arch, terraced brick hills, dense tree clusters and flowers, ending at the lake + brick
-- waterfall on the back edge (the focal point straight up the road). All 5 species spawn here.
-- Tags: ForestGate (park -> meadow arch), ZoneGate (Meadow anchor, always open), WorldZone/ZoneArea/AudioZone
-- (zone volume), WildSpawn (spawn points), Fireflies, NightLight. See notes/graphics.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Layout = require(script.Parent.Layout)
local Terrain = require(script.Parent.Terrain)
local Scatter = require(script.Parent.Scatter)
local Waterfall = require(script.Parent.Waterfall)

local Kit, Nature, P = Theme.Kit, Theme.Nature, Theme.Colors
local V = Vector3.new
local Forest = {}

local function zoneNumbers(z: Layout.ZoneDef): (number, number)
	local cfgZones = (Config :: any).Zones
	if type(cfgZones) == "table" then
		for _, c in cfgZones do
			if type(c) == "table" and c.Id == z.Id then
				return c.Level or z.RequiredLevel, c.Cost or z.Cost
			end
		end
	end
	return z.RequiredLevel, z.Cost
end

-- Brick arch across the road at z (wood pillars, leaf-cube caps, beam, double-sided sign). Returns the model.
local function arch(parent: Instance, z: number, title: string, color: Color3): Model
	local m = Kit.Model(parent, "Arch")
	local w = Layout.RoadWidth + 6
	for _, x in { -w / 2, w / 2 } do
		Kit.Brick(m, V(2, 16, 2), CFrame.new(x, 8, z), P.Trunk, "All", true)
		Kit.Brick(m, V(5, 2.4, 5), CFrame.new(x, 16.4, z), P.Leaf1, "All")
		Kit.Brick(m, V(3, 2.4, 3), CFrame.new(x, 18.8, z), P.Leaf2, "All")
		Kit.Brick(m, V(2, 1.2, 2), CFrame.new(x + 1, 15.2, z - 2), P.Leaf3, "All")
	end
	Kit.Brick(m, V(w + 4, 2, 2), CFrame.new(0, 14.6, z), P.Wood, "Top")
	local board = Kit.Brick(m, V(w - 2, 3.6, 1), CFrame.new(0, 12, z + 1.5), color, "Top")
	board.Name = "Sign"
	Kit.Label(board, Enum.NormalId.Back, title, P.White, true)
	local back = Kit.Label(board, Enum.NormalId.Front, title, P.White, true)
	back.Name = "BackText"
	return m
end

local function hidden(parent: Instance, size: Vector3, cf: CFrame, name: string): Part
	local p = Kit.Block(parent, size, cf, P.Cream)
	p.Name = name
	p.Transparency = 1
	p.CastShadow = false
	return p
end

local function zoneVolume(parent: Instance, z: Layout.ZoneDef): Part
	local depth = z.ZMax - z.ZMin
	local v = hidden(parent, V(z.HalfWidth * 2, 120, depth), CFrame.new(0, 50, (z.ZMin + z.ZMax) / 2), z.Key .. "Zone")
	local look = Theme.Zones[z.Key]
	local attrs = { Zone = z.Id, ZoneKey = z.Key, DisplayName = look.DisplayName, Biome = look.Biome, ZoneIndex = z.Index }
	Kit.Tag(v, "WorldZone", attrs)
	v:AddTag("ZoneArea")
	v:AddTag("AudioZone") -- Audio reads the same volume: Zone = "Meadow".
	return v
end

-- Keep-out test for props: road strip, lake + sand rim (pad = extra radius), waterfall cliff foot.
local function blocked(x: number, zz: number, pad: number): boolean
	local lake = Layout.Lake
	if math.abs(x) < Layout.RoadWidth / 2 + 3 + pad and zz > Layout.RoadEndZ - 4 - pad then
		return true
	end
	if (Vector2.new(x, zz) - Vector2.new(lake.Center.X, lake.Center.Z)).Magnitude < lake.Radius + 12 + pad then
		return true
	end
	return zz < Layout.WaterfallTop.Z + 14 + pad
end

local function spawns(parent: Instance, z: Layout.ZoneDef, rng: Random, count: number)
	local folder = Kit.Folder(parent, "WildSpawns")
	local made, tries = 0, 0
	while made < count and tries < count * 12 do
		tries += 1
		local x = rng:NextNumber(-z.HalfWidth + 30, z.HalfWidth - 30)
		local zz = rng:NextNumber(z.ZMin + 25, z.ZMax - 25)
		if blocked(x, zz, 4) then
			continue
		end
		made += 1
		local p = hidden(folder, V(2, 1, 2), CFrame.new(x, Scatter.GroundY(x, zz) + 0.5, zz), z.Key .. "Spawn" .. made)
		Kit.Tag(p, "WildSpawn", { Zone = z.Id, ZoneKey = z.Key, ZoneIndex = z.Index })
	end
end

-- Glowing brick mushroom: cream stem cube + studded cap plate that turns Neon at night (lake shore flavour).
local function mushroom(parent: Instance, cf: CFrame, s: number, rng: Random)
	local k = math.floor(s * 2 + 0.5) / 2
	Kit.Brick(parent, V(1, 1.6, 1) * k, cf * CFrame.new(0, 0.8 * k, 0), P.Cream, "All")
	local col = if rng:NextNumber() < 0.5 then P.MagicPurple else P.Water
	local cap = Kit.Brick(parent, V(3, 0.8, 3) * k, cf * CFrame.new(0, 2.0 * k, 0), col, "Top")
	Kit.Brick(parent, V(1, 0.4, 1) * k, cf * CFrame.new(0.5 * k, 2.6 * k, 0.5 * k), P.White, "Top").CastShadow = false
	cap:SetAttribute("GlowAtNight", true)
	cap:AddTag("NightLight")
end

local function meadow(parent: Instance, z: Layout.ZoneDef, rng: Random)
	local f = Kit.Model(parent, "Meadow")
	local x0, x1 = -z.HalfWidth + 20, z.HalfWidth - 20
	-- Terraced brick hills either side of the road (max 6 levels, 1.2–2.4 tall, 4–8 narrower each).
	local hills, tries = 0, 0
	while hills < 8 and tries < 60 do
		tries += 1
		local side = if hills % 2 == 0 then 1 else -1
		local size = rng:NextInteger(40, 64)
		local x = side * rng:NextInteger(60, 165)
		local zz = rng:NextInteger(z.ZMin + 70, z.ZMax - 50)
		if not blocked(x, zz, size / 2 + 4) then
			hills += 1
			Terrain.Hill(x, zz, size, size + rng:NextInteger(-8, 8), rng, { Levels = rng:NextInteger(3, 6), Step = rng:NextInteger(2, 4) })
		end
	end
	task.wait()
	-- Tree clusters: round oaks through the meadow, pink/purple magic trees framing the lake and falls.
	local placed = 0
	tries = 0
	while placed < 18 and tries < 120 do
		tries += 1
		local x, zz = rng:NextNumber(x0, x1), rng:NextNumber(z.ZMin + 20, z.ZMax - 20)
		if not blocked(x, zz, 10) then
			placed += 1
			local nearLake = zz < Layout.Lake.Center.Z + 70
			Scatter.Cluster(f, x, zz, rng, if nearLake then "Magic" else "Round", rng:NextNumber(0.9, 1.3))
			if placed % 6 == 0 then
				task.wait()
			end
		end
	end
	for _ = 1, 44 do
		local x, zz = rng:NextNumber(x0 + 5, x1 - 5), rng:NextNumber(z.ZMin + 10, z.ZMax - 10)
		if not blocked(x, zz, 0) then
			Nature.FlowerPatch(f, Scatter.Ground(x, zz), 1.4, rng)
		end
	end
	-- Flower borders along the road.
	for _, s in { -1, 1 } do
		Scatter.FlowerLine(f, V(s * 10, 0.4, z.ZMax - 12), V(s * 10, 0.4, Layout.RoadEndZ + 8), rng, 9)
	end
	Scatter.Sprinkle(f, x0, x1, z.ZMin + 20, z.ZMax - 20, rng, 24)
	-- Glow mushrooms around the lake shore + night fireflies over the meadow.
	local lake = Layout.Lake
	for k = 1, 10 do
		local a = k / 10 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local r = lake.Radius + rng:NextNumber(12, 22)
		local x, zz = lake.Center.X + math.cos(a) * r, lake.Center.Z + math.sin(a) * r
		if math.abs(x) > Layout.RoadWidth and zz > Layout.WaterfallTop.Z + 12 then
			mushroom(f, Scatter.Ground(x, zz), rng:NextNumber(0.8, 1.5), rng)
		end
	end
	local fire = hidden(f, V(z.HalfWidth * 2, 10, z.ZMax - z.ZMin), CFrame.new(0, 8, (z.ZMin + z.ZMax) / 2), "Fireflies")
	local e = Theme.Effects.Fireflies()
	e.Rate = 10
	e.Enabled = false
	e.Parent = fire
	fire:AddTag("Fireflies")
end

function Forest.Build(parent: Instance, rng: Random)
	local root = Kit.Model(parent, "GreenleafMeadow")
	local z = Layout.Zones[1]
	-- Road from the plaza up to the lake shore; the waterfall sits dead ahead.
	Terrain.Road(root, V(0, 0, -Layout.PlazaRadius + 2), V(0, 0, Layout.RoadEndZ), Layout.RoadWidth)
	local lvl, cost = zoneNumbers(z)
	local gate = arch(root, Layout.ForestGateZ, "Greenleaf Meadow", P.Leaf1)
	gate.Name = "ForestGate"
	Kit.Tag(gate, "ForestGate", { Zone = z.Id })
	local anchor = hidden(gate, V(6, 1, 2), CFrame.new(0, 1, Layout.ForestGateZ), "GateAnchor")
	Kit.Tag(anchor, "ZoneGate", { Zone = z.Id, ZoneKey = z.Key, ZoneIndex = z.Index, RequiredLevel = lvl, Cost = cost })
	zoneVolume(root, z)
	Terrain.Lake()
	Terrain.Cliff()
	Waterfall.Build(root)
	meadow(root, z, rng)
	-- Tree walls along both sides of the meadow (the cliff closes the back).
	local walls = Kit.Model(root, "Walls")
	for _, side in { -1, 1 } do
		Scatter.Wall(walls, V(side * 215, 0, z.ZMax - 10), V(side * 215, 0, Layout.WaterfallTop.Z - 6), rng, "Mixed", 26)
	end
	spawns(root, z, rng, 24)
end

return Forest
