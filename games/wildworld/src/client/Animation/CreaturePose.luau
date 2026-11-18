--!strict
-- Computes one creature's pose and queues its part CFrames into Batch.
-- tier 1 = full (limbs, blink, ears, tail), 2 = mid (root + body bob + moments), 3 = far (rigid).
local Batch = require(script.Parent.Batch)
local CreatureMoments = require(script.Parent.CreatureMoments)
local CreatureState = require(script.Parent.CreatureState)
local Fx = require(script.Parent.Fx)
local Poses = require(script.Parent.Poses)
local Rig = require(script.Parent.Rig)
local Tuning = require(script.Parent.Tuning)

type Creature = CreatureState.Creature

export type Ctx = { night: boolean, players: { Vector3 } }

local CreaturePose = {}

local TAU = 2 * math.pi
local sin, abs, clamp = math.sin, math.abs, math.clamp
local LOOKS = { Idle = true, ReactToPlayer = true, Socialize = true, Play = true }
local pose = Poses.New()
local bones: { CFrame } = table.create(Rig.BONES, CFrame.identity)
local rng = Random.new()

local function wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end

local function rot(rig: Rig.Rig, b: number, rx: number, ry: number, rz: number): CFrame
	return rig.pivP[b] * CFrame.fromEulerAnglesYXZ(rx, ry, rz) * rig.pivN[b]
end

-- Walks the visual root toward the server Goal (model pivot space) at Speed. Returns yaw target.
local function steer(c: Creature, now: number, dt: number, ctx: Ctx): number?
	local goal = c.model:GetAttribute("Goal")
	local target = (if typeof(goal) == "Vector3" then goal else c.home) + c.hbOff
	local d = target - c.pos
	local flat = Vector3.new(d.X, 0, d.Z)
	local dist = flat.Magnitude
	local yawTarget: number? = nil
	if dist > Tuning.SnapDistance then
		c.pos = target
		c.speedNow = 0
	elseif dist > 0.05 then
		local spd = c.model:GetAttribute("Speed")
		-- server dead-reckons at exactly Speed, so match it (species feel only affects the fallback)
		local speed = if typeof(spd) == "number" and spd > 0 then spd else Tuning.DefaultSpeed * c.species.speed
		local step = math.min(dist, speed * dt * (if dist > 6 then 1.5 else 1))
		c.pos += flat.Unit * step + Vector3.new(0, d.Y * math.min(1, dt * 10), 0)
		c.speedNow = step / math.max(dt, 1e-3)
		if dist > 0.4 then
			yawTarget = math.atan2(-flat.X, -flat.Z)
		end
	else
		c.pos = Vector3.new(c.pos.X, c.pos.Y + d.Y * math.min(1, dt * 10), c.pos.Z)
		c.speedNow = 0
	end
	local moving = c.speedNow > 0.3
	c.moveBlend += ((if moving then 1 else 0) - c.moveBlend) * math.min(1, dt * Tuning.MoveBlendRate)

	-- look at the nearest player (head first, body follows when far round)
	if moving or not LOOKS[c.state] then
		c.lookYaw = 0
	else
		local best, bestD = nil :: Vector3?, Tuning.LookRadius
		for _, p in ctx.players do
			local dd = (p - c.pos).Magnitude
			if dd < bestD then
				best, bestD = p, dd
			end
		end
		if best then
			local off = best - c.pos
			local want = math.atan2(-off.X, -off.Z)
			local rel = wrap(want - c.yaw)
			if abs(rel) > Tuning.HeadYawMax or c.state == "ReactToPlayer" then
				yawTarget = want
			end
			c.lookYaw = clamp(rel, -Tuning.HeadYawMax, Tuning.HeadYawMax)
		elseif now >= c.nextLook then
			c.nextLook = now + CreatureState.Range(Tuning.LookEvery)
			c.lookYaw = if rng:NextNumber() < 0.4 then 0 else rng:NextNumber(-0.5, 0.5)
		end
	end
	return yawTarget
end

