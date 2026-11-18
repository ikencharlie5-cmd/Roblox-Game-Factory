--!strict
-- Egg wobble that speeds up near hatch, a little hop when ready, crack + shell burst on hatch.
-- Egg = Model or Part tagged "Egg", or a Model with IsEgg / EggId / HatchAt, or a Model named "Egg".
-- Attributes read: HatchAt or ReadyAt (server unix time, compared with workspace:GetServerTimeNow()),
--   Duration (s, total incubation), Ready / Starter (bool: full "ready" wobble + hops),
--   Moment = "Hatch" (crack now), OwnerId (our own egg disappearing = it hatched -> shell burst).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Batch = require(script.Parent.Batch)
local Creatures = require(script.Parent.Creatures)
local Fx = require(script.Parent.Fx)
local Sfx = require(script.Parent.Sfx)
local Tuning = require(script.Parent.Tuning)

local Eggs = {}

type Egg = {
	inst: Instance,
	parts: { BasePart },
	rest: { CFrame },
	base: CFrame,
	height: number,
	color: Color3,
	nextBurst: number,
	burstT0: number,
	axis: number,
	crackT0: number?,
	hatched: boolean,
	moved: boolean,
}

local eggs: { [Instance]: Egg } = {}
local rng = Random.new()
local PI = math.pi

local function progress(e: Egg): number
	local inst = e.inst
	if inst:GetAttribute("Ready") == true or inst:GetAttribute("Starter") == true then
		return 1
	end
	local at = inst:GetAttribute("HatchAt") or inst:GetAttribute("ReadyAt")
	if typeof(at) ~= "number" then
		return 0.3
	end
	local dur = inst:GetAttribute("Duration")
	local total = if typeof(dur) == "number" and dur > 0 then dur else 120
	return 1 - math.clamp((at - workspace:GetServerTimeNow()) / total, 0, 1)
end

local function burst(e: Egg)
	if e.hatched then
		return
	end
	e.hatched = true
	local center = e.base * Vector3.new(0, e.height * 0.5, 0)
	Sfx.At("Egg_Crack", center)
	if Tuning.EggShellBurst then
		Fx.Shell(center, e.color, e.height * 0.8)
	end
	Fx.Burst("Sparkle", center, 20)
	Fx.Burst("Dust", e.base.Position, 8)
	Fx.Flash(center, Color3.fromRGB(255, 250, 230), 4, 0.5)
	Creatures.NoteHatch(e.base.Position)
	for _, p in e.parts do
		if p.Parent then
			p.LocalTransparencyModifier = 1
		end
	end
end

local function add(inst: Instance)
	if eggs[inst] or not (inst:IsA("Model") or inst:IsA("BasePart")) then
		return
	end
	local parts: { BasePart } = {}
	local cf: CFrame, size: Vector3
	if inst:IsA("Model") then
		cf, size = inst:GetBoundingBox()
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				table.insert(parts, d)
			end
		end
	else
		local bp = inst :: BasePart
		cf, size = bp.CFrame, bp.Size
		table.insert(parts, bp)
	end
	if #parts == 0 then
		return
	end
	local base = CFrame.new(cf.Position - Vector3.new(0, size.Y * 0.5, 0))
	local rest, color, vol = {}, parts[1].Color, 0
	for i, p in parts do
		rest[i] = base:ToObjectSpace(p.CFrame)
		local v = p.Size.X * p.Size.Y * p.Size.Z
		if v > vol then
			vol, color = v, p.Color
		end
	end
	local e: Egg = {
		inst = inst,
		parts = parts,
		rest = rest,
		base = base,
		height = size.Y,
		color = color,
		nextBurst = os.clock() + rng:NextNumber(0.5, 2),
		burstT0 = -10,
		axis = 0,
		crackT0 = nil,
		hatched = false,
		moved = false,
	}
	eggs[inst] = e
	inst:GetAttributeChangedSignal("Moment"):Connect(function()
		local m = inst:GetAttribute("Moment")
		if typeof(m) == "string" and string.sub(m, 1, 5) == "Hatch" and not e.crackT0 then
			e.crackT0 = os.clock()
		end
	end)
	inst.AncestryChanged:Connect(function(_, parent)
		if parent == nil and eggs[inst] == e then
			eggs[inst] = nil
			local cam = workspace.CurrentCamera
			local near = cam ~= nil and (cam.CFrame.Position - e.base.Position).Magnitude < Tuning.EggRadius
			local mine = inst:GetAttribute("OwnerId") == Players.LocalPlayer.UserId
			if near and not e.hatched and (e.crackT0 or mine or progress(e) >= 0.97) then
				burst(e)
			end
		end
	end)
end

local function consider(inst: Instance)
	if CollectionService:HasTag(inst, "Egg") then
		add(inst)
	elseif
		inst:IsA("Model")
		and (
			inst:GetAttribute("IsEgg") == true
			or inst:GetAttribute("HatchAt") ~= nil
			or inst:GetAttribute("EggId") ~= nil
			or inst.Name == "Egg"
		)
	then
		add(inst)
	end
end

function Eggs.Start()
	for _, i in CollectionService:GetTagged("Egg") do
		add(i)
	end
	CollectionService:GetInstanceAddedSignal("Egg"):Connect(add)
	for _, d in workspace:GetDescendants() do
		consider(d)
	end
	workspace.DescendantAdded:Connect(consider)
end

function Eggs.Step(now: number, camPos: Vector3)
	for _, e in eggs do
		if e.hatched then
			continue
		end
		local near = (e.base.Position - camPos).Magnitude <= Tuning.EggRadius
		if not near then
			if e.moved then
				e.moved = false
				for i, p in e.parts do
					Batch.Add(p, e.base * e.rest[i])
				end
			end
			continue
		end
		local p = progress(e)
		local angle, dy = 0, 0
		if e.crackT0 then
			local q = (now - e.crackT0) / 0.4
			if q >= 1 then
				burst(e)
				continue
			end
			angle = math.rad(16) * math.sin(q * 10 * PI)
			dy = 0.3 * math.sin(PI * q)
		else
			if now >= e.nextBurst then
				local lo, hi = Tuning.EggBurstEvery[1], Tuning.EggBurstEvery[2]
				e.nextBurst = now + (lo + (hi - lo) * p) * rng:NextNumber(0.8, 1.2)
				e.burstT0 = now
				e.axis = rng:NextInteger(0, 1)
				Sfx.At("Egg_Wobble", e.base.Position, 0.5)
			end
			local q = (now - e.burstT0) / 0.6
			if q < 1 then
				local amp = Tuning.EggAmp[1] + (Tuning.EggAmp[2] - Tuning.EggAmp[1]) * p
				local hz = Tuning.EggHz[1] + (Tuning.EggHz[2] - Tuning.EggHz[1]) * p
				angle = amp * math.sin(2 * PI * hz * (now - e.burstT0)) * math.sin(PI * q)
			end
			if p >= 1 then
				local h = (now % 1.6) / 0.35
				if h < 1 then
					dy = 0.45 * math.sin(PI * h)
				end
			end
		end
		e.moved = true
		local r = if e.axis == 0 then CFrame.Angles(angle, 0, 0) else CFrame.Angles(0, 0, angle)
		local f = e.base * CFrame.new(0, dy, 0) * r
		for i, part in e.parts do
			Batch.Add(part, f * e.rest[i])
		end
	end
end

return Eggs
