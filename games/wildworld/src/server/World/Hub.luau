--!strict
-- Hub plaza at the origin: stone plaza, the Heart Tree + fountain (focal point), flower beds, spawn,
-- Top Parks board, Daily Chest, shop stall with striped awnings, lamps, benches, forest signpost.
-- Interactive bits are tagged (see notes/graphics.md); ProximityPrompts are created here, gameplay wires them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Layout = require(script.Parent.Layout)
local Terrain = require(script.Parent.Terrain)

local Kit, Nature, Structures, P = Theme.Kit, Theme.Nature, Theme.Structures, Theme.Colors
local M = Enum.Material
local Hub = {}

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

local function ring(_parent: Instance, r: number, n: number, fn: (CFrame, number) -> ())
	for k = 0, n - 1 do
		local a = k / n * math.pi * 2
		fn(CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, -a - math.pi / 2, 0), a)
	end
end

local function heartTree(parent: Instance, rng: Random)
	local m = Kit.Model(parent, "HeartTree")
	-- Fountain basin
	Kit.Cyl(m, 2.4, 40, CFrame.new(0, 1.2, 0), P.PlazaStone, M.Cobblestone, true)
	local water = Kit.Cyl(m, 0.4, 36, CFrame.new(0, 2.3, 0), P.Water, M.Glass)
	water.Transparency = 0.2
	water.Name = "Water"
	Kit.Cyl(m, 3, 16, CFrame.new(0, 3.5, 0), P.Moss, M.Grass, true)
	Nature.MagicTree(m, CFrame.new(0, 4.5, 0), 2.6, rng, true)
	-- Little spouts
	ring(m, 15, 6, function(cf)
		local spout = Kit.Ball(m, 1.6, cf * CFrame.new(0, 2.6, 0), P.PlazaStone, M.Cobblestone)
		local e = Theme.Effects.Splash()
		e.Rate = 6
		e.Speed = NumberRange.new(8, 12)
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = spout
	end)
	local fire = Kit.Block(m, Vector3.new(20, 1, 20), CFrame.new(0, 26, 0), P.Cream)
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
	for _, x in { -6.5, 6.5 } do
		Kit.Solid(m, Vector3.new(1, 12, 1), cf * CFrame.new(x, 6, 0), P.WoodDark, M.Wood)
	end
	local board = Kit.Solid(m, Vector3.new(14, 9, 0.6), cf * CFrame.new(0, 7.5, 0), P.Parchment)
	board.Name = "Board"
	local roof = Kit.Wedge(m, Vector3.new(16, 2, 2), cf * CFrame.new(0, 13, 0), P.Teal)
	roof.Name = "Roof"
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.2)
	title.BackgroundColor3 = P.Teal
	title.TextColor3 = P.Cream
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
	Kit.Cyl(m, 1, 9, cf * CFrame.new(0, 0.5, 0), P.PlazaStone, M.Cobblestone, true)
	local base = Kit.Solid(m, Vector3.new(4.4, 2.6, 3), cf * CFrame.new(0, 2.3, 0), P.Wood, M.WoodPlanks)
	base.Name = "Base"
	local lid = Kit.Part(m, {
		Size = Vector3.new(4.4, 3, 3),
		CFrame = cf * CFrame.new(0, 3.6, 0),
		Color = P.Coral,
		Shape = Enum.PartType.Cylinder,
		Name = "Lid",
	})
	for _, x in { -1.6, 1.6 } do
		Kit.Block(m, Vector3.new(0.4, 2.8, 3.1), cf * CFrame.new(x, 2.4, 0), P.Food, M.Metal)
	end
	local lock = Kit.Block(m, Vector3.new(0.8, 0.9, 0.3), cf * CFrame.new(0, 2.9, -1.6), P.Food, M.Metal)
	lock.Name = "Lock"
	local sp = Theme.Effects.Sparkle(P.Food, 2)
	sp.Parent = lid
	m.PrimaryPart = base
	prompt(base, "Open", "Daily Gift")
	Kit.Tag(m, "DailyChest")
	return m
end

local function shopStall(parent: Instance, cf: CFrame, _rng: Random)
	local m = Kit.Model(parent, "ShopStall")
	local counter = Kit.Solid(m, Vector3.new(14, 3.4, 4), cf * CFrame.new(0, 1.7, 0), P.Cream)
	counter.Name = "Counter"
	Kit.Block(m, Vector3.new(14.6, 0.5, 4.6), cf * CFrame.new(0, 3.6, 0), P.Wood, M.WoodPlanks)
	Kit.Solid(m, Vector3.new(14, 9, 1), cf * CFrame.new(0, 4.5, 4), P.Wood, M.WoodPlanks)
	for _, x in { -6.6, 6.6 } do
		Kit.Cyl(m, 9, 0.6, cf * CFrame.new(x, 4.5, -1.8), P.WoodDark, M.Wood, true)
	end
	for i = 0, 11 do
		local col = if i % 2 == 0 then P.Awnings[math.floor(i / 2) % 4 + 1] else P.Cream
		local w = Kit.Wedge(m, Vector3.new(1.25, 2, 7), cf * CFrame.new(-6.9 + i * 1.25, 9.8, 0.8), col)
		w.CastShadow = i == 0
	end
	local sign = Kit.Block(m, Vector3.new(9, 2.2, 0.4), cf * CFrame.new(0, 11.8, -0.4), P.Teal)
	Kit.Label(sign, Enum.NormalId.Front, "Field Shop", P.Cream, true)
	for k = 1, 5 do
		local col = P.Flowers[k]
		Kit.Ball(m, 0.9, cf * CFrame.new(-5 + k * 1.7, 4.3, -0.6), col)
	end
	Structures.FoodBowl(m, cf * CFrame.new(-4.2, 3.85, 0.6))
	m.PrimaryPart = counter
	prompt(counter, "Shop", "Field Shop")
	Kit.Tag(m, "ShopStall", { Shop = "Main" })
	return m
