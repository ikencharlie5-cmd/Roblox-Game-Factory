--!strict
-- Hub plaza at the origin, brick style: stepped-circle studded plaza, the Heart Tree in a brick fountain
-- (focal point), flower planters, spawn pad, Top Parks board, Daily Chest, shop stall with striped
-- awnings, lamps, benches, forest signpost.
-- Interactive bits are tagged (see notes/graphics.md); ProximityPrompts are created here, gameplay wires them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Layout = require(script.Parent.Layout)

local Kit, Nature, Structures, P = Theme.Kit, Theme.Nature, Theme.Structures, Theme.Colors
local V = Vector3.new
local Hub = {}

local PLAZA_TOP = 0.4 -- plaza plates (0..0.4)
local INNER_TOP = 0.8 -- inner ring plates (0.4..0.8)

local function prompt(parent: BasePart, action: string, object: string): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "Prompt"
	pp.ActionText = action
	pp.ObjectText = object
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

local function ring(r: number, n: number, y: number, fn: (CFrame, number) -> ())
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		fn(CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, -a - math.pi / 2, 0), a)
	end
end

-- Pixel circle of studded plates (horizontal strips `step` studs deep) from y0 to y0 + 0.4.
local function disc(parent: Instance, radius: number, step: number, y0: number, color: Color3, name: string)
	for z = -radius, radius - step, step do
		local zc = z + step / 2
		local half = math.floor(math.sqrt(math.max(0, radius * radius - zc * zc)) / 2 + 0.5) * 2
		if half > 0 then
			local p = Kit.Brick(parent, V(half * 2, 0.4, step), CFrame.new(0, y0 + 0.2, zc), color, "Top", true)
			p.Name = name
			p.CanQuery = true
			p.CastShadow = false
		end
	end
end

local function heartTree(parent: Instance, rng: Random)
	local m = Kit.Model(parent, "HeartTree")
	local y = INNER_TOP
	-- Square brick fountain basin: stone walls, blue floor, translucent water, grass island.
	for _, side in { -1, 1 } do
		Kit.Brick(m, V(40, 2.4, 2), CFrame.new(0, y + 1.2, side * 19), P.Stone, "Top", true)
		Kit.Brick(m, V(2, 2.4, 36), CFrame.new(side * 19, y + 1.2, 0), Kit.Shade(P.Stone), "Top", true)
	end
	Kit.Brick(m, V(36, 0.4, 36), CFrame.new(0, y + 0.2, 0), P.WaterDeep, "Top", true).CastShadow = false
	local water = Kit.Tile(m, V(36, 0.4, 36), CFrame.new(0, y + 1.8, 0), P.Water)
	water.Transparency = 0.35
	water.Reflectance = 0.1
	water.Name = "Water"
	Kit.Brick(m, V(16, 3.2, 16), CFrame.new(0, y + 1.6, 0), P.GrassTop, "Top", true)
	Kit.Brick(m, V(12, 0.8, 12), CFrame.new(0, y + 3.6, 0), P.GrassAlt, "Top", true)
	Nature.MagicTree(m, CFrame.new(0, y + 4, 0), 2.6, rng, true)
	-- Spout cubes on the basin walls.
	ring(15, 6, y, function(cf)
		local spout = Kit.Brick(m, V(2, 2, 2), cf * CFrame.new(0, 2.4, 0), P.White, "All")
		local e = Theme.Effects.Splash()
		e.Rate = 6
		e.Speed = NumberRange.new(8, 12)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = spout
	end)
	local fire = Kit.Block(m, V(20, 1, 20), CFrame.new(0, 26, 0), P.Cream)
	fire.Transparency = 1
	fire.Name = "Fireflies"
	local e = Theme.Effects.Fireflies()
	e.Enabled = false
	e.Parent = fire
	fire:AddTag("Fireflies")
	Kit.Tag(m, "HeartTree")
end

