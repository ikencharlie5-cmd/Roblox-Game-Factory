--!strict
-- Body archetypes. Offsets are from the creature's feet-center; front = -Z.
-- Each returns headCF (head center) and headR (head radius) so the face + Top can attach.
export type AddOpts = { skin: boolean?, mat: Enum.Material?, transparency: number? }
export type Add = (shape: string, size: Vector3, offset: CFrame, color: Color3, opts: AddOpts?) -> BasePart

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad

local Kinds = {}

local function legs4(add: Add, col: Color3, h: number, front: number, back: number, spread: number)
	for _, z in { front, back } do
		for _, x in { -spread, spread } do
			add("cyl", V(0.75, h, 0.75), C(x, h / 2, z), col)
		end
	end
end

function Kinds.quad(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.4, 2, 3.2), C(0, 2, 0.3), b)
	legs4(add, b, 1.3, -0.6, 1.2, 0.8)
	add("ball", V(0.9, 0.9, 0.9), C(0, 2.5, 2), a)
	add("blob", V(1.4, 1.2, 0.4), C(0, 1.8, -1.2), a)
	local head = C(0, 3.3, -1.4)
	add("blob", V(2.6, 2.3, 2.3), head, b)
	add("blob", V(1.2, 0.8, 0.8), head * C(0, -0.5, -1), a)
	return head, 1.15
end

function Kinds.blob(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(3.2, 3, 3.2), C(0, 1.5, 0), b)
	add("blob", V(1, 0.5, 1.3), C(-0.8, 0.25, -0.7), a)
	add("blob", V(1, 0.5, 1.3), C(0.8, 0.25, -0.7), a)
	add("blob", V(0.6, 1.1, 0.6), C(-1.6, 1.3, 0) * A(0, 0, rad(25)), b)
	add("blob", V(0.6, 1.1, 0.6), C(1.6, 1.3, 0) * A(0, 0, rad(-25)), b)
	return C(0, 1.7, 0), 1.6
end

function Kinds.biped(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.4, 2.6, 2), C(0, 2.2, 0), b)
	add("blob", V(1.6, 1.8, 0.4), C(0, 2.1, -0.9), a)
	add("cyl", V(0.8, 1.2, 0.8), C(-0.6, 0.6, 0), b)
	add("cyl", V(0.8, 1.2, 0.8), C(0.6, 0.6, 0), b)
	add("blob", V(0.7, 1.8, 0.7), C(-1.4, 2.3, 0) * A(0, 0, rad(-20)), b)
	add("blob", V(0.7, 1.8, 0.7), C(1.4, 2.3, 0) * A(0, 0, rad(20)), b)
	local head = C(0, 4.3, -0.1)
	add("ball", V(2.6, 2.6, 2.6), head, b)
	add("blob", V(1.4, 0.9, 0.6), head * C(0, -0.45, -1.1), a)
	return head, 1.3
end

function Kinds.fish(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.2, 2.4, 3.2), C(0, 2, 0), b)
	add("blob", V(0.3, 1.8, 1.4), C(0, 2.1, 2) * A(rad(20), 0, 0), a)
	add("blob", V(0.2, 0.7, 1.1), C(-1.1, 1.7, 0.2) * A(0, 0, rad(30)), a)
	add("blob", V(0.2, 0.7, 1.1), C(1.1, 1.7, 0.2) * A(0, 0, rad(-30)), a)
	add("blob", V(0.2, 0.9, 1.2), C(0, 3.2, 0.3), a)
	return C(0, 2.2, -0.5), 1.1
end

function Kinds.bird(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.4, 2.8, 2.4), C(0, 1.9, 0), b)
	add("blob", V(1.6, 1.8, 0.5), C(0, 1.7, -1), a)
	add("blob", V(0.4, 1.8, 1.6), C(-1.3, 2, 0.2) * A(0, 0, rad(15)), b)
	add("blob", V(0.4, 1.8, 1.6), C(1.3, 2, 0.2) * A(0, 0, rad(-15)), b)
	add("block", V(0.25, 0.5, 0.8), C(-0.5, 0.25, -0.2), Color3.fromHex("#FF9E3D"))
	add("block", V(0.25, 0.5, 0.8), C(0.5, 0.25, -0.2), Color3.fromHex("#FF9E3D"))
	local head = C(0, 3.4, -0.2)
	add("ball", V(2.2, 2.2, 2.2), head, b)
	add("wedge", V(0.5, 0.5, 0.7), head * C(0, -0.25, -1.25) * A(0, math.pi, 0), Color3.fromHex("#FF9E3D"))
	return head, 1.1
