--!strict
-- Pure "moment" curves. Eval(name, p) with p = 0..1 fills a pose overlay:
--   dy (studs up), yaw (rad spin), tiltX (+ = nose up), tiltZ (side lean), sxz/sy (squash & stretch
--   by part offsets, 1 = none), uni (real uniform scale, 1 = none), head (extra head pitch, + = down).
local Tuning = require(script.Parent.Tuning)

local Poses = {}

local PI = math.pi
local sin = math.sin

export type Pose = {
	dy: number,
	yaw: number,
	tiltX: number,
	tiltZ: number,
	sxz: number,
	sy: number,
	uni: number,
	head: number,
}

function Poses.New(): Pose
	return { dy = 0, yaw = 0, tiltX = 0, tiltZ = 0, sxz = 1, sy = 1, uni = 1, head = 0 }
end

local function backOut(x: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Anticipation squash (p < a), airborne stretch (a..b), landing squash (> b). Returns dy, sxz, sy.
local function jump(p: number, a: number, b: number, h: number): (number, number, number)
	if p < a then
		local q = sin(PI * p / a)
		return 0, 1 + 0.12 * q, 1 - 0.2 * q
	elseif p < b then
		local q = sin(PI * (p - a) / (b - a))
		return h * q, 1 - 0.08 * q, 1 + 0.15 * q
	end
	local q = (p - b) / (1 - b)
	local k = sin(PI * q) * (1 - q)
	return 0, 1 + 0.16 * k, 1 - 0.22 * k
end

Poses.Duration = {
	Hop = 0.5,
	Happy = 1.1, -- two hops + hearts
	Spin = 0.8,
	Wiggle = 0.7,
	Look = 1.6,
	Sniff = 1.2,
	Stretch = 1.3,
	Eat = 1.2,
	Feed = 1.8, -- munch then happy spin
	Pet = 0.8,
	Sad = 1.2,
	Pop = 0.5,
	Hatch = 1.5, -- pop, then jump + spin
	Celebrate = 1.3,
	Discover = 1.4,
	Thud = 0.5,
	Captured = 0.9,
	CaptureFail = 0.9,
} :: { [string]: number }

-- Moments that change real part sizes (need restore at the end).
Poses.Scales = { Pop = true, Hatch = true, Captured = true } :: { [string]: boolean }

function Poses.Eval(name: string, p: number, o: Pose)
	o.dy, o.yaw, o.tiltX, o.tiltZ, o.sxz, o.sy, o.uni, o.head = 0, 0, 0, 0, 1, 1, 1, 0
	if name == "Hop" then
		o.dy, o.sxz, o.sy = jump(p, 0.2, 0.8, 1)
	elseif name == "Happy" then
		local k = if p < 0.5 then 0 else 1
		local q = (p - k * 0.5) * 2
		o.dy, o.sxz, o.sy = jump(q, 0.2, 0.8, 1.1)
		o.tiltZ = (if k == 0 then 0.14 else -0.14) * sin(PI * q)
		o.tiltX = 0.1 * sin(PI * q)
	elseif name == "Spin" then
		o.yaw = 2 * PI * smooth(p)
		o.dy = 0.4 * sin(PI * p)
	elseif name == "Wiggle" or name == "Pet" then
		local k = 1 - p
		o.tiltZ = 0.2 * sin(p * 6 * PI) * k
		o.sxz = 1 + 0.06 * sin(p * 12 * PI) * k
		o.sy = 1 - 0.06 * sin(p * 12 * PI) * k
		o.head = -0.15 * sin(PI * p)
	elseif name == "Look" then
		o.yaw = 0.7 * sin(p * 2 * PI)
	elseif name == "Sniff" then
		o.head = 0.45 * sin(PI * p) + 0.06 * sin(p * 10 * PI) * sin(PI * p)
		o.tiltX = -0.05 * sin(PI * p)
	elseif name == "Stretch" then
		local s = sin(PI * p)
		o.tiltX = -0.12 * s
		o.sy, o.sxz = 1 + 0.1 * s, 1 - 0.05 * s
		o.head = -0.3 * s
	elseif name == "Eat" then
		o.head = 0.5 * smooth(p * 4) * smooth((1 - p) * 4) + 0.12 * sin(p * 12 * PI)
	elseif name == "Feed" then
		if p < 0.55 then
			local q = p / 0.55
			o.head = 0.5 * smooth(q * 4) * smooth((1 - q) * 4) + 0.12 * sin(q * 10 * PI)
		else
			local q = (p - 0.55) / 0.45
			o.yaw = 2 * PI * smooth(q)
			o.dy, o.sxz, o.sy = jump(q, 0.15, 0.85, 0.8)
		end
	elseif name == "Sad" then
		o.head = 0.35 * sin(PI * p)
		o.sy = 1 - 0.06 * sin(PI * p)
	elseif name == "Pop" then
		o.uni = math.max(0.05, backOut(p))
	elseif name == "Hatch" then
		if p < 0.35 then
			o.uni = math.max(0.05, backOut(p / 0.35))
		else
			local q = (p - 0.35) / 0.65
			o.dy, o.sxz, o.sy = jump(q, 0.15, 0.75, 2)
			o.yaw = if q > 0.15 and q < 0.75 then 2 * PI * smooth((q - 0.15) / 0.6) else 0
		end
	elseif name == "Celebrate" or name == "Discover" then
		o.dy, o.sxz, o.sy = jump(p, 0.15, 0.75, if name == "Discover" then 1.6 else 2.4)
		o.yaw = if p > 0.15 and p < 0.75 then 2 * PI * smooth((p - 0.15) / 0.6) else 0
		o.tiltX = if p > 0.15 and p < 0.75 then 0.15 * sin(PI * (p - 0.15) / 0.6) else 0
	elseif name == "Thud" then
		local fall = 0.45
		if p < fall then
			local q = p / fall
			o.dy = Tuning.ThudDrop * (1 - q * q)
			o.sy, o.sxz = 1.1, 0.95
		else
			local q = (p - fall) / (1 - fall)
			local k = sin(PI * q) * (1 - q)
			o.sy, o.sxz = 1 - 0.3 * k, 1 + 0.2 * k
		end
	elseif name == "Captured" then
		o.uni = math.max(0.02, 1 - smooth(p * 1.2))
		o.dy = 1.2 * smooth(p)
		o.yaw = 3 * PI * smooth(p)
	elseif name == "CaptureFail" then
		local k = 1 - p
		o.tiltZ = 0.3 * sin(p * 8 * PI) * k
		if p > 0.5 then
			o.dy, o.sxz, o.sy = jump((p - 0.5) * 2, 0.2, 0.8, 1.2)
		end
	end
end

return Poses