local function topParksBoard(parent: Instance, cf: CFrame)
	local m = Kit.Model(parent, "TopParksBoard")
	for _, x in { -7.5, 7.5 } do
		Kit.Brick(m, V(1, 12, 1), cf * CFrame.new(x, 6, 0), P.WoodDark, "All", true)
	end
	local board = Kit.Brick(m, V(14, 9, 1), cf * CFrame.new(0, 7.5, 0), P.White, "All", true)
	board.Name = "Board"
	local roof = Kit.Wedge(m, V(17, 2.4, 2), cf * CFrame.new(0, 13.6, 0), P.Red)
	roof.Name = "Roof"
	Kit.Brick(m, V(17, 0.4, 2), cf * CFrame.new(0, 12.2, 0), P.Yellow, "Top")
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.2)
	title.BackgroundColor3 = P.Blue
	title.TextColor3 = P.White
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = "Top Parks"
	title.Parent = gui
	for i = 1, 5 do
		local row = Instance.new("TextLabel")
		row.Name = "Row" .. i
		row.Position = UDim2.fromScale(0.05, 0.2 + (i - 1) * 0.16)
		row.Size = UDim2.fromScale(0.9, 0.15)
		row.BackgroundTransparency = 1
		row.TextColor3 = P.Text
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.Text = i .. ".  ---"
		row.Parent = gui
	end
	Kit.Tag(m, "TopParksBoard")
	return m
end

local function dailyChest(parent: Instance, cf: CFrame)
	local m = Kit.Model(parent, "DailyChest")
	Kit.Brick(m, V(9, 0.8, 9), cf * CFrame.new(0, 0.4, 0), P.Blue, "Top", true)
	local base = Kit.Brick(m, V(5, 2.4, 3), cf * CFrame.new(0, 2, 0), P.Wood, "All", true)
	base.Name = "Base"
	local lid = Kit.Brick(m, V(5, 1.2, 3), cf * CFrame.new(0, 3.8, 0), P.Red, "All")
	lid.Name = "Lid"
	for _, x in { -1.5, 1.5 } do
		local band = Kit.Brick(m, V(0.6, 3.6, 3.2), cf * CFrame.new(x, 2.6, 0), P.Yellow, "None")
		band.Reflectance = 0.2
	end
	local lock = Kit.Brick(m, V(1, 1, 0.4), cf * CFrame.new(0, 3.1, -1.6), P.Yellow, "None")
	lock.Name = "Lock"
	lock.Reflectance = 0.2
	local sp = Theme.Effects.Sparkle(P.Food, 2)
	sp.Parent = lid
	m.PrimaryPart = base
	prompt(base, "Open", "Daily Gift")
	Kit.Tag(m, "DailyChest")
	return m
end

local function shopStall(parent: Instance, cf: CFrame, _rng: Random)
	local m = Kit.Model(parent, "ShopStall")
	local counter = Kit.Brick(m, V(14, 3.6, 4), cf * CFrame.new(0, 1.8, 0), P.White, "All", true)
	counter.Name = "Counter"
	Kit.Brick(m, V(14, 0.4, 4), cf * CFrame.new(0, 3.8, 0), P.Wood, "Top")
	Kit.Brick(m, V(14, 9.6, 1), cf * CFrame.new(0, 4.8, 4), P.Wood, "All", true)
	for _, x in { -6.5, 6.5 } do
		Kit.Brick(m, V(1, 9.6, 1), cf * CFrame.new(x, 4.8, -1.5), P.WoodDark, "All", true)
	end
	for i = 0, 13 do
		local col = if i % 2 == 0 then P.Awnings[math.floor(i / 2) % 4 + 1] else P.White
		local w = Kit.Wedge(m, V(1, 2.4, 7), cf * CFrame.new(-6.5 + i, 10.8, 1), col)
		w.CastShadow = i == 0
	end
	local sign = Kit.Brick(m, V(9, 2.4, 1), cf * CFrame.new(0, 13.2, 1.5), P.Blue, "Top")
	Kit.Label(sign, Enum.NormalId.Front, "Field Shop", P.White, true)
	for k = 1, 5 do
		Kit.Brick(m, V(1, 1, 1), cf * CFrame.new(-5 + k * 1.6, 4.5, -0.8), P.Flowers[k], "All")
	end
	Structures.FoodBowl(m, cf * CFrame.new(-4.5, 4.0, 0.8))
	m.PrimaryPart = counter
	prompt(counter, "Shop", "Field Shop")
	Kit.Tag(m, "ShopStall", { Shop = "Main" })
	return m