end

-- Builds the hub. Returns the spawn SpawnLocation.
function Hub.Build(parent: Instance, rng: Random): SpawnLocation
	local hub = Kit.Model(parent, "Hub")
	Terrain.PaintDisc(Vector3.zero, Layout.PlazaRadius + 4, Enum.Material.Ground)
	local plaza = Kit.Cyl(hub, 0.6, Layout.PlazaRadius * 2, CFrame.new(0, 0.1, 0), P.Plaza, M.Pavement, true)
	plaza.Name = "Plaza"
	local inner = Kit.Cyl(hub, 0.62, 64, CFrame.new(0, 0.12, 0), P.PlazaStone, M.Cobblestone, true)
	inner.Name = "InnerRing"
	heartTree(hub, rng)

	-- Flower beds between the spoke paths (spokes run at 22.5° + 45°k, the forest road at 270°).
	for _, deg in { 45, 90, 135, 315 } do
		local a = math.rad(deg)
		local base = CFrame.lookAt(Vector3.new(math.cos(a) * 68, 0, math.sin(a) * 68), Vector3.zero)
		local bed = Kit.Model(hub, "FlowerBed")
		Kit.Solid(bed, Vector3.new(14, 1, 5), base * CFrame.new(0, 0.6, 0), P.WoodDark, M.Wood)
		Kit.Block(bed, Vector3.new(13, 0.4, 4), base * CFrame.new(0, 1.2, 0), P.Trunk, M.Ground)
		for x = -5, 5, 2.5 do
			Nature.FlowerPatch(bed, base * CFrame.new(x, 1.3, 0), 0.8, rng)
		end
	end
	-- Lamps + benches on the inner circle.
	ring(hub, 36, 8, function(cf)
		Structures.Lantern(hub, cf * CFrame.Angles(0, math.rad(90), 0))
	end)
	ring(hub, 30, 4, function(cf)
		Structures.Bench(hub, cf * CFrame.Angles(0, math.rad(180), 0))
	end)

	-- Landmarks (facing the centre).
	local function facing(deg: number, r: number): CFrame
		local a = math.rad(deg)
		local pos = Vector3.new(math.cos(a) * r, 0.4, math.sin(a) * r)
		return CFrame.lookAt(pos, Vector3.new(0, 0.4, 0))
	end
	topParksBoard(hub, facing(-135, 64))
	shopStall(hub, facing(0, 64), rng)
	dailyChest(hub, facing(180, 62))
	-- Signpost to the forest (north edge of the plaza).
	local post = Kit.Model(hub, "ForestSign")
	local sp = CFrame.new(10, 0.4, -72)
	Kit.Cyl(post, 8, 0.8, sp * CFrame.new(0, 4, 0), P.WoodDark, M.Wood, true)
	local arrow = Kit.Block(post, Vector3.new(9, 2, 0.5), sp * CFrame.new(-2, 7, 0), P.Leaf1)
	Kit.Label(arrow, Enum.NormalId.Back, "Greenleaf Forest", P.Cream)
	local arrow2 = Kit.Block(post, Vector3.new(8, 1.8, 0.5), sp * CFrame.new(2, 4.8, 0), P.Parchment)
	Kit.Label(arrow2, Enum.NormalId.Back, "Your Park", P.Text)

	-- Spawn: south of the tree, facing it.
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "HubSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.Size = Vector3.new(10, 0.4, 10)
	spawnLoc.CFrame = CFrame.new(0, 0.6, 42)
	spawnLoc.Color = P.PlazaStone
	spawnLoc.Material = M.Cobblestone
	spawnLoc.Transparency = 1
	spawnLoc.CanCollide = false
	spawnLoc.Parent = hub
	local decal = spawnLoc:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	Kit.Tag(spawnLoc, "HubSpawn")

	-- Outer flower strip + a few bushes around the plaza rim.
	ring(hub, Layout.PlazaRadius + 3, 16, function(cf, a)
		local deg = math.deg(a)
		if math.abs(deg - 270) < 12 or math.abs((deg - 22.5) % 45) < 1 then
			return
		end
		Nature.Bush(hub, cf, 1.1, rng, rng:NextNumber() < 0.3)
	end)
	return spawnLoc
end

return Hub
