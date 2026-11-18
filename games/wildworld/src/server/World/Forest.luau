--!strict
-- Greenleaf Forest, north of the plot ring: Meadow Edge (open hills, flowers) -> Mossy Hollow (dense trees,
-- mossy rocks, mist) -> Waterfall Glade (lake, waterfall, pink/purple magic trees, discovery spots).
-- Tags: ForestGate (park -> forest arch), ZoneGate (barrier per locked zone), WorldZone (zone volumes),
-- WildSpawn (spawn points), DiscoverySpot. See notes/graphics.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Layout = require(script.Parent.Layout)
local Terrain = require(script.Parent.Terrain)
local Scatter = require(script.Parent.Scatter)
local Waterfall = require(script.Parent.Waterfall)

local Kit, Nature, P = Theme.Kit, Theme.Nature, Theme.Colors
local M = Enum.Material
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

-- Wooden arch across the road at z. Returns the arch model.
local function arch(parent: Instance, z: number, title: string, color: Color3): Model
	local m = Kit.Model(parent, "Arch")
	local w = Layout.RoadWidth + 6
	for _, x in { -w / 2, w / 2 } do
		Kit.Solid(m, Vector3.new(2.4, 16, 2.4), CFrame.new(x, 8, z), P.Trunk, M.Wood)
		Kit.Ball(m, 4.5, CFrame.new(x, 16.5, z), P.Leaf1)
		Kit.Ball(m, 3, CFrame.new(x + 1.2, 15, z - 1.4), P.Leaf3)
	end
	Kit.Block(m, Vector3.new(w + 4, 2, 2.4), CFrame.new(0, 14.6, z), P.Wood, M.Wood)
	local board = Kit.Block(m, Vector3.new(w - 2, 3.4, 0.5), CFrame.new(0, 12, z + 1.4), color)
	board.Name = "Sign"
	Kit.Label(board, Enum.NormalId.Back, title, P.Cream, true)
	local back = Kit.Label(board, Enum.NormalId.Front, title, P.Cream, true)
	back.Name = "BackText"
	return m
end

local function zoneVolume(parent: Instance, z: Layout.ZoneDef): Part
	local depth = z.ZMax - z.ZMin
	local v = Kit.Block(parent, Vector3.new(z.HalfWidth * 2, 120, depth), CFrame.new(0, 50, (z.ZMin + z.ZMax) / 2), P.Cream)
	v.Name = z.Key .. "Zone"
	v.Transparency = 1
	v.CastShadow = false
	local look = Theme.Zones[z.Key]
	local attrs = { Zone = z.Id, ZoneKey = z.Key, DisplayName = look.DisplayName, Biome = look.Biome, ZoneIndex = z.Index }
	Kit.Tag(v, "WorldZone", attrs)
	v:AddTag("ZoneArea")
	-- Audio reads the same volume: Zone = Config id (Meadow/Hollow/Glade).
	v:AddTag("AudioZone")
	return v
end

local function spawns(parent: Instance, z: Layout.ZoneDef, rng: Random, count: number, avoid: (number, number) -> boolean)
	local folder = Kit.Folder(parent, "WildSpawns")
	local made = 0
	local tries = 0
	while made < count and tries < count * 10 do
		tries += 1
		local x = rng:NextNumber(-z.HalfWidth + 30, z.HalfWidth - 30)
		local zz = rng:NextNumber(z.ZMin + 25, z.ZMax - 25)
		if math.abs(x) < Layout.RoadWidth or avoid(x, zz) then
			continue
		end
		made += 1
		local p = Kit.Block(folder, Vector3.new(2, 1, 2), CFrame.new(x, Scatter.GroundY(x, zz) + 0.5, zz), P.Cream)
		p.Name = z.Key .. "Spawn" .. made
		p.Transparency = 1
		p.CastShadow = false
		Kit.Tag(p, "WildSpawn", { Zone = z.Id, ZoneKey = z.Key, ZoneIndex = z.Index })
	end
end

local function zoneGate(parent: Instance, z: Layout.ZoneDef, title: string, color: Color3)
	local lvl, cost = zoneNumbers(z)
	local m = arch(parent, z.ZMax, title, color)
	m.Name = z.Key .. "Gate"
	-- Magic veil across the zone width (visual only, walk-through: gameplay teleports locked players back
	-- to the ZoneGate anchor). Clients may hide it once the zone is unlocked.
	local barrier = Kit.Block(m, Vector3.new(z.HalfWidth * 2, 40, 1), CFrame.new(0, 20, z.ZMax), Theme.Mutation.Crystal, M.ForceField)
	barrier.Name = "Barrier"
	barrier.Transparency = 0.6
	barrier.CastShadow = false
	local anchor = Kit.Block(m, Vector3.new(6, 1, 2), CFrame.new(0, 1, z.ZMax), P.Cream)
	anchor.Name = "GateAnchor"
	anchor.Transparency = 1
	anchor.CastShadow = false
	local lock = Kit.Block(m, Vector3.new(8, 2.4, 0.4), CFrame.new(0, 7, z.ZMax + 1.4), P.Parchment)
	lock.Name = "LockSign"
	local text = if cost > 0 then string.format("Park Lv %d  +  %d coins", lvl, cost) else string.format("Park Lv %d", lvl)
	Kit.Label(lock, Enum.NormalId.Back, text, P.Text)
	Kit.Tag(anchor, "ZoneGate", { Zone = z.Id, ZoneKey = z.Key, ZoneIndex = z.Index, RequiredLevel = lvl, Cost = cost })
	m:SetAttribute("Zone", z.Id)