end

-- Builds the hub. Returns the spawn SpawnLocation.
function Hub.Build(parent: Instance, rng: Random): SpawnLocation
	local hub = Kit.Model(parent, "Hub")
	disc(hub, Layout.PlazaRadius, 8, 0, P.Plaza, "Plaza")
	disc(hub, 32, 4, PLAZA_TOP, P.Path, "InnerRing")
	heartTree(hub, rng)

	-- Flower planters between the spoke paths (spokes run at 22.5° + 45°k, the forest road at 270°).
	for _, deg in { 45, 90, 135, 315 } do
		local a = math.rad(deg)
		local base = CFrame.lookAt(V(math.cos(a) * 68, PLAZA_TOP, math.sin(a) * 68), V(0, PLAZA_TOP, 0))
		local bed = Kit.Model(hub, "FlowerBed")
		Kit.Brick(bed, V(14, 1.2, 5), base * CFrame.new(0, 0.6, 0), P.Red, "Top", true)
		Kit.Brick(bed, V(12, 0.4, 3), base * CFrame.new(0, 1.4, 0), P.Dirt, "Top")
		for x = -4.8, 4.8, 2.4 do
			Nature.FlowerPatch(bed, base * CFrame.new(x, 1.6, 0), 0.7, rng)
		end
	end
	-- Lamps + benches on the inner circle.
	ring(36, 8, PLAZA_TOP, function(cf)
		Structures.Lantern(hub, cf * CFrame.Angles(0, math.rad(90), 0))
	end)
	ring(27, 4, INNER_TOP, function(cf)
		Structures.Bench(hub, cf * CFrame.Angles(0, math.rad(180), 0))
	end)

	-- Landmarks (facing the centre).
	local function facing(deg: number, r: number): CFrame
		local a = math.rad(deg)
		local pos = V(math.cos(a) * r, PLAZA_TOP, math.sin(a) * r)
		return CFrame.lookAt(pos, V(0, PLAZA_TOP, 0))
	end
	topParksBoard(hub, facing(-135, 64))
	shopStall(hub, facing(0, 64), rng)
	dailyChest(hub, facing(180, 62))
	-- Signpost to the forest (north edge of the plaza).
	local post = Kit.Model(hub, "ForestSign")
	local sp = CFrame.new(10, PLAZA_TOP, -72)
	Kit.Brick(post, V(1, 8, 1), sp * CFrame.new(0, 4, 0), P.WoodDark, "All", true)
	local arrow = Kit.Brick(post, V(9, 2, 1), sp * CFrame.new(-2, 7, 0), P.Leaf2, "Top")
	Kit.Label(arrow, Enum.NormalId.Back, "Greenleaf Meadow", P.White)
	local arrow2 = Kit.Brick(post, V(8, 2, 1), sp * CFrame.new(2, 4.8, 0), P.Yellow, "Top")
	Kit.Label(arrow2, Enum.NormalId.Back, "Your Park", P.Text)

	-- Spawn: studded blue pad south of the tree, facing it.
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.Size = V(10, 0.4, 10)
	spawnLoc.CFrame = CFrame.new(0, 0.6, 42)
	spawnLoc.Color = P.Blue
	spawnLoc.Material = Enum.Material.Plastic
	Kit.Studs(spawnLoc, "Top")
	spawnLoc.CanCollide = true
	spawnLoc.CastShadow = false
	spawnLoc.Parent = hub
	local decal = spawnLoc:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	Kit.Tag(spawnLoc, "HubSpawn")

	-- Bushes around the plaza rim (gaps for the spokes and the forest road).
	ring(Layout.PlazaRadius + 3, 16, 0, function(cf, a)
		local deg = math.deg(a)
		if math.abs(deg - 270) < 12 or math.abs((deg - 22.5) % 45) < 1 then
			return
		end
		Nature.Bush(hub, cf, 1.1, rng, rng:NextNumber() < 0.3)
	end)
	return spawnLoc
end

return Hub
