--!strict
-- Pure animation curves ("moments"). Eval(name, p) with p = 0..1 returns a pose offset:
--   dy (studs up), yaw (rad), tiltX (rad, + = lean back), tiltZ (rad, side lean),
--   sxz / sy (squash & stretch, 1 = none; mesh creatures only), uni (uniform scale via ScaleTo, 1 = none).
-- Also owns pooled particle bursts (one hidden anchored part per preset; moved + :Emit()).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme")) :: any
local Tuning = require(script.Parent.Tuning)

local Moments = {}

local PI = math.pi
local sin = math.sin

local function backOut(x: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

-- A jump between p = a and p = b with anticipation squash before and a landing squash after.
local function jump(p: number, a: number, b: number, h: number): (number, number, number)
	if p < a then
		local q = p / a
		return 0, 1 + 0.12 * sin(PI * q), 1 - 0.18 * sin(PI * q)
	elseif p < b then
		local q = (p - a) / (b - a)
		return h * sin(PI * q), 1 - 0.08 * sin(PI * q), 1 + 0.14 * sin(PI * q)
	end
	local q = (p - b) / (1 - b)
	return 0, 1 + 0.14 * sin(PI * q) * (1 - q), 1 - 0.2 * sin(PI * q) * (1 - q)
end

export type Pose = { dy: number, yaw: number, tiltX: number, tiltZ: number, sxz: number, sy: number, uni: number }

Moments.Duration = {
	Pop = Tuning.PopTime,
	Bounce = Tuning.BounceTime,
	Celebrate = Tuning.CelebrateTime,
	Hop = Tuning.HopTime,
	HappyHops = Tuning.HopTime * 3,
	Spin = 0.8,
	Wiggle = 0.7,
	Look = 1.6,
	Thud = Tuning.ThudTime,
}

function Moments.Eval(name: string, p: number, out: Pose)
	out.dy, out.yaw, out.tiltX, out.tiltZ, out.sxz, out.sy, out.uni = 0, 0, 0, 0, 1, 1, 1
	if name == "Pop" then
		out.uni = math.max(0.05, backOut(p) * 1.05 - 0.05 * p)
	elseif name == "Bounce" then
		out.uni = 0.7 + 0.3 * backOut(math.min(p * 1.6, 1))
		out.dy, out.sxz, out.sy = jump(p, 0.15, 0.6, 0.8)
	elseif name == "Celebrate" then
		out.dy, out.sxz, out.sy = jump(p, 0.15, 0.75, 2.4)
		out.yaw = if p > 0.15 and p < 0.75 then 2 * PI * smooth((p - 0.15) / 0.6) else 0
		out.tiltX = if p > 0.15 and p < 0.75 then -0.15 * sin(PI * (p - 0.15) / 0.6) else 0
	elseif name == "Hop" then
		out.dy, out.sxz, out.sy = jump(p, 0.2, 0.8, 1)
	elseif name == "HappyHops" then
		local k = math.min(math.floor(p * 3), 2)
		local q = p * 3 - k
		out.dy, out.sxz, out.sy = jump(q, 0.2, 0.8, 0.9)
		out.tiltZ = (if k % 2 == 0 then 0.12 else -0.12) * sin(PI * q)
	elseif name == "Spin" then
		out.yaw = 2 * PI * smooth(p)
		out.dy = 0.3 * sin(PI * p)
	elseif name == "Wiggle" then
		out.tiltZ = 0.22 * sin(p * 6 * PI) * (1 - p)
		out.sxz = 1 + 0.05 * sin(p * 12 * PI) * (1 - p)
	elseif name == "Look" then
		out.yaw = 0.6 * sin(p * 2 * PI)
		out.tiltX = -0.08 * sin(PI * p)
	elseif name == "Thud" then
		local fall = 0.45
		if p < fall then
			local q = p / fall
			out.dy = Tuning.ThudDrop * (1 - q * q)
			out.sy, out.sxz = 1.1, 0.95
		else
			local q = (p - fall) / (1 - fall)
			local k = sin(PI * q) * (1 - q)
			out.sy, out.sxz = 1 - 0.3 * k, 1 + 0.2 * k
			out.uni = 1 - 0.12 * k
		end
	end
end

-- Pooled particle bursts ---------------------------------------------------------------------------
local fxFolder: Folder? = nil
local pool: { [string]: ParticleEmitter } = {}

local function folder(): Folder
	if fxFolder and fxFolder.Parent then
		return fxFolder
	end
	local f = Instance.new("Folder")
	f.Name = "ClientAnimFX"
	f.Parent = workspace
	fxFolder = f
	return f
end

local function make(kind: string): ParticleEmitter?
	local ok, e = pcall(function(): ParticleEmitter
		if kind == "Dust" then
			return Theme.Effects.Puff(Color3.fromRGB(222, 200, 160))
		elseif kind == "Coins" then
			return Theme.Effects.CoinBurst()
		elseif kind == "Leaves" then
			return Theme.Effects.Leaves()
		end
		return Theme.Effects.Sparkle(Theme.Colors.Gold or Color3.fromRGB(255, 220, 90), 0)
	end)
	if not ok or not e then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = kind
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Parent = folder()
	e.Enabled = false
	e.Parent = p
	return e
end

-- Burst(kind, position, count?, color?) - kind: "Dust" | "Sparkle" | "Coins" | "Leaves".
function Moments.Burst(kind: string, pos: Vector3, count: number?, color: Color3?)
	local e = pool[kind]
	if not e or not e.Parent or not (e.Parent :: Instance).Parent then
		local made = make(kind)
		if not made then
			return
		end
		pool[kind] = made
		e = made
	end
	local em = e :: ParticleEmitter
	local part = em.Parent :: BasePart
	part.CFrame = CFrame.new(pos)
	if color then
		em.Color = ColorSequence.new(color)
	end
	em:Emit(count or 12)
end

function Moments.Folder(): Folder
	return folder()
end

return Moments
