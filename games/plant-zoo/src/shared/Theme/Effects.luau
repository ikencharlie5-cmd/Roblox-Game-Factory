--!strict
-- Particle presets (Theme.Effects). Each returns an unparented ParticleEmitter; built-in textures only.
local function hex(h: string): Color3
	return Color3.fromHex(h)
end

-- Particle presets. Each returns a ParticleEmitter (not parented). Built-in textures only.
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new(a, b)
end

local function emitter(props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE
	e.LightEmission = 0.6
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	return e
end

local Effects = {}

function Effects.Sparkle(color: Color3, rate: number?): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(color),
		Rate = rate or 6,
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(0.5, 1.5),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(0.5, 0),
		Transparency = seq(0.1, 1),
	})
end

function Effects.Aura(color: Color3): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(color),
		Rate = 10,
		Lifetime = NumberRange.new(1, 1.8),
		Speed = NumberRange.new(1, 2),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(25, 25),
		Size = seq(0.7, 0.1),
		Transparency = seq(0.2, 1),
		LightEmission = 1,
	})
end

function Effects.RainbowAura(): ParticleEmitter
	local e = Effects.Aura(Color3.new(1, 1, 1))
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.8, 1)))
	end
	e.Color = ColorSequence.new(keys)
	return e
end

function Effects.Leaves(): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(hex("#6BFF7A"), hex("#2F8F4E")),
		Rate = 3,
		Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(1, 2),
		Acceleration = Vector3.new(0, -1.5, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-90, 90),
		SpreadAngle = Vector2.new(60, 60),
		Size = seq(0.35, 0.2),
		Transparency = seq(0, 1),
		LightEmission = 0.2,
	})
end

-- Burst emitter: call :Emit(n) yourself (Rate = 0).
function Effects.CoinBurst(): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(hex("#FFE066"), hex("#FFB300")),
		Rate = 0,
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(10, 16),
		Acceleration = Vector3.new(0, -35, 0),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(40, 40),
		Size = seq(0.8, 0.4),
		Transparency = seq(0, 0.6),
		LightEmission = 0.8,
	})
end

function Effects.Puff(color: Color3): ParticleEmitter
	return emitter({
		Texture = SMOKE,
		Color = ColorSequence.new(color),
		Rate = 0,
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(1.2, 2.5),
		Transparency = seq(0.3, 1),
		LightEmission = 0,
	})
end

function Effects.Fireflies(): ParticleEmitter
	return emitter({
		Color = ColorSequence.new(hex("#FFF27A")),
		Rate = 4,
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 0.2, 0),
		Size = seq(0.35, 0.35),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0),
			NumberSequenceKeypoint.new(0.7, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		LightEmission = 1,
	})
end

-- Weather sheets: emitted from a flat part high above an area, falling down.
function Effects.Weather(kind: string): ParticleEmitter?
	local base = {
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(5, 5),
		Rate = 60,
	}
	if kind == "Rain" or kind == "Thunderstorm" then
		base.Color = ColorSequence.new(hex("#CFE8FF"))
		base.Speed = NumberRange.new(60, 70)
		base.Lifetime = NumberRange.new(0.6, 0.8)
		base.Size = seq(0.12, 0.12)
		base.Squash = seq(4, 4)
		base.Transparency = seq(0.3, 0.3)
		base.LightEmission = 0.2
		base.Rate = if kind == "Thunderstorm" then 150 else 110
	elseif kind == "Snow Flurry" or kind == "Snow" then
		base.Color = ColorSequence.new(Color3.new(1, 1, 1))
		base.Speed = NumberRange.new(6, 9)
		base.Lifetime = NumberRange.new(5, 7)
		base.Size = seq(0.35, 0.3)
		base.SpreadAngle = Vector2.new(25, 25)
		base.Transparency = seq(0.1, 0.4)
	elseif kind == "Bloom Season" or kind == "Bloom" then
		base.Color = ColorSequence.new(hex("#FFB7D5"), hex("#FFF0F6"))
		base.Speed = NumberRange.new(5, 8)
		base.Lifetime = NumberRange.new(5, 7)
		base.Size = seq(0.45, 0.35)
		base.Rotation = NumberRange.new(0, 360)
		base.RotSpeed = NumberRange.new(-120, 120)
		base.SpreadAngle = Vector2.new(30, 30)
		base.Rate = 30
	elseif kind == "Starfall" then
		base.Color = ColorSequence.new(hex("#FFFFFF"), hex("#B8C8FF"))
		base.Speed = NumberRange.new(40, 60)
		base.Lifetime = NumberRange.new(1, 1.5)
		base.Size = seq(1, 0)
		base.SpreadAngle = Vector2.new(35, 35)
		base.LightEmission = 1
		base.Rate = 4
	elseif kind == "Heatwave" then
		base.Texture = SMOKE
		base.Color = ColorSequence.new(hex("#FFD9A0"))
		base.EmissionDirection = Enum.NormalId.Top
		base.Speed = NumberRange.new(1, 2)
		base.Lifetime = NumberRange.new(2, 3)
		base.Size = seq(6, 10)
		base.Transparency = seq(0.92, 1)
		base.Rate = 6
	else
		return nil
	end
	return emitter(base)
end

return Effects
