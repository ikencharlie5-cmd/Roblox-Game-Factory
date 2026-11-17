--!strict
-- Signature head/back features per species (the "plant" half of each plant-creature).
-- Signature: (add, head: CFrame, r: number, body: Color3, accent: Color3).
local Kinds = require(script.Parent.Kinds)
type Add = Kinds.Add

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad
local hex = Color3.fromHex

local GREEN = hex("#8BD65A")
local LEAF = hex("#4CAF50")
local BARK = hex("#8B5A2B")
local PINK = hex("#FF8FB8")
local WHITE = Color3.new(1, 1, 1)
local NEON = Enum.Material.Neon

-- Petals around center's local Z axis (center's XY plane).
local function ring(add: Add, center: CFrame, radius: number, n: number, size: Vector3, color: Color3, mat: Enum.Material?)
	for i = 0, n - 1 do
		add("blob", size, center * A(0, 0, rad(i * 360 / n)) * C(0, radius, 0), color, { mat = mat })
	end
end

-- Same ring but lying flat (petals around Y).
local function flatRing(add: Add, center: CFrame, radius: number, n: number, size: Vector3, color: Color3, tilt: number, mat: Enum.Material?)
	for i = 0, n - 1 do
		add("blob", size, center * A(0, rad(i * 360 / n), 0) * C(0, 0, -radius) * A(rad(tilt), 0, 0), color, { mat = mat })
	end
end

local function leafPair(add: Add, at: CFrame, color: Color3, len: number)
	add("cyl", V(0.25, 0.7, 0.25), at * C(0, 0.35, 0), LEAF)
	add("blob", V(len, 0.15, len * 0.5), at * C(-len * 0.4, 0.7, 0) * A(0, 0, rad(25)), color)
	add("blob", V(len, 0.15, len * 0.5), at * C(len * 0.4, 0.7, 0) * A(0, 0, rad(-25)), color)
end

local Tops: { [string]: (Add, CFrame, number, Color3, Color3) -> () } = {}

Tops.sprout = function(add, head, r, _b, a)
	leafPair(add, head * C(0, r - 0.1, 0), GREEN, 1.3)
	add("ball", V(0.5, 0.5, 0.5), head * C(0, r + 0.75, 0), a)
end

Tops.pebbles = function(add, head, r, _b, a)
	add("ball", V(0.8, 0.8, 0.8), head * C(-0.5, r - 0.15, 0.3), a, { mat = Enum.Material.Slate })
	add("ball", V(0.6, 0.6, 0.6), head * C(0.5, r - 0.2, 0.5), a, { mat = Enum.Material.Slate })
	leafPair(add, head * C(0.1, r - 0.15, -0.2), GREEN, 0.9)
end

Tops.lily = function(add, head, r, _b, _a)
	add("cyl", V(2, 0.15, 2), head * C(0, r - 0.05, 0.2), hex("#5FBF6A"))
	add("ball", V(0.7, 0.7, 0.7), head * C(0.3, r + 0.3, 0.2), PINK)
end

