--!strict
-- Finds creature models, keeps them sorted by camera distance, picks a tier per creature and
-- updates them. A creature = a Model tagged "Creature" OR any Model with a `Species` attribute,
-- whose PrimaryPart (or child "Hitbox") is the server-owned Hitbox. The Hitbox is never moved.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local CreatureHooks = require(script.Parent.CreatureHooks)
local CreatureMoments = require(script.Parent.CreatureMoments)
local CreaturePose = require(script.Parent.CreaturePose)
local CreatureState = require(script.Parent.CreatureState)
local Rig = require(script.Parent.Rig)
local Tuning = require(script.Parent.Tuning)

type Creature = CreatureState.Creature

local Creatures = {}

local list: { Creature } = {}
local byModel: { [Model]: Creature } = {}
local pending: { [Model]: boolean } = {}
local startedAt = os.clock()
local lastCull = 0
local hatches: { { pos: Vector3, t: number } } = {}
local ctx: CreaturePose.Ctx = { night = false, players = {} }

local function hitboxOf(model: Model): BasePart?
	local hb = model:FindFirstChild("Hitbox")
	if hb and hb:IsA("BasePart") then
		return hb
	end
	return model.PrimaryPart
end

local function remove(model: Model)
	local c = byModel[model]
	pending[model] = nil
	if not c then
		return
	end
	byModel[model] = nil
	CreatureHooks.OnRemoved(c)
	local i = table.find(list, c)
	if i then
		table.remove(list, i)
	end
end

local function add(model: Model)
	if byModel[model] then
		return
	end
	local hb = hitboxOf(model)
	if not hb then
		pending[model] = true
		return
	end
	pending[model] = nil
	local c = CreatureState.New(model, hb)
	byModel[model] = c
	table.insert(list, c)
	lastCull = 0
	local now = os.clock()
	CreatureHooks.Connect(c)

	-- entrance moments (never for things already there when we joined / streamed in)
	if now - startedAt > Tuning.ArmDelay then
		local recentBorn = c.born > 0 and workspace:GetServerTimeNow() - c.born < Tuning.BornRecent
		local nearHatch = false
		for _, h in hatches do
			if now - h.t < Tuning.HatchLinkTime and (h.pos - c.pos).Magnitude < Tuning.HatchLink then
				nearHatch = true
			end
		end
		if recentBorn or nearHatch then
			CreatureMoments.Play(c, "Hatch", now)
		end
	end
end

local function isEgg(m: Model): boolean
	return CollectionService:HasTag(m, "Egg")
		or m:GetAttribute("IsEgg") == true
		or m:GetAttribute("HatchAt") ~= nil
		or m:GetAttribute("EggId") ~= nil
		or m.Name == "Egg"
end

local function consider(inst: Instance)
	if
		inst:IsA("Model")
		and (
			CollectionService:HasTag(inst, "Creature")
			or CollectionService:HasTag(inst, "WildCreature")
			or inst:GetAttribute("Species") ~= nil
		)
	then
		if inst:GetAttribute("NoAnim") or isEgg(inst) then
			return
		end
		local parent = inst:FindFirstAncestorWhichIsA("Model")
		if parent and (byModel[parent] or pending[parent]) then
			return -- a visual sub-model of a creature we already animate
		end
		add(inst)
	end
end

-- Called by Eggs when an egg hatches here (links the new creature to a Hatch moment).
function Creatures.NoteHatch(pos: Vector3)
	table.insert(hatches, { pos = pos, t = os.clock() })
	if #hatches > 8 then
		table.remove(hatches, 1)
	end
end

function Creatures.Get(model: Model): Creature?
	return byModel[model]
end

function Creatures.Play(model: Model, name: string): boolean
	local c = byModel[model]
	if not c then
		return false
	end
	return CreatureMoments.Play(c, name, os.clock())
end

function Creatures.Start()
	for _, m in CollectionService:GetTagged("Creature") do
		consider(m)
	end
	CollectionService:GetInstanceAddedSignal("Creature"):Connect(consider)
	CollectionService:GetInstanceAddedSignal("WildCreature"):Connect(consider)
	CreatureHooks.Start(list)
	for _, d in workspace:GetDescendants() do
		consider(d)
	end
	workspace.DescendantAdded:Connect(consider)
	workspace.DescendantRemoving:Connect(function(d)
		if d:IsA("Model") and (byModel[d] or pending[d]) then
			remove(d)
		end
	end)
end

local function cull(now: number, cam: Camera)
	lastCull = now
	for m in pending do
		if not m.Parent then
			pending[m] = nil
		elseif hitboxOf(m) then
			add(m)
		end
	end
	local camPos = cam.CFrame.Position
	for _, c in list do
		local busy = c.sized or c.eyesClosed
		if c.dirty and not busy then
			CreatureState.Rebuild(c)
		end
		local s = c.model:GetScale()
		if math.abs(s - c.scale) > 1e-3 and not busy then
			Rig.Rescale(c.rig, s / c.scale) -- server ScaleTo (Baby -> Adult)
			c.scale = s
		end
		c.dist = (c.pos - camPos).Magnitude
	end
	table.sort(list, function(a, b)
		return a.dist < b.dist
	end)
	local full, parts = 0, 0
	local w = 1 + Tuning.ScreenMargin * 2
	local vp = cam.ViewportSize
	for _, c in list do
		local tier = 3
		if c.dist <= Tuning.AlwaysOnScreen then
			tier = 1
		else
			local sp, inFront = cam:WorldToViewportPoint(c.pos)
			local onScreen = inFront
				and math.abs(sp.X / vp.X - 0.5) * 2 < w
				and math.abs(sp.Y / vp.Y - 0.5) * 2 < w
			if not onScreen then
				tier = 0
			elseif c.dist <= Tuning.FullRadius then
				tier = 1
			elseif c.dist <= Tuning.MidRadius then
				tier = 2
			end
		end
		if tier == 1 then
			if full >= Tuning.MaxFull or parts + c.rig.count > Tuning.MaxParts then
				tier = 2
			else
				full += 1
				parts += c.rig.count
			end
		end
		c.tier = tier
	end
end

function Creatures.Step(now: number, dt: number, cam: Camera, night: boolean)
	if now - lastCull >= Tuning.CullInterval then
		cull(now, cam)
	end
	ctx.night = night
	table.clear(ctx.players)
	for _, plr in Players:GetPlayers() do
		local ch = plr.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			table.insert(ctx.players, hrp.Position)
		end
	end
	for _, c in list do
		local tier = c.tier
		if tier == 0 or not c.hitbox.Parent then
			continue
		end
		if tier == 1 then
			CreaturePose.Update(c, now, dt, 1, ctx)
			c.lastUpdate = now
		else
			local rate = if tier == 2 then Tuning.MidRate else Tuning.FarRate
			if now - c.lastUpdate >= rate then
				CreaturePose.Update(c, now, math.min(now - c.lastUpdate, 0.5), tier, ctx)
				c.lastUpdate = now
			end
		end
	end
end

return Creatures
