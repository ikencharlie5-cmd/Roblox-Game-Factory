--!strict
-- Terrain ground, spoke paths hub -> plots, lamps, benches, clustered foliage, ponds, hills, clouds.
-- Scenery.Ground() runs synchronously in WorldService.Init (players need the floor); Scenery.Build() is async.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)
local Props = require(script.Parent.Props)
local Terrain = require(script.Parent.Terrain)

local V = Vector3.new
local C = CFrame.new
local M = Enum.Material

local Scenery = {}

Scenery.PathWidth = 14
Scenery.SpokeInner = 58
Scenery.SpokeOuter = 131
Scenery.PondAngles = { 90, 270 } -- between-spoke slots that get a terrain pond
Scenery.PondRadius = 100

local function polar(angleDeg: number, r: number, y: number?): Vector3
	local a = math.rad(angleDeg)
	return V(math.cos(a) * r, y or 0, math.sin(a) * r)
end

local function spokeCF(i: number): (CFrame, number)
	local len = Scenery.SpokeOuter - Scenery.SpokeInner
	local p = polar((i - 1) * 60, (Scenery.SpokeInner + Scenery.SpokeOuter) / 2, 0)
	return CFrame.lookAt(p, V(0, 0, 0)), len
end

-- Grass terrain + dirt under the hub, every plot and every spoke path (blades must not poke through parts).
function Scenery.Ground(plotCFs: { CFrame }, hubRadius: number)
	Terrain.Setup()
	Terrain.Ground()
	Terrain.PaintDisc(V(), hubRadius + 4, M.Ground)
	for i, cf in plotCFs do
		Terrain.Paint(cf - V(0, cf.Position.Y, 0), 92, 92, M.Ground)
		local scf, len = spokeCF(i)
		Terrain.Paint(scf, Scenery.PathWidth + 6, len + 4, M.Ground)
	end
end

local function spoke(f: Instance, i: number, rng: Random)
	local cf, len = spokeCF(i)
	local w = Scenery.PathWidth
	Build.Part(f, {
		Size = V(w, 0.5, len),
		CFrame = cf,
		Color = Theme.Colors.Path,
		Name = "Spoke",
	})
	for _, side in { -1, 1 } do
		Build.Part(f, {
			Size = V(1, 0.6, len),
			CFrame = cf * C(side * (w / 2 + 0.5), 0.05, 0),
			Color = Theme.Colors.PathEdge,
			Name = "Edge",
		})
		for _, z in { -22, 22 } do
			Props.Lamp(f, (cf * C(side * (w / 2 + 2.5), 0, z)).Position, rng)
		end
		-- Flower strips along both edges (skip the lamp spots).
		for _, seg in { { -len / 2 + 3, -25 }, { -19, 19 }, { 25, len / 2 - 3 } } do
			local a = (cf * C(side * (w / 2 + 2), 0, seg[1])).Position
			local b = (cf * C(side * (w / 2 + 2), 0, seg[2])).Position
			Props.FlowerStrip(f, a, b, 3.5, rng)
		end
	end
	Props.Bench(f, cf * C(-(w / 2 + 4.5), 0, 0) * CFrame.Angles(0, math.rad(-90), 0), rng)
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

local function pond(f: Instance, center: Vector3, radius: number, rng: Random)
	Terrain.Pond(center, radius)
	for k = 0, 6 do
		local a = k * (360 / 7) + rng:NextNumber(-12, 12)
		Props.Rock(f, center + polar(a, radius + 3.5), rng:NextNumber(1.5, 3.2), rng)
	end
	for k = 0, 3 do
		local lily = Build.Blob(
			f,
			V(2.4, 0.15, 2.4),
			C(center + polar(k * 90 + rng:NextNumber(0, 40), rng:NextNumber(3, radius - 3), 0.1)),
			Theme.Colors.LeafLight
		)
		lily.CastShadow = false
		if k % 2 == 0 then
			Build.Ball(f, 0.7, lily.CFrame * C(0.4, 0.3, 0), Theme.Colors.Blossom).CastShadow = false
		end
	end
	Props.Bush(f, center + polar(rng:NextNumber(0, 360), radius + 7), 1.1, rng)
	Props.Bush(f, center + polar(rng:NextNumber(0, 360), radius + 7), 0.9, rng)
end

-- Meadow patch: bushes + loose flowers between two spokes.
local function meadow(f: Instance, mid: number, rng: Random)
	for _ = 1, 3 do
		Props.Bush(f, polar(mid + rng:NextNumber(-12, 12), rng:NextNumber(72, 118)), rng:NextNumber(0.8, 1.3), rng)
	end
	for _ = 1, 2 do
		local c = polar(mid + rng:NextNumber(-10, 10), rng:NextNumber(80, 110))
		for _ = 1, 7 do
			Props.Flower(f, c + V(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)), rng)
		end
	end
end

function Scenery.Build(parent: Instance, plotCount: number, plotRadius: number)
	local f = Build.Folder(parent, "Scenery")
	local rng = Random.new(20261117)
	for i = 1, plotCount do
		spoke(f, i, rng)
		fireflyZone(f, polar((i - 1) * 60, plotRadius), 70)
		task.wait()
	end
	fireflyZone(f, V(0, 0, 0), 100)
	-- Between spokes: a pond or a meadow near the hub, tree clusters further out, bushes ringing the hub.
	for i = 1, plotCount do
		local mid = (i - 1) * 60 + 30
		if table.find(Scenery.PondAngles, mid) then
			pond(f, polar(mid, Scenery.PondRadius), 11, rng)
		else
			meadow(f, mid, rng)
		end
		for _, d in { -14, 14 } do
			Props.Bush(f, polar(mid + d, 66), 1.1, rng)
		end
		Props.TreeCluster(f, polar(mid + rng:NextNumber(-4, 4), 158), 1.1, rng, 0.35)
		Props.TreeCluster(f, polar(mid + rng:NextNumber(-6, 6), 228), 1.3, rng, 0.2)
		task.wait()
	end
	-- Outer forest ring + rocks, then terrain hills (with trees on top) so there's no visible map edge.
	for k = 0, 23 do
		local ang = k * 15 + rng:NextNumber(-4, 4)
		Props.TreeCluster(f, polar(ang, rng:NextNumber(268, 300)), rng:NextNumber(1.4, 1.9), rng, 0.15)
		if k % 3 == 0 then
			Props.Rock(f, polar(ang + 7, rng:NextNumber(250, 262)), rng:NextNumber(2, 4), rng)
		end
		if k % 4 == 0 then
			task.wait()
		end
	end
	local tops = Terrain.Hills(rng, 330, 20)
	for k, top in tops do
		if k % 2 == 0 then
			Props.Tree(f, top, rng:NextNumber(1.8, 2.4), rng, rng:NextNumber() < 0.2)
		end
	end
	for k = 0, 9 do
		Props.Cloud(f, polar(k * 36 + rng:NextNumber(-12, 12), rng:NextNumber(160, 360), rng:NextNumber(110, 160)), rng)
	end
end

return Scenery