end

-- Glowing mushroom (Hollow flavour).
local function mushroom(parent: Instance, cf: CFrame, s: number, rng: Random)
	Kit.Cyl(parent, 1.4 * s, 0.6 * s, cf * CFrame.new(0, 0.7 * s, 0), P.Cream)
	local col = if rng:NextNumber() < 0.5 then P.MagicPurple else P.Water
	local cap = Kit.Blob(parent, Vector3.new(2.2, 1, 2.2) * s, cf * CFrame.new(0, 1.5 * s, 0), col)
	cap:SetAttribute("GlowAtNight", true)
	cap:AddTag("NightLight")
end

local function meadow(parent: Instance, z: Layout.ZoneDef, rng: Random)
	local f = Kit.Model(parent, "MeadowEdge")
	-- Gentle open hills either side of the road.
	for k = 1, 6 do
		local side = if k % 2 == 0 then 1 else -1
		local x = side * rng:NextNumber(60, 150)
		local zz = rng:NextNumber(z.ZMin + 40, z.ZMax - 40)
		Terrain.Hill(Vector3.new(x, -rng:NextNumber(18, 26), zz), rng:NextNumber(28, 40), M.Grass)
	end
	task.wait()
	for _ = 1, 10 do
		local x = rng:NextNumber(-z.HalfWidth + 20, z.HalfWidth - 20)
		if math.abs(x) > 30 then
			Scatter.Cluster(f, x, rng:NextNumber(z.ZMin + 20, z.ZMax - 20), rng, "Round", rng:NextNumber(0.9, 1.2))
		end
	end
	for _ = 1, 26 do
		local x = rng:NextNumber(-z.HalfWidth + 15, z.HalfWidth - 15)
		local zz = rng:NextNumber(z.ZMin + 10, z.ZMax - 10)
		if math.abs(x) > 10 then
			Nature.FlowerPatch(f, Scatter.Ground(x, zz), 1.4, rng)
		end
	end
	Scatter.Sprinkle(f, -z.HalfWidth + 20, z.HalfWidth - 20, z.ZMin + 20, z.ZMax - 20, rng, 14)
end

local function hollow(parent: Instance, z: Layout.ZoneDef, rng: Random)
	local f = Kit.Model(parent, "MossyHollow")
	for k = 1, 22 do
		local x = rng:NextNumber(-z.HalfWidth + 15, z.HalfWidth - 15)
		if math.abs(x) > 22 then
			Scatter.Cluster(f, x, rng:NextNumber(z.ZMin + 15, z.ZMax - 15), rng, "Mixed", rng:NextNumber(1.1, 1.5))
		end
		if k % 6 == 0 then
			task.wait()
		end
	end
	Scatter.Sprinkle(f, -z.HalfWidth + 15, z.HalfWidth - 15, z.ZMin + 15, z.ZMax - 15, rng, 24, true)
	for _ = 1, 18 do
		local x, zz = rng:NextNumber(-z.HalfWidth + 15, z.HalfWidth - 15), rng:NextNumber(z.ZMin + 10, z.ZMax - 10)
		mushroom(f, Scatter.Ground(x, zz), rng:NextNumber(0.8, 1.6), rng)
	end
	-- Ground mist emitters.
	for k = 1, 6 do
		local p = Kit.Block(f, Vector3.new(80, 1, 60), CFrame.new(((k - 1) % 3 - 1) * 110, 3, z.ZMin + 60 + (if k > 3 then 130 else 0)), P.Cream)
		p.Name = "Mist"
		p.Transparency = 1
		p.CastShadow = false
		Theme.Effects.Mist().Parent = p
	end
	local fire = Kit.Block(f, Vector3.new(z.HalfWidth * 2, 10, z.ZMax - z.ZMin), CFrame.new(0, 8, (z.ZMin + z.ZMax) / 2), P.Cream)
	fire.Name = "Fireflies"
	fire.Transparency = 1
	fire.CastShadow = false
	local e = Theme.Effects.Fireflies()
	e.Rate = 12
	e.Enabled = false
	e.Parent = fire
	fire:AddTag("Fireflies")