Tops.spikes = function(add, head, r, _b, a)
	for i = 0, 5 do
		local cf = head * A(rad(-60 + (i % 3) * 40), 0, rad(-30 + (i // 3) * 60)) * C(0, r, 0)
		add("block", V(0.18, 0.7, 0.18), cf, a)
	end
	add("ball", V(0.7, 0.7, 0.7), head * C(0, r + 0.2, 0), PINK)
end

Tops.shroom = function(add, head, r, _b, a)
	add("cyl", V(0.5, 0.6, 0.5), head * C(0, r + 0.1, 0), hex("#FFF6E0"))
	add("blob", V(2, 0.9, 2), head * C(0, r + 0.5, 0), a)
	add("ball", V(0.35, 0.35, 0.35), head * C(0.4, r + 0.9, -0.3), WHITE, { mat = NEON })
	for _, x in { -1, 1 } do
		add("ball", V(0.8, 0.8, 0.3), head * C(x * 0.9, r * 0.6, 0.1), a)
	end
end

Tops.bunnyears = function(add, head, r, b, a)
	for _, x in { -1, 1 } do
		local cf = head * C(x * 0.45, r + 0.7, 0.1) * A(0, 0, rad(-x * 10))
		add("blob", V(0.55, 1.9, 0.35), cf, b)
		add("blob", V(0.3, 1.4, 0.1), cf * C(0, 0, -0.15), a)
	end
	add("ball", V(0.5, 0.5, 0.5), head * C(0, r + 0.05, -0.3), WHITE, { mat = NEON })
end

Tops.mane = function(add, head, r, _b, a)
	ring(add, head * C(0, 0, 0.35), r * 1.05, 10, V(0.9, 1.3, 0.45), a)
end

Tops.fins = function(add, head, r, _b, a)
	for i = 0, 2 do
		add("blob", V(0.2, 0.9, 0.9), head * C(0, r - 0.1, 0.2 + i * 0.6) * A(rad(-20), 0, 0), a)
	end
end

Tops.leafears = function(add, head, r, _b, a)
	for _, x in { -1, 1 } do
		add("blob", V(1.5, 0.2, 0.9), head * C(x * (r + 0.4), 0.3, 0) * A(0, 0, rad(x * 30)), a)
	end
	add("cyl", V(0.25, 1.6, 0.25), CFrame.new(0, 1.8, 1.2) * A(rad(40), 0, 0), LEAF)
	add("blob", V(0.9, 0.15, 0.5), CFrame.new(0, 2.6, 1.9), GREEN)
end

Tops.twigs = function(add, head, r, _b, a)
	for i = 0, 6 do
		local cf = head * A(rad(-70 + i * 23), rad(i * 51), 0) * C(0, r, 0)
		add("block", V(0.15, 1.1, 0.15), cf, a)
	end
end

Tops.puffs = function(add, head, r, _b, a)
	for i = 0, 3 do
		add("ball", V(0.55, 0.55, 0.55), head * A(rad(-40 + i * 25), rad(i * 90), 0) * C(0, r, 0), a)
	end
end

Tops.sunpetals = function(add, head, r, _b, a)
	ring(add, head * C(0, 0, 0.2), r * 1.1, 12, V(0.7, 1.1, 0.25), a)
	add("blob", V(0.5, 0.4, 0.4), head * C(-0.5, r + 0.1, 0) * A(0, 0, rad(20)), hex("#5E3B1E"))
	add("blob", V(0.5, 0.4, 0.4), head * C(0.5, r + 0.1, 0) * A(0, 0, rad(-20)), hex("#5E3B1E"))
end

Tops.lotus = function(add, _head, _r, _b, a)
	local top = C(0, 3.05, 0.2)
	flatRing(add, top, 0.6, 6, V(0.6, 0.25, 1), a, -35)
	add("ball", V(0.6, 0.6, 0.6), top * C(0, 0.15, 0), hex("#FFD54F"), { mat = NEON })
end

Tops.humps = function(add, _head, _r, b, a)
	add("blob", V(1.3, 1.7, 1.3), C(0, 3.3, -0.1), b)
	add("blob", V(1.1, 1.4, 1.1), C(0, 3.1, 1.1), b)
	add("ball", V(0.6, 0.6, 0.6), C(0, 4.2, -0.1), a)
end

Tops.fern = function(add, head, r, b, a)
	for _, x in { -1, 1 } do
		add("wedge", V(0.3, 1, 0.8), head * C(x * 0.6, r + 0.3, 0), b)
	end
	for i = -1, 1 do
		add("blob", V(0.5, 0.2, 2), C(i * 0.5, 2.8, 2.6) * A(rad(30), rad(i * 25), 0), a)
	end
end

Tops.glowcap = function(add, head, r, _b, a)
	for _, x in { -1, 1 } do
		add("cyl", V(0.15, 0.8, 0.15), head * C(x * 0.3, r + 0.35, 0), hex("#D8C29A"))
		add("ball", V(0.35, 0.35, 0.35), head * C(x * 0.3, r + 0.8, 0), a, { mat = NEON })
	end
end

Tops.orchid = function(add, head, r, _b, a)
	for i = -1, 1 do
		add("blob", V(0.5, 1.4, 0.3), head * C(i * 0.35, r + 0.4, 0.3) * A(rad(-30), 0, rad(-i * 25)), a)
	end
	add("ball", V(0.5, 0.5, 0.5), head * C(0, r + 0.1, -0.1), PINK)
	for i = -1, 1 do
		add("blob", V(0.4, 0.2, 1.8), C(i * 0.3, 1.2, 1.6) * A(rad(30), rad(i * 15), 0), a)
	end
end

Tops.traps = function(add, _head, _r, _b, a)
	add("blob", V(1.6, 0.4, 2), C(0, 1.8, -2.4), a)
	for _, x in { -0.5, 0, 0.5 } do
		add("wedge", V(0.2, 0.3, 0.2), C(x, 1.55, -3.2) * A(math.pi, 0, 0), WHITE)
	end
	add("ball", V(0.8, 0.8, 0.8), C(0, 2.4, -0.4), PINK)
end

Tops.mothwings = function(add, head, r, _b, a)
	for _, x in { -1, 1 } do
		add("blob", V(0.2, 3, 2.4), C(x * 1.9, 2.8, 0.5) * A(0, rad(x * 20), rad(-x * 25)), a, { transparency = 0.25, mat = Enum.Material.Glass })
		add("cyl", V(0.1, 1, 0.1), head * C(x * 0.35, r + 0.4, 0) * A(0, 0, rad(-x * 20)), hex("#5E3B1E"))
		add("ball", V(0.3, 0.3, 0.3), head * C(x * 0.55, r + 0.9, 0), a, { mat = NEON })
	end
end

Tops.pinecone = function(add, head, r, _b, a)
	for _, x in { -1, 1 } do
		add("ball", V(0.8, 0.8, 0.5), head * C(x * 0.9, r * 0.75, 0), a)
	end
	for i = 0, 2 do
		add("blob", V(1.4 - i * 0.35, 0.5, 1.4 - i * 0.35), head * C(0, r + i * 0.35, 0), a)
	end
	add("blob", V(0.6, 0.15, 0.3), head * C(0, r + 1.1, 0), GREEN)
end

Tops.antlers = function(add, head, r, _b, a)
	for _, x in { -1, 1 } do
		local base = head * C(x * 0.5, r, 0.1) * A(0, 0, rad(-x * 25))
		add("block", V(0.25, 1.8, 0.25), base * C(0, 0.9, 0), a)
		add("block", V(0.2, 0.9, 0.2), base * C(0, 1, 0) * A(0, 0, rad(-x * 45)) * C(0, 0.4, 0), a)
		add("ball", V(0.6, 0.6, 0.6), base * C(0, 1.9, 0), PINK)
		add("ball", V(0.45, 0.45, 0.45), base * C(-x * 0.7, 1.5, 0), WHITE)
	end
end

Tops.bonsai = function(add, head, r, _b, a)
	add("cyl", V(0.35, 1, 0.35), head * C(0, r + 0.3, 0.1), BARK)
	add("blob", V(1.8, 0.5, 1.4), head * C(-0.3, r + 0.9, 0.1), LEAF)
	add("blob", V(1.1, 0.4, 0.9), head * C(0.5, r + 1.3, 0.1), GREEN)
	for _, x in { -1, 1 } do
		add("block", V(0.2, 0.9, 0.2), head * C(x * 0.7, r - 0.1, 0.3) * A(rad(-30), 0, rad(-x * 30)), a, { mat = NEON })
	end
end

Tops.stinger = function(add, _head, _r, b, a)
	local pts = { V(0, 1.3, 1.9), V(0, 2.1, 2.5), V(0, 3, 2.4), V(0, 3.6, 1.7) }
	for i, p in pts do
		add("ball", V(1.1 - i * 0.1, 1.1 - i * 0.1, 1.1 - i * 0.1), CFrame.new(p), b)
	end
	add("wedge", V(0.4, 0.6, 0.8), C(0, 3.5, 1) * A(rad(200), 0, 0), a, { mat = NEON })
end

Tops.icecrown = function(add, head, r, _b, a)
	for i = 0, 4 do
		add("block", V(0.4, 1.1 + (i % 2) * 0.5, 0.4), head * A(0, rad(i * 72), 0) * C(0, r - 0.1, -0.6) * A(rad(-15), 0, 0), a, { mat = Enum.Material.Ice })
	end
end

Tops.flame = function(add, head, r, _b, a)
	for i = -1, 1 do
		add("blob", V(0.5, 1.6, 0.4), head * C(i * 0.35, r + 0.5, 0.2) * A(rad(-20), 0, rad(-i * 20)), a, { mat = NEON })
	end
	for i = -1, 1 do
		add("blob", V(0.5, 0.25, 2.2), C(i * 0.45, 1.6, 1.8) * A(rad(20), rad(i * 20), 0), if i == 0 then a else hex("#FF3D2B"), { mat = NEON })
	end
end

Tops.horn = function(add, head, r, _b, a)
	for i = 0, 2 do
		local d = 0.55 - i * 0.15
		add("ball", V(d, d, d), head * C(0, r + 0.1 + i * 0.4, -0.5 - i * 0.12), hex("#FFE9A8"), { mat = NEON })
	end
	for i = 0, 3 do
		add("blob", V(0.5, 1, 0.8), head * C(0, r - 0.2 - i * 0.5, 0.8 + i * 0.3), a)
	end
end

Tops.worldtree = function(add, _head, _r, _b, a)
	add("cyl", V(0.8, 2.6, 0.8), C(0, 4, 0.2), BARK)
	add("ball", V(3, 3, 3), C(0, 5.8, 0.2), a)
	add("ball", V(2.2, 2.2, 2.2), C(1.2, 5.2, 0.6), GREEN)
	add("ball", V(2, 2, 2), C(-1.1, 5.3, -0.3), LEAF)
	add("ball", V(0.5, 0.5, 0.5), C(0.8, 6.5, -1), hex("#FFD54F"), { mat = NEON })
	add("ball", V(0.5, 0.5, 0.5), C(-0.7, 5, 1.3), hex("#FFD54F"), { mat = NEON })
end

Tops.abyssbloom = function(add, head, r, _b, a)
	local top = head * C(0, r + 0.6, 0.2)
	flatRing(add, top, 0.7, 6, V(0.7, 0.25, 1.3), a, -40, NEON)
	add("ball", V(0.7, 0.7, 0.7), top * C(0, 0.2, 0), hex("#7CF7FF"), { mat = NEON })
end

return Tops