end

function Kinds.serpent(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("ball", V(1.1, 1.1, 1.1), C(0, 0.55, 2.2), b)
	add("ball", V(1.4, 1.4, 1.4), C(0.6, 0.7, 1.2), a)
	add("ball", V(1.6, 1.6, 1.6), C(0, 0.9, 0.1), b)
	add("ball", V(1.6, 1.6, 1.6), C(-0.3, 1.6, -0.6), a)
	local head = C(0, 2.7, -0.9)
	add("blob", V(2.2, 2, 2.4), head, b)
	add("blob", V(1.3, 0.7, 1), head * C(0, -0.45, -1.1), a)
	return head, 1.05
end

function Kinds.turtle(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.6, 1, 3), C(0, 0.9, 0), b)
	legs4(add, b, 0.8, -1, 1, 1.1)
	add("blob", V(3.6, 2.2, 3.8), C(0, 1.7, 0.2), b:Lerp(Color3.new(0.2, 0.15, 0.05), 0.35))
	add("blob", V(2.4, 0.5, 2.6), C(0, 2.75, 0.2), a)
	local head = C(0, 1.8, -2.1)
	add("ball", V(1.8, 1.8, 1.8), head, b)
	return head, 0.9
end

function Kinds.snail(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(1.8, 0.8, 4), C(0, 0.4, 0), b)
	add("blob", V(1.3, 2, 1.3), C(0, 1.3, -1.4), b)
	add("ball", V(2.8, 2.8, 2.8), C(0, 2, 0.7), a)
	add("blob", V(1.6, 1.6, 0.6), C(0, 2, 2.1), a:Lerp(Color3.new(1, 1, 1), 0.4))
	return C(0, 2, -1.45), 0.75
end

function Kinds.scorpion(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.6, 1.2, 3), C(0, 0.9, 0.2), b)
	for i = -1, 1 do
		for _, x in { -1, 1 } do
			add("block", V(1.2, 0.25, 0.25), C(x * 1.5, 0.45, i * 0.8) * A(0, 0, rad(x * 30)), a)
		end
	end
	add("blob", V(0.9, 0.6, 1.3), C(-1.3, 0.9, -1.9), a)
	add("blob", V(0.9, 0.6, 1.3), C(1.3, 0.9, -1.9), a)
	local head = C(0, 1.5, -1.2)
	add("blob", V(1.8, 1.4, 1.4), head, b)
	return head, 0.85
end

function Kinds.frog(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(3, 2, 2.8), C(0, 1, 0), b)
	add("blob", V(2, 1.2, 0.6), C(0, 0.8, -1.2), a:Lerp(Color3.new(1, 1, 1), 0.5))
	add("blob", V(1, 0.6, 1.8), C(-1.4, 0.3, 0.4), b)
	add("blob", V(1, 0.6, 1.8), C(1.4, 0.3, 0.4), b)
	add("ball", V(1.1, 1.1, 1.1), C(-0.7, 2.1, -0.6), b)
	add("ball", V(1.1, 1.1, 1.1), C(0.7, 2.1, -0.6), b)
	return C(0, 1.6, -0.3), 1.3
end

function Kinds.croc(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(2.2, 1.4, 4), C(0, 1, 0.5), b)
	legs4(add, b, 0.7, -0.6, 1.6, 1)
	add("blob", V(0.9, 0.7, 2.4), C(0, 0.8, 3) * A(rad(-8), 0, 0), b)
	add("blob", V(1.7, 0.9, 2.2), C(0, 1.2, -2.3), b)
	for i = 0, 3 do
		add("block", V(0.4, 0.4, 0.4), C(0, 1.75, 1.6 - i * 0.8) * A(0, 0, rad(45)), a)
	end
	return C(0, 1.7, -1.3), 0.9
end

function Kinds.kraken(add: Add, b: Color3, a: Color3): (CFrame, number)
	add("blob", V(3.2, 3.4, 3.2), C(0, 3, 0.2), b)
	for i = 0, 5 do
		local ang = rad(i * 60 + 30)
		local dir = Vector3.new(math.sin(ang), 0, math.cos(ang))
		local p = dir * 1.6 + Vector3.new(0, 0.7, 0)
		local cf = CFrame.lookAt(p, p + dir + Vector3.new(0, -0.6, 0))
		add("blob", V(0.7, 0.7, 2.6), cf, b)
		add("ball", V(0.5, 0.5, 0.5), cf * C(0, 0.3, -0.6), a, { mat = Enum.Material.Neon })
	end
	return C(0, 2.6, -0.2), 1.5
end

return Kinds
