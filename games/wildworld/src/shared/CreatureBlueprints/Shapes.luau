--!strict
-- Blueprint vocabulary shared by every species file. Coordinates are adult scale, studs, relative to the
-- ground point under the creature's centre; the creature faces -Z (Roblox LookVector).
local Shapes = {}

export type Role = string -- Primary | Secondary | Belly | Accent | Feature | Glow | Eye | EyeShine | Cheek
export type PartSpec = {
	Name: string,
	Shape: "Ball" | "Blob" | "Cyl" | "Block" | "Wedge",
	Size: Vector3,
	CF: CFrame,
	Role: Role,
	Anim: string, -- Body | Head | LegFL | LegFR | LegBL | LegBR | Tail | EarL | EarR
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
	Shards: { Shard }, -- Crystal mutation mount points
	EmitterPart: string, -- part that hosts the creature's one emitter / light
	Native: { Emitter: string?, NightLight: number? }, -- built-in VFX (Emberfox embers, Lumibun ear glow)
}

local V = Vector3.new

function Shapes.Ball(name: string, d: number, pos: Vector3, role: Role, anim: string): PartSpec
	return { Name = name, Shape = "Ball", Size = V(d, d, d), CF = CFrame.new(pos), Role = role, Anim = anim }
end

function Shapes.Blob(name: string, size: Vector3, cf: CFrame | Vector3, role: Role, anim: string): PartSpec
	local c = if typeof(cf) == "Vector3" then CFrame.new(cf) else cf
	return { Name = name, Shape = "Blob", Size = size, CF = c, Role = role, Anim = anim }
end

-- Upright leg cylinder centred at pos.
function Shapes.Leg(name: string, len: number, d: number, pos: Vector3, role: Role, anim: string): PartSpec
	return {
		Name = name,
		Shape = "Cyl",
		Size = V(len, d, d),
		CF = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Role = role,
		Anim = anim,
	}
end

-- Cylinder stick between two points.
function Shapes.Stick(name: string, a: Vector3, b: Vector3, d: number, role: Role, anim: string): PartSpec
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
	return { Name = name, Shape = "Cyl", Size = V((b - a).Magnitude, d, d), CF = cf, Role = role, Anim = anim }
end

function Shapes.Wedge(name: string, size: Vector3, cf: CFrame, role: Role, anim: string): PartSpec
	return { Name = name, Shape = "Wedge", Size = size, CF = cf, Role = role, Anim = anim }
end

-- Big glossy eyes + highlights (+ optional blush cheeks). x = half spacing, front = z of eye centre.
function Shapes.Face(list: { PartSpec }, x: number, y: number, z: number, d: number, cheeks: boolean)
	for _, side in { -1, 1 } do
		local tag = if side < 0 then "L" else "R"
		table.insert(list, Shapes.Ball("Eye" .. tag, d, V(side * x, y, z), "Eye", "Head"))
		local shine = Shapes.Ball("Shine" .. tag, d * 0.32, V(side * x + side * 0.08, y + d * 0.22, z - d * 0.38), "EyeShine", "Head")
		table.insert(list, shine)
		if cheeks then
			local c = Shapes.Blob("Cheek" .. tag, V(d * 0.9, d * 0.5, d * 0.3), V(side * (x + d * 0.45), y - d * 0.75, z + 0.08), "Cheek", "Head")
			c.Transparency = 0.35
			table.insert(list, c)
		end
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

function Shapes.Shard(pos: Vector3, tiltX: number, tiltZ: number, len: number, anim: string?): Shard
	return {
		CF = CFrame.new(pos) * CFrame.Angles(math.rad(tiltX), math.rad(45), math.rad(tiltZ)),
		Len = len,
		Anim = anim or "Body",
	}
end

return Shapes
