--!strict
-- Helper module: server creature brains (Main calls Start(), which connects the loop).
-- One Heartbeat loop, max N decisions per frame,
-- nextThink = now + rand(3, 8). The server never moves parts: it replicates State / Goal / Speed
-- attributes and dead-reckons its own position (from -> goal over time) for feeding/capture checks.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CreatureAI = {}

export type Agent = {
	model: Model,
	kind: string, -- "park" | "wild"
	owner: Player?,
	species: string,
	personality: string,
	speed: number,
	centre: Vector3, -- park: pad centre (ground); wild: home node (ground)
	half: number, -- park: pad half-size minus margin; wild: wander radius
	foot: number, -- pivot height above ground
	from: Vector3,
	goal: Vector3,
	departAt: number,
	arriveAt: number,
	state: string,
	nextThink: number,
	hunger: () -> number,
	context: (() -> any)?, -- park: {food=Vector3?, water=Vector3?, toy=Vector3?, shelter=Vector3?, partners={Agent}}
	onDone: ((Agent, string) -> ())?, -- called when Eat/Drink/Play/Sleep/Socialize finishes
	override: any?, -- {state, goal, speedMult, untilT} forced behaviour (bait, flee)
	paused: boolean?,
}

local agents: { Agent } = {}
local index: { [Model]: number } = {}
local cursor = 1
local rng = Random.new()

local function isNight(): boolean
	local t = Lighting.ClockTime
	return t >= Config.AI.NightStart or t < Config.AI.NightEnd
end

function CreatureAI.Position(a: Agent, now: number?): Vector3
	local t = now or os.clock()
	if t >= a.arriveAt or a.arriveAt <= a.departAt then
		return a.goal
	end
	local alpha = (t - a.departAt) / (a.arriveAt - a.departAt)
	return a.from:Lerp(a.goal, math.clamp(alpha, 0, 1))
end

-- Distance for range checks: nearest of the server position and the replicated Goal (- GoalSlack),
-- so clicks on the visible (client-tweened) creature never fail as "too far".
function CreatureAI.Distance(a: Agent, pos: Vector3): number
	local d = math.min((CreatureAI.Position(a) - pos).Magnitude, (a.goal - pos).Magnitude - Config.Needs.GoalSlack)
	return math.max(d, 0)
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundY(pos: Vector3, fallback: number): number
	local excl = {}
	for _, name in { "Creatures", "WildCreatures" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(excl, f)
		end
	end
	rayParams.FilterDescendantsInstances = excl
	local hit = workspace:Raycast(pos + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rayParams)
	return if hit then hit.Position.Y else fallback
end

local function clampGoal(a: Agent, p: Vector3): Vector3
	local c = a.centre
	local x, z
	if a.kind == "park" then
		x = math.clamp(p.X, c.X - a.half, c.X + a.half)
		z = math.clamp(p.Z, c.Z - a.half, c.Z + a.half)
		return Vector3.new(x, c.Y + a.foot, z)
	end
	local off = Vector3.new(p.X - c.X, 0, p.Z - c.Z)
	if off.Magnitude > a.half * 1.6 then
		off = off.Unit * a.half * 1.6
	end
	x, z = c.X + off.X, c.Z + off.Z
	return Vector3.new(x, groundY(Vector3.new(x, c.Y, z), c.Y) + a.foot, z)
end

local function randomPoint(a: Agent): Vector3
	local r = a.half
	return clampGoal(a, a.centre + Vector3.new(rng:NextNumber(-r, r), 0, rng:NextNumber(-r, r)))
end

-- Move toward `goal` in state `state`; returns travel seconds.
function CreatureAI.Go(a: Agent, state: string, goal: Vector3, speedMult: number?): number
	local now = os.clock()
	a.from = CreatureAI.Position(a, now)
	a.goal = clampGoal(a, goal)
	local speed = a.speed * (speedMult or 1)
	local dist = (a.goal - a.from).Magnitude
	a.departAt = now
	a.arriveAt = now + (if speed > 0 then dist / speed else 0)
	a.state = state
	a.model:SetAttribute("Speed", speed)
	a.model:SetAttribute("Goal", a.goal)
	a.model:SetAttribute("State", state)
	return a.arriveAt - now
end

local function nearestOwnerDist(a: Agent, pos: Vector3): (number, Vector3?)
	local owner = a.owner
	local char = owner and owner.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return math.huge, nil
	end
	return (root.Position - pos).Magnitude, root.Position
end

local function anyPlayerNear(pos: Vector3, range: number): boolean
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - pos).Magnitude <= range then
			return true
		end
	end
	return false
end

