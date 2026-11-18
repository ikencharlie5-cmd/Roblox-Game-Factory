--!strict
-- Particle presets (Theme.Effects). Each returns an unparented ParticleEmitter; built-in textures only.
-- Mobile rates per ART_STYLE_GUIDE §2 (splash 15, mist 10).
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new(a, b)
end

local function fadeInOut(): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.1),
		NumberSequenceKeypoint.new(0.75, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function emitter(name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = SPARKLE
	e.LightEmission = 0.6
	for k, v in props do
		(e :: any)[k] = v
	end
	return e
end

local Effects = {}

-- Golden mutation sparkle (guide §5.4: Rate 3, Lifetime 1, Size 0.25 -> 0, LightEmission 1).
function Effects.Sparkle(color: Color3?, rate: number?): ParticleEmitter
	return emitter("Sparkle", {
		Color = ColorSequence.new(color or hex("#FFE27A")),
		Rate = rate or 3,
		Lifetime = NumberRange.new(0.8, 1.1),
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(0.35, 0),
		Transparency = seq(0, 0.4),
		LightEmission = 1,
	})
end

-- Emberfox tail / ember-touched.
function Effects.Embers(): ParticleEmitter
	return emitter("Embers", {
		Texture = FIRE,
		Color = ColorSequence.new(hex("#FFB347"), hex("#FF4E3A")),
		Rate = 2,
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(1, 2),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(30, 30),
		Size = seq(0.3, 0),
		Transparency = seq(0.1, 1),
		LightEmission = 1,
	})
end

-- One-shot hearts (Rate 0, call :Emit(3)).
function Effects.Hearts(): ParticleEmitter
	return emitter("Hearts", {
		Color = ColorSequence.new(hex("#FF6F91")),
		Rate = 0,
		Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(2, 3),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(25, 25),
		Size = seq(0.6, 0.2),
		Transparency = seq(0, 1),
		LightEmission = 0.5,
	})
end

-- Burst: Rate 0, call :Emit(n).
function Effects.CoinBurst(): ParticleEmitter
	return emitter("CoinBurst", {
		Color = ColorSequence.new(hex("#FFE066"), hex("#FFB300")),
		Rate = 0,
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(10, 16),
		Acceleration = Vector3.new(0, -35, 0),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(35, 35),
		Size = seq(0.8, 0.4),
		Transparency = seq(0, 0.6),
		LightEmission = 0.8,
	})
end

function Effects.Confetti(): ParticleEmitter
	local keys = {}
	for i = 0, 5 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 6, 0.6, 1)))
	end
	return emitter("Confetti", {
		Color = ColorSequence.new(keys),
		Rate = 0,
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(14, 22),
		Acceleration = Vector3.new(0, -30, 0),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(50, 50),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-200, 200),
		Size = seq(0.5, 0.4),
		Transparency = seq(0, 0.3),
	})
end

function Effects.Puff(color: Color3?): ParticleEmitter
	return emitter("Puff", {
		Texture = SMOKE,
		Color = ColorSequence.new(color or Color3.new(1, 1, 1)),
		Rate = 0,
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(1.2, 2.5),
		Transparency = seq(0.3, 1),
		LightEmission = 0,
	})
end

-- Discovery spot: ~3 rising sparkles.
function Effects.Discovery(): ParticleEmitter
	return emitter("Discovery", {
		Color = ColorSequence.new(hex("#FFF3A0")),
		Rate = 3,
		Lifetime = NumberRange.new(1.5, 2.2),
		Speed = NumberRange.new(1.5, 2.5),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(15, 15),
		Size = seq(0.5, 0),
		Transparency = seq(0, 0.5),
		LightEmission = 1,
	})
end

function Effects.Fireflies(): ParticleEmitter
	return emitter("Fireflies", {
		Color = ColorSequence.new(hex("#FFF27A")),
		Rate = 3,
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		Size = seq(0.3, 0.3),
		Transparency = fadeInOut(),
		LightEmission = 1,
	})
end

-- Mossy Hollow ground mist.
function Effects.Mist(): ParticleEmitter
	return emitter("Mist", {
		Texture = SMOKE,
		Color = ColorSequence.new(hex("#E8F6EC")),
		Rate = 2,
		Lifetime = NumberRange.new(8, 12),
		Speed = NumberRange.new(0.5, 1),
		SpreadAngle = Vector2.new(180, 10),
		Size = seq(12, 18),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		}),
		LightEmission = 0,
	})
end

-- Waterfall base (guide §2, mobile rates).
function Effects.Splash(): ParticleEmitter
	return emitter("Splash", {
		Color = ColorSequence.new(hex("#E8FAFF")),
		Rate = 15,
		Lifetime = NumberRange.new(0.25, 0.35),
		Speed = NumberRange.new(20, 35),
		Acceleration = Vector3.new(0, -40, 0),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(40, 40),
		Size = seq(0.6, 0.2),
		Transparency = seq(0.2, 1),
		LightEmission = 0.3,
	})
end

function Effects.WaterMist(): ParticleEmitter
	return emitter("WaterMist", {
		Texture = SMOKE,
		Color = ColorSequence.new(hex("#F2FCFF")),
		Rate = 10,
		Lifetime = NumberRange.new(1.5, 2.5),
		Speed = NumberRange.new(3, 6),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(60, 60),
		Size = seq(8, 10),
		Transparency = seq(0.75, 1),
		LightEmission = 0.2,
	})
end

-- Falling water streaks (translucent-part waterfall fallback, no texture upload needed).
function Effects.Fall(): ParticleEmitter
	return emitter("Fall", {
		Texture = SMOKE,
		Color = ColorSequence.new(hex("#DFF7FF")),
		Rate = 25,
		Lifetime = NumberRange.new(1, 1.3),
		Speed = NumberRange.new(28, 34),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(4, 4),
		Size = seq(2.5, 4),
		Squash = seq(2, 2),
		Transparency = seq(0.45, 0.9),
		LightEmission = 0.3,
	})
end

-- Weather sheets emitted from a flat part high above an area: "Rain" | "RainbowShower".
function Effects.Weather(kind: string): ParticleEmitter?
	if kind == "Rain" then
		return emitter("Rain", {
			Color = ColorSequence.new(hex("#CFE8FF")),
			Rate = 90,
			Lifetime = NumberRange.new(0.8, 1),
			Speed = NumberRange.new(60, 70),
			EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(4, 4),
			Size = seq(0.12, 0.12),
			Squash = seq(4, 4),
			Transparency = seq(0.3, 0.3),
			LightEmission = 0.2,
		})
	elseif kind == "RainbowShower" then
		local keys = {}
		for i = 0, 6 do
			table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 7, 0.55, 1)))
		end
		return emitter("RainbowShower", {
			Color = ColorSequence.new(keys),
			Rate = 40,
			Lifetime = NumberRange.new(2.5, 3.5),
			Speed = NumberRange.new(18, 24),
			EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(8, 8),
			Size = seq(0.45, 0.2),
			Transparency = seq(0, 0.4),
			LightEmission = 1,
		})
	end
	return nil
end

return Effects
