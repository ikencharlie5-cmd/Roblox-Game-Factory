--!strict
-- Tiny part-building helpers shared by all World modules. Everything is anchored.
local Build = {}

export type PartProps = {
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3?,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	CanCollide: boolean?,
	Name: string?,
	Reflectance: number?,
}

function Build.Part(parent: Instance, p: PartProps): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Shape = p.Shape or Enum.PartType.Block
	part.Size = p.Size
	part.CFrame = p.CFrame
	part.Color = p.Color or Color3.new(1, 1, 1)
	part.Material = p.Material or Enum.Material.SmoothPlastic
	part.Transparency = p.Transparency or 0
	part.Reflectance = p.Reflectance or 0
	part.CanCollide = if p.CanCollide == nil then true else p.CanCollide
	part.Name = p.Name or "Part"
	part.CastShadow = part.Size.Magnitude > 3
	part.Parent = parent
	return part
end

-- Decorative (non-colliding, non-touch) part.
function Build.Deco(parent: Instance, p: PartProps): Part
	local part = Build.Part(parent, p)
	part.CanCollide = false
	part.CanTouch = false
	return part
end

-- Ellipsoid via SpecialMesh (Ball parts can't be squashed).
function Build.Blob(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Build.Deco(parent, {
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material,
		Name = "Blob",
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Vertical cylinder (Roblox cylinders lie along X, so rotate).
function Build.Cyl(
	parent: Instance,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?
): Part
	local part = Build.Part(parent, {
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Shape = Enum.PartType.Cylinder,
		CanCollide = collide == true,
		Name = "Cylinder",
	})
	return part
end

function Build.Ball(parent: Instance, d: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return Build.Deco(parent, {
		Size = Vector3.new(d, d, d),
		CFrame = cf,
		Color = color,
		Material = material,
		Shape = Enum.PartType.Ball,
		Name = "Ball",
	})
end

function Build.Wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material or Enum.Material.SmoothPlastic
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

function Build.Model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Build.Folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- SurfaceGui text sign on one face of a part. Returns the TextLabel.
function Build.Label(part: BasePart, face: Enum.NormalId, text: string, color: Color3?, bg: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if bg then 0 else 1
	label.BackgroundColor3 = bg or Color3.new(1, 1, 1)
	label.TextColor3 = color or Color3.fromHex("#3B2A1A")
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.Name = "Text"
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return label
end

-- Floating billboard text above a part.
function Build.Billboard(adornee: BasePart, text: string, color: Color3, height: number, width: number?): TextLabel
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(width or 8, 1.6)
	bb.StudsOffset = Vector3.new(0, height, 0)
	bb.MaxDistance = 120
	bb.LightInfluence = 0
	bb.Adornee = adornee
	bb.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.Name = "Text"
	label.Parent = bb
	return label
end

-- Simple low-poly tree: trunk + 2-3 leaf balls. ~4 parts.
function Build.Tree(parent: Instance, pos: Vector3, scale: number, leaf: Color3?)
	local s = scale
	local trunk = Build.Cyl(parent, 6 * s, 1.4 * s, CFrame.new(pos + Vector3.new(0, 3 * s, 0)), Color3.fromHex("#8B5A2B"), Enum.Material.Wood, true)
	trunk.Name = "Trunk"
	local c = leaf or Color3.fromHex("#4CAF50")
	Build.Ball(parent, 6 * s, CFrame.new(pos + Vector3.new(0, 7 * s, 0)), c, Enum.Material.Grass)
	Build.Ball(parent, 4.5 * s, CFrame.new(pos + Vector3.new(1.8 * s, 6 * s, 0.8 * s)), c:Lerp(Color3.new(1, 1, 0.6), 0.15), Enum.Material.Grass)
	Build.Ball(parent, 4 * s, CFrame.new(pos + Vector3.new(-1.6 * s, 6.4 * s, -1 * s)), c:Lerp(Color3.new(0, 0.2, 0), 0.15), Enum.Material.Grass)
end

-- Little flower: stem + bloom. 2 parts.
function Build.Flower(parent: Instance, pos: Vector3, color: Color3)
	Build.Deco(parent, {
		Size = Vector3.new(0.2, 1.2, 0.2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.6, 0)),
		Color = Color3.fromHex("#4CAF50"),
	})
	Build.Ball(parent, 0.8, CFrame.new(pos + Vector3.new(0, 1.3, 0)), color, Enum.Material.SmoothPlastic)
end

function Build.Tag(inst: Instance, tag: string, attrs: { [string]: any }?)
	inst:AddTag(tag)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
end

return Build