local function think(a: Agent, now: number)
	local prev = a.state
	if a.onDone and (prev == "Eat" or prev == "Drink" or prev == "Play" or prev == "Sleep" or prev == "Socialize") then
		a.onDone(a, prev)
	end
	local o = a.override
	if o then
		if os.clock() < o.untilT then
			local t = CreatureAI.Go(a, o.state, o.goal, o.speedMult)
			a.nextThink = now + math.max(t, 0) + rng:NextNumber(1, 2)
			return
		end
		a.override = nil
	end
	local pos = CreatureAI.Position(a, now)
	local p = (Config.AI.Personality :: any)[a.personality] or {}
	local base = Config.AI.Base
	local hunger = a.hunger()
	local urgency = (100 - hunger) / 25
	if hunger < 30 then
		urgency *= urgency
	end
	local ctx = if a.context then a.context() else {}
	local w: { [string]: number } = {
		Idle = base.Idle * (p.Idle or 1),
		Wander = base.Wander * (p.Wander or 1),
		Sleep = base.Sleep * (p.Sleep or 1) * (if isNight() then Config.AI.NightSleepMult else 1),
	}
	if ctx.food then
		w.Eat = base.Eat * urgency
	end
	if ctx.water then
		w.Drink = base.Drink
	end
	if ctx.toy then
		w.Play = base.Play * (p.Play or 1)
	end
	if ctx.partners and #ctx.partners > 0 then
		w.Socialize = base.Socialize * (p.Socialize or 1)
	end
	local ownerDist, ownerPos = nearestOwnerDist(a, pos)
	if a.kind == "park" and ownerDist <= Config.AI.ReactRange then
		w.ReactToPlayer = base.ReactToPlayer * (p.ReactToPlayer or 1)
	end
	local total = 0
	for _, v in w do
		total += v
	end
	local roll = rng:NextNumber(0, total)
	local pick = "Idle"
	for state, v in w do
		roll -= v
		if roll <= 0 then
			pick = state
			break
		end
	end

	local travel, linger = 0, rng:NextNumber(Config.AI.ThinkMin, Config.AI.ThinkMax)
	if pick == "Wander" then
		travel = CreatureAI.Go(a, "Wander", randomPoint(a))
	elseif pick == "Eat" or pick == "Drink" or pick == "Play" then
		local target = if pick == "Eat" then ctx.food elseif pick == "Drink" then ctx.water else ctx.toy
		travel = CreatureAI.Go(a, pick, target + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)))
		linger = 4
	elseif pick == "Sleep" then
		travel = CreatureAI.Go(a, "Sleep", ctx.shelter or pos)
		linger = rng:NextNumber(20, 40)
	elseif pick == "Socialize" then
		local partner = ctx.partners[rng:NextInteger(1, #ctx.partners)]
		local ppos = CreatureAI.Position(partner, now)
		local away = Vector3.new(pos.X - ppos.X, 0, pos.Z - ppos.Z)
		away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
		travel = CreatureAI.Go(a, "Socialize", ppos + away * 3)
		linger = 5
	elseif pick == "ReactToPlayer" and ownerPos then
		local dir = Vector3.new(ownerPos.X - pos.X, 0, ownerPos.Z - pos.Z)
		if dir.Magnitude < 0.1 then
			dir = Vector3.new(1, 0, 0)
		end
		if p.flees then
			travel = CreatureAI.Go(a, "ReactToPlayer", pos - dir.Unit * Config.AI.ShyFleeDistance, 1.3)
		else
			travel = CreatureAI.Go(a, "ReactToPlayer", ownerPos - dir.Unit * 4)
		end
		linger = 3
	else
		CreatureAI.Go(a, "Idle", pos)
		linger = rng:NextNumber(2, 5)
	end
	a.nextThink = now + travel + linger
end

function CreatureAI.Add(a: Agent)
	if index[a.model] then
		return
	end
	table.insert(agents, a)
	index[a.model] = #agents
end

function CreatureAI.Remove(model: Model)
	local i = index[model]
	if not i then
		return
	end
	local last = #agents
	agents[i] = agents[last]
	index[agents[i].model] = i
	agents[last] = nil
	index[model] = nil
end

function CreatureAI.Get(model: Model): Agent?
	local i = index[model]
	return if i then agents[i] else nil
end

-- Force a behaviour now (bait, flee). Clears after `seconds`.
function CreatureAI.Force(a: Agent, state: string, goal: Vector3, seconds: number, speedMult: number?)
	a.override = { state = state, goal = goal, untilT = os.clock() + seconds, speedMult = speedMult }
	a.nextThink = 0
end

function CreatureAI.Start()
	RunService.Heartbeat:Connect(function()
		local n = #agents
		if n == 0 then
			return
		end
		local now = os.clock()
		local budget = Config.AI.MaxDecisionsPerFrame
		local checks = math.min(n, budget * 4)
		for _ = 1, checks do
			if cursor > #agents then
				cursor = 1
			end
			local a = agents[cursor]
			cursor += 1
			if a and not a.paused and now >= a.nextThink then
				if a.kind == "wild" and not anyPlayerNear(CreatureAI.Position(a, now), Config.AI.WildThinkRange) then
					a.nextThink = now + 2
				else
					local ok, err = pcall(think, a, now)
					if not ok then
						warn("[CreatureAI] think failed:", err)
						a.nextThink = now + 5
					end
					budget -= 1
					if budget <= 0 then
						break
					end
				end
			end
		end
	end)
end

return CreatureAI
