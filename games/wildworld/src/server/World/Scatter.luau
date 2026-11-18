--!strict
-- Foliage clustering: groups of 3–5 (1 big, 2 medium, 1–2 small) brick trees, yaw in 90° steps (grid look),
-- scale ×0.8–1.3. Brick trees are bigger and blockier, so clusters are ~30% sparser than the lush plan
-- (STUDS_STYLE_GUIDE §6). Each cluster is its own small Model (streaming-friendly).
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Kit, Nature = Theme.Kit, Theme.Nature
local Terrain = require(script.Parent.Terrain)

local Scatter = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Ground-part surface height at (x, z) (plates, hills, cliff; 0 if nothing hit).
function Scatter.GroundY(x: number, z: number): number
	rayParams.FilterDescendantsInstances = { Terrain.Folder() }
	local hit = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -320, 0), rayParams)
	if hit then
		return hit.Position.Y
	end
	return 0
end

function Scatter.Ground(x: number, z: number): CFrame
	return CFrame.new(x, Scatter.GroundY(x, z), z)
end

local function yaw(rng: Random): CFrame
	return CFrame.Angles(0, rng:NextInteger(0, 3) * math.pi / 2, 0)
end

export type Kind = "Round" | "Pine" | "Magic" | "Mixed"

local function tree(parent: Instance, cf: CFrame, s: number, rng: Random, kind: Kind)
	local k = kind
	if k == "Mixed" then
		k = if rng:NextNumber() < 0.35 then "Pine" else "Round"
	end
	if k == "Pine" then
		Nature.Pine(parent, cf, s, rng)
	elseif k == "Magic" then
		Nature.MagicTree(parent, cf, s, rng, rng:NextNumber() < 0.4)
	else
		Nature.Tree(parent, cf, s, rng)
	end
end

-- Tree cluster around (x, z). size = base scale (1 = ~12-stud tall brick oak).
function Scatter.Cluster(parent: Instance, x: number, z: number, rng: Random, kind: Kind, size: number?)
	local m = Kit.Model(parent, "TreeCluster")
	local s = size or 1
	local sizes = { 1.25, 0.95, 0.9, 0.7 }
	local n = rng:NextInteger(2, 4)
	for i = 1, n do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = if i == 1 then 0 else rng:NextNumber(9, 13) * s
		local px, pz = x + math.cos(a) * d, z + math.sin(a) * d
		local sc = sizes[i] * s * rng:NextNumber(0.85, 1.15)
		if i >= 3 and rng:NextNumber() < 0.5 then
			Nature.Bush(m, Scatter.Ground(px, pz) * yaw(rng), sc * 1.3, rng, rng:NextNumber() < 0.3)
		else
			tree(m, Scatter.Ground(px, pz) * yaw(rng), sc, rng, kind)
		end
	end
	if rng:NextNumber() < 0.6 then
		local a = rng:NextNumber(0, math.pi * 2)
		Nature.FlowerPatch(m, Scatter.Ground(x + math.cos(a) * 9 * s, z + math.sin(a) * 9 * s), 1.2, rng)
	end
	return m
end

-- Flower strip along a line (a -> b), tufts every `step` studs.
function Scatter.FlowerLine(parent: Instance, a: Vector3, b: Vector3, rng: Random, step: number?)
	local m = Kit.Model(parent, "Flowers")
	local len = (b - a).Magnitude
	local st = step or 6
	for d = 0, len, st do
		local p = a:Lerp(b, d / math.max(len, 1))
		Nature.FlowerPatch(m, CFrame.new(p.X, p.Y, p.Z) * yaw(rng), 0.9, rng)
	end
	return m
end

-- Dense wall of clusters along a line (biome edges / map edges).
function Scatter.Wall(parent: Instance, a: Vector3, b: Vector3, rng: Random, kind: Kind, spacing: number?)
	local len = (b - a).Magnitude
	local sp = (spacing or 26) * 1.2
	for d = 0, len, sp do
		local p = a:Lerp(b, d / math.max(len, 1))
		Scatter.Cluster(parent, p.X + rng:NextNumber(-6, 6), p.Z + rng:NextNumber(-6, 6), rng, kind, rng:NextNumber(1.1, 1.5))
	end
	task.wait()
end

-- Loose rocks / bushes / flowers sprinkled in a rectangle.
function Scatter.Sprinkle(parent: Instance, x0: number, x1: number, z0: number, z1: number, rng: Random, count: number, mossy: boolean?)
	local m = Kit.Model(parent, "Sprinkle")
	for _ = 1, count do
		local x, z = rng:NextNumber(x0, x1), rng:NextNumber(z0, z1)
		local r = rng:NextNumber()
		local cf = Scatter.Ground(x, z) * yaw(rng)
		if r < 0.35 then
			Nature.FlowerPatch(m, cf, 1.1, rng)
		elseif r < 0.65 then
			Nature.Rock(m, cf, rng:NextNumber(0.7, 1.5), rng, mossy or rng:NextNumber() < 0.3)
		elseif r < 0.85 then
			Nature.Bush(m, cf, rng:NextNumber(0.9, 1.3), rng, rng:NextNumber() < 0.3)
		else
			Nature.Log(m, cf, rng:NextNumber(0.9, 1.3))
		end
	end
	return m
end

return Scatter
