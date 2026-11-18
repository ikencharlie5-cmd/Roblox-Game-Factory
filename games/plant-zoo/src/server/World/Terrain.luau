--!strict
-- Smooth Terrain ground (ART_STYLE_GUIDE §3): grass with Decoration (wind-animated blades), dirt under
-- every part-built area (so grass blades don't poke through floors/paths), hills ringing the map, ponds.
-- Ground top is y = 0 everywhere (same height the old Ground part had), so plots/pads/spawns are unchanged.
-- Generated in chunks with task.wait() so the server stays responsive.
local Workspace = game:GetService("Workspace")
local hex = Color3.fromHex
local M = Enum.Material

local Terrain = {}
Terrain.Half = 512 -- map is 1024 x 1024 studs
Terrain.Depth = 12

local function terrain(): Terrain
	return Workspace.Terrain
end

function Terrain.Setup()
	local t = terrain()
	-- Decoration (animated grass) can't be set by game scripts; it's set once in Studio and saved
	-- in the place (see README). pcall so the build never stops here.
	pcall(function()
		t.Decoration = true
	end)
	t:SetMaterialColor(M.Grass, hex("#6CC644"))
	t:SetMaterialColor(M.LeafyGrass, hex("#5FB13D"))
	t:SetMaterialColor(M.Ground, hex("#D9B98A"))
	t:SetMaterialColor(M.Sand, hex("#EBD5A6"))
	t:SetMaterialColor(M.Rock, hex("#9AA3B5"))
	t:SetMaterialColor(M.Mud, hex("#8A6A4A"))
	t.WaterColor = hex("#3CC3E8")
	t.WaterTransparency = 0.35
	t.WaterReflectance = 0.4
	t.WaterWaveSize = 0.08
	t.WaterWaveSpeed = 6
end

-- Old flat Baseplate (if Charlie's place has one) is replaced by terrain; keep an invisible safety floor.
local function retireBaseplate()
	local base = Workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base:Destroy()
	end
	local floor = Instance.new("Part")
	floor.Name = "SafetyFloor"
	floor.Anchored = true
	floor.Size = Vector3.new(Terrain.Half * 2, 2, Terrain.Half * 2)
	floor.CFrame = CFrame.new(0, -Terrain.Depth - 2, 0)
	floor.Transparency = 1
	floor.CanQuery = false
	floor.CastShadow = false
	floor.Parent = Workspace
end

-- Solid grass slab, top at y = 0, filled in 128-stud chunks.
function Terrain.Ground()
	retireBaseplate()
	local t = terrain()
	local chunk = 128
	local n = 0
	for x = -Terrain.Half, Terrain.Half - chunk, chunk do
		for z = -Terrain.Half, Terrain.Half - chunk, chunk do
			t:FillBlock(
				CFrame.new(x + chunk / 2, -Terrain.Depth / 2, z + chunk / 2),
				Vector3.new(chunk, Terrain.Depth, chunk),
				M.Grass
			)
			n += 1
			if n % 4 == 0 then
				task.wait()
			end
		end
	end
end

-- Repaint the top voxel layer under a part-built area (cf = ground-level CFrame, may be rotated).
function Terrain.Paint(cf: CFrame, sizeX: number, sizeZ: number, material: Enum.Material?)
	terrain():FillBlock(cf * CFrame.new(0, -2, 0), Vector3.new(sizeX, 4, sizeZ), material or M.Ground)
end

function Terrain.PaintDisc(center: Vector3, radius: number, material: Enum.Material?)
	terrain():FillCylinder(CFrame.new(center.X, -2, center.Z), 4, radius, material or M.Ground)
end

-- Pond: sand rim, then water flush with the grass (6 deep).
function Terrain.Pond(center: Vector3, radius: number)
	local t = terrain()
	t:FillCylinder(CFrame.new(center.X, -4, center.Z), 8, radius + 4, M.Sand)
	t:FillCylinder(CFrame.new(center.X, -3, center.Z), 6, radius, M.Water)
end

-- Rolling hills ringing the map edge (hide the void). Returns hill top positions for trees.
function Terrain.Hills(rng: Random, innerR: number, count: number): { Vector3 }
	local t = terrain()
	local tops = {}
	for k = 0, count - 1 do
		local ang = math.rad(k * (360 / count) + rng:NextNumber(-4, 4))
		local ring = innerR + rng:NextNumber(0, 50)
		local r = rng:NextNumber(32, 60)
		local center = Vector3.new(math.cos(ang) * (ring + r * 0.6), -r * 0.45, math.sin(ang) * (ring + r * 0.6))
		t:FillBall(center, r, if k % 3 == 0 then M.Grass else M.LeafyGrass)
		table.insert(tops, center + Vector3.new(0, r * 0.5, 0)) -- surface top is at center.Y + r = 0.55r
		-- A second, taller hill further out so the skyline is layered.
		local far = Vector3.new(math.cos(ang) * (ring + 110), -r * 0.3, math.sin(ang) * (ring + 110))
		t:FillBall(far, r * 1.3, M.LeafyGrass)
		if k % 3 == 1 then
			t:FillBall(
				center + Vector3.new(rng:NextNumber(-10, 10), r * 0.5, rng:NextNumber(-10, 10)),
				r * 0.25,
				M.Rock
			)
		end
		if k % 3 == 2 then
			task.wait()
		end
	end
	return tops
end

return Terrain
