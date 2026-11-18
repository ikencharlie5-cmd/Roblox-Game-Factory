--!strict
-- Builds a procedural "rig" from a code-built creature Model (no Humanoid, no Motor6D).
-- Every part is assigned a bone from its `Anim` attribute (Body, Head, Neck, EarL/EarR/Ear, Tail,
-- LegFL/LegFR/LegBL/LegBR/Leg, Wing/WingL/WingR, Eye), else its name, else its Role (Eye/Cheek -> Head),
-- else the nearest tagged part. Rest offsets are stored relative to the creature's root frame
-- (Hitbox position + yaw; CreatureBuilder also stamps each part's `Rest` attribute in that frame), and
-- joint pivots are derived from the part bounds (HeadPivot attribute used for the neck when present).
local Rig = {}

Rig.BODY, Rig.HEAD, Rig.EARL, Rig.EARR, Rig.TAIL = 1, 2, 3, 4, 5
Rig.LFL, Rig.LFR, Rig.LBL, Rig.LBR, Rig.WINGL, Rig.WINGR = 6, 7, 8, 9, 10, 11
Rig.BONES = 11

export type Eye = { part: BasePart, mesh: SpecialMesh?, scale: Vector3, size: Vector3, ball: boolean }

export type Rig = {
	parts: { BasePart },
	rest: { CFrame },
	sizes: { Vector3 },
	bone: { number },
	restOf: { [BasePart]: CFrame },
	has: { [number]: boolean },
	pivP: { CFrame },
	pivN: { CFrame },
	eyes: { Eye },
	shines: { BasePart },
	lights: { Light },
	lightBase: { number },
	emitters: { ParticleEmitter },
	groundY: number,
	top: number,
	count: number,
}

local NAMES: { [string]: number } = {
	body = 1,
	torso = 1,
	head = 2,
	neck = 2,
	eye = 2,
	earl = 3,
	earr = 4,
	tail = 5,
	legfl = 6,
	legfr = 7,
	legbl = 8,
	legbr = 9,
	wingl = 10,
	wingr = 11,
}

local HEAD_ROLES = { Eye = true, EyeShine = true, Cheek = true, Mouth = true, Nose = true }

local function halfY(cf: CFrame, s: Vector3): number
	return 0.5 * (math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z)
end

local function halfX(cf: CFrame, s: Vector3): number
	return 0.5 * (math.abs(cf.XVector.X) * s.X + math.abs(cf.YVector.X) * s.Y + math.abs(cf.ZVector.X) * s.Z)
end

-- Bone from a label like "EarL", "Leg", "Wing" (side/quadrant from the rest position).
local function fromLabel(label: string, pos: Vector3, center: Vector3): number?
	local l = string.lower(label)
	local direct = NAMES[l]
	if direct then
		return direct
	end
	local left = pos.X < center.X
	local front = pos.Z < center.Z -- models face -Z
	if string.find(l, "ear") then
		return if left then Rig.EARL else Rig.EARR
	elseif string.find(l, "wing") then
		return if left then Rig.WINGL else Rig.WINGR
	elseif string.find(l, "leg") or string.find(l, "foot") or string.find(l, "paw") then
		if front then
			return if left then Rig.LFL else Rig.LFR
		end
		return if left then Rig.LBL else Rig.LBR
	elseif string.find(l, "tail") then
		return Rig.TAIL
	elseif string.find(l, "head") or string.find(l, "eye") or string.find(l, "snout") or string.find(l, "neck") then
		return Rig.HEAD
	elseif string.find(l, "body") or string.find(l, "belly") then
		return Rig.BODY
	end
	return nil
end

local function isEye(p: BasePart): boolean
	local role = p:GetAttribute("Role")
	if role == "Eye" or p:GetAttribute("Anim") == "Eye" then
		return true
	end
	local n = string.lower(p.Name)
	return role == nil and string.find(n, "eye") ~= nil and string.find(n, "shine") == nil
end

local function isShine(p: BasePart): boolean
	if p:GetAttribute("Role") == "EyeShine" then
		return true
	end
	local n = string.lower(p.Name)
	return string.find(n, "shine") ~= nil or string.find(n, "highlight") ~= nil
end

-- root: the creature's root frame; hitbox is excluded; known: rest offsets of parts already rigged
-- (so a rebuild never reads back animated CFrames).
function Rig.Build(model: Model, root: CFrame, hitbox: BasePart, known: { [BasePart]: CFrame }?): Rig
	local parts, rest, sizes = {}, {}, {}
	local rig: Rig = {
		parts = parts,
		rest = rest,
		sizes = sizes,
		bone = {},
		restOf = {},
		has = {},
		pivP = {},
		pivN = {},
		eyes = {},
		shines = {},
		lights = {},
		lightBase = {},
		emitters = {},
		groundY = 0,
		top = 0,
		count = 0,
	}
	local sum, n = Vector3.zero, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d == hitbox or d:GetAttribute("NoAnim") or d.Name == "Hitbox" then
				continue
			end
			-- prefer offsets we already use, then the builder's `Rest` attribute, then the live CFrame
			local attr = d:GetAttribute("Rest")
			local r = (known and known[d]) or (if typeof(attr) == "CFrame" then attr else root:ToObjectSpace(d.CFrame))
			table.insert(parts, d)
			table.insert(rest, r)
			table.insert(sizes, d.Size)
			rig.restOf[d] = r
			sum += r.Position
			n += 1
		elseif d:IsA("Light") then
			table.insert(rig.lights, d)
			table.insert(rig.lightBase, d.Brightness)
		elseif d:IsA("ParticleEmitter") then
			table.insert(rig.emitters, d)
		end
	end
	rig.count = n
	if n == 0 then
		return rig
	end
	local center = sum / n

	-- 1) tagged bones
	local tagged: { [number]: number } = {}
	for i, p in parts do
		local label = p:GetAttribute("Anim")
		local b = if typeof(label) == "string" then fromLabel(label, rest[i].Position, center) else nil
		if not b then
			local role = p:GetAttribute("Role")
			if typeof(role) == "string" and HEAD_ROLES[role] then
				b = nil -- decided after we know whether a head exists
			else
				b = fromLabel(p.Name, rest[i].Position, center)
			end
		end
		if b then
			rig.bone[i] = b
			tagged[i] = b
			rig.has[b] = true
		end
	end
	-- 2) untagged: face roles -> head, else nearest tagged part, else body
	for i, p in parts do
		if rig.bone[i] then
			continue
		end
		local role = p:GetAttribute("Role")
		if typeof(role) == "string" and HEAD_ROLES[role] and rig.has[Rig.HEAD] then
			rig.bone[i] = Rig.HEAD
			continue
		end
		local best, bestD = Rig.BODY, math.huge
		local pos = rest[i].Position
		for j, b in tagged do
			local dd = (rest[j].Position - pos).Magnitude
			if dd < bestD then
				best, bestD = b, dd
			end
		end
		rig.bone[i] = best
	end
	rig.has[Rig.BODY] = true

	-- 3) bounds and pivots
	local ground, top = math.huge, -math.huge
	local bodySum, bodyN = Vector3.zero, 0
	local biggest: { [number]: number } = {}
	local bigVol: { [number]: number } = {}
	for i, p in parts do
		local hy = halfY(rest[i], sizes[i])
		ground = math.min(ground, rest[i].Y - hy)
		top = math.max(top, rest[i].Y + hy)
		local b = rig.bone[i]
		if b == Rig.BODY then
			bodySum += rest[i].Position
			bodyN += 1
		end
		local v = sizes[i].X * sizes[i].Y * sizes[i].Z
		if v > (bigVol[b] or 0) then
			bigVol[b], biggest[b] = v, i
		end
		if isEye(p) then
			local mesh = p:FindFirstChildOfClass("SpecialMesh")
			local ball = p:IsA("Part") and p.Shape == Enum.PartType.Ball and not mesh
			table.insert(
				rig.eyes,
				{ part = p, mesh = mesh, scale = if mesh then mesh.Scale else Vector3.one, size = p.Size, ball = ball }
			)
		elseif isShine(p) then
			table.insert(rig.shines, p)
		end
	end
	rig.groundY, rig.top = ground, top
	local bc = if bodyN > 0 then bodySum / bodyN else center
	for b = 1, Rig.BONES do
		local pivot = Vector3.new(bc.X, ground, bc.Z)
		local i = biggest[b]
		if i and b ~= Rig.BODY then
			local cf, s = rest[i], sizes[i]
			local c = cf.Position
			if b == Rig.HEAD then
				local hp = model:GetAttribute("HeadPivot")
				pivot = if typeof(hp) == "Vector3" then hp else c:Lerp(bc, 0.4)
			elseif b == Rig.EARL or b == Rig.EARR then
				pivot = c - Vector3.new(0, halfY(cf, s) * 0.85, 0)
			elseif b == Rig.TAIL then
				-- the tail part closest to the body is the root of the wag
				local bestD = math.huge
				for j = 1, #parts do
					if rig.bone[j] == Rig.TAIL then
						local d = (rest[j].Position - bc).Magnitude
						if d < bestD then
							bestD, pivot = d, rest[j].Position:Lerp(bc, 0.15)
						end
					end
				end
			elseif b >= Rig.LFL and b <= Rig.LBR then
				pivot = c + Vector3.new(0, halfY(cf, s) * 0.8, 0)
			elseif b == Rig.WINGL or b == Rig.WINGR then
				local sx = if c.X < bc.X then -1 else 1
				pivot = c - Vector3.new(sx * halfX(cf, s) * 0.8, 0, 0)
			end
		end
		rig.pivP[b] = CFrame.new(pivot)
		rig.pivN[b] = CFrame.new(-pivot)
	end
	return rig
end

-- Uniform rescale of rest offsets (server ScaleTo, e.g. Baby -> Adult).
function Rig.Rescale(rig: Rig, k: number)
	for i, r in rig.rest do
		local nr = r - r.Position + r.Position * k
		rig.rest[i] = nr
		rig.restOf[rig.parts[i]] = nr
		rig.sizes[i] *= k
	end
	for b = 1, Rig.BONES do
		local p = rig.pivP[b].Position * k
		rig.pivP[b], rig.pivN[b] = CFrame.new(p), CFrame.new(-p)
	end
	rig.groundY *= k
	rig.top *= k
	for _, e in rig.eyes do
		e.size *= k
	end
end

return Rig
