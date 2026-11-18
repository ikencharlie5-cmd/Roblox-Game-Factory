--!strict
-- Per-creature animation state + small helpers shared by CreaturePose / CreatureMoments / Creatures.
local Rig = require(script.Parent.Rig)
local Tuning = require(script.Parent.Tuning)

local CreatureState = {}

export type Creature = {
	model: Model,
	hitbox: BasePart,
	rig: Rig.Rig,
	species: { hop: boolean, speed: number, personality: string },
	persona: { every: number, actions: { string } },
	mutation: string?, -- strongest visible mutation name (for reveal colours / glow pulse)
	glowing: boolean,
	baby: boolean,
	scale: number,
	-- visual root (the client moves the Hitbox too: the server never moves parts, it only sets Goal)
	pos: Vector3,
	yaw: number,
	home: Vector3, -- model pivot at spawn (used when there is no Goal)
	spawnRoot: CFrame, -- server Hitbox frame at spawn (new parts are placed relative to this)
	hbOff: Vector3, -- Hitbox position minus model pivot
	speedNow: number,
	moveBlend: number,
	-- idle clocks
	phase: number,
	walkPhase: number,
	state: string,
	nextBlink: number,
	blinkUntil: number,
	eyesClosed: boolean,
	nextFlick: number,
	flickUntil: number,
	flickLeft: boolean,
	nextLook: number,
	headYaw: number,
	lookYaw: number,
	nextAction: number,
	nextZ: number,
	-- moments
	moment: string?,
	momentT0: number,
	momentDur: number,
	landed: boolean,
	sized: boolean,
	hidden: boolean,
	hiddenUntil: number,
	revealAt: number?,
	muted: { [Instance]: boolean },
	-- scheduling
	tier: number, -- 0 skip, 1 full, 2 mid, 3 far
	dist: number,
	lastUpdate: number,
	lastRoot: CFrame?,
	dirty: boolean,
	born: number,
}

local rng = Random.new()

function CreatureState.Range(t: { number }): number
	return rng:NextNumber(t[1], t[2])
end

function CreatureState.YawOf(cf: CFrame): number
	local l = cf.LookVector
	return math.atan2(-l.X, -l.Z)
end

-- Root frame used for rest offsets: Hitbox position + yaw only.
function CreatureState.HitboxFrame(hitbox: BasePart): CFrame
	local cf = hitbox.CFrame
	return CFrame.new(cf.Position) * CFrame.Angles(0, CreatureState.YawOf(cf), 0)
end

function CreatureState.ReadMutation(c: Creature)
	local raw = c.model:GetAttribute("Mutations") or c.model:GetAttribute("Mutation")
	local text = if typeof(raw) == "string" then raw else ""
	c.mutation = nil
	for _, name in { "Crystal", "Golden", "Albino", "Glowing" } do
		if string.find(text, name) then
			c.mutation = name
			break
		end
	end
	c.glowing = string.find(text, "Glowing") ~= nil or c.model:GetAttribute("Pulse") == true
	c.baby = c.model:GetAttribute("Stage") == "Baby"
end

