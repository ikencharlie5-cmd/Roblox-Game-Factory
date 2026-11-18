--!strict
-- Scenery props with asset hooks: each kind first tries a random variant from
-- ReplicatedStorage.Assets.Props (<Kind>, <Kind>1, <Kind>2, <Kind>_x ...), scaled to a target height with
-- its bounding-box bottom-center on the ground; if none exist it builds the primitive fallback.
-- Contract: notes/graphics.md "Asset hooks".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))
local Build = require(script.Parent.Build)

local V = Vector3.new
local C = CFrame.new
local hex = Color3.fromHex
local M = Enum.Material

local Props = {}

local function yaw(rng: Random): CFrame
	return CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
end

-- Places an asset variant of `kind` (nil if none). collide: keep CanCollide on the asset's parts.
function Props.Asset(
	parent: Instance,
	kind: string,
	feet: CFrame,
	height: number,
	rng: Random,
	collide: boolean?
): Model?
	local src = Theme.Assets.Pick("Props", kind, rng)
	if not src then
		return nil
	end
	local m, parts = Theme.Assets.Fit(src, { Height = height, Feet = feet })
	for _, p in parts do
		p.CanTouch = false
		if not collide then
			p.CanCollide = false
			p.CanQuery = false
		end
		if height < 3 then
			p.CastShadow = false
		end
	end
	m.Parent = parent
	return m
end

