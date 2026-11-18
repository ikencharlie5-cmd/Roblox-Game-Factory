--!strict
-- One-shot creature moments: start (with their FX) and per-frame bookkeeping (landing dust,
-- mutation reveal, captured hide). The pose curves themselves live in Poses.
local CreatureState = require(script.Parent.CreatureState)
local Fx = require(script.Parent.Fx)
local Poses = require(script.Parent.Poses)
local Sfx = require(script.Parent.Sfx)
local Tuning = require(script.Parent.Tuning)

type Creature = CreatureState.Creature

local CreatureMoments = {}

local HEART = "\u{2665}"
local PINK = Color3.fromRGB(255, 110, 150)
local WHITE = Color3.fromRGB(255, 255, 255)

local function rootCF(c: Creature): CFrame
	return CFrame.new(c.pos) * CFrame.Angles(0, c.yaw, 0)
end

function CreatureMoments.TopPos(c: Creature): Vector3
	return rootCF(c) * Vector3.new(0, c.rig.top + 0.6, 0)
end

function CreatureMoments.GroundPos(c: Creature): Vector3
	return rootCF(c) * Vector3.new(0, c.rig.groundY, 0)
end

local function hearts(c: Creature, n: number)
	local top = CreatureMoments.TopPos(c)
	for _ = 1, n do
		Fx.Float(HEART, top, PINK, 1.3)
	end
end

local function mutationColor(c: Creature): Color3
	return (c.mutation and Tuning.MutationColors[c.mutation]) or Color3.fromRGB(255, 226, 122)
end

-- Starts a moment. Unknown names are ignored. Returns true if it played.
function CreatureMoments.Play(c: Creature, name: string, now: number): boolean
	local dur = Poses.Duration[name]
	if not dur then
		return false
	end
	if c.sized and not Poses.Scales[name] then
		CreatureState.SetSize(c, 1)
	end
	c.moment = name
	c.momentT0 = now
	c.momentDur = dur
	c.landed = false
	local center = rootCF(c) * Vector3.new(0, (c.rig.groundY + c.rig.top) * 0.5, 0)
	local radius = math.max(1, (c.rig.top - c.rig.groundY) * 0.7)
	if name == "Happy" then
		hearts(c, 3)
		Sfx.At("HappyHearts", center, 1.5)
	elseif name == "Pet" then
		hearts(c, 2)
		Sfx.At("HappyHearts", center, 1.5)
	elseif name == "Hatch" or name == "Pop" then
		local ground = CreatureMoments.GroundPos(c)
		Fx.Burst("Dust", ground, 10)
		Fx.Ring(ground, WHITE, radius * 2)
		if name == "Hatch" then
			Sfx.At("Baby_Chirp", center)
			Fx.Flash(center, WHITE, 3, 0.5)
			Fx.Burst("Sparkle", center, 16, WHITE)
			if c.mutation then
				-- mutation VFX turns on after the pop, for drama
				CreatureState.MuteVfx(c, true)
				c.revealAt = now + dur * 0.35 + Tuning.RevealDelay
			end
		end
		CreatureState.SetSize(c, 0.05)
	elseif name == "Celebrate" or name == "Discover" then
		Fx.Burst("Sparkle", center, 30, mutationColor(c))
		Fx.Ring(CreatureMoments.GroundPos(c), mutationColor(c), radius * 2.5)
	elseif name == "Captured" then
		Fx.Bubble(center, radius * 1.2, radius * 0.25, dur)
	elseif name == "CaptureFail" then
		Fx.Bubble(center, radius * 1.1, radius * 1.4, 0.35)
	elseif name == "Sad" then
		Fx.Float("...", CreatureMoments.TopPos(c), Color3.fromRGB(170, 190, 220), 1.2)
	end
	return true
end

-- Per-frame bookkeeping for the active moment + reveal/hide timers (runs in every tier).
function CreatureMoments.Step(c: Creature, now: number)
	if c.revealAt and now >= c.revealAt then
		c.revealAt = nil
		CreatureState.MuteVfx(c, false)
		local center = rootCF(c) * Vector3.new(0, (c.rig.groundY + c.rig.top) * 0.5, 0)
		local col = mutationColor(c)
		local big = c.mutation ~= nil and Tuning.BigMutations[c.mutation :: string] == true
		Fx.Burst("Sparkle", center, if big then 60 else 30, col)
		Fx.Flash(center, col, if big then 8 else 4, if big then 1.2 else 0.7)
		Fx.Ring(CreatureMoments.GroundPos(c), col, if big then 9 else 5)
		if big then
			Fx.Float("\u{2605}", CreatureMoments.TopPos(c), col, 2.2)
		end
	end
	if c.hiddenUntil > 0 then
		if now >= c.hiddenUntil then
			c.hiddenUntil = 0
			CreatureState.SetHidden(c, false)
		else
			CreatureState.SetHidden(c, true)
		end
	end
	local m = c.moment
	if not m then
		return
	end
	local p = (now - c.momentT0) / c.momentDur
	if m == "Thud" and not c.landed and p >= 0.45 then
		c.landed = true
		Fx.Burst("Dust", CreatureMoments.GroundPos(c), 14)
		Fx.Ring(CreatureMoments.GroundPos(c), Color3.fromRGB(240, 225, 190), 4)
	elseif m == "Feed" and not c.landed and p >= 0.55 then
		c.landed = true
		hearts(c, 3)
	end
	if p >= 1 then
		c.moment = nil
		CreatureState.SetSize(c, 1)
		if m == "Captured" then
			c.hiddenUntil = now + Tuning.CapturedHide
		end
	end
end

-- Moment name from an attribute value like "Happy" or "Happy:17" (suffix makes repeats fire).
function CreatureMoments.Parse(value: any): string?
	if typeof(value) ~= "string" or value == "" then
		return nil
	end
	local name = string.match(value, "^([%w]+)")
	return name
end

return CreatureMoments
