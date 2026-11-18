--!strict
-- Blueprint vocabulary shared by every species file, brick-figure style (STUDS_STYLE_GUIDE §4).
-- Coordinates are adult scale, studs, relative to the ground point under the creature's centre; the
-- creature faces -Z (Roblox LookVector). X/Z sizes are whole studs, Y sizes are 0.4 plates / 1.2 bricks.
local Shapes = {}

export type Role = string -- Primary | Secondary | Belly | Accent | Feature | Glow | Eye | EyeShine | Cheek | Nose
export type Studs = "All" | "Top" | "None"
export type PartSpec = {
	Name: string,
	Shape: "Brick" | "Wedge" | "Tile",
	Size: Vector3,
	CF: CFrame,
	Role: Role,
	Anim: string, -- Body | Head | LegFL | LegFR | LegBL | LegBR | Tail | EarL | EarR
	Studs: Studs?, -- Brick: default "All" (studs on 5 faces, inlet below)
	Layer: number?, -- slab layer index; even layers are shaded ×0.95 (brick seams)
	Pattern: boolean?, -- only built when the Pattern gene is pp (spots)
	Shadow: boolean?, -- CastShadow (body + head only)
	Transparency: number?,
}
export type Shard = { CF: CFrame, Len: number, Anim: string }
export type Blueprint = {
	Species: string,
	Palette: { [string]: Color3 }, -- Primary/Secondary/Belly/Accent/Feature/Glow
	AltPalette: { [string]: Color3 }, -- Color gene cc
	HeadPivot: Vector3, -- neck point; Baby head scales ×1.25 around it, animator rotates head around it
	Parts: { PartSpec },
	Shards: { Shard }, -- Crystal mutation mount points (crystal brick stacks)
	EmitterPart: string, -- part that hosts the creature's one emitter / light (the hero glow part)
	Native: { Emitter: string?, NightLight: number? }, -- built-in VFX (Emberfox embers, Lumibun ear glow)
}

local V = Vector3.new

local function toCF(cf: CFrame | Vector3): CFrame
	return if typeof(cf) == "Vector3" then CFrame.new(cf) else cf
end

-- Studded Plastic brick (studs on all faces by default).
function Shapes.Brick(name: string, size: Vector3, cf: CFrame | Vector3, role: Role, anim: string, studs: Studs?): PartSpec
	return { Name = name, Shape = "Brick", Size = size, CF = toCF(cf), Role = role, Anim = anim, Studs = studs or "All" }
end

-- Smooth slope brick (ear tips, snouts).
function Shapes.Wedge(name: string, size: Vector3, cf: CFrame | Vector3, role: Role, anim: string): PartSpec
	return { Name = name, Shape = "Wedge", Size = size, CF = toCF(cf), Role = role, Anim = anim }
end

-- Flat SmoothPlastic face tile (eyes, cheeks, nose, belly patch, inner ears).
function Shapes.Tile(name: string, size: Vector3, cf: CFrame | Vector3, role: Role, anim: string): PartSpec
	return { Name = name, Shape = "Tile", Size = size, CF = toCF(cf), Role = role, Anim = anim, Studs = "None" }
end

-- Stacked layers ("slabs") reading as brick seams: heights bottom -> top, starting at y0, centred on
-- (x, z). Even layers get Layer = 2 (×0.95 shade) and a 0.1 inset on X/Z. The first layer keeps `name`
-- (so "Body"/"Head" exist); the rest are name..i. Returns the top y.
function Shapes.Slab(
	list: { PartSpec },
	name: string,
	w: number,
	d: number,
	x: number,
	y0: number,
	z: number,
	heights: { number },
	role: Role,
	anim: string,
	shadow: boolean?
): number
	local y = y0
	for i, h in heights do
		local inset = if i % 2 == 0 and i < #heights then 0.2 else 0
		local spec = Shapes.Brick(if i == 1 then name else name .. i, V(w - inset, h, d - inset), V(x, y + h / 2, z), role, anim)
		spec.Layer = i
		spec.Shadow = shadow
		table.insert(list, spec)
		y += h
	end
	return y
end

-- The standard brick face (§4.2), on the head's front face. headW = 3 or 4 (eye class), headH = head
-- height, bottom = head bottom y, front = z of the head's front face (negative, facing -Z), cx = head x.
-- opts: muzzle size override, nose role, noMuzzle.
function Shapes.BrickFace(
	list: { PartSpec },
	headW: number,
	headH: number,
	bottom: number,
	front: number,
	opts: { Muzzle: Vector3?, NoMuzzle: boolean?, NoseRole: string?, Cx: number? }?
)
	local o = opts or {}
	local cx = o.Cx or 0
	local big = headW >= 4
	local eyeSize = if big then V(0.8, 1.0, 0.1) else V(0.6, 0.8, 0.1)
	local ex = if big then 1.0 else 0.7
	local ey = bottom + headH * 0.55
	local fz = front - 0.05
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "L" else "R"
		local x = cx + side * ex
		table.insert(list, Shapes.Tile("Eye" .. tag, eyeSize, V(x, ey, fz), "Eye", "Head"))
		local hx = x + side * (eyeSize.X / 2 - 0.125)
		local hy = ey + eyeSize.Y / 2 - 0.125
		table.insert(list, Shapes.Tile("Shine" .. tag, V(0.25, 0.25, 0.05), V(hx, hy, fz - 0.08), "EyeShine", "Head"))
		local chx = x + side * 0.3
		table.insert(list, Shapes.Tile("Cheek" .. tag, V(0.8, 0.4, 0.1), V(chx, ey - 0.5 - eyeSize.Y / 2, fz), "Cheek", "Head"))
	end
	if not o.NoMuzzle then
		local mz = o.Muzzle or (if big then V(2, 1.2, 0.8) else V(1.6, 1.2, 0.6))
		local my = bottom + mz.Y / 2 - 0.1 -- top stays under the eyes
		table.insert(list, Shapes.Brick("Muzzle", mz, V(cx, my, front - mz.Z / 2), "Belly", "Head", "Top"))
		table.insert(list, Shapes.Tile("Nose", V(0.6, 0.4, 0.1), V(cx, my + mz.Y / 2 - 0.25, front - mz.Z - 0.05), o.NoseRole or "Nose", "Head"))
	end
end

function Shapes.Pattern(spec: PartSpec): PartSpec
	spec.Pattern = true
	return spec
end

function Shapes.Shadow(spec: PartSpec): PartSpec
	spec.Shadow = true
	return spec
end

-- Crystal mount: a crystal brick stack (0.8x1.2x0.8 + 0.6x0.8x0.6, ×len) rotated 45° on Y.
-- tiltX/tiltZ are clamped to ±15° (brick figures only tilt ears/antlers/crystals slightly).
function Shapes.Shard(pos: Vector3, tiltX: number, tiltZ: number, len: number, anim: string?): Shard
	local tx, tz = math.clamp(tiltX, -15, 15), math.clamp(tiltZ, -15, 15)
	return {
		CF = CFrame.new(pos) * CFrame.Angles(math.rad(tx), math.rad(45), math.rad(tz)),
		Len = len,
		Anim = anim or "Body",
	}
end

return Shapes