local function pick<T>(list: { T }, rng: Random): T
	return list[rng:NextInteger(1, #list)]
end

-- Tree ~10*scale studs tall. blossom = pink leaves (primitive fallback only).
function Props.Tree(parent: Instance, pos: Vector3, scale: number, rng: Random, blossom: boolean?)
	local h = 10 * scale * rng:NextNumber(0.9, 1.15)
	if Props.Asset(parent, "Tree", C(pos) * yaw(rng), h, rng, true) then
		return
	end
	local leaf = if blossom then Theme.Colors.Blossom else pick(Theme.LeafColors, rng)
	Build.Tree(parent, pos, scale, leaf)
end

-- Cluster of 3-5 trees: one big, two medium, one or two small (guide §6).
function Props.TreeCluster(parent: Instance, center: Vector3, scale: number, rng: Random, blossomChance: number?)
	local n = rng:NextInteger(3, 5)
	for i = 1, n do
		local s = scale * (if i == 1 then 1.3 elseif i <= 3 then 1 else 0.7) * rng:NextNumber(0.85, 1.15)
		local off = if i == 1 then V() else V(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)).Unit * (6 + 5 * s)
		Props.Tree(parent, center + off, s, rng, rng:NextNumber() < (blossomChance or 0))
	end
end

-- Bush ~3*scale studs; primitive = 3 overlapping balls (+ a few blossoms).
function Props.Bush(parent: Instance, pos: Vector3, scale: number, rng: Random)
	if Props.Asset(parent, "Bush", C(pos) * yaw(rng), 3 * scale, rng) then
		return
	end
	local col = pick(Theme.LeafColors, rng)
	for k = 0, 2 do
		local a = k * 2.1 + rng:NextNumber()
		local d = (if k == 0 then 3.4 else 2.6) * scale
		local b = Build.Ball(parent, d, C(pos + V(math.cos(a) * 0.9 * scale, d * 0.38, math.sin(a) * 0.9 * scale)), col)
		b.CanQuery = false
		col = col:Lerp(hex("#2F8F3E"), 0.12)
	end
	if rng:NextNumber() < 0.6 then
		local fc = pick(Theme.FlowerColors, rng)
		for k = 0, 2 do
			local a = k * 2.3
			local fl = Build.Ball(parent, 0.5, C(pos + V(math.cos(a) * scale, 2.6 * scale, math.sin(a) * scale)), fc)
			fl.CastShadow = false
			fl.CanQuery = false
		end
	end
end

function Props.Flower(parent: Instance, pos: Vector3, rng: Random, color: Color3?)
	if Props.Asset(parent, "Flower", C(pos) * yaw(rng), rng:NextNumber(1.2, 1.8), rng) then
		return
	end
	Build.Flower(parent, pos, color or pick(Theme.FlowerColors, rng))
end

-- Flower strip from a to b: a flower every `step` studs, cycling 3 colours.
function Props.FlowerStrip(parent: Instance, a: Vector3, b: Vector3, step: number, rng: Random)
	local len = (b - a).Magnitude
	local n = math.max(1, math.floor(len / step))
	local cols = { pick(Theme.FlowerColors, rng), pick(Theme.FlowerColors, rng), pick(Theme.FlowerColors, rng) }
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		Props.Flower(parent, p + V(rng:NextNumber(-0.4, 0.4), 0, rng:NextNumber(-0.4, 0.4)), rng, cols[i % 3 + 1])
	end
end

function Props.Rock(parent: Instance, pos: Vector3, size: number, rng: Random)
	if Props.Asset(parent, "Rock", C(pos) * yaw(rng), size, rng, true) then
		return
	end
	local col = Theme.Colors.Rock:Lerp(hex("#B8C0CF"), rng:NextNumber())
	local r = Build.Blob(parent, V(size * 1.5, size, size * 1.2), C(pos + V(0, size * 0.3, 0)) * yaw(rng), col)
	r.CanCollide = true
	if size > 2 then
		Build.Blob(
			parent,
			V(size * 0.8, size * 0.6, size * 0.7),
			C(pos + V(size * 0.8, size * 0.15, 0.3)) * yaw(rng),
			col
		)
	end
end

function Props.Cloud(parent: Instance, pos: Vector3, rng: Random)
	local m = Props.Asset(parent, "Cloud", C(pos) * yaw(rng), rng:NextNumber(14, 22), rng)
	if m then
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				p.CastShadow = false
			end
		end
		return
	end
	for k = 0, 4 do
		local s = rng:NextNumber(12, 20) * (if k == 2 then 1.3 else 1)
		local b = Build.Ball(
			parent,
			s,
			C(pos + V((k - 2) * s * 0.55, rng:NextNumber(-2, 3), rng:NextNumber(-4, 4))),
			hex("#FFFDF8")
		)
		b.CastShadow = false
		b.CanQuery = false
	end
end

-- Lamp post ~9 studs. The lantern (asset part named "Lantern"/"Light", else the highest part) gets a
-- PointLight + the NightLight tag (Sky turns it on at night).
function Props.Lamp(parent: Instance, pos: Vector3, rng: Random)
	local m = Props.Asset(parent, "Lamp", C(pos) * yaw(rng), 9, rng, true)
	local lantern: BasePart
	if m then
		local found = m:FindFirstChild("Lantern", true) or m:FindFirstChild("Light", true)
		if found and found:IsA("BasePart") then
			lantern = found
		else
			local best: BasePart? = nil
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and (not best or p.Position.Y > best.Position.Y) then
					best = p
				end
			end
			lantern = best :: BasePart
		end
	else
		Build.Cyl(parent, 7, 0.5, C(pos + V(0, 3.5, 0)), Theme.Colors.WoodDark, M.SmoothPlastic, true)
		Build.Deco(parent, { Size = V(2, 0.4, 2), CFrame = C(pos + V(0, 0.2, 0)), Color = Theme.Colors.WoodDark })
		lantern = Build.Deco(
			parent,
			{ Size = V(1.3, 1.5, 1.3), CFrame = C(pos + V(0, 7.7, 0)), Color = hex("#FFF2B3"), Name = "Lantern" }
		)
		lantern:SetAttribute("GlowAtNight", true)
		Build.Wedge(parent, V(1.8, 0.6, 0.9), C(pos + V(0, 8.75, -0.45)), Theme.Colors.WoodDark)
		Build.Wedge(
			parent,
			V(1.8, 0.6, 0.9),
			C(pos + V(0, 8.75, 0.45)) * CFrame.Angles(0, math.pi, 0),
			Theme.Colors.WoodDark
		)
	end
	if not lantern then
		return
	end
	local l = Instance.new("PointLight")
	l.Color = hex("#FFD58A")
	l.Range = 18
	l.Brightness = 1.4
	l.Enabled = false
	l.Parent = lantern
	Build.Tag(lantern, "NightLight")
end

-- Bench ~3 studs, facing -Z of cf.
function Props.Bench(parent: Instance, cf: CFrame, rng: Random)
	if Props.Asset(parent, "Bench", cf, 3, rng, true) then
		return
	end
	local wood, dark = Theme.Colors.Wood, Theme.Colors.WoodDark
	Build.Part(parent, { Size = V(5, 0.4, 1.6), CFrame = cf * C(0, 1.4, 0), Color = wood, Name = "Seat" })
	Build.Part(parent, { Size = V(5, 1.2, 0.3), CFrame = cf * C(0, 2.4, 0.75), Color = wood, Name = "Back" })
	for _, x in { -2.1, 2.1 } do
		Build.Deco(parent, { Size = V(0.4, 1.2, 1.4), CFrame = cf * C(x, 0.6, 0), Color = dark })
	end
end

-- Fence run from a to b (asset only; long axis = X). Returns false if there's no Fence asset.
function Props.FenceRun(parent: Instance, a: Vector3, b: Vector3, height: number, rng: Random): boolean
	local src = Theme.Assets.Pick("Props", "Fence", rng)
	if not src then
		return false
	end
	local dir = b - a
	local len = dir.Magnitude
	local frame = CFrame.lookAt(a, b) * CFrame.Angles(0, math.rad(90), 0) -- X axis along a->b
	local first = Props.Asset(parent, "Fence", frame, height, rng, true) :: Model
	local seg = math.max(first:GetExtentsSize().X, 1)
	local n = math.max(1, math.floor(len / seg + 0.5))
	for i = 0, n - 1 do
		local m = if i == 0 then first else first:Clone()
		m:PivotTo(CFrame.new(a:Lerp(b, (i + 0.5) / n)) * frame.Rotation)
		m.Parent = parent
	end
	return true
end

return Props
