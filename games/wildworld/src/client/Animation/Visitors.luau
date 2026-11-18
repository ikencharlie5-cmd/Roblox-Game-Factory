--!strict
-- Client-only park visitors: simple 6-part figures walking a square loop just outside each owned
-- plot's buildable Land square (so they never cross a habitat), stopping to look in and emote.
-- No network. Plot = the Base part tagged "Plot" (pivot = floor-top centre; a Plot Model is mapped to its
-- tagged PrimaryPart). Attributes read from it:
--   OwnerId / OwnerUserId (non-zero = owned), LandSize / Land (buildable side, studs),
--   Visitors (optional count), Tips (counter: +1 -> coin fountain from a visitor), TipAmount ("+N").
local CollectionService = game:GetService("CollectionService")
local Batch = require(script.Parent.Batch)
local Fx = require(script.Parent.Fx)
local Tuning = require(script.Parent.Tuning)

local Visitors = {}

type Visitor = {
	model: Model,
	parts: { BasePart },
	rest: { CFrame },
	pos: Vector3,
	yaw: number,
	wp: number,
	dir: number,
	waitUntil: number,
	phase: number,
	speed: number,
}

type Plot = {
	model: PVInstance,
	center: Vector3,
	points: { Vector3 },
	visitors: { Visitor },
	shown: boolean,
	tips: number,
}

local plots: { [PVInstance]: Plot } = {}
local folder: Folder
local rng = Random.new()
local SHIRTS = { "#FF8A65", "#4FC3F7", "#FFD54F", "#81C784", "#BA68C8", "#F06292", "#4DB6AC" }
local SKINS = { "#F1C27D", "#E0AC69", "#C68642", "#8D5524", "#FFDBAC" }
local PANTS = { "#37474F", "#5D4037", "#3949AB", "#00695C" }
-- name, size, rest offset (from feet), colour group, ball
local BODY = {
	{ "LegL", Vector3.new(0.8, 1.6, 0.8), CFrame.new(-0.45, 0.8, 0), 3 },
	{ "LegR", Vector3.new(0.8, 1.6, 0.8), CFrame.new(0.45, 0.8, 0), 3 },
	{ "Torso", Vector3.new(1.8, 1.8, 1), CFrame.new(0, 2.5, 0), 1 },
	{ "Head", Vector3.new(1.5, 1.5, 1.5), CFrame.new(0, 4.1, 0), 2 },
	{ "ArmL", Vector3.new(0.6, 1.6, 0.6), CFrame.new(-1.25, 2.55, 0), 2 },
	{ "ArmR", Vector3.new(0.6, 1.6, 0.6), CFrame.new(1.25, 2.55, 0), 2 },
}
local HIP_L, HIP_R = Vector3.new(-0.45, 1.6, 0), Vector3.new(0.45, 1.6, 0)
local SH_L, SH_R = Vector3.new(-1.25, 3.3, 0), Vector3.new(1.25, 3.3, 0)