local function idleAction(c: Creature, now: number)
	if c.moment or c.moveBlend > 0.3 or c.state == "Sleep" or c.state == "Eat" or c.state == "Drink" then
		return
	end
	if now < c.nextAction then
		return
	end
	local every = c.persona.every
	local list = c.persona.actions
	if c.state == "Play" then
		every *= 0.4
		list = { "Hop", "Spin", "Happy" }
	elseif c.state == "Socialize" then
		list = { "Hop", "Wiggle", "Look" }
	end
	c.nextAction = now + CreatureState.Range(Tuning.ActionEvery) * every
	local happy = c.model:GetAttribute("Happy") or c.model:GetAttribute("Happiness")
	local name = list[rng:NextInteger(1, #list)]
	if typeof(happy) == "number" and happy >= Tuning.HappyAbove and rng:NextNumber() < 0.25 then
		name = "Happy"
	end
	CreatureMoments.Play(c, name, now)
end

function CreaturePose.Update(c: Creature, now: number, dt: number, tier: number, ctx: Ctx)
	local yawTarget = steer(c, now, dt, ctx)
	if yawTarget then
		c.yaw += wrap(yawTarget - c.yaw) * math.min(1, dt * Tuning.TurnRate)
	end
	CreatureMoments.Step(c, now)
	local rig = c.rig
	local root = CFrame.new(c.pos) * CFrame.Angles(0, c.yaw, 0)
	if c.lastRoot ~= root then
		Batch.Add(c.hitbox, root) -- keep clicks, prompts and nameplates on the visible creature
	end
	if tier == 3 then
		if c.lastRoot == root and not c.moment then
			return
		end
		c.lastRoot = root
		for i, p in rig.parts do
			Batch.Add(p, root * rig.rest[i])
		end
		return
	end
	c.lastRoot = nil
	if tier == 1 then
		idleAction(c, now)
	end

	local state = c.state
	local sleeping = state == "Sleep"
	local hunger = c.model:GetAttribute("Hunger")
	local happiness = c.model:GetAttribute("Happy") or c.model:GetAttribute("Happiness")
	local hungry = typeof(hunger) == "number" and hunger < Tuning.HungryBelow
	local happy = (typeof(happiness) == "number" and happiness >= Tuning.HappyAbove)
		or state == "Play"
		or state == "ReactToPlayer"
		or state == "Socialize"
	local spd = c.species.speed * (if c.baby then 1.25 else 1) * (if ctx.night and not sleeping then 0.75 else 1)
	local period = Tuning.BobPeriod * (if sleeping then 2.2 else 1) / spd
	local wave = sin(TAU * now / period + c.phase)

	-- base body
	local bob = Tuning.BobAmp * wave
	local breath = Tuning.BreathAmp * wave * (if sleeping then 1.8 else 1)
	local sy, sxz = 1 + breath, 1 - breath * 0.5
	local lower, bodyPitch, headPitch, headRoll = 0, 0, 0, 0
	local mb = c.moveBlend
	if mb > 0.01 then
		local rate = clamp(c.speedNow / Tuning.WalkRefSpeed, 0.6, 2)
		c.walkPhase += dt * TAU * Tuning.WalkHz * rate
		if c.species.hop then
			local h = abs(sin(c.walkPhase * 0.5))
			bob += Tuning.HopHeight * h * mb
			local contact = 1 - math.min(1, h * 4)
			sy -= Tuning.HopSquash * contact * mb
			sxz += Tuning.HopSquash * 0.6 * contact * mb
		else
			bob += Tuning.WalkBob * abs(sin(c.walkPhase)) * mb
			headPitch += 0.05 * sin(c.walkPhase * 2) * mb
		end
	end
	if sleeping then
		lower = -Tuning.SleepLower
		headPitch += Tuning.SleepDroop
		bodyPitch = -0.05
		if tier == 1 and now >= c.nextZ then
			c.nextZ = now + Tuning.ZEvery
			Fx.Float(if rng:NextNumber() < 0.5 then "z" else "Z", CreatureMoments.TopPos(c), Color3.fromRGB(200, 215, 255), 1.1)
		end
	elseif state == "Eat" or state == "Drink" then
		headPitch += 0.45 + 0.1 * sin(TAU * 3 * now)
	elseif state == "Socialize" then
		headRoll = 0.15 * sin(now * 1.5 + c.phase)
	end
	if hungry and not sleeping then
		headPitch += Tuning.HungryDroop
	end

	-- moment overlay
	local m = c.moment
	local M = CFrame.identity
	local uni = 1
	if m then
		Poses.Eval(m, math.clamp((now - c.momentT0) / c.momentDur, 0, 1), pose)
		sy *= pose.sy
		sxz *= pose.sxz
		headPitch += pose.head
		uni = pose.uni
		M = CFrame.new(0, pose.dy, 0) * rot(rig, Rig.BODY, pose.tiltX, pose.yaw, pose.tiltZ)
		if Poses.Scales[m] then
			CreatureState.SetSize(c, uni)
		end
	end

	-- bones (root space)
	local B = CFrame.new(0, bob + lower, 0) * rot(rig, Rig.BODY, bodyPitch, 0, 0)
	for b = 1, Rig.BONES do
		bones[b] = B
	end
	if tier == 1 then
		-- blink / ears / tail / head
		if now >= c.nextBlink then
			c.nextBlink = now + CreatureState.Range(Tuning.BlinkEvery)
			c.blinkUntil = now + Tuning.BlinkTime
		end
		CreatureState.SetEyes(c, sleeping or now < c.blinkUntil)
		if now >= c.nextFlick then
			c.nextFlick = now + CreatureState.Range(Tuning.EarFlickEvery) * (if c.persona == Tuning.Personality.Shy then 0.6 else 1)
			c.flickUntil = now + Tuning.EarFlickTime
			c.flickLeft = rng:NextNumber() < 0.5
		end
		local flick = if now < c.flickUntil
			then Tuning.EarFlickAngle * sin(math.pi * (1 - (c.flickUntil - now) / Tuning.EarFlickTime))
			else 0
		local earSway = 0.05 * sin(now * 2 + c.phase)
		local earPitch = if sleeping then 0.4 else 0
		c.headYaw += (c.lookYaw - c.headYaw) * math.min(1, dt * 4)
		local H = B * rot(rig, Rig.HEAD, -headPitch, c.headYaw, headRoll)
		bones[Rig.HEAD] = H
		bones[Rig.EARL] = H * rot(rig, Rig.EARL, earPitch, 0, earSway + (if c.flickLeft then flick else 0))
		bones[Rig.EARR] = H * rot(rig, Rig.EARR, earPitch, 0, -earSway - (if c.flickLeft then 0 else flick))
		local tAmp = if sleeping then 0.02 elseif happy then Tuning.HappyTailAmp else Tuning.TailAmp
		local tHz = if happy then Tuning.HappyTailHz else Tuning.TailHz
		if hungry then
			tAmp *= 0.5
		end
		bones[Rig.TAIL] = B * rot(rig, Rig.TAIL, 0, tAmp * sin(TAU * tHz * now + c.phase), 0)
		local swing = Tuning.LegSwing * sin(c.walkPhase) * mb * (if c.species.hop then 0.3 else 1)
		bones[Rig.LFL] = rot(rig, Rig.LFL, swing, 0, 0)
		bones[Rig.LBR] = rot(rig, Rig.LBR, swing, 0, 0)
		bones[Rig.LFR] = rot(rig, Rig.LFR, -swing, 0, 0)
		bones[Rig.LBL] = rot(rig, Rig.LBL, -swing, 0, 0)
		local flap = Tuning.WingFlap * (0.3 + mb) * sin(TAU * 1.5 * now + c.phase)
		bones[Rig.WINGL] = B * rot(rig, Rig.WINGL, 0, 0, flap)
		bones[Rig.WINGR] = B * rot(rig, Rig.WINGR, 0, 0, -flap)
		if c.glowing then
			for i, l in rig.lights do
				l.Brightness = rig.lightBase[i] * (0.9 + 0.3 * sin(TAU * now / 2))
			end
		end
	else
		for b = Rig.LFL, Rig.LBR do
			bones[b] = CFrame.identity
		end
	end

	-- squash & stretch about the ground centre, then world
	local gc = rig.pivP[Rig.BODY].Position
	local kx, ky = sxz * uni, sy * uni
	local W = root * M
	for i, p in rig.parts do
		local L = bones[rig.bone[i]] * rig.rest[i]
		local lp = L.Position
		local q = Vector3.new(gc.X + (lp.X - gc.X) * kx, gc.Y + (lp.Y - gc.Y) * ky, gc.Z + (lp.Z - gc.Z) * kx)
		Batch.Add(p, W * (L + (q - lp)))
	end
end

return CreaturePose