function CreatureState.New(model: Model, hitbox: BasePart): Creature
	local now = os.clock()
	local speciesName = model:GetAttribute("Species")
	local species = Tuning.Species[if typeof(speciesName) == "string" then speciesName else ""] or Tuning.Species.Default
	local pname = model:GetAttribute("Personality")
	local persona = Tuning.Personality[if typeof(pname) == "string" then pname else species.personality]
		or Tuning.Personality.Curious
	local root = CreatureState.HitboxFrame(hitbox)
	local yaw = CreatureState.YawOf(root)
	local born = model:GetAttribute("Born")
	local c: Creature = {
		model = model,
		hitbox = hitbox,
		rig = Rig.Build(model, root, hitbox, nil),
		species = species,
		persona = persona,
		mutation = nil,
		glowing = false,
		baby = false,
		scale = model:GetScale(),
		pos = root.Position,
		yaw = yaw,
		home = model:GetPivot().Position,
		spawnRoot = root,
		hbOff = root.Position - model:GetPivot().Position,
		speedNow = 0,
		moveBlend = 0,
		phase = rng:NextNumber(0, 2 * math.pi),
		walkPhase = 0,
		state = "Idle",
		nextBlink = now + CreatureState.Range(Tuning.BlinkEvery),
		blinkUntil = 0,
		eyesClosed = false,
		nextFlick = now + CreatureState.Range(Tuning.EarFlickEvery),
		flickUntil = 0,
		flickLeft = true,
		nextLook = now + CreatureState.Range(Tuning.LookEvery),
		headYaw = 0,
		lookYaw = 0,
		nextAction = now + CreatureState.Range(Tuning.ActionEvery) * persona.every,
		nextZ = now,
		moment = nil,
		momentT0 = 0,
		momentDur = 1,
		landed = false,
		sized = false,
		hidden = false,
		hiddenUntil = 0,
		revealAt = nil,
		muted = {},
		tier = 0,
		dist = math.huge,
		lastUpdate = 0,
		lastRoot = nil,
		dirty = false,
		born = if typeof(born) == "number" then born else 0,
	}
	CreatureState.ReadMutation(c)
	return c
end

-- Rebuild the rig after parts were added (keeps rest offsets of parts we already move).
function CreatureState.Rebuild(c: Creature)
	-- we move the Hitbox locally, so use where the server put it, not where it is now
	c.rig = Rig.Build(c.model, c.spawnRoot, c.hitbox, c.rig.restOf)
	c.eyesClosed = false
	c.dirty = false
end

function CreatureState.SetEyes(c: Creature, closed: boolean)
	if closed == c.eyesClosed then
		return
	end
	c.eyesClosed = closed
	for _, e in c.rig.eyes do
		if not e.part.Parent then
			continue
		end
		if e.mesh then
			e.mesh.Scale = if closed then Vector3.new(e.scale.X, e.scale.Y * 0.1, e.scale.Z) else e.scale
		elseif e.ball then
			e.part.LocalTransparencyModifier = if closed then 1 else 0
		else
			e.part.Size = if closed then Vector3.new(e.size.X, e.size.Y * 0.1, e.size.Z) else e.size
		end
	end
	for _, s in c.rig.shines do
		s.LocalTransparencyModifier = if closed then 1 else 0
	end
end

function CreatureState.SetHidden(c: Creature, hidden: boolean)
	if hidden == c.hidden then
		return
	end
	c.hidden = hidden
	for _, p in c.rig.parts do
		p.LocalTransparencyModifier = if hidden then 1 else 0
	end
end

-- Real uniform scale (Size writes) for pop/hatch/capture moments only.
function CreatureState.SetSize(c: Creature, k: number)
	local rig = c.rig
	if k == 1 then
		if not c.sized then
			return
		end
		c.sized = false
	else
		c.sized = true
	end
	for i, p in rig.parts do
		p.Size = rig.sizes[i] * k
	end
end

-- Mutation VFX off/on (hatch reveal drama).
function CreatureState.MuteVfx(c: Creature, muted: boolean)
	if muted then
		for _, e in c.rig.emitters do
			if e.Enabled then
				c.muted[e] = true
				e.Enabled = false
			end
		end
		for _, l in c.rig.lights do
			local host = l.Parent
			if host and host:HasTag("NightLight") then
				continue -- Graphics owns day/night switching of these
			end
			if l.Enabled then
				c.muted[l] = true
				l.Enabled = false
			end
		end
	else
		for inst in c.muted do
			if inst:IsA("ParticleEmitter") or inst:IsA("Light") then
				(inst :: any).Enabled = true
			end
		end
		table.clear(c.muted)
	end
end

return CreatureState
