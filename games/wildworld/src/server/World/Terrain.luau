--!strict
-- Smooth Terrain ground (ART_STYLE_GUIDE §2): Grass slab (top y = 0) with Decoration, Ground under
-- part-built areas, rolling backdrop hills, the Glade lake + waterfall cliff. Chunked with task.wait().
local Workspace = game:GetService("Workspace")
local Layout = require(script.Parent.Layout)

local hex = Color3.fromHex
local M = Enum.Material
local Terrain = {}
local DEPTH = 12

local function t(): Terrain
	return Workspace.Terrain
end

function Terrain.Setup()
	local tr = t()
	-- Decoration can't always be set by scripts (Studio property); pcall so the build never stops.
	pcall(function()
		tr.Decoration = true
	end)
	tr:SetMaterialColor(M.Grass, hex("#6CC644"))
	tr:SetMaterialColor(M.LeafyGrass, hex("#4FA63A"))
	tr:SetMaterialColor(M.Ground, hex("#D4B386"))
	tr:SetMaterialColor(M.Sand, hex("#F2DFA7"))
	tr:SetMaterialColor(M.Rock, hex("#9AA3B5"))
	tr:SetMaterialColor(M.Slate, hex("#7E8799"))
	tr:SetMaterialColor(M.Mud, hex("#7A5C40"))
	tr.WaterColor = hex("#3CC3E8")
	tr.WaterTransparency = 0.4
	tr.WaterReflectance = 0.35
	tr.WaterWaveSize = 0.08
	tr.WaterWaveSpeed = 6
	local base = Workspace:FindFirstChild("Baseplate")
	if base then
		base:Destroy()
	end
	local floor = Instance.new("Part")
	floor.Name = "SafetyFloor"
	floor.Anchored = true
	floor.Size = Vector3.new(2048, 2, 2048)
	floor.CFrame = CFrame.new(0, -DEPTH - 3, -320)
	floor.Transparency = 1
	floor.CanQuery = false
	floor.CastShadow = false
	floor.Parent = Workspace
end

-- Flat slab, top at y = 0. Forest area uses LeafyGrass south of the Glade too (cheaper under trees).
function Terrain.Ground()
	local tr = t()
	local chunk = 128
	local n = 0
	for x = Layout.MinX, Layout.MaxX - 1, chunk do
		for z = Layout.MinZ, Layout.MaxZ - 1, chunk do
			local cz = z + chunk / 2
			local mat = if cz < -660 and math.abs(x + chunk / 2) < 260 then M.LeafyGrass else M.Grass
			tr:FillBlock(CFrame.new(x + chunk / 2, -DEPTH / 2, cz), Vector3.new(chunk, DEPTH, chunk), mat)
			n += 1
			if n % 6 == 0 then
				task.wait()
			end
		end
	end
end

