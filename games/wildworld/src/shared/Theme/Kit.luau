--!strict
-- Part-building helpers shared by World (server), Theme.Props (build items) and CreatureBuilder.
-- Classic studs look (STUDS_STYLE_GUIDE §2.1): blocks default to Plastic with legacy Studs on top and
-- Inlet underneath (studs only render on Plastic block faces). Textured materials (Wood, Slate, Grass,
-- Metal, Glass...) are mapped to Plastic so every block keeps its studs; Metal -> Reflectance 0.2.
-- Round props (Ball / Blob / Cyl) stay SmoothPlastic. Small props don't cast shadows; decoration isn't
-- queryable/touchable.
local Kit = {}

export type Studs = "Top" | "All" | "None"
export type PartProps = {
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3?,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	CanCollide: boolean?,
	Name: string?,
	Studs: Studs?,
}

local M = Enum.Material
local KEEP: { [Enum.Material]: boolean } = {
	[M.Plastic] = true,
	[M.SmoothPlastic] = true,
	[M.Neon] = true,
	[M.ForceField] = true,
}

-- Brick material for a requested material (+ reflectance for "metal" gold bits).
function Kit.Mat(m: Enum.Material?): (Enum.Material, number)
	if m == nil then
		return M.Plastic, 0
	end
	if KEEP[m] then
		return m, 0
	end
	if m == M.Metal or m == M.DiamondPlate or m == M.Foil then
		return M.Plastic, 0.2
	end
	if m == M.Glass or m == M.Ice then
		return M.Plastic, 0.1
	end
	return M.Plastic, 0
end

-- Legacy surfaces: "Top" = studs on top / inlet below (world), "All" = studs on 5 faces (creatures,
-- trees), "None" = smooth. Only shows on Plastic.
function Kit.Studs(part: BasePart, mode: Studs?)
	local S = Enum.SurfaceType
	local m = mode or "Top"
	local side = if m == "All" then S.Studs else S.Smooth
	part.TopSurface = if m == "None" then S.Smooth else S.Studs
	part.BottomSurface = if m == "None" then S.Smooth else S.Inlet
	part.FrontSurface = side
	part.BackSurface = side
	part.LeftSurface = side
	part.RightSurface = side
end

-- Snap a size to the stud grid: X/Z whole studs (min 1), Y multiples of a 0.4 plate (min 0.4).
function Kit.Snap(v: Vector3): Vector3
	local function plate(y: number): number
		return math.max(0.4, math.floor(y / 0.4 + 0.5) * 0.4)
	end
	return Vector3.new(math.max(1, math.floor(v.X + 0.5)), plate(v.Y), math.max(1, math.floor(v.Z + 0.5)))
end

local function finish(part: BasePart, p: PartProps, parent: Instance, round: boolean): BasePart
	part.Anchored = true
	part.Size = p.Size
	part.CFrame = p.CFrame
	part.Color = p.Color or Color3.new(1, 1, 1)
	local mat, refl = Kit.Mat(p.Material)
	if round and p.Material == nil then
		mat = M.SmoothPlastic
	end
	part.Material = mat
	part.Reflectance = refl
	part.Transparency = p.Transparency or 0
	if mat == M.Plastic and not round then
		Kit.Studs(part, p.Studs or "Top")
	else
		Kit.Studs(part, "None")
	end
	part.CanCollide = if p.CanCollide == nil then false else p.CanCollide
	part.CanTouch = false
	part.CanQuery = part.CanCollide
	part.CastShadow = p.Size.Magnitude > 4
	part.Name = p.Name or "Part"
	part.Parent = parent
	return part
end

-- Generic part. Non-colliding unless CanCollide = true.
function Kit.Part(parent: Instance, p: PartProps): Part
	local part = Instance.new("Part")
	part.Shape = p.Shape or Enum.PartType.Block
	finish(part, p, parent, part.Shape ~= Enum.PartType.Block)
	return part
end

-- Studded brick. studs: "Top" (world default) | "All" (creatures, trees, props) | "None".
function Kit.Brick(parent: Instance, size: Vector3, cf: CFrame, color: Color3, studs: Studs?, collide: boolean?): Part
	return Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Studs = studs, CanCollide = collide == true, Name = "Brick" })
end

-- Solid (walk-on / bump-into) block.
function Kit.Solid(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Material = material, CanCollide = true })
end

function Kit.Block(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Material = material })
end

-- Smooth tile (signs, water surfaces, glass): SmoothPlastic, no studs.
function Kit.Tile(parent: Instance, size: Vector3, cf: CFrame, color: Color3): Part
	return Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Material = M.SmoothPlastic, Name = "Tile" })
end

-- Round props only (toy ball, lantern glass, bowls). SmoothPlastic unless a material is given.
function Kit.Ball(parent: Instance, d: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Kit.Part(parent, {
		Size = Vector3.new(d, d, d),
		CFrame = cf,
		Color = color,
		Material = material,
		Shape = Enum.PartType.Ball,
		Name = "Ball",
	})
end

-- Ellipsoid (Block + SpecialMesh Sphere). Round props only; SmoothPlastic, no studs.
function Kit.Blob(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic })
	Kit.Studs(part, "None")
	part.Name = "Blob"
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Upright cylinder: height along world Y at cf (Roblox cylinders lie along X, so rotate).
function Kit.Cyl(
	parent: Instance,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?
): Part
	return Kit.Part(parent, {
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Shape = Enum.PartType.Cylinder,
		CanCollide = collide == true,
		Name = "Cylinder",
	})
end

-- Slope brick (roofs, ear tips): smooth slope, like real slope bricks.
function Kit.Wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local w = Instance.new("WedgePart")
	finish(w, { Size = size, CFrame = cf, Color = color, Material = material }, parent, false)
	w.Name = "Wedge"
	return w
end

function Kit.Model(parent: Instance?, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Kit.Folder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = name
	nf.Parent = parent
	return nf
end

-- SurfaceGui text on one face of a part. Returns the TextLabel (named "Text").
function Kit.Label(part: BasePart, face: Enum.NormalId, text: string, color: Color3?, glow: boolean?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = if glow then 0 else 0.3
	gui.Brightness = if glow then 1.6 else 1
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromHex("#1F2A36")
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.Parent = label
	return label
end

function Kit.Tag(inst: Instance, tag: string, attrs: { [string]: any }?)
	inst:AddTag(tag)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
end

-- Lightness jitter (±amount) for foliage variety.
function Kit.Jitter(c: Color3, rng: Random, amount: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + rng:NextNumber(-amount, amount), 0, 1))
end

-- Brick "seam" shade: value ×0.95 by default (alternate layers); k > 1 lightens.
function Kit.Shade(c: Color3, k: number?): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.min(1, v * (k or 0.95)))
end

return Kit