end

local function glade(parent: Instance, z: Layout.ZoneDef, rng: Random): (number, number) -> boolean
	local f = Kit.Model(parent, "WaterfallGlade")
	local lake = Layout.Lake
	Terrain.Lake(lake.Center, lake.Radius)
	Terrain.Cliff()
	Waterfall.Build(f)
	local function inLake(x: number, zz: number): boolean
		return (Vector2.new(x, zz) - Vector2.new(lake.Center.X, lake.Center.Z)).Magnitude < lake.Radius + 12 or zz < -1135
	end
	for _ = 1, 14 do
		local x, zz = rng:NextNumber(-z.HalfWidth + 15, z.HalfWidth - 15), rng:NextNumber(z.ZMin + 30, z.ZMax - 15)
		if math.abs(x) > 20 and not inLake(x, zz) then
			Scatter.Cluster(f, x, zz, rng, "Magic", rng:NextNumber(1, 1.3))
		end
	end
	Scatter.Sprinkle(f, -z.HalfWidth + 20, z.HalfWidth - 20, z.ZMin + 40, z.ZMax - 20, rng, 10)
	-- Discovery spots: glowing ring + rising sparkles + footprint trail.
	local spots = { Vector3.new(-90, 0, -960), Vector3.new(120, 0, -980), Vector3.new(-60, 0, -1090), Vector3.new(110, 0, -1100) }
	for i, pos in spots do
		local y = Scatter.GroundY(pos.X, pos.Z)
		local m = Kit.Model(f, "DiscoverySpot" .. i)
		local ringPart = Kit.Cyl(m, 0.2, 9, CFrame.new(pos.X, y + 0.1, pos.Z), P.Discovery, M.Neon)
		ringPart.Transparency = 0.5
		ringPart.Name = "Ring"
		local inner = Kit.Cyl(m, 0.22, 7.6, CFrame.new(pos.X, y + 0.11, pos.Z), P.ForestFloor)
		inner.Name = "Inner"
		Theme.Effects.Discovery().Parent = ringPart
		for k = 1, 4 do
			local fp = Kit.Blob(m, Vector3.new(0.9, 0.12, 1.3), CFrame.new(pos.X + k * 3 * (if k % 2 == 0 then 1 else 0.8), y + 0.08, pos.Z + k * 3.4), P.WoodDark)
			fp.CastShadow = false
		end
		m.PrimaryPart = ringPart
		Kit.Tag(m, "DiscoverySpot", { SpotId = i, Zone = z.Id })
	end
	return inLake
end

function Forest.Build(parent: Instance, rng: Random)
	local root = Kit.Model(parent, "GreenleafForest")
	local zones = Layout.Zones
	-- Road from the plaza to the waterfall.
	Terrain.Road(Vector3.new(0, 0, -Layout.PlazaRadius), Vector3.new(0, 0, zones[3].ZMin + 60), Layout.RoadWidth)
	local gate = arch(root, Layout.ForestGateZ, "Greenleaf Forest", P.Leaf1)
	gate.Name = "ForestGate"
	Kit.Tag(gate, "ForestGate", { Zone = zones[1].Id })
	local anchor = Kit.Block(gate, Vector3.new(6, 1, 2), CFrame.new(0, 1, Layout.ForestGateZ), P.Cream)
	anchor.Name = "GateAnchor"
	anchor.Transparency = 1
	anchor.CastShadow = false
	Kit.Tag(anchor, "ZoneGate", { Zone = zones[1].Id, ZoneKey = zones[1].Key, ZoneIndex = 1, RequiredLevel = 1, Cost = 0 })
	for _, z in zones do
		zoneVolume(root, z)
	end
	meadow(root, zones[1], rng)
	hollow(root, zones[2], rng)
	local inLake = glade(root, zones[3], rng)
	zoneGate(root, zones[2], "Mossy Hollow", P.Teal)
	zoneGate(root, zones[3], "Waterfall Glade", P.MagicPurple)
	-- Forest walls: sides of every zone + the boundary between the park ring and the meadow.
	local walls = Kit.Model(root, "Walls")
	for _, side in { -1, 1 } do
		Scatter.Wall(walls, Vector3.new(side * 215, 0, -380), Vector3.new(side * 215, 0, -1140), rng, "Mixed", 28)
		Scatter.Wall(walls, Vector3.new(side * 30, 0, -640), Vector3.new(side * 195, 0, -640), rng, "Mixed", 30)
		Scatter.Wall(walls, Vector3.new(side * 30, 0, -900), Vector3.new(side * 195, 0, -900), rng, "Pine", 30)
	end
	spawns(root, zones[1], rng, 16, function()
		return false
	end)
	spawns(root, zones[2], rng, 16, function()
		return false
	end)
	spawns(root, zones[3], rng, 14, inLake)
end

return Forest
