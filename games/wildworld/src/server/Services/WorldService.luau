--!strict
-- WorldService (Graphics): builds the whole map in code on Init and exposes world helpers to gameplay.
-- Build order: terrain -> hub -> spokes -> 8 plots -> Greenleaf Forest -> lighting/day cycle/clouds.
-- Gameplay: call WorldService.WaitReady() before touching plots (Init yields while terrain fills).
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

local World = script.Parent.Parent:WaitForChild("World")
local Layout = require(World:WaitForChild("Layout"))
local Terrain = require(World:WaitForChild("Terrain"))
local Scatter = require(World:WaitForChild("Scatter"))
local Hub = require(World:WaitForChild("Hub"))
local Plots = require(World:WaitForChild("Plots"))
local Forest = require(World:WaitForChild("Forest"))
local Sky = require(World:WaitForChild("Sky"))

local Kit = Theme.Kit
local WorldService = {}
WorldService.Layout = Layout
WorldService.Moments = Theme.Moments

local ready = false
local readyEvent = Instance.new("BindableEvent")
local hubSpawn: SpawnLocation? = nil

local function spokes(parent: Instance, rng: Random)
	local folder = Kit.Model(parent, "Spokes")
	for i = 1, Layout.PlotCount do
		local a = Layout.PlotAngle(i)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local from = dir * (Layout.PlazaRadius - 2)
		local to = dir * (Layout.PlotRing - Layout.PlotSize / 2)
		Terrain.Road(from, to, 12)
		local side = Vector3.new(-dir.Z, 0, dir.X)
		for _, t in { 0.35, 0.75 } do
			local p = from:Lerp(to, t) + side * 8
			Theme.Structures.Lantern(folder, CFrame.lookAt(p, p + dir))
		end
		for _, s in { -1, 1 } do
			Scatter.FlowerLine(folder, from + dir * 8 + side * s * 7.5, to - dir * 6 + side * s * 7.5, rng, 7)
		end
	end
end

function WorldService.Init()
	local rng = Random.new(20261118)
	local root = Kit.Folder(Workspace, "World")
	Kit.Folder(Workspace, "WorldFX")
	Terrain.Setup()
	Terrain.Ground()
	local hillTops = Terrain.Backdrop(rng)
	hubSpawn = Hub.Build(root, rng)
	spokes(root, rng)
	-- Tree clusters on the lawns between spokes (not on the forest road at 270°).
	local lawn = Kit.Model(root, "LawnTrees")
	for _, deg in { 0, 45, 90, 135, 180, 225, 315 } do
		local a = math.rad(deg)
		Scatter.Cluster(lawn, math.cos(a) * 150, math.sin(a) * 150, rng, "Round", 1.1)
	end
	Plots.Build(root, rng)
	Forest.Build(root, rng)
	Terrain.Bounds(root)
	-- Anyone who falls onto the hidden SafetyFloor goes back to the hub (per-character debounce).
	local floor = Workspace:FindFirstChild("SafetyFloor") :: BasePart?
	if floor then
		local busy: { [Model]: boolean } = {}
		floor.Touched:Connect(function(hit)
			local parent = hit.Parent
			if not parent or not parent:IsA("Model") or not parent:FindFirstChildOfClass("Humanoid") then
				return
			end
			local char = parent :: Model
			if busy[char] then
				return
			end
			busy[char] = true
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
			char:PivotTo(WorldService.HubSpawn())
			task.delay(1, function()
				busy[char] = nil
			end)
		end)
	end
	-- Trees on every other backdrop hilltop.
	local hills = Kit.Model(root, "HillTrees")
	for i, top in hillTops do
		if i % 2 == 0 then
			Scatter.Cluster(hills, top.X, top.Z, rng, "Mixed", 1.4)
		end
	end
	local areas = { Vector3.zero }
	for i = 1, Layout.PlotCount do
		table.insert(areas, Layout.PlotCFrame(i).Position)
	end
	for _, z in Layout.Zones do
		table.insert(areas, Vector3.new(-90, 0, (z.ZMin + z.ZMax) / 2))
		table.insert(areas, Vector3.new(90, 0, (z.ZMin + z.ZMax) / 2))
	end
	-- Audio zone volumes for the hub and every plot (forest ones are made by Forest).
	local hubZone = Kit.Block(root, Vector3.new(180, 80, 180), CFrame.new(0, 30, 0), Theme.Colors.Cream)
	hubZone.Name = "HubAudio"
	hubZone.Transparency = 1
	hubZone.CastShadow = false
	Kit.Tag(hubZone, "AudioZone", { Zone = "Hub" })
	for i = 1, Layout.PlotCount do
		local z = Kit.Block(root, Vector3.new(140, 80, 140), Layout.PlotCFrame(i) + Vector3.new(0, 30, 0), Theme.Colors.Cream)
		z.Name = "Plot" .. i .. "Audio"
		z.Transparency = 1
		z.CastShadow = false
		Kit.Tag(z, "AudioZone", { Zone = "Park", PlotIndex = i })
	end
	Sky.Setup(areas)
	Sky.Clouds(rng)
	ready = true
	Workspace:SetAttribute("WorldReady", true)
	readyEvent:Fire()