-- Repaint the top layer (so grass blades don't poke through part floors / make dirt roads).
function Terrain.Paint(cf: CFrame, sizeX: number, sizeZ: number, material: Enum.Material?)
	t():FillBlock(CFrame.new(cf.X, -2, cf.Z) * cf.Rotation, Vector3.new(sizeX, 4, sizeZ), material or M.Ground)
end

function Terrain.PaintDisc(center: Vector3, radius: number, material: Enum.Material?)
	t():FillCylinder(CFrame.new(center.X, -2, center.Z), 4, radius, material or M.Ground)
end

-- Straight road between two ground points.
function Terrain.Road(a: Vector3, b: Vector3, width: number, material: Enum.Material?)
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(Vector3.new(mid.X, 0, mid.Z), Vector3.new(b.X, 0, b.Z))
	Terrain.Paint(cf, width, (b - a).Magnitude + width * 0.5, material)
end

function Terrain.Hill(center: Vector3, radius: number, material: Enum.Material?)
	t():FillBall(center, radius, material or M.Grass)
end

-- Lake with a sand rim, flush with the ground.
function Terrain.Lake(center: Vector3, radius: number)
	local tr = t()
	tr:FillCylinder(CFrame.new(center.X, -4, center.Z), 8, radius + 6, M.Sand)
	tr:FillCylinder(CFrame.new(center.X, -4.5, center.Z), 7, radius, M.Water)
	tr:FillCylinder(CFrame.new(center.X, -8.5, center.Z), 1, radius, M.Sand)
end

-- Backdrop hills ringing the park + flanking the forest so there's never a void.
function Terrain.Backdrop(rng: Random): { Vector3 }
	local tops = {}
	-- Park ring (skip the north wedge where the forest is).
	for k = 0, 23 do
		local deg = k * 15
		if deg > 235 and deg < 305 then
			continue
		end
		local a = math.rad(deg + rng:NextNumber(-4, 4))
		local ring = 440 + rng:NextNumber(0, 40)
		local r = rng:NextNumber(40, 70)
		local c = Vector3.new(math.cos(a) * ring, -r * 0.45, math.sin(a) * ring)
		Terrain.Hill(c, r, if k % 3 == 0 then M.Grass else M.LeafyGrass)
		table.insert(tops, c + Vector3.new(0, r * 0.5, 0))
		Terrain.Hill(Vector3.new(math.cos(a) * (ring + 120), -r * 0.25, math.sin(a) * (ring + 120)), r * 1.4, M.LeafyGrass)
		if k % 4 == 1 then
			Terrain.Hill(c + Vector3.new(0, r * 0.45, 0), r * 0.25, M.Rock)
		end
		if k % 3 == 2 then
			task.wait()
		end
	end
	-- Forest flanks.
	for z = -420, -1180, -70 do
		for _, side in { -1, 1 } do
			local r = rng:NextNumber(45, 70)
			local c = Vector3.new(side * (270 + rng:NextNumber(0, 40)), -r * 0.4, z)
			Terrain.Hill(c, r, M.LeafyGrass)
			table.insert(tops, c + Vector3.new(0, r * 0.55, 0))
		end
		task.wait()
	end
	return tops
end

-- Invisible boundary walls: park box (x/z ±420) + forest corridor (x ±225, down to z -1240).
-- Keeps players off the backdrop hills / out of the SafetyFloor pit. Clear of plots (r <= 360) and zones (x ±210).
function Terrain.Bounds(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Bounds"
	folder.Parent = parent
	local H, P, F, S = 400, 420, 225, -1240
	local function wall(name: string, a: Vector2, b: Vector2)
		local w = Instance.new("Part")
		w.Name = name
		w.Anchored = true
		w.CanCollide = true
		w.CanTouch = false
		w.CanQuery = false
		w.CastShadow = false
		w.Transparency = 1
		local mid = (a + b) / 2
		w.Size = Vector3.new(math.abs(b.X - a.X) + 4, H, math.abs(b.Y - a.Y) + 4)
		w.CFrame = CFrame.new(mid.X, H / 2 - 20, mid.Y)
		w.Parent = folder
	end
	wall("South", Vector2.new(-P, P), Vector2.new(P, P))
	wall("East", Vector2.new(P, -P), Vector2.new(P, P))
	wall("West", Vector2.new(-P, -P), Vector2.new(-P, P))
	wall("NorthEast", Vector2.new(F, -P), Vector2.new(P, -P))
	wall("NorthWest", Vector2.new(-P, -P), Vector2.new(-F, -P))
	wall("ForestEast", Vector2.new(F, S), Vector2.new(F, -P))
	wall("ForestWest", Vector2.new(-F, S), Vector2.new(-F, -P))
	wall("ForestEnd", Vector2.new(-F, S), Vector2.new(F, S))
end

-- Glade back wall: rock cliff the waterfall pours over, with grass on top.
function Terrain.Cliff()
	local tr = t()
	local top = Layout.WaterfallTop
	for x = -200, 200, 40 do
		local h = 50 + math.abs(x - top.X) * 0.12
		tr:FillBlock(CFrame.new(x, h / 2 - 6, -1190), Vector3.new(48, h + 12, 90), M.Rock)
		tr:FillBlock(CFrame.new(x, h + 3, -1195), Vector3.new(48, 8, 90), M.Grass)
	end
	tr:FillBall(Vector3.new(top.X - 30, 30, -1150), 26, M.Slate)
	tr:FillBall(Vector3.new(top.X + 32, 26, -1148), 24, M.Rock)
	-- Plunge channel from the cliff into the lake.
	tr:FillBlock(CFrame.new(top.X, -3, -1110), Vector3.new(22, 6, 50), M.Water)
end

return Terrain
