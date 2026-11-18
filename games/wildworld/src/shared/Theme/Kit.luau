--!strict
-- Part-building helpers shared by World (server), Theme.Props (build items) and CreatureBuilder.
-- Every part is anchored, SmoothPlastic by default, and decoration flags follow ART_STYLE_GUIDE §4:
-- small props don't cast shadows, decoration isn't queryable/touchable.
local Kit = {}

export type PartProps = {
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3?,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	CanCollide: boolean?,
	Name: string?,
}

local function finish(part: BasePart, p: PartProps, parent: Instance): BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = p.Size
	part.CFrame = p.CFrame
	part.Color = p.Color or Color3.new(1, 1, 1)
	part.Material = p.Material or Enum.Material.SmoothPlastic
	part.Transparency = p.Transparency or 0
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
	finish(part, p, parent)
	return part
end

-- Solid (walk-on / bump-into) block.
function Kit.Solid(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Material = material, CanCollide = true })
end

function Kit.Block(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Kit.Part(parent, { Size = size, CFrame = cf, Color = color, Material = material })
end

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

-- Ellipsoid (Block + SpecialMesh Sphere; mesh Scale stays 1 so part Size drives it).
function Kit.Blob(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Kit.Block(parent, size, cf, color, material)
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

function Kit.Wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local w = Instance.new("WedgePart")
	finish(w, { Size = size, CFrame = cf, Color = color, Material = material }, parent)
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
	label.TextColor3 = color or Color3.fromHex("#3B2A1A")
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

return Kit
