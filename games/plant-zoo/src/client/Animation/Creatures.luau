--!strict
-- Per-creature procedural animation. A creature = any Model with PrimaryPart "Root" (anchored, feet)
-- and a Weld "Bob" (Root -> Body); every visible part is welded to Body (CreatureModels contract).
-- We only ever write: Bob.C0 (bob, wander offset, yaw, tilt), MeshPart.Size (squash & stretch, mesh
-- creatures near the camera) and Model:ScaleTo (pop moments). The server Hitbox never moves; wander
-- stays inside Tuning.Wander (< 1.2 studs) so taps still land.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Tuning = require(script.Parent.Tuning)
local Moments = require(script.Parent.Moments)

local Creatures = {}

export type Creature = {
	model: Model,
	root: BasePart,
	bob: Weld,
	base: CFrame,
	grown: boolean,
	reserve: boolean,
	thriving: boolean,
	phase: number,
	speed: number,
	hover: number,
	mesh: { BasePart },
	meshSize: { Vector3 },
	centerY: number,
	meshDirty: boolean,
	sized: boolean,
	ox: number,
	oz: number,
	tx: number,
	tz: number,
	yaw: number,
	nextWander: number,
	nextAction: number,
	action: string?,
	actionT0: number,
	uni: number,
	active: boolean,
	dist: number,
}

local rng = Random.new()
local list: { Creature } = {}
local byModel: { [Model]: Creature } = {}
local pose: Moments.Pose = { dy = 0, yaw = 0, tiltX = 0, tiltZ = 0, sxz = 1, sy = 1, uni = 1 }
local lastCull = 0

local function range(t: { number }): number
	return rng:NextNumber(t[1], t[2])
end

local function collectMesh(c: Creature)
	table.clear(c.mesh)
	table.clear(c.meshSize)
	local body = c.bob.Part1
	local best, bestVol = nil :: BasePart?, 0
	for _, d in c.model:GetDescendants() do
		if d:IsA("MeshPart") and d.Transparency < 1 then
			table.insert(c.mesh, d)
			table.insert(c.meshSize, d.Size)
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > bestVol then
				best, bestVol = d, v
			end
		end
	end
	c.centerY = if best and body then body.CFrame:ToObjectSpace(best.CFrame).Y else 0
	c.meshDirty = false
end

local function resetSizes(c: Creature)
	if c.sized then
		for i, p in c.mesh do
			if p.Parent then
				p.Size = c.meshSize[i]
			end
		end
		c.sized = false
	end
end

local function setUni(c: Creature, s: number)
	if math.abs(s - c.uni) < 0.004 then
		return
	end
	resetSizes(c)
	pcall(function()
		c.model:ScaleTo(s)
	end)
	c.uni = s
end

local function rest(c: Creature)
	setUni(c, 1)
	resetSizes(c)
	c.bob.C0 = c.base
	c.active = false
end

function Creatures.Get(model: Model): Creature?
	return byModel[model]
end

function Creatures.Play(c: Creature, name: string)
	if Moments.Duration[name] then
		c.action = name
		c.actionT0 = os.clock()
		if c.meshDirty then
			resetSizes(c)
			collectMesh(c)
		end
	end
end

function Creatures.SetThriving(c: Creature, on: boolean)
	c.thriving = on
end

function Creatures.Add(model: Model, reserve: boolean): Creature?
	if byModel[model] then
		return byModel[model]
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root") :: BasePart?
	local bob = root and root:FindFirstChild("Bob")
	if not root or not bob or not bob:IsA("Weld") then
		return nil
	end
	local kind = model:GetAttribute("Kind")
	local grown = model:GetAttribute("Stage") == "Grown"
	local now = os.clock()
	local c: Creature = {
		model = model,
		root = root,
		bob = bob,
		base = bob.C0,
		grown = grown,
		reserve = reserve,
		thriving = false,
		phase = rng:NextNumber(0, math.pi * 2),
		speed = Tuning.BobSpeed * rng:NextNumber(0.8, 1.2),
		hover = Tuning.BobHeight * (if kind == "fish" or kind == "bird" then 2 else 1),
		mesh = {},
		meshSize = {},
		centerY = 0,
		meshDirty = false,
		sized = false,
		ox = 0,
		oz = 0,
		tx = 0,
		tz = 0,
		yaw = 0,
		nextWander = now + range(Tuning.WanderEvery),
		nextAction = now + range(Tuning.ActionEvery),
		action = nil,
		actionT0 = 0,
		uni = 1,
		active = false,
		dist = math.huge,
	}
	if model:GetAttribute("Mesh") then
		collectMesh(c)
		model.DescendantAdded:Connect(function(d)
			if d:IsA("MeshPart") then
				c.meshDirty = true
			end
		end)
	end
	byModel[model] = c
	table.insert(list, c)
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil and byModel[model] == c then
			byModel[model] = nil
			local i = table.find(list, c)
			if i then
				table.remove(list, i)
			end
		end
	end)
	lastCull = 0 -- re-cull next frame so new creatures start right away
	return c