end

function WorldService.Start()
	Sky.StartCycle()
	-- Follow gameplay's WeatherService (ReplicatedStorage.GameState attribute "Weather").
	task.spawn(function()
		local state = ReplicatedStorage:WaitForChild("GameState", 60)
		if not state then
			return
		end
		local function apply()
			Sky.SetWeather(state:GetAttribute("Weather") :: string?)
		end
		state:GetAttributeChangedSignal("Weather"):Connect(apply)
		apply()
	end)
end

function WorldService.WaitReady()
	if not ready then
		readyEvent.Event:Wait()
	end
end

-- ===== Plots =====
function WorldService.GetPlot(i: number): Model?
	return Plots.Get(i)
end

function WorldService.GetPlots(): { Model }
	return Plots.All()
end

function WorldService.PlotCFrame(i: number): CFrame
	return Layout.PlotCFrame(i)
end

function WorldService.SetPlotOwner(i: number, player: Player?)
	Plots.SetOwner(i, player)
end

-- studs: 64 / 80 / 96 / 112 / 128 (Park Land upgrade).
function WorldService.SetPlotLand(i: number, studs: number)
	Plots.SetLand(i, studs)
end

-- Where a player should stand when arriving at plot i (inside the gate, facing in).
function WorldService.PlotSpawn(i: number): CFrame
	return Layout.PlotCFrame(i) * CFrame.new(0, 3, -Layout.PlotSize / 2 + 10) * CFrame.Angles(0, math.pi, 0)
end

-- World CFrame of an item footprint on plot i (cells 1..32, rot = 90° steps). See Theme.Grid.
function WorldService.CellToWorld(i: number, cellX: number, cellZ: number, footX: number, footZ: number, rot: number?): CFrame
	return Layout.PlotCFrame(i) * Theme.Grid.CellToLocal(cellX, cellZ, footX, footZ, rot)
end

-- Build + place an item model into plot i's Items folder. Returns the model (gameplay sets its own attrs).
function WorldService.SpawnItem(i: number, itemId: string, cellX: number, cellZ: number, rot: number?, seed: number?): Model?
	local plot = Plots.Get(i)
	local m = Theme.Props.Build(itemId, seed)
	if not plot or not m then
		return nil
	end
	local foot = Theme.Props.Items[itemId].Foot
	m:PivotTo(WorldService.CellToWorld(i, cellX, cellZ, foot[1], foot[2], rot))
	m.Parent = plot:FindFirstChild("Items") or plot
	return m
end

-- ===== Hub / zones =====
function WorldService.HubSpawn(): CFrame
	return if hubSpawn then hubSpawn.CFrame + Vector3.new(0, 3, 0) else CFrame.new(0, 4, 42)
end

local function inside(part: BasePart, pos: Vector3): boolean
	local lp = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end

-- "Hub" | "Park" (+ plot index) | "Meadow" | "Hollow" | "Glade" | "Wild" (anywhere else).
function WorldService.ZoneAt(pos: Vector3): (string, number?)
	for _, v in CollectionService:GetTagged("WorldZone") do
		if v:IsA("BasePart") and inside(v, pos) then
			return v:GetAttribute("Zone") :: string, nil
		end
	end
	if Vector2.new(pos.X, pos.Z).Magnitude <= Layout.PlazaRadius + 5 then
		return "Hub", nil
	end
	for i, plot in Plots.All() do
		local lp = Layout.PlotCFrame(i):PointToObjectSpace(pos)
		if math.abs(lp.X) <= Layout.PlotSize / 2 + 2 and math.abs(lp.Z) <= Layout.PlotSize / 2 + 2 then
			return "Park", plot:GetAttribute("PlotIndex") :: number
		end
	end
	return "Wild", nil
end

function WorldService.WildSpawns(zoneKey: string): { BasePart }
	local out = {}
	for _, p in CollectionService:GetTagged("WildSpawn") do
		if p:IsA("BasePart") and p:GetAttribute("Zone") == zoneKey then
			table.insert(out, p)
		end
	end
	return out
end

function WorldService.ZoneGate(zoneKey: string): Model?
	for _, g in CollectionService:GetTagged("ZoneGate") do
		if g:IsA("Model") and g:GetAttribute("Zone") == zoneKey then
			return g
		end
	end
	return nil
end

-- rows = { {name, rating}, ... } (up to 5) -> Top Parks board in the hub.
function WorldService.SetTopParks(rows: { { any } })
	for _, board in CollectionService:GetTagged("TopParksBoard") do
		local gui = board:FindFirstChild("BoardGui", true)
		if not gui then
			continue
		end
		for i = 1, 5 do
			local label = gui:FindFirstChild("Row" .. i) :: TextLabel?
			local r = rows[i]
			if label then
				label.Text = if r then string.format("%d.  %s  -  %s", i, tostring(r[1]), tostring(r[2])) else i .. ".  ---"
			end
		end
	end
end

-- ===== Sky =====
function WorldService.SetWeather(name: string?)
	Sky.SetWeather(name)
end

function WorldService.IsNight(): boolean
	return Sky.IsNight()
end

return WorldService