local function pick(t: { string }): Color3
	return Color3.fromHex(t[rng:NextInteger(1, #t)])
end

local function newVisitor(plot: Plot): Visitor
	local m = Instance.new("Model")
	m.Name = "Visitor"
	local cols = { pick(SHIRTS), pick(SKINS), pick(PANTS) }
	local parts, rest = {}, {}
	for i, def in BODY do
		local p = Instance.new("Part")
		p.Name = def[1] :: string
		p.Size = def[2] :: Vector3
		p.Color = cols[def[4] :: number]
		p.Material = Enum.Material.SmoothPlastic
		p.Shape = if p.Name == "Head" then Enum.PartType.Ball else Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = i == 3
		p.Parent = m
		parts[i], rest[i] = p, def[3] :: CFrame
	end
	m.Parent = folder
	local wp = rng:NextInteger(1, #plot.points)
	return {
		model = m,
		parts = parts,
		rest = rest,
		pos = plot.points[wp],
		yaw = 0,
		wp = wp,
		dir = if rng:NextNumber() < 0.5 then 1 else -1,
		waitUntil = 0,
		phase = rng:NextNumber(0, 6),
		speed = Tuning.VisitorSpeed * rng:NextNumber(0.8, 1.15),
	}
end

local function wanted(m: PVInstance): number
	local owner = m:GetAttribute("OwnerId") or m:GetAttribute("OwnerUserId") or m:GetAttribute("Owner")
	local owned = (typeof(owner) == "number" and owner ~= 0) or (typeof(owner) == "string" and owner ~= "")
	if not owned then
		return 0
	end
	local v = m:GetAttribute("Visitors")
	local n = if typeof(v) == "number" then v else Tuning.DefaultVisitors
	return math.clamp(math.floor(n), 0, Tuning.MaxVisitorsPerPlot)
end

local function layout(plot: Plot)
	local m = plot.model
	local pivot = m:GetPivot()
	local land = m:GetAttribute("LandSize") or m:GetAttribute("Land")
	local half = math.clamp((if typeof(land) == "number" then land else 64) * 0.5 + 4, 20, 60)
	plot.center = pivot.Position
	table.clear(plot.points)
	for i = 0, 15 do
		local t = i / 16 * 4
		local side, f = math.floor(t), t - math.floor(t)
		local x = if side == 0 then -half + 2 * half * f elseif side == 1 then half elseif side == 2 then half - 2 * half * f else -half
		local z = if side == 0 then -half elseif side == 1 then -half + 2 * half * f elseif side == 2 then half else half - 2 * half * f
		table.insert(plot.points, pivot * Vector3.new(x, 0, z))
	end
end

local function sync(plot: Plot)
	local n = wanted(plot.model)
	while #plot.visitors > n do
		local v = table.remove(plot.visitors) :: Visitor
		v.model:Destroy()
	end
	if n > 0 and #plot.points == 0 then
		layout(plot)
	end
	while #plot.visitors < n do
		table.insert(plot.visitors, newVisitor(plot))
	end
end

local function addPlot(child: Instance)
	-- The tag (and OwnerId/LandSize/Tips/TipAmount) lives on the Base part; folder children are Models.
	if child:IsA("Model") and child.PrimaryPart and CollectionService:HasTag(child.PrimaryPart, "Plot") then
		child = child.PrimaryPart
	end
	if not (child:IsA("BasePart") or child:IsA("Model")) or plots[child :: PVInstance] then
		return
	end
	local inst = child :: PVInstance
	local plot: Plot = { model = inst, center = inst:GetPivot().Position, points = {}, visitors = {}, shown = true, tips = 0 }
	local t = inst:GetAttribute("Tips")
	plot.tips = if typeof(t) == "number" then t else 0
	plots[inst] = plot
	for _, a in { "OwnerId", "OwnerUserId", "Owner", "Visitors" } do
		inst:GetAttributeChangedSignal(a):Connect(function()
			sync(plot)
		end)
	end
	inst:GetAttributeChangedSignal("Tips"):Connect(function()
		local v = inst:GetAttribute("Tips")
		local n = if typeof(v) == "number" then v else 0
		if n > plot.tips then
			Visitors.Tip(inst)
		end
		plot.tips = n
	end)
	for _, a in { "LandSize", "Land" } do
		inst:GetAttributeChangedSignal(a):Connect(function()
			layout(plot)
			for _, v in plot.visitors do
				v.pos = plot.points[v.wp] -- hop onto the new loop
			end
		end)
	end
	sync(plot)
end

-- Coin fountain from one of this plot's visitors (or the plot centre).
function Visitors.Tip(plotModel: PVInstance)
	local plot = plots[plotModel]
	if not plot then
		return
	end
	local pos = plot.center
	if #plot.visitors > 0 then
		local v = plot.visitors[rng:NextInteger(1, #plot.visitors)]
		pos = v.pos
		v.waitUntil = os.clock() + 1.5
	end
	Fx.Coins(pos + Vector3.new(0, 3, 0), 8, nil)
	local amt = plotModel:GetAttribute("TipAmount")
	if typeof(amt) == "number" then
		Fx.Float("+" .. tostring(math.floor(amt)), pos + Vector3.new(0, 5.5, 0), Color3.fromRGB(255, 214, 64), 2)
	end
end

function Visitors.Start()
	folder = Instance.new("Folder")
	folder.Name = "ClientVisitors"
	folder.Parent = workspace
	for _, p in CollectionService:GetTagged("Plot") do
		addPlot(p)
	end
	CollectionService:GetInstanceAddedSignal("Plot"):Connect(addPlot)
	local function watch(f: Instance)
		for _, p in f:GetChildren() do
			addPlot(p)
		end
		f.ChildAdded:Connect(addPlot)
	end
	local world = workspace:FindFirstChild("World")
	local pf = (world and world:FindFirstChild("Plots")) or workspace:FindFirstChild("Plots")
	if pf then
		watch(pf)
	end
end

local function around(p: Vector3, a: number): CFrame
	return CFrame.new(p) * CFrame.Angles(a, 0, 0) * CFrame.new(-p)
end

local function stepVisitor(plot: Plot, v: Visitor, now: number, dt: number)
	local moving = 0
	if now >= v.waitUntil then
		local target = plot.points[v.wp]
		local d = Vector3.new(target.X - v.pos.X, 0, target.Z - v.pos.Z)
		if d.Magnitude < 0.5 then
			v.wp = (v.wp + v.dir - 1) % #plot.points + 1
			if rng:NextNumber() < 0.4 then
				v.waitUntil = now + rng:NextNumber(2, 4)
				local look = plot.center - v.pos
				v.yaw = math.atan2(-look.X, -look.Z)
				if rng:NextNumber() < 0.35 then
					local e = Tuning.VisitorEmotes
					Fx.Float(e[rng:NextInteger(1, #e)], v.pos + Vector3.new(0, 5.5, 0), Color3.fromRGB(255, 255, 255), 1.6)
				end
			end
		else
			local step = math.min(d.Magnitude, v.speed * dt)
			v.pos += d.Unit * step + Vector3.new(0, (target.Y - v.pos.Y) * math.min(1, dt * 5), 0)
			v.yaw = math.atan2(-d.X, -d.Z)
			moving = 1
		end
	end
	v.phase += dt * 8 * moving
	local swing = 0.6 * math.sin(v.phase) * moving
	local root = CFrame.new(v.pos + Vector3.new(0, 0.12 * math.abs(math.sin(v.phase)) * moving, 0))
		* CFrame.Angles(0, v.yaw, 0)
	local idle = 0.03 * math.sin(now * 2 + v.phase)
	local r = v.rest
	local parts = v.parts
	Batch.Add(parts[1], root * around(HIP_L, swing) * r[1])
	Batch.Add(parts[2], root * around(HIP_R, -swing) * r[2])
	Batch.Add(parts[3], root * CFrame.new(0, idle, 0) * r[3])
	Batch.Add(parts[4], root * CFrame.new(0, idle, 0) * r[4])
	Batch.Add(parts[5], root * around(SH_L, -swing * 0.8) * r[5])
	Batch.Add(parts[6], root * around(SH_R, swing * 0.8) * r[6])
end

function Visitors.Step(now: number, dt: number, camPos: Vector3)
	for _, plot in plots do
		if #plot.visitors == 0 then
			continue
		end
		local near = (plot.center - camPos).Magnitude <= Tuning.VisitorRadius
		if near ~= plot.shown then
			plot.shown = near
			for _, v in plot.visitors do
				v.model.Parent = if near then folder else nil
			end
		end
		if near then
			for _, v in plot.visitors do
				stepVisitor(plot, v, now, dt)
			end
		end
	end
end

return Visitors