end

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function animate(c: Creature, now: number, dt: number, night: boolean, hrp: BasePart?, squash: boolean)
	local speedMul = if night then Tuning.NightSpeed elseif c.thriving then Tuning.ThrivingSpeed else 1
	local phase = now * c.speed * speedMul + c.phase
	local y, sxz, sy, tiltX, tiltZ = 0, 1, 1, 0, 0
	local yawTarget = 0
	if c.grown then
		y = c.hover * (0.5 + 0.5 * math.sin(phase))
		local b = math.sin(phase * 2) * Tuning.Breathe
		sy, sxz = 1 + b, 1 - b * 0.5
		tiltX = if night then Tuning.NightDroop else 0
		-- wander
		if now >= c.nextWander then
			c.nextWander = now + range(Tuning.WanderEvery) * (if night then 2 else 1)
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, Tuning.Wander)
			c.tx, c.tz = math.cos(a) * r, math.sin(a) * r
		end
		local dx, dz = c.tx - c.ox, c.tz - c.oz
		local d = math.sqrt(dx * dx + dz * dz)
		if d > 0.05 then
			local step = math.min(d, Tuning.WanderSpeed * dt * speedMul)
			c.ox += dx / d * step
			c.oz += dz / d * step
			local lv = c.root.CFrame:VectorToObjectSpace(Vector3.new(dx, 0, dz))
			yawTarget = math.atan2(-lv.X, -lv.Z)
		end
		-- face the local player when close
		if hrp then
			local off = hrp.Position - c.root.Position
			if off.Magnitude < Tuning.FaceRadius then
				local lv = c.root.CFrame:VectorToObjectSpace(off)
				yawTarget = math.atan2(-lv.X, -lv.Z)
			end
		end
		-- idle actions
		if not c.action and now >= c.nextAction then
			local mul = if night then Tuning.NightActionMul elseif c.thriving then Tuning.ThrivingActionMul else 1
			c.nextAction = now + range(Tuning.ActionEvery) * mul
			local roll = rng:NextNumber()
			c.action = if c.thriving and roll < 0.5
				then "HappyHops"
				elseif roll < 0.4 then "Hop"
				elseif roll < 0.6 then "Wiggle"
				elseif roll < 0.8 then "Look"
				else "Spin"
			c.actionT0 = now
		end
	else
		-- growing plant: gentle sway
		tiltZ = 0.05 * math.sin(phase * 0.7)
		tiltX = 0.03 * math.sin(phase * 0.5)
	end
	c.yaw += wrap(yawTarget - c.yaw) * math.min(1, dt * Tuning.TurnSpeed)

	local uni, actYaw = 1, 0
	local act = c.action
	if act then
		local p = (now - c.actionT0) / (Moments.Duration[act] or 1)
		if p >= 1 then
			c.action = nil
		else
			Moments.Eval(act, p, pose)
			y += pose.dy
			sxz *= pose.sxz
			sy *= pose.sy
			tiltX += pose.tiltX
			tiltZ += pose.tiltZ
			uni = pose.uni
			actYaw = pose.yaw
		end
	end
	setUni(c, uni)
	local yaw = c.yaw + actYaw

	-- squash & stretch (mesh creatures near the camera only)
	if squash and uni == 1 and #c.mesh > 0 then
		if c.meshDirty then
			resetSizes(c)
			collectMesh(c)
		end
		local scale = Vector3.new(sxz, sy, sxz)
		for i, p in c.mesh do
			p.Size = c.meshSize[i] * scale
		end
		c.sized = true
		y += (sy - 1) * c.centerY
	elseif c.sized then
		resetSizes(c)
	end
	c.bob.C0 = c.base * CFrame.new(c.ox, y, c.oz) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(tiltX, 0, tiltZ)
end

function Creatures.Step(now: number, dt: number, camPos: Vector3)
	if now - lastCull >= Tuning.CullInterval then
		lastCull = now
		for _, c in list do
			c.dist = if c.root.Parent then (c.root.Position - camPos).Magnitude else math.huge
		end
		table.sort(list, function(a, b)
			return a.dist < b.dist
		end)
		for i, c in list do
			local want = i <= Tuning.MaxActive and c.dist <= Tuning.ActiveRadius
			if c.active and not want then
				rest(c)
			end
			c.active = want
		end
	end
	local night = Lighting:GetAttribute("IsNight") == true
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local squashed = 0
	for _, c in list do
		if not c.active then
			break -- list is sorted by distance; actives come first
		end
		local squash = c.dist <= Tuning.NearRadius and squashed < Tuning.MaxSquash
		if squash and #c.mesh > 0 then
			squashed += 1
		end
		animate(c, now, dt, night, hrp, squash)
	end
end

return Creatures
