--!strict
-- Ground, spoke paths from hub to plots, lamps, trees, flowers, distant hills and clouds.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)

local V = Vector3.new
local C = CFrame.new
local hex = Color3.fromHex
local M = Enum.Material

local Scenery = {}

local FLOWER_COLORS = { hex("#FFD54F"), hex("#FF8FB8"), hex("#FFFFFF"), hex("#B57CFF"), hex("#FF6F61") }

local function polar(angleDeg: number, r: number, y: number?): Vector3
	local a = math.rad(angleDeg)
	return V(math.cos(a) * r, y or 0, math.sin(a) * r)
end

-- Reuse Charlie's Baseplate if the place has one; otherwise make a grass ground. Top surface at y = 0.
local function ground()
	local base = Workspace:FindFirstChild("Baseplate")
	local part: Part
	if base and base:IsA("Part") then
		part = base
		if part.Size.X < 900 then
			part.Size = V(900, 16, 900)
		end
		part.CFrame = C(0, -part.Size.Y / 2, 0)
	else
		part = Build.Part(Workspace, { Size = V(900, 16, 900), CFrame = C(0, -8, 0), Name = "Ground" })
	end
	part.Anchored = true
	part.Color = Theme.Colors.Grass
	part.Material = M.Grass
	for _, d in part:GetChildren() do
		if d:IsA("Texture") or d:IsA("Decal") then
			d:Destroy()
		end
	end
end

local function lamp(f: Instance, pos: Vector3)
	Build.Cyl(f, 7, 0.5, C(pos + V(0, 3.5, 0)), hex("#3B3B4A"), M.Metal, true)
	local lantern = Build.Deco(
		f,
		{ Size = V(1.2, 1.4, 1.2), CFrame = C(pos + V(0, 7.6, 0)), Color = hex("#FFF2B3"), Name = "Lantern" }
	)
	Build.Deco(
		f,
		{ Size = V(1.6, 0.3, 1.6), CFrame = C(pos + V(0, 8.45, 0)), Color = hex("#3B3B4A"), Material = M.Metal }
	)
	local l = Instance.new("PointLight")
	l.Color = hex("#FFD58A")
	l.Range = 18
	l.Brightness = 1.4
	l.Enabled = false
	l.Parent = lantern
	Build.Tag(lantern, "NightLight")
end

local function spoke(f: Instance, i: number)
	local angle = (i - 1) * 60
	local inner, outer = 61, 130
	local mid = (inner + outer) / 2
	local p = polar(angle, mid, 0.1)
	local cf = CFrame.lookAt(p, V(0, 0.1, 0))
	Build.Part(
		f,
		{ Size = V(10, 0.2, outer - inner), CFrame = cf, Color = Theme.Colors.Path, Material = M.Sand, Name = "Spoke" }
	)
	for _, side in { -1, 1 } do
		Build.Part(
			f,
			{
				Size = V(0.8, 0.3, outer - inner),
				CFrame = cf * C(side * 5.4, 0.05, 0),
				Color = Theme.Colors.PathEdge,
				Material = M.Cobblestone,
				Name = "Edge",
			}
		)
		for _, z in { -20, 20 } do
			lamp(f, (cf * C(side * 7, -0.1, z)).Position)
		end
	end
end

local function flowerPatch(f: Instance, center: Vector3, rng: Random)
	Build.Blob(f, V(7, 0.6, 5), C(center), Theme.Colors.GrassDark, M.Grass)
	for _ = 1, 5 do
		local off = V(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-1.8, 1.8))
		Build.Flower(f, center + off, FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
	end
end

local function bush(f: Instance, pos: Vector3, rng: Random)
	local col = Theme.Colors.Leaf:Lerp(Theme.Colors.LeafLight, rng:NextNumber())
	Build.Ball(f, rng:NextNumber(3, 4.5), C(pos + V(0, 1, 0)), col, M.Grass)
	Build.Ball(f, 0.6, C(pos + V(0.8, 2.4, -0.6)), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)])
end

local function cloud(f: Instance, pos: Vector3, rng: Random)
	for k = 0, 2 do
		local s = rng:NextNumber(14, 22)
		local b = Build.Ball(
			f,
			s,
			C(pos + V((k - 1) * s * 0.7, rng:NextNumber(-2, 2), rng:NextNumber(-3, 3))),
			Color3.new(1, 1, 1),
			M.SmoothPlastic
		)
		b.CastShadow = false
	end
end

local function fireflyZone(f: Instance, pos: Vector3, size: number)
	local p =
		Build.Deco(f, { Size = V(size, 6, size), CFrame = C(pos + V(0, 4, 0)), Transparency = 1, Name = "Fireflies" })
	p.CanQuery = false
	local e = Theme.Effects.Fireflies()
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Rate = math.floor(size / 10)
	e.Enabled = false
	e.Parent = p
	Build.Tag(p, "Fireflies")
end

function Scenery.Build(parent: Instance, plotCount: number, plotRadius: number)
	ground()
	local f = Build.Folder(parent, "Scenery")
	local rng = Random.new(20261117)
	for i = 1, plotCount do
		spoke(f, i)
		fireflyZone(f, polar((i - 1) * 60, plotRadius), 70)
	end
	fireflyZone(f, V(0, 0, 0), 100)
	task.wait()
	-- Between spokes: flower patches + bushes near the hub, tree clusters further out.
	for i = 1, plotCount do
		local mid = (i - 1) * 60 + 30
		flowerPatch(f, polar(mid + rng:NextNumber(-6, 6), 80), rng)
		flowerPatch(f, polar(mid + rng:NextNumber(-10, 10), 105), rng)
		for _ = 1, 3 do
			bush(f, polar(mid + rng:NextNumber(-14, 14), rng:NextNumber(68, 120)), rng)
		end
		for k = 0, 3 do
			local pos = polar(mid + rng:NextNumber(-8, 8), 150 + k * 25)
			Build.Tree(
				f,
				pos,
				rng:NextNumber(1, 1.6),
				Theme.Colors.Leaf:Lerp(hex("#FFB7D5"), if k % 2 == 0 then 0 else 0.6)
			)
		end
		task.wait()
	end
	-- Outer forest ring + hills so the world feels enclosed.
	for k = 0, 35 do
		local ang = k * 10 + rng:NextNumber(-3, 3)
		Build.Tree(
			f,
			polar(ang, rng:NextNumber(270, 300)),
			rng:NextNumber(1.6, 2.4),
			Theme.Colors.Leaf:Lerp(hex("#2F8F4E"), rng:NextNumber())
		)
		if k % 2 == 0 then
			local hill = Build.Blob(
				f,
				V(rng:NextNumber(60, 90), rng:NextNumber(25, 45), rng:NextNumber(50, 70)),
				C(polar(ang + 5, 340)),
				Theme.Colors.GrassDark,
				M.Grass
			)
			hill.CastShadow = false
		end
		if k % 6 == 0 then
			task.wait()
		end
	end
	for k = 0, 7 do
		cloud(f, polar(k * 45 + rng:NextNumber(-15, 15), rng:NextNumber(150, 320), rng:NextNumber(110, 150)), rng)
	end
end

return Scenery
